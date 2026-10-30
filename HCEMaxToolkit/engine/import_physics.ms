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

-- Imports one file without dialogs. Returns the created spheres, or undefined on failure.
fn importPhysicsFile physicsFile =
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
    logger.info "Mass points: {}" args:#(physicsData.massPoints.count)
    logger.info "Powered mass points: {}" args:#(physicsData.poweredMassPointNames.count)

    logger.log "=== BUILDING MASS POINT SPHERES ==="
    local buildStartTime = timestamp()
    local createdSpheres = createMassPointSpheres \
        physicsData.massPoints \
        physicsData.poweredMassPointNames \
        physicsData.mass \
        physicsData.density
    logger.info "Scene building: {} seconds" args:#((timestamp() - buildStartTime) / 1000.)

    completeRedraw()
    -- createMassPointSpheres returns undefined when the tag has no mass points
    if createdSpheres == undefined then #() else createdSpheres
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
    local createdSpheres = importPhysicsFile physicsFile
    local elapsedTime = (timestamp() - startTime) / 1000.

    if createdSpheres == undefined then
    (
        messageBox "Failed to read physics tag!" title:"Import Failed"
        return undefined
    )

    logger.log "=== IMPORT SUMMARY ==="
    logger.info "Total time: {} seconds" args:#(elapsedTime)
    logger.log "Physics import complete\n\n"

    local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true

    if showDialogs and createdSpheres.count > 0 then
    (
        local fileName = filenameFromPath physicsFile
        messageBox ("Physics mass points imported successfully!\n\n" + \
                    "File: " + fileName + "\n" + \
                    "Spheres created: " + createdSpheres.count as string + "\n" + \
                    "Time: " + (formattedPrint elapsedTime format:".3f") + " seconds") \
                    title:"Import Complete" \
                    beep:false
    )
    clearListener()
    return createdSpheres
)

-- Tests set importerNoAutoRun = true to load these functions without importing.
global importerNoAutoRun
if importerNoAutoRun != true do ImportPhysics()
