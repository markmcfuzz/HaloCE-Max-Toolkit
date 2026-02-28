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

-- Shader Texture Resolver
-- Resolves shader tag references from gbxmodel to actual texture file paths
-- Loads shader modules on-demand (struct + reader) per shader type

-------------------------------------------------------
-- Module initialization flags and paths
-------------------------------------------------------

global _shaderModelModulesLoaded = false
global _shaderChicagoModulesLoaded = false
global _shaderChicagoExtendedModulesLoaded = false
global _shaderGenericModulesLoaded = false
global _shaderGlassModulesLoaded = false
global _shaderMeterModulesLoaded = false
global _shaderWaterModulesLoaded = false
global _shaderModulesPath = undefined

-- Capture the tag/ directory path at load time
if _shaderModulesPath == undefined then
(
	local resolverDir = getFilenamePath (getThisScriptFilename())
	-- Go up one level from gbxmodel/ to tag/
	-- resolverDir ends with "gbxmodel\", we want to go to parent "tag\"
	_shaderModulesPath = getFilenamePath (trimRight resolverDir "\\")
	--logger.debug "Shader modules path: {}" args:#(_shaderModulesPath)
)

-------------------------------------------------------
-- Load shader modules on-demand
-------------------------------------------------------

fn loadShaderModelModules =
(
	if not _shaderModelModulesLoaded and _shaderModulesPath != undefined then
	(
		local sharedStructPath = _shaderModulesPath + "shader\\shader_struct.ms"
		local structPath       = _shaderModulesPath + "shader_model\\tag_struct.ms"
		local readerPath       = _shaderModulesPath + "shader_model\\tag_reader.ms"
		local sharedStructName = getFilenameFile sharedStructPath + getFilenameType sharedStructPath
		local structName       = getFilenameFile structPath + getFilenameType structPath
		local readerName       = getFilenameFile readerPath + getFilenameType readerPath
		
		logger.info "Loading shader model modules:  Shared: {}  Struct: {}  Reader: {}" args:#(sharedStructName, structName, readerName)
		
		if doesFileExist sharedStructPath and doesFileExist structPath and doesFileExist readerPath then
		(
			global readShaderModelTag
			global shaderModelTag
			fileIn sharedStructPath
			fileIn structPath
			fileIn readerPath
			if readShaderModelTag != undefined then
				_shaderModelModulesLoaded = true
		)
		else
		(
			local sharedExists = doesFileExist sharedStructPath
			local structExists = doesFileExist structPath
			local readerExists = doesFileExist readerPath
			logger.error "Shader model module files not found:  Shared exists: {}  Struct exists: {}  Reader exists: {}" args:#(sharedExists, structExists, readerExists)
		)
	)
	if _shaderModelModulesLoaded and readShaderModelTag != undefined then
		return true

	logger.error "Shader model modules not available\n"

	return false
)

fn loadShaderChicagoModules =
(
	if not _shaderChicagoModulesLoaded and _shaderModulesPath != undefined then
	(
		local sharedStructPath = _shaderModulesPath + "shader\\shader_struct.ms"
		local structPath       = _shaderModulesPath + "shader_transparent_chicago\\tag_struct.ms"
		local readerPath       = _shaderModulesPath + "shader_transparent_chicago\\tag_reader.ms"
		local sharedStructName = getFilenameFile sharedStructPath
		local structName       = getFilenameFile structPath	
		local readerName       = getFilenameFile readerPath
		
		logger.info "Loading shader chicago modules:  Shared: {}  Struct: {}  Reader: {}" args:#(sharedStructName, structName, readerName)
		
		if doesFileExist sharedStructPath and doesFileExist structPath and doesFileExist readerPath then
		(
			global readShaderTransparentChicagoTag
			global shaderTransparentChicagoTag
			fileIn sharedStructPath
			fileIn structPath
			fileIn readerPath
			if readShaderTransparentChicagoTag != undefined then
				_shaderChicagoModulesLoaded = true
		)
		else
		(
			local sharedExists = doesFileExist sharedStructPath
			local structExists = doesFileExist structPath
			local readerExists = doesFileExist readerPath
			logger.error "Shader chicago module files not found:  Shared exists: {}  Struct exists: {}  Reader exists: {}" args:#(sharedExists, structExists, readerExists)
		)
	)
	if _shaderChicagoModulesLoaded and readShaderTransparentChicagoTag != undefined then
		return true
	logger.error "Shader transparent chicago modules not available\n"
	return false
)

fn loadShaderChicagoExtendedModules =
(
	if not _shaderChicagoExtendedModulesLoaded and _shaderModulesPath != undefined then
	(
		local sharedStructPath = _shaderModulesPath + "shader\\shader_struct.ms"
		local structPath       = _shaderModulesPath + "shader_transparent_chicago_extended\\tag_struct.ms"
		local readerPath       = _shaderModulesPath + "shader_transparent_chicago_extended\\tag_reader.ms"
		local sharedStructName = getFilenameFile sharedStructPath
		local structName       = getFilenameFile structPath
		local readerName       = getFilenameFile readerPath

		logger.info "Loading shader chicago extended modules:  Shared: {}  Struct: {}  Reader: {}" args:#(sharedStructName, structName, readerName)

		if doesFileExist sharedStructPath and doesFileExist structPath and doesFileExist readerPath then
		(
			global readShaderTransparentChicagoExtendedTag
			global shaderTransparentChicagoExtendedTag
			fileIn sharedStructPath
			fileIn structPath
			fileIn readerPath
			if readShaderTransparentChicagoExtendedTag != undefined then
				_shaderChicagoExtendedModulesLoaded = true
		)
		else
		(
			local sharedExists = doesFileExist sharedStructPath
			local structExists = doesFileExist structPath
			local readerExists = doesFileExist readerPath
			logger.error "Shader chicago extended module files not found:  Shared exists: {}  Struct exists: {}  Reader exists: {}" args:#(sharedExists, structExists, readerExists)
		)
	)
	if _shaderChicagoExtendedModulesLoaded and readShaderTransparentChicagoExtendedTag != undefined then
		return true
	logger.error "Shader transparent chicago extended modules not available\n"
	return false
)

fn loadShaderGenericModules =
(
	if not _shaderGenericModulesLoaded and _shaderModulesPath != undefined then
	(
		local sharedStructPath = _shaderModulesPath + "shader\\shader_struct.ms"
		local structPath       = _shaderModulesPath + "shader_transparent_generic\\tag_struct.ms"
		local readerPath       = _shaderModulesPath + "shader_transparent_generic\\tag_reader.ms"
		local sharedStructName = getFilenameFile sharedStructPath
		local structName       = getFilenameFile structPath
		local readerName       = getFilenameFile readerPath

		logger.info "Loading shader generic modules:  Shared: {}  Struct: {}  Reader: {}" args:#(sharedStructName, structName, readerName)

		if doesFileExist sharedStructPath and doesFileExist structPath and doesFileExist readerPath then
		(
			global readShaderTransparentGenericTag
			global shaderTransparentGenericTag
			fileIn sharedStructPath
			fileIn structPath
			fileIn readerPath
			if readShaderTransparentGenericTag != undefined then
				_shaderGenericModulesLoaded = true
		)
		else
		(
			local sharedExists = doesFileExist sharedStructPath
			local structExists = doesFileExist structPath
			local readerExists = doesFileExist readerPath
			logger.error "Shader generic module files not found:  Shared exists: {}  Struct exists: {}  Reader exists: {}" args:#(sharedExists, structExists, readerExists)
		)
	)
	if _shaderGenericModulesLoaded and readShaderTransparentGenericTag != undefined then
		return true
	logger.error "Shader transparent generic modules not available\n"
	return false
)

fn loadShaderGlassModules =
(
	if not _shaderGlassModulesLoaded and _shaderModulesPath != undefined then
	(
		local sharedStructPath = _shaderModulesPath + "shader\\shader_struct.ms"
		local structPath       = _shaderModulesPath + "shader_transparent_glass\\tag_struct.ms"
		local readerPath       = _shaderModulesPath + "shader_transparent_glass\\tag_reader.ms"
		local sharedStructName = getFilenameFile sharedStructPath
		local structName       = getFilenameFile structPath
		local readerName       = getFilenameFile readerPath

		logger.info "Loading shader glass modules:  Shared: {}  Struct: {}  Reader: {}" args:#(sharedStructName, structName, readerName)

		if doesFileExist sharedStructPath and doesFileExist structPath and doesFileExist readerPath then
		(
			global readShaderTransparentGlassTag
			global shaderTransparentGlassTag
			fileIn sharedStructPath
			fileIn structPath
			fileIn readerPath
			if readShaderTransparentGlassTag != undefined then
				_shaderGlassModulesLoaded = true
		)
		else
		(
			local sharedExists = doesFileExist sharedStructPath
			local structExists = doesFileExist structPath
			local readerExists = doesFileExist readerPath
			logger.error "Shader glass module files not found:  Shared exists: {}  Struct exists: {}  Reader exists: {}" args:#(sharedExists, structExists, readerExists)
		)
	)
	if _shaderGlassModulesLoaded and readShaderTransparentGlassTag != undefined then
		return true
	logger.error "Shader transparent glass modules not available\n"
	return false
)

fn loadShaderMeterModules =
(
	if not _shaderMeterModulesLoaded and _shaderModulesPath != undefined then
	(
		local sharedStructPath = _shaderModulesPath + "shader\\shader_struct.ms"
		local structPath       = _shaderModulesPath + "shader_transparent_meter\\tag_struct.ms"
		local readerPath       = _shaderModulesPath + "shader_transparent_meter\\tag_reader.ms"
		local sharedStructName = getFilenameFile sharedStructPath
		local structName       = getFilenameFile structPath
		local readerName       = getFilenameFile readerPath

		logger.info "Loading shader meter modules:  Shared: {}  Struct: {}  Reader: {}" args:#(sharedStructName, structName, readerName)

		if doesFileExist sharedStructPath and doesFileExist structPath and doesFileExist readerPath then
		(
			global readShaderTransparentMeterTag
			global shaderTransparentMeterTag
			fileIn sharedStructPath
			fileIn structPath
			fileIn readerPath
			if readShaderTransparentMeterTag != undefined then
				_shaderMeterModulesLoaded = true
		)
		else
		(
			local sharedExists = doesFileExist sharedStructPath
			local structExists = doesFileExist structPath
			local readerExists = doesFileExist readerPath
			logger.error "Shader meter module files not found:  Shared exists: {}  Struct exists: {}  Reader exists: {}" args:#(sharedExists, structExists, readerExists)
		)
	)
	if _shaderMeterModulesLoaded and readShaderTransparentMeterTag != undefined then
		return true
	logger.error "Shader transparent meter modules not available\n"
	return false
)

fn loadShaderWaterModules =
(
	if not _shaderWaterModulesLoaded and _shaderModulesPath != undefined then
	(
		local sharedStructPath = _shaderModulesPath + "shader\\shader_struct.ms"
		local structPath       = _shaderModulesPath + "shader_transparent_water\\tag_struct.ms"
		local readerPath       = _shaderModulesPath + "shader_transparent_water\\tag_reader.ms"
		local sharedStructName = getFilenameFile sharedStructPath
		local structName       = getFilenameFile structPath
		local readerName       = getFilenameFile readerPath

		logger.info "Loading shader water modules:  Shared: {}  Struct: {}  Reader: {}" args:#(sharedStructName, structName, readerName)

		if doesFileExist sharedStructPath and doesFileExist structPath and doesFileExist readerPath then
		(
			global readShaderTransparentWaterTag
			global shaderTransparentWaterTag
			fileIn sharedStructPath
			fileIn structPath
			fileIn readerPath
			if readShaderTransparentWaterTag != undefined then
				_shaderWaterModulesLoaded = true
		)
		else
		(
			local sharedExists = doesFileExist sharedStructPath
			local structExists = doesFileExist structPath
			local readerExists = doesFileExist readerPath
			logger.error "Shader water module files not found:  Shared exists: {}  Struct exists: {}  Reader exists: {}" args:#(sharedExists, structExists, readerExists)
		)
	)
	if _shaderWaterModulesLoaded and readShaderTransparentWaterTag != undefined then
		return true
	logger.error "Shader transparent water modules not available\n"
	return false
)

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
		default: "shader_model"
	)
)

-------------------------------------------------------
-- Path Utilities
-------------------------------------------------------

-- Extract tags root from a full gbxmodel path
-- Example: "D:\halo\tags\weapons\rifle\rifle.gbxmodel" -> "D:\halo\tags\"
fn getTagsRootFromGbxmodelPath gbxmodelPath =
(
	if gbxmodelPath == undefined then return undefined
	local tagsPos = findString gbxmodelPath "\\tags\\"
	if tagsPos == undefined then
	(
		tagsPos = findString gbxmodelPath "/tags/"
		if tagsPos == undefined then
		(
			logger.warn "Could not find 'tags' directory in path: {}\n" args:#(gbxmodelPath)
			return undefined
		)
	)
	return substring gbxmodelPath 1 (tagsPos + 5)
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
fn buildShaderFilePath gbxmodelPath shaderRelativePath shaderType:undefined =
(
	if shaderRelativePath == undefined or shaderRelativePath == "" then return undefined
	local tagsRoot = getTagsRootFromGbxmodelPath gbxmodelPath
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
		default:                               ".shader_model"
	)
	return tagsRoot + shaderRelativePath + ext
)

-- Build texture file path (maps tags->data, tries multiple image formats)
fn buildTextureFilePath gbxmodelPath bitmapRelativePath =
(
	if bitmapRelativePath == undefined or bitmapRelativePath == "" or bitmapRelativePath == "NULL" then
		return undefined
	local tagsRoot = getTagsRootFromGbxmodelPath gbxmodelPath
	if tagsRoot == undefined then return undefined
	local dataRoot = convertTagsPathToDataPath tagsRoot
	if dataRoot == undefined then return undefined
	local basePath = dataRoot + bitmapRelativePath
	for ext in #(".tif", ".png", ".bmp", ".dds", ".tga") do
	(
		local fullPath = basePath + ext
		if doesFileExist fullPath then return fullPath
	)
	return undefined
)

-------------------------------------------------------
-- Map Path Getters (per shader type)
-------------------------------------------------------

fn getBaseMapFromShaderModel shaderFilePath =
(
	if not doesFileExist shaderFilePath then
	(
		logger.warn "Shader file not found: {}\n" args:#(shaderFilePath)
		return undefined
	)
	local shaderData = readShaderModelTag shaderFilePath
	if shaderData == undefined then
	(
		logger.error "Failed to read shader_model tag: {}\n" args:#(shaderFilePath)
		return undefined
	)
	local path = shaderData.maps.baseMap.path
	if path == undefined or path == "" or path == "NULL" then
	(
		logger.warn "No base map in shader: {}\n" args:#(filenameFromPath shaderFilePath)
		return undefined
	)
	return path
)

fn getMap1FromChicagoShader shaderFilePath =
(
	if not doesFileExist shaderFilePath then
	(
		logger.warn "Shader file not found: {}\n" args:#(shaderFilePath)
		return undefined
	)
	local shaderData = readShaderTransparentChicagoTag shaderFilePath
	if shaderData == undefined then
	(
		logger.error "Failed to read shader_transparent_chicago tag: {}\n" args:#(shaderFilePath)
		return undefined
	)
	if shaderData.fourStageMap != undefined and shaderData.fourStageMap.count > 0 then
	(
		local map1 = shaderData.fourStageMap[shaderData.fourStageMap.count]
		local path = map1.mapsProps.mapPath.path
		if path != undefined and path != "" and path != "NULL" then return path
	)
	logger.warn "No maps in chicago shader: {}\n" args:#(filenameFromPath shaderFilePath)
	return undefined
)

fn getMap1FromChicagoExtendedShader shaderFilePath =
(
	if not doesFileExist shaderFilePath then
	(
		logger.warn "Shader file not found: {}\n" args:#(shaderFilePath)
		return undefined
	)
	local shaderData = readShaderTransparentChicagoExtendedTag shaderFilePath
	if shaderData == undefined then
	(
		logger.error "Failed to read shader_transparent_chicago_extended tag: {}\n" args:#(shaderFilePath)
		return undefined
	)
	if shaderData.fourStageMap != undefined and shaderData.fourStageMap.count > 0 then
	(
		local map1 = shaderData.fourStageMap[shaderData.fourStageMap.count]
		local path = map1.mapsProps.mapPath.path
		if path != undefined and path != "" and path != "NULL" then return path
	)
	logger.info "No maps in chicago extended shader: {}\n" args:#(filenameFromPath shaderFilePath)
	return undefined
)

fn getMap1FromGenericShader shaderFilePath =
(
	if not doesFileExist shaderFilePath then
	(
		logger.warn "Shader file not found: {}\n" args:#(shaderFilePath)
		return undefined
	)
	local shaderData = readShaderTransparentGenericTag shaderFilePath
	if shaderData == undefined then
	(
		logger.error "Failed to read shader_transparent_generic tag: {}\n" args:#(shaderFilePath)
		return undefined
	)
	if shaderData.maps != undefined and shaderData.maps.count > 0 then
	(
		local map1 = shaderData.maps[shaderData.maps.count]
		local path = map1.mapsProps.mapPath.path
		if path != undefined and path != "" and path != "NULL" then return path
	)
	logger.warn "No maps in generic shader: {}\n" args:#(filenameFromPath shaderFilePath)
	return undefined
)

fn getDiffuseMapFromGlassShader shaderFilePath =
(
	if not doesFileExist shaderFilePath then
	(
		logger.warn "Shader file not found: {}\n" args:#(shaderFilePath)
		return undefined
	)
	local shaderData = readShaderTransparentGlassTag shaderFilePath
	if shaderData == undefined then
	(
		logger.error "Failed to read shader_transparent_glass tag: {}\n" args:#(shaderFilePath)
		return undefined
	)
	local path = shaderData.diffuseProps.diffuseMapPath.path
	if path == undefined or path == "" or path == "NULL" then
	(
		logger.warn "No diffuse map in glass shader: {}\n" args:#(filenameFromPath shaderFilePath)
		return undefined
	)
	return path
)

fn getMeterMapFromMeterShader shaderFilePath =
(
	if not doesFileExist shaderFilePath then
	(
		logger.warn "Shader file not found: {}\n" args:#(shaderFilePath)
		return undefined
	)
	local shaderData = readShaderTransparentMeterTag shaderFilePath
	if shaderData == undefined then
	(
		logger.error "Failed to read shader_transparent_meter tag: {}\n" args:#(shaderFilePath)
		return undefined
	)
	local path = shaderData.meterShader.meterMapPath.path
	if path == undefined or path == "" or path == "NULL" then
	(
		logger.warn "No meter map in meter shader: {}\n" args:#(filenameFromPath shaderFilePath)
		return undefined
	)
	return path
)

fn getBaseMapFromWaterShader shaderFilePath =
(
	if not doesFileExist shaderFilePath then
	(
		logger.warn "Shader file not found: {}\n" args:#(shaderFilePath)
		return undefined
	)
	local shaderData = readShaderTransparentWaterTag shaderFilePath
	if shaderData == undefined then
	(
		logger.error "Failed to read shader_transparent_water tag: {}\n" args:#(shaderFilePath)
		return undefined
	)
	local path = shaderData.waterShader.waterMapPath.path
	if path == undefined or path == "" or path == "NULL" then
	(
		logger.warn "No water map in water shader: {}\n" args:#(filenameFromPath shaderFilePath)
		return undefined
	)
	return path
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
	baseMapPath,
	textureFilePath,
	success = false
)

fn resolveShaderTexture gbxmodelPath shaderStruct =
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
	
	local shaderFilePath = buildShaderFilePath gbxmodelPath shaderPath shaderType:result.shaderType
	if shaderFilePath == undefined then return result
	result.shaderFilePath = shaderFilePath
	
	if not doesFileExist shaderFilePath then
	(
		local tagsDir = "tags\\"
		local shaderLogPath = tagsDir + shaderPath + "." + result.shaderType
		logger.warn "Shader not found: '{}'" args:#(shaderLogPath)
		return result
	)
	else
	(
		local tagsDir = "tags\\"
		local shaderLogPath = tagsDir + shaderPath + "." + result.shaderType
		logger.info "Shader found: '{}'" args:#(shaderLogPath)
	)

	local baseMapPath = undefined
	case result.shaderType of
	(
		"shader_model":
		(
			if loadShaderModelModules() then
				baseMapPath = getBaseMapFromShaderModel shaderFilePath
		)
		"shader_transparent_chicago":
		(
			if loadShaderChicagoModules() then
				baseMapPath = getMap1FromChicagoShader shaderFilePath
		)
		"shader_transparent_chicago_extended":
		(
			if loadShaderChicagoExtendedModules() then
				baseMapPath = getMap1FromChicagoExtendedShader shaderFilePath
		)
		"shader_transparent_generic":
		(
			if loadShaderGenericModules() then
				baseMapPath = getMap1FromGenericShader shaderFilePath
		)
		"shader_transparent_glass":
		(
			if loadShaderGlassModules() then
				baseMapPath = getDiffuseMapFromGlassShader shaderFilePath
		)
		"shader_transparent_meter":
		(
			if loadShaderMeterModules() then
				baseMapPath = getMeterMapFromMeterShader shaderFilePath
		)
		"shader_transparent_water":
		(
			if loadShaderWaterModules() then
				baseMapPath = getBaseMapFromWaterShader shaderFilePath
		)
		default:
		(
			logger.warn "Unsupported shader type: {}\n" args:#(result.shaderType)
			return result
		)
	)

	if baseMapPath == undefined then return result
	result.baseMapPath = baseMapPath

	local textureFilePath = buildTextureFilePath gbxmodelPath baseMapPath
	if textureFilePath == undefined then
	(
		logger.warn "Texture not found: '{}'" args:#("data\\" + baseMapPath)
		return result
	)

	result.textureFilePath = textureFilePath
	result.success = true
	return result
)

fn resolveAllShaderTextures gbxmodelPath shadersArray =
(
	if shadersArray == undefined or shadersArray.count == 0 then
	(
		logger.info "No shaders to resolve\n"
		return #()
	)
	local results = #()
	for i = 1 to shadersArray.count do
	(
		local result = resolveShaderTexture gbxmodelPath shadersArray[i]
		result.shaderIndex = i - 1  -- Zero-based to match shader array
		append results result
	)
	return results
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)