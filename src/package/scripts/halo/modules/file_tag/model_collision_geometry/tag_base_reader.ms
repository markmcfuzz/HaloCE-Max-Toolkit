-- HALO CE COLLISION TAG READER v3.0 (Clean Rewrite)
-- Modular, structure-based approach following HEK definitions exactly


-------------------------------------------------------
-- Tag Header (64 bytes)
-------------------------------------------------------

fn readTagHeader =
(
    -- format "=== READING TAG HEADER ===\n"
    
    -- Seek to tag class (offset 36 in header)
    seekToPosition 36
    local tagClass = read.longB "#unsigned"
    
    -- Seek to version (offset 56 in header)  
    seekToPosition 56
    local version = read.shortB "#unsigned"
    
    -- Validate tag class
    local expectedCollFourcc = getFourccByTagName "coll"
    if tagClass != expectedCollFourcc then
    (
        -- format "[ERROR] Invalid tag class. Expected: %, Found: %\n" expectedCollFourcc tagClass
        return undefined
    )
    
    -- format "Valid collision tag: version %\n" version
    return #(tagClass, version)
)

-------------------------------------------------------
-- Tag Flags and Indirect Damage (6 bytes at offset 64)
-------------------------------------------------------

fn readMainFlags =
(
    -- format "\n=== READING MAIN FLAGS ===\n"
    
    -- Seek to start of tag data (offset 64)
    seekToPosition 64
    
    -- Read flags (4 bytes)
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
    
    -- Read indirect damage material (2 bytes)
    local indirectDamageMaterial = read.shortB "#signed"
    
    -- Skip padding (2 bytes)
    skipBytes 2
    
    -- format "Flags: %\n" activeFlags
    -- format "Indirect Damage Material: %\n" indirectDamageMaterial
    
    return #(activeFlags, indirectDamageMaterial)
)

-------------------------------------------------------  
-- Body Section Reading (196 bytes at offset 72)
-------------------------------------------------------

fn readBodySection =
(
    -- format "\n=== READING BODY SECTION ===\n"
    
    -- Should already be at offset 72 after readMainFlags
    local currentPos = getCurrentFilePosition()
    -- format "Reading body at position: %\n" currentPos
    
    -- Read maximum body vitality (offset 0 in body)
    local maxBodyVitality = read.floatB()
    
    -- Read body system shock (offset 4 in body) 
    local bodySystemShock = read.floatB()
    
    -- Skip to friendly damage resistance (offset 60 in body)
    skipBytes 52  -- Skip from offset 8 to 60
    local friendlyDamageResistance = read.floatB()
    
    -- Skip to localized damage effect (offset 104 in body)
    skipBytes 40  -- Skip from offset 64 to 104
    local localizedDamageEffect = read.tagRef()
    
    -- Read area damage threshold (offset 120 in body)
    local areaDamageThreshold = read.floatB()
    
    -- Read area damage effect (offset 124 in body)
    local areaDamageEffect = read.tagRef()
    
    -- Read body damaged threshold (offset 140 in body)
    local bodyDamagedThreshold = read.floatB()
    
    -- Read body damaged effect (offset 144 in body)
    local bodyDamagedEffect = read.tagRef()
    
    -- Read body depleted effect (offset 160 in body)
    local bodyDepletedEffect = read.tagRef()
    
    -- Read body destroyed threshold (offset 176 in body)
    local bodyDestroyedThreshold = read.floatB()
    
    -- Read body destroyed effect (offset 180 in body)
    local bodyDestroyedEffect = read.tagRef()
    
    -- Display results
    -- format "Maximum Body Vitality: %\n" maxBodyVitality
    -- format "Body System Shock: %\n" bodySystemShock
    -- format "Friendly Damage Resistance: %\n" friendlyDamageResistance
    -- format "Area Damage Threshold: %\n" areaDamageThreshold
    -- format "Body Damaged Threshold: %\n" bodyDamagedThreshold
    -- format "Body Destroyed Threshold: %\n" bodyDestroyedThreshold
    
    -- Display TagRefs if they exist
    -- if localizedDamageEffect[3] > 0 then
    --     format "Localized Damage Effect: % (% bytes)\n" (getTagClassInfo localizedDamageEffect[1]) localizedDamageEffect[3]
    -- if areaDamageEffect[3] > 0 then
    --     format "Area Damage Effect: % (% bytes)\n" (getTagClassInfo areaDamageEffect[1]) areaDamageEffect[3]
    -- if bodyDamagedEffect[3] > 0 then
    --     format "Body Damaged Effect: % (% bytes)\n" (getTagClassInfo bodyDamagedEffect[1]) bodyDamagedEffect[3]
    -- if bodyDepletedEffect[3] > 0 then
    --     format "Body Depleted Effect: % (% bytes)\n" (getTagClassInfo bodyDepletedEffect[1]) bodyDepletedEffect[3]
    -- if bodyDestroyedEffect[3] > 0 then
    --     format "Body Destroyed Effect: % (% bytes)\n" (getTagClassInfo bodyDestroyedEffect[1]) bodyDestroyedEffect[3]
    
    return #(maxBodyVitality, bodySystemShock, friendlyDamageResistance, areaDamageThreshold,
             bodyDamagedThreshold, bodyDestroyedThreshold, localizedDamageEffect, areaDamageEffect,
             bodyDamagedEffect, bodyDepletedEffect, bodyDestroyedEffect)
)

-------------------------------------------------------
-- Shield Section Reading (248 bytes at offset 268)  
-------------------------------------------------------

fn readShieldSection =
(
    -- format "\n=== READING SHIELD SECTION ===\n"
    
    -- Should be at offset 268 (64 + 6 + 196 + 2 padding) after body section
    local currentPos = getCurrentFilePosition()
    -- format "Reading shield at position: %\n" currentPos
    
    -- Read maximum shield vitality (offset 0 in shield)
    local maxShieldVitality = read.floatB()
    
    -- Skip to shield material type (offset 6 in shield) 
    skipBytes 2
    local shieldMaterialType = read.shortB "#signed"
    
    -- Skip to shield failure function (offset 32 in shield)
    skipBytes 24  -- Skip from offset 8 to 32
    local shieldFailureFunction = read.shortB "#signed"
    
    -- Read shield failure threshold (offset 36 in shield)
    skipBytes 2
    local shieldFailureThreshold = read.floatB()
    
    -- Read shield failing leak fraction (offset 40 in shield)
    local shieldFailingLeakFraction = read.floatB()
    
    -- Skip to minimum stun damage (offset 60 in shield)
    skipBytes 16  -- Skip from offset 44 to 60  
    local minStunDamage = read.floatB()
    
    -- Read stun time (offset 64 in shield)
    local stunTime = read.floatB()
    
    -- Read recharge time (offset 68 in shield)
    local rechargeTime = read.floatB()
    
    -- Skip to shield damaged threshold (offset 184 in shield)
    skipBytes 112  -- Skip from offset 72 to 184
    local shieldDamagedThreshold = read.floatB()
    
    -- Read shield damaged effect (offset 188 in shield)
    local shieldDamagedEffect = read.tagRef()
    
    -- Read shield depleted effect (offset 204 in shield)
    local shieldDepletedEffect = read.tagRef()
    
    -- Read shield recharging effect (offset 220 in shield)
    local shieldRechargingEffect = read.tagRef()
    
    -- Read shield recharge rate (offset 244 in shield)
    skipBytes 8
    local shieldRechargeRate = read.floatB()
    
    -- Display results
    -- format "Maximum Shield Vitality: %\n" maxShieldVitality
    -- format "Shield Material Type: % (%)\n" (materialTypeToString shieldMaterialType) shieldMaterialType
    -- format "Shield Failure Function: % (%)\n" (shieldFailureFunctionToString shieldFailureFunction) shieldFailureFunction
    -- format "Shield Failure Threshold: %\n" shieldFailureThreshold
    -- format "Shield Failing Leak Fraction: %\n" shieldFailingLeakFraction
    -- format "Minimum Stun Damage: %\n" minStunDamage
    -- format "Stun Time: % seconds\n" stunTime
    -- format "Recharge Time: % seconds\n" rechargeTime
    -- format "Shield Damaged Threshold: %\n" shieldDamagedThreshold
    -- format "Shield Recharge Rate: %\n" shieldRechargeRate
    
    -- Display TagRefs if they exist
    -- if shieldDamagedEffect[3] > 0 then
    --     format "Shield Damaged Effect: % (% bytes)\n" (getTagClassInfo shieldDamagedEffect[1]) shieldDamagedEffect[3]
    -- if shieldDepletedEffect[3] > 0 then
    --     format "Shield Depleted Effect: % (% bytes)\n" (getTagClassInfo shieldDepletedEffect[1]) shieldDepletedEffect[3]
    -- if shieldRechargingEffect[3] > 0 then
    --     format "Shield Recharging Effect: % (% bytes)\n" (getTagClassInfo shieldRechargingEffect[1]) shieldRechargingEffect[3]
        
    return #(maxShieldVitality, shieldMaterialType, shieldFailureFunction, shieldFailureThreshold,
             shieldFailingLeakFraction, minStunDamage, stunTime, rechargeTime, shieldDamagedThreshold,
             shieldRechargeRate, shieldDamagedEffect, shieldDepletedEffect, shieldRechargingEffect)
)

-------------------------------------------------------
-- Reflexive Headers Reading (at offset 564)
-------------------------------------------------------

fn readReflexiveHeaders =
(
    -- format "\n=== READING REFLEXIVE HEADERS ===\n"
    
    -- According to coll_def.txt, reflexives start at offset 564 in the main tagdata struct
    -- The main tagdata struct itself starts at offset 64 (after the 64-byte blam_header)
    -- So, absolute start of reflexives is 64 + 564 = 628
    local actualReflexiveStart = 628
    
    -- format "Reading reflexives at discovered position: %\n" actualReflexiveStart
    seekToPosition actualReflexiveStart
    
    -- Read materials reflexive (offset 564 in tagdata)
    local materialsReflexive = read.reflexive()
    -- format "[DEBUG] Materials reflexive: count=%, pointer=%\n" materialsReflexive[1] materialsReflexive[2]
    
    -- Read regions reflexive (offset 576 in tagdata)
    local regionsReflexive = read.reflexive()
    -- format "[DEBUG] Regions reflexive: count=%, pointer=%\n" regionsReflexive[1] regionsReflexive[2]
    
    -- Read modifiers reflexive (offset 588 in tagdata)
    local modifiersReflexive = read.reflexive()
    -- format "[DEBUG] Modifiers reflexive: count=%, pointer=%\n" modifiersReflexive[1] modifiersReflexive[2]
    
    -- Current position should be 628 + 12 + 12 + 12 = 664
    local currentPos = getCurrentFilePosition()
    -- format "[DEBUG] Current position after reflexives: %\n" currentPos
    
    -- Skip to pathfinding box (offset 616 in tagdata, absolute 616 + 64 = 680)
    -- But there's padding between modifiers and pathfinding box
    -- Let's seek directly to the pathfinding box based on coll_def.txt
    seekToPosition (64 + 616)
    
    -- Read pathfinding box (24 bytes)
    local pathfindingBoxXFrom = read.floatB()
    local pathfindingBoxXTo = read.floatB()
    local pathfindingBoxYFrom = read.floatB()
    local pathfindingBoxYTo = read.floatB()
    local pathfindingBoxZFrom = read.floatB()
    local pathfindingBoxZTo = read.floatB()
    
    -- Read pathfinding spheres reflexive (offset 640 in tagdata, absolute 640 + 64 = 704)
    local pathfindingSpheresReflexive = read.reflexive()
    -- format "[DEBUG] Pathfinding spheres reflexive: count=%, pointer=%\n" pathfindingSpheresReflexive[1] pathfindingSpheresReflexive[2]
    
    -- Read nodes reflexive (offset 652 in tagdata, absolute 652 + 64 = 716)
    local nodesReflexive = read.reflexive()
    -- format "[DEBUG] Nodes reflexive: count=%, pointer=%\n" nodesReflexive[1] nodesReflexive[2]
    
    -- Display results
    -- format "Materials reflexive: count=%, pointer=%\n" materialsReflexive[1] materialsReflexive[2]
    -- format "Regions reflexive: count=%, pointer=%\n" regionsReflexive[1] regionsReflexive[2]
    -- format "Modifiers reflexive: count=%, pointer=%\n" modifiersReflexive[1] modifiersReflexive[2]
    -- format "Pathfinding Spheres reflexive: count=%, pointer=%\n" pathfindingSpheresReflexive[1] pathfindingSpheresReflexive[2]
    -- format "Nodes reflexive: count=%, pointer=%\n" nodesReflexive[1] nodesReflexive[2]
    
    -- format "Pathfinding Box: X[% to %], Y[% to %], Z[% to %]\n" pathfindingBoxXFrom pathfindingBoxXTo pathfindingBoxYFrom pathfindingBoxYTo pathfindingBoxZFrom pathfindingBoxZTo
    
    return #(materialsReflexive, regionsReflexive, modifiersReflexive, pathfindingSpheresReflexive, nodesReflexive,
             #(pathfindingBoxXFrom, pathfindingBoxXTo), #(pathfindingBoxYFrom, pathfindingBoxYTo), #(pathfindingBoxZFrom, pathfindingBoxZTo))
)

-------------------------------------------------------
-- Collision Reader Main Function
-------------------------------------------------------

fn readCollisionTag filePath =
(
    -- format "\n"
    -- format "===============================================\n"
    -- format "HALO CE COLLISION TAG READER v3.0 (Clean)\n"  
    -- format "===============================================\n"
    -- format "File: %\n" (getFilenameFile filePath)
    -- format "===============================================\n"
    
    -- Open file
    local fileHandle = fopen filePath "rb"
    if fileHandle == undefined then
    (
        -- format "[ERROR] Could not open file: %\n" filePath
        return undefined
    )
    
    -- Set global file handle
    setFileHandle fileHandle
    in_file = fileHandle
    
    try
    (
        -- Create collision data structure
        local collisionData = collisionTag()
        
        -- Step 1: Read and validate tag header
        local headerResult = readTagHeader()
        if headerResult == undefined then
        (
            fclose fileHandle
            return undefined
        )
        collisionData.header = headerResult[1]
        
        -- Step 2: Read main flags and indirect damage
        local flagsResult = readMainFlags()
        collisionData.flags = flagsResult[1]  -- actual flags array 
        collisionData.indirect_damage_material = flagsResult[2]
        
        -- Step 3: Read body section
        local bodyResult = readBodySection()
        collisionData.maximum_body_vitality = bodyResult[1]
        collisionData.body_system_shock = bodyResult[2] 
        collisionData.friendly_damage_resistance = bodyResult[3]
        collisionData.area_damage_effect_threshold = bodyResult[4]
        collisionData.body_damaged_threshold = bodyResult[5]
        collisionData.body_destroyed_threshold = bodyResult[6]
        collisionData.localized_damage_effect = bodyResult[7]
        collisionData.area_damage_effect = bodyResult[8]
        collisionData.body_damaged_effect = bodyResult[9]
        collisionData.body_depleted_effect = bodyResult[10]
        collisionData.body_destroyed_effect = bodyResult[11]
        
        -- Step 4: Read shield section  
        local shieldResult = readShieldSection()
        collisionData.maximum_shield_vitality = shieldResult[1]
        collisionData.shield_material_type = shieldResult[2]
        collisionData.shield_failure_function = shieldResult[3]
        collisionData.shield_failure_threshold = shieldResult[4]
        collisionData.shield_failing_leak_fraction = shieldResult[5]
        collisionData.minimum_stun_damage = shieldResult[6]
        collisionData.stun_time = shieldResult[7]
        collisionData.recharge_time = shieldResult[8]
        collisionData.shield_damaged_threshold = shieldResult[9]
        collisionData.shield_damaged_effect = shieldResult[11]
        collisionData.shield_depleted_effect = shieldResult[12]
        collisionData.shield_recharging_effect = shieldResult[13]
        
        -- Step 5: Read reflexive headers
        local reflexivesResult = readReflexiveHeaders()
        collisionData.materials_tag_block = reflexivesResult[1]
        collisionData.regions_tag_block = reflexivesResult[2] 
        collisionData.modifiers_tag_block = reflexivesResult[3]
        collisionData.pathfinding_spheres_tag_block = reflexivesResult[4]
        collisionData.nodes_tag_block = reflexivesResult[5]
        collisionData.pathfinding_box_x = reflexivesResult[6]
        collisionData.pathfinding_box_y = reflexivesResult[7]
        collisionData.pathfinding_box_z = reflexivesResult[8]
        
        -- Step 6: Read actual reflexive data
        -- format "\n=== READING REFLEXIVE DATA ===\n"
        
        -- Read materials data
		local materialsDataOffset = 0
        if reflexivesResult[1][1] > 0 then
        (
            local materialsResult = readMaterialsBlock reflexivesResult[1] reflexivesResult[2] reflexivesResult[4] reflexivesResult[5]
			collisionData.materials = materialsResult[1]
			materialsDataOffset = materialsResult[2]
        )
        
        -- Read regions data  
		local regionsEndOffset = materialsDataOffset
        if reflexivesResult[2][1] > 0 then
        (
            local regionsResult = readRegionsBlock reflexivesResult[2] reflexivesResult[1] materialsDataOffset
			collisionData.regions = regionsResult[1]
			regionsEndOffset = regionsResult[2]
        )
		
		-- Account for modifiers block (comes after regions/permutations, before pathfinding spheres)
		-- Each modifier is 52 bytes
		local modifiersCount = reflexivesResult[3][1]
		local modifiersEndOffset = regionsEndOffset + (modifiersCount * 52)
        
        -- Read pathfinding spheres data
		local spheresEndOffset = modifiersEndOffset
        if reflexivesResult[4][1] > 0 then
        (
            local spheresResult = readPathfindingSpheresBlock reflexivesResult[4] modifiersEndOffset
			collisionData.pathfinding_spheres = spheresResult[1]
			spheresEndOffset = spheresResult[2]
        )
        
        -- Read nodes data
        if reflexivesResult[5][1] > 0 then
        (
            collisionData.nodes = readNodesBlock reflexivesResult[5] spheresEndOffset
        )
        
        -- format "\n COMPLETE COLLISION TAG READING FINISHED\n"
        -- format "Materials: %, Regions: %, Spheres: %, Nodes: %\n" collisionData.materials.count collisionData.regions.count collisionData.pathfinding_spheres.count collisionData.nodes.count
        
        fclose fileHandle
        return collisionData
    )
    catch ex
    (
        format "[ERROR] Exception during tag reading: %\n" (ex as string)
        fclose fileHandle
        return undefined
    )
)
