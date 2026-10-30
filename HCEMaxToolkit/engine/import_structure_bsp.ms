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
include "builders\\tag\\shared\\collision_bsp_reader.ms"
include "builders\\tag\\scenario_structure_bsp\\lua_reader.ms"
include "builders\\tag\\shared\\shader_resolver.ms"
include "builders\\tag\\shared\\dx_material_builder.ms"
include "builders\\tag\\shared\\viewport_material.ms"
include "builders\\tag\\scenario_structure_bsp\\build_scene.ms"

-------------------------------------------------------
-- MAIN IMPORT FUNCTIONS
-------------------------------------------------------

fn isStructureBspTag tagPath = (getTagClass tagPath) == "sbsp"

-- Imports one file without dialogs. Returns the created meshes, or undefined on failure.
fn importStructureBspFile bspFile = (
    if not (isStructureBspTag bspFile) then (
        logger.error "Not a scenario_structure_bsp tag: '{}'" args:#(bspFile)
        return undefined
    )

    local tagsPos = findString bspFile "tags\\"
    local displayPath = if tagsPos != undefined then (substring bspFile tagsPos -1) else (filenameFromPath bspFile)
    logger.log "Importing tag: {}" args:#(displayPath)

    local readStartTime = timestamp()
    local bspData = readStructureBspWithLua bspFile
    if bspData == undefined then return undefined
    logger.info "Reading: {} seconds" args:#((timestamp() - readStartTime) / 1000.0)
    logger.log "Structure BSP reading complete\n"

    -- Shader textures are resolved relative to bspFile's tags\ root
    logger.log "=== BUILDING SCENE FROM BSP DATA ==="
    local buildStartTime = timestamp()
    local createdMeshes = buildBSPMesh bspData (getFilenameFile bspFile) bspFile
    logger.info "Building: {} seconds" args:#((timestamp() - buildStartTime) / 1000.0)
    logger.log "Scene building complete\n"

    completeRedraw()
    createdMeshes
)

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

    if not (isStructureBspTag bspFile) then (
        messageBox "Unsupported tag type!" title:"Import Failed"
        return undefined
    )

    local startTime = timestamp()
    local createdMeshes = importStructureBspFile bspFile
    local elapsedTime = (timestamp() - startTime) / 1000.0

    if createdMeshes == undefined then (
        messageBox "Failed to read BSP data!" title:"Import Failed"
        return undefined
    )

    logger.log "=== IMPORT SUMMARY ==="
    logger.info "Total time: {} seconds" args:#(elapsedTime)
    logger.log "Structure BSP import complete\n\n"

    local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true

    if showDialogs and createdMeshes.count > 0 then (
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

-- Tests set importerNoAutoRun = true to load these functions without importing.
global importerNoAutoRun
if importerNoAutoRun != true do importBSP()
