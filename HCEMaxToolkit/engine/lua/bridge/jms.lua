-- JMS files for 3ds Max (formats\jms\jms_reader.ms, process_file.ms and process_scene.ms):
--   run.lua bridge.jms read <file.jms> <out.bin>    JMS -> binary for Max
--   run.lua bridge.jms write <in.bin> <file.jms>    binary from Max -> JMS
--   run.lua bridge.jms mesh <in.bin> <out.bin>      scene meshes -> JMS vertices

local jms = require "formats.jms"
local jmsMesh = require "formats.jms_mesh"
local maxbin = require "bridge.maxbin"

local jmsBridge = {}

-- Name and version at the start of each binary (Max checks the same values)
local binaryName = "jms"
local binaryVersion = 2
local meshBinaryName = "jms_mesh"
local meshInVersion = 2  -- scene meshes from Max
local meshOutVersion = 1 -- JMS vertices back to Max

function jmsBridge.read(jmsPath, outPath)
	local data = jms.read(jmsPath)
	local output = maxbin.open(outPath, binaryName, binaryVersion)

	-- Standard files had their rotations normalized by the old reader; inline ones did not
	output:int(data.inline and 0 or 1)
	output:ints({ data.version, data.checksum })

	output:int(data.nodeCount)
	output:int(#data.nodes)
	for _, node in ipairs(data.nodes) do
		output:string(node.name)
		output:ints({ node.child, node.sibling })
		output:floats(node.rot)
		output:floats(node.trans)
	end

	output:int(data.shaderCount)
	output:int(#data.shaders)
	for _, shader in ipairs(data.shaders) do
		output:string(shader.name)
		output:string(shader.bitmap)
	end

	output:int(data.markerCount)
	output:int(#data.markers)
	for _, marker in ipairs(data.markers) do
		output:string(marker.name)
		output:ints({ marker.region, marker.parent })
		output:floats(marker.rot)
		output:floats(marker.trans)
		output:float(marker.radius)
	end

	output:int(data.regionCount)
	output:int(#data.regions)
	for _, name in ipairs(data.regions) do output:string(name) end

	output:int(data.vertexCount)
	output:int(#data.vertices)
	for _, vertex in ipairs(data.vertices) do
		output:int(vertex.node0)
		output:floats(vertex.pos)
		output:floats(vertex.normal)
		output:int(vertex.node1)
		output:floats({ vertex.weight, vertex.u, vertex.v })
		output:int(vertex.tex)
	end

	output:int(data.triangleCount)
	output:int(#data.triangles)
	for _, triangle in ipairs(data.triangles) do
		output:ints({ triangle.region, triangle.shader, triangle.a, triangle.b, triangle.c })
	end

	output:int(#data.smoothingGroups)
	if #data.smoothingGroups > 0 then output:ints(data.smoothingGroups) end
	output:close()
end

function jmsBridge.write(inPath, jmsPath)
	local input = maxbin.readFile(inPath, binaryName, binaryVersion)
	local function floats(count)
		local values = {}
		for i = 1, count do values[i] = input:float() end
		return values
	end
	local data = { nodes = {}, shaders = {}, markers = {}, regions = {}, vertices = {}, triangles = {},
		smoothingGroups = {} }

	data.version, data.checksum, data.nodeCount = input:int(), input:int(), input:int()
	for i = 1, input:int() do
		data.nodes[i] = { name = input:string(), child = input:int(), sibling = input:int(), rot = floats(4),
			trans = floats(3) }
	end
	data.shaderCount = input:int()
	for i = 1, input:int() do data.shaders[i] = { name = input:string(), bitmap = input:string() } end
	data.markerCount = input:int()
	for i = 1, input:int() do
		data.markers[i] = { name = input:string(), region = input:int(), parent = input:int(), rot = floats(4),
			trans = floats(3), radius = input:float() }
	end
	data.regionCount = input:int()
	for i = 1, input:int() do data.regions[i] = input:string() end
	data.vertexCount = input:int()
	for i = 1, input:int() do
		data.vertices[i] = { node0 = input:int(), pos = floats(3), normal = floats(3), node1 = input:int(),
			weight = input:float(), u = input:float(), v = input:float(), tex = input:int() }
	end
	data.triangleCount = input:int()
	for i = 1, input:int() do
		data.triangles[i] = { region = input:int(), shader = input:int(), a = input:int(), b = input:int(),
			c = input:int() }
	end
	data.writeSmoothing = input:int() == 1
	if data.writeSmoothing then
		for i = 1, input:int() do data.smoothingGroups[i] = input:int() end
	end
	if not jms.write(jmsPath, data) then error("cannot write " .. jmsPath, 0) end
end

-- Scene meshes from Max (extractGeometryData) -> JMS vertices + the vertex of every face corner
function jmsBridge.mesh(inPath, outPath)
	local input = maxbin.readFile(inPath, meshBinaryName, meshInVersion)
	local vertices, corners = {}, {}
	for _ = 1, input:int() do
		local obj = { parent = input:int(), positions = {}, uvs = {}, faces = {}, normals = {} }
		for i = 1, input:int() * 3 do obj.positions[i] = input:float() end
		if input:int() == 1 then
			obj.skin = {}
			for vertex = 1, #obj.positions / 3 do
				local bones, weights = {}, {}
				for i = 1, input:int() do
					bones[i] = input:int()
					weights[i] = input:float()
				end
				obj.skin[vertex] = { bones, weights }
			end
		end
		local uvCount = input:int()
		for i = 1, uvCount * 2 do obj.uvs[i] = input:float() end
		if uvCount > 0 then obj.tvfaces = {} end
		local faces, tvfaces, normals = obj.faces, obj.tvfaces, obj.normals
		local faceCount = input:int()
		-- Normals saved in one go (file, count, rotMatrix rows), or per corner with each face
		local saved
		if input:int() == 1 then
			saved = { path = input:string(), count = input:int(), rotMatrix = {} }
			for i = 1, 12 do saved.rotMatrix[i] = input:float() end
		end
		for face = 0, faceCount - 1 do
			for corner = 1, 3 do faces[face * 3 + corner] = input:int() end
			if tvfaces then
				for corner = 1, 3 do tvfaces[face * 3 + corner] = input:int() end
			end
			if not saved then
				for i = 1, 9 do normals[face * 9 + i] = input:float() end
			end
		end
		if saved then obj.normals = jmsMesh.savedNormals(saved.path, saved.count, faceCount, saved.rotMatrix) end
		jmsMesh.addObject(obj, vertices, corners)
	end

	local output = maxbin.open(outPath, meshBinaryName, meshOutVersion)
	output:int(#vertices)
	for _, vertex in ipairs(vertices) do
		output:int(vertex.node0)
		output:floats(vertex.pos)
		output:floats(vertex.normal)
		output:int(vertex.node1)
		output:floats({ vertex.weight, vertex.u, vertex.v })
	end
	output:int(#corners)
	if #corners > 0 then output:ints(corners) end
	output:close()
end

return jmsBridge
