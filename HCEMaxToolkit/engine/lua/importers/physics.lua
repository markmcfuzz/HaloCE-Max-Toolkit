-- physics -> 3ds Max: mass points with their raw values (the builder does the math).
-- Read in Max by builders\tag\physics\lua_reader.ms.
local physics = {group = "physics", version = 1}

function physics.write(root, output)
    output:floats({root["mass"], root["density"]})

    local poweredPoints = root["powered mass points"]
    output:int(#poweredPoints)
    for _, poweredPoint in ipairs(poweredPoints) do
        output:string(poweredPoint["name"])
    end

    local points = root["mass points"]
    output:int(#points)
    for _, point in ipairs(points) do
        output:string(point["name"])
        output:ints({
            point["powered mass point"],
            point["model node"],
            point["flags"],
            point["friction type"]
        })
        output:floats({
            point["relative mass"],
            point["relative density"],
            point["density"],
            point["radius"],
            point["friction parallel scale"],
            point["friction perpendicular scale"]
        })
        output:floats(point["position"])
        output:floats(point["forward"])
        output:floats(point["up"])
    end
end

return physics
