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

-- Extracts every animation of a model_animations tag to JMA/JMO/JMR/... source files.
-- The work is done by lua\importers\model_animations.lua; this asks for the folder and reports.

-- lua_bridge.ms is loaded by init.ms; reload it if Max still runs an older toolkit.
global luaExportTag
if luaExportTag == undefined and rootEngine != undefined do
    fileIn (rootEngine + "shared\\utils\\lua_bridge.ms")

-- outputDir: when given (e.g. by a test script), no folder dialog and no completion dialog
fn extractModelAnimations tagPath outputDir:undefined =
(
    local askedForFolder = outputDir == undefined
    if askedForFolder do
        outputDir = getSavePath caption:"Select output folder for extracted animations"

    if outputDir == undefined then
    (
        logger.warn "Extraction cancelled by user."
        return false
    )

    -- Ensure the chosen directory exists (user may have typed a new path)
    makeDir outputDir all:true
    -- A trailing backslash would escape the closing quote of the Lua argument
    outputDir = trimRight outputDir "\\"

    local startTime = timestamp()
    local f = luaExportTag "lua\\importers\\model_animations.lua" 2 tagPath options:#(outputDir)
    if f == undefined then
    (
        logger.error "Lua extractor failed | cannot extract animations."
        return false
    )

    local hasNodes  = (luaReadInt f) == 1
    local nodeCount = luaReadInt f
    local animCount = luaReadInt f
    local extracted = luaReadInt f
    local skipped   = luaReadInt f
    logger.info "Nodes: {}, Animations: {}\n" args:#(nodeCount, animCount)

    -- Messages from Lua: 1 info, 2 warning, 3 error
    for i = 1 to (luaReadInt f) do
    (
        local level = luaReadInt f
        local text = readString f
        case level of
        (
            1: logger.info "{}" args:#(text)
            2: logger.warn "{}" args:#(text)
            default: logger.error "{}" args:#(text)
        )
    )
    luaCloseExport f "model_animations"

    local totalMs = timestamp() - startTime
    logger.log "=== TIMING  TOTAL = {} ms ({} sec) ===" args:#(totalMs, (totalMs / 1000.0))
    logger.log "=== EXTRACTION COMPLETE: extracted = {} skipped = {} ===\n\n" args:#(extracted, skipped)
    if not hasNodes then return false

    local showDialogs = askedForFolder and configManager.getBool "feedback" "show_completion_dialogs" true
    if showDialogs then
    (
        messageBox ("Extraction complete!\n\nExtracted: " + extracted as string + \
            "\nSkipped:   " + skipped as string + \
            "\n\nTotal time: " + (totalMs / 1000.0) as string + " sec") title:"Animation Extractor"
    )
    true
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
