actorVariantChangecolorsFields = #(
    tagField \
        name:"colorLowerBound" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"colorUpperBound" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8
)

actorVariantChangecolorsBlock = tagBlock \
    name:"changeColorsBlock" \
    length:32 \
    maximum:4 \
    fields:actorVariantChangecolorsFields

actorVariantFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"actorDefinition" \
        hidden:false \
        type:#tagReference \
        allowed:#(#actor), \
    tagField \
        name:"unit" \
        hidden:false \
        type:#tagReference \
        allowed:#(#unit), \
    tagField \
        name:"majorVariant" \
        hidden:false \
        type:#tagReference \
        allowed:#(#actor_variant), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"movementType" \
        hidden:false \
        type:#enum \
        description:"when we have a choice of movement types, which type we will use", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"initialCrouchChance" \
        hidden:false \
        type:#float \
        description:"actors that start their movement try to maintain this fraction of crouched actors" \
        unit:"[0,1]", \
    tagField \
        name:"crouchTime" \
        hidden:false \
        type:#floatBounds \
        description:"when switching movement types, how long we will stay crouched for before running" \
        unit:"seconds", \
    tagField \
        name:"runTime" \
        hidden:false \
        type:#floatBounds \
        description:"when switching movement types, how long we will run for before slowing to a crouch" \
        unit:"seconds", \
    tagField \
        name:"weapon" \
        hidden:false \
        type:#tagReference \
        allowed:#(#weapon), \
    tagField \
        name:"maximumFiringDistance" \
        hidden:false \
        type:#float \
        description:"we can only fire our weapon at targets within this distance" \
        unit:"world units", \
    tagField \
        name:"rateOfFire" \
        hidden:false \
        type:#float \
        description:"how many times per second we pull the trigger (zero = continuously held down)", \
    tagField \
        name:"projectileError" \
        hidden:false \
        type:#floatAngle \
        description:"error added to every projectile we fire" \
        unit:"degrees", \
    tagField \
        name:"firstBurstDelayTime" \
        hidden:false \
        type:#floatBounds \
        unit:"seconds", \
    tagField \
        name:"newTargetFiringPatternTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"surpriseDelayTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"surpriseFireWildlyTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"deathFireWildlyChance" \
        hidden:false \
        type:#float \
        unit:"[0,1]", \
    tagField \
        name:"deathFireWildlyTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"desiredCombatRange" \
        hidden:false \
        type:#floatBounds \
        unit:"world units", \
    tagField \
        name:"customStandGunOffset" \
        hidden:false \
        type:#vector3d \
        description:"custom standing gun offset for overriding the default in the base actor", \
    tagField \
        name:"customCrouchGunOffset" \
        hidden:false \
        type:#vector3d \
        description:"custom crouching gun offset for overriding the default in the base actor", \
    tagField \
        name:"targetTracking" \
        hidden:false \
        type:#float \
        description:"how well our bursts track moving targets. 0.0= fire at the position they were standing when we started the burst. 1.0= fire at current position" \
        unit:"[0,1]", \
    tagField \
        name:"targetLeading" \
        hidden:false \
        type:#float \
        description:"how much we lead moving targets. 0.0= no prediction. 1.0= predict completely." \
        unit:"[0,1]", \
    tagField \
        name:"weaponDamageModifier" \
        hidden:false \
        type:#float \
        description:"what fraction of its normal damage our weapon inflicts (zero = no modifier)", \
    tagField \
        name:"damagePerSecond" \
        hidden:false \
        type:#float \
        description:"only used if weapon damage modifier is zero... how much damage we should deliver to the target per second while firing a burst at them (zero = use weapon default)", \
    tagField \
        name:"burstOriginRadius" \
        hidden:false \
        type:#float \
        description:"how far away from the target the starting point is" \
        unit:"world units", \
    tagField \
        name:"burstOriginAngle" \
        hidden:false \
        type:#floatAngle \
        description:"the range from the horizontal that our starting error can be" \
        unit:"degrees", \
    tagField \
        name:"burstReturnLength" \
        hidden:false \
        type:#floatBounds \
        description:"how far the burst point moves back towards the target (could be negative)" \
        unit:"world units", \
    tagField \
        name:"burstReturnAngle" \
        hidden:false \
        type:#floatAngle \
        description:"the range from the horizontal that the return direction can be" \
        unit:"degrees", \
    tagField \
        name:"burstDuration" \
        hidden:false \
        type:#floatBounds \
        description:"how long each burst we fire is" \
        unit:"seconds", \
    tagField \
        name:"burstSeparation" \
        hidden:false \
        type:#floatBounds \
        description:"how long we wait between bursts" \
        unit:"seconds", \
    tagField \
        name:"burstAngularVelocity" \
        hidden:false \
        type:#floatAngle \
        description:"the maximum rate at which we can sweep our fire (zero = unlimited)" \
        unit:"degrees per second", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"specialDamageModifier" \
        hidden:false \
        type:#float \
        description:"damage modifier for special weapon fire (applied in addition to the normal damage modifier. zero = no change)" \
        unit:"[0,1]", \
    tagField \
        name:"specialProjectileError" \
        hidden:false \
        type:#floatAngle \
        description:"projectile error angle for special weapon fire (applied in addition to the normal error)" \
        unit:"degrees", \
    tagField \
        name:"newTargetBurstDuration" \
        hidden:false \
        type:#float \
        description:"burst duration multiplier for newly appeared targets (zero = unchanged)", \
    tagField \
        name:"newTargetBurstSeparation" \
        hidden:false \
        type:#float \
        description:"burst separation multiplier for newly appeared targets (zero = unchanged)", \
    tagField \
        name:"newTargetRateOfFire" \
        hidden:false \
        type:#float \
        description:"rate-of-fire multiplier for newly appeared targets (zero = unchanged)", \
    tagField \
        name:"newTargetProjectileError" \
        hidden:false \
        type:#float \
        description:"error multiplier for newly appeared targets (zero = unchanged)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"movingBurstDuration" \
        hidden:false \
        type:#float \
        description:"burst duration multiplier when the actor is moving (zero = unchanged)", \
    tagField \
        name:"movingBurstSeparation" \
        hidden:false \
        type:#float \
        description:"burst separation multiplier when the actor is moving (zero = unchanged)", \
    tagField \
        name:"movingRateOfFire" \
        hidden:false \
        type:#float \
        description:"rate-of-fire multiplier when the actor is moving (zero = unchanged)", \
    tagField \
        name:"movingProjectileError" \
        hidden:false \
        type:#float \
        description:"error multiplier when the actor is moving (zero = unchanged)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"berserkBurstDuration" \
        hidden:false \
        type:#float \
        description:"burst duration multiplier when the actor is berserk (zero = unchanged)", \
    tagField \
        name:"berserkBurstSeparation" \
        hidden:false \
        type:#float \
        description:"burst separation multiplier when the actor is berserk (zero = unchanged)", \
    tagField \
        name:"berserkRateOfFire" \
        hidden:false \
        type:#float \
        description:"rate-of-fire multiplier when the actor is berserk (zero = unchanged)", \
    tagField \
        name:"berserkProjectileError" \
        hidden:false \
        type:#float \
        description:"error multiplier when the actor is berserk (zero = unchanged)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"superBallisticRange" \
        hidden:false \
        type:#float \
        description:"we try to aim our shots super-ballistically if target is outside this range (zero = never)", \
    tagField \
        name:"bombardmentRange" \
        hidden:false \
        type:#float \
        description:"we offset our burst targets randomly by this range when firing at non-visible enemies (zero = never)", \
    tagField \
        name:"modifiedVisionRange" \
        hidden:false \
        type:#float \
        description:"any custom vision range that this actor variant has (zero = normal)", \
    tagField \
        name:"specialFireMode" \
        hidden:false \
        type:#enum \
        description:"the type of special weapon fire that we can use", \
    tagField \
        name:"specialFireSituation" \
        hidden:false \
        type:#enum \
        description:"when we will decide to use our special weapon fire mode", \
    tagField \
        name:"specialFireChance" \
        hidden:false \
        type:#float \
        description:"how likely we are to use our special weapon fire mode" \
        unit:"[0,1]", \
    tagField \
        name:"specialFireDelay" \
        hidden:false \
        type:#float \
        description:"how long we must wait between uses of our special weapon fire mode" \
        unit:"seconds", \
    tagField \
        name:"meleeRange" \
        hidden:false \
        type:#float \
        description:"how close an enemy target must get before triggering a melee charge" \
        unit:"world units", \
    tagField \
        name:"meleeAbortRange" \
        hidden:false \
        type:#float \
        description:"if our target gets this far away from us, we stop trying to melee them" \
        unit:"world units", \
    tagField \
        name:"berserkFiringRanges" \
        hidden:false \
        type:#floatBounds \
        description:"if we are outside maximum range, we advance towards target, stopping when we reach minimum range" \
        unit:"world units", \
    tagField \
        name:"berserkMeleeRange" \
        hidden:false \
        type:#float \
        description:"while berserking, how close an enemy target must get before triggering a melee charge" \
        unit:"world units", \
    tagField \
        name:"berserkMeleeAbortRange" \
        hidden:false \
        type:#float \
        description:"while berserking, if our target gets this far away from us, we stop trying to melee them" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"grenadeType" \
        hidden:false \
        type:#enum \
        description:"type of grenades that we throw", \
    tagField \
        name:"trajectoryType" \
        hidden:false \
        type:#enum \
        description:"how we throw our grenades", \
    tagField \
        name:"grenadeStimulus" \
        hidden:false \
        type:#enum \
        description:"what causes us to consider throwing a grenade", \
    tagField \
        name:"minimumEnemyCount" \
        hidden:false \
        type:#int16 \
        description:"how many enemies must be within the radius of the grenade before we will consider throwing there", \
    tagField \
        name:"enemyRadius" \
        hidden:false \
        type:#float \
        description:"we consider enemies within this radius when determining where to throw" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"grenadeVelocity" \
        hidden:false \
        type:#float \
        description:"how fast we can throw our grenades" \
        unit:"world units per second", \
    tagField \
        name:"grenadeRanges" \
        hidden:false \
        type:#floatBounds \
        description:"ranges within which we will consider throwing a grenade" \
        unit:"world units", \
    tagField \
        name:"collateralDamageRadius" \
        hidden:false \
        type:#float \
        description:"we won't throw if there are friendlies around our target within this range" \
        unit:"world units", \
    tagField \
        name:"grenadeChance" \
        hidden:false \
        type:#floatClamped \
        description:"how likely we are to throw a grenade" \
        unit:"[0,1]", \
    tagField \
        name:"grenadeCheckTime" \
        hidden:false \
        type:#float \
        description:"for continuous stimuli (e.g. visible target), how often we check to see if we want to throw a grenade" \
        unit:"seconds", \
    tagField \
        name:"encounterGrenadeTimeout" \
        hidden:false \
        type:#float \
        description:"we cannot throw grenades if someone else in our encounter threw one this recently" \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20, \
    tagField \
        name:"equipment" \
        hidden:false \
        type:#tagReference \
        description:"equipment item to drop when we die" \
        allowed:#(#equipment), \
    tagField \
        name:"grenadeCount" \
        hidden:false \
        type:#int16 \
        description:"number of grenades that we start with", \
    tagField \
        name:"dontDropGrenadesChance" \
        hidden:false \
        type:#float \
        description:"how likely we are not to drop any grenades when we die, even if we still have some" \
        unit:"[0,1]", \
    tagField \
        name:"dropWeaponLoaded" \
        hidden:false \
        type:#floatBounds \
        description:"amount of ammo loaded into the weapon that we drop (in fractions of a clip, e.g. 0.3 to 0.5)", \
    tagField \
        name:"dropWeaponAmmo" \
        hidden:false \
        type:#int16 \
        description:"total number of rounds in the weapon that we drop (ignored for energy weapons)", \
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
        count:16, \
    tagField \
        name:"bodyVitality" \
        hidden:false \
        type:#float \
        description:"maximum body vitality of our unit", \
    tagField \
        name:"shieldVitality" \
        hidden:false \
        type:#float \
        description:"maximum shield vitality of our unit", \
    tagField \
        name:"shieldSappingRadius" \
        hidden:false \
        type:#float \
        description:"how far away we can drain the player's shields" \
        unit:"world units", \
    tagField \
        name:"forcedShaderPermutation" \
        hidden:false \
        type:#int16 \
        description:"if nonzero, overrides the unit's shader permutation", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
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
        count:12, \
    tagField \
        name:"changeColors" \
        hidden:false \
        type:#block \
        block:actorVariantChangecolorsBlock
)

actorVariantBlock = tagBlock \
    name:"actorVariantBlock" \
    length:568 \
    maximum:1 \
    fields:actorVariantFields

actorVariantDef = tagDef \
    fourcc:1633907830 \
    supergroup:undefined \
    tagBlock:actorVariantBlock
