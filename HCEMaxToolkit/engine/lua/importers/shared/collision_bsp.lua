-- Collision BSP geometry (surfaces, edges, vertices) as both model_collision_geometry and
-- scenario_structure_bsp store it. Read in Max by builders\tag\shared\collision_bsp_reader.ms.

local collision_bsp = {}

-- Raw tag values: 0-based indices (-1 = none), vertices in Halo units
function collision_bsp.write(w, bsp)
	local surfaces = bsp["surfaces"]
	local ints = {}
	for i, s in ipairs(surfaces) do
		ints[i * 3 - 2], ints[i * 3 - 1], ints[i * 3] = s["first edge"], s["flags"], s["material"]
	end
	w:int(#surfaces)
	w:ints(ints, #surfaces * 3)

	local edges = bsp["edges"]
	ints = {}
	for i, e in ipairs(edges) do
		local o = (i - 1) * 6
		ints[o + 1], ints[o + 2] = e["start vertex"], e["end vertex"]
		ints[o + 3], ints[o + 4] = e["forward edge"], e["reverse edge"]
		ints[o + 5], ints[o + 6] = e["left surface"], e["right surface"]
	end
	w:int(#edges)
	w:ints(ints, #edges * 6)

	local vertices = bsp["vertices"]
	local floats = {}
	for i, v in ipairs(vertices) do
		local p = v["point"]
		floats[i * 3 - 2], floats[i * 3 - 1], floats[i * 3] = p[1], p[2], p[3]
	end
	w:int(#vertices)
	w:floats(floats, #vertices * 3)
end

return collision_bsp
