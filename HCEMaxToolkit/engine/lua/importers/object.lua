-- Object tags (biped, vehicle, weapon, scenery, device_machine) -> 3ds Max: model, collision and physics paths, every field as text
-- (shared\tag_fields.lua). options[1]: where to write the panel script (bridge\tag_ui.lua).
-- Read in Max by builders\tag\object\lua_reader.ms; written back by exporters\object.lua.
local tagDefs = require "tags.tag_defs"
local tagFields = require "importers.shared.tag_fields"
local tagUi = require "bridge.tag_ui"

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

    if options[1] then
        tagUi.writeScript(defs, tagData.group, tagData.rootStruct, options[1])
    end
end

return object
