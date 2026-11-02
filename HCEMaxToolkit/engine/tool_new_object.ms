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

-- Creates an object tag from scratch: a Point (e.g. "new_vehicle.vehicle") with every field of
-- the chosen tag type empty. Selecting it opens the tag editor; its "Export Tag..." button writes it.

scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

include "builders\\tag\\object\\lua_reader.ms"
include "builders\\tag\\object\\build_scene.ms"

(
	global NewObjectTagRollout
	try (destroyDialog NewObjectTagRollout) catch()

	rollout NewObjectTagRollout "Create Object Tag"
	(
		local groups = #("biped", "vehicle", "weapon", "scenery", "device_machine")

		dropdownList typeList "Tag type" items:#("Biped", "Vehicle", "Weapon", "Scenery", "Device Machine") \
			selection:2
		edittext nameBox "Name" text:"new_vehicle" labelOnTop:true
		button createButton "Create" width:120

		on typeList selected i do nameBox.text = "new_" + groups[i]

		on createButton pressed do
		(
			local group = groups[typeList.selection]
			local name = trimLeft (trimRight nameBox.text)
			if name == "" do name = "new_" + group
			local data = newObjectWithLua group
			if data == undefined then
				messageBox "Could not create the tag! See the log for details." title:"Create Object Tag"
			else
			(
				local container
				undo "Create Object Tag" on
				(
					container = createObjectContainer data (name + "." + group) #()
					container.tagFile = ""  -- not exported yet
				)
				logger.info "New {} tag: '{}' ({} fields)" args:#(group, container.name, data.keys.count)
				-- Selecting it opens the tag editor
				select container
				destroyDialog NewObjectTagRollout
			)
		)
	)

	createDialog NewObjectTagRollout 200 120
)
