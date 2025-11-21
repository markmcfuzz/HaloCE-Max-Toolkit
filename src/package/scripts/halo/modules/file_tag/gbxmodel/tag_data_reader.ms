/**
"REFLEXIVE DATA READERS"
Reads all reflexive data structures for gbxmodel
*/


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
            local markerName = read.tagString 32
            
            -- Magic identifier (2 bytes)
            local magicIdentifier = read.shortB "#unsigned"
            
            -- Skip padding to offset 52 (18 bytes)
            skipBytes 18
            
            -- Marker instances reflexive (12 bytes at offset 52)
            local markerInstancesReflex = read.reflexive()
            
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
        local nodesOffset = if nodesReflex[2] > 0 then nodesReflex[2] else currentOffset
        seekToPosition nodesOffset
        
        local nodesCount = nodesReflex[1]
        if readNodesLogger then
        (
            logger "\n=======================================\n"
            logger "============ READING NODES ============\n"
            logger "=======================================\n"
            logger "NODES: %\n" params:#(nodesCount)
            --logger "Nodes Block Offset: %\n\n" params:#(nodesOffset) logType:#debug
            logger "\n"
        )
        
        for i = 1 to nodesReflex[1] do
        (
            -- Name (32 bytes)
            local nodeName = read.tagString 32
            -- Node indices (6 bytes)
            local nextSibling = read.shortB "#signed"
            local firstChild = read.shortB "#signed"
            local parentNode = read.shortB "#signed"
            -- Skip padding (2 bytes to offset 40)
            skipBytes 2
            -- Translation (12 bytes - 3 floats)
            local translation = math.readPoint3()
            -- Rotation quaternion (16 bytes - 4 floats)
            local defRotation = math.readQuat()
            -- Distance from parent (4 bytes)
            local distanceToParent = read.floatB()
            -- Skip unknown data (offset 72-103 = 32 bytes)
            skipBytes 32
            -- Unknown float (offset 104)
            local unknown = read.floatB()
            -- Rotation matrices (3x12 bytes = 36 bytes)
            local rotJJKK = math.readPoint3()
            local rotKKII = math.readPoint3()
            local rotIIJJ = math.readPoint3()
            -- Translation to root (12 bytes)
            local translationToRoot = math.readPoint3()

            local nodeData = #(nodeName, nextSibling, firstChild, parentNode,
                translation, defRotation, distanceToParent,
                rotJJKK, rotKKII, rotIIJJ, translationToRoot
            )
            
            if nodeName == "" then nodeName = "<empty>"
            -- Add elements to an array
            append nodesArray nodeData
            
            if readNodesLogger then
            ( 
                -- Get node names if valid index
                local parentNodeName = "NULL"
                local siblingNodeName = "NULL"
                local childNodeName = "NULL"
                -- Search names for nodes
                if parentNode >= 0 and parentNode < nodesArray.count then
                    parentNodeName = nodesArray[parentNode + 1][1]
                if nextSibling >= 0 and nextSibling < nodesArray.count then
                    siblingNodeName = nodesArray[nextSibling + 1][1]
                if firstChild >= 0 and firstChild < nodesArray.count then
                    childNodeName = nodesArray[firstChild + 1][1]
                logger "NODE [%]: (%)\n" params:#(i-1, nodeName) logType:#debug
                logger "========================================\n"
                logger "Next Sibling: %  (%)\n" params:#(nextSibling, siblingNodeName) logType:#debug
                logger "First Child: %  (%)\n" params:#(firstChild, childNodeName) logType:#debug
                logger "Parent Node: %  (%)\n" params:#(parentNode, parentNodeName) logType:#debug
                logger "Translation: [%]\n" params:#(pointFormat translation type:#point) logType:#debug
                logger "Rotation: [%]\n" params:#(pointFormat defRotation type:#quat) logType:#debug
                logger "Distance from Parent: %\n" params:#(distance) logType:#debug
                logger "========================================\n\n"
            )
        )
        newOffset += (nodesReflex[1] * 156) -- Each node is 156 bytes
    )
    
    return #(nodesArray, newOffset)
)

-------------------------------------------------------
-- Read All Regions (handles nested reflexives)
-- Region: 76 bytes
-- Permutation: 88 bytes
-- Local Marker: 80 bytes
-------------------------------------------------------
fn readAllRegions regionsReflex currentOffset nodesArray =
(
    local regionsArray = #()
    local totalLocalMarkers = 0
    local newOffset = currentOffset
    
    if regionsReflex[1] > 0 then
    (
        local regionsOffset = if regionsReflex[2] > 0 then regionsReflex[2] else currentOffset
        seekToPosition regionsOffset
        
        if readRegionsLogger then
        (
            logger "\n=========================================\n"
            logger "============ READING REGIONS ============\n"
            logger "=========================================\n"
            logger "REGIONS: %\n" params:#(regionsReflex[1])
        )
        
        -- Read all region headers (76 bytes each)
        local regionHeaders = #()
        for i = 1 to regionsReflex[1] do
        (
            -- Region Name (32 bytes)
            local regionName = read.tagString 32
            -- Skip padding to offset 64
            skipBytes 32
            -- Permutations reflexive (12 bytes at offset 64)
            local permutationsReflex = read.reflexive()
            -- Array from region data
            local regionData = #(regionName, permutationsReflex)
            -- Add elements to an array
            append regionHeaders regionData
        )
        newOffset += (regionsReflex[1] * 76)
        
        -- Read permutations for each region
        for i = 1 to regionHeaders.count do
        (
            local regionData = regionHeaders[i]
            local regionName = regionData[1]
            local permutationsReflex = regionData[2]
            
            -- Log region header
            if readRegionsLogger then
            (
                logger "\n\n"
                logger "REGION [%]: (%)\n" params:#(i-1, regionName) logType:#debug
                logger "Permutations: %\n" params:#(permutationsReflex[1]) logType:#debug
                logger "================================\n"
            )
            
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
                    local permutationName = read.tagString 32
                    
                    -- Flags (4 bytes)
                    local flags = read.longB "#unsigned"
                    
                    -- Permutation set (2 bytes)
                    local permutationSet = read.shortB "#unsigned"
                    
                    -- Skip padding to offset 64 (26 bytes)
                    skipBytes 26
                    
                    -- LOD geometry indices (10 bytes)
                    local superlowGeo = read.shortB "#signed"
                    local lowGeo = read.shortB "#signed"
                    local mediumGeo = read.shortB "#signed"
                    local highGeo = read.shortB "#signed"
                    local superhighGeo = read.shortB "#signed"
                    
                    -- Skip padding to offset 76 (2 bytes)
                    skipBytes 2
                    
                    -- Local markers reflexive (12 bytes at offset 76)
                    local localMarkersReflex = read.reflexive()
                    
                    local permData = #(permutationName, flags, superlowGeo, lowGeo, mediumGeo, highGeo, superhighGeo, localMarkersReflex)
                    append permutationHeaders permData
                )
                newOffset += (permutationsReflex[1] * 88)
                
                -- Second pass: read local markers for each permutation
                for j = 1 to permutationHeaders.count do
                (
                    local permData = permutationHeaders[j]
                    local permName = permData[1]
                    local flags = permData[2]
                    local localMarkersReflex = permData[8]
                    
                    -- Log permutation header
                    if readPermutationsLogger then
                    (
                        local flagName = if flags == 1 then "cannot be choosen randomly" else "NULL"
                        logger "PERMUTATION [%]: (%)\n" params:#(j-1, permName) logType:#debug
                        logger "Flags: % (%)\n" params:#(flags, flagName) logType:#debug
                        logger "Local Markers: %\n" params:#(localMarkersReflex[1]) logType:#debug
                        logger "=================================\n"
                    )
                    
                    local localMarkersArray = #()
                    if localMarkersReflex[1] > 0 then
                    (
                        local localMarkersOffset = if localMarkersReflex[2] > 0 then localMarkersReflex[2] else newOffset
                        seekToPosition localMarkersOffset
                        
                        for k = 1 to localMarkersReflex[1] do
                        (
                            -- Name (32 bytes)
                            local markerName = read.tagString 32
                            -- Node index (2 bytes)
                            local nodeIndex = read.shortB "#signed"
                            -- Skip padding to offset 36 (2 bytes)
                            skipBytes 2
                            -- Rotation quaternion (16 bytes)
                            local mRotation = math.readQuat()
                            -- Translation (12 bytes)
                            local translation = math.readPoint3()
                            -- Skip remaining padding (16 bytes to make total 80)
                            skipBytes 16
                            
                            local markerData = #(markerName, nodeIndex, mRotation, translation)
                            append localMarkersArray markerData
                            totalLocalMarkers += 1
                            
                            if readLocalMarkersLogger then
                            (
                                -- Get node name if valid index
                                local nodeName = "NONE"
                                if nodeIndex >= 0 and nodeIndex < nodesArray.count then
                                    nodeName = nodesArray[nodeIndex + 1][1]  -- [1] is the name in nodeData array
                                logger "MARKER [%]: (%)\n" params:#(k-1, markerName) logType:#debug
                                logger "Node Index: [%]  (%)\n" params:#(nodeIndex, nodeName) logType:#debug
                                logger "Rotation: [%]\n" params:#(pointFormat mRotation type:#quat) logType:#debug
                                logger "Translation: [%]\n" params:#(pointFormat translation type:#point) logType:#debug
                                logger "=================================\n"
                            )
                        )
                        newOffset += (localMarkersReflex[1] * 80)
                    )
                    
                    -- Store permutation with its local markers
                    append permutationsArray #(permData, localMarkersArray)
                )
            )
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
        
        -- Read all geometry headers
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
        -- Store geometries
        for i = 1 to geometryHeaders.count do
        (
            append geometriesArray geometryHeaders[i]
        )
    )
    
    return #(geometriesArray, newOffset)
)

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
    local pathString = read.tagString pathLen
    
    -- Restore position
    fseek fileHandle savedPos #seek_set
    
    return pathString
)

-------------------------------------------------------
-- Read All Shaders (32 bytes per shader)
-------------------------------------------------------

fn readAllShaders shadersReflex geometriesArray currentOffset =
(
    local shadersArray = #()
    
    if shadersReflex[1] > 0 then
    (
        if readShadersLogger then
        (
            logger "\n=========================================\n"
            logger "============ READING SHADERS ============\n"
            logger "=========================================\n"
            logger "SHADERS: %\n\n" params:#(shadersReflex[1])
        )
        
        -- First, read shaders so we can pass shader names to processAllGeometries
        -- Seek to shaders: use pointer if non-zero
        if shadersReflex[2] > 0 then
        (
            seekToPosition shadersReflex[2]
        )
        else
        (
            -- Shaders follow geometries sequentially, need to skip geometry data first
            local result = processAllGeometries geometriesArray currentOffset undefined
            local success = result[1]
            local allPartsData = result[2]
            
            if not success then
            (
                return #(#(), currentOffset, geometriesArray)
            )
            -- Update geometriesArray with actual part data
            if allPartsData != undefined and allPartsData.count > 0 then
            (
                for partDataEntry in allPartsData do
                (
                    local geomIdx = partDataEntry[1]
                    local geometryParts = partDataEntry[2]
                    geometriesArray[geomIdx] = #(geometryParts)
                )
            )
            
            -- Now at shaders position - read them and we're done (already processed geometries)
        )
        
        -- Read shader headers and paths
        local fileHandle = getCurrentFileHandle()
        
        -- FIRST PASS: Read all shader headers (32 bytes each)
        local shaderHeaders = #()
        for i = 1 to shadersReflex[1] do
        (
            local shaderStartPos = ftell fileHandle
            
            -- Shader TagRef (16 bytes)
            local shaderTagRef = read.tagRef()
            
            -- Permutation index (2 bytes)
            local permutationIndex = read.shortB "#signed"
            
            -- Skip padding (14 bytes)
            skipBytes 14
            
            local shaderData = #(shaderTagRef, permutationIndex)
            local shaderClass = shaderTagRef[1]
            local shaderPathPtr = shaderTagRef[2]
            local shaderPathLen = shaderTagRef[3]
            
            -- Get shader type name
            local shaderTypeName = shaderTypes shaderClass
            
            append shaderHeaders #(shaderData, shaderTypeName, shaderClass, shaderPathPtr, shaderPathLen)
        )
        
        -- SECOND PASS: Read all shader path strings and build shadersArray
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
                (shaderPath = read.nullTerminatedString())
                else
                (shaderPath = readShaderPathString shaderPathPtr shaderPathLen)
            )
            if shaderPath == "" then
                shaderPath = "<no path>"
            
            -- Extract shader name (last component of path)
            local shaderName = "<no name>"
            local lastSlashIdx = 0
            for c = shaderPath.count to 1 by -1 do
            (
                if shaderPath[c] == "\\" then
                (
                    lastSlashIdx = c
                    exit
                )
            )
            if lastSlashIdx > 0 and lastSlashIdx < shaderPath.count then
                shaderName = substring shaderPath (lastSlashIdx + 1) -1
            else if shaderPath != "<no path>" then
                shaderName = shaderPath
            
            if readShadersLogger then
            (
                logger "[Shader %]:\n" params:#(i-1) logType:#debug
                logger "============================================================\n"
                logger "Type: %\n" params:#(shaderTypeName) logType:#debug
                logger "Path: %\n" params:#(shaderPath) logType:#debug
                logger "============================================================\n\n"
            )
            
            append shadersArray #(shaderName, shaderPath, shaderTypeName, shaderClass)
        )
        
        -- NOW process geometries with shader names available (only if shaders had absolute pointer)
        if shadersReflex[2] > 0 then
        (
            -- Shaders had absolute pointer, so we haven't processed geometries yet
            local result = processAllGeometries geometriesArray currentOffset shadersArray
            local success = result[1]
            local allPartsData = result[2]
            
            if not success then
            (
                return #(shadersArray, currentOffset, geometriesArray)
            )
            
            -- Update geometriesArray with actual part data
            if allPartsData != undefined and allPartsData.count > 0 then
            (
                for partDataEntry in allPartsData do
                (
                    local geomIdx = partDataEntry[1]
                    local geometryParts = partDataEntry[2]
                    geometriesArray[geomIdx] = #(geometryParts)
                )
            )
        )
        -- else: geometries already processed before reading shaders
    )
    else
    (
        -- No shaders, but still process geometries
        local result = processAllGeometries geometriesArray currentOffset undefined
        local success = result[1]
        local allPartsData = result[2]
        
        if not success then
        (
            return #(#(), currentOffset, geometriesArray)
        )
        
        -- Update geometriesArray with actual part data
        if allPartsData != undefined and allPartsData.count > 0 then
        (
            for partDataEntry in allPartsData do
            (
                local geomIdx = partDataEntry[1]
                local geometryParts = partDataEntry[2]
                geometriesArray[geomIdx] = #(geometryParts)
            )
        )
    )
    
    return #(shadersArray, currentOffset, geometriesArray)
)

logger "Data tag reader loaded.\n" logType:#success
