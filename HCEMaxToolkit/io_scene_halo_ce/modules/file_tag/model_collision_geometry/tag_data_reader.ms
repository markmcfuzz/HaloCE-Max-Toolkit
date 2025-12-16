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
-- Materials Tag Block
-------------------------------------------------------

fn readMaterialsBlock materialsReflexive regionsReflexive pathfindingSpheresReflexive nodesReflexive =
(
    -------------------------------------------------------------------
    -- Unpack reflexive struct
    -------------------------------------------------------------------
    local materialsCount   = if materialsReflexive != undefined then materialsReflexive.count   else 0
    local materialsPointer = if materialsReflexive != undefined then materialsReflexive.pointer else 0

    if materialsCount == 0 then
    (
        local result = materialsBlockResult()
        result.materials = #()
        result.endOffset = 0
        return result
    )

    local materials = #()
    local materialsDataOffset = 0
    -------------------------------------------------------------------
    -- Follow proper pointer interpretation
    -------------------------------------------------------------------
    if materialsPointer > 0 then
    (
        materialsDataOffset = materialsPointer
    )
    else
    (
        local dataBlockStart = 728
        local totalTagRefPathSize = 0
        local allPathLengths = #()
        local fileHandle = getCurrentFileHandle()
        local savedPos = ftell fileHandle
        -------------------------------------------------------------------
        -- Body TagRefs
        -------------------------------------------------------------------
        local bodyTagRefOffsets = #(176, 196, 216, 232, 252)
        for offset in bodyTagRefOffsets do
        (
			seekToPosition offset seekMode:#seek_set
			skipBytes 8
            local pathLength = read.longB "#signed"
            if pathLength > 0 then 
			append allPathLengths (pathLength + 1)
        )
        -------------------------------------------------------------------
        -- Shield TagRefs
        -------------------------------------------------------------------
        local shieldTagRefOffsets = #(456, 472, 488)
        for offset in shieldTagRefOffsets do
        (
			seekToPosition offset seekMode:#seek_set
			skipBytes 8
            local pathLength = read.longB "#signed"
            if pathLength > 0 then 
			append allPathLengths (pathLength + 1)
        )
        -------------------------------------------------------------------
        -- Compute total size of path strings
        -------------------------------------------------------------------
        for i = 1 to allPathLengths.count do
        (
            totalTagRefPathSize += allPathLengths[i]
        )
        materialsDataOffset = dataBlockStart + totalTagRefPathSize
        fseek fileHandle savedPos #seek_set
    )
    -------------------------------------------------------------------
    -- Read material block
    -------------------------------------------------------------------
    seekToPosition materialsDataOffset
    for i = 1 to materialsCount do
    (
        local name = read.tagString 32
        
        local flagsValue = read.longB "#unsigned"
        local flags = if flagsValue == 1 then ("head") else ("none")
        
        local materialType = read.shortB "#signed"
        
        skipBytes 2
        
        local shieldLeakPercentage = read.floatB()
        local shieldDamageMultiplier = read.floatB()
        
        skipBytes 12
        
        local bodyDamageMultiplier = read.floatB()
        
        skipBytes 8
        
		local material = returnMaterials()
		material.name = name
		material.flags = flags
		material.materialType = materialType
		material.shieldLeakPercentage = shieldLeakPercentage
		material.shieldDamageMultiplier = shieldDamageMultiplier
		material.bodyDamageMultiplier = bodyDamageMultiplier

        append materials material
    )

    local result = materialsBlockResult()
    result.materials = materials
    result.endOffset = materialsDataOffset
    return result
)

-------------------------------------------------------
-- Regions Tag Block
-------------------------------------------------------

fn readRegionsBlock regionsReflexive materialsReflexive materialsDataOffset =
(
	local regionsCount = regionsReflexive.count
	local materialsCount = materialsReflexive.count
	
	if regionsCount == 0 then
	(
		local result = regionsBlockResult()
		result.regions = #()
		result.endOffset = materialsDataOffset
		return result
	)
	local regionsDataOffset = materialsDataOffset + (materialsCount * 72)

	seekToPosition regionsDataOffset
	
	local regions = #()
	local allPermutationsReflexives = #()  -- Store all permutation reflexives to read later
	
	for i = 1 to regionsCount do
	(
		local name = read.tagString 32
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
		local flags = decodeFlagBits flagsValue regionFlagNames
		skipBytes 4
		local damageThreshold = read.floatB()
		skipBytes 12
		local destroyedEffect = read.tagRef()
		local permutationsReflexive = read.reflex()
		append allPermutationsReflexives permutationsReflexive
		local region = returnRegions()
		region.name = name
		region.flags = flags
		region.damageThreshold = damageThreshold
		region.destroyedEffect = destroyedEffect
		region.permutations = #()
		
		append regions region
	)
	local regionsStructEnd = regionsDataOffset + (regionsCount * 84)
	local pathsStartOffset = regionsDataOffset + (regionsCount * 84)
	seekToPosition pathsStartOffset
	
	local fh = getCurrentFileHandle()
	
	for i = 1 to regionsCount do
	(
		local tagRef = regions[i].destroyedEffect
		
		if tagRef != undefined and tagRef.pathPtr == 0 and tagRef.pathLen > 0 then
		(
			local pathString = read.nullTerminatedString()
			if pathString.count > 0 then
				regions[i].destroyedEffect.path = pathString
		)
		local permutationsReflex = allPermutationsReflexives[i]
		if permutationsReflex != undefined then
		(
			local permCount = permutationsReflex.count
			local permutations = #()
			for p = 1 to permCount do
			(
				local permName = read.tagString 32
				local permutation = returnPermutation name:permName
				append permutations permutation
			)
			
			regions[i].permutations = permutations
		)
	)
	local currentPos = getCurrentFilePosition()
	local result = regionsBlockResult()
	result.regions = regions
	result.endOffset = currentPos
	return result
)

-------------------------------------------------------
-- Pathfinding Spheres Tag Block
-------------------------------------------------------

fn readPathfindingSpheresBlock pathfindingSpheresReflexive modifiersEndOffset nodes:#() =
(
	local spheresCount = pathfindingSpheresReflexive.count
	
	if spheresCount == 0 then
	(
		local result = spheresBlockResult()
		result.spheres = #()
		result.endOffset = modifiersEndOffset
		return result
	)
	
	local spheresDataOffset = modifiersEndOffset

	seekToPosition spheresDataOffset
	
	local spheres = #()
	for i = 1 to spheresCount do
	(
		local node = read.shortB "#signed"
		skipBytes 14
		local centerX = read.floatB()
		local centerY = read.floatB()
		local centerZ = read.floatB()
		local center = [centerX, centerY, centerZ]
		local radius = read.floatB()
		local sphere = returnPathfindingSpheres()
		sphere.node = node
		sphere.center = center
		sphere.radius = radius
		
		append spheres sphere
	)
	for sphere in spheres do
	(
		try
		(
			if sphere.node == -1 then
				sphere.nodeName = "NULL"
			else if nodes != undefined and nodes.count > 0 and sphere.node >= 0 and sphere.node < nodes.count then
				sphere.nodeName = nodes[sphere.node + 1].name  -- +1 for 1-based indexing
			else if nodes != undefined and nodes.count > 0 then
				sphere.nodeName = "INVALID(" + (sphere.node as string) + ")"
			else
				sphere.nodeName = "[" + (sphere.node as string) + "]"
		)
		catch
		(
			sphere.nodeName = "[" + (sphere.node as string) + "]"
		)
	)
	local spheresEndOffset = spheresDataOffset + (spheresCount * 32)
	
	local result = spheresBlockResult()
	result.spheres = spheres
	result.endOffset = spheresEndOffset
	return result
)

-------------------------------------------------------
-- Nodes Tag Block
-------------------------------------------------------

fn readNodesBlock nodesReflexive spheresEndOffset regions:#() =
(
	local nodesCount = nodesReflexive.count
	
	if nodesCount == 0 then
	(
		return #()
	)
	local nodesDataOffset = spheresEndOffset
	
	seekToPosition nodesDataOffset
	
	local nodes = #()
	local allBSPsReflexives = #()
	for i = 1 to nodesCount do
	(
		local nodeName = read.tagString 32
		local region = read.shortB "#signed"
		local parentNode = read.shortB "#signed"
		local nextSiblingNode = read.shortB "#signed"
		local firstChildNode = read.shortB "#signed"
		
		skipBytes 8
		
		local unknown0 = read.shortB "#signed"
		local unknown1 = read.shortB "#signed"
		local bspsReflexive = read.reflex()
		
		append allBSPsReflexives bspsReflexive

		local node = returnNodes()
		node.name = nodeName
		node.region = region
		node.parentNode = parentNode
		node.nextSiblingNode = nextSiblingNode
		node.firstChildNode = firstChildNode
		node.unknown0 = unknown0
		node.unknown1 = unknown1
		node.bspsReflexive = bspsReflexive
		
		append nodes node
	)
	for node in nodes do
	(
		try
		(
			if node.region == -1 then
				node.regionName = "NULL"
			else if regions != undefined and regions.count > 0 and node.region >= 0 and node.region < regions.count then
				node.regionName = regions[node.region + 1].name  -- +1 for 1-based indexing
			else if regions != undefined and regions.count > 0 then
				node.regionName = "INVALID(" + (node.region as string) + ")"
			else
				node.regionName = "[" + (node.region as string) + "]"
		)
		catch
		(
			node.regionName = "[" + (node.region as string) + "]"
		)
	)
	local nodesEndOffset = nodesDataOffset + (nodesCount * 64)
	nodes = readAllNodesBSPGeometry nodes nodesDataOffset
	return nodes
)

logger "Data tag reader loaded.\n" logType:#success