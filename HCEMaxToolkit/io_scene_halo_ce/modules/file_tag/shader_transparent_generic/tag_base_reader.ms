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
fn readShaderGenericTagHeader = 
(	
	seekToPosition 36
	local tagClass = read.longB "#unsigned"
	seekToPosition 40
	local checksum = read.longB "#unsigned"
	seekToPosition 56
	local version = read.shortB "#unsigned"
	seekToPosition 60
	local engineId = read.longB "#unsigned"
	local expectedFourcc = getFourccByTagName "sotr"
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
-- Read Generic Shader Properties
-- Structure at offset 0 within sotr_attrs 
-- (file offset 104), size 12 bytes
-- Total size including padding: 32 bytes
-------------------------------------------------------

fn readGenericShaderProperties =
(
    seekToPosition 104
    -- offset 0, 1 byte
    local numericCounterLimit = ReadByte in_file #unsigned 
    -- offset 1, 1 byte
	local genericFlagsValue = ReadByte in_file #unsigned       
	local genericFlagNames = #(
		"alpha tested",
		"decal",
		"two sided",
		"first map is in screenspace",
		"draw before water",
		"ignore effect",
		"scale first map with distance",
		"numeric"
	)
    local genericFlags = decodeFlagBits genericFlagsValue genericFlagNames
    -- offset 2, 2 bytes
    local firstMapType = read.shortB "#signed"
    -- offset 4, 2 bytes
	local framebufferBlendFunction = read.shortB "#signed"
    -- offset 6, 2 bytes  
	local framebufferFadeMode = read.shortB "#signed"
    -- offset 8, 2 bytes    
	local framebufferFadeSource = read.shortB "#signed"  
    
    -- padding 2 bytes to offset 12
    skipBytes 2  

    -- offset 12, 4 bytes
    local lensFlareSpacing = read.floatB()                     
	-- offset 16, 16 bytes
    local lensFlareTagRef = read.tagRef()

    local genericShader = returnGenericShader()
	genericShader.numericCounterLimit = numericCounterLimit
	genericShader.genericFlags = genericFlags
	genericShader.firstMapType = firstMapType
	genericShader.framebufferBlendFunction = framebufferBlendFunction
	genericShader.framebufferFadeMode = framebufferFadeMode
	genericShader.framebufferFadeSource = framebufferFadeSource
	genericShader.lensFlareSpacing = lensFlareSpacing
	genericShader.lensFlare = lensFlareTagRef

    return genericShader
)

-------------------------------------------------------
-- Read Reflexive Headers (Extra Layers, Maps and Stages)
-- At offset 32 within sotr_attrs (file offset 136)
-- Size 36 bytes total (3 reflexives, 12 bytes each)
------------------------------------------------------- 

fn readReflexiveHeaders =
(
    seekToPosition 136

    -- offset 136, 12 bytes
	local extraLayersReflexive = read.reflex()
    -- offset 148, 12 bytes               
	local mapsReflexive = read.reflex() 
    -- offset 160, 12 bytes               
    local stagesReflexive = read.reflex()

    -- Now at offset 172 (136 + 36)
    local reflexives = returnGenericReflexives()
    reflexives.extraLayers = extraLayersReflexive
    reflexives.maps = mapsReflexive
    reflexives.stages = stagesReflexive

    return reflexives
)

-------------------------------------------------------
-- Read Extra Layers
-- Size 16 bytes each
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
-- Read Maps
-- Size 100 bytes each
-------------------------------------------------------

fn readMaps mapsReflexive lensFlarePathLen extraLayersArray =
(
    local maps = #()
    local count = mapsReflexive.count
    
    if count == 0 then
        return maps

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
    
    -- Read each map structure (48 bytes each)
    for i = 1 to count do
    (
        local mapResult = shaderMapsResult()
		local mapProps = returnMaps()
        -- Read flags (offset 0, 2 bytes)
        local flagsValue = read.shortB "#unsigned"
        local flagNames = #("unfiltered", "u clamped", "v clamped")
        mapProps.mapflags = decodeFlagBits flagsValue flagNames
        -- padding to offset 4
        skipBytes 2
        -- offset 4, 4 bytes
        mapProps.mapUScale = read.floatB()
        -- offset 8, 4 bytes
        mapProps.mapVScale = read.floatB()
        -- offset 12, 4 bytes
        mapProps.mapUOffset = read.floatB()
        -- offset 16, 4 bytes
        mapProps.mapVOffset = read.floatB()
        -- offset 20, 4 bytes
        mapProps.mapRotation = read.floatB()
        -- offset 24, 4 bytes
        mapProps.mipmapBias = read.floatB()
        -- offset 28, 16 bytes
        mapProps.mapPath = read.tagRef()

        -- Read texture animations
        local animProps = returnTextureAnimation()

        -- offset 44, Size 16 bytes, total (5 entries)
        -- offset 0, 2 bytes
        animProps.uAnimationSource = read.shortB "#signed"
        -- offset 2, 2 bytes
        animProps.uAnimationFunction = read.shortB "#signed"
        -- offset 4, 4 bytes
        animProps.uAnimationPeriod = read.floatB()
        -- offset 8, 4 bytes
        animProps.uAnimationPhase = read.floatB()
        -- offset 12, 4 bytes
        animProps.uAnimationScale = read.floatB()

        -- offset 60, Size 16 bytes
        animProps.vAnimationSource = read.shortB "#signed"
        animProps.vAnimationFunction = read.shortB "#signed"
        animProps.vAnimationPeriod = read.floatB()
        animProps.vAnimationPhase = read.floatB()
        animProps.vAnimationScale = read.floatB()

        -- offset 76, Size 16 bytes
        animProps.rotationAnimationSource = read.shortB "#signed"
        animProps.rotationAnimationFunction = read.shortB "#signed"
        animProps.rotationAnimationPeriod = read.floatB()
        animProps.rotationAnimationPhase = read.floatB()
        animProps.rotationAnimationScale = read.floatB()

        -- offset 92, Size 8 bytes
        local rotCenter = returnRotationCenter()
		rotCenter.x = read.floatB()
		rotCenter.y = read.floatB()
		animProps.rotationAnimationCenter = rotCenter

        -- Now at end of structure (100 bytes total)

		mapResult.mapsProps = mapProps
		mapResult.animProps = animProps
        
        append maps mapResult
    )
    
    return maps
)

-------------------------------------------------------
-- Read Stages
-- Size 112 bytes each
-------------------------------------------------------

fn readStages stagesReflexive lensFlarePathLen extraLayersArray mapsReflexive mapsArray =
(
    local stages = #()
    local count = stagesReflexive.count
    
    if count == 0 then
        return stages

    -- Calculate where stages reflexive data starts
    -- After lens flare string + all extra layer strings + extra layers data + maps strings + maps data
    local lensFlareStringSize = if lensFlarePathLen > 0 then (lensFlarePathLen + 1) else 0
    local extraLayersStringSize = 0
    for i = 1 to extraLayersArray.count do
    (
        if extraLayersArray[i].pathLen > 0 then
            extraLayersStringSize += (extraLayersArray[i].pathLen + 1)
    )
    
    -- Calculate maps strings size
    local mapsStringSize = 0
    for i = 1 to mapsArray.count do
    (
        if mapsArray[i].mapsProps.mapPath.pathLen > 0 then
            mapsStringSize += (mapsArray[i].mapsProps.mapPath.pathLen + 1)
    )

    -- Calculate Reflexive data sizes
    local extraLayersDataSize = extraLayersArray.count * 16
    local mapsDataSize = mapsReflexive.count * 100
    local stagesDataOffset = 172 + lensFlareStringSize + extraLayersStringSize + extraLayersDataSize + mapsStringSize + mapsDataSize

    -- Seek to stages reflexive data block
    seekToPosition stagesDataOffset

    -- Read each stage structure (112 bytes each)
    for i = 1 to count do
    (
        local mapResult = shaderMapsResult()
        local stageProps = returnStages()

        -- Read flags (offset 0, 2 bytes)
        local flagsValue = read.shortB "#unsigned"
        local flagNames = #("color_mux", "alpha_mux", "a_out_controls_color")
        stageProps.flags = decodeFlagBits flagsValue flagNames
        -- Padding to offset 4
        skipBytes 2
        -- offset 4, 2 bytes
        stageProps.color0Source = read.shortB "#signed"
        -- offset 6, 2 bytes
        stageProps.color0AnimFunction = read.shortB "#signed"
        -- offset 8, 4 bytes
        stageProps.color0AnimPeriod = read.floatB()
        -- offset 12, 16 bytes
        local color0AnimLowerBoundA = read.floatB()
        local color0AnimLowerBoundR = read.floatB()
        local color0AnimLowerBoundG = read.floatB()
        local color0AnimLowerBoundB = read.floatB()
        stageProps.color0AnimLowerBound = [color0AnimLowerBoundA, color0AnimLowerBoundR, color0AnimLowerBoundG, color0AnimLowerBoundB] 
        -- offset 28, 16 bytes
        local color0AnimUpperBoundA = read.floatB()
        local color0AnimUpperBoundR = read.floatB()
        local color0AnimUpperBoundG = read.floatB()
        local color0AnimUpperBoundB = read.floatB()
        stageProps.color0AnimUpperBound = [color0AnimUpperBoundA, color0AnimUpperBoundR, color0AnimUpperBoundG, color0AnimUpperBoundB]
        -- offset 44, 16 bytes
        local color1A = read.floatB()
        local color1R = read.floatB()
        local color1G = read.floatB()
        local color1B = read.floatB()
        stageProps.color1 = [color1A, color1R, color1G, color1B]
        
        -- Color Properties sub-structure
        -- offset 60, 28 bytes
        stageProps.colorProps = stageColorProperties()
        -- offset 0, 4 bytes
        stageProps.colorProps.inputA = read.shortB "#signed"
        stageProps.colorProps.inputAMapping = read.shortB "#signed"
        -- offset 4, 4 bytes
        stageProps.colorProps.inputB = read.shortB "#signed"
        stageProps.colorProps.inputBMapping = read.shortB "#signed"
        -- offset 8, 4 bytes
        stageProps.colorProps.inputC = read.shortB "#signed"
        stageProps.colorProps.inputCMapping = read.shortB "#signed"
        -- offset 12, 4 bytes
        stageProps.colorProps.inputD = read.shortB "#signed"
        stageProps.colorProps.inputDMapping = read.shortB "#signed"
        -- offset 16, 4 bytes
        stageProps.colorProps.outputAB = read.shortB "#signed"
        stageProps.colorProps.outputABFunction = read.shortB "#signed"
        -- offset 20, 4 bytes
        stageProps.colorProps.outputCD = read.shortB "#signed"
        stageProps.colorProps.outputCDFunction = read.shortB "#signed"
        -- offset 24, 2 bytes
        stageProps.colorProps.outputABCDMuxSum = read.shortB "#signed"
        -- offset 26, 2 bytes
        stageProps.colorProps.outputMapping = read.shortB "#signed"
        
        -- Alpha Properties sub-structure
        -- offset 88, 24 bytes
        stageProps.alphaProps = stageAlphaProperties()
        -- offset 0, 4 bytes
        stageProps.alphaProps.inputA = read.shortB "#signed"
        stageProps.alphaProps.inputAMapping = read.shortB "#signed"
        -- offset 4, 4 bytes
        stageProps.alphaProps.inputB = read.shortB "#signed"
        stageProps.alphaProps.inputBMapping = read.shortB "#signed"
        -- offset 8, 4 bytes
        stageProps.alphaProps.inputC = read.shortB "#signed"
        stageProps.alphaProps.inputCMapping = read.shortB "#signed"
        -- offset 12, 4 bytes
        stageProps.alphaProps.inputD = read.shortB "#signed"
        stageProps.alphaProps.inputDMapping = read.shortB "#signed"
        -- offset 16, 2 bytes
        stageProps.alphaProps.outputAB = read.shortB "#signed"
        -- offset 18, 2 bytes
        stageProps.alphaProps.outputCD = read.shortB "#signed"
        -- offset 20, 2 bytes
        stageProps.alphaProps.outputABCDMuxSum = read.shortB "#signed"
        -- offset 22, 2 bytes
        stageProps.alphaProps.outputMapping = read.shortB "#signed"

        -- Now at end of structure (112 bytes total)

        mapResult.stageProps = stageProps

        append stages mapResult
    )

    return stages
)

-------------------------------------------------------
-- Main Tagdata Reader Function
-------------------------------------------------------

fn readShaderTransparentGenericTag filePath =
(
    -- Open file
	local fileHandle = fopen filePath "rb"
	if fileHandle == undefined then
	(		
		return undefined
	)
	setFileHandle fileHandle
	in_file = fileHandle

	local tagStruct = shaderTransparentGenericTag()
	local tagHeader = readShaderGenericTagHeader()

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

    -- Read generic shader properties
    local genericShader = readGenericShaderProperties()
    if genericShader == undefined then
    (        
        logger "Failed to read generic shader properties\n" logType: #error
        fclose fileHandle
        return undefined
    )
    tagStruct.genericShader = genericShader

    -- Read reflexive headers
    local reflexives = readReflexiveHeaders()
    if reflexives == undefined then
    (        
        logger "Failed to read reflexive headers\n" logType: #error
        fclose fileHandle
        return undefined
    )
    tagStruct.extraLayersBlock = reflexives.extraLayers
    tagStruct.mapsBlock = reflexives.maps
    tagStruct.stagesBlock = reflexives.stages

    -- Read tag reference paths from strings section
    -- Strings start at offset 172 (64 header + 108 tagdata)
    seekToPosition 172

    -- Read lens flare path if it exist
    if genericShader.lensFlare.pathLen > 0 then
    (
        genericShader.lensFlare.path = read.nullTerminatedString()
    )

    -- Read extra layers data (reflexive structures)
    tagStruct.extraLayers = readExtraLayers reflexives.extraLayers genericShader.lensFlare.pathLen

    -- Read extra layer paths (strings section continues after lens flare)
    for i = 1 to tagStruct.extraLayers.count do
    (
        local layerRef = tagStruct.extraLayers[i]
        if layerRef.pathLen > 0 then
        (
            layerRef.path = read.nullTerminatedString()
        )
    )

    -- Read maps data (reflexive structures)
    tagStruct.maps = readMaps reflexives.maps genericShader.lensFlare.pathLen tagStruct.extraLayers

    -- Read map paths (strings section continues after extra layers)
    for i = 1 to tagStruct.maps.count do
    (
        if tagStruct.maps[i].mapsProps.mapPath.pathLen> 0 then
        (
            tagStruct.maps[i].mapsProps.mapPath.path = read.nullTerminatedString()
        )
    )

    -- Read stages data (reflexive structures)
    tagStruct.stages = readStages reflexives.stages genericShader.lensFlare.pathLen tagStruct.extraLayers reflexives.maps tagStruct.maps

    if tagHeaderLogger then
    (
        logger "\n=== SHADER TRANSPARENT GENERIC SUMMARY ===\n"
        logger "Generic Shader:\n"
        logger "    - Numeric Counter Limit: [%]\n" params:#(tagStruct.genericShader.numericCounterLimit)
        logger "    - Generic Flags: %\n" params:#(tagStruct.genericShader.genericFlags)
        logger "    - First Map Type: (%)\n" params:#(firstMapTypeToString tagStruct.genericShader.firstMapType)
        logger "    - Framebuffer Blend Function: (%)\n" params:#(framebufferBlendFunctionToString tagStruct.genericShader.framebufferBlendFunction)
        logger "    - Framebuffer Fade Mode: (%)\n" params:#(framebufferFadeModeToString tagStruct.genericShader.framebufferFadeMode)
        logger "    - Framebuffer Fade Source: (%)\n" params:#(framebufferFadeSourceToString tagStruct.genericShader.framebufferFadeSource)
        logger "    - Lens Flare Spacing: [%]\n" params:#(tagStruct.genericShader.lensFlareSpacing)
        logger "    - Lens Flare Path: '%'\n" params:#(tagStruct.genericShader.lensFlare.path)
        
        logger "Extra Layers Count: [%]\n" params:#(tagStruct.extraLayers.count)
        for i = 1 to tagStruct.extraLayers.count do
        (
            logger "    - Layer % Path: '%' | %\n" params:#(i, tagStruct.extraLayers[i].path, getTagClassInfo tagStruct.extraLayers[i].tagClass)
        )
        
        logger "Maps Count: [%]\n" params:#(tagStruct.maps.count)
        for i = 1 to tagStruct.maps.count do
        (
            local map = tagStruct.maps[i]
            logger "    - Map %:\n" params:#(i)
            --logger "        Flags: %\n" params:#(map.mapsProps.mapFlags)
            --logger "        Scale: U=% V=%\n" params:#(map.mapsProps.mapUScale, map.mapsProps.mapVScale)
            --logger "        Offset: U=% V=%\n" params:#(map.mapsProps.mapUOffset, map.mapsProps.mapVOffset)
            --logger "        Rotation: [%]\n" params:#(map.mapsProps.mapRotation)
            --logger "        Mipmap Bias: [%]\n" params:#(map.mapsProps.mipmapBias)
            logger "        Bitmap Path: '%'\n" params:#(map.mapsProps.mapPath.path)
            --logger "        U Animation: Source=% Function=% Period=%\n" params:#(sourceBlockToString map.animProps.uAnimationSource, animFunctionToString map.animProps.uAnimationFunction, map.animProps.uAnimationPeriod)
            --logger "        V Animation: Source=% Function=% Period=%\n" params:#(sourceBlockToString map.animProps.vAnimationSource, animFunctionToString map.animProps.vAnimationFunction, map.animProps.vAnimationPeriod)
            --logger "        Rotation Animation: Source=% Function=% Period=%\n" params:#(sourceBlockToString map.animProps.rotationAnimationSource, animFunctionToString map.animProps.rotationAnimationFunction, map.animProps.rotationAnimationPeriod)
        )
        logger "Stages Count: [%]\n" params:#(tagStruct.stages.count)
        --for i = 1 to tagStruct.stages.count do
        --(
        --    local stage = tagStruct.stages[i]
        --    logger "    - Stage %:\n" params:#(i)
        --    logger "        Flags: %\n" params:#(stage.stageProps.flags)
        --    logger "        Color0 Source: (%)\n" params:#(sourceBlockToString stage.stageProps.color0Source)
        --    logger "        Color0 Animation Function: (%)\n" params:#(animFunctionToString stage.stageProps.color0AnimFunction)
        --    logger "        Color0 Animation Period: [%]\n" params:#(stage.stageProps.color0AnimPeriod)
        --    logger "        Color0 Lower Bound: A=% R=% G=% B=%\n" params:#(stage.stageProps.color0AnimLowerBound[1], stage.stageProps.color0AnimLowerBound[2], stage.stageProps.color0AnimLowerBound[3], stage.stageProps.color0AnimLowerBound[4])
        --    logger "        Color0 Upper Bound: A=% R=% G=% B=%\n" params:#(stage.stageProps.color0AnimUpperBound[1], stage.stageProps.color0AnimUpperBound[2], stage.stageProps.color0AnimUpperBound[3], stage.stageProps.color0AnimUpperBound[4])
        --    logger "        Color1: A=% R=% G=% B=%\n" params:#(stage.stageProps.color1[1], stage.stageProps.color1[2], stage.stageProps.color1[3], stage.stageProps.color1[4])
        --    logger "        Color Inputs: A=(% | %) B=(% | %) C=(% | %) D=(% | %)\n" params:#(colorInputToString stage.stageProps.colorProps.inputA, colorInputMappingToString stage.stageProps.colorProps.inputAMapping, colorInputToString stage.stageProps.colorProps.inputB, colorInputMappingToString stage.stageProps.colorProps.inputBMapping, colorInputToString stage.stageProps.colorProps.inputC, colorInputMappingToString stage.stageProps.colorProps.inputCMapping, colorInputToString stage.stageProps.colorProps.inputD, colorInputMappingToString stage.stageProps.colorProps.inputDMapping)
        --    logger "        Color Outputs: AB=(% | %) CD=(% | %) Mux/Sum=% Mapping=%\n" params:#(colorOutputToString stage.stageProps.colorProps.outputAB, colorOutputFunctionToString stage.stageProps.colorProps.outputABFunction, colorOutputToString stage.stageProps.colorProps.outputCD, colorOutputFunctionToString stage.stageProps.colorProps.outputCDFunction, colorOutputToString stage.stageProps.colorProps.outputABCDMuxSum, colorOutputMappingToString stage.stageProps.colorProps.outputMapping)
        --    logger "        Alpha Inputs: A=(% | %) B=(% | %) C=(% | %) D=(% | %)\n" params:#(colorInputToString stage.stageProps.alphaProps.inputA, colorInputMappingToString stage.stageProps.alphaProps.inputAMapping, colorInputToString stage.stageProps.alphaProps.inputB, colorInputMappingToString stage.stageProps.alphaProps.inputBMapping, colorInputToString stage.stageProps.alphaProps.inputC, colorInputMappingToString stage.stageProps.alphaProps.inputCMapping, colorInputToString stage.stageProps.alphaProps.inputD, colorInputMappingToString stage.stageProps.alphaProps.inputDMapping)
        --    logger "        Alpha Outputs: AB=% CD=% Mux/Sum=% Mapping=%\n" params:#(colorOutputToString stage.stageProps.alphaProps.outputAB, colorOutputToString stage.stageProps.alphaProps.outputCD, colorOutputToString stage.stageProps.alphaProps.outputABCDMuxSum, colorOutputMappingToString stage.stageProps.alphaProps.outputMapping)
        --)
        logger "\n"
    )

    -- Close file and return tag struct
	fclose fileHandle
	return tagStruct
)