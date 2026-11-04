------------------------------------------------------------------------------
--	Copyright (C) 2025 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------

scriptDir = getFilenamePath (getThisScriptFilename())
rootEngine = pathConfig.removePathLeaf scriptDir + "\\"
scriptName = getFilenameFile (getThisScriptFilename())

-- Force garbage collection to clear old structs from memory
gc light:true

fileIn (scriptDir + "utils\\path_utils.ms")
fileIn (scriptDir + "config\\config_manager.ms")
fileIn (scriptDir + "config\\logger.ms")
-- Initialize config and logger BEFORE loading other scripts that use logger
configManager.init()
logger.loadConfig callerScriptName:scriptName

fileIn (rootEngine + "builders\\helper_builder.ms")
fileIn (rootEngine + "utility_coplanar_checker.ms")
fileIn (scriptDir + "utils\\tag_utils.ms")
fileIn (scriptDir + "utils\\lua_bridge.ms")
fileIn (scriptDir + "utils\\mesh_normals.ms")
fileIn (scriptDir + "utils\\build_utils.ms")
fileIn (scriptDir + "utils\\text_utils.ms")
-- Opens the tag editor whenever an object tag Point is selected
fileIn (rootEngine + "builders\\tag\\object\\tag_editor.ms")
-- GlyphFX Animation Preview follows the timeline (after tag_editor.ms: uses collectSubMaterials)
fileIn (rootEngine + "builders\\tag\\shared\\shader_animation.ms")
-- Names of tag Points, markers and nodes in the viewport (after tag_editor.ms and helper_builder.ms)
fileIn (scriptDir + "utils\\viewport_labels.ms")

