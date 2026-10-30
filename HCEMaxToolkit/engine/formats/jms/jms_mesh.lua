-- Builds the JMS vertex list from the scene meshes Max sends (formats\jms\process_scene.ms).
-- Same rules as the previous MAXScript loop: one vertex per face corner, merged with an earlier
-- vertex of the same object when the createVertexHash key matched.

local f32 = require("shared.utils.max_numbers").f32

local floor, ceil, format = math.floor, math.ceil, string.format

local jms_mesh = {}

-- (x * 10000) as integer in MAXScript: Float product, truncated toward zero
local function key_int(x)
	local y = f32(x * 10000)
	return y >= 0 and floor(y) or ceil(y)
end

-- Two strongest bone weights of a vertex, as the old loop picked them (first maximum wins).
-- bones/weights: lists of node indices and weights. Returns node0, node1, weight1 or nil.
local function top_two(bones, weights)
	local n = #bones
	if n == 0 then return nil end
	local first = 1
	for i = 2, n do
		if weights[i] > weights[first] then first = i end
	end
	local second
	for i = 1, n do
		if i ~= first and (not second or weights[i] > weights[second]) then second = i end
	end
	if second then return bones[first], bones[second], weights[second] end
	return bones[first], -1, 0
end

-- obj: { parent, positions = {x,y,z,...}, skin = nil | { {bones}, {weights} } per vertex,
--        uvs = {u,v,...}, faces = vertex per corner, tvfaces = uv per corner or nil,
--        normals = {x,y,z per corner} }; indices are 1-based like Max's.
-- Appends new vertices to `vertices` and returns the global (0-based) index of every corner.
function jms_mesh.add_object(obj, vertices, corners)
	-- Bone influence of each vertex, picked once per vertex
	local node0, node1, weight1 = {}, {}, {}
	local vertex_count = #obj.positions / 3
	for v = 1, vertex_count do
		local influence = obj.skin and obj.skin[v]
		local a, b, w
		if influence then a, b, w = top_two(influence[1], influence[2]) end
		if a then
			node0[v], node1[v], weight1[v] = a, b, w
		else
			node0[v], node1[v], weight1[v] = obj.parent, -1, 0
		end
	end

	local seen = {}
	local positions, uvs, normals, faces, tvfaces = obj.positions, obj.uvs, obj.normals, obj.faces, obj.tvfaces
	local uv_count = #uvs / 2
	for c = 1, #faces do
		local v = faces[c]
		local p = (v - 1) * 3
		local x, y, z = positions[p + 1], positions[p + 2], positions[p + 3]
		local n = (c - 1) * 3
		local nx, ny, nz = normals[n + 1], normals[n + 2], normals[n + 3]
		local u, w = 0, 0
		if tvfaces then
			local t = tvfaces[c]
			if t > 0 and t <= uv_count then u, w = uvs[t * 2 - 1], uvs[t * 2] end
		end
		local key = format("%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d",
			key_int(x), key_int(y), key_int(z), key_int(nx), key_int(ny), key_int(nz),
			key_int(u), key_int(w), node0[v], node1[v], key_int(weight1[v]))
		local index = seen[key]
		if not index then
			index = #vertices
			vertices[index + 1] = { node0 = node0[v], pos = { x, y, z }, normal = { nx, ny, nz },
				node1 = node1[v], weight = weight1[v], u = u, v = w }
			seen[key] = index
		end
		corners[#corners + 1] = index
	end
end

return jms_mesh
