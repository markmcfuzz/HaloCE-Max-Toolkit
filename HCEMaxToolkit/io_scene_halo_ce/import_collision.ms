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

-- Get script directory
scriptDir = getFilenamePath (getThisScriptFilename())

clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Load required modules
filein (scriptDir + "modules\\global_functions\\config.ms")
filein (scriptDir + "modules\\global_functions\\utils.ms")
filein (scriptDir + "modules\\global_functions\\object_builder.ms")
filein (scriptDir + "modules\\global_functions\\tag_metadata.ms")
filein (scriptDir + "modules\\file_tag\\model_collision_geometry\\tag_struct.ms")
filein (scriptDir + "modules\\file_tag\\model_collision_geometry\\tag_geo_reader.ms")
filein (scriptDir + "modules\\file_tag\\model_collision_geometry\\tag_data_reader.ms")
filein (scriptDir + "modules\\file_tag\\model_collision_geometry\\build_mesh.ms")
filein (scriptDir + "modules\\file_tag\\model_collision_geometry\\tag_base_reader.ms")

-------------------------------------------------------
-- Main Import Function
-------------------------------------------------------

fn importCollisionGeometry =
(
	collisionFile = getOpenFileName \
		caption:"Select Halo CE Collision Geometry Tag" \
		types:"Collision Geometry (*.model_collision_geometry)|*.model_collision_geometry|All Files (*.*)|*.*" \
		historyCategory:"HaloCECollision"
	
	if collisionFile == undefined then
	(
		format "Import cancelled by user.\n"
		return undefined
	)
	
	global enableFileLogging = false
	if enableFileLogging then
	(
		local logPath = (getFilenamePath collisionFile) + (getFilenameFile collisionFile) + "_collision_import.log"
		global logFile = createFile logPath
	)
	
	--format "\n=== IMPORTING COLLISION GEOMETRY ===\n"
	--format "File: %\n" (filenameFromPath collisionFile)
	
	local collisionData = readCollisionTag collisionFile
	
	if logFile != undefined do
	(
		close logFile
		global logFile = undefined
	)
	global enableFileLogging = false
	
	if collisionData == undefined then
	(
		logger "Could not read collision tag\n" logType:#error
		messageBox "Failed to read collision tag file!\n\nThe file may be corrupted or not a valid Halo CE collision geometry tag." title:"Import Failed"
		return undefined
	)

	--format "\n=== BUILDING COLLISION MESH ===\n"
	local collisionName = getFilenameFile collisionFile
	local success = buildCollisionMesh collisionData collisionName
	
	completeRedraw()
	
	-- Show success message
    if success != undefined and success.count > 0 then
    (
        local fileName = filenameFromPath collisionFile
        messageBox ("Collision geometry imported successfully!\n\n" + "File: " + fileName + "\n") \
                title:"Import Complete" \
                beep:false
    )

	clearListener()
	return success
)

importCollisionGeometry()
