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

-------------------------------------------------------
-- SECTION WRITERS
-------------------------------------------------------

-- Write JMA header (version, frame count, frame rate, actor info, node count, node checksum)
fn writeHeader fileStream jmaData =
(
	format "%\n" jmaData.jmaVersion to:fileStream
	format "%\n" jmaData.frameCount to:fileStream
	format "%\n" jmaData.frameRate to:fileStream
	format "%\n" jmaData.actorNamesIndex to:fileStream
	format "%\n" jmaData.actorNames to:fileStream
	format "%\n" jmaData.nodeCount to:fileStream
	format "%\n" jmaData.nodeChecksum to:fileStream
)

-- Write all nodes
fn writeNodes fileStream jmaData =
(
	-- Write each node
	for node in jmaData.nodes do
	(
		format "%\n" node.nodeName to:fileStream
		format "%\n" node.firstChildNodeIndex to:fileStream
		format "%\n" node.nextSiblingNodeIndex to:fileStream
	)
)

-- Write all keyframes
fn writeKeyframes fileStream jmaData =
(
	-- Build keyframes in batches for better performance
	local batchSize = 500000  -- Process 500000 frames at a time
	local ss = StringStream ""
	local frameCount = jmaData.keyframes.count
	
	for frameIdx = 1 to frameCount do
	(
		local keyframe = jmaData.keyframes[frameIdx]
		local nodeCount = keyframe.nodeTranslation.count
		
		if frameIdx == 1 then
		(
			logger.debug "'frame 1' trans[1] = {} rot[1] = {} scl[1] = {}" args:#(
				keyframe.nodeTranslation[1], keyframe.nodeRotation[1], keyframe.nodeScale[1])
		)
		
		-- Write transform data for each node in this frame
		for nodeIdx = 1 to nodeCount do
		(
			local trans = keyframe.nodeTranslation[nodeIdx]
			local rot = keyframe.nodeRotation[nodeIdx]
			local scl = keyframe.nodeScale[nodeIdx]
			if scl == undefined then scl = 1.0
			
			-- Write translation (x, y, z)
			format "%\t%\t%\n" (formatFloat trans[1]) (formatFloat trans[2]) (formatFloat trans[3]) to:ss
			
			-- Write rotation (i, j, k, w)
			format "%\t%\t%\t%\n" (formatFloat rot[1]) (formatFloat rot[2]) (formatFloat rot[3]) (formatFloat rot[4]) to:ss
			
			-- Write scale (uniform)
			format "%\n" (formatFloat scl) to:ss
		)
		
		-- Write batch when buffer is full or at end
		if (mod frameIdx batchSize) == 0 or frameIdx == frameCount then
		(
			format "%" (ss as string) to:fileStream
			ss = StringStream ""
		)
	)
)

-------------------------------------------------------
-- MAIN EXPORT FUNCTION
-------------------------------------------------------

-- Write complete JMA file
fn writeJmaFile filePath jmaData =
(
	logger.log "=== WRITING JMA FILE ==="
	logger.info "Output: '{}'" args:#(filePath)
	
	local writeStartTime = timestamp()
	
	-- Create/open file for writing
	if doesFileExist filePath do deleteFile filePath
	local fileStream = createFile filePath
	
	--logger.debug "createFile returned: {} " args:#(fileStream, classOf fileStream)
	
	if fileStream == undefined or fileStream == OK then
	(
		logger.error "Failed to create file: '{}'" args:#(filePath)
		return #(false, 0)
	)
	
	try
	(
		-- Write all sections in order
		logger.info "writeHeader starting"
		writeHeader fileStream jmaData
		logger.info "writeNodes starting"
		writeNodes fileStream jmaData
		logger.info "writeKeyframes starting"
		writeKeyframes fileStream jmaData
		logger.info "writeKeyframes done"
		
		-- Close file
		close fileStream
		
		local writeTime = timestamp() - writeStartTime
		
		logger.info "Version: {}" args:#(jmaData.jmaVersion)
		logger.info "Frames: {}" args:#(jmaData.frameCount)
		logger.info "Frame Rate: {}" args:#(jmaData.frameRate)
		logger.info "Nodes: {}" args:#(jmaData.nodeCount)
		logger.info "Actor: '{}'" args:#(jmaData.actorNames)
		--logger.info "JMA file written: {} ms" args:#(writeTime)
		--logger.log "JMA file written successfully\n"
		
		return #(true, writeTime)
	)
	catch
	(
		logger.error "Error writing JMA file: {}" args:#(getCurrentException())
		close fileStream
		return #(false, 0)
	)
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)