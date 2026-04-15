------------------------------------------------------------------------------
--	Copyright (C) 2025 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------

-------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------

-- Animation type field values
animTypeBase = 0
animTypeOverlay = 1
animTypeReplacement = 2

-- Frame info type field values
frameInfoNone = 0
frameInfoDxDy = 1
frameInfoDxDyDyaw = 2
frameInfoDxDyDzDyaw = 3

-- Animation flag bits (bit.get index, 1-based)
animFlagCompressed = 1
animFlagWorldRelative = 2

-------------------------------------------------------
-- HELPERS
-------------------------------------------------------

-- Convert CE tagData memory pointer to actual file offset.
-- CE source tags map tag data starting at the base address; the
-- file stores the tag header at bytes 0-63, so the data starts
-- at file offset 64.
fn tagDataToFileOffset tagDataOffset =
(
    local base = getTagMemoryBaseAddress()
    if base == undefined then base = 0x40440000
    tagDataOffset - base + 64
)

-- Check whether bit `bitIndex` (1-based) is set for node `nodeIndex`
-- (1-based) in the two-int32 packed flag array used by the tag.
fn getNodeFlagBit flagArray nodeIndex =
(
    if nodeIndex <= 32 then
        bit.get flagArray[1] nodeIndex
    else
        bit.get flagArray[2] (nodeIndex - 32)
)

-- Return the animation source-format file extension for the given
-- type/frameInfoType/flags combination.
fn getAnimExtension animType frameInfoType animFlags =
(
    local worldRelative = bit.get animFlags animFlagWorldRelative
    case of
    (
        (animType == animTypeReplacement):                                               "JMR"
        (animType == animTypeOverlay):                                                   "JMO"
        (animType == animTypeBase and frameInfoType == frameInfoNone and worldRelative): "JMW"
        (animType == animTypeBase and frameInfoType == frameInfoDxDy):                "JMA"
        (animType == animTypeBase and frameInfoType == frameInfoDxDyDyaw):           "JMT"
        (animType == animTypeBase and frameInfoType == frameInfoDxDyDzDyaw):        "JMZ"
        default:                                                                            "JMM"
    )
)

-------------------------------------------------------
-- RAW DATA READERS
-------------------------------------------------------

-- Read the frame-info section for one animation.
-- Returns an array of frameCount entries; each entry is
-- #(dx, dy, dz, dyaw) in world-units (already * 100) / radians.
fn readFrameInfoData fileHandle frameCount frameInfoType =
(
    local frameInfo = #()
    if frameInfoType == frameInfoNone then return frameInfo

    for f = 1 to frameCount do
    (
        local dx   = read.floatB() * 100.0
        local dy   = read.floatB() * 100.0
        local dz   = 0.0
        local dyaw = 0.0

        if frameInfoType == frameInfoDxDyDyaw then
        (
            dyaw = read.floatB()
        )
        else if frameInfoType == frameInfoDxDyDzDyaw then
        (
            dz   = read.floatB() * 100.0
            dyaw = read.floatB()
        )

        append frameInfo #(dx, dy, dz, dyaw)
    )
    frameInfo
)

-- Read the default-data section.
-- For each node the flag bits indicate whether it has per-frame data;
-- nodes that do NOT have per-frame data store a single default value here.
-- Returns an array of nodeCount entries, each #(trans[x,y,z], rot#(i,j,k,w), scale).
fn readDefaultData fileHandle nodeCount transFlags rotFlags scaleFlags =
(
    local defaults = #()

    for n = 1 to nodeCount do
    (
        local trans = [0.0, 0.0, 0.0]
        local rot = point4 0 0 0 1
        local scale = 1.0

        -- Rotation first (tag layout matches old importer order)
        if not (getNodeFlagBit rotFlags n) then
        (
            rot = math.readQuatCompressed()
        )

        -- Translation
        if not (getNodeFlagBit transFlags n) then
        (
            local x = read.floatB() * 100.0
            local y = read.floatB() * 100.0
            local z = read.floatB() * 100.0
            trans = [x, y, z]
        )

        -- Scale
        if not (getNodeFlagBit scaleFlags n) then
        (
            scale = read.floatB()
        )

        append defaults #(trans, rot, scale)
    )
    defaults
)

-- Read the per-frame data section.
-- For each frame and each node: only data for nodes whose flag bit IS set
-- is present; nodes without the bit use their default value.
-- Returns an array of frameCount arrays, each containing nodeCount
-- entries of #(trans, rot, scale).
fn readFrameData fileHandle nodeCount frameCount transFlags rotFlags scaleFlags defaults =
(
    local allFrames = #()

    for f = 1 to frameCount do
    (
        local frameNodes = #()

        for n = 1 to nodeCount do
        (
            local transD = defaults[n][1]
            local trans  = [transD.x, transD.y, transD.z]
            local rotD   = defaults[n][2]
            local rot    = rotD
            local scale  = defaults[n][3]
        if scale == undefined then scale = 1.0
            if getNodeFlagBit rotFlags n then
            (
                rot = math.readQuatCompressed()
            )

            -- Translation
            if getNodeFlagBit transFlags n then
            (
                local x = read.floatB() * 100.0
                local y = read.floatB() * 100.0
                local z = read.floatB() * 100.0
                trans = [x, y, z]
            )

            -- Scale
            if getNodeFlagBit scaleFlags n then
            (
                scale = read.floatB()
            )

            append frameNodes #(trans, rot, scale)
        )

        append allFrames frameNodes
    )
    allFrames
)

-------------------------------------------------------
-- COMPRESSED ANIMATION READER
-- Supports animations with animFlagCompressed set.
-- Binary format is little-endian (unlike the rest of the tag).
-------------------------------------------------------

-- Evaluate a channel value at 0-based frame index `frameIdx` using keyframe data.
-- kfStart / kfEnd : 1-based inclusive indices into kfNums / kfData for this node.
--   kfStart >= kfEnd  → no usable keyframes; always returns defVal.
-- kfNums  : global UInt16 array of frame-index numbers (shared across all nodes).
-- defVal  : value at frame 0 (returned for frame 0 and non-animated nodes).
-- kfData  : global array of decoded channel values matching kfNums positions.
-- blendFn : function(a, b, ratio) that interpolates between two values.
fn getKeyframeValue frameIdx kfStart kfEnd kfNums defVal kfData blendFn =
(
    -- No usable keyframes (kf_ct <= 1) or frame 0 always maps to default.
    if kfStart >= kfEnd or frameIdx == 0 then return defVal

    -- Past (or at) the last stored keyframe: hold the last value.
    local lastFrame = kfNums[kfEnd]
    if frameIdx >= lastFrame then return kfData[kfEnd]

    -- Before the first stored keyframe: blend from default to the first keyframe.
    local firstFrame = kfNums[kfStart]
    if frameIdx < firstFrame then
    (
        if firstFrame == 0 then return defVal
        local ratio = frameIdx as float / firstFrame as float
        return blendFn defVal kfData[kfStart] ratio
    )

    -- Within stored keyframe range: find the surrounding pair.
    -- NOTE: frameIdx >= firstFrame and < lastFrame guarantees a valid pair exists.
    local kf_i = kfStart
    for k = kfStart to (kfEnd - 1) do
    (
        if kfNums[k] <= frameIdx and kfNums[k+1] > frameIdx then
        (
            kf_i = k
            exit
        )
    )

    if frameIdx == kfNums[kf_i] then return kfData[kf_i]

    local span = kfNums[kf_i + 1] - kfNums[kf_i]
    if span == 0 then return kfData[kf_i]
    local ratio = (frameIdx - kfNums[kf_i]) as float / span as float
    blendFn kfData[kf_i] kfData[kf_i + 1] ratio
)

-- Read and decompress a compressed animation's per-frame node data.
-- Parameters:
--   fileHandle              : open file handle
--   frameCount              : number of animation frames to produce
--   nodeCount               : total node count for this animation
--   transFlags / rotFlags / scaleFlags : per-node animation flag arrays
--   frameDataFileOff        : file offset where frame_data blob begins
--   offsetToCompressedData  : byte offset WITHIN frame_data to compressed block
--   fdSize                  : total size of frame_data blob in bytes
-- Returns an array of frameCount arrays, each nodeCount entries of
--   #([x,y,z], #(i,j,k,w), scale), matching the output of readFrameData.
fn readCompressedFrameData fileHandle frameCount nodeCount transFlags rotFlags scaleFlags \
    frameDataFileOff offsetToCompressedData fdSize = (
    local compStart = frameDataFileOff + offsetToCompressedData

    -- Parse the 44-byte little-endian header.
    -- Byte layout (all UInt32 LE, offsets measured from compStart):
    --   [0 .. 11]  rotation offsets  : keyframes, default_data, keyframe_data
    --                                  (rotation keyframe_head is ALWAYS at +44)
    --   [12 .. 27] translation offsets: keyframe_head, keyframes, default_data, keyframe_data
    --   [28 .. 43] scale offsets      : keyframe_head, keyframes, default_data, keyframe_data
    fseek fileHandle compStart #seek_set
    setCurrentFileHandle fileHandle
    local rKfOff  = read.longL()  -- rotation keyframes array
    local rDdOff  = read.longL()  -- rotation default_data array
    local rFdOff  = read.longL()  -- rotation keyframe_data array
    local tKhOff  = read.longL()  -- translation keyframe_head array
    local tKfOff  = read.longL()  -- translation keyframes array
    local tDdOff  = read.longL()  -- translation default_data array
    local tFdOff  = read.longL()  -- translation keyframe_data array
    local sKhOff  = read.longL()  -- scale keyframe_head array
    local sKfOff  = read.longL()  -- scale keyframes array
    local sDdOff  = read.longL()  -- scale default_data array
    local sFdOff  = read.longL()  -- scale keyframe_data array

    -- Rotation keyframe_head always starts at offset 44 from compStart.
    local rKhOff = 44

    -- Count nodes animated per transform type (used for keyframe_head array sizes).
    local nR = 0; local nT = 0; local nS = 0
    for ni = 1 to nodeCount do
    (
        if getNodeFlagBit rotFlags   ni then nR += 1
        if getNodeFlagBit transFlags ni then nT += 1
        if getNodeFlagBit scaleFlags ni then nS += 1
    )

    -- -------------------------------------------------------
    -- Read rotation streams
    -- -------------------------------------------------------

    -- keyframe_head: nR × UInt32 LE at compStart+44.
    -- Each UInt32: bits[11:0] = kf count, bits[31:12] = kf start offset.
    local rotKh = #()
    if nR > 0 then
    (
        fseek fileHandle (compStart + rKhOff) #seek_set
        for i = 1 to nR do append rotKh (read.longL())
    )

    -- keyframes: UInt16 LE array of frame-index numbers.
    local rKfCount  = (rDdOff - rKfOff) / 2
    local rotKfNums = #()
    if rKfCount > 0 then
    (
        fseek fileHandle (compStart + rKfOff) #seek_set
        for i = 1 to rKfCount do append rotKfNums (read.shortL())
    )

    -- default_data: 3 × UInt16 per node (all nodeCount nodes)  →  compressed quat48.
    local rotDdRaw = #()
    fseek fileHandle (compStart + rDdOff) #seek_set
    for i = 1 to (nodeCount * 3) do append rotDdRaw (read.shortL())

    -- keyframe_data: 3 × UInt16 per stored keyframe  →  compressed quat48.
    local rFdCount  = (tKhOff - rFdOff) / 2
    local rotFdRaw  = #()
    if rFdCount > 0 then
    (
        fseek fileHandle (compStart + rFdOff) #seek_set
        for i = 1 to rFdCount do append rotFdRaw (read.shortL())
    )

    -- Decode rotation defaults (one per node) and keyframe values.
    local rotNodeDef = #()
    for ni = 1 to nodeCount do
    (
        local b = (ni - 1) * 3 + 1
        append rotNodeDef (decompressQuaternion rotDdRaw[b] rotDdRaw[b+1] rotDdRaw[b+2])
    )

    local rotKfData = #()
    local numRotKfs = rFdCount / 3
    for ki = 1 to numRotKfs do
    (
        local b = (ki - 1) * 3 + 1
        append rotKfData (decompressQuaternion rotFdRaw[b] rotFdRaw[b+1] rotFdRaw[b+2])
    )

    -- -------------------------------------------------------
    -- Read translation streams
    -- -------------------------------------------------------

    -- keyframe_head: nT × UInt32 LE.
    local transKh = #()
    if nT > 0 then
    (
        fseek fileHandle (compStart + tKhOff) #seek_set
        for i = 1 to nT do append transKh (read.longL())
    )

    -- keyframes: UInt16 LE frame-index array.
    local tKfCount   = (tDdOff - tKfOff) / 2
    local transKfNums = #()
    if tKfCount > 0 then
    (
        fseek fileHandle (compStart + tKfOff) #seek_set
        for i = 1 to tKfCount do append transKfNums (read.shortL())
    )

    -- default_data: 3 × float LE per node (all nodeCount); scaled * 100 to world units.
    local transNodeDef = #()
    fseek fileHandle (compStart + tDdOff) #seek_set
    for ni = 1 to nodeCount do
    (
        local x = read.floatL() * 100.0
        local y = read.floatL() * 100.0
        local z = read.floatL() * 100.0
        append transNodeDef #(x, y, z)
    )

    -- keyframe_data: 3 × float LE per stored keyframe; scaled * 100.
    local tFdCount  = (sKhOff - tFdOff) / 4
    local transKfData = #()
    if tFdCount > 0 then
    (
        fseek fileHandle (compStart + tFdOff) #seek_set
        for ki = 1 to (tFdCount / 3) do
        (
            local x = read.floatL() * 100.0
            local y = read.floatL() * 100.0
            local z = read.floatL() * 100.0
            append transKfData #(x, y, z)
        )
    )

    -- -------------------------------------------------------
    -- Read scale streams
    -- -------------------------------------------------------

    -- keyframe_head: nS × UInt32 LE.
    local scaleKh = #()
    if nS > 0 then
    (
        fseek fileHandle (compStart + sKhOff) #seek_set
        for i = 1 to nS do append scaleKh (read.longL())
    )

    -- keyframes: UInt16 LE frame-index array.
    local sKfCount    = (sDdOff - sKfOff) / 2
    local scaleKfNums = #()
    if sKfCount > 0 then
    (
        fseek fileHandle (compStart + sKfOff) #seek_set
        for i = 1 to sKfCount do append scaleKfNums (read.shortL())
    )

    -- default_data: 1 × float per ANIMATED scale node (nS entries, NOT nodeCount).
    local sDdCount     = (sFdOff - sDdOff) / 4
    local scaleDefaults = #()
    if sDdCount > 0 then
    (
        fseek fileHandle (compStart + sDdOff) #seek_set
        for i = 1 to sDdCount do append scaleDefaults (read.floatL())
    )

    -- keyframe_data: 1 × float per stored keyframe.
    local compSize  = fdSize - offsetToCompressedData
    local sFdCount  = (compSize - sFdOff) / 4
    local scaleKfData = #()
    if sFdCount > 0 then
    (
        fseek fileHandle (compStart + sFdOff) #seek_set
        for i = 1 to sFdCount do append scaleKfData (read.floatL())
    )

    -- -------------------------------------------------------
    -- Pre-compute per-node keyframe range (1-based indices into global arrays).
    -- kfStart >= kfEnd  →  no usable keyframes (treated as static/default).
    -- -------------------------------------------------------
    local nodeRKfStart = #()
    local nodeRKfEnd   = #()
    local nodeTKfStart = #()
    local nodeTKfEnd   = #()
    local nodeSKfStart = #()
    local nodeSKfEnd   = #()
    local nodeSDef     = #()   -- scale default (1.0 for non-animated nodes)

    local ri = 0; local ti = 0; local si = 0
    for ni = 1 to nodeCount do
    (
        if getNodeFlagBit rotFlags ni then
        (
            ri += 1
            local rKhVal  = rotKh[ri]
            local rKfCt   = bit.and rKhVal 0x0FFF
            local rKfOff_ = bit.shift rKhVal -12    -- 0-based start in global rotKfNums
            append nodeRKfStart (rKfOff_ + 1)       -- convert to 1-based
            append nodeRKfEnd   (rKfOff_ + rKfCt)   -- 1-based inclusive end
        )
        else
        (
            append nodeRKfStart 1
            append nodeRKfEnd   0   -- kfStart >= kfEnd → static, always use default
        )

        if getNodeFlagBit transFlags ni then
        (
            ti += 1
            local tKhVal  = transKh[ti]
            local tKfCt   = bit.and tKhVal 0x0FFF
            local tKfOff_ = bit.shift tKhVal -12
            append nodeTKfStart (tKfOff_ + 1)
            append nodeTKfEnd   (tKfOff_ + tKfCt)
        )
        else
        (
            append nodeTKfStart 1
            append nodeTKfEnd   0
        )

        if getNodeFlagBit scaleFlags ni then
        (
            si += 1
            local sKhVal  = scaleKh[si]
            local sKfCt   = bit.and sKhVal 0x0FFF
            local sKfOff_ = bit.shift sKhVal -12
            append nodeSKfStart (sKfOff_ + 1)
            append nodeSKfEnd   (sKfOff_ + sKfCt)
            append nodeSDef     scaleDefaults[si]
        )
        else
        (
            append nodeSKfStart 1
            append nodeSKfEnd   0
            append nodeSDef     1.0
        )
    )

    -- -------------------------------------------------------
    -- Decompress all frames  (outer = frame, inner = node)
    -- -------------------------------------------------------
    local allFrames = #()
    for f = 1 to frameCount do
    (
        local fi        = f - 1   -- 0-based frame index for getKeyframeValue
        local frameNodes = #()

        for ni = 1 to nodeCount do
        (
            -- Rotation: get blended (possibly unnormalized) quaternion, then normalize.
            local rRaw = getKeyframeValue fi nodeRKfStart[ni] nodeRKfEnd[ni] \
                rotKfNums rotNodeDef[ni] rotKfData blendQuaternion
            local rMag2 = rRaw[1]*rRaw[1] + rRaw[2]*rRaw[2] + rRaw[3]*rRaw[3] + rRaw[4]*rRaw[4]
            local rot
            if rMag2 == 0.0 then
                rot = #(0.0, 0.0, 0.0, 1.0)
            else
            (
                local inv = 1.0 / (sqrt rMag2)
                rot = #(rRaw[1]*inv, rRaw[2]*inv, rRaw[3]*inv, rRaw[4]*inv)
            )

            -- Translation: get blended #(x,y,z), convert to Point3.
            local tArr  = getKeyframeValue fi nodeTKfStart[ni] nodeTKfEnd[ni] \
                transKfNums transNodeDef[ni] transKfData blendVector3
            local trans = [tArr[1], tArr[2], tArr[3]]

            -- Scale: get blended float.
            local scale = getKeyframeValue fi nodeSKfStart[ni] nodeSKfEnd[ni] \
                scaleKfNums nodeSDef[ni] scaleKfData blendScalar

            append frameNodes #(trans, rot, scale)
        )

        append allFrames frameNodes
    )

    allFrames
)

-------------------------------------------------------
-- JMA KEYFRAME BUILDER
-------------------------------------------------------

-- Build one jmaKeyframe from a frame's node data, applying the
-- accumulated frame-info offsets to the root node (node index 1).
--
-- accumX/Y/Z  : accumulated translation deltas so far (world units)
-- accumYawRad : accumulated yaw so far (radians)
fn buildFrameKeyframe frameNodes nodeCount accumX accumY accumZ accumYawRad =
(
    local translations = #()
    local rotations    = #()
    local scales       = #()

    for n = 1 to nodeCount do
    (
        local nodeData = frameNodes[n]
        local transD   = nodeData[1]
        local trans    = [transD.x, transD.y, transD.z]
        local rotD     = nodeData[2]
        local rot      = #(rotD[1], rotD[2], rotD[3], rotD[4])
        local scale    = nodeData[3]
        if scale == undefined then scale = 1.0
        -- Apply accumulated frame-info to the root node only
        if n == 1 then
        (
            trans = [trans.x + accumX, trans.y + accumY, trans.z + accumZ]

            if accumYawRad != 0.0 then
            (
                -- Compose yaw rotation around the x-axis (Halo coordinate convention).
                -- Match the old importer: (angleaxis -dyaw [1,0,0]) as quat + frameRot
                local yawDeg  = accumYawRad * (180.0 / pi)
                local yawQ    = (angleaxis (-yawDeg) [1,0,0]) as quat
                local frameQ  = quat rot[1] rot[2] rot[3] rot[4]
                local combined = yawQ + frameQ
                rot = #(combined.x, combined.y, combined.z, combined.w)
            )
        )

        append translations #(trans.x, trans.y, trans.z)
        append rotations    rot
        append scales       scale
    )

    local kf = jmaKeyframes()
    kf.nodeTranslation = translations
    kf.nodeRotation    = rotations
    kf.nodeScale       = scales
    kf
)

-------------------------------------------------------
-- OVERLAY HELPERS
-------------------------------------------------------

-- Find the best base+idle animation to use as a reference pose for an overlay.
-- Returns the 1-based index into animationsBlock, or undefined if none found.
fn findIdleAnimForOverlay overlayName animationsBlock =
(
    local parts = filterString overlayName " "
    local overlayPrefix = if parts.count > 0 then parts[1] else ""

    local bestIdx = undefined

    for i = 1 to animationsBlock.count do
    (
        local ae    = animationsBlock[i]
        local aType = ae.type
        if aType != animTypeBase then continue

        local aName = ae.name as string
        if (findString aName "idle") == undefined then continue

        local aParts  = filterString aName " "
        local aPrefix = if aParts.count > 0 then aParts[1] else ""

        if aPrefix == overlayPrefix then
        (
            bestIdx = i
            exit
        )
        if bestIdx == undefined then bestIdx = i
    )
    bestIdx
)

-- Read the absolute pose of the first frame of animation at animIdx (1-based).
-- Returns array of nodeCount entries, each #(point3_trans, rot_array, scale).
fn readAnimFirstFrame animIdx animationsBlock fileHandle =
(
    local ae          = animationsBlock[animIdx]
    local animNC      = ae.nodeCount
    local aTransFlags = ae.nodeTransFlagData
    local aRotFlags   = ae.nodeRotFlagData
    local aScaleFlags = ae.nodeScaleFlagData
    local ddSz        = ae.defaultDataSize
    local fdSz        = ae.frameDataSize

    -- Compressed animations embed all state in the frame_data blob.
    if bit.get ae.flags animFlagCompressed then
    (
        if fdSz > 0 then
        (
            local cf = readCompressedFrameData fileHandle 1 animNC aTransFlags aRotFlags \
                aScaleFlags ae.frameDataFileOff ae.offsetToCompressedData fdSz
            if cf.count > 0 then return cf[1]
        )
        -- Fallback: identity transforms.
        local fb = #()
        for n = 1 to animNC do append fb #([0,0,0], #(0.0,0.0,0.0,1.0), 1.0)
        return fb
    )

    local iDefaults = #()
    if ddSz > 0 then
    (
        fseek fileHandle ae.defaultDataFileOff #seek_set
        iDefaults = readDefaultData fileHandle animNC aTransFlags aRotFlags aScaleFlags
    )
    else
    (
        for n = 1 to animNC do
            append iDefaults #([0,0,0], #(0.0,0.0,0.0,1.0), 1.0)
    )

    if fdSz > 0 then
    (
        fseek fileHandle ae.frameDataFileOff #seek_set
        local iFrames = readFrameData fileHandle animNC 1 aTransFlags aRotFlags aScaleFlags iDefaults
        if iFrames.count > 0 then return iFrames[1]
    )

    iDefaults
)

-- Multiply two quaternions q1 * q2.  Both are in #(i,j,k,w) order.
fn quatMul q1 q2 =
(
    local x1 = q1[1]; local y1 = q1[2]; local z1 = q1[3]; local w1 = q1[4]
    local x2 = q2[1]; local y2 = q2[2]; local z2 = q2[3]; local w2 = q2[4]
    #(
        w1*x2 + x1*w2 + y1*z2 - z1*y2,
        w1*y2 - x1*z2 + y1*w2 + z1*x2,
        w1*z2 + x1*y2 - y1*x2 + z1*w2,
        w1*w2 - x1*x2 - y1*y2 - z1*z2
    )
)

-- Compose each node of an overlay frame with the idle base pose.
--
-- The overlay binary uses different conventions per component:
--   ROTATION
--     IN rotFlags    : binary stores a DELTA quaternion (identity = no change)
--                      → compose as overlay * idle  (quatMul oRot bRot)
--     NOT in rotFlags: defaultData stores identity → idle stays unchanged
--   TRANSLATION
--     IN transFlags  : binary stores a DELTA from zero       → idle + delta (additive)
--     NOT in transFlags: defaultData stores idle's absolute value → just use idle (ignore raw)
--   SCALE
--     IN scaleFlags  : binary stores scale factor            → idle * factor
--     NOT in scaleFlags: defaultData stores idle's scale     → just use idle
--
-- baseFrame / overlayFrame : nodeCount-length arrays of #(trans, rot, scale)
-- transFlags / rotFlags / scaleFlags : the overlay animation's own flag arrays
fn composeOverlayWithBase baseFrame overlayFrame nodeCount transFlags rotFlags scaleFlags =
(
    local composed = #()
    for n = 1 to nodeCount do
    (
        local bTrans = baseFrame[n][1]
        local bRot   = baseFrame[n][2]
        local bS     = baseFrame[n][3]; if bS == undefined then bS = 1.0
        local oTrans = overlayFrame[n][1]
        local oRot   = overlayFrame[n][2]
        local oS     = overlayFrame[n][3]; if oS == undefined then oS = 1.0

        -- Translation: delta-add for animated nodes; pure idle for static nodes
        local cT = if getNodeFlagBit transFlags n \
            then [bTrans.x + oTrans.x, bTrans.y + oTrans.y, bTrans.z + oTrans.z] \
            else [bTrans.x, bTrans.y, bTrans.z]

        -- Rotation: compose overlay delta onto idle (overlay * idle) for animated nodes;
        -- pure idle for static nodes
        local cR = if getNodeFlagBit rotFlags n \
            then quatMul oRot bRot \
            else #(bRot[1], bRot[2], bRot[3], bRot[4])

        -- Scale: multiplicative for animated nodes; pure idle for static nodes
        local cS = if getNodeFlagBit scaleFlags n then (bS * oS) else bS

        append composed #(cT, cR, cS)
    )
    composed
)

-------------------------------------------------------
-- MAIN EXTRACTOR
-------------------------------------------------------

fn extractModelAnimations tagPath tagDef =
(
    local outputDir = getSavePath caption:"Select output folder for extracted animations"

    if outputDir == undefined then
    (
        logger.warn "Extraction cancelled by user."
        return false
    )

    -- Ensure the chosen directory exists (user may have typed a new path)
    makeDir outputDir all:true

    -- Open tag file
    local fileHandle = fopen tagPath "rb"
    if fileHandle == undefined then
    (
        logger.error "Cannot open tag file: {}" args:#(tagPath)
        return false
    )
    setCurrentFileHandle fileHandle
    setTagMemoryBaseAddress 0x40440000
    fseek fileHandle 64 #seek_set

    local totalStartTime = timestamp()

    logger.info "Parsing model_animations tag..."
    local parseStartTime = timestamp()
    local parsedEntry = readTag tagDef
    if parsedEntry == undefined then
    (
        logger.error "Parser failed | cannot extract animations."
        fclose fileHandle
        return false
    )
    local tagResult = convertAntrData parsedEntry
    logger.info "Tag parse: {} ms" args:#(timestamp() - parseStartTime)

    local nodesBlock      = tagResult[1]
    local animationsBlock = tagResult[2]

    local nodeCount = nodesBlock.count
    logger.info "Nodes: {}, Animations: {}\n" args:#(nodeCount, animationsBlock.count)

    -- Build the shared JMA node list from the tag's node block
    local jmaNodeList = #()
    if nodeCount > 0 then
    (
        for nodeEntry in nodesBlock do
        (
            local jn = jmaNodes()
            jn.nodeName             = nodeEntry.name
            jn.firstChildNodeIndex  = nodeEntry.firstChildNodeIndex
            jn.nextSiblingNodeIndex = nodeEntry.nextSiblingNodeIndex
            append jmaNodeList jn
        )
    )
    else
    (
        -- Tag has no nodes block: look up hardcoded retail fallback.
        -- Use the nodeCount and checksum stored in the first animation entry.
        if animationsBlock.count > 0 then
        (
            local fbCount    = animationsBlock[1].nodeCount
            local fbChecksum = animationsBlock[1].nodeListChecksum
            local fbRaw      = getAntrFallbackNodes fbCount fbChecksum
            if fbRaw != undefined then
            (
                logger.warn "No nodes block in tag"
                logger.info "Using hardcoded fallback: nodes: {}  checksum: {}\n" args:#(fbCount, fbChecksum)
                for nd in fbRaw do
                (
                    local jn = jmaNodes()
                    jn.nodeName             = nd[1]
                    jn.firstChildNodeIndex  = nd[2]
                    jn.nextSiblingNodeIndex = nd[3]
                    append jmaNodeList jn
                )
            )
            else
            (
                logger.error "Tag has no nodes and no fallback found (count={}, checksum={})." \
                    args:#(fbCount, fbChecksum)
                fclose fileHandle
                return false
            )
        )
        else
        (
            logger.error "Tag has no nodes and no animations | cannot extract."
            fclose fileHandle
            return false
        )
    )

    -- Also read the tag-level nodeListChecksum for use when per-animation
    -- checksum is 0 (some tools omit it on individual animations).
    -- We'll fall back to the first animation's checksum if needed.

    local extracted = 0
    local skipped   = 0
    local total     = animationsBlock.count

    local totalExtractMs = 0
    local totalWriteMs   = 0

    --ProgressStart "Extracting animations..."

    for animIdx = 1 to total do
    (
        local animEntry = animationsBlock[animIdx]

        local animName      = animEntry.name
        local animType      = animEntry.type
        local frameCount    = animEntry.frameCount
        local frameInfoType = animEntry.frameInfoType
        local nodeChecksum  = animEntry.nodeListChecksum
        local animNodeCount = animEntry.nodeCount
        local animFlags     = animEntry.flags

        local transFlags    = animEntry.nodeTransFlagData
        local rotFlags      = animEntry.nodeRotFlagData
        local scaleFlags    = animEntry.nodeScaleFlagData

        -- Skip animations with no useful node count
        if animNodeCount == 0 then
        (
            logger.warn "Skipping '{}': nodeCount is 0." args:#(animName)
            skipped += 1
            --ProgressUpdate (animIdx as float / total * 100.0)
            continue
        )

        local frameInfoSize    = animEntry.frameInfoSize
        local defaultDataSize  = animEntry.defaultDataSize
        local frameDataSize    = animEntry.frameDataSize

        local frameInfoFileOff   = animEntry.frameInfoFileOff
        local defaultDataFileOff = animEntry.defaultDataFileOff
        local frameDataFileOff   = animEntry.frameDataFileOff

        logger.log "=== EXTRACT ANIMATION SOURCE ==="
        logger.info "[{}/{}] '{}' | type = {} | frameInfoType = {} | frames = {}" args:#(\
            animIdx, total, animName, animType, frameInfoType, frameCount)

        local animExtractStart = timestamp()

        -- Read frame info
        local frameInfo = #()
        if frameInfoSize > 0 and frameInfoType != frameInfoNone then
        (
            fseek fileHandle frameInfoFileOff #seek_set
            frameInfo = readFrameInfoData fileHandle frameCount frameInfoType
        )

        -- OVERLAY: find the idle base pose to compose with each overlay frame.
        -- The overlay tag stores delta transforms relative to identity.
        -- We compose every frame: cTrans = idleTrans + overlayDelta, cRot = idleRot * overlayDelta.
        local idleBaseFrame = undefined
        if animType == animTypeOverlay then
        (
            local idleIdx = findIdleAnimForOverlay animName animationsBlock
            if idleIdx != undefined then
            (
                logger.info "Using '{}' as idle base for overlay '{}'" args:#(\
                    animationsBlock[idleIdx].name, animName)
                idleBaseFrame = readAnimFirstFrame idleIdx animationsBlock \
                    fileHandle
            )
            else
            (
                logger.warn "No idle base found for overlay '{}' | using animation defaults." args:#(animName)
            )
        )

        -- Read default data and per-frame data.
        -- Compressed animations embed all node state in the frame_data blob.
        local defaults = #()
        local frames   = #()

        if bit.get animFlags animFlagCompressed then
        (
            -- Decompress all frameCount frames from the compressed block.
            if frameDataSize > 0 then
                frames = readCompressedFrameData fileHandle frameCount animNodeCount \
                    transFlags rotFlags scaleFlags frameDataFileOff \
                    animEntry.offsetToCompressedData frameDataSize

            -- Frame[1] at fi=0 always holds the default (rest) pose for compressed
            -- animations.  Use it as the stand-in for `defaults` so the overlay
            -- pre-pend logic and the rest of the pipeline work unmodified.
            if frames.count > 0 then
                defaults = frames[1]
            else
            (
                for n = 1 to animNodeCount do
                    append defaults #([0,0,0], #(0.0,0.0,0.0,1.0), 1.0)
            )
        )
        else
        (
            -- Uncompressed path (original logic).
            if defaultDataSize > 0 then
            (
                fseek fileHandle defaultDataFileOff #seek_set
                defaults = readDefaultData fileHandle animNodeCount transFlags rotFlags scaleFlags
            )
            else
            (
                -- No default data: fill with identity transforms.
                for n = 1 to animNodeCount do
                    append defaults #([0,0,0], #(0.0,0.0,0.0,1.0), 1.0)
            )

            if frameDataSize > 0 then
            (
                fseek fileHandle frameDataFileOff #seek_set
                frames = readFrameData fileHandle animNodeCount frameCount \
                    transFlags rotFlags scaleFlags defaults
            )
            else
            (
                -- No frame data: every frame is the default pose.
                -- All frames are identical so we just reference defaults directly;
                -- frame data is never mutated after this point.
                for f = 1 to frameCount do
                    append frames defaults
            )
        )

        -- Determine output extension
        local ext    = getAnimExtension animType frameInfoType animFlags
        --local outFile = outputDir + "\\" + animName + "." + ext
        local filename = animName + "." + ext
        local outFile = pathConfig.appendPath outputDir filename

        -- Build JMA structure
        -- Total frames written  = frameCount actual frames  + 1 extra
        -- (overlay prepends a default frame; base/replacement appends a looping frame)
        local jmaData = jmaFile()
        jmaData.jmaVersion      = 16392
        jmaData.frameCount      = frameCount + 1
        jmaData.frameRate       = 30
        jmaData.actorNamesIndex = 1
        jmaData.actorNames      = "unnamedActor"
        jmaData.nodeCount       = animNodeCount
        jmaData.nodeChecksum    = 0 --nodeChecksum
        jmaData.nodes           = jmaNodeList

        local keyframes = #()

        -- OVERLAY: prepend the idle base as frame 0 so the import starts at the rest pose.
        if animType == animTypeOverlay then
        (
            -- Frame 0: the base pose (idle first frame, or animation defaults as fallback)
            local baseSource = if idleBaseFrame != undefined then idleBaseFrame else defaults
            local defTranslations = #()
            local defRotations    = #()
            local defScales       = #()
            for n = 1 to animNodeCount do
            (
                local d = baseSource[n]
                local s = d[3]; if s == undefined then s = 1.0
                append defTranslations #(d[1].x, d[1].y, d[1].z)
                append defRotations    #(d[2][1], d[2][2], d[2][3], d[2][4])
                append defScales       s
            )
            local defKf = jmaKeyframes()
            defKf.nodeTranslation = defTranslations
            defKf.nodeRotation    = defRotations
            defKf.nodeScale       = defScales
            append keyframes defKf
        )

        -- Frame-info accumulation state
        local accumX   = 0.0
        local accumY   = 0.0
        local accumZ   = 0.0
        local accumYaw = 0.0

        -- Write each actual frame.
        -- For overlays: compose each frame with the idle base pose using flag-aware rules.
        -- See composeOverlayWithBase for the per-component conventions.
        for f = 1 to frameCount do
        (
            local frameData = if (animType == animTypeOverlay and idleBaseFrame != undefined) then \
                (composeOverlayWithBase idleBaseFrame frames[f] animNodeCount transFlags rotFlags scaleFlags) \
                else frames[f]

            append keyframes (buildFrameKeyframe frameData animNodeCount \
                accumX accumY accumZ accumYaw)

            -- Accumulate deltas for the next frame
            if f <= frameInfo.count then
            (
                accumX   += frameInfo[f][1]
                accumY   += frameInfo[f][2]
                accumZ   += frameInfo[f][3]
                accumYaw += frameInfo[f][4]
            )
        )

        -- BASE / REPLACEMENT: append a looping base frame
        -- (copy of frame[1] with the full accumulated frame-info offset applied)
        if animType == animTypeBase or animType == animTypeReplacement then
        (
            append keyframes (buildFrameKeyframe frames[1] animNodeCount \
                accumX accumY accumZ accumYaw)
        )

        jmaData.keyframes = keyframes

        local animExtractMs = timestamp() - animExtractStart
        totalExtractMs += animExtractMs

        -- Sanity-check before writing
        logger.debug "keyframes: {} | nodeCount: {}" args:#(
            keyframes.count,
            if keyframes.count > 0 then keyframes[1].nodeTranslation.count else 0)

        -- Write file
        local result = writeJmaFile outFile jmaData
        local animWriteMs = result[2]
        totalWriteMs += animWriteMs

        logger.info "Extract: {} ms | Write: {} ms\n" args:#(animExtractMs, animWriteMs)

        if result[1] then
        (
            extracted += 1
        )
        else
        (
            logger.error "Failed to write: {}" args:#(outFile)
            skipped += 1
        )

        --ProgressUpdate (animIdx as float / total * 100.0)
    )

    --ProgressEnd()
    fclose fileHandle

    local totalMs   = timestamp() - totalStartTime
    local parseMs   = totalMs - totalExtractMs - totalWriteMs
    logger.log "=== TIMING  parse = {} ms | extract = {} ms | write = {} ms | TOTAL = {} ms ({} sec) ===" args:#(\
        parseMs, totalExtractMs, totalWriteMs, totalMs, (totalMs / 1000.0))
    logger.log "=== EXTRACTION COMPLETE: extracted = {} skipped = {} ===\n\n" args:#(extracted, skipped)
    
    local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true
    if showDialogs then
    (
        messageBox ("Extraction complete!\n\nExtracted: " + extracted as string + \
            "\nSkipped:   " + skipped as string + \
            "\n\nTotal time: " + (totalMs / 1000.0) as string + " sec") title:"Animation Extractor"
    )
    true
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)