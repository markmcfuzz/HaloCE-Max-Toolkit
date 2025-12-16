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
-- Shader Model tag structure
-------------------------------------------------------

struct shaderModelTag (
    header = undefined,
    radiosityProperties = undefined,
    physicsProperties = undefined,
    modelShader = undefined,
    changeColor = undefined,
    selfIllumination = undefined,
    maps = undefined,
    textureAnimation = undefined,
    reflectionProperties = undefined,
    unknown0 = 0.0,
    unknown1 = #()
)

struct returnHeader (
    tagClass,
    checksum,
    version,
    engineId
)

struct returnRadiosityProperties (
    flags,
    detailLevel,
    lightPower,
    lightColor,
    tintColor
)

struct returnPhysicsProperties (
    materialType
)

struct returnModelShader (
    flags,
    translucency
)

struct returnChangeColor (
    changeColorSource
)

struct returnSelfIllumination (
    flags,
    colorSource,
    animationFunction,
    animationPeriod,
    animColorLowerBound,
    animColorUpperBound
)

struct returnMaps (
    mapUScale,
    mapVScale,
    baseMap,
    multipurposeMap,
    detailFunction,
    detailMask,
    detailMapScale,
    detailMap,
    detailMapVScale
)

struct shaderAttributesResult (
    radProps,
    physProps
)

struct returnTextureAnimation (
    uAnimationSource,
    uAnimationFunction,
    uAnimationPeriod,
    uAnimationPhase,
    uAnimationScale,
    vAnimationSource,
    vAnimationFunction,
    vAnimationPeriod,
    vAnimationPhase,
    vAnimationScale,
    rotationAnimationSource,
    rotationAnimationFunction,
    rotationAnimationPeriod,
    rotationAnimationPhase,
    rotationAnimationScale,
    rotationAnimationCenter
)

struct returnReflectionProperties (
    falloffDistance,
    cutoffDistance,
    perpendicularBrightness,
    perpendicularTintColor,
    parallelBrightness,
    parallelTintColor,
    cubeMap
)

fn detailLevel enum =
(
    case enum of
    (
        
        0: "high";
        1: "medium";
        2: "low";
        3: "turd";
        default: ("unknown_flag_" + (flags as string))
    )
)

fn sourceBlockToString enum =
(
    case enum of
    (
        
        0: "none";
        1: "A";
        2: "B";
        3: "C";
        4: "D";
        default: ("unknown_" + (enum as string))
    )
)

fn animFunctionToString enum =
(
    case enum of
    (
        
        0: "one";
        1: "zero";
        2: "cosine";
        3: "cosine (variable period)";
        4: "diagonal wave";
        5: "diagonal wave (variable period)";
        6: "slide";
        7: "slide (variable period)";
        8: "noise";
        9: "jitter";
        10: "wander";
        11: "spark";
        default: ("unknown_" + (enum as string))
    )
)

fn detailFunctionToString enum =
(
    case enum of
    (
        
        0: "double/biased multiply";
        1: "multiply";
        2: "double/biased add";
        default: ("unknown_" + (enum as string))
    )
)

fn detailMaskToString enum =
(
    case enum of
    (
        
        0: "none";
        1: "reflection mask inverse";
        2: "reflection mask";
        3: "self-illumination mask inverse";
        4: "self-illumination mask";
        5: "change-color mask inverse";
        6: "change-color mask";
        7: "auxiliary mask inverse";
        8: "auxiliary mask";
        default: ("unknown_" + (enum as string))
    )
)