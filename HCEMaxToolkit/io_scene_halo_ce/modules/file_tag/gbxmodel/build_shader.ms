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
-- Module initialization flags and paths
-------------------------------------------------------
global _shaderModelModulesLoaded = false
global _shaderChicagoModulesLoaded = false
global _shaderModulesPath = undefined

-- Capture the path at file load time
if _shaderModulesPath == undefined then
(
    local resolverDir = getFilenamePath (getThisScriptFilename())
    _shaderModulesPath = pathConfig.removePathLeaf resolverDir
)

-------------------------------------------------------
-- Load shader modules on-demand (not at script level)
-------------------------------------------------------
fn loadShaderModelModules =
(
    if not _shaderModelModulesLoaded and _shaderModulesPath != undefined then
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
                    _shaderModelModulesLoaded = true
            )
            catch ()  -- Silently ignore any errors during load
        )
    )
    
    if _shaderModelModulesLoaded and readShaderModelTag != undefined then
        return true
    
    logger "Shader model modules not available\n" logType:#error
    return false
)

fn loadShaderChicagoModules =
(
    if not _shaderChicagoModulesLoaded and _shaderModulesPath != undefined then
    (
        local structPath = _shaderModulesPath + "\\shader_transparent_chicago\\tag_struct.ms"
        local readerPath = _shaderModulesPath + "\\shader_transparent_chicago\\tag_base_reader.ms"
        
        if doesFileExist structPath and doesFileExist readerPath then
        (
            try
            (
                -- Declare as global first so the filein can populate it
                global readShaderTransparentChicagoTag
                global shaderTransparentChicagoTag
                
                fileIn structPath
                fileIn readerPath
                
                if readShaderTransparentChicagoTag != undefined then
                    _shaderChicagoModulesLoaded = true
            )
            catch ()  -- Silently ignore any errors during load
        )
    )
    
    if _shaderChicagoModulesLoaded and readShaderTransparentChicagoTag != undefined then
        return true
    
    logger "Shader transparent chicago modules not available\n" logType:#error
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
-- *   shaderType = "shader model"
-- * Returns: "D:\...\tags\gdd\weapons\shared\shaders\gdd_bullets.shader_model"
--
fn buildShaderFilePath gbxmodelPath shaderRelativePath shaderType:"shader model" =
(
    local tagsRoot = getTagsRootFromGbxmodelPath gbxmodelPath
    if tagsRoot == undefined then
        return undefined
    
    -- Determine file extension based on shader type
    local extension = case shaderType of
    (
        "shader model": ".shader_model"
        "shader transparent chicago": ".shader_transparent_chicago"
        "shader transparent chicago extended": ".shader_transparent_chicago_extended"
        "shader environment": ".shader_environment"
        "shader transparent generic": ".shader_transparent_generic"
        "shader transparent glass": ".shader_transparent_glass"
        "shader transparent meter": ".shader_transparent_meter"
        "shader transparent plasma": ".shader_transparent_plasma"
        "shader transparent water": ".shader_transparent_water"
        default: ".shader_model"  -- Fallback
    )
    
    -- Combine tags root with relative shader path and add extension
    local shaderFullPath = tagsRoot + shaderRelativePath + extension
    
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
fn getBaseMapFromShaderModel shaderFilePath =
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
 * Open a shader_transparent_chicago tag and extract first map path
 * Returns: bitmap relative path or undefined if failed
 */
fn getMap1FromChicagoShader shaderFilePath =
(
    -- Check if file exists
    if not doesFileExist shaderFilePath then
    (
        logger "Shader file not found: %\n" params:#(shaderFilePath) logType:#warning
        return undefined
    )
    
    -- Read chicago shader tag
    local shaderData = readShaderTransparentChicagoTag shaderFilePath
    
    if shaderData == undefined then
    (
        logger "Failed to read shader transparent chicago tag: %\n" params:#(shaderFilePath) logType:#error
        return undefined
    )
    
    -- Extract first map from fourStageMap array
    if shaderData.fourStageMap != undefined and shaderData.fourStageMap.count > 0 then
    (
        local map1 = shaderData.fourStageMap[1]
        -- map1 is shaderMapsResult, which contains mapsProps (returnFourStageMap)
        -- mapsProps contains mapPath (tagRefData), which has the path string
        local mapPath = map1.mapsProps.mapPath.path
        
        if mapPath != undefined and mapPath != "" and mapPath != "NULL" then
            return mapPath
    )
    
    logger "No maps found in chicago shader: %\n" params:#(filenameFromPath shaderFilePath) logType:#info
    return undefined
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
    
    -- Build full shader file path with correct extension
    local shaderFilePath = buildShaderFilePath gbxmodelPath shaderData.shaderPath shaderType:shaderData.shaderType
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
    
    -- Get base map from shader based on shader type
    local baseMapPath = undefined
    case shaderData.shaderType of
    (
        "shader model":
        (
            if not loadShaderModelModules() then
                return result
            baseMapPath = getBaseMapFromShaderModel shaderFilePath
        )
        "shader transparent chicago":
        (
            if not loadShaderChicagoModules() then
                return result
            baseMapPath = getMap1FromChicagoShader shaderFilePath
        )
        default:
        (
            logger "Unsupported shader type: %\n" params:#(shaderData.shaderType) logType:#warning
            return result
        )
    )
    
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
    
    -- Note: Shader modules are loaded on-demand per shader type
    -- No preloading needed here
    
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
