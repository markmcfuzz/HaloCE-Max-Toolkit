-- physics -> 3ds Max: every field as text (shared\tag_fields.lua); the builder makes the mass
-- point spheres from them. Read in Max by builders\tag\physics\lua_reader.ms.
local tagFields = require "importers.shared.tag_fields"

local physics = {group = "physics", version = 2}

function physics.write(root, output, options, tagData, defs)
    local fields = tagFields.flatten(defs, tagData.rootStruct, root, "", {})
    output:int(#fields)
    for _, field in ipairs(fields) do
        output:string(field[1])
        output:string(field[2])
    end
end

return physics
