-- Halo Custom Edition Model Collision Geometry Importer
-- by Mark McFuzz
-- Version 1.0.0
------------------------------------------------------------------------------------------------
-- Features:
-- - Imports model collision geometry tags from Halo Custom Edition.
-- - Accurate geometry.
-- - Objects are named by region, permutation and parent node for easy identification.
-- - Materials are assigned based on collision material properties.
-- - Automatically links objects to their parent nodes in the scene.
-- - Imports pathfinding spheres in the correct positions and scale.
-- - Asigns geometry and pathfinding spheres to separate layers for organization.
-- - Serialized materials by colors.
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

-- Load required modules
filein (scriptDir + "modules\\global_functions\\read_utils.ms")
filein (scriptDir + "modules\\global_functions\\tag_classes.ms")
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
	-- Open file dialog
	collisionFile = getOpenFileName \
		caption:"Select Halo CE Collision Geometry Tag" \
		types:"Collision Geometry (*.model_collision_geometry)|*.model_collision_geometry|All Files (*.*)|*.*" \
		historyCategory:"HaloCECollision"
	
	if collisionFile == undefined then
	(
		format "Import cancelled by user.\n"
		return undefined
	)
	
	format "\n=== IMPORTING COLLISION GEOMETRY ===\n"
	format "File: %\n" (filenameFromPath collisionFile)
	
	-- Read collision tag
	local collisionData = readCollisionTag collisionFile
	
	if collisionData == undefined then
	(
		format "[FAILED] Could not read collision tag\n"
		messageBox "Failed to read collision tag file!\n\nThe file may be corrupted or not a valid Halo CE collision geometry tag." title:"Import Failed"
		return undefined
	)
	
	format "\n[SUCCESS] Collision tag read successfully!\n"
	format "Materials: %\n" collisionData.materials.count
	format "Regions: %\n" collisionData.regions.count
	format "Spheres: %\n" collisionData.pathfinding_spheres.count
	format "Nodes: %\n" collisionData.nodes.count
	
	-- Build collision mesh in scene
	format "\n=== BUILDING COLLISION MESH ===\n"
	local collisionName = getFilenameFile collisionFile
	local success = buildCollisionMesh collisionData collisionName
	
	-- Refresh viewport to show imported geometry
	completeRedraw()
	
	if success != undefined and success.count > 0 then
	(
		format "\n[SUCCESS] Collision geometry imported successfully!\n"
		messageBox ("Collision geometry imported successfully!\nCreated " + success.count as string + " mesh objects.") title:"Import Complete"
	)
	else
	(
		format "\n[FAILED] Could not build collision mesh\n"
		messageBox "Failed to build collision mesh in scene!" title:"Import Failed"
	)
	
	return success
)

-- Run the import
importCollisionGeometry()
