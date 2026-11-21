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

-- Reads a physics tag through lua\importers\physics.lua (same read order).

-- Every field as text: "mass points[0].radius" = "0.3"
struct PhysicsTagData (keys, values)

-- Reads what physics.write wrote and closes the file
fn readPhysicsData f =
(
	local keys = #()
	local values = #()
	for i = 1 to (luaReadInt f) do
	(
		append keys (readString f)
		append values (readString f)
	)
	luaCloseExport f "physics"

	PhysicsTagData keys:keys values:values
)

-- Returns a PhysicsTagData, or undefined on error (details in the log)
fn readPhysicsWithLua tagPath =
(
	local f = luaExportTag "physics" 2 tagPath
	if f == undefined then return undefined
	readPhysicsData f
)

-- A new tag from a template of lua\generators\templates ("ball", "jeep"...). boxMin / boxMax: what it must fill, in world
-- units (equal = the template's size); option: one of its options, or "". wheels: the scene's
-- wheels to put the mass points on ("x y z radius node;..."), or "". rootNode: model node of the
-- other mass points (the model's root), or -1. exact: a stock template stays as the original tag;
-- nodeNames: the scene's model nodes ("a;b;..."), to link a stock template by name. Undefined on error
fn newPhysicsWithLua template boxMin boxMax option wheels:"" rootNode:-1 exact:false nodeNames:"" =
(
	local outPath = luaExportPath "physics"
	deleteFile outPath
	local exactText = if exact then "1" else ""
	local args = #(template, boxMin.x, boxMin.y, boxMin.z, boxMax.x, boxMax.y, boxMax.z, option, outPath, wheels, \
		rootNode, exactText, nodeNames)
	if not (luaRun "generators.physics" "preset" args) then return undefined
	local f = luaOpenOutput outPath "physics" 2
	if f == undefined then return undefined
	readPhysicsData f
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
