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

-----------------------------------------
-- UTILITY FUNCTIONS
-----------------------------------------

-- Calculate the byte size of a block structure for skipping
fn calculateBlockSize blockDef =
(
	local totalSize = 0
	for field in blockDef.fields do
	(
		local fieldSize = 0
		
		-- Calculate base field size
		case field.type of
		(
			#float: fieldSize = 4
			#floatAngle: fieldSize = 4
			#floatClamped: fieldSize = 4
			#floatBounds: fieldSize = 8
			#colorRGB: fieldSize = 12
			#colorARGB: fieldSize = 16
			#euler2d: fieldSize = 8
			#vector3d: fieldSize = 12
			#point2d: fieldSize = 8
			#point3d: fieldSize = 12
			#plane2d: fieldSize = 12
			#plane3d: fieldSize = 16
			#quaternion: fieldSize = 16
			#index: fieldSize = 2
			#int8: fieldSize = 1
			#int16: fieldSize = 2
			#int32: fieldSize = 4
			#padding:
			(
				local padSize = case field.size of
				(
					#int8: 1
					#int16: 2
					#int32: 4
					default: 1
				)
				fieldSize = padSize * field.count
			)
			#string: fieldSize = 32
			#enum: fieldSize = 2
			#enum16: fieldSize = 2
			#tagData: fieldSize = 20
			#bitfield:
			(
				fieldSize = case field.size of
				(
					#int8: 1
					#int16: 2
					#int32: 4
					default: 4
				)
			)
			#tagReference: fieldSize = 16
			#block: fieldSize = 12
			default: fieldSize = 0
		)
	
		-- Handle array fields (count > 1)
		if field.count != unsupplied and field.count != undefined and classOf field.count == Integer and field.count > 1 and field.type != #padding then
			totalSize += fieldSize * field.count
		else
			totalSize += fieldSize
	)
	totalSize
)

-----------------------------------------
-- FIELD READING FUNCTIONS
-----------------------------------------

-- Read a single field value based on type
fn readFieldValue fieldDef &deferredTagRefs &deferredReflexives =
(
	local value = undefined
	
	-- Check if this is an array field (count > 1)
	local isArray = (fieldDef.count != unsupplied and fieldDef.count != undefined and \
	                 classOf fieldDef.count == Integer and fieldDef.count > 1 and \
	                 fieldDef.type != #padding)
	
	case fieldDef.type of
	(
		#float:      value = if isArray then (for i=1 to fieldDef.count collect read.floatB()) else read.floatB()
		#floatAngle: value = if isArray then (for i=1 to fieldDef.count collect read.floatB()) else read.floatB()
		#floatClamped: value = if isArray then (for i=1 to fieldDef.count collect read.floatB()) else read.floatB()
		#floatBounds: value = math.readBounds()
		#colorRGB:   value = math.readColorRGB()
		#colorARGB:  value = math.readColorARGB()
		#euler2d:    value = math.readEuler2D()
		#vector3d:   value = math.readVector3D()
		#point2d:    value = math.readPoint2()
		#point3d:    value = math.readPoint3()
		#plane2d:    value = math.readPlane2D()
		#plane3d:    value = math.readPlane3D()
		#quaternion: value = math.readQuat()
		#index:      value = if isArray then (for i=1 to fieldDef.count collect (read.shortB "#signed")) else (read.shortB "#signed")
		#int8:       value = if isArray then (for i=1 to fieldDef.count collect (readByte (getCurrentFileHandle()) #signed)) else (readByte (getCurrentFileHandle()) #signed)
		#int16:      value = if isArray then (for i=1 to fieldDef.count collect (read.shortB "#signed")) else (read.shortB "#signed")
		#int32:      value = if isArray then (for i=1 to fieldDef.count collect (read.longB "#signed")) else (read.longB "#signed")
		#string:     value = read.tagString 32  -- 32-byte inline string
		#enum:       value = if isArray then (for i=1 to fieldDef.count collect (read.shortB "#signed")) else (read.shortB "#signed")
		#enum16:     value = if isArray then (for i=1 to fieldDef.count collect (read.shortB "#signed")) else (read.shortB "#signed")
		#bitfield:
		(
			value = case fieldDef.size of
			(
				#int8:  readByte (getCurrentFileHandle()) #unsigned
				#int16: read.shortB "#unsigned"
				#int32: read.longB "#unsigned"
				default: read.longB "#unsigned"
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
			local f = getCurrentFileHandle()
			fseek f totalBytes #seek_cur
			value = undefined
		)
		#tagData:
		(
			-- TagData: size(4) + flags(4) + unused(4) + offset(4) + unused(4) = 20 bytes
			local dataSize = read.longB "#unsigned"
			local flags = read.longB "#unsigned"
			local unused1 = read.longB "#unsigned"
			local offset = read.longB "#unsigned"
			local unused2 = read.longB "#unsigned"
			value = #(dataSize, flags, offset)
		)
		#tagReference:
		(
			-- TagReference: class(4) + pathPtr(4) + pathLen(4) + tagID(4) = 16 bytes
			-- CE source tags have pathPtr=0, MCC cached tags have pathPtr>0
			local tagClass = read.longB "#unsigned"
			local pathPtr = read.longB "#signed"
			local pathLen = read.longB "#signed"
			local tagID = read.longB "#unsigned"
			
			-- Store for deferred path reading
            local tagRefInfo = dictionary #name
            tagRefInfo[#tagClass] = tagClass
            tagRefInfo[#pathPtr]  = pathPtr
            tagRefInfo[#pathLen]  = pathLen
            tagRefInfo[#tagID]    = tagID
            tagRefInfo[#path]     = ""

            append deferredTagRefs tagRefInfo
			logger.debug "  Deferred tag-ref #{}: class=0x{} pathPtr=0x{} pathLen={}" args:#(
				deferredTagRefs.count, 
				bit.intAsHex tagClass, 
				bit.intAsHex pathPtr, 
				pathLen
			)
            value = tagRefInfo
		)
		#block:
		(
			-- Reflexive block: count(4) + offset(4) + unused(4) = 12 bytes
			local count = read.longB "#signed"
			local offset = read.longB "#unsigned"
			local unused = read.longB "#unsigned"
			
			-- Clamp count to maximum
			local maximum = if fieldDef.fieldBlock.maximum != unsupplied then fieldDef.fieldBlock.maximum else 65535
			if count > maximum and count > 0 then
			(
				logger.warn "Clamping reflexive '{}' count from {} to 0 (max {})" args:#(fieldDef.fieldBlock.name, count, maximum)
				count = 0
			)
			
			logger.debug "Reflexive header '{}': rawCount: {} rawOffset: 0x{}" args:#(fieldDef.name, count, (bit.intAsHex offset))
			
			-- Store for deferred reading (returns empty array initially)
            local reflexiveInfo = dictionary #name

            reflexiveInfo[#blockDef]  = fieldDef.fieldBlock
            reflexiveInfo[#count]     = count
            reflexiveInfo[#offset]    = offset
            reflexiveInfo[#fieldName] = fieldDef.name

            append deferredReflexives reflexiveInfo
            value = #() -- Empty array, will be filled when reflexive is read
		)
		default:
		(
			logger.warn "Unknown field type: {}" args:#(fieldDef.type)
			value = undefined
		)
	)
	
	value
)

-----------------------------------------
-- BLOCK READING FUNCTIONS
-----------------------------------------

--Read a complete tag block (tagdata → tag-refs → reflexives)
-- Returns: #(entry, deferredTagRefs, deferredReflexives)
fn readBlockTagdata blockDef =
(
	local entry = #()
	local deferredTagRefs = #()
	local deferredReflexives = #()
	local tagDataSkips = #()  -- Tracks tagData rawdata between sibling reflexives (CE format)
	
	-- Read all fields sequentially
	for i = 1 to blockDef.fields.count do
	(
		local field = blockDef.fields[i]
		local value = readFieldValue field &deferredTagRefs &deferredReflexives
		append entry #(field.name, value, field)
		
		-- Track tagData fields that sit between reflexives in the parent struct.
		-- afterReflexiveIndex = number of reflexives already collected before this tagData.
		if field.type == #tagData then
		(
			if value != undefined and classOf value == Array and value.count >= 1 then
			(
				local dataSize = value[1]
				if classOf dataSize == Integer and dataSize > 0 then
					append tagDataSkips #(deferredReflexives.count, dataSize)
			)
		)
	)
	
	#(entry, deferredTagRefs, deferredReflexives, tagDataSkips)
)

-- Read tag-ref paths (null-terminated strings following tagdata)
-- CE source tags (pathPtr==0) have sequential null-terminated strings
-- MCC cached tags (pathPtr>0) require seeking to pointer location
fn readTagRefPaths deferredTagRefs =
(
	if deferredTagRefs.count == 0 then return ok
	
	local f = getCurrentFileHandle()
	logger.debug "Reading {} tag-ref paths at position 0x{}" args:#(deferredTagRefs.count, bit.intAsHex (ftell f))
	
	for i = 1 to deferredTagRefs.count do
	(
		local tagRefInfo = deferredTagRefs[i]
		local pathLen = tagRefInfo[#pathLen]
		local pathPtr = tagRefInfo[#pathPtr]
		
		-- Skip tag-refs with no path (pathLen==0 means null/empty reference)
		if pathLen == 0 then
		(
			tagRefInfo[#path] = ""
			logger.debug "  [{}/{}] Empty tag-ref (pathLen=0)" args:#(i, deferredTagRefs.count)
			continue
		)
		
		-- For MCC cached tags with pathPtr>0, paths are often still stored sequentially after tagdata
		-- Try to read as null-terminated string if pathLen > 0
		if pathLen > 0 then
		(
			local pathStr = read.nullTerminatedString()
			tagRefInfo[#path] = pathStr
			
			if pathPtr == 0 then
				logger.debug "  [{}/{}] CE tag-ref: '{}'" args:#(i, deferredTagRefs.count, pathStr)
			else
				logger.debug "  [{}/{}] MCC tag-ref (pathPtr=0x{}): '{}'" args:#(i, deferredTagRefs.count, bit.intAsHex pathPtr, pathStr)
		)
		else
		(
			-- No valid path
			tagRefInfo[#path] = ""
			logger.debug "  [{}/{}] No path (pathLen={})" args:#(i, deferredTagRefs.count, pathLen)
		)
	)
	ok
)

-- Read a single reflexive block entry
fn readReflexiveEntry blockDef &entryTagRefs &entryReflexives =
(
	local n = blockDef.fields.count
	local entry = #()
	entry.count = n
	
	for i = 1 to n do
	(
		local field = blockDef.fields[i]
		local value = readFieldValue field &entryTagRefs &entryReflexives
		entry[i] = #(field.name, value, field)
	)
	
	entry
)

-- Read reflexive blocks and read paths immediately after each block's data (CE structure)
-- skipBlocks: array of field names to skip reading (e.g., #("uncompressedVertices"))
-- tagDataSkips: array of #(afterReflexiveIndex, byteCount) pairs for main-struct tagData between sibling blocks
-- subBlockSkips: array of #(parentFieldName, #(childFieldName, ...)) pairs.
-- When a block named parentFieldName is being read, the listed child names are
-- automatically added to skipBlocks for that block's nested recursion only.
fn readReflexiveBlocks deferredReflexives parentEntry skipBlocks:#() tagDataSkips:#() subBlockSkips:#() =
(
	if deferredReflexives.count == 0 then return ok
	
	logger.debug "Reading [{}] reflexive block(s)" args:#(deferredReflexives.count)
	
	for i = 1 to deferredReflexives.count do
	(
		-- Apply any main-struct tagData rawdata skips that belong before block i
		-- (i.e., those recorded after reflexive i-1 in the parent struct definition)
		if tagDataSkips.count > 0 then
		(
			local prevIndex = i - 1
			for skipInfo in tagDataSkips do
			(
				if skipInfo[1] == prevIndex and skipInfo[2] > 0 then
				(
					local f = getCurrentFileHandle()
					logger.debug "Skipping {} bytes of parent-struct tagData rawdata before block {}" args:#(skipInfo[2], i)
					fseek f skipInfo[2] #seek_cur
				)
			)
		)
		local reflexiveInfo = deferredReflexives[i]
		local blockDef = reflexiveInfo[#blockDef]
		local count = reflexiveInfo[#count]
		local fieldName = reflexiveInfo[#fieldName]
		
		logger.debug "Block [{}]: '{}': {} entries" args:#(i, blockDef.name, count)
		
		if count == 0 then continue
		
		-- Check if this block should be skipped
		if findItem skipBlocks fieldName > 0 then
		(
			local skipBlockSize = calculateBlockSize blockDef
			local totalSkip = skipBlockSize * count
			logger.info "Skipping '{}' ({} entries, {} bytes)" args:#(fieldName, count, totalSkip)
			local f = getCurrentFileHandle()
			fseek f totalSkip #seek_cur
			
			-- Mark as empty in parent entry
			for k = 1 to parentEntry.count do
			(
				if parentEntry[k][1] == fieldName then
				(
					parentEntry[k][2] = #()  -- Empty array
					exit
				)
			)
			
			continue  -- Skip to next reflexive
		)
		
		if count == 0 then continue
		
		logger.debug "Reading reflexive '{}' sequentially from current position" args:#(blockDef.name)
		
		-- Read all entries in this reflexive block (binary data)
		local entries = #()
		entries.count = count
		local allEntryTagRefsPerEntry = #()  -- per-entry arrays, NOT flattened
		allEntryTagRefsPerEntry.count = count
		local allEntryReflexivesIndexed = #()  -- Store reflexives with entry index
		
		for j = 1 to count do
		(
			local entryTagRefs = #()
			local entryReflexives = #()
			local entry = readReflexiveEntry blockDef &entryTagRefs &entryReflexives
			entries[j] = entry
			allEntryTagRefsPerEntry[j] = entryTagRefs  -- store per-entry, not joined
			
			-- Tag each reflexive with its parent entry index
			for k = 1 to entryReflexives.count do
			(
				entryReflexives[k][#entryIndex] = j
				append allEntryReflexivesIndexed entryReflexives[k]
			)
		)
		
		-- CE source format: rawdata for entry j immediately follows entry j's tag-ref path strings.
		-- Process per-entry: [entry j paths] → [entry j rawdata skip] → [entry j+1 paths] → ...
		-- Batching all paths then all rawdata is WRONG for blocks with multiple entries.
		for j = 1 to entries.count do
		(
			local entryTagRefs = allEntryTagRefsPerEntry[j]
			if entryTagRefs.count > 0 then
			(
				logger.debug "Reading {} tag-ref path(s) for entry [{}] of '{}' block" args:#(entryTagRefs.count, j, blockDef.name)
				readTagRefPaths entryTagRefs
			)
			
			local entryRawSkip = 0
			local entry = entries[j]
			for k = 1 to entry.count do
			(
				local field = entry[k]
				if field[3].type == #tagData then
				(
					local tagDataValue = field[2]
					if tagDataValue != undefined and classOf tagDataValue == Array and tagDataValue.count >= 1 then
					(
						local dataSize = tagDataValue[1]
						if classOf dataSize == Integer and dataSize > 0 then
							entryRawSkip += dataSize
					)
				)
			)
			if entryRawSkip > 0 then
			(
				local f = getCurrentFileHandle()
				local rawDataFilePos = ftell f
				-- Annotate each tagData field with its file position so callers can seek back and read raw bytes
				local cumulativeOffset = 0
				for k = 1 to entry.count do
				(
					if entry[k][3].type == #tagData then
					(
						local tdv = entry[k][2]
						if tdv != undefined and classOf tdv == Array and tdv.count >= 3 then
						(
							local dataSize = tdv[1]
							if classOf dataSize == Integer and dataSize > 0 then
							(
								entry[k][2] = #(tdv[1], tdv[2], tdv[3], rawDataFilePos + cumulativeOffset)
								cumulativeOffset += dataSize
							)
						)
					)
				)
				logger.debug "Skipping {} bytes of rawdata after entry [{}] in '{}' block at 0x{}" args:#(entryRawSkip, j, blockDef.name, bit.intAsHex rawDataFilePos)
				fseek f entryRawSkip #seek_cur
			)
		)
		
		-- Process nested reflexives after reading ALL entries.
		-- If subBlockSkips has an entry for this block, merge its child names into skipBlocks
		-- for the nested recursion only (does not affect sibling or parent blocks).
		if allEntryReflexivesIndexed.count > 0 then
		(
			local childSkipBlocks = skipBlocks
			for subSkipEntry in subBlockSkips do
			(
				if subSkipEntry[1] == fieldName then
				(
					-- copy on an array returns OK in MaxScript; use join into a fresh array instead
					local newSkips = #()
					join newSkips skipBlocks
					for childName in subSkipEntry[2] do
						if findItem newSkips childName == 0 then
							append newSkips childName
					childSkipBlocks = newSkips
					exit
				)
			)
			for k = 1 to allEntryReflexivesIndexed.count do
			(
				local reflexiveWithIndex = allEntryReflexivesIndexed[k]
				local entryIndex = reflexiveWithIndex[#entryIndex]
				local targetEntry = entries[entryIndex]
				readReflexiveBlocks #(reflexiveWithIndex) targetEntry skipBlocks:childSkipBlocks subBlockSkips:subBlockSkips
			)
		)
		
		-- Update parent entry with reflexive data
		-- Find the field in parent entry by name
		for k = 1 to parentEntry.count do
		(
			if parentEntry[k][1] == fieldName then
			(
				parentEntry[k][2] = entries
				exit
			)
		)
	)
	
	ok
)

-----------------------------------------
-- PARENT CHAIN HANDLING
-----------------------------------------

-- Collect parent chain (deepest first)
fn collectParentChain tagDef =
(
	local parents = #()
	local current = tagDef
	
	-- Walk up parent chain
	while current.supergroup != unsupplied and current.supergroup != undefined do
	(
		-- Convert symbol to def name (e.g., #unit → "unitDef")
		local supergroupName = current.supergroup as string
		local parentDefName = supergroupName + "Def"
		
		-- Get the parent definition from global scope
		local parentDef = execute parentDefName
		
		if parentDef == undefined then
		(
			logger.warn "Parent group '{}' not found for '{}'" args:#(supergroupName, current.tagBlock.name)
			exit
		)
		
		append parents parentDef
		current = parentDef
	)
	
	-- Reverse to get deepest first (object, unit, biped)
	local reversed = #()
	for i = parents.count to 1 by -1 do
		append reversed parents[i]
	
	reversed
)

-- Read parent block (tagdata only, defer reflexives AND tag-refs for global reading)
fn readParentBlock parentDef parentNumber =
(
	logger.info "Reading parent [{}]: '{}'" args:#(parentNumber, parentDef.tagBlock.name)
	
	-- Read tagdata ONLY (reflexives come globally after ALL tagdata in CE format)
	local result = readBlockTagdata parentDef.tagBlock
	local entry = result[1]
	local deferredTagRefs = result[2]
	local deferredReflexives = result[3]
	local tagDataSkips = result[4]
	
	local f = getCurrentFileHandle()
	if f != undefined then logger.debug "After parent [{}] tagdata, file pos={}" args:#(parentNumber, ftell f)
	
	#(entry, parentDef, deferredTagRefs, deferredReflexives, tagDataSkips)
)

-- Read main tag block (tagdata only, defer reflexives AND tag-refs for global reading)
fn readMainBlock tagDef =
(
	logger.info "Reading main tag: '{}'" args:#(tagDef.tagBlock.name)
	
	-- Read tagdata ONLY (reflexives come globally after ALL tagdata in CE format)
	local result = readBlockTagdata tagDef.tagBlock
	local entry = result[1]
	local deferredTagRefs = result[2]
	local deferredReflexives = result[3]
	local tagDataSkips = result[4]
	
	local f = getCurrentFileHandle()
	if f != undefined then logger.debug "After main tagdata, file pos: '{}'" args:#(ftell f)
	
	#(entry, tagDef, deferredTagRefs, deferredReflexives, tagDataSkips)
)

-----------------------------------------
-- SINGLE TAG READING FUNCTION
-----------------------------------------

-- Read a single-level tag (no parents) - for tags like collision geometry, physics, etc.
fn readTag tagDefOrBlock skipBlocks:#() readOnlyBlocks:#() subBlockSkips:#() printData:false =
(
	-- Handle both tagDef and blockDef inputs
	local blockDef = if (iskindof tagDefOrBlock tagDef) then tagDefOrBlock.tagBlock else tagDefOrBlock
	
	logger.info "Reading tag: '{}'" args:#(blockDef.name)
	
	-- Read tagdata
	local result = readBlockTagdata blockDef
	local entry = result[1]
	local deferredTagRefs = result[2]
	local deferredReflexives = result[3]
	local tagDataSkips = result[4]
	
	local f = getCurrentFileHandle()
	if f != undefined then logger.debug "After tagdata, file pos: '{}'" args:#(ftell f)
	
	-- Read tag-ref paths
	if deferredTagRefs.count > 0 then
	(
		logger.debug "Reading [{}] tag-ref path(s)" args:#(deferredTagRefs.count)
		readTagRefPaths deferredTagRefs
	)
	
	-- If a whitelist is provided, keep only those blocks.
	-- Non-whitelisted blocks that sit BETWEEN whitelisted ones are auto-added to
	-- skipBlocks so readReflexiveBlocks seeks past them correctly (file stays in sync).
	-- Non-whitelisted blocks that sit AFTER the last whitelisted block are simply
	-- dropped from the list - we stop reading before reaching them.
	if readOnlyBlocks.count > 0 then
	(
		-- Find the index of the last whitelisted block in deferredReflexives
		local lastWLIdx = 0
		for i = 1 to deferredReflexives.count do
		(
			if findItem readOnlyBlocks deferredReflexives[i][#fieldName] > 0 then
				lastWLIdx = i
		)

		-- Build filtered list up to lastWLIdx; keep ALL blocks in filtered so
		-- readReflexiveBlocks can traverse the file sequentially and seek past gaps.
		-- Non-whitelisted blocks are added to skipBlocks so they get skipped.
		local filtered = #()
		for i = 1 to lastWLIdx do
		(
			local fieldName = deferredReflexives[i][#fieldName]
			if findItem readOnlyBlocks fieldName == 0 and findItem skipBlocks fieldName == 0 then
				append skipBlocks fieldName  -- non-whitelisted gap: will be skipped
			append filtered deferredReflexives[i]  -- always include in filtered
		)
		deferredReflexives = filtered
		-- Note: tagDataSkips are intentionally preserved. Skips recorded beyond
		-- lastWLIdx can never trigger (prevIndex is bounded by lastWLIdx-1), so
		-- they are harmless. Skips within the range (e.g. clusterData between
		-- clusters and clusterPortals) MUST be preserved to keep file position correct.
	)
	
	-- Process reflexives
	if deferredReflexives.count > 0 then
	(
		logger.debug "Processing [{}] reflexive block(s)" args:#(deferredReflexives.count)
		readReflexiveBlocks deferredReflexives entry skipBlocks:skipBlocks tagDataSkips:tagDataSkips subBlockSkips:subBlockSkips
	)

	if printData then
	(
		logger.info "Tag: '{}'" args:#(blockDef.name)
		printBlockRecursively entry blockDef indent:1
	)
	
	logger.info "Read tag successfully"
	entry
)

-- Backward compatibility alias
fn readRootTagData blockDef skipBlocks:#() readOnlyBlocks:#() subBlockSkips:#() =
(
	readTag blockDef skipBlocks:skipBlocks readOnlyBlocks:readOnlyBlocks subBlockSkips:subBlockSkips
)

-----------------------------------------
-- MAIN TAG READING FUNCTION
-----------------------------------------

-- Read a complete tag with CE structure: each parent reads tagdata+reflexives, then all tag-ref strings at end
fn readTagWithParents tagDef skipBlocks:#() printParents:true printMain:true =
(
	local result = #()
	local allDeferredTagRefs = #()
	local allDeferredReflexives = #()
	
	-- Collect parent chain (deepest first: object → unit → biped)
	local parents = collectParentChain tagDef
	
	-- PHASE 1: Read ALL tagdata (no paths yet - they're stored globally after all tagdata at 1332)
	logger.info "=== Reading {} parent block(s) tagdata ===" args:#(parents.count)
	for i = 1 to parents.count do
	(
		local parentResult = readParentBlock parents[i] i
		local entry = parentResult[1]
		local parentDef = parentResult[2]
		local tagRefs = parentResult[3]
		local reflexives = parentResult[4]
		local parentTagDataSkips = parentResult[5]
		
		append result #(entry, parentDef)
		-- Store for later processing (don't read paths yet!)
		append allDeferredTagRefs #(entry, parentDef, tagRefs, "parent")
		append allDeferredReflexives #(entry, parentDef, reflexives, parentTagDataSkips)
	)
	
	-- Read main tag tagdata
	local mainResult = readMainBlock tagDef
	local mainEntry = mainResult[1]
	local mainDef = mainResult[2]
	local mainTagRefs = mainResult[3]
	local mainReflexives = mainResult[4]
	local mainTagDataSkips = mainResult[5]
	
	append result #(mainEntry, mainDef)
	append allDeferredTagRefs #(mainEntry, mainDef, mainTagRefs, "main")
	append allDeferredReflexives #(mainEntry, mainDef, mainReflexives, mainTagDataSkips)
	
	local f = getCurrentFileHandle()
	logger.info "All tagdata read, now at position {} (should be 1332 for research.biped)" args:#(ftell f)
	
	-- PHASE 2: Now at position 1332 - process each parent depth-first (paths → reflexives with embedded paths)
	logger.info "=== Processing tag-refs and reflexives depth-first ===" args:#()
	for i = 1 to allDeferredTagRefs.count do
	(
		local entry = allDeferredTagRefs[i][1]
		local def = allDeferredTagRefs[i][2]
		local tagRefs = allDeferredTagRefs[i][3]
		local blockType = allDeferredTagRefs[i][4]
		
		-- Read tagdata paths for this block
		if tagRefs.count > 0 then
		(
			logger.info "Reading {} tag-ref path(s) for '{}' {}" args:#(tagRefs.count, def.tagBlock.name, blockType)
			readTagRefPaths tagRefs
		)
		
		-- Process reflexives for this block (reads data + paths per-block)
		local reflexives = allDeferredReflexives[i][3]
		local blockTagDataSkips = if allDeferredReflexives[i].count >= 4 then allDeferredReflexives[i][4] else #()
		if reflexives.count > 0 then
		(
			logger.info "Processing {} reflexive block(s) for '{}' (data+paths per block)" args:#(reflexives.count, def.tagBlock.name)
			readReflexiveBlocks reflexives entry skipBlocks:skipBlocks tagDataSkips:blockTagDataSkips
		)
	)
	
	local f = getCurrentFileHandle()
	if f != undefined then logger.info "Tag complete at file pos={}" args:#(ftell f)
	
	-- Print results (only if requested)
	if printParents then
	(
		for i = 1 to parents.count do
		(
			logger.info "Parent [{}]: '{}'" args:#(i, result[i][2].tagBlock.name)
			printBlockRecursively result[i][1] result[i][2].tagBlock indent:1
		)
	)
	
	if printMain then
	(
		local mainIdx = result.count
		logger.info "Main Tag: '{}'" args:#(result[mainIdx][2].tagBlock.name)
		printBlockRecursively result[mainIdx][1] result[mainIdx][2].tagBlock indent:1
	)
	
	-- Only print success message if we did the printing
	if printParents or printMain then
		logger.info "Read tag successfully"
	
	result
)

-----------------------------------------
-- PRINT FUNCTION
-----------------------------------------

fn printBlockRecursively data blockDef indent:0 onlyBlock:"" =
(
	local pad = ""
	for i = 1 to indent do pad += "    "
	
	-- Check if this is primitive data
	if (classOf data == String) or (classOf data == Integer) or (classOf data == Float) then
	(
		logger.debug "{}{}" args:#(pad, data)
		return()
	)
	
	-- Check if data is empty
	if data == undefined or (classOf data == Array and data.count == 0) then
	(
		logger.debug "{}(No Entries)" args:#(pad)
		return()
	)
	
	-- Process array of entries
	if classOf data == Array then
	(
		-- Check if this is an array of field tuples
		if data.count > 0 and classOf data[1] == Array and data[1].count >= 3 then
		(
			-- This is a block entry or array of entries
			for i = 1 to data.count do
			(
				local item = data[i]
				
				-- Check for field structure: item is #(fieldName, fieldValue, fieldDefinition)
				if item.count >= 3 and classOf item[3] == fieldDef then
				(
					local fieldName = item[1]
					local fieldValue = item[2]
					local fDef = item[3]  -- Renamed to avoid conflict with global fieldDef struct
					
					-- Skip padding fields
					if fDef.type == #padding then continue
					
					-- Block filter: skip any field that is not the requested block
					if onlyBlock != "" and fieldName != onlyBlock then continue
					
					if fDef.type == #block or fDef.type == #Block then
					(
						-- This is a reflexive block
						logger.debug "{}'{}':" args:#(pad, fieldName)
						if classOf fieldValue == Array and fieldValue.count > 0 then
						(
							-- Print each entry in the reflexive
							for j = 1 to fieldValue.count do
							(
								logger.debug "{}entry [{}]:" args:#(pad + "    ", j - 1)
								printBlockRecursively fieldValue[j] fDef.fieldBlock indent:(indent + 2)
							)
						)
						else
						(
							logger.debug "{}(No Entries)" args:#(pad + "    ")
						)
					)
					else if fDef.type == #tagReference then
					(
						-- Tag reference
						local tagRefInfo = fieldValue
						if tagRefInfo != undefined and classOf tagRefInfo == Dictionary then
						(
							if tagRefInfo[#path] != "" then
								logger.debug "{}{}: '{}'" args:#(pad, fieldName, tagRefInfo[#path])
							else
								logger.debug "{}{}: 'no path'" args:#(pad, fieldName)
						)
						else
							logger.debug "{}{}: '{}'" args:#(pad, fieldName, fieldValue)
					)
					else
					(
                        -- Regular field
                        if classOf fieldValue == String then
                            logger.debug "{}{}: '{}'" args:#(pad, fieldName, fieldValue)
                        else
						logger.debug "{}{}: {}" args:#(pad, fieldName, fieldValue)
					)
				)
			)
		)
	)
	ok
)
