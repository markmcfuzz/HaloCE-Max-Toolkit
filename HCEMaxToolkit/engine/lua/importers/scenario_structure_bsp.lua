-- scenario_structure_bsp -> 3ds Max: collision BSP, render geometry per lightmap material,
-- portals, fog planes, weather polyhedra and markers. Read in Max by
-- builders\tag\scenario_structure_bsp\lua_reader.ms; options: { halo scale }.

local ffi = require("ffi")
local packed = require("core.halo1.packed")
local collision_bsp = require("core.halo1.collision_bsp")

local decompress_normal = packed.decompress_normal

-- Compressed render vertex, little-endian (binormal/tangent are not used)
ffi.cdef [[ typedef struct { float px, py, pz; uint32_t normal, binormal, tangent; float u, v; } h1bsp_cvert; ]]
local CVERT_SIZE = 32

local bsp_importer = { group = "scenario_structure_bsp", version = 1 }

-- Rendered vertices of one lightmap material: positions (scaled), UVs (u, 1 - v), normals
local function write_render_vertices(w, mat, bytes, scale)
	local count = mat["vertex buffers"][1]["count"]
	local data = mat["compressed vertices"]
	-- Like the previous importer, no vertices are read when the data is empty
	if count <= 0 or data.size == 0 then
		w:int(0)
		return
	end
	if data.size < count * CVERT_SIZE then
		error(("lightmap material has %d vertices but only %d bytes of compressed vertex data")
			:format(count, data.size), 0)
	end
	local verts = ffi.cast("const h1bsp_cvert*", ffi.cast("const uint8_t*", bytes) + data.offset)
	local pos, uvs, normals = {}, {}, {}
	for i = 0, count - 1 do
		local v = verts[i]
		pos[i * 3 + 1], pos[i * 3 + 2], pos[i * 3 + 3] = v.px * scale, v.py * scale, v.pz * scale
		uvs[i * 2 + 1], uvs[i * 2 + 2] = v.u, 1 - v.v
		normals[i * 3 + 1], normals[i * 3 + 2], normals[i * 3 + 3] = decompress_normal(v.normal)
	end
	w:int(count)
	w:floats(pos, count * 3)
	w:floats(uvs, count * 2)
	w:floats(normals, count * 3)
end

-- Polygons stored as a block of { point } vertices (portals, fog planes), scaled
local function write_polygons(w, list, scale)
	w:int(#list)
	for _, item in ipairs(list) do
		local floats = {}
		for i, v in ipairs(item["vertices"]) do
			local p = v["point"]
			floats[i * 3 - 2], floats[i * 3 - 1], floats[i * 3] = p[1] * scale, p[2] * scale, p[3] * scale
		end
		w:int(#item["vertices"])
		w:floats(floats, #item["vertices"] * 3)
	end
end

function bsp_importer.write(root, w, options, tag)
	local scale = tonumber(options[1]) or 100
	local bytes = tag.bytes

	local materials = root["collision materials"]
	w:int(#materials)
	for _, m in ipairs(materials) do w:tagref(m["shader"]) end

	-- Only the first collision BSP is used
	local collision = root["collision bsp"]
	w:int(#collision)
	if #collision > 0 then collision_bsp.write(w, collision[1]) end

	-- Render triangles: 0-based vertex indices local to each lightmap material
	local surfaces = root["surfaces"]
	local ints = {}
	for i, s in ipairs(surfaces) do
		local v = s["vertices"]
		ints[i * 3 - 2], ints[i * 3 - 1], ints[i * 3] = v[1]["a"], v[2]["a"], v[3]["a"]
	end
	w:int(#surfaces)
	w:ints(ints, #surfaces * 3)

	local lightmaps = root["lightmaps"]
	w:int(#lightmaps)
	for _, lm in ipairs(lightmaps) do
		w:int(lm["bitmap"])
		w:int(#lm["materials"])
		for _, mat in ipairs(lm["materials"]) do
			w:tagref(mat["shader"])
			w:ints({ mat["surfaces"], mat["surface count"], mat["vertex buffers"][1]["count"] })
			write_render_vertices(w, mat, bytes, scale)
		end
	end

	write_polygons(w, root["cluster portals"], scale)
	write_polygons(w, root["fog planes"], scale)

	local weather = root["weather polyhedra"]
	w:int(#weather)
	for _, poly in ipairs(weather) do
		local c = poly["bounding sphere center"]
		w:floats({ c[1] * scale, c[2] * scale, c[3] * scale, poly["bounding sphere radius"] * scale })
		w:int(#poly["planes"])
		for _, pl in ipairs(poly["planes"]) do w:floats(pl["plane"]) end
	end

	local markers = root["markers"]
	w:int(#markers)
	for _, m in ipairs(markers) do
		w:string(m["name"])
		w:floats(m["rotation"])
		local p = m["position"]
		w:floats({ p[1] * scale, p[2] * scale, p[3] * scale })
	end
end

return bsp_importer
