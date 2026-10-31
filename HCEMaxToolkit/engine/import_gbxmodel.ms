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

logger.log "=== IMPORTING GBX MODEL ==="

-- Load required modules
include "builders\\tag\\gbxmodel\\model_data.ms"
include "builders\\tag\\gbxmodel\\lua_reader.ms"
include "builders\\tag\\shared\\shader_resolver.ms"
include "builders\\tag\\shared\\dx_material_builder.ms"
include "builders\\tag\\shared\\viewport_material.ms"
include "builders\\tag\\gbxmodel\\build_scene.ms"

-------------------------------------------------------
-- MAIN IMPORT FUNCTIONS
-------------------------------------------------------

fn isGbxModelTag tagPath = (getTagClass tagPath) == "mod2"

-- Imports one file without dialogs. Returns the created meshes, or undefined on failure.
fn importGbxModelFile gbxModelFile =
(
    if not (isGbxModelTag gbxModelFile) then
    (
        logger.error "Not a gbxmodel tag: '{}'" args:#(gbxModelFile)
        return undefined
    )

    local readStartTime = timestamp()
    local model = readGbxModelWithLua gbxModelFile
    if model == undefined then return undefined
    logger.info "Reading: {} seconds" args:#((timestamp() - readStartTime) / 1000.0)

    logger.log "=== BUILDING GBX MODEL ==="
    local buildStartTime = timestamp()
    -- Undo off: with undo on, every skinOps call got ~15x slower (Ctrl+Z won't remove the import)
    local createdMeshes = with undo off (buildGBXModelMesh model (getFilenameFile gbxModelFile) gbxModelFile)
    logger.info "Scene building: {} seconds" args:#((timestamp() - buildStartTime) / 1000.0)

    completeRedraw()
    createdMeshes
)

fn ImportGbxModel =
(
    local gbxModelFile = getOpenFileName \
		caption:"Select Halo CE GBX Model Tag" \
		types:"GBX Model (*.gbxmodel)|*.gbxmodel|All Files (*.*)|*.*" \
		historyCategory:"HaloCEGBXModel"

    if gbxModelFile == undefined then
    (
        logger.warn "Import cancelled by user.\n"
        return undefined
    )

    if not (isGbxModelTag gbxModelFile) then
    (
        messageBox "Unsupported tag type!" title:"Import Failed"
        return undefined
    )

    local startTime = timestamp()
    local createdMeshes = importGbxModelFile gbxModelFile
    local elapsedTime = (timestamp() - startTime) / 1000.0

    if createdMeshes == undefined then
    (
        messageBox "Failed to read GBX model tag!" title:"Import Failed"
        return undefined
    )

    logger.log "=== IMPORT SUMMARY ==="
    logger.info "Total time: {} seconds" args:#(elapsedTime)
    logger.log "GBX Model import complete\n\n"

    local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true
    if showDialogs and createdMeshes.count > 0 then
    (
        local fileName = filenameFromPath gbxModelFile
        messageBox ("GBX model imported successfully!\n\n" + \
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
if importerNoAutoRun != true do ImportGbxModel()
