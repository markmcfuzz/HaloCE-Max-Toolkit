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

-------------------------------------------------------
-- SECTION READERS
-------------------------------------------------------

-- Read JMS header (version and checksum)
fn readHeader fileStream jmsData =
(
	jmsData.jmsVersion = readIntValue fileStream
	jmsData.jmsChecksum = readIntValue fileStream
	
	logger ("JMS Version: " + jmsData.jmsVersion as string + "\n") logType: #info
	logger ("Checksum: " + jmsData.jmsChecksum as string + "\n") logType: #info
	
	return true
)

-- Read all nodes
fn readNodes fileStream jmsData =
(
	jmsData.nodeCount = readIntValue fileStream
	logger ("Reading " + jmsData.nodeCount as string + " nodes...\n") logType: #info
	
	jmsData.nodes = #()
	
	for i = 1 to jmsData.nodeCount do
	(
		local node = nodes()
		
		node.nodeName = readLineFromStream fileStream
		node.firstChildNodeIndex = readIntValue fileStream
		node.nextSiblingNodeIndex = readIntValue fileStream
		node.nodeRotation = readQuatValue fileStream
		node.nodeTranslation = readVectorValue fileStream
		
		append jmsData.nodes node
	)
	
	-- Auto-detect indexing format and normalize to 0-based
	-- fbx-to-jms and Blender use indices starting at 3 (skipping 0,1,2)
	-- Old exporters use proper 0-based indexing starting at 1
	-- Detection: check if first node's child index is 3 (characteristic of new format)
	if jmsData.nodes.count > 0 then
	(
		-- Detect backward sibling references (fbx-to-jms/Blender format)
		-- These files use normal indices but have sibling chains that point backward
		-- instead of forward, making the traditional two-pass algorithm fail
		local hasBackwardSiblings = false
		
		-- Debug: print first few nodes
		logger "Checking node hierarchy format:\n" logType: #info
		for i = 1 to (amin 5 jmsData.nodeCount) do
		(
			local node = jmsData.nodes[i]
			logger ("  Node % (array %): % - firstChild:% nextSibling:%\n") params:#((i-1), i, node.nodeName, node.firstChildNodeIndex, node.nextSiblingNodeIndex) logType: #info
		)
		
		for i = 1 to jmsData.nodeCount do
		(
			local node = jmsData.nodes[i]
			local siblingIdx = node.nextSiblingNodeIndex
			
			-- If sibling index points to a LOWER index, it's a backward reference
			if siblingIdx >= 0 and siblingIdx < (i - 1) then
			(
				logger ("  -> Backward sibling detected at node % (array %): nextSibling=% < %\n") params:#((i-1), i, siblingIdx, (i-1)) logType: #info
				hasBackwardSiblings = true
				exit
			)
		)
		
		if hasBackwardSiblings then
		(
			logger "Detected backward sibling references (fbx-to-jms/Blender format)\n" logType: #info
			logger "Using simple hierarchy calculation (firstChildNodeIndex only)\n" logType: #info
			
			-- Set flag to use simple hierarchy calculation (no sibling chains)
			jmsData.useSimpleHierarchy = true
		)
		else
		(
			logger "No backward siblings found\n" logType: #info
			logger "Using traditional hierarchy calculation (firstChild + sibling chains)\n" logType: #info
		)
	)
	
	return true
)

-- Read all shaders/materials
fn readShaders fileStream jmsData =
(
	jmsData.shaderCount = readIntValue fileStream
	logger ("Reading " + jmsData.shaderCount as string + " shaders...\n") logType: #info
	
	jmsData.shaders = #()
	
	for i = 1 to jmsData.shaderCount do
	(
		local shader = shaders()
		
		shader.shaderName = readLineFromStream fileStream
		shader.bitmapPath = readLineFromStream fileStream
		
		append jmsData.shaders shader
	)
	
	return true
)

-- Read all markers
fn readMarkers fileStream jmsData =
(
	jmsData.markerCount = readIntValue fileStream
	logger ("Reading " + jmsData.markerCount as string + " markers...\n") logType: #info
	
	jmsData.markers = #()
	
	for i = 1 to jmsData.markerCount do
	(
		local marker = markers()
		
		marker.markerName = readLineFromStream fileStream
		marker.markerRegion = readIntValue fileStream
		marker.parentNodeIndex = readIntValue fileStream
		marker.markerRotation = readQuatValue fileStream
		marker.markerTranslation = readVectorValue fileStream
		marker.markerRadius = readFloatValue fileStream
		
		append jmsData.markers marker
	)
	
	return true
)

-- Read all regions
fn readRegions fileStream jmsData =
(
	jmsData.regionCount = readIntValue fileStream
	logger ("Reading " + jmsData.regionCount as string + " regions...\n") logType: #info
	
	jmsData.regions = #()
	
	for i = 1 to jmsData.regionCount do
	(
		local reg = region()
		reg.regionName = readLineFromStream fileStream
		
		append jmsData.regions reg
	)
	
	return true
)

-- Read all vertices
fn readVertices fileStream jmsData =
(
	jmsData.vertexCount = readIntValue fileStream
	logger ("Reading " + jmsData.vertexCount as string + " vertices...\n") logType: #info
	
	jmsData.vertices = #()
	
	for i = 1 to jmsData.vertexCount do
	(
		local vert = vertices()
		
		vert.node0Index = readIntValue fileStream
		vert.position = readVectorValue fileStream
		vert.normal = readVectorValue fileStream
		vert.node1Index = readIntValue fileStream
		vert.node1Weight = readFloatValue fileStream
		
		-- Read texture coordinates - support both formats:
		-- fbx/Blender format: texU and texV on same line (tab separated)
		-- Our JMS format: texU on one line, texV on next line
		local texU = 0.0
		local texV = 0.0
		
		local uvLine = readLineFromStream fileStream
		if uvLine != undefined then
		(
			local uvValues = filterString uvLine " \t"
			if uvValues.count >= 2 then
			(
				-- fbx/Blender format: both on same line
				texU = uvValues[1] as float
				texV = uvValues[2] as float
			)
			else if uvValues.count == 1 then
			(
				-- Our JMS format: only texU, read texV from next line
				texU = uvValues[1] as float
				local texVLine = readLineFromStream fileStream
				texV = texVLine as float
			)
		)
		
		local texIndex = readIntValue fileStream
		
		vert.texturePos = [texU, texV, texIndex]
		
		append jmsData.vertices vert
	)
	
	return true
)

-- Read all triangles
fn readTriangles fileStream jmsData =
(
	jmsData.triangleCount = readIntValue fileStream
	logger ("Reading " + jmsData.triangleCount as string + " triangles...\n") logType: #info
	
	jmsData.triangles = #()
	
	for i = 1 to jmsData.triangleCount do
	(
		local tri = triangles()
		
		tri.regionIndex = readIntValue fileStream
		tri.shaderIndex = readIntValue fileStream
		
		-- Read the three vertex indices from one line (tab/space separated)
		local indicesLine = readLineFromStream fileStream
		local indices = filterString indicesLine " \t"
		
		if indices.count >= 3 then
			tri.vertexIndices = #(indices[1] as integer, indices[2] as integer, indices[3] as integer)
		else
			tri.vertexIndices = #(0, 0, 0)
		
		append jmsData.triangles tri
	)
	
	return true
)

-- Read extended metadata (optional - smoothing groups)
fn readExtendedMetadata fileStream jmsData =
(
	-- Try to read next line - if EOF or not a metadata section, return
	local nextLine = readLineFromStream fileStream
	if nextLine == undefined then return true
	
	-- Skip blank lines
	while nextLine != undefined and (trimLeft (trimRight nextLine)) == "" do
		nextLine = readLineFromStream fileStream
	
	if nextLine == undefined then return true
	
	-- Check if we have smoothing groups section
	if nextLine == ";### SMOOTHING GROUPS ###" then
	(
		logger "Reading smoothing groups..." logType: #info
		
		local sgCountLine = readLineFromStream fileStream
		logger ("  Count line read: '" + sgCountLine as string + "'\n") logType: #info
		
		if sgCountLine == undefined or sgCountLine == "" then
		(
			logger "Warning: Smoothing groups section header found but no count line" logType: #warning
			return true
		)
		
		-- Parse the count (triangle count)
		local sgCount = 0
		try
		(
			local numStr = trimLeft (trimRight sgCountLine)
			sgCount = numStr as integer

			if sgCount == undefined then sgCount = 0
		)
		catch
		(
			logger ("  Exception parsing count: " + getCurrentException() as string) logType: #warning
			sgCount = 0
		)
		
		logger ("  Parsed count: " + sgCount as string + "\n") logType: #info
		
		if sgCount == 0 then
		(
			logger "Warning: Invalid or zero smoothing group count" logType: #warning
			return true
		)
		
		jmsData.smoothingGroups = #()
		
		logger ("Smoothing group count: " + sgCount as string + "\n") logType: #info
		
		for i = 1 to sgCount do
		(
			local sgLine = readLineFromStream fileStream
			if sgLine == undefined or sgLine == "" then
			(
				logger ("Warning: Expected " + sgCount as string + " smoothing groups but file ended at " + i as string) logType: #warning
				break
			)
			
			local sg = 0
			try
			(
				sg = sgLine as integer
				if sg == undefined then sg = 0
			)
			catch
			(
				sg = 0
			)
			
			append jmsData.smoothingGroups sg
		)
		
		logger ("Total smoothing groups loaded: " + jmsData.smoothingGroups.count as string + "\n") logType: #info
	)
	
	return true
)

-------------------------------------------------------
-- MAIN IMPORT FUNCTION
-------------------------------------------------------

-- Read a complete JMS file and return a jmsFile struct with all data
fn readJmsFile filePath =
(
	logger ("Opening JMS file: " + filePath + "\n") logType: #info
	
	-- Clear token buffer for tab-separated format support
	clearTokenBuffer()
	
	-- Create the data structure
	local jmsData = jmsFile()
	
	-- Open the file for reading
	local fileStream = openFile filePath mode:"r"
	
	if fileStream == undefined then
	(
		logger "Failed to open JMS file!" logType: #error
		return undefined
	)
	
	try
	(
		-- Read each section in order
		--logger "Reading header...\n" logType: #info
		if not (readHeader fileStream jmsData) then throw "Failed to read header"
		
		--logger "Reading nodes...\n" logType: #info
		if not (readNodes fileStream jmsData) then throw "Failed to read nodes"
		
		--logger "Reading shaders...\n" logType: #info
		if not (readShaders fileStream jmsData) then throw "Failed to read shaders"
		
		--logger "Reading markers...\n" logType: #info
		if not (readMarkers fileStream jmsData) then throw "Failed to read markers"
		
		--logger "Reading regions...\n" logType: #info
		if not (readRegions fileStream jmsData) then throw "Failed to read regions"
		
		--logger "Reading vertices...\n" logType: #info
		if not (readVertices fileStream jmsData) then throw "Failed to read vertices"
		
		--logger "Reading triangles...\n" logType: #info
		if not (readTriangles fileStream jmsData) then throw "Failed to read triangles"
		
		-- Try to read extended metadata (optional - don't fail if it doesn't exist)
		logger "Reading extended metadata...\n" logType: #info
		try
		(
			readExtendedMetadata fileStream jmsData
		)
		catch
		(
			logger ("Extended metadata read failed: " + getCurrentException() as string + "\n\n") logType: #warning
		)
		
		logger "JMS file read successfully!" logType: #success
	)
	catch
	(
		logger "\n"
		logger ("Error reading JMS file: " + getCurrentException() as string + "\n") logType: #error
		close fileStream
		return undefined
	)
	
	-- Close the file
	close fileStream
	return jmsData
)

logger "JMS Reader module loaded." logType: #success