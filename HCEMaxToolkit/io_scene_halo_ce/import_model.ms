-- Halo Custom Edition Model Importer
-- by Mark McFuzz
-- Version 1.0.0
------------------------------------------------------------------------------------------------
-- Features:
-- - Imports model tags from Halo Custom Edition
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
filein (scriptDir + "modules\\file_tag\\model\\build_mesh.ms")
filein (scriptDir + "modules\\file_tag\\model\\tag_struct.ms")
filein (scriptDir + "modules\\file_tag\\model\\tag_geo_reader.ms")
filein (scriptDir + "modules\\file_tag\\model\\tag_data_reader.ms")
filein (scriptDir + "modules\\file_tag\\model\\tag_base_reader.ms")

-------------------------------------------------------
-- Main Import Function
-------------------------------------------------------

fn ImportModelGeometry modelFile:undefined =
(
    -- Get model file if not provided
    if modelFile == undefined then
    (
        modelFile = getOpenFileName caption:"Select Model File" types:"Model (*.model)|*.model|All Files (*.*)|*.*"
        
        if modelFile == undefined then
        (
            format "Import cancelled by user.\n"
            return undefined
        )
    )
    
    --format "\n=== IMPORTING MODEL ===\n"
    --format "File: %\n" (filenameFromPath modelFile)
    
    -- Extract filename without extension for material name
    local fileName = getFilenameFile modelFile
    
    -- Read model tag
    local startTime = timestamp()
    local tagData = readModelTag modelFile
    local readTime = (timestamp() - startTime) / 1000.0
    
    if tagData == undefined then
    (
        format "[FAILED] Could not read model tag\n"
        messageBox "Failed to read model tag file!\n\nThe file may be corrupted or not a valid Halo CE model tag." title:"Import Failed"
        return undefined
    )
    
    --format "\n[SUCCESS] Model tag read successfully!\n"
    
    -- Extract data
    local headerData = tagData[1]
    local tagdataFields = tagData[2]
    local markersArray = tagData[3]
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
    
    --format "Base Map U-Scale: %\n" baseMapUScale
    --format "Base Map V-Scale: %\n" baseMapVScale
    --format "Version: %\n" headerData[2]
    --format "Nodes: %\n" nodesArray.count
    --format "Markers: %\n" markersArray.count
    --format "Regions: %\n" regionsArray.count
    --format "Geometries: %\n" geometriesArray.count
    --format "Shaders: %\n" shadersArray.count
    --format "Local Markers: %\n" totalLocalMarkers

    local sceneStartTime = timestamp()
    -- Create nodes/bones hierarchy
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
    local createdMarkers = createMarkers markersArray nodesArray createdNodes
    
    -- Create local markers
    local t2 = timestamp()
    local createdLocalMarkers = createMarkers allLocalMarkers nodesArray createdNodes
    logger "Local markers created: % ms\n" params:#((timestamp() - t2)) logType:#timestamp
    
    -- Create Multi/Sub-Object material with filename as material name
    local t3 = timestamp()
    local modelMaterial = createMaterial shadersArray materialName:fileName
    logger "Material created: % ms\n" params:#((timestamp() - t3)) logType:#timestamp
    
    -- Build geometry meshes organized by regions (using model-specific function)
    local t4 = timestamp()
    local createdMeshes = buildModelGeometryByRegions regionsArray geometriesArray modelFile modelMaterial nodesArray createdNodes uScale:baseMapUScale vScale:baseMapVScale
    logger "Geometry built: % ms\n" params:#((timestamp() - t4)) logType:#timestamp

    local sceneTime = (timestamp() - sceneStartTime) / 1000.0
    if timeStampLogger then
    (
        logger "\n=== BUILDING SCENE ===\n"
        local totalTime = readTime + sceneTime
        logger "----------------------------------\n"
        logger "Reading: % seconds\n" params:#(readTime) logType:#info
        logger "Scene building: % seconds\n" params:#(sceneTime) logType:#info
        logger "Total time: % seconds\n" params:#(totalTime) logType:#info
    )
    
    --local summary = "Model tag imported successfully!\n\n"
    --summary += "Version: " + headerData[2] as string + "\n"
    --summary += "Nodes: " + nodesArray.count as string + "\n"
    --summary += "Markers: " + markersArray.count as string + "\n"
    --summary += "Regions: " + regionsArray.count as string + "\n"
    --summary += "Geometries: " + geometriesArray.count as string + "\n"
    --summary += "Shaders: " + shadersArray.count as string + "\n"
    --summary += "Local Markers: " + allLocalMarkers.count as string
    
    --messageBox summary title:"Import Complete"
    
    -- Refresh viewport to show imported geometry
    completeRedraw()
    
    return tagData
)

ImportModelGeometry()