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
-- FORMAT DETECTION
-------------------------------------------------------

-- Detect JMS format type based on header structure
fn detectJMSFormat firstLine =
(
	if firstLine == undefined then
		return #unknown
	
	local parts = filterString firstLine " \t"
	
	-- Inline format: header has all data on one line (version checksum nodeCount)
	-- Standard format: header has just version on first line
	if parts.count >= 3 then
		return #inline
	else
		return #standard
)

-------------------------------------------------------
-- INLINE FORMAT READERS (Old JMS Exporters)
-------------------------------------------------------

-- Read inline header (version, checksum, nodeCount all on one line)
fn readHeaderInline firstLine jmsData =
(
	local parts = filterString firstLine " \t"
	if parts.count < 3 then
		return false
	
	jmsData.jmsVersion = parts[1] as integer
	jmsData.jmsChecksum = parts[2] as integer
	jmsData.nodeCount = parts[3] as integer
	
	return true
)

-- Read nodes in inline format (all node data on one line)
fn readNodesInline fileStream jmsData =
(
	jmsData.nodes = #()
	
	for i = 1 to jmsData.nodeCount do
	(
		local line = readLineFromStream fileStream
		local parts = filterString line "\t"  -- Tab-separated only (preserve spaces in names)
		
		if parts.count >= 10 then
		(
			local node = nodes()
			
			node.nodeName = parts[1]
			node.firstChildNodeIndex = parts[2] as integer
			node.nextSiblingNodeIndex = parts[3] as integer
			node.nodeRotation = quat (parts[4] as float) (parts[5] as float) (parts[6] as float) (parts[7] as float)
			node.nodeTranslation = [parts[8] as float, parts[9] as float, parts[10] as float]
			
			append jmsData.nodes node
		)
	)
	
	return true
)

-- Read shaders in inline format (name and path on one line)
fn readShadersInline fileStream jmsData =
(
	local countLine = readLineFromStream fileStream
	jmsData.shaderCount = countLine as integer
	
	jmsData.shaders = #()
	
	for i = 1 to jmsData.shaderCount do
	(
		local line = readLineFromStream fileStream
		local parts = filterString line "\t"  -- Tab-separated only (preserve spaces in names)
		
		if parts.count >= 2 then
		(
			local shader = shaders()
			
			shader.shaderName = parts[1]
			shader.bitmapPath = parts[2]
			
			append jmsData.shaders shader
		)
	)
	
	return true
)

-- Read markers in inline format (all marker data on one line)
fn readMarkersInline fileStream jmsData =
(
	local countLine = readLineFromStream fileStream
	jmsData.markerCount = countLine as integer
	
	jmsData.markers = #()
	
	for i = 1 to jmsData.markerCount do
	(
		local line = readLineFromStream fileStream
		local parts = filterString line "\t"  -- Tab-separated only (preserve spaces in names)
		
		if parts.count >= 11 then
		(
			local marker = markers()
			
			marker.markerName = parts[1]
			marker.markerRegion = parts[2] as integer
			marker.parentNodeIndex = parts[3] as integer
			marker.markerRotation = quat (parts[4] as float) (parts[5] as float) (parts[6] as float) (parts[7] as float)
			marker.markerTranslation = [parts[8] as float, parts[9] as float, parts[10] as float]
			marker.markerRadius = parts[11] as float
			
			append jmsData.markers marker
		)
	)
	
	return true
)

-- Read regions in inline format (same as standard - one per line)
fn readRegionsInline fileStream jmsData =
(
	local countLine = readLineFromStream fileStream
	jmsData.regionCount = countLine as integer
	
	jmsData.regions = #()
	
	for i = 1 to jmsData.regionCount do
	(
		local reg = region()
		
		local regionName = readLineFromStream fileStream
		while regionName != undefined and regionName == "" do
			regionName = readLineFromStream fileStream
		
		reg.regionName = regionName
		
		append jmsData.regions reg
	)
	
	return true
)

-- Read vertices in inline format (all vertex data on one line)
fn readVerticesInline fileStream jmsData =
(
	local countLine = readLineFromStream fileStream
	jmsData.vertexCount = countLine as integer
	
	jmsData.vertices = #()
	
	for i = 1 to jmsData.vertexCount do
	(
		local line = readLineFromStream fileStream
		local parts = filterString line "\t"  -- Tab-separated only
		
		-- Ultra-inline detection: if we have WAY more than 12 fields, multiple vertices are on one line
		if i == 1 and parts.count > 50 then
		(
			logger.error "========================================================================================"
			logger.error "ULTRA-INLINE FORMAT DETECTED (Example 2)"
			logger.error "========================================================================================"
			logger.error "This JMS file has ALL vertices on a single line, which is not currently supported."
			logger.error ""
			logger.error "Please use the JMS Formatter tool to convert this file first:"
			logger.error "  Tools > HCE Max Toolkit > JMS Formatter"
			logger.error ""
			logger.error "This will convert the file to a readable format."
			logger.error "========================================================================================"
			return false
		)
		
		if parts.count >= 12 then
		(
			local vert = vertices()
			
			vert.node0Index = parts[1] as integer
			vert.position = [parts[2] as float, parts[3] as float, parts[4] as float]
			vert.normal = [parts[5] as float, parts[6] as float, parts[7] as float]
			vert.node1Index = parts[8] as integer
			vert.node1Weight = parts[9] as float
			vert.texturePos = [parts[10] as float, parts[11] as float, parts[12] as integer]
			
			append jmsData.vertices vert
		)
	)
	
	return true
)

-- Read triangles in inline format (all triangle data on one line)
fn readTrianglesInline fileStream jmsData =
(
	local countLine = readLineFromStream fileStream
	jmsData.triangleCount = countLine as integer
	
	jmsData.triangles = #()
	
	for i = 1 to jmsData.triangleCount do
	(
		local line = readLineFromStream fileStream
		local parts = filterString line "\t"  -- Tab-separated only
		
		if parts.count >= 5 then
		(
			local tri = triangles()
			
			-- Handle "undefined" as 0 for region index (default to first region)
			local regionStr = parts[1]
			if regionStr != undefined and (toLower regionStr) == "undefined" then
				tri.regionIndex = 0
			else
				tri.regionIndex = parts[1] as integer
			
			tri.shaderIndex = parts[2] as integer
			tri.vertexIndices = #(parts[3] as integer, parts[4] as integer, parts[5] as integer)
			
			append jmsData.triangles tri
		)
	)
	
	return true
)

-------------------------------------------------------
-- STANDARD FORMAT READERS (Current Modern Formats)
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
		
		-- Skip blank lines (some exporters like invader-recover add empty lines between regions)
		local regionName = readLineFromStream fileStream
		while regionName != undefined and regionName == "" do
			regionName = readLineFromStream fileStream
		
		reg.regionName = regionName
		
		append jmsData.regions reg
	)
	
	return true
)

-- Read all vertices
fn readVertices fileStream jmsData =
(
	-- Skip blank lines before vertex count (invader-recover adds blank line after regions)
	local line = readLineFromStream fileStream
	while line != undefined and line == "" do
		line = readLineFromStream fileStream
	
	-- Parse vertex count from the non-blank line
	jmsData.vertexCount = line as integer
	
	jmsData.vertices = #()
	
	for i = 1 to jmsData.vertexCount do
	(
		local vert = vertices()
		
		vert.node0Index = readIntValue fileStream
		vert.position = readVectorValue fileStream
		vert.normal = readVectorValue fileStream
		vert.node1Index = readIntValue fileStream
		vert.node1Weight = readFloatValue fileStream
		
		-- Read texture coordinates - support three formats:
		-- invader-recover format: texU, texV, and texIndex all on same line (tab separated)
		-- fbx/Blender format: texU and texV on same line (tab separated), texIndex on next line
		-- HCE Max Toolkit format: texU on one line, texV on next line, texIndex on third line
		local texU = 0.0
		local texV = 0.0
		local texIndex = 0
		
		local uvLine = readLineFromStream fileStream
		if uvLine != undefined then
		(
			local uvValues = filterString uvLine " \t"
			if uvValues.count >= 3 then
			(
				-- invader-recover format: all three values on same line
				texU = uvValues[1] as float
				texV = uvValues[2] as float
				texIndex = uvValues[3] as integer
			)
			else if uvValues.count == 2 then
			(
				-- fbx/Blender format: texU and texV on same line, texIndex on next
				texU = uvValues[1] as float
				texV = uvValues[2] as float
				texIndex = readIntValue fileStream
			)
			else if uvValues.count == 1 then
			(
				-- HCE Max Toolkit format: each on separate lines
				texU = uvValues[1] as float
				local texVLine = readLineFromStream fileStream
				texV = texVLine as float
				texIndex = readIntValue fileStream
			)
		)
		
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
		-- Detect format by reading first line
		local firstLine = readLineFromStream fileStream
		local format = detectJMSFormat firstLine
		
		logger.debug "Detected format: {}" args:#(format as string)
		
		-- Route to appropriate readers based on format
		if format == #inline then
		(
			-- INLINE FORMAT (old JMS exporters)
			logger.debug "Using inline format readers"
			
			if not (readHeaderInline firstLine jmsData) then throw "Failed to read inline header"
			if not (readNodesInline fileStream jmsData) then throw "Failed to read inline nodes"
			if not (readShadersInline fileStream jmsData) then throw "Failed to read inline shaders"
			if not (readMarkersInline fileStream jmsData) then throw "Failed to read inline markers"
			if not (readRegionsInline fileStream jmsData) then throw "Failed to read inline regions"
			if not (readVerticesInline fileStream jmsData) then throw "Failed to read inline vertices"
			if not (readTrianglesInline fileStream jmsData) then throw "Failed to read inline triangles"
		)
		else
		(
			-- STANDARD FORMAT (HCE Max Toolkit, Blender, invader-recover)
			logger.debug "Using standard format readers"
			
			-- Reset stream to beginning for standard reading
			seek fileStream 0
			
			if not (readHeader fileStream jmsData) then throw "Failed to read header"
			if not (readNodes fileStream jmsData) then throw "Failed to read nodes"
			if not (readShaders fileStream jmsData) then throw "Failed to read shaders"
			if not (readMarkers fileStream jmsData) then throw "Failed to read markers"
			if not (readRegions fileStream jmsData) then throw "Failed to read regions"
			if not (readVertices fileStream jmsData) then throw "Failed to read vertices"
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