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

-- Layers where the importers put what each reference brings ("animation": nothing imported yet)
fn tagRefLayers part = case part of
(
	"model": #("Geometry Model", "Nodes", "Markers")
	"collision": #("Collision Model", "Pathfinding Spheres")
	"physics": #("Physics")
	default: #()
)

-- False for Points saved before the reference lists (object_tag_ca.ms)
fn hasTagParts obj = try (obj.partsVersion != undefined) catch (false)

-- Nodes of a reference ("model", "collision" or "physics"), imported or linked
fn tagRefNodes obj part =
(
	if not (hasTagParts obj) then return #()
	local list = case part of
	(
		"model": obj.modelNodes
		"collision": obj.collisionNodes
		"physics": obj.physicsNodes
		default: #()
	)
	for n in list where isValidNode n collect n
)

fn setTagRefNodes obj part nodes = case part of
(
	"model": obj.modelNodes = nodes
	"collision": obj.collisionNodes = nodes
	"physics": obj.physicsNodes = nodes
)

-- Older Points get the new definition, and their lists are filled once from the layers
fn upgradeObjectTagContainer obj =
(
	if not (hasTagParts obj) do fileIn (rootEngine + "builders\\tag\\object\\object_tag_ca.ms")
	if not (hasTagParts obj) or obj.partsVersion >= 1 then return ok
	with undo off
	(
		for part in #("model", "collision", "physics") do
		(
			local layers = tagRefLayers part
			local nodes = for n in obj.memberNodes where isValidNode n and findItem layers n.layer.name > 0 collect n
			setTagRefNodes obj part nodes
		)
		obj.partsVersion = 1
	)
)

-- Below upgradeObjectTagContainer: at startup a function not defined yet is read as a local
-- #(handle, name, tag group, tag file, keys, values, imported nodes still in the scene)
fn tagEditorFields obj =
(
	upgradeObjectTagContainer obj
	local keys = for k in obj.fieldKeys collect k
	local values = for v in obj.fieldValues collect v
	local contents = 0
	for n in obj.memberNodes where isValidNode n do contents += 1
	#(obj.inode.handle, obj.name, obj.tagGroup, obj.tagFile, keys, values, contents)
)

-- Select From Scene filters take only the node, so they read these globals
global tagEditorPickPoint
global tagEditorPickNodes = #()
fn tagEditorCanLink n = n != tagEditorPickPoint and findItem tagEditorPickNodes n == 0
fn tagEditorCanUnlink n = findItem tagEditorPickNodes n > 0

-- Adds scene objects picked in Select From Scene to a reference (undoable). Returns how many
fn tagEditorLinkRef obj part =
(
	tagEditorPickPoint = obj
	tagEditorPickNodes = tagRefNodes obj part
	local picked = selectByName title:("Link to " + part) buttonText:"Link" filter:tagEditorCanLink showHidden:true
	if picked == undefined or picked.count == 0 then return 0
	undo "Link Tag Nodes" on
	(
		setTagRefNodes obj part (tagEditorPickNodes + picked)
		local members = for n in obj.memberNodes where isValidNode n collect n
		for n in picked do appendIfUnique members n
		obj.memberNodes = members
	)
	picked.count
)

-- Takes picked objects out of a reference (undoable); they stay in the scene. Returns how many
fn tagEditorUnlinkRef obj part =
(
	tagEditorPickNodes = tagRefNodes obj part
	if tagEditorPickNodes.count == 0 then return 0
	local picked = selectByName title:("Unlink from " + part) buttonText:"Unlink" filter:tagEditorCanUnlink showHidden:true
	if picked == undefined or picked.count == 0 then return 0
	undo "Unlink Tag Nodes" on
	(
		local kept = for n in tagEditorPickNodes where findItem picked n == 0 collect n
		setTagRefNodes obj part kept
		-- Out of the Point's contents too, unless another reference still has them
		local others = #()
		for p in #("model", "collision", "physics") where p != part do join others (tagRefNodes obj p)
		obj.memberNodes = for n in obj.memberNodes where isValidNode n and (findItem picked n == 0 or findItem others n > 0) collect n
	)
	picked.count
)

fn tagEditorSelectRef obj part =
(
	local nodes = tagRefNodes obj part
	if nodes.count > 0 do select nodes
	nodes.count
)

-- Eye button state: 0 = no nodes, 1 = all hidden, 2 = some visible
fn tagEditorRefVisibility obj part =
(
	local nodes = tagRefNodes obj part
	if nodes.count == 0 then 0 else if (for n in nodes where not n.isHidden collect n).count == 0 then 1 else 2
)

fn tagEditorShowRef obj part visible =
(
	local nodes = tagRefNodes obj part
	undo "Show/Hide Tag Nodes" on
		for n in nodes do n.isHidden = not visible
	redrawViews()
	nodes.count
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
