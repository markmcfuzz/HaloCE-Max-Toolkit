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
fn readShaderWaterTagHeader = 
(	
	seekToPosition 36
	local tagClass = read.longB "#unsigned"

	seekToPosition 40
	local checksum = read.longB "#unsigned"

	seekToPosition 56
	local version = read.shortB "#unsigned"

	seekToPosition 60
	local engineId = read.longB "#unsigned"

	local expectedFourcc = getFourccByTagName "swat"
	local gbxmodelFourcc = getFourccByTagName "mod2"
	-- Accept shader_transparent_water tags, ignore gbxmodel (which may be open during module initialization)
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
-- Read Water Shader Properties
-- Structure at offset 0 within swat_attrs
-- (file offset 104, size 188 bytes)
-------------------------------------------------------

fn readWaterShaderProperties =
(
    seekToPosition 104

    -- offset 0, 2 bytes
    local waterFlagsValue = read.shortB "#unsigned"
    local waterFlagNames = #(
        "base map alpha modulates reflection",
        "base map color modulates background",
        "atmospheric fog",
        "draw before fog"
    )
    local waterFlags = decodeFlagBits waterFlagsValue waterFlagNames

    -- Offset 2-35, 34 bytes - padding/unused
    skipBytes 34

    -- offset 36, 16 bytes
    local waterMapTagRef = read.tagRef() 
    -- Now at offset 52 (36 + 16)

    -- offset 52
    skipBytes 16
    -- Now at offset 68

    -- offset 68, 4 bytes
    local perpendicularBrightness = read.floatB()
    -- offset 72, 12 bytes
    local perpendicularTintR = read.floatB()
    local perpendicularTintG = read.floatB()
    local perpendicularTintB = read.floatB()
    local perpendicularTintColor = [perpendicularTintR, perpendicularTintG, perpendicularTintB]
    -- Now at offset 84
    
    -- offset 84, 4 bytes
    local parallelBrightness = read.floatB()
    -- offset 88, 12 bytes
    local parallelTintR = read.floatB()
    local parallelTintG = read.floatB()
    local parallelTintB = read.floatB()
    local parallelTintColor = [parallelTintR, parallelTintG, parallelTintB]
    -- Now at offset 100

    -- offset 100, 16 bytes
    skipBytes 16
    -- Now at offset 116

    -- offset 116, 16 bytes
    local reflectionMapTagRef = read.tagRef()
    -- Now at offset 132

    -- offset 132, 16 bytes
    skipBytes 16
    -- Now at offset 148

    -- offset 148, 4 bytes
    local rippleAnimAngle = read.floatB()
    -- offset 152, 4 bytes
    local rippleAnimVelocity = read.floatB()
    -- offset 156, 4 bytes
    local rippleScale = read.floatB()
    -- offset 160, 16 bytes
    local rippleMapsTagRef = read.tagRef()
    -- offset 176, 2 bytes
    local rippleMipMapLevels = read.shortB "#unsigned"

    -- offset 178, 2 bytes padding
    skipBytes 2
    -- offset 180, 4 bytes
    local rippleMipMapFadeFactor = read.floatB()
    -- offset 184, 4 bytes
    local rippleMipMapDetailBias = read.floatB()

    local waterShader = returnWaterShader()
    waterShader.waterFlags = waterFlags
    waterShader.waterMapPath = waterMapTagRef
    waterShader.perpendicularBrightness = perpendicularBrightness
    waterShader.perpendicularTintColor = perpendicularTintColor
    waterShader.parallelBrightness = parallelBrightness
    waterShader.parallelTintColor = parallelTintColor
    waterShader.reflectionMapPath = reflectionMapTagRef
    waterShader.rippleAnimAngle = rippleAnimAngle
    waterShader.rippleAnimVelocity = rippleAnimVelocity
    waterShader.rippleScale = rippleScale
    waterShader.rippleMapsPath = rippleMapsTagRef
    waterShader.rippleMipMapLevels = rippleMipMapLevels
    waterShader.rippleMipMapFadeFactor = rippleMipMapFadeFactor
    waterShader.rippleMipMapDetailBias = rippleMipMapDetailBias

    return waterShader
)

-------------------------------------------------------
-- Read Reflexive Headers (Ripples)
-- At offset 252 within swat_attrs (file offset 356)
-- Size 12 bytes
-------------------------------------------------------

fn readWaterReflexiveHeaders =
(
    seekToPosition 356

    -- offset 252, 12 bytes
    local ripplesReflexive = read.reflex()

    -- Now at offset 368 (356 + 12)

    local reflexives = returnWaterReflexives()
    reflexives.ripples = ripplesReflexive

    return reflexives
)

-------------------------------------------------------
-- Read Ripples
-------------------------------------------------------

fn readRipples count =
(
    local ripplesArray = #()

    for i = 1 to count do
    (
        -- Each ripple entry is 76 bytes

        skipBytes 4
        
        -- offset 4, 4 bytes
        local contributionFactor = read.floatB()

        skipBytes 32
        
        -- offset 40, 4 bytes
        local animationAngle = read.floatB()
        -- offset 44, 4 bytes
        local animationVelocity = read.floatB()
        -- offset 48, 8 bytes (2 floats)
        local mapOffsetX = read.floatB()
        local mapOffsetY = read.floatB()
        local mapOffset = [mapOffsetX, mapOffsetY]
        -- Now at offset 56
        
        -- offset 56, 2 bytes - map_repeats (UInt16)
        local mapRepeats = read.shortB "#unsigned"
        -- offset 58, 2 bytes - map_index (UInt16)
        local mapIndex = read.shortB "#unsigned"
        -- Now at offset 60
        
        -- offset 60-75, 16 bytes - padding to complete 76 bytes
        skipBytes 16
        -- Now at offset 76 (start of next ripple or end)

        local rippleEntry = returnRipples()
        rippleEntry.contributionFactor = contributionFactor
        rippleEntry.animationAngle = animationAngle
        rippleEntry.animationVelocity = animationVelocity
        rippleEntry.mapOffset = mapOffset
        rippleEntry.mapRepeats = mapRepeats
        rippleEntry.mapIndex = mapIndex

        append ripplesArray rippleEntry
    )

    return ripplesArray
)

-------------------------------------------------------
-- Main Tagdata Reader Function
-------------------------------------------------------
fn readShaderTransparentWaterTag filePath = 
(
    -- Open file
	local fileHandle = fopen filePath "rb"
	if fileHandle == undefined then
	(		
		return undefined
	)
	setFileHandle fileHandle
	in_file = fileHandle
	local tagStruct = shaderTransparentWaterTag()
	local tagHeader = readShaderWaterTagHeader()
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

    -- Read swat_attrs
    local waterShader = readWaterShaderProperties()
    if waterShader == undefined then
    (  
        
        logger "Failed to read water shader properties\n" logType: #error
        fclose fileHandle
        return undefined
    )
    tagStruct.waterShader = waterShader

    -- Read Reflexive Headers
    local reflexives = readWaterReflexiveHeaders()
    if reflexives == undefined then
    (        
        logger "Failed to read water reflexive headers\n" logType: #error
        fclose fileHandle
        return undefined
    )
    tagStruct.ripplesBlock = reflexives.ripples

    -- Calculate string section offset
    -- Base: 64 (header) + 320 (tagdata) = 384
    local baseOffset = 384
    local waterMapStringSize = if waterShader.waterMapPath.pathLen > 0 then waterShader.waterMapPath.pathLen + 1 else 0
    local reflectionMapStringSize = if waterShader.reflectionMapPath.pathLen > 0 then waterShader.reflectionMapPath.pathLen + 1 else 0
    local rippleMapsStringSize = if waterShader.rippleMapsPath.pathLen > 0 then waterShader.rippleMapsPath.pathLen + 1 else 0
    
    -- Read tag reference paths from strings section
    seekToPosition baseOffset
    
    -- Read water base map path
    if waterShader.waterMapPath.pathLen > 0 then
    (
        waterShader.waterMapPath.path = read.nullTerminatedString()
    )
    
    -- Read reflection map path
    if waterShader.reflectionMapPath.pathLen > 0 then
    (
        waterShader.reflectionMapPath.path = read.nullTerminatedString()
    )
    
    -- Read ripple maps path
    if waterShader.rippleMapsPath.pathLen > 0 then
    (
        waterShader.rippleMapsPath.path = read.nullTerminatedString()
    )
    
    -- Read ripples reflexive data if present
    local ripplesArray = #()
    if reflexives.ripples.count > 0 then
    (
        local ripplesDataOffset = baseOffset + waterMapStringSize + reflectionMapStringSize + rippleMapsStringSize
        seekToPosition ripplesDataOffset
        ripplesArray = readRipples reflexives.ripples.count
        tagStruct.ripples = ripplesArray
    )
    
    -- Logger output
    if tagHeaderLogger then
    (
        logger "\n=== SHADER TRANSPARENT WATER DATA ===\n"
        logger "Water Shader:\n"
        logger "    - Glass Flags: %\n" params:#(tagStruct.waterShader.waterFlags)
        logger "    - Base Map Path: '%'\n" params:#(if waterShader.waterMapPath.path != undefined then waterShader.waterMapPath.path else "(NULL)")
        logger "    - Perpendicular Brightness: [%]\n" params:#(waterShader.perpendicularBrightness)
        logger "    - Perpendicular Tint Color: [R= %, G= %, B= %]\n" params:#(waterShader.perpendicularTintColor[1], waterShader.perpendicularTintColor[2], waterShader.perpendicularTintColor[3])
        logger "    - Parallel Brightness: [%]\n" params:#(waterShader.parallelBrightness)
        logger "    - Parallel Tint Color: [R= %, G= %, B= %]\n" params:#(waterShader.parallelTintColor[1], waterShader.parallelTintColor[2], waterShader.parallelTintColor[3])
        logger "    - Reflection Map Path: '%'\n" params:#(if waterShader.reflectionMapPath.path != undefined then waterShader.reflectionMapPath.path else "(NULL)")
        logger "    - Ripple Animation Angle: [%]\n" params:#(radiansToDegrees waterShader.rippleAnimAngle)
        logger "    - Ripple Animation Velocity: [%]\n" params:#(waterShader.rippleAnimVelocity)
        logger "    - Ripple Scale: [%]\n" params:#(waterShader.rippleScale)
        logger "    - Ripple Maps Path: '%'\n" params:#(if waterShader.rippleMapsPath.path != undefined then waterShader.rippleMapsPath.path else "(NULL)")
        logger "    - Ripple Mipmap Levels: [%]\n" params:#(waterShader.rippleMipMapLevels)
        logger "    - Ripple Mipmap Fade Factor: [%]\n" params:#(waterShader.rippleMipMapFadeFactor)
        logger "    - Ripple Mipmap Detail Bias: [%]\n" params:#(waterShader.rippleMipMapDetailBias)
        -- Ripples reflexive
        logger "\nRipples Count: [%]\n" params:#(reflexives.ripples.count)
        if ripplesArray.count > 0 then
        (
            for i = 1 to ripplesArray.count do
            (
                local ripples = ripplesArray[i]
                logger "  Ripple [%]:\n" params:#(i)
                logger "    Contribution Factor: [%]\n" params:#(ripples.contributionFactor)
                logger "    Animation Angle: [%]\n" params:#(radiansToDegrees ripples.animationAngle)
                logger "    Animation Velocity: [%]\n" params:#(ripples.animationVelocity)
                logger "    Map Offset: [i= %, j= %]\n" params:#(ripples.mapOffset[1], ripples.mapOffset[2])
                logger "    Map Repeats: [%]\n" params:#(ripples.mapRepeats)
                logger "    Map Index: [%]\n" params:#(ripples.mapIndex)
            )
        )
        
        logger "\n"
    )

    -- Close file
    fclose fileHandle
    return tagStruct
)