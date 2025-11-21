-- Halo Custom Edition Gbxmodel Importer
-- by Mark McFuzz
-- Version 1.0.0
------------------------------------------------------------------------------------------------
-- Features:
-- - Imports gbxmodel tags from Halo Custom Edition
-- - Accurate geometry.
-- - Accurate vertex weights.
-- - Accurate UV's.
-- - Renames objects as regionName + permutationName + levelLOD.
-- - Links each geometry to the first node.
-- - Creates a Multi/Sub-Object material using only the materials actually used and with the 
--   shaders names.
-- - Asigns a different layer each type objects in scene (nodes, markers, geometry).
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
filein (scriptDir + "modules\\file_tag\\gbxmodel\\build_mesh.ms")
filein (scriptDir + "modules\\file_tag\\gbxmodel\\build_scene.ms")
filein (scriptDir + "modules\\file_tag\\gbxmodel\\tag_struct.ms")
filein (scriptDir + "modules\\file_tag\\gbxmodel\\tag_geo_reader.ms")
filein (scriptDir + "modules\\file_tag\\gbxmodel\\tag_data_reader.ms")
filein (scriptDir + "modules\\file_tag\\gbxmodel\\tag_base_reader.ms")

-------------------------------------------------------
-- Main Import Function
-------------------------------------------------------

fn ImportGbxmodelGeometry modelFile:undefined =
(
    -- Get gbxmodel file if not provided
    if modelFile == undefined then
    (
        modelFile = getOpenFileName caption:"Select Gbxmodel File" types:"Gbxmodel (*.gbxmodel)|*.gbxmodel|All Files (*.*)|*.*"
        
        if modelFile == undefined then
        (
            logger "Import cancelled by user.\n" logType:#warning
            --clearListener()
            return undefined
        )
    )
    
    --logger "\n=== IMPORTING GBXMODEL ===\n"
    
    -- Extract filename without extension for material name
    local fileName = getFilenameFile modelFile
    
    -- Read gbxmodel tag
    local startTime = timestamp()
    local tagData = readGbxmodelTag modelFile
    local readTime = (timestamp() - startTime) / 1000.0
    --if timeStampLogger then
    --(
    --    logger "Tag read in % seconds\n" params:#(readTime) logType:#success
    --)
    
    if tagData == undefined then
    (
        logger "Could not read gbxmodel tag\n" logType:#error
        messageBox "Failed to read gbxmodel tag file!\n\nThe file may be corrupted or not a valid Halo CE gbxmodel tag." title:"Import Failed"
        return undefined
    )
    
    -- Extract data
    local headerData = tagData[1]
    local tagdataFields = tagData[2]
    --local markersArray = tagData[3]
    local nodesArray = tagData[4]
    local regionsArray = tagData[5]
    local geometriesArray = tagData[6]
    local shadersArray = tagData[7]
    local totalLocalMarkers = tagData[8]
    
    -- Extract UV scales from tagdataFields (indices 13 and 14)
    local baseMapUScale = tagdataFields[13]
    local baseMapVScale = tagdataFields[14]
    
    -- Default to 1.0 if zero or undefined (use abs for float comparison)
    if baseMapUScale == undefined or (abs baseMapUScale) < 0.0001 then baseMapUScale = 1.0
    if baseMapVScale == undefined or (abs baseMapVScale) < 0.0001 then baseMapVScale = 1.0
    
    -- Create nodes/bones hierarchy
    
    local sceneStartTime = timestamp()
    -- Create nodes / bones
    local t1 = timestamp()
    local createdNodes = createAllNodes nodesArray
    logger "Nodes created: % ms\n" params:#((timestamp() - t1)) logType:#timestamp
    
    -- Extract all local markers from regions into flat array
    local allLocalMarkers = #()
    for r = 1 to regionsArray.count do
    (
        local regionData = regionsArray[r]
        local permutations = regionData[2]  -- Array of permutations (regionData[1] is region info)
        
        for p = 1 to permutations.count do
        (
            local permData = permutations[p]
            local permInfo = permData[1]  -- Permutation info array
            local localMarkersArray = permData[2]  -- Array of local markers for this permutation
            
            for m = 1 to localMarkersArray.count do
            (
                append allLocalMarkers localMarkersArray[m]
            )
        )
    )
    
    -- Create global markers (if any)
    --local createdMarkers = createMarkers markersArray nodesArray createdNodes
    
    -- Create local markers
    local t2 = timestamp()
    local createdLocalMarkers = createMarkers allLocalMarkers nodesArray createdNodes
    logger "Markers created: % ms\n" params:#((timestamp() - t2)) logType:#timestamp
    
    -- Create Multi/Sub-Object material with filename as material name
    local t3 = timestamp()
    local modelMaterial = createMaterial shadersArray materialName:fileName
    logger "Materials created: % ms\n" params:#((timestamp() - t3)) logType:#timestamp
    
    -- Build geometry meshes organized by regions
    local t4 = timestamp()
    local createdMeshes = buildGeometryByRegions regionsArray geometriesArray modelFile modelMaterial nodesArray createdNodes uScale:baseMapUScale vScale:baseMapVScale
    logger "Geometry built: % ms\n" params:#((timestamp() - t4)) logType:#timestamp
    
    local sceneTime = (timestamp() - sceneStartTime) / 1000.0
    if tagHeaderLogger then
    (
        logger "\n=== IMPORT COMPLETE ===\n"
        logger "File Name: %\n" params:#((filenameFromPath modelFile)) logType:#info
        logger "File Path: %\n" params:#(modelFile) logType:#info
        --logger "Tag Class: %\n" params:#(getTagClassInfo headerData[1]) logType:#info
        --logger "Version: %\n" params:#(headerData[3]) logType:#info
        --logger "Engine ID: %\n" params:#(getEngineIdInfo headerData[4]) logType:#info
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
    
    --local summary = "Gbxmodel tag imported successfully!\n\n"
    ----summary += "Version: " + headerData[2] as string + "\n"
    --summary += "Nodes: " + nodesArray.count as string + "\n"
    ----summary += "Markers: " + markersArray.count as string + "\n"
    --summary += "Regions: " + regionsArray.count as string + "\n"
    --summary += "Geometries: " + geometriesArray.count as string + "\n"
    --summary += "Shaders: " + shadersArray.count as string + "\n"
    --summary += "Local Markers: " + allLocalMarkers.count as string
    --
    --messageBox summary title:"Import Complete"

    return tagData
)

importGbxmodelGeometry()
