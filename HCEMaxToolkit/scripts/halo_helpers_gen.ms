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
-----------------------------------------------------------------------

try
(
	-- Get the user scripts directory path
	local thisScript = getThisScriptFilename()
    local pluginRoot = pathConfig.removePathLeaf (getFilenamePath thisScript)
	local haloPath = pluginRoot + @"\io_scene_halo_ce\modules\global_functions\"
	--local scriptsPath = getDir #userscripts
	--local haloPath = scriptsPath + @"\io_scene_halo_ce\modules\global_functions\"
	
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