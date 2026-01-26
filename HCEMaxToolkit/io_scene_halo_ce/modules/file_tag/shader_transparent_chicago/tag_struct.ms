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

struct returnChicagoShader (
    numericCounterLimit,
    chicagoFlags,
    firstMapType,
    framebufferBlendFunction,
    framebufferFadeMode,
    framebufferFadeSource,
    lensFlareSpacing,
    lensFlare
)

struct returnExtraLayers (
    shaderTagClass,
    shaderPath
)

struct returnFourStageMap (
    mapFlags,
    colorFunction,
    alphaFunction,
    mapUScale,
    mapVScale,
    mapUOffset,
    mapVOffset,
    mapRotation,
    mipmapBias,
    mapPath,
    uAnimation,
    vAnimation,
    rotationAnimation,
    rotationCenter
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

struct returnRotationCenter (
    x,
    y
)

struct shaderMapsResult (
    mapsProps,
    animProps
)

struct returnChicagoReflexives (
    extraLayers,
    fourStageMap
)

struct shaderAttributesResult (
    radProps,
    physProps
)

fn detailLeveltoString enum =
(
    case enum of
    (
        0: "high";
        1: "medium";
        2: "low";
        3: "turd";
        default: ("unknown_flag_" + (enum as string))
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

fn firstMapTypeToString enum =
(
    case enum of
    (
        0: "map_2d";
        1: "reflection_cube_map";
        2: "object_centered_cube_map";
        3: "viewer_centered_cube_map";
        default: ("unknown_flag_" + (enum as string))
    )
)

fn framebufferBlendFunctionToString enum =
(
    case enum of
    (
        0: "alpha_blend";
        1: "multiply";
        2: "double_multiply";
        3: "add";
        4: "subtract";
        5: "component_min";
        6: "component_max";
        7: "alpha_multiply_add";
        default: ("unknown_flag_" + (enum as string))
    )
)

fn framebufferFadeModeToString enum =
(
    case enum of
    (
        0: "none";
        1: "fade_when_perpendicular";
        2: "fade_when_parallel";
        default: ("unknown_flag_" + (enum as string))
    )
)

fn framebufferFadeSourceToString enum =
(
    case enum of
    (
        0: "none";
        1: "A out";
        2: "B out";
        3: "C out";
        4: "D out";
        default: ("unknown_flag_" + (enum as string))
    )
)

fn extraLayerTagClass enum =
(
    case enum of
    (
        1936221298: "shader";
        1936027254: "shader_environment";
        1936683887: "shader_model";
        1935894633: "shader_transparent_chicago";
        1935893880: "shader_transparent_chicago_extended";
        1936684146: "shader_transparent_generic";
        1936157793: "shader_transparent_glass";
        1936549236: "shader_transparent_meter";
        1936747617: "shader_transparent_plasma";
        1937203572: "shader_transparent_water";
        4294967295: "none";
        default: ("unknown_flag_" + (enum as string))
    )
)

fn colorFunctionToString enum =
(
    case enum of
    (
        0: "current";
        1: "next_map";
        2: "multiply";
        3: "double_multiply";
        4: "add";
        5: "add_signed_current";
        6: "add_signed_next_map";
        7: "subtract_signed_current";
        8: "subtract_signed_next_map";
        9: "blend_current_alpha";
        10: "blend_current_alpha_inverse";
        11: "blend_next_map_alpha";
        12: "blend_next_map_alpha_inverse";
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

logger "Tag Struct Loaded: shader_transparent_chicago"