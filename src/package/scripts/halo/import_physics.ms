-- Halo Custom Edition Physics Importer (Modular Version)
-- by Mark McFuzz
-- Version 1.1.0
------------------------------------------------------------------------------------------------
-- Features:
-- - Imports physics tags from Halo Custom Edition.
-- - Accurate orientation for spheres.
-- - Accurate world positions and scales for spheres.
-- - Automatic linking to frame*, b_*, and bip01* nodes in scene.
-- - Mass point data displayed in custom attributes (Modify panel).
-- - Assigns mass point physics to a new layer for organization.
-- - Color-codes for mass points for easy identification.
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
filein (scriptDir + "modules\\file_tag\\physics\\tag_struct.ms")
filein (scriptDir + "modules\\file_tag\\physics\\tag_base_reader.ms")
filein (scriptDir + "modules\\file_tag\\physics\\build_mesh.ms")

-------------------------------------------------------
-- Main Import Function
-------------------------------------------------------

fn ImportPhysicsGeometry =
(
	format "\n=== IMPORTING PHYSICS GEOMETRY ===\n"
	
	-- Open file dialog
	local physicsFile = getOpenFileName \
		caption:"Select Physics Tag File" \
		types:"Physics Tag (*.physics)|*.physics|All Files (*.*)|*.*" \
		historyCategory:"PhysicsImport"
	
	if physicsFile == undefined then
	(
		format "Import cancelled by user.\n"
		return undefined
	)
	
	format "File: %\n" (filenameFromPath physicsFile)
	
	-- Read physics tag
	local physicsData = readPhysicsTag physicsFile
	
	if physicsData == undefined then
	(
		messageBox "Failed to read physics tag!" title:"Import Failed"
		return undefined
	)
	
	local massPointsData = physicsData[1]
	local poweredMassPointsData = physicsData[2]
	
	-- Build spheres
	format "\n=== BUILDING MASS POINT SPHERES ===\n"
	local success = createMassPointSpheres massPointsData poweredMassPointsData
	
	-- Refresh viewport
	completeRedraw()
	
	if success != undefined and success.count > 0 then
	(
		format "\n[SUCCESS] Physics geometry imported successfully!\n"
		messageBox ("Physics mass points imported successfully!\nCreated " + success.count as string + " sphere objects.") title:"Import Complete"
	)
	else
	(
		format "\n[FAILED] Could not build mass point spheres\n"
		messageBox "Failed to build mass point spheres in scene!" title:"Import Failed"
	)
	
	return success
)

-- Run the import
ImportPhysicsGeometry()
