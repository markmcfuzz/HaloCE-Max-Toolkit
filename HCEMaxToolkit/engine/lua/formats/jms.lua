-- JMS model source files: read and write with the same rules as the previous MAXScript
-- reader (jms_reader.ms) and writer (process_file.ms). Values the old reader left undefined
-- (a number that did not parse) are nil here.

local max_numbers = require("shared.utils.max_numbers")

local fixed6, float_text = max_numbers.fixed6, max_numbers.float_text

local jms = {}

-------------------------------------------------------------------------------
-- Text helpers (MAXScript rules)
-------------------------------------------------------------------------------

-- Lines trimmed like readLineFromStream; nil at the end of the file
local function line_reader(path)
	local f = assert(io.open(path, "rb"))
	local text = f:read("*a")
	f:close()
	local pos, line_no = 1, 0
	local reader = {}
	function reader.peek_line()
		if pos > #text then return nil end
		local stop = text:find("\n", pos, true) or (#text + 1)
		return text:sub(pos, stop - 1):match("^%s*(.-)%s*$"), stop + 1
	end
	-- readLine fails at the end of the file
	function reader.line()
		local line, next_pos = reader.peek_line()
		if not line then error(("unexpected end of file after line %d"):format(line_no), 0) end
		pos = next_pos
		line_no = line_no + 1
		return line
	end
	function reader.at_end() return pos > #text end
	function reader.line_no() return line_no end
	return reader
end

-- "x" as integer: nil when it is not a number (MAXScript gave undefined)
local function as_int(text)
	local v = text and tonumber(text)
	if not v then return nil end
	return v >= 0 and math.floor(v) or math.ceil(v)
end

-- readIntValue: like as_int, but an "undefined" line counts as 0
local function int_value(text)
	if text == "undefined" then return 0 end
	return as_int(text)
end

-- A count must be a number (the old reader failed on its loop otherwise)
local function count_value(v, what, r)
	if not v then error(("line %d: %s count is not a number"):format(r.line_no(), what), 0) end
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
		if not v then error(("line %d: '%s' is not a number"):format(r.line_no(), tostring(parts[first + i])), 0) end
		values[i + 1] = v
	end
	return values
end

-- readVectorValue / readQuatValue: fewer values than needed give the default
local function vector_line(r, count, default)
	local parts = split(r.line(), " \t")
	if #parts < count then return default end
	return floats(parts, 1, count, r)
end

-------------------------------------------------------------------------------
-- Inline format (old exporters: one record per line, tab separated)
-------------------------------------------------------------------------------

local function read_inline(r, first_line, data)
	local header = split(first_line, " \t")
	data.version, data.checksum, data.node_count = as_int(header[1]), as_int(header[2]), as_int(header[3])

	-- Records with too few fields are skipped, as before
	for _ = 1, count_value(data.node_count, "node", r) do
		local p = split(r.line(), "\t")
		if #p >= 10 then
			data.nodes[#data.nodes + 1] = { name = p[1], child = as_int(p[2]), sibling = as_int(p[3]),
				rot = floats(p, 4, 4, r), trans = floats(p, 8, 3, r) }
		end
	end

	data.shader_count = as_int(r.line())
	for _ = 1, count_value(data.shader_count, "shader", r) do
		local p = split(r.line(), "\t")
		if #p >= 2 then data.shaders[#data.shaders + 1] = { name = p[1], bitmap = p[2] } end
	end

	data.marker_count = as_int(r.line())
	for _ = 1, count_value(data.marker_count, "marker", r) do
		local p = split(r.line(), "\t")
		if #p >= 11 then
			data.markers[#data.markers + 1] = { name = p[1], region = as_int(p[2]), parent = as_int(p[3]),
				rot = floats(p, 4, 4, r), trans = floats(p, 8, 3, r), radius = tonumber(p[11]) }
		end
	end

	data.region_count = as_int(r.line())
	for _ = 1, count_value(data.region_count, "region", r) do
		local name = r.line()
		while name == "" do name = r.line() end
		data.regions[#data.regions + 1] = name
	end

	data.vertex_count = as_int(r.line())
	for i = 1, count_value(data.vertex_count, "vertex", r) do
		local p = split(r.line(), "\t")
		if i == 1 and #p > 50 then
			error("ultra-inline JMS (all vertices on one line) is not supported; convert it with the JMS Formatter first", 0)
		end
		if #p >= 12 then
			local uv = floats(p, 10, 2, r)
			local tex = as_int(p[12])
			if not tex then error(("line %d: texture index '%s' is not a number"):format(r.line_no(), p[12]), 0) end
			data.vertices[#data.vertices + 1] = { node0 = as_int(p[1]), pos = floats(p, 2, 3, r),
				normal = floats(p, 5, 3, r), node1 = as_int(p[8]), weight = tonumber(p[9]),
				u = uv[1], v = uv[2], tex = tex }
		end
	end

	data.triangle_count = as_int(r.line())
	for _ = 1, count_value(data.triangle_count, "triangle", r) do
		local p = split(r.line(), "\t")
		if #p >= 5 then
			local region = p[1]:lower() == "undefined" and 0 or as_int(p[1])
			data.triangles[#data.triangles + 1] = { region = region, shader = as_int(p[2]),
				a = as_int(p[3]), b = as_int(p[4]), c = as_int(p[5]) }
		end
	end
end

-------------------------------------------------------------------------------
-- Standard format (toolkit, Blender, invader-recover, fbx-to-jms: one value per line)
-------------------------------------------------------------------------------

-- UV line layouts: "u v index" (invader-recover), "u v" + index line (Blender/fbx),
-- or u, v and index on three lines (toolkit). An empty line gives 0, 0, 0.
local function read_uv(r)
	local p = split(r.line(), " \t")
	local u, v, tex
	if #p >= 3 then
		u, v, tex = tonumber(p[1]), tonumber(p[2]), as_int(p[3])
	elseif #p == 2 then
		u, v, tex = tonumber(p[1]), tonumber(p[2]), int_value(r.line())
	elseif #p == 1 then
		u = tonumber(p[1])
		v = tonumber(r.line())
		tex = int_value(r.line())
	else
		u, v, tex = 0, 0, 0
	end
	if not (u and v and tex) then error(("line %d: texture coordinate is not a number"):format(r.line_no()), 0) end
	return u, v, tex
end

-- ";### SMOOTHING GROUPS ###" section after the triangles (optional). The old reader stopped
-- quietly at the end of the file; lines that are not numbers count as 0.
local function read_smoothing_groups(r, data)
	if r.at_end() then return end
	local line = r.line()
	while line == "" do
		if r.at_end() then return end
		line = r.line()
	end
	if line ~= ";### SMOOTHING GROUPS ###" or r.at_end() then return end
	local count = as_int(r.line()) or 0
	for _ = 1, count do
		if r.at_end() then return end
		data.smoothing_groups[#data.smoothing_groups + 1] = as_int(r.line()) or 0
	end
end

local function read_standard(r, data)
	data.version = int_value(r.line())
	data.checksum = int_value(r.line())

	data.node_count = int_value(r.line())
	for _ = 1, count_value(data.node_count, "node", r) do
		local name = r.line()
		local child = int_value(r.line())
		local sibling = int_value(r.line())
		local rot = vector_line(r, 4, { 0, 0, 0, 1 })
		local trans = vector_line(r, 3, { 0, 0, 0 })
		data.nodes[#data.nodes + 1] = { name = name, child = child, sibling = sibling, rot = rot, trans = trans }
	end

	data.shader_count = int_value(r.line())
	for _ = 1, count_value(data.shader_count, "shader", r) do
		local name = r.line()
		data.shaders[#data.shaders + 1] = { name = name, bitmap = r.line() }
	end

	data.marker_count = int_value(r.line())
	for _ = 1, count_value(data.marker_count, "marker", r) do
		local name = r.line()
		local region = int_value(r.line())
		local parent = int_value(r.line())
		local rot = vector_line(r, 4, { 0, 0, 0, 1 })
		local trans = vector_line(r, 3, { 0, 0, 0 })
		data.markers[#data.markers + 1] = { name = name, region = region, parent = parent,
			rot = rot, trans = trans, radius = tonumber(r.line()) }
	end

	-- Blank lines are skipped before each region name and before the vertex count
	data.region_count = int_value(r.line())
	for _ = 1, count_value(data.region_count, "region", r) do
		local name = r.line()
		while name == "" do name = r.line() end
		data.regions[#data.regions + 1] = name
	end

	local count_line = r.line()
	while count_line == "" do count_line = r.line() end
	data.vertex_count = as_int(count_line)
	for _ = 1, count_value(data.vertex_count, "vertex", r) do
		local vert = {}
		vert.node0 = int_value(r.line())
		vert.pos = vector_line(r, 3, { 0, 0, 0 })
		vert.normal = vector_line(r, 3, { 0, 0, 0 })
		vert.node1 = int_value(r.line())
		vert.weight = tonumber(r.line())
		vert.u, vert.v, vert.tex = read_uv(r)
		data.vertices[#data.vertices + 1] = vert
	end

	data.triangle_count = int_value(r.line())
	for _ = 1, count_value(data.triangle_count, "triangle", r) do
		local region = int_value(r.line())
		local shader = int_value(r.line())
		local p = split(r.line(), " \t")
		local tri = { region = region, shader = shader, a = 0, b = 0, c = 0 }
		if #p >= 3 then tri.a, tri.b, tri.c = as_int(p[1]), as_int(p[2]), as_int(p[3]) end
		data.triangles[#data.triangles + 1] = tri
	end

	read_smoothing_groups(r, data)
end

-- Returns the JMS data; inline = true for the old one-record-per-line format
-- (its rotations were not normalized; standard ones were, in Max).
function jms.read(path)
	local r = line_reader(path)
	local data = { nodes = {}, shaders = {}, markers = {}, regions = {}, vertices = {}, triangles = {},
		smoothing_groups = {} }
	local first_line = r.line()
	data.inline = #split(first_line, " \t") >= 3
	if data.inline then
		read_inline(r, first_line, data)
	else
		-- Read again from the first line
		r = line_reader(path)
		read_standard(r, data)
	end
	return data
end

-------------------------------------------------------------------------------
-- Writing (same text as writeJmsFile)
-------------------------------------------------------------------------------

-- Values the old writer printed with format "%": integer, float or text, as Max sent them
local function value_text(v)
	if type(v) == "table" then return float_text(v.float) end
	return tostring(v)
end

local function fixed_list(values)
	local out = {}
	for i, v in ipairs(values) do out[i] = fixed6(v) end
	return table.concat(out, "\t")
end

-- data uses the read layout, except that values printed with format "%" can be numbers,
-- strings or { float = x }, and smoothing groups are written only when write_smoothing is set
function jms.write(path, data)
	local lines = {}
	local function add(text) lines[#lines + 1] = text end
	add(value_text(data.version))
	add(value_text(data.checksum))
	add(value_text(data.node_count))
	for _, n in ipairs(data.nodes) do
		add(value_text(n.name))
		add(value_text(n.child))
		add(value_text(n.sibling))
		add(fixed_list(n.rot))
		add(fixed_list(n.trans))
	end
	add(value_text(data.shader_count))
	for _, s in ipairs(data.shaders) do
		add(value_text(s.name))
		add(value_text(s.bitmap))
	end
	add(value_text(data.marker_count))
	for _, m in ipairs(data.markers) do
		add(value_text(m.name))
		add(value_text(m.region))
		add(value_text(m.parent))
		add(fixed_list(m.rot))
		add(fixed_list(m.trans))
		add(fixed6(m.radius))
	end
	add(value_text(data.region_count))
	for _, name in ipairs(data.regions) do add(value_text(name)) end
	add(value_text(data.vertex_count))
	for _, v in ipairs(data.vertices) do
		add(value_text(v.node0))
		add(fixed_list(v.pos))
		add(fixed_list(v.normal))
		add(value_text(v.node1))
		add(value_text(v.weight))
		add(fixed6(v.u))
		add(fixed6(v.v))
		add(value_text(v.tex))
	end
	add(value_text(data.triangle_count))
	for _, t in ipairs(data.triangles) do
		add(value_text(t.region))
		add(value_text(t.shader))
		add(value_text(t.a) .. "\t" .. value_text(t.b) .. "\t" .. value_text(t.c))
	end
	if data.write_smoothing then
		add("")
		add(";### SMOOTHING GROUPS ###")
		add(value_text(#data.smoothing_groups))
		for _, sg in ipairs(data.smoothing_groups) do add(value_text(sg)) end
	end

	local f = io.open(path, "wb")
	if not f then return false end
	f:write(table.concat(lines, "\r\n"), "\r\n")
	f:close()
	return true
end

return jms
