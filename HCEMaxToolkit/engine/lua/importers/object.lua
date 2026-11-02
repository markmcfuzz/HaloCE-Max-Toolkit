-- Object tags (biped, vehicle, weapon, scenery, device_machine) -> 3ds Max: model, collision and
-- physics paths, every field as text (shared\tag_fields.lua).
-- Read in Max by builders\tag\object\lua_reader.ms; written back by exporters\object.lua.
local tagDefs = require "tags.tag_defs"
local tagFields = require "importers.shared.tag_fields"
local maxbin = require "bridge.maxbin"

local readAs = tagDefs.readAs

local object = {group = {"biped", "vehicle", "weapon", "scenery", "device_machine"}, version = 1}

-- The element holding the object fields (unit.object in a vehicle)
local function findObject(structDef, element)
    for _, field in ipairs(structDef.fields) do
        if field.key == "collision model" then
            return element
        end
    end
    for _, field in ipairs(structDef.fields) do
        if field.readAs == readAs.struct then
            local found = findObject(field.sub, element[field.key])
            if found then
                return found
            end
        end
    end
    error("tag has no object fields", 0)
end

function object.write(root, output, options, tagData, defs)
    local objectFields = findObject(tagData.rootStruct, root)
    output:string(tagData.group)
    output:string(tagFields.refText(defs, objectFields["model"]))
    output:string(tagFields.refText(defs, objectFields["collision model"]))
    output:string(tagFields.refText(defs, objectFields["physics"]))

    local fields = tagFields.flatten(defs, tagData.rootStruct, root, "", {})
    output:int(#fields)
    for _, field in ipairs(fields) do
        output:string(field[1])
        output:string(field[2])
    end
end

-- A new tag with every field zero / empty, in the same format as object.write:
--   run.lua importers.object blank <group> <out.bin>
function object.blank(groupName, outPath)
    local known = false
    for _, g in ipairs(object.group) do
        known = known or g == groupName
    end
    if not known then
        error(("'%s' is not an object tag group"):format(tostring(groupName)), 0)
    end
    local defs = tagDefs.open()
    local rootStruct = defs:rootStruct(defs:group(groupName))
    local root = tagFields.unflatten(defs, rootStruct, {}, "")
    local output = maxbin.open(outPath, "object", object.version)
    object.write(root, output, {}, {group = groupName, rootStruct = rootStruct}, defs)
    output:close()
end

return object
