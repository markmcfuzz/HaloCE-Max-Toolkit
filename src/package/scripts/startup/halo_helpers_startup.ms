------------------------------------------------------------------------------------------------
--	Halo CE Max Toolkit - Startup Script
--	Automatically loads Halo helper objects on 3ds Max startup
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
------------------------------------------------------------------------------------------------

(
	-- Only run during actual 3ds Max startup, not during file operations
	if maxOps.isMaxStarting() == false then
	(
		-- Get the user scripts directory path (not the 3ds Max installation scripts)
		local scriptsPath = getDir #userscripts
		
		-- Construct path to object_builder.ms
		local objectBuilderPath = scriptsPath + "halo\\modules\\global_functions\\object_builder.ms"
		
		-- Check if file exists and load it
		if doesFileExist objectBuilderPath then
		(
			try
			(
				fileIn objectBuilderPath
				format "[Halo CE Toolkit] Helper objects loaded successfully.\n"
			)
			catch
			(
				format "[Halo CE Toolkit] Error loading helper objects.\n"
			)
		)
	)
)
