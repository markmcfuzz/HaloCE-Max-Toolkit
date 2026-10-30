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

-- Writes JMS files through formats\jms\jms_cli.lua (formats\jms\jms.lua): the data goes to Lua
-- as binary and Lua writes the same text the previous MAXScript writer did.

-- lua_bridge.ms is loaded by init.ms; reload it if Max still runs an older toolkit.
global luaRunScript
if luaRunScript == undefined and rootEngine != undefined do
	fileIn (rootEngine + "shared\\utils\\lua_bridge.ms")

-- True when the smoothing groups section is written (setting on and any group non-zero)
fn jmsWritesSmoothingGroups jmsData =
(
	if not (configManager.getBool "export_jms_jma" "export_extended_metadata" true) then return false
	if jmsData.smoothingGroups == undefined then return false
	local anyGroup = false
	for sg in jmsData.smoothingGroups while not anyGroup do anyGroup = sg != 0
	anyGroup
)

-- Binary for jms_cli.lua "write". Values printed with format "%" go with their type
-- (luaWriteValue); the others are floats printed with 6 decimals.
fn writeJmsForLua f jmsData =
(
	luaWriteString f "jms"
	luaWriteInt f 1
	luaWriteValue f jmsData.jmsVersion
	luaWriteValue f jmsData.jmsChecksum

	luaWriteValue f jmsData.nodeCount
	luaWriteInt f jmsData.nodes.count
	for node in jmsData.nodes do
	(
		luaWriteValue f node.nodeName
		luaWriteValue f node.firstChildNodeIndex
		luaWriteValue f node.nextSiblingNodeIndex
		for i = 1 to 4 do luaWriteFloat f node.nodeRotation[i]
		for i = 1 to 3 do luaWriteFloat f node.nodeTranslation[i]
	)

	luaWriteValue f jmsData.shaderCount
	luaWriteInt f jmsData.shaders.count
	for shader in jmsData.shaders do
	(
		luaWriteValue f shader.shaderName
		luaWriteValue f shader.bitmapPath
	)

	luaWriteValue f jmsData.markerCount
	luaWriteInt f jmsData.markers.count
	for marker in jmsData.markers do
	(
		luaWriteValue f marker.markerName
		luaWriteValue f marker.markerRegion
		luaWriteValue f marker.parentNodeIndex
		for i = 1 to 4 do luaWriteFloat f marker.markerRotation[i]
		for i = 1 to 3 do luaWriteFloat f marker.markerTranslation[i]
		luaWriteFloat f marker.markerRadius
	)

	luaWriteValue f jmsData.regionCount
	luaWriteInt f jmsData.regions.count
	for reg in jmsData.regions do luaWriteValue f reg.regionName

	-- Undefined vertices / triangles were skipped by the previous writer too
	luaWriteValue f jmsData.vertexCount
	if jmsData.vertices == undefined then
	(
		logger.error "ERROR: jmsData.vertices is undefined!"
		luaWriteInt f 0
	)
	else
	(
		local verts = #()
		for v in jmsData.vertices do if v != undefined do append verts v
		luaWriteInt f verts.count
		for vertex in verts do
		(
			local tex = if vertex.texturePos == undefined then #(0.0, 0.0, 0) else vertex.texturePos
			luaWriteValue f vertex.node0Index
			for i = 1 to 3 do luaWriteFloat f vertex.position[i]
			for i = 1 to 3 do luaWriteFloat f vertex.normal[i]
			luaWriteValue f vertex.node1Index
			luaWriteValue f vertex.node1Weight
			luaWriteFloat f tex[1]
			luaWriteFloat f tex[2]
			luaWriteValue f tex[3]
		)
	)

	luaWriteValue f jmsData.triangleCount
	if jmsData.triangles == undefined then
	(
		logger.error "ERROR: jmsData.triangles is undefined!"
		luaWriteInt f 0
	)
	else
	(
		local tris = #()
		for t in jmsData.triangles do if t != undefined and t.vertexIndices != undefined do append tris t
		luaWriteInt f tris.count
		for tri in tris do
		(
			luaWriteValue f tri.regionIndex
			luaWriteValue f tri.shaderIndex
			for i = 1 to 3 do luaWriteValue f tri.vertexIndices[i]
		)
	)

	if jmsWritesSmoothingGroups jmsData then
	(
		luaWriteInt f 1
		luaWriteInt f jmsData.smoothingGroups.count
		for sg in jmsData.smoothingGroups do luaWriteValue f sg
	)
	else
		luaWriteInt f 0
)

-------------------------------------------------------
-- MAIN EXPORT FUNCTION
-------------------------------------------------------

-- Write complete JMS file. Returns #(true, writeTimeMs), or false on error.
fn writeJmsFile filePath jmsData =
(
	logger.log "=== WRITING JMS FILE ==="
	logger.info "Output: '{}'" args:#(filePath)

	local writeStartTime = timestamp()
	local inPath = (getDir #temp) + "\\hce_jms_write.bin"
	local ok = false
	local f = undefined
	try
	(
		f = fopen inPath "wb"
		writeJmsForLua f jmsData
		fclose f
		f = undefined
		ok = luaRunScript "formats\\jms\\jms_cli.lua" #("write", inPath, filePath)
	)
	catch
	(
		logger.error "Exception while writing file: '{}'" args:#((getCurrentException()))
		if f != undefined do fclose f
	)
	deleteFile inPath
	if not ok then
	(
		logger.error "Failed to create file: '{}'" args:#(filePath)
		return false
	)

	local writeTime = timestamp() - writeStartTime
	logger.info "Version: {}" args:#(jmsData.jmsVersion)
	logger.info "Nodes: {}" args:#(jmsData.nodeCount)
	logger.info "Shaders: {}" args:#(jmsData.shaderCount)
	logger.info "Markers: {}" args:#(jmsData.markerCount)
	logger.info "Regions: {}" args:#(jmsData.regionCount)
	logger.info "Vertices: {}" args:#(jmsData.vertexCount)
	logger.info "Triangles: {}" args:#(jmsData.triangleCount)

	local extendedMetadataMsg = "None"
	if jmsData.smoothingGroups != undefined and jmsData.smoothingGroups.count > 0 then
	(
		local anyGroup = false
		for sg in jmsData.smoothingGroups while not anyGroup do anyGroup = sg != 0
		if anyGroup then
			extendedMetadataMsg = "'Written' " + (jmsData.smoothingGroups.count as string) + " smoothing groups"
		else
			extendedMetadataMsg = "'Skipped' (no smoothing groups found)"
	)
	logger.info "Extended Metadata: {}" args:#(extendedMetadataMsg)
	logger.info "Total write time: {} ms" args:#(writeTime)
	logger.log "JMS file written successfully\n"
	#(true, writeTime)
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
