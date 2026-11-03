-- model_animations -> JMA/JMO/JMR/... source files, one per animation (same output as the
-- previous MAXScript extractor). options: { output folder [, "3,7,12": only those (1-based)] }.
-- Writes a summary that
-- pipeline\extract_model_animations\animation_extractor.ms reads.
-- Math is rounded to 32-bit floats like MAXScript, so the text matches the old files.
local bit = require "bit" -- LuaJIT: bit operations on 32-bit integers
local tagReader = require "tags.tag_reader"
local maxNumbers = require "formats.max_numbers"
local jma = require "formats.jma"
local fallbackNodes = require "importers.shared.fallback_nodes"

local band, bor, rshift, lshift = bit.band, bit.bor, bit.rshift, bit.lshift
local sqrt = math.sqrt

local modelAnimations = {group = "model_animations", version = 2}

-- Rounds to a 32-bit float (MAXScript Float)
local f32 = maxNumbers.f32

-- Values of the tag's "type" and "frame info type" fields
local animationTypes = {base = 0, overlay = 1, replacement = 2}
local frameInfoTypes = {none = 0, dxdy = 1, dxdyDyaw = 2, dxdyDzDyaw = 3}

-- Message levels for animation_extractor.ms
local logLevel = {info = 1, warning = 2, error = 3}

-- π rounded to a 32-bit float, as MAXScript has it
local pi = f32(math.pi)

-- Reader over the tag file bytes (tagReader.openBytes), set in write
local dataReader

-------------------------------------------------------------------------------
-- Helpers (same math as the previous MAXScript extractor)
-------------------------------------------------------------------------------

-- Bit nodeIndex (1-based) of the two int32 node flag words
local function nodeFlag(flags, nodeIndex)
    if nodeIndex <= 32 then
        return band(flags[1], lshift(1, nodeIndex - 1)) ~= 0
    end
    if nodeIndex <= 64 then
        return band(flags[2], lshift(1, nodeIndex - 33)) ~= 0
    end
    return false
end

-- File extension of an animation from its type, frame info and world-relative flag
local function extension(anim)
    local worldRelative = band(anim.flags, 2) ~= 0
    local animType, infoType = anim.type, anim.frameInfoType
    if animType == animationTypes.replacement then
        return "JMR"
    elseif animType == animationTypes.overlay then
        return "JMO"
    elseif animType == animationTypes.base and infoType == frameInfoTypes.none and worldRelative then
        return "JMW"
    elseif animType == animationTypes.base and infoType == frameInfoTypes.dxdy then
        return "JMA"
    elseif animType == animationTypes.base and infoType == frameInfoTypes.dxdyDyaw then
        return "JMT"
    elseif animType == animationTypes.base and infoType == frameInfoTypes.dxdyDzDyaw then
        return "JMZ"
    end
    return "JMM"
end

-- Normalized { i, j, k, w }; identity when the length is 0
local function normalizeQuat(i, j, k, w)
    local lengthSquared = f32(f32(f32(f32(i * i) + f32(j * j)) + f32(k * k)) + f32(w * w))
    if lengthSquared == 0 then
        return {0, 0, 0, 1}
    end
    local inverseLength = f32(1 / f32(sqrt(lengthSquared)))
    return {
        f32(i * inverseLength),
        f32(j * inverseLength),
        f32(k * inverseLength),
        f32(w * inverseLength)
    }
end

-- Uncompressed tag quaternion: 4 x int16 / 32767
local function readQuat()
    local i = f32(dataReader:beI16() / 32767)
    local j = f32(dataReader:beI16() / 32767)
    local k = f32(dataReader:beI16() / 32767)
    local w = f32(dataReader:beI16() / 32767)
    return normalizeQuat(i, j, k, w)
end

-- Compressed quaternion: four 12-bit signed values packed into three 16-bit words
local function decompressQuat(word0, word1, word2)
    local w = band(word2, 0x0FFF)
    local k = bor(rshift(word2, 12), lshift(band(word1, 0x00FF), 4))
    local j = bor(rshift(word1, 8), lshift(band(word0, 0x000F), 8))
    local i = rshift(word0, 4)
    if band(w, 0x800) ~= 0 then
        w = w - 4095
    end
    if band(k, 0x800) ~= 0 then
        k = k - 4095
    end
    if band(j, 0x800) ~= 0 then
        j = j - 4095
    end
    if band(i, 0x800) ~= 0 then
        i = i - 4095
    end
    local lengthSquared = f32(f32(f32(i * i + j * j) + k * k) + w * w)
    if lengthSquared == 0 then
        return {0, 0, 0, 1}
    end
    local inverseLength = f32(1 / f32(sqrt(lengthSquared)))
    return {
        f32(i * inverseLength),
        f32(j * inverseLength),
        f32(k * inverseLength),
        f32(w * inverseLength)
    }
end

-- Blends with anti-flip; result is not normalized (the caller does it)
local function blendQuat(a, b, ratio)
    local weightA, weightB = f32(1 - ratio), ratio
    local dot = f32(f32(f32(f32(a[1] * b[1]) + f32(a[2] * b[2])) + f32(a[3] * b[3])) +
                        f32(a[4] * b[4]))
    if dot < 0 then
        weightB = -weightB
    end
    return {
        f32(f32(a[1] * weightA) + f32(b[1] * weightB)),
        f32(f32(a[2] * weightA) + f32(b[2] * weightB)),
        f32(f32(a[3] * weightA) + f32(b[3] * weightB)),
        f32(f32(a[4] * weightA) + f32(b[4] * weightB))
    }
end

local function clamp01(ratio)
    return ratio < 0 and 0 or (ratio > 1 and 1 or ratio)
end

local function blendVec3(a, b, ratio)
    local weightB = clamp01(ratio)
    local weightA = f32(1 - weightB)
    return {
        f32(f32(a[1] * weightA) + f32(b[1] * weightB)),
        f32(f32(a[2] * weightA) + f32(b[2] * weightB)),
        f32(f32(a[3] * weightA) + f32(b[3] * weightB))
    }
end

local function blendScalar(a, b, ratio)
    local weightB = clamp01(ratio)
    return f32(f32(a * f32(1 - weightB)) + f32(b * weightB))
end

-- Hamilton product q1 * q2, both { i, j, k, w }
local function quatMul(q1, q2)
    local x1, y1, z1, w1 = q1[1], q1[2], q1[3], q1[4]
    local x2, y2, z2, w2 = q2[1], q2[2], q2[3], q2[4]
    return {
        f32(f32(f32(f32(w1 * x2) + f32(x1 * w2)) + f32(y1 * z2)) - f32(z1 * y2)),
        f32(f32(f32(f32(w1 * y2) - f32(x1 * z2)) + f32(y1 * w2)) + f32(z1 * x2)),
        f32(f32(f32(f32(w1 * z2) + f32(x1 * y2)) - f32(y1 * x2)) + f32(z1 * w2)),
        f32(f32(f32(f32(w1 * w2) - f32(x1 * x2)) - f32(y1 * y2)) - f32(z1 * z2))
    }
end

-- A node pose: { trans = {x,y,z}, rot = {i,j,k,w}, scale }
local function identityPose()
    return {trans = {0, 0, 0}, rot = {0, 0, 0, 1}, scale = 1}
end

-- Three big-endian floats * 100 (Halo units -> JMA units)
local function scaledVec3Be()
    local x = f32(dataReader:beFloat() * 100)
    local y = f32(dataReader:beFloat() * 100)
    local z = f32(dataReader:beFloat() * 100)
    return {x, y, z}
end

-- Integer division truncating toward zero, like MAXScript's int / int
local function intDivide(a, b)
    local q = a / b
    return q >= 0 and math.floor(q) or math.ceil(q)
end

-------------------------------------------------------------------------------
-- Uncompressed data
-------------------------------------------------------------------------------

-- Per frame { dx, dy, dz, dyaw } (translation * 100, yaw in radians)
local function readFrameInfo(anim)
    local info = {}
    if anim.frameInfoType == frameInfoTypes.none or anim.frameInfo.size == 0 then
        return info
    end
    dataReader:seek(anim.frameInfo.offset)
    for frameIndex = 1, anim.frameCount do
        local dx = f32(dataReader:beFloat() * 100)
        local dy = f32(dataReader:beFloat() * 100)
        local dz, dyaw = 0, 0
        if anim.frameInfoType == frameInfoTypes.dxdyDyaw then
            dyaw = dataReader:beFloat()
        elseif anim.frameInfoType == frameInfoTypes.dxdyDzDyaw then
            dz = f32(dataReader:beFloat() * 100)
            dyaw = dataReader:beFloat()
        end
        info[frameIndex] = {dx, dy, dz, dyaw}
    end
    return info
end

-- Nodes without per-frame data store their single value here (rotation, translation, scale)
local function readDefaults(anim)
    local defaults = {}
    for nodeIndex = 1, anim.nodeCount do
        local pose = identityPose()
        if not nodeFlag(anim.rotFlags, nodeIndex) then
            pose.rot = readQuat()
        end
        if not nodeFlag(anim.transFlags, nodeIndex) then
            pose.trans = scaledVec3Be()
        end
        if not nodeFlag(anim.scaleFlags, nodeIndex) then
            pose.scale = dataReader:beFloat()
        end
        defaults[nodeIndex] = pose
    end
    return defaults
end

-- Every frame: animated nodes are read, the others copy their default
local function readFrames(anim, defaults, frameCount)
    local frames = {}
    for frameIndex = 1, frameCount do
        local nodes = {}
        for nodeIndex = 1, anim.nodeCount do
            local defaultPose = defaults[nodeIndex]
            local pose = {
                trans = {defaultPose.trans[1], defaultPose.trans[2], defaultPose.trans[3]},
                rot = defaultPose.rot,
                scale = defaultPose.scale
            }
            if nodeFlag(anim.rotFlags, nodeIndex) then
                pose.rot = readQuat()
            end
            if nodeFlag(anim.transFlags, nodeIndex) then
                pose.trans = scaledVec3Be()
            end
            if nodeFlag(anim.scaleFlags, nodeIndex) then
                pose.scale = dataReader:beFloat()
            end
            nodes[nodeIndex] = pose
        end
        frames[frameIndex] = nodes
    end
    return frames
end

-------------------------------------------------------------------------------
-- Compressed data (little-endian block inside frame data)
-------------------------------------------------------------------------------

-- Value at a 0-based frame from a node's keys firstKey..lastKey (1-based, inclusive).
-- keyFrames: frame number of each key; keyValues: value of each key.
local function keyframeValue(frame, firstKey, lastKey, keyFrames, default, keyValues, blend)
    if firstKey >= lastKey or frame == 0 then
        return default
    end
    if frame >= keyFrames[lastKey] then
        return keyValues[lastKey]
    end
    local firstFrame = keyFrames[firstKey]
    if frame < firstFrame then
        if firstFrame == 0 then
            return default
        end
        return blend(default, keyValues[firstKey], f32(frame / firstFrame))
    end
    local key = firstKey
    for i = firstKey, lastKey - 1 do
        if keyFrames[i] <= frame and keyFrames[i + 1] > frame then
            key = i;
            break
        end
    end
    if frame == keyFrames[key] then
        return keyValues[key]
    end
    local span = keyFrames[key + 1] - keyFrames[key]
    if span == 0 then
        return keyValues[key]
    end
    return blend(keyValues[key], keyValues[key + 1], f32((frame - keyFrames[key]) / span))
end

-- Key ranges per node from the keyframe_head words: low 12 bits count, high bits first key
local function keyframeRanges(anim, flags, heads)
    local starts, ends, headIndex = {}, {}, 0
    for nodeIndex = 1, anim.nodeCount do
        if nodeFlag(flags, nodeIndex) then
            headIndex = headIndex + 1
            local count = band(heads[headIndex], 0x0FFF)
            local first = rshift(heads[headIndex], 12)
            starts[nodeIndex], ends[nodeIndex] = first + 1, first + count
        else
            starts[nodeIndex], ends[nodeIndex] = 1, 0
        end
    end
    return starts, ends
end

-- The compressed block has a 44-byte header with the offset of each section (relative to the
-- block start): per channel (rotation, translation, scale) the keyframe heads, the frame number
-- of each key, the default values and the key values.
local function readCompressedFrames(anim, frameCount)
    local compressedStart = anim.frameData.offset + anim.offsetToCompressed
    dataReader:seek(compressedStart)
    local rotKeyframesAt, rotDefaultsAt, rotDataAt = dataReader:leI32(), dataReader:leI32(),
                                                     dataReader:leI32()
    local transHeadsAt, transKeyframesAt, transDefaultsAt, transDataAt = dataReader:leI32(),
                                                                         dataReader:leI32(),
                                                                         dataReader:leI32(),
                                                                         dataReader:leI32()
    local scaleHeadsAt, scaleKeyframesAt, scaleDefaultsAt, scaleDataAt = dataReader:leI32(),
                                                                         dataReader:leI32(),
                                                                         dataReader:leI32(),
                                                                         dataReader:leI32()
    local rotHeadsAt = 44 -- rotation keyframe heads always follow the 44-byte header

    local rotNodeCount, transNodeCount, scaleNodeCount = 0, 0, 0
    for nodeIndex = 1, anim.nodeCount do
        if nodeFlag(anim.rotFlags, nodeIndex) then
            rotNodeCount = rotNodeCount + 1
        end
        if nodeFlag(anim.transFlags, nodeIndex) then
            transNodeCount = transNodeCount + 1
        end
        if nodeFlag(anim.scaleFlags, nodeIndex) then
            scaleNodeCount = scaleNodeCount + 1
        end
    end

    -- count values read with readValue (a reader function) from a section
    local function readList(offset, count, readValue)
        local list = {}
        dataReader:seek(compressedStart + offset)
        for i = 1, count do
            list[i] = readValue(dataReader)
        end
        return list
    end

    -- Rotation
    local rotHeads = readList(rotHeadsAt, rotNodeCount, dataReader.leI32)
    local rotKeyframes = readList(rotKeyframesAt, intDivide(rotDefaultsAt - rotKeyframesAt, 2),
                                  dataReader.leU16)
    local words = readList(rotDefaultsAt, anim.nodeCount * 3, dataReader.leU16)
    local rotDefaults = {}
    for nodeIndex = 1, anim.nodeCount do
        local at = (nodeIndex - 1) * 3
        rotDefaults[nodeIndex] = decompressQuat(words[at + 1], words[at + 2], words[at + 3])
    end
    local rotWordCount = intDivide(transHeadsAt - rotDataAt, 2)
    words = readList(rotDataAt, rotWordCount, dataReader.leU16)
    local rotData = {}
    for key = 1, intDivide(rotWordCount, 3) do
        local at = (key - 1) * 3
        rotData[key] = decompressQuat(words[at + 1], words[at + 2], words[at + 3])
    end

    -- Translation (* 100)
    local transHeads = readList(transHeadsAt, transNodeCount, dataReader.leI32)
    local transKeyframes = readList(transKeyframesAt,
                                    intDivide(transDefaultsAt - transKeyframesAt, 2),
                                    dataReader.leU16)
    local function leVec3(input)
        local x = f32(input:leFloat() * 100)
        local y = f32(input:leFloat() * 100)
        local z = f32(input:leFloat() * 100)
        return {x, y, z}
    end
    local transDefaults = readList(transDefaultsAt, anim.nodeCount, leVec3)
    local transData = readList(transDataAt, intDivide(intDivide(scaleHeadsAt - transDataAt, 4), 3),
                               leVec3)

    -- Scale: the defaults list only has the animated scale nodes
    local scaleHeads = readList(scaleHeadsAt, scaleNodeCount, dataReader.leI32)
    local scaleKeyframes = readList(scaleKeyframesAt,
                                    intDivide(scaleDefaultsAt - scaleKeyframesAt, 2),
                                    dataReader.leU16)
    local animatedScaleDefaults = readList(scaleDefaultsAt,
                                           intDivide(scaleDataAt - scaleDefaultsAt, 4),
                                           dataReader.leFloat)
    local compressedSize = anim.frameData.size - anim.offsetToCompressed
    local scaleData = readList(scaleDataAt, intDivide(compressedSize - scaleDataAt, 4),
                               dataReader.leFloat)

    local rotStart, rotEnd = keyframeRanges(anim, anim.rotFlags, rotHeads)
    local transStart, transEnd = keyframeRanges(anim, anim.transFlags, transHeads)
    local scaleStart, scaleEnd = keyframeRanges(anim, anim.scaleFlags, scaleHeads)
    local scaleDefaults, scaleIndex = {}, 0
    for nodeIndex = 1, anim.nodeCount do
        if nodeFlag(anim.scaleFlags, nodeIndex) then
            scaleIndex = scaleIndex + 1
            scaleDefaults[nodeIndex] = animatedScaleDefaults[scaleIndex]
        else
            scaleDefaults[nodeIndex] = 1
        end
    end

    local frames = {}
    for frameIndex = 1, frameCount do
        local frame = frameIndex - 1
        local nodes = {}
        for nodeIndex = 1, anim.nodeCount do
            local rot = keyframeValue(frame, rotStart[nodeIndex], rotEnd[nodeIndex], rotKeyframes,
                                      rotDefaults[nodeIndex], rotData, blendQuat)
            local trans = keyframeValue(frame, transStart[nodeIndex], transEnd[nodeIndex],
                                        transKeyframes, transDefaults[nodeIndex], transData,
                                        blendVec3)
            nodes[nodeIndex] = {
                trans = {trans[1], trans[2], trans[3]},
                rot = normalizeQuat(rot[1], rot[2], rot[3], rot[4]),
                scale = keyframeValue(frame, scaleStart[nodeIndex], scaleEnd[nodeIndex],
                                      scaleKeyframes, scaleDefaults[nodeIndex], scaleData,
                                      blendScalar)
            }
        end
        frames[frameIndex] = nodes
    end
    return frames
end

-------------------------------------------------------------------------------
-- Poses per animation
-------------------------------------------------------------------------------

local function isCompressed(anim)
    return band(anim.flags, 1) ~= 0
end

local function identityFrame(anim)
    local frame = {}
    for nodeIndex = 1, anim.nodeCount do
        frame[nodeIndex] = identityPose()
    end
    return frame
end

-- Returns defaults (rest pose) and frames
local function readPoses(anim, frameCount)
    if isCompressed(anim) then
        local frames = {}
        if anim.frameData.size > 0 then
            frames = readCompressedFrames(anim, frameCount)
        end
        return frames[1] or identityFrame(anim), frames
    end
    local defaults
    if anim.defaultData.size > 0 then
        dataReader:seek(anim.defaultData.offset)
        defaults = readDefaults(anim)
    else
        defaults = identityFrame(anim)
    end
    local frames = {}
    if anim.frameData.size > 0 then
        dataReader:seek(anim.frameData.offset)
        frames = readFrames(anim, defaults, frameCount)
    else
        for frameIndex = 1, frameCount do
            frames[frameIndex] = defaults
        end
    end
    return defaults, frames
end

-- First frame of a base animation, used as the rest pose under an overlay
local function firstFrame(anim)
    if isCompressed(anim) then
        if anim.frameData.size > 0 then
            local frames = readCompressedFrames(anim, 1)
            if frames[1] then
                return frames[1]
            end
        end
        return identityFrame(anim)
    end
    local defaults, frames = readPoses(anim, 1)
    if anim.frameData.size > 0 and frames[1] then
        return frames[1]
    end
    return defaults
end

-- Base idle animation for an overlay: same first word ("alert", "stand"...) preferred
local function findIdle(overlay, animations)
    local prefix = (overlay.name:match("^ *([^ ]+)") or ""):lower()
    local best
    for i, candidate in ipairs(animations) do
        if candidate.type == animationTypes.base and candidate.name:find("idle", 1, true) then
            if (candidate.name:match("^ *([^ ]+)") or ""):lower() == prefix then
                return i
            end
            best = best or i
        end
    end
    return best
end

-- Overlay delta on the idle pose (see the previous composeOverlayWithBase)
local function composeOverlay(base, overlay, anim)
    local composed = {}
    for nodeIndex = 1, anim.nodeCount do
        local basePose, overlayPose = base[nodeIndex], overlay[nodeIndex]
        local baseTrans = basePose.trans
        local trans = nodeFlag(anim.transFlags, nodeIndex) and {
            f32(baseTrans[1] + overlayPose.trans[1]),
            f32(baseTrans[2] + overlayPose.trans[2]),
            f32(baseTrans[3] + overlayPose.trans[3])
        } or {baseTrans[1], baseTrans[2], baseTrans[3]}
        local rot = nodeFlag(anim.rotFlags, nodeIndex) and quatMul(overlayPose.rot, basePose.rot) or
                        basePose.rot
        local scale = nodeFlag(anim.scaleFlags, nodeIndex) and
                          f32(basePose.scale * overlayPose.scale) or basePose.scale
        composed[nodeIndex] = {trans = trans, rot = rot, scale = scale}
    end
    return composed
end

-- (angleaxis -deg [1,0,0]) as quat in MAXScript; yawSign is checked against old files
local yawSign = 1
local function yawQuat(yawRad)
    local deg = f32(yawRad * f32(180 / pi))
    local half = f32(f32(-deg * f32(pi / 180)) / 2)
    return {f32(yawSign * math.sin(half)), 0, 0, f32(math.cos(half))}
end

-- One output frame: the root node gets the frame info accumulated so far
local function keyframe(frame, nodeCount, totalX, totalY, totalZ, totalYaw)
    local out = {}
    for nodeIndex = 1, nodeCount do
        local pose = frame[nodeIndex]
        local trans, rot = pose.trans, pose.rot
        if nodeIndex == 1 then
            trans = {f32(trans[1] + totalX), f32(trans[2] + totalY), f32(trans[3] + totalZ)}
            if totalYaw ~= 0 then
                rot = quatMul(yawQuat(totalYaw), rot)
            end
        end
        out[nodeIndex] = {trans = trans, rot = rot, scale = pose.scale}
    end
    return out
end

-------------------------------------------------------------------------------
-- JMA text
-------------------------------------------------------------------------------

-- Every frame gets exactly nodeCount poses (an overlay's idle pose can have more nodes)
local function writeJma(path, anim, nodes, keyframes)
    local frames = {}
    for frameIndex, frame in ipairs(keyframes) do
        local poses = {}
        for nodeIndex = 1, anim.nodeCount do
            poses[nodeIndex] = frame[nodeIndex] or
                                   error(
                                       ("frame %d has no pose for node %d"):format(frameIndex,
                                                                                   nodeIndex), 0)
        end
        frames[frameIndex] = poses
    end
    return jma.write(path, {
        version = jma.supportedVersion,
        frameCount = anim.frameCount + 1,
        frameRate = 30,
        actorCount = 1,
        actorName = "unnamedActor",
        nodeCount = anim.nodeCount,
        checksum = 0,
        nodes = nodes,
        frames = frames
    })
end

-------------------------------------------------------------------------------
-- Main
-------------------------------------------------------------------------------

-- Tag fields the extraction uses
local function animationInfo(animation)
    local function pair(array)
        return {array[1]["field_0"], array[2]["field_0"]}
    end
    return {
        name = animation["name"],
        type = animation["type"],
        frameCount = animation["frame count"],
        frameInfoType = animation["frame info type"],
        checksum = animation["node list checksum"],
        nodeCount = animation["node count"],
        flags = animation["flags"],
        transFlags = pair(animation["node trans. flag data"]),
        rotFlags = pair(animation["node rotation flag data"]),
        scaleFlags = pair(animation["node scale flag data"]),
        offsetToCompressed = animation["offset to compressed data"],
        frameInfo = animation["frame info"],
        defaultData = animation["default data"],
        frameData = animation["frame data"]
    }
end

-- Poses of one animation as the JMA has them: an overlay starts with its idle pose, base and
-- replacement animations end with a looping copy of frame 1
local function animationKeyframes(anim, animations, log)
    local info = readFrameInfo(anim)

    local idle
    if anim.type == animationTypes.overlay then
        local idleIndex = findIdle(anim, animations)
        if idleIndex then
            log(logLevel.info, ("Using '%s' as idle base for overlay '%s'"):format(
                    animations[idleIndex].name, anim.name))
            idle = firstFrame(animations[idleIndex])
        else
            log(logLevel.warning,
                ("No idle base found for overlay '%s' | using animation defaults."):format(anim.name))
        end
    end

    local defaults, frames = readPoses(anim, anim.frameCount)
    local keyframes = {}
    if anim.type == animationTypes.overlay then
        keyframes[1] = idle or defaults
    end

    -- The root moves by the frame info (dx, dy, dz, dyaw) accumulated over the frames
    local totalX, totalY, totalZ, totalYaw = 0, 0, 0, 0
    for frameIndex = 1, anim.frameCount do
        local frame = (anim.type == animationTypes.overlay and idle) and
                          composeOverlay(idle, frames[frameIndex], anim) or frames[frameIndex]
        keyframes[#keyframes + 1] =
            keyframe(frame, anim.nodeCount, totalX, totalY, totalZ, totalYaw)
        local delta = info[frameIndex]
        if delta then
            totalX, totalY = f32(totalX + delta[1]), f32(totalY + delta[2])
            totalZ, totalYaw = f32(totalZ + delta[3]), f32(totalYaw + delta[4])
        end
    end
    -- Base and replacement animations end with a looping copy of frame 1
    if anim.type == animationTypes.base or anim.type == animationTypes.replacement then
        keyframes[#keyframes + 1] = keyframe(frames[1], anim.nodeCount, totalX, totalY, totalZ,
                                             totalYaw)
    end
    return keyframes
end

-- Writes one animation's file; returns true when written
local function extractOne(anim, animations, nodes, outDir, log)
    local keyframes = animationKeyframes(anim, animations, log)
    local path = outDir .. "\\" .. anim.name .. "." .. extension(anim)
    return writeJma(path, anim, nodes, keyframes)
end

-- The tag's nodes { name, first child, next sibling }; empty when it has none and no fallback
local function tagNodes(root, animations, log)
    local nodes = {}
    for i, node in ipairs(root["nodes"]) do
        nodes[i] = {node["name"], node["first child node index"], node["next sibling node index"]}
    end
    if #nodes == 0 then
        -- Old retail tags have no nodes block: known node lists by count and checksum
        local first = animations[1]
        local known = first and fallbackNodes.find(first.nodeCount, first.checksum)
        if not known then
            log(logLevel.error, first and
                    ("Tag has no nodes and no fallback found (count=%d, checksum=%d)."):format(
                        first.nodeCount, first.checksum) or
                    "Tag has no nodes and no animations | cannot extract.")
        else
            log(logLevel.warning,
                ("No nodes block in tag; using hardcoded fallback: nodes: %d  checksum: %d"):format(
                    first.nodeCount, first.checksum))
            nodes = known
        end
    end
    return nodes
end

local function readAnimations(root)
    local animations = {}
    for i, animation in ipairs(root["animations"]) do
        animations[i] = animationInfo(animation)
    end
    return animations
end

-- For the Animation Player (importers\animation_player.lua): the nodes, and per animation
-- { name, ext, nodeCount, keyframes } (no keyframes when it can't be read)
function modelAnimations.decodeAll(root, tag, log)
    dataReader = tagReader.openBytes(tag.bytes)
    local animations = readAnimations(root)
    local nodes = tagNodes(root, animations, log)
    local decoded = {}
    for i, anim in ipairs(animations) do
        local entry = {name = anim.name, ext = extension(anim), nodeCount = anim.nodeCount, keyframes = {}}
        if #nodes > 0 and anim.nodeCount > 0 then
            local ok, result = pcall(animationKeyframes, anim, animations, log)
            if ok then
                entry.keyframes = result
            else
                log(logLevel.error, ("Failed to read '%s': %s"):format(anim.name, tostring(result)))
            end
        end
        decoded[i] = entry
    end
    dataReader = nil
    return nodes, decoded
end

modelAnimations.logLevel = logLevel

function modelAnimations.write(root, output, options, tag)
    local outDir = assert(options[1], "missing output folder"):gsub("[\\/]+$", "")
    dataReader = tagReader.openBytes(tag.bytes)

    local only = nil
    if options[2] and options[2] ~= "" then
        only = {}
        for index in options[2]:gmatch("%d+") do only[tonumber(index)] = true end
    end

    local messages = {}
    local function log(level, text)
        messages[#messages + 1] = {level, text}
    end

    local animations = readAnimations(root)
    local nodes = tagNodes(root, animations, log)

    -- Without nodes nothing is written (the old extractor stopped there too)
    local hasNodes = #nodes > 0
    local extracted, skipped = 0, 0
    for i, anim in ipairs(hasNodes and animations or {}) do
        if only and not only[i] then
            -- Not picked in the Animation Player
        elseif anim.nodeCount == 0 then
            log(logLevel.warning, ("Skipping '%s': nodeCount is 0."):format(anim.name))
            skipped = skipped + 1
        else
            local ok, result = pcall(extractOne, anim, animations, nodes, outDir, log)
            if ok and result then
                extracted = extracted + 1
            else
                log(logLevel.error, ("Failed to extract '%s': %s"):format(anim.name, ok and
                                                                              "cannot write the file" or
                                                                              tostring(result)))
                skipped = skipped + 1
            end
        end
    end
    dataReader = nil

    -- Summary for animation_extractor.ms: counts, then each message as level + text
    output:ints({hasNodes and 1 or 0, #nodes, #animations, extracted, skipped})
    output:int(#messages)
    for _, message in ipairs(messages) do
        output:int(message[1])
        output:string(message[2])
    end
end

return modelAnimations
