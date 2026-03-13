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
fn readShaderGlassTagHeader = 
(	
	seekToPosition 36
	local tagClass = read.longB "#unsigned"

	seekToPosition 40
	local checksum = read.longB "#unsigned"

	seekToPosition 56
	local version = read.shortB "#unsigned"

	seekToPosition 60
	local engineId = read.longB "#unsigned"

	local expectedFourcc = getFourccByTagName "sgla"
	local gbxmodelFourcc = getFourccByTagName "mod2"
	-- Accept shader_transparent_glass tags, ignore gbxmodel (which may be open during module initialization)
	if tagClass != expectedFourcc then
	(		
		if tagClass != gbxmodelFourcc then
		(			
			logger.error "Invalid tag class. Expected: {}, Found: {}" args:#(expectedFourcc, tagClass)
			return undefined
		)
		-- If it's a gbxmodel, we're likely in preload mode - return undefined silently
		return undefined
	)
    --if tagHeaderLogger then
    --(
    --    logger.log "=== READING TAG HEADER ==="
    --    logger.debug "Tag Class: {}" args:#(getTagClassInfo tagClass)
    --    logger.debug "Checksum: {}" args:#(checksum)
    --    logger.debug "Version: {}" args:#(version)
    --    logger.debug "Engine ID: {}" args:#(getEngineIdInfo engineId)
    --)
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
-- Read Glass Shader Properties
-- Structure at offset 0 within sgla_attrs 
-- (file offset 104), size 2 bytes
-------------------------------------------------------

fn readGlassShaderProperties =
(
    seekToPosition 104
    
    local glassFlagsValue = read.shortB "#unsigned" -- offset 0, 2 bytes
    local glassFlagNames = #(
        "alpha-tested",
        "decal",
        "two-sided",
        "bump map is specular mask"
    )
    local glassFlags = decodeFlagBits glassFlagsValue glassFlagNames
    
    local glassShader = returnGlassShader()
    glassShader.glassFlags = glassFlags

    return glassShader
)

-------------------------------------------------------
-- Read Background Tint Properties
-- Structure at offset 44 within sgla_attrs 
-- (file offset 148), size 32 bytes
-------------------------------------------------------
fn readBackgroundTintProperties =
(
    seekToPosition 148
    
    -- color (offset 0, 12 bytes)
    local tintColorR = read.floatB() -- offset 0, 4 bytes
    local tintColorG = read.floatB() -- offset 4, 4 bytes
    local tintColorB = read.floatB() -- offset 8, 4 bytes
    
    -- map_scale (offset 12, 4 bytes)
    local tintMapScale = read.floatB() -- offset 12, 4 bytes
    
    -- map (TagRef, offset 16, 16 bytes)
    local tintMapTagRef = read.tagRef() -- offset 16, 16 bytes

    -- Now at offset 180 (148 + 32)

    local tintProps = returnBackgroundTintProps()
    tintProps.tintColor = [tintColorR, tintColorG, tintColorB]
    tintProps.tintMapScale = tintMapScale
    tintProps.tintMapPath = tintMapTagRef

    return tintProps
)

-------------------------------------------------------
-- Read Reflection Properties
-- Structure at offset 98 within sgla_attrs
-- (file offset 202), size 70 bytes
-------------------------------------------------------

fn readReflectionProperties =
(
    seekToPosition 202
    
    -- reflection_type (offset 0, 2 bytes)
    local reflectionValue = read.shortB "#signed" -- offset 0, 2 bytes
    local reflectionType = reflectionTypeToString reflectionValue
    -- perpendicular_brightness (offset 2, 4 bytes)
    local perpendicularBrightness = read.floatB() -- offset 2, 4 bytes

    -- perpendicular_tint_color (offset 6, 12 bytes)
    local perpendicularTintR = read.floatB() -- offset 6, 4 bytes
    local perpendicularTintG = read.floatB() -- offset 10, 4 bytes
    local perpendicularTintB = read.floatB() -- offset 14, 4 bytes

    -- parallel_brightness (offset 18, 4 bytes)
    local parallelBrightness = read.floatB() -- offset 18, 4 bytes

    -- parallel_tint_color (offset 22, 12 bytes)
    local parallelTintR = read.floatB() -- offset 22, 4 bytes
    local parallelTintG = read.floatB() -- offset 26, 4 bytes
    local parallelTintB = read.floatB() -- offset 30, 4 bytes

    -- reflection_map (TagRef, offset 34, 16 bytes)
    local reflectionMapTagRef = read.tagRef() -- offset 34, 16 bytes

    -- bump_map_scale (offset 50, 4 bytes)
    local bumpMapScale = read.floatB() -- offset 50, 4 bytes

    -- bump_map (TagRef, offset 54, 16 bytes)
    local bumpMapTagRef = read.tagRef() -- offset 54, 16 bytes

    -- Now at offset 272 (202 + 70)

    local reflectionProps = returnGlassReflectionProps()
    reflectionProps.reflectionType = reflectionType
    reflectionProps.perpendicularBrightness = perpendicularBrightness
    reflectionProps.perpendicularTintColor = [perpendicularTintR, perpendicularTintG, perpendicularTintB]
    reflectionProps.parallelBrightness = parallelBrightness
    reflectionProps.parallelTintColor = [parallelTintR, parallelTintG, parallelTintB]
    reflectionProps.reflectionMapPath = reflectionMapTagRef
    reflectionProps.bumpMapScale = bumpMapScale
    reflectionProps.bumpMapPath = bumpMapTagRef

    return reflectionProps
)

-------------------------------------------------------
-- Read Diffuse Properties
-- Structure at offset 300 within sgla_attrs 
-- (file offset 404), size 40 bytes
-------------------------------------------------------

fn readDiffuseProperties =
(
    seekToPosition 404
    
    -- map_scale (offset 0, 4 bytes)
    local diffuseMapScale = read.floatB() -- offset 0, 4 bytes

    -- map (TagRef, offset 4, 16 bytes)
    local diffuseMapTagRef = read.tagRef() -- offset 4, 16 bytes

    -- detail_map_scale (offset 20, 4 bytes)
    local diffuseDetailMapScale = read.floatB() -- offset 20, 4 bytes

    -- detail_map (TagRef, offset 24, 16 bytes)
    local diffuseDetailMapTagRef = read.tagRef() -- offset 24, 16 bytes

    -- Now at offset 444 (404 + 40)

    local diffuseProps = returnDiffuseProps()
    diffuseProps.diffuseMapScale = diffuseMapScale
    diffuseProps.diffuseMapPath = diffuseMapTagRef
    diffuseProps.diffuseDetailMapScale = diffuseDetailMapScale
    diffuseProps.diffuseDetailMapPath = diffuseDetailMapTagRef

    return diffuseProps
)

-------------------------------------------------------
-- Read Specular Properties
-- Structure at offset 372 within sgla_attrs 
-- (file offset 476), size 40 bytes
-------------------------------------------------------

fn readSpecularProperties =
(
    seekToPosition 476
    
    -- map_scale (offset 0, 4 bytes)
    local specularMapScale = read.floatB() -- offset 0, 4 bytes

    -- map (TagRef, offset 4, 16 bytes)
    local specularMapTagRef = read.tagRef() -- offset 4, 16 bytes

    -- detail_map_scale (offset 20, 4 bytes)
    local specularDetailMapScale = read.floatB() -- offset 20, 4 bytes

    -- detail_map (TagRef, offset 24, 16 bytes)
    local specularDetailMapTagRef = read.tagRef() -- offset 24, 16 bytes

    -- Now at offset 516 (476 + 40)

    local specularProps = returnSpecularProps()
    specularProps.specularMapScale = specularMapScale
    specularProps.specularMapPath = specularMapTagRef
    specularProps.specularDetailMapScale = specularDetailMapScale
    specularProps.specularDetailMapPath = specularDetailMapTagRef

    return specularProps
)

-------------------------------------------------------
-- Main Tagdata Reader Function
-------------------------------------------------------
fn readShaderTransparentGlassTag filePath =
(
	-- Open file
	local fileHandle = fopen filePath "rb"
	if fileHandle == undefined then
	(		
		return undefined
	)
	setFileHandle fileHandle
	in_file = fileHandle
	local tagStruct = shaderTransparentGlassTag()
	local tagHeader = readShaderGlassTagHeader()
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
		logger.error "Failed to read shader attributes"
		fclose fileHandle
		return undefined
	)
	tagStruct.radiosityProperties = shaderAttrs.radProps
	tagStruct.physicsProperties = shaderAttrs.physProps

    -- Read glass shader properties
    local glassShader = readGlassShaderProperties()
    if glassShader == undefined then
    (
        logger.error "Failed to read glass shader properties"
        fclose fileHandle
        return undefined
    )
    tagStruct.glassShader = glassShader

    -- Read background tint properties
    local backgroundTintProps = readBackgroundTintProperties()
    if backgroundTintProps == undefined then
    (
        logger.error "Failed to read background tint properties"
        fclose fileHandle
        return undefined
    )
    tagStruct.backgroundTintProps = backgroundTintProps

    -- Read reflection properties
    local reflectionProps = readReflectionProperties()
    if reflectionProps == undefined then
    (
        logger.error "Failed to read reflection properties"
        fclose fileHandle
        return undefined
    )
    tagStruct.reflectionProps = reflectionProps

    -- Read diffuse properties
    local diffuseProps = readDiffuseProperties()
    if diffuseProps == undefined then
    (
        logger.error "Failed to read diffuse properties"
        fclose fileHandle
        return undefined
    )
    tagStruct.diffuseProps = diffuseProps

    -- Read specular properties
    local specularProps = readSpecularProperties()
    if specularProps == undefined then
    (
        logger.error "Failed to read specular properties"
        fclose fileHandle
        return undefined
    )
    tagStruct.specularProps = specularProps

    -- Read tag reference paths from strings section
    -- Strings start at offset 544 (64 header + 480 tagdata)
    seekToPosition 544
    
    -- Read background tint map path
    if backgroundTintProps.tintMapPath.pathLen > 0 then
    (
        backgroundTintProps.tintMapPath.path = read.nullTerminatedString()
    )
    
    -- Read reflection map path
    if reflectionProps.reflectionMapPath.pathLen > 0 then
    (
        reflectionProps.reflectionMapPath.path = read.nullTerminatedString()
    )
    
    -- Read bump map path
    if reflectionProps.bumpMapPath.pathLen > 0 then
    (
        reflectionProps.bumpMapPath.path = read.nullTerminatedString()
    )
    
    -- Read diffuse map path
    if diffuseProps.diffuseMapPath.pathLen > 0 then
    (
        diffuseProps.diffuseMapPath.path = read.nullTerminatedString()
    )
    
    -- Read diffuse detail map path
    if diffuseProps.diffuseDetailMapPath.pathLen > 0 then
    (
        diffuseProps.diffuseDetailMapPath.path = read.nullTerminatedString()
    )
    
    -- Read specular map path
    if specularProps.specularMapPath.pathLen > 0 then
    (
        specularProps.specularMapPath.path = read.nullTerminatedString()
    )
    
    -- Read specular detail map path
    if specularProps.specularDetailMapPath.pathLen > 0 then
    (
        specularProps.specularDetailMapPath.path = read.nullTerminatedString()
    )

    --if tagHeaderLogger then
    --(
    --    logger.log "=== SHADER TRANSPARENT GLASS SUMMARY ==="
    --    logger.log "Glass Shader:"
    --    logger.info "    - Glass Flags: {}\n" args:#(tagStruct.glassShader.glassFlags)
    --    
    --    logger.log "Background Tint Properties:"
    --    logger.info "    - Tint Color: [{}, {}, {}]" args:#(backgroundTintProps.tintColor[1], backgroundTintProps.tintColor[2], backgroundTintProps.tintColor[3])
    --    logger.info "    - Map Scale: [{}]" args:#(backgroundTintProps.tintMapScale)
    --    logger.info "    - Map Path: '{}'\n" args:#(backgroundTintProps.tintMapPath.path)
    --    
    --    logger.log "Reflection Properties:"
    --    logger.info "    - Reflection Type: ({})" args:#(reflectionProps.reflectionType)
    --    logger.info "    - Perpendicular Brightness: [{}]" args:#(reflectionProps.perpendicularBrightness)
    --    logger.info "    - Perpendicular Tint Color: [{}, {}, {}]" args:#(reflectionProps.perpendicularTintColor[1], reflectionProps.perpendicularTintColor[2], reflectionProps.perpendicularTintColor[3])
    --    logger.info "    - Parallel Brightness: [{}]" args:#(reflectionProps.parallelBrightness)
    --    logger.info "    - Parallel Tint Color: [{}, {}, {}]" args:#(reflectionProps.parallelTintColor[1], reflectionProps.parallelTintColor[2], reflectionProps.parallelTintColor[3])
    --    logger.info "    - Reflection Map Path: '{}'" args:#(reflectionProps.reflectionMapPath.path)
    --    logger.info "    - Bump Map Scale: [{}]" args:#(reflectionProps.bumpMapScale)
    --    logger.info "    - Bump Map Path: '{}'\n" args:#(reflectionProps.bumpMapPath.path)
    --    
    --    logger.log "Diffuse Properties:"
    --    logger.info "    - Map Scale: [{}]" args:#(diffuseProps.diffuseMapScale)
    --    logger.info "    - Map Path: '{}'" args:#(diffuseProps.diffuseMapPath.path)
    --    logger.info "    - Detail Map Scale: [{}]" args:#(diffuseProps.diffuseDetailMapScale)
    --    logger.info "    - Detail Map Path: '{}'\n" args:#(diffuseProps.diffuseDetailMapPath.path)
    --    
    --    logger.log "Specular Properties:"
    --    logger.info "    - Map Scale: [{}]" args:#(specularProps.specularMapScale)
    --    logger.info "    - Map Path: '{}'" args:#(specularProps.specularMapPath.path)
    --    logger.info "    - Detail Map Scale: [{}]" args:#(specularProps.specularDetailMapScale)
    --    logger.info "    - Detail Map Path: '{}'\n\n" args:#(specularProps.specularDetailMapPath.path)
    --)

	fclose fileHandle
	return tagStruct

)