-- Collision BSP geometry (surfaces, edges, vertices) as both model_collision_geometry and
-- scenario_structure_bsp store it. Read in Max by builders\tag\shared\collision_bsp_reader.ms.
local collisionBsp = {}

-- Writes one BSP with raw tag values: 0-based indices (-1 = none), vertices in Halo units.
-- Each list goes as its count, then all its numbers in one go.
function collisionBsp.write(output, bsp)
    local surfaces = bsp["surfaces"]
    local ints = {}
    for i, surface in ipairs(surfaces) do
        ints[i * 3 - 2], ints[i * 3 - 1], ints[i * 3] = surface["first edge"], surface["flags"],
        surface["material"]
    end
    output:int(#surfaces)
    output:ints(ints, #surfaces * 3)

    local edges = bsp["edges"]
    ints = {}
    for i, edge in ipairs(edges) do
        local at = (i - 1) * 6
        ints[at + 1], ints[at + 2] = edge["start vertex"], edge["end vertex"]
        ints[at + 3], ints[at + 4] = edge["forward edge"], edge["reverse edge"]
        ints[at + 5], ints[at + 6] = edge["left surface"], edge["right surface"]
    end
    output:int(#edges)
    output:ints(ints, #edges * 6)

    local vertices = bsp["vertices"]
    local floats = {}
    for i, vertex in ipairs(vertices) do
        local point = vertex["point"]
        floats[i * 3 - 2], floats[i * 3 - 1], floats[i * 3] = point[1], point[2], point[3]
    end
    output:int(#vertices)
    output:floats(floats, #vertices * 3)
end

return collisionBsp
