-- 3ds Max -> camera_track: control points written by pipeline\create_tag\create_camera_track.ms
-- (count, then position x y z and orientation i j k w per point, already in tag units).
local tagFields = require "importers.shared.tag_fields"

local cameraTrack = {version = 1}

local function readFloats(input, count)
    local values = {}
    for i = 1, count do
        values[i] = input:float()
    end
    return values
end

function cameraTrack.read(input, defs)
    -- A blank tag (all fields zero), then the control points
    local root = tagFields.unflatten(defs, defs:rootStruct(defs:group("camera_track")), {}, "")
    local points = {}
    for i = 1, input:int() do
        local position = readFloats(input, 3)
        points[i] = {position = position, orientation = readFloats(input, 4)}
    end
    root["control points"] = points
    return "camera_track", root
end

return cameraTrack
