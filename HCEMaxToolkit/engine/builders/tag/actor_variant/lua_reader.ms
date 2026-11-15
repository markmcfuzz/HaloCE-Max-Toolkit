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

-- Reads an actor_variant tag through lua\importers\actor_variant.lua.

-- Refs are tags-relative paths with extension ("" = none). weaponAnimated: the unit's "stand"
-- seat has animations for the weapon. colors: lower bounds as "r,g,b" (0-1), at most four
struct ActorVariantTagData (unitRef, weaponRef, actorRef, weaponLabel, seatLabel, handMarker, gripMarker, weaponAnimated, colors)

-- tagsRoot: tags folder ending in "\". Returns an ActorVariantTagData, or undefined on error
fn readActorVariantWithLua tagPath tagsRoot =
(
	-- Without the last "\": it would escape the closing quote of the argument
	local tagsFolder = trimRight tagsRoot "\\/"
	local f = luaExportTag "actor_variant" 1 tagPath options:#(tagsFolder)
	if f == undefined then return undefined

	local data = ActorVariantTagData()
	data.unitRef = readString f
	data.weaponRef = readString f
	data.actorRef = readString f
	data.weaponLabel = readString f
	data.seatLabel = readString f
	data.handMarker = readString f
	data.gripMarker = readString f
	data.weaponAnimated = (luaReadInt f) == 1
	data.colors = #()
	for i = 1 to (luaReadInt f) do
	(
		local lower = luaReadPoint3 f
		-- Upper bound: the game picks a random color between both, we show the lower
		luaReadPoint3 f
		append data.colors ((lower.x as string) + "," + (lower.y as string) + "," + (lower.z as string))
	)
	luaCloseExport f "actor_variant"
	data
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
