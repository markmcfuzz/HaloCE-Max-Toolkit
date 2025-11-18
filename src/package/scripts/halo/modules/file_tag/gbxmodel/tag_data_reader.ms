-------------------------------------------------------
-- REFLEXIVE DATA READERS
-- Reads all reflexive/nested data structures for gbxmodel
-------------------------------------------------------

-------------------------------------------------------
-- Shader Path String Reader
-------------------------------------------------------

fn readShaderPathString pathPtr pathLen =
(
    if pathPtr == 0 or pathLen <= 0 then
        return ""
    
    -- Save current position
    local fileHandle = getCurrentFileHandle()
    local savedPos = ftell fileHandle
    
    -- Seek to path location
    seekToPosition pathPtr
    
    -- Read path string
    local pathString = readFixedString pathLen
    
    -- Restore position
    fseek fileHandle savedPos #seek_set
    
    return pathString
)

-------------------------------------------------------
-- Read All Markers (64 bytes per marker)
-------------------------------------------------------

fn readAllMarkers markersReflex currentOffset =
(
    local markersArray = #()
    local newOffset = currentOffset
    
    if markersReflex[1] > 0 then
    (
        --format "\n=== READING MARKERS ===\n"
        local markersOffset = if markersReflex[2] > 0 then markersReflex[2] else currentOffset
        seekToPosition markersOffset
        
        for i = 1 to markersReflex[1] do
        (
            -- Name (32 bytes)
            local markerName = readFixedString 32
            
            -- Magic identifier (2 bytes)
            local magicIdentifier = readShortB "#unsigned"
            
            -- Skip padding to offset 52 (18 bytes)
            skipBytes 18
            
            -- Marker instances reflexive (12 bytes at offset 52)
            local markerInstancesReflex = readReflexive()
            
            local markerData = #(markerName, magicIdentifier, markerInstancesReflex)
            --format "Marker %: '%'\n" i markerData[1]
            append markersArray markerData
        )
        newOffset += (markersReflex[1] * 64) -- Each marker is 64 bytes
    )
    
    return #(markersArray, newOffset)
)

-------------------------------------------------------
-- Read All Nodes (156 bytes per node)
-------------------------------------------------------

fn readAllNodes nodesReflex currentOffset =
(
    local nodesArray = #()
    local newOffset = currentOffset
    
    if nodesReflex[1] > 0 then
    (
        --format "\n=== READING NODES ===\n"
        local nodesOffset = if nodesReflex[2] > 0 then nodesReflex[2] else currentOffset
        seekToPosition nodesOffset
        
        for i = 1 to nodesReflex[1] do
        (
            -- Name (32 bytes)
            local nodeName = readFixedString 32
            
            -- Node indices (6 bytes)
            local nextSibling = readShortB "#signed"
            local firstChild = readShortB "#signed"
            local parentNode = readShortB "#signed"
            
            -- Skip padding (2 bytes to offset 40)
            skipBytes 2
            
            -- Translation (12 bytes - 3 floats)
            local translation = readPoint3B()
            
            -- Rotation quaternion (16 bytes - 4 floats)
            local rotI = readFloatB()
            local rotJ = readFloatB()
            local rotK = readFloatB()
            local rotW = readFloatB()
            
            -- Distance from parent (4 bytes)
            local distance = readFloatB()
            
            -- Skip unknown data (offset 72-103 = 32 bytes)
            skipBytes 32
            
            -- Unknown float (offset 104)
            local unknown = readFloatB()
            
            -- Rotation matrices (3x12 bytes = 36 bytes)
            local rotJJKK = readPoint3B()
            local rotKKII = readPoint3B()
            local rotIIJJ = readPoint3B()
            
            -- Translation to root (12 bytes)
            local translationToRoot = readPoint3B()
            
            local nodeData = #(nodeName, nextSibling, firstChild, parentNode, 
                             translation, #(rotI, rotJ, rotK, rotW), distance,
                             rotJJKK, rotKKII, rotIIJJ, translationToRoot)
            
            if nodeName == "" then nodeName = "<empty>"
            --format "Node %: '%'\n" i nodeName
            append nodesArray nodeData
        )
        newOffset += (nodesReflex[1] * 156) -- Each node is 156 bytes
    )
    
    return #(nodesArray, newOffset)
)

-------------------------------------------------------
-- Read All Regions (handles nested reflexives)
-- Region: 76 bytes, Permutation: 88 bytes, Local Marker: 80 bytes
-------------------------------------------------------

fn readAllRegions regionsReflex currentOffset =
(
    local regionsArray = #()
    local totalLocalMarkers = 0
    local newOffset = currentOffset
    
    if regionsReflex[1] > 0 then
    (
        --format "\n=== READING REGIONS ===\n"
        local regionsOffset = if regionsReflex[2] > 0 then regionsReflex[2] else currentOffset
        seekToPosition regionsOffset
        
        -- First pass: read all region headers (76 bytes each)
        local regionHeaders = #()
        for i = 1 to regionsReflex[1] do
        (
            -- Name (32 bytes)
            local regionName = readFixedString 32
            
            -- Skip padding to offset 64
            skipBytes 32
            
            -- Permutations reflexive (12 bytes at offset 64)
            local permutationsReflex = readReflexive()
            
            local regionData = #(regionName, permutationsReflex)
            append regionHeaders regionData
        )
        newOffset += (regionsReflex[1] * 76)
        
        -- Second pass: read permutations for each region
        for i = 1 to regionHeaders.count do
        (
            local regionData = regionHeaders[i]
            local regionName = regionData[1]
            local permutationsReflex = regionData[2]
            
            local permutationsArray = #()
            if permutationsReflex[1] > 0 then
            (
                local permutationsOffset = if permutationsReflex[2] > 0 then permutationsReflex[2] else newOffset
                seekToPosition permutationsOffset
                
                -- First pass: read all permutation headers (88 bytes each)
                local permutationHeaders = #()
                for j = 1 to permutationsReflex[1] do
                (
                    -- Name (32 bytes)
                    local permutationName = readFixedString 32
                    
                    -- Flags (4 bytes)
                    local flags = readLongB "#unsigned"
                    
                    -- Permutation set (2 bytes)
                    local permutationSet = readShortB "#unsigned"
                    
                    -- Skip padding to offset 64 (26 bytes)
                    skipBytes 26
                    
                    -- LOD geometry indices (10 bytes)
                    local superlowGeo = readShortB "#signed"
                    local lowGeo = readShortB "#signed"
                    local mediumGeo = readShortB "#signed"
                    local highGeo = readShortB "#signed"
                    local superhighGeo = readShortB "#signed"
                    
                    -- Skip padding to offset 76 (2 bytes)
                    skipBytes 2
                    
                    -- Local markers reflexive (12 bytes at offset 76)
                    local localMarkersReflex = readReflexive()
                    
                    local permData = #(permutationName, flags, superlowGeo, lowGeo, mediumGeo, highGeo, superhighGeo, localMarkersReflex)
                    append permutationHeaders permData
                )
                newOffset += (permutationsReflex[1] * 88)
                
                -- Second pass: read local markers for each permutation
                for j = 1 to permutationHeaders.count do
                (
                    local permData = permutationHeaders[j]
                    local permName = permData[1]
                    local localMarkersReflex = permData[8]
                    
                    local localMarkersArray = #()
                    if localMarkersReflex[1] > 0 then
                    (
                        local localMarkersOffset = if localMarkersReflex[2] > 0 then localMarkersReflex[2] else newOffset
                        seekToPosition localMarkersOffset
                        
                        for k = 1 to localMarkersReflex[1] do
                        (
                            -- Name (32 bytes)
                            local markerName = readFixedString 32
                            
                            -- Node index (2 bytes)
                            local nodeIndex = readShortB "#signed"
                            
                            -- Skip padding to offset 36 (2 bytes)
                            skipBytes 2
                            
                            -- Rotation quaternion (16 bytes)
                            local rotI = readFloatB()
                            local rotJ = readFloatB()
                            local rotK = readFloatB()
                            local rotW = readFloatB()
                            
                            -- Translation (12 bytes)
                            local translation = readPoint3B()
                            
                            -- Skip remaining padding (16 bytes to make total 80)
                            skipBytes 16
                            
                            local markerData = #(markerName, nodeIndex, #(rotI, rotJ, rotK, rotW), translation)
                            --format "  Local Marker '%' in permutation '%' of region '%'\n" markerData[1] permName regionName
                            append localMarkersArray markerData
                            totalLocalMarkers += 1
                        )
                        newOffset += (localMarkersReflex[1] * 80)
                    )
                    
                    -- Store permutation with its local markers
                    append permutationsArray #(permData, localMarkersArray)
                )
            )
            
            --format "Region %: '%%'\n" i regionName (if permutationsArray.count > 0 then (" (" + permutationsArray.count as string + " permutations)") else "")
            
            -- Store region with its permutations
            append regionsArray #(regionData, permutationsArray)
        )
    )
    
    return #(regionsArray, newOffset, totalLocalMarkers)
)

-------------------------------------------------------
-- Read All Geometries (48 bytes per geometry)
-------------------------------------------------------

fn readAllGeometries geometriesReflex currentOffset =
(
    local geometriesArray = #()
    local newOffset = currentOffset
    
    if geometriesReflex[1] > 0 then
    (
        --format "\n=== READING GEOMETRIES ===\n"
        local geometriesOffset = if geometriesReflex[2] > 0 then geometriesReflex[2] else currentOffset
        seekToPosition geometriesOffset
        
        -- First pass: read all geometry headers
        local geometryHeaders = #()
        for i = 1 to geometriesReflex[1] do
        (
            local geometryData = readGeometry()
            local partsReflex = geometryData[1]
            -- format "[DEBUG] Geometry % header: parts reflexive = count:%, pointer:%, id:%\n" i partsReflex[1] partsReflex[2] partsReflex[3]
            append geometryHeaders geometryData
        )
        newOffset += (geometriesReflex[1] * 48) -- Each geometry is 48 bytes
        
        -- Calculate total parts for informational purposes
        local totalParts = 0
        for i = 1 to geometryHeaders.count do
        (
            totalParts += geometryHeaders[i][1][1]
            --format "Geometry %: % parts\n" i geometryHeaders[i][1][1]
        )
        
        --format "Total parts across all geometries: %\n" totalParts
        
        -- Store geometries
        for i = 1 to geometryHeaders.count do
        (
            append geometriesArray geometryHeaders[i]
        )
    )
    
    return #(geometriesArray, newOffset)
)

-------------------------------------------------------
-- Read All Shaders (32 bytes per shader)
-------------------------------------------------------

fn readAllShaders shadersReflex geometriesArray currentOffset =
(
    local shadersArray = #()
    
    if shadersReflex[1] > 0 then
    (
        --format "\n=== READING SHADERS ===\n"
        -- format "[DEBUG] Shaders reflexive: count=%, pointer=%, id=%\n" shadersReflex[1] shadersReflex[2] shadersReflex[3]
        
        -- ALWAYS process geometries to read actual part data
        local result = processAllGeometries geometriesArray currentOffset
        local success = result[1]
        local allPartsData = result[2]
        
        if not success then
        (
            --format "[ERROR] Failed to process geometries, cannot read shaders\n"
            return #(#(), currentOffset, geometriesArray)
        )
        
        -- Update geometriesArray with actual part data
        if allPartsData != undefined and allPartsData.count > 0 then
        (
            for partDataEntry in allPartsData do
            (
                local geomIdx = partDataEntry[1]
                local geometryParts = partDataEntry[2]
                
                -- Update geometry entry: change from #(partsReflex) to #(partsArray)
                geometriesArray[geomIdx] = #(geometryParts)
            )
        )
        
        -- Now seek to shaders: use pointer if non-zero, otherwise we're already at the right position
        if shadersReflex[2] > 0 then
        (
            local shadersOffset = shadersReflex[2]
            -- format "[DEBUG] Seeking to shader pointer: %L\n" shadersOffset
            seekToPosition shadersOffset
        )
        -- else: we're already at the correct position after processAllGeometries
        
        -- Read shader headers and paths
        local fileHandle = getCurrentFileHandle()
        
        -- FIRST PASS: Read all shader headers (32 bytes each)
        local shaderHeaders = #()
        for i = 1 to shadersReflex[1] do
        (
            local shaderStartPos = ftell fileHandle
            
            -- Shader TagRef (16 bytes)
            local shaderTagRef = readTagRef()
            
            -- Permutation index (2 bytes)
            local permutationIndex = readShortB "#signed"
            
            -- Skip padding (14 bytes)
            skipBytes 14
            
            local shaderData = #(shaderTagRef, permutationIndex)
            local shaderClass = shaderTagRef[1]
            local shaderPathPtr = shaderTagRef[2]
            local shaderPathLen = shaderTagRef[3]
            
            -- Get shader type name
            local shaderTypeName = shaderTypes shaderClass
            
            -- format "[DEBUG] Shader % header at %L: type='%' (%), pathPtr=%, pathLen=%\n" \
            --     i shaderStartPos shaderTypeName shaderClass shaderPathPtr shaderPathLen
            
            append shaderHeaders #(shaderData, shaderTypeName, shaderClass, shaderPathPtr, shaderPathLen)
        )
        
        -- SECOND PASS: Read all shader path strings sequentially
        -- format "[DEBUG] Now reading shader paths at position %L\n" (ftell fileHandle)
        for i = 1 to shaderHeaders.count do
        (
            local headerInfo = shaderHeaders[i]
            local shaderData = headerInfo[1]
            local shaderTypeName = headerInfo[2]
            local shaderClass = headerInfo[3]
            local shaderPathPtr = headerInfo[4]
            local shaderPathLen = headerInfo[5]
            
            -- Read path
            local shaderPath = ""
            if shaderPathLen > 0 and shaderPathLen < 10000 then
            (
                if shaderPathPtr == 0 then
                (
                    -- Path follows sequentially - use null-terminated reader
                    shaderPath = readNullTerminatedString()
                )
                else
                (
                    -- Path at absolute position
                    shaderPath = readShaderPathString shaderPathPtr shaderPathLen
                )
            )
            
            if shaderPath == "" then
                shaderPath = "<no path>"
            
            -- Extract shader name (last component of path)
            local shaderName = "<no name>"
            if shaderPath != "<no path>" then
            (
                local pathParts = filterString shaderPath "\\"
                if pathParts.count > 0 then
                    shaderName = pathParts[pathParts.count]
                else
                    shaderName = shaderPath
            )
            
            --format "Shader %: name='%', type='%', path='%' (permutation=%)\n" i shaderName shaderTypeName shaderPath shaderData[2]
            
            append shadersArray #(shaderData, shaderPath, shaderName, shaderTypeName)
        )
    )
    
    return #(shadersArray, currentOffset, geometriesArray)
)

format "Gbxmodel Data Tag Reader loaded successfully.\n"
