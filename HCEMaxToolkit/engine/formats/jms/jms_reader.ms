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
	
	return true
)

-- Read all nodes
fn readNodes fileStream jmsData =
(
	jmsData.nodeCount = readIntValue fileStream
	
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

-- Validate node hierarchy (called AFTER file is closed to avoid file handle conflicts)
fn validateNodeHierarchy jmsData =
(
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
		
		-- Build debug output as string buffer to avoid rapid file open/close
		logger.debug "Checking node hierarchy format:"
		for i = 1 to (amin 5 jmsData.nodeCount) do
		(
			local node = jmsData.nodes[i]
			local line =
				"Node " + ((i-1) as string) +
				" (array " + (i as string) + "): '" +
				node.nodeName +
				"' - firstChild: " +
				(node.firstChildNodeIndex as string) +
				" nextSibling:" +
				(node.nextSiblingNodeIndex as string)
			logger.debug line
		)
		--local nodeDebug = "Checking node hierarchy format:\n"
		--for i = 1 to (amin 5 jmsData.nodeCount) do
		--(
		--	local node = jmsData.nodes[i]
		--	nodeDebug += "  Node " + ((i-1) as string) + " (array " + (i as string) + "): '" + node.nodeName + "' - firstChild: " + (node.firstChildNodeIndex as string) + " nextSibling:" + (node.nextSiblingNodeIndex as string) + "\n"
		--)
		--logger.debug nodeDebug

		
		for i = 1 to jmsData.nodeCount do
		(
			local node = jmsData.nodes[i]
			local siblingIdx = node.nextSiblingNodeIndex
			
			-- If sibling index points to a LOWER index, it's a backward reference
			if siblingIdx >= 0 and siblingIdx < (i - 1) then
			(
				logger.info "-> Backward sibling detected at node {} (array {}): nextSibling={} < {}" args:#((i-1), i, siblingIdx, (i-1))
				hasBackwardSiblings = true
				exit
			)
		)
		
		if hasBackwardSiblings then
		(
			logger.info "Detected backward sibling references (fbx-to-jms/Blender format)"
			logger.info "Using simple hierarchy calculation (firstChildNodeIndex only)"
			
			-- Set flag to use simple hierarchy calculation (no sibling chains)
			jmsData.useSimpleHierarchy = true
		)
		else
		(
			logger.info "No backward siblings found"
			logger.info "Using traditional hierarchy calculation (firstChild + sibling chains)"
		)
	)
	
	return true
)

-- Log JMS data (called AFTER file is closed to avoid file handle conflicts)
fn logJmsData jmsData =
(
	logger.log "=== READING JMS ==="
	logger.info "JMS Version: {}" args:#(jmsData.jmsVersion)
	logger.info "Checksum: {}" args:#(jmsData.jmsChecksum)
	logger.info "Reading {} nodes" args:#(jmsData.nodeCount)
	logger.info "Reading {} shaders" args:#(jmsData.shaderCount)
	logger.info "Reading {} markers" args:#(jmsData.markerCount)
	logger.info "Reading {} regions" args:#(jmsData.regionCount)
	logger.info "Reading {} vertices" args:#(jmsData.vertexCount)
	logger.info "Reading {} triangles" args:#(jmsData.triangleCount)
	if jmsData.smoothingGroups.count > 0 then
		logger.info "Reading {} smoothing groups" args:#(jmsData.smoothingGroups.count)
)

-- Read all shaders/materials
fn readShaders fileStream jmsData =
(
	jmsData.shaderCount = readIntValue fileStream
	
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
		local sgCountLine = readLineFromStream fileStream
		
		if sgCountLine == undefined or sgCountLine == "" then
			return true
		
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
			sgCount = 0
		)
		
		if sgCount == 0 then
			return true
		
		jmsData.smoothingGroups = #()
		
		for i = 1 to sgCount do
		(
			local sgLine = readLineFromStream fileStream
			if sgLine == undefined or sgLine == "" then
				break
			
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
	)
	
	return true
)

-------------------------------------------------------
-- MAIN IMPORT FUNCTION
-------------------------------------------------------

-- Read a complete JMS file and return a jmsFile struct with all data
fn readJmsFile filePath =
(
	logger.info "Opening JMS file: '{}'" args:#(getFilenameFile filePath + getFilenameType filePath)
	logger.info "JMS opened successfully!\n"
	-- Clear token buffer for tab-separated format support
	clearTokenBuffer()
	
	-- Create the data structure
	local jmsData = jmsFile()
	
	-- Open the file for reading
	local fileStream = openFile filePath mode:"r"
	
	if fileStream == undefined then
	(
		logger.error "Failed to open JMS file!"
		return undefined
	)
	
	try
	(
		-- Read each section in order
		--logger.info "Reading header..."
		if not (readHeader fileStream jmsData) then throw "Failed to read header"
		
		--logger.info "Reading nodes..."
		if not (readNodes fileStream jmsData) then throw "Failed to read nodes"
		
		--logger.info "Reading shaders..."
		if not (readShaders fileStream jmsData) then throw "Failed to read shaders"
		
		--logger.info "Reading markers..."
		if not (readMarkers fileStream jmsData) then throw "Failed to read markers"
		
		--logger.info "Reading regions..."
		if not (readRegions fileStream jmsData) then throw "Failed to read regions"
		
		--logger.info "Reading vertices..."
		if not (readVertices fileStream jmsData) then throw "Failed to read vertices"
		
		--logger.info "Reading triangles..."
		if not (readTriangles fileStream jmsData) then throw "Failed to read triangles"
		
		-- Try to read extended metadata (optional - don't fail if it doesn't exist)
		try
		(
			readExtendedMetadata fileStream jmsData
		)
		catch
		(
			-- Extended metadata is optional, so don't fail
		)
		
		-- Close the file before logging (to avoid file handle conflicts)
		close fileStream
		
		-- Log all JMS data after file is closed
		logJmsData jmsData
		
		-- Validate node hierarchy AFTER closing file to avoid file handle conflicts
		validateNodeHierarchy jmsData
		
		--logger.info "JMS file read successfully!"
	)
	catch
	(
		-- Close file before logging to avoid file handle conflicts
		close fileStream
		logger.error "Error reading JMS file: {}" args:#(getCurrentException() as string)
		return undefined
	)
	return jmsData
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)