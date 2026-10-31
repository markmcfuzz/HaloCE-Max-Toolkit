-- scenario_structure_bsp -> 3ds Max: collision BSP, render geometry per lightmap material,
-- portals, fog planes, weather polyhedra and markers. Read in Max by
-- builders\tag\scenario_structure_bsp\lua_reader.ms; options: { halo scale }.
local ffi = require "ffi" -- LuaJIT: C types and direct memory access
local packed = require "importers.shared.packed"
local collisionBsp = require "importers.shared.collision_bsp"

local decompressNormal = packed.decompressNormal

-- Compressed render vertex as stored in the tag, little-endian (binormal/tangent are not used)
ffi.cdef [[ typedef struct { float px, py, pz; uint32_t normal, binormal, tangent; float u, v; } h1bsp_cvert; ]]
local compressedVertexSize = 32

local bspImporter = {group = "scenario_structure_bsp", version = 1}

-- Rendered vertices of one lightmap material: positions (scaled), UVs (u, 1 - v), normals
local function writeRenderVertices(output, material, bytes, scale)
    local count = material["vertex buffers"][1]["count"]
    local data = material["compressed vertices"]
    -- Like the previous importer, no vertices are read when the data is empty
    if count <= 0 or data.size == 0 then
        output:int(0)
        return
    end
    if data.size < count * compressedVertexSize then
        error(
            ("lightmap material has %d vertices but only %d bytes of compressed vertex data"):format(
                count, data.size), 0)
    end
    -- The vertex data read straight from the tag bytes as an array of h1bsp_cvert
    local vertices = ffi.cast("const h1bsp_cvert*", ffi.cast("const uint8_t*", bytes) + data.offset)
    local positions, uvs, normals = {}, {}, {}
    for i = 0, count - 1 do
        local vertex = vertices[i]
        positions[i * 3 + 1], positions[i * 3 + 2], positions[i * 3 + 3] = vertex.px * scale,
                                                                           vertex.py * scale,
                                                                           vertex.pz * scale
        uvs[i * 2 + 1], uvs[i * 2 + 2] = vertex.u, 1 - vertex.v
        normals[i * 3 + 1], normals[i * 3 + 2], normals[i * 3 + 3] = decompressNormal(vertex.normal)
    end
    output:int(count)
    output:floats(positions, count * 3)
    output:floats(uvs, count * 2)
    output:floats(normals, count * 3)
end

-- Polygons stored as a block of { point } vertices (portals, fog planes), scaled
local function writePolygons(output, list, scale)
    output:int(#list)
    for _, item in ipairs(list) do
        local floats = {}
        for i, vertex in ipairs(item["vertices"]) do
            local point = vertex["point"]
            floats[i * 3 - 2], floats[i * 3 - 1], floats[i * 3] = point[1] * scale,
                                                                  point[2] * scale, point[3] * scale
        end
        output:int(#item["vertices"])
        output:floats(floats, #item["vertices"] * 3)
    end
end

function bspImporter.write(root, output, options, tag)
    local scale = tonumber(options[1]) or 100
    local bytes = tag.bytes

    local materials = root["collision materials"]
    output:int(#materials)
    for _, material in ipairs(materials) do
        output:tagref(material["shader"])
    end

    -- Only the first collision BSP is used
    local collision = root["collision bsp"]
    output:int(#collision)
    if #collision > 0 then
        collisionBsp.write(output, collision[1])
    end

    -- Render triangles: 0-based vertex indices local to each lightmap material, unsigned 16-bit
    -- (a material can have more than 32767 vertices)
    local surfaces = root["surfaces"]
    local ints = {}
    for i, surface in ipairs(surfaces) do
        local corners = surface["vertices"]
        ints[i * 3 - 2], ints[i * 3 - 1], ints[i * 3] = corners[1]["a"] % 65536,
                                                        corners[2]["a"] % 65536,
                                                        corners[3]["a"] % 65536
    end
    output:int(#surfaces)
    output:ints(ints, #surfaces * 3)

    local lightmaps = root["lightmaps"]
    output:int(#lightmaps)
    for _, lightmap in ipairs(lightmaps) do
        output:int(lightmap["bitmap"])
        output:int(#lightmap["materials"])
        for _, material in ipairs(lightmap["materials"]) do
            output:tagref(material["shader"])
            output:ints({
                material["surfaces"],
                material["surface count"],
                material["vertex buffers"][1]["count"]
            })
            writeRenderVertices(output, material, bytes, scale)
        end
    end

    writePolygons(output, root["cluster portals"], scale)
    writePolygons(output, root["fog planes"], scale)

    local weather = root["weather polyhedra"]
    output:int(#weather)
    for _, polyhedron in ipairs(weather) do
        local center = polyhedron["bounding sphere center"]
        output:floats({
            center[1] * scale,
            center[2] * scale,
            center[3] * scale,
            polyhedron["bounding sphere radius"] * scale
        })
        output:int(#polyhedron["planes"])
        for _, plane in ipairs(polyhedron["planes"]) do
            output:floats(plane["plane"])
        end
    end

    local markers = root["markers"]
    output:int(#markers)
    for _, marker in ipairs(markers) do
        output:string(marker["name"])
        output:floats(marker["rotation"])
        local position = marker["position"]
        output:floats({position[1] * scale, position[2] * scale, position[3] * scale})
    end
end

return bspImporter
