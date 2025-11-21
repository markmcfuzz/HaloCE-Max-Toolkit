-- Halo CE Gbxmodel Geometry Builder
-- Builds mesh geometry from gbxmodel part data
-- syntax: off

global HALO_SCALE = 100.0  -- Halo units to 3ds Max units conversion
-------------------------------------------------------
-- GEOMETRY BUILDING
-------------------------------------------------------

-- Read vertex data directly into arrays (optimized - no intermediate mesh)
fn readPartVerticesDirectly partData fileHandle uScale vScale vertexOffset nodeIndicesArray nodeWeightsArray verticesArray uvsArray normalsArray =
(
	local partShaderIndex = partData[1]
	local uncompVertReflex = partData[2]
	local compVertReflex = partData[3]
	local uncompVertFilePos = partData[6]
	local compVertFilePos = partData[7]
	local uncompVertCount = uncompVertReflex[1]
	local compVertCount = compVertReflex[1]
	
	-- Respect USE_COMPRESSED_ONLY flag - skip uncompressed even if available
	local useUncompressed = (uncompVertCount > 0 and USE_COMPRESSED_ONLY != true)
	local vertexCount = if useUncompressed then uncompVertCount else compVertCount
	
	if vertexCount == 0 then return 0
	
	setFileHandle fileHandle
	
	if useUncompressed then
	(
		fseek fileHandle uncompVertFilePos #seek_set
		for v = 1 to vertexCount do
		(
			local idx = vertexOffset + v
			local px = read.floatB()
			local py = read.floatB()
			local pz = read.floatB()
			verticesArray[idx] = [px, py, pz] * HALO_SCALE
			
			local nx = read.floatB()
			local ny = read.floatB()
			local nz = read.floatB()
			normalsArray[idx] = [nx, ny, nz]
			
			-- Skip binormal and tangent (12 bytes each = 24 bytes total)
			fseek fileHandle 24 #seek_cur
			
			local u = read.floatB()
			local v_coord = read.floatB()
			u = u * uScale
			v_coord = 1.0 - (v_coord * vScale)
			uvsArray[idx] = [u, v_coord, 0]
			
			local node0Index = read.shortB "#signed" + 1
			local node1Index = read.shortB "#signed" + 1
			local node0Weight = read.floatB()
			local node1Weight = read.floatB()
			nodeIndicesArray[idx] = #(node0Index, node1Index)
			nodeWeightsArray[idx] = #(node0Weight, node1Weight)
		)
	)
	else
	(
		fseek fileHandle compVertFilePos #seek_set
		for v = 1 to vertexCount do
		(
			local idx = vertexOffset + v
			local px = read.floatB()
			local py = read.floatB()
			local pz = read.floatB()
			verticesArray[idx] = [px, py, pz] * HALO_SCALE
			
			local normalPacked = read.longB "#unsigned"
			-- @vscode-ignore
			local nx = (bit.and (bit.shift normalPacked -21) 0x7FF) / 1023.0 * 2.0 - 1.0
			local ny = (bit.and (bit.shift normalPacked -10) 0x7FF) / 1023.0 * 2.0 - 1.0
			local nz = (bit.and normalPacked 0x3FF) / 511.0 * 2.0 - 1.0
			
			normalsArray[idx] = [nx, ny, nz]
			
			-- Skip compressed binormal and tangent (8 bytes total)
			fseek fileHandle 8 #seek_cur
			
			local u16 = read.shortB "#signed"
			local v16 = read.shortB "#signed"
			local u = (u16 / 32767.0) * uScale
			local v_coord = 1.0 - ((v16 / 32767.0) * vScale)
			uvsArray[idx] = [u, v_coord, 0]
			
			-- Decompress node indices: compressed format stores them * 3
			-- Must divide by 3 to get actual node index
			local node0IndexRaw = readByte fileHandle "#signed"
			local node1IndexRaw = readByte fileHandle "#signed"
			local node0Index = (node0IndexRaw / 3) + 1
			local node1Index = (node1IndexRaw / 3) + 1
			
			-- Decompress weight: compressed weight is stored as signed 16-bit integer
			-- but represents unsigned range 0-32767 mapped to 0.0-1.0
			local node0WeightRaw = read.shortB "#signed"
			local node0Weight = node0WeightRaw / 32767.0
			
			nodeIndicesArray[idx] = #(node0Index, node1Index)
			nodeWeightsArray[idx] = #(node0Weight, 1.0 - node0Weight)
		)
	)
	
	return vertexCount
)

-- Build mesh from geometry part data
-- partData structure: #(shaderIndex, uncompVertReflex, compVertReflex, trisReflex, flags, uncompVertPos, compVertPos, trisPos, indexCount)
-- where each reflex is #(count, pointer, id)
-- Returns created mesh object
fn buildGeometryMesh geometryIndex partIndex partData geometriesArray gbxmodelFile materialObj uScale:1.0 vScale:1.0 =
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
	local useUncompressed = (uncompVertCount > 0 and USE_COMPRESSED_ONLY != true)
	local vertexCount = if useUncompressed then uncompVertCount else compVertCount
	local vertexSize = if useUncompressed then 68 else 32
	if vertexCount == 0 or triangleCount == 0 then
	(
		format "  [!] Part %:%: No vertices or triangles (verts=%, tris=%)\n" geometryIndex partIndex vertexCount triangleCount
		return undefined
	)
	--format "  Building part %:% - shader=%, verts=% (%s), tris=%\n" \
	--	geometryIndex partIndex partShaderIndex vertexCount \
	--	(if useUncompressed then "uncompressed" else "compressed") triangleCount
	-- Open file for reading vertex/triangle data
	local fileHandle = fopen gbxmodelFile "rb"
	if fileHandle == undefined then
	(
		format "  [!] Failed to open file for reading geometry data\n"
		return undefined
	)
	-- Set global file handle for read utilities
	setFileHandle fileHandle
	-- Pre-allocate arrays to avoid costly reallocations (major performance boost)
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
			vertexPositions[v] = [px, py, pz] * HALO_SCALE
			-- Normal (12 bytes: 3 floats)
			local nx = read.floatB()
			local ny = read.floatB()
			local nz = read.floatB()
			normals[v] = [nx, ny, nz]
			-- Binormal (12 bytes: 3 floats) - skip for now
			local skipB1 = read.floatB()
			local skipB2 = read.floatB()
			local skipB3 = read.floatB()
			-- Tangent (12 bytes: 3 floats) - skip for now
			local skipT1 = read.floatB()
			local skipT2 = read.floatB()
			local skipT3 = read.floatB()
            -- UV coordinates (8 bytes: 2 floats)
            local u = read.floatB()
            local v_coord = read.floatB()
            -- Apply UV scaling and invert V-coordinate
            u = u * uScale
            v_coord = 1.0 - (v_coord * vScale)
            uvCoords[v] = [u, v_coord, 0]
			-- Node indices and weights (12 bytes total)
			local node0Index = read.shortB "#signed"  -- 2 bytes
			local node1Index = read.shortB "#signed"  -- 2 bytes
			local node0Weight = read.floatB()         -- 4 bytes
			local node1Weight = read.floatB()         -- 4 bytes
			-- Convert to 1-based indices (add 1)
			nodeIndices[v] = #(node0Index + 1, node1Index + 1)
			nodeWeights[v] = #(node0Weight, node1Weight)
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
			vertexPositions[v] = [px, py, pz] * HALO_SCALE
			-- Compressed normal (4 bytes: 1 unsigned int32)
			local normalPacked = read.longB "#unsigned"
			-- Decompress normal from packed format (11-11-10 bit)
			local nx = (bit.and (bit.shift normalPacked -21) 0x7FF) / 1023.0 * 2.0 - 1.0
			local ny = (bit.and (bit.shift normalPacked -10) 0x7FF) / 1023.0 * 2.0 - 1.0
			local nz = (bit.and normalPacked 0x3FF) / 511.0 * 2.0 - 1.0
			normals[v] = [nx, ny, nz]
			-- Compressed binormal, tangent (8 bytes) - skip for now
			local skipC2 = read.longB "#unsigned"
			local skipC3 = read.longB "#unsigned"
			-- UV coordinates (4 bytes: 2 signed shorts)
			local u16 = read.shortB "#signed"
			local v16 = read.shortB "#signed"
			local u = u16 / 32767.0
			local v_coord = v16 / 32767.0
			-- Apply UV scaling and invert V-coordinate
			u = u * uScale
			v_coord = 1.0 - (v_coord * vScale)
			uvCoords[v] = [u, v_coord, 0]
			-- Node indices and weight (4 bytes total)
			local node0IndexRaw = readByte fileHandle "#signed"  -- 1 byte
			local node1IndexRaw = readByte fileHandle "#signed"  -- 1 byte
			local node0WeightRaw = read.shortB "#signed"  -- 2 bytes (signed short)
			-- Decompress weight: signed short to float (0.0 to 1.0)
			local node0Weight = node0WeightRaw / 32767.0
			local node1Weight = 1.0 - node0Weight
			-- Decompress node indices by dividing by 3, then convert to 1-based
			nodeIndices[v] = #((node0IndexRaw / 3) + 1, (node1IndexRaw / 3) + 1)
			nodeWeights[v] = #(node0Weight, node1Weight)
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
	-- Apply normals - TEMPORARILY DISABLED (causes invisible meshes)
	/*
	if normals.count == vertexPositions.count then
	(
		-- Build normals specification for each face
		meshObj.numFaces = triangleIndices.count
		for f = 1 to triangleIndices.count do
		(
			local face = triangleIndices[f]
			-- Set normals for each vertex of the face
			setNormal meshObj face[1] normals[face[1]]
			setNormal meshObj face[2] normals[face[2]]
			setNormal meshObj face[3] normals[face[3]]
		)
		-- Force mesh update with new normals
		update meshObj
		format "Applied % normals\n" normals.count
	)
	*/
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

-- Build all geometry meshes from geometries array
fn buildAllGeometry geometriesArray gbxmodelFile materialObj =
(
	if geometriesArray.count == 0 then
	(
		--format "\n[i] No geometries to build\n"
		return #()
	)
	--format "\n=== BUILDING GEOMETRY ===\n"
	--format "Total geometries: %\n" geometriesArray.count
	local createdMeshes = #()
	for g = 1 to geometriesArray.count do
	(
		local geometryData = geometriesArray[g]
		local partsArray = geometryData[1]  -- Array of parts for this geometry
		--format "Geometry %: % parts\n" g partsArray.count
		for p = 1 to partsArray.count do
		(
			local partData = partsArray[p]
			local meshObj = buildGeometryMesh g p partData geometriesArray gbxmodelFile materialObj
			if meshObj != undefined then
				append createdMeshes meshObj
		)
	)
	--format "Created % mesh objects\n" createdMeshes.count
	return createdMeshes
)

-- Build geometry organized by regions (merges all parts for each region permutation)
fn buildGeometryByRegions regionsArray geometriesArray gbxmodelFile materialObj nodesArray createdNodes uScale:1.0 vScale:1.0 =
(
    if regionsArray.count == 0 then
    (
        format "\n[i] No regions to build\n"
        return #()
    )
    local createdMeshes = #()
    local importedGeometryIndices = #()
    for r = 1 to regionsArray.count do
    (
        local regionData = regionsArray[r]
        local regionInfo = regionData[1]
        local regionName = regionInfo[1]
        local permutations = regionData[2]
        for p = 1 to permutations.count do
        (
            local permData = permutations[p]
            local permInfo = permData[1]
            local permName = permInfo[1]
            local lodLevels = #(
                #( "superhigh", permInfo[7] ),
                #( "high",      permInfo[6] ),
                #( "medium",    permInfo[5] ),
                #( "low",       permInfo[4] ),
                #( "superlow",  permInfo[3] )
            )
            for lodEntry in lodLevels do
            (
                local lodName = lodEntry[1]
                local geoIndex = lodEntry[2]
                if geoIndex >= 0 then
                (
                    local geometryIndex = geoIndex + 1
                    if findItem importedGeometryIndices geometryIndex > 0 then
                        continue
                    if geometryIndex <= geometriesArray.count then
                    (
                        local geometryData = geometriesArray[geometryIndex]
                        local partsArray = geometryData[1]
                        local hasValidParts = (partsArray.count > 0 and classOf partsArray[1] == Array)
                        if not hasValidParts then continue
                        local meshName = regionName + " " + permName + " " + lodName
                        local allVertices = #()
                        local allUVs = #()
                        local allNormals = #()
                        local allFaces = #()
                        local allMatIDs = #()
                        local allNodeIndices = #()
                        local allNodeWeights = #()
                        local vertexOffset = 0

                        local tPartsStart = timestamp()
                        for partIdx = 1 to partsArray.count do
                        (
                            local partData = partsArray[partIdx]
                            local partResult = buildGeometryMesh geometryIndex partIdx partData geometriesArray gbxmodelFile materialObj uScale:uScale vScale:vScale
                            if partResult != undefined then
                            (
                                local tempMesh = partResult[1]
                                local partNodeIndices = partResult[2]
                                local partNodeWeights = partResult[3]
                                local numVerts = tempMesh.numVerts
                                local numFaces = tempMesh.numFaces
                                local tCopyStart = timestamp()
                                for v = 1 to numVerts do append allVertices (getVert tempMesh v)
                                for v = 1 to numVerts do append allNormals (getNormal tempMesh v)
                                for v = 1 to numVerts do
                                (
                                    local extractedUV = getTVert tempMesh v
                                    append allUVs extractedUV
                                )
                                for v = 1 to numVerts do
                                (
                                    append allNodeIndices partNodeIndices[v]
                                    append allNodeWeights partNodeWeights[v]
                                )
                                for f = 1 to numFaces do
                                (
                                    local face = getFace tempMesh f
                                    append allFaces [face[1] + vertexOffset, face[2] + vertexOffset, face[3] + vertexOffset]
                                    append allMatIDs (getFaceMatID tempMesh f)
                                )
                                vertexOffset += numVerts
								if timeStampLogger then
									logger "  [Part %] Data copy: % ms\n" params:#(partIdx, (timestamp() - tCopyStart)) logType:#timestamp
                                delete tempMesh
                            )
                        )
						if timeStampLogger then
							logger "  [Total] Parts processing: % ms\n" params:#((timestamp() - tPartsStart)) logType:#timestamp
                        local tMeshCreate = timestamp()
                        if allFaces.count > 0 then
                        (
                            local combinedMesh = mesh vertices:allVertices faces:allFaces materialIDs:allMatIDs
                            combinedMesh.name = meshName
                            combinedMesh.material = materialObj
							
							if timeStampLogger then (
								logger "  [Mesh] Creation: % ms\n" params:#((timestamp() - tMeshCreate)) logType:#timestamp
							)
                            local tUVStart = timestamp()
                            if allUVs.count > 0 then
                            (
                                setNumTVerts combinedMesh allUVs.count
                                buildTVFaces combinedMesh
                                for i = 1 to allUVs.count do setTVert combinedMesh i allUVs[i]
                                for f = 1 to allFaces.count do setTVFace combinedMesh f allFaces[f]
                            )
							if timeStampLogger then (
								logger "  [UV] Application: % ms\n" params:#((timestamp() - tUVStart)) logType:#timestamp
							)
                            update combinedMesh
                            local tSkinStart = timestamp()
                            if allNodeIndices.count > 0 and createdNodes.count > 0 then
                            (
                                local skinMod = Skin()
                                addModifier combinedMesh skinMod
                                skinMod.bone_Limit = 2
                                
                                local tBonesStart = timestamp()
                                for n = 1 to createdNodes.count do
                                    skinOps.addBone skinMod createdNodes[n] 1
                                
                                if timeStampLogger then
                                    logger "  [Skin] Add bones: % ms\n" params:#((timestamp() - tBonesStart)) logType:#timestamp
                                
                                local tWeightsStart = timestamp()
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
                                
                                if timeStampLogger then
                                    logger "  [Skin] Apply weights: % ms\n" params:#((timestamp() - tWeightsStart)) logType:#timestamp
                            )
                            
                            if timeStampLogger then
                                logger "  [Skin] Total: % ms\n" params:#((timestamp() - tSkinStart)) logType:#timestamp
                            
                            append createdMeshes combinedMesh
                            append importedGeometryIndices geometryIndex
                            local geometryLayer = LayerManager.getLayerFromName "Geometry Model"
                            if geometryLayer == undefined then
                                geometryLayer = LayerManager.newLayerFromName "Geometry Model"
                            geometryLayer.addNode combinedMesh
                            if createdNodes.count > 0 and createdNodes[1] != undefined then
                                combinedMesh.parent = createdNodes[1]
                        )
                    )
                )
            )
        )
    )
	return createdMeshes
)
format "Gbxmodel Mesh Builder loaded successfully.\n"
