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
-- Shader Transparent Glass tag structure
-------------------------------------------------------

struct shaderTransparentGlassTag (
    header = undefined,
    radiosityProperties = undefined,
    physicsProperties = undefined,
    glassShader = undefined,
    backgroundTintProps = undefined,
    reflectionProps = undefined,
    diffuseProps = undefined,
    specularProps = undefined
)

struct returnGlassShader (
    glassFlags
)

struct returnBackgroundTintProps (
    tintColor,
    tintMapScale,
    tintMapPath
)

struct returnGlassReflectionProps (
    reflectionType,
    perpendicularBrightness,
    perpendicularTintColor,
    parallelBrightness,
    parallelTintColor,
    reflectionMapPath,
    bumpMapScale,
    bumpMapPath
)

struct returnDiffuseProps (
    diffuseMapScale,
    diffuseMapPath,
    diffuseDetailMapScale,
    diffuseDetailMapPath
)

struct returnSpecularProps (
    specularMapScale,
    specularMapPath,
    specularDetailMapScale,
    specularDetailMapPath
)

fn reflectionTypeToString enum =
(
    case enum of
    (
        
        0: "bumped cube-map";
        1: "flat cube-map";
        2: "dynamic mirror";
        default: ("unknown_" + (enum as string))
    )
)

logger "Tag Struct Loaded: shader_transparent_glass"