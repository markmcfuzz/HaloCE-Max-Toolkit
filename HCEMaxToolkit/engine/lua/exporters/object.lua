-- 3ds Max -> object tag (biped, vehicle, weapon, scenery, device_machine): the Point's fields,
-- written by builders\tag\object\export_tag.ms, back to tables for tags\tag_writer.lua.
-- Each tag reference gets the group of the file it points to.
local tagDefs = require "tags.tag_defs"
local tagFields = require "importers.shared.tag_fields"

local readAs = tagDefs.readAs

local object = {
    groups = {biped = true, vehicle = true, weapon = true, scenery = true, device_machine = true},
    version = 1
}

local function fileExists(path)
    local f = io.open(path, "rb")
    if f then
        f:close()
    end
    return f ~= nil
end

-- Picks the group of a reference whose path changed in Max; tagsRoot ends with "tags\"
local function resolveRef(defs, field, ref, tagsRoot, key)
    if ref.path == "" then
        return
    end
    -- A typed extension names the group
    local base, ext = ref.path:match("^(.*)%.([^.\\/]+)$")
    if base then
        for fourcc, name in pairs(defs.byFourcc) do
            if name == ext then
                ref.path, ref.group = base, fourcc
            end
        end
    end
    if not tagsRoot then
        return
    end

    local function exists(fourcc)
        local name = defs.byFourcc[fourcc]
        return name and fileExists(tagsRoot .. ref.path .. "." .. name)
    end
    if ref.group and exists(ref.group) then
        return
    end
    local accepted = defs:acceptedGroups(field)
    for _, fourcc in ipairs(accepted) do
        if exists(fourcc) then
            ref.group = fourcc
            return
        end
    end
    io.stdout:write(("warning: %s: tag not found: %s\n"):format(key, ref.path))
    ref.group = ref.group or accepted[1]
end

local function resolveRefs(defs, structDef, element, tagsRoot, prefix)
    for _, field in ipairs(structDef.fields) do
        local key = prefix .. field.key
        local r = field.readAs
        if r == readAs.tagRef then
            resolveRef(defs, field, element[field.key], tagsRoot, key)
        elseif r == readAs.struct then
            resolveRefs(defs, field.sub, element[field.key], tagsRoot, key .. ".")
        elseif r == readAs.block or r == readAs.array then
            local sub = r == readAs.block and defs:blockStruct(field) or field.sub
            for i, item in ipairs(element[field.key]) do
                resolveRefs(defs, sub, item, tagsRoot, key .. "[" .. (i - 1) .. "].")
            end
        end
    end
end

-- "D:\halo\tags\vehicles\warthog\warthog.vehicle" -> "D:\halo\tags\" (nil outside a tags folder)
local function tagsRootOf(tagPath)
    local at = tagPath:lower():find("[/\\]tags[/\\]")
    if at then
        return tagPath:sub(1, at + 5)
    end
end

-- input: group name, field count, then key and text per field. Returns group name and root
function object.read(input, defs, tagPath)
    local groupName = input:string()
    if not object.groups[groupName] then
        error(("object exporter does not write %s tags"):format(groupName), 0)
    end
    local values = {}
    for _ = 1, input:int() do
        local key = input:string()
        values[key] = input:string()
    end
    local rootStruct = defs:rootStruct(defs:group(groupName))
    local root = tagFields.unflatten(defs, rootStruct, values, "")
    resolveRefs(defs, rootStruct, root, tagsRootOf(tagPath), "")
    return groupName, root
end

return object
