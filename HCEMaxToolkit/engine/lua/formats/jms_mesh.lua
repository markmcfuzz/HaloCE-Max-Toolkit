-- Builds the JMS vertex list from the scene meshes Max sends (formats\jms\process_scene.ms).
-- Same rules as the previous MAXScript loop: one vertex per face corner, merged with an earlier
-- vertex of the same object when the createVertexHash key matched.
local ffi = require "ffi" -- LuaJIT: C types and direct memory access
local f32 = require("formats.max_numbers").f32

local floor, ceil, format = math.floor, math.ceil, string.format

local jmsMesh = {}

-- (x * 10000) as integer in MAXScript: Float product, truncated toward zero
local function keyInt(x)
    local y = f32(x * 10000)
    return y >= 0 and floor(y) or ceil(y)
end

-- Two strongest bone weights of a vertex, as the old loop picked them (first maximum wins).
-- bones/weights: lists of node indices and weights. Returns node0, node1, weight1 or nil.
local function topTwo(bones, weights)
    local count = #bones
    if count == 0 then
        return nil
    end
    local first = 1
    for i = 2, count do
        if weights[i] > weights[first] then
            first = i
        end
    end
    local second
    for i = 1, count do
        if i ~= first and (not second or weights[i] > weights[second]) then
            second = i
        end
    end
    if second then
        return bones[first], bones[second], weights[second]
    end
    return bones[first], -1, 0
end

-- Normal of every face corner from a file saved by meshNormalsSave (shared\utils\mesh_normals.ms):
-- float x,y,z per normal, then per face 3 normal ids + specified bits (int32). rotMatrix: the 4
-- rows of the object's rotation matrix (12 floats). Same result as MAXScript's
-- normalize (normal * rotMatrix): Float product, then normalize in double precision (checked
-- bit for bit against Max).
function jmsMesh.savedNormals(path, normalCount, faceCount, rotMatrix)
    local file = assert(io.open(path, "rb"))
    local data = file:read("*a")
    file:close()
    if #data ~= normalCount * 12 + faceCount * 16 then
        error("unexpected size of " .. path, 0)
    end
    local values = ffi.cast("const float*", data)
    local ids = ffi.cast("const int32_t*", ffi.cast("const uint8_t*", data) + normalCount * 12)
    local m = rotMatrix -- short name for the formulas below

    local world = {} -- world-space normal per normal id, computed once
    local out = {}
    for corner = 0, faceCount * 3 - 1 do
        local id = ids[math.floor(corner / 3) * 4 + corner % 3]
        if id < 0 or id >= normalCount then
            error("normal id " .. id .. " out of range in " .. path, 0)
        end
        local normal = world[id]
        if not normal then
            local x, y, z = values[id * 3], values[id * 3 + 1], values[id * 3 + 2]
            local wx = f32(f32(f32(f32(x * m[1]) + f32(y * m[4])) + f32(z * m[7])) + m[10])
            local wy = f32(f32(f32(f32(x * m[2]) + f32(y * m[5])) + f32(z * m[8])) + m[11])
            local wz = f32(f32(f32(f32(x * m[3]) + f32(y * m[6])) + f32(z * m[9])) + m[12])
            local length = math.sqrt(wx * wx + wy * wy + wz * wz)
            normal = {f32(wx / length), f32(wy / length), f32(wz / length)}
            world[id] = normal
        end
        out[corner * 3 + 1], out[corner * 3 + 2], out[corner * 3 + 3] = normal[1], normal[2],
                                                                        normal[3]
    end
    return out
end

-- obj: { parent, positions = {x,y,z,...}, skin = nil | { {bones}, {weights} } per vertex,
--        uvs = {u,v,...}, faces = vertex per corner, tvfaces = uv per corner or nil,
--        normals = {x,y,z per corner} }; indices are 1-based like Max's.
-- Appends new vertices to `vertices` and returns the global (0-based) index of every corner.
function jmsMesh.addObject(obj, vertices, corners)
    -- Bone influence of each vertex, picked once per vertex
    local node0, node1, weight1 = {}, {}, {}
    local vertexCount = #obj.positions / 3
    for vertex = 1, vertexCount do
        local influence = obj.skin and obj.skin[vertex]
        local bone0, bone1, weight
        if influence then
            bone0, bone1, weight = topTwo(influence[1], influence[2])
        end
        if bone0 then
            node0[vertex], node1[vertex], weight1[vertex] = bone0, bone1, weight
        else
            node0[vertex], node1[vertex], weight1[vertex] = obj.parent, -1, 0
        end
    end

    local seen = {} -- vertex key -> index of the vertex already added
    local positions, uvs, normals, faces, tvfaces = obj.positions, obj.uvs, obj.normals, obj.faces,
                                                    obj.tvfaces
    local uvCount = #uvs / 2
    for corner = 1, #faces do
        local vertex = faces[corner]
        local positionAt = (vertex - 1) * 3
        local x, y, z = positions[positionAt + 1], positions[positionAt + 2],
                        positions[positionAt + 3]
        local normalAt = (corner - 1) * 3
        local nx, ny, nz = normals[normalAt + 1], normals[normalAt + 2], normals[normalAt + 3]
        local u, v = 0, 0
        if tvfaces then
            local uvIndex = tvfaces[corner]
            if uvIndex > 0 and uvIndex <= uvCount then
                u, v = uvs[uvIndex * 2 - 1], uvs[uvIndex * 2]
            end
        end
        local key = format("%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", keyInt(x), keyInt(y), keyInt(z),
                           keyInt(nx), keyInt(ny), keyInt(nz), keyInt(u), keyInt(v), node0[vertex],
                           node1[vertex], keyInt(weight1[vertex]))
        local index = seen[key]
        if not index then
            index = #vertices
            vertices[index + 1] = {
                node0 = node0[vertex],
                pos = {x, y, z},
                normal = {nx, ny, nz},
                node1 = node1[vertex],
                weight = weight1[vertex],
                u = u,
                v = v
            }
            seen[key] = index
        end
        corners[#corners + 1] = index
    end
end

return jmsMesh
