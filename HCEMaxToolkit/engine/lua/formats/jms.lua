-- JMS model source files: read and write with the same rules as the previous MAXScript
-- reader (jms_reader.ms) and writer (process_file.ms). A value that is not a number is an
-- error with its line number.

local maxNumbers = require("formats.max_numbers")

local fixed6, floatText = maxNumbers.fixed6, maxNumbers.floatText

local jms = {}

-------------------------------------------------------------------------------
-- Text helpers (MAXScript rules)
-------------------------------------------------------------------------------

-- Lines trimmed like readLineFromStream; nil at the end of the file
local function lineReader(path)
	local f = assert(io.open(path, "rb"))
	local text = f:read("*a")
	f:close()
	local pos, lineNo = 1, 0
	local reader = {}
	function reader.peekLine()
		if pos > #text then return nil end
		local stop = text:find("\n", pos, true) or (#text + 1)
		return text:sub(pos, stop - 1):match("^%s*(.-)%s*$"), stop + 1
	end
	-- readLine fails at the end of the file
	function reader.line()
		local line, nextPos = reader.peekLine()
		if not line then error(("unexpected end of file after line %d"):format(lineNo), 0) end
		pos = nextPos
		lineNo = lineNo + 1
		return line
	end
	function reader.atEnd() return pos > #text end
	function reader.lineNo() return lineNo end
	return reader
end

-- "x" as integer (MAXScript "as integer"), or nil when it is not a number
local function asInt(text)
	local v = text and tonumber(text)
	if not v then return nil end
	return v >= 0 and math.floor(v) or math.ceil(v)
end

-- Integer of the current line; "undefined" counts as 0 (old toolkit files have it)
local function toInt(text, r)
	if text and text:lower() == "undefined" then return 0 end
	local v = asInt(text)
	if not v then error(("line %d: '%s' is not a number"):format(r.lineNo(), tostring(text)), 0) end
	return v
end

local function toFloat(text, r)
	local v = text and tonumber(text)
	if not v then error(("line %d: '%s' is not a number"):format(r.lineNo(), tostring(text)), 0) end
	return v
end

local function split(text, separators)
	local parts = {}
	for token in text:gmatch("[^" .. separators .. "]+") do parts[#parts + 1] = token end
	return parts
end

-- Numbers that went into a Point3/quat: the old reader failed when one did not parse
local function floats(parts, first, count, r)
	local values = {}
	for i = 0, count - 1 do
		local v = tonumber(parts[first + i])
		if not v then error(("line %d: '%s' is not a number"):format(r.lineNo(), tostring(parts[first + i])), 0) end
		values[i + 1] = v
	end
	return values
end

-- readVectorValue / readQuatValue: fewer values than needed give the default
local function vectorLine(r, count, default)
	local parts = split(r.line(), " \t")
	if #parts < count then return default end
	return floats(parts, 1, count, r)
end

-------------------------------------------------------------------------------
-- Inline format (old exporters: one record per line, tab separated)
-------------------------------------------------------------------------------

local function readInline(r, firstLine, data)
	local header = split(firstLine, " \t")
	data.version, data.checksum = toInt(header[1], r), toInt(header[2], r)
	data.nodeCount = toInt(header[3], r)

	-- Records with too few fields are skipped, as before
	for _ = 1, data.nodeCount do
		local p = split(r.line(), "\t")
		if #p >= 10 then
			data.nodes[#data.nodes + 1] = { name = p[1], child = toInt(p[2], r), sibling = toInt(p[3], r),
				rot = floats(p, 4, 4, r), trans = floats(p, 8, 3, r) }
		end
	end

	data.shaderCount = toInt(r.line(), r)
	for _ = 1, data.shaderCount do
		local p = split(r.line(), "\t")
		if #p >= 2 then data.shaders[#data.shaders + 1] = { name = p[1], bitmap = p[2] } end
	end

	data.markerCount = toInt(r.line(), r)
	for _ = 1, data.markerCount do
		local p = split(r.line(), "\t")
		if #p >= 11 then
			data.markers[#data.markers + 1] = { name = p[1], region = toInt(p[2], r), parent = toInt(p[3], r),
				rot = floats(p, 4, 4, r), trans = floats(p, 8, 3, r), radius = toFloat(p[11], r) }
		end
	end

	data.regionCount = toInt(r.line(), r)
	for _ = 1, data.regionCount do
		local name = r.line()
		while name == "" do name = r.line() end
		data.regions[#data.regions + 1] = name
	end

	data.vertexCount = toInt(r.line(), r)
	for i = 1, data.vertexCount do
		local p = split(r.line(), "\t")
		if i == 1 and #p > 50 then
			error("ultra-inline JMS (all vertices on one line) is not supported; convert it with the JMS Formatter first", 0)
		end
		if #p >= 12 then
			local uv = floats(p, 10, 2, r)
			data.vertices[#data.vertices + 1] = { node0 = toInt(p[1], r), pos = floats(p, 2, 3, r),
				normal = floats(p, 5, 3, r), node1 = toInt(p[8], r), weight = toFloat(p[9], r),
				u = uv[1], v = uv[2], tex = toInt(p[12], r) }
		end
	end

	data.triangleCount = toInt(r.line(), r)
	for _ = 1, data.triangleCount do
		local p = split(r.line(), "\t")
		if #p >= 5 then
			data.triangles[#data.triangles + 1] = { region = toInt(p[1], r), shader = toInt(p[2], r),
				a = toInt(p[3], r), b = toInt(p[4], r), c = toInt(p[5], r) }
		end
	end
end

-------------------------------------------------------------------------------
-- Standard format (toolkit, Blender, invader-recover, fbx-to-jms: one value per line)
-------------------------------------------------------------------------------

-- UV line layouts: "u v index" (invader-recover), "u v" + index line (Blender/fbx),
-- or u, v and index on three lines (toolkit). An empty line gives 0, 0, 0.
local function readUv(r)
	local p = split(r.line(), " \t")
	if #p >= 3 then
		return toFloat(p[1], r), toFloat(p[2], r), toInt(p[3], r)
	elseif #p == 2 then
		local u, v = toFloat(p[1], r), toFloat(p[2], r)
		return u, v, toInt(r.line(), r)
	elseif #p == 1 then
		local u = toFloat(p[1], r)
		local v = toFloat(r.line(), r)
		return u, v, toInt(r.line(), r)
	end
	return 0, 0, 0
end

-- ";### SMOOTHING GROUPS ###" section after the triangles (optional). The old reader stopped
-- quietly at the end of the file; lines that are not numbers count as 0.
local function readSmoothingGroups(r, data)
	if r.atEnd() then return end
	local line = r.line()
	while line == "" do
		if r.atEnd() then return end
		line = r.line()
	end
	if line ~= ";### SMOOTHING GROUPS ###" or r.atEnd() then return end
	local count = asInt(r.line()) or 0
	for _ = 1, count do
		if r.atEnd() then return end
		data.smoothingGroups[#data.smoothingGroups + 1] = asInt(r.line()) or 0
	end
end

local function readStandard(r, data)
	data.version = toInt(r.line(), r)
	data.checksum = toInt(r.line(), r)

	data.nodeCount = toInt(r.line(), r)
	for _ = 1, data.nodeCount do
		local name = r.line()
		local child = toInt(r.line(), r)
		local sibling = toInt(r.line(), r)
		local rot = vectorLine(r, 4, { 0, 0, 0, 1 })
		local trans = vectorLine(r, 3, { 0, 0, 0 })
		data.nodes[#data.nodes + 1] = { name = name, child = child, sibling = sibling, rot = rot, trans = trans }
	end

	data.shaderCount = toInt(r.line(), r)
	for _ = 1, data.shaderCount do
		local name = r.line()
		data.shaders[#data.shaders + 1] = { name = name, bitmap = r.line() }
	end

	data.markerCount = toInt(r.line(), r)
	for _ = 1, data.markerCount do
		local name = r.line()
		local region = toInt(r.line(), r)
		local parent = toInt(r.line(), r)
		local rot = vectorLine(r, 4, { 0, 0, 0, 1 })
		local trans = vectorLine(r, 3, { 0, 0, 0 })
		data.markers[#data.markers + 1] = { name = name, region = region, parent = parent,
			rot = rot, trans = trans, radius = toFloat(r.line(), r) }
	end

	-- Blank lines are skipped before each region name and before the vertex count
	data.regionCount = toInt(r.line(), r)
	for _ = 1, data.regionCount do
		local name = r.line()
		while name == "" do name = r.line() end
		data.regions[#data.regions + 1] = name
	end

	local countLine = r.line()
	while countLine == "" do countLine = r.line() end
	data.vertexCount = toInt(countLine, r)
	for _ = 1, data.vertexCount do
		local vert = {}
		vert.node0 = toInt(r.line(), r)
		vert.pos = vectorLine(r, 3, { 0, 0, 0 })
		vert.normal = vectorLine(r, 3, { 0, 0, 0 })
		vert.node1 = toInt(r.line(), r)
		vert.weight = toFloat(r.line(), r)
		vert.u, vert.v, vert.tex = readUv(r)
		data.vertices[#data.vertices + 1] = vert
	end

	data.triangleCount = toInt(r.line(), r)
	for _ = 1, data.triangleCount do
		local region = toInt(r.line(), r)
		local shader = toInt(r.line(), r)
		local p = split(r.line(), " \t")
		local tri = { region = region, shader = shader, a = 0, b = 0, c = 0 }
		if #p >= 3 then tri.a, tri.b, tri.c = toInt(p[1], r), toInt(p[2], r), toInt(p[3], r) end
		data.triangles[#data.triangles + 1] = tri
	end

	readSmoothingGroups(r, data)
end

-- Returns the JMS data; inline = true for the old one-record-per-line format
-- (its rotations were not normalized; standard ones were, in Max).
function jms.read(path)
	local r = lineReader(path)
	local data = { nodes = {}, shaders = {}, markers = {}, regions = {}, vertices = {}, triangles = {},
		smoothingGroups = {} }
	local firstLine = r.line()
	data.inline = #split(firstLine, " \t") >= 3
	if data.inline then
		readInline(r, firstLine, data)
	else
		-- Read again from the first line
		r = lineReader(path)
		readStandard(r, data)
	end
	return data
end

-------------------------------------------------------------------------------
-- Writing (same text as writeJmsFile)
-------------------------------------------------------------------------------

local function fixedList(values)
	local out = {}
	for i, v in ipairs(values) do out[i] = fixed6(v) end
	return table.concat(out, "\t")
end

-- data uses the read layout; smoothing groups are written only when writeSmoothing is set.
-- The weight is printed like MAXScript format "%", other floats with 6 decimals.
function jms.write(path, data)
	local lines = {}
	local function add(text) lines[#lines + 1] = text end
	add(tostring(data.version))
	add(tostring(data.checksum))
	add(tostring(data.nodeCount))
	for _, n in ipairs(data.nodes) do
		add(n.name)
		add(tostring(n.child))
		add(tostring(n.sibling))
		add(fixedList(n.rot))
		add(fixedList(n.trans))
	end
	add(tostring(data.shaderCount))
	for _, s in ipairs(data.shaders) do
		add(s.name)
		add(s.bitmap)
	end
	add(tostring(data.markerCount))
	for _, m in ipairs(data.markers) do
		add(m.name)
		add(tostring(m.region))
		add(tostring(m.parent))
		add(fixedList(m.rot))
		add(fixedList(m.trans))
		add(fixed6(m.radius))
	end
	add(tostring(data.regionCount))
	for _, name in ipairs(data.regions) do add(name) end
	add(tostring(data.vertexCount))
	for _, v in ipairs(data.vertices) do
		add(tostring(v.node0))
		add(fixedList(v.pos))
		add(fixedList(v.normal))
		add(tostring(v.node1))
		add(floatText(v.weight))
		add(fixed6(v.u))
		add(fixed6(v.v))
		add(tostring(v.tex))
	end
	add(tostring(data.triangleCount))
	for _, t in ipairs(data.triangles) do
		add(tostring(t.region))
		add(tostring(t.shader))
		add(tostring(t.a) .. "\t" .. tostring(t.b) .. "\t" .. tostring(t.c))
	end
	if data.writeSmoothing then
		add("")
		add(";### SMOOTHING GROUPS ###")
		add(tostring(#data.smoothingGroups))
		for _, sg in ipairs(data.smoothingGroups) do add(tostring(sg)) end
	end

	local f = io.open(path, "wb")
	if not f then return false end
	f:write(table.concat(lines, "\r\n"), "\r\n")
	f:close()
	return true
end

return jms
