-- tag_geo_reader.ms
-- Geometry reading functions for gbxmodel tags

-- Read a single part header (132 bytes)
fn readPartHeader =
(
    local fileHandle = getCurrentFileHandle()
    local startPos = ftell fileHandle
    
    local flags = read.longB "#unsigned" -- flags (4 bytes at offset 0)
    local shaderIndex = read.shortB "#unsigned" -- shader index (2 bytes at offset 4)
    local prevPartIndex = readByte fileHandle "#signed" -- prev (1 byte at offset 6)
    local nextPartIndex = readByte fileHandle "#signed" -- next (1 byte at offset 7)
    
    skipBytes 2 -- centroid_primary_node (2 bytes at offset 8)
    skipBytes 2 -- centroid_secondary_node (2 bytes at offset 10)
    skipBytes 4 -- centroid_primary_weight (4 bytes at offset 12)
    skipBytes 4 -- centroid_secondary_weight (4 bytes at offset 16)
    skipBytes 12 -- centroid (12 bytes at offset 20)
    
    -- Now at offset 32
    local uncompressedVerticesReflex = read.reflexive() -- (12 bytes at offset 32)
    local compressedVerticesReflex = read.reflexive() -- (12 bytes at offset 44)
    local trianglesReflex = read.reflexive() -- (12 bytes at offset 56)
    
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
    local position = math.readPoint3()
    local normal = math.readPoint3()
    local binormal = math.readPoint3()
    local tangent = math.readPoint3()
    local u = read.floatB()
    local v = read.floatB()
    local node0Index = read.shortB "#signed"
    local node1Index = read.shortB "#signed"
    local node0Weight = read.floatB()
    local node1Weight = read.floatB()
    
    return #(position, normal, binormal, tangent, u, v, node0Index, node1Index, node0Weight, node1Weight)
)

-- Read compressed vertex (32 bytes)
fn readCompressedVertex =
(
    local position = math.readPoint3()
    local normal = read.longB "#unsigned"
    local binormal = read.longB "#unsigned"
    local tangent = read.longB "#unsigned"
    local u = read.shortB "#signed"
    local v = read.shortB "#signed"
    local node0Index = readByte (getCurrentFileHandle()) "#signed"
    local node1Index = readByte (getCurrentFileHandle()) "#signed"
    local node0Weight = read.shortB "#signed"
    
    return #(position, normal, binormal, tangent, u, v, node0Index, node1Index, node0Weight)
)

-- Read triangle (6 bytes)
fn readTriangle =
(
    local v0 = read.shortB "#signed"
    local v1 = read.shortB "#signed"
    local v2 = read.shortB "#signed"
    
    return #(v0, v1, v2)
)

-- Read geometry header (48 bytes) and return parts reflexive
fn readGeometry =
(
    -- Skip flags and unknown data (36 bytes before parts reflexive)
    skipBytes 36
    
    -- Parts reflexive at offset 36
    local partsReflex = read.reflexive()
    
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
fn processAllGeometries geometriesArray currentOffset shadersArray =
(
    --format "\n╔════════════════════════════════════════════════════════════════════════════════╗\n"
    --format "║                        PROCESSING ALL GEOMETRIES                               ║\n"
    --format "╚════════════════════════════════════════════════════════════════════════════════╝\n"
    --format "Starting position: %\n" currentOffset
    
    local allPartsData = #() -- Store all valid part headers for later use
    local geometryFailed = false
    local needsInitialSeek = true -- Track if we need to seek to initial position
    
    for geomIdx = 1 to geometriesArray.count do
    (
        local partsReflex = geometriesArray[geomIdx][1]
        local partCount = partsReflex[1]
        local partsPointer = partsReflex[2]
        
        --format "\n\n╔═══════════════════════════════════════╗\n"
        --format "║     GEOMETRY [%]                       ║\n" (geomIdx - 1)
        --format "╚═══════════════════════════════════════╝\n"
        
        -- Check if we need to seek to an absolute position for this geometry's parts
        if partsPointer > 0 then
        (
            --format "Parts at absolute position: %\n" partsPointer
            seekToPosition partsPointer
            needsInitialSeek = false
        )
        else
        (
            -- Parts follow sequentially
            if needsInitialSeek then
            (
                --format "Seeking to initial position: %\n" currentOffset
                seekToPosition currentOffset
                needsInitialSeek = false
            )
            --else
            --(
            --    format "Parts follow at current position\n"
            --)
        )
        
        -- SPECIAL CASE: If parts count is 0 but pointer is 0, it means data follows
        -- We need to read at least 1 part and check if more exist
        if partCount == 0 and partsPointer == 0 then
        (
            --format "Parts reflexive count=0, will read parts until finding next section\n"
            partCount = 99999 -- Sentinel value - will read until we detect end
        )
        else if partCount == 0 then
        (
            --format "Geometry has 0 parts (skipping)\n"
            continue
        )
        
        --format "Reading up to % parts\n" partCount
        
        -- Read part headers for THIS geometry
        local geometryParts = #()
        for partIdx = 1 to partCount do
        (
            local fileHandle = getCurrentFileHandle()
            local readPos = ftell fileHandle
            
            local partHeader = readPartHeader()
            
            -- Check if this looks like garbage (vertex data or next section)
            if isGarbagePartHeader partHeader then
            (
                --format "Hit non-part data at % (read % valid parts so far)\n" readPos geometryParts.count
                -- Rewind to before this read
                fseek fileHandle readPos #seek_set
                exit
            )
            
            append geometryParts partHeader
        )
        
        if geometryParts.count == 0 then
        (
            --format "[WARNING] Geometry %: No valid parts found\n" (geomIdx - 1)
            
            -- If we hit non-part data and haven't found any parts yet, we've likely reached
            -- the shader block or another section. Stop processing further geometries.
            if geomIdx > 1 then
            (
                --format "[WARNING] Reached non-geometry data after geometry %. Stopping geometry processing.\n" (geomIdx - 2)
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
            local shaderIndex = partHeader[1]
            local uncompVertReflex = partHeader[2]
            local compVertReflex = partHeader[3]
            local trisReflex = partHeader[4]
            local flags = partHeader[5]
            
            --format "\n  ┌───────────────────────────────────┐\n"
            --format "  │   PART [%]                         │\n" (partIdx - 1)
            --format "  └───────────────────────────────────┘\n"
            --format "    Flags: %\n" flags
            --format "    Shader Index: %\n" shaderIndex
            
            -- Get shader name if available
            if shadersArray != undefined and shaderIndex >= 0 and shaderIndex < shadersArray.count then
            (
                local shaderName = shadersArray[shaderIndex + 1][1]
                format "    Shader Name: '%'\n" shaderName
            )
            
            -- Calculate indexCount from triangle count (model_meta_info is often empty/unused)
            -- Original import_gbx.ms uses: triangle_vertices = triangle_blocks * 3
            local indexCount = trisReflex[1] * 3
            
            -- Calculate file positions for this part's data
            local uncompVertPos = currentFilePos
            local compVertPos = uncompVertPos + (uncompVertReflex[1] * 68)
            local trisPos = compVertPos + (compVertReflex[1] * 32)
            
            -- Log uncompressed vertices
            --format "\n    ┌─ UNCOMPRESSED VERTICES ─┐\n"
            --format "    │ Count: %\n" uncompVertReflex[1]
            --format "    │ File Position: %\n" uncompVertPos
            
            if uncompVertReflex[1] > 0 and readVertexDataLogger == true and USE_COMPRESSED_ONLY != true then
            (
                -- Read and log uncompressed vertices (skip if using compressed-only mode)
                local savedPos = ftell fileHandle
                fseek fileHandle uncompVertPos #seek_set
                
                for vIdx = 1 to uncompVertReflex[1] do
                (
                    --format "    │   [Vertex %]\n" (vIdx - 1)
                    
                    -- Position (12 bytes)
                    local px = read.floatB()
                    local py = read.floatB()
                    local pz = read.floatB()
                    --format "    │     Position: [%, %, %]\n" px py pz
                    
                    -- Normal (12 bytes)
                    local nx = read.floatB()
                    local ny = read.floatB()
                    local nz = read.floatB()
                    --format "    │     Normal: [%, %, %]\n" nx ny nz
                    
                    -- Binormal (12 bytes)
                    local bnx = read.floatB()
                    local bny = read.floatB()
                    local bnz = read.floatB()
                    --format "    │     Binormal: [%, %, %]\n" bnx bny bnz
                    
                    -- Tangent (12 bytes)
                    local tx = read.floatB()
                    local ty = read.floatB()
                    local tz = read.floatB()
                    --format "    │     Tangent: [%, %, %]\n" tx ty tz
                    
                    -- UV (8 bytes)
                    local u = read.floatB()
                    local v = read.floatB()
                    --format "    │     UV: [%, %]\n" u v
                    
                    -- Node indices and weights (12 bytes)
                    local node0Idx = read.shortB "#signed"
                    local node1Idx = read.shortB "#signed"
                    local node0Weight = read.floatB()
                    local node1Weight = read.floatB()
                    --format "    │     Node0: Index=%, Weight=%\n" node0Idx node0Weight
                    --format "    │     Node1: Index=%, Weight=%\n" node1Idx node1Weight
                    --format "    │\n"
                )
                
                -- Restore file position
                fseek fileHandle savedPos #seek_set
            )
            else if uncompVertReflex[1] > 0 and USE_COMPRESSED_ONLY == true then
            (
                --format "    │ (Skipped - USE_COMPRESSED_ONLY enabled)\n"
            )
            --format "    └─────────────────────────┘\n"
            
            -- Log compressed vertices
            --format "\n    ┌─ COMPRESSED VERTICES ─┐\n"
            --format "    │ Count: %\n" compVertReflex[1]
            --format "    │ File Position: %\n" compVertPos
            
            if compVertReflex[1] > 0 and readVertexDataLogger == true then
            (
                -- Read and log compressed vertices
                local savedPos = ftell fileHandle
                fseek fileHandle compVertPos #seek_set
                
                for vIdx = 1 to compVertReflex[1] do
                (
                    --format "    │   [Vertex %]\n" (vIdx - 1)
                    
                    -- Position (12 bytes)
                    local px = read.floatB()
                    local py = read.floatB()
                    local pz = read.floatB()
                    --format "    │     Position: [%, %, %]\n" px py pz
                    
                    -- Compressed normal (4 bytes)
                    local normal = read.longB "#unsigned"
                    --format "    │     Normal (compressed): %\n" normal
                    
                    -- Compressed binormal (4 bytes)
                    local binormal = read.longB "#unsigned"
                    --format "    │     Binormal (compressed): %\n" binormal
                    
                    -- Compressed tangent (4 bytes)
                    local tangent = read.longB "#unsigned"
                    --format "    │     Tangent (compressed): %\n" tangent
                    
                    -- UV (4 bytes)
                    local u = read.shortB "#signed"
                    local v = read.shortB "#signed"
                    --format "    │     UV (compressed): [%, %]\n" u v
                    
                    -- Node indices (2 bytes)
                    local node0Idx = readByte fileHandle "#signed"
                    local node1Idx = readByte fileHandle "#signed"
                    --format "    │     Node0 Index: %\n" node0Idx
                    --format "    │     Node1 Index: %\n" node1Idx
                    
                    -- Node weight (2 bytes)
                    local node0Weight = read.shortB "#signed"
                    --format "    │     Node0 Weight (compressed): %\n" node0Weight
                    --format "    │\n"
                )
                
                -- Restore file position
                fseek fileHandle savedPos #seek_set
            )
            --format "    └───────────────────────┘\n"
            
            -- Log triangles
            --format "\n    ┌─ TRIANGLES ─┐\n"
            --format "    │ Count: %\n" trisReflex[1]
            --format "    │ Index Count: %\n" indexCount
            --format "    │ File Position: %\n" trisPos
            
            if indexCount > 0 and readTriangleDataLogger == true then
            (
                -- Read and log triangle indices
                local savedPos = ftell fileHandle
                fseek fileHandle trisPos #seek_set
                
                --format "    │ Indices: "
                --for iIdx = 1 to indexCount do
                --(
                --    local idx = read.shortB "#unsigned"
                --    format "% " idx
                --    if (mod iIdx 15) == 0 then
                --        format "\n    │          "
                --)
                --format "\n"
                
                -- Restore file position
                fseek fileHandle savedPos #seek_set
            )
            --format "    └─────────────┘\n"
            
            -- Add positions to part data: #(shaderIndex, uncompReflex, compReflex, trisReflex, flags, uncompVertPos, compVertPos, trisPos, indexCount)
            local partWithPos = #(shaderIndex, uncompVertReflex, compVertReflex, trisReflex, flags, uncompVertPos, compVertPos, trisPos, indexCount)
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
    
    --format "\n╔════════════════════════════════════════════════════════════════════════════════╗\n"
    --format "║                   ALL GEOMETRIES PROCESSED SUCCESSFULLY                        ║\n"
    --format "╚════════════════════════════════════════════════════════════════════════════════╝\n"
    --format "Shader block starts at: %\n" shadersOffset
    --format "Total geometries processed: %\n\n" allPartsData.count
    
    return #(true, allPartsData)
)

format "Gbxmodel Geometry Tag Reader module loaded.\n"
