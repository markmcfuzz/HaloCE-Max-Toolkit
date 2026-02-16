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
-- ANIMATION APPLICATION
-------------------------------------------------------

-- Apply animation keyframes to scene nodes
-- Returns: struct with success status and any missing nodes
fn applyAnimationToScene jmaData =
(
	local result = #(true, #())  -- [success, missingNodes]
	local missingNodeIndices = #()
	
	logger "\n=== APPLYING ANIMATION ===\n"
	logger "Frames: %\n" params:#(jmaData.frameCount) logType:#info
	logger "Frame Rate: %\n" params:#(jmaData.frameRate) logType:#info
	logger "Nodes: %\n" params:#(jmaData.nodeCount) logType:#info
	
	-- Set animation mode
	max tool animmode
	set animate on
	
	-- Set animation range (0-based frame indices)
	animationRange = interval 0 (jmaData.frameCount - 1)
	frameRate = jmaData.frameRate
	
	-- Process each frame
	for f = 1 to jmaData.frameCount do
	(
		local frameData = jmaData.frames[f]
		local frameIdx = f - 1  -- Convert to 0-based for 3ds Max timeline
		
		-- Process each node in this frame
		for n = 1 to jmaData.nodeCount do
		(
			local nodeName = jmaData.nodes[n].nodeName
			local sceneNode = getNodeByName nodeName
			
			if sceneNode != undefined then
			(
				local nodeFrame = frameData.nodeFrames[n]
				
				-- Convert rotation (negate i, j, k for Halo to 3ds Max conversion)
				local nodeRotation = quat \
					-nodeFrame.rotation.x \
					-nodeFrame.rotation.y \
					-nodeFrame.rotation.z \
					nodeFrame.rotation.w
				
				-- Get translation
				local nodeTranslation = nodeFrame.translation
				
				-- Get uniform scale as point3
				local nodeScale = [nodeFrame.scale, nodeFrame.scale, nodeFrame.scale]
				
				-- Add keyframes
				addNewKey sceneNode.rotation.controller frameIdx
				at time frameIdx (in coordsys parent sceneNode.rotation = nodeRotation)
				
				addNewKey sceneNode.position.controller frameIdx
				at time frameIdx (in coordsys parent sceneNode.position = nodeTranslation)
				
				addNewKey sceneNode.scale.controller frameIdx
				at time frameIdx (in coordsys parent sceneNode.scale = nodeScale)
			)
			else
			(
				-- Track missing nodes (only log once per node)
				if (findInArray missingNodeIndices n) == -1 then
				(
					append missingNodeIndices n
					append result[2] nodeName
					logger "Warning: Node not found in scene: '%'\n" params:#(nodeName) logType:#warning
				)
			)
		)
	)
	
	-- Exit animation mode
	max tool animmode
	set animate off
	
	-- Report results
	if missingNodeIndices.count > 0 then
	(
		logger "\nAnimation applied with % missing node(s)\n" params:#(missingNodeIndices.count) logType:#warning
	)
	else
	(
		logger "\nAnimation applied successfully to all nodes!\n" logType:#success
	)
	
	return result
)

-------------------------------------------------------
-- MAIN BUILD FUNCTION
-------------------------------------------------------

-- Build animation from JMA data
-- Returns: true if successful (with or without warnings), false if failed
fn buildJmaAnimation jmaData =
(
	if jmaData == undefined then
	(
		logger "Error: No JMA data provided\n" logType:#error
		return false
	)
	
	if jmaData.frameCount == undefined or jmaData.frameCount == 0 then
	(
		logger "Error: No frames to import\n" logType:#error
		return false
	)
	
	if jmaData.nodeCount == undefined or jmaData.nodeCount == 0 then
	(
		logger "Error: No nodes in animation\n" logType:#error
		return false
	)
	
	-- Apply animation to scene
	local result = applyAnimationToScene jmaData
	local success = result[1]
	local missingNodes = result[2]
	
	-- Return success even if some nodes were missing (user may want partial import)
	return true
)

-- Get list of missing nodes from jmaData compared to scene
fn getMissingNodes jmaData =
(
	local missing = #()
	
	for node in jmaData.nodes do
	(
		local sceneNode = getNodeByName node.nodeName
		if sceneNode == undefined then
			append missing node.nodeName
	)
	
	return missing
)

logger "JMA Build Scene module loaded.\n" logType:#success
