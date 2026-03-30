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
fn readAnimFirstFrame animIdx animationsBlock animDataOffsets fileHandle =
(
    local ae          = animationsBlock[animIdx]
    local animNC      = ae.nodeCount
    local aTransFlags = ae.nodeTransFlagData
    local aRotFlags   = ae.nodeRotFlagData
    local aScaleFlags = ae.nodeScaleFlagData
    local ddSz        = ae.defaultDataSize
    local fdSz        = ae.frameDataSize
    local offsets     = animDataOffsets[animIdx]

    local iDefaults = #()
    if ddSz > 0 then
    (
        fseek fileHandle offsets[2] #seek_set
        iDefaults = readDefaultData fileHandle animNC aTransFlags aRotFlags aScaleFlags
    )
    else
    (
        for n = 1 to animNC do
            append iDefaults #([0,0,0], #(0.0,0.0,0.0,1.0), 1.0)
    )

    if fdSz > 0 then
    (
        fseek fileHandle offsets[3] #seek_set
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

    local totalStartTime = timestamp()

    logger.info "Parsing model_animations tag..."
    local parseStartTime = timestamp()
    local tagResult = readAntrTagDirect fileHandle
    logger.info "Tag parse: {} ms" args:#(timestamp() - parseStartTime)

    if tagResult == undefined then
    (
        logger.error "readAntrTagDirect failed | cannot extract animations."
        fclose fileHandle
        return false
    )

    local nodesBlock      = tagResult[1]
    local animationsBlock = tagResult[2]
    local rawDataBase     = tagResult[3]
    logger.info "Raw data section begins at file offset: '{}'" args:#(rawDataBase)

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

    -- Pre-compute sequential file offsets for each animation's three data blobs.
    -- Layout per animation: [frameInfo][defaultData][frameData] packed end-to-end.
    local animDataOffsets = #()
    local runningOffset   = rawDataBase
    for aIdx = 1 to animationsBlock.count do
    (
        local ae    = animationsBlock[aIdx]
        local fiSz  = ae.frameInfoSize
        local ddSz  = ae.defaultDataSize
        local fdSz  = ae.frameDataSize
        append animDataOffsets #(runningOffset, runningOffset + fiSz, runningOffset + fiSz + ddSz)
        runningOffset += fiSz + ddSz + fdSz
    )

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

        -- Skip compressed animations (decompression not yet implemented)
        if bit.get animFlags animFlagCompressed then
        (
            logger.warn "Skipping '{}': compressed data not yet supported." args:#(animName)
            skipped += 1
            --ProgressUpdate (animIdx as float / total * 100.0)
            continue
        )

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

        local animOffsets        = animDataOffsets[animIdx]
        local frameInfoFileOff   = animOffsets[1]
        local defaultDataFileOff = animOffsets[2]
        local frameDataFileOff   = animOffsets[3]

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
                    animDataOffsets fileHandle
            )
            else
            (
                logger.warn "No idle base found for overlay '{}' | using animation defaults." args:#(animName)
            )
        )

        -- Read default data
        local defaults = #()
        if defaultDataSize > 0 then
        (
            fseek fileHandle defaultDataFileOff #seek_set
            defaults = readDefaultData fileHandle animNodeCount transFlags rotFlags scaleFlags
        )
        else
        (
            -- No default data: fill with identity transforms
            for n = 1 to animNodeCount do
                append defaults #([0,0,0], #(0.0,0.0,0.0,1.0), 1.0)
        )

        -- Read per-frame data
        local frames = #()
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