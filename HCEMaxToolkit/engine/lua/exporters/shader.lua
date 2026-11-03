-- 3ds Max -> shader tag: fields read from a GlyphFX material by pipeline\create_tag\create_shader.ms.
-- Keys match field names ignoring case, spaces and symbols ("mapUScale" = "map u-scale" = "map uscale").
-- Missing fields stay zero; flags are integers, enums indices, refs "bitm:path".
local tagDefs = require "tags.tag_defs"
local tagFields = require "importers.shared.tag_fields"

local readAs = tagDefs.readAs

local shader = {
    groups = {
        shader_model = true,
        shader_model_extended = true,
        shader_environment = true,
        shader_transparent_chicago = true,
        shader_transparent_chicago_extended = true,
        shader_transparent_generic = true,
        shader_transparent_glass = true,
        shader_transparent_meter = true,
        shader_transparent_plasma = true,
        shader_transparent_water = true
    },
    version = 1
}

local function normalize(name)
    return (name:lower():gsub("[^%w]", ""))
end

local function fieldByName(structDef, name)
    local wanted = normalize(name)
    for _, field in ipairs(structDef.fields) do
        if field.readAs ~= readAs.skip and normalize(field.key) == wanted then
            return field
        end
    end
end

-- "stages[0].inputA2" -> "stages[0].input A 2" (the key tag_fields.unflatten uses)
local function tagKey(defs, rootStruct, maxKey)
    local parts = {}
    local structDef = rootStruct
    for segment in maxKey:gmatch("[^.]+") do
        local name, index = segment:match("^(.-)(%[%d+%])$")
        name = name or segment
        local field = structDef and fieldByName(structDef, name)
        if not field then
            error(("unknown shader field '%s'"):format(maxKey), 0)
        end
        parts[#parts + 1] = field.key .. (index or "")
        local r = field.readAs
        if r == readAs.struct then
            structDef = field.sub
        elseif index and r == readAs.block then
            structDef = defs:blockStruct(field)
        elseif index and r == readAs.array then
            structDef = field.sub
        else
            structDef = nil
        end
    end
    return table.concat(parts, ".")
end

-- input: group name, field count, then key and text per field. Returns group name and root
function shader.read(input, defs)
    local groupName = input:string()
    if not shader.groups[groupName] then
        error(("shader exporter does not write %s tags"):format(groupName), 0)
    end
    local rootStruct = defs:rootStruct(defs:group(groupName))
    local values = {}
    for _ = 1, input:int() do
        local key = tagKey(defs, rootStruct, input:string())
        values[key] = input:string()
    end
    return groupName, tagFields.unflatten(defs, rootStruct, values, "")
end

return shader
