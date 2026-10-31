-- model_collision_geometry -> 3ds Max: materials, regions, pathfinding spheres and node BSPs
-- (raw values, the builder does the math). Read in Max by builders\tag\model_collision_geometry\lua_reader.ms.
local collisionBsp = require "importers.shared.collision_bsp"

local collision = {group = "model_collision_geometry", version = 1}

function collision.write(root, output)
    local materials = root["materials"]
    output:int(#materials)
    for _, material in ipairs(materials) do
        output:string(material["name"])
        output:int(material["material type"])
    end

    local regions = root["regions"]
    output:int(#regions)
    for _, region in ipairs(regions) do
        output:string(region["name"])
        output:int(#region["permutations"])
        for _, permutation in ipairs(region["permutations"]) do
            output:string(permutation["name"])
        end
    end

    local spheres = root["pathfinding spheres"]
    output:int(#spheres)
    for _, sphere in ipairs(spheres) do
        output:int(sphere["node"])
        output:floats(sphere["center"])
        output:float(sphere["radius"])
    end

    local nodes = root["nodes"]
    output:int(#nodes)
    for _, node in ipairs(nodes) do
        output:string(node["name"])
        output:int(node["region"])
        output:int(#node["bsps"])
        for _, bsp in ipairs(node["bsps"]) do
            collisionBsp.write(output, bsp)
        end
    end
end

return collision
