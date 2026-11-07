-- Any shader tag -> 3ds Max: the parent 'shader' fields and the shader type's own fields,
-- as parser-style tuples (shared\tuples.lua), then every field as text (shared\tag_fields.lua)
-- for the tag editor. Read in Max by builders\tag\shared\shader_resolver.ms.
local tuples = require "importers.shared.tuples"
local tagFields = require "importers.shared.tag_fields"
local tagDefs = require "tags.tag_defs"
local maxbin = require "bridge.maxbin"

local shader = {
    group = {
        "shader_model",
        "shader_model_extended",
        "shader_environment",
        "shader_transparent_chicago",
        "shader_transparent_chicago_extended",
        "shader_transparent_generic",
        "shader_transparent_glass",
        "shader_transparent_meter",
        "shader_transparent_plasma",
        "shader_transparent_water"
    },
    version = 2
}

function shader.write(root, output, options, tag, defs)
    -- Field 1 of every shader type is the inherited 'shader' struct
    local rootStruct = tag.rootStruct
    tuples.write(output, rootStruct.fields[1].sub, root["shader"])
    tuples.write(output, rootStruct, root, 2)

    local fields = tagFields.flatten(defs, rootStruct, root, "", {})
    output:int(#fields)
    for _, field in ipairs(fields) do
        output:string(field[1])
        output:string(field[2])
    end
end

-- The fields kept on a material (tag editor edits) -> the same output as shader.write:
--   run.lua importers.shader fromFields <in.bin> <out.bin>
-- in.bin ("shaderFields" v1, applyShaderTagFields in Max): group name, field count, key and text per field
function shader.fromFields(inPath, outPath)
    local defs = tagDefs.open()
    local input = maxbin.readFile(inPath, "shaderFields", 1)
    local groupName = input:string()
    local rootStruct = defs:rootStruct(defs:group(groupName))
    local values = {}
    for _ = 1, input:int() do
        local key = input:string()
        values[key] = input:string()
    end
    local root = tagFields.unflatten(defs, rootStruct, values, "")
    local output = maxbin.open(outPath, "shader", shader.version)
    shader.write(root, output, {}, {rootStruct = rootStruct}, defs)
    output:close()
end

-- A material made by hand -> every field of its tag (what the material lacks is zero):
--   run.lua importers.shader fromMax <in.bin> <out.bin>
-- in.bin is what Build Shaders' reader writes for exporters\shader.lua; out.bin ("shaderFields" v1):
-- group name, field count, key and text per field
function shader.fromMax(inPath, outPath)
    local defs = tagDefs.open()
    local exporter = require "exporters.shader"
    local input = maxbin.readFile(inPath, "shader", exporter.version)
    local groupName, root = exporter.read(input, defs)
    local rootStruct = defs:rootStruct(defs:group(groupName))
    local fields = tagFields.flatten(defs, rootStruct, root, "", {})
    local output = maxbin.open(outPath, "shaderFields", 1)
    output:string(groupName)
    output:int(#fields)
    for _, field in ipairs(fields) do
        output:string(field[1])
        output:string(field[2])
    end
    output:close()
end

return shader
