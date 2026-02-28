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

global HALO_SCALE = 100.0
global BONE_SIZE = 1.0

-------------------------------------------------------
-- MATERIAL HELPERS
-------------------------------------------------------
--
fn stringToColor str =
(
	local hash = 0
	for i = 1 to str.count do
	(
		hash += (bit.charasint str[i]) * (i * 31)
	)
	
	local r = (mod (hash * 73) 156) + 100
	local g = (mod (hash * 151) 156) + 100
	local b = (mod (hash * 257) 156) + 100
	
	return (color r g b)
)

-------------------------------------------------------
-- MATERIAL CREATION
-------------------------------------------------------

fn createGBXModelMultiMaterial gbxmodelPath shaders gbxModelName =
(
	if shaders == undefined or shaders.count == 0 then
		return undefined
	
	-- Resolve shader textures using new parser approach
	local textureResults = resolveAllShaderTextures gbxmodelPath shaders
	
	local multiMat = MultiMaterial numSubs:shaders.count
	multiMat.name = gbxModelName
	
	for i = 1 to shaders.count do
	(
		local shader = shaders[i]
		local subMat = StandardMaterial()
		
		-- Get shader name from tag reference path
		local shaderTagRef = getFieldValue shader "shader"
		local shaderName = "unknown"
		if shaderTagRef != undefined and shaderTagRef[#path] != undefined then
		(
			local pathParts = filterString shaderTagRef[#path] "\\"
			if pathParts.count > 0 then
				shaderName = pathParts[pathParts.count]
		)
		
		subMat.name = shaderName
		subMat.showInViewport = true
		
		-- Find corresponding texture result
		local textureResult = undefined
		for result in textureResults where result != undefined and result.shaderIndex == (i - 1) do
		(
			textureResult = result
			exit
		)
		
		-- Apply texture if resolved successfully
		if textureResult != undefined then
		(
			logger.debug "Material '{}': textureFilePath: '{}'" args:#(shaderName, textureResult.textureFilePath)
		)
		
		if textureResult != undefined and textureResult.success and doesFileExist textureResult.textureFilePath then
		(
			logger.debug "Applying texture {} to material: '{}'" args:#((getFilenameFile textureResult.textureFilePath + getFilenameType textureResult.textureFilePath), shaderName)
			local diffuseMap = Bitmaptexture fileName:textureResult.textureFilePath
			subMat.diffusemap = diffuseMap
			subMat.showInViewport = true
			
			-- For transparent shaders, apply texture to opacity channel
			local shaderType = textureResult.shaderType
			if shaderType == "shader_transparent_glass" or \
				shaderType == "shader_transparent_chicago" or \
				shaderType == "shader_transparent_chicago_extended" or \
				shaderType == "shader_transparent_generic" then
			(
				local opacityMap = Bitmaptexture fileName:textureResult.textureFilePath
				opacityMap.alphaSource = 2  -- Use image alpha
				subMat.opacitymap = opacityMap
			)
			else if shaderType == "shader_transparent_meter" or \
				shaderType == "shader_transparent_water" then
			(
				local opacityMap = Bitmaptexture fileName:textureResult.textureFilePath
				opacityMap.rgbOutput = 1
				subMat.opacitymap = opacityMap
			)
		)
		else
		(
			-- Apply checker pattern for missing textures
			if textureResult == undefined then
				logger.warn "Material '{}': No texture result ('applying checker')" args:#(shaderName)
			else if not textureResult.success then
				logger.warn "Material '{}': Texture resolution failed ('applying checker')" args:#(shaderName)
			else if textureResult.textureFilePath == undefined then
				logger.warn "Material '{}': No texture file path ('applying checker')" args:#(shaderName)
			else
				logger.warn "Material '{}': Texture file not found ('applying checker'): {}" args:#(shaderName, textureResult.textureFilePath)
			
			local checkerMap = Checker()
			checkerMap.color1 = color 25 25 25    -- #191919
			checkerMap.color2 = color 136 136 136  -- #888888
			checkerMap.coordinates.U_Tiling = 10.0
			checkerMap.coordinates.V_Tiling = 10.0
			
			subMat.diffusemap = checkerMap
			subMat.showInViewport = true
		)
		
		multiMat[i] = subMat
		multiMat.names[i] = shaderName
	)
	
	return multiMat
)

-------------------------------------------------------
-- NODE CREATION
-------------------------------------------------------

fn createGbxmodelNode nodeData nodeIndex allNodeData nodesLayer =
(
	local nodeName = nodeData.name
	
	-- Create ALL nodes as spheres at origin (matches old script approach)
	-- Bone nodes will be converted to actual bones in a later pass
	local nodeObj = Sphere radius:BONE_SIZE pos:[0,0,0] name:nodeName smooth:on
	
	-- Use isNodeObject from utils to check if this should be a bone
	if isNodeObject nodeObj then
		nodeObj.wirecolor = color 6 134 6  --#068606 Green for nodes that will become bones
	else
		nodeObj.wirecolor = color 128 128 128  --#808080 Gray for other nodes
	
	-- Assign to "Nodes" layer (layer passed in to avoid repeated lookups)
	nodesLayer.addNode nodeObj
	
	return nodeObj
)

-- Link node hierarchy and apply transforms (must be called after all nodes are created)
fn linkNodeHierarchy createdNodes nodeDataArray nodesLayer =
(
	-- First pass: link parent-child relationships
	for i = 1 to createdNodes.count do
	(
		local nodeObj = createdNodes[i]
		local nodeData = nodeDataArray[i]
		local parentIndex = nodeData.parentNode  -- Parent node index (-1 = no parent)
		
		if parentIndex >= 0 and parentIndex < createdNodes.count then
		(
			local parentObj = createdNodes[parentIndex + 1]  -- Convert 0-based to 1-based
			nodeObj.parent = parentObj
		)
	)
	
	-- Second pass: apply transforms in parent-local space
	for i = 1 to createdNodes.count do
	(
		local nodeObj = createdNodes[i]
		if nodeObj == undefined then continue
		
		local nodeData = nodeDataArray[i]
		local translation = nodeData.translation
		local rotation = nodeData.rotation  -- Already a quaternion value
		
		-- Scale translation from Halo units to 3ds Max units
		local scaledTranslation = translation * HALO_SCALE
		
		-- Apply quaternion directly (NO negation for spheres/helpers - only bones get negated)
		local rotQuat = normalize rotation
		
		-- Apply transform in parent-local space (separate statements match old script)
		in coordsys parent nodeObj.rotation = rotQuat
		in coordsys parent nodeObj.pos = scaledTranslation
	)
	
	-- Third pass: Convert spheres/helpers to bones for bip01 nodes
	for i = 1 to createdNodes.count do
	(
		local nodeObj = createdNodes[i]
		if nodeObj == undefined then continue
		
		local nodeData = nodeDataArray[i]
		local nodeName = nodeData.name
		local firstChild = nodeData.firstChildNode
		local parentIndex = nodeData.parentNode
		local translation = nodeData.translation
		local rotation = nodeData.rotation
		
		if isNodeObject nodeObj then
		(
			-- Get current WORLD position (already transformed)
			local nodeWorldPos = nodeObj.pos
			
			-- Determine bone end position in WORLD space
			local boneEndPos
			if firstChild >= 0 and firstChild < createdNodes.count then
			(
				local childObj = createdNodes[firstChild + 1]
				if childObj != undefined then
					boneEndPos = childObj.pos  -- Use world position
				else
					boneEndPos = nodeWorldPos + [BONE_SIZE, 0, 0]
			)
			else
			(
				boneEndPos = nodeWorldPos + [BONE_SIZE, 0, 0]
			)
			
			-- Create bone using WORLD positions
			local myBone = BoneSys.createBone nodeWorldPos boneEndPos [0, 0, 1]
			myBone.name = nodeName
			myBone.wirecolor = color 255 180 6 --#ffb406
			myBone.width = BONE_SIZE
			myBone.height = BONE_SIZE
			myBone.setBoneEnable false 0  -- Disable bone scaling on X axis
			myBone.setBoneEnable false 1  -- Disable bone scaling on Y axis  
			myBone.setBoneEnable false 2  -- Disable bone scaling on Z axis
			
			if firstChild >= 0 then
				myBone.taper = 70
			else
				myBone.taper = 50
			
			-- Apply special bone handling (matches old importer)
			local lowerName = toLower nodeName
			
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
			
			-- Delete old object and replace in array
			delete nodeObj
			createdNodes[i] = myBone
			
			-- Assign bone to "Nodes" layer (layer passed in to avoid repeated lookups)
			nodesLayer.addNode myBone
			
			-- Set parent (matches old script line 1061)
			if parentIndex >= 0 and parentIndex < createdNodes.count then
			(
				local parentObj = createdNodes[parentIndex + 1]
				if parentObj != undefined then
				(
					myBone.parent = parentObj
				)
			)
			
			-- Re-apply transforms (matches old script lines 1063-1064 exactly)
			-- IMPORTANT: Negate x, y, z components of quaternion for bones (old importer does this)
			local scaledTranslation = translation * HALO_SCALE
			local rotQuat = normalize (quat (-rotation.x) (-rotation.y) (-rotation.z) rotation.w)
			in coordsys parent myBone.rotation = rotQuat
			in coordsys parent myBone.pos = scaledTranslation
		)
		else
		(
			-- For non-bone nodes, re-link parent if needed
			if parentIndex >= 0 and parentIndex < createdNodes.count then
			(
				local parentObj = createdNodes[parentIndex + 1]
				if parentObj != undefined then
				(
					nodeObj.parent = parentObj
				)
			)
		)
	)
)

fn createGBXModelNodes nodes =
(
	if nodes == undefined or nodes.count == 0 then
	(
		logger.warn "No nodes found in model\n"
		return #()
	)
	
	-- Convert tuples to structs for fast access
	local gbxNodes = tuplesToGBXModelStructs nodes #node
	
	-- Get "Nodes" layer once (avoid repeated lookups)
	local nodesLayer = LayerManager.getLayerFromName "Nodes"
	if nodesLayer == undefined then
		nodesLayer = LayerManager.newLayerFromName "Nodes"
	
	local createdNodes = #()
	
	-- First pass: create all nodes as spheres
	for i = 1 to gbxNodes.count do
	(
		local nodeData = gbxNodes[i]
		local nodeObj = createGbxmodelNode nodeData i gbxNodes nodesLayer
		
		if nodeObj != undefined then
			append createdNodes nodeObj
		else
			append createdNodes undefined  -- Keep array indices aligned
	)
	
	-- Second pass: link hierarchy, transform, and convert to bones
	linkNodeHierarchy createdNodes gbxNodes nodesLayer
	
	--logger.info "Created {} nodes\n" args:#(createdNodes.count)
	
	return createdNodes
)

-------------------------------------------------------
-- MARKER CREATION
-------------------------------------------------------

fn createGBXModelMarkers regions gbxNodes createdNodes =
(
	if regions == undefined or regions.count == 0 then
	(
		logger.debug "No regions found for markers"
		return #()
	)
	
	-- Get "Markers" layer once (avoid repeated lookups)
	local markersLayer = LayerManager.getLayerFromName "Markers"
	if markersLayer == undefined then
		markersLayer = LayerManager.newLayerFromName "Markers"
	
	-- Convert tuples to structs
	local gbxRegions = tuplesToGBXModelStructs regions #region
	
	local createdMarkers = #()
	local markerSize = 1.0  -- Default marker radius
	
	-- Build hashtable of existing markers for fast duplicate checking (O(1) vs O(n))
	local existingMarkers = dictionary #string  -- Dictionary for fast lookup
	for node in createdNodes where node != undefined do
	(
		for child in node.children do
		(
			if matchPattern child.name pattern:"#*" then
				existingMarkers[child.name] = child
		)
	)
	
	for region in gbxRegions do
	(
		for permutation in region.permutations do
		(
			for marker in permutation.localMarkers do
			(
				local nodeIndex = marker.nodeIndex
				local markerName = marker.name
				local rotation = marker.rotation  -- Quaternion
				local translation = marker.translation  -- Point3
				
				-- Marker names in the scene have "#" prefix, but tag data doesn't
				local markerNameWithPrefix = "#" + markerName
				
				-- Fast duplicate check using hashtable (O(1) instead of O(n))
				local existingMarker = existingMarkers[markerNameWithPrefix]
				if existingMarker != undefined then
				(
					append createdMarkers existingMarker
					continue
				)
				
				-- Create marker using Halo Helper (createHaloMarker handles the "#" prefix automatically)
				local markerObj = createHaloMarker \
					pos:[0,0,0] \
					radius:markerSize \
					markerType:"Marker" \
					name:markerName \
					wireColor:(color 0 240 255)  --#00f0ff
				
				-- Assign to "Markers" layer (layer passed in to avoid repeated lookups)
				markersLayer.addNode markerObj
				
				-- Link to corresponding node
				if nodeIndex >= 0 and nodeIndex < createdNodes.count then
				(
					local parentNode = createdNodes[nodeIndex + 1]  -- Convert 0-based to 1-based
					if parentNode != undefined then
					(
						markerObj.parent = parentNode
						
						-- Apply transform in parent-local space
						-- Negate x, y, z components of quaternion (same as bones)
						local rotQuat = normalize (quat (-rotation.x) (-rotation.y) (-rotation.z) rotation.w)
						
						in coordsys parent (
							markerObj.rotation = rotQuat
							markerObj.pos = translation * HALO_SCALE
						)
					)
				)
				
				append createdMarkers markerObj
			)
		)
	)
	
	return createdMarkers
)

-------------------------------------------------------
-- GEOMETRY CREATION
-------------------------------------------------------

-- Build mesh from part data (reads vertices/triangles on-demand from file)
fn buildPartMesh fileHandle geometryIndex partIndex partStruct materialObj uScale:1.0 vScale:1.0 =
(
	-- Access part data directly from struct properties
	local shaderIndex = partStruct.shaderIndex
	local uncompVertArray = partStruct.uncompressedVerticesReflexive
	local compVertArray = partStruct.compressedVerticesReflexive 
	local trianglesArray = partStruct.trianglesReflexive
	
	local uncompVertCount = if uncompVertArray != undefined then uncompVertArray.count else 0
	local compVertCount = if compVertArray != undefined then compVertArray.count else 0
	local triangleCount = if trianglesArray != undefined then trianglesArray.count else 0
	
	-- Auto-detect best vertex format (validate compressed data if both exist)
	local useCompressed = false
	if compVertCount > 0 and uncompVertCount > 0 then
	(
		-- Both formats exist - always prefer compressed (faster to read and build)
		useCompressed = true
	)
	else if compVertCount > 0 then
	(
		useCompressed = true  -- Only compressed exists
	)
	else if uncompVertCount > 0 then
	(
		useCompressed = false  -- Only uncompressed exists
	)
	
	local vertexCount = if useCompressed then compVertCount else uncompVertCount
	
	if vertexCount == 0 or triangleCount == 0 then
		return undefined
	
	-- Pre-allocate arrays
	local vertexPositions = #()
	vertexPositions.count = vertexCount
	local uvCoords = #()
	uvCoords.count = vertexCount
	local normals = #()
	normals.count = vertexCount
	local nodeIndices = #()
	nodeIndices.count = vertexCount
	local nodeWeights = #()
	nodeWeights.count = vertexCount
	
	-- Log which format is being used
	local formatName = if useCompressed then "compressed" else "uncompressed"
	logger.debug "Part {}: using {} vertices ({} comp, {} uncomp)" args:#(partIndex, formatName, compVertCount, uncompVertCount)
	
	-- Check for local node remapping (direct struct property access)
	local localNodes = partStruct.localNodeIndices
	local hasLocalNodes = (localNodes != undefined and localNodes.count > 0)
	
	if hasLocalNodes then
		logger.debug "Part {}: Has {} local nodes: {}" args:#(partIndex, localNodes.count, (localNodes as string))
	else
		logger.debug "Part {}: No local nodes" args:#(partIndex)
	
	-- Process vertices (data is already in parsed arrays)
	if useCompressed then
	(
		-- Convert all compressed vertices at once
		local vertices = tuplesToGBXModelStructs compVertArray #compressedVertex
		
		-- NOTE: Compressed vertices DO NOT use local nodes - they use global node indices directly
		-- Only uncompressed vertices can use local node remapping
		
		for v = 1 to vertexCount do
		(
			local vert = vertices[v]
			
			-- Position (already Point3)
			vertexPositions[v] = vert.position * HALO_SCALE
			
			-- Decompress normal from packed uint32
			normals[v] = decompressNormal vert.normal
			
			-- Decompress UV
			uvCoords[v] = decompressUV vert.textureCoordinateU vert.textureCoordinateV uScale:uScale vScale:vScale
			
			-- Decompress node indices (compressed vertices use GLOBAL indices, no remapping)
			local indices = decompressNodeIndices vert.nodeIndex0 vert.nodeIndex1
			local idx0 = indices[1]
			local idx1 = indices[2]
			
			-- Validate indices (fallback if invalid)
			if idx0 < 1 or idx0 > 255 then idx0 = 1
			if idx1 < 1 or idx1 > 255 then idx1 = idx0
			
			nodeIndices[v] = #(idx0, idx1)
			
			-- Decompress weight
			local weight0 = decompressNodeWeight vert.nodeWeight0
			-- Clamp weight to valid range
			if weight0 < 0.0 then weight0 = 0.0
			if weight0 > 1.0 then weight0 = 1.0
			nodeWeights[v] = #(weight0, 1.0 - weight0)
		)
	)
	else
	(
		-- Convert all uncompressed vertices at once
		local vertices = tuplesToGBXModelStructs uncompVertArray #uncompressedVertex
		
		-- Get local nodes from struct property
		local localNodes = partStruct.localNodeIndices
		local hasLocalNodes = (localNodes != undefined and localNodes.count > 0)
		
		for v = 1 to vertexCount do
		(
			local vert = vertices[v]
			
			-- Position (already Point3)
			vertexPositions[v] = vert.position * HALO_SCALE
			
			-- Normal (already Vector3D)
			normals[v] = normalize [vert.normal.x, vert.normal.y, vert.normal.z]
			
			--UV (apply scale and flip V)
			uvCoords[v] = [vert.textureCoordinateU * uScale, (1.0 - vert.textureCoordinateV) * vScale, 0]
			
			-- Node indices (store 0-based initially)
			local localIdx0 = vert.nodeIndex0
			local localIdx1 = vert.nodeIndex1
			
			-- Remap from local to global indices if needed
			local idx0 = localIdx0
			local idx1 = localIdx1
			
			if hasLocalNodes then
			(
				-- Remap using local node table
				if localIdx0 >= 0 and localIdx0 < localNodes.count then
					idx0 = localNodes[localIdx0 + 1]  -- Get global index from local table
				else
					idx0 = 0  -- Default to node 0 if out of range
					
				if localIdx1 >= 0 and localIdx1 < localNodes.count then
					idx1 = localNodes[localIdx1 + 1]  -- Get global index from local table
				else
					idx1 = idx0  -- Use same as idx0 if invalid
					
				-- Log first vertex remapping
				if v == 1 then
					logger.info "Vert 1 remap: Local [{},{}] -> Global [{},{}]" args:#(localIdx0, localIdx1, idx0, idx1)
			)
			
			-- Convert to 1-based for MaxScript
			idx0 = idx0 + 1
			idx1 = if idx1 >= 0 then (idx1 + 1) else idx0
			
			-- Clamp to valid range (fallback if indices are invalid)
			if idx0 < 1 or idx0 > 255 then idx0 = 1
			if idx1 < 1 or idx1 > 255 then idx1 = idx0
			
			nodeIndices[v] = #(idx0, idx1)
			nodeWeights[v] = #(vert.nodeWeight0, vert.nodeWeight1)
		)
	)
	
	-- Process triangles (convert triangle strip to individual triangles)
	-- Convert all triangles at once
	local triangles = tuplesToGBXModelStructs trianglesArray #triangle
	
	local vertexOrder = #()
	for t = 1 to triangleCount do
	(
		local tri = triangles[t]
		
		append vertexOrder (tri.vertex0 + 1)  -- Convert to 1-based
		append vertexOrder (tri.vertex1 + 1)
		append vertexOrder (tri.vertex2 + 1)
	)
	
	-- Convert triangle strip to individual triangles
	local triangleIndices = #()
	for w = 1 to (vertexOrder.count - 2) do
	(
		append triangleIndices [vertexOrder[w], vertexOrder[w+1], vertexOrder[w+2]]
	)
	
	-- Fix winding order for triangle strip (reverse odd triangles)
	for r = 1 to triangleIndices.count by 2 do
	(
		local temp = triangleIndices[r][1]
		triangleIndices[r][1] = triangleIndices[r][3]
		triangleIndices[r][3] = temp
	)
	
	-- Remove degenerate triangles
	for i = triangleIndices.count to 1 by -1 do
	(
		local tri = triangleIndices[i]
		if tri[1] == tri[2] or tri[2] == tri[3] or tri[1] == tri[3] or \
			tri[1] > vertexCount or tri[2] > vertexCount or tri[3] > vertexCount or \
			tri[1] <= 0 or tri[2] <= 0 or tri[3] <= 0 then
		(
			deleteItem triangleIndices i
		)
	)
	
	if triangleIndices.count == 0 then
		return undefined
	
	-- Create mesh
	local meshName = "geo_" + geometryIndex as string + "_part_" + partIndex as string
	local meshObj = mesh vertices:vertexPositions faces:triangleIndices
	meshObj.name = meshName
	meshObj.wirecolor = color 200 200 200
	
	-- Clear smoothing groups (use explicit normals)
	for i = 1 to meshObj.numfaces do
		setFaceSmoothGroup meshObj i 0
	
	-- Apply UVs
	if uvCoords.count == vertexPositions.count then
	(
		setNumTVerts meshObj uvCoords.count
		buildTVFaces meshObj
		
		for i = 1 to uvCoords.count do
			setTVert meshObj i uvCoords[i]
		
		for i = 1 to triangleIndices.count do
			setTVFace meshObj i triangleIndices[i]
		
		update meshObj
	)
	
	-- Set per-face material ID from shaderIndex unconditionally so the correct
	-- IDs are preserved even when materialObj is undefined (geometry is built
	-- before materials are resolved in buildGBXModelMesh)
	local materialID = shaderIndex + 1
	for i = 1 to meshObj.numfaces do
		setFaceMatID meshObj i materialID
	
	-- Assign material object if already available
	if materialObj != undefined then
		meshObj.material = materialObj
	
	return #(meshObj, nodeIndices, nodeWeights, normals)
)

-- Build all geometry meshes
fn createGBXModelGeometry regions geometries materialObj createdNodes =
(
	if regions == undefined or regions.count == 0 then
		return #()
	
	if geometries == undefined or geometries.count == 0 then
		return #()
	
	local geometryLayer = LayerManager.getLayerFromName "Geometry Model"
	if geometryLayer == undefined then
		geometryLayer = LayerManager.newLayerFromName "Geometry Model"
	
	local createdMeshes = #()
	local importedGeometryIndices = #()
	
	-- Track meshes by region for Named Selection Sets
	struct RegionMeshEntry (regionName, meshes = #())
	local regionMeshMap = #()
	
	-- Convert to structs
	local gbxRegions = tuplesToGBXModelStructs regions #region
	local gbxGeometries = tuplesToGBXModelStructs geometries #geometry
	
	for region in gbxRegions do
	(
		for permutation in region.permutations do
		(
			-- Process LOD levels
			local lodLevels = #(
				#("superhigh", permutation.superHighGeometryBlock),
				#("high", permutation.highGeometryBlock),
				#("medium", permutation.mediumGeometryBlock),
				#("low", permutation.lowGeometryBlock),
				#("superlow", permutation.superLowGeometryBlock)
			)
			
			for lodEntry in lodLevels do
			(
				local lodName = lodEntry[1]
				local geoIndex = lodEntry[2]
				
				if geoIndex < 0 or geoIndex >= gbxGeometries.count then continue
				
				local geometryIndex = geoIndex + 1
				
				if findItem importedGeometryIndices geometryIndex > 0 then continue
				
				local geometry = gbxGeometries[geometryIndex]
				local parts = geometry.parts
				
				if parts == undefined or parts.count == 0 then continue
				
				local meshName = region.name + " " + permutation.name + " " + lodName
				
				-- Accumulate all part data
				local allVertices = #()
				local allUVs = #()
				local allNormals = #()
				local allFaces = #()
				local allMatIDs = #()
				local allNodeIndices = #()
				local allNodeWeights = #()
				local vertexOffset = 0
				
				for partIdx = 1 to parts.count do
				(
					local partResult = buildPartMesh undefined geometryIndex partIdx parts[partIdx] materialObj uScale:1.0 vScale:1.0
					
					if partResult == undefined then continue
					
					local tempMesh = partResult[1]
					local partNodeIndices = partResult[2]
					local partNodeWeights = partResult[3]
					local partNormals = partResult[4]
					
					local numVerts = tempMesh.numVerts
					local numFaces = tempMesh.numFaces
					
					-- Copy vertex data
					for v = 1 to numVerts do
						append allVertices (getVert tempMesh v)
					
					for v = 1 to numVerts do
						append allNormals partNormals[v]
					
					for v = 1 to numVerts do
						append allUVs (getTVert tempMesh v)
					
					for v = 1 to numVerts do
					(
						append allNodeIndices partNodeIndices[v]
						append allNodeWeights partNodeWeights[v]
					)
					
					-- Copy faces with offset
					for f = 1 to numFaces do
					(
						local face = getFace tempMesh f
						append allFaces [face[1] + vertexOffset, face[2] + vertexOffset, face[3] + vertexOffset]
						append allMatIDs (getFaceMatID tempMesh f)
					)
					
					vertexOffset += numVerts
					delete tempMesh
				)
				
				if allFaces.count == 0 then continue
				
				-- Create combined mesh
				local combinedMesh = mesh vertices:allVertices faces:allFaces materialIDs:allMatIDs
				combinedMesh.name = meshName
				combinedMesh.material = materialObj
				
				-- Apply UVs
				if allUVs.count > 0 then
				(
					setNumTVerts combinedMesh allUVs.count
					buildTVFaces combinedMesh
					
					for i = 1 to allUVs.count do
						setTVert combinedMesh i allUVs[i]
					
					for f = 1 to allFaces.count do
						setTVFace combinedMesh f allFaces[f]
				)
				
				-- Clear smoothing groups
				for i = 1 to combinedMesh.numfaces do
					setFaceSmoothGroup combinedMesh i 0
				
				-- Apply explicit normals
				if allNormals.count == combinedMesh.numverts then
				(
					for v = 1 to allNormals.count do
						setNormal combinedMesh v allNormals[v]
				)
				
				-- Apply skinning
				if allNodeIndices.count > 0 and createdNodes.count > 0 then
				(
					local skinMod = Skin()
					addModifier combinedMesh skinMod
					skinMod.bone_Limit = 2
					
					for n = 1 to createdNodes.count do
						skinOps.addBone skinMod createdNodes[n] 1
					
					for v = 1 to allNodeIndices.count do
					(
						local node0Idx = allNodeIndices[v][1]
						local node1Idx = allNodeIndices[v][2]
						local node0Weight = allNodeWeights[v][1]
						local node1Weight = allNodeWeights[v][2]
						
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
				
				append createdMeshes combinedMesh
				append importedGeometryIndices geometryIndex
				
				-- Track mesh by region name for Named Selection Sets
				local regionEntry = undefined
				for entry in regionMeshMap where entry.regionName == region.name do
					regionEntry = entry
				
				if regionEntry == undefined then
				(
					regionEntry = RegionMeshEntry regionName:region.name
					append regionMeshMap regionEntry
				)
				
				append regionEntry.meshes combinedMesh
				
				geometryLayer.addNode combinedMesh
				
				-- Parent to root node
				if createdNodes.count > 0 and createdNodes[1] != undefined then
					combinedMesh.parent = createdNodes[1]
			)
		)
	)
	
	-- Create Named Selection Sets for regions
	for entry in regionMeshMap do
	(
		if entry.meshes.count > 0 then
		(
			-- Check if selection set already exists
			local existingSet = selectionSets[entry.regionName]
			if existingSet != undefined then
			(
				-- Selection set exists - append new meshes to it
				local combinedArray = #()
				-- Add existing objects from the selection set
				for obj in existingSet do
					append combinedArray obj
				-- Add new meshes if they're not already in the set
				for mesh in entry.meshes do
				(
					if findItem combinedArray mesh == 0 then
						append combinedArray mesh
				)
				selectionSets[entry.regionName] = combinedArray
			)
			else
			(
				-- Selection set doesn't exist - create new one
				selectionSets[entry.regionName] = entry.meshes
			)
		)
	)
	
	return createdMeshes
)

-------------------------------------------------------
-- MAIN BUILD FUNCTION
-------------------------------------------------------

fn buildGBXModelMesh gbxModelData gbxModelName gbxmodelPath =
(
	--logger.info "Building GBX Model: {}" args:#(gbxModelName)
	-- Extract parsed data
	local nodes = getFieldValue gbxModelData "nodes"
	local shaders = getFieldValue gbxModelData "shaders"
	local regions = getFieldValue gbxModelData "regions"
	local markers = getFieldValue gbxModelData "markers"  -- Root level markers
	
	-- Create nodes (skeleton) FIRST
	local t1 = timestamp()
	local createdNodes = createGBXModelNodes nodes
	logger.info "Nodes created: {} in {} ms" args:#(createdNodes.count, (timestamp() - t1))
	
	-- Convert nodes to structs for marker creation
	local gbxNodes = tuplesToGBXModelStructs nodes #node
	
	-- Create markers from regions/permutations (local markers)
	local t2 = timestamp()
	local createdMarkers = createGBXModelMarkers regions gbxNodes createdNodes
	logger.info "Markers created: {} in {} ms" args:#(createdMarkers.count, (timestamp() - t2))
	
	-- Create markers from root level (global marker instances)
	if markers != undefined and markers.count > 0 then
	(
		-- TODO: Implement root level marker instances
		logger.warn "Root level markers not yet implemented"
	)
	
	-- Create geometry meshes (WITHOUT materials yet)
	local t3 = timestamp()
	local geometriesArray = getFieldValue gbxModelData "geometries"
	local createdMeshes = createGBXModelGeometry regions geometriesArray undefined createdNodes
	logger.info "Geometry built: {} in {} ms" args:#(createdMeshes.count, (timestamp() - t3))
	
	-- Create materials LAST (reads shader tag files separately)
	local t4 = timestamp()
	local multiMat = createGBXModelMultiMaterial gbxmodelPath shaders gbxModelName
	if multiMat != undefined then
	(
		meditMaterials[1] = multiMat
		-- Apply material to all created meshes
		for mesh in createdMeshes where mesh != undefined do
		(
			mesh.material = multiMat
		)
	)
	local matCount = if multiMat != undefined then 1 else 0
	logger.info "Materials created: {} in {} ms" args:#(matCount, (timestamp() - t4))
	
	
	return createdMeshes
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)