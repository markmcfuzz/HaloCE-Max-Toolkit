---------------------------------------------------------
-- * Build Shader Resolver Module
-- * Resolves shader references from gbxmodel to actual texture file paths
-- * 
-- * This module:
-- * - Builds full paths to shader tag files from relative paths in gbxmodel
-- * - Opens shader_model tags to extract base map texture references
-- * - Converts tag-relative bitmap paths to data-relative file paths
-- * - Returns texture paths ready for material application
-- * 
-- * NOTE: Shader_model modules are loaded on-demand to avoid struct conflicts
--

-------------------------------------------------------
-- Module initialization flag and paths
-------------------------------------------------------
global _shaderModulesLoaded = false
global _shaderModulesPath = undefined

-- Capture the path at file load time
if _shaderModulesPath == undefined then
(
    local resolverDir = getFilenamePath (getThisScriptFilename())
    _shaderModulesPath = pathConfig.removePathLeaf resolverDir
)

-------------------------------------------------------
-- Preload shader_model modules at script level
-------------------------------------------------------
if not _shaderModulesLoaded and _shaderModulesPath != undefined then
(
    local structPath = _shaderModulesPath + "\\shader_model\\tag_struct.ms"
    local readerPath = _shaderModulesPath + "\\shader_model\\tag_base_reader.ms"
    
    if doesFileExist structPath and doesFileExist readerPath then
    (
        try
        (
            -- Declare as global first so the filein can populate it
            global readShaderModelTag
            global shaderModelTag
            
            fileIn structPath
            fileIn readerPath
            
            if readShaderModelTag != undefined then
                _shaderModulesLoaded = true
        )
        catch ()  -- Silently ignore any errors during preload
    )
)

-------------------------------------------------------
-- Verify shader modules are loaded (for safety)
-------------------------------------------------------
fn loadShaderModelModules =
(
    if _shaderModulesLoaded and readShaderModelTag != undefined then
        return true
    
    -- If not loaded, something went wrong during preload
    logger "Shader model modules not available\n" logType:#error
    return false
)

-------------------------------------------------------
-- Path Utilities
-------------------------------------------------------

--
-- * Extract the tags root directory from a gbxmodel file path
-- * Example: D:\Dev\HaloCE\Shadowmods\alpha-halo\tags\gdd\weapons\shotgun_double\fp\fp.gbxmodel
-- * Returns: D:\Dev\HaloCE\Shadowmods\alpha-halo\tags\
--
fn getTagsRootFromGbxmodelPath gbxmodelPath =
(
    -- Find "tags\" or "tags/" in the path
    local tagsPos = findString gbxmodelPath "\\tags\\"
    
    if tagsPos == undefined then
    (
        -- Try forward slash variant
        tagsPos = findString gbxmodelPath "/tags/"
        if tagsPos == undefined then
        (
            logger "Could not find 'tags' directory in gbxmodel path: %\n" params:#(gbxmodelPath) logType:#warning
            return undefined
        )
    )
    
    -- Extract everything up to and including "tags\"
    -- +5 to include "\tags\" (backslash + tags + backslash)
    local tagsRoot = substring gbxmodelPath 1 (tagsPos + 5)
    return tagsRoot
)

-- * Convert tags root path to data root path
-- * Example: D:\Dev\HaloCE\Shadowmods\alpha-halo\tags\
-- * Returns: D:\Dev\HaloCE\Shadowmods\alpha-halo\data\
fn convertTagsPathToDataPath tagsRoot =
(
    if tagsRoot == undefined then
        return undefined
        
    -- Replace "tags\" with "data\"
    local dataRoot = substituteString tagsRoot "\\tags\\" "\\data\\"
    
    -- Handle forward slash variant
    if dataRoot == tagsRoot then
        dataRoot = substituteString tagsRoot "/tags/" "/data/"
    
    return dataRoot
)

--
-- * Build full shader file path from gbxmodel path and relative shader path
-- * Example: 
-- *   gbxmodelPath = "D:\...\tags\gdd\weapons\shotgun_double\fp\fp.gbxmodel"
-- *   shaderRelativePath = "gdd\weapons\shared\shaders\gdd_bullets"
-- * Returns: "D:\...\tags\gdd\weapons\shared\shaders\gdd_bullets.shader_model"
--
fn buildShaderFilePath gbxmodelPath shaderRelativePath =
(
    local tagsRoot = getTagsRootFromGbxmodelPath gbxmodelPath
    if tagsRoot == undefined then
        return undefined
    
    -- Combine tags root with relative shader path and add extension
    local shaderFullPath = tagsRoot + shaderRelativePath + ".shader_model"
    
    return shaderFullPath
)

--
-- * Build full texture file path from tags root and relative bitmap path
-- * Supports multiple image formats: .tif, .png
-- * Returns the first format that exists on disk
-- * Example:
-- *   gbxmodelPath = D:\...\tags\gdd\weapons\shotgun_double\fp\fp.gbxmodel
-- *   bitmapRelativePath = gdd\weapons\shared\bitmaps\bullets
-- * Returns: D:\...\data\gdd\weapons\shared\bitmaps\bullets.tif (if exists)
--
fn buildTextureFilePath gbxmodelPath bitmapRelativePath =
(
    if bitmapRelativePath == undefined or bitmapRelativePath == "" or bitmapRelativePath == "NULL" then
        return undefined
    
    local tagsRoot = getTagsRootFromGbxmodelPath gbxmodelPath
    if tagsRoot == undefined then
        return undefined
    
    local dataRoot = convertTagsPathToDataPath tagsRoot
    if dataRoot == undefined then
        return undefined
    
    -- Try multiple image formats in order of preference
    local imageFormats = #(".tif", ".png")
    local basePath = dataRoot + bitmapRelativePath
    
    for ext in imageFormats do
    (
        local fullPath = basePath + ext
        if doesFileExist fullPath then
        (
            return fullPath
        )
    )
    
    -- If no file found, return the .tif path as default
    return basePath + ".tif"
)

-------------------------------------------------------
-- Shader Processing
-------------------------------------------------------

/**
 * Open a shader_model tag and extract base map path
 * Returns: bitmap relative path or undefined if failed
 */
fn getBaseMapFromShader shaderFilePath =
(
    -- Check if file exists
    if not doesFileExist shaderFilePath then
    (
        logger "Shader file not found: %\n" params:#(shaderFilePath) logType:#warning
        return undefined
    )
    
    -- Read shader model tag (readShaderModelTag handles file opening internally)
    local shaderData = readShaderModelTag shaderFilePath
    
    if shaderData == undefined then
    (
        logger "Failed to read shader model tag: %\n" params:#(shaderFilePath) logType:#error
        return undefined
    )
    
    -- Extract base map path
    local baseMapPath = shaderData.maps.baseMap.path
    
    if baseMapPath == undefined or baseMapPath == "" or baseMapPath == "NULL" then
    (
        logger "No base map found in shader: %\n" params:#(filenameFromPath shaderFilePath) logType:#info
        return undefined
    )
    
    return baseMapPath
)

/**
 * Resolve a single shader reference to its texture file path
 * Returns: struct with shader info and texture path
 */
fn resolveShaderTexture gbxmodelPath shaderData =
(
    struct ShaderTextureResult
    (
        shaderIndex,
        shaderName,
        shaderType,
        shaderPath,
        shaderFilePath,
        baseMapPath,
        textureFilePath,
        success = false
    )
    
    local result = ShaderTextureResult()
    result.shaderName = shaderData.shaderName
    result.shaderType = shaderData.shaderType
    result.shaderPath = shaderData.shaderPath
    
    -- Build full shader file path
    local shaderFilePath = buildShaderFilePath gbxmodelPath shaderData.shaderPath
    if shaderFilePath == undefined then
    (
        return result
    )
    result.shaderFilePath = shaderFilePath
    
    -- Check if shader file exists
    if not doesFileExist shaderFilePath then
    (
        logger "Shader file not found: %\n" params:#(shaderFilePath) logType:#warning
        return result
    )
    
    -- Get base map from shader
    local baseMapPath = getBaseMapFromShader shaderFilePath
    if baseMapPath == undefined then
    (
        return result
    )
    result.baseMapPath = baseMapPath
    
    -- Build full texture file path
    local textureFilePath = buildTextureFilePath gbxmodelPath baseMapPath
    if textureFilePath == undefined then
    (
        return result
    )
    result.textureFilePath = textureFilePath
    
    -- Check if texture file exists
    if not doesFileExist textureFilePath then
    (
        --logger "Texture file not found: %\n" params:#(textureFilePath) logType:#info
        return result
    )
    
    result.success = true
    return result
)

/**
 * Resolve all shader textures from a gbxmodel
 * Main entry point for texture resolution
 * 
 * Parameters:
 *   gbxmodelPath - Full path to the gbxmodel file
 *   shadersArray - Array of shader data from gbxmodel
 * 
 * Returns: Array of ShaderTextureResult structs
 */
fn resolveAllShaderTextures gbxmodelPath shadersArray =
(
    if shadersArray == undefined or shadersArray.count == 0 then
    (
        logger "No shaders to resolve\n" logType:#info
        return #()
    )
    
    -- Load shader_model modules on demand (after gbxmodel is fully loaded)
    if not loadShaderModelModules() then
    (
        logger "Failed to load shader model modules\n" logType:#error
        return #()
    )
    
    local results = #()
    
    for i = 1 to shadersArray.count do
    (
        local shaderData = shadersArray[i]
        local result = resolveShaderTexture gbxmodelPath shaderData
        result.shaderIndex = i - 1  -- Zero-based index to match shader array
        append results result
    )
    
    return results
)

logger "Shader texture resolver loaded.\n" logType:#success
