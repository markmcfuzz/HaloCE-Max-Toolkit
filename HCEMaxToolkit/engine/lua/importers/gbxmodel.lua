-- gbxmodel -> 3ds Max: nodes, regions/markers, shaders and one merged mesh per geometry.
-- Read in Max by builders\tag\gbxmodel\lua_reader.ms; options: { halo scale }.
local packed = require "importers.shared.packed"

local normalize, decompressNormal = packed.normalize, packed.decompressNormal

local gbxmodel = {group = "gbxmodel", version = 1}

-------------------------------------------------------------------------------
-- Vertex decoding (same rules as the previous MAXScript importer)
-------------------------------------------------------------------------------

-- Integer division truncating toward zero, like MAXScript's int / int
local function intDivide(a, b)
    local q = a / b
    return q >= 0 and math.floor(q) or math.ceil(q)
end

-- 1-based node pair; an index outside 1..255 falls back to node 1 (or to node0 for node1)
local function validNodePair(node0, node1)
    if node0 < 1 or node0 > 255 then
        node0 = 1
    end
    if node1 < 1 or node1 > 255 then
        node1 = node0
    end
    return node0, node1
end

-- Appends every value after list to the end of list
local function push(list, ...)
    local count = #list
    for i = 1, select("#", ...) do
        list[count + i] = select(i, ...)
    end
end

-- Compressed vertices use global node indices, stored x3
local function addCompressedVertices(mesh, vertices, scale, uScale, vScale)
    for _, vertex in ipairs(vertices) do
        local position = vertex["position"]
        push(mesh.positions, position[1] * scale, position[2] * scale, position[3] * scale)
        push(mesh.normals, decompressNormal(vertex["normal[11.11.10-bit]"]))
        push(mesh.uvs, (vertex["texture coordinate u[16-bit]"] / 32767) * uScale,
             (1 - vertex["texture coordinate v[16-bit]"] / 32767) * vScale)
        push(mesh.nodes, validNodePair(intDivide(vertex["node0 index(x3)"], 3) + 1,
                                       intDivide(vertex["node1 index(x3)"], 3) + 1))
        local weight = vertex["node0 weight[16-bit]"] / 32767
        if weight < 0 then
            weight = 0
        elseif weight > 1 then
            weight = 1
        end
        push(mesh.weights, weight, 1 - weight)
    end
end

-- Uncompressed vertices may use part-local node indices (local_node_table)
local function addUncompressedVertices(mesh, vertices, localNodes, scale, uScale, vScale)
    local localCount = #localNodes
    for _, vertex in ipairs(vertices) do
        local position = vertex["position"]
        push(mesh.positions, position[1] * scale, position[2] * scale, position[3] * scale)
        local normal = vertex["normal"]
        push(mesh.normals, normalize(normal[1], normal[2], normal[3]))
        local uv = vertex["texture coords"]
        push(mesh.uvs, uv[1] * uScale, (1 - uv[2]) * vScale)

        local node0, node1 = vertex["node0 index"], vertex["node1 index"]
        if localCount > 0 then
            local local0, local1 = node0, node1
            node0 = (local0 >= 0 and local0 < localCount) and localNodes[local0 + 1] or 0
            node1 = (local1 >= 0 and local1 < localCount) and localNodes[local1 + 1] or node0
        end
        node0 = node0 + 1
        node1 = node1 >= 0 and node1 + 1 or node0
        push(mesh.nodes, validNodePair(node0, node1))
        push(mesh.weights, vertex["node0 weight"], vertex["node1 weight"])
    end
end

-- Triangle strip -> 1-based faces, flipping every other triangle and dropping degenerate ones
local function stripToFaces(triangles, vertexCount)
    -- Indices are unsigned 16-bit (parts can have more than 32767 vertices); -1 padding becomes
    -- 65535, which is out of range and dropped
    local order = {}
    for _, triangle in ipairs(triangles) do
        push(order, triangle["vertex0 index"] % 65536 + 1, triangle["vertex1 index"] % 65536 + 1,
             triangle["vertex2 index"] % 65536 + 1)
    end
    local faces = {}
    for stripIndex = 1, #order - 2 do
        local a, b, c = order[stripIndex], order[stripIndex + 1], order[stripIndex + 2]
        if stripIndex % 2 == 1 then
            a, c = c, a
        end
        local degenerate = a == b or b == c or a == c
        local inRange =
            a >= 1 and b >= 1 and c >= 1 and a <= vertexCount and b <= vertexCount and c <=
                vertexCount
        if not degenerate and inRange then
            faces[#faces + 1] = {a, b, c}
        end
    end
    return faces
end

-- All parts of a geometry merged; compressed vertices are preferred when a part has both
local function buildGeometry(geometry, scale, uScale, vScale)
    local mesh = {
        positions = {},
        normals = {},
        uvs = {},
        nodes = {},
        weights = {},
        faces = {},
        matIds = {},
        vertexCount = 0
    }
    for _, part in ipairs(geometry["parts"]) do
        local compressed = part["compressed vertices"]
        local uncompressed = part["uncompressed vertices"]
        local vertexCount = #compressed > 0 and #compressed or #uncompressed
        local faces = stripToFaces(part["triangles"], vertexCount)

        if vertexCount > 0 and #faces > 0 then
            local offset = mesh.vertexCount
            if #compressed > 0 then
                addCompressedVertices(mesh, compressed, scale, uScale, vScale)
            else
                local localNodes = {}
                local nodeTable = part["local_node_table"]
                for i = 1, math.min(part["num_nodes"], #nodeTable) do
                    localNodes[i] = nodeTable[i]["node index"]
                end
                addUncompressedVertices(mesh, uncompressed, localNodes, scale, uScale, vScale)
            end
            local matId = part["shader index"] + 1
            for _, face in ipairs(faces) do
                push(mesh.faces, face[1] + offset, face[2] + offset, face[3] + offset)
                mesh.matIds[#mesh.matIds + 1] = matId
            end
            mesh.vertexCount = offset + vertexCount
        end
    end
    return mesh
end

-------------------------------------------------------------------------------
-- Output (same order as readGbxModelWithLua)
-------------------------------------------------------------------------------

function gbxmodel.write(root, output, options)
    local scale = assert(tonumber(options[1]), "missing halo scale option")
    local uScale = root["base map u-scale"]
    local vScale = root["base map v-scale"]
    if math.abs(uScale) < 0.0001 then
        uScale = 1
    end
    if math.abs(vScale) < 0.0001 then
        vScale = 1
    end
    output:floats({uScale, vScale})

    output:int(#root["nodes"])
    for _, node in ipairs(root["nodes"]) do
        output:string(node["name"])
        output:ints({
            node["next sibling node index"],
            node["first child node index"],
            node["parent node index"]
        })
        output:floats(node["default translation"])
        output:floats(node["default rotation"])
        output:float(node["node distance from parent"])
    end

    output:int(#root["regions"])
    for _, region in ipairs(root["regions"]) do
        output:string(region["name"])
        output:int(#region["permutations"])
        for _, permutation in ipairs(region["permutations"]) do
            output:string(permutation["name"])
            output:ints({
                permutation["flags"],
                permutation["super low"],
                permutation["low"],
                permutation["medium"],
                permutation["high"],
                permutation["super high"]
            })
            output:int(#permutation["markers"])
            for _, marker in ipairs(permutation["markers"]) do
                output:string(marker["name"])
                output:int(marker["node index"])
                output:floats(marker["rotation"])
                output:floats(marker["translation"])
            end
        end
    end

    output:int(#root["shaders"])
    for _, shader in ipairs(root["shaders"]) do
        output:tagref(shader["shader"])
        output:int(shader["permutation"])
    end

    output:int(#root["geometries"])
    for _, geometry in ipairs(root["geometries"]) do
        local mesh = buildGeometry(geometry, scale, uScale, vScale)
        output:ints({mesh.vertexCount, #mesh.matIds})
        output:floats(mesh.positions)
        output:floats(mesh.normals)
        output:floats(mesh.uvs)
        output:ints(mesh.nodes)
        output:floats(mesh.weights)
        output:ints(mesh.faces)
        output:ints(mesh.matIds)
    end
end

return gbxmodel
