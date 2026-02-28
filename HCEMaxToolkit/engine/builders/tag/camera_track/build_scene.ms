------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

-------------------------------------------------------
-- CAMERA TRACK SCENE BUILDER MODULE
-------------------------------------------------------

global haloScale = 100

fn buildControlPoints controlPointsArray =
(
    if controlPointsArray == undefined or controlPointsArray.count == 0 then
    (
        logger.warn "No control points to build."
        return #()
    )

    logger.info "Building {} control points..." args:#(controlPointsArray.count)

    local camPoints = #()

    -- Create or get Camera Control Points layer
    local camLayer = LayerManager.getLayerFromName "Camera Control Points"
    if camLayer == undefined then
        camLayer = LayerManager.newLayerFromName "Camera Control Points"

    for i = 1 to controlPointsArray.count do
    (
        local cp = controlPointsArray[i]

        -- position is a Point3 from the parser; scale to Max units
        local rawPos = getFieldValue cp "position"
        local pos    = rawPos * haloScale

        -- orientation is a native quat from the parser
        local rot = inverse (getFieldValue cp "orientation")

        if i == 1 then
        (
            logger.debug "Control Point 1: pos = [{}, {}, {}]" args:#(rawPos.x, rawPos.y, rawPos.z)
        )

        -- Create pyramid shape for control point
        local ctrlPoint = pyramid()
        ctrlPoint.width = 15
        ctrlPoint.depth = 15
        ctrlPoint.height = 15
        
        -- Set object offset rotation to make pyramid tip point correctly
        ctrlPoint.objectOffsetRot = quat 0.0 -0.707107 0.0 0.707107
        
        -- Name with zero-padded index starting from 00 (control_point00, control_point01, etc.)
        ctrlPoint.name = "control_point_" + (formattedPrint (i - 1) format:"02d")
        
        -- Set position and rotation
        ctrlPoint.rotation = rot
        ctrlPoint.position = pos
        
        -- Set wirecolor (cyan for camera control points)
        ctrlPoint.wirecolor = color 0 240 255
        
        -- Add to layer
        camLayer.addNode ctrlPoint
        
        append camPoints ctrlPoint
    )

    logger.info "Created {} camera control points." args:#(camPoints.count)

    return camPoints
)

-------------------------------------------------------
-- Create Camera Setup
-------------------------------------------------------

fn createCameraSetup pyramidObjects =
(
    logger.info "Creating camera setup..."
    
    -- Create or get Camera Control Points Animation layer
    local camLayer = LayerManager.getLayerFromName "Camera Control Points Animation"
    if camLayer == undefined then
        camLayer = LayerManager.newLayerFromName "Camera Control Points Animation"

    -- Step 1: Create target camera at origin with distance 70
    local cam = Targetcamera \
        fov:70 \
        pos:[0,0,0] \
        target:(Targetobject transform:(matrix3 [1,0,0] [0,1,0] [0,0,1] [70,0,0]))
    
    cam.name = "camera_track_cam"
    cam.target.name = "camera_track_target"
    cam.wirecolor = color 255 200 0  -- Orange
    
    -- Rotate camera -180 degrees on X axis
    --rotate cam (angleaxis -180 [1,0,0])
    
    logger.info "Created target camera with distance: 70, FOV: 70"
    
    -- Step 2: Create 30x30x30 dummy at origin
    local dummyObj = Dummy()
    dummyObj.name = "camera_track_dummy"
    dummyObj.position = [0, 0, 0]
    dummyObj.boxsize = [15, 15, 15]
    dummyObj.wirecolor = color 0 255 0  -- Green
    
    logger.info "Created 15x15x15 dummy at origin"
    
    -- Step 3: Link camera and target to dummy
    cam.parent = dummyObj
    cam.target.parent = dummyObj
    
    logger.info "Linked camera and target to dummy"
    
    -- Add to layer
    camLayer.addNode dummyObj
    camLayer.addNode cam
    camLayer.addNode cam.target

    -- Set a specific viewport to camera view (default: viewport 3)
    try
    (
        -- Save current active viewport
        local previousViewport = viewport.activeViewport
        
        -- Switch to target viewport (3 = bottom-left in standard 4-view layout)
        viewport.activeViewport = 3
        
        viewport.setCamera cam
        viewport.setType #view_camera
        
        -- Set viewport to default shading (smooth + highlights)
        viewport.setRenderLevel #smoothhighlights
        
        -- Restore previous active viewport
        viewport.activeViewport = previousViewport
        
        logger.info "Set viewport 3 to camera view with default shading"
    )
    catch
    (
        logger.warn "Could not set viewport to camera view"
    )
    
    return #(cam, dummyObj)
)

-------------------------------------------------------
-- Animate Camera Path
-------------------------------------------------------

fn animateCameraPath dummyObj pyramidObjects =
(
    logger.info "Generating camera animation..."
    
    -- Debug: Check first pyramid's actual position
    if pyramidObjects.count > 0 then
    (
        logger.debug "First pyramid actual position [X: {}, Y: {}, Z: {}]" args:#(pyramidObjects[1].pos.x, pyramidObjects[1].pos.y, pyramidObjects[1].pos.z)
    )
    
    -- Enable animation and create keyframes every 5 frames
    animate on
    (
        local currentFrame = 0
        for i = 1 to pyramidObjects.count do
        (
            local pyramid = pyramidObjects[i]
            
            at time currentFrame
            (
                -- Copy the entire transform matrix
                dummyObj.transform = pyramid.transform
                
                if i == 1 then
                    logger.debug "Assigned dummy pos: [X: {}, Y: {}, Z: {}]" args:#(dummyObj.pos.x, dummyObj.pos.y, dummyObj.pos.z)
            )
            logger.info "Frame {}: Aligned to '{}'" args:#(currentFrame, pyramid.name)
            currentFrame += 5
        )
    )
    
    -- Set animation range to match the keyframes
    local lastFrame = (pyramidObjects.count - 1) * 5
    animationRange = interval 0 lastFrame
    
    logger.info "Animation created with {} keyframes (frames 0 - {})" args:#(pyramidObjects.count, lastFrame)
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)