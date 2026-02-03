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
		return false
	)
	
	return true
)

fn createFallbackFrameRoot =
(
	local nodeObj = Sphere radius:BONE_SIZE pos:[0,0,0] name:"frame root" smooth:on
	nodeObj.wirecolor = color 255 255 0
	
	logger "Created fallback 'frame root' node (no scene nodes detected)\n" logType:#warning
	

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
		
		local localPos = [pfSphere.center.x, pfSphere.center.y, pfSphere.center.z] * HALO_SCALE
		local sphereRadius = pfSphere.radius * HALO_SCALE
		
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

fn buildBSPGeometry bspData nodeName regionName permutationName materialOffset fallbackNode:undefined =
(
	if bspData.vertices.count == 0 then
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
	for v in bspData.vertices do
	(
		local localPos = [v.point.x, v.point.y, v.point.z] * HALO_SCALE
		local worldPos = localPos * nodeTransform
		append vertArray worldPos
	)
	local faceArray = #()
	local matIDArray = #()
	for surfIndex = 1 to bspData.surfaces.count do
	(
		local surf = bspData.surfaces[surfIndex]
		local matID = surf.material + materialOffset + 1
		local faceVerts = #()
		local currentEdgeIndex = surf.firstEdge
		local startEdgeIndex = surf.firstEdge
		local edgesProcessed = 0
		local maxEdges = bspData.edges.count
		local surfaceIndex0Based = surfIndex - 1
		
		while edgesProcessed < maxEdges do
		(
			if currentEdgeIndex < 0 or currentEdgeIndex >= bspData.edges.count then
			exit
			
			local edge = bspData.edges[currentEdgeIndex + 1]
			
			local isLeftSurface = (edge.leftSurface == surfaceIndex0Based)
			
			if isLeftSurface then
			(
				append faceVerts (edge.startVertex + 1)
				currentEdgeIndex = edge.forwardEdge
			)
			else if edge.rightSurface == surfaceIndex0Based then
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
	
	local collisionLayer = LayerManager.getLayerFromName "Collision Model"
	if collisionLayer == undefined then
		collisionLayer = LayerManager.newLayerFromName "Collision Model"
	collisionLayer.addNode newMesh
	
	return newMesh
)

fn buildCollisionMesh collisionData collisionFileName =
(
	struct regionStruct (regionName, meshes)
	
	local hasSceneNodes = validateSceneNodes collisionData.nodes
	local fallbackNode = undefined
	
	if not hasSceneNodes then
	(
		fallbackNode = createFallbackFrameRoot()
		if fallbackNode == undefined then
			return undefined
	)
	
	local collisionName = getFilenameFile collisionFileName
	
	local materialSurfaceFlags = #()
	for i = 1 to collisionData.materials.count do
		append materialSurfaceFlags #()
	
	for node in collisionData.nodes do
	(
		if node.bsps == undefined then 
		continue
		
		for bsp in node.bsps do
		(
			-- Skip BSPs with empty or invalid surfaces data
			if bsp.surfaces == undefined or classOf bsp.surfaces != Array then
			continue
			
			for surf in bsp.surfaces do
			(
				local matIndex = surf.material + 1
				
				if matIndex <= 0 or matIndex > materialSurfaceFlags.count then 
				continue
				
				if surf.flags == undefined or classOf surf.flags != Array then 
				continue
				
				for flag in surf.flags do
				(
					if findItem materialSurfaceFlags[matIndex] flag == 0 then
						append materialSurfaceFlags[matIndex] flag
				)
			)
		)
	)
	local multiMat = createCollisionMultiMaterial collisionData.materials collisionName materialSurfaceFlags
	if multiMat != undefined then
	(
		meditMaterials[1] = multiMat
	)
	local pathfindingSpheres = createPathfindingSpheres collisionData.pathfindingSpheres collisionData.nodes
	local createdMeshes = #()
	local regionMeshMap = #()
	for node in collisionData.nodes do
	(
		if node.bsps != undefined and node.bsps.count > 0 then
		(
			local regionName = "__unnamed"
			if node.region >= 0 and node.region < collisionData.regions.count then
				regionName = collisionData.regions[node.region + 1].name
			for bspIdx = 1 to node.bsps.count do
			(
				local bsp = node.bsps[bspIdx]
				local permutationName = undefined
				if node.region >= 0 and node.region < collisionData.regions.count then
				(
					local region = collisionData.regions[node.region + 1]
					if bspIdx <= region.permutations.count then
					(
						local perm = region.permutations[bspIdx]
						if perm != undefined then
							permutationName = perm.name
					)
				)
				local meshObj = buildBSPGeometry bsp node.name regionName permutationName 0 fallbackNode:fallbackNode
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

logger "Collision Mesh builder loaded.\n" logType:#success
