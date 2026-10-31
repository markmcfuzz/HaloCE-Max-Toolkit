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

-- Reads JMS files through lua\bridge\jms.lua; returns the jmsFile struct (jms_struct.ms).

-------------------------------------------------------
-- AFTER READING
-------------------------------------------------------

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

-------------------------------------------------------
-- MAIN IMPORT FUNCTION
-------------------------------------------------------

-- Read a complete JMS file and return a jmsFile struct with all data (undefined on error).
-- The file is parsed by lua\bridge\jms.lua (lua\formats\jms.lua); every format the
-- previous MAXScript reader knew is supported: inline (old exporters), toolkit, Blender,
-- invader-recover and fbx-to-jms, plus the smoothing groups section.
fn readJmsFile filePath =
(
	logger.info "Opening JMS file: '{}'" args:#(getFilenameFile filePath + getFilenameType filePath)

	local outPath = (getDir #temp) + "\\hce_jms_read.bin"
	deleteFile outPath
	if not (luaRun "bridge.jms" "read" #(filePath, outPath)) then
	(
		logger.error "Error reading JMS file: '{}'" args:#(filePath)
		return undefined
	)
	local f = luaOpenOutput outPath "jms" 2
	if f == undefined then return undefined

	local jmsData = jmsFile()
	-- Standard files had their rotations normalized by the old reader; inline ones did not
	local normalizeRotations = (luaReadInt f) == 1
	jmsData.jmsVersion = luaReadInt f
	jmsData.jmsChecksum = luaReadInt f

	jmsData.nodeCount = luaReadInt f
	jmsData.nodes = for i = 1 to (luaReadInt f) collect
	(
		local node = nodes()
		node.nodeName = readString f
		node.firstChildNodeIndex = luaReadInt f
		node.nextSiblingNodeIndex = luaReadInt f
		local rot = luaReadQuat f
		node.nodeRotation = if normalizeRotations then normalize rot else rot
		node.nodeTranslation = luaReadPoint3 f
		node
	)

	jmsData.shaderCount = luaReadInt f
	jmsData.shaders = for i = 1 to (luaReadInt f) collect
	(
		local shaderName = readString f
		local bitmapPath = readString f
		shaders shaderName:shaderName bitmapPath:bitmapPath
	)

	jmsData.markerCount = luaReadInt f
	jmsData.markers = for i = 1 to (luaReadInt f) collect
	(
		local marker = markers()
		marker.markerName = readString f
		marker.markerRegion = luaReadInt f
		marker.parentNodeIndex = luaReadInt f
		local rot = luaReadQuat f
		marker.markerRotation = if normalizeRotations then normalize rot else rot
		marker.markerTranslation = luaReadPoint3 f
		marker.markerRadius = readFloat f
		marker
	)

	jmsData.regionCount = luaReadInt f
	jmsData.regions = for i = 1 to (luaReadInt f) collect region regionName:(readString f)

	jmsData.vertexCount = luaReadInt f
	jmsData.vertices = for i = 1 to (luaReadInt f) collect
	(
		local vert = vertices()
		vert.node0Index = luaReadInt f
		vert.position = luaReadPoint3 f
		vert.normal = luaReadPoint3 f
		vert.node1Index = luaReadInt f
		vert.node1Weight = readFloat f
		local u = readFloat f
		local v = readFloat f
		local texIndex = luaReadInt f
		vert.texturePos = [u, v, texIndex]
		vert
	)

	jmsData.triangleCount = luaReadInt f
	jmsData.triangles = for i = 1 to (luaReadInt f) collect
	(
		local tri = triangles()
		tri.regionIndex = luaReadInt f
		tri.shaderIndex = luaReadInt f
		local a = luaReadInt f
		local b = luaReadInt f
		local c = luaReadInt f
		tri.vertexIndices = #(a, b, c)
		tri
	)

	jmsData.smoothingGroups = for i = 1 to (luaReadInt f) collect luaReadInt f
	fclose f
	deleteFile outPath

	logJmsData jmsData
	validateNodeHierarchy jmsData
	jmsData
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
