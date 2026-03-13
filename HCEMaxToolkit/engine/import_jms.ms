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

logger.log "=== IMPORTING JMS ==="

-- Load required modules
include "builders\\helper_builder.ms"
include "formats\\jms\\jms_struct.ms"
include "formats\\jms\\jms_reader.ms"
include "builders\\jms\\build_materials.ms"
include "builders\\jms\\build_scene.ms"

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
			historyCategory:"HaloCEJMS"
	
		if jmsFile == undefined then
		(
			logger.warn "Import cancelled by user.\n"
			--clearListener()
			return undefined
		)
    )

	-- Read the JMS file
	local startTime = timestamp()
	local jmsData = readJmsFile jmsFile
	local readTime = (timestamp() - startTime) / 1000.0
	
	if jmsData == undefined then
	(
		logger.error "Could not read JMS file\n"
		messageBox "Failed to read JMS file!\n\nThe file may be corrupted or not a valid JMS file." title:"Import Failed"
		--clearListener()
		return undefined
	)
	
	logger.info "JMS file readed: {} seconds" args:#(readTime)
	logger.info "JMS file read successfully!\n"
	
	logger.log "=== BUILDING JMS ==="

	-- Build the scene
	local sceneStartTime = timestamp()
	
	-- Build materials
	local t1 = timestamp()
	local materials = buildMaterials jmsData undefined undefined
	logger.info "Materials created: {} ms" args:#((timestamp() - t1) / 1000.0)
	
	-- Build nodes
	t1 = timestamp()
	local createdNodes = buildNodes jmsData
	logger.info "Nodes created: {} ms" args:#((timestamp() - t1) / 1000.0)
	
	-- Build markers
	t1 = timestamp()
	local createdMarkers = buildMarkers jmsData createdNodes
	logger.info "Markers created: {} ms" args:#((timestamp() - t1) / 1000.0)
	
	-- Build geometry
	t1 = timestamp()
	local createdMesh = buildGeometry jmsData createdNodes materials jmsFile
	logger.info "Geometry created: {} ms" args:#((timestamp() - t1) / 1000.0)
	local sceneTime = (timestamp() - sceneStartTime) / 1000.0
	logger.info "Total scene build time: {} seconds" args:#(sceneTime)
	logger.info "JMS built successfully!\n"
	
	logger.log "=== IMPORT SUMMARY ==="
	logger.info "Total time: {} seconds\n\n" args:#(readTime + sceneTime)
	
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
