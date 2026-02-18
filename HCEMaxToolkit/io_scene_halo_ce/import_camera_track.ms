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

-- Get script directory
scriptDir = getFilenamePath (getThisScriptFilename())

-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Load required modules
filein (scriptDir + "modules\\global_functions\\config.ms")
filein (scriptDir + "modules\\global_functions\\utils.ms")
filein (scriptDir + "modules\\file_tag\\camera_track\\tag_struct.ms")
filein (scriptDir + "modules\\file_tag\\camera_track\\tag_reader.ms")
filein (scriptDir + "modules\\file_tag\\camera_track\\build_scene.ms")

fn importCameraTrackTag trakFile:undefined =
(
    if trakFile == undefined then
    (
        trakFile = getOpenFileName \
            caption:"Select Camera Track Tag File" \
            types:"Tag Files (*.camera_track)|*.camera_track|All Files (*.*)|*.*"
        
        if trakFile == undefined then
        (
            logger "Import cancelled by user.\n"
            return undefined
        )
    )
    
    logger "\n=== IMPORTING CAMERA TRACK TAG ===\n"
    logger "File: (%)\n" params:#(filenameFromPath trakFile)

    local tagData = readCameraTrackTag trakFile
    
    if tagData == undefined then
    (
        logger "Failed to read Camera Track tag data.\n" logType:#error
        messageBox "Failed to read Camera Track tag data!\n\nThe file may be corrupted, not a valid Camera Track tag, or an unsupported version." title:"Import Failed"
        return undefined
    )
    
    logger "Camera Track tag read successfully.\n" logType:#success
    
    -- Build control points in the scene
    local createdPoints = buildControlPoints tagData
    local pointsName = getFilenameFile trakFile
    
    -- Create camera setup (returns #(camera, dummy))
    local cameraSetup = createCameraSetup createdPoints
    local cam = cameraSetup[1]
    local dummyObj = cameraSetup[2]
    
    -- Animate the camera path
    if createdPoints.count > 0 then
    (
        animateCameraPath dummyObj createdPoints
        logger "Camera Track import completed successfully.\n" logType:#success
        select createdPoints
    )
    else
    (
        logger "No control points were created.\n" logType:#warning
    )
    completeRedraw()

    -- Show success message box
    if createdPoints != undefined and createdPoints.count > 0 then
    (
        local fileName = getFilenameFile trakFile
        messageBox ("Camera Track imported successfully!\n\n" + "File: " + fileName + "\nControl Points Created: " + (createdPoints.count as string)) \
                title:"Import Successful" \
                beep:false
    )

    clearListener()
    return tagData
)

importCameraTrackTag()