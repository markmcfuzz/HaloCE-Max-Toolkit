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

-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

filein (scriptDir + "..\\modules\\global_functions\\config.ms")
filein (scriptDir + "..\\modules\\global_functions\\utils.ms")
filein (scriptDir + "..\\modules\\global_functions\\object_builder.ms")
filein (scriptDir + "..\\modules\\file_jms\\process_scene.ms")


-- Convert sphere markers in scene to Halo Marker helpers
fn spheresToHelpers =
(
	local convertedCount = 0
	local skippedCount = 0
	local sphereMarkers = #()
	
	-- Collect all sphere objects with "#" prefix
	for obj in objects do
	(
		if obj.isHidden then continue
		if classOf obj != Sphere then continue
		if obj.name.count == 0 then continue
		if obj.name[1] != "#" then continue
		
		append sphereMarkers obj
	)
	
	if sphereMarkers.count == 0 then
	(
		messageBox "No sphere markers found in the scene.\n\nLooking for Sphere objects with '#' prefix." title:"No Markers Found"
		return 0
	)
	
	-- Ask for confirmation
	local confirmMsg = "Found " + (sphereMarkers.count as string) + " sphere marker(s).\n\n"
	confirmMsg += "Convert them to Halo Marker helpers?\n\n"
	confirmMsg += "This will:\n"
	confirmMsg += "  • Preserve position, rotation, and parent\n"
	confirmMsg += "  • Preserve radius and wirecolor\n"
	confirmMsg += "  • Delete the original sphere objects"
	
	if queryBox confirmMsg title:"Convert Sphere Markers?" != true then
		return 0
	
	-- Disable undo for batch operation
	undo off
	(
		local spheresToDelete = #()
		
		-- First pass: Create all helpers
		for sphereObj in sphereMarkers do
		(
			-- Store properties BEFORE creating helper
			local markerName = substring sphereObj.name 2 -1  -- Remove "#" prefix
			local markerParent = sphereObj.parent
			local markerRadius = sphereObj.radius
			local markerColor = sphereObj.wirecolor
			
			-- Store world transform
			local worldTransform = sphereObj.transform
			
			-- Create new Halo Marker helper at origin first
			local newMarker = createHaloMarker \
				pos:[0,0,0] \
				radius:markerRadius \
				markerType:"Marker" \
				name:markerName \
				wireColor:(color 0 240 255)
			
			-- Set parent first
			newMarker.parent = markerParent
			
			-- Then apply the world transform (this will automatically convert to parent space)
			newMarker.transform = worldTransform
			
			-- Assign to "Markers" layer
			local markersLayer = LayerManager.getLayerFromName "Markers"
			if markersLayer == undefined then
				markersLayer = LayerManager.newLayerFromName "Markers"
			markersLayer.addNode newMarker
			
			-- Mark sphere for deletion
			append spheresToDelete sphereObj
			convertedCount += 1
		)
		
		-- Second pass: Delete all original spheres
		for sphereObj in spheresToDelete do
		(
			try (delete sphereObj) catch()
		)
	)
	
	-- Show results
	local resultMsg = "Conversion complete!\n\n"
	resultMsg += "Converted: " + (convertedCount as string) + " marker(s)\n"
	if skippedCount > 0 then
		resultMsg += "Skipped: " + (skippedCount as string) + " marker(s)"
	
	messageBox resultMsg title:"Conversion Complete"
	
	return convertedCount
)

-- Only run if executed directly (not when included by another script)
if (getSourceFileName()) == (getThisScriptFilename()) then
	spheresToHelpers()