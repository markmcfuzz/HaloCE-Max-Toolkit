-- Halo CE Collision Mesh Builder
-- Builds 3D geometry in 3ds Max from collision tag data

-- Global scale factor: Halo world units to 3ds Max units
global HALO_SCALE = 100.0

-------------------------------------------------------
-- MATERIAL CREATION
-------------------------------------------------------

-- Generate a deterministic color from a string using hash
fn stringToColor str =
(
	-- Simple hash function: sum character codes with prime multipliers
	local hash = 0
	for i = 1 to str.count do
	(
		hash += (bit.charasint str[i]) * (i * 31)
	)
	
	-- Generate RGB values from hash (ensure they're in valid range and reasonably bright)
	local r = (mod (hash * 73) 156) + 100  -- Range: 100-255
	local g = (mod (hash * 151) 156) + 100
	local b = (mod (hash * 257) 156) + 100
	
	return (color r g b)
)

-- Create multi-material from collision materials with surface flags
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
		
		-- Set sub-material name to actual material name with flags
		local subMatName = mat.name
		if surfaceFlagsArray != undefined and i <= surfaceFlagsArray.count then
		(
			local flags = surfaceFlagsArray[i]
			if flags != undefined then
			(
				-- two_sided = %, invisible = @, climbable = ^, breakable = -
				if findItem flags "two_sided" > 0 then subMatName += "%"
				if findItem flags "invisible" > 0 then subMatName += "@"
				if findItem flags "climbable" > 0 then subMatName += "^"
				if findItem flags "breakable" > 0 then subMatName += "-"
			)
		)
		subMat.name = subMatName
		
		-- Set material color based on material name for better visual distinction
		-- Each unique material name gets a consistent but different color
		subMat.diffuse = stringToColor mat.name
		
		-- Old material type-based colors (kept for reference):
		-- case mat.material_type of
		-- (
		-- 	0: subMat.diffuse = color 150 150 150  --#969696 dirt (gray)
		-- 	1: subMat.diffuse = color 200 200 200  --#c8c8c8 sand (light gray)
		-- 	2: subMat.diffuse = color 100 100 100  --#646464 stone (dark gray)
		-- 	3: subMat.diffuse = color 139 69 19    --#8b4513 snow (brown)
		-- 	4: subMat.diffuse = color 139 90 43    --#8b5a2b wood (wood brown)
		-- 	5: subMat.diffuse = color 128 128 128  --#808080 metal_hollow (medium gray)
		-- 	6: subMat.diffuse = color 160 160 160  --#a0a0a0 metal_thin (light metal)
		-- 	7: subMat.diffuse = color 140 140 140  --#8c8c8c metal_thick (dark metal)
		-- 	8: subMat.diffuse = color 255 192 203  --#ffc0cb rubber (pink)
		-- 	9: subMat.diffuse = color 200 200 255  --#c8c8ff glass (light blue)
		-- 	10: subMat.diffuse = color 100 149 237 --#6495ed force_field (cornflower blue)
		-- 	11: subMat.diffuse = color 34 139 34   --#228b22 grunt (forest green)
		-- 	12: subMat.diffuse = color 255 140 0   --#ff8c00 hunter_armor (dark orange)
		-- 	13: subMat.diffuse = color 255 0 0     --#ff0000 hunter_skin (red)
		-- 	14: subMat.diffuse = color 138 43 226  --#8a2be2 elite (blue violet)
		-- 	15: subMat.diffuse = color 240 230 140 --#f0e68c jackal (khaki)
		-- 	16: subMat.diffuse = color 220 20 60   --#dc143c jackal_energy_shield (crimson)
		-- 	17: subMat.diffuse = color 255 215 0   --#ffd700 engineer_skin (gold)
		-- 	18: subMat.diffuse = color 218 165 32  --#daa520 engineer_force_field (goldenrod)
		-- 	19: subMat.diffuse = color 0 191 255   --#00bfff flood_combat_form (deep sky blue)
		-- 	20: subMat.diffuse = color 50 205 50   --#32cd32 flood_carrier_form (lime green)
		-- 	21: subMat.diffuse = color 124 252 0   --#7cfc00 cyborg_armor (lawn green)
		-- 	22: subMat.diffuse = color 245 245 220 --#f5f5dc cyborg_energy_shield (beige)
		-- 	23: subMat.diffuse = color 255 105 180 --#ff69b4 human_armor (hot pink)
		-- 	24: subMat.diffuse = color 127 255 212 --#7fffd4 human_skin (aquamarine)
		-- 	25: subMat.diffuse = color 70 130 180  --#4682b4 sentinel (steel blue)
		-- 	26: subMat.diffuse = color 143 188 143 --#8fbc8f monitor (dark sea green)
		-- 	27: subMat.diffuse = color 175 238 238 --#afeeee plastic (pale turquoise)
		-- 	28: subMat.diffuse = color 135 206 250 --#87cefa water (light sky blue)
		-- 	29: subMat.diffuse = color 60 179 113  --#3cb371 leaves (medium sea green)
		-- 	30: subMat.diffuse = color 238 232 170 --#eee8aa elite_energy_shield (pale goldenrod)
		-- 	31: subMat.diffuse = color 189 183 107 --#bdb76b ice (dark khaki)
		-- 	32: subMat.diffuse = color 255 69 0    --#ff4500 hunter_shield (orange red)
		-- 	default: subMat.diffuse = color 128 128 128  -- unknown
		-- )
		
		multiMat[i] = subMat
		
		-- Set the Multi/Sub-Object display name to material type (wood, metal, etc.)
		multiMat.names[i] = materialTypeToString mat.material_type
	)
	
	return multiMat
)

-------------------------------------------------------
-- NODE VALIDATION
-------------------------------------------------------

-- Check if required nodes exist in the scene
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
		-- format "[WARNING] Missing nodes in scene:\n"
		-- for nodeName in missingNodes do
		-- 	format "  - %\n" nodeName
		return false
	)
	
	-- format "All collision nodes exist in scene\n"
	return true
)

-------------------------------------------------------
-- PATHFINDING SPHERES
-------------------------------------------------------

-- Create pathfinding spheres linked to nodes
fn createPathfindingSpheres pathfindingSpheres collisionNodes =
(
	if pathfindingSpheres == undefined or pathfindingSpheres.count == 0 then
	(
		-- format "[INFO] No pathfinding spheres to create\n"
		return #()
	)
	
	local createdSpheres = #()
	
	for i = 1 to pathfindingSpheres.count do
	(
		local pfSphere = pathfindingSpheres[i]
		
		-- Get the node index (0-based in tag, 1-based in MaxScript array)
		local nodeIndex = pfSphere.node + 1
		
		-- Validate node index
		if nodeIndex < 1 or nodeIndex > collisionNodes.count then
		(
			-- format "[ERROR] Invalid node index % for pathfinding sphere %\n" pfSphere.node i
			continue
		)
		
		local nodeName = collisionNodes[nodeIndex].name
		local sceneNode = getNodeByName nodeName
		
		if sceneNode == undefined then
		(
			-- format "[ERROR] Node '%' not found in scene for pathfinding sphere %\n" nodeName i
			continue
		)
		
		-- Convert Halo coordinates to 3ds Max scale (local space)
		local localPos = [pfSphere.center.x, pfSphere.center.y, pfSphere.center.z] * HALO_SCALE
		local sphereRadius = pfSphere.radius * HALO_SCALE
		
		-- Transform from node-local space to world space
		local nodeTransform = sceneNode.transform
		local worldPos = localPos * nodeTransform
		
		-- Create sphere at world position
		local sphereObj = Sphere radius:sphereRadius pos:worldPos name:"#pathfinding" smooth:on
		
		-- Link to parent node (3ds Max will convert to local space automatically)
		sphereObj.parent = sceneNode
		
		-- Set sphere properties for identification
		sphereObj.wirecolor = color 0 200 0  --#00c800 Green
		
		-- Assign to "Pathfinding Spheres" layer
		local pathfindingLayer = LayerManager.getLayerFromName "Pathfinding Spheres"
		if pathfindingLayer == undefined then
			pathfindingLayer = LayerManager.newLayerFromName "Pathfinding Spheres"
		pathfindingLayer.addNode sphereObj
		
		append createdSpheres sphereObj		
		-- format "Created pathfinding sphere % linked to node '%'\n" i nodeName
	)
	
	-- format "Created % pathfinding spheres\n" createdSpheres.count
	return createdSpheres
)

-------------------------------------------------------
-- GEOMETRY UTILITIES
-------------------------------------------------------

-- Transform vertex from plane-local coordinates to world coordinates
-- Plane normal (i,j,k) and distance (d) define the plane position and orientation
fn transformVertexFromPlane vertex planeNormal planeDistance =
(
	-- Create an orthonormal basis for the plane
	-- The plane normal is the Z-axis of the local coordinate system
	local zAxis = normalize planeNormal
	
	-- Find an arbitrary perpendicular vector for X-axis
	-- Choose a vector that's not parallel to the normal
	local xAxis
	if abs(zAxis.x) < 0.9 then
		xAxis = normalize (cross [1,0,0] zAxis)
	else
		xAxis = normalize (cross [0,1,0] zAxis)
	
	-- Y-axis is perpendicular to both
	local yAxis = normalize (cross zAxis xAxis)
	
	-- Find a point on the plane (the origin of the plane's local coordinate system)
	-- Point on plane along normal: P = normal * distance
	local planeOrigin = planeNormal * planeDistance
	
	-- Transform the vertex from plane-local (2D-ish) to world 3D
	-- Vertex in plane coordinates (x,y,z) where z should be ~0 (on the plane)
	local worldPos = planeOrigin + (xAxis * vertex.x) + (yAxis * vertex.y) + (zAxis * vertex.z)
	
	return worldPos
)

-------------------------------------------------------
-- MESH BUILDING
-------------------------------------------------------

-- Build mesh geometry from a single BSP
fn buildBSPGeometry bspData nodeName regionName permutationName materialOffset =
(
	if bspData.vertices.count == 0 then
	(
		-- format "[INFO] No geometry in BSP for node '%'\n" nodeName
		return undefined
	)
	
	-- Create mesh name with @region permutation nodeName format
	local meshName = "@" + regionName + " " + permutationName + " " + nodeName
	
	-- format "[INFO] Building mesh '%' with % vertices, % edges, % surfaces\n" meshName bspData.vertices.count bspData.edges.count bspData.surfaces.count
	
	-- Get the parent node to transform vertices from node-local to world space
	local sceneNode = getNodeByName nodeName
	if sceneNode == undefined then
	(
		-- format "[ERROR] Parent node '%' not found in scene\n" nodeName
		return undefined
	)
	
	-- Get the node's world transform matrix
	local nodeTransform = sceneNode.transform
	
	-- format "[DEBUG] Node '%' transform: pos=[%, %, %]\n" nodeName nodeTransform.position.x nodeTransform.position.y nodeTransform.position.z
	
	-- Convert vertices from node-local space to world space
	local vertArray = #()
	for v in bspData.vertices do
	(
		-- Scale from Halo units to 3ds Max units
		local localPos = [v.point.x, v.point.y, v.point.z] * HALO_SCALE
		
		-- Transform from node-local space to world space
		local worldPos = localPos * nodeTransform
		
		-- format "[DEBUG] Vertex: original=[%, %, %], local=[%, %, %], world=[%, %, %]\n" \
		-- 	v.point.x v.point.y v.point.z \
		-- 	localPos.x localPos.y localPos.z \
		-- 	worldPos.x worldPos.y worldPos.z
		
		append vertArray worldPos
	)
	
	-- Build faces from surfaces and edges
	local faceArray = #()
	local matIDArray = #()
	
	for surfIndex = 1 to bspData.surfaces.count do
	(
		local surf = bspData.surfaces[surfIndex]
		
		-- Get material ID (1-based for Max)
		local matID = surf.material + materialOffset + 1
		
		-- Walk edges to build face
		local faceVerts = #()
		local currentEdgeIndex = surf.first_edge
		local startEdgeIndex = surf.first_edge
		local edgesProcessed = 0
		local maxEdges = bspData.edges.count  -- Safety limit
		
		-- Surface index is 0-based in the tag
		local surfaceIndex0Based = surfIndex - 1
		
		while edgesProcessed < maxEdges do
		(
			if currentEdgeIndex < 0 or currentEdgeIndex >= bspData.edges.count then
			(
				-- format "[ERROR] Invalid edge index % for surface %\n" currentEdgeIndex surfIndex
				exit
			)
			
			local edge = bspData.edges[currentEdgeIndex + 1]  -- 1-based array
			
			-- Determine which side of the edge this surface is on
			local isLeftSurface = (edge.left_surface == surfaceIndex0Based)
			
			-- Add the appropriate vertex and get next edge based on which side we're on
			if isLeftSurface then
			(
				-- We're on the left side, so we go forward
				-- Add the start vertex of this edge
				append faceVerts (edge.start_vertex + 1)
				currentEdgeIndex = edge.forward_edge
			)
			else if edge.right_surface == surfaceIndex0Based then
			(
				-- We're on the right side, so we go in reverse
				-- Add the end vertex of this edge
				append faceVerts (edge.end_vertex + 1)
				currentEdgeIndex = edge.reverse_edge
			)
			else
			(
				-- format "[ERROR] Surface % not found on edge %\n" surfaceIndex0Based currentEdgeIndex
				exit
			)
			
			edgesProcessed += 1
			
			-- If we've looped back to start, we're done
			if currentEdgeIndex == startEdgeIndex then
				exit
		)
		
		-- format "[DEBUG] Surface % has % vertices: %\n" surfIndex faceVerts.count faceVerts
		
		-- Create face(s) from the vertex loop (triangulate if needed)
		if faceVerts.count >= 3 then
		(
			-- Simple fan triangulation from first vertex
			for i = 2 to (faceVerts.count - 1) do
			(
				append faceArray [faceVerts[1], faceVerts[i], faceVerts[i+1]]
				append matIDArray matID
			)
		)
	)
	
	if faceArray.count == 0 then
	(
		-- format "[WARNING] No valid faces generated for '%'\n" meshName
		return undefined
	)
	
	-- Create the mesh
	local newMesh = mesh vertices:vertArray faces:faceArray materialIDs:matIDArray
	newMesh.name = meshName
	
	-- Clear all smoothing groups (collision geometry should be faceted)
	for f = 1 to newMesh.numfaces do
		setFaceSmoothGroup newMesh f 0
	
	-- Parent the mesh to the node so it follows bone transforms
	newMesh.parent = sceneNode
	
	-- Assign to "Collision Model" layer
	local collisionLayer = LayerManager.getLayerFromName "Collision Model"
	if collisionLayer == undefined then
		collisionLayer = LayerManager.newLayerFromName "Collision Model"
	collisionLayer.addNode newMesh
	
	-- format "Created mesh '%' with % faces\n" meshName faceArray.count
	
	return newMesh
)

-- Build collision mesh from BSP geometry data
fn buildCollisionMesh collisionData collisionFileName =
(
	-- format "\n=== BUILDING COLLISION MESH ===\n"
	
	-- Struct to track meshes by region for named selection sets
	struct regionStruct (regionName, meshes)
	
	-- Validate nodes exist in scene
	if not validateSceneNodes collisionData.nodes then
	(
		-- format "[ERROR] Cannot build mesh - missing required nodes\n"
		return undefined
	)
	
	-- Get collision name without extension
	local collisionName = getFilenameFile collisionFileName
	
	-- Collect surface flags for each material
	local materialSurfaceFlags = #()
	for i = 1 to collisionData.materials.count do
		append materialSurfaceFlags #()
	
	-- Scan all BSPs to collect surface flags used by each material
	for node in collisionData.nodes do
	(
		for bsp in node.bsps do
		(
			for surf in bsp.surfaces do
			(
				local matIndex = surf.material + 1  -- 1-based
				if matIndex > 0 and matIndex <= materialSurfaceFlags.count then
				(
					-- Collect flags from this surface
					if surf.flags != undefined then
					(
						-- format "[DEBUG] Surface material:% flags:%\n" matIndex surf.flags
						for flag in surf.flags do
						(
							if findItem materialSurfaceFlags[matIndex] flag == 0 then
								append materialSurfaceFlags[matIndex] flag
						)
					)
				)
			)
		)
	)
	
	-- format "[DEBUG] Collected material flags: %\n" materialSurfaceFlags
	
	-- Create multi-material with surface flags
	local multiMat = createCollisionMultiMaterial collisionData.materials collisionName materialSurfaceFlags
	if multiMat != undefined then
	(
		-- Assign to first available material editor slot
		meditMaterials[1] = multiMat
		-- format "Created multi-material '%' with % sub-materials (assigned to Material Editor slot 1)\n" collisionName collisionData.materials.count
	)
	
	-- Create pathfinding spheres
	local pathfindingSpheres = createPathfindingSpheres collisionData.pathfinding_spheres collisionData.nodes
	
	-- Build geometry from BSP data
	local createdMeshes = #()
	local regionMeshMap = #()  -- Array to track which meshes belong to which region
	
	for node in collisionData.nodes do
	(
		if node.bsps.count > 0 then
		(
			-- Get region name for this node
			local regionName = "__unnamed"
			if node.region >= 0 and node.region < collisionData.regions.count then
				regionName = collisionData.regions[node.region + 1].name
			
			-- Process each BSP (permutation) in this node
			for bspIdx = 1 to node.bsps.count do
			(
				local bsp = node.bsps[bspIdx]
				
				-- Get permutation name if available
				local permutationName = undefined
				if node.region >= 0 and node.region < collisionData.regions.count then
				(
					local region = collisionData.regions[node.region + 1]
					if bspIdx <= region.permutations.count then
						permutationName = region.permutations[bspIdx].name
				)
				
				-- Build the mesh
				local meshObj = buildBSPGeometry bsp node.name regionName permutationName 0
				
				if meshObj != undefined then
				(
					-- Apply multi-material
					if multiMat != undefined then
						meshObj.material = multiMat
					
					append createdMeshes meshObj
					
					-- Track region membership for named selection sets
				local regionEntry = undefined
				for entry in regionMeshMap where entry.regionName == regionName do
					regionEntry = entry
				
				if regionEntry == undefined then
				(
					regionEntry = (regionStruct regionName:regionName meshes:#())
					append regionMeshMap regionEntry
				)
				
				append regionEntry.meshes meshObj
				)
			)
		)
	)
	
	-- Create named selection sets for each region
	for entry in regionMeshMap do
	(
		if entry.meshes.count > 0 then
		(
			selectionSets[entry.regionName] = entry.meshes
			-- format "Created named selection set '%' with % objects\n" entry.regionName entry.meshes.count
		)
	)
	
	-- format "\nMesh building complete - created % mesh objects in % regions\n" createdMeshes.count regionMeshMap.count
	
	return createdMeshes
)

format "Collision Mesh Builder loaded successfully.\n"
