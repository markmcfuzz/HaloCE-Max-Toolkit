----------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
----------------------------------------------------------------------------

-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Log file setup
scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

logger.log "=== EXPORTING JMS FILE ==="
-- Load required modules
include "formats\\jms\\jms_struct.ms"
include "formats\\jms\\validate_scene.ms"
include "formats\\jms\\process_cat.ms"
include "formats\\jms\\process_scene.ms"
include "formats\\jms\\process_file.ms"

fn exportJmsFile =
(
    -- Process scene and extract JMS data
    local processResult = processSceneForJMS()
    
    -- Check if validation failed
    if processResult == undefined then
        return false
    
    local jmsData = processResult[1]
    local processingTime = processResult[2]

    -- Prompt user for save location
    local filePath = getSaveFileName \
        caption:"Export JMS File" \
        types:"JMS Files (*.JMS)|*.JMS|All Files (*.*)|*.*" \
        filename:"untitled.JMS"
    
    -- Check if user cancelled
    if filePath == undefined then
        return false
    
    -- Write the JMS file
    local writeResult = writeJmsFile filePath jmsData
    local success = writeResult[1]
    local writeTime = writeResult[2]
    local totalTime = (processingTime + writeTime) / 1000.0

    -- Show success message
    if success then
    (
        local fileName = filenameFromPath filePath
        messageBox ("JMS file exported successfully!\n\n" + \
                "File: " + fileName + "\n" + \
                "Total Time: " + (formattedPrint totalTime format:".3f") + " seconds") \
                title:"Export Complete" \
                beep:false
    )
    
    logger.log "=== EXPORT SUMMARY ==="
    logger.info "Export process completed in {} seconds" args:#(formattedPrint totalTime format:".3f")
    logger.log "JMS Export Complete\n\n"

    --clearListener()
    return success
)

-- Run the exporter
exportJmsFile()