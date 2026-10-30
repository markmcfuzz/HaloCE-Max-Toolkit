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

logger.log "=== IMPORTING CAMERA TRACK ==="

-- Load required modules
include "builders\\tag\\camera_track\\lua_reader.ms"
include "builders\\tag\\camera_track\\build_scene.ms"

-------------------------------------------------------
-- MAIN IMPORT FUNCTIONS
-------------------------------------------------------

fn isCameraTrackTag tagPath = (getTagClass tagPath) == "trak"

-- Imports one file without dialogs. Returns the created control points, or undefined on failure.
fn importCameraTrackFile trakFile =
(
    if not (isCameraTrackTag trakFile) then
    (
        logger.error "Not a camera_track tag: '{}'" args:#(trakFile)
        return undefined
    )

    local readStartTime = timestamp()
    local controlPoints = readCameraTrackWithLua trakFile
    if controlPoints == undefined then return undefined
    logger.info "Camera Track read: {} seconds" args:#((timestamp() - readStartTime) / 1000.)
    logger.info "Control points in tag: {}\n" args:#(controlPoints.count)

    -- Build control points in the scene
    logger.log "=== BUILDING CONTROL POINTS ==="

    local buildStartTime = timestamp()
    local createdPoints = buildControlPoints controlPoints
    logger.info "Control points built: {} seconds" args:#((timestamp() - buildStartTime) / 1000.)

    local importCameraAnimation = configManager.getBool "import_camera_track" "import_camera_animation" true

    if importCameraAnimation then
    (
        local cameraSetup = createCameraSetup createdPoints
        local cam = cameraSetup[1]
        local dummyObj = cameraSetup[2]

        if createdPoints.count > 0 then
        (
            animateCameraPath dummyObj createdPoints
            logger.info "Camera Track import completed successfully.\n"
            select createdPoints
        )
        else
        (
            logger.warn "No control points were created.\n"
        )
    )
    else
    (
        logger.info "Camera animation skipped (import_camera_animation=0).\n"
        if createdPoints.count > 0 then
            select createdPoints
        else
            logger.warn "No control points were created.\n"
    )

    CompleteRedraw()
    createdPoints
)

fn importCameraTrack =
(
    -- Open file dialog
    local trakFile = getOpenFileName \
            caption:"Select Camera Track Tag File" \
            types:"Tag Files (*.camera_track)|*.camera_track|All Files (*.*)|*.*"

    if trakFile == undefined then
    (
        logger.warn "Import cancelled by user.\n"
        return undefined
    )

    if not (isCameraTrackTag trakFile) then
    (
        messageBox "Unsupported tag type!" title:"Import Failed"
        return undefined
    )

    -- Start timing AFTER file selection
    local startTime = timestamp()
    local createdPoints = importCameraTrackFile trakFile
    local elapsedTime = (timestamp() - startTime) / 1000.

    if createdPoints == undefined then
    (
        messageBox "Failed to read Camera Track tag data!" title:"Import Failed"
        return undefined
    )

    logger.log "=== IMPORT SUMMARY ==="
    logger.info "Total time: {} seconds" args:#(elapsedTime)
    logger.log "Camera Track import completed successfully.\n\n"

    local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true

    if showDialogs and createdPoints.count > 0 then
    (
        local fileName = filenameFromPath trakFile
        messageBox ("Camera Track imported successfully!\n\n" + \
                    "File: " + fileName + "\n" + \
                    "Control Points Created: " + createdPoints.count as string + "\n" + \
                    "Total Time: " + (formattedPrint elapsedTime format:".3f") + " seconds") \
                    title:"Import Successful" \
                    beep:false
    )

    clearListener()
    return createdPoints
)

-- Tests set importerNoAutoRun = true to load these functions without importing.
global importerNoAutoRun
if importerNoAutoRun != true do importCameraTrack()
