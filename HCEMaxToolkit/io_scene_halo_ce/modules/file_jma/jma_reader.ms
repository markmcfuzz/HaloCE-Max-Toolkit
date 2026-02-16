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
		logger "Unsupported JMA version: %\n" params:#(jmaData.jmaVersion) logType:#error
		logger "Expected version: %\n" params:#(SUPPORTED_JMA_VERSION) logType:#error
		return false
	)
	
	jmaData.frameCount = readIntValue fileStream
	jmaData.frameRate = readIntValue fileStream
	jmaData.actorNamesIndex = readIntValue fileStream
	jmaData.actorNames = readLineFromStream fileStream
	jmaData.nodeCount = readIntValue fileStream
	jmaData.nodeChecksum = readIntValue fileStream
	
	logger "JMA Version: %\n" params:#(jmaData.jmaVersion) logType:#info
	logger "Frame Count: %\n" params:#(jmaData.frameCount) logType:#info
	logger "Frame Rate: %\n" params:#(jmaData.frameRate) logType:#info
	logger "Actor Count: %\n" params:#(jmaData.actorNamesIndex) logType:#info
	logger "Actor Name: %\n" params:#(jmaData.actorNames) logType:#info
	logger "Node Count: %\n" params:#(jmaData.nodeCount) logType:#info
	logger "Node Checksum: %\n" params:#(jmaData.nodeChecksum) logType:#info
	
	return true
)

-- Read all nodes (name, first child index, next sibling index)
fn readJmaNodes fileStream jmaData =
(
	logger "Reading % nodes...\n" params:#(jmaData.nodeCount) logType:#info
	
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
	logger "Reading % frames...\n" params:#(jmaData.frameCount) logType:#info
	
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
	logger "\n=== READING JMA FILE ===\n"
	logger "File: %\n" params:#(filePath) logType:#info
	
	-- Create the data structure
	local jmaData = jmaFile()
	
	-- Open the file for reading
	local fileStream = openFile filePath mode:"r"
	
	if fileStream == undefined then
	(
		logger "Failed to open JMA file: %\n" params:#(filePath) logType:#error
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
		
		logger "\nJMA file read successfully!\n" logType:#success
	)
	catch
	(
		logger "Error reading JMA file: %\n" params:#(getCurrentException()) logType:#error
		close fileStream
		return undefined
	)
	
	-- Close the file
	close fileStream
	return jmaData
)

logger "JMA Reader module loaded.\n" logType:#success
