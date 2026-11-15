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

-- Imports a character from its actor_variant tag: the unit (biped) with the object importer,
-- its weapon in the hand and the variant's change colors on the unit's materials.

-- The object importer is loaded without running it
global importerNoAutoRun
global actorVariantImporterAutoRun = importerNoAutoRun != true
importerNoAutoRun = true
include "import_object.ms"
importerNoAutoRun = not actorVariantImporterAutoRun

scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

logger.log "=== IMPORTING ACTOR VARIANT TAG ==="

include "builders\\tag\\actor_variant\\lua_reader.ms"
include "builders\\tag\\actor_variant\\attach_weapon.ms"
include "builders\\tag\\actor_variant\\weapon_ik.ms"

-------------------------------------------------------
-- MAIN IMPORT FUNCTIONS
-------------------------------------------------------

-- Imports the object tag of a reference (relPath "" = none); undefined when it can't
fn importActorVariantObject tagsRoot relPath =
(
	if relPath == "" then return undefined
	local fullPath = tagsRoot + relPath
	if not (doesFileExist fullPath) then
	(
		logger.warn "Tag not found: '{}'" args:#(fullPath)
		return undefined
	)
	logger.log "--- Importing '{}' ---" args:#(relPath)
	importObjectFile fullPath
)

-- Imports one file without dialogs. Returns the unit's Point, or undefined on failure.
fn importActorVariantFile tagPath =
(
	local tagsRoot = getTagsRootFromTagPath tagPath
	if tagsRoot == undefined then
	(
		logger.error "The actor variant is not inside a tags folder: '{}'" args:#(tagPath)
		return undefined
	)
	local data = readActorVariantWithLua tagPath tagsRoot
	if data == undefined then return undefined
	logger.info "Unit: '{}'" args:#(data.unitRef)
	logger.info "Weapon: '{}' (label '{}')" args:#(data.weaponRef, data.weaponLabel)
	logger.info "Actor: '{}'" args:#(data.actorRef)

	local unitPoint = importActorVariantObject tagsRoot data.unitRef
	if unitPoint == undefined then
	(
		logger.error "Could not import the unit of the actor variant"
		return undefined
	)

	local weaponPoint = importActorVariantObject tagsRoot data.weaponRef
	with undo off
	(
		if weaponPoint != undefined do
		(
			-- Half the unit's Point, so each one can be picked in the viewport
			weaponPoint.size = unitPoint.size / 2
			-- For the weapon IK (weapon_ik.ms)
			setUserProp unitPoint "hceVariantWeapon" weaponPoint.inode.handle
			if not data.weaponAnimated do
				logger.warn "Stance '{}' has no animations for weapon '{}'" args:#(data.seatLabel, data.weaponLabel)
			local handNode = attachWeaponToUnit unitPoint weaponPoint data.handMarker data.gripMarker
			if handNode == undefined then logger.warn "The unit has no nodes: weapon left at the origin"
			else logger.info "Weapon on '{}' (hand marker '{}', grip marker '{}')" args:#(handNode.name, data.handMarker, data.gripMarker)
		)

		-- The variant's colors replace the unit's (change_colors.ms reads them from here)
		if data.colors.count > 0 do
		(
			local colorsText = ""
			for i = 1 to data.colors.count do colorsText += (if i > 1 then ";" else "") + data.colors[i]
			setUserProp unitPoint "hceVariantColors" colorsText
			logger.info "Variant change colors on {} materials" args:#(applyObjectChangeColors unitPoint)
		)
	)

	completeRedraw()
	unitPoint
)

fn ImportActorVariant =
(
	local tagPath = getOpenFileName \
		caption:"Select Halo CE Actor Variant Tag" \
		types:"Actor Variant (*.actor_variant)|*.actor_variant|All Files (*.*)|*.*" \
		historyCategory:"HaloCEActorVariant"

	if tagPath == undefined then
	(
		logger.warn "Import cancelled by user.\n"
		return undefined
	)

	if getTagClass tagPath != "actv" then
	(
		messageBox "Unsupported tag type!\n\nSelect an actor_variant tag." title:"Import Failed"
		return undefined
	)

	local startTime = timestamp()
	local unitPoint = importActorVariantFile tagPath
	local elapsedTime = (timestamp() - startTime) / 1000.

	if unitPoint == undefined then
	(
		messageBox "Failed to import the actor variant! See the log for details." title:"Import Failed"
		return undefined
	)

	logger.log "=== IMPORT SUMMARY ==="
	logger.info "Total time: {} seconds" args:#(elapsedTime)
	logger.log "Actor variant import complete\n\n"

	-- Selecting it opens the tag editor (tag_editor.ms)
	select unitPoint
	-- Behaviors tab (core/tag_editor/actor.py). Python opens from here (a macro), never from scene code
	try ((tagEditorModule()).show_actor unitPoint tagPath)
	catch (logger.error "Actor panel failed: {}" args:#(getCurrentException()))
	local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true
	if showDialogs then
	(
		messageBox ("Actor variant imported successfully!\n\n" + \
					"File: " + (filenameFromPath tagPath) + "\n" + \
					"Time: " + (formattedPrint elapsedTime format:".3f") + " seconds") \
					title:"Import Complete" \
					beep:false
	)
	unitPoint
)

-- Tests set importerNoAutoRun = true to load these functions without importing.
if actorVariantImporterAutoRun do ImportActorVariant()
