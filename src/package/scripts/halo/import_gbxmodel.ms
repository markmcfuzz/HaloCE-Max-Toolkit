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

-- Get script directory
scriptDir = getFilenamePath (getThisScriptFilename())

-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Load required modules
filein (scriptDir + "modules\\global_functions\\config.ms")
filein (scriptDir + "modules\\global_functions\\utils.ms")
filein (scriptDir + "modules\\global_functions\\tag_metadata.ms")
filein (scriptDir + "modules\\file_tag\\gbxmodel\\tag_struct.ms")
filein (scriptDir + "modules\\file_tag\\gbxmodel\\tag_geo_reader.ms")
filein (scriptDir + "modules\\file_tag\\gbxmodel\\tag_data_reader.ms")
filein (scriptDir + "modules\\file_tag\\gbxmodel\\tag_base_reader.ms")
filein (scriptDir + "modules\\file_tag\\gbxmodel\\build_shader.ms")
filein (scriptDir + "modules\\file_tag\\gbxmodel\\build_mesh.ms")
filein (scriptDir + "modules\\file_tag\\gbxmodel\\build_scene.ms")

-------------------------------------------------------
-- Main Import Function
-------------------------------------------------------

fn ImportGbxmodelGeometry modelFile:undefined =
(
    -- Get gbxmodel file if not provided
    if modelFile == undefined then
    (
        modelFile = getOpenFileName \
            caption:"Select Gbxmodel File" \ 
            types:"Gbxmodel (*.gbxmodel)|*.gbxmodel|All Files (*.*)|*.*"
        
        if modelFile == undefined then
        (
            logger "Import cancelled by user.\n"
            clearListener()
            return undefined
        )
    )
    
    -- Extract filename without extension for material name
    local fileName = getFilenameFile modelFile
    
    -- Read gbxmodel tag
    local startTime = timestamp()
    local tagData = readGbxmodelTag modelFile
    local readTime = (timestamp() - startTime) / 1000.0

    if tagData == undefined then
    (
        logger "Could not read gbxmodel tag\n" logType:#error
        messageBox "Failed to read gbxmodel tag file!\n\nThe file may be corrupted or not a valid Halo CE gbxmodel tag." title:"Import Failed"
        return undefined
    )
    
    -- Extract UV scales from tagBase struct
    local baseMapUScale = tagData.tagBase.baseMapUScale
    local baseMapVScale = tagData.tagBase.baseMapVScale
    
    -- Default to 1.0 if zero or undefined (use abs for float comparison)
    if baseMapUScale == undefined or (abs baseMapUScale) < 0.0001 then baseMapUScale = 1.0
    if baseMapVScale == undefined or (abs baseMapVScale) < 0.0001 then baseMapVScale = 1.0
    
    -- Create scene
    local sceneStartTime = timestamp()
    
    -- Create nodes / bones
    local t1 = timestamp()
    local createdNodes = createAllNodes tagData.nodes
    logger "Nodes created: % ms\n" params:#((timestamp() - t1)) logType:#timestamp
    
    -- Extract all local markers from regions into flat array
    local allLocalMarkers = #()
    for r = 1 to tagData.regions.count do
    (
        local region = tagData.regions[r]
        local permutations = region.permutations
        
        for p = 1 to permutations.count do
        (
            local perm = permutations[p]
            local localMarkersArray = perm.localMarkers
            
            for m = 1 to localMarkersArray.count do
            (
                append allLocalMarkers localMarkersArray[m]
            )
        )
    )
    
    -- Create local markers
    local t2 = timestamp()
    local createdLocalMarkers = createMarkers allLocalMarkers tagData.nodes createdNodes
    logger "Markers created: % ms\n" params:#((timestamp() - t2)) logType:#timestamp
    
    -- Create Multi/Sub-Object material with textures resolved from shader tags
    local t3 = timestamp()
    local modelMaterial = createMaterialWithTextures modelFile tagData.shaders materialName:fileName
    logger "Materials created: % ms\n" params:#((timestamp() - t3)) logType:#timestamp
    
    -- Build geometry meshes organized by regions
    local t4 = timestamp()
    local createdMeshes = buildGeometryByRegions modelFile tagData modelMaterial createdNodes uScale:baseMapUScale vScale:baseMapVScale
    logger "Geometry built: % ms\n" params:#((timestamp() - t4)) logType:#timestamp
    
    local sceneTime = (timestamp() - sceneStartTime) / 1000.0
    if tagHeaderLogger then
    (
        logger "\n=== IMPORT COMPLETE ===\n"
        logger "File Name: %\n" params:#((filenameFromPath modelFile)) logType:#info
        --logger "File Path: %\n" params:#(modelFile) logType:#info
    )
    if timeStampLogger then
    (
        logger "\n=== BUILDING SCENE ===\n"
        local totalTime = readTime + sceneTime
        logger "----------------------------------\n"
        logger "Reading: % seconds\n" params:#(readTime) logType:#info
        logger "Scene building: % seconds\n" params:#(sceneTime) logType:#info
        logger "Total time: % seconds\n" params:#(totalTime) logType:#info
    )
    -- Refresh viewport to show imported geometry
    completeRedraw()

    -- Show success message
    if createdMeshes != undefined then
    (
        local fileName = filenameFromPath modelFile
        messageBox ("Gbxmodel geometry imported successfully!\n\n" + "File: " + fileName + "\n") \
                title:"Import Complete" \
                beep:false
    )

    clearListener()
    return tagData
)

importGbxmodelGeometry()
