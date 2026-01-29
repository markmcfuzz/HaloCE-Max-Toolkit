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
-- Shader Transparent Meter tag structure
-------------------------------------------------------

struct shaderTransparentMeterTag (
    header = undefined,
    radiosityProperties = undefined,
    physicsProperties = undefined,
    meterShader = undefined,
    colors = undefined,
    externalFunctionSource = undefined
)

struct returnMeterShader (
    meterFlags,
    meterMapPath
)

struct returnColors (
    gradientMin,
    gradientMax,
    background,
    flash,
    tint,
    meterTransparency,
    backgroundTransparency
)

struct returnExternalFunctionSource (
    meterBrightness,
    flashBrightness,
    valueSource,
    gradientSource,
    flashExtension
)

logger "Tag Shader Shared Structure loaded.\n" logType:#success