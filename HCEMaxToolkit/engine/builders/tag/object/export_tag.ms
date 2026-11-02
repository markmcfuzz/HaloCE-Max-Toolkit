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

-- Writes an object tag Point back to a tag (lua\exporters\object.lua). Called by the
-- "Export Tag..." button of the tag editor.

-- Returns true when the tag was written (errors are in the log)
fn exportObjectFile container tagPath =
(
	local keys = container.fieldKeys
	local values = container.fieldValues
	local f = luaOpenTagInput "object" 1
	luaWriteString f container.tagGroup
	luaWriteInt f keys.count
	for i = 1 to keys.count do
	(
		luaWriteString f keys[i]
		luaWriteString f values[i]
	)
	luaWriteTag f "object" tagPath
)

-- Always asks where to save (starts at the imported tag), so nothing is overwritten unseen.
-- Returns the written path, or undefined (cancelled or failed)
fn tagEditorExport container =
(
	local group = container.tagGroup
	local typeName = substituteString group "_" " "
	-- The Point's name; it gets the extension when it lacks it ("warthog" -> "warthog.vehicle")
	local fileName = container.name
	if getFilenameType fileName != ("." + group) do fileName += "." + group
	local tagPath = getSaveFileName caption:"Export Halo CE Object Tag" \
		filename:((getFilenamePath container.tagFile) + fileName) \
		types:(typeName + " (*." + group + ")|*." + group + "|All Files (*.*)|*.*") \
		historyCategory:"HaloCEObject"
	if tagPath == undefined then return undefined
	if getFilenameType tagPath != ("." + group) do tagPath += "." + group

	logger.log "=== EXPORTING OBJECT TAG ==="
	local startTime = timestamp()
	local ok = exportObjectFile container tagPath
	local elapsedTime = (timestamp() - startTime) / 1000.
	if not ok then
	(
		messageBox "Failed to write the tag! See the log for details." title:"Export Failed"
		return undefined
	)
	-- The next export starts here
	with undo off container.tagFile = tagPath
	logger.info "Written: '{}' in {} seconds" args:#(tagPath, elapsedTime)

	if configManager.getBool "feedback" "show_completion_dialogs" true do
	(
		messageBox ("Object tag exported successfully!\n\n" + \
					"File: " + (filenameFromPath tagPath) + "\n" + \
					"Time: " + (formattedPrint elapsedTime format:".3f") + " seconds") \
					title:"Export Complete" \
					beep:false
	)
	tagPath
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
