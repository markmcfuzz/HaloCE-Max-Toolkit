-- physics -> 3ds Max: mass points with their raw values (the builder does the math).
-- Read in Max by builders\tag\physics\lua_reader.ms.

local physics = { group = "physics", version = 1 }

function physics.write(root, w)
	w:floats({ root["mass"], root["density"] })

	local powered = root["powered mass points"]
	w:int(#powered)
	for _, pmp in ipairs(powered) do
		w:string(pmp["name"])
	end

	local points = root["mass points"]
	w:int(#points)
	for _, mp in ipairs(points) do
		w:string(mp["name"])
		w:ints({ mp["powered mass point"], mp["model node"], mp["flags"], mp["friction type"] })
		w:floats({ mp["relative mass"], mp["relative density"], mp["density"], mp["radius"],
			mp["friction parallel scale"], mp["friction perpendicular scale"] })
		w:floats(mp["position"])
		w:floats(mp["forward"])
		w:floats(mp["up"])
	end
end

return physics
