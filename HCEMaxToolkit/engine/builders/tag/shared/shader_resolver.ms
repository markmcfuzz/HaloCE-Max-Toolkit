------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but MERCHANTABILITY ANY WARRANTY; without the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

-- Shader Texture Resolver (parser-based)
-- Resolves shader tag references (from any tag block with a "shader" tagReference
-- field - gbxmodel's shaders, scenario_structure_bsp's materials/collisionMaterials,
-- etc.) to actual texture file paths. Each shader tag is read with the generic tag
-- parser (readTagWithParents), so the FULL tag data is available to callers
-- (result.shaderEntry / result.mainEntry), not just the primary texture path.
-- Requires the shader group definitions (core\halo1\groups\shader*.ms) to be
-- included by the importer.

-------------------------------------------------------
-- Shader Type Utilities
-------------------------------------------------------

-- Convert shader tag class FourCC (integer) to type string
fn shaderTagClassToString tagClass =
(
	case tagClass of
	(
		1936683887: "shader_model"                         -- 'soso'
		1935894633: "shader_transparent_chicago"           -- 'schi'
		1935893880: "shader_transparent_chicago_extended"  -- 'scex'
		1936684146: "shader_transparent_generic"           -- 'sotr'
		1936157793: "shader_transparent_glass"             -- 'sgla'
		1936549236: "shader_transparent_meter"             -- 'smet'
		1937203572: "shader_transparent_water"             -- 'swat'
		1936747617: "shader_transparent_plasma"            -- 'spla'
		1936027254: "shader_environment"                   -- 'senv'
		default: "shader_model"
	)
)

-- Convert shader tag class string (from file header) to type string
fn shaderTagClassStrToString classStr =
(
	case classStr of
	(
		"soso": "shader_model"
		"schi": "shader_transparent_chicago"
		"scex": "shader_transparent_chicago_extended"
		"sotr": "shader_transparent_generic"
		"sgla": "shader_transparent_glass"
		"smet": "shader_transparent_meter"
		"swat": "shader_transparent_water"
		"spla": "shader_transparent_plasma"
		"senv": "shader_environment"
		default: undefined
	)
)

-------------------------------------------------------
-- Path Utilities
-------------------------------------------------------

-- Extract tags root from any full tag path (gbxmodel, scenario_structure_bsp, ...)
-- Example: "D:\halo\tags\weapons\rifle\rifle.gbxmodel" -> "D:\halo\tags\"
fn getTagsRootFromTagPath tagFilePath =
(
	if tagFilePath == undefined then return undefined
	local tagsPos = findString tagFilePath "\\tags\\"
	if tagsPos == undefined then
	(
		tagsPos = findString tagFilePath "/tags/"
		if tagsPos == undefined then
		(
			logger.warn "Could not find 'tags' directory in path: {}\n" args:#(tagFilePath)
			return undefined
		)
	)
	return substring tagFilePath 1 (tagsPos + 5)
)

-- Convert tags root to data root
-- Example: "D:\halo\tags\" -> "D:\halo\data\"
fn convertTagsPathToDataPath tagsRoot =
(
	if tagsRoot == undefined then return undefined
	local dataRoot = substituteString tagsRoot "\\tags\\" "\\data\\"
	if dataRoot == tagsRoot then
		dataRoot = substituteString tagsRoot "/tags/" "/data/"
	return dataRoot
)

-- Build full shader file path with correct extension
fn buildShaderFilePath tagFilePath shaderRelativePath shaderType:undefined =
(
	if shaderRelativePath == undefined or shaderRelativePath == "" then return undefined
	local tagsRoot = getTagsRootFromTagPath tagFilePath
	if tagsRoot == undefined then return undefined
	local ext = case shaderType of
	(
		"shader_model":                        ".shader_model"
		"shader_transparent_chicago":          ".shader_transparent_chicago"
		"shader_transparent_chicago_extended": ".shader_transparent_chicago_extended"
		"shader_transparent_generic":          ".shader_transparent_generic"
		"shader_transparent_glass":            ".shader_transparent_glass"
		"shader_transparent_meter":            ".shader_transparent_meter"
		"shader_transparent_water":            ".shader_transparent_water"
		"shader_transparent_plasma":           ".shader_transparent_plasma"
		"shader_environment":                  ".shader_environment"
		default:                               ".shader_model"
	)
	return tagsRoot + shaderRelativePath + ext
)

-- Build texture file path (maps tags->data, tries multiple image formats)
fn buildTextureFilePath tagFilePath bitmapRelativePath =
(
	if bitmapRelativePath == undefined or bitmapRelativePath == "" or bitmapRelativePath == "NULL" then
		return undefined
	local tagsRoot = getTagsRootFromTagPath tagFilePath
	if tagsRoot == undefined then return undefined
	local dataRoot = convertTagsPathToDataPath tagsRoot
	if dataRoot == undefined then return undefined
	local basePath = dataRoot + bitmapRelativePath
	for ext in #(".png", ".tif", ".bmp", ".dds", ".tga") do
	(
		local fullPath = basePath + ext
		if doesFileExist fullPath then return fullPath
	)
	return undefined
)

-------------------------------------------------------
-- Parser-based Shader Tag Reading
-------------------------------------------------------

-- Parse cache: shader file path -> parseInfo dictionary (cleared per import)
global _shaderResolverCache = dictionary #string

-- Clear the parse cache. Call once at the start of an import job before resolving
-- shaders one-by-one (resolveAllShaderTextures does this internally already).
fn resetShaderResolverCache =
(
	_shaderResolverCache = dictionary #string
)

-- Extract the bitmap path from a parser tag-ref dictionary (undefined if empty)
fn shaderTagRefPath tagRefDict =
(
	if tagRefDict == undefined or classOf tagRefDict != Dictionary then return undefined
	local p = tagRefDict[#path]
	if p == undefined or p == "" or p == "NULL" then undefined else p
)

-- Read a complete shader tag using the generic parser.
-- Returns a dictionary:
--   #classStr    tag class from file header (e.g. "soso")
--   #shaderType  type string (e.g. "shader_model")
--   #shaderEntry parsed parent 'shader' block tuples (radiosity/physics)
--   #mainEntry   parsed shader-type block tuples (full tag data)
fn readShaderTagParsed shaderFilePath =
(
	local cached = _shaderResolverCache[shaderFilePath]
	if cached != undefined then return cached

	local classStr = getTagClass shaderFilePath
	local shaderType = shaderTagClassStrToString classStr
	if shaderType == undefined then
	(
		logger.warn "Unsupported shader class '{}' in: {}\n" args:#(classStr, filenameFromPath shaderFilePath)
		return undefined
	)

	local shaderTagDef = getTagDefByClass classStr
	if shaderTagDef == undefined then
	(
		logger.error "Tag definition for '{}' not loaded. Include core\\halo1\\groups\\{}.ms\n" args:#(classStr, shaderType)
		return undefined
	)

	local f = fopen shaderFilePath "rb"
	if f == undefined then
	(
		logger.error "Cannot open shader file: {}\n" args:#(shaderFilePath)
		return undefined
	)

	-- The parser works on a global file handle; save/restore it around this read
	local prevHandle = getCurrentFileHandle()
	setCurrentFileHandle f

	-- Skip 64-byte tag header; readTagWithParents reads shader parent block + main block
	fseek f 64 #seek_set

	local parsed = undefined
	try
	(
		parsed = readTagWithParents shaderTagDef printParents:false printMain:false
	)
	catch
	(
		logger.error "Parser failed on shader '{}': {}\n" args:#(filenameFromPath shaderFilePath, getCurrentException())
		parsed = undefined
	)

	fclose f
	setCurrentFileHandle prevHandle

	if parsed == undefined or parsed.count == 0 then return undefined

	-- readTagWithParents returns #(#(parentEntry, parentDef), ..., #(mainEntry, mainDef))
	local parseInfo = dictionary #name
	parseInfo[#classStr]    = classStr
	parseInfo[#shaderType]  = shaderType
	parseInfo[#mainEntry]   = parsed[parsed.count][1]
	parseInfo[#shaderEntry] = if parsed.count > 1 then parsed[1][1] else undefined

	_shaderResolverCache[shaderFilePath] = parseInfo
	return parseInfo
)

-------------------------------------------------------
-- Bitmap Reference Collection (per shader type)
-------------------------------------------------------

-- Collected bitmap references of one shader tag
struct ShaderMapCollection
(
	orderedKeys = #(),   -- map key strings in tag field order
	refs,                -- Dictionary: key -> parser tag-ref dictionary
	primaryKey           -- key of the map used as diffuse in the viewport material
)

-- Append a tag-ref to the collection if it has a non-empty path. Returns the key or undefined.
fn _addShaderMapRef coll key refDict =
(
	if (shaderTagRefPath refDict) == undefined then return undefined
	append coll.orderedKeys key
	coll.refs[key] = refDict
	return key
)

-- Add every 'map' tag-ref found in a maps-style reflexive block ("map1", "map2", ...)
-- Returns the key of the LAST map added (undefined if none)
fn _addShaderMapBlock coll mainEntry blockFieldName keyPrefix =
(
	local lastKey = undefined
	local mapEntries = getFieldValue mainEntry blockFieldName
	if mapEntries != undefined and classOf mapEntries == Array then
	(
		for j = 1 to mapEntries.count do
		(
			local refDict = getFieldValue mapEntries[j] "map"
			local key = _addShaderMapRef coll (keyPrefix + (j as string)) refDict
			if key != undefined then lastKey = key
		)
	)
	return lastKey
)

-- Collect all bitmap tag-refs of a parsed shader tag.
-- primaryKey preserves the legacy resolver behavior per shader type.
fn collectShaderMapRefs shaderType mainEntry =
(
	local coll = ShaderMapCollection orderedKeys:#() refs:(dictionary #string)

	case shaderType of
	(
		"shader_model":
		(
			coll.primaryKey = _addShaderMapRef coll "baseMap" (getFieldValue mainEntry "baseMap")
			_addShaderMapRef coll "multipurposeMap" (getFieldValue mainEntry "multipurposeMap")
			_addShaderMapRef coll "detailMap" (getFieldValue mainEntry "detailMap")
			_addShaderMapRef coll "reflectionCubeMap" (getFieldValue mainEntry "reflectionCubeMap")
		)
		"shader_transparent_chicago":
		(
			-- Legacy behavior: the LAST map entry drives the viewport material
			coll.primaryKey = _addShaderMapBlock coll mainEntry "maps" "map"
		)
		"shader_transparent_chicago_extended":
		(
			local last4 = _addShaderMapBlock coll mainEntry "4StageMaps" "4StageMap"
			local last2 = _addShaderMapBlock coll mainEntry "2StageMaps" "2StageMap"
			coll.primaryKey = if last4 != undefined then last4 else last2
		)
		"shader_transparent_generic":
		(
			coll.primaryKey = _addShaderMapBlock coll mainEntry "maps" "map"
		)
		"shader_transparent_glass":
		(
			_addShaderMapRef coll "backgroundTintMap" (getFieldValue mainEntry "backgroundTintMap")
			_addShaderMapRef coll "reflectionMap" (getFieldValue mainEntry "reflectionMap")
			_addShaderMapRef coll "bumpMap" (getFieldValue mainEntry "bumpMap")
			coll.primaryKey = _addShaderMapRef coll "diffuseMap" (getFieldValue mainEntry "diffuseMap")
			_addShaderMapRef coll "diffuseDetailMap" (getFieldValue mainEntry "diffuseDetailMap")
			_addShaderMapRef coll "specularMap" (getFieldValue mainEntry "specularMap")
			_addShaderMapRef coll "specularDetailMap" (getFieldValue mainEntry "specularDetailMap")
		)
		"shader_transparent_meter":
		(
			coll.primaryKey = _addShaderMapRef coll "map" (getFieldValue mainEntry "map")
		)
		"shader_transparent_water":
		(
			coll.primaryKey = _addShaderMapRef coll "baseMap" (getFieldValue mainEntry "baseMap")
			_addShaderMapRef coll "reflectionMap" (getFieldValue mainEntry "reflectionMap")
			_addShaderMapRef coll "rippleMaps" (getFieldValue mainEntry "rippleMaps")
		)
		"shader_transparent_plasma":
		(
			coll.primaryKey = _addShaderMapRef coll "primaryNoiseMap" (getFieldValue mainEntry "primaryNoiseMap")
			_addShaderMapRef coll "secondaryNoiseMap" (getFieldValue mainEntry "secondaryNoiseMap")
		)
		"shader_environment":
		(
			coll.primaryKey = _addShaderMapRef coll "baseMap" (getFieldValue mainEntry "baseMap")
			_addShaderMapRef coll "primaryDetailMap" (getFieldValue mainEntry "primaryDetailMap")
			_addShaderMapRef coll "secondaryDetailMap" (getFieldValue mainEntry "secondaryDetailMap")
			_addShaderMapRef coll "microDetailMap" (getFieldValue mainEntry "microDetailMap")
			_addShaderMapRef coll "bumpMap" (getFieldValue mainEntry "bumpMap")
			_addShaderMapRef coll "map" (getFieldValue mainEntry "map")
			_addShaderMapRef coll "reflectionCubeMap" (getFieldValue mainEntry "reflectionCubeMap")
		)
		default:
		(
			logger.warn "No map collection rule for shader type: {}\n" args:#(shaderType)
		)
	)

	return coll
)

-------------------------------------------------------
-- Shader Resolution
-------------------------------------------------------

struct ShaderTextureResult
(
	shaderIndex,
	shaderName,
	shaderType,
	shaderPath,
	shaderFilePath,
	baseMapPath,       -- tag-relative path of the primary (diffuse) bitmap
	textureFilePath,   -- resolved disk file of the primary bitmap
	success = false,
	shaderEntry,       -- parsed parent 'shader' block tuples (radiosity/physics)
	mainEntry,         -- parsed shader-type block tuples (FULL tag data)
	mapKeys,           -- array of map key strings in tag field order
	mapPaths,          -- Dictionary: map key -> tag-relative bitmap path
	mapFiles           -- Dictionary: map key -> resolved disk texture file (only found ones)
)

fn resolveShaderTexture tagFilePath shaderStruct =
(
	local result = ShaderTextureResult()

	-- Extract the shader tag reference from the parser tuple
	local shaderTagRef = getFieldValue shaderStruct "shader"
	if shaderTagRef == undefined or shaderTagRef[#path] == undefined then
	(
		logger.warn "Shader tag reference missing or has no path\n"
		return result
	)

	local shaderPath = shaderTagRef[#path]
	local pathParts = filterString shaderPath "\\"
	result.shaderName = if pathParts.count > 0 then pathParts[pathParts.count] else "unknown"
	result.shaderType = shaderTagClassToString shaderTagRef[#tagClass]
	result.shaderPath = shaderPath

	local shaderFilePath = buildShaderFilePath tagFilePath shaderPath shaderType:result.shaderType
	if shaderFilePath == undefined then return result
	result.shaderFilePath = shaderFilePath

	local shaderLogPath = "tags\\" + shaderPath + "." + result.shaderType
	if not doesFileExist shaderFilePath then
	(
		logger.warn "Shader not found: '{}'" args:#(shaderLogPath)
		return result
	)
	logger.info "Shader found: '{}'" args:#(shaderLogPath)

	-- Read the FULL shader tag with the generic parser
	local parseInfo = readShaderTagParsed shaderFilePath
	if parseInfo == undefined then return result

	-- Type from the actual file header wins over the referencing tag's class
	if parseInfo[#shaderType] != result.shaderType then
	(
		logger.warn "Shader class mismatch: reference says '{}', file is '{}'" args:#(result.shaderType, parseInfo[#shaderType])
		result.shaderType = parseInfo[#shaderType]
	)

	result.shaderEntry = parseInfo[#shaderEntry]
	result.mainEntry   = parseInfo[#mainEntry]

	-- Collect every bitmap reference and resolve them to disk files
	local coll = collectShaderMapRefs result.shaderType result.mainEntry
	result.mapKeys  = coll.orderedKeys
	result.mapPaths = dictionary #string
	result.mapFiles = dictionary #string

	local foundCount = 0
	for key in coll.orderedKeys do
	(
		local tagPath = shaderTagRefPath (coll.refs[key])
		result.mapPaths[key] = tagPath
		local textureFile = buildTextureFilePath tagFilePath tagPath
		if textureFile != undefined then
		(
			result.mapFiles[key] = textureFile
			foundCount += 1
		)
		else
			logger.debug "  Map '{}': texture not found on disk: 'data\\{}'" args:#(key, tagPath)
	)
	logger.info "Shader '{}' ({}): {} bitmap ref(s), {} texture(s) on disk" args:#(result.shaderName, result.shaderType, coll.orderedKeys.count, foundCount)

	-- Primary (diffuse) map keeps the legacy single-texture behavior
	if coll.primaryKey == undefined then
	(
		logger.warn "No primary map in shader: {}\n" args:#(filenameFromPath shaderFilePath)
		return result
	)
	result.baseMapPath = result.mapPaths[coll.primaryKey]

	local textureFilePath = result.mapFiles[coll.primaryKey]
	if textureFilePath == undefined then
	(
		logger.warn "Texture not found: '{}'" args:#("data\\" + result.baseMapPath)
		return result
	)

	result.textureFilePath = textureFilePath
	result.success = true
	return result
)

fn resolveAllShaderTextures tagFilePath shadersArray =
(
	if shadersArray == undefined or shadersArray.count == 0 then
	(
		logger.info "No shaders to resolve\n"
		return #()
	)
	-- Clear parse cache (tags may have changed on disk since the last import)
	resetShaderResolverCache()

	local results = #()
	for i = 1 to shadersArray.count do
	(
		local result = resolveShaderTexture tagFilePath shadersArray[i]
		result.shaderIndex = i - 1  -- Zero-based to match shader array
		append results result
	)
	return results
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
