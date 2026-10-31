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

-- mesh_normals.ms is loaded by init.ms; load it if Max still runs an older toolkit
global meshNormalsSave
if meshNormalsSave == undefined and rootEngine != undefined do
	fileIn (rootEngine + "shared\\utils\\mesh_normals.ms")

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
-- Uses hierarchy depth prefix + alphabetical sorting (matches old exporter exactly)
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

-- Get index of object in node array (-1 if not found)
fn getNodeIndex obj nodeArray =
(
	if obj == undefined then return -1
	
	for i = 1 to nodeArray.count do
	(
		if nodeArray[i] == obj then
			return (i - 1)  -- Convert to 0-based index
	)
	
	return -1
)

-- Build sorted child indices array for each node
-- This matches the old exporter's approach: collect children, sort by index
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
-- This matches old exporter: siblings are linked in sorted order
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
		-- Regular objects: decompose the evaluated world transform matrix.
		-- Do NOT read obj.rotation / in coordsys parent here: those return the
		-- raw PRS controller value, which is a constant offset when the node is
		-- driven at the transform-controller level (Link Constraint, IK, helper
		-- rigs). obj.transform is always the fully evaluated result.
		-- Note: matrix rotationpart already matches the JMS quat convention,
		-- so no x/y/z negation is needed (unlike .rotation property reads)
		local tm = obj.transform
		if obj.parent != undefined then
			tm = tm * inverse obj.parent.transform
		rotQuat = tm.rotationpart
	)
	
	-- Normalize to ensure unit quaternion
	rotQuat = normalize rotQuat
	
	-- Return as array (already converted)
	return #(rotQuat.x, rotQuat.y, rotQuat.z, rotQuat.w)
)

-- Get node translation in parent space
fn getNodeTranslation obj parentNode:undefined =
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
		-- Regular objects
		-- If parentNode is provided (for markers parented to skinned geometry),
		-- transform from world space to that node's space
		if parentNode != undefined then
			pos = obj.pos * inverse(parentNode.transform)  -- World to parent node space
		else
		(
			-- Decompose the evaluated world transform matrix
			-- (see getNodeRotationQuat for why property reads are not used here)
			local tm = obj.transform
			if obj.parent != undefined then
				tm = tm * inverse obj.parent.transform
			pos = tm.translationpart
		)
	)
	
	-- Return as array: [x, y, z]
	return #(pos.x, pos.y, pos.z)
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
		local nodeData = nodes()
		nodeData.nodeName = obj.name
		nodeData.firstChildNodeIndex = getFirstChildIndex i childIndicesArray
		nodeData.nextSiblingNodeIndex = getNextSiblingIndex i childIndicesArray
		nodeData.nodeRotation = getNodeRotationQuat obj
		nodeData.nodeTranslation = getNodeTranslation obj
		
		append nodeDataArray nodeData
	)
	
	-- Return both node data array and original object array
	return #(nodeDataArray, nodeArray)
)

-------------------------------------------------------
-- MARKER DATA EXTRACTION
-------------------------------------------------------

-- Extract all marker data from scene
fn extractMarkerData nodeArray =
(
	if nodeArray.count == 0 then
		return #()
	
	local markerDataArray = #()
	
	-- Find root node to check descendants
	local rootNode = nodeArray[1]
	
	-- Collect all objects in scene
	for obj in objects do
	(
		if obj.isHidden then continue
		if not (isMarkerObject obj) then continue
		if obj.parent == undefined then continue
		
		-- Check if marker is descendant of root node
		local testParent = obj.parent
		local rootParent = undefined
		
		while testParent != undefined do
		(
			rootParent = testParent
			testParent = testParent.parent
		)
		
		-- Only include markers that share same root as nodes
		if rootParent != rootNode then continue
		
		-- Find parent node index in node array
		-- If marker is parented to geometry, walk up to find the parent node
		local parentNodeObj = obj.parent
		while parentNodeObj != undefined and not (isNodeObject parentNodeObj) do
		(
			parentNodeObj = parentNodeObj.parent
		)
		
		local parentIndex = -1
		if parentNodeObj != undefined then
		(
			for i = 1 to nodeArray.count do
			(
				if nodeArray[i] == parentNodeObj then
				(
					parentIndex = i - 1  -- Convert to 0-based
					exit
				)
			)
		)
		
		-- Create marker data
		local markerData = markers()
		markerData.markerName = substring obj.name 2 -1  -- Remove '#' prefix
		markerData.markerRegion = -1  -- Default region
		markerData.parentNodeIndex = parentIndex
		markerData.markerRotation = getNodeRotationQuat obj
		-- If marker is parented to skinned geometry, pass the parent node for proper space conversion
		if obj.parent != undefined and (getSkinModifier obj.parent) != undefined then
			markerData.markerTranslation = getNodeTranslation obj parentNode:parentNodeObj
		else
			markerData.markerTranslation = getNodeTranslation obj
		
		-- Get marker radius based on object type
		-- For HaloHelper objects, use markerRadius parameter
		-- For legacy sphere objects, use radius property
		local markerRadius = 1.0  -- Default
		
		if classOf obj == HaloMarker then
		(
			-- HaloMarker object - read from custom attributes
			if hasProperty obj #markerRadius then
				markerRadius = obj.markerRadius
		)
		else if hasProperty obj #radius then
		(
			-- Legacy sphere object - read radius property
			markerRadius = obj.radius
		)
		
		markerData.markerRadius = markerRadius
		
		append markerDataArray markerData
	)
	
	return markerDataArray
)

-------------------------------------------------------
-- SHADER AND REGION EXTRACTION
-------------------------------------------------------

-- Extract unique materials/shaders from geometry objects
fn extractShaders nodeObjectArray =
(
	local shaderArray = #()
	local shaderNames = #()
	local rootNode = nodeObjectArray[1]
	
	-- Helper function to extract bitmap path from a material
	fn getBitmapPathFromMaterial mat =
	(
		local bitmapPath = "<none>"
		try
		(
			local bitmapMap = undefined
			
			-- Check for Physical Material (base_color_map)
			if classOf mat == Physical_Material then
				bitmapMap = mat.base_color_map
			-- Check for Standard Material (diffuseMap)
			else if hasProperty mat #diffuseMap then
				bitmapMap = mat.diffuseMap
			
			if bitmapMap != undefined then
			(
				local fullPath = try (bitmapMap.filename) catch (undefined)
				if fullPath != undefined and fullPath != "" then
				(
					-- Remove file extension to support multiple formats
					local pathOnly = getFilenamePath fullPath
					local fileOnly = getFilenameFile fullPath
					bitmapPath = pathOnly + fileOnly
				)
			)
		)
		catch ()
		
		return bitmapPath
	)
	
	-- Collect all geometry objects
	for obj in objects do
	(
		if obj.isHidden then continue
		if not (isGeometryObject obj) then continue
		if obj.parent == undefined then continue
		if isNodeObject obj then continue
		if isMarkerObject obj then continue
		
		-- Check if geometry is descendant of root node
		local testParent = obj.parent
		local rootParent = undefined
		while testParent != undefined do
		(
			rootParent = testParent
			testParent = testParent.parent
		)
		if rootParent != rootNode then continue
		
		-- Get mesh data to check face material IDs
		local meshObj = snapshotAsMesh obj
		
		-- Get material from object
		if obj.material != undefined then
		(
			-- Check if it's a Multi/Sub-Object material
			if classOf obj.material == Multimaterial then
			(
				-- Iterate through all faces to find used sub-materials
				for f = 1 to meshObj.numfaces do
				(
					local faceMatID = getFaceMatID meshObj f
					
					-- Get the sub-material for this face
					if faceMatID > 0 and faceMatID <= obj.material.count then
					(
						local subMat = obj.material[faceMatID]
						if subMat != undefined then
						(
							local matName = subMat.name
							
							-- Check if we already have this shader
							if (findItem shaderNames matName) == 0 then
							(
								local shaderData = shaders()
								shaderData.shaderName = matName
								shaderData.bitmapPath = getBitmapPathFromMaterial subMat
								
								append shaderArray shaderData
								append shaderNames matName
							)
						)
					)
				)
			)
			else
			(
				-- Simple material (not Multi/Sub-Object)
				local matName = obj.material.name
				
				-- Check if we already have this shader
				if (findItem shaderNames matName) == 0 then
				(
					local shaderData = shaders()
					shaderData.shaderName = matName
					shaderData.bitmapPath = getBitmapPathFromMaterial obj.material
					
					append shaderArray shaderData
					append shaderNames matName
				)
			)
		)
		
		-- Clean up snapshot
		delete meshObj
	)
	
	return shaderArray
)


-- Extract unique regions from face properties and named selection sets
fn extractRegions nodeObjectArray =
(
	local regionArray = #()
	local regionNames = #()
	local rootNode = nodeObjectArray[1]
	local hasObjectsWithoutNamedSet = false
	
	-- Collect all geometry objects
	for obj in objects do
	(
		if obj.isHidden then continue
		if not (isGeometryObject obj) then continue
		if obj.parent == undefined then continue
		if isNodeObject obj then continue
		if isMarkerObject obj then continue
		
		-- Check if geometry is descendant of root node
		local testParent = obj.parent
		local rootParent = undefined
		while testParent != undefined do
		(
			rootParent = testParent
			testParent = testParent.parent
		)
		if rootParent != rootNode then continue
		
		-- Get mesh data to check face selection sets
		local meshObj = snapshotAsMesh obj
		
		-- Method 1: Check named selection sets (new method - primary workflow)
		-- Get all named selection sets for this object
		local selSetNames = #()
		for i = 1 to (selectionSets.count) do
		(
			local selSet = selectionSets[i]
			-- Check if any items from this object are in this selection set
			for item in selSet do
			(
				-- Check if this is our object
				if item == obj then
				(
					local setName = selSet.name
					if (findItem selSetNames setName) == 0 then
						append selSetNames setName
					exit
				)
			)
		)
		
		-- Add all found selection set names as regions
		for setName in selSetNames do
		(
			if (findItem regionNames setName) == 0 then
			(
				local regionData = region()
				regionData.regionName = setName
				
				append regionArray regionData
				append regionNames setName
			)
		)
		
		-- Method 2: Check for region property (legacy user-defined property method)
		local regionName = getUserProp obj "region"
		if regionName != undefined then
		(
			-- Check if we already have this region
			if (findItem regionNames regionName) == 0 then
			(
				local regionData = region()
				regionData.regionName = regionName
				
				append regionArray regionData
				append regionNames regionName
			)
		)
		
		-- Method 3: Check face selection set names (old exporter method)
		local faceSelSetNames = try (obj.faces.selSetNames) catch(#())
		for selName in faceSelSetNames do
		(
			if (findItem regionNames selName) == 0 then
			(
				local regionData = region()
				regionData.regionName = selName
				
				append regionArray regionData
				append regionNames selName
			)
		)
		-- Check if object has ANY region assignment (Named Selection Set, face selection sets, or user property)
		local hasRegionAssignment = (selSetNames.count > 0) or (faceSelSetNames.count > 0) or (regionName != undefined)
		
		-- If object has NO region assignment at all, mark it for __unnamed region
		if not hasRegionAssignment then
			hasObjectsWithoutNamedSet = true
		
		-- Clean up snapshot
		delete meshObj
	)
	-- Add "__unnamed" region only if there are objects NOT in any Named Selection Set
	if hasObjectsWithoutNamedSet then
	(
		if (findItem regionNames "__unnamed") == 0 then
		(
			local regionData = region()
			regionData.regionName = "__unnamed"
			
			append regionArray regionData
			append regionNames "__unnamed"
		)
	)
	return regionArray
)

-------------------------------------------------------
-- GEOMETRY DATA EXTRACTION
-------------------------------------------------------

-- Extract all geometry data from scene
fn extractGeometryData nodeObjectArray shaderArray regionArray =
(
	if nodeObjectArray.count == 0 then
		return #(#(), #(), #())  -- Return empty vertices, triangles, and smoothing groups
	
	local rootNode = nodeObjectArray[1]
	local allVertices = #()
	local allTriangles = #()
	local allSmoothingGroups = #()  -- Store smoothing group per triangle
	
	-- Timing variables
	local timeRegionMapping = 0
	local timeTriangleCreation = 0
	local objectCount = 0
	
	-- Build node name to index lookup ONCE (needed for all skin caching)
	struct NodeLookup (nodeNames = #(), nodeIndices = #())
	local nodeLookup = NodeLookup()
	for i = 1 to nodeObjectArray.count do
	(
		append nodeLookup.nodeNames (nodeObjectArray[i].name)
		append nodeLookup.nodeIndices (i - 1)
	)
	
	-- ============================================================================
	-- PRE-PASS: Collect valid objects and cache ALL skin data BEFORE any Edit_Normals
	-- Edit_Normals panel activation corrupts skinOps for ALL subsequent objects
	-- ============================================================================
	local validObjects = #()
	local allSkinCache = #()  -- Parallel array: allSkinCache[i] = skin data for validObjects[i]
	local allParentNodeIndices = #()  -- Parallel array: parent node index for each valid object
	local allHasSmoothingGroups = #()  -- Parallel array: hasSmoothingGroups for each valid object
	
	for obj in objects do
	(
		if obj.isHidden then continue
		if not (isGeometryObject obj) then continue
		if obj.parent == undefined then continue
		if isNodeObject obj then continue
		if isMarkerObject obj then continue
		
		-- Check if geometry is descendant of root node
		local testParent = obj.parent
		local rootParent = undefined
		while testParent != undefined do
		(
			rootParent = testParent
			testParent = testParent.parent
		)
		if rootParent != rootNode then continue
		
		-- Find parent node index
		local parentNodeObj = obj.parent
		while parentNodeObj != undefined and not (isNodeObject parentNodeObj) do
			parentNodeObj = parentNodeObj.parent
		
		local parentNodeIndex = -1
		if parentNodeObj != undefined then
		(
			for i = 1 to nodeObjectArray.count do
			(
				if nodeObjectArray[i] == parentNodeObj then
				(
					parentNodeIndex = i - 1
					exit
				)
			)
		)
		if parentNodeIndex < 0 then continue
		
		-- Valid object - add to list
		append validObjects obj
		append allParentNodeIndices parentNodeIndex
		
		-- PRE-CACHE hasSmoothingGroups for this object
		local tempMesh = snapshotAsMesh obj
		local numVerts = tempMesh.numverts
		local numFaces = tempMesh.numfaces
		
		local objHasSmoothingGroups = false
		for f = 1 to numFaces do
		(
			local sg = getFaceSmoothGroup tempMesh f
			if sg != 0 and sg != undefined then
			(
				objHasSmoothingGroups = true
				exit
			)
		)
		append allHasSmoothingGroups objHasSmoothingGroups
		
		-- PRE-CACHE skin data for this object NOW (before any Edit_Normals runs)
		local objSkinData = #()
		local skinMod = getSkinModifier obj
		
		if skinMod != undefined then
		(
			local testCount = try (skinOps.getVertexWeightCount skinMod 1) catch (undefined)
			if testCount != undefined then
			(
				for v = 1 to numVerts do
				(
					local vertWeights = #()
					local weightCount = skinOps.getVertexWeightCount skinMod v
					
					for w = 1 to weightCount do
					(
						local boneID = skinOps.getVertexWeightBoneID skinMod v w
						local weight = skinOps.getVertexWeight skinMod v w
						
						if weight > 0.0 then
						(
							local boneName = skinOps.getBoneName skinMod boneID 0
							local foundIdx = findItem nodeLookup.nodeNames boneName
							
							if foundIdx > 0 then
								append vertWeights #(nodeLookup.nodeIndices[foundIdx], weight)
						)
					)
					
					append objSkinData vertWeights
				)
			)
		)
		
		delete tempMesh
		append allSkinCache objSkinData
	)
	
	-- Region / shader names in JMS order (index = position - 1)
	local regionNames = for r in regionArray collect r.regionName
	local shaderNames = for s in shaderArray collect s.shaderName
	local faceRegions = #()
	local faceShaders = #()
	local normalsFiles = #()  -- normals saved by meshNormalsSave, deleted after Lua reads them

	-- The meshes go to lua\formats\jms_cli.lua "mesh", which builds the JMS vertices
	local meshPath = (getDir #temp) + "\\hce_jms_mesh.bin"
	local meshFile = fopen meshPath "wb"
	luaWriteString meshFile "jms_mesh"
	luaWriteInt meshFile 2
	luaWriteInt meshFile validObjects.count

	-- ============================================================================
	-- MAIN PASS: Process geometry using pre-cached skin data
	-- Now safe to use Edit_Normals since all skin data is already cached
	-- ============================================================================
	for objIdx = 1 to validObjects.count do
	(
		local obj = validObjects[objIdx]
		local parentNodeIndex = allParentNodeIndices[objIdx]
		local cachedSkinData = allSkinCache[objIdx]
		local hasSkin = (cachedSkinData.count > 0)
		local hasSmoothingGroups = allHasSmoothingGroups[objIdx]
		
		objectCount += 1
		
		-- Check for Edit_Normals modifier
		local editNormalsMod = undefined
		for m = 1 to obj.modifiers.count do
		(
			if classOf obj.modifiers[m] == Edit_Normals then
			(
				editNormalsMod = obj.modifiers[m]
				exit
			)
		)
		
		-- Get mesh data
		local meshObj = snapshotAsMesh obj
		local numVerts = meshObj.numverts
		local numFaces = meshObj.numfaces
		
		-- Build face region map first (needed for triangle processing)
		local timeRegionStart = timestamp()
		local faceRegionMap = #()
		for f = 1 to numFaces do
			append faceRegionMap undefined
		
		-- Method 1: Check named selection sets
		for i = 1 to (selectionSets.count) do
		(
			local selSet = selectionSets[i]
			local setName = selSet.name
			
			for item in selSet do
			(
				if item == obj then
				(
					local faceSelection = try (item.faces) catch(undefined)
					if faceSelection != undefined then
					(
						local faceBits = faceSelection as bitArray
						for faceIdx = 1 to numFaces do
						(
							if faceBits[faceIdx] then
								faceRegionMap[faceIdx] = setName
						)
					)
				)
			)
		)
		
		-- Method 2: Check face selection set names
		local faceSelSetNames = try (obj.faces.selSetNames) catch(#())
		if faceSelSetNames.count > 0 then
		(
			for selName in faceSelSetNames do
			(
				local selFaces = try (obj.faces[selName]) catch(undefined)
				if selFaces != undefined then
				(
					-- Convert face selection to bitArray for proper iteration
					local faceBits = selFaces as bitArray
					for faceIdx = 1 to numFaces do
					(
						if faceBits[faceIdx] then
							faceRegionMap[faceIdx] = selName
					)
				)
			)
		)
		
		-- Check for legacy region property
		local legacyRegionName = getUserProp obj "region"
		
		timeRegionMapping += timestamp() - timeRegionStart
		
	-- Pre-calculate face normals and smoothing groups (caching for performance)
	local timeCacheStart = timestamp()
	local faceNormals = #()
	local faceSmoothGroups = #()
	local vertexFaceMap = #()  -- Store which faces use each vertex
	local explicitNormalsCache = #()  -- Store explicit normals per face: #( #(corner1_normal, corner2_normal, corner3_normal), ... )
	local hasExplicitNormals = false
	local normalsFile = undefined  -- #(path, normal count, rotMatrix) when saved in one go

	-- If no smoothing groups, try to read explicit normals from Edit_Normals modifier
	if not hasSmoothingGroups then
	(
		-- Track if we auto-added the modifier so we can clean it up later
		local autoAddedEditNormals = false
		
		-- If no Edit_Normals modifier exists, automatically add one to capture mesh normals
		if editNormalsMod == undefined then
		(
			logger.info "No smoothing groups detected:"
			logger.debug "Adding 'Edit Normals' modifier to capture normals"
			
			-- Add Edit_Normals modifier to the object
			editNormalsMod = Edit_Normals()
			addModifier obj editNormalsMod
			autoAddedEditNormals = true
			
			-- NOTE: Do NOT re-snapshot the mesh here!
			-- Edit_Normals does not change mesh topology (vertices, faces, UVs)
			-- Re-snapshotting could change vertex ordering, breaking our pre-cached skin data
		)
		
		if editNormalsMod != undefined then
		(
			-- Read explicit normals from Edit_Normals modifier
			logger.info "Reading explicit normals from 'Edit Normals' modifier..."
			
			-- CRITICAL: Edit_Normals API requires the modifier to be active in the modify panel
			-- Without this setup, GetNormalID and GetNormal will return undefined
			max modify mode
			select obj
			modPanel.setCurrentObject editNormalsMod
			
			-- Get the object's rotation to transform normals to world space
			-- Using rotation quaternion converted to matrix works correctly for normals
			local rotMatrix = obj.rotation as matrix3

			-- Fast way: when Edit_Normals is on top of the stack, the evaluated mesh has its normals;
			-- save them in one go and let Lua do normalize (normal * rotMatrix)
			if obj.modifiers[1] == editNormalsMod then
			(
				local path = (getDir #temp) + "\\hce_jms_normals_" + objIdx as string + ".bin"
				local saved = try (meshNormalsSave obj path) catch
				(
					logger.warn "Normals could not be read in one go ({}), using Edit_Normals" args:#(getCurrentException())
					undefined
				)
				if saved != undefined and saved[2] == numFaces then
				(
					normalsFile = #(path, saved[1], rotMatrix)
					append normalsFiles path
				)
				else if saved != undefined then
					deleteFile path
			)

			-- Otherwise read normals per face corner from Edit_Normals
			if normalsFile == undefined then for f = 1 to numFaces do
			(
				local cornerNormals = #()
				for corner = 1 to 3 do
				(
					-- GetNormalID returns the normal index for this face corner
					local normalID = editNormalsMod.GetNormalID f corner
					if normalID != undefined and normalID > 0 then
					(
						local normal = editNormalsMod.GetNormal normalID
						if normal != undefined then
						(
							-- Transform normal to world space using rotation
							local worldNormal = normalize (normal * rotMatrix)
							append cornerNormals worldNormal
						)
						else
						(
							-- Fallback to face normal if GetNormal returns undefined
							append cornerNormals (getFaceNormal meshObj f)
						)
					)
					else
					(
						-- Fallback to face normal if explicit normal not available
						append cornerNormals (getFaceNormal meshObj f)
					)
				)
				append explicitNormalsCache cornerNormals
			)
			hasExplicitNormals = true
			
			-- Clean up auto-added modifier to not pollute the scene
			if autoAddedEditNormals then
			(
				deleteModifier obj editNormalsMod
				logger.debug "Removed 'Edit Normals' modifier..."
			)
		)
		else
		(
			-- No Edit_Normals modifier, fall back to face normals
			logger.warning "No smoothing groups detected, using face normals"
			
			-- Cache empty explicit normals (will use face normals in vertex loop)
			for f = 1 to numFaces do
				append explicitNormalsCache #()
		)
	)
	-- Cache face data
	for f = 1 to numFaces do
	(
		append faceNormals (getFaceNormal meshObj f)
		append faceSmoothGroups (getFaceSmoothGroup meshObj f)
	)		-- Build vertex-to-faces map
		for v = 1 to numVerts do
			append vertexFaceMap #()
		
		for f = 1 to numFaces do
		(
			local face = getFace meshObj f
			append vertexFaceMap[face.x] f
			append vertexFaceMap[face.y] f
			append vertexFaceMap[face.z] f
		)
		-- =====================================================================
        -- PRECOMPUTE SMOOTHING CLUSTER NORMALS (OPTIMIZED CACHE)
        -- =====================================================================
        local vertexFaceClusterNormal = #()  
        if hasSmoothingGroups then
        (
			logger.info "Smoothing groups detected:"
			logger.info "Pre-calculating smoothing cluster normals for vertices..."
            for v = 1 to numVerts do
            (
                local sharedFacesRaw = vertexFaceMap[v]
                if sharedFacesRaw == undefined or sharedFacesRaw.count == 0 then
                    continue
                -- Force standard array
                local unvisited = for sf in sharedFacesRaw collect sf
                local faceNormalMap = dictionary #integer  -- faceIndex → normal
                while unvisited.count > 0 do
                (
                    local cluster = #()
                    local stack = #(unvisited[1])
                    deleteItem unvisited 1
                    while stack.count > 0 do
                    (
                        local current = stack[stack.count]
                        deleteItem stack stack.count
                        append cluster current
                        local currentSG = faceSmoothGroups[current]
                        for i = unvisited.count to 1 by -1 do
                        (
                            local test = unvisited[i]
                            if (bit.and currentSG faceSmoothGroups[test]) != 0 then
                            (
                                append stack test
                                deleteItem unvisited i
                            )
                        )
                    )
                    -- Compute cluster normal ONCE
                    local n = [0,0,0]
                    for faceIdx in cluster do
                        n += faceNormals[faceIdx]
                    n = normalize n
                    -- Assign same normal to all faces in this cluster
                    for faceIdx in cluster do
                        faceNormalMap[faceIdx] = n
                )
                vertexFaceClusterNormal[v] = faceNormalMap
            )
        )
		-- End of smoothing cluster normals caching
		local timeCacheEnd = timestamp() - timeCacheStart
		logger.info "Pre-calculation cache: '{} ms'" args:#(timeCacheEnd)
		
		local timeTriStart = timestamp()

		-- Region of every face: its selection set, else the "region" property, else "__unnamed"
		local defaultRegion = if legacyRegionName != undefined then legacyRegionName else "__unnamed"
		for f = 1 to numFaces do
		(
			local regionName = faceRegionMap[f]
			if regionName == undefined then regionName = defaultRegion
			local foundIdx = findItem regionNames regionName
			append faceRegions (if foundIdx > 0 then foundIdx - 1 else 0)
		)

		-- Shader of every face: looked up once per (sub-)material, then picked by material ID
		local objMat = obj.material
		local isMulti = objMat != undefined and classOf objMat == Multimaterial
		local singleShader = 0
		local subShaders = #()
		if isMulti then
		(
			for i = 1 to objMat.count do
			(
				local subMat = objMat[i]
				local foundIdx = if subMat != undefined then findItem shaderNames subMat.name else 0
				subShaders[i] = if foundIdx > 0 then foundIdx - 1 else 0
			)
		)
		else if objMat != undefined then
		(
			local foundIdx = findItem shaderNames objMat.name
			if foundIdx > 0 then singleShader = foundIdx - 1
		)
		for f = 1 to numFaces do
		(
			local shaderIndex = singleShader
			if isMulti then
			(
				local faceMatID = getFaceMatID meshObj f
				shaderIndex = if faceMatID > 0 and faceMatID <= subShaders.count then subShaders[faceMatID] else 0
			)
			append faceShaders shaderIndex
			local smoothGroup = faceSmoothGroups[f]
			append allSmoothingGroups (if smoothGroup == undefined then 0 else smoothGroup)
		)

		-- Mesh data for Lua: positions, skin weights (cached above), UVs, and per face its
		-- vertices, UV vertices and the normal of each corner
		writeLong meshFile parentNodeIndex #signed
		writeLong meshFile numVerts #signed
		for v = 1 to numVerts do
		(
			local p = getVert meshObj v
			writeFloat meshFile p.x
			writeFloat meshFile p.y
			writeFloat meshFile p.z
		)
		writeLong meshFile (if hasSkin then 1 else 0) #signed
		if hasSkin then
		(
			for v = 1 to numVerts do
			(
				local boneWeights = if v <= cachedSkinData.count then cachedSkinData[v] else #()
				writeLong meshFile boneWeights.count #signed
				for bw in boneWeights do
				(
					writeLong meshFile bw[1] #signed
					writeFloat meshFile bw[2]
				)
			)
		)
		local numTVerts = meshObj.numtverts
		writeLong meshFile numTVerts #signed
		for t = 1 to numTVerts do
		(
			local tvert = getTVert meshObj t
			writeFloat meshFile tvert.x
			writeFloat meshFile tvert.y
		)
		writeLong meshFile numFaces #signed
		-- Normals: 1 = saved in one go (file, count, rotMatrix rows), 0 = per corner with each face
		if normalsFile != undefined then
		(
			writeLong meshFile 1 #signed
			writeString meshFile normalsFile[1]
			writeLong meshFile normalsFile[2] #signed
			for r = 1 to 4 do
			(
				local row = normalsFile[3][r]
				writeFloat meshFile row.x
				writeFloat meshFile row.y
				writeFloat meshFile row.z
			)
		)
		else
			writeLong meshFile 0 #signed
		for f = 1 to numFaces do
		(
			local face = getFace meshObj f
			writeLong meshFile (face.x as integer) #signed
			writeLong meshFile (face.y as integer) #signed
			writeLong meshFile (face.z as integer) #signed
			if numTVerts > 0 then
			(
				local tvFace = getTVFace meshObj f
				writeLong meshFile (tvFace.x as integer) #signed
				writeLong meshFile (tvFace.y as integer) #signed
				writeLong meshFile (tvFace.z as integer) #signed
			)
			if normalsFile == undefined then for corner = 1 to 3 do
			(
				-- Explicit normal, smoothing-group normal, or the face normal
				local vNormal = faceNormals[f]
				if not hasSmoothingGroups then
				(
					if hasExplicitNormals then vNormal = explicitNormalsCache[f][corner]
				)
				else
				(
					local faceNormalMap = vertexFaceClusterNormal[face[corner] as integer]
					if faceNormalMap != undefined and faceNormalMap[f] != undefined then
						vNormal = faceNormalMap[f]
				)
				writeFloat meshFile vNormal.x
				writeFloat meshFile vNormal.y
				writeFloat meshFile vNormal.z
			)
		)
		timeTriangleCreation += timestamp() - timeTriStart

		-- Clean up snapshot (always created now)
		delete meshObj
	)
	fclose meshFile

	-- Lua merges the face corners into vertices (same rules as the previous MAXScript loop)
	local timeLuaStart = timestamp()
	local meshOutPath = (getDir #temp) + "\\hce_jms_mesh_out.bin"
	deleteFile meshOutPath
	local luaOk = luaRunScript "lua\\formats\\jms_cli.lua" #("mesh", meshPath, meshOutPath)
	deleteFile meshPath
	for path in normalsFiles do deleteFile path
	local outFile = if luaOk then luaOpenOutput meshOutPath "jms_mesh" 1 else undefined
	if outFile == undefined then throw "Lua could not build the JMS vertices (see the log)"

	allVertices = for i = 1 to (luaReadInt outFile) collect
	(
		local vert = vertices()
		vert.node0Index = readLong outFile #signed
		local x = readFloat outFile
		local y = readFloat outFile
		local z = readFloat outFile
		vert.position = #(x, y, z)
		x = readFloat outFile
		y = readFloat outFile
		z = readFloat outFile
		vert.normal = #(x, y, z)
		vert.node1Index = readLong outFile #signed
		vert.node1Weight = readFloat outFile
		local u = readFloat outFile
		local v = readFloat outFile
		vert.texturePos = #(u, v, 0)
		vert
	)
	-- One triangle per face; its 3 vertices come from Lua
	local faceCount = (luaReadInt outFile) / 3
	allTriangles = for t = 1 to faceCount collect
	(
		local tri = triangles()
		tri.regionIndex = faceRegions[t]
		tri.shaderIndex = faceShaders[t]
		local a = readLong outFile #signed
		local b = readLong outFile #signed
		local c = readLong outFile #signed
		tri.vertexIndices = #(a, b, c)
		tri
	)
	fclose outFile
	deleteFile meshOutPath
	local timeLua = timestamp() - timeLuaStart

	-- Print detailed geometry timing
	logger.info "Geometries: {} objects" args:#(objectCount)
	logger.info "Region mapping: {} ms" args:#(timeRegionMapping)
	logger.info "Triangle/vertex processing: {} ms" args:#(timeTriangleCreation)
	logger.info "Vertex building (Lua): {} ms" args:#(timeLua)

	return #(allVertices, allTriangles, allSmoothingGroups)
)

-------------------------------------------------------
-- MAIN EXPORT FUNCTION
-------------------------------------------------------

-- Main function to process scene and return JMS data structure
fn processSceneForJMS =
(
	local startTime = timestamp()
	
	-- Validate scene before processing
	local validationErrors = validateSceneForExport()
	if validationErrors.count > 0 then
	(
		-- Show all errors in a single message box
		local errorMsg = "Cannot export JMS file. Please fix the following issues:\n\n"
		for i = 1 to validationErrors.count do
		(
			errorMsg += validationErrors[i]
			if i < validationErrors.count then
				errorMsg += "\n\n========================================\n\n"
		)
		
		messageBox errorMsg title:"JMS Export Validation Failed" beep:false
		return undefined
	)
	
	-- Create main JMS structure
	local jmsData = jmsFile()
	
	-- Set fixed values
	jmsData.jmsVersion = 8200
	jmsData.jmsChecksum = 0
	
	-- Extract node data
	local nodeStartTime = timestamp()
	local extractResult = extractNodeData()
	local nodeDataArray = extractResult[1]
	local nodeObjectArray = extractResult[2]
	jmsData.nodes = nodeDataArray
	jmsData.nodeCount = nodeDataArray.count
	local nodeTime = timestamp() - nodeStartTime

	logger.info "Node extraction: {} ms ({} nodes)" args:#(nodeTime, nodeDataArray.count)
	
	-- Extract marker data (needs node object array for parent lookup)
	local markerStartTime = timestamp()
	local markerDataArray = extractMarkerData nodeObjectArray
	jmsData.markers = markerDataArray
	jmsData.markerCount = markerDataArray.count
	local markerTime = timestamp() - markerStartTime
	logger.info "Marker extraction: {} ms ({} markers)" args:#(markerTime, markerDataArray.count)
	
	-- Extract shaders and regions
	local shaderStartTime = timestamp()
	local shaderDataArray = extractShaders nodeObjectArray
	jmsData.shaders = shaderDataArray
	jmsData.shaderCount = shaderDataArray.count
	local shaderTime = timestamp() - shaderStartTime
	logger.info "Shader extraction: {} ms ({} shaders)" args:#(shaderTime, shaderDataArray.count)
	
	local regionStartTime = timestamp()
	local regionDataArray = extractRegions nodeObjectArray
	jmsData.regions = regionDataArray
	jmsData.regionCount = regionDataArray.count
	local regionTime = timestamp() - regionStartTime
	logger.info "Region extraction: {} ms ({} regions)" args:#(regionTime, regionDataArray.count)
	
	-- Extract geometry data (vertices and triangles)
	-- Pass shaders and regions for proper indexing
	local geomStartTime = timestamp()
	local geometryResult = extractGeometryData nodeObjectArray shaderDataArray regionDataArray
	local vertexDataArray = geometryResult[1]
	local triangleDataArray = geometryResult[2]
	local smoothingGroupsArray = geometryResult[3]
	jmsData.vertices = vertexDataArray
	jmsData.vertexCount = vertexDataArray.count
	jmsData.triangles = triangleDataArray
	jmsData.triangleCount = triangleDataArray.count
	jmsData.smoothingGroups = smoothingGroupsArray
	local geomTime = timestamp() - geomStartTime
	logger.info "Geometry extraction: {} ms ({} vertices, {} triangles)" args:#(geomTime, vertexDataArray.count, triangleDataArray.count)
	
	-- Bitmap paths are now stored directly in shader.bitmapPath (no need for separate extraction)
	
	local totalTime = timestamp() - startTime
	logger.info "Total extraction time: {} ms" args:#(totalTime)
	logger.log "Exported JMS data successfully\n"
	
	return #(jmsData, totalTime)
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)