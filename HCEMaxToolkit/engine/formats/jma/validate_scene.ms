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
-- CONSTRAINT AND HELPER DETECTION
-------------------------------------------------------

-- Check if an object has any animation on its controllers
fn objectHasKeyframes obj =
(
	if obj == undefined then return false
	
	-- Check for position keyframes
	if obj.position.controller != undefined and obj.position.controller.keys != undefined and obj.position.controller.keys.count > 0 then
		return true
	
	-- Check for rotation keyframes
	if obj.rotation.controller != undefined and obj.rotation.controller.keys != undefined and obj.rotation.controller.keys.count > 0 then
		return true
	
	-- Check for scale keyframes
	if obj.scale.controller != undefined and obj.scale.controller.keys != undefined and obj.scale.controller.keys.count > 0 then
		return true
	
	return false
)

-- Get all helpers (splines, dummies, etc.) that have keyframes
fn getAnimatedHelpers =
(
	local animatedHelpers = #()
	
	for obj in objects do
	(
		if obj.isHidden then continue
		if isNodeObject obj then continue  -- Skip node objects
		
		-- Check if this is a helper with animation
		if objectHasKeyframes obj then
		(
			append animatedHelpers obj
		)
	)
	
	return animatedHelpers
)

-- Recursively check if a constraint controller exists
fn hasConstraintController controller =
(
	if controller == undefined then return false
	
	-- Check if this is a constraint (constraint controllers have refs to target objects)
	if classOf controller == Link_Constraint then return true
	if classOf controller == Position_Constraint then return true
	if classOf controller == Rotation_Constraint then return true
	if classOf controller == Scale_Constraint then return true
	if classOf controller == Point3_Constraint then return true
	if classOf controller == Orientation_Constraint then return true
	if classOf controller == LookAt_Constraint then return true
	if classOf controller == Surface_Constraint then return true
	if classOf controller == Path_Constraint then return true
	if classOf controller == LookAtConstraint then return true
	
	return false
)

-- Get constraint target objects for a specific transform type
fn getConstraintTargets obj transformType =
(
	local targets = #()
	local controller = undefined
	
	case transformType of
	(
		#position: controller = obj.position.controller
		#rotation: controller = obj.rotation.controller
		#scale: controller = obj.scale.controller
	)
	
	if controller != undefined and hasConstraintController controller then
	(
		-- Try to get target objects from the constraint
		try
		(
			if hasProperty controller #target then
			(
				append targets controller.target
			)
		)
		catch()
		
		-- For constraints with multiple targets, try to enumerate them
		try
		(
			for i = 1 to controller.numNodes do
			(
				local targetNode = controller.getNode i
				if targetNode != undefined then
					append targets targetNode
			)
		)
		catch()
	)
	
	return targets
)

-- Get all objects that affect a given node through constraints
fn getConstraintSourceObjects obj =
(
	local sources = #()
	
	-- Check position constraint
	local posTargets = getConstraintTargets obj #position
	for target in posTargets do
	(
		if target != undefined and findItem sources target == 0 then
			append sources target
	)
	
	-- Check rotation constraint
	local rotTargets = getConstraintTargets obj #rotation
	for target in rotTargets do
	(
		if target != undefined and findItem sources target == 0 then
			append sources target
	)
	
	-- Check scale constraint
	local scaleTargets = getConstraintTargets obj #scale
	for target in scaleTargets do
	(
		if target != undefined and findItem sources target == 0 then
			append sources target
	)
	
	return sources
)

-- Check if a node is affected by animated constraints
fn nodeHasConstraintAnimation obj =
(
	local constraintSources = getConstraintSourceObjects obj
	
	for source in constraintSources do
	(
		if objectHasKeyframes source then
			return true
	)
	
	return false
)

-------------------------------------------------------
-- SCENE VALIDATION FOR JMA EXPORT
-------------------------------------------------------

-- Validate scene before export and return error messages if any
fn validateSceneForExport =
(
	local errors = #()
	
	-- Validation 1: Check for valid root node
	local rootNode = undefined
	local rootNodeCount = 0
	
	for obj in objects do
	(
		if obj.isHidden then continue
		
		-- Direct root node (no parent)
		if (isNodeObject obj) and obj.parent == undefined then
		(
			rootNode = obj
			rootNodeCount += 1
		)
		-- Node parented to a helper container (e.g., Editable Spline for rotation)
		else if obj.parent != undefined and \
		        obj.parent.parent == undefined and \
		        (not obj.parent.isHidden) and \
		        (isNodeObject obj) and \
		        (isHelperContainer obj.parent) then
		(
			-- Check if this is the only node child of the helper
			local siblingNodeCount = 0
			for sibling in obj.parent.children do
			(
				if (isNodeObject sibling) and (not sibling.isHidden) then
					siblingNodeCount += 1
			)
			
			if siblingNodeCount == 1 then
			(
				rootNode = obj
				rootNodeCount += 1
			)
		)
	)
	
	if rootNodeCount == 0 then
	(
		append errors "No valid root node found.\n\nA root node must exist and be visible.\nRoot nodes must have a prefix: 'b', 'b_', 'bone', 'frame', or 'bip01'\n\nNote: Root nodes can be parented to helper objects (Splines, Dummies, Points) for rotation control."
	)
	else if rootNodeCount > 1 then
	(
		append errors "Multiple root nodes found.\n\nOnly one root node (visible, no parent or parented to a single helper container) is allowed."
	)
	
	-- Validation 2: Check for animation keyframes on at least one node or through constraints
	if rootNode != undefined then
	(
		local hasAnimation = false
		local startFrame = animationRange.start.frame as integer
		local endFrame = animationRange.end.frame as integer
		
		-- Check if animation range has more than one frame
		if (endFrame - startFrame) > 0 then
		(
			-- Check if any visible node has keyframes
			for obj in objects do
			(
				if obj.isHidden then continue
				if not (isNodeObject obj) then continue
				
				-- Check for direct keyframes
				if objectHasKeyframes obj then
				(
					hasAnimation = true
					exit
				)
				
				-- Check for biped controller (always has animation data if it exists)
				if classOf obj == Biped_Object then
				(
					hasAnimation = true
					exit
				)
				
				-- Check for CAT controller
				if isCATObject obj then
				(
					hasAnimation = true
					exit
				)
				
				-- Check if node has constraint animation
				if nodeHasConstraintAnimation obj then
				(
					hasAnimation = true
					exit
				)
			)
			
			-- Also check for animated helpers if no direct node animation found
			if not hasAnimation then
			(
				local animatedHelpers = getAnimatedHelpers()
				if animatedHelpers.count > 0 then
				(
					hasAnimation = true
				)
			)
		)
		
		if not hasAnimation then
		(
			local frameRangeStr = (startFrame as string) + " to " + (endFrame as string)
			append errors ("No animation keyframes detected.\n\nAt least one node must have animation keyframes (position, rotation, or scale),\nor animation must come through link/position/rotation constraints.\nAnimation range: frames " + frameRangeStr)
		)
	)
	
	return errors
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)