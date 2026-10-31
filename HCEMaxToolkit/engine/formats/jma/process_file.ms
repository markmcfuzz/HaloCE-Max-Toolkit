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

-- Writes JMA/JMO/JMR/... files through lua\formats\jma_cli.lua (lua\formats\jma.lua):
-- the data goes to Lua as binary and Lua writes the same text the previous MAXScript writer did.

-- lua_bridge.ms is loaded by init.ms; reload it if Max still runs an older toolkit.
global luaRunScript
if luaRunScript == undefined and rootEngine != undefined do
	fileIn (rootEngine + "shared\\utils\\lua_bridge.ms")

-------------------------------------------------------
-- MAIN EXPORT FUNCTION
-------------------------------------------------------

-- Write complete JMA file. jmaData.keyframes: jmaKeyframes with per-node arrays
-- (translation #(x,y,z), rotation #(i,j,k,w), scale). Returns #(success, writeTimeMs).
fn writeJmaFile filePath jmaData =
(
	logger.log "=== WRITING JMA FILE ==="
	logger.info "Output: '{}'" args:#(filePath)

	local writeStartTime = timestamp()
	local inPath = (getDir #temp) + "\\hce_jma_write.bin"
	local ok = false
	local f = undefined
	try
	(
		f = fopen inPath "wb"
		luaWriteString f "jma"
		luaWriteInt f 1
		luaWriteInt f jmaData.jmaVersion
		luaWriteInt f jmaData.frameCount
		luaWriteInt f jmaData.frameRate
		luaWriteInt f jmaData.actorNamesIndex
		luaWriteString f jmaData.actorNames
		luaWriteInt f jmaData.nodeCount
		luaWriteInt f jmaData.nodeChecksum

		luaWriteInt f jmaData.nodes.count
		for node in jmaData.nodes do
		(
			luaWriteString f node.nodeName
			luaWriteInt f node.firstChildNodeIndex
			luaWriteInt f node.nextSiblingNodeIndex
		)

		-- Every keyframe writes all the entries it has; a missing scale is written as 1
		luaWriteInt f jmaData.keyframes.count
		for keyframe in jmaData.keyframes do
		(
			luaWriteInt f keyframe.nodeTranslation.count
			for n = 1 to keyframe.nodeTranslation.count do
			(
				local trans = keyframe.nodeTranslation[n]
				local rot = keyframe.nodeRotation[n]
				local scl = keyframe.nodeScale[n]
				if scl == undefined then scl = 1.0
				for i = 1 to 3 do luaWriteFloat f trans[i]
				for i = 1 to 4 do luaWriteFloat f rot[i]
				luaWriteFloat f scl
			)
		)
		fclose f
		f = undefined

		if doesFileExist filePath do deleteFile filePath
		ok = luaRunScript "lua\\formats\\jma_cli.lua" #("write", inPath, filePath)
	)
	catch
	(
		logger.error "Error writing JMA file: {}" args:#(getCurrentException())
		if f != undefined do fclose f
	)
	deleteFile inPath

	if not ok then
	(
		logger.error "Failed to create file: '{}'" args:#(filePath)
		return #(false, 0)
	)

	local writeTime = timestamp() - writeStartTime
	logger.info "Version: {}" args:#(jmaData.jmaVersion)
	logger.info "Frames: {}" args:#(jmaData.frameCount)
	logger.info "Frame Rate: {}" args:#(jmaData.frameRate)
	logger.info "Nodes: {}" args:#(jmaData.nodeCount)
	logger.info "Actor: '{}'" args:#(jmaData.actorNames)
	#(true, writeTime)
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
