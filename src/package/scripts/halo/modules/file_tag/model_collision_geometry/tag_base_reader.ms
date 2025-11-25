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
-- Tag Header (64 bytes)
-------------------------------------------------------

fn readTagHeader =
(
    seekToPosition 36
    local tagClass = read.longB "#unsigned"
    seekToPosition 40
    local checksum = read.longB "#unsigned"
    seekToPosition 56
    local version = read.shortB "#unsigned"
    seekToPosition 60
    local engineId = read.longB "#unsigned"
    local expectedGbxFourcc = getFourccByTagName "coll"

    if tagClass != expectedGbxFourcc then
    (
        logger "Invalid tag class. Expected: %, Found: %\n" params:#(expectedGbxFourcc, tagClass) logType:#error
        return undefined
    )

    local header = returnHeader()
    header.tagClass = tagClass
    header.checksum = checksum
    header.version = version
    header.engineId = engineId
    return header
)

-------------------------------------------------------
-- Tag Flags and Indirect Damage (6 bytes at offset 64)
-------------------------------------------------------

fn readMainFlags =
(
    seekToPosition 64
    local flagsValue = read.longB "#unsigned"
    local flagNames = #(
        "takes_shield_damage_for_children",
        "takes_body_damage_for_children",
        "always_shields_friendly_damage",
        "passes_area_damage_to_children",
        "parent_never_takes_body_damage_for_us",
        "only_damaged_by_explosives", 
        "only_damaged_while_occupied"
    )
    local activeFlags = decodeFlagBits flagsValue flagNames
    local indirectDamageMaterial = read.shortB "#signed"
    skipBytes 2

    local mainFlags = returnFlags()
    mainFlags.flags = activeFlags
    mainFlags.indirectDamageMaterial = indirectDamageMaterial

    return mainFlags
)

-------------------------------------------------------  
-- Body Section Reading (196 bytes at offset 72)
-------------------------------------------------------

fn readBodySection =
(
    seekToPosition 72
    local currentPos = getCurrentFilePosition()    
    local maxBodyVitality = read.floatB()
    local bodySystemShock = read.floatB()
    skipBytes 52
    local friendlyDamageResistance = read.floatB()
    skipBytes 40
    local localizedDamageEffect = read.tagRef()
    local areaDamageEffectThreshold = read.floatB()
    local areaDamageEffect = read.tagRef()
    local bodyDamagedThreshold = read.floatB()
    local bodyDamagedEffect = read.tagRef()
    local bodyDepletedEffect = read.tagRef()
    local bodyDestroyedThreshold = read.floatB()
    local bodyDestroyedEffect = read.tagRef()

    local body = returnBody()
    body.maximumBodyVitality = maxBodyVitality
    body.bodySystemShock = bodySystemShock
    body.friendlyDamageResistance = friendlyDamageResistance
    body.localizedDamageEffect = localizedDamageEffect
    body.areaDamageEffectThreshold = areaDamageEffectThreshold
    body.areaDamageEffect = areaDamageEffect
    body.bodyDamagedThreshold = bodyDamagedThreshold
    body.bodyDamagedEffect = bodyDamagedEffect
    body.bodyDepletedEffect = bodyDepletedEffect
    body.bodyDestroyedThreshold = bodyDestroyedThreshold
    body.bodyDestroyedEffect = bodyDestroyedEffect
    
    return body
)

-------------------------------------------------------
-- Shield Section Reading (248 bytes at offset 268)  
-------------------------------------------------------

fn readShieldSection =
(
    local currentPos = getCurrentFilePosition()    
    local maxShieldVitality = read.floatB()
    
    skipBytes 2
    
    local shieldMaterialType = read.shortB "#signed"
    
    skipBytes 24
    
    local shieldFailureFunction = read.shortB "#signed"
    
    skipBytes 2
    
    local shieldFailureThreshold = read.floatB()
    local shieldFailingLeakFraction = read.floatB()
    
    skipBytes 16
    
    local minStunDamage = read.floatB()
    local stunTime = read.floatB()
    local rechargeTime = read.floatB()
    
    skipBytes 112
    
    local shieldDamagedThreshold = read.floatB()
    local shieldDamagedEffect = read.tagRef()
    local shieldDepletedEffect = read.tagRef()
    local shieldRechargingEffect = read.tagRef()
    skipBytes 8
    local shieldRechargeRate = read.floatB()
    
    local shield = returnShield()
    shield.maximumShieldVitality = maxShieldVitality
    shield.shieldMaterialType = shieldMaterialType
    shield.shieldFailureFunction = shieldFailureFunction
    shield.shieldFailureThreshold = shieldFailureThreshold
    shield.shieldFailingLeakFraction = shieldFailingLeakFraction
    shield.minimumStunDamage = minStunDamage
    shield.stunTime = stunTime
    shield.rechargeTime = rechargeTime
    shield.shieldDamagedThreshold = shieldDamagedThreshold
    shield.shieldDamagedEffect = shieldDamagedEffect
    shield.shieldDepletedEffect = shieldDepletedEffect
    shield.shieldRechargingEffect = shieldRechargingEffect
    
    return shield
)

-------------------------------------------------------
-- Reflexive Headers Reading (at offset 564)
-------------------------------------------------------

fn readReflexiveHeaders =
(
    local actualReflexiveStart = 628
    seekToPosition actualReflexiveStart

    local materialsReflexive = read.reflex()
    local regionsReflexive = read.reflex()
    local modifiersReflexive = read.reflex()
    local currentPos = getCurrentFilePosition()

    seekToPosition (64 + 616)

    local pathfindingBoxX = #( read.floatB(), read.floatB() )
    local pathfindingBoxY = #( read.floatB(), read.floatB() )
    local pathfindingBoxZ = #( read.floatB(), read.floatB() )
    local pfSpheresReflexive = read.reflex()
    local nodesReflexive = read.reflex()

    local reflexives = returnReflexives()
    reflexives.materials = materialsReflexive
    reflexives.regions = regionsReflexive
    reflexives.modifiers = modifiersReflexive
    reflexives.spheres = pfSpheresReflexive
    reflexives.nodes = nodesReflexive
    reflexives.boxX = pathfindingBoxX
    reflexives.boxY = pathfindingBoxY
    reflexives.boxZ = pathfindingBoxZ

    return reflexives
)

-------------------------------------------------------
-- Read Body and Shield TagRef Inline Paths
-- Reads inline paths stored at offset 728 for TagRefs with pathPtr==0
-------------------------------------------------------

fn readBodyShieldInlinePaths bodyStruct shieldStruct =
(
    seekToPosition 728

    if bodyStruct.localizedDamageEffect.pathPtr == 0 and bodyStruct.localizedDamageEffect.pathLen > 0 then
        bodyStruct.localizedDamageEffect.path = read.nullTerminatedString()
    
    if bodyStruct.areaDamageEffect.pathPtr == 0 and bodyStruct.areaDamageEffect.pathLen > 0 then
        bodyStruct.areaDamageEffect.path = read.nullTerminatedString()
    
    if bodyStruct.bodyDamagedEffect.pathPtr == 0 and bodyStruct.bodyDamagedEffect.pathLen > 0 then
        bodyStruct.bodyDamagedEffect.path = read.nullTerminatedString()
    
    if bodyStruct.bodyDepletedEffect.pathPtr == 0 and bodyStruct.bodyDepletedEffect.pathLen > 0 then
        bodyStruct.bodyDepletedEffect.path = read.nullTerminatedString()
    
    if bodyStruct.bodyDestroyedEffect.pathPtr == 0 and bodyStruct.bodyDestroyedEffect.pathLen > 0 then
        bodyStruct.bodyDestroyedEffect.path = read.nullTerminatedString()
    
    if shieldStruct.shieldDamagedEffect.pathPtr == 0 and shieldStruct.shieldDamagedEffect.pathLen > 0 then
        shieldStruct.shieldDamagedEffect.path = read.nullTerminatedString()
    
    if shieldStruct.shieldDepletedEffect.pathPtr == 0 and shieldStruct.shieldDepletedEffect.pathLen > 0 then
        shieldStruct.shieldDepletedEffect.path = read.nullTerminatedString()
    
    if shieldStruct.shieldRechargingEffect.pathPtr == 0 and shieldStruct.shieldRechargingEffect.pathLen > 0 then
        shieldStruct.shieldRechargingEffect.path = read.nullTerminatedString()
)

-------------------------------------------------------
-- Collision Reader Main Function
-------------------------------------------------------

fn readCollisionTag filePath =
(
    local fileHandle = fopen filePath "rb"
    if fileHandle == undefined then
    (
        return undefined
    )
    
    setFileHandle fileHandle
    in_file = fileHandle
    
    local tagStruct = collisionTag()
    
    local tagHeader = readTagHeader()
    if tagHeader == undefined then
    (
        fclose fileHandle
        return undefined
    )
    tagStruct.header = tagHeader
    
    tagStruct.flags = readMainFlags()
    
    tagStruct.body = readBodySection()
    
    tagStruct.shield = readShieldSection()
    
    readBodyShieldInlinePaths tagStruct.body tagStruct.shield
    
    local coll = readReflexiveHeaders()
    tagStruct.materialsTagBlock = coll.materials
    tagStruct.regionsTagBlock = coll.regions
    tagStruct.modifiersTagBlock = coll.modifiers
    tagStruct.pathfindingSpheresTagBlock = coll.spheres
    tagStruct.pathfindingBoxX = coll.boxX
    tagStruct.pathfindingBoxY = coll.boxY
    tagStruct.pathfindingBoxZ = coll.boxZ
    tagStruct.nodesTagBlock = coll.nodes
    
	local materialsDataOffset = 0
    if coll.materials.count > 0 then
    (
        local materialsResult = readMaterialsBlock coll.materials coll.regions coll.spheres coll.nodes
		tagStruct.materials = materialsResult.materials
		materialsDataOffset = materialsResult.endOffset
    )
    
	local regionsEndOffset = materialsDataOffset
    if coll.regions.count > 0 then
    (
        local regionsResult = readRegionsBlock coll.regions coll.materials materialsDataOffset
		tagStruct.regions = regionsResult.regions
		regionsEndOffset = regionsResult.endOffset
    )
    
	local modifiersCount = coll.modifiers.count
	local modifiersEndOffset = regionsEndOffset + (modifiersCount * 52)
    
    local spheresEndOffset = modifiersEndOffset
    if coll.spheres.count > 0 then
        spheresEndOffset = modifiersEndOffset + (coll.spheres.count * 32)
    
    if coll.nodes.count > 0 then
    (
        tagStruct.nodes = readNodesBlock coll.nodes spheresEndOffset regions:tagStruct.regions
    )
    else
    (
        tagStruct.nodes = #()
    )
    
    if coll.spheres.count > 0 then
    (
        local spheresResult = readPathfindingSpheresBlock coll.spheres modifiersEndOffset nodes:tagStruct.nodes
		tagStruct.pathfindingSpheres = spheresResult.spheres
    )
    else
    (
        tagStruct.pathfindingSpheres = #()
    )
    fclose fileHandle
    return tagStruct
)

logger "Base tag reader loaded.\n" logType:#success