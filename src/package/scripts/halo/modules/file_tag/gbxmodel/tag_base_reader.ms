-- Halo CE Gbxmodel Tag Base Reader
-- Reads main tag structure (header and tagdata)
-- Reflexive data reading is in tag_data_reader.ms


-------------------------------------------------------
-- Tag Header (64 bytes)
-------------------------------------------------------

fn readTagHeader =
(
    -- Seek to tag class (offset 36 in header)
    seekToPosition 36
    local tagClass = read.longB "#unsigned"
    -- Seek to checksum (offset 40)
    seekToPosition 40
    local checksum = read.longB "#unsigned"
    -- Seek to version (offset 56 in header)  
    seekToPosition 56
    local version = read.shortB "#unsigned"
    -- Seek to engine_id (offset 60 in header)
    seekToPosition 60
    local engineId = read.longB "#unsigned"
    -- Validate tag class
    local expectedGbxFourcc = getFourccByTagName "mod2"
    if tagClass != expectedGbxFourcc then
    (
        logger "Invalid tag class. Expected: %, Found: %\n" params:#(expectedGbxFourcc, tagClass) logType:#error
        return undefined
    )
    
    if tagHeaderLogger then
    (
        logger "\n=== READING TAG HEADER ===\n"
        logger "Tag Class: %\n" params:#(getTagClassInfo tagClass) logType:#debug
        logger "Checksum: %\n" params:#(checksum) logType:#debug
        logger "Version: %\n" params:#(version) logType:#debug
        logger "Engine ID: %\n" params:#(getEngineIdInfo engineId) logType:#debug
    )
    --format "Valid gbxmodel tag: version %\n" version
    return #(tagClass, checksum, version, engineId)
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
    local flags = read.longB "#unsigned"
    
    -- Node list checksum (offset 4)
    local nodeListChecksum = read.longB "#signed"
    
    -- LOD cutoffs (offsets 8-24)
    local superhighLodCutoff = read.floatB()
    local highLodCutoff = read.floatB()
    local mediumLodCutoff = read.floatB()
    local lowLodCutoff = read.floatB()
    local superlowLodCutoff = read.floatB()
    
    -- LOD node counts (offsets 28-36)
    local superhighLodNodes = read.shortB "#signed"
    local highLodNodes = read.shortB "#signed"
    local mediumLodNodes = read.shortB "#signed"
    local lowLodNodes = read.shortB "#signed"
    local superlowLodNodes = read.shortB "#signed"
    
    -- Skip padding (offsets 38-47 = 10 bytes)
    skipBytes 10
    
    -- Base map scales (offsets 48-55)
    local baseMapUScale = read.floatB()
    local baseMapVScale = read.floatB()
    
    -- Skip padding (offsets 56-171 = 116 bytes)
    skipBytes 116
    -- Reflexive blocks start at offset 172 (file offset 236)
    -- Markers reflexive (offset 172)
    local markersReflex = read.reflexive()
    -- Nodes reflexive (offset 184)
    local nodesReflex = read.reflexive()
    -- Regions reflexive (offset 196)
    local regionsReflex = read.reflexive()
    -- Geometries reflexive (offset 208)
    local geometriesReflex = read.reflexive()
    -- Shaders reflexive (offset 220)
    local shadersReflex = read.reflexive()
    
    if tagMainDataLogger then
    (
        logger "\n=== MAIN TAGDATA ===\n"
        logger "Flags: %\n" params:#(flags) logType:#debug
        logger "Node List Checksum: %\n" params:#(nodeListChecksum) logType:#debug
        logger "Super High Cutoff: %\n" params:#(superhighLodCutoff) logType:#debug
        logger "High Cutoff: %\n" params:#(highLodCutoff) logType:#debug
        logger "Medium Cutoff: %\n" params:#(mediumLodCutoff) logType:#debug
        logger "Low Cutoff: %\n" params:#(lowLodCutoff) logType:#debug
        logger "Super Low Cutoff: %\n" params:#(superlowLodCutoff) logType:#debug
        logger "Super High LOD Nodes: %\n" params:#(superhighLodNodes) logType:#debug
        logger "High LOD Nodes: %\n" params:#(highLodNodes) logType:#debug
        logger "Medium LOD Nodes: %\n" params:#(mediumLodNodes) logType:#debug
        logger "Low LOD Nodes: %\n" params:#(lowLodNodes) logType:#debug
        logger "Super Low LOD Nodes: %\n" params:#(superlowLodNodes) logType:#debug
        logger "Base Map U-Scale: %\n" params:#(baseMapUScale) logType:#debug
        logger "Base Map V-Scale: %\n" params:#(baseMapVScale) logType:#debug
    )

    return #(
        flags, nodeListChecksum, superhighLodCutoff, highLodCutoff,
        mediumLodCutoff, lowLodCutoff, superlowLodCutoff, superhighLodNodes,
        highLodNodes, mediumLodNodes, lowLodNodes, superlowLodNodes,
        baseMapUScale, baseMapVScale, markersReflex, nodesReflex, regionsReflex, 
        geometriesReflex, shadersReflex
    )
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
    --local markersResult = readAllMarkers markersReflex currentOffset
    --local markersArray = markersResult[1]
    --currentOffset = markersResult[2]
    
    local t1 = timestamp()
    local nodesResult = readAllNodes nodesReflex currentOffset
    local nodesArray = nodesResult[1]
    currentOffset = nodesResult[2]
    logger "Nodes read: % ms\n" params:#((timestamp() - t1)) logType:#timestamp
    
    local t2 = timestamp()
    local regionsResult = readAllRegions regionsReflex currentOffset nodesArray
    local regionsArray = regionsResult[1]
    currentOffset = regionsResult[2]
    local totalLocalMarkers = regionsResult[3]
    logger "Regions read: % ms\n" params:#((timestamp() - t2)) logType:#timestamp
    
    local t3 = timestamp()
    local geometriesResult = readAllGeometries geometriesReflex currentOffset
    local geometriesArray = geometriesResult[1]
    currentOffset = geometriesResult[2]
    logger "Geometries read: % ms\n" params:#((timestamp() - t3)) logType:#timestamp
    
    local t4 = timestamp()
    local shadersResult = readAllShaders shadersReflex geometriesArray currentOffset
    local shadersArray = shadersResult[1]
    currentOffset = shadersResult[2]
    local updatedGeometriesArray = shadersResult[3]
    logger "Shaders read: % ms\n" params:#((timestamp() - t4)) logType:#timestamp
    
    -- Use updated geometries array if available (contains actual part data)
    if updatedGeometriesArray != undefined then
        geometriesArray = updatedGeometriesArray
    
    fclose halo_file_handle
    --format "\n[SUCCESS] Gbxmodel tag read complete!\n"
    --format "Total local markers: %\n" totalLocalMarkers
    
    return #(headerData, tagdata, markersArray, nodesArray, regionsArray, geometriesArray, shadersArray, totalLocalMarkers)
)

logger "Base tag reader loaded.\n" logType:#success
