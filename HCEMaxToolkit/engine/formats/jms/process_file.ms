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

-- Write JMS header (version and checksum)
fn writeHeader fileStream jmsData =
(
	format "%\n" jmsData.jmsVersion to:fileStream
	format "%\n" jmsData.jmsChecksum to:fileStream
)

-- Write node count and all nodes
fn writeNodes fileStream jmsData =
(
	-- Write node count
	format "%\n" jmsData.nodeCount to:fileStream
	
	-- Write each node
	for node in jmsData.nodes do
	(
		format "%\n" node.nodeName to:fileStream
		format "%\n" node.firstChildNodeIndex to:fileStream
		format "%\n" node.nextSiblingNodeIndex to:fileStream
		format "%\n" (formatRotation node.nodeRotation) to:fileStream
		format "%\n" (formatTranslation node.nodeTranslation) to:fileStream
	)
)

-- Write shader count and all shaders
fn writeShaders fileStream jmsData =
(
	-- Write shader count
	format "%\n" jmsData.shaderCount to:fileStream
	
	-- Write each shader
	for shader in jmsData.shaders do
	(
		format "%\n" shader.shaderName to:fileStream
		format "%\n" shader.bitmapPath to:fileStream
	)
)

-- Write marker count and all markers
fn writeMarkers fileStream jmsData =
(
	-- Write marker count
	format "%\n" jmsData.markerCount to:fileStream
	
	-- Write each marker
	for marker in jmsData.markers do
	(
		format "%\n" marker.markerName to:fileStream
		format "%\n" marker.markerRegion to:fileStream
		format "%\n" marker.parentNodeIndex to:fileStream
		format "%\n" (formatRotation marker.markerRotation) to:fileStream
		format "%\n" (formatTranslation marker.markerTranslation) to:fileStream
		format "%\n" (formatFloat marker.markerRadius) to:fileStream
	)
)

-- Write region count and all regions
fn writeRegions fileStream jmsData =
(
	-- Write region count
	format "%\n" jmsData.regionCount to:fileStream
	
	-- Write each region
	for region in jmsData.regions do
	(
		format "%\n" region.regionName to:fileStream
	)
)

-- Write vertex count and all vertices
fn writeVertices fileStream jmsData =
(
	-- Write vertex count
	format "%\n" jmsData.vertexCount to:fileStream
	
	-- Safety check
	if jmsData.vertices == undefined then
	(
		logger.error "ERROR: jmsData.vertices is undefined!"
		return false
	)
	
	-- Build vertices in larger batches (500000 vertices = 4M lines)
	local batchSize = 500000
	local ss = StringStream ""
	local vertexCount = jmsData.vertices.count
	
	for i = 1 to vertexCount do
	(
		local vertex = jmsData.vertices[i]
		
		-- Safety checks
		if vertex == undefined then
		(
			logger.error "Vertex {} is undefined!" args:#(i)
			continue
		)
		if vertex.texturePos == undefined then
		(
			logger.error "Vertex {} texturePos is undefined!" args:#(i)
			vertex.texturePos = #(0.0, 0.0, 0)
		)
		
		format "%\n" vertex.node0Index to:ss
		format "%\n" (formatTranslation vertex.position) to:ss
		format "%\n" (formatTranslation vertex.normal) to:ss
		format "%\n" vertex.node1Index to:ss
		format "%\n" vertex.node1Weight to:ss
		format "%\n" (formatFloat vertex.texturePos[1]) to:ss
		format "%\n" (formatFloat vertex.texturePos[2]) to:ss
		format "%\n" vertex.texturePos[3] to:ss
		
		-- Write batch when buffer is full
		if (mod i batchSize) == 0 or i == vertexCount then
		(
			format "%" (ss as string) to:fileStream
			ss = StringStream ""
		)
	)
)

-- Write triangle count and all triangles
fn writeTriangles fileStream jmsData =
(
	-- Write triangle count
	format "%\n" jmsData.triangleCount to:fileStream
	
	-- Safety check
	if jmsData.triangles == undefined then
	(
		logger.error "ERROR: jmsData.triangles is undefined!"
		return false
	)
	
	-- Build triangles in larger batches (500000 triangles = 1.5M lines)
	local batchSize = 500000
	local ss = StringStream ""
	local triangleCount = jmsData.triangles.count
	
	for i = 1 to triangleCount do
	(
		local triangle = jmsData.triangles[i]
		
		-- Safety checks
		if triangle == undefined then
		(
			--logger.error "Triangle {} is undefined!" args:#(i)
			continue
		)
		if triangle.vertexIndices == undefined then
		(
			--logger.error "Triangle {} vertexIndices is undefined!" args:#(i)
			continue
		)
		
		format "%\n" triangle.regionIndex to:ss
		format "%\n" triangle.shaderIndex to:ss
		format "%\t%\t%\n" triangle.vertexIndices[1] triangle.vertexIndices[2] triangle.vertexIndices[3] to:ss
		
		-- Write batch when buffer is full
		if (mod i batchSize) == 0 or i == triangleCount then
		(
			format "%" (ss as string) to:fileStream
			ss = StringStream ""
		)
	)
)

-- Write extended metadata section (optional, for enhanced workflows)
fn writeExtendedMetadata fileStream jmsData =
(
	-- Only write if we have smoothing groups
	if jmsData.smoothingGroups == undefined or jmsData.smoothingGroups.count == 0 then
		return ok
	
	-- Check if ANY smoothing group is non-zero (if all are 0, skip extended metadata entirely)
	local hasNonZeroSmoothingGroup = false
	for sg in jmsData.smoothingGroups do
	(
		if sg != 0 then
		(
			hasNonZeroSmoothingGroup = true
			exit
		)
	)
	
	if not hasNonZeroSmoothingGroup then
	(
		--logger.info "No smoothing groups found:"
		--logger.info "Skipping extended metadata"
		return ok
	)
	
	-- Blank line separator
	format "\n" to:fileStream
	
	-- Write smoothing groups
	format ";### SMOOTHING GROUPS ###\n" to:fileStream
	format "%\n" jmsData.smoothingGroups.count to:fileStream
	
	-- Write in batches for performance
	local batchSize = 500000
	local ss = StringStream ""
	
	for i = 1 to jmsData.smoothingGroups.count do
	(
		format "%\n" jmsData.smoothingGroups[i] to:ss
		
		if (mod i batchSize) == 0 or i == jmsData.smoothingGroups.count then
		(
			format "%" (ss as string) to:fileStream
			ss = StringStream ""
		)
	)
)

-------------------------------------------------------
-- MAIN EXPORT FUNCTION
-------------------------------------------------------

-- Write complete JMS file
fn writeJmsFile filePath jmsData =
(
	logger.log "=== WRITING JMS FILE ==="
	logger.info "Output: '{}'" args:#(filePath)
	
	local writeStartTime = timestamp()
	
	-- Create/open file for writing
	local fileStream = createFile filePath
	
	if fileStream == undefined then
	(
		logger.error "Failed to create file: '{}'" args:#(filePath)
		return false
	)
	
	try
	(
		-- Write all sections in order
		--logger.info "Writing header..."
		writeHeader fileStream jmsData
		
		--logger.info "Writing nodes..."
		writeNodes fileStream jmsData
		
		--logger.info "Writing shaders..."
		writeShaders fileStream jmsData
		
		--logger.info "Writing markers..."
		writeMarkers fileStream jmsData
		
		--logger.info "Writing regions..."
		writeRegions fileStream jmsData
		
		--logger.info "Writing vertices..."
		writeVertices fileStream jmsData
		
		--logger.info "Writing triangles..."
		writeTriangles fileStream jmsData
		
		--logger.info "Writing extended metadata..."
		-- Write extended metadata (bitmaps, smoothing groups, etc.)
		writeExtendedMetadata fileStream jmsData
		
		-- Close file
		close fileStream
		
		local writeTime = timestamp() - writeStartTime
		
		logger.info "Version: {}" args:#(jmsData.jmsVersion)
		logger.info "Nodes: {}" args:#(jmsData.nodeCount)
		logger.info "Shaders: {}" args:#(jmsData.shaderCount)
		logger.info "Markers: {}" args:#(jmsData.markerCount)
		logger.info "Regions: {}" args:#(jmsData.regionCount)
		logger.info "Vertices: {}" args:#(jmsData.vertexCount)
		logger.info "Triangles: {}" args:#(jmsData.triangleCount)
		
		-- Check if extended metadata was actually written
		local extendedMetadataMsg = "None"
		if jmsData.smoothingGroups != undefined and jmsData.smoothingGroups.count > 0 then
		(
			-- Check if any smoothing group is non-zero
			local hasNonZero = false
			for sg in jmsData.smoothingGroups do
			(
				if sg != 0 then
				(
					hasNonZero = true
					exit
				)
			)
			if hasNonZero then
				extendedMetadataMsg = "'Written' " + (jmsData.smoothingGroups.count as string) + " smoothing groups"
			else
				extendedMetadataMsg = "'Skipped' (no smoothing groups found)"
		)
		
		logger.info "Extended Metadata: {}" args:#(extendedMetadataMsg)
        logger.info "Total write time: {} ms" args:#(writeTime)
        logger.log "JMS file written successfully\n"
		return #(true, writeTime)
	)
	catch
	(
		logger.error "Exception while writing file: '{}'" args:#((getCurrentException()))
		close fileStream
		return false
	)
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)