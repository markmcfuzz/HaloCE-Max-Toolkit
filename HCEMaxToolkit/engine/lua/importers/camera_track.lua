-- camera_track -> 3ds Max: control points (raw position and orientation, scaled in Max).
-- Read in Max by builders\tag\camera_track\lua_reader.ms.

local cameraTrack = { group = "camera_track", version = 1 }

function cameraTrack.write(root, w)
	local points = root["control points"]
	w:int(#points)
	for _, point in ipairs(points) do
		w:floats(point["position"])
		w:floats(point["orientation"])
	end
end

return cameraTrack
