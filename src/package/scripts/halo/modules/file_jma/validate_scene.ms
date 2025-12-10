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
	
	-- Validation 2: Check for animation keyframes on at least one node
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
				
				-- Check for position keyframes
				if obj.position.controller != undefined and obj.position.controller.keys != undefined and obj.position.controller.keys.count > 0 then
				(
					hasAnimation = true
					exit
				)
				
				-- Check for rotation keyframes
				if obj.rotation.controller != undefined and obj.rotation.controller.keys != undefined and obj.rotation.controller.keys.count > 0 then
				(
					hasAnimation = true
					exit
				)
				
				-- Check for scale keyframes
				if obj.scale.controller != undefined and obj.scale.controller.keys != undefined and obj.scale.controller.keys.count > 0 then
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
			)
		)
		
		if not hasAnimation then
		(
			local frameRangeStr = (startFrame as string) + " to " + (endFrame as string)
			append errors ("No animation keyframes detected.\n\nAt least one node must have animation keyframes (position, rotation, or scale).\nAnimation range: frames " + frameRangeStr)
		)
	)
	
	return errors
)

logger "JMA Validate Scene loaded.\n" logType:#success
