------------------------------------------------------------------------------------------------
--	Halo CE Max Toolkit - Startup Script
--	Automatically loads Halo helper objects on 3ds Max startup
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
------------------------------------------------------------------------------------------------

-- Get the scripts directory path
local scriptsPath = getDir #scripts

-- Construct path to object_builder.ms
local objectBuilderPath = scriptsPath + "\\halo\\modules\\global_functions\\object_builder.ms"

-- Check if file exists and load it
if doesFileExist objectBuilderPath then
(
	fileIn objectBuilderPath
	format "[Halo CE Toolkit] Helper objects loaded successfully.\n"
)
else
(
	format "[Halo CE Toolkit] Warning: Could not find object_builder.ms at: %\n" objectBuilderPath
)
