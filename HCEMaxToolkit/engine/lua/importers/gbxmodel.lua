-- gbxmodel -> 3ds Max: nodes, regions/markers, shaders and one merged mesh per geometry.
-- Read in Max by builders\tag\gbxmodel\lua_reader.ms; options: { halo scale }.

local packed = require("core.halo1.packed")

local normalize, decompress_normal = packed.normalize, packed.decompress_normal

local gbxmodel = { group = "gbxmodel", version = 1 }

-------------------------------------------------------------------------------
-- Vertex decoding (same rules as the previous MAXScript importer)
-------------------------------------------------------------------------------

-- Integer division truncating toward zero, like MAXScript's int / int
local function idiv(a, b)
	local q = a / b
	return q >= 0 and math.floor(q) or math.ceil(q)
end

local function valid_node_pair(idx0, idx1)
	if idx0 < 1 or idx0 > 255 then idx0 = 1 end
	if idx1 < 1 or idx1 > 255 then idx1 = idx0 end
	return idx0, idx1
end

local function push(t, ...)
	local n = #t
	for i = 1, select("#", ...) do t[n + i] = select(i, ...) end
end

-- Compressed vertices use global node indices, stored x3
local function add_compressed_vertices(geo, verts, scale, u_scale, v_scale)
	for _, v in ipairs(verts) do
		local p = v["position"]
		push(geo.positions, p[1] * scale, p[2] * scale, p[3] * scale)
		push(geo.normals, decompress_normal(v["normal[11.11.10-bit]"]))
		push(geo.uvs, (v["texture coordinate u[16-bit]"] / 32767) * u_scale,
			(1 - v["texture coordinate v[16-bit]"] / 32767) * v_scale)
		push(geo.nodes, valid_node_pair(idiv(v["node0 index(x3)"], 3) + 1, idiv(v["node1 index(x3)"], 3) + 1))
		local w = v["node0 weight[16-bit]"] / 32767
		if w < 0 then w = 0 elseif w > 1 then w = 1 end
		push(geo.weights, w, 1 - w)
	end
end

-- Uncompressed vertices may use part-local node indices (local_node_table)
local function add_uncompressed_vertices(geo, verts, local_nodes, scale, u_scale, v_scale)
	local n_local = #local_nodes
	for _, v in ipairs(verts) do
		local p = v["position"]
		push(geo.positions, p[1] * scale, p[2] * scale, p[3] * scale)
		local n = v["normal"]
		push(geo.normals, normalize(n[1], n[2], n[3]))
		local uv = v["texture coords"]
		push(geo.uvs, uv[1] * u_scale, (1 - uv[2]) * v_scale)

		local idx0, idx1 = v["node0 index"], v["node1 index"]
		if n_local > 0 then
			local l0, l1 = idx0, idx1
			idx0 = (l0 >= 0 and l0 < n_local) and local_nodes[l0 + 1] or 0
			idx1 = (l1 >= 0 and l1 < n_local) and local_nodes[l1 + 1] or idx0
		end
		idx0 = idx0 + 1
		idx1 = idx1 >= 0 and idx1 + 1 or idx0
		push(geo.nodes, valid_node_pair(idx0, idx1))
		push(geo.weights, v["node0 weight"], v["node1 weight"])
	end
end

-- Triangle strip -> 1-based faces, flipping every other triangle and dropping degenerate ones
local function strip_to_faces(triangles, vertex_count)
	local order = {}
	for _, t in ipairs(triangles) do
		push(order, t["vertex0 index"] + 1, t["vertex1 index"] + 1, t["vertex2 index"] + 1)
	end
	local faces = {}
	for w = 1, #order - 2 do
		local a, b, c = order[w], order[w + 1], order[w + 2]
		if w % 2 == 1 then a, c = c, a end
		local degenerate = a == b or b == c or a == c
		local in_range = a >= 1 and b >= 1 and c >= 1 and a <= vertex_count and b <= vertex_count and c <= vertex_count
		if not degenerate and in_range then faces[#faces + 1] = { a, b, c } end
	end
	return faces
end

-- All parts of a geometry merged; compressed vertices are preferred when a part has both
local function build_geometry(geometry, scale, u_scale, v_scale)
	local geo = { positions = {}, normals = {}, uvs = {}, nodes = {}, weights = {}, faces = {}, mat_ids = {}, vertex_count = 0 }
	for _, part in ipairs(geometry["parts"]) do
		local compressed = part["compressed vertices"]
		local uncompressed = part["uncompressed vertices"]
		local vertex_count = #compressed > 0 and #compressed or #uncompressed
		local faces = strip_to_faces(part["triangles"], vertex_count)

		if vertex_count > 0 and #faces > 0 then
			local offset = geo.vertex_count
			if #compressed > 0 then
				add_compressed_vertices(geo, compressed, scale, u_scale, v_scale)
			else
				local local_nodes = {}
				local node_table = part["local_node_table"]
				for i = 1, math.min(part["num_nodes"], #node_table) do local_nodes[i] = node_table[i]["node index"] end
				add_uncompressed_vertices(geo, uncompressed, local_nodes, scale, u_scale, v_scale)
			end
			local mat_id = part["shader index"] + 1
			for _, f in ipairs(faces) do
				push(geo.faces, f[1] + offset, f[2] + offset, f[3] + offset)
				geo.mat_ids[#geo.mat_ids + 1] = mat_id
			end
			geo.vertex_count = offset + vertex_count
		end
	end
	return geo
end

-------------------------------------------------------------------------------
-- Output (same order as readGbxModelWithLua)
-------------------------------------------------------------------------------

function gbxmodel.write(root, w, options)
	local scale = assert(tonumber(options[1]), "missing halo scale option")
	local u_scale = root["base map u-scale"]
	local v_scale = root["base map v-scale"]
	if math.abs(u_scale) < 0.0001 then u_scale = 1 end
	if math.abs(v_scale) < 0.0001 then v_scale = 1 end
	w:floats({ u_scale, v_scale })

	w:int(#root["nodes"])
	for _, node in ipairs(root["nodes"]) do
		w:string(node["name"])
		w:ints({ node["next sibling node index"], node["first child node index"], node["parent node index"] })
		w:floats(node["default translation"])
		w:floats(node["default rotation"])
		w:float(node["node distance from parent"])
	end

	w:int(#root["regions"])
	for _, region in ipairs(root["regions"]) do
		w:string(region["name"])
		w:int(#region["permutations"])
		for _, perm in ipairs(region["permutations"]) do
			w:string(perm["name"])
			w:ints({ perm["flags"], perm["super low"], perm["low"], perm["medium"], perm["high"], perm["super high"] })
			w:int(#perm["markers"])
			for _, marker in ipairs(perm["markers"]) do
				w:string(marker["name"])
				w:int(marker["node index"])
				w:floats(marker["rotation"])
				w:floats(marker["translation"])
			end
		end
	end

	w:int(#root["shaders"])
	for _, shader in ipairs(root["shaders"]) do
		w:tagref(shader["shader"])
		w:int(shader["permutation"])
	end

	w:int(#root["geometries"])
	for _, geometry in ipairs(root["geometries"]) do
		local geo = build_geometry(geometry, scale, u_scale, v_scale)
		w:ints({ geo.vertex_count, #geo.mat_ids })
		w:floats(geo.positions)
		w:floats(geo.normals)
		w:floats(geo.uvs)
		w:ints(geo.nodes)
		w:floats(geo.weights)
		w:ints(geo.faces)
		w:ints(geo.mat_ids)
	end
end

return gbxmodel
