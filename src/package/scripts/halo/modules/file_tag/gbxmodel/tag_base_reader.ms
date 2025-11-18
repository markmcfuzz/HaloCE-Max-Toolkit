-- Halo CE Gbxmodel Tag Base Reader
-- Reads main tag structure (header and tagdata)
-- Reflexive data reading is in tag_data_reader.ms

-------------------------------------------------------
-- Tag Header (64 bytes)
-------------------------------------------------------

fn readTagHeader =
(
    --format "=== READING TAG HEADER ===\n"
    
    -- Seek to tag class (offset 36 in header)
    seekToPosition 36
    local tagClass = readLongB "#unsigned"
    
    -- Seek to checksum (offset 40)
    local checksum = readLongB "#unsigned"
    
    -- Header size (offset 44)
    local headerSize = readLongB "#unsigned"
    
    -- Seek to version (offset 56 in header)  
    seekToPosition 56
    local version = readShortB "#unsigned"
    
    -- Validate tag class
    local expectedGbxFourcc = getFourccByTagName "mod2"
    if tagClass != expectedGbxFourcc then
    (
        format "[ERROR] Invalid tag class. Expected: %, Found: %\n" expectedGbxFourcc tagClass
        return undefined
    )
    
    --format "Valid gbxmodel tag: version %\n" version
    return #(tagClass, version, checksum, headerSize)
)

-------------------------------------------------------
-- Main Tagdata (232 bytes starting at offset 64)
-------------------------------------------------------

fn readMainTagdata =
(
    --format "\n=== READING MAIN TAGDATA ===\n"
    
    -- Seek to start of tagdata (after 64-byte header)
    seekToPosition 64
    
    -- Flags (offset 0 in tagdata, offset 64 in file)
    local flags = readLongB "#unsigned"
    
    -- Node list checksum (offset 4)
    local nodeListChecksum = readLongB "#signed"
    
    -- LOD cutoffs (offsets 8-24)
    local superhighLodCutoff = readFloatB()
    local highLodCutoff = readFloatB()
    local mediumLodCutoff = readFloatB()
    local lowLodCutoff = readFloatB()
    local superlowLodCutoff = readFloatB()
    
    -- LOD node counts (offsets 28-36)
    local superhighLodNodes = readShortB "#signed"
    local highLodNodes = readShortB "#signed"
    local mediumLodNodes = readShortB "#signed"
    local lowLodNodes = readShortB "#signed"
    local superlowLodNodes = readShortB "#signed"
    
    -- Skip padding (offsets 38-47 = 10 bytes)
    skipBytes 10
    
    -- Base map scales (offsets 48-55)
    local baseMapUScale = readFloatB()
    local baseMapVScale = readFloatB()
    
    -- Skip padding (offsets 56-171 = 116 bytes)
    skipBytes 116
    
    -- Reflexive blocks start at offset 172 (file offset 236)
    
    -- Markers reflexive (offset 172)
    local markersReflex = readReflexive()
    --format "Markers: count=%, pointer=%\n" markersReflex[1] markersReflex[2]
    
    -- Nodes reflexive (offset 184)
    local nodesReflex = readReflexive()
    --format "Nodes: count=%, pointer=%\n" nodesReflex[1] nodesReflex[2]
    
    -- Regions reflexive (offset 196)
    local regionsReflex = readReflexive()
    --format "Regions: count=%, pointer=%\n" regionsReflex[1] regionsReflex[2]
    
    -- Geometries reflexive (offset 208)
    local geometriesReflex = readReflexive()
    --format "Geometries: count=%, pointer=%\n" geometriesReflex[1] geometriesReflex[2]
    
    -- Shaders reflexive (offset 220)
    local shadersReflex = readReflexive()
    --format "Shaders: count=%, pointer=%\n" shadersReflex[1] shadersReflex[2]
    
    return #(flags, nodeListChecksum, 
             superhighLodCutoff, highLodCutoff, mediumLodCutoff, lowLodCutoff, superlowLodCutoff,
             superhighLodNodes, highLodNodes, mediumLodNodes, lowLodNodes, superlowLodNodes,
             baseMapUScale, baseMapVScale,
             markersReflex, nodesReflex, regionsReflex, geometriesReflex, shadersReflex)
)

-------------------------------------------------------
-- Main Tag Reader Function
-------------------------------------------------------

fn readGbxmodelTag gbxmodelFilePath =
(
    --format "\n========================================\n"
    --format "GBXMODEL TAG READER\n"
    --format "========================================\n"
    --format "File: %\n" (filenameFromPath gbxmodelFilePath)
    
    -- Open file
    global halo_file_handle = fopen gbxmodelFilePath "rb"
    
    if halo_file_handle == undefined then
    (
        format "[ERROR] Could not open file\n"
        return undefined
    )
    
    -- Read header
    local headerData = readTagHeader()
    if headerData == undefined then
    (
        fclose halo_file_handle
        return undefined
    )
    
    -- Read main tagdata
    local tagdata = readMainTagdata()
    
    -- Extract reflexive data
    local markersReflex = tagdata[15]
    local nodesReflex = tagdata[16]
    local regionsReflex = tagdata[17]
    local geometriesReflex = tagdata[18]
    local shadersReflex = tagdata[19]
    
    -- Calculate data block start offset
    -- Header = 64 bytes, Main tagdata = 232 bytes
    -- Total = 296 bytes - this is where reflexive data begins when pointer is 0
    local dataBlockStart = 296
    local currentOffset = dataBlockStart
    
    -- Read all tag blocks using dedicated functions
    local markersResult = readAllMarkers markersReflex currentOffset
    local markersArray = markersResult[1]
    currentOffset = markersResult[2]
    
    local nodesResult = readAllNodes nodesReflex currentOffset
    local nodesArray = nodesResult[1]
    currentOffset = nodesResult[2]
    
    local regionsResult = readAllRegions regionsReflex currentOffset
    local regionsArray = regionsResult[1]
    currentOffset = regionsResult[2]
    local totalLocalMarkers = regionsResult[3]
    
    local geometriesResult = readAllGeometries geometriesReflex currentOffset
    local geometriesArray = geometriesResult[1]
    currentOffset = geometriesResult[2]
    
    local shadersResult = readAllShaders shadersReflex geometriesArray currentOffset
    local shadersArray = shadersResult[1]
    currentOffset = shadersResult[2]
    local updatedGeometriesArray = shadersResult[3]
    
    -- Use updated geometries array if available (contains actual part data)
    if updatedGeometriesArray != undefined then
        geometriesArray = updatedGeometriesArray
    
    fclose halo_file_handle
    --format "\n[SUCCESS] Gbxmodel tag read complete!\n"
    --format "Total local markers: %\n" totalLocalMarkers
    
    return #(headerData, tagdata, markersArray, nodesArray, regionsArray, geometriesArray, shadersArray, totalLocalMarkers)
)

format "Gbxmodel Base Tag Reader loaded successfully.\n"
