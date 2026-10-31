-- model_animations -> JMA/JMO/JMR/... source files, one per animation (same output as the
-- previous MAXScript extractor). options: { output folder }. Writes a summary that
-- pipeline\extract_model_animations\animation_extractor.ms reads.
-- Math is rounded to 32-bit floats like MAXScript, so the text matches the old files.

local bit = require("bit")
local bytes = require("tags.bytes")
local maxNumbers = require("formats.max_numbers")
local jma = require("formats.jma")
local fallbackNodes = require("importers.shared.fallback_nodes")

local band, bor, rshift, lshift = bit.band, bit.bor, bit.rshift, bit.lshift
local sqrt, format = math.sqrt, string.format

local modelAnimations = { group = "model_animations", version = 2 }

-- Rounds to a 32-bit float (MAXScript Float)
local f32 = maxNumbers.f32

local TYPE_BASE, TYPE_OVERLAY, TYPE_REPLACEMENT = 0, 1, 2
local INFO_NONE, INFO_DXDY, INFO_DXDYDYAW, INFO_DXDYDZDYAW = 0, 1, 2, 3
local PI = f32(math.pi)

-------------------------------------------------------------------------------
-- Reading the tag bytes
-------------------------------------------------------------------------------

local src -- bytes reader over the tag file (set in write)

-------------------------------------------------------------------------------
-- Helpers (same math as the previous MAXScript extractor)
-------------------------------------------------------------------------------

-- Bit n (1-based) of the two int32 node flag words
local function nodeFlag(flags, n)
	if n <= 32 then return band(flags[1], lshift(1, n - 1)) ~= 0 end
	if n <= 64 then return band(flags[2], lshift(1, n - 33)) ~= 0 end
	return false
end

local function extension(anim)
	local worldRelative = band(anim.flags, 2) ~= 0
	local t, info = anim.type, anim.frameInfoType
	if t == TYPE_REPLACEMENT then return "JMR"
	elseif t == TYPE_OVERLAY then return "JMO"
	elseif t == TYPE_BASE and info == INFO_NONE and worldRelative then return "JMW"
	elseif t == TYPE_BASE and info == INFO_DXDY then return "JMA"
	elseif t == TYPE_BASE and info == INFO_DXDYDYAW then return "JMT"
	elseif t == TYPE_BASE and info == INFO_DXDYDZDYAW then return "JMZ"
	end
	return "JMM"
end

-- Normalized #(i,j,k,w); identity when the length is 0
local function normalizeQuat(i, j, k, w)
	local mag2 = f32(f32(f32(f32(i * i) + f32(j * j)) + f32(k * k)) + f32(w * w))
	if mag2 == 0 then return { 0, 0, 0, 1 } end
	local inv = f32(1 / f32(sqrt(mag2)))
	return { f32(i * inv), f32(j * inv), f32(k * inv), f32(w * inv) }
end

-- Uncompressed tag quaternion: 4 x int16 / 32767
local function readQuat()
	local i = f32(src:beI16() / 32767)
	local j = f32(src:beI16() / 32767)
	local k = f32(src:beI16() / 32767)
	local w = f32(src:beI16() / 32767)
	return normalizeQuat(i, j, k, w)
end

-- Compressed quaternion: four 12-bit signed values packed into three 16-bit words
local function decompressQuat(w0, w1, w2)
	local ww = band(w2, 0x0FFF)
	local kk = bor(rshift(w2, 12), lshift(band(w1, 0x00FF), 4))
	local jj = bor(rshift(w1, 8), lshift(band(w0, 0x000F), 8))
	local ii = rshift(w0, 4)
	if band(ww, 0x800) ~= 0 then ww = ww - 4095 end
	if band(kk, 0x800) ~= 0 then kk = kk - 4095 end
	if band(jj, 0x800) ~= 0 then jj = jj - 4095 end
	if band(ii, 0x800) ~= 0 then ii = ii - 4095 end
	local mag2 = f32(f32(f32(ii * ii + jj * jj) + kk * kk) + ww * ww)
	if mag2 == 0 then return { 0, 0, 0, 1 } end
	local inv = f32(1 / f32(sqrt(mag2)))
	return { f32(ii * inv), f32(jj * inv), f32(kk * inv), f32(ww * inv) }
end

-- Blends with anti-flip; result is not normalized (the caller does it)
local function blendQuat(a, b, ratio)
	local r0, r1 = f32(1 - ratio), ratio
	local dot = f32(f32(f32(f32(a[1] * b[1]) + f32(a[2] * b[2])) + f32(a[3] * b[3])) + f32(a[4] * b[4]))
	if dot < 0 then r1 = -r1 end
	return {
		f32(f32(a[1] * r0) + f32(b[1] * r1)), f32(f32(a[2] * r0) + f32(b[2] * r1)),
		f32(f32(a[3] * r0) + f32(b[3] * r1)), f32(f32(a[4] * r0) + f32(b[4] * r1)),
	}
end

local function clamp01(r) return r < 0 and 0 or (r > 1 and 1 or r) end

local function blendVec3(a, b, ratio)
	local r1 = clamp01(ratio)
	local r0 = f32(1 - r1)
	return { f32(f32(a[1] * r0) + f32(b[1] * r1)), f32(f32(a[2] * r0) + f32(b[2] * r1)), f32(f32(a[3] * r0) + f32(b[3] * r1)) }
end

local function blendScalar(a, b, ratio)
	local r1 = clamp01(ratio)
	return f32(f32(a * f32(1 - r1)) + f32(b * r1))
end

-- Hamilton product q1 * q2, both { i, j, k, w }
local function quatMul(q1, q2)
	local x1, y1, z1, w1 = q1[1], q1[2], q1[3], q1[4]
	local x2, y2, z2, w2 = q2[1], q2[2], q2[3], q2[4]
	return {
		f32(f32(f32(f32(w1 * x2) + f32(x1 * w2)) + f32(y1 * z2)) - f32(z1 * y2)),
		f32(f32(f32(f32(w1 * y2) - f32(x1 * z2)) + f32(y1 * w2)) + f32(z1 * x2)),
		f32(f32(f32(f32(w1 * z2) + f32(x1 * y2)) - f32(y1 * x2)) + f32(z1 * w2)),
		f32(f32(f32(f32(w1 * w2) - f32(x1 * x2)) - f32(y1 * y2)) - f32(z1 * z2)),
	}
end

-- A node pose: { trans = {x,y,z}, rot = {i,j,k,w}, scale }
local function identityPose() return { trans = { 0, 0, 0 }, rot = { 0, 0, 0, 1 }, scale = 1 } end

local function scaledVec3Be()
	local x = f32(src:beFloat() * 100)
	local y = f32(src:beFloat() * 100)
	local z = f32(src:beFloat() * 100)
	return { x, y, z }
end

-------------------------------------------------------------------------------
-- Uncompressed data
-------------------------------------------------------------------------------

-- Per frame { dx, dy, dz, dyaw } (translation * 100, yaw in radians)
local function readFrameInfo(anim)
	local info = {}
	if anim.frameInfoType == INFO_NONE or anim.frameInfo.size == 0 then return info end
	src:seek(anim.frameInfo.offset)
	for f = 1, anim.frameCount do
		local dx = f32(src:beFloat() * 100)
		local dy = f32(src:beFloat() * 100)
		local dz, dyaw = 0, 0
		if anim.frameInfoType == INFO_DXDYDYAW then
			dyaw = src:beFloat()
		elseif anim.frameInfoType == INFO_DXDYDZDYAW then
			dz = f32(src:beFloat() * 100)
			dyaw = src:beFloat()
		end
		info[f] = { dx, dy, dz, dyaw }
	end
	return info
end

-- Nodes without per-frame data store their single value here (rotation, translation, scale)
local function readDefaults(anim)
	local defaults = {}
	for n = 1, anim.nodeCount do
		local pose = identityPose()
		if not nodeFlag(anim.rotFlags, n) then pose.rot = readQuat() end
		if not nodeFlag(anim.transFlags, n) then pose.trans = scaledVec3Be() end
		if not nodeFlag(anim.scaleFlags, n) then pose.scale = src:beFloat() end
		defaults[n] = pose
	end
	return defaults
end

local function readFrames(anim, defaults, frameCount)
	local frames = {}
	for f = 1, frameCount do
		local nodes = {}
		for n = 1, anim.nodeCount do
			local d = defaults[n]
			local pose = { trans = { d.trans[1], d.trans[2], d.trans[3] }, rot = d.rot, scale = d.scale }
			if nodeFlag(anim.rotFlags, n) then pose.rot = readQuat() end
			if nodeFlag(anim.transFlags, n) then pose.trans = scaledVec3Be() end
			if nodeFlag(anim.scaleFlags, n) then pose.scale = src:beFloat() end
			nodes[n] = pose
		end
		frames[f] = nodes
	end
	return frames
end

-------------------------------------------------------------------------------
-- Compressed data (little-endian block inside frame data)
-------------------------------------------------------------------------------

-- Value at 0-based frame fi from the keyframes kfStart..kfEnd (1-based, inclusive)
local function keyframeValue(fi, kfStart, kfEnd, kfNums, def, kfData, blend)
	if kfStart >= kfEnd or fi == 0 then return def end
	if fi >= kfNums[kfEnd] then return kfData[kfEnd] end
	local first = kfNums[kfStart]
	if fi < first then
		if first == 0 then return def end
		return blend(def, kfData[kfStart], f32(fi / first))
	end
	local k = kfStart
	for i = kfStart, kfEnd - 1 do
		if kfNums[i] <= fi and kfNums[i + 1] > fi then k = i; break end
	end
	if fi == kfNums[k] then return kfData[k] end
	local span = kfNums[k + 1] - kfNums[k]
	if span == 0 then return kfData[k] end
	return blend(kfData[k], kfData[k + 1], f32((fi - kfNums[k]) / span))
end

-- MAXScript integer division truncates toward zero
local function idiv(a, b)
	local q = a / b
	return q >= 0 and math.floor(q) or math.ceil(q)
end

-- Keyframe ranges per node from a keyframe_head word: low 12 bits count, high bits start
local function keyframeRanges(anim, flags, heads)
	local starts, ends, h = {}, {}, 0
	for n = 1, anim.nodeCount do
		if nodeFlag(flags, n) then
			h = h + 1
			local count = band(heads[h], 0x0FFF)
			local first = rshift(heads[h], 12)
			starts[n], ends[n] = first + 1, first + count
		else
			starts[n], ends[n] = 1, 0
		end
	end
	return starts, ends
end

local function readCompressedFrames(anim, frameCount)
	local comp = anim.frameData.offset + anim.offsetToCompressed
	src:seek(comp)
	local rKf, rDd, rFd = src:leI32(), src:leI32(), src:leI32()
	local tKh, tKf, tDd, tFd = src:leI32(), src:leI32(), src:leI32(), src:leI32()
	local sKh, sKf, sDd, sFd = src:leI32(), src:leI32(), src:leI32(), src:leI32()
	local rKh = 44 -- rotation keyframe_head always follows the 44-byte header

	local nR, nT, nS = 0, 0, 0
	for n = 1, anim.nodeCount do
		if nodeFlag(anim.rotFlags, n) then nR = nR + 1 end
		if nodeFlag(anim.transFlags, n) then nT = nT + 1 end
		if nodeFlag(anim.scaleFlags, n) then nS = nS + 1 end
	end

	local function readList(offset, count, reader)
		local list = {}
		src:seek(comp + offset)
		for i = 1, count do list[i] = reader(src) end
		return list
	end

	-- Rotation
	local rotHeads = readList(rKh, nR, src.leI32)
	local rotNums = readList(rKf, idiv(rDd - rKf, 2), src.leU16)
	local raw = readList(rDd, anim.nodeCount * 3, src.leU16)
	local rotDef = {}
	for n = 1, anim.nodeCount do
		local b = (n - 1) * 3
		rotDef[n] = decompressQuat(raw[b + 1], raw[b + 2], raw[b + 3])
	end
	local fdCount = idiv(tKh - rFd, 2)
	raw = readList(rFd, fdCount, src.leU16)
	local rotData = {}
	for k = 1, idiv(fdCount, 3) do
		local b = (k - 1) * 3
		rotData[k] = decompressQuat(raw[b + 1], raw[b + 2], raw[b + 3])
	end

	-- Translation (* 100)
	local transHeads = readList(tKh, nT, src.leI32)
	local transNums = readList(tKf, idiv(tDd - tKf, 2), src.leU16)
	local function leVec3(reader)
		local x = f32(reader:leFloat() * 100)
		local y = f32(reader:leFloat() * 100)
		local z = f32(reader:leFloat() * 100)
		return { x, y, z }
	end
	local transDef = readList(tDd, anim.nodeCount, leVec3)
	local transData = readList(tFd, idiv(idiv(sKh - tFd, 4), 3), leVec3)

	-- Scale: defaults only for animated scale nodes
	local scaleHeads = readList(sKh, nS, src.leI32)
	local scaleNums = readList(sKf, idiv(sDd - sKf, 2), src.leU16)
	local scaleDefaults = readList(sDd, idiv(sFd - sDd, 4), src.leFloat)
	local compSize = anim.frameData.size - anim.offsetToCompressed
	local scaleData = readList(sFd, idiv(compSize - sFd, 4), src.leFloat)

	local rStart, rEnd = keyframeRanges(anim, anim.rotFlags, rotHeads)
	local tStart, tEnd = keyframeRanges(anim, anim.transFlags, transHeads)
	local sStart, sEnd = keyframeRanges(anim, anim.scaleFlags, scaleHeads)
	local scaleDef, s = {}, 0
	for n = 1, anim.nodeCount do
		if nodeFlag(anim.scaleFlags, n) then
			s = s + 1
			scaleDef[n] = scaleDefaults[s]
		else
			scaleDef[n] = 1
		end
	end

	local frames = {}
	for f = 1, frameCount do
		local fi = f - 1
		local nodes = {}
		for n = 1, anim.nodeCount do
			local q = keyframeValue(fi, rStart[n], rEnd[n], rotNums, rotDef[n], rotData, blendQuat)
			local t = keyframeValue(fi, tStart[n], tEnd[n], transNums, transDef[n], transData, blendVec3)
			nodes[n] = {
				trans = { t[1], t[2], t[3] },
				rot = normalizeQuat(q[1], q[2], q[3], q[4]),
				scale = keyframeValue(fi, sStart[n], sEnd[n], scaleNums, scaleDef[n], scaleData, blendScalar),
			}
		end
		frames[f] = nodes
	end
	return frames
end

-------------------------------------------------------------------------------
-- Poses per animation
-------------------------------------------------------------------------------

local function isCompressed(anim) return band(anim.flags, 1) ~= 0 end

local function identityFrame(anim)
	local frame = {}
	for n = 1, anim.nodeCount do frame[n] = identityPose() end
	return frame
end

-- Returns defaults (rest pose) and frames
local function readPoses(anim, frameCount)
	if isCompressed(anim) then
		local frames = {}
		if anim.frameData.size > 0 then frames = readCompressedFrames(anim, frameCount) end
		return frames[1] or identityFrame(anim), frames
	end
	local defaults
	if anim.defaultData.size > 0 then
		src:seek(anim.defaultData.offset)
		defaults = readDefaults(anim)
	else
		defaults = identityFrame(anim)
	end
	local frames = {}
	if anim.frameData.size > 0 then
		src:seek(anim.frameData.offset)
		frames = readFrames(anim, defaults, frameCount)
	else
		for f = 1, frameCount do frames[f] = defaults end
	end
	return defaults, frames
end

-- First frame of a base animation, used as the rest pose under an overlay
local function firstFrame(anim)
	if isCompressed(anim) then
		if anim.frameData.size > 0 then
			local frames = readCompressedFrames(anim, 1)
			if frames[1] then return frames[1] end
		end
		return identityFrame(anim)
	end
	local defaults, frames = readPoses(anim, 1)
	if anim.frameData.size > 0 and frames[1] then return frames[1] end
	return defaults
end

-- Base idle animation for an overlay: same first word ("alert", "stand"...) preferred
local function findIdle(overlay, animations)
	local prefix = (overlay.name:match("^ *([^ ]+)") or ""):lower()
	local best
	for i, a in ipairs(animations) do
		if a.type == TYPE_BASE and a.name:find("idle", 1, true) then
			if (a.name:match("^ *([^ ]+)") or ""):lower() == prefix then return i end
			best = best or i
		end
	end
	return best
end

-- Overlay delta on the idle pose (see the previous composeOverlayWithBase)
local function composeOverlay(base, overlay, anim)
	local composed = {}
	for n = 1, anim.nodeCount do
		local b, o = base[n], overlay[n]
		local bt = b.trans
		local trans = nodeFlag(anim.transFlags, n)
			and { f32(bt[1] + o.trans[1]), f32(bt[2] + o.trans[2]), f32(bt[3] + o.trans[3]) }
			or { bt[1], bt[2], bt[3] }
		local rot = nodeFlag(anim.rotFlags, n) and quatMul(o.rot, b.rot) or b.rot
		local scale = nodeFlag(anim.scaleFlags, n) and f32(b.scale * o.scale) or b.scale
		composed[n] = { trans = trans, rot = rot, scale = scale }
	end
	return composed
end

-- (angleaxis -deg [1,0,0]) as quat in MAXScript; YAW_SIGN is checked against old files
local YAW_SIGN = 1
local function yawQuat(yawRad)
	local deg = f32(yawRad * f32(180 / PI))
	local half = f32(f32(-deg * f32(PI / 180)) / 2)
	return { f32(YAW_SIGN * math.sin(half)), 0, 0, f32(math.cos(half)) }
end

-- One output frame: the root node gets the frame info accumulated so far
local function keyframe(frame, nodeCount, ax, ay, az, ayaw)
	local out = {}
	for n = 1, nodeCount do
		local pose = frame[n]
		local t, r = pose.trans, pose.rot
		if n == 1 then
			t = { f32(t[1] + ax), f32(t[2] + ay), f32(t[3] + az) }
			if ayaw ~= 0 then r = quatMul(yawQuat(ayaw), r) end
		end
		out[n] = { trans = t, rot = r, scale = pose.scale }
	end
	return out
end

-------------------------------------------------------------------------------
-- JMA text
-------------------------------------------------------------------------------

-- Every frame gets exactly nodeCount poses (an overlay's idle pose can have more nodes)
local function writeJma(path, anim, nodes, keyframes)
	local frames = {}
	for f, frame in ipairs(keyframes) do
		local poses = {}
		for n = 1, anim.nodeCount do
			poses[n] = frame[n] or error(("frame %d has no pose for node %d"):format(f, n), 0)
		end
		frames[f] = poses
	end
	return jma.write(path, {
		version = jma.SUPPORTED_VERSION, frameCount = anim.frameCount + 1, frameRate = 30,
		actorCount = 1, actorName = "unnamedActor", nodeCount = anim.nodeCount, checksum = 0,
		nodes = nodes, frames = frames,
	})
end

-------------------------------------------------------------------------------
-- Main
-------------------------------------------------------------------------------

-- Tag fields the extraction uses
local function animationInfo(a)
	local function pair(array) return { array[1]["field_0"], array[2]["field_0"] } end
	return {
		name = a["name"], type = a["type"], frameCount = a["frame count"],
		frameInfoType = a["frame info type"], checksum = a["node list checksum"],
		nodeCount = a["node count"], flags = a["flags"],
		transFlags = pair(a["node trans. flag data"]), rotFlags = pair(a["node rotation flag data"]),
		scaleFlags = pair(a["node scale flag data"]), offsetToCompressed = a["offset to compressed data"],
		frameInfo = a["frame info"], defaultData = a["default data"], frameData = a["frame data"],
	}
end

local function extractOne(anim, animations, nodes, outDir, log)
	local info = readFrameInfo(anim)

	local idle
	if anim.type == TYPE_OVERLAY then
		local idleIndex = findIdle(anim, animations)
		if idleIndex then
			log(1, ("Using '%s' as idle base for overlay '%s'"):format(animations[idleIndex].name, anim.name))
			idle = firstFrame(animations[idleIndex])
		else
			log(2, ("No idle base found for overlay '%s' | using animation defaults."):format(anim.name))
		end
	end

	local defaults, frames = readPoses(anim, anim.frameCount)
	local keyframes = {}
	if anim.type == TYPE_OVERLAY then
		keyframes[1] = idle or defaults
	end

	local ax, ay, az, ayaw = 0, 0, 0, 0
	for f = 1, anim.frameCount do
		local frame = (anim.type == TYPE_OVERLAY and idle) and composeOverlay(idle, frames[f], anim) or frames[f]
		keyframes[#keyframes + 1] = keyframe(frame, anim.nodeCount, ax, ay, az, ayaw)
		local fi = info[f]
		if fi then
			ax, ay, az, ayaw = f32(ax + fi[1]), f32(ay + fi[2]), f32(az + fi[3]), f32(ayaw + fi[4])
		end
	end
	-- Base and replacement animations end with a looping copy of frame 1
	if anim.type == TYPE_BASE or anim.type == TYPE_REPLACEMENT then
		keyframes[#keyframes + 1] = keyframe(frames[1], anim.nodeCount, ax, ay, az, ayaw)
	end

	local path = outDir .. "\\" .. anim.name .. "." .. extension(anim)
	return writeJma(path, anim, nodes, keyframes)
end

function modelAnimations.write(root, w, options, tag)
	local outDir = assert(options[1], "missing output folder"):gsub("[\\/]+$", "")
	src = bytes.reader(tag.bytes)

	local messages = {}
	local function log(level, text) messages[#messages + 1] = { level, text } end

	local animations = {}
	for i, a in ipairs(root["animations"]) do animations[i] = animationInfo(a) end

	local nodes = {}
	for i, n in ipairs(root["nodes"]) do
		nodes[i] = { n["name"], n["first child node index"], n["next sibling node index"] }
	end
	if #nodes == 0 then
		-- Old retail tags have no nodes block: known node lists by count and checksum
		local first = animations[1]
		local known = first and fallbackNodes.find(first.nodeCount, first.checksum)
		if not known then
			log(3, first and ("Tag has no nodes and no fallback found (count=%d, checksum=%d)."):format(first.nodeCount, first.checksum)
				or "Tag has no nodes and no animations | cannot extract.")
		else
			log(2, ("No nodes block in tag; using hardcoded fallback: nodes: %d  checksum: %d"):format(first.nodeCount, first.checksum))
			nodes = known
		end
	end

	-- Without nodes nothing is written (the old extractor stopped there too)
	local okNodes = #nodes > 0
	local extracted, skipped = 0, 0
	for _, anim in ipairs(okNodes and animations or {}) do
		if anim.nodeCount == 0 then
			log(2, ("Skipping '%s': nodeCount is 0."):format(anim.name))
			skipped = skipped + 1
		else
			local ok, result = pcall(extractOne, anim, animations, nodes, outDir, log)
			if ok and result then
				extracted = extracted + 1
			else
				log(3, ("Failed to extract '%s': %s"):format(anim.name, ok and "cannot write the file" or tostring(result)))
				skipped = skipped + 1
			end
		end
	end
	src = nil

	w:ints({ okNodes and 1 or 0, #nodes, #animations, extracted, skipped })
	w:int(#messages)
	for _, m in ipairs(messages) do
		w:int(m[1])
		w:string(m[2])
	end
end

return modelAnimations
