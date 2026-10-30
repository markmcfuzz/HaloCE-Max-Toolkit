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

logger.log "=== IMPORTING MODEL COLLISION GEOMETRY ==="

-- Load required modules
include "builders\\tag\\shared\\collision_bsp_reader.ms"
include "builders\\tag\\model_collision_geometry\\lua_reader.ms"
include "builders\\tag\\model_collision_geometry\\build_scene.ms"

-------------------------------------------------------
-- MAIN IMPORT FUNCTIONS
-------------------------------------------------------

fn isCollisionTag tagPath = (getTagClass tagPath) == "coll"

-- Imports one file without dialogs. Returns the created meshes, or undefined on failure.
fn importCollisionFile collisionFile =
(
    if not (isCollisionTag collisionFile) then
    (
        logger.error "Not a model_collision_geometry tag: '{}'" args:#(collisionFile)
        return undefined
    )

    local tagsPos = findString collisionFile "tags\\"
    local displayPath = if tagsPos != undefined then (substring collisionFile tagsPos -1) else (filenameFromPath collisionFile)
    logger.log "Opening tag file: '{}'" args:#(displayPath)

    local readStartTime = timestamp()
    local collisionData = readCollisionWithLua collisionFile
    if collisionData == undefined then return undefined
    logger.info "Reading: {} seconds" args:#((timestamp() - readStartTime) / 1000.)
    logger.log "Collision geometry reading complete\n"

    logger.log "=== BUILDING COLLISION MESH ==="
    local buildStartTime = timestamp()
    local createdMeshes = buildCollisionMesh collisionData (getFilenameFile collisionFile)
    logger.info "Scene building: {} seconds" args:#((timestamp() - buildStartTime) / 1000.)
    logger.log "Collision geometry build complete\n"

    completeRedraw()
    -- buildCollisionMesh returns undefined when the fallback root can't be created
    if createdMeshes == undefined then #() else createdMeshes
)

fn ImportCollision =
(
    -- Open file dialog
    local collisionFile = getOpenFileName \
		caption:"Select Halo CE Collision Geometry Tag" \
		types:"Collision Geometry (*.model_collision_geometry)|*.model_collision_geometry|All Files (*.*)|*.*" \
		historyCategory:"HaloCECollision"

    if collisionFile == undefined then
    (
        logger.warn "Import cancelled by user.\n"
        return undefined
    )

    if not (isCollisionTag collisionFile) then
    (
        messageBox "Unsupported tag type!" title:"Import Failed"
        return undefined
    )

    local startTime = timestamp()
    local createdMeshes = importCollisionFile collisionFile
    local elapsedTime = (timestamp() - startTime) / 1000.

    if createdMeshes == undefined then
    (
        messageBox "Failed to read collision tag!" title:"Import Failed"
        return undefined
    )

    logger.log "=== IMPORT SUMMARY ==="
    logger.info "Total time: {} seconds" args:#(elapsedTime)
    logger.log "Collision geometry import complete\n\n"

    local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true

    if showDialogs and createdMeshes.count > 0 then
    (
        local fileName = filenameFromPath collisionFile
        messageBox ("Collision geometry imported successfully!\n\n" + \
                    "File: " + fileName + "\n" + \
                    "Meshes created: " + createdMeshes.count as string + "\n" + \
                    "Time: " + (formattedPrint elapsedTime format:".3f") + " seconds") \
                    title:"Import Complete" \
                    beep:false
    )

    clearListener()
    return createdMeshes
)

-- Tests set importerNoAutoRun = true to load these functions without importing.
global importerNoAutoRun
if importerNoAutoRun != true do ImportCollision()
