----------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
----------------------------------------------------------------------------

-------------------------------------------------------
-- JMS SCENE BUILDER MODULE
-------------------------------------------------------

-- JMS files already use 3ds Max units (no scaling needed)
global HALO_SCALE = 1.0
global BONE_SIZE = 1.0

-------------------------------------------------------
-- NODE/BONE CREATION
-------------------------------------------------------

-- Calculate parent node index from JMS sibling structure
fn calculateParentIndices jmsData useSimpleHierarchy:false =
(
	local parentIndices = #()
	
	-- Initialize all as -1 (no parent)
	for i = 1 to jmsData.nodeCount do
		append parentIndices -1
	
	if useSimpleHierarchy then
	(
		-- Backward sibling chain algorithm for fbx-to-jms/Blender format
		-- In this format, sibling chains point BACKWARD from firstChild
		-- Example: pelvis.firstChild=3 (spine), spine.nextSibling=2 (r thigh), r thigh.nextSibling=1 (l thigh)
		-- This means pelvis's children are: 1, 2, 3 (following the backward chain)
		for i = 1 to jmsData.nodeCount do
		(
			local node = jmsData.nodes[i]
			local firstChildIdx = node.firstChildNodeIndex
			
			if firstChildIdx >= 0 and firstChildIdx < jmsData.nodeCount then
			(
				local currentParent = i - 1  -- 0-based parent index
				local currentIdx = firstChildIdx
				
				-- Follow the backward sibling chain from firstChild
				while currentIdx >= 0 and currentIdx < jmsData.nodeCount do
				(
					-- Assign this node to the parent
					parentIndices[currentIdx + 1] = currentParent
					
					-- Move to the previous sibling (backward chain)
					local siblingNode = jmsData.nodes[currentIdx + 1]
					currentIdx = siblingNode.nextSiblingNodeIndex
				)
			)
		)
	)
	else
	(
		-- Traditional algorithm using sibling chains
		-- First pass: set parent for first child nodes
		for i = 1 to jmsData.nodeCount do
		(
			local node = jmsData.nodes[i]
			local firstChildIdx = node.firstChildNodeIndex
			
			if firstChildIdx >= 0 and firstChildIdx < jmsData.nodeCount then
			(
				parentIndices[firstChildIdx + 1] = i - 1  -- Store as 0-based
			)
		)
		
		-- Second pass: set parent for sibling nodes
		for i = 1 to jmsData.nodeCount do
		(
			local node = jmsData.nodes[i]
			local nextSiblingIdx = node.nextSiblingNodeIndex
			
			if nextSiblingIdx >= 0 and nextSiblingIdx < jmsData.nodeCount then
			(
				parentIndices[nextSiblingIdx + 1] = parentIndices[i]
			)
		)
	)
	
	return parentIndices
)

-- Create a single node (sphere helper)
fn createJmsNode nodeData nodeIndex parentIndices =
(
	local nodeName = nodeData.nodeName
	
	-- Create node as sphere at origin
	local nodeObj = Sphere radius:BONE_SIZE pos:[0,0,0] name:nodeName smooth:on
	
	-- Color based on whether it's a bone node
	if isNodeObject nodeObj then
		nodeObj.wirecolor = color 6 134 6  --#068606 -- Green for bone nodes
	else
		nodeObj.wirecolor = color 128 128 128  --#808080 -- Gray for other nodes
	
	-- Assign to "Nodes" layer
	local nodesLayer = LayerManager.getLayerFromName "Nodes"
	if nodesLayer == undefined then
		nodesLayer = LayerManager.newLayerFromName "Nodes"
	nodesLayer.addNode nodeObj
	
	return nodeObj
)

-- Link node hierarchy and apply transforms
fn linkAndTransformNodes createdNodes jmsData parentIndices =
(
	-- First pass: link parent-child relationships
	for i = 1 to createdNodes.count do
	(
		local nodeObj = createdNodes[i]
		local parentIdx = parentIndices[i]
		
		if parentIdx >= 0 and parentIdx < createdNodes.count then
		(
			local parentObj = createdNodes[parentIdx + 1]  -- Convert to 1-based
			nodeObj.parent = parentObj
		)
	)
	
	-- Second pass: apply transforms in parent-local space
	for i = 1 to createdNodes.count do
	(
		local nodeObj = createdNodes[i]
		if nodeObj == undefined then continue
		
		local nodeData = jmsData.nodes[i]
		local translation = nodeData.nodeTranslation
		local rotation = nodeData.nodeRotation
		
		-- Don't scale translation (JMS already uses 3ds Max units)
		local scaledTranslation = translation * HALO_SCALE
		
		-- Apply transform in parent-local space (matching gbxmodel importer)
		in coordsys parent nodeObj.rotation = rotation
		in coordsys parent nodeObj.pos = scaledTranslation
	)
	
	-- Third pass: Convert to bones for bone nodes
	for i = 1 to createdNodes.count do
	(
		local nodeObj = createdNodes[i]
		if nodeObj == undefined then continue
		
		local nodeData = jmsData.nodes[i]
		
		if isNodeObject nodeObj then
		(
			-- Store the sphere's world transform before conversion
			local nodeWorldPos = nodeObj.pos
			local nodeWorldRot = nodeObj.rotation
			local parentIdx = parentIndices[i]
			
			-- Calculate bone end position in world space using rotation
			-- This ensures the bone direction matches the desired rotation
			local boneLength = BONE_SIZE
			local firstChildIdx = nodeData.firstChildNodeIndex
			
			-- If there's a child, calculate distance to it
			if firstChildIdx >= 0 and firstChildIdx < createdNodes.count then
			(
				local childObj = createdNodes[firstChildIdx + 1]
				if childObj != undefined then
				(
					local distToChild = distance nodeWorldPos childObj.pos
					if distToChild > 0.001 then
						boneLength = distToChild
				)
			)
			
			-- Calculate bone end position using current world rotation
			-- The bone points along its local X axis
			-- Rotate the X-axis vector [boneLength,0,0] by the quaternion
			local directionVector = [boneLength, 0, 0]
			local rotatedDirection = directionVector * (nodeWorldRot as matrix3)
			local boneEndPos = nodeWorldPos + rotatedDirection
			
			-- Create bone using calculated positions
			local myBone = BoneSys.createBone nodeWorldPos boneEndPos [0, 0, 1]
			myBone.name = nodeData.nodeName
			myBone.wirecolor = color 255 180 6 --#ffb406
			myBone.width = BONE_SIZE
			myBone.height = BONE_SIZE
			myBone.setBoneEnable false 0
			myBone.setBoneEnable false 1
			myBone.setBoneEnable false 2
			
			if firstChildIdx >= 0 then
				myBone.taper = 70
			else
				myBone.taper = 50
			
			-- Special bone handling for Biped Skeleton
			local lowerName = toLower nodeData.nodeName
			
			if lowerName == "bip01 spine1" then
			(
				myBone.length *= 0.8
				myBone.width = BONE_SIZE
				myBone.height = BONE_SIZE / 2.0
				myBone.taper = -180
			)
			else if lowerName == "bip01 pelvis" or lowerName == "bip01 spine" then
			(
				myBone.width = BONE_SIZE
				myBone.height = BONE_SIZE / 2.0
				myBone.taper = -180
			)
			else if lowerName == "frame bone24" then
			(
				myBone.length = BONE_SIZE * 4
				myBone.width = BONE_SIZE * 4
				myBone.height = BONE_SIZE * 4
				myBone.taper = 100
			)
			else if lowerName == "frame l wriste" or lowerName == "frame r wriste" then
			(
				myBone.length = 2.8
				myBone.width = BONE_SIZE
				myBone.height = BONE_SIZE * 0.3
				myBone.taper = -270
			)
			else if lowerName == "frame l forearm" or lowerName == "frame r forearm" then
			(
				myBone.width = BONE_SIZE * 2
				myBone.height = BONE_SIZE * 2
			)
			else if lowerName == "frame l upperarm" or lowerName == "frame r upperarm" then
			(
				myBone.width = BONE_SIZE * 3
				myBone.height = BONE_SIZE * 3
			)
			
			-- Delete the sphere helper
			delete nodeObj
			
			-- Replace in array
			createdNodes[i] = myBone
			
			-- Assign to Nodes layer
			local nodesLayer = LayerManager.getLayerFromName "Nodes"
			if nodesLayer == undefined then
				nodesLayer = LayerManager.newLayerFromName "Nodes"
			nodesLayer.addNode myBone
			
			-- Set parent (this preserves the hierarchy and transform)
			if parentIdx >= 0 and parentIdx < createdNodes.count then
			(
				local parentObj = createdNodes[parentIdx + 1]
				if parentObj != undefined then
					myBone.parent = parentObj
			)
			
			-- Re-apply rotation and position using negated quaternion (matching old importer)
			local rotation = nodeData.nodeRotation
			local translation = nodeData.nodeTranslation
			local negatedQuat = quat (-rotation.x) (-rotation.y) (-rotation.z) rotation.w
			in coordsys parent myBone.rotation = negatedQuat
			in coordsys parent myBone.pos = translation * HALO_SCALE
		)
	)
)

-- Build all nodes
fn buildNodes jmsData =
(
	logger ("Building " + jmsData.nodeCount as string + " nodes...\n") logType: #info
	
	local parentIndices = calculateParentIndices jmsData useSimpleHierarchy:jmsData.useSimpleHierarchy
	local createdNodes = #()
	
	-- Create all nodes as spheres first
	for i = 1 to jmsData.nodeCount do
	(
		local nodeObj = createJmsNode jmsData.nodes[i] i parentIndices
		append createdNodes nodeObj
	)
	
	-- Link hierarchy and apply transforms
	linkAndTransformNodes createdNodes jmsData parentIndices
	
	logger "Nodes created successfully!" logType: #success
	
	return createdNodes
)

-------------------------------------------------------
-- MARKER CREATION
-------------------------------------------------------

-- Create markers as Halo marker helpers
fn buildMarkers jmsData createdNodes =
(
	if jmsData.markerCount == 0 then
		return #()
	
	logger ("Building " + jmsData.markerCount as string + " markers...\n") logType: #info
	
	local createdMarkers = #()
	
	for i = 1 to jmsData.markerCount do
	(
		local markerData = jmsData.markers[i]
		local markerName = markerData.markerName
		local parentIdx = markerData.parentNodeIndex
		local translation = markerData.markerTranslation * HALO_SCALE
		local rotation = markerData.markerRotation
		local radius = markerData.markerRadius * HALO_SCALE
		
		-- Create Halo marker helper
		local markerObj = HaloMarker()
		-- Add prefix: "+" if name contains "mp", otherwise "#"
		local prefix = if (findString (toLower markerName) "mp") != undefined then "+" else "#"
		markerObj.name = prefix + markerName
		markerObj.markerRadius = radius
		markerObj.wirecolor = color 0 240 255 --#00f0ff
		
		-- Parent to node if valid
		if parentIdx >= 0 and parentIdx < createdNodes.count then
		(
			local parentNode = createdNodes[parentIdx + 1]
			markerObj.parent = parentNode
			
			-- Apply transform in parent space with negated quaternion (matching gbxmodel)
			local negatedQuat = quat (-rotation.x) (-rotation.y) (-rotation.z) rotation.w
			in coordsys parent markerObj.rotation = negatedQuat
			in coordsys parent markerObj.pos = translation
		)
		else
		(
			-- World space
			local negatedQuat = quat (-rotation.x) (-rotation.y) (-rotation.z) rotation.w
			markerObj.rotation = negatedQuat
			markerObj.pos = translation
		)
		
		-- Assign to "Markers" layer
		local markersLayer = LayerManager.getLayerFromName "Markers"
		if markersLayer == undefined then
			markersLayer = LayerManager.newLayerFromName "Markers"
		markersLayer.addNode markerObj
		
		append createdMarkers markerObj
	)
	
	logger "Markers created successfully!" logType: #success
	
	return createdMarkers
)

-------------------------------------------------------
-- MESH CREATION
-------------------------------------------------------

-- Build geometry mesh from JMS data
fn buildGeometry jmsData createdNodes materials jmsFileName =
(
	if jmsData.triangleCount == 0 or jmsData.vertexCount == 0 then
	(
		logger "No geometry to build." logType: #warning
		return undefined
	)
	
	logger ("Building geometry: " + jmsData.vertexCount as string + " vertices, " + jmsData.triangleCount as string + " triangles...\n") logType: #info
	
	-- Pre-allocate vertex arrays
	local vertPositions = #()
	vertPositions.count = jmsData.vertexCount
	
	local vertNormals = #()
	vertNormals.count = jmsData.vertexCount
	
	local vertUVs = #()
	vertUVs.count = jmsData.vertexCount
	
	-- Convert vertices
	for i = 1 to jmsData.vertexCount do
	(
		local vert = jmsData.vertices[i]
		vertPositions[i] = vert.position * HALO_SCALE
		vertNormals[i] = normalize vert.normal
		vertUVs[i] = [vert.texturePos[1], vert.texturePos[2], 0]
	)
	
	-- Group triangles by region
	local regionTriangles = #()
	for r = 1 to jmsData.regionCount do
		regionTriangles[r] = #()
	
	for i = 1 to jmsData.triangleCount do
	(
		local tri = jmsData.triangles[i]
		local regionIdx = tri.regionIndex
		local matID = tri.shaderIndex + 1
		local face = [tri.vertexIndices[1] + 1, tri.vertexIndices[2] + 1, tri.vertexIndices[3] + 1]
		local triangleData = #(face, matID)
		
		if regionIdx >= 0 and regionIdx < jmsData.regionCount then
			append regionTriangles[regionIdx + 1] triangleData
	)
	
	-- Create separate mesh for each region
	local createdMeshes = #()
	local fileNameNoExt = getFilenameFile jmsFileName
	
	for r = 1 to jmsData.regionCount do
	(
		local regionName = jmsData.regions[r].regionName
		local triangles = regionTriangles[r]
		
		if triangles.count == 0 then
			continue
		
		logger ("Building region: " + regionName + " (" + triangles.count as string + " triangles)\n") logType: #info
		
		-- Extract unique vertices used by this region
		local usedVertIndices = #()
		local vertexRemap = #()
		vertexRemap.count = jmsData.vertexCount
		
		for i = 1 to jmsData.vertexCount do
			vertexRemap[i] = -1
		
		-- Collect unique vertices
		for triData in triangles do
		(
			local face = triData[1]
			local v1 = face[1]
			local v2 = face[2]
			local v3 = face[3]
			
			if vertexRemap[v1] == -1 then
			(
				append usedVertIndices v1
				vertexRemap[v1] = usedVertIndices.count
			)
			if vertexRemap[v2] == -1 then
			(
				append usedVertIndices v2
				vertexRemap[v2] = usedVertIndices.count
			)
			if vertexRemap[v3] == -1 then
			(
				append usedVertIndices v3
				vertexRemap[v3] = usedVertIndices.count
			)
		)
		
		-- Build vertex arrays for this region
		local regionVertPositions = #()
		local regionVertNormals = #()
		local regionVertUVs = #()
		
		for vi in usedVertIndices do
		(
			append regionVertPositions vertPositions[vi]
			append regionVertNormals vertNormals[vi]
			append regionVertUVs vertUVs[vi]
		)
		
		-- Build face array with remapped indices
		local regionFaces = #()
		local regionFaceMaterials = #()
		
		for triData in triangles do
		(
			local face = triData[1]
			local matID = triData[2]
			
			local remappedFace = [vertexRemap[face[1]], vertexRemap[face[2]], vertexRemap[face[3]]]
			append regionFaces remappedFace
			append regionFaceMaterials matID
		)
		
		-- Create mesh for this region
		local meshObj = mesh vertices:regionVertPositions faces:regionFaces
		meshObj.name = regionName + " " + fileNameNoExt
		
		-- Set UV coordinates
		setNumTVerts meshObj regionVertPositions.count
		
		for i = 1 to regionVertPositions.count do
			setTVert meshObj i regionVertUVs[i]
		
		-- Build TV faces
		buildTVFaces meshObj
		for i = 1 to regionFaces.count do
			setTVFace meshObj i regionFaces[i]
		
		-- Set material IDs
		for i = 1 to regionFaces.count do
			setFaceMatID meshObj i regionFaceMaterials[i]
		
		-- Apply material
		if materials != undefined then
			meshObj.material = materials
		
		-- Don't set smoothing groups or explicit normals - let 3ds Max use default face smoothing
		-- This matches gbxmodel importer behavior and preserves hard edges properly
		
		-- Link to main frame node
		if createdNodes.count > 0 then
		(
			local mainFrame = createdNodes[1]
			meshObj.parent = mainFrame
		)

		-- Assign to "Geometry Model" layer
		local geoLayer = LayerManager.getLayerFromName "Geometry Model"
		if geoLayer == undefined then
			geoLayer = LayerManager.newLayerFromName "Geometry Model"
		geoLayer.addNode meshObj
		
		-- Add to named selection set (region name) - reuse if exists
		local selSetName = regionName
		local existingSet = selectionSets[selSetName]
		if existingSet != undefined then
		(
			-- Collect objects from selection set, append new object, recreate selection set
			local existingObjs = for obj in existingSet collect obj
			append existingObjs meshObj
			selectionSets[selSetName] = existingObjs
		)
		else
		(
			selectionSets[selSetName] = #(meshObj)
		)
		
		-- Weld vertices FIRST so smoothing groups work properly
		local preWeldVertCount = meshObj.numverts
		meshop.weldVertsByThreshold meshObj #{1..meshObj.numverts} 0.00001
		local postWeldVertCount = meshObj.numverts
		
		logger ("Welded vertices: " + preWeldVertCount as string + " -> " + postWeldVertCount as string + "\n") logType: #info
		
		-- Apply smoothing groups AFTER welding
		if jmsData.smoothingGroups != undefined and jmsData.smoothingGroups.count > 0 then
		(
			local globalTriIndex = 0
			
			-- Find the starting triangle index for this region
			for t = 1 to jmsData.triangles.count do
			(
				if jmsData.triangles[t].regionIndex < (r - 1) then
					globalTriIndex += 1
				else
					exit
			)
			logger ("Applying smoothing groups to region " + regionName + " (starting at tri " + globalTriIndex as string + ")\n") logType: #info
			-- Apply smoothing groups to this mesh's faces
			for f = 1 to meshObj.numfaces do
			(
				local triIndex = globalTriIndex + f
				if triIndex <= jmsData.smoothingGroups.count then
				(
					local sg = jmsData.smoothingGroups[triIndex]
					setFaceSmoothGroup meshObj f sg
				)
			)
		)
		else
		(
			logger ("No smoothing groups available in JMS data\n") logType: #info
		)
		
		-- Build bone weight arrays for WELDED mesh vertices
		-- After welding, face vertex indices are updated to point to welded vertices
		-- We need to map each welded vertex back to an original vertex by tracing face topology
		
		-- Build map: original vertex index -> welded vertex index
		local originalToWeldedMap = #()
		for i = 1 to preWeldVertCount do
			append originalToWeldedMap 0
		
		-- Scan all faces to find which welded vertex each original vertex maps to
		for faceIdx = 1 to meshObj.numfaces do
		(
			local faceVerts = getFace meshObj faceIdx
			local remappedFace = regionFaces[faceIdx]  -- Original face with pre-weld indices
			
			-- Map original vertex indices to current welded indices
			if originalToWeldedMap[remappedFace[1]] == 0 then
				originalToWeldedMap[remappedFace[1]] = faceVerts[1]
			if originalToWeldedMap[remappedFace[2]] == 0 then
				originalToWeldedMap[remappedFace[2]] = faceVerts[2]
			if originalToWeldedMap[remappedFace[3]] == 0 then
				originalToWeldedMap[remappedFace[3]] = faceVerts[3]
		)
		
		-- Build reverse map: welded vertex index -> original vertex index
		local weldedToOriginalMap = #()
		for i = 1 to postWeldVertCount do
			append weldedToOriginalMap 0
		
		for origIdx = 1 to originalToWeldedMap.count do
		(
			local weldedIdx = originalToWeldedMap[origIdx]
			if weldedIdx > 0 and weldedToOriginalMap[weldedIdx] == 0 then
				weldedToOriginalMap[weldedIdx] = origIdx
		)
		
		local weldedNodeIndices = #()
		local weldedNodeWeights = #()
		
		-- Process each welded vertex and get bone weights from its original vertex
		for v = 1 to postWeldVertCount do
		(
			local originalIdx = weldedToOriginalMap[v]
			
			if originalIdx > 0 and originalIdx <= usedVertIndices.count then
			(
				local globalVertIdx = usedVertIndices[originalIdx] as integer
				if globalVertIdx > 0 and globalVertIdx <= jmsData.vertices.count then
				(
					local vertData = jmsData.vertices[globalVertIdx]
					append weldedNodeIndices #(vertData.node0Index + 1, vertData.node1Index + 1)
					append weldedNodeWeights #((1.0 - vertData.node1Weight), vertData.node1Weight)
				)
				else
				(
					append weldedNodeIndices #(1, -1)
					append weldedNodeWeights #(1.0, 0.0)
				)
			)
			else
			(
				append weldedNodeIndices #(1, -1)
				append weldedNodeWeights #(1.0, 0.0)
			)
		)
		
		-- Apply skin modifier with welded vertex bone data
		if createdNodes.count > 0 and weldedNodeIndices.count == postWeldVertCount then
		(
			local skinMod = Skin()
			addModifier meshObj skinMod
			skinMod.bone_Limit = 2
			
			-- Add all bones
			for n = 1 to createdNodes.count do
				skinOps.addBone skinMod createdNodes[n] 1
			
			-- Apply bone weights to each welded vertex
			for v = 1 to postWeldVertCount do
			(
				local node0Idx = weldedNodeIndices[v][1]
				local node1Idx = weldedNodeIndices[v][2]
				local node0Weight = weldedNodeWeights[v][1]
				local node1Weight = weldedNodeWeights[v][2]
				
				if node1Idx <= 0 or node1Idx > createdNodes.count then
				(
					if node0Idx > 0 and node0Idx <= createdNodes.count then
						skinOps.ReplaceVertexWeights skinMod v node0Idx 1.0
				)
				else if node0Idx <= 0 or node0Idx > createdNodes.count then
				(
					if node1Idx > 0 and node1Idx <= createdNodes.count then
						skinOps.ReplaceVertexWeights skinMod v node1Idx 1.0
				)
				else if node0Idx == node1Idx then
				(
					skinOps.ReplaceVertexWeights skinMod v node0Idx 1.0
				)
				else
				(
					skinOps.ReplaceVertexWeights skinMod v #(node0Idx, node1Idx) #(node0Weight, node1Weight)
				)
			)
		)
		

		append createdMeshes meshObj
	)
	logger "Geometry built successfully!" logType: #success
	return createdMeshes
)

fn buildSkinModifier meshObj jmsData createdNodes usedVertIndices =
(
	logger "Applying skin weights..." logType: #info
	-- Add Skin modifier
	local skinMod = Skin()
	addModifier meshObj skinMod
	
	-- Set bone affect limit to 2
	skinMod.bone_Limit = 2
	
	-- Add all bones to the skin modifier
	for node in createdNodes do
	(
		if classOf node == BoneGeometry then
			skinOps.addBone skinMod node 1
	)
	
	-- Apply vertex weights (using vertex indices from the region)
	for i = 1 to usedVertIndices.count do
	(
		local globalVertIdx = usedVertIndices[i]
		local vert = jmsData.vertices[globalVertIdx]
		local node0Idx = vert.node0Index
		local node1Idx = vert.node1Index
		local node1Weight = vert.node1Weight
		
		-- Get bone indices in skin modifier (1-based)
		local boneCount = skinOps.getNumberBones skinMod
		local bone0SkinIdx = -1
		local bone1SkinIdx = -1
		
		-- Find matching bones
		for b = 1 to boneCount do
		(
			local bone = skinOps.getBoneName skinMod b 1
			if node0Idx >= 0 and node0Idx < createdNodes.count then
			(
				local node0 = createdNodes[node0Idx + 1]
				if bone == node0.name then
					bone0SkinIdx = b
			)
			
			if node1Idx >= 0 and node1Idx < createdNodes.count then
			(
				local node1 = createdNodes[node1Idx + 1]
				if bone == node1.name then
					bone1SkinIdx = b
			)
		)
		
		-- Set weights (i is the local vertex index in this mesh)
		if bone0SkinIdx > 0 and bone1SkinIdx > 0 and node1Weight > 0.0 then
		(
			-- Dual bone influence
			local weight0 = 1.0 - node1Weight
			skinOps.ReplaceVertexWeights skinMod i bone0SkinIdx weight0
			skinOps.ReplaceVertexWeights skinMod i bone1SkinIdx node1Weight
		)
		else if bone0SkinIdx > 0 then
		(
			-- Single bone influence
			skinOps.ReplaceVertexWeights skinMod i bone0SkinIdx 1.0
		)
	)
	logger "Skin weights applied!" logType: #success
)

logger "JMS Scene Builder module loaded." logType: #success