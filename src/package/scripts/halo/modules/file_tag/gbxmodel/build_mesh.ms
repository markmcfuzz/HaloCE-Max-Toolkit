-- Halo CE Gbxmodel Geometry Builder (Struct-based)
-- Builds mesh geometry from gbxmodel struct data
-- Uses compressed vertex data with decompression
-- syntax: off

global HALO_SCALE = 100.0  -- Halo units to 3ds Max units conversion

-------------------------------------------------------
-- MESH BUILDING FROM STRUCT DATA
-------------------------------------------------------

-- Build mesh from part struct (uses compressed vertices, reads on-demand)
fn buildPartMesh fileHandle geometryIndex partIndex part materialObj uScale:1.0 vScale:1.0 =
(
    -- Read compressed vertices on-demand from file
    local compVertReflex = part.compressedVerticesReflexive
    local trisReflex = part.trianglesReflexive
    local vertexCount = compVertReflex.count
    local triangleCount = trisReflex.count  -- Number of triangles
    local indexCount = triangleCount * 3     -- File contains triangleCount × 3 indices
    
    if vertexCount == 0 or triangleCount == 0 then
    (
        return undefined
    )
    
    -- Get the data offset for this specific part (calculated during tag reading)
    local partDataStart = part.dataOffset
    
    -- Calculate file positions (uncompressed vertices first, then compressed, then triangles)
    local uncompVertCount = part.uncompressedVerticesReflexive.count
    local uncompVertOffset = if part.uncompressedVerticesReflexive.pointer == 0 then partDataStart else part.uncompressedVerticesReflexive.pointer
    local compVertOffset = if compVertReflex.pointer == 0 then (uncompVertOffset + uncompVertCount * 68) else compVertReflex.pointer
    local trisOffset = if trisReflex.pointer == 0 then (compVertOffset + vertexCount * 32) else trisReflex.pointer
    
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
    
    -- Set global file handle for read struct
    setFileHandle fileHandle
    
    -- Read and process compressed vertices (32 bytes each)
    fseek fileHandle compVertOffset #seek_set
    
    for v = 1 to vertexCount do
    (
        -- Read compressed vertex data (32 bytes)
        -- Position (3 floats = 12 bytes)
        local px = read.floatB()
        local py = read.floatB()
        local pz = read.floatB()
        local position = [px, py, pz]
        
        -- Normal packed (1 uint32 = 4 bytes)
        local normalPacked = read.longB "#unsigned"
        
        -- Binormal packed (1 uint32 = 4 bytes) - skip
        read.longB "#unsigned"
        
        -- Tangent packed (1 uint32 = 4 bytes) - skip
        read.longB "#unsigned"
        
        -- UV (2 signed shorts = 4 bytes)
        local textureCoordU = read.shortB "#signed"
        local textureCoordV = read.shortB "#signed"
        
        -- Node indices (2 signed bytes = 2 bytes)
        local node0Index = readByte fileHandle #signed
        local node1Index = readByte fileHandle #signed
        
        -- Node weight (1 signed short = 2 bytes)
        local node0Weight = read.shortB "#signed"
        
        -- Position (already in world space, just scale)
        vertexPositions[v] = position * HALO_SCALE
        
        -- Decompress normal
        normals[v] = decompressNormal normalPacked
        
        -- Decompress UV coordinates
        uvCoords[v] = decompressUV textureCoordU textureCoordV uScale:uScale vScale:vScale
        
        -- Decompress node indices and weights
        local indices = decompressNodeIndices node0Index node1Index
        nodeIndices[v] = indices
        
        local weight0 = decompressNodeWeight node0Weight
        nodeWeights[v] = #(weight0, 1.0 - weight0)
    )
    
    -- Read triangle strip data (indexCount is triangleCount × 3)
    fseek fileHandle trisOffset #seek_set
    
    local vertexOrder = #()
    for i = 1 to indexCount do
    (
        local idx = read.shortB "#unsigned"  -- Read raw value (0-based)
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
    local triangleIndices = #()
    for w = 1 to (vertexOrder.count - 2) do
    (
        append triangleIndices [vertexOrder[w], vertexOrder[w+1], vertexOrder[w+2]]
    )
    
    -- Fix winding order for triangle strip (reverse odd triangles: 1, 3, 5...)
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
    
    -- Create mesh object
    local meshName = "geo_" + geometryIndex as string + "_part_" + partIndex as string
    local meshObj = mesh vertices:vertexPositions faces:triangleIndices
    meshObj.name = meshName
    meshObj.wirecolor = color 200 200 200
    
    -- Apply UV coordinates
    if uvCoords.count == vertexPositions.count then
    (
        setNumTVerts meshObj uvCoords.count
        buildTVFaces meshObj
        
        for i = 1 to uvCoords.count do
            setTVert meshObj i uvCoords[i]
        
        for i = 1 to triangleIndices.count do
        (
            local face = triangleIndices[i]
            setTVFace meshObj i face
        )
        
        update meshObj
    )
    
    -- Assign material and set material ID
    if materialObj != undefined then
    (
        meshObj.material = materialObj
        local materialID = part.shaderIndex + 1  -- Convert to 1-based
        
        for i = 1 to meshObj.numfaces do
        (
            setFaceMatID meshObj i materialID
        )
    )
    
    -- Return mesh object with weight data
    return #(meshObj, nodeIndices, nodeWeights)
)

-------------------------------------------------------
-- BUILD GEOMETRY BY REGIONS
-------------------------------------------------------

-- Build geometry organized by regions (merges all parts for each region permutation)
fn buildGeometryByRegions modelFilePath tagStruct materialObj createdNodes uScale:1.0 vScale:1.0 =
(
    local regionsArray = tagStruct.regions
    local geometriesArray = tagStruct.geometries
    
    -- Guard: No regions to build
    if regionsArray.count == 0 then
    (
        format "\n[i] No regions to build\n"
        return #()
    )
    
    -- Guard: Cannot open file
    local fileHandle = fopen modelFilePath "rb"
    if fileHandle == undefined then
    (
        format "[ERROR] Could not open file for mesh building\n"
        return #()
    )
    
    local createdMeshes = #()
    local importedGeometryIndices = #()
    
    for r = 1 to regionsArray.count do
    (
        local region = regionsArray[r]
        local regionName = region.name
        local permutations = region.permutations
        
        for p = 1 to permutations.count do
        (
            local perm = permutations[p]
            local permName = perm.name
            
            -- LOD levels to process
            local lodLevels = #(
                #("superhigh", perm.superHighGeometryBlock),
                #("high", perm.highGeometryBlock),
                #("medium", perm.mediumGeometryBlock),
                #("low", perm.lowGeometryBlock),
                #("superlow", perm.superLowGeometryBlock)
            )
            
            for lodEntry in lodLevels do
            (
                local lodName = lodEntry[1]
                local geoIndex = lodEntry[2]
                
                -- Guard: Invalid geometry index
                if geoIndex < 0 then continue
                
                local geometryIndex = geoIndex + 1  -- Convert to 1-based
                
                -- Guard: Already imported
                if findItem importedGeometryIndices geometryIndex > 0 then continue
                
                -- Guard: Out of bounds
                if geometryIndex > geometriesArray.count then continue
                
                local geometry = geometriesArray[geometryIndex]
                local parts = geometry.parts
                
                -- Guard: No parts to build
                if parts.count == 0 then continue
                
                local meshName = regionName + " " + permName + " " + lodName
                
                -- Arrays to accumulate all part data
                local allVertices = #()
                local allUVs = #()
                local allNormals = #()
                local allFaces = #()
                local allMatIDs = #()
                local allNodeIndices = #()
                local allNodeWeights = #()
                local vertexOffset = 0
                
                local tPartsStart = timestamp()
                
                for partIdx = 1 to parts.count do
                (
                    local part = parts[partIdx]
                    local partResult = buildPartMesh fileHandle geometryIndex partIdx part materialObj uScale:uScale vScale:vScale
                    
                    -- Guard: Part build failed
                    if partResult == undefined then continue
                    
                    local tempMesh = partResult[1]
                    local partNodeIndices = partResult[2]
                    local partNodeWeights = partResult[3]
                    
                    local numVerts = tempMesh.numVerts
                    local numFaces = tempMesh.numFaces
                    
                    local tCopyStart = timestamp()
                    
                    -- Copy vertex data
                    for v = 1 to numVerts do
                        append allVertices (getVert tempMesh v)
                    
                    for v = 1 to numVerts do
                        append allNormals (getNormal tempMesh v)
                    
                    for v = 1 to numVerts do
                        append allUVs (getTVert tempMesh v)
                    
                    for v = 1 to numVerts do
                    (
                        append allNodeIndices partNodeIndices[v]
                        append allNodeWeights partNodeWeights[v]
                    )
                    
                    -- Copy face data with offset
                    for f = 1 to numFaces do
                    (
                        local face = getFace tempMesh f
                        append allFaces [face[1] + vertexOffset, face[2] + vertexOffset, face[3] + vertexOffset]
                        append allMatIDs (getFaceMatID tempMesh f)
                    )
                    
                    vertexOffset += numVerts
                                        
                    delete tempMesh
                )
                                
                -- Guard: No faces to build
                if allFaces.count == 0 then continue
                
                local tMeshCreate = timestamp()
                
                local combinedMesh = mesh vertices:allVertices faces:allFaces materialIDs:allMatIDs
                combinedMesh.name = meshName
                combinedMesh.material = materialObj
                
                local tUVStart = timestamp()
                
                -- Apply UV coordinates
                if allUVs.count > 0 then
                (
                    setNumTVerts combinedMesh allUVs.count
                    buildTVFaces combinedMesh
                    
                    for i = 1 to allUVs.count do
                        setTVert combinedMesh i allUVs[i]
                    
                    for f = 1 to allFaces.count do
                        setTVFace combinedMesh f allFaces[f]
                )
                
                update combinedMesh
                
                local tSkinStart = timestamp()
                
                -- Apply skinning
                if allNodeIndices.count > 0 and createdNodes.count > 0 then
                (
                    local skinMod = Skin()
                    addModifier combinedMesh skinMod
                    skinMod.bone_Limit = 2
                    
                    local tBonesStart = timestamp()
                    
                    for n = 1 to createdNodes.count do
                        skinOps.addBone skinMod createdNodes[n] 1
                    
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
                )
                
                append createdMeshes combinedMesh
                append importedGeometryIndices geometryIndex
                
                -- Add to layer
                local geometryLayer = LayerManager.getLayerFromName "Geometry Model"
                if geometryLayer == undefined then
                    geometryLayer = LayerManager.newLayerFromName "Geometry Model"
                geometryLayer.addNode combinedMesh
                
                -- Parent to root node
                if createdNodes.count > 0 and createdNodes[1] != undefined then
                    combinedMesh.parent = createdNodes[1]
            )
        )
    )
    
    -- Close file
    fclose fileHandle
    return createdMeshes
)

logger "Mesh Builder loaded.\n" logType:#success
