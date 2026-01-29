------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------
-------------------------------------------------------
-- Tag Header (64 bytes)
-------------------------------------------------------
fn readChicagoTagHeader = 
(	
	seekToPosition 36
	local tagClass = read.longB "#unsigned"
	seekToPosition 40
	local checksum = read.longB "#unsigned"
	seekToPosition 56
	local version = read.shortB "#unsigned"
	seekToPosition 60
	local engineId = read.longB "#unsigned"
	local expectedFourcc = getFourccByTagName "schi"
	local gbxmodelFourcc = getFourccByTagName "mod2"
	-- Accept shader_transparent_chicago tags, ignore gbxmodel (which may be open during module initialization)
	if tagClass != expectedFourcc then
	(		
		if tagClass != gbxmodelFourcc then
		(			
			logger "Invalid tag class. Expected: %, Found: %\n" params: #( expectedFourcc, tagClass ) logType: #error
			return undefined
		)
		-- If it's a gbxmodel, we're likely in preload mode - return undefined silently
		return undefined
	)
	if tagHeaderLogger then
	(		
		logger "\n=== READING TAG HEADER ===\n"
		logger "Tag Class: %\n" params: #( getTagClassInfo tagClass ) logType: #debug
		--logger "Checksum: %\n" params:#(checksum) logType:#debug
		logger "Version: %\n" params: #( version ) logType: #debug
		logger "Engine ID: %\n\n" params: #( getEngineIdInfo engineId ) logType: #debug
	)
	local header = returnHeader()
	header.tagClass = tagClass
	header.checksum = checksum
	header.version = version
	header.engineId = engineId
	return header
)

-------------------------------------------------------
-- Read shdr_attrs (Radiosity & Physics Properties)
-- Structure at offset 64, size 40 bytes
-------------------------------------------------------
fn readShaderAttributes = 
(	
	seekToPosition 64
	-- Read radiosity properties (offset 0-32 within shdr_attrs)
	local radiosityFlagsValue = read.shortB "#unsigned" -- offset 0, 2 bytes
	local radiosityFlagNames = #(		
		"simple parameterization",
		"ignore normals",
		"transparent lit"
	)
	local radiosityFlags = decodeFlagBits radiosityFlagsValue radiosityFlagNames
	local detailLevel = read.shortB "#signed" -- offset 2, 2 bytes
	local lightPower = read.floatB() -- offset 4, 4 bytes
	local lightColorR = read.floatB() -- offset 8, 4 bytes
	local lightColorG = read.floatB() -- offset 12, 4 bytes
	local lightColorB = read.floatB() -- offset 16, 4 bytes
	local tintColorR = read.floatB() -- offset 20, 4 bytes
	local tintColorG = read.floatB() -- offset 24, 4 bytes
	local tintColorB = read.floatB() -- offset 28, 4 bytes
	-- Read material type (offset 34, 2 bytes)
	skipBytes 2 -- skip from offset 32 to 34
	local materialType = read.shortB "#signed" -- offset 34, 2 bytes
	-- Read shader type (offset 36, 2 bytes)
	local shaderType = read.shortB "#signed" -- offset 36, 2 bytes
	-- Skip padding (2 bytes to complete 40 bytes total)
	skipBytes 2
	-- Now at offset 104 (64 + 40)
	-- Create and populate radiosity properties struct
	local radProps = returnRadiosityProperties()
	radProps.flags = radiosityFlags
	radProps.detailLevel = detailLevel
	radProps.lightPower = lightPower
	radProps.lightColor = [lightColorR, lightColorG, lightColorB]
	radProps.tintColor = [tintColorR, tintColorG, tintColorB]
	-- Create and populate physics properties struct
	local physProps = returnPhysicsProperties()
	physProps.materialType = materialType

	local result = shaderAttributesResult()
	result.radProps = radProps
	result.physProps = physProps
	return result
)

-------------------------------------------------------
-- Read Chicago Shader Properties
-- Structure at offset 0 within schi_attrs (file offset 104), size 12 bytes
-------------------------------------------------------

fn readChicagoShaderProperties = 
(	
	-- Should be at offset 104 (64 + 40) when called
	
	local numericCounterLimit = ReadByte in_file #unsigned     -- offset 0, 1 byte
	
	local chicagoFlagsValue = ReadByte in_file #unsigned       -- offset 1, 1 byte
	local chicagoFlagNames = #(
		"alpha tested",
		"decal",
		"two sided",
		"first map is in screenspace",
		"draw before water",
		"ignore effect",
		"scale first map with distance",
		"numeric"
	)
	local chicagoFlags = decodeFlagBits chicagoFlagsValue chicagoFlagNames
	
	local firstMapType = read.shortB "#signed"                  -- offset 2, 2 bytes
	local framebufferBlendFunction = read.shortB "#signed"      -- offset 4, 2 bytes
	local framebufferFadeMode = read.shortB "#signed"           -- offset 6, 2 bytes
	local framebufferFadeSource = read.shortB "#signed"         -- offset 8, 2 bytes
	
	skipBytes 2  -- skip 2 bytes padding to align to 12 bytes
	
	-- Now at offset 116 (104 + 12)
	
	local lensFlareSpacing = read.floatB()                     -- offset 12, 4 bytes
	local lensFlareTagRef = read.tagRef()                      -- offset 16, 16 bytes
	
	-- Now at offset 136 (116 + 4 + 16)
	
	local chicagoShader = returnChicagoShader()
	chicagoShader.numericCounterLimit = numericCounterLimit
	chicagoShader.chicagoFlags = chicagoFlags
	chicagoShader.firstMapType = firstMapType
	chicagoShader.framebufferBlendFunction = framebufferBlendFunction
	chicagoShader.framebufferFadeMode = framebufferFadeMode
	chicagoShader.framebufferFadeSource = framebufferFadeSource
	chicagoShader.lensFlareSpacing = lensFlareSpacing
	chicagoShader.lensFlare = lensFlareTagRef

	return chicagoShader
)

-------------------------------------------------------
-- Read Reflexive Headers (Extra Layers and Maps)
-- At offset 32 within schi_attrs (file offset 136), 
-- size 24 bytes total (2 reflexives)
-------------------------------------------------------

fn readReflexiveHeaders =
(
	seekToPosition 136
	
    -- offset 136, 12 bytes
	local extraLayersReflexive = read.reflex()
    -- offset 148, 12 bytes               
	local mapsReflexive = read.reflex()                         
	
	-- Now at offset 160 (136 + 24)
	
	local reflexives = returnChicagoReflexives()
	reflexives.extraLayers = extraLayersReflexive
	reflexives.fourStageMap = mapsReflexive
	
	return reflexives
)

-------------------------------------------------------
-- Read Extra Layers
-------------------------------------------------------
fn readExtraLayers extraLayersReflexive lensFlarePathLen =
(
	local extraLayers = #()
	local count = extraLayersReflexive.count
	
	if count == 0 then
		return extraLayers
	-- In source tags with pointer=0, reflexive data is stored after strings at offset 172
	-- Calculate where extra layers reflexive data starts
	-- Strings section: ONLY paths with null terminators (no tag class bytes in strings section)
	local lensFlareStringSize = if lensFlarePathLen > 0 then (lensFlarePathLen + 1) else 0
	local extraLayersDataOffset = 172 + lensFlareStringSize
	
	-- Seek to extra layers reflexive data block
	seekToPosition extraLayersDataOffset
	
	-- Read each extra layer tag reference (16 bytes each)
	for i = 1 to count do
	(
		local tagRef = read.tagRef()		
		append extraLayers tagRef
	)
	
	return extraLayers
)

-------------------------------------------------------
-- Read Maps (Four Stage Map)
-------------------------------------------------------
fn readFourStageMaps mapsReflexive lensFlarePathLen extraLayersArray =
(
	local fourStageMaps = #()
	local count = mapsReflexive.count
	
	if count == 0 then
		return fourStageMaps
	
	-- Calculate where maps reflexive data starts
	-- After lens flare string + all extra layer strings
	local lensFlareStringSize = if lensFlarePathLen > 0 then (lensFlarePathLen + 1) else 0
	local extraLayersStringSize = 0
	for i = 1 to extraLayersArray.count do
	(
		if extraLayersArray[i].pathLen > 0 then
			extraLayersStringSize += (extraLayersArray[i].pathLen + 1)
	)
	
	-- Extra layers reflexive data comes before maps reflexive data
    -- Each extra layer tag reference is 16 bytes
	local extraLayersDataSize = extraLayersArray.count * 16  
	local mapsDataOffset = 172 + lensFlareStringSize + extraLayersStringSize + extraLayersDataSize
	
	-- Seek to maps reflexive data block
	seekToPosition mapsDataOffset
	
	-- Read each map structure (220 bytes each)
	for i = 1 to count do
	(
		local mapResult = shaderMapsResult()
		local mapProps = returnFourStageMap()
		
		-- Read flags (offset 0, 2 bytes)
		local flagsValue = read.shortB "#unsigned"
		local flagNames = #("unfiltered", "alpha replicate", "u clamped", "v clamped")
		mapProps.mapFlags = decodeFlagBits flagsValue flagNames
		
		-- Skip to color_function (offset 44, 2 bytes)
		skipBytes 42
		mapProps.colorFunction = read.shortB "#signed"
		
		-- Read alpha_function (offset 46, 2 bytes)
		mapProps.alphaFunction = read.shortB "#signed"
		
		-- Skip to map scales/offsets (offset 84)
		skipBytes 36
		mapProps.mapUScale = read.floatB()          -- offset 84, 4 bytes
		mapProps.mapVScale = read.floatB()          -- offset 88, 4 bytes
		mapProps.mapUOffset = read.floatB()         -- offset 92, 4 bytes
		mapProps.mapVOffset = read.floatB()         -- offset 96, 4 bytes
		mapProps.mapRotation = read.floatB()        -- offset 100, 4 bytes
		mapProps.mipmapBias = read.floatB()         -- offset 104, 4 bytes
		
		-- Read bitmap tag reference (offset 108, 16 bytes)
		mapProps.mapPath = read.tagRef()
		
		-- Read texture animations
		local animProps = returnTextureAnimation()
		
		-- Skip to u_animation (offset 164)
		skipBytes 40
		animProps.uAnimationSource = read.shortB "#signed"      -- offset 0, 2 bytes
		animProps.uAnimationFunction = read.shortB "#signed"    -- offset 2, 2 bytes
		animProps.uAnimationPeriod = read.floatB()              -- offset 4, 4 bytes
		animProps.uAnimationPhase = read.floatB()               -- offset 8, 4 bytes
		animProps.uAnimationScale = read.floatB()               -- offset 12, 4 bytes
		
		-- v_animation (offset 180, 16 bytes) - already positioned
		animProps.vAnimationSource = read.shortB "#signed"
		animProps.vAnimationFunction = read.shortB "#signed"
		animProps.vAnimationPeriod = read.floatB()
		animProps.vAnimationPhase = read.floatB()
		animProps.vAnimationScale = read.floatB()
		
		-- rotation_animation (offset 196, 16 bytes)
		animProps.rotationAnimationSource = read.shortB "#signed"
		animProps.rotationAnimationFunction = read.shortB "#signed"
		animProps.rotationAnimationPeriod = read.floatB()
		animProps.rotationAnimationPhase = read.floatB()
		animProps.rotationAnimationScale = read.floatB()
		
		-- rotation_center (offset 212, 8 bytes)
		local rotCenter = returnRotationCenter()
		rotCenter.x = read.floatB()
		rotCenter.y = read.floatB()
		animProps.rotationAnimationCenter = rotCenter
		
		-- Now at end of structure (220 bytes total)
		
		mapResult.mapsProps = mapProps
		mapResult.animProps = animProps
		
		--if tagHeaderLogger then
		--(
		--	logger "Map %: tag_class=%, path_length=%\n" params:#(i, getTagClassInfo mapProps.mapPath.tagClass, mapProps.mapPath.pathLen) logType:#debug
		--)
		
		append fourStageMaps mapResult
	)

	return fourStageMaps
)

-------------------------------------------------------
-- Main Tagdata Reader Function
-------------------------------------------------------
fn readShaderTransparentChicagoTag filePath = 
(	
	-- Open file
	local fileHandle = fopen filePath "rb"
	if fileHandle == undefined then
	(		
		return undefined
	)
	setFileHandle fileHandle
	in_file = fileHandle
	local tagStruct = shaderTransparentChicagoTag()
	local tagHeader = readChicagoTagHeader()
	if tagHeader == undefined then
	(		
		fclose fileHandle
		return undefined
	)
	tagStruct.header = tagHeader

	-- Read shdr_attrs
	local shaderAttrs = readShaderAttributes()
	if shaderAttrs == undefined then
	(		
		logger "Failed to read shader attributes\n" logType: #error
		fclose fileHandle
		return undefined
	)
	tagStruct.radiosityProperties = shaderAttrs.radProps
	tagStruct.physicsProperties = shaderAttrs.physProps
	
	-- Read chicago shader properties
	local chicagoShader = readChicagoShaderProperties()
	if chicagoShader == undefined then
	(
		logger "Failed to read chicago shader properties\n" logType:#error
		fclose fileHandle
		return undefined
	)
	tagStruct.chicagoShader = chicagoShader
	
	-- Read reflexive headers
	local reflexives = readReflexiveHeaders()
	if reflexives == undefined then
	(
		logger "Failed to read reflexive headers\n" logType:#error
		fclose fileHandle
		return undefined
	)
	tagStruct.extraLayersBlock = reflexives.extraLayers
	tagStruct.fourStageMapBlock = reflexives.fourStageMap
	
	-- Read tag reference paths from strings section
	-- Strings start at offset 172 in source tags
	seekToPosition 172
	
	-- Read lens flare path if it exists
	if chicagoShader.lensFlare.pathLen > 0 then
	(
		chicagoShader.lensFlare.path = read.nullTerminatedString()
	)
	
	-- Read extra layers data (reflexive structures)
	tagStruct.extraLayers = readExtraLayers reflexives.extraLayers chicagoShader.lensFlare.pathLen
	
	-- Read extra layer paths (strings section continues after lens flare)
	for i = 1 to tagStruct.extraLayers.count do
	(
		if tagStruct.extraLayers[i].pathLen > 0 then
		(
			tagStruct.extraLayers[i].path = read.nullTerminatedString()
		)
	)
	
	-- Read four stage maps data (reflexive structures)
	tagStruct.fourStageMap = readFourStageMaps reflexives.fourStageMap chicagoShader.lensFlare.pathLen tagStruct.extraLayers
	
	-- Read map paths (strings section continues after extra layers)
	for i = 1 to tagStruct.fourStageMap.count do
	(
		if tagStruct.fourStageMap[i].mapsProps.mapPath.pathLen > 0 then
		(
			tagStruct.fourStageMap[i].mapsProps.mapPath.path = read.nullTerminatedString()
		)
	)
	
	if tagHeaderLogger then
	(
		logger "\n=== SHADER TRANSPARENT CHICAGO SUMMARY ===\n"
		logger "Chicago Shader:\n"
		logger "    - Numeric Counter Limit: [%]\n" params:#(tagStruct.chicagoShader.numericCounterLimit)
		logger "    - Chicago Flags: %\n" params:#(tagStruct.chicagoShader.chicagoFlags)
		logger "    - First Map Type: (%)\n" params:#(firstMapTypeToString tagStruct.chicagoShader.firstMapType)
		logger "    - Framebuffer Blend Function: (%)\n" params:#(framebufferBlendFunctionToString tagStruct.chicagoShader.framebufferBlendFunction)
		logger "    - Framebuffer Fade Mode: (%)\n" params:#(framebufferFadeModeToString tagStruct.chicagoShader.framebufferFadeMode)
		logger "    - Framebuffer Fade Source: (%)\n" params:#(framebufferFadeSourceToString tagStruct.chicagoShader.framebufferFadeSource)
		logger "    - Lens Flare Spacing: [%]\n" params:#(tagStruct.chicagoShader.lensFlareSpacing)
		logger "    - Lens Flare Path: '%'\n" params:#(tagStruct.chicagoShader.lensFlare.path)
		logger "Extra Layers Count: [%]\n" params:#(tagStruct.extraLayers.count)
		for i = 1 to tagStruct.extraLayers.count do
		(
			logger "    - Layer % Path: '%' | %\n" params:#(i, tagStruct.extraLayers[i].path, getTagClassInfo tagStruct.extraLayers[i].tagClass)
		)
		logger "Maps Count: [%]\n" params:#(tagStruct.fourStageMap.count)
		for i = 1 to tagStruct.fourStageMap.count do
		(
			logger "    - Map % Path: '%'\n" params:#(i, tagStruct.fourStageMap[i].mapsProps.mapPath.path)
		)

        logger "\n\n"
	)

	-- Close file and return tag struct
	fclose fileHandle
	return tagStruct

)