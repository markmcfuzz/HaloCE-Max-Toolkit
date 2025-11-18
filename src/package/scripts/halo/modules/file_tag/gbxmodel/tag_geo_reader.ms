-- tag_geo_reader.ms
-- Geometry reading functions for gbxmodel tags

-- Read a single part header (132 bytes)
fn readPartHeader =
(
    local fileHandle = getCurrentFileHandle()
    local startPos = ftell fileHandle
    
    local flags = readLongB "#unsigned" -- flags (4 bytes at offset 0)
    local shaderIndex = readShortB "#unsigned" -- shader index (2 bytes at offset 4)
    local prevPartIndex = readByte fileHandle "#signed" -- prev (1 byte at offset 6)
    local nextPartIndex = readByte fileHandle "#signed" -- next (1 byte at offset 7)
    
    skipBytes 2 -- centroid_primary_node (2 bytes at offset 8)
    skipBytes 2 -- centroid_secondary_node (2 bytes at offset 10)
    skipBytes 4 -- centroid_primary_weight (4 bytes at offset 12)
    skipBytes 4 -- centroid_secondary_weight (4 bytes at offset 16)
    skipBytes 12 -- centroid (12 bytes at offset 20)
    
    -- Now at offset 32
    local uncompressedVerticesReflex = readReflexive() -- (12 bytes at offset 32)
    local compressedVerticesReflex = readReflexive() -- (12 bytes at offset 44)
    local trianglesReflex = readReflexive() -- (12 bytes at offset 56)
    
    -- Now at offset 68: Skip model_meta_info struct (36 bytes, often empty/unused)
    skipBytes 36
    
    -- Now at offset 104: Skip rest of part structure (28 bytes: local_node_count + local_nodes + padding)
    skipBytes 28
    
    -- Now at offset 132 (end of part structure)
    
    -- format "[DEBUG] Part at %L: flags=%, shader=%, uncompVerts: count=% ptr=% id=%, compVerts: count=% ptr=% id=%, tris: count=% ptr=% id=%\n" \
    --     startPos flags shaderIndex \
    --     uncompressedVerticesReflex[1] uncompressedVerticesReflex[2] uncompressedVerticesReflex[3] \
    --     compressedVerticesReflex[1] compressedVerticesReflex[2] compressedVerticesReflex[3] \
    --     trianglesReflex[1] trianglesReflex[2] trianglesReflex[3]
    
    -- Return: #(shaderIndex, uncompVertReflex, compVertReflex, trisReflex, flags)
    return #(shaderIndex, uncompressedVerticesReflex, compressedVerticesReflex, trianglesReflex, flags)
)

-- Read uncompressed vertex (68 bytes)
fn readUncompressedVertex =
(
    local position = readPoint3B()
    local normal = readPoint3B()
    local binormal = readPoint3B()
    local tangent = readPoint3B()
    local u = readFloatB()
    local v = readFloatB()
    local node0Index = readShortB "#signed"
    local node1Index = readShortB "#signed"
    local node0Weight = readFloatB()
    local node1Weight = readFloatB()
    
    return #(position, normal, binormal, tangent, u, v, node0Index, node1Index, node0Weight, node1Weight)
)

-- Read compressed vertex (32 bytes)
fn readCompressedVertex =
(
    local position = readPoint3B()
    local normal = readLongB "#unsigned"
    local binormal = readLongB "#unsigned"
    local tangent = readLongB "#unsigned"
    local u = readShortB "#signed"
    local v = readShortB "#signed"
    local node0Index = readByte (getCurrentFileHandle()) "#signed"
    local node1Index = readByte (getCurrentFileHandle()) "#signed"
    local node0Weight = readShortB "#signed"
    
    return #(position, normal, binormal, tangent, u, v, node0Index, node1Index, node0Weight)
)

-- Read triangle (6 bytes)
fn readTriangle =
(
    local v0 = readShortB "#signed"
    local v1 = readShortB "#signed"
    local v2 = readShortB "#signed"
    
    return #(v0, v1, v2)
)

-- Read geometry header (48 bytes) and return parts reflexive
fn readGeometry =
(
    -- Skip flags and unknown data (36 bytes before parts reflexive)
    skipBytes 36
    
    -- Parts reflexive at offset 36
    local partsReflex = readReflexive()
    
    -- format "[DEBUG] readGeometry() raw parts reflexive: count=%, pointer=%, id=%\n" \
    --     partsReflex[1] partsReflex[2] partsReflex[3]
    
    return #(partsReflex)
)

-- Check if data looks like vertex/triangle data instead of a part header
fn isGarbagePartHeader partHeader =
(
    local uncompVerts = partHeader[2][1]
    local compVerts = partHeader[3][1]
    local tris = partHeader[4][1]
    local shaderIdx = partHeader[1]
    
    -- If any of these values are extremely large, we're reading vertex data as a header
    if uncompVerts > 50000 or compVerts > 50000 or tris > 50000 or shaderIdx > 50 then
        return true
    
    return false
)

-- Process all geometries: read parts, skip vertex/triangle data, reach shader block
fn processAllGeometries geometriesArray currentOffset =
(
    -- format "[DEBUG] Processing geometries sequentially (parts → vertex data → next geometry)...\n"
    -- format "[DEBUG] Starting position (after geometry headers): %L\n" currentOffset
    
    local allPartsData = #() -- Store all valid part headers for later use
    local geometryFailed = false
    local needsInitialSeek = true -- Track if we need to seek to initial position
    
    for geomIdx = 1 to geometriesArray.count do
    (
        local partsReflex = geometriesArray[geomIdx][1]
        local partCount = partsReflex[1]
        local partsPointer = partsReflex[2]
        
        -- Check if we need to seek to an absolute position for this geometry's parts
        if partsPointer > 0 then
        (
            -- format "[DEBUG] === Geometry %: parts at absolute position %L ===\n" geomIdx partsPointer
            seekToPosition partsPointer
            needsInitialSeek = false
        )
        else
        (
            -- Parts follow sequentially
            if needsInitialSeek then
            (
                -- format "[DEBUG] === Geometry %: seeking to initial position %L ===\n" geomIdx currentOffset
                seekToPosition currentOffset
                needsInitialSeek = false
            )
            else
            (
                -- format "[DEBUG] === Geometry %: parts follow at current position ===\n" geomIdx
            )
        )
        
        -- SPECIAL CASE: If parts count is 0 but pointer is 0, it means data follows
        -- We need to read at least 1 part and check if more exist
        if partCount == 0 and partsPointer == 0 then
        (
            -- format "[DEBUG] === Geometry % has parts reflexive count=0, will read parts until finding next section ===\n" geomIdx
            partCount = 99999 -- Sentinel value - will read until we detect end
        )
        else if partCount == 0 then
        (
            -- format "[DEBUG] === Geometry % has 0 parts (skipping) ===\n" geomIdx
            continue
        )
        
        -- format "[DEBUG] === Processing Geometry % (reading up to % parts) ===\n" geomIdx partCount
        
        -- Read part headers for THIS geometry
        local geometryParts = #()
        for partIdx = 1 to partCount do
        (
            local fileHandle = getCurrentFileHandle()
            local readPos = ftell fileHandle
            
            -- Read raw bytes to inspect
            -- format "[DEBUG] Reading part at position %L - first 16 bytes as hex: " readPos
            -- local rawBytes = #()
            -- for b = 1 to 16 do
            -- (
            --     append rawBytes (readByte fileHandle #unsigned)
            -- )
            -- for b in rawBytes do
            --     format "%02X " b
            -- format "\n"
            
            -- Rewind to read part header properly
            -- fseek fileHandle readPos #seek_set
            
            local partHeader = readPartHeader()
            
            -- Check if this looks like garbage (vertex data or next section)
            if isGarbagePartHeader partHeader then
            (
                -- format "[DEBUG] Geometry % Part %: Hit non-part data at %L (read % valid parts so far)\n" \
                --     geomIdx partIdx readPos geometryParts.count
                -- Rewind to before this read
                fseek fileHandle readPos #seek_set
                exit
            )
            
            append geometryParts partHeader
            -- format "[DEBUG]   Part %: shader=%, uncompVerts=% (ptr=%),compVerts=% (ptr=%), tris=% (ptr=%)\n" \
            --     partIdx partHeader[1] partHeader[2][1] partHeader[2][2] partHeader[3][1] partHeader[3][2] partHeader[4][1] partHeader[4][2]
        )
        
        if geometryParts.count == 0 then
        (
            format "[WARNING] Geometry %: No valid parts found\n" geomIdx
            
            -- If we hit non-part data and haven't found any parts yet, we've likely reached
            -- the shader block or another section. Stop processing further geometries.
            if geomIdx > 1 then
            (
                format "[WARNING] Reached non-geometry data after geometry %. Stopping geometry processing.\n" (geomIdx - 1)
                geometryFailed = false -- Not a failure, just end of geometry data
                exit
            )
            continue
        )
        
        -- Now track and store file positions for vertex/triangle data
        local fileHandle = getCurrentFileHandle()
        local currentFilePos = ftell fileHandle
        
        -- Store this geometry's parts WITH file positions
        local partsWithPositions = #()
        
        for partIdx = 1 to geometryParts.count do
        (
            local partHeader = geometryParts[partIdx]
            local uncompVertReflex = partHeader[2]
            local compVertReflex = partHeader[3]
            local trisReflex = partHeader[4]
            
            -- Calculate indexCount from triangle count (model_meta_info is often empty/unused)
            -- Original import_gbx.ms uses: triangle_vertices = triangle_blocks * 3
            local indexCount = trisReflex[1] * 3
            
            -- Calculate file positions for this part's data
            local uncompVertPos = currentFilePos
            local compVertPos = uncompVertPos + (uncompVertReflex[1] * 68)
            local trisPos = compVertPos + (compVertReflex[1] * 32)
            
            -- Add positions to part data: #(shaderIndex, uncompReflex, compReflex, trisReflex, flags, uncompVertPos, compVertPos, trisPos, indexCount)
            local partWithPos = #(partHeader[1], partHeader[2], partHeader[3], partHeader[4], partHeader[5], uncompVertPos, compVertPos, trisPos, indexCount)
            append partsWithPositions partWithPos
            
            -- Update current position for next part
            currentFilePos = trisPos + (trisReflex[1] * 6)
        )
        
        -- Store this geometry's parts with positions
        append allPartsData #(geomIdx, partsWithPositions)
        
        -- Now skip vertex/triangle data for THIS geometry's parts
        -- BUT ONLY if the reflexive pointers are 0 (meaning data follows sequentially)
        -- format "[DEBUG] Skipping vertex/triangle data for geometry % (% parts)...\n" geomIdx geometryParts.count
        local totalSkipped = 0
        
        for partIdx = 1 to geometryParts.count do
        (
            local partHeader = geometryParts[partIdx]
            local uncompVertReflex = partHeader[2]  -- #(count, pointer, id)
            local compVertReflex = partHeader[3]
            local trisReflex = partHeader[4]
            
            -- Calculate indexCount from triangle count (model_meta_info is often empty/unused)
            -- Original import_gbx.ms uses: triangle_vertices = triangle_blocks * 3
            local indexCount = trisReflex[1] * 3
            
            local uncompVertCount = uncompVertReflex[1]
            local uncompVertPtr = uncompVertReflex[2]
            local compVertCount = compVertReflex[1]
            local compVertPtr = compVertReflex[2]
            local trisCount = trisReflex[1]
            local trisPtr = trisReflex[2]
            
            -- Only skip if pointer is 0 (data follows sequentially)
            -- If pointer != 0, data is at absolute position and we don't skip
            local needsSkip = false
            local uncompVertSize = 0
            local compVertSize = 0
            local trisSize = 0
            
            if uncompVertPtr == 0 and uncompVertCount > 0 then
            (
                uncompVertSize = uncompVertCount * 68
                needsSkip = true
            )
            
            if compVertPtr == 0 and compVertCount > 0 then
            (
                compVertSize = compVertCount * 32
                needsSkip = true
            )
            
            if trisPtr == 0 and indexCount > 0 then
            (
                trisSize = indexCount * 2  -- Index count * 2 bytes per index (uint16)
                needsSkip = true
            )
            
            if needsSkip then
            (
                local partTotalSkip = uncompVertSize + compVertSize + trisSize
                skipBytes partTotalSkip
                totalSkipped += partTotalSkip
                -- format "[DEBUG]     Part %: skipped % bytes (uc:%+%+%)\n" \
                --     partIdx partTotalSkip uncompVertSize compVertSize trisSize
            )
            else
            (
                -- format "[DEBUG]     Part %: data at absolute positions (ptr: uc=%, c=%, t=%)\n" \
                --     partIdx uncompVertPtr compVertPtr trisPtr
            )
        )
        
        -- format "[DEBUG] Geometry %: skipped % bytes total\n" geomIdx totalSkipped
    )
    
    if geometryFailed then
    (
        format "[ERROR] Failed to process all geometries. Cannot read shaders.\n"
        return #(false, undefined)
    )
    
    -- After processing all geometries, we should be at the shader block
    local fileHandle = getCurrentFileHandle()
    local shadersOffset = ftell fileHandle
    -- format "[DEBUG] All geometries processed successfully. Shader block starts at %L\n" shadersOffset
    
    return #(true, allPartsData)
)

format "Gbxmodel Geometry Tag Reader module loaded.\n"
