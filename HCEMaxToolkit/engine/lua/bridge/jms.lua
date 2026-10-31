-- JMS files for 3ds Max (formats\jms\jms_reader.ms, process_file.ms and process_scene.ms):
--   run.lua bridge.jms read <file.jms> <out.bin>    JMS -> binary for Max
--   run.lua bridge.jms write <in.bin> <file.jms>    binary from Max -> JMS
--   run.lua bridge.jms mesh <in.bin> <out.bin>      scene meshes -> JMS vertices

local jms = require("formats.jms")
local jmsMesh = require("formats.jms_mesh")
local maxbin = require("bridge.maxbin")

local jmsBridge = {}

-- Format version of the binaries exchanged with Max (checked on both sides)
local FORMAT = "jms"
local VERSION = 2

function jmsBridge.read(jmsPath, outPath)
	local data = jms.read(jmsPath)
	local w = maxbin.open(outPath)

	w:string(FORMAT)
	w:int(VERSION)
	-- Standard files had their rotations normalized by the old reader; inline ones did not
	w:int(data.inline and 0 or 1)
	w:ints({ data.version, data.checksum })

	w:int(data.nodeCount)
	w:int(#data.nodes)
	for _, n in ipairs(data.nodes) do
		w:string(n.name)
		w:ints({ n.child, n.sibling })
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
	for _, m in ipairs(data.markers) do
		w:string(m.name)
		w:ints({ m.region, m.parent })
		w:floats(m.rot)
		w:floats(m.trans)
		w:float(m.radius)
	end

	w:int(data.regionCount)
	w:int(#data.regions)
	for _, name in ipairs(data.regions) do w:string(name) end

	w:int(data.vertexCount)
	w:int(#data.vertices)
	for _, v in ipairs(data.vertices) do
		w:int(v.node0)
		w:floats(v.pos)
		w:floats(v.normal)
		w:int(v.node1)
		w:floats({ v.weight, v.u, v.v })
		w:int(v.tex)
	end

	w:int(data.triangleCount)
	w:int(#data.triangles)
	for _, t in ipairs(data.triangles) do
		w:ints({ t.region, t.shader, t.a, t.b, t.c })
	end

	w:int(#data.smoothingGroups)
	if #data.smoothingGroups > 0 then w:ints(data.smoothingGroups) end
	w:close()
end

function jmsBridge.write(inPath, jmsPath)
	local r = maxbin.readFile(inPath)
	if r:string() ~= FORMAT or r:int() ~= VERSION then
		error(("unexpected data from Max (expected %s v%d)"):format(FORMAT, VERSION), 0)
	end
	local function floats(n)
		local t = {}
		for i = 1, n do t[i] = r:float() end
		return t
	end
	local data = { nodes = {}, shaders = {}, markers = {}, regions = {}, vertices = {}, triangles = {},
		smoothingGroups = {} }

	data.version, data.checksum, data.nodeCount = r:int(), r:int(), r:int()
	for i = 1, r:int() do
		data.nodes[i] = { name = r:string(), child = r:int(), sibling = r:int(), rot = floats(4), trans = floats(3) }
	end
	data.shaderCount = r:int()
	for i = 1, r:int() do data.shaders[i] = { name = r:string(), bitmap = r:string() } end
	data.markerCount = r:int()
	for i = 1, r:int() do
		data.markers[i] = { name = r:string(), region = r:int(), parent = r:int(), rot = floats(4), trans = floats(3),
			radius = r:float() }
	end
	data.regionCount = r:int()
	for i = 1, r:int() do data.regions[i] = r:string() end
	data.vertexCount = r:int()
	for i = 1, r:int() do
		data.vertices[i] = { node0 = r:int(), pos = floats(3), normal = floats(3), node1 = r:int(),
			weight = r:float(), u = r:float(), v = r:float(), tex = r:int() }
	end
	data.triangleCount = r:int()
	for i = 1, r:int() do
		data.triangles[i] = { region = r:int(), shader = r:int(), a = r:int(), b = r:int(), c = r:int() }
	end
	data.writeSmoothing = r:int() == 1
	if data.writeSmoothing then
		for i = 1, r:int() do data.smoothingGroups[i] = r:int() end
	end
	if not jms.write(jmsPath, data) then error("cannot write " .. jmsPath, 0) end
end

-- Scene meshes from Max (extractGeometryData) -> JMS vertices + the vertex of every face corner
function jmsBridge.mesh(inPath, outPath)
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

return jmsBridge
