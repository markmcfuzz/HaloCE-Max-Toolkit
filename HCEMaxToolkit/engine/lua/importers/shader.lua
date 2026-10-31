-- Any shader tag -> 3ds Max: the parent 'shader' fields and the shader type's own fields,
-- as parser-style tuples (shared\tuples.lua). Read in Max by builders\tag\shared\shader_resolver.ms.

local tuples = require("importers.shared.tuples")

local shader = {
	group = {
		"shader_model", "shader_model_extended", "shader_environment",
		"shader_transparent_chicago", "shader_transparent_chicago_extended", "shader_transparent_generic",
		"shader_transparent_glass", "shader_transparent_meter", "shader_transparent_plasma",
		"shader_transparent_water",
	},
	version = 1,
}

function shader.write(root, w, options, tag)
	-- Field 1 of every shader type is the inherited 'shader' struct
	local c = tag.rootStruct
	tuples.write(w, c.fields[1].sub, root["shader"])
	tuples.write(w, c, root, 2)
end

return shader
