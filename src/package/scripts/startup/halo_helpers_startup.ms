------------------------------------------------------------------------------------------------
--	Halo CE Max Toolkit - Startup Script
--	Automatically loads Halo helper objects on 3ds Max startup
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
------------------------------------------------------------------------------------------------

try
(
	-- Get the user scripts directory path
	local scriptsPath = getDir #userscripts
	local haloPath = scriptsPath + @"\halo\modules\global_functions\"
	
	-- Load dependencies in order
	local configPath = haloPath + "config.ms"
	local utilsPath = haloPath + "utils.ms"
	local objectBuilderPath = haloPath + "object_builder.ms"
	
	-- Load config first
	if doesFileExist configPath then
		fileIn configPath
	
	-- Load utils second
	if doesFileExist utilsPath then
		fileIn utilsPath
	
	-- Load object_builder last
	if doesFileExist objectBuilderPath then
	(
		fileIn objectBuilderPath
		format "[Halo CE Toolkit] Helper objects loaded successfully.\n"
	)
	else
	(
		format "[Halo CE Toolkit] Could not find object_builder.ms at: %\n" objectBuilderPath
	)
)
catch
(
	format "[Halo CE Toolkit] Error loading helper objects: %\n" (getCurrentException())
)

--clearListener()