-- JMS files for 3ds Max (formats\jms\jms_reader.ms and process_file.ms):
--   luajit jms_cli.lua read <file.jms> <out.bin>    JMS -> binary for Max
--   luajit jms_cli.lua write <in.bin> <file.jms>    binary from Max -> JMS
--   luajit jms_cli.lua mesh <in.bin> <out.bin>      scene meshes -> JMS vertices (process_scene.ms)
-- Errors go to stderr with exit code 1.

-- Modules are required from the lua folder: require("formats.jms")
local luaDir = ((arg[0]:match("^(.*)[/\\]") or ".") .. "/..")
package.path = luaDir .. "/?.lua;" .. package.path

local jms = require("formats.jms")
local jmsMesh = require("formats.jms_mesh")
local maxbin = require("bridge.maxbin")

-- Format version of the binaries exchanged with Max (checked on both sides)
local FORMAT = "jms"
local VERSION = 1

-- Integers the old reader left undefined travel as this value (luaReadMaybeInt in lua_bridge.ms)
local UNDEFINED_INT = -2147483648

local function read(jmsPath, outPath)
	local data = jms.read(jmsPath)
	local w = maxbin.open(outPath)
	local function maybe(v) w:int(v or UNDEFINED_INT) end
	local undefinedFloats = {} -- { kind, index }: 1 = marker radius, 2 = vertex weight

	w:string(FORMAT)
	w:int(VERSION)
	-- Standard files had their rotations normalized by the old reader; inline ones did not
	w:int(data.inline and 0 or 1)
	maybe(data.version)
	maybe(data.checksum)

	w:int(data.nodeCount)
	w:int(#data.nodes)
	for _, n in ipairs(data.nodes) do
		w:string(n.name)
		maybe(n.child)
		maybe(n.sibling)
		w:floats(n.rot)
		w:floats(n.trans)
	end

	w:int(data.shaderCount)
	w:int(#data.shaders)
	for _, s in ipairs(data.shaders) do
		w:string(s.name)
		w:string(s.bitmap)
	end

	w:int(data.markerCount)
	w:int(#data.markers)
	for i, m in ipairs(data.markers) do
		w:string(m.name)
		maybe(m.region)
		maybe(m.parent)
		w:floats(m.rot)
		w:floats(m.trans)
		w:float(m.radius or 0)
		if not m.radius then undefinedFloats[#undefinedFloats + 1] = { 1, i } end
	end

	w:int(data.regionCount)
	w:int(#data.regions)
	for _, name in ipairs(data.regions) do w:string(name) end

	w:int(data.vertexCount)
	w:int(#data.vertices)
	for i, v in ipairs(data.vertices) do
		maybe(v.node0)
		w:floats(v.pos)
		w:floats(v.normal)
		maybe(v.node1)
		w:float(v.weight or 0)
		w:floats({ v.u, v.v })
		w:int(v.tex)
		if not v.weight then undefinedFloats[#undefinedFloats + 1] = { 2, i } end
	end

	w:int(data.triangleCount)
	w:int(#data.triangles)
	for _, t in ipairs(data.triangles) do
		maybe(t.region)
		maybe(t.shader)
		maybe(t.a)
		maybe(t.b)
		maybe(t.c)
	end

	w:int(#data.smoothingGroups)
	if #data.smoothingGroups > 0 then w:ints(data.smoothingGroups) end

	w:int(#undefinedFloats)
	for _, u in ipairs(undefinedFloats) do w:ints(u) end
	w:close()
end

-- Value Max printed with format "%": 1 integer, 2 float, 3 text (luaWriteValue in lua_bridge.ms)
local function value(r)
	local kind = r:int()
	if kind == 1 then return r:int()
	elseif kind == 2 then return { float = r:float() }
	elseif kind == 3 then return r:string()
	end
	error("unexpected value type " .. kind .. " in the data from Max", 0)
end

local function write(inPath, jmsPath)
	local r = maxbin.readFile(inPath)
	if r:string() ~= FORMAT or r:int() ~= VERSION then error("unexpected data from Max (expected jms v1)", 0) end
	local function floats(n)
		local t = {}
		for i = 1, n do t[i] = r:float() end
		return t
	end
	local data = { nodes = {}, shaders = {}, markers = {}, regions = {}, vertices = {}, triangles = {},
		smoothingGroups = {} }

	data.version, data.checksum, data.nodeCount = value(r), value(r), value(r)
	for i = 1, r:int() do
		data.nodes[i] = { name = value(r), child = value(r), sibling = value(r), rot = floats(4), trans = floats(3) }
	end
	data.shaderCount = value(r)
	for i = 1, r:int() do data.shaders[i] = { name = value(r), bitmap = value(r) } end
	data.markerCount = value(r)
	for i = 1, r:int() do
		data.markers[i] = { name = value(r), region = value(r), parent = value(r), rot = floats(4), trans = floats(3),
			radius = r:float() }
	end
	data.regionCount = value(r)
	for i = 1, r:int() do data.regions[i] = value(r) end
	data.vertexCount = value(r)
	for i = 1, r:int() do
		data.vertices[i] = { node0 = value(r), pos = floats(3), normal = floats(3), node1 = value(r),
			weight = value(r), u = r:float(), v = r:float(), tex = value(r) }
	end
	data.triangleCount = value(r)
	for i = 1, r:int() do
		data.triangles[i] = { region = value(r), shader = value(r), a = value(r), b = value(r), c = value(r) }
	end
	data.writeSmoothing = r:int() == 1
	if data.writeSmoothing then
		for i = 1, r:int() do data.smoothingGroups[i] = value(r) end
	end
	if not jms.write(jmsPath, data) then error("cannot write " .. jmsPath, 0) end
end

-- Scene meshes from Max (extractGeometryData) -> JMS vertices + the vertex of every face corner
local function mesh(inPath, outPath)
	local r = maxbin.readFile(inPath)
	if r:string() ~= "jms_mesh" or r:int() ~= 2 then error("unexpected data from Max (expected jms_mesh v2)", 0) end
	local vertices, corners = {}, {}
	for _ = 1, r:int() do
		local obj = { parent = r:int(), positions = {}, uvs = {}, faces = {}, normals = {} }
		for i = 1, r:int() * 3 do obj.positions[i] = r:float() end
		if r:int() == 1 then
			obj.skin = {}
			for v = 1, #obj.positions / 3 do
				local bones, weights = {}, {}
				for i = 1, r:int() do
					bones[i] = r:int()
					weights[i] = r:float()
				end
				obj.skin[v] = { bones, weights }
			end
		end
		local uvCount = r:int()
		for i = 1, uvCount * 2 do obj.uvs[i] = r:float() end
		if uvCount > 0 then obj.tvfaces = {} end
		local faces, tvfaces, normals = obj.faces, obj.tvfaces, obj.normals
		local faceCount = r:int()
		-- Normals saved in one go (file, count, rotMatrix rows), or per corner with each face
		local saved
		if r:int() == 1 then
			saved = { path = r:string(), count = r:int(), m = {} }
			for i = 1, 12 do saved.m[i] = r:float() end
		end
		for f = 0, faceCount - 1 do
			for c = 1, 3 do faces[f * 3 + c] = r:int() end
			if tvfaces then
				for c = 1, 3 do tvfaces[f * 3 + c] = r:int() end
			end
			if not saved then
				for i = 1, 9 do normals[f * 9 + i] = r:float() end
			end
		end
		if saved then obj.normals = jmsMesh.savedNormals(saved.path, saved.count, faceCount, saved.m) end
		jmsMesh.addObject(obj, vertices, corners)
	end

	local w = maxbin.open(outPath)
	w:string("jms_mesh")
	w:int(1)
	w:int(#vertices)
	for _, v in ipairs(vertices) do
		w:int(v.node0)
		w:floats(v.pos)
		w:floats(v.normal)
		w:int(v.node1)
		w:floats({ v.weight, v.u, v.v })
	end
	w:int(#corners)
	if #corners > 0 then w:ints(corners) end
	w:close()
end

local command, a, b = arg[1], arg[2], arg[3]
local ok, err = pcall(function()
	if command == "read" and a and b then read(a, b)
	elseif command == "write" and a and b then write(a, b)
	elseif command == "mesh" and a and b then mesh(a, b)
	else error("usage: luajit jms_cli.lua read <file.jms> <out.bin> | write <in.bin> <file.jms> | mesh <in.bin> <out.bin>", 0)
	end
end)
if not ok then
	io.stderr:write(tostring(err), "\n")
	os.exit(1)
end
