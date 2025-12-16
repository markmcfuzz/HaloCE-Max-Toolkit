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
-- Shader Transparent Chicago tag structure
-------------------------------------------------------

struct shaderTransparentChicagoTag (
    header = undefined,
    radiosityProperties = undefined,
    physicsProperties = undefined,
    chicagoShader = undefined,
    lensFlares = undefined,
    extraLayersBlock = undefined,
    extraLayers = #(),
    fourStageMapBlock = undefined,
    fourStageMap = #(),
    extraFlags = undefined
)

struct header (
    tagClass,
    checksum,
    version,
    engineId
)

struct radiosityProperties (
    flags,
    detailLevel,
    lightPower,
    lightColor,
    tintColor
)

struct physicsProperties (
    materialType
)

struct chicagoShader (
    numericCounterLimit,
    chicagoFlags,
    firstMapType,
    framebufferBlendFunction,
    framebufferFadeMode,
    framebufferFadeSource
)

struct lensFlares (
    lensFlareSpacing,
    lensFlare
)

struct extraLayersBlock (
    shader
)

struct fourStageMap (
    mapFlags,
    colorFunction,
    alphaFunction,
    mapUScale,
    mapVScale,
    mapUOffset,
    mapVOffset,
    mapRotation,
    mipmapBias,
    map,
    uAnimation,
    vAnimation,
    rotationAnimation,
    rotationCenter
)

struct uVRotAnimation (
    source
    function
    period
    phase
    scale
)

struct rotationCenter (
    x,
    y
)




logger "Tag Struct Loaded: shader_transparent_chicago"