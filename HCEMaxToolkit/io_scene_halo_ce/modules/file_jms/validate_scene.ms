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
-- SCENE VALIDATION FOR JMS EXPORT
-------------------------------------------------------

-- Recursive helper to check all descendants for geometry
fn checkDescendantsForGeometry parentObj =
(
	for child in parentObj.children do
	(
		if child.isHidden then continue
		
		-- If this child is geometry (and not a node/marker), we found it
		if isGeometryObject child and not (isNodeObject child) and not (isMarkerObject child) then
			return true
		
		-- Recursively check this child's descendants (for containers/helpers)
		if checkDescendantsForGeometry child then
			return true
	)
	return false
)

-- Helper function to check if a node has geometry linked or skinned to it
-- Recursively checks all descendants (containers/helpers) for geometry
fn nodeHasGeometry node =
(
	-- Check for geometry in descendants (including through containers/helpers)
	if checkDescendantsForGeometry node then
		return true
	
	-- Check for skinned geometry (vertices weighted to this node)
	for obj in objects do
	(
		if obj.isHidden then continue
		if not (isGeometryObject obj) then continue
		
		local skinMod = getSkinModifier obj
		if skinMod != undefined then
		(
			-- Check if this node is used as a bone in the skin
			local boneCount = skinOps.GetNumberBones skinMod
			for b = 1 to boneCount do
			(
				local bone = skinOps.GetBoneName skinMod b 0
				if bone == node.name then
					return true
			)
		)
	)
	
	return false
)

-- Validate scene before export and return error messages if any
fn validateSceneForExport =
(
	local errors = #()
	
	-- Validation 1: Check for valid root node
	local rootNode = undefined
	local rootNodeCount = 0
	
	for obj in objects do
	(
		if (not obj.isHidden) and (isNodeObject obj) and obj.parent == undefined then
		(
			rootNode = obj
			rootNodeCount += 1
		)
	)
	
	if rootNodeCount == 0 then
	(
		append errors "No valid root node found.\n\nA root node must exist and be visible.\nRoot nodes must have a prefix: 'b', 'b_', 'bone', 'frame', or 'bip01'"
	)
	else if rootNodeCount > 1 then
	(
		append errors "Multiple root nodes found.\n\nOnly one root node (visible, no parent) is allowed."
	)
	
	-- Validation 2: Check for geometry linked to markers
	local geometryLinkedToMarkers = #()
	
	for obj in objects do
	(
		if obj.isHidden then continue
		if not (isGeometryObject obj) then continue
		
		-- Check if parent is a marker
		if obj.parent != undefined and isMarkerObject obj.parent then
		(
			append geometryLinkedToMarkers obj.name
		)
	)
	
	if geometryLinkedToMarkers.count > 0 then
	(
		local errorMsg = "Geometry objects linked to markers:\n\n"
		for i = 1 to geometryLinkedToMarkers.count do
		(
			errorMsg += "  • " + geometryLinkedToMarkers[i] + "\n"
		)
		errorMsg += "\nGeometry must be linked to frame/bone nodes or other geometry, not markers."
		append errors errorMsg
	)
	
	-- Validation 3: Check for geometry without materials
	local geometryWithoutMaterial = #()
	
	for obj in objects do
	(
		if obj.isHidden then continue
		if not (isGeometryObject obj) then continue
		if isNodeObject obj then continue
		if isMarkerObject obj then continue
		
		-- Check if object has no material assigned
		if obj.material == undefined then
		(
			append geometryWithoutMaterial obj.name
		)
	)
	
	if geometryWithoutMaterial.count > 0 then
	(
		local errorMsg = "Geometry objects without assigned materials:\n\n"
		for i = 1 to geometryWithoutMaterial.count do
		(
			errorMsg += "  • " + geometryWithoutMaterial[i] + "\n"
		)
		errorMsg += "\nAll geometry objects must have a material assigned."
		append errors errorMsg
	)
	
	-- Validation 4: Check for invalid material IDs in multi-sub-object materials
	local invalidMaterialIDs = #()
	
	for obj in objects do
	(
		if obj.isHidden then continue
		if not (isGeometryObject obj) then continue
		if isNodeObject obj then continue
		if isMarkerObject obj then continue
		if obj.material == undefined then continue
		
		-- Check if material is multi-sub-object
		if classOf obj.material == Multimaterial then
		(
			-- Get mesh data to check face material IDs
			local meshObj = undefined
			if classOf obj == Editable_mesh then
				meshObj = obj.mesh
			else
				meshObj = snapshotAsMesh obj
			
			if meshObj != undefined then
			(
				local numSubMats = obj.material.numsubs
				local invalidIDs = #()
				
				-- Check all face material IDs
				for f = 1 to meshObj.numfaces do
				(
					local faceMatID = getFaceMatID meshObj f
					
					-- Check if material ID is out of range
					if faceMatID < 1 or faceMatID > numSubMats then
					(
						if (findItem invalidIDs faceMatID) == 0 then
							append invalidIDs faceMatID
					)
				)
				
				-- Clean up snapshot if we created one
				if classOf obj != Editable_mesh then
					delete meshObj
				
				-- Add to error list if invalid IDs found
				if invalidIDs.count > 0 then
				(
					sort invalidIDs
					local idsString = ""
					for i = 1 to invalidIDs.count do
					(
						idsString += invalidIDs[i] as string
						if i < invalidIDs.count then idsString += ", "
					)
					
					local errorEntry = obj.name + " (Invalid IDs: " + idsString + ", Material has " + numSubMats as string + " sub-materials)"
					append invalidMaterialIDs errorEntry
				)
			)
		)
	)
	
	if invalidMaterialIDs.count > 0 then
	(
		local errorMsg = "Geometry with invalid material IDs:\n\n"
		for i = 1 to invalidMaterialIDs.count do
		(
			errorMsg += "  • " + invalidMaterialIDs[i] + "\n"
		)
		errorMsg += "\nAll face material IDs must exist in the assigned multi-sub-object material."
		append errors errorMsg
	)
	
	-- Validation 5: Check for markers linked to nodes without geometry
	local markersOnEmptyNodes = #()
	
	for obj in objects do
	(
		if obj.isHidden then continue
		if not (isMarkerObject obj) then continue
		if isPhysicsObject obj then continue  -- Skip physics/pathfinding objects (they don't need geometry)
		if obj.parent == undefined then continue
		
		-- Find the parent node (walk up hierarchy until we find a node)
		local parentNode = obj.parent
		while parentNode != undefined and not (isNodeObject parentNode) do
		(
			parentNode = parentNode.parent
		)
		
		if parentNode != undefined then
		(
			-- Check if this node has geometry linked or skinned to it
			if not (nodeHasGeometry parentNode) then
			(
				local errorEntry = obj.name + " (linked to node: " + parentNode.name + ")"
				append markersOnEmptyNodes errorEntry
			)
		)
	)
	
	if markersOnEmptyNodes.count > 0 then
	(
		local errorMsg = "Markers linked to nodes without geometry:\n\n"
		for i = 1 to markersOnEmptyNodes.count do
		(
			errorMsg += "  • " + markersOnEmptyNodes[i] + "\n"
		)
		errorMsg += "\nMarkers must be linked to nodes that have geometry attached.\nGeometry can be directly linked or skinned to the node or nested within containers/helpers."
		append errors errorMsg
	)
	
	-- Validation 6: Check for visible geometry linked to valid nodes
	local hasValidGeometry = false
	
	-- First, find root node
	local rootNode = undefined
	for obj in objects do
	(
		if (not obj.isHidden) and (isNodeObject obj) and obj.parent == undefined then
		(
			rootNode = obj
			exit
		)
	)
	
	-- If we have a root node, check for geometry
	if rootNode != undefined then
	(
		for obj in objects do
		(
			if obj.isHidden then continue
			if not (isGeometryObject obj) then continue
			if isNodeObject obj then continue
			if isMarkerObject obj then continue
			
			-- Check if geometry has a skin modifier (skinned geometry is valid)
			if (getSkinModifier obj) != undefined then
			(
				hasValidGeometry = true
				exit
			)
			
			-- Check if geometry is descendant of root node (directly linked geometry)
			local testParent = obj.parent
			local rootParent = undefined
			
			while testParent != undefined do
			(
				rootParent = testParent
				testParent = testParent.parent
			)
			
			if rootParent == rootNode then
			(
				hasValidGeometry = true
				exit
			)
		)
	)
	
	if not hasValidGeometry then
	(
		append errors "No visible geometry found in scene.\n\nAt least one visible geometry object must be linked to a valid node hierarchy for JMS export."
	)
	
	return errors
)

logger "JMS Validation loaded.\n" logType:#success
