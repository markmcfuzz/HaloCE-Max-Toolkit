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
include "core\\halo1\\core_defs.ms"
include "core\\halo1\\parser.ms"
include "core\\halo1\\groups\\model_collision_geometry.ms"
include "builders\\tag\\model_collision_geometry\\struct_mapper.ms"
include "builders\\tag\\model_collision_geometry\\build_scene.ms"

-------------------------------------------------------
-- READ TAG FUNCTION
-------------------------------------------------------

fn readCollisionTag tagPath tagDef =
(
    local fileCollision = fopen tagPath "rb"
    if fileCollision == undefined then
    (
        logger.error "Cannot open file: {}" args:#(tagPath)
        return undefined
    )
    
    logger.log "File opened successfully\n"
    setCurrentFileHandle fileCollision

    if tagDef == undefined then
    (
        logger.error "tagDef is undefined\n"
        fclose fileCollision
        return undefined
    )

    -- Set default base address for Halo CE
    setTagMemoryBaseAddress 0x40440000
    
    -- Skip to tag data (after 64-byte header)
    fseek fileCollision 64 #seek_set
    
    logger.log "=== READING MODEL COLLISION GEOMETRY ==="
    
    -- Read all tag data
    local collisionData = readRootTagData tagDef.tagBlock
    fclose fileCollision
    
    return collisionData
)

-------------------------------------------------------
-- MAIN IMPORT FUNCTION
-------------------------------------------------------

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
    
    -- Start timing AFTER file selection
    local startTime = timestamp()
    
    -- Detect tag class from file
    local tagClass = getTagClass collisionFile

    logger.info "Detected tagClass: '{}'" args:#(tagClass)
    
    -- Get tag definition
    local tagDef = getTagDefByClass tagClass
    
    if tagDef == undefined then
    (
        --
        logger.error "Unknown or unsupported tag class: '{}'" args:#(tagClass)
        messageBox "Unsupported tag type!" title:"Import Failed"
        return undefined
    )
    
    local tagsPos = findString collisionFile "tags\\"
    local displayPath = if tagsPos != undefined then (substring collisionFile tagsPos -1) else (filenameFromPath collisionFile)
    logger.log "Opening tag file: '{}'" args:#(displayPath)

    -- Read collision data using parser
    local readStartTime = timestamp()
    local collisionData = readCollisionTag collisionFile tagDef
    local readEndTime = timestamp()
    local readTime = (readEndTime - readStartTime) / 1000.
    
    if collisionData == undefined then
    (
        messageBox "Failed to read collision tag!" title:"Import Failed"
        return undefined
    )
    logger.info "Reading: {} seconds" args:#(readTime)
    logger.log "Collision geometry reading complete\n"
    -- Build collision mesh geometry
    logger.log "=== BUILDING COLLISION MESH ==="
    local collisionName = getFilenameFile collisionFile
    
    -- buildCollisionMesh expects the parsed data and builds 3D meshes
    local buildStartTime = timestamp()
    local createdMeshes = buildCollisionMesh collisionData collisionName
    local buildEndTime = timestamp()
    local buildTime = (buildEndTime - buildStartTime) / 1000.0

    logger.info "Scene building: {} seconds" args:#(buildTime)
    logger.log "Collision geometry build complete\n"
    
    -- Refresh viewport
    completeRedraw()
    
    local endTime = timestamp()
    local elapsedTime = (endTime - startTime) / 1000.0
    
    logger.log "=== IMPORT SUMMARY ==="
    logger.info "Total time: {} seconds" args:#(elapsedTime)
    logger.log "Collision geometry import complete\n\n"

    local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true

    -- Show success message
    if showDialogs and createdMeshes != undefined and createdMeshes.count > 0 then
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
-- === Run - auto-detects tag type from file ===
ImportCollision()
