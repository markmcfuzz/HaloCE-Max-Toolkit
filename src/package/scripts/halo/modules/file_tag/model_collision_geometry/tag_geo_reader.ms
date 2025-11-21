/*
Halo CE Collision BSP Geometry Reader
Handles reading of BSP (Binary Space Partition) geometry data from model collision geometry tags
*/

-------------------------------------------------------
-- BSPs Tag Block
-------------------------------------------------------

-- Read BSP geometry data for a single node
-- Each node can have multiple BSP permutations (96 bytes each)
fn readNodeBSPsData nodeIndex nodeName bspsReflexive bspsDataOffset =
(
	local bspsCount = bspsReflexive[1]
	
	if bspsCount == 0 then
		return #()
	
	--format "  Reading % BSPs for node '%'...\n" bspsCount nodeName
	
	-- Seek to this node's BSP data
	--format "  [DEBUG] Seeking to BSP header offset: %\n" bspsDataOffset
	seekToPosition bspsDataOffset
	
	local bsps = #()
	
	for i = 1 to bspsCount do
	(
		local currentPos = getFilePosition()
		--format "  [DEBUG] Reading BSP % at file position %\n" i (if currentPos != undefined then currentPos else "UNKNOWN")
		local bsp = permutationBSP()
		
		-- Read BSP3D nodes reflexive (12 bytes at offset 0)
		bsp.bsp3d_nodes_tag_block = read.reflexive()
		local afterPos = getFilePosition()
		--format "  [DEBUG] After BSP3D reflexive, position=%, reflexive=%\n" (if afterPos != undefined then afterPos else "UNKNOWN") bsp.bsp3d_nodes_tag_block
		
		-- Read planes reflexive (12 bytes at offset 12)
		bsp.planes_tag_block = read.reflexive()
		
		-- Read leaves reflexive (12 bytes at offset 24)
		bsp.leaves_tag_block = read.reflexive()
		
		-- Read BSP2D references reflexive (12 bytes at offset 36)
		bsp.bsp2d_references_tag_block = read.reflexive()
		
		-- Read BSP2D nodes reflexive (12 bytes at offset 48)
		bsp.bsp2d_nodes_tag_block = read.reflexive()
		
		-- Read surfaces reflexive (12 bytes at offset 60)
		bsp.surfaces_tag_block = read.reflexive()
		
		-- Read edges reflexive (12 bytes at offset 72)
		bsp.edges_tag_block = read.reflexive()
		
		-- Read vertices reflexive (12 bytes at offset 84)
		bsp.vertices_tag_block = read.reflexive()
		
		append bsps bsp
		
		-- Display BSP summary
		--format "    BSP [%]: 3DNodes=%, Planes=%, Leaves=%, BSP2DRefs=%, BSP2DNodes=%, Surfaces=%, Edges=%, Vertices=%\n" \
		--	i bsp.bsp3d_nodes_tag_block[1] bsp.planes_tag_block[1] bsp.leaves_tag_block[1] \
		--	bsp.bsp2d_references_tag_block[1] bsp.bsp2d_nodes_tag_block[1] \
		--	bsp.surfaces_tag_block[1] bsp.edges_tag_block[1] bsp.vertices_tag_block[1]
		
		--format "    [DEBUG] BSP [%] at offset %, next offset will be %\n" i bspsDataOffset (bspsDataOffset + 96)
	)
	
	return bsps
)

-------------------------------------------------------
-- BSP3D Nodes Tag Block
-------------------------------------------------------

-- Read BSP3D nodes data
fn readBSP3DNodes bsp3dNodesReflexive dataOffset =
(
	local count = bsp3dNodesReflexive[1]
	if count == 0 then return #()
	
	seekToPosition dataOffset
	local nodes = #()
	
	for i = 1 to count do
	(
		local node = bspsBSP3DNodes()
		node.plane = read.longB "#signed"
		node.back_child = read.longB "#signed"
		node.front_child = read.longB "#signed"
		append nodes node
	)
	
	return nodes
)

-------------------------------------------------------
-- Planes Tag Block
-------------------------------------------------------

-- Read planes data
fn readPlanes planesReflexive dataOffset =
(
	local count = planesReflexive[1]
	if count == 0 then return #()
	
	seekToPosition dataOffset
	local planes = #()
	
	for i = 1 to count do
	(
		local plane = bspsPlanes()
		plane.i = read.floatB()
		plane.j = read.floatB()
		plane.k = read.floatB()
		plane.d = read.floatB()
		append planes plane
	)
	
	return planes
)

-------------------------------------------------------
-- Leaves Tag Block
-------------------------------------------------------

-- Read leaves data
fn readLeaves leavesReflexive dataOffset =
(
	local count = leavesReflexive[1]
	if count == 0 then return #()
	
	seekToPosition dataOffset
	local leaves = #()
	
	for i = 1 to count do
	(
		local leaf = bspsLeaves()
		local flagsValue = read.shortB "#unsigned"
		leaf.flags = if (bit.get flagsValue 1) then #("contains_double_sided_surfaces") else #("none")
		leaf.bsp2d_reference_count = read.shortB "#signed"
		leaf.first_bsp2d_reference = read.longB "#signed"
		append leaves leaf
	)
	
	return leaves
)

-------------------------------------------------------
-- BSP2D References Tag Block
-------------------------------------------------------

-- Read BSP2D references data
fn readBSP2DReferences bsp2dRefsReflexive dataOffset =
(
	local count = bsp2dRefsReflexive[1]
	if count == 0 then return #()
	
	seekToPosition dataOffset
	local refs = #()
	
	for i = 1 to count do
	(
		local ref = bspsBSP2DReference()
		ref.plane = read.longB "#signed"
		ref.bsp2d_node = read.longB "#signed"
		append refs ref
	)
	
	return refs
)

-------------------------------------------------------
-- BSP2D Nodes Tag Block
-------------------------------------------------------

-- Read BSP2D nodes data
fn readBSP2DNodes bsp2dNodesReflexive dataOffset =
(
	local count = bsp2dNodesReflexive[1]
	if count == 0 then return #()
	
	seekToPosition dataOffset
	local nodes = #()
	
	for i = 1 to count do
	(
		local node = bspsBSP2DNode()
		node.plane_i = read.floatB()
		node.plane_j = read.floatB()
		node.plane_d = read.floatB()
		node.left_child = read.longB "#signed"
		node.right_child = read.longB "#signed"
		append nodes node
	)
	
	return nodes
)

-------------------------------------------------------
-- Surfaces Tag Block
-------------------------------------------------------

-- Read surfaces data
fn readSurfaces surfacesReflexive dataOffset =
(
	local count = surfacesReflexive[1]
	if count == 0 then return #()
	
	seekToPosition dataOffset
	local surfaces = #()
	
	for i = 1 to count do
	(
		local surface = bspsSurface()
		surface.plane = read.longB "#signed"
		surface.first_edge = read.longB "#signed"
		
		-- Read flags (1 byte)
		local fileHandle = getCurrentFileHandle()
		local flagsValue = readByte fileHandle #unsigned
		local surfaceFlagNames = #("two_sided", "invisible", "climbable", "breakable")
		surface.flags = decodeFlagBits flagsValue surfaceFlagNames
		
		surface.breakable_surface = readByte fileHandle #signed
		surface.material = read.shortB "#signed"
		
		append surfaces surface
	)
	
	return surfaces
)

-------------------------------------------------------
-- Edges Tag Block
-------------------------------------------------------

-- Read edges data
fn readEdges edgesReflexive dataOffset =
(
	local count = edgesReflexive[1]
	if count == 0 then return #()
	
	seekToPosition dataOffset
	local edges = #()
	
	for i = 1 to count do
	(
		local edge = bspsEdge()
		edge.start_vertex = read.longB "#signed"
		edge.end_vertex = read.longB "#signed"
		edge.forward_edge = read.longB "#signed"
		edge.reverse_edge = read.longB "#signed"
		edge.left_surface = read.longB "#signed"
		edge.right_surface = read.longB "#signed"
		append edges edge
	)
	
	return edges
)

-------------------------------------------------------
-- Vertices Tag Block
-------------------------------------------------------

-- Read vertices data
fn readVertices verticesReflexive dataOffset =
(
	local count = verticesReflexive[1]
	if count == 0 then return #()
	
	seekToPosition dataOffset
	local vertices = #()
	
	for i = 1 to count do
	(
		local vertex = bspsVertices()
		local x = read.floatB()
		local y = read.floatB()
		local z = read.floatB()
		vertex.point = [x, y, z]
		vertex.first_edge = read.longB "#signed"
		append vertices vertex
	)
	
	return vertices
)

-------------------------------------------------------
-- Read All Nodes BSP Geometry
-------------------------------------------------------

fn readAllNodesBSPGeometry nodes nodesDataOffset =
(
	if nodes.count == 0 then
		return nodes
	
	--format "\n=== READING BSP GEOMETRY DATA ===\n"
	
	-- Get file size for validation
	local fileHandle = getCurrentFileHandle()
	local currentPos = ftell fileHandle
	fseek fileHandle 0 #seek_end
	local fileSize = ftell fileHandle
	fseek fileHandle currentPos #seek_set
	--format "[DEBUG] File size: % bytes\n" fileSize
	
	-- Calculate where BSP data starts (after all node headers)
	-- Each node header is 64 bytes
	local bspsDataStartOffset = nodesDataOffset + (nodes.count * 64)
	local currentBSPOffset = bspsDataStartOffset
	
	--format "[DEBUG] Nodes end at: %, BSP headers start at: %\n" (nodesDataOffset + (nodes.count * 64)) bspsDataStartOffset
	
	-- Read BSP permutations for each node (header + geometry interleaved)
	for i = 1 to nodes.count do
	(
		local node = nodes[i]
		local bspsReflexive = node.bsps_tag_block
		
		if bspsReflexive[1] > 0 then
		(
			--format "\n[DEBUG] Node % '%' BSP at offset %\n" (i-1) node.name currentBSPOffset
			
			-- Read BSP header (96 bytes)
			node.bsps = readNodeBSPsData i node.name bspsReflexive currentBSPOffset
			currentBSPOffset += (bspsReflexive[1] * 96)
			
			-- Immediately read geometry data for this node's BSPs (interleaved structure)
			for bspIdx = 1 to node.bsps.count do
			(
				local bsp = node.bsps[bspIdx]
				--format "  BSP [%] geometry at offset %:\n" (bspIdx - 1) currentBSPOffset
				
				-- Read geometry components sequentially
				if bsp.bsp3d_nodes_tag_block[1] > 0 then
				(
					bsp.bsp3d_nodes = readBSP3DNodes bsp.bsp3d_nodes_tag_block currentBSPOffset
					currentBSPOffset += (bsp.bsp3d_nodes_tag_block[1] * 12)
					--format "    - BSP3D Nodes: %\n" bsp.bsp3d_nodes.count
				)
			
				if bsp.planes_tag_block[1] > 0 then
				(
					bsp.planes = readPlanes bsp.planes_tag_block currentBSPOffset
					currentBSPOffset += (bsp.planes_tag_block[1] * 16)
					--format "    - Planes: %\n" bsp.planes.count
				)

				if bsp.leaves_tag_block[1] > 0 then
				(
					bsp.leaves = readLeaves bsp.leaves_tag_block currentBSPOffset
					currentBSPOffset += (bsp.leaves_tag_block[1] * 8)
					--format "    - Leaves: %\n" bsp.leaves.count
				)

				if bsp.bsp2d_references_tag_block[1] > 0 then
				(
					bsp.bsp2d_references = readBSP2DReferences bsp.bsp2d_references_tag_block currentBSPOffset
					currentBSPOffset += (bsp.bsp2d_references_tag_block[1] * 8)
					--format "    - BSP2D References: %\n" bsp.bsp2d_references.count
				)

				if bsp.bsp2d_nodes_tag_block[1] > 0 then
				(
					bsp.bsp2d_nodes = readBSP2DNodes bsp.bsp2d_nodes_tag_block currentBSPOffset
					currentBSPOffset += (bsp.bsp2d_nodes_tag_block[1] * 20)
					--format "    - BSP2D Nodes: %\n" bsp.bsp2d_nodes.count
				)

				if bsp.surfaces_tag_block[1] > 0 then
				(
					bsp.surfaces = readSurfaces bsp.surfaces_tag_block currentBSPOffset
					currentBSPOffset += (bsp.surfaces_tag_block[1] * 12)
					--format "    - Surfaces: %\n" bsp.surfaces.count
				)

				if bsp.edges_tag_block[1] > 0 then
				(
					bsp.edges = readEdges bsp.edges_tag_block currentBSPOffset
					currentBSPOffset += (bsp.edges_tag_block[1] * 24)
					--format "    - Edges: %\n" bsp.edges.count
				)

				if bsp.vertices_tag_block[1] > 0 then
				(
					bsp.vertices = readVertices bsp.vertices_tag_block currentBSPOffset
					currentBSPOffset += (bsp.vertices_tag_block[1] * 16)
					--format "    - Vertices: %\n" bsp.vertices.count
				)
			)
		)
	)
	
	--format "\nBSP Geometry reading complete\n"
	return nodes
)

format "Tag Geometry Reader loaded successfully.\n"
