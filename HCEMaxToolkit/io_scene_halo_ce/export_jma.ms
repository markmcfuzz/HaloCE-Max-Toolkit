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

-- Get script directory
scriptDir = getFilenamePath (getThisScriptFilename())

-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Load required modules
filein (scriptDir + "modules\\global_functions\\config.ms")
filein (scriptDir + "modules\\global_functions\\utils.ms")
filein (scriptDir + "modules\\file_jma\\jma_struct.ms")
filein (scriptDir + "modules\\file_jma\\validate_scene.ms")
filein (scriptDir + "modules\\file_jms\\process_cat.ms")
filein (scriptDir + "modules\\file_jma\\process_scene.ms")
filein (scriptDir + "modules\\file_jma\\process_file.ms")

fn exportJmaFile =
(
    -- Process scene and extract JMA data
    local jmaData = processSceneForJMA()
    
    -- Check if processing failed
    if jmaData == undefined then
        return false
    
    -- Prompt user for save location
    local filePath = getSaveFileName \
        caption:"Export JMA File" \
        types:"JMA Files (*.JMA)|*.JMA|JMO Files (*.JMO)|*.JMO|JMR Files (*.JMR)|*.JMR|JMM Files (*.JMM)|*.JMM|JMT Files (*.JMT)|*.JMT|JMW Files (*.JMW)|*.JMW|JMZ Files (*.JMZ)|*.JMZ|All Files (*.*)|*.*" \
        filename:"untitled.JMA"
    
    -- Check if user cancelled
    if filePath == undefined then
        return false
    
    -- Write the JMA file
    local success = writeJmaFile filePath jmaData
    
    -- Show success message
    if success then
    (
        local fileName = filenameFromPath filePath
        messageBox ("JMA file exported successfully!\n\n" + \
                "File: " + fileName + "\n" + \
                "Frames: " + (jmaData.frameCount as string) + "\n" + \
                "Nodes: " + (jmaData.nodeCount as string) + "\n") \
                title:"Export Complete" \
                beep:false
    )
    
    clearListener()
    return success
)

-- Run the exporter
exportJmaFile()