-------------------------------------------------------
-- REFLEXIVE DATA READERS (CORRECTED VERSION)
-- Reads actual reflexive data using robust pointer system
-------------------------------------------------------


-------------------------------------------------------
-- Materials Tag Block
-------------------------------------------------------

-- Materials block reader following robust pointer system
fn readMaterialsBlock materialsReflexive regionsReflexive pathfindingSpheresReflexive nodesReflexive =
(
	--format "\n=== READING MATERIALS BLOCK ===\n"
	
	-- Unpack reflexive info
	local materialsCount = if materialsReflexive != undefined and materialsReflexive.count > 0 then materialsReflexive[1] else 0
	local materialsPointer = if materialsReflexive != undefined and materialsReflexive.count > 1 then materialsReflexive[2] else 0
	
	--format "Materials count: %\n" materialsCount
	--format "Materials pointer: %\n" materialsPointer
	
	if materialsCount == 0 then (
		--format "No materials to read.\n"
		return #()
	)
	
	local materials = #()
	local materialsDataOffset = 0
	
	-- Follow proper Halo tag pointer system
	if materialsPointer > 0 then
	(
		-- Absolute pointer - seek directly to materials data
		--format "[DEBUG] Using absolute pointer: %\n" materialsPointer
		materialsDataOffset = materialsPointer
	)
	else
	(
		-- Pointer = 0: data laid out sequentially after main tagdata struct
		-- Main tagdata struct ends at: 64 (blam_header) + 664 (tagdata) = 728
		local dataBlockStart = 728
		
		-- Calculate total size of all TagRef path strings in the file
		-- These strings are stored between the main struct and the reflexive data
		-- Path length includes null terminator, and paths are padded to 4-byte alignment
		-- EXCEPT the last path string which may not be padded
		local totalTagRefPathSize = 0
		local allPathLengths = #()
		
		-- Scan through the body section TagRefs (5 TagRefs at specific offsets)
		local fileHandle = getCurrentFileHandle()
		local savedPos = ftell fileHandle
		
		-- Body section TagRefs (offsets relative to body start at 72):
		-- localized_damage_effect at 72+104=176, area_damage_effect at 72+124=196,
		-- body_damaged_effect at 72+144=216, body_depleted_effect at 72+160=232,
		-- body_destroyed_effect at 72+180=252
		local bodyTagRefOffsets = #(176, 196, 216, 232, 252)
		
	for offset in bodyTagRefOffsets do
	(
		fseek fileHandle offset #seek_set
		fseek fileHandle 8 #seek_cur -- Skip to path_length field
		local pathLength = read.longB "#signed"
		if pathLength > 0 then
		(
			-- path_length does NOT include null terminator - add 1
			local actualLength = pathLength + 1
			--format "[DEBUG] TagRef at offset %: path_length=%, actual=%\n" offset pathLength actualLength
			append allPathLengths actualLength
		)
	)		-- Shield section TagRefs (offsets relative to shield start at 268):
		-- shield_damaged_effect at 268+188=456, shield_depleted_effect at 268+204=472,
		-- shield_recharging_effect at 268+220=488
		local shieldTagRefOffsets = #(456, 472, 488)
		
	for offset in shieldTagRefOffsets do
	(
		fseek fileHandle offset #seek_set
		fseek fileHandle 8 #seek_cur -- Skip to path_length field
		local pathLength = read.longB "#signed"
		if pathLength > 0 then
		(
			-- path_length does NOT include null terminator - add 1
			local actualLength = pathLength + 1
			--format "[DEBUG] TagRef at offset %: path_length=%, actual=%\n" offset pathLength actualLength
			append allPathLengths actualLength
		)
	)		-- Check if all paths have the same length
		local allSameLength = true
		if allPathLengths.count > 1 then
		(
			local firstLength = allPathLengths[1]
			for i = 2 to allPathLengths.count do
			(
				if allPathLengths[i] != firstLength then
				(
					allSameLength = false
					exit
				)
			)
		)
		
	-- Calculate total size
	-- Paths are stored consecutively WITHOUT padding
	for i = 1 to allPathLengths.count do
	(
		local pathLength = allPathLengths[i]
		totalTagRefPathSize += pathLength
		--format "[DEBUG] Path %: length=%\n" i pathLength
	)		-- DEBUG: Read hex bytes at data block start to verify what's there
		fseek fileHandle dataBlockStart #seek_set
		local hexDump = ""
		for i = 1 to 80 do (
			local b = readByte fileHandle #unsigned
			hexDump += (formattedPrint b format:"02X ")
			if (mod i 16) == 0 then hexDump += "\n"
		)
		--format "[DEBUG] First 80 bytes at dataBlockStart (%): \n%\n" dataBlockStart hexDump
		
	-- Restore file position
	fseek fileHandle savedPos #seek_set
	
	-- Materials start immediately after paths (no alignment)
	materialsDataOffset = dataBlockStart + totalTagRefPathSize
	--format "[DEBUG] Materials offset: % (paths total %)\n" materialsDataOffset totalTagRefPathSize
	
	fseek fileHandle savedPos #seek_set
	--format "[DEBUG] Final materials offset: %\n" materialsDataOffset
    )

    -- Seek to the calculated start of the materials data
    --format "[DEBUG] Final materials offset: %\n" materialsDataOffset
	seekToPosition materialsDataOffset
	
	-- Read each material (72 bytes each)
	for i = 1 to materialsCount do
	(
		local material = collisionMaterials()
		
		-- Read material name (32 bytes at offset 0)
		material.name = read.tagString 32
		
		-- Read flags (4 bytes at offset 32)
		local flagsValue = read.longB "#unsigned"
		material.flags = if flagsValue == 1 then #("head") else #("none")
		
		-- Read material type (2 bytes at offset 36)
		material.material_type = read.shortB "#signed"
		
		-- Skip 2 bytes padding (offset 38-39)
		skipBytes 2
		
		-- Read shield leak percentage (4 bytes at offset 40)
		material.shield_leak_percentage = read.floatB()
		
		-- Read shield damage multiplier (4 bytes at offset 44)
		material.shield_damage_multiplier = read.floatB()
		
		-- Skip 12 bytes (offset 48-59) to reach body_damage_multiplier at offset 60
		skipBytes 12
		
		-- Read body damage multiplier (4 bytes at offset 60)
		material.body_damage_multiplier = read.floatB()
		
		-- Skip remaining 8 bytes to complete 72-byte structure (offset 64-71)
		skipBytes 8
		
		-- Store material
		append materials material
		
		-- Display material info
		--format "[%] Name: '%'\n" (i - 1) material.name
		--format "Type: '%' (%)\n" (materialTypeToString material.material_type) material.material_type
		--format "Flags: %\n" material.flags
		--format "Shield Leak: %\n" material.shield_leak_percentage
		--format "Shield Damage Multiplier: %\n" material.shield_damage_multiplier
		--format "Body Damage Multiplier: %\n" material.body_damage_multiplier
		--format "\n"n"
	)
	
	--format "Successfully read % materials\n" materials.count
	-- Return both materials array and the offset where materials data started
	return #(materials, materialsDataOffset)
)

-------------------------------------------------------
-- Regions Tag Block
-------------------------------------------------------

fn readRegionsBlock regionsReflexive materialsReflexive materialsDataOffset =
(
	local regionsCount = regionsReflexive[1]
	local materialsCount = materialsReflexive[1]
	
	if regionsCount == 0 then
	(
		format "\n=== NO REGIONS TO READ ===\n"
		return #()
	)
	
	--format "\n=== READING REGIONS BLOCK ===\n"
	--format "Regions count: %\n" regionsCount
	
	-- Calculate regions offset: materials end + regions data
	-- Each material is 72 bytes
	local regionsDataOffset = materialsDataOffset + (materialsCount * 72)
	--format "[DEBUG] Regions offset: %\n" regionsDataOffset
	
	-- Seek to regions data
	seekToPosition regionsDataOffset
	
	local regions = #()
	local allPermutationsReflexives = #()  -- Store all permutation reflexives to read later
	
	for i = 1 to regionsCount do
	(
		local region = collisionRegions()
		
		-- Read region name (32 bytes at offset 0)
		region.name = read.tagString 32
		
		-- Read flags (4 bytes at offset 32)
		local flagsValue = read.longB "#unsigned"
		local regionFlagNames = #(
			"lives_until_object_dies",
			"forces_object_to_die",
			"dies_when_object_dies",
			"dies_when_object_is_damaged",
			"disappears_when_shield_is_off",
			"inhibits_melee_attack",
			"inhibits_weapon_attack",
			"inhibits_walking",
			"forces_drop_weapon",
			"causes_head_maimed_scream"
		)
		
		region.flags = decodeFlagBits flagsValue regionFlagNames
		
		-- Skip 4 bytes (offset 36-39) to reach damage_threshold at offset 40
		skipBytes 4
		
		-- Read damage threshold (4 bytes at offset 40)
		region.damage_threshold = read.floatB()
		
		-- Skip 12 bytes (offset 44-55) to reach destroyed_effect at offset 56
		skipBytes 12
		
		-- Read destroyed_effect TagRef (16 bytes at offset 56)
		region.destroyed_effect = read.tagRef()
		
		-- Read permutations reflexive (12 bytes at offset 72)
		local permutationsReflexive = read.reflexive()
		append allPermutationsReflexives permutationsReflexive
		
		-- Store region
		append regions region
	)
	
	-- Now read all permutations data (comes after all regions AND their TagRef paths)
	-- Calculate permutations offset: regions end + TagRef path strings
	-- Each region is 84 bytes
	local regionsStructEnd = regionsDataOffset + (regionsCount * 84)
	
	-- Calculate total size of TagRef path strings for all regions
	-- Each region has one destroyed_effect TagRef
	local totalPathBytes = 0
	for i = 1 to regionsCount do
	(
		local destroyedEffectRef = regions[i].destroyed_effect
		if destroyedEffectRef != undefined and destroyedEffectRef.count >= 3 then
		(
			local pathLength = destroyedEffectRef[3]
			if pathLength > 0 then
				totalPathBytes += (pathLength + 1)  -- +1 for null terminator
		)
	)
	
	local permutationsDataOffset = regionsStructEnd + totalPathBytes
	--format "[DEBUG] Permutations offset: % (regions end: %, paths: %)\n" permutationsDataOffset regionsStructEnd totalPathBytes
	
	seekToPosition permutationsDataOffset
	
	-- Read permutations for each region
	for i = 1 to regionsCount do
	(
		local permutationsCount = allPermutationsReflexives[i][1]
		local permutations = #()
		
		for j = 1 to permutationsCount do
		(
			local permutation = regionPermutations()
			-- Read permutation name (32 bytes)
			permutation.name = read.tagString 32
			append permutations permutation
		)
		
		regions[i].permutations = permutations
	)
	
	-- Display region info
	--for i = 1 to regions.count do
	--(
	--	local region = regions[i]
	--	format "[%] Name: '%'\n" (i - 1) region.name
	--	format "Flags: %\n" region.flags
	--	format "Damage Threshold: %\n" region.damage_threshold
	--	format "Permutations: %\n" region.permutations.count
	--	if region.permutations.count > 0 then
	--	(
	--		for p = 1 to region.permutations.count do
	--			format "  [%] '%'\n" (p - 1) region.permutations[p].name
	--	)
	--	format "\n"
	--)
	
		--	format "\n"
	--)
	
	--format "Successfully read % regions\n" regions.count
	
	-- Calculate total permutations read for offset calculation
	
	-- Calculate total permutations read for offset calculation
	local totalPermutations = 0
	for i = 1 to regions.count do
		totalPermutations += regions[i].permutations.count
	
	-- Calculate end offset: permutations data end
	-- Each permutation is 32 bytes
	local regionsEndOffset = permutationsDataOffset + (totalPermutations * 32)
	
	-- Return regions array and end offset for next block
	return #(regions, regionsEndOffset)
)

-------------------------------------------------------
-- Pathfinding Spheres Tag Block
-------------------------------------------------------

fn readPathfindingSpheresBlock pathfindingSpheresReflexive modifiersEndOffset =
(
	local spheresCount = pathfindingSpheresReflexive[1]
	
	if spheresCount == 0 then
	(
		format "\n=== NO PATHFINDING SPHERES TO READ ===\n"
		return #()
	)
	
	--format "\n=== READING PATHFINDING SPHERES BLOCK ===\n"
	--format "Pathfinding Spheres count: %\n" spheresCount
	
	-- Pathfinding spheres start after modifiers
	local spheresDataOffset = modifiersEndOffset
	--format "[DEBUG] Pathfinding Spheres offset: %\n" spheresDataOffset
	
	-- Seek to spheres data
	seekToPosition spheresDataOffset
	
	local spheres = #()
	
	for i = 1 to spheresCount do
	(
		local sphere = collisionPathfindingSpheres()
		
		-- Read node index (2 bytes at offset 0)
		sphere.node = read.shortB "#signed"
		
		-- Skip 14 bytes (offset 2-15) to reach center at offset 16
		skipBytes 14
		
		-- Read center point (12 bytes at offset 16: x, y, z)
		local centerX = read.floatB()
		local centerY = read.floatB()
		local centerZ = read.floatB()
		sphere.center = [centerX, centerY, centerZ]
		
		-- Read radius (4 bytes at offset 28)
		sphere.radius = read.floatB()
		
		-- Store sphere
		append spheres sphere
		
		-- Display sphere info
		--format "[%] Node: %\n" (i - 1) sphere.node -- Sphere indices are zero-based
		--format "Center: [%, %, %]\n" sphere.center.x sphere.center.y sphere.center.z
		--format "Radius: %\n" sphere.radius
		--format "\n"
	)
	
	--format "Successfully read % pathfinding spheres\n" spheres.count
	
	-- Calculate end offset for next block
	-- Each sphere is 32 bytes
	local spheresEndOffset = spheresDataOffset + (spheresCount * 32)
	
	return #(spheres, spheresEndOffset)
)

-------------------------------------------------------
-- Nodes Tag Block
-------------------------------------------------------

fn readNodesBlock nodesReflexive spheresEndOffset =
(
	local nodesCount = nodesReflexive[1]
	
	if nodesCount == 0 then
	(
		format "\n=== NO NODES TO READ ===\n"
		return #()
	)
	
	--format "\n=== READING NODES BLOCK ===\n"
	--format "Nodes count: %\n" nodesCount
	
	-- Nodes start after pathfinding spheres
	local nodesDataOffset = spheresEndOffset
	--format "[DEBUG] Nodes offset: %\n" nodesDataOffset
	
	-- Seek to nodes data
	seekToPosition nodesDataOffset
	
	local nodes = #()
	local allBSPsReflexives = #()  -- Store BSP reflexives for later reading
	
	for i = 1 to nodesCount do
	(
		local node = collisionNodes()
		
		-- Read node name (32 bytes at offset 0)
		node.name = read.tagString 32
		
		-- Read region index (2 bytes at offset 32)
		node.region = read.shortB "#signed"
		
		-- Read parent node (2 bytes at offset 34)
		node.parent_node = read.shortB "#signed"
		
		-- Read next sibling node (2 bytes at offset 36)
		node.next_sibling_node = read.shortB "#signed"
		
		-- Read first child node (2 bytes at offset 38)
		node.first_child_node = read.shortB "#signed"
		
		-- Skip 8 bytes (offset 40-47) to reach unknown fields at offset 48
		skipBytes 8
		
		-- Read unknown fields (4 bytes at offset 48-51)
		node.unknown0 = read.shortB "#signed"
		node.unknown1 = read.shortB "#signed"
		
		-- Read BSPs reflexive (12 bytes at offset 52)
		local bspsReflexive = read.reflexive()
		node.bsps_tag_block = bspsReflexive
		append allBSPsReflexives bspsReflexive
		
		-- Store node
		append nodes node
		
		-- Display node info
		--format "[%] Name: '%'\n" (i - 1) node.name -- Node indices are zero-based
		--format "Region: %\n" node.region
		--format "Parent: %\n" node.parent_node
        --format "Next Sibling: %\n" node.next_sibling_node
        --format "First Child: %\n" node.first_child_node
        --format "BSPs: %\n" bspsReflexive[1]
		--format "\n"
	)
	
	--format "Successfully read % nodes\n" nodes.count
	
	-- Calculate nodes end offset (each node is 64 bytes)
	local nodesEndOffset = nodesDataOffset + (nodesCount * 64)
	
	-- Now read BSP geometry data for all nodes
	--format "\n=== READING BSP GEOMETRY FOR ALL NODES ===\n"
	nodes = readAllNodesBSPGeometry nodes nodesDataOffset
	
	return nodes
)