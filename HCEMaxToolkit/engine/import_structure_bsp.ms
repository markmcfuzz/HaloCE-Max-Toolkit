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

logger.log "=== IMPORTING STRUCTURE BSP DATA ==="

-- Load required modules
include "core\\halo1\\core_defs.ms"
include "core\\halo1\\parser.ms"
include "core\\halo1\\groups\\scenario_structure_bsp.ms"
include "builders\\tag\\scenario_structure_bsp\\struct_mapper.ms"
include "builders\\tag\\scenario_structure_bsp\\build_scene.ms"

-------------------------------------------------------
-- RENDER VERTEX READER
-------------------------------------------------------
--
-- Read compressed render vertices for every lightmap material from the open file handle.
-- The parser must have already run so that tagData fields carry their file positions (#[4]).
-- Returns array of BSPLightmapData structs (defined in struct_mapper.ms).
fn readBSPRenderVertexData fileBSP bspData = (
    local lightmapTuples = getFieldValue bspData "lightmaps"
    if lightmapTuples == undefined or lightmapTuples.count == 0 then return #()
    
    local result = #()
    result.count = lightmapTuples.count
    
    for li = 1 to lightmapTuples.count do (
        local lm             = lightmapTuples[li]
        local bitmapIndex    = getFieldValue lm "bitmap"
        local materialTuples = getFieldValue lm "materials"
        
        local materialsData = #()
        
        if materialTuples != undefined and materialTuples.count > 0 then (
            materialsData.count = materialTuples.count
            
            for mi = 1 to materialTuples.count do (
                local mat = materialTuples[mi]
                
                -- Shader name from tag-ref path
                local shaderName = ""
                local shaderRef  = getFieldValue mat "shader"
                if shaderRef != undefined and classOf shaderRef == Dictionary then (
                    local shaderPath = shaderRef[#path]
                    if shaderPath != undefined and shaderPath != "" then
                        shaderName = filenameFromPath shaderPath
                )
                
                local surfacesStart = getFieldValue mat "surfaces"
                local surfaceCount  = getFieldValue mat "surfaceCount"
                local vertexCount   = getFieldValue mat "renderedVerticesCount"
                local cmpVerts      = getFieldValue mat "compressedVertices"
                
                if surfacesStart == undefined then surfacesStart = 0
                if surfaceCount  == undefined then surfaceCount  = 0
                if vertexCount   == undefined then vertexCount   = 0
                
                local vertices = #()
                
                local canReadVerts = vertexCount > 0 and \
                                        cmpVerts != undefined and \
                                        classOf cmpVerts == Array and \
                                        cmpVerts.count >= 4 and \
                                        cmpVerts[4] != undefined
                
                if canReadVerts then (
                    fseek fileBSP (cmpVerts[4] as integer) #seek_set
                    vertices.count = vertexCount
                    -- Compressed render vertex (32 bytes, LITTLE-endian):
                    --   position  : 3 floats (12 bytes)  ← read
                    --   normal    : uint32    (4 bytes)  ← read (packed 11-11-10 signed)
                    --   binormal  : uint32    (4 bytes)  ← skip (packed)
                    --   tangent   : uint32    (4 bytes)  ← skip (packed)
                    --   UV        : 2 floats  (8 bytes)  ← read
                    for vi = 1 to vertexCount do (
                        local px           = readFloat fileBSP
                        local py           = readFloat fileBSP
                        local pz           = readFloat fileBSP
                        local normalPacked = readLong fileBSP #unsigned
                        -- skip packed binormal + tangent
                        fseek fileBSP 8 #seek_cur
                        local u = readFloat fileBSP
                        local v = readFloat fileBSP
                        vertices[vi] = BSPRenderVertex \
                            pos:[px * haloScale, py * haloScale, pz * haloScale] \
                            uv:[u, 1.0 - v, 0] \
                            normal:(decompressNormal normalPacked)
                    )
                )
                materialsData[mi] = BSPRenderMaterialData \
                    shaderName:shaderName \
                    surfacesStart:surfacesStart \
                    surfaceCount:surfaceCount \
                    vertexCount:vertexCount \
                    vertices:vertices
            )
        )
        result[li] = BSPLightmapData \
            bitmapIndex:(if bitmapIndex != undefined then bitmapIndex else -1) \
            materials:materialsData
    )
    result
)

-------------------------------------------------------
-- READ TAG FUNCTION
-------------------------------------------------------

fn readBSPTag tagPath tagDef = (
    local fileBSP = fopen tagPath "rb"
    if fileBSP == undefined then (
        logger.error "Cannot open file: {}" args:#(tagPath)
        return undefined
    )
    
    logger.log "File opened successfully\n"
    setCurrentFileHandle fileBSP

    if tagDef == undefined then (
        logger.error "tagDef is undefined\n"
        fclose fileBSP
        return undefined
    )

    -- Set default base address for Halo CE
    setTagMemoryBaseAddress 0x40440000
    
    -- Skip to tag data (after 64-byte header)
    fseek fileBSP 64 #seek_set
    
    logger.log "=== READING BSP DATA ==="
    
    -- Read the blocks needed for collision + render scene building.
    -- collisionMaterials/collisionBsp are first; surfaces/lightmaps follow.
    -- clusters must be traversed (has nested sub-blocks) so the file position
    -- is correct when clusterPortals is read immediately after.
    -- breakableSurfaces has no nested reflexives so it is trivially skipped.
    local bspData = readRootTagData tagDef.tagBlock \
        readOnlyBlocks:#("collisionMaterials", "collisionBsp", "surfaces", \
        "lightmaps", "lensFlares", "clusters", "clusterPortals", \ 
        "fogPlanes", "fogPalette", "weatherPalette", "weatherPolyhedra", \
        "pathfindingSurfaces", "pathfindingEdges", "backgroundSoundPalette", \
        "soundEnvironmentPalette", "markers") \
        subBlockSkips:#(
                        #("collisionBsp", \
                            #("bsp3dNodes", \
                                "planes", \
                                "leaves", \
                                "bsp2dReferences", \
                                "bsp2dNodes")))

    -- Read raw render-vertex data while the file is still open.
    -- (parser annotated tagData fields with their file positions above)
    local lightmapsRenderData = readBSPRenderVertexData fileBSP bspData

    fclose fileBSP

    return #(bspData, lightmapsRenderData)
)

-------------------------------------------------------
-- MAIN IMPORT FUNCTION
-------------------------------------------------------

fn importBSP = (
    -- Open file dialog
    local bspFile = getOpenFileName \
        caption:"Select Structure BSP Tag" \
        types:"Structure BSP Tags (*.scenario_structure_bsp)|*.scenario_structure_bsp|All Files (*.*)|*.*" \
        historyCategory:"HaloCEBSP"

    if bspFile == undefined then (
        logger.warn "Import cancelled by user."
        return undefined
    )

    -- start timing AFTER file selection
    local startTime = timestamp()

    -- Detect tag class from file
    local tagClass = getTagClass bspFile

    logger.info "Detected tagClass: '{}'" args:#(tagClass)

    -- Get tag definition
    local tagDef = getTagDefByClass tagClass

    if tagDef == undefined then (
        logger.error "No tag definition found for class '{}'" args:#(tagClass)
        messageBox "Unsupported tag type!" title:"Import Failed"
        return undefined
    )

    local tagsPos = findString bspFile "tags\\"
    local displayPath = if tagsPos != undefined then (substring bspFile tagsPos -1) else (filenameFromPath bspFile)
    logger.log "Importing tag: {}" args:#(displayPath)

    -- Read BSP Data using parser
    local readStartTime = timestamp()
    local tagResult = readBSPTag bspFile tagDef
    local readEndTime = timestamp()
    local readTime = (readEndTime - readStartTime) / 1000.0

    if tagResult == undefined then (
        messageBox "Failed to read BSP data!" title:"Import Failed"
        return undefined
    )

    local bspData           = tagResult[1]
    local lightmapsRenderData = tagResult[2]

    if bspData == undefined then (
        messageBox "Failed to read BSP data!" title:"Import Failed"
        return undefined
    )

    logger.info "Reading: {} seconds" args:#(readTime)
    logger.log "Structure BSP reading complete\n"

    -- Build scene from BSP data
    logger.log "=== BUILDING SCENE FROM BSP DATA ==="
    local bspName = getFilenameFile bspFile

    -- buildBSPMesh expects the parsed data and builds 3d meshes
    local buildStartTime = timestamp()
    local createdMeshes = buildBSPMesh bspData lightmapsRenderData bspName
    local buildEndTime = timestamp()
    local buildTime = (buildEndTime - buildStartTime) / 1000.0

    logger.info "Building: {} seconds" args:#(buildTime)
    logger.log "Scene building complete\n"

    -- Refresh viewport
    completeRedraw()

    local endTime = timestamp()
    local elapsedTime = (endTime - startTime) / 1000.0

    logger.log "=== IMPORT SUMMARY ==="
    logger.info "Total time: {} seconds" args:#(elapsedTime)
    logger.log "Structure BSP import complete\n\n"

    local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true

    if showDialogs and createdMeshes != undefined and createdMeshes.count > 0 then (
        local fileName = filenameFromPath bspFile
        messageBox ("Structure BSP imported successfully!\n\n" + \
                    "File: " + fileName + "\n" + \
                    "Meshes created: " + createdMeshes.count as string + "\n" + \
                    "Time: " + (formattedPrint elapsedTime format:".3f") + " seconds") \
                    title:"Import Complete" \
                    beep:false
    )

    clearListener()
    return createdMeshes
)

importBSP()