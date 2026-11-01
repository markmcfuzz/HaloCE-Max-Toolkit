-- Loads the Halo CE JSON tag definitions and compiles each struct into a list of fields with
-- their byte offsets. Every struct is checked against its declared size, so mistakes fail early.
local json = require "tags.json"

local tagDefs = {}

-- How a field is read from the tag. Many JSON types share one (real_point_3d, real_vector_3d
-- and real_rgb_color are all read as float3). tag_reader.lua reads each field by this.
local readAs = {
    skip = 0, -- padding and UI-only fields: no value
    int8 = 1,
    uint8 = 2,
    int16 = 3,
    uint16 = 4,
    int32 = 5,
    uint32 = 6,
    float = 7,
    float2 = 8,
    float3 = 9,
    float4 = 10,
    int16x2 = 11,
    int16x4 = 12,
    string = 13, -- 32-byte text
    fourcc = 14, -- 4-letter tag group, e.g. "bitm"
    tagRef = 15, -- 16 bytes; the path is stored after the element
    block = 16, -- 12 bytes; the elements are stored after the element
    data = 17, -- 20 bytes; the raw bytes are stored after the element
    struct = 18, -- struct inside the element
    array = 19 -- fixed number of structs inside the element
}
tagDefs.readAs = readAs

-- JSON type name -> { readAs, size in bytes }
local typeInfo = {
    char_integer = {readAs.int8, 1},
    short_integer = {readAs.int16, 2},
    long_integer = {readAs.int32, 4},
    char_enum = {readAs.int8, 1},
    short_enum = {readAs.int16, 2},
    long_enum = {readAs.int32, 4},
    byte_flags = {readAs.uint8, 1},
    word_flags = {readAs.uint16, 2},
    long_flags = {readAs.uint32, 4},
    char_block_index = {readAs.int8, 1},
    short_block_index = {readAs.int16, 2},
    long_block_index = {readAs.int32, 4},
    rgb_color = {readAs.uint32, 4},
    argb_color = {readAs.uint32, 4},
    tag = {readAs.fourcc, 4},
    angle = {readAs.float, 4},
    real = {readAs.float, 4},
    real_fraction = {readAs.float, 4},
    point_2d = {readAs.int16x2, 4},
    rectangle_2d = {readAs.int16x4, 8},
    short_bounds = {readAs.int16x2, 4},
    real_point_2d = {readAs.float2, 8},
    real_vector_2d = {readAs.float2, 8},
    real_euler_angles_2d = {readAs.float2, 8},
    real_bounds = {readAs.float2, 8},
    angle_bounds = {readAs.float2, 8},
    fraction_bounds = {readAs.float2, 8},
    real_point_3d = {readAs.float3, 12},
    real_vector_3d = {readAs.float3, 12},
    real_euler_angles_3d = {readAs.float3, 12},
    real_plane_2d = {readAs.float3, 12},
    real_rgb_color = {readAs.float3, 12},
    real_hsv_color = {readAs.float3, 12},
    real_quaternion = {readAs.float4, 16},
    real_plane_3d = {readAs.float4, 16},
    real_argb_color = {readAs.float4, 16},
    real_ahsv_color = {readAs.float4, 16},
    string = {readAs.string, 32},
    tag_reference = {readAs.tagRef, 16},
    block = {readAs.block, 12},
    data = {readAs.data, 20},
    explanation = {readAs.skip, 0},
    custom = {readAs.skip, 0},
    terminator = {readAs.skip, 0}
}

-- Folder of this file + \definitions
local function defaultDir()
    local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\]") or "."
    return here .. "/definitions"
end

-- "base map u-scale*#0 defaults to 1" -> "base map u-scale" 
-- ('#' description, ':' units, '*^!' flags)
local function cleanName(name)
    if type(name) ~= "string" then
        return nil
    end
    local cut = name:find("[#:]")
    if cut then
        name = name:sub(1, cut - 1)
    end
    name = name:gsub("[%*%^!]", "")
    name = name:match("^%s*(.-)%s*$")
    if name == "" then
        return nil
    end
    return name
end

-------------------------------------------------------------------------------
-- Loading
-------------------------------------------------------------------------------

-- Functions shared by the definitions that tagDefs.open returns
local definitions = {}
definitions.__index = definitions

-- dir: folder with _meta.json and <group>.json (defaults to lua\tags\definitions).
-- Group files are loaded the first time they are needed.
function tagDefs.open(dir)
    dir = (dir or defaultDir()):gsub("[/\\]$", "")
    local meta = json.decodeFile(dir .. "/_meta.json")
    return setmetatable({
        dir = dir,
        byFourcc = meta.tag_index or {}, -- fourcc -> group name, e.g. "mod2" -> "gbxmodel"
        groups = {}, -- group name -> its JSON
        compiled = {} -- "group/struct" -> compiled struct
    }, definitions)
end

-- JSON of a group by name ("gbxmodel"), loaded once
function definitions:group(name)
    local g = self.groups[name]
    if g then
        return g
    end
    g = json.decodeFile(self.dir .. "/" .. name .. ".json")
    self.groups[name] = g
    return g
end

-- JSON of a group by its fourcc ("mod2"), or nil when unknown
function definitions:groupByFourcc(fourcc)
    local name = self.byFourcc[fourcc]
    if not name then
        return nil
    end
    return self:group(name)
end

-- Finds an entry of a section ("structs", "blocks" or "arrays") in the group or its parents
-- (a weapon's fields include item's and object's). Returns the entry and the group it is in.
function definitions:lookup(group, section, name)
    local g = group
    while g do
        local t = g[section]
        if t and t[name] then
            return t[name], g
        end
        -- parent_tag is a group name ("unit") or a fourcc ("obje")
        local parent = g.parent_tag
        if type(parent) == "string" then
            g = self:group(self.byFourcc[parent] or parent)
        else
            g = nil
        end
    end
    error(("definition not found: %s '%s' (from group '%s')"):format(section, name, group.name), 0)
end

-------------------------------------------------------------------------------
-- Compiling
-------------------------------------------------------------------------------

-- Turns a JSON struct into { name, size, fields, hasTail }, cached. Each field is
-- { key, name, readAs, offset, size, sub, count, maxCount, type, definition, owner }:
--   key: unique name in the struct ("flags", "flags 2"); name: as in the definition
--   sub: struct of a struct/array field, or { owner, struct } of a block field
--   type: JSON type name ("real_point_3d"); definition, owner: its JSON definition and group
-- hasTail: the struct has tag references, data or blocks, whose contents (its tail) come after it.
function definitions:compileStruct(group, structName)
    local cacheKey = group.name .. "/" .. structName
    local c = self.compiled[cacheKey]
    if c then
        return c
    end

    local def, owner = self:lookup(group, "structs", structName)
    cacheKey = owner.name .. "/" .. structName
    c = self.compiled[cacheKey]
    if c then
        return c
    end

    c = {name = structName, size = def.size, fields = {}, hasTail = false}
    -- registered before recursing (blocks can contain themselves)
    self.compiled[cacheKey] = c

    local offset = 0
    local used = {}
    for _, fd in ipairs(def.fields) do
        local t = fd.type
        local fieldReadAs, size, sub, count, maxCount
        if t == "pad" or t == "skip" then
            fieldReadAs, size = readAs.skip, fd.definition
        elseif t == "struct" then
            fieldReadAs = readAs.struct
            sub = self:compileStruct(owner, fd.definition)
            size = sub.size
        elseif t == "array" then
            fieldReadAs = readAs.array
            local arr, arrOwner = self:lookup(owner, "arrays", fd.definition)
            sub = self:compileStruct(arrOwner, arr.struct)
            count = arr.count
            size = sub.size * count
        elseif t == "block" then
            fieldReadAs, size = readAs.block, 12
            local blk, blkOwner = self:lookup(owner, "blocks", fd.definition)
            sub = {owner = blkOwner, struct = blk.struct} -- compiled when first read (blockStruct)
            maxCount = blk.max_count
        else
            local info = typeInfo[t]
            if not info then
                error(("unknown field type '%s' in %s/%s"):format(t, owner.name, structName), 0)
            end
            fieldReadAs, size = info[1], info[2]
        end

        if size > 0 and fieldReadAs ~= readAs.skip then
            local name = cleanName(fd.name)
            local key = name or ("field_" .. offset)
            if used[key] then
                local n = 2
                while used[key .. " " .. n] do
                    n = n + 1
                end
                key = key .. " " .. n
            end
            used[key] = true
            c.fields[#c.fields + 1] = {
                key = key,
                name = name or key,
                readAs = fieldReadAs,
                offset = offset,
                size = size,
                sub = sub,
                count = count,
                maxCount = maxCount,
                type = t,
                definition = fd.definition,
                owner = owner
            }
            if fieldReadAs == readAs.tagRef or fieldReadAs == readAs.data or fieldReadAs ==
                readAs.block then
                c.hasTail = true
            elseif (fieldReadAs == readAs.struct or fieldReadAs == readAs.array) and sub.hasTail then
                c.hasTail = true
            end
        end
        offset = offset + size
    end

    if offset ~= def.size then
        error(("struct %s/%s: fields add up to %d bytes but definition says %d"):format(owner.name,
                                                                                        structName,
                                                                                        offset,
                                                                                        def.size), 0)
    end
    return c
end

-- Compiled struct of a block field's elements
function definitions:blockStruct(field)
    local sub = field.sub
    if not sub.compiled then
        sub.compiled = self:compileStruct(sub.owner, sub.struct)
    end
    return sub.compiled
end

-- Compiled struct of a group's main element (the whole tag)
function definitions:rootStruct(group)
    local blk = group.blocks[group.block]
    return self:compileStruct(group, blk.struct)
end

-- Compiles every struct of every group; returns a list of error strings (empty = all good)
function definitions:validateAll()
    local errors = {}
    for _, name in pairs(self.byFourcc) do
        local ok, err = pcall(function()
            local g = self:group(name)
            for sname in pairs(g.structs) do
                self:compileStruct(g, sname)
            end
        end)
        if not ok then
            errors[#errors + 1] = name .. ": " .. tostring(err)
        end
    end
    table.sort(errors)
    return errors
end

return tagDefs
