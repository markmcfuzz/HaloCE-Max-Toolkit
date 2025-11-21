-- Halo CE Model Tag Geometry Builder
-- Builds mesh geometry from .model tag part data
-- NOTE: Adapted from gbxmodel builder for .model-specific structure

global HALO_SCALE = 100.0  -- Halo units to 3ds Max units conversion

-------------------------------------------------------
-- GEOMETRY BUILDING
-------------------------------------------------------

-- Build mesh from geometry part data
-- partData structure: #(shaderIndex, uncompVertReflex, compVertReflex, trisReflex, flags, uncompVertPos, compVertPos, trisPos, indexCount)
-- where each reflex is #(count, pointer, id)
-- Returns created mesh object
fn buildModelGeometryMesh geometryIndex partIndex partData geometriesArray modelFile materialObj uScale:1.0 vScale:1.0 =
(
	-- Extract part data components
	local partShaderIndex = partData[1]  -- Shader index (0-based)
	local uncompVertReflex = partData[2]  -- #(count, pointer, id)
	local compVertReflex = partData[3]    -- #(count, pointer, id)
	local trisReflex = partData[4]        -- #(count, pointer, id)
	local partFlags = partData[5]         -- flags
	local uncompVertFilePos = partData[6] -- file position for uncompressed verts
	local compVertFilePos = partData[7]   -- file position for compressed verts
	local trisFilePos = partData[8]       -- file position for triangles
	local indexCount = partData[9]        -- number of indices in triangle strip
	
	local uncompVertCount = uncompVertReflex[1]
	local compVertCount = compVertReflex[1]
	local triangleCount = trisReflex[1]
	
	-- Determine which vertex format to use - respect USE_COMPRESSED_ONLY flag
	-- Uncompressed has priority if count > 0, unless USE_COMPRESSED_ONLY is enabled
	local useUncompressed = (uncompVertCount > 0 and USE_COMPRESSED_ONLY != true)
	local vertexCount = if useUncompressed then uncompVertCount else compVertCount
	local vertexSize = if useUncompressed then 68 else 32
	
	if vertexCount == 0 or triangleCount == 0 then
	(
		format "  [!] Part %:%: No vertices or triangles (verts=%, tris=%)\n" geometryIndex partIndex vertexCount triangleCount
		return undefined
	)
	
	--format "Building part %:% - shader=%, verts=% (%s), tris=%\n" \
	--	geometryIndex partIndex partShaderIndex vertexCount \
	--	(if useUncompressed then "uncompressed" else "compressed") triangleCount
	
	-- Open file for reading vertex/triangle data
	local fileHandle = fopen modelFile "rb"
	if fileHandle == undefined then
	(
		format "  [!] Failed to open file for reading geometry data\n"
		return undefined
	)
	
	-- Set global file handle for read utilities
	setFileHandle fileHandle
	
	-- Arrays to store mesh data
	local vertexPositions = #()
	local uvCoords = #()
	local normals = #()  -- Array of normal vectors for each vertex
	local nodeIndices = #()  -- Array of #(node0Index, node1Index) for each vertex
	local nodeWeights = #()  -- Array of #(node0Weight, node1Weight) for each vertex
	local triangleIndices = #()
	
	-- Read vertex data
	if useUncompressed then
	(
		-- Read uncompressed vertices (68 bytes each)
		fseek fileHandle uncompVertFilePos #seek_set
		for v = 1 to vertexCount do
		(
			-- Position (12 bytes: 3 floats)
			local px = read.floatB()
			local py = read.floatB()
			local pz = read.floatB()
			local pos = [px, py, pz] * HALO_SCALE
			append vertexPositions pos
			
			-- Normal (12 bytes: 3 floats)
			local nx = read.floatB()
			local ny = read.floatB()
			local nz = read.floatB()
			append normals [nx, ny, nz]
			
			-- Binormal (12 bytes: 3 floats) - skip for now
			local skipB1 = read.floatB()
			local skipB2 = read.floatB()
			local skipB3 = read.floatB()
			
			-- Tangent (12 bytes: 3 floats) - skip for now
			local skipT1 = read.floatB()
			local skipT2 = read.floatB()
			local skipT3 = read.floatB()
			
		-- UV coordinates (8 bytes: 2 floats)
		local uCoord = read.floatB()
		local vCoord = read.floatB()
		-- Apply UV scaling and invert V-coordinate
		uCoord = uCoord * uScale
		vCoord = 1.0 - (vCoord * vScale)
		append uvCoords [uCoord, vCoord, 0]			-- Node indices and weights (12 bytes total)
			local node0Index = read.shortB "#signed"  -- 2 bytes
			local node1Index = read.shortB "#signed"  -- 2 bytes
			local node0Weight = read.floatB()         -- 4 bytes
			local node1Weight = read.floatB()         -- 4 bytes
			
			-- Convert to 1-based indices (add 1)
			append nodeIndices #(node0Index + 1, node1Index + 1)
			append nodeWeights #(node0Weight, node1Weight)
		)
	)
	else
	(
		-- Read compressed vertices (32 bytes each)
		fseek fileHandle compVertFilePos #seek_set
		for v = 1 to vertexCount do
		(
			-- Position (12 bytes: 3 floats)
			local px = read.floatB()
			local py = read.floatB()
			local pz = read.floatB()
			local pos = [px, py, pz] * HALO_SCALE
			append vertexPositions pos
			
			-- Compressed normal (4 bytes: 1 unsigned int32)
			local normalPacked = read.longB "#unsigned"
			-- Decompress normal from packed format (11-11-10 bit)
			local nx = (bit.and (bit.shift normalPacked -21) 0x7FF) / 1023.0 * 2.0 - 1.0
			local ny = (bit.and (bit.shift normalPacked -10) 0x7FF) / 1023.0 * 2.0 - 1.0
			local nz = (bit.and normalPacked 0x3FF) / 511.0 * 2.0 - 1.0
			append normals [nx, ny, nz]
			
			-- Compressed binormal, tangent (8 bytes) - skip for now
			local skipC2 = read.longB "#unsigned"
			local skipC3 = read.longB "#unsigned"
			
			-- UV coordinates (4 bytes: 2 signed shorts)
			local u16 = read.shortB "#signed"
			local v16 = read.shortB "#signed"
			local uCoord = u16 / 32767.0
			local vCoord = v16 / 32767.0
			-- Apply UV scaling and invert V-coordinate
			uCoord = uCoord * uScale
			vCoord = 1.0 - (vCoord * vScale)
			append uvCoords [uCoord, vCoord, 0]
			
		-- Node indices and weight (4 bytes total)
		-- Decompress node indices: compressed format stores them * 3
		-- Must divide by 3 to get actual node index
		local node0IndexRaw = readByte fileHandle "#signed"  -- 1 byte
		local node1IndexRaw = readByte fileHandle "#signed"  -- 1 byte
		local node0WeightRaw = read.shortB "#signed"  -- 2 bytes (signed short)
			-- Decompress weight: signed short to float (0.0 to 1.0)
			local node0Weight = node0WeightRaw / 32767.0
			local node1Weight = 1.0 - node0Weight
			-- Decompress node indices by dividing by 3, then convert to 1-based
			nodeIndices[V] = #((node0IndexRaw / 3) + 1, (node1IndexRaw / 3) + 1)
			nodeWeights[V] = #(node0Weight, node1Weight)
		)
	)
	
	-- Read triangle strip data
	-- indexCount is the total number of indices in the strip
	fseek fileHandle trisFilePos #seek_set
	local vertexOrder = #()
	for i = 1 to indexCount do
	(
		local idx = read.shortB "#unsigned"  -- Read raw value (0-based)
		-- Don't skip 65535 here - it will become a degenerate triangle later
		append vertexOrder (idx + 1)  -- Convert to 1-based immediately
	)
	
	-- Remove trailing zeros in 1-based indices (would have been -1 or 0 in file, padding bytes)
	local vo_count = vertexOrder.count
	if vo_count > 0 and vertexOrder[vo_count] == 0 do
	(
		deleteItem vertexOrder vo_count
	)
	if vo_count > 1 and vertexOrder[vo_count-1] == 0 do
	(
		deleteItem vertexOrder (vo_count-1)
	)
	
	-- Convert triangle strip to individual triangles
	for w = 1 to (vertexOrder.count - 2) do
	(
		append triangleIndices [vertexOrder[w], vertexOrder[w+1], vertexOrder[w+2]]
	)
	
	-- Fix winding order for triangle strip (reverse odd triangles: 1, 3, 5...)
	for r = 1 to triangleIndices.count by 2 do
	(
		-- Reverse the entire triangle array [v0,v1,v2] -> [v2,v1,v0]
		local temp = triangleIndices[r][1]
		triangleIndices[r][1] = triangleIndices[r][3]
		triangleIndices[r][3] = temp
	)
	
	-- Remove degenerate triangles (including those with invalid vertex indices like 65536)
	for i = triangleIndices.count to 1 by -1 do
	(
		local tri = triangleIndices[i]
		-- Check for duplicate vertices OR invalid indices beyond vertex count
		if tri[1] == tri[2] or tri[2] == tri[3] or tri[1] == tri[3] or \
		   tri[1] > vertexPositions.count or tri[2] > vertexPositions.count or tri[3] > vertexPositions.count then
		(
			deleteItem triangleIndices i
		)
	)
	
	fclose fileHandle
	
	-- Create mesh object
	local meshName = "geo_" + geometryIndex as string + "_part_" + partIndex as string
	local meshObj = mesh vertices:vertexPositions faces:triangleIndices
	meshObj.name = meshName
	meshObj.wirecolor = color 200 200 200 --#c8c8c8
	
	-- Apply UV coordinates
	if uvCoords.count == vertexPositions.count then
	(
		setNumTVerts meshObj uvCoords.count
		buildTVFaces meshObj
		for i = 1 to uvCoords.count do
			setTVert meshObj i uvCoords[i]
		
		-- Map TV faces to mesh faces (1:1 mapping)
		for i = 1 to triangleIndices.count do
		(
			local face = triangleIndices[i]
			setTVFace meshObj i face
		)
		
		-- Force update mesh
		update meshObj
	)
	
	-- Assign material and set material ID on all faces
	if materialObj != undefined then
	(
		meshObj.material = materialObj
		local materialID = partShaderIndex + 1  -- Convert to 1-based
		for i = 1 to meshObj.numfaces do
		(
			setFaceMatID meshObj i materialID
		)
	)
	
	--format "Created mesh '%' (% verts, % faces)\n" meshName vertexPositions.count triangleIndices.count
	
	-- Return mesh object along with weight data: #(meshObj, nodeIndices, nodeWeights)
	return #(meshObj, nodeIndices, nodeWeights)
)

-- Build geometry organized by regions (merges all parts for each region permutation)
fn buildModelGeometryByRegions regionsArray geometriesArray modelFile materialObj nodesArray createdNodes uScale:1.0 vScale:1.0 =
(
	if regionsArray.count == 0 then
	(
		format "\n[i] No regions to build\n"
		return #()
	)
	
	--format "\n=== BUILDING GEOMETRY BY REGIONS ===\n"
	local createdMeshes = #()
	
	-- Iterate through regions
	for r = 1 to regionsArray.count do
	(
		local regionData = regionsArray[r]
		local regionInfo = regionData[1]  -- #(regionName, permutationsReflex)
		local regionName = regionInfo[1]
		local permutations = regionData[2]  -- Array of permutations
		
		-- Iterate through permutations in this region
		for p = 1 to permutations.count do
		(
			local permData = permutations[p]
			local permInfo = permData[1]  -- #(name, flags, superlowGeo, lowGeo, mediumGeo, highGeo, superhighGeo, localMarkersReflex)
			local permName = permInfo[1]
			
			-- Import all available LOD levels
			local lodLevels = #(
				#("superlow", permInfo[3]),   -- superlowGeo
				#("low", permInfo[4]),        -- lowGeo
				#("medium", permInfo[5]),     -- mediumGeo
				#("high", permInfo[6]),       -- highGeo
				#("superhigh", permInfo[7])   -- superhighGeo
			)
			
			-- Process each LOD level
			for lodEntry in lodLevels do
			(
				local lodName = lodEntry[1]
				local geoIndex = lodEntry[2]
				
				if geoIndex >= 0 then
				(
					-- Convert to 1-based index
					local geometryIndex = geoIndex + 1
					
					if geometryIndex <= geometriesArray.count then
					(
						local geometryData = geometriesArray[geometryIndex]
						local partsArray = geometryData[1]
						
						-- Check if this geometry actually has part data (not just reflexive count)
						-- Valid part data: partsArray[1] is an array like #(shaderIdx, vertReflex, ...)
						-- Reflexive count: partsArray[1] is just an integer
						local hasValidParts = (partsArray.count > 0 and classOf partsArray[1] == Array)
						
						--if not hasValidParts then
						--(
						--	format "[SKIP] Geometry % has no part data (still contains reflexive count structure)\n" geometryIndex
						--	continue
						--)
						
						-- Build mesh name from region + permutation + LOD
						local meshName = regionName + " " + permName + " " + lodName
						--format "Building '%': region '%', permutation '%', geometry % (% parts)\n" \
						--	meshName regionName permName geometryIndex partsArray.count
						
						-- Collect all vertices, UVs, and faces from all parts
						local allVertices = #()
						local allUVs = #()
						local allNormals = #()  -- Accumulate normals from all parts
						local allFaces = #()
						local allMatIDs = #()
						local allNodeIndices = #()  -- Accumulate node indices for all vertices
						local allNodeWeights = #()  -- Accumulate node weights for all vertices
						local vertexOffset = 0
						
						for partIdx = 1 to partsArray.count do
						(
							local partData = partsArray[partIdx]
							
							-- Build this part's geometry (using model-specific function)
							local partResult = buildModelGeometryMesh geometryIndex partIdx partData geometriesArray modelFile materialObj uScale:uScale vScale:vScale
							
							if partResult != undefined then
							(
								local tempMesh = partResult[1]       -- Mesh object
								local partNodeIndices = partResult[2] -- Node indices array
								local partNodeWeights = partResult[3] -- Node weights array
								
								local numVerts = tempMesh.numVerts
								local numFaces = tempMesh.numFaces
								
								-- Copy vertices
								for v = 1 to numVerts do
									append allVertices (getVert tempMesh v)
								
								-- Copy normals
								for v = 1 to numVerts do
									append allNormals (getNormal tempMesh v)
								
								-- Copy UVs
								for v = 1 to numVerts do
								(
									local extractedUV = getTVert tempMesh v
									append allUVs extractedUV
								)
								
								-- Copy weight data
								for v = 1 to numVerts do
								(
									append allNodeIndices partNodeIndices[v]
									append allNodeWeights partNodeWeights[v]
								)
								
								-- Copy faces with vertex offset
								for f = 1 to numFaces do
								(
									local face = getFace tempMesh f
									append allFaces [face[1] + vertexOffset, face[2] + vertexOffset, face[3] + vertexOffset]
									append allMatIDs (getFaceMatID tempMesh f)
								)
								
								vertexOffset += numVerts
								
								-- Delete temporary mesh
								delete tempMesh
							)
						)
						
						-- Create combined mesh
						if allFaces.count > 0 then
						(
							local combinedMesh = mesh vertices:allVertices faces:allFaces materialIDs:allMatIDs
							combinedMesh.name = meshName
							combinedMesh.material = materialObj
							
							-- Assign to "Geometry Model" layer
							local geometryLayer = LayerManager.getLayerFromName "Geometry Model"
							if geometryLayer == undefined then
								geometryLayer = LayerManager.newLayerFromName "Geometry Model"
							geometryLayer.addNode combinedMesh
							
							-- Link mesh to first node (root bone) if nodes exist
							if createdNodes.count > 0 and createdNodes[1] != undefined then
							(
								combinedMesh.parent = createdNodes[1]
							)
							
							-- Apply UVs
							if allUVs.count > 0 then
							(
								setNumTVerts combinedMesh allUVs.count
								buildTVFaces combinedMesh
								
								-- Set texture vertices
								for i = 1 to allUVs.count do
									setTVert combinedMesh i allUVs[i]
								
								-- Set texture faces (1:1 mapping with geometry faces)
								for f = 1 to allFaces.count do
									setTVFace combinedMesh f allFaces[f]
							)
							
							-- Force mesh update
							update combinedMesh
							
							-- Apply Skin modifier with vertex weights
							if allNodeIndices.count > 0 and createdNodes.count > 0 then
							(
								--format "  Applying Skin modifier...\n"
								local skinMod = Skin()
								addModifier combinedMesh skinMod
								
								-- Set bone affect limit to 2 (Halo CE limitation)
								skinMod.bone_Limit = 2
								
								-- Add all bones to skin modifier
								for n = 1 to createdNodes.count do
								(
									skinOps.addBone skinMod createdNodes[n] 1
								)
								
								-- Apply vertex weights
								for v = 1 to allNodeIndices.count do
								(
									local node0Idx = allNodeIndices[v][1]
									local node1Idx = allNodeIndices[v][2]
									local node0Weight = allNodeWeights[v][1]
									local node1Weight = allNodeWeights[v][2]
									
									-- Handle different weight scenarios
									if node1Idx <= 0 or node1Idx > createdNodes.count then
									(
										-- Only node0 is valid
										if node0Idx > 0 and node0Idx <= createdNodes.count then
											skinOps.ReplaceVertexWeights skinMod v node0Idx 1.0
									)
									else if node0Idx <= 0 or node0Idx > createdNodes.count then
									(
										-- Only node1 is valid
										if node1Idx > 0 and node1Idx <= createdNodes.count then
											skinOps.ReplaceVertexWeights skinMod v node1Idx 1.0
									)
									else if node0Idx == node1Idx then
									(
										-- Both indices same - full weight to one bone
										skinOps.ReplaceVertexWeights skinMod v node0Idx 1.0
									)
									else
									(
										-- Both nodes valid and different - apply both weights
										skinOps.ReplaceVertexWeights skinMod v #(node0Idx, node1Idx) #(node0Weight, node1Weight)
									)
								)
								
								--format "Applied skin weights to % vertices\n" allNodeIndices.count
							)
							
							--format "Created mesh '%' (% verts, % faces)\n" meshName allVertices.count allFaces.count
							append createdMeshes combinedMesh
						)  -- End if allFaces.count > 0
					)  -- End if geometryIndex <= geometriesArray.count
				)  -- End if geoIndex >= 0
			)  -- End LOD loop
		)  -- End permutation loop
	)  -- End region loop
	
	--format "Created % region meshes\n" createdMeshes.count
	return createdMeshes
)

format "Model Geometry Builder loaded successfully.\n"
