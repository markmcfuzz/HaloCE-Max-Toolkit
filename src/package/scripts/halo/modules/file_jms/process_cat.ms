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
-- CAT (Character Animation Toolkit) SUPPORT
-------------------------------------------------------
-- This module provides support for exporting CAT rigs to JMS format.
-- CAT is a modern character animation system in 3ds Max that provides
-- more flexibility than the legacy Biped system.
-------------------------------------------------------

-------------------------------------------------------
-- DETECTION FUNCTIONS
-------------------------------------------------------

-- Check if an object is a CAT bone
fn isCATObject obj =
(
	if obj == undefined then return false
	
	-- CAT bones are typically of class CATBone
	-- Additional checks may be needed for different CAT bone types
	local objClass = classOf obj
	local objClassName = objClass as string
	local objSuperClass = superClassOf obj
	
	-- Check for common CAT bone classes
	if objClass == CATBone then return true
	
	-- Check for CAT Hub (the root controller object in CAT rigs)
	if objClassName == "CATParent" then return true
	if objClassName == "Hub" then return true
	
	-- Check for UndefinedClass objects (plugin objects like CAT Hub)
	-- These often have "CAT" or specific properties we can check
	if objClassName == "UndefinedClass" then
	(
		-- Check if object name contains CAT-related patterns (case-insensitive)
		if matchPattern obj.name pattern:"*Hub*" ignoreCase:true then return true
		if matchPattern obj.name pattern:"*Spider*" ignoreCase:true then return true
		
		-- Check for CAT-specific properties
		if (hasProperty obj #CATRigParent) then return true
		if (hasProperty obj #CATParent) then return true
		if (hasProperty obj #limbType) then return true
		if (hasProperty obj #CATUnits) then return true
		
		-- Check if superclass suggests it's part of a rig
		if objSuperClass == helper then
		(
			-- If it has CAT bone children, it's likely a CAT component
			for child in obj.children do
			(
				if classOf child == CATBone then
					return true
			)
		)
	)
	
	-- Some CAT bones might have different class names
	-- Check if the object has CAT-specific properties
	if (hasProperty obj #CATRigParent) then return true
	if (hasProperty obj #CATParent) then return true
	
	-- Final fallback: Check if object has CATBone children
	-- This catches CAT Hub objects (HubObject class) regardless of their class or superclass
	for child in obj.children do
	(
		if classOf child == CATBone then
			return true
	)
	
	return false
)

-- Get CAT rig root (similar to finding Biped root)
fn getCATRigRoot obj =
(
	if not (isCATObject obj) then return undefined
	
	-- Walk up the hierarchy to find the root CAT bone
	local rootObj = obj
	while rootObj.parent != undefined do
	(
		if isCATObject rootObj.parent then
			rootObj = rootObj.parent
		else
			exit
	)
	
	return rootObj
)

-------------------------------------------------------
-- TRANSFORM EXTRACTION
-------------------------------------------------------

-- Extract rotation quaternion from CAT bone
-- Returns as array: [i, j, k, w] with coordinate conversion applied
fn getCATRotationQuat obj =
(
	if not (isCATObject obj) then return undefined
	
	local rotQuat = undefined
	
	-- CAT bones need temporary meshes like Biped to properly extract rotations
	try
	(
		-- Get the transform matrix
		local tm = obj.transform
		
		-- Check if this is a root CAT bone (no CAT parent)
		if obj.parent == undefined or not (isCATObject obj.parent) then
		(
			-- Root CAT bone - extract rotation from world transform
			rotQuat = tm.rotationpart as quat
			
			-- No coordinate conversion for root (matching Biped root behavior)
		)
		else
		(
			-- Child CAT bone - use temporary meshes like Biped implementation
			local m = mesh vertices:#() faces:#()
			local mp = mesh vertices:#() faces:#()
			m.parent = mp
			
			-- Get parent transform
			local parentTM = obj.parent.transform
			local mpRot = parentTM.rotationpart as quat
			mp.rotation = quat -mpRot.x -mpRot.y -mpRot.z mpRot.w
			mp.pos = parentTM.translationpart
			
			-- Get child transform with coordinate conversion
			local mRot = tm.rotationpart as quat
			m.rotation = quat -mRot.x -mRot.y -mRot.z mRot.w
			m.pos = tm.translationpart
			
			-- Get rotation in parent space
			in coordsys parent rotQuat = m.rotation
			
			-- Apply coordinate conversion again
			rotQuat = normalize (quat -rotQuat.x -rotQuat.y -rotQuat.z rotQuat.w)
			
			delete m
			delete mp
		)
		
		-- Normalize to ensure unit quaternion
		rotQuat = normalize rotQuat
	)
	catch
	(
		format "ERROR: Could not extract rotation from CAT bone %\n" obj.name
		return undefined
	)
	
	-- Return as array
	return #(rotQuat.x, rotQuat.y, rotQuat.z, rotQuat.w)
)

-- Extract translation from CAT bone
-- Returns as array: [x, y, z] in parent space
fn getCATTranslation obj =
(
	if not (isCATObject obj) then return undefined
	
	local pos
	
	try
	(
		-- Get the transform matrix
		local tm = obj.transform
		
		-- Check if this is a root CAT bone
		if obj.parent == undefined or not (isCATObject obj.parent) then
		(
			-- Root CAT bone - get world position
			pos = tm.translationpart
		)
		else
		(
			-- Child CAT bone - use temporary meshes like Biped implementation
			local m = mesh vertices:#() faces:#()
			local mp = mesh vertices:#() faces:#()
			m.parent = mp
			
			-- Get parent transform with coordinate conversion
			local parentTM = obj.parent.transform
			local mpRot = parentTM.rotationpart as quat
			mp.rotation = quat -mpRot.x -mpRot.y -mpRot.z mpRot.w
			mp.pos = parentTM.translationpart
			
			-- Get child transform with coordinate conversion
			local mRot = tm.rotationpart as quat
			m.rotation = quat -mRot.x -mRot.y -mRot.z mRot.w
			m.pos = tm.translationpart
			
			-- Get position in parent space
			in coordsys parent pos = m.pos
			
			delete m
			delete mp
		)
	)
	catch
	(
		format "ERROR: Could not extract translation from CAT bone %\n" obj.name
		return undefined
	)
	
	-- Return as array
	return #(pos.x, pos.y, pos.z)
)

-------------------------------------------------------
-- VALIDATION FUNCTIONS
-------------------------------------------------------

-- Validate CAT rig structure for export
fn validateCATRig rootObj =
(
	local errors = #()
	
	if not (isCATObject rootObj) then
	(
		append errors "Object is not a CAT bone"
		return errors
	)
	
	-- Add validation checks as needed:
	-- - Check for valid bone hierarchy
	-- - Verify transform data is accessible
	-- - Check for animation conflicts
	
	return errors
)

-------------------------------------------------------
-- DEBUG/TESTING FUNCTIONS
-------------------------------------------------------

-- Print CAT bone hierarchy for debugging
fn printCATHierarchy obj indent:0 =
(
	if not (isCATObject obj) then
	(
		format "% is not a CAT object\n" obj.name
		return false
	)
	
	local indentStr = ""
	for i = 1 to indent do indentStr += "  "
	
	format "%%\n" indentStr obj.name
	format "%  Class: %\n" indentStr (classOf obj)
	
	-- CAT bones use transform matrix instead of .pos and .rotation
	local tm = obj.transform
	format "%  Position: %\n" indentStr tm.translationpart
	format "%  Rotation: %\n" indentStr (tm.rotationpart as quat)
	
	-- Process children
	for child in obj.children do
	(
		if isCATObject child then
			printCATHierarchy child indent:(indent + 1)
	)
	
	return true
)

-- Test CAT transform extraction
fn testCATTransforms obj =
(
	if not (isCATObject obj) then
	(
		format "% is not a CAT object\n" obj.name
		return false
	)
	
	format "\n=== Testing CAT Transforms for: % ===\n" obj.name
	format "Class: %\n" (classOf obj)
	format "Has parent: %\n" (obj.parent != undefined)
	
	if obj.parent != undefined then
		format "Parent is CAT: %\n" (isCATObject obj.parent)
	
	-- Test rotation extraction
	local rot = getCATRotationQuat obj
	if rot != undefined then
		format "Rotation (i,j,k,w): %, %, %, %\n" rot[1] rot[2] rot[3] rot[4]
	else
		format "ERROR: Could not extract rotation\n"
	
	-- Test translation extraction
	local pos = getCATTranslation obj
	if pos != undefined then
		format "Translation (x,y,z): %, %, %\n" pos[1] pos[2] pos[3]
	else
		format "ERROR: Could not extract translation\n"
	
	format "\n"
	return true
)

logger "Process CAT loaded.\n" logType:#success
