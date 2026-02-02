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
-- Shader Transparent Generic tag structure
-------------------------------------------------------

struct shaderTransparentGenericTag (
    header = undefined,
    radiosityProperties = undefined,
    physicsProperties = undefined,
    genericShader = undefined,
    lensFlares = undefined,
    extraLayersBlock = undefined,
    extraLayers = #(),
    mapsBlock = undefined,
    maps = #(),
    stagesBlock = undefined,
    stages = #()
)

struct returnGenericShader (
    numericCounterLimit,
    genericFlags,
    firstMapType,
    framebufferBlendFunction,
    framebufferFadeMode,
    framebufferFadeSource,
    lensFlareSpacing,
    lensFlare
)

struct returnGenericReflexives (
    extraLayers,
    maps,
    stages
)

struct returnMaps (
    mapFlags,
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

struct returnStages (
    flags,
    color0Source,
    color0AnimFunction,
    color0AnimPeriod,  
    color0AnimLowerBound,
    color0AnimUpperBound,
    color1,
    colorProps,
    alphaProps
) 

struct stageColorProperties (
    inputA,
    inputAMapping,
    inputB,
    inputBMapping,
    inputC,
    inputCMapping,
    inputD,
    inputDMapping,
    outputAB,
    outputABFunction,
    outputCD,
    outputCDFunction,
    outputABCDMuxSum,
    outputMapping
)

struct stageAlphaProperties (
    inputA,
    inputAMapping,
    inputB,
    inputBMapping,
    inputC,
    inputCMapping,
    inputD,
    inputDMapping,
    outputAB,
    outputCD,
    outputABCDMuxSum,
    outputMapping
)

fn colorInputToString enum =
(
    case enum of
    (
        
        0: "zero";
        1: "one";
        2: "one half";
        3: "negative one";
        4: "negative one half";
        5: "map color 0";
        6: "map color 1";
        7: "map color 2";
        8: "map color 3";
        9: "vertex color 0";
        10: "vertex color 1";
        11: "scratch color 0";
        12: "scratch color 1";
        13: "constant color 0";
        14: "constant color 1";
        15: "map alpha 0";
        16: "map alpha 1";
        17: "map alpha 2";
        18: "map alpha 3";
        19: "vertex alpha 0";
        20: "vertex alpha 1";
        21: "scratch alpha 0";
        22: "scratch alpha 1";
        23: "constant alpha 0";
        24: "constant alpha 1";
        default: ("unknown_" + (enum as string))
    )
)

fn colorInputMappingToString enum =
(
    case enum of
    (
        0: "clamp(x)";
        1: "1 - clamp(x)";
        2: "2*clamp(x) - 1";
        3: "1 - 2*clamp(x)";
        4: "clamp(x) - 1/2";
        5: "1/2 - clamp(x)";
        6: "x";
        7: "-x";
        default: ("unknown_" + (enum as string))
    )
)

fn colorOutputToString enum =
(
    case enum of
    (
        0: "discard";
        1: "scratch color 0";
        2: "scratch color 1";
        3: "vertex color 0";
        4: "vertex color 1";
        5: "map color 0";
        6: "map color 1";
        7: "map color 2";
        8: "map color 3";
        default: ("unknown_" + (enum as string))
    )
)

fn colorOutputFunctionToString enum =
(
    case enum of
    (
        0: "multiply";
        1: "dot product";
        default: ("unknown_" + (enum as string))
    )
)

fn colorOutputMappingToString enum =
(
    case enum of
    (
        0: "identity";
        1: "scale by 1/2";
        2: "scale by 2";
        3: "scale by 4";
        4: "bias by - 1/2";
        5: "expand normal";
        default: ("unknown_" + (enum as string))
    )
)

logger "Shader Transparent Generic tag structure loaded.\n" logType: #success 