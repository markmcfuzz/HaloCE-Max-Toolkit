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
fn readShaderMeterTagHeader = 
(	
	seekToPosition 36
	local tagClass = read.longB "#unsigned"

	seekToPosition 40
	local checksum = read.longB "#unsigned"

	seekToPosition 56
	local version = read.shortB "#unsigned"

	seekToPosition 60
	local engineId = read.longB "#unsigned"

	local expectedFourcc = getFourccByTagName "smet"
	local gbxmodelFourcc = getFourccByTagName "mod2"
	-- Accept shader_transparent_meter tags, ignore gbxmodel (which may be open during module initialization)
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
-- Read Meter Shader Properties
-- Structure at offset 0 within sgla_attrs 
-- (file offset 104), size 2 bytes
-------------------------------------------------------

fn readMeterShaderProperties = 
(
    seekToPosition 104
    
    -- meter_shader struct at offset 0 within smet_attrs (file offset 104), size 84 bytes
    
    -- Offset 0, 2 bytes - flags
    local meterFlagsValue = read.shortB "#unsigned"
    local meterFlagNames = #(		
        "decal",
        "two-sided",
        "flash color is negative",
        "tint mode 2",
        "unfiltered"
    )
    local meterFlags = decodeFlagBits meterFlagsValue meterFlagNames
    
    -- Offset 2-35, 34 bytes - padding/unused
    skipBytes 34
    
    -- Offset 36-51, 16 bytes - map TagRef
    local meterMapTagRef = read.tagRef()
    
    -- Offset 52-83, 32 bytes - remaining unused space to complete 84-byte struct
    skipBytes 32
    
    -- Now at offset 188 (104 + 84) - start of colors struct
    
    local meterShader = returnMeterShader()
    meterShader.meterFlags = meterFlags
    meterShader.meterMapPath = meterMapTagRef
    
    return meterShader
)

-------------------------------------------------------
-- Read Colors Properties
-- (file offset 188), size 68 bytes
-------------------------------------------------------

fn readColorsProperties = 
(
    seekToPosition 188
    
    -- colors struct, size 68 bytes
    
    -- Offset 0-11, 12 bytes - gradient min color (R,G,B)
    local gradientMinR = read.floatB()
    local gradientMinG = read.floatB()
    local gradientMinB = read.floatB()
    
    -- Offset 12-23, 12 bytes - gradient max color (R,G,B)
    local gradientMaxR = read.floatB()
    local gradientMaxG = read.floatB()
    local gradientMaxB = read.floatB()
    
    -- Offset 24-35, 12 bytes - background color (R,G,B)
    local backgroundR = read.floatB()
    local backgroundG = read.floatB()
    local backgroundB = read.floatB()
    
    -- Offset 36-47, 12 bytes - flash color (R,G,B)
    local flashR = read.floatB()
    local flashG = read.floatB()
    local flashB = read.floatB()
    
    -- Offset 48-59, 12 bytes - tint color (R,G,B)
    local tintR = read.floatB()
    local tintG = read.floatB()
    local tintB = read.floatB()
    
    -- Offset 60, 4 bytes - meter transparency
    local meterTransparency = read.floatB()
    
    -- Offset 64, 4 bytes - background transparency
    local backgroundTransparency = read.floatB()
    
    -- Now at offset 256 (188 + 68) - start of external function source struct
    
    local colors = returnColors()
    colors.gradientMin = [gradientMinR, gradientMinG, gradientMinB]
    colors.gradientMax = [gradientMaxR, gradientMaxG, gradientMaxB]
    colors.background = [backgroundR, backgroundG, backgroundB]
    colors.flash = [flashR, flashG, flashB]
    colors.tint = [tintR, tintG, tintB]
    colors.meterTransparency = meterTransparency
    colors.backgroundTransparency = backgroundTransparency
    
    return colors
)

-------------------------------------------------------
-- Read External Functions Properties
-- Structure at offset 176 within smet_attrs 
-- (file offset 280), size 10 bytes
-- Note: 24 bytes of padding exist between colors 
-- (ends at 256) and this struct (starts at 280)
-------------------------------------------------------

fn readExternalFunctionSource = 
(
    seekToPosition 280
    
    -- Offset 0, 2 bytes - meter brightness source
    local meterBrightnessSource = read.shortB "#signed"
    
    -- Offset 2, 2 bytes - flash brightness source
    local flashBrightnessSource = read.shortB "#signed"
    
    -- Offset 4, 2 bytes - value source
    local valueSource = read.shortB "#signed"
    
    -- Offset 6, 2 bytes - gradient source
    local gradientSource = read.shortB "#signed"
    
    -- Offset 8, 2 bytes - flash extension source
    local flashExtensionSource = read.shortB "#signed"
    
    
    local externalFuncSource = returnExternalFunctionSource()
    externalFuncSource.meterBrightness = meterBrightnessSource
    externalFuncSource.flashBrightness = flashBrightnessSource
    externalFuncSource.valueSource = valueSource
    externalFuncSource.gradientSource = gradientSource
    externalFuncSource.flashExtension = flashExtensionSource
    
    return externalFuncSource
)

-------------------------------------------------------
-- Main Tagdata Reader Function
-------------------------------------------------------

fn readShaderTransparentMeterTag filePath =
(
    -- Open file
	local fileHandle = fopen filePath "rb"
	if fileHandle == undefined then
	(		
		return undefined
	)
	setFileHandle fileHandle
	in_file = fileHandle
	local tagStruct = shaderTransparentMeterTag()
	local tagHeader = readShaderMeterTagHeader()
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

    -- Read meter shader properties
    local meterShader = readMeterShaderProperties()
    if meterShader == undefined then
    (        
        logger "Failed to read meter shader properties\n" logType: #error
        fclose fileHandle
        return undefined
    )
    tagStruct.meterShader = meterShader

    -- Read colors properties
    local colors = readColorsProperties()
    if colors == undefined then
    (        
        logger "Failed to read colors properties\n" logType: #error
        fclose fileHandle
        return undefined
    )
    tagStruct.colors = colors

    -- Read external function source properties
    local externalFuncSource = readExternalFunctionSource()
    if externalFuncSource == undefined then
    (        
        logger "Failed to read external function source properties\n" logType: #error
        fclose fileHandle
        return undefined
    )
    tagStruct.externalFunctionSource = externalFuncSource

    -- Read tag reference paths from strings section
    -- Strings start at offset 324 (64 header + 260 tagdata)

    seekToPosition 324

    -- Read meter shader map mapPath
    if meterShader.meterMapPath.pathLen > 0 then
    (
        meterShader.meterMapPath.path = read.nullTerminatedString()
    )

    if tagHeaderLogger then
    (        
        logger "\n=== SHADER TRANSPARENT METER TAG DATA ===\n"
        logger "Meter Shader Properties:\n"
        logger "  - Flags: %\n" params:#(meterShader.meterFlags)
        logger "  - Map Path: '%'\n\n" params:#(meterShader.meterMapPath.path)
        
        logger "Colors Properties:\n"
        logger "  - Gradient Min Color: R=% G=% B=%\n" params:#(colors.gradientMin[1], colors.gradientMin[2], colors.gradientMin[3])
        logger "  - Gradient Max Color: R=% G=% B=%\n" params:#(colors.gradientMax[1], colors.gradientMax[2], colors.gradientMax[3])
        logger "  - Background Color: R=% G=% B=%\n" params:#(colors.background[1], colors.background[2], colors.background[3])
        logger "  - Flash Color: R=% G=% B=%\n" params:#(colors.flash[1], colors.flash[2], colors.flash[3])
        logger "  - Tint Color: R=% G=% B=%\n" params:#(colors.tint[1], colors.tint[2], colors.tint[3])
        logger "  - Meter Transparency: [%]\n" params:#(colors.meterTransparency)
        logger "  - Background Transparency: [%]\n\n" params:#(colors.backgroundTransparency)
        
        logger "External Function Source Properties:\n"
        logger "  - Meter Brightness Source: (%)\n" params:#(framebufferFadeSourceToString externalFuncSource.meterBrightness)
        logger "  - Flash Brightness Source: (%)\n" params:#(framebufferFadeSourceToString externalFuncSource.flashBrightness)
        logger "  - Value Source: (%)\n" params:#(framebufferFadeSourceToString externalFuncSource.valueSource)
        logger "  - Gradient Source: (%)\n" params:#(framebufferFadeSourceToString externalFuncSource.gradientSource)
        logger "  - Flash Extension Source: (%)\n\n" params:#(framebufferFadeSourceToString externalFuncSource.flashExtension)
    )

	fclose fileHandle
	return tagStruct
)