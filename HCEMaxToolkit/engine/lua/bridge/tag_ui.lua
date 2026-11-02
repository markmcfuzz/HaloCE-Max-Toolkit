-- Layout of a tag group for the Python tag editor (engine\core\tag_editor), in tag order:
--   run.lua bridge.tag_ui layout <group> <out.json>
-- Keys match importers\shared\tag_fields.lua; inside a block they are relative to the element.
local tagDefs = require "tags.tag_defs"
local json = require "tags.json"

local readAs = tagDefs.readAs

local tagUi = {}

local defs -- definitions of the group being described

-- "seats" -> "Seats", "device_machine" -> "Device Machine"
local function capitalize(text)
    text = text:gsub("_(%l)", function(c)
        return " " .. c:upper()
    end)
    return (text:gsub("^%l", string.upper))
end

-- "has e-brake*#NOT YET BACKPORTED from H2" -> "has e-brake" ("region #00 damage" stays)
local function optionName(name)
    name = name:gsub("#%a.*$", ""):gsub("[%*%^!]", "")
    return (name:match("^%s*(.-)%s*$"))
end

-- Enum or flags option names of a field, or nil when the definition has none
local function fieldOptions(field)
    local ok, entry = pcall(defs.lookup, defs, field.owner, "enums_flags", field.definition)
    if ok and entry.options then
        local names = {}
        for i, name in ipairs(entry.options) do
            names[i] = optionName(name)
        end
        return names
    end
end

local intRanges = {
    [readAs.int8] = {-128, 127},
    [readAs.uint8] = {0, 255},
    [readAs.int16] = {-32768, 32767},
    [readAs.uint16] = {0, 65535},
    [readAs.int32] = {-2147483648, 2147483647}
}

local partCounts = {
    [readAs.float2] = 2,
    [readAs.float3] = 3,
    [readAs.float4] = 4,
    [readAs.int16x2] = 2,
    [readAs.int16x4] = 4
}

-- What the editor shows for a field: kind plus what that kind needs
local function fieldLayout(field, key)
    local t, r = field.type, field.readAs
    local item = {name = field.name, key = key}
    local options = fieldOptions(field)
    if t:find("_enum$") and options then
        item.kind, item.options = "enum", options
    elseif t:find("_flags$") and options then
        item.kind, item.options = "flags", options
    elseif t == "angle" then
        item.kind = "angle"
    elseif t == "angle_bounds" or t:find("^real_euler_angles") then
        item.kind, item.parts = "angles", partCounts[r]
    elseif t == "real_rgb_color" or t == "real_argb_color" then
        -- 0-1 floats: r g b, or a r g b
        item.kind, item.parts = "color", partCounts[r]
    elseif r == readAs.float then
        item.kind = "float"
    elseif r == readAs.float2 or r == readAs.float3 or r == readAs.float4 then
        item.kind, item.parts = "floats", partCounts[r]
    elseif r == readAs.int16x2 or r == readAs.int16x4 then
        item.kind, item.parts = "ints", partCounts[r]
    elseif intRanges[r] then
        item.kind, item.min, item.max = "int", intRanges[r][1], intRanges[r][2]
    elseif r == readAs.tagRef then
        -- Path without extension; the tooltip lists the allowed groups
        local allowed = {}
        for _, fourcc in ipairs(field.definition and field.definition.allowed or {}) do
            allowed[#allowed + 1] = defs.byFourcc[fourcc] or fourcc
        end
        -- {name, fourcc} of every group the file browser shows (inheriting groups too)
        local accepts = {}
        for _, fourcc in ipairs(defs:acceptedGroups(field)) do
            if defs.byFourcc[fourcc] then
                accepts[#accepts + 1] = {defs.byFourcc[fourcc], fourcc}
            end
        end
        item.kind, item.allowed, item.accepts = "ref", allowed, accepts
    elseif r == readAs.string then
        item.kind, item.maxLength = "text", 31
    else
        item.kind, item.maxLength = "text", 255
    end
    return item
end

-- First text or tag reference of an element, shown next to its number in the picker
local function labelField(structDef)
    for _, field in ipairs(structDef.fields) do
        if field.readAs == readAs.string or field.readAs == readAs.tagRef then
            return field
        end
    end
end

local structFields -- structFields and blockLayout call each other

local function blockLayout(field, key)
    local sub = field.readAs == readAs.block and defs:blockStruct(field) or field.sub
    -- Arrays have a fixed count; blocks can grow up to max
    local item = {kind = "block", name = field.name, key = key, fields = {}}
    if field.readAs == readAs.array then
        item.fixed, item.count = true, field.count
    else
        item.max = field.maxCount
    end
    local label = labelField(sub)
    if label then
        item.label, item.labelIsRef = label.key, label.readAs == readAs.tagRef
    end
    -- The object's functions and change colors are A-D in game: "0: A out", "0: A"
    if key:find("object%.functions$") then
        item.letters = " out"
    elseif key:find("object%.change colors$") then
        item.letters = ""
    end
    structFields(sub, "", item.fields)
    return item
end

-- Fields of a struct in tag order; structs inside it are shown inline
structFields = function(structDef, prefix, out)
    for _, field in ipairs(structDef.fields) do
        if field.readAs == readAs.struct then
            structFields(field.sub, prefix .. field.key .. ".", out)
        elseif field.readAs == readAs.block or field.readAs == readAs.array then
            out[#out + 1] = blockLayout(field, prefix .. field.key)
        else
            out[#out + 1] = fieldLayout(field, prefix .. field.key)
        end
    end
end

-- Sections in tag order (object, unit, vehicle): the parent struct comes first
local function collectSections(structDef, prefix, title, sections)
    local section = {title = capitalize(title), fields = {}}
    for _, field in ipairs(structDef.fields) do
        if field.readAs == readAs.struct then
            collectSections(field.sub, prefix .. field.key .. ".", field.key, sections)
        elseif field.readAs == readAs.block or field.readAs == readAs.array then
            section.fields[#section.fields + 1] = blockLayout(field, prefix .. field.key)
        else
            section.fields[#section.fields + 1] = fieldLayout(field, prefix .. field.key)
        end
    end
    if #section.fields > 0 then
        sections[#sections + 1] = section
    end
end

-- Layout table of a group: {group, title, sections = {{title, fields}, ...}}
function tagUi.groupLayout(tagDefinitions, groupName)
    defs = tagDefinitions
    local sections = {}
    collectSections(defs:rootStruct(defs:group(groupName)), "", groupName, sections)
    defs = nil
    return {group = groupName, title = capitalize(groupName), sections = sections}
end

function tagUi.layout(groupName, outPath)
    if not (groupName and outPath) then
        error("usage: run.lua bridge.tag_ui layout <group> <out.json>", 0)
    end
    local layout = tagUi.groupLayout(tagDefs.open(), groupName)
    local f = assert(io.open(outPath, "wb"))
    f:write(json.encode(layout))
    f:close()
end

return tagUi
