-- Every field of a tag as text, keyed by its path: "unit.seats[0].yaw rate" = "60".
-- Block counts are fields too ("unit.seats" = "3"). Used by the object importer/exporter.
local ffi = require "ffi"
local tagDefs = require "tags.tag_defs"

local readAs = tagDefs.readAs

local tagFields = {}

local float32 = ffi.new("float[1]")

local partCounts = {
    [readAs.float2] = 2,
    [readAs.float3] = 3,
    [readAs.float4] = 4,
    [readAs.int16x2] = 2,
    [readAs.int16x4] = 4
}

-- Shortest text that reads back as the same 32-bit float ("0.255", not "0.254999995")
function tagFields.floatText(value)
    if value ~= value or value == math.huge or value == -math.huge then
        return ("%.9g"):format(value)
    end
    float32[0] = value
    local exact = float32[0]
    for digits = 6, 8 do
        local text = ("%." .. digits .. "g"):format(exact)
        float32[0] = tonumber(text)
        if float32[0] == exact then
            return text
        end
    end
    return ("%.9g"):format(exact)
end

-- Tag reference as a tags-relative path with extension ("vehicles\warthog\warthog.gbxmodel")
function tagFields.refText(defs, ref)
    if ref.path == "" then
        return ""
    end
    local groupName = ref.group and defs.byFourcc[ref.group]
    if not groupName then
        return ref.path
    end
    return ref.path .. "." .. groupName
end

local function floatsText(values)
    local parts = {}
    for i, v in ipairs(values) do
        parts[i] = tagFields.floatText(v)
    end
    return table.concat(parts, " ")
end

local function valueText(field, value)
    local r = field.readAs
    if r == readAs.float then
        return tagFields.floatText(value)
    elseif r == readAs.float2 or r == readAs.float3 or r == readAs.float4 then
        return floatsText(value)
    elseif r == readAs.int16x2 or r == readAs.int16x4 then
        return table.concat(value, " ")
    elseif r == readAs.uint32 then
        -- Signed, so MAXScript reads every bit as a normal integer
        if value >= 2147483648 then
            value = value - 4294967296
        end
        return tostring(value)
    elseif r == readAs.int8 or r == readAs.uint8 or r == readAs.int16 or r == readAs.uint16 or r ==
        readAs.int32 then
        return tostring(value)
    elseif r == readAs.string then
        return value
    elseif r == readAs.fourcc then
        return value or ""
    elseif r == readAs.tagRef then
        -- "ligh:vehicles\warthog\headlights"; a group of zero bytes is stored as none
        local group = value.group or ""
        if group:find("[%z\1-\31]") then
            group = ""
        end
        return group .. ":" .. value.path
    end
    error(("field '%s' (%s) is not supported yet"):format(field.key, field.type), 0)
end

-- Adds { key, text } pairs for the fields of one element to out, in tag order
function tagFields.flatten(defs, structDef, element, prefix, out)
    for _, field in ipairs(structDef.fields) do
        local key = prefix .. field.key
        local value = element[field.key]
        if field.readAs == readAs.struct then
            tagFields.flatten(defs, field.sub, value, key .. ".", out)
        elseif field.readAs == readAs.block or field.readAs == readAs.array then
            local sub = field.readAs == readAs.block and defs:blockStruct(field) or field.sub
            out[#out + 1] = {key, tostring(#value)}
            for i, item in ipairs(value) do
                tagFields.flatten(defs, sub, item, key .. "[" .. (i - 1) .. "].", out)
            end
        else
            out[#out + 1] = {key, valueText(field, value)}
        end
    end
    return out
end

-------------------------------------------------------------------------------
-- Text back to values (tag_writer.lua takes the result)
-------------------------------------------------------------------------------

local function toNumber(key, text)
    local v = tonumber(text)
    if not v then
        error(("field '%s': '%s' is not a number"):format(key, text), 0)
    end
    return v
end

-- Missing fields (text nil) get zero / empty values
local function parseValue(field, key, text)
    local r = field.readAs
    text = text or ""
    if r == readAs.string then
        return text
    elseif r == readAs.fourcc then
        return text ~= "" and text or nil
    elseif r == readAs.tagRef then
        local group, path = text:match("^([^:]*):(.*)$")
        if not group then
            group, path = "", text
        end
        return {group = group ~= "" and group or nil, path = path}
    end
    local count = partCounts[r]
    if count then
        local values = {}
        for part in text:gmatch("%S+") do
            values[#values + 1] = toNumber(key, part)
        end
        for i = #values + 1, count do
            values[i] = 0
        end
        return values
    end
    if text == "" then
        return 0
    end
    return toNumber(key, text)
end

-- Element tables (as tag_reader.lua makes them) from the key -> text map that flatten made
function tagFields.unflatten(defs, structDef, values, prefix)
    local element = {}
    for _, field in ipairs(structDef.fields) do
        local key = prefix .. field.key
        local r = field.readAs
        if r == readAs.struct then
            element[field.key] = tagFields.unflatten(defs, field.sub, values, key .. ".")
        elseif r == readAs.block or r == readAs.array then
            local sub = r == readAs.block and defs:blockStruct(field) or field.sub
            local count = r == readAs.array and field.count or toNumber(key, values[key] or "0")
            local list = {}
            for i = 1, count do
                list[i] = tagFields.unflatten(defs, sub, values, key .. "[" .. (i - 1) .. "].")
            end
            element[field.key] = list
        else
            element[field.key] = parseValue(field, key, values[key])
        end
    end
    return element
end

return tagFields
