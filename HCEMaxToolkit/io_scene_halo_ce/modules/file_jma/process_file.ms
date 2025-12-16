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
	local batchSize = 100  -- Process 100 frames at a time
	local ss = StringStream ""
	local frameCount = jmaData.keyframes.count
	
	for frameIdx = 1 to frameCount do
	(
		local keyframe = jmaData.keyframes[frameIdx]
		local nodeCount = keyframe.nodeTranslation.count
		
		-- Write transform data for each node in this frame
		for nodeIdx = 1 to nodeCount do
		(
			local trans = keyframe.nodeTranslation[nodeIdx]
			local rot = keyframe.nodeRotation[nodeIdx]
			local scl = keyframe.nodeScale[nodeIdx]
			
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
	logger "\n=== WRITING JMA FILE ===\n"
	logger "Output: %\n" params:#(filePath) logType:#info
	
	local writeStartTime = timestamp()
	
	-- Create/open file for writing
	local fileStream = createFile filePath
	
	if fileStream == undefined then
	(
		logger "Failed to create file: %\n" params:#(filePath) logType:#error
		return false
	)
	
	try
	(
		-- Write all sections in order
		writeHeader fileStream jmaData
		writeNodes fileStream jmaData
		writeKeyframes fileStream jmaData
		
		-- Close file
		close fileStream
		
		local writeTime = timestamp() - writeStartTime
		
		logger "JMA file written successfully\n" logType:#success
		logger "    Version: %\n" params:#(jmaData.jmaVersion) logType:#info
		logger "    Frames: %\n" params:#(jmaData.frameCount) logType:#info
		logger "    Frame Rate: %\n" params:#(jmaData.frameRate) logType:#info
		logger "    Nodes: %\n" params:#(jmaData.nodeCount) logType:#info
		logger "    Actor: %\n" params:#(jmaData.actorNames) logType:#info
		
		format "TOTAL WRITE TIME: % ms\n" writeTime
		format "=============================\n\n"
		
		return true
	)
	catch
	(
		logger "Error writing JMA file: %\n" params:#(getCurrentException()) logType:#error
		close fileStream
		return false
	)
)

logger "JMA Process File loaded.\n" logType:#success