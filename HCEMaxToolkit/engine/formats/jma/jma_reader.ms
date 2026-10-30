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

-- Reads JMA/JMO/JMR/... files through formats\jma\jma_cli.lua (formats\jma\jma.lua).
-- Returns the same jmaFile struct (jma_struct.ms) as the previous MAXScript reader.

-- Supported JMA version
global SUPPORTED_JMA_VERSION = 16392

-- lua_bridge.ms is loaded by init.ms; reload it if Max still runs an older toolkit.
global luaRunScript
if luaRunScript == undefined and rootEngine != undefined do
	fileIn (rootEngine + "shared\\utils\\lua_bridge.ms")

-------------------------------------------------------
-- MAIN READ FUNCTION
-------------------------------------------------------

-- Read a complete JMA file and return a jmaFile struct with all data (undefined on error)
fn readJmaFile filePath =
(
	logger.log "=== READING JMA FILE ==="
	logger.info "File: '{}'" args:#(filePath)

	local outPath = (getDir #temp) + "\\hce_jma_read.bin"
	deleteFile outPath
	if not (luaRunScript "formats\\jma\\jma_cli.lua" #("read", filePath, outPath)) then
	(
		logger.error "Error reading JMA file: '{}'" args:#(filePath)
		return undefined
	)
	local f = luaOpenOutput outPath "jma" 1
	if f == undefined then return undefined

	local jmaData = jmaFile()
	jmaData.jmaVersion = luaReadInt f
	jmaData.frameCount = luaReadInt f
	jmaData.frameRate = luaReadInt f
	jmaData.actorNamesIndex = luaReadInt f
	jmaData.actorNames = readString f
	jmaData.nodeCount = luaReadInt f
	jmaData.nodeChecksum = luaReadInt f

	jmaData.nodes = for i = 1 to jmaData.nodeCount collect
	(
		local nodeName = readString f
		local firstChild = luaReadInt f
		local nextSibling = luaReadInt f
		jmaNodes nodeName:nodeName firstChildNodeIndex:firstChild nextSiblingNodeIndex:nextSibling
	)

	-- Rotations arrive as written in the file; normalized here like the previous reader did
	jmaData.frames = for fr = 1 to jmaData.frameCount collect
	(
		local frameData = jmaFrameData()
		frameData.nodeFrames = for n = 1 to jmaData.nodeCount collect
		(
			local translation = luaReadPoint3 f
			local qi = readFloat f
			local qj = readFloat f
			local qk = readFloat f
			local qw = readFloat f
			local nodeScale = readFloat f
			jmaNodeFrame translation:translation rotation:(normalize (quat qi qj qk qw)) scale:nodeScale
		)
		frameData
	)

	-- Scale lines that were not numbers stay undefined, as before
	for i = 1 to (luaReadInt f) do
	(
		local fr = luaReadInt f
		local n = luaReadInt f
		jmaData.frames[fr].nodeFrames[n].scale = undefined
	)
	fclose f
	deleteFile outPath

	logger.info "JMA Version: {}" args:#(jmaData.jmaVersion)
	logger.info "Frame Count: {}" args:#(jmaData.frameCount)
	logger.info "Frame Rate: {}" args:#(jmaData.frameRate)
	logger.info "Actor Count: {}" args:#(jmaData.actorNamesIndex)
	logger.info "Actor Name: {}" args:#(jmaData.actorNames)
	logger.info "Node Count: {}" args:#(jmaData.nodeCount)
	logger.info "Node Checksum: {}" args:#(jmaData.nodeChecksum)
	logger.info "JMA file read successfully!\n"
	jmaData
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
