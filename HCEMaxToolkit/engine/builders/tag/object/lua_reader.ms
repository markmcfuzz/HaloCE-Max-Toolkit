------------------------------------------------------------------------------
--	Copyright (C) 2026 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------

-- Reads an object tag (biped, vehicle, weapon, scenery, device_machine) through lua\importers\object.lua.

-- Refs are tags-relative paths with extension ("" = none). keys/values: every field as text
struct ObjectTagData (group, modelRef, collisionRef, physicsRef, keys, values)

-- Also writes the panel script to uiScriptPath. Returns an ObjectTagData, or undefined on error
fn readObjectWithLua tagPath uiScriptPath =
(
	local f = luaExportTag "object" 1 tagPath options:#(uiScriptPath)
	if f == undefined then return undefined

	local group = readString f
	local modelRef = readString f
	local collisionRef = readString f
	local physicsRef = readString f
	local keys = #()
	local values = #()
	for i = 1 to (luaReadInt f) do
	(
		append keys (readString f)
		append values (readString f)
	)
	luaCloseExport f "object"

	ObjectTagData group:group modelRef:modelRef collisionRef:collisionRef physicsRef:physicsRef \
		keys:keys values:values
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
