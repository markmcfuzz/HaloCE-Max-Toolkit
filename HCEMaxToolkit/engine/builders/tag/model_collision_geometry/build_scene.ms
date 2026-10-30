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

-------------------------------------------------------
-- BITFIELD FLAG HELPERS
-------------------------------------------------------

-- Surface flags bit positions (8-bit bitfield)
fn isTwoSidedFlag flagValue = (bit.and flagValue 1) != 0  -- Bit 0
fn isInvisibleFlag flagValue = (bit.and flagValue 2) != 0  -- Bit 1
fn isClimbableFlag flagValue = (bit.and flagValue 4) != 0  -- Bit 2
fn isBreakableFlag flagValue = (bit.and flagValue 8) != 0  -- Bit 3

-- Convert integer bitfield to array of flag names (for material display)
fn surfaceFlagsToArray flagValue =
(
	local flagArray = #()
	if flagValue == undefined then return flagArray
	
	if isTwoSidedFlag flagValue then append flagArray "two_sided"
	if isInvisibleFlag flagValue then append flagArray "invisible"
	if isClimbableFlag flagValue then append flagArray "climbable"
	if isBreakableFlag flagValue then append flagArray "breakable"

	return flagArray
)

-- Collision material type enum -> name (used as the multi-material slot name)
fn materialTypeToString matType =
(
	case matType of
	(
		0: "dirt";
		1: "sand";
		2: "stone";
		3: "snow";
		4: "wood";
		5: "metal hollow";
		6: "metal thin";
		7: "metal thick";
		8: "rubber";
		9: "glass";
		10: "force field";
		11: "grunt";
		12: "hunter armor";
		13: "hunter skin";
		14: "elite";
		15: "jackal";
		16: "jackal energy shield";
		17: "engineer skin";
		18: "engineer force field";
		19: "flood combat form";
		20: "flood carrier form";
		21: "cyborg armor";
		22: "cyborg energy shield";
		23: "human armor";
		24: "human skin";
		25: "sentinel";
		26: "monitor";
		27: "plastic";
		28: "water";
		29: "leaves";
		30: "elite energy shield";
		31: "ice";
		32: "hunter shield";
		default: ("unknown_" + (matType as string))
	)
)

-------------------------------------------------------
-- MATERIAL CREATION
-------------------------------------------------------

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

fn createCollisionMultiMaterial materials collisionName surfaceFlagsArray =
(
	if materials == undefined or materials.count == 0 then
		return undefined
	
	local multiMat = MultiMaterial numSubs:materials.count
	multiMat.name = collisionName
	
	for i = 1 to materials.count do
	(
		local mat = materials[i]
		local subMat = StandardMaterial()
		
		local subMatName = mat.name
		if surfaceFlagsArray != undefined and i <= surfaceFlagsArray.count then
		(
			local flags = surfaceFlagsArray[i]
			if flags != undefined and flags.count > 0 then
			(
				-- flags is now an array of flag names from surfaceFlagsToArray
				local hasTwoSided = findItem flags "two_sided" > 0
				local hasInvisible = findItem flags "invisible" > 0
				local hasClimbable = findItem flags "climbable" > 0
				local hasBreakable = findItem flags "breakable" > 0
				
				-- Special case: two_sided + invisible = *
				if hasTwoSided and hasInvisible then
				(
					subMatName += "*"
				)
				else
				(
					if hasTwoSided then subMatName += "%"
					--if hasInvisible then subMatName += "@"
				)
				
				if hasClimbable then subMatName += "^"
				if hasBreakable then subMatName += "-"
			)
		)
		subMat.name = subMatName
		
		subMat.diffuse = stringToColor mat.name

		multiMat[i] = subMat
		multiMat.names[i] = materialTypeToString mat.materialType
	)
	
	return multiMat
)

-------------------------------------------------------
-- NODE VALIDATION
-------------------------------------------------------

fn validateSceneNodes collisionNodes =
(
	local missingNodes = #()

	for collNode in collisionNodes do
	(
		local nodeName = collNode.name
		local sceneNode = getNodeByName nodeName
		
		if sceneNode == undefined then
		(
			append missingNodes nodeName
		)
	)
	
	if missingNodes.count > 0 then
	(
		logger.warn "Missing scene nodes: {}" args:#(missingNodes)
		return false
	)
	else
	(
		logger.info "All scene nodes validated successfully."
		return true
	)
	
	return true
)

fn createFallbackFrameRoot =
(
	local nodeObj = Sphere radius:boneSize pos:[0,0,0] name:"frame root" smooth:on
	nodeObj.wirecolor = color 255 255 0
	
	logger.warn "Created fallback 'frame root' node (no scene nodes detected)"

	-- Assign to "Nodes" layer
	local nodesLayer = LayerManager.getLayerFromName "Nodes"
	if nodesLayer == undefined then
		nodesLayer = LayerManager.newLayerFromName "Nodes"
	nodesLayer.addNode nodeObj

	return nodeObj
)

-------------------------------------------------------
-- PATHFINDING SPHERES
-------------------------------------------------------

fn createPathfindingSpheres pathfindingSpheres collisionNodes =
(
	if pathfindingSpheres == undefined or pathfindingSpheres.count == 0 then
	(
		return #()
	)
	
	local createdHelpers = #()
	
	for i = 1 to pathfindingSpheres.count do
	(
		local pfSphere = pathfindingSpheres[i]
		
		local nodeIndex = pfSphere.node + 1

		if nodeIndex < 1 or nodeIndex > collisionNodes.count then continue

		local nodeName = collisionNodes[nodeIndex].name
		local sceneNode = getNodeByName nodeName

		if sceneNode == undefined then continue

		local localPos = pfSphere.center * haloScale
		local sphereRadius = pfSphere.radius * haloScale
		
		local nodeTransform = sceneNode.transform
		local worldPos = localPos * nodeTransform
		
		-- Create Halo Helper with Pathfinding type (createHaloHelper handles the "+" prefix automatically)
		local helperObj = createHaloPhysics \
			pos:worldPos \
			radius:sphereRadius \
			markerType:"Physics" \
			name:"pathfinding" \
			nearColor:(color 0 200 0)  \
			farColor:(color 0 200 0)   --#00c800 Green
		
		helperObj.parent = sceneNode
		
		local pathfindingLayer = LayerManager.getLayerFromName "Pathfinding Spheres"
		if pathfindingLayer == undefined then
			pathfindingLayer = LayerManager.newLayerFromName "Pathfinding Spheres"
		pathfindingLayer.addNode helperObj
		
		append createdHelpers helperObj		
	)

	--logger.info "Created {} pathfinding sphere(s)" args:#(createdHelpers.count)

	return createdHelpers
)

-------------------------------------------------------
-- GEOMETRY UTILITIES
-------------------------------------------------------

fn transformVertexFromPlane vertex planeNormal planeDistance =
(
	local zAxis = normalize planeNormal
	
	local xAxis
	if abs(zAxis.x) < 0.9 then
		xAxis = normalize (cross [1,0,0] zAxis)
	else
		xAxis = normalize (cross [0,1,0] zAxis)
	
	local yAxis = normalize (cross zAxis xAxis)
	
	local planeOrigin = planeNormal * planeDistance
	
	local worldPos = planeOrigin + (xAxis * vertex.x) + (yAxis * vertex.y) + (zAxis * vertex.z)
	
	return worldPos
)

-------------------------------------------------------
-- MESH BUILDING
-------------------------------------------------------

fn getSurfaceEdgeSet edges surf surfaceIndex0Based =
(
	-- Extract all edges for a surface and return as a sorted array of vertex pairs
	local edgeSet = #()
	local faceVerts = #()
	local currentEdgeIndex = surf.firstEdge
	local startEdgeIndex = surf.firstEdge
	local edgesProcessed = 0
	local maxEdges = edges.count
	
	while edgesProcessed < maxEdges do
	(
		if currentEdgeIndex < 0 or currentEdgeIndex >= edges.count then
			exit
		
		local edge = edges[currentEdgeIndex + 1]
		-- Direct struct property access - O(1)
		local edgeLeftSurface = edge.leftSurface
		local edgeRightSurface = edge.rightSurface
		local isLeftSurface = (edgeLeftSurface == surfaceIndex0Based)
		
		if isLeftSurface then
		(
			append faceVerts (edge.startVertex + 1)
			currentEdgeIndex = edge.forwardEdge
		)
		else if edgeRightSurface == surfaceIndex0Based then
		(
			append faceVerts (edge.endVertex + 1)
			currentEdgeIndex = edge.reverseEdge
		)
		else
			exit
		
		edgesProcessed += 1
		
		if currentEdgeIndex == startEdgeIndex then
			exit
	)
	
	-- Convert to sorted vertex pairs for comparison
	for i = 1 to faceVerts.count do
	(
		local v1 = faceVerts[i]
		local v2 = if i < faceVerts.count then faceVerts[i+1] else faceVerts[1]
		-- Store as sorted pair so we can detect same edge regardless of direction
		if v1 < v2 then
			append edgeSet #(v1, v2)
		else
			append edgeSet #(v2, v1)
	)
	
	qsort edgeSet (fn comparer a b = (if a[1] < b[1] then -1 else if a[1] > b[1] then 1 else (if a[2] < b[2] then -1 else if a[2] > b[2] then 1 else 0)))
	
	return edgeSet
)

fn edgeSetsMatch edgeSet1 edgeSet2 =
(
	if edgeSet1.count != edgeSet2.count then
		return false
	
	for i = 1 to edgeSet1.count do
	(
		if edgeSet1[i][1] != edgeSet2[i][1] or edgeSet1[i][2] != edgeSet2[i][2] then
			return false
	)
	
	return true
)

--
fn buildBSPGeometry bsp nodeName regionName permutationName materialOffset fallbackNode:undefined =
(
	if bsp.vertices == undefined or bsp.vertices.count == 0 then
	(
		return undefined
	)
	
	local meshName = "@" + regionName + " "
	if permutationName != undefined and permutationName != "" then
		meshName += permutationName + " "
	meshName += nodeName
	
	local sceneNode = getNodeByName nodeName
	if sceneNode == undefined then
	(
		sceneNode = fallbackNode
		if sceneNode == undefined then
			return undefined
	)
	
	local nodeTransform = sceneNode.transform
	
	local vertArray = #()
	for v in bsp.vertices do
	(
		local localPos = v * haloScale
		local worldPos = localPos * nodeTransform
		append vertArray worldPos
	)
	
	-- Pre-process surfaces to detect two-sided duplicates
	local processedSurfaces = #{}
	local surfaceEdgeSets = #()
	
	for surfIndex = 1 to bsp.surfaces.count do
	(
		local surf = bsp.surfaces[surfIndex]
		local surfaceIndex0Based = surfIndex - 1
		local edgeSet = getSurfaceEdgeSet bsp.edges surf surfaceIndex0Based
		append surfaceEdgeSets edgeSet
	)
	
	-- Build face array, skipping two-sided duplicates
	local faceArray = #()
	local matIDArray = #()
	
	for surfIndex = 1 to bsp.surfaces.count do
	(
		-- Skip if already marked as processed
		if processedSurfaces[surfIndex] then
			continue
		
		local surf = bsp.surfaces[surfIndex]
		-- Direct struct property access - O(1)
		local matID = surf.material + materialOffset + 1
		local surfFlags = surf.flags
		local firstEdge = surf.firstEdge
		local surfaceIndex0Based = surfIndex - 1
		
		-- Check if this surface has the two_sided flag
		local hasTwoSided = (surfFlags != undefined and isTwoSidedFlag surfFlags)
		
		-- If two-sided, look for duplicate surface and mark it to skip
		if hasTwoSided then
		(
			local currentEdgeSet = surfaceEdgeSets[surfIndex]
			
			for otherSurfIndex = (surfIndex + 1) to bsp.surfaces.count do
			(
				if processedSurfaces[otherSurfIndex] then
					continue
				
				local otherEdgeSet = surfaceEdgeSets[otherSurfIndex]
				
				-- If edge sets match, this is the duplicate back-face
				if edgeSetsMatch currentEdgeSet otherEdgeSet then
				(
					processedSurfaces[otherSurfIndex] = true
					exit
				)
			)
		)
		
		-- Process this surface normally
		local faceVerts = #()
		local currentEdgeIndex = firstEdge
		local startEdgeIndex = firstEdge
		local edgesProcessed = 0
		local maxEdges = bsp.edges.count
		
		while edgesProcessed < maxEdges do
		(
			if currentEdgeIndex < 0 or currentEdgeIndex >= bsp.edges.count then
				exit
			
			local edge = bsp.edges[currentEdgeIndex + 1]
			-- Direct struct property access - O(1)
			local edgeLeftSurface = edge.leftSurface
			local edgeRightSurface = edge.rightSurface
			local isLeftSurface = (edgeLeftSurface == surfaceIndex0Based)
			
			if isLeftSurface then
			(
				append faceVerts (edge.startVertex + 1)
				currentEdgeIndex = edge.forwardEdge
			)
			else if edgeRightSurface == surfaceIndex0Based then
			(
				append faceVerts (edge.endVertex + 1)
				currentEdgeIndex = edge.reverseEdge
			)
			else
				exit

			edgesProcessed += 1
			
			if currentEdgeIndex == startEdgeIndex then
				exit
		)
		
		if faceVerts.count >= 3 then
		(
			for i = 2 to (faceVerts.count - 1) do
			(
				append faceArray [faceVerts[1], faceVerts[i], faceVerts[i+1]]
				append matIDArray matID
			)
		)
	)
	
	if faceArray.count == 0 then
	(
		return undefined
	)
	local newMesh = mesh vertices:vertArray faces:faceArray materialIDs:matIDArray
	newMesh.name = meshName

	for f = 1 to newMesh.numfaces do
		setFaceSmoothGroup newMesh f 0
	
	newMesh.parent = sceneNode

	logger.debug "Mesh: '{}' parent to: '{}'" args:#(newMesh.name, sceneNode.name)

	local collisionLayer = LayerManager.getLayerFromName "Collision Model"
	if collisionLayer == undefined then
		collisionLayer = LayerManager.newLayerFromName "Collision Model"
	collisionLayer.addNode newMesh
	

	return newMesh
)

fn buildCollisionMesh collisionData collisionFileName =
(
	struct regionStruct (regionName, meshes)
	
	local collisionNodes = collisionData.nodes
	local collisionMaterials = collisionData.materials
	local collisionRegions = collisionData.regions
	local collisionPathfindingSpheres = collisionData.pathfindingSpheres
	
	local hasSceneNodes = validateSceneNodes collisionNodes
	local fallbackNode = undefined
	
	local t2 = timestamp()

	if not hasSceneNodes then
	(
		fallbackNode = createFallbackFrameRoot()
		if fallbackNode == undefined then
			return undefined
	)
	
	local collisionName = getFilenameFile collisionFileName
	
	local materialSurfaceFlags = #()
	for i = 1 to collisionMaterials.count do
		append materialSurfaceFlags #()
	
	for node in collisionNodes do
	(
		for bsp in node.bsps do
		(
			for surf in bsp.surfaces do
			(
				local matIndex = surf.material + 1

				if matIndex <= 0 or matIndex > materialSurfaceFlags.count then
				continue

				local surfFlags = surf.flags

				-- Convert integer bitfield to flag names
				local flagNames = surfaceFlagsToArray surfFlags
				for flag in flagNames do
				(
					if findItem materialSurfaceFlags[matIndex] flag == 0 then
						append materialSurfaceFlags[matIndex] flag
				)
			)
		)
	)
	local multiMat = createCollisionMultiMaterial collisionMaterials collisionName materialSurfaceFlags
	if multiMat != undefined then
	(
		meditMaterials[1] = multiMat
	)
	-- After the fallback root exists, so spheres can attach to it
	local t1 = timestamp()
	local createdHelpers = createPathfindingSpheres collisionPathfindingSpheres collisionNodes
	logger.info "Pathfinding spheres created: {} in {} ms" args:#(createdHelpers.count, (timestamp() - t1))
	local createdMeshes = #()
	local regionMeshMap = #()
	for node in collisionNodes do
	(
		local nodeBsps = node.bsps
		local nodeRegion = node.region
		local nodeName = node.name
		if nodeBsps.count > 0 then
		(
			local regionName = "__unnamed"
			if nodeRegion >= 0 and nodeRegion < collisionRegions.count then
				regionName = collisionRegions[nodeRegion + 1].name
			for bspIdx = 1 to nodeBsps.count do
			(
				local bsp = nodeBsps[bspIdx]
				local permutationName = undefined
				if nodeRegion >= 0 and nodeRegion < collisionRegions.count then
				(
					local permutationNames = collisionRegions[nodeRegion + 1].permutationNames
					if bspIdx <= permutationNames.count then
						permutationName = permutationNames[bspIdx]
				)
				local meshObj = buildBSPGeometry bsp nodeName regionName permutationName 0 fallbackNode:fallbackNode
				if meshObj != undefined then
				(
					if multiMat != undefined then
						meshObj.material = multiMat
					append createdMeshes meshObj
					local regionEntry = undefined
					for entry in regionMeshMap where entry.regionName == regionName do
						regionEntry = entry
					if regionEntry == undefined then
					(
						regionEntry = regionStruct regionName #()
						append regionMeshMap regionEntry
					)
					append regionEntry.meshes meshObj
				)
			)
		)
	)
	
	logger.info "BSP Geometry built: {} meshes in {} ms" args:#(createdMeshes.count, (timestamp() - t2))
	
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

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)