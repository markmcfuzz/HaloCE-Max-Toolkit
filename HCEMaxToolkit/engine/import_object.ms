------------------------------------------------------------------------------
--	Copyright (C) 2026 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------

-- Imports an object tag (biped, vehicle, weapon, scenery, device_machine): its gbxmodel, collision
-- and physics with their own importers, plus a Point named after the tag that holds every tag
-- field; the Qt tag editor (builders\tag\object\tag_editor.ms) opens to edit them.

-- The importers of the tags it contains are loaded without running them
global importerNoAutoRun
global objectImporterAutoRun = importerNoAutoRun != true
importerNoAutoRun = true
include "import_gbxmodel.ms"
include "import_collision.ms"
include "import_physics.ms"
importerNoAutoRun = not objectImporterAutoRun

clearListener()
gc light:true

scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

logger.log "=== IMPORTING OBJECT TAG ==="

include "builders\\tag\\object\\lua_reader.ms"
include "builders\\tag\\object\\build_scene.ms"
include "builders\\tag\\object\\tag_editor.ms"

-------------------------------------------------------
-- MAIN IMPORT FUNCTIONS
-------------------------------------------------------

fn isObjectTag tagPath = findItem #("bipd", "vehi", "weap", "scen", "mach") (getTagClass tagPath) > 0

-- Imports a tag the object refers to (relPath "" = none) with importFn; logs what is missing
fn importReferencedTag tagsRoot relPath importFn =
(
    if relPath == "" then return undefined
    if tagsRoot == undefined then
    (
        logger.warn "Skipped '{}': the object tag is not inside a tags folder" args:#(relPath)
        return undefined
    )
    local fullPath = tagsRoot + relPath
    if not (doesFileExist fullPath) then
    (
        logger.warn "Tag not found: '{}'" args:#(fullPath)
        return undefined
    )
    logger.log "--- Importing '{}' ---" args:#(relPath)
    importFn fullPath
)

-- Imports one file without dialogs. Returns the container, or undefined on failure.
fn importObjectFile tagPath =
(
    if not (isObjectTag tagPath) then
    (
        logger.error "Not an object tag: '{}'" args:#(tagPath)
        return undefined
    )

    local readStartTime = timestamp()
    local data = readObjectWithLua tagPath
    if data == undefined then return undefined
    logger.info "Reading: {} seconds" args:#((timestamp() - readStartTime) / 1000.)
    logger.info "Fields: {}" args:#(data.keys.count)

    -- Model first: collision and physics attach to its nodes
    local lastHandle = getLastNodeHandle()
    local tagsRoot = getTagsRootFromTagPath tagPath
    importReferencedTag tagsRoot data.modelRef importGbxModelFile
    local modelHandle = getLastNodeHandle()
    importReferencedTag tagsRoot data.collisionRef importCollisionFile
    local collisionHandle = getLastNodeHandle()
    importReferencedTag tagsRoot data.physicsRef importPhysicsFile
    local physicsHandle = getLastNodeHandle()
    -- What each reference brought, for the editor's eye and link buttons
    local parts = #(getNodesBetweenHandles lastHandle modelHandle, \
                    getNodesBetweenHandles modelHandle collisionHandle, \
                    getNodesBetweenHandles collisionHandle physicsHandle)

    -- Created last, so physics doesn't count it among the model nodes
    local memberNodes = getNodesAfterHandle lastHandle
    append memberNodes (createBoundingRadiusHelper data.keys data.values (filenameFromPath tagPath))
    local container = createObjectContainer data tagPath memberNodes parts:parts
    logger.info "Change colors on {} materials" args:#(applyObjectChangeColors container)
    logger.info "Container '{}' with {} nodes" args:#(container.name, memberNodes.count)

    completeRedraw()
    container
)

fn ImportObject =
(
    local tagPath = getOpenFileName \
        caption:"Select Halo CE Object Tag" \
        types:("Object Tags|*.biped;*.vehicle;*.weapon;*.scenery;*.device_machine|" + \
               "Biped (*.biped)|*.biped|Vehicle (*.vehicle)|*.vehicle|Weapon (*.weapon)|*.weapon|" + \
               "Scenery (*.scenery)|*.scenery|Device Machine (*.device_machine)|*.device_machine|" + \
               "All Files (*.*)|*.*") \
        historyCategory:"HaloCEObject"

    if tagPath == undefined then
    (
        logger.warn "Import cancelled by user.\n"
        return undefined
    )

    if not (isObjectTag tagPath) then
    (
        messageBox "Unsupported tag type!" title:"Import Failed"
        return undefined
    )

    local startTime = timestamp()
    local container = importObjectFile tagPath
    local elapsedTime = (timestamp() - startTime) / 1000.

    if container == undefined then
    (
        messageBox "Failed to import the object tag! See the log for details." title:"Import Failed"
        return undefined
    )

    logger.log "=== IMPORT SUMMARY ==="
    logger.info "Total time: {} seconds" args:#(elapsedTime)
    logger.log "Object import complete\n\n"

    -- Selecting it opens the tag editor (tag_editor.ms)
    select container
    local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true
    if showDialogs then
    (
        messageBox ("Object tag imported successfully!\n\n" + \
                    "File: " + (filenameFromPath tagPath) + "\n" + \
                    "Nodes created: " + (container.memberNodes.count as string) + "\n" + \
                    "Time: " + (formattedPrint elapsedTime format:".3f") + " seconds") \
                    title:"Import Complete" \
                    beep:false
    )
    clearListener()
    container
)

-- Tests set importerNoAutoRun = true to load these functions without importing.
if objectImporterAutoRun do ImportObject()
