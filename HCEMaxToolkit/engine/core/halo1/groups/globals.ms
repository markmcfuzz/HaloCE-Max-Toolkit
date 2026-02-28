globalsSoundsFields = #(
    tagField \
        name:"sound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound)
)

globalsSoundsBlock = tagBlock \
    name:"soundsBlock" \
    length:16 \
    maximum:2 \
    fields:globalsSoundsFields

globalsCameraFields = #(
    tagField \
        name:"defaultUnitCameraTrack" \
        hidden:false \
        type:#tagReference \
        allowed:#(#camera_track)
)

globalsCameraBlock = tagBlock \
    name:"cameraBlock" \
    length:16 \
    maximum:1 \
    fields:globalsCameraFields

globalsLookfunctionFields = #(
    tagField \
        name:"scale" \
        hidden:false \
        type:#float
)

globalsLookfunctionBlock = tagBlock \
    name:"lookFunctionBlock" \
    length:4 \
    maximum:16 \
    fields:globalsLookfunctionFields

globalsPlayercontrolFields = #(
    tagField \
        name:"magnetismFriction" \
        hidden:false \
        type:#floatClamped \
        description:"how much the crosshair slows over enemies", \
    tagField \
        name:"magnetismAdhesion" \
        hidden:false \
        type:#floatClamped \
        description:"how much the crosshair sticks to enemies", \
    tagField \
        name:"inconsequentialTargetScale" \
        hidden:false \
        type:#floatClamped \
        description:"scales magnetism level for inconsequential targets like infection forms", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:52, \
    tagField \
        name:"lookAccelerationTime" \
        hidden:false \
        type:#float \
        description:"time for a pegged look to reach maximum effect" \
        unit:"seconds", \
    tagField \
        name:"lookAccelerationScale" \
        hidden:false \
        type:#float \
        description:"maximum effect of a pegged look (scales last value in the look function below)", \
    tagField \
        name:"lookPegThreshold[0,1]" \
        hidden:false \
        type:#floatClamped \
        description:"magnitude of yaw for pegged acceleration to kick in", \
    tagField \
        name:"lookDefaultPitchRate" \
        hidden:false \
        type:#float \
        unit:"degrees", \
    tagField \
        name:"lookDefaultYawRate" \
        hidden:false \
        type:#float \
        unit:"degrees", \
    tagField \
        name:"lookAutolevellingScale" \
        hidden:false \
        type:#float \
        description:"1 is fast, 0 is none, >1 will probably be really fast", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20, \
    tagField \
        name:"minimumWeaponSwapTicks" \
        hidden:false \
        type:#int16 \
        description:"amount of time player needs to hold down ACTION to pick up a new weapon", \
    tagField \
        name:"minimumAutolevellingTicks" \
        hidden:false \
        type:#int16 \
        description:"amount of time player needs to move and not look up or down for autolevelling to kick in", \
    tagField \
        name:"minimumAngleForVehicleFlipping" \
        hidden:false \
        type:#floatAngle \
        description:"0 means the vehicle's up vector is along the ground, 90 means the up vector is pointing straight up" \
        unit:"degrees", \
    tagField \
        name:"lookFunction" \
        hidden:false \
        type:#block \
        block:globalsLookfunctionBlock
)

globalsPlayercontrolBlock = tagBlock \
    name:"playerControlBlock" \
    length:128 \
    maximum:1 \
    fields:globalsPlayercontrolFields

globalsDifficultyFields = #(
    tagField \
        name:"easyEnemyDamage" \
        hidden:false \
        type:#float \
        description:"enemy damage multiplier on easy difficulty", \
    tagField \
        name:"normalEnemyDamage" \
        hidden:false \
        type:#float \
        description:"enemy damage multiplier on normal difficulty", \
    tagField \
        name:"hardEnemyDamage" \
        hidden:false \
        type:#float \
        description:"enemy damage multiplier on hard difficulty", \
    tagField \
        name:"impossEnemyDamage" \
        hidden:false \
        type:#float \
        description:"enemy damage multiplier on impossible difficulty", \
    tagField \
        name:"easyEnemyVitality" \
        hidden:false \
        type:#float \
        description:"enemy maximum body vitality scale on easy difficulty", \
    tagField \
        name:"normalEnemyVitality" \
        hidden:false \
        type:#float \
        description:"enemy maximum body vitality scale on normal difficulty", \
    tagField \
        name:"hardEnemyVitality" \
        hidden:false \
        type:#float \
        description:"enemy maximum body vitality scale on hard difficulty", \
    tagField \
        name:"impossEnemyVitality" \
        hidden:false \
        type:#float \
        description:"enemy maximum body vitality scale on impossible difficulty", \
    tagField \
        name:"easyEnemyShield" \
        hidden:false \
        type:#float \
        description:"enemy maximum shield vitality scale on easy difficulty", \
    tagField \
        name:"normalEnemyShield" \
        hidden:false \
        type:#float \
        description:"enemy maximum shield vitality scale on normal difficulty", \
    tagField \
        name:"hardEnemyShield" \
        hidden:false \
        type:#float \
        description:"enemy maximum shield vitality scale on hard difficulty", \
    tagField \
        name:"impossEnemyShield" \
        hidden:false \
        type:#float \
        description:"enemy maximum shield vitality scale on impossible difficulty", \
    tagField \
        name:"easyEnemyRecharge" \
        hidden:false \
        type:#float \
        description:"enemy shield recharge scale on easy difficulty", \
    tagField \
        name:"normalEnemyRecharge" \
        hidden:false \
        type:#float \
        description:"enemy shield recharge scale on normal difficulty", \
    tagField \
        name:"hardEnemyRecharge" \
        hidden:false \
        type:#float \
        description:"enemy shield recharge scale on hard difficulty", \
    tagField \
        name:"impossEnemyRecharge" \
        hidden:false \
        type:#float \
        description:"enemy shield recharge scale on impossible difficulty", \
    tagField \
        name:"easyFriendDamage" \
        hidden:false \
        type:#float \
        description:"friend damage multiplier on easy difficulty", \
    tagField \
        name:"normalFriendDamage" \
        hidden:false \
        type:#float \
        description:"friend damage multiplier on normal difficulty", \
    tagField \
        name:"hardFriendDamage" \
        hidden:false \
        type:#float \
        description:"friend damage multiplier on hard difficulty", \
    tagField \
        name:"impossFriendDamage" \
        hidden:false \
        type:#float \
        description:"friend damage multiplier on impossible difficulty", \
    tagField \
        name:"easyFriendVitality" \
        hidden:false \
        type:#float \
        description:"friend maximum body vitality scale on easy difficulty", \
    tagField \
        name:"normalFriendVitality" \
        hidden:false \
        type:#float \
        description:"friend maximum body vitality scale on normal difficulty", \
    tagField \
        name:"hardFriendVitality" \
        hidden:false \
        type:#float \
        description:"friend maximum body vitality scale on hard difficulty", \
    tagField \
        name:"impossFriendVitality" \
        hidden:false \
        type:#float \
        description:"friend maximum body vitality scale on impossible difficulty", \
    tagField \
        name:"easyFriendShield" \
        hidden:false \
        type:#float \
        description:"friend maximum shield vitality scale on easy difficulty", \
    tagField \
        name:"normalFriendShield" \
        hidden:false \
        type:#float \
        description:"friend maximum shield vitality scale on normal difficulty", \
    tagField \
        name:"hardFriendShield" \
        hidden:false \
        type:#float \
        description:"friend maximum shield vitality scale on hard difficulty", \
    tagField \
        name:"impossFriendShield" \
        hidden:false \
        type:#float \
        description:"friend maximum shield vitality scale on impossible difficulty", \
    tagField \
        name:"easyFriendRecharge" \
        hidden:false \
        type:#float \
        description:"friend shield recharge scale on easy difficulty", \
    tagField \
        name:"normalFriendRecharge" \
        hidden:false \
        type:#float \
        description:"friend shield recharge scale on normal difficulty", \
    tagField \
        name:"hardFriendRecharge" \
        hidden:false \
        type:#float \
        description:"friend shield recharge scale on hard difficulty", \
    tagField \
        name:"impossFriendRecharge" \
        hidden:false \
        type:#float \
        description:"friend shield recharge scale on impossible difficulty", \
    tagField \
        name:"easyInfectionForms" \
        hidden:false \
        type:#float \
        description:"toughness of infection forms (may be negative) on easy difficulty", \
    tagField \
        name:"normalInfectionForms" \
        hidden:false \
        type:#float \
        description:"toughness of infection forms (may be negative) on normal difficulty", \
    tagField \
        name:"hardInfectionForms" \
        hidden:false \
        type:#float \
        description:"toughness of infection forms (may be negative) on hard difficulty", \
    tagField \
        name:"impossInfectionForms" \
        hidden:false \
        type:#float \
        description:"toughness of infection forms (may be negative) on impossible difficulty", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"easyRateOfFire" \
        hidden:false \
        type:#float \
        description:"enemy rate of fire scale on easy difficulty", \
    tagField \
        name:"normalRateOfFire" \
        hidden:false \
        type:#float \
        description:"enemy rate of fire scale on normal difficulty", \
    tagField \
        name:"hardRateOfFire" \
        hidden:false \
        type:#float \
        description:"enemy rate of fire scale on hard difficulty", \
    tagField \
        name:"impossRateOfFire" \
        hidden:false \
        type:#float \
        description:"enemy rate of fire scale on impossible difficulty", \
    tagField \
        name:"easyProjectileError" \
        hidden:false \
        type:#float \
        description:"enemy projectile error scale, as a fraction of their base firing error. on easy difficulty", \
    tagField \
        name:"normalProjectileError" \
        hidden:false \
        type:#float \
        description:"enemy projectile error scale, as a fraction of their base firing error. on normal difficulty", \
    tagField \
        name:"hardProjectileError" \
        hidden:false \
        type:#float \
        description:"enemy projectile error scale, as a fraction of their base firing error. on hard difficulty", \
    tagField \
        name:"impossProjectileError" \
        hidden:false \
        type:#float \
        description:"enemy projectile error scale, as a fraction of their base firing error. on impossible difficulty", \
    tagField \
        name:"easyBurstError" \
        hidden:false \
        type:#float \
        description:"enemy burst error scale; reduces intra-burst shot distance. on easy difficulty", \
    tagField \
        name:"normalBurstError" \
        hidden:false \
        type:#float \
        description:"enemy burst error scale; reduces intra-burst shot distance. on normal difficulty", \
    tagField \
        name:"hardBurstError" \
        hidden:false \
        type:#float \
        description:"enemy burst error scale; reduces intra-burst shot distance. on hard difficulty", \
    tagField \
        name:"impossBurstError" \
        hidden:false \
        type:#float \
        description:"enemy burst error scale; reduces intra-burst shot distance. on impossible difficulty", \
    tagField \
        name:"easyNewTargetDelay" \
        hidden:false \
        type:#float \
        description:"enemy new-target delay scale factor. on easy difficulty", \
    tagField \
        name:"normalNewTargetDelay" \
        hidden:false \
        type:#float \
        description:"enemy new-target delay scale factor. on normal difficulty", \
    tagField \
        name:"hardNewTargetDelay" \
        hidden:false \
        type:#float \
        description:"enemy new-target delay scale factor. on hard difficulty", \
    tagField \
        name:"impossNewTargetDelay" \
        hidden:false \
        type:#float \
        description:"enemy new-target delay scale factor. on impossible difficulty", \
    tagField \
        name:"easyBurstSeparation" \
        hidden:false \
        type:#float \
        description:"delay time between bursts scale factor for enemies. on easy difficulty", \
    tagField \
        name:"normalBurstSeparation" \
        hidden:false \
        type:#float \
        description:"delay time between bursts scale factor for enemies. on normal difficulty", \
    tagField \
        name:"hardBurstSeparation" \
        hidden:false \
        type:#float \
        description:"delay time between bursts scale factor for enemies. on hard difficulty", \
    tagField \
        name:"impossBurstSeparation" \
        hidden:false \
        type:#float \
        description:"delay time between bursts scale factor for enemies. on impossible difficulty", \
    tagField \
        name:"easyTargetTracking" \
        hidden:false \
        type:#float \
        description:"additional target tracking fraction for enemies. on easy difficulty", \
    tagField \
        name:"normalTargetTracking" \
        hidden:false \
        type:#float \
        description:"additional target tracking fraction for enemies. on normal difficulty", \
    tagField \
        name:"hardTargetTracking" \
        hidden:false \
        type:#float \
        description:"additional target tracking fraction for enemies. on hard difficulty", \
    tagField \
        name:"impossTargetTracking" \
        hidden:false \
        type:#float \
        description:"additional target tracking fraction for enemies. on impossible difficulty", \
    tagField \
        name:"easyTargetLeading" \
        hidden:false \
        type:#float \
        description:"additional target leading fraction for enemies. on easy difficulty", \
    tagField \
        name:"normalTargetLeading" \
        hidden:false \
        type:#float \
        description:"additional target leading fraction for enemies. on normal difficulty", \
    tagField \
        name:"hardTargetLeading" \
        hidden:false \
        type:#float \
        description:"additional target leading fraction for enemies. on hard difficulty", \
    tagField \
        name:"impossTargetLeading" \
        hidden:false \
        type:#float \
        description:"additional target leading fraction for enemies. on impossible difficulty", \
    tagField \
        name:"easyOverchargeChance" \
        hidden:false \
        type:#float \
        description:"overcharge chance scale factor for enemies. on easy difficulty", \
    tagField \
        name:"normalOverchargeChance" \
        hidden:false \
        type:#float \
        description:"overcharge chance scale factor for enemies. on normal difficulty", \
    tagField \
        name:"hardOverchargeChance" \
        hidden:false \
        type:#float \
        description:"overcharge chance scale factor for enemies. on hard difficulty", \
    tagField \
        name:"impossOverchargeChance" \
        hidden:false \
        type:#float \
        description:"overcharge chance scale factor for enemies. on impossible difficulty", \
    tagField \
        name:"easySpecialFireDelay" \
        hidden:false \
        type:#float \
        description:"delay between special-fire shots (overcharge, banshee bombs) scale factor for enemies. on easy difficulty", \
    tagField \
        name:"normalSpecialFireDelay" \
        hidden:false \
        type:#float \
        description:"delay between special-fire shots (overcharge, banshee bombs) scale factor for enemies. on normal difficulty", \
    tagField \
        name:"hardSpecialFireDelay" \
        hidden:false \
        type:#float \
        description:"delay between special-fire shots (overcharge, banshee bombs) scale factor for enemies. on hard difficulty", \
    tagField \
        name:"impossSpecialFireDelay" \
        hidden:false \
        type:#float \
        description:"delay between special-fire shots (overcharge, banshee bombs) scale factor for enemies. on impossible difficulty", \
    tagField \
        name:"easyGuidanceVsPlayer" \
        hidden:false \
        type:#float \
        description:"guidance velocity scale factor for all projectiles targeted on a player. on easy difficulty", \
    tagField \
        name:"normalGuidanceVsPlayer" \
        hidden:false \
        type:#float \
        description:"guidance velocity scale factor for all projectiles targeted on a player. on normal difficulty", \
    tagField \
        name:"hardGuidanceVsPlayer" \
        hidden:false \
        type:#float \
        description:"guidance velocity scale factor for all projectiles targeted on a player. on hard difficulty", \
    tagField \
        name:"impossGuidanceVsPlayer" \
        hidden:false \
        type:#float \
        description:"guidance velocity scale factor for all projectiles targeted on a player. on impossible difficulty", \
    tagField \
        name:"easyMeleeDelayBase" \
        hidden:false \
        type:#float \
        description:"delay period added to all melee attacks, even when berserk. on easy difficulty", \
    tagField \
        name:"normalMeleeDelayBase" \
        hidden:false \
        type:#float \
        description:"delay period added to all melee attacks, even when berserk. on normal difficulty", \
    tagField \
        name:"hardMeleeDelayBase" \
        hidden:false \
        type:#float \
        description:"delay period added to all melee attacks, even when berserk. on hard difficulty", \
    tagField \
        name:"impossMeleeDelayBase" \
        hidden:false \
        type:#float \
        description:"delay period added to all melee attacks, even when berserk. on impossible difficulty", \
    tagField \
        name:"easyMeleeDelayScale" \
        hidden:false \
        type:#float \
        description:"multiplier for all existing non-berserk melee delay times. on easy difficulty", \
    tagField \
        name:"normalMeleeDelayScale" \
        hidden:false \
        type:#float \
        description:"multiplier for all existing non-berserk melee delay times. on normal difficulty", \
    tagField \
        name:"hardMeleeDelayScale" \
        hidden:false \
        type:#float \
        description:"multiplier for all existing non-berserk melee delay times. on hard difficulty", \
    tagField \
        name:"impossMeleeDelayScale" \
        hidden:false \
        type:#float \
        description:"multiplier for all existing non-berserk melee delay times. on impossible difficulty", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"easyGrenadeChanceScale" \
        hidden:false \
        type:#float \
        description:"scale factor affecting the desicions to throw a grenade. on easy difficulty", \
    tagField \
        name:"normalGrenadeChanceScale" \
        hidden:false \
        type:#float \
        description:"scale factor affecting the desicions to throw a grenade. on normal difficulty", \
    tagField \
        name:"hardGrenadeChanceScale" \
        hidden:false \
        type:#float \
        description:"scale factor affecting the desicions to throw a grenade. on hard difficulty", \
    tagField \
        name:"impossGrenadeChanceScale" \
        hidden:false \
        type:#float \
        description:"scale factor affecting the desicions to throw a grenade. on impossible difficulty", \
    tagField \
        name:"easyGrenadeTimerScale" \
        hidden:false \
        type:#float \
        description:"scale factor affecting the delay period between grenades thrown from the same encounter (lower is more often). on easy difficulty", \
    tagField \
        name:"normalGrenadeTimerScale" \
        hidden:false \
        type:#float \
        description:"scale factor affecting the delay period between grenades thrown from the same encounter (lower is more often). on normal difficulty", \
    tagField \
        name:"hardGrenadeTimerScale" \
        hidden:false \
        type:#float \
        description:"scale factor affecting the delay period between grenades thrown from the same encounter (lower is more often). on hard difficulty", \
    tagField \
        name:"impossGrenadeTimerScale" \
        hidden:false \
        type:#float \
        description:"scale factor affecting the delay period between grenades thrown from the same encounter (lower is more often). on impossible difficulty", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"easyMajorUpgrade(normal)" \
        hidden:false \
        type:#float \
        description:"fraction of actors upgraded to their major variant. on easy difficulty", \
    tagField \
        name:"normalMajorUpgrade(normal)" \
        hidden:false \
        type:#float \
        description:"fraction of actors upgraded to their major variant. on normal difficulty", \
    tagField \
        name:"hardMajorUpgrade(normal)" \
        hidden:false \
        type:#float \
        description:"fraction of actors upgraded to their major variant. on hard difficulty", \
    tagField \
        name:"impossMajorUpgrade(normal)" \
        hidden:false \
        type:#float \
        description:"fraction of actors upgraded to their major variant. on impossible difficulty", \
    tagField \
        name:"easyMajorUpgrade(few)" \
        hidden:false \
        type:#float \
        description:"fraction of actors upgraded to their major variant when mix = normal. on easy difficulty", \
    tagField \
        name:"normalMajorUpgrade(few)" \
        hidden:false \
        type:#float \
        description:"fraction of actors upgraded to their major variant when mix = normal. on normal difficulty", \
    tagField \
        name:"hardMajorUpgrade(few)" \
        hidden:false \
        type:#float \
        description:"fraction of actors upgraded to their major variant when mix = normal. on hard difficulty", \
    tagField \
        name:"impossMajorUpgrade(few)" \
        hidden:false \
        type:#float \
        description:"fraction of actors upgraded to their major variant when mix = normal. on impossible difficulty", \
    tagField \
        name:"easyMajorUpgrade(many)" \
        hidden:false \
        type:#float \
        description:"fraction of actors upgraded to their major variant when mix = many. on easy difficulty", \
    tagField \
        name:"normalMajorUpgrade(many)" \
        hidden:false \
        type:#float \
        description:"fraction of actors upgraded to their major variant when mix = many. on normal difficulty", \
    tagField \
        name:"hardMajorUpgrade(many)" \
        hidden:false \
        type:#float \
        description:"fraction of actors upgraded to their major variant when mix = many. on hard difficulty", \
    tagField \
        name:"impossMajorUpgrade(many)" \
        hidden:false \
        type:#float \
        description:"fraction of actors upgraded to their major variant when mix = many. on impossible difficulty", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:84
)

globalsDifficultyBlock = tagBlock \
    name:"difficultyBlock" \
    length:644 \
    maximum:1 \
    fields:globalsDifficultyFields

globalsGrenadesFields = #(
    tagField \
        name:"maximumCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"mpSpawnDefault" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"throwingEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"hudInterface" \
        hidden:false \
        type:#tagReference \
        allowed:#(#grenade_hud_interface), \
    tagField \
        name:"equipment" \
        hidden:false \
        type:#tagReference \
        allowed:#(#equipment), \
    tagField \
        name:"projectile" \
        hidden:false \
        type:#tagReference \
        allowed:#(#projectile)
)

globalsGrenadesBlock = tagBlock \
    name:"grenadesBlock" \
    length:68 \
    maximum:2 \
    fields:globalsGrenadesFields

globalsRasterizerdataFields = #(
    tagField \
        name:"distanceAttenuation" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"vectorNormalization" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"atmosphericFogDensity" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"planarFogDensity" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"linearCornerFade" \
        hidden:false \
        type:#tagReference \
        description:"used for shadows" \
        allowed:#(#bitmap), \
    tagField \
        name:"activeCamouflageDistortion" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"glow" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:60, \
    tagField \
        name:"default2d" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"default3d" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"defaultCubeMap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"test0" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"test1" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"test2" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"test3" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"videoScanlineMap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"videoNoiseMap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:52, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"refractionAmount" \
        hidden:false \
        type:#float \
        unit:"pixels", \
    tagField \
        name:"distanceFalloff" \
        hidden:false \
        type:#float, \
    tagField \
        name:"tintColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"hyperStealthRefraction" \
        hidden:false \
        type:#float \
        unit:"pixels", \
    tagField \
        name:"hyperStealthDistanceFalloff" \
        hidden:false \
        type:#float, \
    tagField \
        name:"hyperStealthTintColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"distanceAttenuation2d" \
        hidden:false \
        type:#tagReference \
        description:"the pc can't use 3d textures, so we use this instead" \
        allowed:#(#bitmap)
)

globalsRasterizerdataBlock = tagBlock \
    name:"rasterizerDataBlock" \
    length:428 \
    maximum:1 \
    fields:globalsRasterizerdataFields

globalsInterfacebitmapsFields = #(
    tagField \
        name:"fontSystem" \
        hidden:false \
        type:#tagReference \
        allowed:#(#font), \
    tagField \
        name:"fontTerminal" \
        hidden:false \
        type:#tagReference \
        allowed:#(#font), \
    tagField \
        name:"screenColorTable" \
        hidden:false \
        type:#tagReference \
        allowed:#(#color_table), \
    tagField \
        name:"hudColorTable" \
        hidden:false \
        type:#tagReference \
        allowed:#(#color_table), \
    tagField \
        name:"editorColorTable" \
        hidden:false \
        type:#tagReference \
        allowed:#(#color_table), \
    tagField \
        name:"dialogColorTable" \
        hidden:false \
        type:#tagReference \
        allowed:#(#color_table), \
    tagField \
        name:"hudGlobals" \
        hidden:false \
        type:#tagReference \
        allowed:#(#hud_globals), \
    tagField \
        name:"motionSensorSweepBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"motionSensorSweepBitmapMask" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"multiplayerHudBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"localization" \
        hidden:false \
        type:#tagReference \
        allowed:#(#string_list), \
    tagField \
        name:"hudDigitsDefinition" \
        hidden:false \
        type:#tagReference \
        allowed:#(#hud_number), \
    tagField \
        name:"motionSensorBlipBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"interfaceGooMap1" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"interfaceGooMap2" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"interfaceGooMap3" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:48
)

globalsInterfacebitmapsBlock = tagBlock \
    name:"interfaceBitmapsBlock" \
    length:304 \
    maximum:1 \
    fields:globalsInterfacebitmapsFields

globalsWeaponlistupdateweaponlistenumingameglobalshFields = #(
    tagField \
        name:"weapon" \
        hidden:false \
        type:#tagReference \
        allowed:#(#item)
)

globalsWeaponlistupdateweaponlistenumingameglobalshBlock = tagBlock \
    name:"weaponListUpdateWeaponListEnumInGameGlobalshBlock" \
    length:16 \
    maximum:20 \
    fields:globalsWeaponlistupdateweaponlistenumingameglobalshFields

globalsCheatpowerupsFields = #(
    tagField \
        name:"powerup" \
        hidden:false \
        type:#tagReference \
        allowed:#(#equipment)
)

globalsCheatpowerupsBlock = tagBlock \
    name:"cheatPowerupsBlock" \
    length:16 \
    maximum:20 \
    fields:globalsCheatpowerupsFields

globalsVehiclesFields = #(
    tagField \
        name:"vehicle" \
        hidden:false \
        type:#tagReference \
        allowed:#(#vehicle)
)

globalsVehiclesBlock = tagBlock \
    name:"vehiclesBlock" \
    length:16 \
    maximum:20 \
    fields:globalsVehiclesFields

globalsMultiplayerinformationsoundsFields = #(
    tagField \
        name:"sound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound)
)

globalsMultiplayerinformationsoundsBlock = tagBlock \
    name:"multiplayerInformationSoundsBlock" \
    length:16 \
    maximum:60 \
    fields:globalsMultiplayerinformationsoundsFields

globalsMultiplayerinformationFields = #(
    tagField \
        name:"flag" \
        hidden:false \
        type:#tagReference \
        allowed:#(#item), \
    tagField \
        name:"unit" \
        hidden:false \
        type:#tagReference \
        allowed:#(#unit), \
    tagField \
        name:"vehicles" \
        hidden:false \
        type:#block \
        block:globalsVehiclesBlock, \
    tagField \
        name:"hillShader" \
        hidden:false \
        type:#tagReference \
        allowed:#(#shader), \
    tagField \
        name:"flagShader" \
        hidden:false \
        type:#tagReference \
        allowed:#(#shader), \
    tagField \
        name:"ball" \
        hidden:false \
        type:#tagReference \
        allowed:#(#item), \
    tagField \
        name:"sounds" \
        hidden:false \
        type:#block \
        block:globalsMultiplayerinformationsoundsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:56
)

globalsMultiplayerinformationBlock = tagBlock \
    name:"multiplayerInformationBlock" \
    length:160 \
    maximum:1 \
    fields:globalsMultiplayerinformationFields

globalsPlayerinformationFields = #(
    tagField \
        name:"unit" \
        hidden:false \
        type:#tagReference \
        allowed:#(#unit), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28, \
    tagField \
        name:"walkingSpeed" \
        hidden:false \
        type:#float \
        unit:"world units per second", \
    tagField \
        name:"'doubleSpeed'Multiplier" \
        hidden:false \
        type:#float \
        unit:"[1.0,+inf]", \
    tagField \
        name:"runForward" \
        hidden:false \
        type:#float \
        unit:"world units per second", \
    tagField \
        name:"runBackward" \
        hidden:false \
        type:#float \
        unit:"world units per second", \
    tagField \
        name:"runSideways" \
        hidden:false \
        type:#float \
        unit:"world units per second", \
    tagField \
        name:"runAcceleration" \
        hidden:false \
        type:#float \
        unit:"world units per second squared", \
    tagField \
        name:"sneakForward" \
        hidden:false \
        type:#float \
        unit:"world units per second", \
    tagField \
        name:"sneakBackward" \
        hidden:false \
        type:#float \
        unit:"world units per second", \
    tagField \
        name:"sneakSideways" \
        hidden:false \
        type:#float \
        unit:"world units per second", \
    tagField \
        name:"sneakAcceleration" \
        hidden:false \
        type:#float \
        unit:"world units per second squared", \
    tagField \
        name:"airborneAcceleration" \
        hidden:false \
        type:#float \
        unit:"world units per second squared", \
    tagField \
        name:"speedMultiplier" \
        hidden:false \
        type:#float \
        unit:" multiplayer only", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"grenadeOrigin" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"stunMovementPenalty" \
        hidden:false \
        type:#float \
        description:"1.0 prevents moving while stunned" \
        unit:"[0,1]", \
    tagField \
        name:"stunTurningPenalty" \
        hidden:false \
        type:#float \
        description:"1.0 prevents turning while stunned" \
        unit:"[0,1]", \
    tagField \
        name:"stunJumpingPenalty" \
        hidden:false \
        type:#float \
        description:"1.0 prevents jumping while stunned" \
        unit:"[0,1]", \
    tagField \
        name:"minimumStunTime" \
        hidden:false \
        type:#float \
        description:"all stunning damage will last for at least this long" \
        unit:"seconds", \
    tagField \
        name:"maximumStunTime" \
        hidden:false \
        type:#float \
        description:"no stunning damage will last for longer than this" \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"firstPersonIdleTime" \
        hidden:false \
        type:#floatBounds \
        unit:"seconds", \
    tagField \
        name:"firstPersonSkipFraction" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"coopRespawnEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:44
)

globalsPlayerinformationBlock = tagBlock \
    name:"playerInformationBlock" \
    length:244 \
    maximum:1 \
    fields:globalsPlayerinformationFields

globalsFirstpersoninterfaceFields = #(
    tagField \
        name:"firstPersonHands" \
        hidden:false \
        type:#tagReference \
        allowed:#(#gbxmodel), \
    tagField \
        name:"baseBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"shieldMeter" \
        hidden:false \
        type:#tagReference \
        allowed:#(#meter), \
    tagField \
        name:"shieldMeterOrigin" \
        hidden:false \
        type:#point2d_int, \
    tagField \
        name:"bodyMeter" \
        hidden:false \
        type:#tagReference \
        allowed:#(#meter), \
    tagField \
        name:"bodyMeterOrigin" \
        hidden:false \
        type:#point2d_int, \
    tagField \
        name:"nightVisionOff>onEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"nightVisionOn>offEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:88
)

globalsFirstpersoninterfaceBlock = tagBlock \
    name:"firstPersonInterfaceBlock" \
    length:192 \
    maximum:1 \
    fields:globalsFirstpersoninterfaceFields

globalsFallingdamageFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"harmfulFallingDistance" \
        hidden:false \
        type:#floatBounds \
        unit:"world units", \
    tagField \
        name:"fallingDamage" \
        hidden:false \
        type:#tagReference \
        allowed:#(#damage_effect), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"maximumFallingDistance" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"distanceDamage" \
        hidden:false \
        type:#tagReference \
        allowed:#(#damage_effect), \
    tagField \
        name:"vehicleEnvironemtnCollisionDamageEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#damage_effect), \
    tagField \
        name:"vehicleKilledUnitDamageEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#damage_effect), \
    tagField \
        name:"vehicleCollisionDamage" \
        hidden:false \
        type:#tagReference \
        allowed:#(#damage_effect), \
    tagField \
        name:"flamingDeathDamage" \
        hidden:false \
        type:#tagReference \
        allowed:#(#damage_effect), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28
)

globalsFallingdamageBlock = tagBlock \
    name:"fallingDamageBlock" \
    length:152 \
    maximum:1 \
    fields:globalsFallingdamageFields

globalsParticleeffectsFields = #(
    tagField \
        name:"particleType" \
        hidden:false \
        type:#tagReference \
        allowed:#(#particle), \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"density" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"velocityScale" \
        hidden:false \
        type:#floatBounds \
        description:"scales initial velocity", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"angularVelocity" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees per second", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"radius" \
        hidden:false \
        type:#floatBounds \
        description:"particle radius" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"tintLowerBound" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"tintUpperBound" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28
)

globalsParticleeffectsBlock = tagBlock \
    name:"particleEffectsBlock" \
    length:128 \
    maximum:8 \
    fields:globalsParticleeffectsFields

globalsMaterialsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:100, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:48, \
    tagField \
        name:"groundFrictionScale" \
        hidden:false \
        type:#float \
        description:"fraction of original velocity parallel to the ground after one tick", \
    tagField \
        name:"groundFrictionNormalK1Scale" \
        hidden:false \
        type:#float \
        description:"cosine of angle at which friction falls off", \
    tagField \
        name:"groundFrictionNormalK0Scale" \
        hidden:false \
        type:#float \
        description:"cosine of angle at which friction is zero", \
    tagField \
        name:"groundDepthScale" \
        hidden:false \
        type:#float \
        description:"depth a point mass rests in the ground", \
    tagField \
        name:"groundDampFractionScale" \
        hidden:false \
        type:#float \
        description:"fraction of original velocity perpendicular to the ground after one tick", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:76, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:480, \
    tagField \
        name:"maximumVitality" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"effect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"sound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"particleEffects" \
        hidden:false \
        type:#block \
        block:globalsParticleeffectsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:60, \
    tagField \
        name:"meleeHitSound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound)
)

globalsMaterialsBlock = tagBlock \
    name:"materialsBlock" \
    length:884 \
    maximum:33 \
    fields:globalsMaterialsFields

globalsPlaylistmembersFields = #(
    tagField \
        name:"mapName" \
        hidden:false \
        type:#string, \
    tagField \
        name:"gameVariant" \
        hidden:false \
        type:#string, \
    tagField \
        name:"minimumExperience" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"maximumExperience" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"minimumPlayerCount" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"maximumPlayerCount" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"rating" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:64
)

globalsPlaylistmembersBlock = tagBlock \
    name:"playlistMembersBlock" \
    length:148 \
    maximum:20 \
    fields:globalsPlaylistmembersFields

globalsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:248, \
    tagField \
        name:"sounds" \
        hidden:false \
        type:#block \
        block:globalsSoundsBlock, \
    tagField \
        name:"camera" \
        hidden:false \
        type:#block \
        block:globalsCameraBlock, \
    tagField \
        name:"playerControl" \
        hidden:false \
        type:#block \
        block:globalsPlayercontrolBlock, \
    tagField \
        name:"difficulty" \
        hidden:false \
        type:#block \
        block:globalsDifficultyBlock, \
    tagField \
        name:"grenades" \
        hidden:false \
        type:#block \
        block:globalsGrenadesBlock, \
    tagField \
        name:"rasterizerData" \
        hidden:false \
        type:#block \
        block:globalsRasterizerdataBlock, \
    tagField \
        name:"interfaceBitmaps" \
        hidden:false \
        type:#block \
        block:globalsInterfacebitmapsBlock, \
    tagField \
        name:"weaponList(updateWeaponListEnumInGameGlobalsH)" \
        hidden:false \
        type:#block \
        block:globalsWeaponlistupdateweaponlistenumingameglobalshBlock, \
    tagField \
        name:"cheatPowerups" \
        hidden:false \
        type:#block \
        block:globalsCheatpowerupsBlock, \
    tagField \
        name:"multiplayerInformation" \
        hidden:false \
        type:#block \
        block:globalsMultiplayerinformationBlock, \
    tagField \
        name:"playerInformation" \
        hidden:false \
        type:#block \
        block:globalsPlayerinformationBlock, \
    tagField \
        name:"firstPersonInterface" \
        hidden:false \
        type:#block \
        block:globalsFirstpersoninterfaceBlock, \
    tagField \
        name:"fallingDamage" \
        hidden:false \
        type:#block \
        block:globalsFallingdamageBlock, \
    tagField \
        name:"materials" \
        hidden:false \
        type:#block \
        block:globalsMaterialsBlock, \
    tagField \
        name:"playlistMembers" \
        hidden:false \
        type:#block \
        block:globalsPlaylistmembersBlock
)

globalsBlock = tagBlock \
    name:"globalsBlock" \
    length:428 \
    maximum:1 \
    fields:globalsFields

globalsDef = tagDef \
    fourcc:1835103335 \
    supergroup:undefined \
    tagBlock:globalsBlock
