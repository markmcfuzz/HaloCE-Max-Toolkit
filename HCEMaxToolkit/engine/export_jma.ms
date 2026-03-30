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

-- Load required modules
include "formats\\jma\\jma_struct.ms"
include "formats\\jma\\validate_scene.ms"
include "formats\\jms\\process_cat.ms"
include "formats\\jma\\process_scene.ms"
include "formats\\jma\\process_file.ms"

logger.log "=== EXPORTING ANIMATION DATA ==="

fn exportJmaFile =
(
    -- Process scene and extract JMA data
    local processResult = processSceneForJMA()
    
    -- Check if processing failed
    if processResult == undefined then
        return false
    
    local jmaData = processResult[1]
    local processingTime = processResult[2]
    
    -- Prompt user for save location
    local filePath = getSaveFileName \
        caption:"Export JMA File" \
        types:"JMA Files (*.JMA)|*.JMA|JMO Files (*.JMO)|*.JMO|JMR Files (*.JMR)|*.JMR|JMM Files (*.JMM)|*.JMM|JMT Files (*.JMT)|*.JMT|JMW Files (*.JMW)|*.JMW|JMZ Files (*.JMZ)|*.JMZ|All Files (*.*)|*.*" \
        filename:"untitled.JMA"
    
    -- Check if user cancelled
    if filePath == undefined then
        return false

    -- Write the JMA file
    local writeResult = writeJmaFile filePath jmaData
    local success = writeResult[1]
    local writeTime = writeResult[2]
    local totalTime = (processingTime + writeTime) / 1000.0

    local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true
    -- Show success message
    if showDialogs and success then
    (
        local fileName = filenameFromPath filePath
        messageBox ("JMA file exported successfully!\n\n" + \
                "File: " + fileName + "\n" + \
                "Frames: " + (jmaData.frameCount as string) + "\n" + \
                "Nodes: " + (jmaData.nodeCount as string) + "\n" + \
                "Time: " + (formattedPrint totalTime format:".3f") + " seconds") \
                title:"Export Complete" \
                beep:false
    )
    
    logger.log "=== EXPORT SUMMARY ==="
    logger.info "Export process completed in {} seconds" args:#(formattedPrint totalTime format:".3f")
    logger.log "Animation Export Complete\n\n"

    clearListener()
    return success
)

-- Run the exporter
exportJmaFile()