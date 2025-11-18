-------------------------------------------------------
-- MODEL TAG GEOMETRY READER
-- Reads geometry and part data for .model tags
-- NOTE: .model parts are 104 bytes (no local_nodes)
-- vs gbxmodel parts which are 132 bytes
-------------------------------------------------------

-- Read a single part header (104 bytes for .model)
fn readModelPartHeader =
(
    local fileHandle = getCurrentFileHandle()
    local partFlags = readLongB "#unsigned"
    local shaderIndex = readShortB "#unsigned"
    local prevPartIndex = readByte fileHandle #signed
    local nextPartIndex = readByte fileHandle #signed
    
    -- format "[DEBUG] After reading shader+prev+next, position: %L (should be 6184 for first part)\n" (ftell fileHandle)
    
    -- Centroid data (16 bytes)
    local centroidPrimaryNode = readShortB "#signed"
    local centroidSecondaryNode = readShortB "#signed"
    local centroidPrimaryWeight = readFloatB()
    local centroidSecondaryWeight = readFloatB()
    
    -- Centroid translation (12 bytes)
    local centroidTranslation = readPoint3B()
    
    -- Uncompressed vertices reflexive (12 bytes at offset 32)
    -- format "[DEBUG] About to read uncompVerts reflexive at position %L\n" (ftell (getCurrentFileHandle()))
    local uncompVertReflex = readReflexive()
    -- format "[DEBUG] Read uncompVerts: count=%, ptr=%, id=%\n" uncompVertReflex[1] uncompVertReflex[2] uncompVertReflex[3]
    
    -- Compressed vertices reflexive (12 bytes at offset 44)
    local compVertReflex = readReflexive()
    -- format "[DEBUG] Read compVerts: count=%, ptr=%, id=%\n" compVertReflex[1] compVertReflex[2] compVertReflex[3]
    
    -- Triangles reflexive (12 bytes at offset 56)
    local trisReflex = readReflexive()
    -- format "[DEBUG] Read tris: count=%, ptr=%, id=%\n" trisReflex[1] trisReflex[2] trisReflex[3]
    
    -- model_meta_info (36 bytes at offset 68)
    -- Offsets below are RELATIVE to model_meta_info start (offset 68 in part)
    local indexType = readShortB "#unsigned"        -- offset 0 (absolute 68)
    skipBytes 2                                     -- padding
    local indexCount = readLongB "#unsigned"        -- offset 4 (absolute 72)
    local indicesOffset = readLongB "#unsigned"     -- offset 8 (absolute 76)
    local indicesReflexiveOffset = readLongB "#unsigned" -- offset 12 (absolute 80)
    local vertexType = readShortB "#unsigned"       -- offset 16 (absolute 84)
    skipBytes 2                                     -- padding
    local vertexCount = readLongB "#unsigned"       -- offset 20 (absolute 88)
    skipBytes 4                                     -- offset 24 (unused field)
    local verticesOffset = readLongB "#unsigned"    -- offset 28 (absolute 96)
    local verticesReflexiveOffset = readLongB "#unsigned" -- offset 32 (absolute 100)
    
    --format "[DEBUG readModelPartHeader] model_meta_info: indexType=%, indexCount=%, indicesOffset=%L, verticesOffset=%L\n" \
    --    indexType indexCount indicesOffset verticesOffset
    
    -- NOTE: .model parts END here at 104 bytes total
    -- (gbxmodel continues with local_node_count + local_nodes array = +28 bytes to 132)
    
    -- Return: #(shaderIdx, uncompVertReflex, compVertReflex, trisReflex, partFlags, verticesOffset, indicesOffset)
    return #(shaderIndex, uncompVertReflex, compVertReflex, trisReflex, partFlags, verticesOffset, indicesOffset)
)

fn readModelGeometry =
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
fn processAllModelGeometries geometriesArray currentOffset =
(
    -- format "[DEBUG] Processing geometries sequentially (parts → vertex data → next geometry)...\n"
    -- format "[DEBUG] Starting position (after geometry headers): %L\n" currentOffset
    
    local allPartsData = #() -- Store all valid part headers for later use
    local geometryFailed = false
    local needsInitialSeek = true -- Track if we need to seek to initial position
    local readPartHeader = readModelPartHeader -- Alias for the function
    
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
        else if needsInitialSeek then
        (
            -- format "[DEBUG] === Geometry %: seeking to initial position %L ===\n" geomIdx currentOffset
            seekToPosition currentOffset
            needsInitialSeek = false
        )
        --else
        --(
        --    format "[DEBUG] === Geometry %: parts follow at current position ===\n" geomIdx
        --)
        
        -- Read all parts for this geometry
        --format "[DEBUG] === Processing Geometry % (reading up to % parts) ===\n" geomIdx partCount
        local geometryParts = #()
        
        for partIdx = 1 to partCount do
        (
            local fileHandle = getCurrentFileHandle()
            local readPos = ftell fileHandle
            
            -- Debug: read first 16 bytes as raw hex to see what we're getting
            /*
            local debugBytes = #()
            for b = 1 to 16 do
                append debugBytes (ReadByte fileHandle #unsigned)
            fseek fileHandle readPos #seek_set -- rewind
            
            format "[DEBUG] Reading part at position %LL - first 16 bytes as hex: " readPos
            for b in debugBytes do format "%02X " b
            format "\n"
            */
            
            local partHeader = readPartHeader()
            
            --format "[DEBUG] Part at %LL: flags=%, shader=%, uncompVerts: count=% ptr=% id=%, compVerts: count=% ptr=% id=%, tris: count=% ptr=% id=%\n" \
            --    readPos partHeader[5] partHeader[1] \
            --    partHeader[2][1] partHeader[2][2] partHeader[2][3] \
            --    partHeader[3][1] partHeader[3][2] partHeader[3][3] \
            --    partHeader[4][1] partHeader[4][2] partHeader[4][3]
            
            -- Check if this looks like valid part data or garbage
            if isGarbagePartHeader partHeader then
            (
                --format "[DEBUG] Geometry % Part %: Hit non-part data at %L (read % valid parts so far)\n" \
                --    geomIdx partIdx readPos geometryParts.count
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
            --format "[WARNING] Geometry %: No valid parts found\n" geomIdx
            
            -- If we hit non-part data and haven't found any parts yet, we've likely reached
            -- the shader block or another section. Stop processing further geometries.
            if geomIdx > 1 then
            (
                --format "[WARNING] Reached non-geometry data after geometry %. Stopping geometry processing.\n" (geomIdx - 1)
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
            local verticesOffset = partHeader[6] -- from model_meta_info
            local indicesOffset = partHeader[7] -- from model_meta_info
            
            -- Calculate indexCount from triangle count (model_meta_info is often empty/unused)
            -- Original import_gbx.ms uses: triangle_vertices = triangle_blocks * 3
            local indexCount = trisReflex[1] * 3
            
            -- Use explicit offsets if provided (non-zero), otherwise calculate sequentially
            local uncompVertPos = if verticesOffset > 0 then verticesOffset else currentFilePos
            local compVertPos = uncompVertPos + (uncompVertReflex[1] * 68)
            local trisPos = if indicesOffset > 0 then indicesOffset else (compVertPos + (compVertReflex[1] * 32))
            
            --format "[DEBUG]   Part % positions: verticesOffset=%, indicesOffset=%, calculated uncompVertPos=%L, trisPos=%L\n" \
            --    partIdx verticesOffset indicesOffset uncompVertPos trisPos
            
            -- Store: #(shaderIdx, uncompVertReflex, compVertReflex, trisReflex, flags, uncompPos, compPos, trisPos, indexCount)
            local partWithPos = #(partHeader[1], uncompVertReflex, compVertReflex, trisReflex, 
                                  partHeader[5], uncompVertPos, compVertPos, trisPos, indexCount)
            append partsWithPositions partWithPos
            
            -- Move file pointer past this part's data (for sequential parts)
            if verticesOffset == 0 then
                currentFilePos = trisPos + (indexCount * 2) -- triangles are UInt16 indices
        )
        
        -- Calculate total bytes to skip for this geometry
        local bytesToSkip = currentFilePos - (ftell fileHandle)
        --format "[DEBUG] Skipping vertex/triangle data for geometry % (% parts)...\n" geomIdx geometryParts.count
        
        for partIdx = 1 to partsWithPositions.count do
        (
            local part = partsWithPositions[partIdx]
            local uncompVertCount = part[2][1]
            local compVertCount = part[3][1]
            local triIndexCount = part[9]
            
            if part[2][2] == 0 and part[3][2] == 0 and part[4][2] == 0 then
            (
                --format "[DEBUG]     Part %: skipped % bytes (uc:%+%+%)\n" \
                --    partIdx (uncompVertCount * 68 + compVertCount * 32 + triIndexCount * 2) \
                --    (uncompVertCount * 68) (compVertCount * 32) (triIndexCount * 2)
            )
            else
            (
                --format "[DEBUG]     Part %: data at absolute positions (ptr: uc=%, c=%, t=%)\n" \
                    partIdx part[2][2] part[3][2] part[4][2]
            )
        )
        
        if bytesToSkip > 0 then
        (
            skipBytes bytesToSkip
            --format "[DEBUG] Geometry %: skipped % bytes total\n" geomIdx bytesToSkip
        )
        
        -- Replace the original reflexive structure with the full part data
        geometriesArray[geomIdx] = #(partsWithPositions)
    )
    
    local fileHandle = getCurrentFileHandle()
    local finalPos = ftell fileHandle
    --format "[DEBUG] All geometries processed successfully. Shader block starts at %LL\n" finalPos
    
    return #(true, geometriesArray, finalPos)
)

format "Model Geometry Reader loaded successfully.\n"
