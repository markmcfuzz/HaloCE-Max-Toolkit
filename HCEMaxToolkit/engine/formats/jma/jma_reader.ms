------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

-- Supported JMA version
global SUPPORTED_JMA_VERSION = 16392

-------------------------------------------------------
-- SECTION READERS
-------------------------------------------------------

-- Read JMA header (version, frame count, frame rate, actor info, node info)
fn readJmaHeader fileStream jmaData =
(
	jmaData.jmaVersion = readIntValue fileStream
	
	-- Validate version
	if jmaData.jmaVersion != SUPPORTED_JMA_VERSION then
	(
		logger.error "Unsupported JMA version: {}" args:#(jmaData.jmaVersion)
		logger.error "Expected version: {}" args:#(SUPPORTED_JMA_VERSION)
		return false
	)
	
	jmaData.frameCount = readIntValue fileStream
	jmaData.frameRate = readIntValue fileStream
	jmaData.actorNamesIndex = readIntValue fileStream
	jmaData.actorNames = readLineFromStream fileStream
	jmaData.nodeCount = readIntValue fileStream
	jmaData.nodeChecksum = readIntValue fileStream
	
	logger.info "JMA Version: {}" args:#(jmaData.jmaVersion)
	logger.info "Frame Count: {}" args:#(jmaData.frameCount)
	logger.info "Frame Rate: {}" args:#(jmaData.frameRate)
	logger.info "Actor Count: {}" args:#(jmaData.actorNamesIndex)
	logger.info "Actor Name: {}" args:#(jmaData.actorNames)
	logger.info "Node Count: {}" args:#(jmaData.nodeCount)
	logger.info "Node Checksum: {}" args:#(jmaData.nodeChecksum)
	
	return true
)

-- Read all nodes (name, first child index, next sibling index)
fn readJmaNodes fileStream jmaData =
(
	logger.info "Reading {} nodes..." args:#(jmaData.nodeCount)
	
	jmaData.nodes = #()
	
	for i = 1 to jmaData.nodeCount do
	(
		local node = jmaNodes()
		
		node.nodeName = readLineFromStream fileStream
		node.firstChildNodeIndex = readIntValue fileStream
		node.nextSiblingNodeIndex = readIntValue fileStream
		
		append jmaData.nodes node
	)
	
	return true
)

-- Read all frames and keyframe data
fn readJmaFrames fileStream jmaData =
(
	logger.info "Reading {} frames..." args:#(jmaData.frameCount)
	
	jmaData.frames = #()
	
	for f = 1 to jmaData.frameCount do
	(
		local frameData = jmaFrameData()
		frameData.nodeFrames = #()
		
		for n = 1 to jmaData.nodeCount do
		(
			local nodeFrame = jmaNodeFrame()
			
			nodeFrame.translation = readVectorValue fileStream
			nodeFrame.rotation = readQuatValue fileStream
			nodeFrame.scale = readFloatValue fileStream
			
			append frameData.nodeFrames nodeFrame
		)
		
		append jmaData.frames frameData
	)
	
	return true
)

-------------------------------------------------------
-- MAIN READ FUNCTION
-------------------------------------------------------

-- Read a complete JMA file and return a jmaFile struct with all data
fn readJmaFile filePath =
(
	logger.log "=== READING JMA FILE ==="
	logger.info "File: '{}'" args:#(filePath)
	
	-- Create the data structure
	local jmaData = jmaFile()
	
	-- Open the file for reading
	local fileStream = openFile filePath mode:"r"
	
	if fileStream == undefined then
	(
		logger.error "Failed to open JMA file: '{}'" args:#(filePath)
		return undefined
	)
	
	try
	(
		-- Read header
		if not (readJmaHeader fileStream jmaData) then
			throw "Failed to read header - unsupported file version"
		
		-- Read nodes
		if not (readJmaNodes fileStream jmaData) then
			throw "Failed to read nodes"
		
		-- Read frame data
		if not (readJmaFrames fileStream jmaData) then
			throw "Failed to read frames"
		
		logger.info "JMA file read successfully!\n"
	)
	catch
	(
		logger.error "Error reading JMA file: {}" args:#(getCurrentException())
		close fileStream
		return undefined
	)
	
	-- Close the file
	close fileStream
	return jmaData
)
scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)