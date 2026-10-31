-- JMA/JMO/JMR/... animation source files: read and write with the same rules as the
-- previous MAXScript reader (jma_reader.ms) and writer (process_file.ms).
-- jma = { version, frame_count, frame_rate, actor_count, actor_name, node_count, checksum,
--         nodes = { { name, first_child, next_sibling } },
--         frames = { { { trans = {x,y,z}, rot = {i,j,k,w}, scale } per node } per frame } }

local max_numbers = require("shared.utils.max_numbers")

local num = max_numbers.fixed6

local jma = {}

jma.SUPPORTED_VERSION = 16392

-------------------------------------------------------------------------------
-- Reading
-------------------------------------------------------------------------------

-- Lines of a text file, trimmed like readLineFromStream (text_utils.ms)
local function line_reader(path)
	local f = assert(io.open(path, "rb"))
	local text = f:read("*a")
	f:close()
	local pos, line_no = 1, 0
	return function()
		if pos > #text then error(("unexpected end of file after line %d"):format(line_no), 0) end
		local stop = text:find("\n", pos, true) or (#text + 1)
		local line = text:sub(pos, stop - 1):match("^%s*(.-)%s*$")
		pos = stop + 1
		line_no = line_no + 1
		return line, line_no
	end
end

-- MAXScript "as integer": "undefined" lines count as 0 (old JMS/JMA files)
local function to_int(line, line_no)
	if line == "undefined" then return 0 end
	local v = tonumber(line)
	if not v then error(("line %d: '%s' is not a number"):format(line_no, line), 0) end
	return v >= 0 and math.floor(v) or math.ceil(v)
end

-- First count numbers of a space/tab separated line, or nil when the line has fewer values
-- (readVectorValue/readQuatValue then used a default). Extra values are ignored.
local function to_floats(line, count, line_no)
	local tokens = {}
	for token in line:gmatch("[^ \t]+") do tokens[#tokens + 1] = token end
	if #tokens < count then return nil end
	local values = {}
	for i = 1, count do
		values[i] = tonumber(tokens[i])
		if not values[i] then error(("line %d: '%s' is not a number"):format(line_no, tokens[i]), 0) end
	end
	return values
end

-- Rotations are returned as read; the caller normalizes them (readQuatValue did it in Max).
-- A scale line that is not a number gives nil scale (Max got undefined there).
function jma.read(path)
	local next_line = line_reader(path)
	local function int() return to_int(next_line()) end
	local function floats(count)
		local line, line_no = next_line()
		return to_floats(line, count, line_no)
	end

	local data = { nodes = {}, frames = {} }
	data.version = int()
	if data.version ~= jma.SUPPORTED_VERSION then
		error(("unsupported JMA version %d (expected %d)"):format(data.version, jma.SUPPORTED_VERSION), 0)
	end
	data.frame_count = int()
	data.frame_rate = int()
	data.actor_count = int()
	data.actor_name = next_line()
	data.node_count = int()
	data.checksum = int()

	for n = 1, data.node_count do
		local name = next_line()
		data.nodes[n] = { name, int(), int() }
	end

	for f = 1, data.frame_count do
		local frame = {}
		for n = 1, data.node_count do
			local trans = floats(3) or { 0, 0, 0 }
			local rot = floats(4) or { 0, 0, 0, 1 }
			local scale = tonumber((next_line()))
			frame[n] = { trans = trans, rot = rot, scale = scale }
		end
		data.frames[f] = frame
	end
	return data
end

-------------------------------------------------------------------------------
-- Writing
-------------------------------------------------------------------------------

-- Same text as writeJmaFile: CRLF lines, numbers like formattedPrint ".6f", missing scale = 1
function jma.write(path, data)
	local parts = {
		tostring(data.version), tostring(data.frame_count), tostring(data.frame_rate),
		tostring(data.actor_count), data.actor_name, tostring(data.node_count), tostring(data.checksum),
	}
	for _, node in ipairs(data.nodes) do
		parts[#parts + 1] = node[1]
		parts[#parts + 1] = tostring(node[2])
		parts[#parts + 1] = tostring(node[3])
	end
	for _, frame in ipairs(data.frames) do
		for _, pose in ipairs(frame) do
			local t, r = pose.trans, pose.rot
			parts[#parts + 1] = num(t[1]) .. "\t" .. num(t[2]) .. "\t" .. num(t[3])
			parts[#parts + 1] = num(r[1]) .. "\t" .. num(r[2]) .. "\t" .. num(r[3]) .. "\t" .. num(r[4])
			parts[#parts + 1] = num(pose.scale or 1)
		end
	end
	local f = io.open(path, "wb")
	if not f then return false end
	f:write(table.concat(parts, "\r\n"), "\r\n")
	f:close()
	return true
end

return jma
