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


-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Log file setup
scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

logger.log "=== IMPORTING PHYSICS DATA ==="

-- Load required modules
include "builders\\tag\\physics\\lua_reader.ms"
include "builders\\tag\\physics\\build_scene.ms"

-------------------------------------------------------
-- MAIN IMPORT FUNCTIONS
-------------------------------------------------------

fn isPhysicsTag tagPath = (getTagClass tagPath) == "phys"

-- Imports one file without dialogs. modelNodes: the model's nodes in tag order (undefined = those
-- of the last model imported). Returns the tag's Point, or undefined on failure.
fn importPhysicsFile physicsFile modelNodes:undefined =
(
    if not (isPhysicsTag physicsFile) then
    (
        logger.error "Not a physics tag: '{}'" args:#(physicsFile)
        return undefined
    )

    local readStartTime = timestamp()
    local physicsData = readPhysicsWithLua physicsFile
    if physicsData == undefined then return undefined
    logger.info "Reading: {} seconds" args:#((timestamp() - readStartTime) / 1000.)
    logger.info "Fields: {}" args:#(physicsData.keys.count)

    logger.log "=== BUILDING MASS POINT SPHERES ==="
    local buildStartTime = timestamp()
    -- Undo off: a long undo history makes every bone key slower later (Ctrl+Z won't remove the import)
    local container = with undo off (createPhysicsContainer physicsData physicsFile modelNodes:modelNodes)
    logger.info "Mass points: {}" args:#(container.physicsNodes.count)
    logger.info "Scene building: {} seconds" args:#((timestamp() - buildStartTime) / 1000.)

    completeRedraw()
    container
)

fn ImportPhysics =
(
    -- Open file dialog
    local physicsFile = getOpenFileName \
        caption:"Select Physics Tag File" \
        types:"Physics Tag (*.physics)|*.physics|All Files (*.*)|*.*" \
        historyCategory:"PhysicsImport"

    if physicsFile == undefined then
    (
        logger.warn "Import cancelled by user.\n"
        return undefined
    )

    if not (isPhysicsTag physicsFile) then
    (
        messageBox "Unsupported tag type!" title:"Import Failed"
        return undefined
    )

    local startTime = timestamp()
    local container = importPhysicsFile physicsFile
    local elapsedTime = (timestamp() - startTime) / 1000.

    if container == undefined then
    (
        messageBox "Failed to read physics tag!" title:"Import Failed"
        return undefined
    )

    logger.log "=== IMPORT SUMMARY ==="
    logger.info "Total time: {} seconds" args:#(elapsedTime)
    logger.log "Physics import complete\n\n"

    -- Selecting it opens the tag editor (tag_editor.ms)
    select container
    local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true

    if showDialogs then
    (
        local fileName = filenameFromPath physicsFile
        messageBox ("Physics mass points imported successfully!\n\n" + \
                    "File: " + fileName + "\n" + \
                    "Mass points: " + container.physicsNodes.count as string + "\n" + \
                    "Time: " + (formattedPrint elapsedTime format:".3f") + " seconds") \
                    title:"Import Complete" \
                    beep:false
    )
    clearListener()
    return container
)

-- Tests set importerNoAutoRun = true to load these functions without importing.
global importerNoAutoRun
if importerNoAutoRun != true do ImportPhysics()
