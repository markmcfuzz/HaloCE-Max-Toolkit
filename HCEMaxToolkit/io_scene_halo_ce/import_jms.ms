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

clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Load required modules
filein (scriptDir + "modules\\global_functions\\config.ms")
filein (scriptDir + "modules\\global_functions\\utils.ms")
filein (scriptDir + "modules\\global_functions\\object_builder.ms")
filein (scriptDir + "modules\\file_jms\\jms_struct.ms")
filein (scriptDir + "modules\\file_jms\\jms_reader.ms")
filein (scriptDir + "modules\\file_jms\\build_materials.ms")
filein (scriptDir + "modules\\file_jms\\build_scene.ms")

-------------------------------------------------------
-- Main Import Function
-------------------------------------------------------

fn importJmsFile jmsFile:undefined =
(
	-- Get JMS file
    if jmsFile == undefined then
    (
	    jmsFile = getOpenFileName \
		    caption:"Select JMS File" \
		    types:"JMS Files (*.JMS)|*.JMS|All Files (*.*)|*.*" \
		    --historyCategory:"HaloCEJMS"
	
	    if jmsFile == undefined then
	    (
	    	logger "Import cancelled by user.\n"
	    	clearListener()
	    	return undefined
	    )
    )

	-- Read the JMS file
	local startTime = timestamp()
	local jmsData = readJmsFile jmsFile
	local readTime = (timestamp() - startTime) / 1000.0
	
	if jmsData == undefined then
	(
		logger "Could not read JMS file\n" logType:#error
		messageBox "Failed to read JMS file!\n\nThe file may be corrupted or not a valid JMS file." title:"Import Failed"
		--clearListener()
		return undefined
	)
	
	--logger "JMS file loaded: % seconds\n" params:#(readTime) logType:#timestamp
	
	-- Build the scene
	local sceneStartTime = timestamp()
	
	-- Build materials
	local t1 = timestamp()
	local materials = buildMaterials jmsData undefined undefined
	logger "Materials created: % ms\n" params:#((timestamp() - t1)) logType:#timestamp
	
	-- Build nodes
	t1 = timestamp()
	local createdNodes = buildNodes jmsData
	logger "Nodes created: % ms\n" params:#((timestamp() - t1)) logType:#timestamp
	
	-- Build markers
	t1 = timestamp()
	local createdMarkers = buildMarkers jmsData createdNodes
	logger "Markers created: % ms\n" params:#((timestamp() - t1)) logType:#timestamp
	
	-- Build geometry
	t1 = timestamp()
	local createdMesh = buildGeometry jmsData createdNodes materials jmsFile
	logger "Geometry created: % ms\n" params:#((timestamp() - t1)) logType:#timestamp
	
	local sceneTime = (timestamp() - sceneStartTime) / 1000.0
	
	logger "\n=== IMPORT COMPLETE ===\n"
	logger "Total scene build time: % seconds\n" params:#(sceneTime) logType:#timestamp
	logger "Total time: % seconds\n" params:#(readTime + sceneTime) logType:#timestamp
	
	completeRedraw()
	
	if createdMesh != undefined then
    (
        local fileName = filenameFromPath jmsFile
        messageBox ("JMS geometry imported successfully!\n\n" + "File: " + (filenameFromPath jmsFile) + "\n") \
                title:"Import Complete" \
                beep:false
    )
	clearListener()
	return jmsData
)

importJmsFile()
