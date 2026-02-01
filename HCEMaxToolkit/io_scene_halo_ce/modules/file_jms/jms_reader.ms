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
	
	logger ("JMS Version: " + jmsData.jmsVersion as string) logType: #info
	logger ("Checksum: " + jmsData.jmsChecksum as string) logType: #info
	
	return true
)

-- Read all nodes
fn readNodes fileStream jmsData =
(
	jmsData.nodeCount = readIntValue fileStream
	logger ("Reading " + jmsData.nodeCount as string + " nodes...") logType: #info
	
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
	
	return true
)

-- Read all shaders/materials
fn readShaders fileStream jmsData =
(
	jmsData.shaderCount = readIntValue fileStream
	logger ("Reading " + jmsData.shaderCount as string + " shaders...") logType: #info
	
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
	logger ("Reading " + jmsData.markerCount as string + " markers...") logType: #info
	
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
	logger ("Reading " + jmsData.regionCount as string + " regions...") logType: #info
	
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
	logger ("Reading " + jmsData.vertexCount as string + " vertices...") logType: #info
	
	jmsData.vertices = #()
	
	for i = 1 to jmsData.vertexCount do
	(
		local vert = vertices()
		
		vert.node0Index = readIntValue fileStream
		vert.position = readVectorValue fileStream
		vert.normal = readVectorValue fileStream
		vert.node1Index = readIntValue fileStream
		vert.node1Weight = readFloatValue fileStream
		
		-- Read texture coordinates (U, V, and texture index/unknown)
		local texU = readFloatValue fileStream
		local texV = readFloatValue fileStream
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
	logger ("Reading " + jmsData.triangleCount as string + " triangles...") logType: #info
	
	jmsData.triangles = #()
	
	for i = 1 to jmsData.triangleCount do
	(
		local tri = triangles()
		
		tri.regionIndex = readIntValue fileStream
		tri.shaderIndex = readIntValue fileStream
		
		-- Read the three vertex indices (can be space or tab separated on one line)
		local line = readLineFromStream fileStream
		local indices = filterString line " \t"
		
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
		logger ("  Count line read: '" + sgCountLine as string + "'") logType: #info
		
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
		
		logger ("  Parsed count: " + sgCount as string) logType: #info
		
		if sgCount == 0 then
		(
			logger "Warning: Invalid or zero smoothing group count" logType: #warning
			return true
		)
		
		jmsData.smoothingGroups = #()
		
		logger ("Smoothing group count: " + sgCount as string) logType: #info
		
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
		
		logger ("Total smoothing groups loaded: " + jmsData.smoothingGroups.count as string) logType: #info
	)
	
	return true
)

-------------------------------------------------------
-- MAIN IMPORT FUNCTION
-------------------------------------------------------

-- Read a complete JMS file and return a jmsFile struct with all data
fn readJmsFile filePath =
(
	logger ("Opening JMS file: " + filePath) logType: #info
	
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
		logger "Reading header..." logType: #info
		if not (readHeader fileStream jmsData) then throw "Failed to read header"
		
		logger "Reading nodes..." logType: #info
		if not (readNodes fileStream jmsData) then throw "Failed to read nodes"
		
		logger "Reading shaders..." logType: #info
		if not (readShaders fileStream jmsData) then throw "Failed to read shaders"
		
		logger "Reading markers..." logType: #info
		if not (readMarkers fileStream jmsData) then throw "Failed to read markers"
		
		logger "Reading regions..." logType: #info
		if not (readRegions fileStream jmsData) then throw "Failed to read regions"
		
		logger "Reading vertices..." logType: #info
		if not (readVertices fileStream jmsData) then throw "Failed to read vertices"
		
		logger "Reading triangles..." logType: #info
		if not (readTriangles fileStream jmsData) then throw "Failed to read triangles"
		
		-- Try to read extended metadata (optional - don't fail if it doesn't exist)
		logger "Reading extended metadata..." logType: #info
		try
		(
			readExtendedMetadata fileStream jmsData
		)
		catch
		(
			logger ("Extended metadata read failed: " + getCurrentException() as string) logType: #warning
		)
		
		logger "JMS file read successfully!" logType: #success
	)
	catch
	(
		logger ("Error reading JMS file: " + getCurrentException()) logType: #error
		close fileStream
		return undefined
	)
	
	-- Close the file
	close fileStream
	return jmsData
)

logger "JMS Reader module loaded." logType: #success