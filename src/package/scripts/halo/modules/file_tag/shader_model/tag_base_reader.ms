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

fn readTagHeader = 
(
    seekToPosition 36
    local tagClass = read.longB "#unsigned"
    
    seekToPosition 40
    local checksum = read.longB "#unsigned"
    
    seekToPosition 56
    local version = read.shortB "#unsigned"
    
    seekToPosition 60
    local engineId = read.longB "#unsigned"
    
    local expectedFourcc = getFourccByTagName "soso"
    local gbxmodelFourcc = getFourccByTagName "mod2"
    
    -- Accept shader_model tags, ignore gbxmodel (which may be open during module initialization)
    if tagClass != expectedFourcc then
    (
        if tagClass != gbxmodelFourcc then
        (
            logger "Invalid tag class. Expected: %, Found: %\n" params:#(expectedFourcc, tagClass) logType:#error
            return undefined
        )
        -- If it's a gbxmodel, we're likely in preload mode - return undefined silently
        return undefined
    )
    
    if tagHeaderLogger then
    (
        logger "\n=== READING TAG HEADER ===\n"
        logger "Tag Class: %\n" params:#(getTagClassInfo tagClass) logType:#debug
        --logger "Checksum: %\n" params:#(checksum) logType:#debug
        logger "Version: %\n" params:#(version) logType:#debug
        logger "Engine ID: %\n\n" params:#(getEngineIdInfo engineId) logType:#debug
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
    local radiosityFlagsValue = read.shortB "#unsigned"              -- offset 0, 2 bytes
    local radiosityFlagNames = #(
        "simple parameterization",
        "ignore normals",
        "transparent lit"
    )
    local radiosityFlags = decodeFlagBits radiosityFlagsValue radiosityFlagNames

    local detailLevel = read.shortB "#signed"                   -- offset 2, 2 bytes
    local lightPower = read.floatB()                            -- offset 4, 4 bytes
    local lightColorR = read.floatB()                           -- offset 8, 4 bytes
    local lightColorG = read.floatB()                           -- offset 12, 4 bytes
    local lightColorB = read.floatB()                           -- offset 16, 4 bytes
    local tintColorR = read.floatB()                            -- offset 20, 4 bytes
    local tintColorG = read.floatB()                            -- offset 24, 4 bytes
    local tintColorB = read.floatB()                            -- offset 28, 4 bytes
    
    -- Read material type (offset 34, 2 bytes)
    skipBytes 2  -- skip from offset 32 to 34
    local materialType = read.shortB "#signed"                  -- offset 34, 2 bytes
    
    -- Read shader type (offset 36, 2 bytes)
    local shaderType = read.shortB "#signed"                    -- offset 36, 2 bytes
    
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
    
    -- Create result struct
    local result = shaderAttributesResult()
    result.radProps = radProps
    result.physProps = physProps
    
    return result
)

-------------------------------------------------------
-- Read Model Shader Properties
-- Structure at offset 0 within soso_attrs (file offset 104), size 20 bytes
-------------------------------------------------------

fn readModelShaderProperties =
(
    -- Should be at offset 104 (64 + 40) when called
    
    local flagsValue = read.shortB "#unsigned"                       -- offset 0, 2 bytes
    local flagNames = #(
        "detail after reflection",
        "two-sided",
        "not alpha-tested",
        "alpha-blended decal",
        "true atmospheric fog",
        "disable two-sided culling"
    )
    local flags = decodeFlagBits flagsValue flagNames
    skipBytes 14                                                -- offset 2-16, padding
    local translucency = read.floatB()                          -- offset 16, 4 bytes
    
    -- Now at offset 124 (104 + 20)
    
    local modelShader = returnModelShader()
    modelShader.flags = flags
    modelShader.translucency = translucency
    
    return modelShader
)

-------------------------------------------------------
-- Read Color Change Properties
-- At offset 36 within soso_attrs (file offset 140), size 2 bytes
-------------------------------------------------------

fn readColorChangeProperties =
(
    -- Now at offset 124, need to skip to 140
    -- Skip 16 bytes (124 + 16 = 140)
    skipBytes 16
    
    local changeColorSource = read.shortB "#signed"             -- offset 36, 2 bytes
    
    -- Now at offset 142 (140 + 2)
    
    local changeColor = returnChangeColor()
    changeColor.changeColorSource = changeColorSource
    
    return changeColor
)

-------------------------------------------------------
-- Read Self Illumination Properties
-- At offset 68 within soso_attrs (file offset 172), size 36 bytes
-------------------------------------------------------

fn readSelfIlluminationProperties =
(
    -- Now at offset 142, need to skip to 172
    -- Skip 30 bytes (142 + 30 = 172)
    skipBytes 30
    
    local flagsValue = read.shortB "#unsigned"                       -- offset 0, 2 bytes
    local flags = if flagsValue > 0 then ("no random phase") else ("Null") 
    skipBytes 2                                                 -- offset 2, 2 bytes padding
    local colorSource = read.shortB "#signed"                   -- offset 4, 2 bytes
    local animationFunction = read.shortB "#signed"             -- offset 6, 2 bytes
    local animationPeriod = read.floatB()                       -- offset 8, 4 bytes
    local colorLowerR = read.floatB()                           -- offset 12, 4 bytes
    local colorLowerG = read.floatB()                           -- offset 16, 4 bytes
    local colorLowerB = read.floatB()                           -- offset 20, 4 bytes
    local colorUpperR = read.floatB()                           -- offset 24, 4 bytes
    local colorUpperG = read.floatB()                           -- offset 28, 4 bytes
    local colorUpperB = read.floatB()                           -- offset 32, 4 bytes
    
    -- Now at offset 208 (172 + 36)
    
    local selfIllum = returnSelfIllumination()
    selfIllum.flags = flags
    selfIllum.colorSource = colorSource
    selfIllum.animationFunction = animationFunction
    selfIllum.animationPeriod = animationPeriod
    selfIllum.animColorLowerBound = [colorLowerR, colorLowerG, colorLowerB]
    selfIllum.animColorUpperBound = [colorUpperR, colorUpperG, colorUpperB]
    
    return selfIllum
)

-------------------------------------------------------
-- Read Maps Properties
-- At offset 116 within soso_attrs (file offset 220), size 84 bytes
-------------------------------------------------------

fn readMapsProperties =
(
    -- Now at offset 208, need to skip to 220
    -- Skip 12 bytes (208 + 12 = 220)
    skipBytes 12
    
    local mapUScale = read.floatB()                             -- offset 0, 4 bytes
    local mapVScale = read.floatB()                             -- offset 4, 4 bytes
    local diffuseMap = read.tagRef()                            -- offset 8, 16 bytes
    skipBytes 8                                                 -- offset 24, 8 bytes padding
    local multipurposeMap = read.tagRef()                       -- offset 32, 16 bytes
    skipBytes 8                                                 -- offset 48, 8 bytes padding
    local detailFunction = read.shortB "#signed"                -- offset 56, 2 bytes
    local detailMask = read.shortB "#signed"                    -- offset 58, 2 bytes
    local detailMapScale = read.floatB()                        -- offset 60, 4 bytes
    local detailMap = read.tagRef()                             -- offset 64, 16 bytes
    local detailMapVScale = read.floatB()                       -- offset 80, 4 bytes
    
    -- Now at offset 304 (220 + 84)
    
    local maps = returnMaps()
    maps.mapUScale = mapUScale
    maps.mapVScale = mapVScale
    maps.baseMap = diffuseMap
    maps.multipurposeMap = multipurposeMap
    maps.detailFunction = detailFunction
    maps.detailMask = detailMask
    maps.detailMapScale = detailMapScale
    maps.detailMap = detailMap
    maps.detailMapVScale = detailMapVScale
    
    return maps
)

-------------------------------------------------------
-- Read Texture Animation Properties
-- At offset 212 within soso_attrs (file offset 316), size 56 bytes
-------------------------------------------------------

fn readTextureAnimationProperties =
(
    -- Now at offset 304, need to skip to 316
    -- Skip 12 bytes (304 + 12 = 316)
    skipBytes 12
    
    -- U animation (offset 0, size 16)
    local uAnimSource = read.shortB "#signed"
    local uAnimFunction = read.shortB "#signed"
    local uAnimPeriod = read.floatB()
    local uAnimPhase = read.floatB()
    local uAnimScale = read.floatB()
    
    -- V animation (offset 16, size 16)
    local vAnimSource = read.shortB "#signed"
    local vAnimFunction = read.shortB "#signed"
    local vAnimPeriod = read.floatB()
    local vAnimPhase = read.floatB()
    local vAnimScale = read.floatB()
    
    -- Rotation animation (offset 32, size 16)
    local rotAnimSource = read.shortB "#signed"
    local rotAnimFunction = read.shortB "#signed"
    local rotAnimPeriod = read.floatB()
    local rotAnimPhase = read.floatB()
    local rotAnimScale = read.floatB()
    
    -- Rotation center (offset 48, size 8)
    local rotCenterX = read.floatB()
    local rotCenterY = read.floatB()
    
    -- Now at offset 372 (316 + 56)
    
    local texAnim = returnTextureAnimation()
    texAnim.uAnimationSource = uAnimSource
    texAnim.uAnimationFunction = uAnimFunction
    texAnim.uAnimationPeriod = uAnimPeriod
    texAnim.uAnimationPhase = uAnimPhase
    texAnim.uAnimationScale = uAnimScale
    texAnim.vAnimationSource = vAnimSource
    texAnim.vAnimationFunction = vAnimFunction
    texAnim.vAnimationPeriod = vAnimPeriod
    texAnim.vAnimationPhase = vAnimPhase
    texAnim.vAnimationScale = vAnimScale
    texAnim.rotationAnimationSource = rotAnimSource
    texAnim.rotationAnimationFunction = rotAnimFunction
    texAnim.rotationAnimationPeriod = rotAnimPeriod
    texAnim.rotationAnimationPhase = rotAnimPhase
    texAnim.rotationAnimationScale = rotAnimScale
    texAnim.rotationAnimationCenter = [rotCenterX, rotCenterY]
    
    return texAnim
)

-------------------------------------------------------
-- Read Reflection Properties
-- At offset 276 within soso_attrs (file offset 380), size 56 bytes
-------------------------------------------------------

fn readReflectionProperties =
(
    -- Now at offset 372, need to skip to 380
    -- Skip 8 bytes (372 + 8 = 380)
    skipBytes 8
    
    local falloffDistance = read.floatB()                       -- offset 0, 4 bytes
    local cutoffDistance = read.floatB()                        -- offset 4, 4 bytes
    local perpendicularBrightness = read.floatB()               -- offset 8, 4 bytes
    local perpendicularTintR = read.floatB()                    -- offset 12, 4 bytes
    local perpendicularTintG = read.floatB()                    -- offset 16, 4 bytes
    local perpendicularTintB = read.floatB()                    -- offset 20, 4 bytes
    local parallelBrightness = read.floatB()                    -- offset 24, 4 bytes
    local parallelTintR = read.floatB()                         -- offset 28, 4 bytes
    local parallelTintG = read.floatB()                         -- offset 32, 4 bytes
    local parallelTintB = read.floatB()                         -- offset 36, 4 bytes
    local cubeMap = read.tagRef()                               -- offset 40, 16 bytes
    
    -- Now at offset 436 (380 + 56)
    
    local reflection = returnReflectionProperties()
    reflection.falloffDistance = falloffDistance
    reflection.cutoffDistance = cutoffDistance
    reflection.perpendicularBrightness = perpendicularBrightness
    reflection.perpendicularTintColor = [perpendicularTintR, perpendicularTintG, perpendicularTintB]
    reflection.parallelBrightness = parallelBrightness
    reflection.parallelTintColor = [parallelTintR, parallelTintG, parallelTintB]
    reflection.cubeMap = cubeMap
    
    return reflection
)

-------------------------------------------------------
-- Read Tag Reference Paths
-------------------------------------------------------

fn readTagReferencePaths maps reflection =
(
    -- For source tags (pathPtr == 0), paths are stored sequentially after ALL tag data
    -- The tagdata structure is 440 bytes total (64 header + 40 shdr_attrs + 400 soso_attrs - 64)
    -- Strings start at offset 504 (64 + 440)
    
    -- Seek to end of tagdata structure (after soso_attrs)
    -- soso_attrs ends at: 64 (header) + 40 (shdr_attrs) + 400 (soso_attrs) = 504
    seekToPosition 504
    
    -- Read base map path
    if maps.baseMap.pathLen <= 0 then
    (
        maps.baseMap.path = "NULL"
        continue
    )
    else if maps.baseMap.pathPtr == 0 then
    (
        -- Source tag: read null-terminated string sequentially
        maps.baseMap.path = read.nullTerminatedString()
    )
    else
    (
        -- Cached tag: read from pointer location
        maps.baseMap.path = readTagRefPath maps.baseMap.pathPtr maps.baseMap.pathLen
    )
    
    -- Read multipurpose map path
    if maps.multipurposeMap.pathLen <= 0 then
    (
        maps.multipurposeMap.path = "NULL"
        continue
    )
    else if maps.multipurposeMap.pathPtr == 0 then
    (
        -- Source tag: read null-terminated string sequentially
        maps.multipurposeMap.path = read.nullTerminatedString()
    )
    else
    (
        -- Cached tag: read from pointer location
        maps.multipurposeMap.path = readTagRefPath maps.multipurposeMap.pathPtr maps.multipurposeMap.pathLen
    )
    
    -- Read detail map path
    if maps.detailMap.pathLen <= 0 then
    (
        maps.detailMap.path = "NULL"
    )
    else if maps.detailMap.pathPtr == 0 then
    (
        -- Source tag: read null-terminated string sequentially
        maps.detailMap.path = read.nullTerminatedString()
    )
    else
    (
        -- Cached tag: read from pointer location
        maps.detailMap.path = readTagRefPath maps.detailMap.pathPtr maps.detailMap.pathLen
    )
    
    -- Read cube map path
    if reflection.cubeMap.pathLen <= 0 then
    (
        reflection.cubeMap.path = "NULL"
        return ok
    )
    else if reflection.cubeMap.pathPtr == 0 then
    (
        -- Source tag: read null-terminated string sequentially
        reflection.cubeMap.path = read.nullTerminatedString()
    )
    else
    (
        -- Cached tag: read from pointer location
        reflection.cubeMap.path = readTagRefPath reflection.cubeMap.pathPtr reflection.cubeMap.pathLen
    )
)

-------------------------------------------------------
-- Main Tagdata Reader Function
-------------------------------------------------------
fn readShaderModelTag filePath =
(
    -- Open file
    local fileHandle = fopen filePath "rb"
    if fileHandle == undefined then
    (
        return undefined
    )
    
    setFileHandle fileHandle
    in_file = fileHandle

    local tagStruct = shaderModelTag()
    
    local tagHeader = readTagHeader()
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
        logger "Failed to read shader attributes\n" logType:#error
        fclose fileHandle
        return undefined
    )
    tagStruct.radiosityProperties = shaderAttrs.radProps
    tagStruct.physicsProperties = shaderAttrs.physProps
    
    -- Read model shader properties
    local modelShader = readModelShaderProperties()
    if modelShader == undefined then
    (
        logger "Failed to read model shader properties\n" logType:#error
        fclose fileHandle
        return undefined
    )
    tagStruct.modelShader = modelShader
    
    -- Read color change properties
    local changeColor = readColorChangeProperties()
    if changeColor == undefined then
    (
        logger "Failed to read color change properties\n" logType:#error
        fclose fileHandle
        return undefined
    )
    tagStruct.changeColor = changeColor
    
    -- Read self illumination properties
    local selfIllum = readSelfIlluminationProperties()
    if selfIllum == undefined then
    (
        logger "Failed to read self illumination properties\n" logType:#error
        fclose fileHandle
        return undefined
    )
    tagStruct.selfIllumination = selfIllum
    
    -- Read maps properties
    local maps = readMapsProperties()
    if maps == undefined then
    (
        logger "Failed to read maps properties\n" logType:#error
        fclose fileHandle
        return undefined
    )
    tagStruct.maps = maps
    
    -- Read texture animation properties
    local texAnim = readTextureAnimationProperties()
    if texAnim == undefined then
    (
        logger "Failed to read texture animation properties\n" logType:#error
        fclose fileHandle
        return undefined
    )
    tagStruct.textureAnimation = texAnim
    
    -- Read reflection properties
    local reflection = readReflectionProperties()
    if reflection == undefined then
    (
        logger "Failed to read reflection properties\n" logType:#error
        fclose fileHandle
        return undefined
    )
    tagStruct.reflectionProperties = reflection
    
    -- Read all tag reference paths
    readTagReferencePaths maps reflection

    if tagHeaderLogger then
    (
        logger "\n=== SHADER MODEL ===\n"
        --logger "Radiosity Properties:\n"
        --logger "    - Flags: %\n" params:#(tagStruct.radiosityProperties.flags)
        --logger "    - Detail Level: (%)\n" params:#(detailLevel tagStruct.radiosityProperties.detailLevel)
        --logger "    - Light Power: [%]\n" params:#(tagStruct.radiosityProperties.lightPower)
        --logger "    - Light Color: R=% G=% B=%\n" params:#(tagStruct.radiosityProperties.lightColor[1], tagStruct.radiosityProperties.lightColor[2], tagStruct.radiosityProperties.lightColor[3])
        --logger "    - Tint Color: R=% G=% B=%\n" params:#(tagStruct.radiosityProperties.tintColor[1], tagStruct.radiosityProperties.tintColor[2], tagStruct.radiosityProperties.tintColor[3])
        --logger "Physics Properties:\n"
        --logger "    - Material Type: (%)\n" params:#(materialTypeToString tagStruct.physicsProperties.materialType)
        --logger "Model Shader Properties:\n"
        --logger "    - Flags: %\n" params:#(tagStruct.modelShader.flags)
        --logger "    - Translucency: [%]\n" params:#(tagStruct.modelShader.translucency)
        --logger "Color Change Properties:\n"
        --logger "    - Change Color Source: (%)\n" params:#(sourceBlockToString tagStruct.changeColor.changeColorSource)
        --logger "Self Illumination Properties:\n"
        --logger "    - Flags: (%)\n" params:#(tagStruct.selfIllumination.flags)
        --logger "    - Color Source: (%)\n" params:#(sourceBlockToString tagStruct.selfIllumination.colorSource)
        --logger "    - Animation Function: (%)\n" params:#(animFunctionToString tagStruct.selfIllumination.animationFunction)
        --logger "    - Animation Period: [%]\n" params:#(tagStruct.selfIllumination.animationPeriod)
        --logger "    - Animation Color Lower Bound: R=% G=% B=%\n" params:#(tagStruct.selfIllumination.animColorLowerBound[1], tagStruct.selfIllumination.animColorLowerBound[2], tagStruct.selfIllumination.animColorLowerBound[3])
        --logger "    - Animation Color Upper Bound: R=% G=% B=%\n" params:#(tagStruct.selfIllumination.animColorUpperBound[1], tagStruct.selfIllumination.animColorUpperBound[2], tagStruct.selfIllumination.animColorUpperBound[3])
        logger "Maps Properties:\n"
        --logger "    - Base Map U-Scale: [%]\n" params:#(tagStruct.maps.mapUScale)
        --logger "    - Base Map V-Scale: [%]\n" params:#(tagStruct.maps.mapVScale)
        logger "    - Base Map: %\n" params:#(tagStruct.maps.baseMap.path)
        logger "    - Multipurpose Map: %\n" params:#(tagStruct.maps.multipurposeMap.path)
        --logger "    - Detail Function: (%)\n" params:#(detailFunctionToString tagStruct.maps.detailFunction)
        --logger "    - Detail Mask: (%)\n" params:#(detailMaskToString tagStruct.maps.detailMask)
        --logger "    - Detail Map Scale: [%]\n" params:#(tagStruct.maps.detailMapScale)
        logger "    - Detail Map: %\n" params:#(tagStruct.maps.detailMap.path)
        --logger "    - Detail Map V-Scale: [%]\n" params:#(tagStruct.maps.detailMapVScale)
        --logger "Texture Animation Properties:\n"
        --logger "    - U Animation Source: (%)\n" params:#(sourceBlockToString tagStruct.textureAnimation.uAnimationSource)
        --logger "    - U Animation Function: (%)\n" params:#(animFunctionToString tagStruct.textureAnimation.uAnimationFunction)
        --logger "    - U Animation Period: [%]\n" params:#(tagStruct.textureAnimation.uAnimationPeriod)
        --logger "    - V Animation Source: (%)\n" params:#(sourceBlockToString tagStruct.textureAnimation.vAnimationSource)
        --logger "    - V Animation Function: (%)\n" params:#(animFunctionToString tagStruct.textureAnimation.vAnimationFunction)
        --logger "    - V Animation Period: [%]\n" params:#(tagStruct.textureAnimation.vAnimationPeriod)
        --logger "    - Rotation Animation Source: (%)\n" params:#(sourceBlockToString tagStruct.textureAnimation.rotationAnimationSource)
        --logger "    - Rotation Animation Function: (%)\n" params:#(animFunctionToString tagStruct.textureAnimation.rotationAnimationFunction)
        --logger "    - Rotation Animation Period: [%]\n" params:#(tagStruct.textureAnimation.rotationAnimationPeriod)
        logger "Reflection Properties:\n"
        --logger "    - Falloff Distance: [%]\n" params:#(tagStruct.reflectionProperties.falloffDistance)
        --logger "    - Cutoff Distance: [%]\n" params:#(tagStruct.reflectionProperties.cutoffDistance)
        --logger "    - Perpendicular Brightness: [%]\n" params:#(tagStruct.reflectionProperties.perpendicularBrightness)
        --logger "    - Perpendicular Tint Color: R=% G=% B=%\n" params:#(tagStruct.reflectionProperties.perpendicularTintColor[1], tagStruct.reflectionProperties.perpendicularTintColor[2], tagStruct.reflectionProperties.perpendicularTintColor[3])
        --logger "    - Parallel Brightness: [%]\n" params:#(tagStruct.reflectionProperties.parallelBrightness)
        --logger "    - Parallel Tint Color: R=% G=% B=%\n" params:#(tagStruct.reflectionProperties.parallelTintColor[1], tagStruct.reflectionProperties.parallelTintColor[2], tagStruct.reflectionProperties.parallelTintColor[3])
        logger "    - Cube Map: %\n" params:#(tagStruct.reflectionProperties.cubeMap.path)
    )
    -- Close file and return tag struct
    fclose fileHandle
    return tagStruct
)
