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
			pos = in coordsys parent obj.pos  -- Parent space position
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

-- Helper function to create hash key from vertex attributes
fn createVertexHash pos norm uv node0 node1 weight1 =
(
	-- Round to 4 decimal places to create hash key (avoids floating point precision issues)
	-- Use StringStream for fast string building (avoids repeated string concatenation overhead)
	local ss = stringstream ""
	format "%,%,%,%,%,%,%,%,%,%,%" \
		((pos[1] * 10000) as integer) \
		((pos[2] * 10000) as integer) \
		((pos[3] * 10000) as integer) \
		((norm[1] * 10000) as integer) \
		((norm[2] * 10000) as integer) \
		((norm[3] * 10000) as integer) \
		((uv[1] * 10000) as integer) \
		((uv[2] * 10000) as integer) \
		node0 node1 \
		((weight1 * 10000) as integer) \
		to:ss
	return ss as string
)

-- Helper function to find matching vertex using hash lookup (with proper dictionary)
fn findMatchingVertexFast vertData hashDict =
(
	local hashKey = createVertexHash vertData.position vertData.normal vertData.texturePos vertData.node0Index vertData.node1Index vertData.node1Weight
	
	-- Try to get value from dictionary (returns undefined if key doesn't exist)
	local result = hashDict[hashKey]
	return result
)

-- Helper function to add vertex to hash dictionary
fn addVertexToHash hashDict hashKey vertexIdx =
(
	hashDict[hashKey] = vertexIdx
)

-- Extract all geometry data from scene
fn extractGeometryData nodeObjectArray shaderArray regionArray =
(
	if nodeObjectArray.count == 0 then
		return #(#(), #(), #())  -- Return empty vertices, triangles, and smoothing groups
	
	local rootNode = nodeObjectArray[1]
	local allVertices = #()
	local allTriangles = #()
	local allSmoothingGroups = #()  -- Store smoothing group per triangle
	local globalVertexOffset = 0
	
	-- Timing variables
	local timeRegionMapping = 0
	local timeMaterialMapping = 0
	local timeVertexCreation = 0
	local timeNormalCalc = 0
	local timeSkinning = 0
	local timeTriangleCreation = 0
	local objectCount = 0
	
	-- Collect all geometry objects in scene
	for obj in objects do
	(
		if obj.isHidden then continue
		if not (isGeometryObject obj) then continue
		if obj.parent == undefined then continue
		
		-- Skip objects that are nodes (they shouldn't be geometry)
		if isNodeObject obj then continue
		
		-- Skip markers (they have geometry but aren't mesh geometry)
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
		
		objectCount += 1
		
		-- Find parent node index (walk up hierarchy until we find a node object)
		local parentNodeObj = obj.parent
		while parentNodeObj != undefined and not (isNodeObject parentNodeObj) do
		(
			parentNodeObj = parentNodeObj.parent
		)
		
		local parentNodeIndex = -1
		if parentNodeObj != undefined then
		(
			for i = 1 to nodeObjectArray.count do
			(
				if nodeObjectArray[i] == parentNodeObj then
				(
					parentNodeIndex = i - 1  -- Convert to 0-based
					exit
				)
			)
		)
		
		if parentNodeIndex < 0 then continue
		
		-- Check for Edit_Normals modifier (explicit normals stored here)
		local editNormalsMod = undefined
		for m = 1 to obj.modifiers.count do
		(
			if classOf obj.modifiers[m] == Edit_Normals then
			(
				editNormalsMod = obj.modifiers[m]
				exit
			)
		)
		
		-- Get mesh data - always use snapshotAsMesh for consistent world-space geometry
		local meshObj = snapshotAsMesh obj
		
		local numVerts = meshObj.numverts
		local numFaces = meshObj.numfaces
		
		-- Check for Skin modifier (we'll pre-cache bone weights after building lookup tables)
		local skinMod = getSkinModifier obj
		local hasSkin = false
		
		if skinMod != undefined then
		(
			-- Test if we can actually access the skin modifier
			local testCount = try (skinOps.getVertexWeightCount skinMod 1) catch (undefined)
			hasSkin = (testCount != undefined)
		)
		
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
	local hasSmoothingGroups = false
	local hasExplicitNormals = false
	
	-- First pass: check if any face has smoothing groups
	for f = 1 to numFaces do
	(
		local sg = getFaceSmoothGroup meshObj f
		if sg != 0 and sg != undefined then
		(
			hasSmoothingGroups = true
			exit
		)
	)
	
	-- If no smoothing groups, use face normals
	-- NOTE: Explicit normals from FBX are not accessible without proper Edit_Normals setup
	-- For now, we default to face normals when no smoothing groups exist
	if not hasSmoothingGroups then
	(
		logger "No smoothing groups detected, using face normals\n" logType:#warning
		
		-- Cache empty explicit normals (will use face normals in vertex loop)
		for f = 1 to numFaces do
			append explicitNormalsCache #()
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
		
		local timeCacheEnd = timestamp() - timeCacheStart

		logger "    Pre-calculation cache: % ms\n" params:#(timeCacheEnd) logType:#timestamp
		
		-- Build region name to index lookup (using struct as dictionary)
		struct RegionLookup (regionNames = #(), regionIndices = #())
		local regionLookup = RegionLookup()
		for i = 1 to regionArray.count do
		(
			append regionLookup.regionNames (regionArray[i].regionName)
			append regionLookup.regionIndices (i - 1)
		)
		
		-- Build shader name to index lookup
		struct ShaderLookup (shaderNames = #(), shaderIndices = #())
		local shaderLookup = ShaderLookup()
		for i = 1 to shaderArray.count do
		(
			append shaderLookup.shaderNames (shaderArray[i].shaderName)
			append shaderLookup.shaderIndices (i - 1)
		)
		
		-- Build node name to index lookup (for skinning)
		struct NodeLookup (nodeNames = #(), nodeIndices = #())
		local nodeLookup = NodeLookup()
		for i = 1 to nodeObjectArray.count do
		(
			append nodeLookup.nodeNames (nodeObjectArray[i].name)
			append nodeLookup.nodeIndices (i - 1)
		)
		
		-- Pre-cache all skin weights for all vertices (now that NodeLookup is built)
		local cachedSkinData = #()  -- Array indexed by vertex: #( #(boneNodeIdx, weight), ... )
		if hasSkin then
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
				
				append cachedSkinData vertWeights
			)
		)
		
		-- Vertex welding: use dictionary-based hash for O(1) lookups
		-- Create hash key from vertex attributes for efficient duplicate detection
		local vertexHashDict = dictionary #string  -- Use MAXScript dictionary for true O(1) lookups
		
		-- Extract vertices AND triangles together (per-face-corner to match UVs)
		-- This matches the old exporter behavior
		for f = 1 to numFaces do
		(
			local timeTriStart = timestamp()
			
			local face = getFace meshObj f
			local tvFace = if meshObj.numtverts > 0 then (getTVFace meshObj f) else (point3 0 0 0)
			
			-- Create triangle
			local triData = triangles()
			
			-- Determine region for this face (using cached lookup)
			local regionIndex = 0
			local faceRegionName = faceRegionMap[f]
			
			if faceRegionName != undefined then
			(
				local foundIdx = findItem regionLookup.regionNames faceRegionName
				if foundIdx > 0 then
					regionIndex = regionLookup.regionIndices[foundIdx]
			)
			else if legacyRegionName != undefined then
			(
				local foundIdx = findItem regionLookup.regionNames legacyRegionName
				if foundIdx > 0 then
					regionIndex = regionLookup.regionIndices[foundIdx]
			)
			else
			(
				-- No region assigned, use "__unnamed" region
				local foundIdx = findItem regionLookup.regionNames "__unnamed"
				if foundIdx > 0 then
					regionIndex = regionLookup.regionIndices[foundIdx]
			)
			
			triData.regionIndex = regionIndex
			
			-- Get shader index (using cached lookup)
			local timeMaterialStart = timestamp()
			local shaderIndex = 0
			if obj.material != undefined then
			(
				if classOf obj.material == Multimaterial then
				(
					local faceMatID = getFaceMatID meshObj f
					if faceMatID > 0 and faceMatID <= obj.material.count then
					(
						local subMat = obj.material[faceMatID]
						if subMat != undefined then
						(
							local foundIdx = findItem shaderLookup.shaderNames subMat.name
							if foundIdx > 0 then
								shaderIndex = shaderLookup.shaderIndices[foundIdx]
						)
					)
				)
				else
				(
					local foundIdx = findItem shaderLookup.shaderNames obj.material.name
					if foundIdx > 0 then
						shaderIndex = shaderLookup.shaderIndices[foundIdx]
				)
			)
			
			triData.shaderIndex = shaderIndex
			timeMaterialMapping += timestamp() - timeMaterialStart
			
			-- Create 3 vertices for this face (one per corner)
			local vertIndices = #()
			
			for corner = 1 to 3 do
			(
			local timeVertStart = timestamp()
			local vertIdx = face[corner]
			local vertData = vertices()
			
			-- Get vertex position from snapshot mesh (already in world space)
			local vertPos = getVert meshObj vertIdx
			
			-- snapshotAsMesh returns world-space geometry, no additional transform needed
			vertData.position = #(vertPos.x, vertPos.y, vertPos.z)
			timeVertexCreation += timestamp() - timeVertStart
			
			-- Calculate vertex normal
			local timeNormalStart = timestamp()
			local vNormal = [0, 0, 0]
			
			-- If no smoothing groups, use explicit normals if available, otherwise face normals
			if not hasSmoothingGroups then
			(
				if hasExplicitNormals then
				(
					-- Use pre-cached explicit normal for this face corner
					vNormal = explicitNormalsCache[f][corner]
				)
				else
				(
					-- Fallback to face normal
					vNormal = faceNormals[f]
				)
			)
			else
			(
				-- Use smoothing group-based calculation
				vNormal += faceNormals[f]  -- Use cached face normal
				
				-- Get smoothing group for current face (from cache)
				local faceSG = faceSmoothGroups[f]
				
				-- Get all faces that share this vertex (from cache)
				local sharedFaces = vertexFaceMap[vertIdx]
				
				-- Check each shared face for smoothing group overlap
				for s = 1 to sharedFaces.count do
				(
					local sharedFaceIdx = sharedFaces[s]
					if sharedFaceIdx != f then  -- Skip current face
					(
						local neiSG = faceSmoothGroups[sharedFaceIdx]  -- Use cached smoothing group
						
						-- Smoothing groups are bitfields - use bitwise AND to check overlap
						-- If they share any smoothing group bits, add the neighbor's normal
						if (bit.and faceSG neiSG) != 0 then
						(
							vNormal += faceNormals[sharedFaceIdx]
						)
					)
				)
				
				-- Normalize the result
				vNormal = normalize vNormal
			)
			
			vertData.normal = #(vNormal.x, vNormal.y, vNormal.z)
			timeNormalCalc += timestamp() - timeNormalStart				-- Handle skinning
				local timeSkinStart = timestamp()
				if hasSkin then
				(
					-- Use pre-cached skin data instead of repeated skinOps calls
					local boneWeights = cachedSkinData[vertIdx]
					
					-- Find top 2 weights (we only export 2 bone influences)
					if boneWeights.count > 0 then
					(
						local maxWeight1 = boneWeights[1]
						local maxWeight2 = undefined
						
						-- Find highest weight
						for i = 2 to boneWeights.count do
						(
							if boneWeights[i][2] > maxWeight1[2] then
								maxWeight1 = boneWeights[i]
						)
						
						-- Find second highest weight
						if boneWeights.count > 1 then
						(
							for i = 1 to boneWeights.count do
							(
								if boneWeights[i] != maxWeight1 then
								(
									if maxWeight2 == undefined or boneWeights[i][2] > maxWeight2[2] then
										maxWeight2 = boneWeights[i]
								)
							)
						)
						
						vertData.node0Index = maxWeight1[1]
						
						if maxWeight2 != undefined then
						(
							vertData.node1Index = maxWeight2[1]
							vertData.node1Weight = maxWeight2[2]
						)
						else
						(
							vertData.node1Index = -1
							vertData.node1Weight = 0.0
						)
					)
					else
					(
						-- No valid weights, use parent
						vertData.node0Index = parentNodeIndex
						vertData.node1Index = -1
						vertData.node1Weight = 0.0
					)
				)
				else
				(
					vertData.node0Index = parentNodeIndex
					vertData.node1Index = -1
					vertData.node1Weight = 0.0
				)
				timeSkinning += timestamp() - timeSkinStart
				
				-- Get texture coordinates for THIS FACE CORNER
				if meshObj.numtverts > 0 then
				(
					local tvIdx = tvFace[corner] as integer
					if tvIdx > 0 and tvIdx <= meshObj.numtverts then
					(
						local tvert = getTVert meshObj tvIdx
						vertData.texturePos = #(tvert.x, tvert.y, 0)
					)
					else
					(
						vertData.texturePos = #(0.0, 0.0, 0)
					)
				)
				else
				(
					vertData.texturePos = #(0.0, 0.0, 0)
				)
				
				-- Vertex welding: check if we already have an identical vertex using hash lookup
			-- Compute hash once and reuse it for both lookup and insertion
			local hashKey = createVertexHash vertData.position vertData.normal vertData.texturePos vertData.node0Index vertData.node1Index vertData.node1Weight
			local existingVertexIdx = vertexHashDict[hashKey]
			
			if existingVertexIdx != undefined then
			(
				-- Reuse existing vertex (already a global index, no offset needed)
				append vertIndices existingVertexIdx
			)
			else
			(
				-- Add new vertex
				append allVertices vertData
				local globalIdx = allVertices.count - 1  -- Global index (0-based)
				append vertIndices globalIdx
				
				-- Add to hash dictionary for future lookups (reuse computed hashKey)
				vertexHashDict[hashKey] = globalIdx
			)
		)
		
		-- Set triangle vertex indices (vertIndices already contains global indices)
		triData.vertexIndices = #(vertIndices[1], vertIndices[2], vertIndices[3])
		
			local smoothGroup = 0  -- Default to 0 (hard edges/no smoothing)
			try (smoothGroup = getFaceSmoothGroup meshObj f) catch ()
			if smoothGroup == undefined then smoothGroup = 0
			
			append allTriangles triData
			append allSmoothingGroups smoothGroup
			timeTriangleCreation += timestamp() - timeTriStart
		)
		
		-- Update global vertex offset and clear per-object hash dictionary
		globalVertexOffset = allVertices.count
		vertexHashDict = dictionary #string  -- Reset dictionary for next object
		
		-- Clean up snapshot (always created now)
		delete meshObj
	)
	
	-- Print detailed geometry timing
	logger "Geometry breakdown (% objects):\n" params:#(objectCount) logType:#timestamp
	logger "    Region mapping: % ms\n" params:#(timeRegionMapping) logType:#timestamp
	logger "    Material mapping: % ms\n" params:#(timeMaterialMapping) logType:#timestamp
	logger "    Vertex creation: % ms\n" params:#(timeVertexCreation) logType:#timestamp
	logger "    Normal calculation: % ms\n" params:#(timeNormalCalc) logType:#timestamp
	logger "    Skinning: % ms\n" params:#(timeSkinning) logType:#timestamp
	logger "    Triangle creation: % ms\n" params:#(timeTriangleCreation) logType:#timestamp
	
	return #(allVertices, allTriangles, allSmoothingGroups)
)

-------------------------------------------------------
-- MAIN EXPORT FUNCTION
-------------------------------------------------------

-- Main function to process scene and return JMS data structure
fn processSceneForJMS =
(
	local startTime = timestamp()
	logger "\n=== EXPORT SCENE DATA ===\n"
	
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

	logger "Node extraction: % ms (% nodes)\n" params:#(nodeTime, nodeDataArray.count) logType:#timestamp
	
	-- Extract marker data (needs node object array for parent lookup)
	local markerStartTime = timestamp()
	local markerDataArray = extractMarkerData nodeObjectArray
	jmsData.markers = markerDataArray
	jmsData.markerCount = markerDataArray.count
	local markerTime = timestamp() - markerStartTime
	logger "Marker extraction: % ms (% markers)\n" params:#(markerTime, markerDataArray.count) logType:#timestamp
	
	-- Extract shaders and regions
	local shaderStartTime = timestamp()
	local shaderDataArray = extractShaders nodeObjectArray
	jmsData.shaders = shaderDataArray
	jmsData.shaderCount = shaderDataArray.count
	local shaderTime = timestamp() - shaderStartTime
	logger "Shader extraction: % ms (% shaders)\n" params:#(shaderTime, shaderDataArray.count) logType:#timestamp
	
	local regionStartTime = timestamp()
	local regionDataArray = extractRegions nodeObjectArray
	jmsData.regions = regionDataArray
	jmsData.regionCount = regionDataArray.count
	local regionTime = timestamp() - regionStartTime
	logger "Region extraction: % ms (% regions)\n" params:#(regionTime, regionDataArray.count) logType:#timestamp
	
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
	logger "Geometry extraction: % ms (% vertices, % triangles)\n" params:#(geomTime, vertexDataArray.count, triangleDataArray.count) logType:#timestamp
	
	-- Bitmap paths are now stored directly in shader.bitmapPath (no need for separate extraction)
	
	local totalTime = timestamp() - startTime
	format "TOTAL TIME: % ms\n" totalTime
	format "=============================\n\n"
	
	return jmsData
)

logger "Process Scene loaded.\n" logType:#success