-- model_collision_geometry -> 3ds Max: materials, regions, pathfinding spheres and node BSPs
-- (raw values, the builder does the math). Read in Max by builders\tag\model_collision_geometry\lua_reader.ms.

local collision_bsp = require("core.halo1.collision_bsp")

local collision = { group = "model_collision_geometry", version = 1 }

function collision.write(root, w)
	local materials = root["materials"]
	w:int(#materials)
	for _, m in ipairs(materials) do
		w:string(m["name"])
		w:int(m["material type"])
	end

	local regions = root["regions"]
	w:int(#regions)
	for _, r in ipairs(regions) do
		w:string(r["name"])
		w:int(#r["permutations"])
		for _, p in ipairs(r["permutations"]) do w:string(p["name"]) end
	end

	local spheres = root["pathfinding spheres"]
	w:int(#spheres)
	for _, s in ipairs(spheres) do
		w:int(s["node"])
		w:floats(s["center"])
		w:float(s["radius"])
	end

	local nodes = root["nodes"]
	w:int(#nodes)
	for _, n in ipairs(nodes) do
		w:string(n["name"])
		w:int(n["region"])
		w:int(#n["bsps"])
		for _, bsp in ipairs(n["bsps"]) do collision_bsp.write(w, bsp) end
	end
end

return collision
