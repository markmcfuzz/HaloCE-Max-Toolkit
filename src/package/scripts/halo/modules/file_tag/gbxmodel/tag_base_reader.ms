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
        logger "Version: %\n" params:#(version) logType:#debug
        logger "Engine ID: %\n" params:#(getEngineIdInfo engineId) logType:#debug
    )
    -- Create and return the header struct
    local header = returnHeader()
    header.tagClass = tagClass
    header.version = version
    header.engineId = engineId
    return header
)

-------------------------------------------------------
-- Main Base Tag (232 bytes starting at offset 64)
-------------------------------------------------------

fn readBaseTag =
(
    -- Start after header
    seekToPosition 64
    
    -- Flags (offset 0 in tagdata, offset 64 in file)
    local flags = read.longB "#unsigned"
    
    -- Node list checksum (offset 4)
    local nodeListChecksum = read.longB "#signed"
    
    -- LOD cutoffs (offsets 8-24, size 4)
    local superhighLodCutoff = read.floatB()
    local highLodCutoff = read.floatB()
    local mediumLodCutoff = read.floatB()
    local lowLodCutoff = read.floatB()
    local superlowLodCutoff = read.floatB()

    -- Skip LOD nodes and padding (offsets 27-47)
    local lodNodesPlusPadding = 10 + 10 
    skipBytes lodNodesPlusPadding
    -- Base map scales (offsets 48-55)
    local baseMapUScale = read.floatB()
    local baseMapVScale = read.floatB()

    local tagBase = returnTagBase()
    tagBase.flags = flags
    tagBase.nodeListChecksum = nodeListChecksum
    tagBase.superHighDetailCutoff = superhighLodCutoff
    tagBase.highDetailCutoff = highLodCutoff
    tagBase.mediumDetailCutoff = mediumLodCutoff
    tagBase.lowDetailCutoff = lowLodCutoff
    tagBase.superLowDetailCutoff = superlowLodCutoff
    tagBase.baseMapUScale = baseMapUScale
    tagBase.baseMapVScale = baseMapVScale
    return tagBase
)

-------------------------------------------------------
-- Reflexive Headers Reading
-------------------------------------------------------

fn readRlexiveHeaders =
(
    /**
    According to the gbxmodel tag structure, reflexive headers start at offset
    172 in the tagdata (file offset 236 = 64 header + 172 tagdata).
    Each reflexive header is 12 bytes.
    The order of reflexives is:
        - markers   (offset 236) - SKIPPED (cache-only, not in source tags)
        - nodes     (offset 248)
        - regions   (offset 260)
        - geometries(offset 272)
        - shaders   (offset 284)
    We skip the markers reflexive since it's only populated in cache files.
    */
    
    -- Seek to nodes reflexive header
    -- header + reflexive header + skip markers
    local nodesReflexiveOffset = 64 + 172 + 12
    seekToPosition nodesReflexiveOffset
    
    local nodesReflexive = read.reflex()
    
    local regionsReflexive = read.reflex()
    
    local geometriesReflexive = read.reflex()
    
    local shadersReflexive = read.reflex()

    local reflexives = returnReflexives()
    reflexives.nodes = nodesReflexive
    reflexives.regions = regionsReflexive
    reflexives.geometries = geometriesReflexive
    reflexives.shaders = shadersReflexive
    return reflexives
)

-------------------------------------------------------
-- Main Tag Reader Function
-------------------------------------------------------

fn readGbxmodelTag gbxmodelFilePath =
(
    local fileHandle = fopen gbxmodelFilePath "rb"
    if fileHandle == undefined then
    (
        format "[ERROR] Could not open file\n"
        return undefined
    )
    setFileHandle fileHandle
    in_file = fileHandle

    -- Create Gbxmodel data structure
    local tagStruct = gbxmodelTag()

    -- Read and validate Header
    local tagHeader = readTagHeader()
    tagStruct.header = tagHeader

    -- Read and store base tag
    local tagBase = readBaseTag()
    tagStruct.tagBase = tagBase

    -- Read Reflexive Headers
    local gbxReflex = readRlexiveHeaders()
    tagStruct.nodesTagBlock = gbxReflex.nodes
    tagStruct.regionsTagBlock = gbxReflex.regions
    tagStruct.geometriesTagBlock = gbxReflex.geometries
    tagStruct.shadersTagBlock = gbxReflex.shaders


    local nodesResult = readNodes gbxReflex.nodes
    tagStruct.nodes = nodesResult.nodes

    local regionsResult = readRegions gbxReflex.regions nodesResult.endOffset
    tagStruct.regions = regionsResult.regions

    local geometriesResult = readGeometries gbxReflex.geometries regionsResult.endOffset
    tagStruct.geometries = geometriesResult.geometries
    tagStruct.geometriesTagBlock = gbxReflex.geometries

    local shadersResult = readShaders gbxReflex.shaders geometriesResult.endOffset
    tagStruct.shaders = shadersResult.shaders

    if tagMainDataLogger then
    (
        logger "\n=== TAG BASE ===\n"
        logger "Flags: (%)\n" params:#(tagFlags tagStruct.tagBase.flags)
        logger "Node List Checksum: [%]\n" params:#(tagStruct.tagBase.nodeListChecksum)
        logger "Super High Detail Cutoff: [%]\n" params:#(tagStruct.tagBase.superHighDetailCutoff)
        logger "High Detail Cutoff: [%]\n" params:#(tagStruct.tagBase.highDetailCutoff)
        logger "Medium Detail Cutoff: [%]\n" params:#(tagStruct.tagBase.mediumDetailCutoff)
        logger "Low Detail Cutoff: [%]\n" params:#(tagStruct.tagBase.lowDetailCutoff)
        logger "Super Low Detail Cutoff: [%]\n" params:#(tagStruct.tagBase.superLowDetailCutoff)
        logger "Base Map U Scale: [%]\n" params:#(tagStruct.tagBase.baseMapUScale)
        logger "Base Map V Scale: [%]\n\n" params:#(tagStruct.tagBase.baseMapVScale)

        logger "\n=== NODES ===\n"
        logger "Nodes Count: [%]\n" params:#(tagStruct.nodes.count)
        for i = 1 to tagStruct.nodes.count do
        (
            local node = tagStruct.nodes[i]
            logger "\nNode [%]:\n" params:#(i - 1)
            logger "    - Name: (%)\n" params:#(node.name)
            logger "    - Next Sibling Node: [%]\n" params:#(node.nextSiblingNode)
            logger "    - First Child Node: [%]\n" params:#(node.firstChildNode)
            logger "    - Parent Node: [%]\n" params:#(node.parentNode)
            logger "    - Translation: [%]\n" params:#(pointFormat node.translation type:#point)
            logger "    - Rotation: [%]\n" params:#(pointFormat node.rotation type:#quat)
            logger "    - Distance From Parent: [%]\n" params:#(node.distanceFromParent)
        )
        
        logger "\n=== REGIONS ===\n"
        logger "Regions Count: [%]\n" params:#(tagStruct.regionsTagBlock.count)
        for i = 1 to tagStruct.regions.count do
        (
            local region = tagStruct.regions[i]
            logger "\nRegion [%]:\n" params:#(i - 1)
            logger "    - Name: (%)\n" params:#(region.name)
            logger "        - PERMUTATIONS COUNT: [%]\n" params:#(region.permutations.count)
            for j = 1 to region.permutations.count do
            (
                local permutation = region.permutations[j]
                logger "            - Permutation [%]:\n" params:#(j - 1)
                logger "                - Name: (%)\n" params:#(permutation.name)
                logger "                - Flags: (%)\n" params:#(permutation.flags)
                logger "                - Super Low Geometry: [%]\n" params:#(permutation.superLowGeometryBlock)
                logger "                - Low Geometry: [%]\n" params:#(permutation.lowGeometryBlock)
                logger "                - Medium Geometry: [%]\n" params:#(permutation.mediumGeometryBlock)
                logger "                - High Geometry: [%]\n" params:#(permutation.highGeometryBlock)
                logger "                - Super High Geometry: [%]\n" params:#(permutation.superHighGeometryBlock)
                logger "                =================================\n"
                logger "                    - LOCAL MARKERS COUNT: [%]\n" params:#(permutation.localMarkers.count)
                for k = 1 to permutation.localMarkers.count do
                (
                    local localMarker = permutation.localMarkers[k]
                    logger "                        - Local Marker [%]:\n" params:#(k - 1)
                    logger "                            - Name: (%)\n" params:#(localMarker.name)
                    logger "                            - Node Index: [%]\n" params:#(localMarker.nodeIndex)
                    logger "                            - Rotation: [%]\n" params:#(pointFormat localMarker.rotation type:#quat)
                    logger "                            - Translation: [%]\n" params:#(pointFormat localMarker.translation type:#point)
                    logger "                            ===============================================================\n"
                )
            )
        )
        logger "\n=== GEOMETRIES ===\n"
        logger "Geometries Count: [%]\n" params:#(tagStruct.geometriesTagBlock.count)
        for i = 1 to tagStruct.geometries.count do
        (
            local geometry = tagStruct.geometries[i]
            logger "\nGeometry [%]:\n" params:#(i - 1)
            logger "    - PARTS COUNT: [%]\n" params:#(geometry.parts.count)
            for j = 1 to geometry.parts.count do
            (
                local part = geometry.parts[j]
                logger "\n        Part [%]:\n" params:#(j - 1)
                logger "            - Flags: [%]\n" params:#(part.flags)
                logger "            - Shader Index: [%]\n" params:#(part.shaderIndex)
                logger "            - Previous Part Index: [%]\n" params:#(part.previousPartIndex)
                logger "            - Next Part Index: [%]\n" params:#(part.nextPartIndex)
                logger "            - Uncompressed Vertices Count: [%]\n" params:#(part.uncompressedVertices.count)
                logger "            - Compressed Vertices Count: [%]\n" params:#(part.compressedVertices.count)
                --for k = 1 to part.compressedVertices.count do
                --(
                --    local vertex = part.compressedVertices[k]
                --    logger "                - Vertex [%]:\n" params:#(k - 1)
                --    logger "                - Position: [%]\n" params:#(pointFormat vertex.position type:#point)
                --)
                logger "            - Triangles Count: [%]\n" params:#(part.triangles.count)
            )
        )
    )
    if gbxShadersLogger then
    (
        logger "\n=== SHADERS ===\n"
        logger "Shaders Count: [%]\n\n" params:#(tagStruct.shadersTagBlock.count)
        for i = 1 to tagStruct.shaders.count do
        (
            local shader = tagStruct.shaders[i]
            logger "Shader [%]:\n" params:#(i - 1)
            logger "    - Shader Type: (%)\n" params:#(shader.shaderType)
            logger "    - Shader Path: (%)\n" params:#(shader.shaderPath)
            logger "    - Shader Name: (%)\n" params:#(shader.shaderName)
            logger "    - Permutation Index: [%]\n" params:#(shader.permutationIndex)
        )
    )
    fclose fileHandle
    return tagStruct
)

logger "Base tag reader loaded.\n" logType:#success