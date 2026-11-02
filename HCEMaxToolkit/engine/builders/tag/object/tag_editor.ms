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

-- Opens the Qt tag editor (engine\core\tag_editor) when an object tag Point is selected and gives
-- it the Point's fields. The tagEditor* functions are called from Python.

-- True for a Point made by import_object.ms (it has the tag fields)
fn isObjectTagContainer obj = isValidNode obj and (try (obj.fieldKeys != undefined) catch (false))

-- The selected object tag Point, or undefined
fn tagEditorSelected =
(
	if selection.count != 1 then return undefined
	local obj = selection[1]
	if isObjectTagContainer obj then obj else undefined
)

-- #(handle, name, tag group, tag file, keys, values, imported nodes still in the scene)
fn tagEditorFields obj =
(
	local keys = for k in obj.fieldKeys collect k
	local values = for v in obj.fieldValues collect v
	local contents = 0
	for n in obj.memberNodes where isValidNode n do contents += 1
	#(obj.inode.handle, obj.name, obj.tagGroup, obj.tagFile, keys, values, contents)
)

-- Stores one field (undoable). Returns false when the key is not there
fn tagEditorSetField obj key text =
(
	local i = findItem (for k in obj.fieldKeys collect k) key
	if i == 0 then return false
	undo "Edit Tag Field" on obj.fieldValues[i] = text
	true
)

-- Replaces every field (block elements added, duplicated or deleted), as one undo step
fn tagEditorSetFields obj keys values =
(
	undo "Edit Tag Block" on
	(
		obj.fieldKeys = for k in keys collect (k as string)
		obj.fieldValues = for v in values collect (v as string)
	)
	true
)

fn tagEditorSelectContents obj =
(
	if isObjectTagContainer obj do select (for n in obj.memberNodes where isValidNode n collect n)
)

-- Python never starts from the Point's own panel: Max blocks it there ("Safe Scene Script
-- Execution"), so the editor opens from the selection callback below
global tagEditorPythonReady

fn tagEditorModule =
(
	if tagEditorPythonReady != true do
	(
		local sysPath = (python.import "sys").path
		local corePath = rootEngine + "core"
		try (sysPath.remove corePath) catch ()
		sysPath.insert 0 corePath
	)
	local m = python.import "tag_editor"
	tagEditorPythonReady = true
	m
)

-- Opens the editor when an object tag Point is selected and keeps it showing the selection
fn tagEditorSelectionChanged =
(
	-- Python only loads once a tag Point is selected
	if tagEditorPythonReady != true and tagEditorSelected() == undefined then return ok
	try ((tagEditorModule()).follow_selection())
	catch (logger.error "Tag editor failed: {}" args:#(getCurrentException()))
)

-- The editor's "Export Tag..." button (tagEditorExport)
fileIn (rootEngine + "builders\\tag\\object\\export_tag.ms")
-- Change colors shown on the model's materials (applyObjectChangeColors)
fileIn (rootEngine + "builders\\tag\\object\\change_colors.ms")
-- Bounding radius helper (createBoundingRadiusHelper, applyObjectBoundingRadius)
fileIn (rootEngine + "builders\\tag\\object\\bounding_radius.ms")

-- Loaded at startup (shared\init.ms), so this works in every scene
callbacks.removeScripts id:#hceTagEditor
for e in #(#selectionSetChanged, #sceneUndo, #sceneRedo, #filePostOpen, #systemPostReset, #systemPostNew) do
	callbacks.addScript e "tagEditorSelectionChanged()" id:#hceTagEditor

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
