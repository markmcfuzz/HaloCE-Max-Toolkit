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

-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Log file setup
scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

logger.log "=== IMPORTING PHYSICS DATA ==="

-- Load required modules
include "core\\halo1\\core_defs.ms"
include "core\\halo1\\parser.ms"
include "core\\halo1\\groups\\physics.ms"
include "builders\\tag\\physics\\build_scene.ms"

-------------------------------------------------------
-- READ TAG FUNCTION
-------------------------------------------------------

fn readPhysicsTag tagPath tagDef =
(
    local filePhysics = fopen tagPath "rb"
    if filePhysics == undefined then
    (
        logger.error "Cannot open file: {}" args:#(tagPath)
        return undefined
    )
    
    logger.log "File opened successfully\n"
    setCurrentFileHandle filePhysics

    if tagDef == undefined then
    (
        logger.error "tagDef is undefined"
        fclose filePhysics
        return undefined
    )
    -- Set default base address for Halo CE
    setTagMemoryBaseAddress 0x40440000
    
    -- Skip to tag data (after 64-byte header)
    fseek filePhysics 64 #seek_set
    
    logger.log "=== READING PHYSICS ==="
    
    -- Read main tag data (now returns camelCase property names)
    local physicsData = readRootTagData tagDef.tagBlock
    fclose filePhysics
    
    local massPointsCount = 0
    local poweredMassPointsCount = 0
    
    -- Get counts from the parsed data
    local massPointsArray = getFieldValue physicsData "massPoints"
    local poweredMassPointsArray = getFieldValue physicsData "poweredMassPoints"
    
    if massPointsArray != undefined then
        massPointsCount = massPointsArray.count
    if poweredMassPointsArray != undefined then
        poweredMassPointsCount = poweredMassPointsArray.count
    
    logger.info "Mass points: {}" args:#(massPointsCount)
    logger.info "Powered mass points: {}" args:#(poweredMassPointsCount)

    return physicsData
)

-------------------------------------------------------
-- MAIN IMPORT FUNCTION
-------------------------------------------------------

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
    
    local startTime = timestamp()
    local setupStartTime = timestamp()

    -- Detect tag class from file
    local tagClass = getTagClass physicsFile

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
    
    logger.info "Opening tag file: '{}'" args:#(substring physicsFile (findString physicsFile "tags\\") -1)

    local setupEndTime = timestamp()
    local setupTime = (setupEndTime - setupStartTime) / 1000.

    -- Read and adapt physics data
    local readStartTime = timestamp()
    local physicsData = readPhysicsTag physicsFile tagDef
    local readEndTime = timestamp()
    local readTime = (readEndTime - readStartTime) / 1000.
    
    if physicsData == undefined then
    (
        messageBox "Failed to read physics tag!" title:"Import Failed"
        return undefined
    )

    logger.info "Reading: {} seconds" args:#(readTime)
    logger.log "Physics read complete\n"

    -- Build spheres using parsed data
    logger.log "=== BUILDING MASS POINT SPHERES ==="

    local massPoints = getFieldValue physicsData "massPoints"
    local poweredMassPoints = getFieldValue physicsData "poweredMassPoints"
    local mass = getFieldValue physicsData "mass"
    local density = getFieldValue physicsData "density"
    
    local buildStartTime = timestamp()
    -- Function in build_scene.ms that creates spheres based on mass points data
    local createdSpheres = createMassPointSpheres \
        massPoints \
        poweredMassPoints \
        mass \
        density
    local buildEndTime = timestamp()
    local buildTime = (buildEndTime - buildStartTime) / 1000.
        

    logger.info "Scene building: {} seconds" args:#(buildTime)
    logger.log "Physics build complete\n"

    -- Refresh viewport
    completeRedraw()

    local endTime = timestamp()
    local elapsedTime = (endTime - startTime) / 1000.

    logger.log "=== IMPORT SUMMARY ==="
    logger.info "Setup/file operations: {} seconds" args:#(setupTime)
    logger.info "Reading tag data: {} seconds" args:#(readTime)
    logger.info "Building scene: {} seconds" args:#(buildTime)
    logger.info "Total time: {} seconds" args:#(elapsedTime)
    logger.log "Physics import complete\n\n"
    
    if createdSpheres != undefined and createdSpheres.count > 0 then
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
-- === Run - auto-detects tag type from file ===
ImportPhysics()
