-- JMS model source files: read and write with the same rules as the previous MAXScript
-- reader (jms_reader.ms) and writer (process_file.ms). Values the old reader left undefined
-- (a number that did not parse) are nil here.

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

-- "x" as integer: nil when it is not a number (MAXScript gave undefined)
local function asInt(text)
	local v = text and tonumber(text)
	if not v then return nil end
	return v >= 0 and math.floor(v) or math.ceil(v)
end

-- readIntValue: like asInt, but an "undefined" line counts as 0
local function intValue(text)
	if text == "undefined" then return 0 end
	return asInt(text)
end

-- A count must be a number (the old reader failed on its loop otherwise)
local function countValue(v, what, r)
	if not v then error(("line %d: %s count is not a number"):format(r.lineNo(), what), 0) end
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
	data.version, data.checksum, data.nodeCount = asInt(header[1]), asInt(header[2]), asInt(header[3])

	-- Records with too few fields are skipped, as before
	for _ = 1, countValue(data.nodeCount, "node", r) do
		local p = split(r.line(), "\t")
		if #p >= 10 then
			data.nodes[#data.nodes + 1] = { name = p[1], child = asInt(p[2]), sibling = asInt(p[3]),
				rot = floats(p, 4, 4, r), trans = floats(p, 8, 3, r) }
		end
	end

	data.shaderCount = asInt(r.line())
	for _ = 1, countValue(data.shaderCount, "shader", r) do
		local p = split(r.line(), "\t")
		if #p >= 2 then data.shaders[#data.shaders + 1] = { name = p[1], bitmap = p[2] } end
	end

	data.markerCount = asInt(r.line())
	for _ = 1, countValue(data.markerCount, "marker", r) do
		local p = split(r.line(), "\t")
		if #p >= 11 then
			data.markers[#data.markers + 1] = { name = p[1], region = asInt(p[2]), parent = asInt(p[3]),
				rot = floats(p, 4, 4, r), trans = floats(p, 8, 3, r), radius = tonumber(p[11]) }
		end
	end

	data.regionCount = asInt(r.line())
	for _ = 1, countValue(data.regionCount, "region", r) do
		local name = r.line()
		while name == "" do name = r.line() end
		data.regions[#data.regions + 1] = name
	end

	data.vertexCount = asInt(r.line())
	for i = 1, countValue(data.vertexCount, "vertex", r) do
		local p = split(r.line(), "\t")
		if i == 1 and #p > 50 then
			error("ultra-inline JMS (all vertices on one line) is not supported; convert it with the JMS Formatter first", 0)
		end
		if #p >= 12 then
			local uv = floats(p, 10, 2, r)
			local tex = asInt(p[12])
			if not tex then error(("line %d: texture index '%s' is not a number"):format(r.lineNo(), p[12]), 0) end
			data.vertices[#data.vertices + 1] = { node0 = asInt(p[1]), pos = floats(p, 2, 3, r),
				normal = floats(p, 5, 3, r), node1 = asInt(p[8]), weight = tonumber(p[9]),
				u = uv[1], v = uv[2], tex = tex }
		end
	end

	data.triangleCount = asInt(r.line())
	for _ = 1, countValue(data.triangleCount, "triangle", r) do
		local p = split(r.line(), "\t")
		if #p >= 5 then
			local region = p[1]:lower() == "undefined" and 0 or asInt(p[1])
			data.triangles[#data.triangles + 1] = { region = region, shader = asInt(p[2]),
				a = asInt(p[3]), b = asInt(p[4]), c = asInt(p[5]) }
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
	local u, v, tex
	if #p >= 3 then
		u, v, tex = tonumber(p[1]), tonumber(p[2]), asInt(p[3])
	elseif #p == 2 then
		u, v, tex = tonumber(p[1]), tonumber(p[2]), intValue(r.line())
	elseif #p == 1 then
		u = tonumber(p[1])
		v = tonumber(r.line())
		tex = intValue(r.line())
	else
		u, v, tex = 0, 0, 0
	end
	if not (u and v and tex) then error(("line %d: texture coordinate is not a number"):format(r.lineNo()), 0) end
	return u, v, tex
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
	data.version = intValue(r.line())
	data.checksum = intValue(r.line())

	data.nodeCount = intValue(r.line())
	for _ = 1, countValue(data.nodeCount, "node", r) do
		local name = r.line()
		local child = intValue(r.line())
		local sibling = intValue(r.line())
		local rot = vectorLine(r, 4, { 0, 0, 0, 1 })
		local trans = vectorLine(r, 3, { 0, 0, 0 })
		data.nodes[#data.nodes + 1] = { name = name, child = child, sibling = sibling, rot = rot, trans = trans }
	end

	data.shaderCount = intValue(r.line())
	for _ = 1, countValue(data.shaderCount, "shader", r) do
		local name = r.line()
		data.shaders[#data.shaders + 1] = { name = name, bitmap = r.line() }
	end

	data.markerCount = intValue(r.line())
	for _ = 1, countValue(data.markerCount, "marker", r) do
		local name = r.line()
		local region = intValue(r.line())
		local parent = intValue(r.line())
		local rot = vectorLine(r, 4, { 0, 0, 0, 1 })
		local trans = vectorLine(r, 3, { 0, 0, 0 })
		data.markers[#data.markers + 1] = { name = name, region = region, parent = parent,
			rot = rot, trans = trans, radius = tonumber(r.line()) }
	end

	-- Blank lines are skipped before each region name and before the vertex count
	data.regionCount = intValue(r.line())
	for _ = 1, countValue(data.regionCount, "region", r) do
		local name = r.line()
		while name == "" do name = r.line() end
		data.regions[#data.regions + 1] = name
	end

	local countLine = r.line()
	while countLine == "" do countLine = r.line() end
	data.vertexCount = asInt(countLine)
	for _ = 1, countValue(data.vertexCount, "vertex", r) do
		local vert = {}
		vert.node0 = intValue(r.line())
		vert.pos = vectorLine(r, 3, { 0, 0, 0 })
		vert.normal = vectorLine(r, 3, { 0, 0, 0 })
		vert.node1 = intValue(r.line())
		vert.weight = tonumber(r.line())
		vert.u, vert.v, vert.tex = readUv(r)
		data.vertices[#data.vertices + 1] = vert
	end

	data.triangleCount = intValue(r.line())
	for _ = 1, countValue(data.triangleCount, "triangle", r) do
		local region = intValue(r.line())
		local shader = intValue(r.line())
		local p = split(r.line(), " \t")
		local tri = { region = region, shader = shader, a = 0, b = 0, c = 0 }
		if #p >= 3 then tri.a, tri.b, tri.c = asInt(p[1]), asInt(p[2]), asInt(p[3]) end
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

-- Values the old writer printed with format "%": integer, float or text, as Max sent them
local function valueText(v)
	if type(v) == "table" then return floatText(v.float) end
	return tostring(v)
end

local function fixedList(values)
	local out = {}
	for i, v in ipairs(values) do out[i] = fixed6(v) end
	return table.concat(out, "\t")
end

-- data uses the read layout, except that values printed with format "%" can be numbers,
-- strings or { float = x }, and smoothing groups are written only when writeSmoothing is set
function jms.write(path, data)
	local lines = {}
	local function add(text) lines[#lines + 1] = text end
	add(valueText(data.version))
	add(valueText(data.checksum))
	add(valueText(data.nodeCount))
	for _, n in ipairs(data.nodes) do
		add(valueText(n.name))
		add(valueText(n.child))
		add(valueText(n.sibling))
		add(fixedList(n.rot))
		add(fixedList(n.trans))
	end
	add(valueText(data.shaderCount))
	for _, s in ipairs(data.shaders) do
		add(valueText(s.name))
		add(valueText(s.bitmap))
	end
	add(valueText(data.markerCount))
	for _, m in ipairs(data.markers) do
		add(valueText(m.name))
		add(valueText(m.region))
		add(valueText(m.parent))
		add(fixedList(m.rot))
		add(fixedList(m.trans))
		add(fixed6(m.radius))
	end
	add(valueText(data.regionCount))
	for _, name in ipairs(data.regions) do add(valueText(name)) end
	add(valueText(data.vertexCount))
	for _, v in ipairs(data.vertices) do
		add(valueText(v.node0))
		add(fixedList(v.pos))
		add(fixedList(v.normal))
		add(valueText(v.node1))
		add(valueText(v.weight))
		add(fixed6(v.u))
		add(fixed6(v.v))
		add(valueText(v.tex))
	end
	add(valueText(data.triangleCount))
	for _, t in ipairs(data.triangles) do
		add(valueText(t.region))
		add(valueText(t.shader))
		add(valueText(t.a) .. "\t" .. valueText(t.b) .. "\t" .. valueText(t.c))
	end
	if data.writeSmoothing then
		add("")
		add(";### SMOOTHING GROUPS ###")
		add(valueText(#data.smoothingGroups))
		for _, sg in ipairs(data.smoothingGroups) do add(valueText(sg)) end
	end

	local f = io.open(path, "wb")
	if not f then return false end
	f:write(table.concat(lines, "\r\n"), "\r\n")
	f:close()
	return true
end

return jms
