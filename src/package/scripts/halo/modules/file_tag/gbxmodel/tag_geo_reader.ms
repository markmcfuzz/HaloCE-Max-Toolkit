/**
#name tag_geo_reader_struct.ms
"Geometry reading functions for gbxmodel tags (struct-based)"
*/

-------------------------------------------------------
-- Read Triangles (6 bytes per triangle)
-------------------------------------------------------

fn readTriangles trianglesReflex currentOffset =
(
    local trianglesCount = trianglesReflex.count
    if trianglesCount == 0 then
    (
        local result = trianglesBlockResult()
        result.triangles = #()
        result.endOffset = currentOffset
        return result
    )

    local trianglesDataOffset = if trianglesReflex.pointer == 0 then currentOffset else trianglesReflex.pointer
    seekToPosition trianglesDataOffset

    local triangles = #()
    
    for i = 1 to trianglesCount do
    (
        -- Vertex indices (6 bytes)
        local v0Index = read.shortB "#signed"
        local v1Index = read.shortB "#signed"
        local v2Index = read.shortB "#signed"
        
        -- Create triangle struct
        local triangle = returnTriangles()
        triangle.v0Index = v0Index
        triangle.v1Index = v1Index
        triangle.v2Index = v2Index
        
        append triangles triangle
    )
    
    local trianglesEndOffset = trianglesDataOffset + (trianglesCount * 6)
    
    local result = trianglesBlockResult()
    result.triangles = triangles
    result.endOffset = trianglesEndOffset
    return result
)

-------------------------------------------------------
-- Read Compressed Vertices (32 bytes per vertex)
-------------------------------------------------------

fn readCompressedVertices verticesReflex currentOffset =
(
    local verticesCount = verticesReflex.count
    if verticesCount == 0 then
    (
        local result = compressedVerticesBlockResult()
        result.vertices = #()
        result.endOffset = currentOffset
        return result
    )

    local verticesDataOffset = if verticesReflex.pointer == 0 then currentOffset else verticesReflex.pointer
    seekToPosition verticesDataOffset

    local vertices = #()
    
    for i = 1 to verticesCount do
    (
        -- Position (12 bytes)
        local position = math.readPoint3()
        
        -- Compressed normal (4 bytes)
        local normal = read.longB "#unsigned"
        
        -- Compressed binormal (4 bytes)
        local binormal = read.longB "#unsigned"
        
        -- Compressed tangent (4 bytes)
        local tangent = read.longB "#unsigned"
        
        -- Texture coordinates (4 bytes)
        local textureCoordU = read.shortB "#signed"
        local textureCoordV = read.shortB "#signed"
        
        -- Node indices (2 bytes)
        local fileHandle = getCurrentFileHandle()
        local node0Index = readByte fileHandle #signed
        local node1Index = readByte fileHandle #signed
        
        -- Node weight (2 bytes)
        local node0Weight = read.shortB "#signed"
        
        -- Create vertex struct
        local vertex = returnCompressedVertices()
        vertex.position = position
        vertex.normal = normal
        vertex.binormal = binormal
        vertex.tangent = tangent
        vertex.textureCoordU = textureCoordU
        vertex.textureCoordV = textureCoordV
        vertex.node0Index = node0Index
        vertex.node1Index = node1Index
        vertex.node0Weight = node0Weight
        
        append vertices vertex
    )
    
    local verticesEndOffset = verticesDataOffset + (verticesCount * 32)
    
    local result = compressedVerticesBlockResult()
    result.vertices = vertices
    result.endOffset = verticesEndOffset
    return result
)

-------------------------------------------------------
-- Read Uncompressed Vertices (68 bytes per vertex)
-------------------------------------------------------

fn readUncompressedVertices verticesReflex currentOffset =
(
    local verticesCount = verticesReflex.count
    if verticesCount == 0 then
    (
        local result = uncompressedVerticesBlockResult()
        result.vertices = #()
        result.endOffset = currentOffset
        return result
    )

    local verticesDataOffset = if verticesReflex.pointer == 0 then currentOffset else verticesReflex.pointer
    seekToPosition verticesDataOffset

    local vertices = #()
    
    for i = 1 to verticesCount do
    (
        -- Position (12 bytes)
        local position = math.readPoint3()
        
        -- Normal (12 bytes)
        local normal = math.readPoint3()
        
        -- Binormal (12 bytes)
        local binormal = math.readPoint3()
        
        -- Tangent (12 bytes)
        local tangent = math.readPoint3()
        
        -- Texture coordinates (8 bytes)
        local u = read.floatB()
        local v = read.floatB()
        local textureCoords = #(u, v)
        
        -- Node indices (4 bytes)
        local node0Index = read.shortB "#signed"
        local node1Index = read.shortB "#signed"
        
        -- Node weights (8 bytes)
        local node0Weight = read.floatB()
        local node1Weight = read.floatB()
        
        -- Create vertex struct
        local vertex = returnUncompressedVertices()
        vertex.position = position
        vertex.normal = normal
        vertex.binormal = binormal
        vertex.tangent = tangent
        vertex.textureCoords = textureCoords
        vertex.u = u
        vertex.v = v
        vertex.node0Index = node0Index
        vertex.node1Index = node1Index
        vertex.node0Weight = node0Weight
        vertex.node1Weight = node1Weight
        
        append vertices vertex
    )
    
    local verticesEndOffset = verticesDataOffset + (verticesCount * 68)
    
    local result = uncompressedVerticesBlockResult()
    result.vertices = vertices
    result.endOffset = verticesEndOffset
    return result
)

-------------------------------------------------------
-- Read Parts (132 bytes per part)
-------------------------------------------------------

fn readParts partsReflex currentOffset =
(
    local partsCount = partsReflex.count
    if partsCount == 0 then
    (
        local result = partsBlockResult()
        result.parts = #()
        result.endOffset = currentOffset
        return result
    )

    -- Parts are sequential after previous data (not using pointer)
    local partsDataOffset = currentOffset
        
    -- Get file size for validation
    local fileHandle = getCurrentFileHandle()
    local savedPos = ftell fileHandle
    fseek fileHandle 0 #seek_end
    local fileSize = ftell fileHandle
    fseek fileHandle savedPos #seek_set
    
    -- Validate offset is within file
    if partsDataOffset >= fileSize then
    (
        format "[ERROR] Parts offset % exceeds file size %. Returning empty parts.\\n" partsDataOffset fileSize
        local result = partsBlockResult()
        result.parts = #()
        result.endOffset = currentOffset
        return result
    )
    
    seekToPosition partsDataOffset

    local parts = #()
    
    -- Track end of parts header data (132 bytes per part)
    local partsEndOffset = partsDataOffset + (partsCount * 132)
    
    -- Read each part header (132 bytes)
    for i = 1 to partsCount do
    (
        local fileHandle = getCurrentFileHandle()
        local readPos = ftell fileHandle
        
        -- Flags (4 bytes at offset 0)
        local flags = read.longB "#unsigned"
        
        -- Shader index (2 bytes at offset 4)
        local shaderIndex = read.shortB "#signed"
        
        -- Previous part index (1 byte at offset 6)
        local previousPartIndex = readByte fileHandle #signed
        
        -- Next part index (1 byte at offset 7)
        local nextPartIndex = readByte fileHandle #signed
        
        -- Skip centroid data (2+2+4+4+12 = 24 bytes: offset 8-32)
        skipBytes 24
        
        -- Uncompressed vertices reflexive (12 bytes at offset 32)
        local uncompressedVerticesReflexive = read.reflex()
        
        -- Compressed vertices reflexive (12 bytes at offset 44)
        local compressedVerticesReflexive = read.reflex()
        
        -- Triangles reflexive (12 bytes at offset 56)
        local trianglesReflexive = read.reflex()
        
        -- GARBAGE DETECTION: Check if this looks like vertex data or another section
        -- If vertex counts or shader index are unreasonably large, we've hit non-part data
        if uncompressedVerticesReflexive.count > 50000 or \
            compressedVerticesReflexive.count > 50000 or \
            trianglesReflexive.count > 50000 or \
            shaderIndex > 50 or shaderIndex < -1 then
        (
            -- Rewind to before this read
            fseek fileHandle readPos #seek_set
            exit  -- Stop reading parts for this geometry
        )
        
        -- Skip model_meta_info (36 bytes: offset 68-103)
        skipBytes 36
        
        -- Read local node data (28 bytes: offset 104-131)
        -- Local node count (4 bytes at offset 104)
        local localNodeCount = read.longB "#signed"
        
        -- Read local node indices array (up to 22 bytes, then 2 bytes padding)
        local localNodeIndices = #()
        if localNodeCount > 0 then
        (
            for n = 1 to localNodeCount do
            (
                local globalNodeIndex = readByte fileHandle #signed
                append localNodeIndices globalNodeIndex
            )
            -- Skip remaining bytes in the 22-byte local nodes array + 2 padding bytes
            local bytesToSkip = (22 - localNodeCount) + 2
            skipBytes bytesToSkip
        )
        else
        (
            -- No local nodes, skip all 24 bytes (22 + 2 padding)
            skipBytes 24
        )
        
        -- Create part struct
        local part = returnParts()
        part.flags = flags
        part.shaderIndex = shaderIndex
        part.previousPartIndex = previousPartIndex
        part.nextPartIndex = nextPartIndex
        part.uncompressedVerticesReflexive = uncompressedVerticesReflexive
        part.compressedVerticesReflexive = compressedVerticesReflexive
        part.trianglesReflexive = trianglesReflexive
        part.localNodeIndices = localNodeIndices
        
        append parts part
    )
    
    -- Calculate data offsets for each part (data follows sequentially after all part headers)
    local currentDataOffset = partsDataOffset + (parts.count * 132)
    for i = 1 to parts.count do
    (
        local part = parts[i]
        part.dataOffset = currentDataOffset
        
        -- Calculate this part's data size to get next part's offset
        local uncompSize = part.uncompressedVerticesReflexive.count * 68
        local compSize = part.compressedVerticesReflexive.count * 32
        -- triangleCount × 3 indices × 2 bytes
        local trisSize = part.trianglesReflexive.count * 6 
        
        currentDataOffset += uncompSize + compSize + trisSize
    )
    -- If we stopped early due to garbage detection, we need to handle that
    if parts.count == 0 then
    (
        local result = partsBlockResult()
        result.parts = #()
        result.endOffset = partsDataOffset  -- Return current position
        return result
    )
    -- Calculate end offset for lazy loading
    -- Vertex/triangle data follows sequentially after part headers we ACTUALLY read
    -- Note: We may have read fewer parts than partsCount if we hit garbage
    local dataOffset = partsDataOffset + (parts.count * 132)  -- Start after actual headers read
    
    for i = 1 to parts.count do
    (
        local part = parts[i]
        
        -- Uncompressed vertices (68 bytes per vertex)
        local uncompVertSize = part.uncompressedVerticesReflexive.count * 68
        if uncompVertSize > 0 then
            dataOffset += uncompVertSize
        
        -- Compressed vertices (32 bytes per vertex)
        local compVertSize = part.compressedVerticesReflexive.count * 32
        if compVertSize > 0 then
            dataOffset += compVertSize
        
        -- Triangle indices: reflexive count is TRIANGLE count, but file stores triangleCount × 3 indices
        -- Each index is 2 bytes (uint16), so: triangleCount × 3 × 2 = triangleCount × 6
        local trisSize = part.trianglesReflexive.count * 6
        if trisSize > 0 then
            dataOffset += trisSize
    )
    local result = partsBlockResult()
    result.parts = parts
    result.endOffset = dataOffset
    return result
)

-------------------------------------------------------
-- Read Geometries (48 bytes per geometry)
-------------------------------------------------------

fn readGeometries geometriesReflex regionsEndOffset =
(
    local geometriesCount = geometriesReflex.count
    if geometriesCount == 0 then
    (
        local result = geometriesBlockResult()
        result.geometries = #()
        result.endOffset = regionsEndOffset
        return result
    )

    -- Geometries are sequential after regions (not using pointer)
    local geometriesDataOffset = regionsEndOffset
    seekToPosition geometriesDataOffset

    local geometries = #()
    
    -- STEP 1: Read ALL geometry headers sequentially (5 × 48 = 240 bytes)
    --format "[DEBUG] Reading % geometry headers starting at offset %\n" geometriesCount geometriesDataOffset
    for i = 1 to geometriesCount do
    (
        -- Skip flags (4 bytes at offset 0)
        skipBytes 4
        
        -- Skip unknown data (32 bytes: offset 4-36)
        skipBytes 32
        
        -- Parts reflexive at offset 36 (12 bytes)
        local partsReflexive = read.reflex()
        
        --format "[DEBUG] Geometry % header: partsReflexive count:%, pointer:%\n" i partsReflexive.count partsReflexive.pointer
        
        -- Create geometry struct
        local geometry = returnGeometries()
        geometry.partsReflexive = partsReflexive
        
        append geometries geometry
    )
    
    -- After reading all headers, file position is after last header
    local geometriesEndOffset = geometriesDataOffset + (geometriesCount * 48)
    --format "[DEBUG] All geometry headers read, offset now: %\n" geometriesEndOffset
    
    -- STEP 2: Read parts for each geometry
    for i = 1 to geometries.count do
    (
        local geometry = geometries[i]
        local partsReflexive = geometry.partsReflexive
        
        --format "[DEBUG] Geometry % parts: count:%, geometriesEndOffset:% (before readParts)\n" i partsReflexive.count geometriesEndOffset
        
        -- Parts are sequential after geometry headers (not using pointer)
        -- Data follows sequentially after part headers
        local partsHeadersOffset = geometriesEndOffset
        local partsDataStart = partsHeadersOffset + (partsReflexive.count * 132)
        geometry.partsDataOffset = partsDataStart
        
        -- Read this geometry's parts (reads part headers, calculates vertex data end offset)
        local partsResult = readParts partsReflexive geometriesEndOffset
        geometry.parts = partsResult.parts
        
        -- Update offset to end of this geometry's data
        geometriesEndOffset = partsResult.endOffset
        
        --format "[DEBUG] Geometry % done: geometriesEndOffset:% (after readParts)\n" i geometriesEndOffset
        
        -- IMPORTANT: Seek past the vertex data we didn't read (lazy loading)
        -- This ensures the next geometry's parts are read from the correct position
        seekToPosition geometriesEndOffset
        
        --format "[DEBUG] Geometry % parts read, new offset: %\n" i geometriesEndOffset
    )
    
    -- Verify final file position
    local fileHandle = getCurrentFileHandle()
    local actualFilePos = ftell fileHandle
    --format "[DEBUG] Final geometries offset: % (actual file position: %)\n" geometriesEndOffset actualFilePos
    
    local result = geometriesBlockResult()
    result.geometries = geometries
    result.endOffset = geometriesEndOffset
    return result
)

logger "Geometry tag reader loaded.\n" logType:#success
