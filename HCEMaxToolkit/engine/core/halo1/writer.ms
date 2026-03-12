------------------------------------------------------------------------------------------------
--	Copyright (C) 2026 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------
--
-------------------------------------------------------
-- TAG HEADER WRITING
-------------------------------------------------------

fn writeTagHeader file tagDef dataSize =
(
	logger.debug "Writing tag header..."
	
	-- Header structure (64 bytes total) based on CE tag format:
	-- Bytes 0-35:   36 bytes of zeros (reserved/padding)
	-- Bytes 36-39:  Tag class fourcc (4 bytes)
	-- Bytes 40-43:  Padding (4 bytes) - old script had "Mozz" here
	-- Byte  44:     Null terminator
	-- Bytes 45-46:  Header size 64 (2 bytes BE)
	-- Bytes 47-54:  8 bytes padding
	-- Bytes 55-56:  Version 2 (2 bytes BE)
	-- Bytes 57-58:  Flags 255 (2 bytes BE)
	-- Bytes 59-62:  "blam" signature (4 bytes)
	-- Byte  63:     Padding to complete 64 bytes
	
	-- Write first 36 bytes (zeros)
	write.padding file 36
	
	-- Write tag class fourcc (4 bytes at positions 36-39) WITHOUT null terminator
	-- Use individual byte writes to avoid WriteString's automatic null termination
	local fourcc = tagDef.fourcc
	WriteByte file (bit.and (bit.shift fourcc -24) 0xFF)
	WriteByte file (bit.and (bit.shift fourcc -16) 0xFF)
	WriteByte file (bit.and (bit.shift fourcc -8) 0xFF)
	WriteByte file (bit.and fourcc 0xFF)
	
	-- Mozz script uses WriteString which adds auto-null, so "trakMozz" + null = 9 bytes (36-44)
	-- Then manual null at 45, making header size start at 46.
	-- We write 4 bytes "trak" manually, so we need 5 more padding + 1 manual null = 6 bytes
	write.padding file 6  -- Positions 40-45
	
	-- Header size (2 bytes BE at positions 46-47)
	write.shortB file 64 signed:false
	
	-- Padding (8 bytes at positions 48-55)
	write.padding file 8
	
	-- Version (2 bytes BE at positions 56-57)
	write.shortB file 2 signed:false
	
	-- Flags (2 bytes BE at positions 58-59)
	write.shortB file 255 signed:false
	
	-- Final signature "blam" (4 bytes ONLY at positions 60-63, no null terminator)
	WriteByte file (bit.charAsInt "b"[1])
	WriteByte file (bit.charAsInt "l"[1])
	WriteByte file (bit.charAsInt "a"[1])
	WriteByte file (bit.charAsInt "m"[1])
	
	logger.debug "Tag header written (64 bytes)"
	ok
)

-- Helper: Convert fourcc integer to tag class string
fn getTagClassFromFourcc fourcc =
(
	local str = ""
	str += bit.intAsChar (bit.and (bit.shift fourcc -24) 0xFF)
	str += bit.intAsChar (bit.and (bit.shift fourcc -16) 0xFF)
	str += bit.intAsChar (bit.and (bit.shift fourcc -8) 0xFF)
	str += bit.intAsChar (bit.and fourcc 0xFF)
	str
)

-------------------------------------------------------
-- FIELD WRITING
-------------------------------------------------------

fn writeFieldValue file fieldDef value deferredTagRefs deferredReflexives =
(
	-- Handle arrays
	local isArray = (fieldDef.count != unsupplied and fieldDef.count != undefined and \
                        classOf fieldDef.count == Integer and fieldDef.count > 1 and \
                        fieldDef.type != #padding)
	
	case fieldDef.type of
	(
		#float:        
		(
			if isArray then
				for v in value do write.floatB file v
			else
				write.floatB file value
		)
		#floatAngle:   
		(
			if isArray then
				for v in value do write.floatB file v
			else
				write.floatB file value
		)
		#floatClamped: 
		(
			if isArray then
				for v in value do write.floatB file v
			else
				write.floatB file value
		)
		#floatBounds:  writeMath.bounds file value
		#colorRGB:     writeMath.colorRGB file value
		#colorARGB:    writeMath.colorARGB file value
		#euler2d:      writeMath.euler2D file value
		#vector3d:     writeMath.vector3D file value
		#point2d:      writeMath.point2D file value
		#point3d:      writeMath.point3D file value
		#plane2d:      writeMath.plane2D file value
		#plane3d:      writeMath.plane3D file value
		#quaternion:   writeMath.quaternion file value
		#index:        
		(
			if isArray then
				for v in value do write.shortB file v signed:true
			else
				write.shortB file value signed:true
		)
		#int8:         
		(
			if isArray then
				for v in value do WriteByte file v
			else
				WriteByte file value
		)
		#int16:        
		(
			if isArray then
				for v in value do write.shortB file v signed:true
			else
				write.shortB file value signed:true
		)
		#int32:        
		(
			if isArray then
				for v in value do write.longB file v signed:true
			else
				write.longB file value signed:true
		)
		#string:       write.tagString file value size:32
		#enum:         write.shortB file value signed:true
		#enum16:       write.shortB file value signed:true
		#bitfield:
		(
			case fieldDef.size of
			(
                
				#int8:  WriteByte file value
				#int16: write.shortB file value signed:false
				#int32: write.longB file value signed:false
				default: write.longB file value signed:false
			)
		)
		#padding:
		(
			local padSize = case fieldDef.size of
			(
				#int8: 1
				#int16: 2
				#int32: 4
				default: 1
			)
			local totalBytes = padSize * fieldDef.count
			write.padding file totalBytes
		)
		#tagData:
		(
			-- TagData: size(4) + flags(4) + unused(4) + offset(4) + unused(4) = 20 bytes
			local dataSize = if value != undefined and value.count > 0 then value[1] else 0
			local flags = if value != undefined and value.count > 1 then value[2] else 0
			local offset = if value != undefined and value.count > 2 then value[3] else 0
			write.rawTagData file dataSize:dataSize flags:flags pointer:offset
		)
		#tagReference:
		(
			-- TagReference: class(4) + pathPtr(4) + pathLen(4) + tagID(4) = 16 bytes
			local tagClass = if value != undefined and value[#tagClass] != undefined then value[#tagClass] else 0
			local pathPtr = 0  -- Always 0 for CE source tags
			local pathLen = if value != undefined and value[#path] != undefined then value[#path].count else 0
			local tagID = 0xFFFFFFFF  -- Default invalid ID
			
			write.tagRef file tagClass:tagClass pathPtr:pathPtr pathLen:pathLen tagID:tagID
			
			-- Store for deferred path writing
			if value != undefined and value[#path] != undefined and value[#path].count > 0 then
				append deferredTagRefs value[#path]
		)
		#block:
		(
			-- Reflexive block: count(4) + offset(4) + unused(4) = 12 bytes
			local count = if value != undefined then value.count else 0
			local offset = 0  -- Will be filled later when writing reflexive data
			
			write.reflexive file count:count pointer:offset id:0
			
			-- Store for deferred reflexive writing
			if count > 0 then
			(
				local reflexiveInfo = dictionary #name
				reflexiveInfo[#blockDef] = fieldDef.fieldBlock
				reflexiveInfo[#data] = value
				reflexiveInfo[#headerPosition] = (ftell file) - 12  -- Remember where to update pointer
				append deferredReflexives reflexiveInfo
			)
		)
		default:
		(
			logger.warn "Unknown field type for writing: {}" args:#(fieldDef.type)
		)
	)
	ok
)

-------------------------------------------------------
-- BLOCK WRITING
-------------------------------------------------------

fn writeBlockData file blockDef data deferredTagRefs deferredReflexives =
(
	logger.debug "Writing block: {}" args:#(blockDef.name)
	
	-- Write all fields sequentially
	for fieldDef in blockDef.fields do
	(
		-- Convert string field name to symbol for dictionary access
		local fieldKey = (fieldDef.name as name)
		local value = data[fieldKey]
		
		if value == undefined and fieldDef.type != #padding then
			logger.debug "  Field '{}' is undefined, writing default" args:#(fieldDef.name)
		
		writeFieldValue file fieldDef value deferredTagRefs deferredReflexives
	)
	ok
)

-------------------------------------------------------
-- TAG REFERENCE PATH WRITING
-------------------------------------------------------

fn writeTagRefPaths file tagRefPaths =
(
	if tagRefPaths.count == 0 then return ok
	
	logger.debug "Writing {} tag reference paths..." args:#(tagRefPaths.count)
	
	for path in tagRefPaths do
	(
		write.nullTerminatedString file path
	)
	ok
)

-------------------------------------------------------
-- REFLEXIVE DATA WRITING
-------------------------------------------------------

fn writeReflexiveData file reflexiveInfo =
(
	local blockDef = reflexiveInfo[#blockDef]
	local dataArray = reflexiveInfo[#data]
	local headerPos = reflexiveInfo[#headerPosition]
	
	if dataArray == undefined or dataArray.count == 0 then
		return ok
	
	logger.debug "Writing reflexive '{}' ({} entries)..." args:#(blockDef.name, dataArray.count)
	
	-- Remember current position (where reflexive data starts)
	local reflexiveStart = ftell file
	
	-- Write each reflexive entry
	local deferredTagRefs = #()
	local deferredReflexives = #()
	
	for entry in dataArray do
	(
		writeBlockData file blockDef entry deferredTagRefs deferredReflexives
	)
	
	-- Write any tag ref paths for this reflexive
	writeTagRefPaths file deferredTagRefs
	
	-- Write any nested reflexives (recursion)
	for nestedReflexive in deferredReflexives do
	(
		writeReflexiveData file nestedReflexive
	)
	
	-- Update the reflexive header with actual offset
	local currentPos = ftell file
	fseek file (headerPos + 4) #seek_set  -- Skip count(4), go to offset(4)
	write.longB file reflexiveStart signed:false
	fseek file currentPos #seek_set  -- Return to end
	

	logger.debug "Reflexive '{}' written at offset 0x{}" args:#(blockDef.name, bit.intAsHex reflexiveStart)
	ok
)

-------------------------------------------------------
-- MAIN WRITE FUNCTION
-------------------------------------------------------

fn writeTag filePath tagDef tagData =
(
	logger.info "=== WRITING TAG: {} ===" args:#(filePath)
	
	local tagFile = fopen filePath "wb"
	if tagFile == undefined then
	(
		logger.error "Cannot create file: {}" args:#(filePath)
		return false
	)
	
	-- Write header (64 bytes)
	writeTagHeader tagFile tagDef 0
	
	-- Collect deferred operations
	local deferredTagRefs = #()
	local deferredReflexives = #()
	
	-- Write main tag block data
	writeBlockData tagFile tagDef.tagBlock tagData deferredTagRefs deferredReflexives
	
	-- Write tag reference paths
	writeTagRefPaths tagFile deferredTagRefs
	
	-- Write reflexive data
	for reflexiveInfo in deferredReflexives do
	(
		writeReflexiveData tagFile reflexiveInfo
	)
	
	fclose tagFile
	--
	logger.info "Tag written successfully: {}" args:#(filePath)
	return true
)

-- Module loaded
scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
