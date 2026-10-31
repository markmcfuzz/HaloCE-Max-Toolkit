-- model_animations -> JMA/JMO/JMR/... source files, one per animation (same output as the
-- previous MAXScript extractor). options: { output folder }. Writes a summary that
-- pipeline\extract_model_animations\animation_extractor.ms reads.
-- Math is rounded to 32-bit floats like MAXScript, so the text matches the old files.

local bit = require("bit")
local bytes = require("core.halo1.bytes")
local max_numbers = require("shared.utils.max_numbers")
local jma = require("formats.jma.jma")
local fallback_nodes = require("pipeline.extract_model_animations.fallback_nodes")

local band, bor, rshift, lshift = bit.band, bit.bor, bit.rshift, bit.lshift
local sqrt, format = math.sqrt, string.format

local model_animations = { group = "model_animations", version = 2 }

-- Rounds to a 32-bit float (MAXScript Float)
local f32 = max_numbers.f32

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
local function node_flag(flags, n)
	if n <= 32 then return band(flags[1], lshift(1, n - 1)) ~= 0 end
	if n <= 64 then return band(flags[2], lshift(1, n - 33)) ~= 0 end
	return false
end

local function extension(anim)
	local world_relative = band(anim.flags, 2) ~= 0
	local t, info = anim.type, anim.frame_info_type
	if t == TYPE_REPLACEMENT then return "JMR"
	elseif t == TYPE_OVERLAY then return "JMO"
	elseif t == TYPE_BASE and info == INFO_NONE and world_relative then return "JMW"
	elseif t == TYPE_BASE and info == INFO_DXDY then return "JMA"
	elseif t == TYPE_BASE and info == INFO_DXDYDYAW then return "JMT"
	elseif t == TYPE_BASE and info == INFO_DXDYDZDYAW then return "JMZ"
	end
	return "JMM"
end

-- Normalized #(i,j,k,w); identity when the length is 0
local function normalize_quat(i, j, k, w)
	local mag2 = f32(f32(f32(f32(i * i) + f32(j * j)) + f32(k * k)) + f32(w * w))
	if mag2 == 0 then return { 0, 0, 0, 1 } end
	local inv = f32(1 / f32(sqrt(mag2)))
	return { f32(i * inv), f32(j * inv), f32(k * inv), f32(w * inv) }
end

-- Uncompressed tag quaternion: 4 x int16 / 32767
local function read_quat()
	local i = f32(src:be_i16() / 32767)
	local j = f32(src:be_i16() / 32767)
	local k = f32(src:be_i16() / 32767)
	local w = f32(src:be_i16() / 32767)
	return normalize_quat(i, j, k, w)
end

-- Compressed quaternion: four 12-bit signed values packed into three 16-bit words
local function decompress_quat(w0, w1, w2)
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
local function blend_quat(a, b, ratio)
	local r0, r1 = f32(1 - ratio), ratio
	local dot = f32(f32(f32(f32(a[1] * b[1]) + f32(a[2] * b[2])) + f32(a[3] * b[3])) + f32(a[4] * b[4]))
	if dot < 0 then r1 = -r1 end
	return {
		f32(f32(a[1] * r0) + f32(b[1] * r1)), f32(f32(a[2] * r0) + f32(b[2] * r1)),
		f32(f32(a[3] * r0) + f32(b[3] * r1)), f32(f32(a[4] * r0) + f32(b[4] * r1)),
	}
end

local function clamp01(r) return r < 0 and 0 or (r > 1 and 1 or r) end

local function blend_vec3(a, b, ratio)
	local r1 = clamp01(ratio)
	local r0 = f32(1 - r1)
	return { f32(f32(a[1] * r0) + f32(b[1] * r1)), f32(f32(a[2] * r0) + f32(b[2] * r1)), f32(f32(a[3] * r0) + f32(b[3] * r1)) }
end

local function blend_scalar(a, b, ratio)
	local r1 = clamp01(ratio)
	return f32(f32(a * f32(1 - r1)) + f32(b * r1))
end

-- Hamilton product q1 * q2, both { i, j, k, w }
local function quat_mul(q1, q2)
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
local function identity_pose() return { trans = { 0, 0, 0 }, rot = { 0, 0, 0, 1 }, scale = 1 } end

local function scaled_vec3_be()
	local x = f32(src:be_float() * 100)
	local y = f32(src:be_float() * 100)
	local z = f32(src:be_float() * 100)
	return { x, y, z }
end

-------------------------------------------------------------------------------
-- Uncompressed data
-------------------------------------------------------------------------------

-- Per frame { dx, dy, dz, dyaw } (translation * 100, yaw in radians)
local function read_frame_info(anim)
	local info = {}
	if anim.frame_info_type == INFO_NONE or anim.frame_info.size == 0 then return info end
	src:seek(anim.frame_info.offset)
	for f = 1, anim.frame_count do
		local dx = f32(src:be_float() * 100)
		local dy = f32(src:be_float() * 100)
		local dz, dyaw = 0, 0
		if anim.frame_info_type == INFO_DXDYDYAW then
			dyaw = src:be_float()
		elseif anim.frame_info_type == INFO_DXDYDZDYAW then
			dz = f32(src:be_float() * 100)
			dyaw = src:be_float()
		end
		info[f] = { dx, dy, dz, dyaw }
	end
	return info
end

-- Nodes without per-frame data store their single value here (rotation, translation, scale)
local function read_defaults(anim)
	local defaults = {}
	for n = 1, anim.node_count do
		local pose = identity_pose()
		if not node_flag(anim.rot_flags, n) then pose.rot = read_quat() end
		if not node_flag(anim.trans_flags, n) then pose.trans = scaled_vec3_be() end
		if not node_flag(anim.scale_flags, n) then pose.scale = src:be_float() end
		defaults[n] = pose
	end
	return defaults
end

local function read_frames(anim, defaults, frame_count)
	local frames = {}
	for f = 1, frame_count do
		local nodes = {}
		for n = 1, anim.node_count do
			local d = defaults[n]
			local pose = { trans = { d.trans[1], d.trans[2], d.trans[3] }, rot = d.rot, scale = d.scale }
			if node_flag(anim.rot_flags, n) then pose.rot = read_quat() end
			if node_flag(anim.trans_flags, n) then pose.trans = scaled_vec3_be() end
			if node_flag(anim.scale_flags, n) then pose.scale = src:be_float() end
			nodes[n] = pose
		end
		frames[f] = nodes
	end
	return frames
end

-------------------------------------------------------------------------------
-- Compressed data (little-endian block inside frame data)
-------------------------------------------------------------------------------

-- Value at 0-based frame fi from the keyframes kf_start..kf_end (1-based, inclusive)
local function keyframe_value(fi, kf_start, kf_end, kf_nums, def, kf_data, blend)
	if kf_start >= kf_end or fi == 0 then return def end
	if fi >= kf_nums[kf_end] then return kf_data[kf_end] end
	local first = kf_nums[kf_start]
	if fi < first then
		if first == 0 then return def end
		return blend(def, kf_data[kf_start], f32(fi / first))
	end
	local k = kf_start
	for i = kf_start, kf_end - 1 do
		if kf_nums[i] <= fi and kf_nums[i + 1] > fi then k = i; break end
	end
	if fi == kf_nums[k] then return kf_data[k] end
	local span = kf_nums[k + 1] - kf_nums[k]
	if span == 0 then return kf_data[k] end
	return blend(kf_data[k], kf_data[k + 1], f32((fi - kf_nums[k]) / span))
end

-- MAXScript integer division truncates toward zero
local function idiv(a, b)
	local q = a / b
	return q >= 0 and math.floor(q) or math.ceil(q)
end

-- Keyframe ranges per node from a keyframe_head word: low 12 bits count, high bits start
local function keyframe_ranges(anim, flags, heads)
	local starts, ends, h = {}, {}, 0
	for n = 1, anim.node_count do
		if node_flag(flags, n) then
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

local function read_compressed_frames(anim, frame_count)
	local comp = anim.frame_data.offset + anim.offset_to_compressed
	src:seek(comp)
	local r_kf, r_dd, r_fd = src:le_i32(), src:le_i32(), src:le_i32()
	local t_kh, t_kf, t_dd, t_fd = src:le_i32(), src:le_i32(), src:le_i32(), src:le_i32()
	local s_kh, s_kf, s_dd, s_fd = src:le_i32(), src:le_i32(), src:le_i32(), src:le_i32()
	local r_kh = 44 -- rotation keyframe_head always follows the 44-byte header

	local n_r, n_t, n_s = 0, 0, 0
	for n = 1, anim.node_count do
		if node_flag(anim.rot_flags, n) then n_r = n_r + 1 end
		if node_flag(anim.trans_flags, n) then n_t = n_t + 1 end
		if node_flag(anim.scale_flags, n) then n_s = n_s + 1 end
	end

	local function read_list(offset, count, reader)
		local list = {}
		src:seek(comp + offset)
		for i = 1, count do list[i] = reader(src) end
		return list
	end

	-- Rotation
	local rot_heads = read_list(r_kh, n_r, src.le_i32)
	local rot_nums = read_list(r_kf, idiv(r_dd - r_kf, 2), src.le_u16)
	local raw = read_list(r_dd, anim.node_count * 3, src.le_u16)
	local rot_def = {}
	for n = 1, anim.node_count do
		local b = (n - 1) * 3
		rot_def[n] = decompress_quat(raw[b + 1], raw[b + 2], raw[b + 3])
	end
	local fd_count = idiv(t_kh - r_fd, 2)
	raw = read_list(r_fd, fd_count, src.le_u16)
	local rot_data = {}
	for k = 1, idiv(fd_count, 3) do
		local b = (k - 1) * 3
		rot_data[k] = decompress_quat(raw[b + 1], raw[b + 2], raw[b + 3])
	end

	-- Translation (* 100)
	local trans_heads = read_list(t_kh, n_t, src.le_i32)
	local trans_nums = read_list(t_kf, idiv(t_dd - t_kf, 2), src.le_u16)
	local function le_vec3(reader)
		local x = f32(reader:le_float() * 100)
		local y = f32(reader:le_float() * 100)
		local z = f32(reader:le_float() * 100)
		return { x, y, z }
	end
	local trans_def = read_list(t_dd, anim.node_count, le_vec3)
	local trans_data = read_list(t_fd, idiv(idiv(s_kh - t_fd, 4), 3), le_vec3)

	-- Scale: defaults only for animated scale nodes
	local scale_heads = read_list(s_kh, n_s, src.le_i32)
	local scale_nums = read_list(s_kf, idiv(s_dd - s_kf, 2), src.le_u16)
	local scale_defaults = read_list(s_dd, idiv(s_fd - s_dd, 4), src.le_float)
	local comp_size = anim.frame_data.size - anim.offset_to_compressed
	local scale_data = read_list(s_fd, idiv(comp_size - s_fd, 4), src.le_float)

	local r_start, r_end = keyframe_ranges(anim, anim.rot_flags, rot_heads)
	local t_start, t_end = keyframe_ranges(anim, anim.trans_flags, trans_heads)
	local s_start, s_end = keyframe_ranges(anim, anim.scale_flags, scale_heads)
	local scale_def, s = {}, 0
	for n = 1, anim.node_count do
		if node_flag(anim.scale_flags, n) then
			s = s + 1
			scale_def[n] = scale_defaults[s]
		else
			scale_def[n] = 1
		end
	end

	local frames = {}
	for f = 1, frame_count do
		local fi = f - 1
		local nodes = {}
		for n = 1, anim.node_count do
			local q = keyframe_value(fi, r_start[n], r_end[n], rot_nums, rot_def[n], rot_data, blend_quat)
			local t = keyframe_value(fi, t_start[n], t_end[n], trans_nums, trans_def[n], trans_data, blend_vec3)
			nodes[n] = {
				trans = { t[1], t[2], t[3] },
				rot = normalize_quat(q[1], q[2], q[3], q[4]),
				scale = keyframe_value(fi, s_start[n], s_end[n], scale_nums, scale_def[n], scale_data, blend_scalar),
			}
		end
		frames[f] = nodes
	end
	return frames
end

-------------------------------------------------------------------------------
-- Poses per animation
-------------------------------------------------------------------------------

local function is_compressed(anim) return band(anim.flags, 1) ~= 0 end

local function identity_frame(anim)
	local frame = {}
	for n = 1, anim.node_count do frame[n] = identity_pose() end
	return frame
end

-- Returns defaults (rest pose) and frames
local function read_poses(anim, frame_count)
	if is_compressed(anim) then
		local frames = {}
		if anim.frame_data.size > 0 then frames = read_compressed_frames(anim, frame_count) end
		return frames[1] or identity_frame(anim), frames
	end
	local defaults
	if anim.default_data.size > 0 then
		src:seek(anim.default_data.offset)
		defaults = read_defaults(anim)
	else
		defaults = identity_frame(anim)
	end
	local frames = {}
	if anim.frame_data.size > 0 then
		src:seek(anim.frame_data.offset)
		frames = read_frames(anim, defaults, frame_count)
	else
		for f = 1, frame_count do frames[f] = defaults end
	end
	return defaults, frames
end

-- First frame of a base animation, used as the rest pose under an overlay
local function first_frame(anim)
	if is_compressed(anim) then
		if anim.frame_data.size > 0 then
			local frames = read_compressed_frames(anim, 1)
			if frames[1] then return frames[1] end
		end
		return identity_frame(anim)
	end
	local defaults, frames = read_poses(anim, 1)
	if anim.frame_data.size > 0 and frames[1] then return frames[1] end
	return defaults
end

-- Base idle animation for an overlay: same first word ("alert", "stand"...) preferred
local function find_idle(overlay, animations)
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
local function compose_overlay(base, overlay, anim)
	local composed = {}
	for n = 1, anim.node_count do
		local b, o = base[n], overlay[n]
		local bt = b.trans
		local trans = node_flag(anim.trans_flags, n)
			and { f32(bt[1] + o.trans[1]), f32(bt[2] + o.trans[2]), f32(bt[3] + o.trans[3]) }
			or { bt[1], bt[2], bt[3] }
		local rot = node_flag(anim.rot_flags, n) and quat_mul(o.rot, b.rot) or b.rot
		local scale = node_flag(anim.scale_flags, n) and f32(b.scale * o.scale) or b.scale
		composed[n] = { trans = trans, rot = rot, scale = scale }
	end
	return composed
end

-- (angleaxis -deg [1,0,0]) as quat in MAXScript; YAW_SIGN is checked against old files
local YAW_SIGN = 1
local function yaw_quat(yaw_rad)
	local deg = f32(yaw_rad * f32(180 / PI))
	local half = f32(f32(-deg * f32(PI / 180)) / 2)
	return { f32(YAW_SIGN * math.sin(half)), 0, 0, f32(math.cos(half)) }
end

-- One output frame: the root node gets the frame info accumulated so far
local function keyframe(frame, node_count, ax, ay, az, ayaw)
	local out = {}
	for n = 1, node_count do
		local pose = frame[n]
		local t, r = pose.trans, pose.rot
		if n == 1 then
			t = { f32(t[1] + ax), f32(t[2] + ay), f32(t[3] + az) }
			if ayaw ~= 0 then r = quat_mul(yaw_quat(ayaw), r) end
		end
		out[n] = { trans = t, rot = r, scale = pose.scale }
	end
	return out
end

-------------------------------------------------------------------------------
-- JMA text
-------------------------------------------------------------------------------

-- Every frame gets exactly node_count poses (an overlay's idle pose can have more nodes)
local function write_jma(path, anim, nodes, keyframes)
	local frames = {}
	for f, frame in ipairs(keyframes) do
		local poses = {}
		for n = 1, anim.node_count do
			poses[n] = frame[n] or error(("frame %d has no pose for node %d"):format(f, n), 0)
		end
		frames[f] = poses
	end
	return jma.write(path, {
		version = jma.SUPPORTED_VERSION, frame_count = anim.frame_count + 1, frame_rate = 30,
		actor_count = 1, actor_name = "unnamedActor", node_count = anim.node_count, checksum = 0,
		nodes = nodes, frames = frames,
	})
end

-------------------------------------------------------------------------------
-- Main
-------------------------------------------------------------------------------

-- Tag fields the extraction uses
local function animation_info(a)
	local function pair(array) return { array[1]["field_0"], array[2]["field_0"] } end
	return {
		name = a["name"], type = a["type"], frame_count = a["frame count"],
		frame_info_type = a["frame info type"], checksum = a["node list checksum"],
		node_count = a["node count"], flags = a["flags"],
		trans_flags = pair(a["node trans. flag data"]), rot_flags = pair(a["node rotation flag data"]),
		scale_flags = pair(a["node scale flag data"]), offset_to_compressed = a["offset to compressed data"],
		frame_info = a["frame info"], default_data = a["default data"], frame_data = a["frame data"],
	}
end

local function extract_one(anim, animations, nodes, out_dir, log)
	local info = read_frame_info(anim)

	local idle
	if anim.type == TYPE_OVERLAY then
		local idle_index = find_idle(anim, animations)
		if idle_index then
			log(1, ("Using '%s' as idle base for overlay '%s'"):format(animations[idle_index].name, anim.name))
			idle = first_frame(animations[idle_index])
		else
			log(2, ("No idle base found for overlay '%s' | using animation defaults."):format(anim.name))
		end
	end

	local defaults, frames = read_poses(anim, anim.frame_count)
	local keyframes = {}
	if anim.type == TYPE_OVERLAY then
		keyframes[1] = idle or defaults
	end

	local ax, ay, az, ayaw = 0, 0, 0, 0
	for f = 1, anim.frame_count do
		local frame = (anim.type == TYPE_OVERLAY and idle) and compose_overlay(idle, frames[f], anim) or frames[f]
		keyframes[#keyframes + 1] = keyframe(frame, anim.node_count, ax, ay, az, ayaw)
		local fi = info[f]
		if fi then
			ax, ay, az, ayaw = f32(ax + fi[1]), f32(ay + fi[2]), f32(az + fi[3]), f32(ayaw + fi[4])
		end
	end
	-- Base and replacement animations end with a looping copy of frame 1
	if anim.type == TYPE_BASE or anim.type == TYPE_REPLACEMENT then
		keyframes[#keyframes + 1] = keyframe(frames[1], anim.node_count, ax, ay, az, ayaw)
	end

	local path = out_dir .. "\\" .. anim.name .. "." .. extension(anim)
	return write_jma(path, anim, nodes, keyframes)
end

function model_animations.write(root, w, options, tag)
	local out_dir = assert(options[1], "missing output folder"):gsub("[\\/]+$", "")
	src = bytes.reader(tag.bytes)

	local messages = {}
	local function log(level, text) messages[#messages + 1] = { level, text } end

	local animations = {}
	for i, a in ipairs(root["animations"]) do animations[i] = animation_info(a) end

	local nodes = {}
	for i, n in ipairs(root["nodes"]) do
		nodes[i] = { n["name"], n["first child node index"], n["next sibling node index"] }
	end
	if #nodes == 0 then
		-- Old retail tags have no nodes block: known node lists by count and checksum
		local first = animations[1]
		local known = first and fallback_nodes.find(first.node_count, first.checksum)
		if not known then
			log(3, first and ("Tag has no nodes and no fallback found (count=%d, checksum=%d)."):format(first.node_count, first.checksum)
				or "Tag has no nodes and no animations | cannot extract.")
		else
			log(2, ("No nodes block in tag; using hardcoded fallback: nodes: %d  checksum: %d"):format(first.node_count, first.checksum))
			nodes = known
		end
	end

	-- Without nodes nothing is written (the old extractor stopped there too)
	local ok_nodes = #nodes > 0
	local extracted, skipped = 0, 0
	for _, anim in ipairs(ok_nodes and animations or {}) do
		if anim.node_count == 0 then
			log(2, ("Skipping '%s': nodeCount is 0."):format(anim.name))
			skipped = skipped + 1
		else
			local ok, result = pcall(extract_one, anim, animations, nodes, out_dir, log)
			if ok and result then
				extracted = extracted + 1
			else
				log(3, ("Failed to extract '%s': %s"):format(anim.name, ok and "cannot write the file" or tostring(result)))
				skipped = skipped + 1
			end
		end
	end
	src = nil

	w:ints({ ok_nodes and 1 or 0, #nodes, #animations, extracted, skipped })
	w:int(#messages)
	for _, m in ipairs(messages) do
		w:int(m[1])
		w:string(m[2])
	end
end

return model_animations
