-- Writes a tag element as the field tuples of the previous MAXScript parser:
-- #(#("camelCaseName", value), ...), blocks as arrays of those. Read in Max by luaReadTuples (lua_bridge.ms).

local tagdefs = require("core.halo1.tagdefs")
local K = tagdefs.K

local tuples = {}

-- Value codes shared with luaReadTuples
local V = { INT = 1, FLOAT = 2, COLOR = 3, ARGB = 4, POINT2 = 5, POINT3 = 6, TAGREF = 7, BLOCK = 8, STRING = 9 }
tuples.V = V

local INT_KINDS = { [K.I8] = true, [K.U8] = true, [K.I16] = true, [K.U16] = true, [K.I32] = true, [K.U32] = true }

-- "map u-scale" -> "mapUScale", "rotation-animation center" -> "rotationAnimationCenter"
function tuples.camel_case(name)
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

local function value_code(fd)
	local k = fd.kind
	if INT_KINDS[k] then return V.INT
	elseif k == K.F32 then return V.FLOAT
	elseif k == K.F32x2 then return V.POINT2
	elseif k == K.F32x3 then return fd.type == "real_rgb_color" and V.COLOR or V.POINT3
	elseif k == K.F32x4 and fd.type == "real_argb_color" then return V.ARGB
	elseif k == K.TAGREF then return V.TAGREF
	elseif k == K.BLOCK then return V.BLOCK
	elseif k == K.STRING then return V.STRING
	end
	error(("field '%s' (%s) has no tuple form yet"):format(fd.key, fd.type), 0)
end

-- c: compiled struct of e; fields before first_field are left out (default 1)
function tuples.write(w, c, e, first_field)
	local fields = c.fields
	first_field = first_field or 1
	w:int(#fields - first_field + 1)
	for i = first_field, #fields do
		local fd = fields[i]
		local v = e[fd.key]
		local code = value_code(fd)
		w:string(tuples.camel_case(fd.name))
		w:int(code)
		if code == V.INT then w:int(v)
		elseif code == V.FLOAT then w:float(v)
		elseif code == V.POINT2 or code == V.POINT3 or code == V.COLOR then w:floats(v)
		elseif code == V.ARGB then w:floats({ v[2], v[3], v[4], v[1] }) -- stored a,r,g,b; Max gets point4 r g b a
		elseif code == V.TAGREF then w:tagref(v)
		elseif code == V.STRING then w:string(v)
		elseif code == V.BLOCK then
			w:int(#v)
			-- Elements were read with this compiled struct (empty blocks have none)
			for _, child in ipairs(v) do tuples.write(w, fd.sub.compiled, child) end
		end
	end
end

return tuples
