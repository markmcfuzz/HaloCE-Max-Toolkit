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

-- Lists a model_animations tag in the Model Animations tab (core\tag_editor\player.py); the
-- picked animation goes as keys on the scene bones with the same names (animation_player.ms)

clearListener()
gc light:true

scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

logger.log "=== IMPORTING MODEL ANIMATIONS ==="

-------------------------------------------------------
-- MAIN IMPORT FUNCTION
-------------------------------------------------------

fn importModelAnimationsFile tagPath:undefined =
(
	if tagPath == undefined do
		tagPath = getOpenFileName caption:"Select model_animations tag" \
			types:"Model Animations (*.model_animations)|*.model_animations|All Files (*.*)|*.*" \
			historyCategory:"HaloCEModelAnimations"
	if tagPath == undefined then
	(
		logger.info "Import cancelled by user.\n"
		return undefined
	)

	local tagClass = getTagClass tagPath
	if tagClass != "antr" then
	(
		logger.error "Unknown or unsupported tag class: '{}'" args:#(tagClass)
		messageBox "Unsupported tag type!\n\nSelect a model_animations tag." title:"Import Failed"
		return undefined
	)
	logger.info "Tag: '{}'" args:#(tagPath)

	-- Python opens from here (a macro), never from scene code: Max blocks it there
	try ((tagEditorModule()).show_model_animations tagPath)
	catch
	(
		logger.error "Model Animations panel failed: {}" args:#(getCurrentException())
		messageBox "Could not open the Model Animations panel.\n\nSee the MaxScript Listener for details." title:"Import Failed"
		return undefined
	)
	tagPath
)

-- Tests set importerNoAutoRun = true to load these functions without importing.
global importerNoAutoRun
if importerNoAutoRun != true do importModelAnimationsFile()
