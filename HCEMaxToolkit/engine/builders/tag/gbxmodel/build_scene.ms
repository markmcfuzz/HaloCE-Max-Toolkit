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

global haloScale = 100.0
global boneSize = 1.0

-- mesh_normals.ms is loaded by init.ms; load it if Max still runs an older toolkit
global meshNormalsApply
if meshNormalsApply == undefined and rootEngine != undefined do
	fileIn (rootEngine + "shared\\utils\\mesh_normals.ms")

-------------------------------------------------------
-- SKELETON DETECTION AND REUSE
-------------------------------------------------------

-- Recursive helper function to collect all children in a hierarchy
-- Must be defined at module level (not nested) due to MaxScript scoping rules
-- Only collects bones and helpers (skeleton nodes), excludes geometry meshes and Markers
fn collectAllChildren parent theArray =
(
    for child in parent.children do
    (
        local childClass = classOf child

        if childClass == BoneGeometry or
        childClass == Sphere or
        childClass == Point or
        childClass == Dummy do
        append theArray child
        
        collectAllChildren child theArray
    )
)

-- Check if a bone hierarchy matches the incoming node data
-- Returns array of existing nodes in correct order if match found, undefined otherwise
fn findMatchingSkeleton nodeDataArray =
(
	-- Guard clause: check if nodeDataArray is undefined or invalid
	if nodeDataArray == undefined then
	(
		logger.warning "findMatchingSkeleton called with undefined nodeDataArray"
		return undefined
	)

	logger.debug "findMatchingSkeleton called with {} nodes"  args:#(nodeDataArray.count)
	
	if nodeDataArray.count == 0 then
		return undefined
	
	-- Get the root node name (first node with parentNode == -1)
	local rootNodeName = undefined
	for nodeData in nodeDataArray do
	(
		if nodeData.parentNode == -1 then
		(
			rootNodeName = nodeData.name
			exit
		)
	)
	
	logger.info "Root node name: '{}'"  args:#(rootNodeName)
	
	if rootNodeName == undefined then
		return undefined
	
	-- Find all potential root nodes in the scene with the same name
	local potentialRoots = for obj in objects where obj.name == rootNodeName collect obj
	logger.info "Found {} potential root objects in scene"  args:#(potentialRoots.count)
	
	if potentialRoots.count == 0 then
		return undefined
	
	-- For each potential root, collect its hierarchy and check if it matches
	for rootObj in potentialRoots do
	(
		--
		logger.debug "Checking root object: '{}'"  args:#(rootObj.name)
		
		-- Collect all nodes in this hierarchy
		local hierarchyNodes = #(rootObj)
		collectAllChildren rootObj hierarchyNodes

		
		logger.debug "Collected {} nodes in hierarchy"  args:#(hierarchyNodes.count)
		
		-- Check if node count matches
		if hierarchyNodes.count != nodeDataArray.count then
		(
			logger.error "Node count mismatch: hierarchy has {}, need {}"  args:#(hierarchyNodes.count, nodeDataArray.count)
			continue
		)
		
		logger.debug "Node counts match! Starting node matching..." 
		
		-- Try to match all nodes by name and parent relationship
		local orderedNodes = #()
		local allMatched = true
		
		for i = 1 to nodeDataArray.count do
		(
			local nodeData = nodeDataArray[i]
			
			-- Find node with matching name in hierarchy
			local foundNode = undefined
			for node in hierarchyNodes where node.name == nodeData.name do
			(
				foundNode = node
				exit
			)
			
			if foundNode == undefined then
			(
				logger.error "Could not find node '{}' in hierarchy"  args:#(nodeData.name)
				allMatched = false
				exit
			)
			logger.debug "Node {}: Found '{}'"  args:#(i, nodeData.name)
			-- Verify parent relationship
			local parentIndex = nodeData.parentNode
			if parentIndex >= 0 and parentIndex < nodeDataArray.count then
			(
				-- Get expected parent name from node data
				local expectedParentName = nodeDataArray[parentIndex + 1].name
				
				-- Check if found node's parent matches
				if foundNode.parent == undefined then
				(
					logger.error "Node '{}' has no parent, expected '{}'"  args:#(nodeData.name, expectedParentName)
					allMatched = false
					exit
				)
				else if foundNode.parent.name != expectedParentName then
				(
					logger.error "Node '{}' parent is '{}', expected '{}'"  args:#(nodeData.name, foundNode.parent.name, expectedParentName)
					allMatched = false
					exit
				)
			)
			else if parentIndex == -1 then
			(
				-- Root node should have no parent
				if foundNode.parent != undefined then
				(
					logger.error "Root node '{}' has parent '{}'"  args:#(nodeData.name, foundNode.parent.name)
					allMatched = false
					exit
				)
			)
			append orderedNodes foundNode
		)
		-- If all nodes matched, return the ordered array
		if allMatched then
		(
			logger.debug "Found matching skeleton: {} nodes"  args:#(orderedNodes.count)
			return orderedNodes
		)
	)
	return undefined
)

-- Show dialog asking user if they want to reuse existing skeleton
-- Returns true if user wants to reuse, false otherwise
fn askReuseSkeletonDialog =
(
	local result = queryBox "Skeleton detected in the scene!\n\nWould you like to reuse the existing bones?" \
		title:"Reuse Skeleton?" \
		beep:false
	
	return result
)

fn askReuseMarkersDialog =
(
	local result = queryBox "Markers detected in the scene!\n\nWould you like to reuse the existing markers?" \
		title:"Reuse Markers?" \
		beep:false
	
	return result
)

-------------------------------------------------------
-- NODE CREATION
-------------------------------------------------------

fn createGbxmodelNode nodeData nodeIndex allNodeData nodesLayer =
(
	local nodeName = nodeData.name
	
	-- Create ALL nodes as spheres at origin (matches old script approach)
	-- Bone nodes will be converted to actual bones in a later pass
	local nodeObj = Sphere radius:boneSize pos:[0,0,0] name:nodeName smooth:on
	
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
		local scaledTranslation = translation * haloScale
		
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
					boneEndPos = nodeWorldPos + [boneSize, 0, 0]
			)
			else
			(
				boneEndPos = nodeWorldPos + [boneSize, 0, 0]
			)
			
			-- Create bone using WORLD positions
			local myBone = BoneSys.createBone nodeWorldPos boneEndPos [0, 0, 1]
			myBone.name = nodeName
			myBone.wirecolor = color 255 180 6 --#ffb406
			myBone.width = boneSize
			myBone.height = boneSize
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
				myBone.width = boneSize
				myBone.height = boneSize / 2.0
				myBone.taper = -180
			)
			else if lowerName == "bip01 pelvis" or lowerName == "bip01 spine" then
			(
				myBone.width = boneSize
				myBone.height = boneSize / 2.0
				myBone.taper = -180
			)
			else if lowerName == "frame bone24" then
			(
				myBone.length = boneSize * 4
				myBone.width = boneSize * 4
				myBone.height = boneSize * 4
				myBone.taper = 100
			)
			else if lowerName == "frame l wriste" or lowerName == "frame r wriste" then
			(
				myBone.length = 2.8
				myBone.width = boneSize
				myBone.height = boneSize * 0.3
				myBone.taper = -270
			)
			else if lowerName == "frame l forearm" or lowerName == "frame r forearm" then
			(
				myBone.width = boneSize * 2
				myBone.height = boneSize * 2
			)
			else if lowerName == "frame l upperarm" or lowerName == "frame r upperarm" then
			(
				myBone.width = boneSize * 3
				myBone.height = boneSize * 3
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
			local scaledTranslation = translation * haloScale
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

fn createGBXModelNodes gbxNodes =
(
	if gbxNodes == undefined or gbxNodes.count == 0 then
	(
		logger.warn "No nodes found in model\n"
		return #()
	)

	-- Get "Nodes" layer once (avoid repeated lookups)
	local nodesLayer = LayerManager.getLayerFromName "Nodes"
	if nodesLayer == undefined then
		nodesLayer = LayerManager.newLayerFromName "Nodes"
	
	local createdNodes = #()
	
	-- Check if a matching skeleton already exists in the scene
	logger.info "Checking for matching skeleton..."
	local existingSkeleton = findMatchingSkeleton gbxNodes
	
	if existingSkeleton != undefined then
	(
		logger.info "Found existing skeleton! Asking user..."
		-- Ask user if they want to reuse the existing skeleton
		local reuseExisting = askReuseSkeletonDialog()
		
		if reuseExisting then
		(
			logger.info "Reusing existing skeleton from scene"
			return existingSkeleton
		)
		else
		(
			logger.info "Creating new skeleton"
		)
	)
	else
	(
		logger.info "No matching skeleton found, creating new one"
	)

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

fn createGBXModelMarkers gbxRegions createdNodes =
(
	if gbxRegions == undefined or gbxRegions.count == 0 then
	(
		logger.debug "No regions found for markers"
		return #()
	)

	-- Get "Markers" layer once (avoid repeated lookups)
	local markersLayer = LayerManager.getLayerFromName "Markers"
	if markersLayer == undefined then
		markersLayer = LayerManager.newLayerFromName "Markers"

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
	
	-- Check if any markers from the incoming data already exist
	local hasExistingMarkers = false
	if existingMarkers.count > 0 then
	(
		for region in gbxRegions do
		(
			for permutation in region.permutations do
			(
				for marker in permutation.localMarkers do
				(
					local markerNameWithPrefix = "#" + marker.name
					if existingMarkers[markerNameWithPrefix] != undefined then
					(
						hasExistingMarkers = true
						exit
					)
				)
				if hasExistingMarkers then exit
			)
			if hasExistingMarkers then exit
		)
	)
	
	-- Ask user if they want to reuse existing markers
	local reuseExisting = false
	if hasExistingMarkers then
	(
		logger.info "Found existing markers! Asking user..."
		reuseExisting = askReuseMarkersDialog()
		
		if reuseExisting then
		(
			logger.info "User chose to reuse existing markers"
		)
		else
		(
			logger.info "User chose to create new markers (duplicates allowed)"
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
				if existingMarker != undefined and reuseExisting then
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
							markerObj.pos = translation * haloScale
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

-- Build all geometry meshes
fn createGBXModelGeometry gbxRegions geometryMeshes materialObj createdNodes =
(
	if gbxRegions == undefined or gbxRegions.count == 0 then
		return #()
	
	if geometryMeshes == undefined or geometryMeshes.count == 0 then
		return #()
	
	local geometryLayer = LayerManager.getLayerFromName "Geometry Model"
	if geometryLayer == undefined then
		geometryLayer = LayerManager.newLayerFromName "Geometry Model"
	
	local createdMeshes = #()
	local importedGeometryIndices = #()
	
	-- Track meshes by region for Named Selection Sets
	struct RegionMeshEntry (regionName, meshes = #())
	local regionMeshMap = #()
	
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
				
				if geoIndex < 0 or geoIndex >= geometryMeshes.count then continue
				
				local geometryIndex = geoIndex + 1
				
				if findItem importedGeometryIndices geometryIndex > 0 then continue
				
				local geoMesh = geometryMeshes[geometryIndex]
				local meshName = region.name + " " + permutation.name + " " + lodName
				
				local allVertices = geoMesh.positions
				local allUVs = geoMesh.uvs
				local allNormals = geoMesh.normals
				local allFaces = geoMesh.faces
				local allMatIDs = geoMesh.matIDs
				local allNodeIndices = geoMesh.nodeIndices
				local allNodeWeights = geoMesh.nodeWeights
				
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
				
				-- Apply explicit normals (in one go; setNormal per vertex took seconds)
				if allNormals.count == combinedMesh.numverts then
					meshNormalsApply combinedMesh allFaces allNormals
				
				-- Apply skinning
				if allNodeIndices.count > 0 and createdNodes.count > 0 then
				(
					local skinMod = Skin()
					addModifier combinedMesh skinMod
					skinMod.bone_Limit = 2
					
					-- The skin only updates after the last bone
					for n = 1 to createdNodes.count do
						skinOps.addBone skinMod createdNodes[n] (if n == createdNodes.count then 1 else 0)
					
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
-- MATERIAL CREATION
-------------------------------------------------------

fn createGBXModelMultiMaterial gbxmodelPath shaders gbxModelName =
(
	if shaders == undefined or shaders.count == 0 then
		return undefined
	
	-- Resolve shader textures using new parser approach
	local textureResults = resolveAllShaderTextures gbxmodelPath shaders

	-- GlyphFX DirectX materials (supported shader types; falls back to StandardMaterial)
	local useDxMaterials = configManager.getBool "visual" "use_directx_materials" true
	
	local multiMat = MultiMaterial numSubs:shaders.count
	multiMat.name = gbxModelName
	
	for i = 1 to shaders.count do
	(
		local shader = shaders[i]
		
		-- Get shader name from tag reference path
		local shaderTagRef = getFieldValue shader "shader"
		local shaderName = "unknown"
		if shaderTagRef != undefined and shaderTagRef[#path] != undefined then
		(
			local pathParts = filterString shaderTagRef[#path] "\\"
			if pathParts.count > 0 then
				shaderName = pathParts[pathParts.count]
		)
		
		-- Find corresponding texture result
		local textureResult = undefined
		for result in textureResults where result != undefined and result.shaderIndex == (i - 1) do
		(
			textureResult = result
			exit
		)

		local subMat = buildShaderViewportMaterial textureResult shaderName useDxMaterials:useDxMaterials
		multiMat[i] = subMat
		multiMat.names[i] = shaderName
	)
	
	return multiMat
)

-------------------------------------------------------
-- MAIN BUILD FUNCTION
-------------------------------------------------------

-- model: GBXModel from readGbxModelWithLua (lua_reader.ms)
fn buildGBXModelMesh model gbxModelName gbxmodelPath =
(
	logger.info "UV Scales: U: {}, V: {}" args:#(model.uScale, model.vScale)
	
	-- Create nodes (skeleton) FIRST
	local t1 = timestamp()
	local createdNodes = createGBXModelNodes model.nodes
	logger.info "Nodes created: {} in {} ms" args:#(createdNodes.count, (timestamp() - t1))
	
	-- Create markers from regions/permutations (local markers)
	local t2 = timestamp()
	local createdMarkers = createGBXModelMarkers model.regions createdNodes
	logger.info "Markers created: {} in {} ms" args:#(createdMarkers.count, (timestamp() - t2))
	
	-- Create geometry meshes (WITHOUT materials yet)
	local t3 = timestamp()
	local createdMeshes = createGBXModelGeometry model.regions model.geometries undefined createdNodes
	logger.info "Geometry built: {} in {} ms" args:#(createdMeshes.count, (timestamp() - t3))
	
	-- Create materials LAST (reads shader tag files separately)
	local t4 = timestamp()
	local multiMat = createGBXModelMultiMaterial gbxmodelPath model.shaders gbxModelName
	if multiMat != undefined then
	(
		meditMaterials[1] = multiMat
		for mesh in createdMeshes where mesh != undefined do
			mesh.material = multiMat
	)
	local matCount = if multiMat != undefined then 1 else 0
	logger.info "Materials created: {} in {} ms" args:#(matCount, (timestamp() - t4))
	
	return createdMeshes
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)