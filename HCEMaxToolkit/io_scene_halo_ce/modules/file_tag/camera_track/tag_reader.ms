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
-- Tag Header (64 bytes)
-------------------------------------------------------

fn readCameraTrackHeader =
(
    seekToPosition 36
    local tagClass = read.longB "#unsigned"

    seekToPosition 40
    local checksum = read.longB "#unsigned"

    seekToPosition 56
    local version = read.shortB "#unsigned"

    seekToPosition 60
    local engineId = read.longB "#unsigned"

    local expectedFourcc = getFourccByTagName "trak"

    if tagClass != expectedFourcc then
    (
        logger "Invalid tag class. Expected trak, Found: %\n" params:#(tagClass) logType:#error
        return undefined
    )

    local header = returnHeader()
    header.tagClass = tagClass
    header.checksum = checksum
    header.version = version
    header.engineId = engineId

    return header
)

-------------------------------------------------------
-- Read Reflexive Header
-- tagdata starts at 64
-------------------------------------------------------

fn readCameraTrackReflexives =
(
    -- Tagdata base
    seekToPosition 64
    
    -- Skip 4 bytes (unknown/padding before reflexive)
    skipBytes 4
    
    -- Read reflexive (12 bytes)
    local controlPointsRef = read.reflex()
    
    local reflexives = returnCameraTrackReflexives()
    reflexives.controlPoints = controlPointsRef
    
    return reflexives
)

-------------------------------------------------------
-- Read Control Points
-------------------------------------------------------

fn readCameraTrackControlPoints controlPointsReflexive =
(
    local controlPointsArray = #()
    
    if controlPointsReflexive.count == 0 then
        return controlPointsArray
    
    -- Data always starts sequentially after ALL tag structures
    -- Header: 64 bytes, Tagdata: 48 bytes = 112
    -- Note: The pointer field in reflexives is a memory address (not file offset) and should be ignored
    local controlPointsDataOffset = 112
    seekToPosition controlPointsDataOffset
    
    for i = 1 to controlPointsReflexive.count do
    (
        local cameraPoint = returnCameraTrackControlPoint()
        
        -- Position (12 bytes)
        cameraPoint.position = math.readPoint3()
        
        -- Orientation quaternion (16 bytes)
        cameraPoint.orientation = math.readQuat()
        
        -- Skip remaining padding to reach 60 bytes total
        skipBytes (60 - 28)
        
        append controlPointsArray cameraPoint
    )
    
    return controlPointsArray
)

-------------------------------------------------------
-- Main Camera Track Reader
-------------------------------------------------------

fn readCameraTrackTag filePath =
(
    local fileHandle = fopen filePath "rb"
    if fileHandle == undefined then
        return undefined
    
    setFileHandle fileHandle
    in_file = fileHandle
    
    local tagStruct = cameraTrackTag()
    
    -- Header
    local tagHeader = readCameraTrackHeader()
    if tagHeader == undefined then
    (
        fclose fileHandle
        return undefined
    )
    tagStruct.header = tagHeader
    
    -- Reflexive header
    local reflexives = readCameraTrackReflexives()
    tagStruct.controlPointsBlock = reflexives.controlPoints
    
    -- Control points
    tagStruct.controlPoints = readCameraTrackControlPoints reflexives.controlPoints
    
    if tagHeaderLogger then
    (
        logger "\n=== CAMERA TRACK SUMMARY ===\n"
        logger "Control Points Count: [%]\n" params:#(tagStruct.controlPoints.count)
        
        for i = 1 to tagStruct.controlPoints.count do
        (
            logger "    Camera Control Point [%]:\n" params:#(i)
            logger "        Position: [%]\n" params:#(pointFormat tagStruct.controlPoints[i].position type:#point)
            logger "        Orientation: [%]\n" params:#(pointFormat tagStruct.controlPoints[i].orientation type:#quat)
        )
        logger "\n"
    )
    fclose fileHandle
    return tagStruct
)
