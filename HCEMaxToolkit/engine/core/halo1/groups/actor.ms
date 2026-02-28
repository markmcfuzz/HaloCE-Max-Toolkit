actorFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"moreFlags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"type" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"maxVisionDistance" \
        hidden:false \
        type:#float \
        description:"maximum range of sight" \
        unit:"world units", \
    tagField \
        name:"centralVisionAngle" \
        hidden:false \
        type:#floatAngle \
        description:"horizontal angle within which we see targets out to our maximum range" \
        unit:"degrees", \
    tagField \
        name:"maxVisionAngle" \
        hidden:false \
        type:#floatAngle \
        description:"maximum horizontal angle within which we see targets at range" \
        unit:"degrees", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"peripheralVisionAngle" \
        hidden:false \
        type:#floatAngle \
        description:"maximum horizontal angle within which we can see targets out of the corner of our eye" \
        unit:"degrees", \
    tagField \
        name:"peripheralDistance" \
        hidden:false \
        type:#float \
        description:"maximum range at which we can see targets our of the corner of our eye" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"standingGunOffset" \
        hidden:false \
        type:#vector3d \
        description:"offset of gun from feet when standing (x=forward, y=left, z=up)", \
    tagField \
        name:"crouchingGunOffset" \
        hidden:false \
        type:#vector3d \
        description:"offset of gun from feet when crouch (x=forward, y=left, z=up)", \
    tagField \
        name:"hearingDistance" \
        hidden:false \
        type:#float \
        description:"maximum range at which sounds can be heard" \
        unit:"world units", \
    tagField \
        name:"noticeProjectileChance" \
        hidden:false \
        type:#float \
        description:"random chance of noticing a dangerous enemy projectile (e.g. grenade)" \
        unit:"[0,1]", \
    tagField \
        name:"noticeVehicleChance" \
        hidden:false \
        type:#float \
        description:"random chance of noticing a dangerous vehicle" \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"combatPerceptionTime" \
        hidden:false \
        type:#float \
        description:"time required to acknowledge a visible enemy when we are already in combat or searching for them" \
        unit:"seconds", \
    tagField \
        name:"guardPerceptionTime" \
        hidden:false \
        type:#float \
        description:"time required to acknowledge a visible enemy when we have been alerted" \
        unit:"seconds", \
    tagField \
        name:"nonCombatPerceptionTime" \
        hidden:false \
        type:#float \
        description:"time required to acknowledge a visible enemy when we are not alerted" \
        unit:"seconds", \
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
        count:8, \
    tagField \
        name:"diveIntoCoverChance" \
        hidden:false \
        type:#float \
        description:"chance of running a dive animation when moving into cover" \
        unit:"[0,1]", \
    tagField \
        name:"emergeFromCoverChance" \
        hidden:false \
        type:#float \
        description:"chance of running an emerge animation when uncovering a target" \
        unit:"[0,1]", \
    tagField \
        name:"diveFromGrenadeChance" \
        hidden:false \
        type:#float \
        description:"chance of running a dive animation when moving away from a grenade" \
        unit:"[0,1]", \
    tagField \
        name:"pathfindingRadius" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"glassIgnoranceChance" \
        hidden:false \
        type:#float \
        description:"chance of not noticing that breakable surfaces have been destroyed" \
        unit:"[0,1]", \
    tagField \
        name:"stationaryMovementDist" \
        hidden:false \
        type:#float \
        description:"movement distance which is considered 'stationary' for considering whether we crouch" \
        unit:"world units", \
    tagField \
        name:"freeFlyingSidestep" \
        hidden:false \
        type:#float \
        description:"distance which we allow sidestepping for flying units" \
        unit:"world units", \
    tagField \
        name:"beginMovingAngle" \
        hidden:false \
        type:#floatAngle \
        description:"we must be facing this close to our target before we start applying the throttle (default" \
        unit:" 180 degrees)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"maximumAimingDeviation" \
        hidden:false \
        type:#euler2d \
        description:"how far we can turn our weapon" \
        unit:"degrees", \
    tagField \
        name:"maximumLookingDeviation" \
        hidden:false \
        type:#euler2d \
        description:"how far we can turn our head" \
        unit:"degrees", \
    tagField \
        name:"noncombatLookDeltaL" \
        hidden:false \
        type:#floatAngle \
        description:"how far we can turn our head left away from our aiming vector when not in combat" \
        unit:"degrees", \
    tagField \
        name:"noncombatLookDeltaR" \
        hidden:false \
        type:#floatAngle \
        description:"how far we can turn our head right away from our aiming vector when not in combat" \
        unit:"degrees", \
    tagField \
        name:"combatLookDeltaL" \
        hidden:false \
        type:#floatAngle \
        description:"how far we can turn our head left away from our aiming vector when in combat" \
        unit:"degrees", \
    tagField \
        name:"combatLookDeltaR" \
        hidden:false \
        type:#floatAngle \
        description:"how far we can turn our head right away from our aiming vector when in combat" \
        unit:"degrees", \
    tagField \
        name:"idleAimingRange" \
        hidden:false \
        type:#euler2d \
        description:"range in which we select random directions to aim in" \
        unit:"degrees", \
    tagField \
        name:"idleLookingRange" \
        hidden:false \
        type:#euler2d \
        description:"range in which we select random directions to look at" \
        unit:"degrees", \
    tagField \
        name:"eventLookTimeModifier" \
        hidden:false \
        type:#floatBounds \
        description:"multiplier for how long we look at interesting events (zero = unchanged)", \
    tagField \
        name:"noncombatIdleFacing" \
        hidden:false \
        type:#floatBounds \
        description:"rate at which we change facing when looking around randomly when not in combat" \
        unit:"seconds", \
    tagField \
        name:"noncombatIdleAiming" \
        hidden:false \
        type:#floatBounds \
        description:"rate at which we change aiming directions when looking around randomly when not in combat" \
        unit:"seconds", \
    tagField \
        name:"noncombatIdleLooking" \
        hidden:false \
        type:#floatBounds \
        description:"rate at which we change look around randomly when not in combat" \
        unit:"seconds", \
    tagField \
        name:"guardIdleFacing" \
        hidden:false \
        type:#floatBounds \
        description:"rate at which we change facing when looking around randomly when guarding" \
        unit:"seconds", \
    tagField \
        name:"guardIdleAiming" \
        hidden:false \
        type:#floatBounds \
        description:"rate at which we change aiming directions when looking around randomly when guarding" \
        unit:"seconds", \
    tagField \
        name:"guardIdleLooking" \
        hidden:false \
        type:#floatBounds \
        description:"rate at which we change look around randomly when guarding" \
        unit:"seconds", \
    tagField \
        name:"combatIdleFacing" \
        hidden:false \
        type:#floatBounds \
        description:"rate at which we change facing when looking around randomly when searching or in combat" \
        unit:"seconds", \
    tagField \
        name:"combatIdleAiming" \
        hidden:false \
        type:#floatBounds \
        description:"rate at which we change aiming directions when looking around randomly when searching or in combat" \
        unit:"seconds", \
    tagField \
        name:"combatIdleLooking" \
        hidden:false \
        type:#floatBounds \
        description:"rate at which we change look around randomly when searching or in combat" \
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
        count:16, \
    tagField \
        name:"doNotUse" \
        hidden:false \
        type:#tagReference \
        allowed:#(#weapon) \
        unit:" weapon", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:268, \
    tagField \
        name:"doNotUse" \
        hidden:false \
        type:#tagReference \
        allowed:#(#projectile) \
        unit:" projectile", \
    tagField \
        name:"unreachableDangerTrigger" \
        hidden:false \
        type:#enum \
        description:"danger level of an unreachable enemy which will trigger a retreat if it continues over time", \
    tagField \
        name:"vehicleDangerTrigger" \
        hidden:false \
        type:#enum \
        description:"danger level of a vehicle-based enemy which will trigger a retreat if it continues over time", \
    tagField \
        name:"playerDangerTrigger" \
        hidden:false \
        type:#enum \
        description:"danger level of an enemy player which will trigger a retreat if it continues over time", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"dangerTriggerTime" \
        hidden:false \
        type:#floatBounds \
        description:"how long it takes for an unopposable enemy that has the above danger level to trigger a retreat" \
        unit:"seconds", \
    tagField \
        name:"friendsKilledTrigger" \
        hidden:false \
        type:#int16 \
        description:"if this many of our friends are killed by an unopposable enemy, we trigger a retreat (zero = never use this as a retreat condition)", \
    tagField \
        name:"friendsRetreatingTrigger" \
        hidden:false \
        type:#int16 \
        description:"if this many of our friends are retreating from an unopposable enemy, we retreat as well (zero = never use this as a retreat condition)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"retreatTime" \
        hidden:false \
        type:#floatBounds \
        description:"how long we retreat from an unopposable enemy for" \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"coweringTime" \
        hidden:false \
        type:#floatBounds \
        description:"how long we hide in cover after being panicked" \
        unit:"seconds", \
    tagField \
        name:"friendKilledPanicChance" \
        hidden:false \
        type:#float \
        description:"chance of panicking when we see a friend killed near us and the enemy is looking at us too" \
        unit:"[0,1]", \
    tagField \
        name:"leaderType" \
        hidden:false \
        type:#enum \
        description:"if we see a friend of this type killed we have a chance of panicking", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"leaderKilledPanicChance" \
        hidden:false \
        type:#float \
        description:"chance of panicking when we see a leader killed" \
        unit:"[0,1]", \
    tagField \
        name:"panicDamageThreshold" \
        hidden:false \
        type:#float \
        description:"panic if we take this much body damage in a short period of time" \
        unit:"[0,1]", \
    tagField \
        name:"surpriseDistance" \
        hidden:false \
        type:#float \
        description:"the distance at which newly acknowledged props or weapon impacts are considered 'close' for surprise purposes" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28, \
    tagField \
        name:"hideBehindCoverTime" \
        hidden:false \
        type:#floatBounds \
        description:"how long we stay behind cover after seeking cover" \
        unit:"seconds", \
    tagField \
        name:"hideTargetNotVisibleTime" \
        hidden:false \
        type:#float \
        description:"if this is non-zero then we will only seek cover if our target has not been visible recently" \
        unit:"seconds", \
    tagField \
        name:"hideShieldFraction" \
        hidden:false \
        type:#float \
        description:"elites and jackals only seek cover if their shield falls below this value" \
        unit:"[0,1]", \
    tagField \
        name:"attackShieldFraction" \
        hidden:false \
        type:#float \
        description:"elites and jackals only come out from cover to attack if they have this much shields" \
        unit:"[0,1]", \
    tagField \
        name:"pursueShieldFraction" \
        hidden:false \
        type:#float \
        description:"elites and jackals only come out from cover to pursue if they have this much shields" \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"defensiveCrouchType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"attackingCrouchThreshold" \
        hidden:false \
        type:#float \
        description:"when in attacking mode, if our crouch type is based on shields, we crouch when our shields are below this number; if our crouch type is based on danger, we crouch when our danger is above this number", \
    tagField \
        name:"defendingCrouchThreshold" \
        hidden:false \
        type:#float \
        description:"when in defending mode, if our crouch type is based on shields, we crouch when our shields are below this number; if our crouch type is based on danger, we crouch when our danger is above this number", \
    tagField \
        name:"minStandTime" \
        hidden:false \
        type:#float \
        description:"minimum time to remain standing (zero = default)" \
        unit:"seconds", \
    tagField \
        name:"minCrouchTime" \
        hidden:false \
        type:#float \
        description:"minimum time to remain crouching (zero = default)" \
        unit:"seconds", \
    tagField \
        name:"defendingHideTimeModifier" \
        hidden:false \
        type:#float \
        description:"how much longer we hide behind cover for when in the defending state (zero = unchanged)", \
    tagField \
        name:"attackingEvasionThreshold" \
        hidden:false \
        type:#float \
        description:"when in attacking mode, we consider seeking cover or evading when our danger gets this high", \
    tagField \
        name:"defendingEvasionThreshold" \
        hidden:false \
        type:#float \
        description:"when in defending mode, we consider seeking cover or evading when our danger gets this high", \
    tagField \
        name:"evasionSeekCoverChance" \
        hidden:false \
        type:#float \
        description:"chance of seeking cover (otherwise we just evade)" \
        unit:"[0,1]", \
    tagField \
        name:"evasionDelayTime" \
        hidden:false \
        type:#float \
        description:"minimum time period between evasion moves" \
        unit:"seconds", \
    tagField \
        name:"maxSeekCoverDistance" \
        hidden:false \
        type:#float \
        description:"maximum distance we will consider going to find cover (zero = default)" \
        unit:"world units", \
    tagField \
        name:"coverDamageThreshold" \
        hidden:false \
        type:#float \
        description:"how much damage we must take before we are allowed to seek cover (zero = always allowed to)" \
        unit:"[0,1]", \
    tagField \
        name:"stalkingDiscoveryTime" \
        hidden:false \
        type:#float \
        description:"if our target sees us for this long while we are stalking them, our cover is blown and we do something else (zero = never stop stalking)" \
        unit:"seconds", \
    tagField \
        name:"stalkingMaxDistance" \
        hidden:false \
        type:#float \
        description:"distance outside of which we don't bother stalking" \
        unit:"world units", \
    tagField \
        name:"stationaryFacingAngle" \
        hidden:false \
        type:#floatAngle \
        description:"angle outside of which we must abandon a stationary facing direction and suffer any penalties" \
        unit:"angle", \
    tagField \
        name:"changeFacingStandTime" \
        hidden:false \
        type:#float \
        description:"how long we must stand up for after changing our fixed stationary facing" \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"uncoverDelayTime" \
        hidden:false \
        type:#floatBounds \
        description:"time to look at target's position after it becomes visible" \
        unit:"seconds", \
    tagField \
        name:"targetSearchTime" \
        hidden:false \
        type:#floatBounds \
        description:"time we search at target's position" \
        unit:"seconds", \
    tagField \
        name:"pursuitPositionTime" \
        hidden:false \
        type:#floatBounds \
        description:"time we search at a pursuit position" \
        unit:"seconds", \
    tagField \
        name:"numPositions(coord)" \
        hidden:false \
        type:#int16 \
        description:"number of pursuit positions to check when in coordinated group search mode" \
        unit:"[0,n]", \
    tagField \
        name:"numPositions(normal)" \
        hidden:false \
        type:#int16 \
        description:"number of pursuit positions to check when in normal search mode" \
        unit:"[0,n]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"meleeAttackDelay" \
        hidden:false \
        type:#float \
        description:"how long we must wait between attempting melee attacks" \
        unit:"seconds", \
    tagField \
        name:"meleeFudgeFactor" \
        hidden:false \
        type:#float \
        description:"fudge factor that offsets how far in front of the target we start our attack (negative = we try to time our attack so that we go _through_ the target). this should be close to zero, but might be bigger for suiciding units" \
        unit:"world units", \
    tagField \
        name:"meleeChargeTime" \
        hidden:false \
        type:#float \
        description:"how long we can stay in the charging state trying to reach our target before we give up" \
        unit:"seconds", \
    tagField \
        name:"meleeLeapRange" \
        hidden:false \
        type:#floatBounds \
        description:"we can launch leaping melee attacks at targets within these ranges (zero = can't leap)" \
        unit:"world units", \
    tagField \
        name:"meleeLeapVelocity" \
        hidden:false \
        type:#float \
        description:"how fast we spring at targets when launching a leaping melee attack" \
        unit:"world units per tick", \
    tagField \
        name:"meleeLeapChance" \
        hidden:false \
        type:#float \
        description:"chance of launching a leaping melee attack at a ground-based target (we always leap at flying targets)" \
        unit:"[0,1]", \
    tagField \
        name:"meleeLeapBallistic" \
        hidden:false \
        type:#float \
        description:"fraction that controls how ballistic our leaping melee trajectory is" \
        unit:"[0,1]", \
    tagField \
        name:"berserkDamageAmount" \
        hidden:false \
        type:#float \
        description:"amount of body damage in a short time that makes us berserk" \
        unit:"[0,1]", \
    tagField \
        name:"berserkDamageThreshold" \
        hidden:false \
        type:#float \
        description:"how low our body health must get before we will consider berserking" \
        unit:"[0,1]", \
    tagField \
        name:"berserkProximity" \
        hidden:false \
        type:#float \
        description:"if we ever get this close to a target, we berserk" \
        unit:"world units", \
    tagField \
        name:"suicideSensingDist" \
        hidden:false \
        type:#float \
        description:"when we are this close to a target, we check to see if they're getting away and if so blow up" \
        unit:"world units", \
    tagField \
        name:"berserkGrenadeChance" \
        hidden:false \
        type:#float \
        description:"chance of berserking when we have a dangerous projectile stuck to us" \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"guardPositionTime" \
        hidden:false \
        type:#floatBounds \
        description:"time after which we decide to change guard positions (zero = never)" \
        unit:"seconds", \
    tagField \
        name:"combatPositionTime" \
        hidden:false \
        type:#floatBounds \
        description:"time after which we change combat firing positions" \
        unit:"seconds", \
    tagField \
        name:"oldPositionAvoidDist" \
        hidden:false \
        type:#float \
        description:"distance we try and stay from our last discarded firing position" \
        unit:"world units", \
    tagField \
        name:"friendAvoidDist" \
        hidden:false \
        type:#float \
        description:"distance we try and stay from any friends" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:40, \
    tagField \
        name:"noncombatIdleSpeechTime" \
        hidden:false \
        type:#floatBounds \
        description:"time between idle vocalizations when we are not in combat" \
        unit:"seconds", \
    tagField \
        name:"combatIdleSpeechTime" \
        hidden:false \
        type:#floatBounds \
        description:"time between idle vocalizations when we are in combat or searching" \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:48, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:128, \
    tagField \
        name:"doNotUse" \
        hidden:false \
        type:#tagReference \
        allowed:#(#actor) \
        unit:" major upgrade", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:48
)

actorBlock = tagBlock \
    name:"actorBlock" \
    length:1272 \
    maximum:1 \
    fields:actorFields

actorDef = tagDef \
    fourcc:1633907826 \
    supergroup:undefined \
    tagBlock:actorBlock
