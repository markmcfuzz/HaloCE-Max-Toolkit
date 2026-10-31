-- Writes a tag element as the field tuples of the previous MAXScript parser:
-- #(#("camelCaseName", value), ...), blocks as arrays of those. Read in Max by luaReadTuples (lua_bridge.ms).
local tagDefs = require "tags.tag_defs"
local readAs = tagDefs.readAs

local tuples = {}

-- Value type sent before each value; luaReadTuples in lua_bridge.ms uses the same numbers
local valueType = {
    int = 1,
    float = 2,
    color = 3,
    argb = 4,
    point2 = 5,
    point3 = 6,
    tagRef = 7,
    block = 8,
    string = 9
}

local integerReadAs = {
    [readAs.int8] = true,
    [readAs.uint8] = true,
    [readAs.int16] = true,
    [readAs.uint16] = true,
    [readAs.int32] = true,
    [readAs.uint32] = true
}

-- "map u-scale" -> "mapUScale", "rotation-animation center" -> "rotationAnimationCenter"
local function camelCase(name)
    local out, first = {}, true
    for word in name:gmatch("[^%s%-]+") do
        if first then
            out[#out + 1] = word:sub(1, 1):lower() .. word:sub(2)
            first = false
        else
            out[#out + 1] = word:sub(1, 1):upper() .. word:sub(2)
        end
    end
    return table.concat(out)
end

-- Value type of a compiled field (tag_defs.lua); errors for fields Max does not read yet
local function valueTypeOf(field)
    local fieldReadAs = field.readAs
    if integerReadAs[fieldReadAs] then
        return valueType.int
    elseif fieldReadAs == readAs.float then
        return valueType.float
    elseif fieldReadAs == readAs.float2 then
        return valueType.point2
    elseif fieldReadAs == readAs.float3 then
        return field.type == "real_rgb_color" and valueType.color or valueType.point3
    elseif fieldReadAs == readAs.float4 and field.type == "real_argb_color" then
        return valueType.argb
    elseif fieldReadAs == readAs.tagRef then
        return valueType.tagRef
    elseif fieldReadAs == readAs.block then
        return valueType.block
    elseif fieldReadAs == readAs.string then
        return valueType.string
    end
    error(("field '%s' (%s) has no tuple form yet"):format(field.key, field.type), 0)
end

-- Writes every field of element (read with structDef) as name, value type and value.
-- Fields before firstField are left out (default 1).
function tuples.write(w, structDef, element, firstField)
    local fields = structDef.fields
    firstField = firstField or 1
    w:int(#fields - firstField + 1)
    for i = firstField, #fields do
        local field = fields[i]
        local value = element[field.key]
        local fieldType = valueTypeOf(field)
        w:string(camelCase(field.name))
        w:int(fieldType)
        if fieldType == valueType.int then
            w:int(value)
        elseif fieldType == valueType.float then
            w:float(value)
        elseif fieldType == valueType.point2 or fieldType == valueType.point3 or fieldType == valueType.color then
            w:floats(value)
        elseif fieldType == valueType.argb then
            w:floats({value[2], value[3], value[4], value[1]}) -- stored a,r,g,b; Max gets point4 r g b a
        elseif fieldType == valueType.tagRef then
            w:tagref(value)
        elseif fieldType == valueType.string then
            w:string(value)
        elseif fieldType == valueType.block then
            w:int(#value)
            -- Elements were read with this compiled struct (empty blocks have none)
            for _, child in ipairs(value) do
                tuples.write(w, field.sub.compiled, child)
            end
        end
    end
end

return tuples
