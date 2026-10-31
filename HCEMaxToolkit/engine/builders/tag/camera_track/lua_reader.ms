------------------------------------------------------------------------------
--	Copyright (C) 2025 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------

-- Reads a camera_track through lua\importers\camera_track.lua (same read order).

-- lua_bridge.ms is loaded by init.ms; reload it if Max still runs an older toolkit.
global luaExportTag
if luaExportTag == undefined and rootEngine != undefined do
	fileIn (rootEngine + "shared\\utils\\lua_bridge.ms")

-- position: Point3 in Halo units; orientation: quat as stored in the tag
struct CameraControlPoint (position, orientation)

-- Returns an array of CameraControlPoint, or undefined on error (details in the log)
fn readCameraTrackWithLua tagPath =
(
	local f = luaExportTag "lua\\importers\\camera_track.lua" 1 tagPath
	if f == undefined then return undefined

	local points = for i = 1 to (luaReadInt f) collect
	(
		local position = luaReadPoint3 f
		local orientation = luaReadQuat f
		CameraControlPoint position:position orientation:orientation
	)
	luaCloseExport f "camera_track"
	points
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
