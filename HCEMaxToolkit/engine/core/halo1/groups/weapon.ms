weaponPredictedresourcesFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"resourceIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"tagIndex" \
        hidden:false \
        type:#int32
)

weaponPredictedresourcesBlock = tagBlock \
    name:"predictedResourcesBlock" \
    length:8 \
    maximum:1024 \
    fields:weaponPredictedresourcesFields

weaponMagazinesFields = #(
    tagField \
        name:"rounds" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:10, \
    tagField \
        name:"equipment" \
        hidden:false \
        type:#tagReference \
        allowed:#(#equipment)
)

weaponMagazinesBlock = tagBlock \
    name:"magazinesBlock" \
    length:28 \
    maximum:8 \
    fields:weaponMagazinesFields

weaponFiringeffectsFields = #(
    tagField \
        name:"shotCountLowerBound" \
        hidden:false \
        type:#int16 \
        description:"the minimum number of times this firing effect will be used, once it has been chosen", \
    tagField \
        name:"shotCountUpperBound" \
        hidden:false \
        type:#int16 \
        description:"the maximum number of times this firing effect will be used, once it has been chosen", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"firingEffect" \
        hidden:false \
        type:#tagReference \
        description:"this effect is used when the weapon is loaded and fired normally" \
        allowed:#(#sound,#effect), \
    tagField \
        name:"misfireEffect" \
        hidden:false \
        type:#tagReference \
        description:"this effect is used when the weapon is loaded but fired while overheated" \
        allowed:#(#sound,#effect), \
    tagField \
        name:"emptyEffect" \
        hidden:false \
        type:#tagReference \
        description:"this effect is used when the weapon is not loaded" \
        allowed:#(#sound,#effect), \
    tagField \
        name:"firingDamage" \
        hidden:false \
        type:#tagReference \
        description:"this effect is used when the weapon is loaded and fired normally" \
        allowed:#(#damage_effect), \
    tagField \
        name:"misfireDamage" \
        hidden:false \
        type:#tagReference \
        description:"this effect is used when the weapon is loaded but fired while overheated" \
        allowed:#(#damage_effect), \
    tagField \
        name:"emptyDamage" \
        hidden:false \
        type:#tagReference \
        description:"this effect is used when the weapon is not loaded" \
        allowed:#(#damage_effect)
)

weaponFiringeffectsBlock = tagBlock \
    name:"firingEffectsBlock" \
    length:132 \
    maximum:8 \
    fields:weaponFiringeffectsFields

weaponTriggersFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"roundsPerSecond" \
        hidden:false \
        type:#floatBounds \
        description:"the number of firing effects created per second", \
    tagField \
        name:"accelerationTime" \
        hidden:false \
        type:#float \
        description:"the continuous firing time it takes for the weapon to achieve its final rounds per second" \
        unit:"seconds", \
    tagField \
        name:"decelerationTime" \
        hidden:false \
        type:#float \
        description:"the continuous idle time it takes for the weapon to return from its final rounds per second to its initial" \
        unit:"seconds", \
    tagField \
        name:"blurredRateOfFire" \
        hidden:false \
        type:#floatClamped \
        description:"a percentage between 0 and 1 which controls how soon in its firing animation the weapon blurs", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"magazine" \
        hidden:false \
        type:#index \
        description:"the magazine from which this trigger draws its ammunition", \
    tagField \
        name:"roundsPerShot" \
        hidden:false \
        type:#int16 \
        description:"the number of rounds expended to create a single firing effect", \
    tagField \
        name:"minimumRoundsLoaded" \
        hidden:false \
        type:#int16 \
        description:"the minimum number of rounds necessary to fire the weapon", \
    tagField \
        name:"roundsBetweenTracers" \
        hidden:false \
        type:#int16 \
        description:"the number of non-tracer rounds fired between tracers", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:6, \
    tagField \
        name:"firingNoise" \
        hidden:false \
        type:#enum \
        description:"how loud this weapon appears to the AI", \
    tagField \
        name:"error" \
        hidden:false \
        type:#floatBounds \
        description:"the accuracy (between 0.0 and 1.0) of the weapon during firing", \
    tagField \
        name:"accelerationTime" \
        hidden:false \
        type:#float \
        description:"the continuous firing time it takes for the weapon to achieve its final error" \
        unit:"seconds", \
    tagField \
        name:"decelerationTime" \
        hidden:false \
        type:#float \
        description:"the continuous idle time it takes for the weapon to return to its initial error" \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"chargingTime" \
        hidden:false \
        type:#float \
        description:"the amount of time it takes for this trigger to become fully charged" \
        unit:"seconds", \
    tagField \
        name:"chargedTime" \
        hidden:false \
        type:#float \
        description:"the amount of time this trigger can be charged before becoming overcharged" \
        unit:"seconds", \
    tagField \
        name:"overchargedAction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"chargedIllumination" \
        hidden:false \
        type:#float \
        description:"the amount of illumination given off when the weapon is fully charged" \
        unit:"[0,1]", \
    tagField \
        name:"spewTime" \
        hidden:false \
        type:#float \
        description:"length of time the weapon will spew (fire continuously) while discharging" \
        unit:"seconds", \
    tagField \
        name:"chargingEffect" \
        hidden:false \
        type:#tagReference \
        description:"the charging effect is created once when the trigger begins to charge" \
        allowed:#(#sound,#effect), \
    tagField \
        name:"distributionFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"projectilesPerShot" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"distributionAngle" \
        hidden:false \
        type:#float \
        unit:"degrees", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"minimumError" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"errorAngle" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"firstPersonOffset" \
        hidden:false \
        type:#point3d \
        description:"+x is forward, +z is up, +y is left" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"projectile" \
        hidden:false \
        type:#tagReference \
        allowed:#(#projectile), \
    tagField \
        name:"ejectionPortRecoveryTime" \
        hidden:false \
        type:#float \
        description:"the amount of time (in seconds) it takes for the ejection port to transition from 1.0 (open) to 0.0 (closed) after a shot has been fired", \
    tagField \
        name:"illuminationRecoveryTime" \
        hidden:false \
        type:#float \
        description:"the amount of time (in seconds) it takes the illumination function to transition from 1.0 (bright) to 0.0 (dark) after a shot has been fired", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"heatGeneratedPerRound" \
        hidden:false \
        type:#floatClamped \
        description:"the amount of heat generated each time the trigger is fired" \
        unit:"[0,1]", \
    tagField \
        name:"ageGeneratedPerRound" \
        hidden:false \
        type:#floatClamped \
        description:"the amount the weapon ages each time the trigger is fired" \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"overloadTime" \
        hidden:false \
        type:#float \
        description:"the next trigger fires this often while holding down this trigger" \
        unit:"seconds", \
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
        count:32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"firingEffects" \
        hidden:false \
        type:#block \
        description:"firing effects determine what happens when this trigger is fired" \
        block:weaponFiringeffectsBlock
)

weaponTriggersBlock = tagBlock \
    name:"triggersBlock" \
    length:276 \
    maximum:2 \
    fields:weaponTriggersFields

weaponFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"label" \
        hidden:false \
        type:#string \
        description:"the string used to match this weapon to an animation mode in the unit carrying it", \
    tagField \
        name:"secondaryTriggerMode" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"maximumAlternateShotsLoaded" \
        hidden:false \
        type:#int16 \
        description:"if the second trigger loads alternate ammunition, this is the maximum number of shots that can be loaded at a time", \
    tagField \
        name:"aIn" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"bIn" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"cIn" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"dIn" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"readyTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"readyEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound,#effect), \
    tagField \
        name:"heatRecoveryThreshold" \
        hidden:false \
        type:#floatClamped \
        description:"the heat value a weapon must return to before leaving the overheated state, once it has become overheated in the first place" \
        unit:"[0,1]", \
    tagField \
        name:"overheatedThreshold" \
        hidden:false \
        type:#floatClamped \
        description:"the heat value over which a weapon first becomes overheated (should be greater than the heat recovery threshold)" \
        unit:"[0,1]", \
    tagField \
        name:"heatDetonationThreshold" \
        hidden:false \
        type:#floatClamped \
        description:"the heat value above which the weapon has a chance of exploding each time it is fired" \
        unit:"[0,1]", \
    tagField \
        name:"heatDetonationFraction" \
        hidden:false \
        type:#floatClamped \
        description:"the percent chance (between 0.0 and 1.0) the weapon will explode when fired over the heat detonation threshold" \
        unit:"[0,1]", \
    tagField \
        name:"heatLossPerSecond" \
        hidden:false \
        type:#floatClamped \
        description:"the amount of heat lost each second when the weapon is not being fired" \
        unit:"[0,1]", \
    tagField \
        name:"heatIllumination" \
        hidden:false \
        type:#floatClamped \
        description:"the amount of illumination given off when the weapon is overheated" \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"overheated" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound,#effect), \
    tagField \
        name:"detonation" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound,#effect), \
    tagField \
        name:"playerMeleeDamage" \
        hidden:false \
        type:#tagReference \
        allowed:#(#damage_effect), \
    tagField \
        name:"playerMeleeResponse" \
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
        name:"actorFiringParameters" \
        hidden:false \
        type:#tagReference \
        allowed:#(#actor_variant), \
    tagField \
        name:"nearReticleRange" \
        hidden:false \
        type:#float \
        description:"the range at which the closer of the two static target reticles will be drawn" \
        unit:"world units", \
    tagField \
        name:"farReticleRange" \
        hidden:false \
        type:#float \
        description:"the range at which the farther of the two static target reticles will be drawn" \
        unit:"world units", \
    tagField \
        name:"intersectionReticleRange" \
        hidden:false \
        type:#float \
        description:"the maximum range at which the dynamic target reticle will be drawn", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"magnificationLevels" \
        hidden:false \
        type:#int16 \
        description:"the number of magnification levels this weapon allows", \
    tagField \
        name:"magnificationRange" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"autoaimAngle" \
        hidden:false \
        type:#floatAngle \
        description:"the maximum angle that autoaim works at full strength" \
        unit:"degrees", \
    tagField \
        name:"autoaimRange" \
        hidden:false \
        type:#float \
        description:"the maximum distance that autoaim works at full strength" \
        unit:"world units", \
    tagField \
        name:"magnetismAngle" \
        hidden:false \
        type:#floatAngle \
        description:"the maximum angle that magnetism works at full strength" \
        unit:"degrees", \
    tagField \
        name:"magnetismRange" \
        hidden:false \
        type:#float \
        description:"the maximum distance that magnetism works at full strength" \
        unit:"world units", \
    tagField \
        name:"deviationAngle" \
        hidden:false \
        type:#floatAngle \
        description:"the maximum angle that a projectile is allowed to deviate from the gun barrel" \
        unit:"degrees", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"movementPenalized" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"forwardMovementPenalty" \
        hidden:false \
        type:#floatClamped \
        description:"percent slowdown to forward movement for units carrying this weapon", \
    tagField \
        name:"sidewaysMovementPenalty" \
        hidden:false \
        type:#floatClamped \
        description:"percent slowdown to sideways and backward movement for units carrying this weapon", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"minimumTargetRange" \
        hidden:false \
        type:#float \
        description:"minimum range that actors using this weapon will try and target stuff at", \
    tagField \
        name:"lookingTimeModifier" \
        hidden:false \
        type:#float \
        description:"how much faster actors look around idly using this weapon (zero is unchanged)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"lightPowerOnTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"lightPowerOffTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"lightPowerOnEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound,#effect), \
    tagField \
        name:"lightPowerOffEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound,#effect), \
    tagField \
        name:"ageHeatRecoveryPenalty" \
        hidden:false \
        type:#float \
        description:"how much the weapon's heat recovery is penalized as it ages", \
    tagField \
        name:"ageRateOfFirePenalty" \
        hidden:false \
        type:#float \
        description:"how much the weapon's rate of fire is penalized as it ages", \
    tagField \
        name:"ageMisfireStart" \
        hidden:false \
        type:#floatClamped \
        description:"the age threshold when the weapon begins to misfire" \
        unit:"[0,1]", \
    tagField \
        name:"ageMisfireChance" \
        hidden:false \
        type:#floatClamped \
        description:"at age 1.0, the misfire chance per shot" \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"firstPersonModel" \
        hidden:false \
        type:#tagReference \
        allowed:#(#gbxmodel), \
    tagField \
        name:"firstPersonAnimations" \
        hidden:false \
        type:#tagReference \
        allowed:#(#model_animations), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"hudInterface" \
        hidden:false \
        type:#tagReference \
        allowed:#(#weapon_hud_interface), \
    tagField \
        name:"pickupSound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"zoomInSound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"zoomOutSound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"activeCamoDing" \
        hidden:false \
        type:#float \
        description:"how much to decrease active camo when a round is fired", \
    tagField \
        name:"activeCamoRegrowthRate" \
        hidden:false \
        type:#float \
        description:"how fast to increase active camo (per tick) when a round is fired", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"weaponType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"predictedResources" \
        hidden:false \
        type:#block \
        block:weaponPredictedresourcesBlock, \
    tagField \
        name:"magazines" \
        hidden:false \
        type:#block \
        block:weaponMagazinesBlock, \
    tagField \
        name:"triggers" \
        hidden:false \
        type:#block \
        block:weaponTriggersBlock
)

weaponBlock = tagBlock \
    name:"weaponBlock" \
    length:512 \
    maximum:1 \
    fields:weaponFields

weaponDef = tagDef \
    fourcc:2003132784 \
    supergroup:#item \
    tagBlock:weaponBlock
