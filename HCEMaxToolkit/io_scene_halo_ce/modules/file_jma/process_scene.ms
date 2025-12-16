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
-- HIERARCHY BUILDING
-------------------------------------------------------

-- Recursive helper to collect nodes with depth prefix
fn collectNodesRecursive obj depth nodeArray =
(
	if obj == undefined or obj.isHidden or (not isNodeObject obj) then
		return false
	
	-- Create prefixed name based on hierarchy depth
	local prefixedName = ""
	if depth < 10 then
		prefixedName = "0" + (depth as string) + obj.name
	else
		prefixedName = (depth as string) + obj.name
	
	-- Store as array: [object, prefixedName]
	append nodeArray #(obj, prefixedName)
	
	-- Process all children recursively
	for child in obj.children do
	(
		collectNodesRecursive child (depth + 1) nodeArray
	)
	
	return true
)

-- Build flat array of all valid nodes in scene (visible only)
-- Uses hierarchy depth prefix + alphabetical sorting
fn collectSceneNodes =
(
	local nodeArray = #()
	local tempNodeArray = #()
	local sceneParent = undefined
	
	-- First, find the root node
	for obj in objects do
	(
		if (not obj.isHidden) and (isNodeObject obj) and obj.parent == undefined then
		(
			if sceneParent != undefined then
				return #()
			sceneParent = obj
		)
	)
	
	if sceneParent == undefined then
		return #()
	
	-- Collect all nodes with hierarchy depth prefix
	collectNodesRecursive sceneParent 1 tempNodeArray
	
	-- Sort by prefixed names (this creates hierarchical order)
	fn compareByPrefixedName a b =
	(
		if a[2] < b[2] then return -1
		else if a[2] > b[2] then return 1
		else return 0
	)
	
	qsort tempNodeArray compareByPrefixedName
	
	-- Extract just the objects (remove prefixes)
	for i = 1 to tempNodeArray.count do
	(
		append nodeArray tempNodeArray[i][1]
	)
	
	return nodeArray
)

-- Build sorted child indices array for each node
fn buildChildIndicesArrays nodeArray =
(
	local childIndicesArray = #()
	
	for n = 1 to nodeArray.count do
	(
		local tempChildIndices = #()
		
		-- Collect all valid child indices
		for child in nodeArray[n].children do
		(
			if child != undefined then
			(
				-- Find child index in node array (1-based)
				for i = 1 to nodeArray.count do
				(
					if nodeArray[i] == child then
					(
						append tempChildIndices i
						exit
					)
				)
			)
		)
		
		-- Sort child indices (critical for correct hierarchy)
		if tempChildIndices.count > 0 then
			sort tempChildIndices
		
		childIndicesArray[n] = tempChildIndices
	)
	
	return childIndicesArray
)

-- Get first child node index using sorted child indices
fn getFirstChildIndex nodeIndex childIndicesArray =
(
	if childIndicesArray[nodeIndex].count == 0 then
		return -1
	else
		return (childIndicesArray[nodeIndex][1] - 1)  -- Convert to 0-based
)

-- Get next sibling index using sorted child indices
fn getNextSiblingIndex nodeIndex childIndicesArray =
(
	-- Find which parent's child array contains this node
	for parentIdx = 1 to childIndicesArray.count do
	(
		local children = childIndicesArray[parentIdx]
		
		-- Find this node in the parent's sorted children
		for childPos = 1 to children.count do
		(
			if children[childPos] == nodeIndex then
			(
				-- If this is the last child, no next sibling
				if childPos == children.count then
					return -1
				else
					return (children[childPos + 1] - 1)  -- Convert to 0-based
			)
		)
	)
	
	return -1  -- No parent found or is root node
)

-------------------------------------------------------
-- TRANSFORM EXTRACTION
-------------------------------------------------------

-- Convert 3ds Max rotation to quaternion (i, j, k, w)
fn getNodeRotationQuat obj =
(
	local rotQuat = undefined
	
	-- Handle Biped objects differently
	if classOf obj == Biped_Object then
	(
		-- For Biped objects, use biped.getTransform
		if obj.parent == undefined then
		(
			-- Root biped object - no coordinate conversion
			rotQuat = biped.getTransform obj #rotation
		)
		else
		(
			-- Child biped - get rotation in parent space using temporary meshes
			local m = mesh vertices:#() faces:#()
			local mp = mesh vertices:#() faces:#()
			m.parent = mp
			
			-- Get parent rotation (always use biped.getTransform)
			local mpRot = biped.getTransform obj.parent #rotation
			mp.rotation = quat -mpRot.x -mpRot.y -mpRot.z mpRot.w
			mp.pos = biped.getTransform obj.parent #pos
			
			-- Get child rotation with coordinate conversion
			local mRot = biped.getTransform obj #rotation
			m.rotation = quat -mRot.x -mRot.y -mRot.z mRot.w
			m.pos = biped.getTransform obj #pos
			
			-- Get rotation in parent space
			in coordsys parent rotQuat = m.rotation
			
			-- Apply coordinate conversion again
			rotQuat = normalize (quat -rotQuat.x -rotQuat.y -rotQuat.z rotQuat.w)
			
			delete m
			delete mp
		)
	)
	else if isCATObject obj then
	(
		-- CAT objects - use specialized CAT transform extraction
		local catRotArray = getCATRotationQuat obj
		if catRotArray != undefined then
			return catRotArray
		else
			return #(0, 0, 0, 1)  -- Identity quaternion as fallback
	)
	else
	(
		-- Regular objects - get rotation in parent space
		in coordsys parent rotQuat = normalize obj.rotation
		
		-- Apply coordinate conversion (negate x, y, z)
		rotQuat = quat -rotQuat.x -rotQuat.y -rotQuat.z rotQuat.w
	)
	
	-- Normalize to ensure unit quaternion
	rotQuat = normalize rotQuat
	
	-- Return as array (already converted)
	return #(rotQuat.x, rotQuat.y, rotQuat.z, rotQuat.w)
)

-- Get node translation in parent space
fn getNodeTranslation obj =
(
	local pos
	
	-- Handle Biped objects differently
	if classOf obj == Biped_Object then
	(
		-- For Biped objects, use biped.getTransform
		if obj.parent == undefined then
		(
			pos = biped.getTransform obj #pos
		)
		else
		(
			-- Get position in parent space using temporary meshes
			local m = mesh vertices:#() faces:#()
			local mp = mesh vertices:#() faces:#()
			m.parent = mp
			
			-- Always use biped.getTransform for parent and apply coordinate conversion
			local mpRot = biped.getTransform obj.parent #rotation
			mp.rotation = quat -mpRot.x -mpRot.y -mpRot.z mpRot.w
			mp.pos = biped.getTransform obj.parent #pos
			
			-- Get child transform with coordinate conversion
			local mRot = biped.getTransform obj #rotation
			m.rotation = quat -mRot.x -mRot.y -mRot.z mRot.w
			m.pos = biped.getTransform obj #pos
			in coordsys parent pos = m.pos
			delete m
			delete mp
		)
	)
	else if isCATObject obj then
	(
		-- CAT objects - use specialized CAT transform extraction
		local catPosArray = getCATTranslation obj
		if catPosArray != undefined then
			return catPosArray
		else
			return #(0, 0, 0)  -- Origin as fallback
	)
	else
	(
		-- Regular objects - get position in parent space
		pos = in coordsys parent obj.pos
	)
	
	-- Return as array: [x, y, z]
	return #(pos.x, pos.y, pos.z)
)

-- Get node scale (uniform scale value)
fn getNodeScale obj =
(
	-- Handle Biped objects differently - they don't have a scale property
	if classOf obj == Biped_Object then
	(
		-- Biped objects always have scale of 1.0
		return 1.0
	)
	else if isCATObject obj then
	(
		-- CAT objects - return default scale
		return 1.0
	)
	else
	(
		-- For JMA, we typically use uniform scale
		-- Get the average of all three scale components
		local scaleVec = in coordsys parent obj.scale
		local uniformScale = (scaleVec.x + scaleVec.y + scaleVec.z) / 3.0
		
		return uniformScale
	)
)

-------------------------------------------------------
-- NODE DATA EXTRACTION
-------------------------------------------------------

-- Extract all node data from scene
fn extractNodeData =
(
	-- Collect all valid nodes
	local nodeArray = collectSceneNodes()
	
	if nodeArray.count == 0 then
		return #(#(), #())  -- Return both empty arrays
	
	-- Build sorted child indices arrays (critical for correct hierarchy)
	local childIndicesArray = buildChildIndicesArrays nodeArray
	
	-- Build node data structures
	local nodeDataArray = #()
	
	for i = 1 to nodeArray.count do
	(
		local obj = nodeArray[i]
		
		-- Create node struct
		local nodeData = jmaNodes()
		nodeData.nodeName = obj.name
		nodeData.firstChildNodeIndex = getFirstChildIndex i childIndicesArray
		nodeData.nextSiblingNodeIndex = getNextSiblingIndex i childIndicesArray
		
		append nodeDataArray nodeData
	)
	
	-- Return both node data array and original object array
	return #(nodeDataArray, nodeArray)
)

-------------------------------------------------------
-- KEYFRAME DATA EXTRACTION
-------------------------------------------------------

-- Extract keyframe data for all nodes across all frames
fn extractKeyframeData nodeArray =
(
	local keyframeDataArray = #()
	
	if nodeArray.count == 0 then
		return keyframeDataArray
	
	-- Get animation range
	local startFrame = animationRange.start.frame as integer
	local endFrame = animationRange.end.frame as integer
	local frameCount = endFrame - startFrame + 1
	
	-- Iterate through each frame
	for frameNum = startFrame to endFrame do
	(
		-- Set current time to this frame
		sliderTime = frameNum as time
		
		-- Create keyframe struct for this frame
		local keyframeData = jmaKeyframes()
		keyframeData.nodeTranslation = #()
		keyframeData.nodeRotation = #()
		keyframeData.nodeScale = #()
		
		-- Extract transform data for each node at this frame
		for obj in nodeArray do
		(
			-- Get translation
			local trans = getNodeTranslation obj
			append keyframeData.nodeTranslation trans
			
			-- Get rotation
			local rot = getNodeRotationQuat obj
			append keyframeData.nodeRotation rot
			
			-- Get scale
			local scl = getNodeScale obj
			append keyframeData.nodeScale scl
		)
		
		append keyframeDataArray keyframeData
	)
	
	return keyframeDataArray
)

-------------------------------------------------------
-- MAIN SCENE PROCESSOR
-------------------------------------------------------

fn processSceneForJMA =
(
	local startTime = timestamp()
	
	-- Validate scene before processing
	local validationErrors = validateSceneForExport()
	if validationErrors.count > 0 then
	(
		-- Show all errors in a single message box
		local errorMsg = "Cannot export JMA file. Please fix the following issues:\n\n"
		for i = 1 to validationErrors.count do
		(
			errorMsg += validationErrors[i]
			if i < validationErrors.count then
				errorMsg += "\n\n========================================\n\n"
		)
		
		messageBox errorMsg title:"JMA Export Validation Failed" beep:false
		return undefined
	)
	
	-- Create main JMA structure
	local jmaData = jmaFile()
	
	-- Set hardcoded values
	jmaData.jmaVersion = 16392
	jmaData.frameRate = 30
	jmaData.actorNamesIndex = 1
	jmaData.actorNames = "unnamedActor"
	jmaData.nodeChecksum = 0
	
	-- Extract node data
	local nodeStartTime = timestamp()
	local extractResult = extractNodeData()
	local nodeDataArray = extractResult[1]
	local nodeObjectArray = extractResult[2]
	jmaData.nodes = nodeDataArray
	jmaData.nodeCount = nodeDataArray.count
	local nodeTime = timestamp() - nodeStartTime
	logger "Node extraction: % ms (% nodes)\n" params:#(nodeTime, nodeDataArray.count) logType:#timestamp
	
	-- Get frame count from animation range
	local startFrame = animationRange.start.frame as integer
	local endFrame = animationRange.end.frame as integer
	jmaData.frameCount = endFrame - startFrame + 1
	
	-- Extract keyframe data for all nodes across all frames
	local keyframeStartTime = timestamp()
	local keyframeDataArray = extractKeyframeData nodeObjectArray
	jmaData.keyframes = keyframeDataArray
	local keyframeTime = timestamp() - keyframeStartTime
	logger "Keyframe extraction: % ms (% frames)\n" params:#(keyframeTime, keyframeDataArray.count) logType:#timestamp
	
	local totalTime = timestamp() - startTime
	format "TOTAL TIME: % ms\n" totalTime
	format "=============================\n\n"
	
	return jmaData
)

logger "JMA Process Scene loaded.\n" logType:#success