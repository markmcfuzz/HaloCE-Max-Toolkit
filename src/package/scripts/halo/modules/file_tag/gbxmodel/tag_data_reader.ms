/**
"REFLEXIVE DATA READERS"
Reads all reflexive data structures for gbxmodel
*/

-------------------------------------------------------
-- Read Nodes (156 bytes per node)
-------------------------------------------------------

fn readNodes nodesReflex =
(
    local nodesCount = nodesReflex.count
    if nodesCount == 0 then
    (
        local result = nodesBlockResult()
        result.nodes = #()
        result.endOffset = 64 + 172 + (5 * 12)
        return result
    )

    -- Calculate data offset
    -- If pointer is 0, data is sequential after all reflexive headers
    -- Reflexives start at 236 (64 header + 172 tagdata)
    -- We have 5 reflexives but skip markers, so: 236 + (5 * 12) = 296
    local nodesDataOffset = if nodesReflex.pointer == 0 then 296 else nodesReflex.pointer
    seekToPosition nodesDataOffset

    local nodes = #()

    for i = 1 to nodesCount do
    (
        -- Read node data (72 bytes of actual data)
        local name = read.tagString 32
        local nextSiblingNode = read.shortB "#signed"
        local firstChildNode = read.shortB "#signed"
        local parentNode = read.shortB "#signed"
        skipBytes 2
        local translation = math.readPoint3()
        local rotation = math.readQuat()
        local distanceFromParent = read.floatB()
        
        -- Skip remaining bytes to complete 156-byte node structure
        skipBytes 84

        local node = returnNodes()
        node.name = name
        node.nextSiblingNode = nextSiblingNode
        node.firstChildNode = firstChildNode
        node.parentNode = parentNode
        node.translation = translation
        node.rotation = rotation
        node.distanceFromParent = distanceFromParent

        append nodes node
    )
    local nodesEndOffset = nodesDataOffset + (nodesCount * 156)
    
    local result = nodesBlockResult()
    result.nodes = nodes
    result.endOffset = nodesEndOffset
    return result
)

-------------------------------------------------------
-- Read Regions (handles nested reflexives)
-- Region: 76 bytes
-- Permutation: 88 bytes  
-- Local Marker: 80 bytes
-------------------------------------------------------
fn readRegions regionsReflex nodesEndOffset =
(
    local regionsCount = regionsReflex.count

    if regionsCount == 0 then
    (
        local result = regionsBlockResult()
        result.regions = #()
        result.endOffset = nodesEndOffset
        return result
    )

    -- Regions start right after nodes data
    local regionsDataOffset = if regionsReflex.pointer == 0 then nodesEndOffset else regionsReflex.pointer
    seekToPosition regionsDataOffset

    local regions = #()
    -- Read all region headers first (76 bytes each)
    for i = 1 to regionsCount do
    (
        -- Read region name (32 bytes at offset 0)
        local name = read.tagString 32
        -- Skip to offset 64 (32 bytes padding)
        skipBytes 32
        
        -- Read permutations reflexive (12 bytes at offset 64)
        local permutationsReflex = read.reflex()

        local region = returnRegions()
        region.name = name
        region.permutationsReflexive = permutationsReflex

        append regions region
    )
    
    -- Track offset after all region headers
    local currentOffset = regionsDataOffset + (regionsCount * 76)

    ---------------------------------------------------
    -- Read permutations for each region
    ---------------------------------------------------
    for i = 1 to regions.count do
    (
        local permReflex = regions[i].permutationsReflexive
        if permReflex.count == 0 then continue
        
        -- Determine permutation data offset
        local permDataOffset = if permReflex.pointer == 0 then currentOffset else permReflex.pointer
        seekToPosition permDataOffset
        
        local permutations = #()
        for j = 1 to permReflex.count do
        (
            -- Name (32 bytes)
            local permName = read.tagString 32
            
            -- Flags (4 bytes at offset 32)
            local flags = read.longB "#unsigned"
            
            -- Skip to offset 64 (28 bytes)
            skipBytes 28
            
            -- LOD geometry indices (10 bytes at offset 64)
            local superlowGeo = read.shortB "#signed"
            local lowGeo = read.shortB "#signed"
            local mediumGeo = read.shortB "#signed"
            local highGeo = read.shortB "#signed"
            local superhighGeo = read.shortB "#signed"
            
            -- Skip to offset 76 (2 bytes padding)
            skipBytes 2
            
            -- Local markers reflexive (12 bytes at offset 76)
            local localMarkersReflex = read.reflex()

            local permutation = returnPermutations()
            permutation.name = permName
            permutation.flags = flags
            permutation.superLowGeometryBlock = superlowGeo
            permutation.lowGeometryBlock = lowGeo
            permutation.mediumGeometryBlock = mediumGeo
            permutation.highGeometryBlock = highGeo
            permutation.superHighGeometryBlock = superhighGeo
            permutation.localMarkersReflexive = localMarkersReflex

            append permutations permutation
        )
        
        -- Update offset after permutations
        currentOffset = permDataOffset + (permReflex.count * 88)

        ---------------------------------------------------
        -- Read local markers for each permutation
        ---------------------------------------------------
        for j = 1 to permutations.count do
        (
            local lMarkersReflex = permutations[j].localMarkersReflexive
            if lMarkersReflex.count == 0 then continue
            
            -- Determine local marker data offset
            local localMarkerDataOffset = if lMarkersReflex.pointer == 0 then currentOffset else lMarkersReflex.pointer
            seekToPosition localMarkerDataOffset

            local localMarkers = #()
            for k = 1 to lMarkersReflex.count do
            (
                -- Name (32 bytes)
                local markerName = read.tagString 32
                
                -- Node index (2 bytes at offset 32)
                local nodeIndex = read.shortB "#signed"
                
                -- Skip padding (2 bytes)
                skipBytes 2

                -- Rotation (16 bytes at offset 36)
                local rotation = math.readQuat()
                
                -- Translation (12 bytes at offset 52)
                local translation = math.readPoint3()

                -- Skip remaining bytes to 80 (16 bytes)
                skipBytes 16

                local localMarker = returnLocalMarkers()
                localMarker.name = markerName
                localMarker.nodeIndex = nodeIndex
                localMarker.rotation = rotation
                localMarker.translation = translation

                append localMarkers localMarker
            )
            -- Update offset after local markers
            currentOffset = localMarkerDataOffset + (lMarkersReflex.count * 80)
            -- Store local markers in permutation
            permutations[j].localMarkers = localMarkers
        )
        -- Store permutations in region
        regions[i].permutations = permutations
    )
    local result = regionsBlockResult()
    result.regions = regions
    result.endOffset = currentOffset
    return result
)

-------------------------------------------------------
-- Read Shaders (32 bytes per shader)
-------------------------------------------------------

fn readShaders shadersReflex geometriesEndOffset =
(
    local shadersCount = shadersReflex.count
    if shadersCount == 0 then
    (
        local result = shadersBlockResult()
        result.shaders = #()
        result.endOffset = geometriesEndOffset
        return result
    )

    local shadersDataOffset = if shadersReflex.pointer == 0 then geometriesEndOffset else shadersReflex.pointer
    seekToPosition shadersDataOffset

    local shaders = #()
    
    -- Read all shader references first (32 bytes each)
    local shaderRefsData = #()
    for i = 1 to shadersCount do
    (
        -- Shader TagRef (16 bytes)
        local shaderTagRef = read.tagRef()

        -- Permutation index (2 bytes)
        local permutationIndex = read.shortB "#signed"

        -- Skip padding (14 bytes)
        skipBytes 14

        -- Store reference data
        local refData = shaderRefData()
        refData.tagRef = shaderTagRef
        refData.shaderType = shaderTypes shaderTagRef.tagClass
        refData.permutationIndex = permutationIndex
        
        append shaderRefsData refData
    )
    
    -- After all shader refs, read the shader path strings sequentially
    seekToPosition (shadersDataOffset + (shadersCount * 32))
    
    for i = 1 to shadersCount do
    (
        local refData = shaderRefsData[i]
        local shaderTagRef = refData.tagRef
        
        local shaderPathPtr = shaderTagRef.pathPtr
        local shaderPathLen = shaderTagRef.pathLen

        -- Read shader path string
        local shaderPath = ""
        if shaderPathPtr == 0 and shaderPathLen > 0 then
        (
            -- Source tag: strings are null-terminated and stored sequentially
            shaderPath = read.nullTerminatedString()
        )
        else if shaderPathPtr != 0 then
        (
            -- Cache tag: read from pointer using utility function
            shaderPath = readTagRefPath shaderPathPtr shaderPathLen
        )
        
        -- Extract shader name from path (last part after last backslash)
        local shaderName = ""
        if shaderPath != "" then
        (
            local lastSlashPos = 0
            for j = shaderPath.count to 1 by -1 do
            (
                if shaderPath[j] == "\\" then
                (
                    lastSlashPos = j
                    exit
                )
            )
            shaderName = if lastSlashPos > 0 then substring shaderPath (lastSlashPos + 1) -1 else shaderPath
        )

        -- Create final shader struct
        local shader = returnShaders()
        shader.shaderType = refData.shaderType
        shader.shaderPath = shaderPath
        shader.shaderName = shaderName
        shader.permutationIndex = refData.permutationIndex

        append shaders shader
    )
    
    -- Calculate end offset: after all shader refs and path strings
    local fileHandle = getCurrentFileHandle()
    local shadersEndOffset = ftell fileHandle

    local result = shadersBlockResult()
    result.shaders = shaders
    result.endOffset = shadersEndOffset
    return result
)


logger "Data tag reader loaded.\n" logType:#success
