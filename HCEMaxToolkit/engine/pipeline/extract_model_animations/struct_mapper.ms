-------------------------------------------------------
-- STRUCT MAPPER - MODEL ANIMATIONS
-- Converts parser tuple arrays to typed struct instances
-- for fast property access in the animation extractor.
-------------------------------------------------------

-- Node struct (only the fields the extractor needs)
struct AntrNode (
    name,
    nextSiblingNodeIndex,
    firstChildNodeIndex
)

-- Animation struct with all extractor-relevant fields.
-- frameInfoFileOff / defaultDataFileOff / frameDataFileOff are absolute
-- file positions annotated by the parser (tagData[4]), replacing the old
-- rawDataBase + cumulative-offset approach.
struct AntrAnimation (
    name,
    type,
    frameCount,
    frameInfoType,
    nodeListChecksum,
    nodeCount,
    flags,
    nodeTransFlagData,         -- #(int32, int32)
    nodeRotFlagData,           -- #(int32, int32)
    nodeScaleFlagData,         -- #(int32, int32)
    frameInfoSize,
    defaultDataSize,
    frameDataSize,
    offsetToCompressedData,
    frameInfoFileOff = 0,
    defaultDataFileOff = 0,
    frameDataFileOff = 0
)

-- Convert parser tuple arrays into AntrNode / AntrAnimation struct arrays.
-- tupleArrays : array of tuple entries from the parser (each entry is #(#(name, val, def), ...))
-- structType  : #node or #animation
fn tuplesToAntrStructs tupleArrays structType =
(
    if tupleArrays == undefined or tupleArrays.count == 0 then return #()

    local fieldIndex = buildFieldIndex tupleArrays[1]
    local result = #()

    case structType of
    (
        #node: (
            local namePos     = getFieldPosition fieldIndex "name"
            local nextSibPos  = getFieldPosition fieldIndex "nextSiblingNodeIndex"
            local firstChPos  = getFieldPosition fieldIndex "firstChildNodeIndex"

            for t in tupleArrays do
            (
                append result (AntrNode \
                    name:t[namePos][2] \
                    nextSiblingNodeIndex:t[nextSibPos][2] \
                    firstChildNodeIndex:t[firstChPos][2])
            )
        )
        #animation: (
            local namePos       = getFieldPosition fieldIndex "name"
            local typePos       = getFieldPosition fieldIndex "type"
            local fcPos         = getFieldPosition fieldIndex "frameCount"
            local fitPos        = getFieldPosition fieldIndex "frameInfoType"
            local chkPos        = getFieldPosition fieldIndex "nodeListChecksum"
            local ncPos         = getFieldPosition fieldIndex "nodeCount"
            local flagsPos      = getFieldPosition fieldIndex "flags"
            local transFlagPos  = getFieldPosition fieldIndex "nodeTransFlagData"
            local rotFlagPos    = getFieldPosition fieldIndex "nodeRotationFlagData"
            local scaleFlagPos  = getFieldPosition fieldIndex "nodeScaleFlagData"
            local compOffPos    = getFieldPosition fieldIndex "offsetToCompressedData"
            local fiPos         = getFieldPosition fieldIndex "frameInfo"
            local ddPos         = getFieldPosition fieldIndex "defaultData"
            local fdPos         = getFieldPosition fieldIndex "frameData"

            for t in tupleArrays do
            (
                -- tagData values: #(size, flags, offset) or #(size, flags, offset, filePos)
                local fiTD = t[fiPos][2]
                local ddTD = t[ddPos][2]
                local fdTD = t[fdPos][2]

                local fiSize = if fiTD != undefined and fiTD.count >= 1 then fiTD[1] else 0
                local ddSize = if ddTD != undefined and ddTD.count >= 1 then ddTD[1] else 0
                local fdSize = if fdTD != undefined and fdTD.count >= 1 then fdTD[1] else 0

                local fiFileOff = if fiTD != undefined and fiTD.count >= 4 then fiTD[4] else 0
                local ddFileOff = if ddTD != undefined and ddTD.count >= 4 then ddTD[4] else 0
                local fdFileOff = if fdTD != undefined and fdTD.count >= 4 then fdTD[4] else 0

                append result (AntrAnimation \
                    name:t[namePos][2] \
                    type:t[typePos][2] \
                    frameCount:t[fcPos][2] \
                    frameInfoType:t[fitPos][2] \
                    nodeListChecksum:t[chkPos][2] \
                    nodeCount:t[ncPos][2] \
                    flags:t[flagsPos][2] \
                    nodeTransFlagData:t[transFlagPos][2] \
                    nodeRotFlagData:t[rotFlagPos][2] \
                    nodeScaleFlagData:t[scaleFlagPos][2] \
                    frameInfoSize:fiSize \
                    defaultDataSize:ddSize \
                    frameDataSize:fdSize \
                    offsetToCompressedData:t[compOffPos][2] \
                    frameInfoFileOff:fiFileOff \
                    defaultDataFileOff:ddFileOff \
                    frameDataFileOff:fdFileOff)
            )
        )
    )
    result
)

-- Top-level converter: takes raw parser entry, extracts nodes and animations blocks,
-- and returns #(nodeStructs, animationStructs).
fn convertAntrData parsedEntry =
(
    local nodesData = getFieldValue parsedEntry "nodes"
    local animsData = getFieldValue parsedEntry "animations"

    local nodes = tuplesToAntrStructs nodesData #node
    local anims = tuplesToAntrStructs animsData #animation

    #(nodes, anims)
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
