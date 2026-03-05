----------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
----------------------------------------------------------------------------

-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Log file setup
scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

logger.log "=== IMPORTING CAMERA TRACK ==="

-- Load required modules
include "core\\halo1\\core_defs.ms"
include "core\\halo1\\parser.ms"
include "core\\halo1\\groups\\camera_track.ms"
include "builders\\tag\\camera_track\\build_scene.ms"

-------------------------------------------------------
-- READ TAG FUNCTION
-------------------------------------------------------

fn readCameraTrackTag tagPath tagDef =
(
    local fileCameraTrack = fopen tagPath "rb"
    if fileCameraTrack == undefined then
    (
        logger.error "Cannot open file: {}" args:#(tagPath)
        return undefined
    )
    
    logger.log "File opened successfully\n"
    setCurrentFileHandle fileCameraTrack

    if tagDef == undefined then
    (
        logger.error "tagDef is undefined\n"
        fclose fileCameraTrack
        return undefined
    )

    -- Set default base address for Halo CE
    setTagMemoryBaseAddress 0x40440000
    
    -- Skip to tag data (after 64-byte header)
    fseek fileCameraTrack 64 #seek_set
    
    logger.log "=== READING CAMERA TRACK ==="

    local cameraTrackData = readRootTagData tagDef.tagBlock
    fclose fileCameraTrack

    return cameraTrackData
)

-------------------------------------------------------
-- MAIN IMPORT FUNCTION
-------------------------------------------------------

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

    -- Start timing AFTER file selection
    local startTime = timestamp()

    local tagClass = getTagClass trakFile

    logger.info "Detected tag class: '{}'" args:#(tagClass)

    -- Get tag definition
    local tagDef = getTagDefByClass tagClass

    if tagDef == undefined then
    (
        logger.error "Unknown or unsupported tag class: '{}'" args:#(tagClass)
        messageBox "Unsupported tag type!" title:"Import Failed"
        return undefined
    )

    local tagsPos = findString trakFile "tags\\"
    local displayPath = if tagsPos != undefined then (substring trakFile tagsPos -1) else (filenameFromPath trakFile)
    logger.info "Opening tag file: '{}'" args:#(displayPath)

    local readStartTime = timestamp()
    local trakData = readCameraTrackTag trakFile tagDef
    local readEndTime = timestamp()
    local readTime = (readEndTime - readStartTime) / 1000.

    if trakData == undefined then
    (
        messageBox "Failed to read Camera Track tag data!" title:"Import Failed"
        return undefined
    )
    logger.info "Camera Track read: {} seconds" args:#(readTime)

    local controlPointsArray = getFieldValue trakData "controlPoints"
    if controlPointsArray == undefined then controlPointsArray = #()
    logger.info "Control points in tag: {}\n" args:#(controlPointsArray.count)

    -- Build control points in the scene
    logger.log "=== BUILDING CONTROL POINTS ==="

    local buildStartTime = timestamp()
    local createdPoints = buildControlPoints controlPointsArray
    local buildEndTime = timestamp()
    local buildTime = (buildEndTime - buildStartTime) / 1000.

    logger.info "Control points built: {} seconds" args:#(buildTime)

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

    CompleteRedraw()

    local endTime = timestamp()
    local elapsedTime = (endTime - startTime) / 1000.

    logger.log "=== IMPORT SUMMARY ==="
    logger.info "Total time: {} seconds" args:#(elapsedTime)
    logger.log "Camera Track import completed successfully.\n\n" 

    if createdPoints != undefined and createdPoints.count > 0 then
    (
        local fileName = filenameFromPath trakFile
        messageBox ("Camera Track imported successfully!\n\n" + \
                    "File: " + fileName + "\n" + \
                    "Control Points Created: " + createdPoints.count as string + "\n" + \
                    "Total Time: " + (formattedPrint elapsedTime format:".3f") + " seconds") \
                    title:"Import Successful" \
                    beep:false
    )

    --clearListener()
    return createdPoints
)

importCameraTrack()