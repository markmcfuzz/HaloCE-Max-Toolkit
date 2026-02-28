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

logger.log "=== IMPORTING GBX MODEL ==="

-- Load required modules
include "core\\halo1\\core_defs.ms"
include "core\\halo1\\parser.ms"
include "core\\halo1\\groups\\gbxmodel.ms"
include "builders\\tag\\gbxmodel\\struct_mapper.ms"
include "builders\\tag\\gbxmodel\\shader_resolver.ms"
include "builders\\tag\\gbxmodel\\build_scene.ms"

-------------------------------------------------------
-- READ TAG FUNCTION
-------------------------------------------------------

fn readGbxModelTag tagPath tagDef =
(
    local fileGbxModel = fopen tagPath "rb"
    if fileGbxModel == undefined then
    (
        logger.error "Cannot open file: {}" args:#(tagPath)
        return undefined
    )
    
    logger.info "File opened successfully\n"
    setCurrentFileHandle fileGbxModel

    if tagDef == undefined then
    (
        logger.error "tagDef is undefined\n"
        fclose fileGbxModel
        return undefined
    )

    -- Set default base address for Halo CE
    setTagMemoryBaseAddress 0x40440000
    
    -- Skip to tag data (after 64-byte header)
    fseek fileGbxModel 64 #seek_set
    
    logger.info "=== READING GBX MODEL ==="

    local skipUncompressed = configManager.getBool \
        "import_gbxmodel" \
        "skip_uncompressed_vertices" \
        true

    local skipBlocksArray = if skipUncompressed then #("uncompressedVertices") else #()
    
    logger.info "Skip uncompressed vertices: {}" args:#(skipUncompressed)
    -- Read all tag data
    local gbxModelData = readRootTagData tagDef.tagBlock skipBlocks:skipBlocksArray
    fclose fileGbxModel
    
    return gbxModelData
)

-------------------------------------------------------
-- MAIN IMPORT FUNCTION
-------------------------------------------------------

fn ImportGbxModel =
(
    -- Open file dialog
    local gbxModelFile = getOpenFileName \
		caption:"Select Halo CE GBX Model Tag" \
		types:"GBX Model (*.gbxmodel)|*.gbxmodel|All Files (*.*)|*.*" \
		historyCategory:"HaloCEGBXModel"
    
    if gbxModelFile == undefined then 
    (
        logger.warn "Import cancelled by user.\n"
        return undefined
    )
    
    -- Start timing AFTER file selection
    local startTime = timestamp()
    
    -- Detect tag class from file
    local tagClass = getTagClass gbxModelFile

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

    logger.info "Opening tag file: '{}'" args:#(substring gbxModelFile (findString gbxModelFile "tags\\") -1)
    
    -- Read GBX model data using parser
    local readStartTime = timestamp()
    local gbxModelData = readGbxModelTag gbxModelFile tagDef
    local readEndTime = timestamp()
    local readTime = (readEndTime - readStartTime) / 1000.0
    
    if gbxModelData == undefined then
    (
        messageBox "Failed to read GBX model tag!" title:"Import Failed"
        return undefined
    )
    logger.info "Reading: {} seconds" args:#(readTime)
    logger.log "GBX Model reading complete\n"
    -- Build GBX model geometry
    logger.log "=== BUILDING GBX MODEL ==="
    local gbxModelName = getFilenameFile gbxModelFile
    
    -- buildGBXModelMesh expects the parsed data, model name, and file path
    local buildStartTime = timestamp()
    local createdMeshes = buildGBXModelMesh gbxModelData gbxModelName gbxModelFile
    local buildEndTime = timestamp()
    local buildTime = (buildEndTime - buildStartTime) / 1000.0
    
    logger.info "Scene building: {} seconds" args:#(buildTime)
    logger.log "GBX Model build complete\n"
    
    -- Refresh viewport
    completeRedraw()
    
    local endTime = timestamp()
    local elapsedTime = (endTime - startTime) / 1000.0
    
    logger.log "=== IMPORT SUMMARY ==="
    logger.info "Total time: {} seconds" args:#(elapsedTime)
    logger.log "GBX Model import complete\n\n"
    
    -- Show success message
    if createdMeshes != undefined and createdMeshes.count > 0 then
    (
        local fileName = filenameFromPath gbxModelFile
        messageBox ("GBX model imported successfully!\n\n" + \
                    "File: " + fileName + "\n" + \
                    "Meshes created: " + createdMeshes.count as string + "\n" + \
                    "Time: " + (formattedPrint elapsedTime format:".3f") + " seconds") \
                    title:"Import Complete" \
                    beep:false
    )
    
    --clearListener()
    return createdMeshes
)
-- === Run - auto-detects tag type from file ===
ImportGbxModel()
