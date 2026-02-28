dialogueFields = #(
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
        count:2, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"idleNoncombat" \
        hidden:false \
        type:#tagReference \
        description:"played randomly and intermittently whenever we aren't in combat" \
        allowed:#(#sound), \
    tagField \
        name:"idleCombat" \
        hidden:false \
        type:#tagReference \
        description:"played randomly and intermittently whenever we're in combat" \
        allowed:#(#sound), \
    tagField \
        name:"idleFlee" \
        hidden:false \
        type:#tagReference \
        description:"played continuously while we are fleeing" \
        allowed:#(#sound), \
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
        name:"painBodyMinor" \
        hidden:false \
        type:#tagReference \
        description:"took body damage" \
        allowed:#(#sound), \
    tagField \
        name:"painBodyMajor" \
        hidden:false \
        type:#tagReference \
        description:"took a significant amount of body damage" \
        allowed:#(#sound), \
    tagField \
        name:"painShield" \
        hidden:false \
        type:#tagReference \
        description:"took shield damage" \
        allowed:#(#sound), \
    tagField \
        name:"painFalling" \
        hidden:false \
        type:#tagReference \
        description:"took damage from falling" \
        allowed:#(#sound), \
    tagField \
        name:"screamFear" \
        hidden:false \
        type:#tagReference \
        description:"screaming in fear (falling to your death, explosive stuck to you)" \
        allowed:#(#sound), \
    tagField \
        name:"screamPain" \
        hidden:false \
        type:#tagReference \
        description:"screaming in pain (being flamed)" \
        allowed:#(#sound), \
    tagField \
        name:"maimedLimb" \
        hidden:false \
        type:#tagReference \
        description:"limb body part (arm or leg) was destroyed" \
        allowed:#(#sound), \
    tagField \
        name:"maimedHead" \
        hidden:false \
        type:#tagReference \
        description:"head body part was destroyed" \
        allowed:#(#sound), \
    tagField \
        name:"deathQuiet" \
        hidden:false \
        type:#tagReference \
        description:"died from minor damage, or was unprepared" \
        allowed:#(#sound), \
    tagField \
        name:"deathViolent" \
        hidden:false \
        type:#tagReference \
        description:"died from violent trauma" \
        allowed:#(#sound), \
    tagField \
        name:"deathFalling" \
        hidden:false \
        type:#tagReference \
        description:"died from falling" \
        allowed:#(#sound), \
    tagField \
        name:"deathAgonizing" \
        hidden:false \
        type:#tagReference \
        description:"died in a horribly painful fashion (burnt to death)" \
        allowed:#(#sound), \
    tagField \
        name:"deathInstant" \
        hidden:false \
        type:#tagReference \
        description:"died instantly" \
        allowed:#(#sound), \
    tagField \
        name:"deathFlying" \
        hidden:false \
        type:#tagReference \
        description:"died and was blown up into the air" \
        allowed:#(#sound), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"damagedFriend" \
        hidden:false \
        type:#tagReference \
        description:"hurt a friendly AI" \
        allowed:#(#sound), \
    tagField \
        name:"damagedFriendPlayer" \
        hidden:false \
        type:#tagReference \
        description:"hurt a friendly player" \
        allowed:#(#sound), \
    tagField \
        name:"damagedEnemy" \
        hidden:false \
        type:#tagReference \
        description:"hurt an enemy" \
        allowed:#(#sound), \
    tagField \
        name:"damagedEnemyCm" \
        hidden:false \
        type:#tagReference \
        description:"hurt an enemy" \
        allowed:#(#sound) \
        unit:" comment to friend", \
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
        name:"hurtFriend" \
        hidden:false \
        type:#tagReference \
        description:"hurt by a friendly AI" \
        allowed:#(#sound), \
    tagField \
        name:"hurtFriendRe" \
        hidden:false \
        type:#tagReference \
        description:"hurt by a friendly AI" \
        allowed:#(#sound) \
        unit:" response from that friend", \
    tagField \
        name:"hurtFriendPlayer" \
        hidden:false \
        type:#tagReference \
        description:"hurt by a friendly player" \
        allowed:#(#sound), \
    tagField \
        name:"hurtEnemy" \
        hidden:false \
        type:#tagReference \
        description:"hurt by an enemy" \
        allowed:#(#sound), \
    tagField \
        name:"hurtEnemyRe" \
        hidden:false \
        type:#tagReference \
        description:"hurt by an enemy" \
        allowed:#(#sound) \
        unit:" response from the enemy that hurt us ('you like that?')", \
    tagField \
        name:"hurtEnemyCm" \
        hidden:false \
        type:#tagReference \
        description:"hurt by an enemy" \
        allowed:#(#sound) \
        unit:" comment from a friend of ours", \
    tagField \
        name:"hurtEnemyBullet" \
        hidden:false \
        type:#tagReference \
        description:"hurt by an enemy with bullets" \
        allowed:#(#sound), \
    tagField \
        name:"hurtEnemyNeedler" \
        hidden:false \
        type:#tagReference \
        description:"hurt by an enemy with needles" \
        allowed:#(#sound), \
    tagField \
        name:"hurtEnemyPlasma" \
        hidden:false \
        type:#tagReference \
        description:"hurt by an enemy with a plasma bolt" \
        allowed:#(#sound), \
    tagField \
        name:"hurtEnemySniper" \
        hidden:false \
        type:#tagReference \
        description:"hurt by an enemy with a sniper weapon" \
        allowed:#(#sound), \
    tagField \
        name:"hurtEnemyGrenade" \
        hidden:false \
        type:#tagReference \
        description:"a grenade is stuck to us" \
        allowed:#(#sound), \
    tagField \
        name:"hurtEnemyExplosion" \
        hidden:false \
        type:#tagReference \
        description:"hurt by an enemy with an explosive weapon" \
        allowed:#(#sound), \
    tagField \
        name:"hurtEnemyMelee" \
        hidden:false \
        type:#tagReference \
        description:"hurt by an enemy with a melee weapon" \
        allowed:#(#sound), \
    tagField \
        name:"hurtEnemyFlame" \
        hidden:false \
        type:#tagReference \
        description:"hurt by an enemy with flamethrower" \
        allowed:#(#sound), \
    tagField \
        name:"hurtEnemyShotgun" \
        hidden:false \
        type:#tagReference \
        description:"hurt by an enemy with a shotgun" \
        allowed:#(#sound), \
    tagField \
        name:"hurtEnemyVehicle" \
        hidden:false \
        type:#tagReference \
        description:"hurt by an enemy with a vehicle" \
        allowed:#(#sound), \
    tagField \
        name:"hurtEnemyMountedweapon" \
        hidden:false \
        type:#tagReference \
        description:"hurt by an enemy with a fixed weapon" \
        allowed:#(#sound), \
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
        name:"killedFriend" \
        hidden:false \
        type:#tagReference \
        description:"killed a friendly AI" \
        allowed:#(#sound), \
    tagField \
        name:"killedFriendCm" \
        hidden:false \
        type:#tagReference \
        description:"killed a friendly AI" \
        allowed:#(#sound) \
        unit:" comment from a friend", \
    tagField \
        name:"killedFriendPlayer" \
        hidden:false \
        type:#tagReference \
        description:"killed a friendly player" \
        allowed:#(#sound), \
    tagField \
        name:"killedFriendPlayerCm" \
        hidden:false \
        type:#tagReference \
        description:"killed a friendly player" \
        allowed:#(#sound) \
        unit:" comment from a friend", \
    tagField \
        name:"killedEnemy" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyCm" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy" \
        allowed:#(#sound) \
        unit:" comment from a friend", \
    tagField \
        name:"killedEnemyPlayer" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy player" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyPlayerCm" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy player" \
        allowed:#(#sound) \
        unit:" comment from a friend", \
    tagField \
        name:"killedEnemyCovenant" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy covenant" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyCovenantCm" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy covenant" \
        allowed:#(#sound) \
        unit:" comment from a friend", \
    tagField \
        name:"killedEnemyFloodcombat" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy flood combat form" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyFloodcombatCm" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy flood combat form" \
        allowed:#(#sound) \
        unit:" comment from a friend", \
    tagField \
        name:"killedEnemyFloodcarrier" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy flood carrier form" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyFloodcarrierCm" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy flood carrier form" \
        allowed:#(#sound) \
        unit:" comment from a friend", \
    tagField \
        name:"killedEnemySentinel" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy sentinel" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemySentinelCm" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy sentinel" \
        allowed:#(#sound) \
        unit:" comment from a friend", \
    tagField \
        name:"killedEnemyBullet" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy with bullets" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyNeedler" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy with needles" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyPlasma" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy with a plasma bolt" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemySniper" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy with a sniper weapon" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyGrenade" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy with a grenade" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyExplosion" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy with an explosive weapon" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyMelee" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy with a melee weapon" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyFlame" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy with flamethrower" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyShotgun" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy with a shotgun" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyVehicle" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy by hitting them with a vehicle" \
        allowed:#(#sound), \
    tagField \
        name:"killedEnemyMountedweapon" \
        hidden:false \
        type:#tagReference \
        description:"killed an enemy with a fixed weapon" \
        allowed:#(#sound), \
    tagField \
        name:"killingSpree" \
        hidden:false \
        type:#tagReference \
        description:"we are on a killing spree" \
        allowed:#(#sound), \
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
        name:"playerKillCm" \
        hidden:false \
        type:#tagReference \
        description:"response to the player killing an enemy" \
        allowed:#(#sound), \
    tagField \
        name:"playerKillBulletCm" \
        hidden:false \
        type:#tagReference \
        description:"response to the player killing an enemy with bullets" \
        allowed:#(#sound), \
    tagField \
        name:"playerKillNeedlerCm" \
        hidden:false \
        type:#tagReference \
        description:"response to the player killing an enemy with needles" \
        allowed:#(#sound), \
    tagField \
        name:"playerKillPlasmaCm" \
        hidden:false \
        type:#tagReference \
        description:"response to the player killing an enemy with a plasma bolt" \
        allowed:#(#sound), \
    tagField \
        name:"playerKillSniperCm" \
        hidden:false \
        type:#tagReference \
        description:"response to the player killing an enemy with a sniper weapon" \
        allowed:#(#sound), \
    tagField \
        name:"anyoneKillGrenadeCm" \
        hidden:false \
        type:#tagReference \
        description:"response to _anyone_ killing an enemy with a grenade" \
        allowed:#(#sound), \
    tagField \
        name:"playerKillExplosionCm" \
        hidden:false \
        type:#tagReference \
        description:"response to the player killing an enemy with an explosive weapon" \
        allowed:#(#sound), \
    tagField \
        name:"playerKillMeleeCm" \
        hidden:false \
        type:#tagReference \
        description:"response to the player killing an enemy with a melee weapon" \
        allowed:#(#sound), \
    tagField \
        name:"playerKillFlameCm" \
        hidden:false \
        type:#tagReference \
        description:"response to the player killing an enemy with flamethrower" \
        allowed:#(#sound), \
    tagField \
        name:"playerKillShotgunCm" \
        hidden:false \
        type:#tagReference \
        description:"response to the player killing an enemy with a shotgun" \
        allowed:#(#sound), \
    tagField \
        name:"playerKillVehicleCm" \
        hidden:false \
        type:#tagReference \
        description:"response to the player killing an enemy by hitting them with a vehicle" \
        allowed:#(#sound), \
    tagField \
        name:"playerKillMountedweaponCm" \
        hidden:false \
        type:#tagReference \
        description:"response to the player killing an enemy with a fixed weapon" \
        allowed:#(#sound), \
    tagField \
        name:"playerKilllingSpreeCm" \
        hidden:false \
        type:#tagReference \
        description:"response to the player going on a killing spree" \
        allowed:#(#sound), \
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
        name:"friendDied" \
        hidden:false \
        type:#tagReference \
        description:"a friendly AI died" \
        allowed:#(#sound), \
    tagField \
        name:"friendPlayerDied" \
        hidden:false \
        type:#tagReference \
        description:"a friendly player died" \
        allowed:#(#sound), \
    tagField \
        name:"friendKilledByFriend" \
        hidden:false \
        type:#tagReference \
        description:"a friend died from friendly fire" \
        allowed:#(#sound), \
    tagField \
        name:"friendKilledByFriendlyPlayer" \
        hidden:false \
        type:#tagReference \
        description:" friend died from player's friendly fire" \
        allowed:#(#sound), \
    tagField \
        name:"friendKilledByEnemy" \
        hidden:false \
        type:#tagReference \
        description:"a friend died from enemy fire" \
        allowed:#(#sound), \
    tagField \
        name:"friendKilledByEnemyPlayer" \
        hidden:false \
        type:#tagReference \
        description:" friend died from an enemy player" \
        allowed:#(#sound), \
    tagField \
        name:"friendKilledByCovenant" \
        hidden:false \
        type:#tagReference \
        description:"a friend died from covenant fire" \
        allowed:#(#sound), \
    tagField \
        name:"friendKilledByFlood" \
        hidden:false \
        type:#tagReference \
        description:"a friend died from the flood" \
        allowed:#(#sound), \
    tagField \
        name:"friendKilledBySentinel" \
        hidden:false \
        type:#tagReference \
        description:"a friend died from sentinel fire" \
        allowed:#(#sound), \
    tagField \
        name:"friendBetrayed" \
        hidden:false \
        type:#tagReference \
        description:"a friend was deliberately killed by an ally that we don't trust (e.g. player killed a marine)" \
        allowed:#(#sound), \
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
        name:"newCombatAlone" \
        hidden:false \
        type:#tagReference \
        description:"see an enemy and we have not previously been in combat" \
        allowed:#(#sound), \
    tagField \
        name:"newEnemyRecentCombat" \
        hidden:false \
        type:#tagReference \
        description:"see a new enemy and we have recently been in combat" \
        allowed:#(#sound), \
    tagField \
        name:"oldEnemySighted" \
        hidden:false \
        type:#tagReference \
        description:"see an enemy that we are currently looking for" \
        allowed:#(#sound), \
    tagField \
        name:"unexpectedEnemy" \
        hidden:false \
        type:#tagReference \
        description:"unexpectedly encounters enemy (behind or to the side)" \
        allowed:#(#sound), \
    tagField \
        name:"deadFriendFound" \
        hidden:false \
        type:#tagReference \
        description:"unexpectedly finds a dead body of a friend" \
        allowed:#(#sound), \
    tagField \
        name:"allianceBroken" \
        hidden:false \
        type:#tagReference \
        description:"we decide that a former ally is now a traitor" \
        allowed:#(#sound), \
    tagField \
        name:"allianceReformed" \
        hidden:false \
        type:#tagReference \
        description:"we forgive a traitor and make him our friend again" \
        allowed:#(#sound), \
    tagField \
        name:"grenadeThrowing" \
        hidden:false \
        type:#tagReference \
        description:"throwing a grenade" \
        allowed:#(#sound), \
    tagField \
        name:"grenadeSighted" \
        hidden:false \
        type:#tagReference \
        description:"see an enemy grenade" \
        allowed:#(#sound), \
    tagField \
        name:"grenadeStartle" \
        hidden:false \
        type:#tagReference \
        description:"alerted by a grenade bouncing near us" \
        allowed:#(#sound), \
    tagField \
        name:"grenadeDangerEnemy" \
        hidden:false \
        type:#tagReference \
        description:"in danger from an enemy grenade" \
        allowed:#(#sound), \
    tagField \
        name:"grenadeDangerSelf" \
        hidden:false \
        type:#tagReference \
        description:"in danger from your own grenade" \
        allowed:#(#sound), \
    tagField \
        name:"grenadeDangerFriend" \
        hidden:false \
        type:#tagReference \
        description:"in danger from a friendly grenade (not our own)" \
        allowed:#(#sound), \
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
        name:"newCombatGroupRe" \
        hidden:false \
        type:#tagReference \
        description:"reply to a nearby friend who alerted us to an enemy" \
        allowed:#(#sound), \
    tagField \
        name:"newCombatNearbyRe" \
        hidden:false \
        type:#tagReference \
        description:"reply to a distant friend who alerted us to an enemy" \
        allowed:#(#sound), \
    tagField \
        name:"alertFriend" \
        hidden:false \
        type:#tagReference \
        description:"alert a friend who is in a noncombat state" \
        allowed:#(#sound), \
    tagField \
        name:"alertFriendRe" \
        hidden:false \
        type:#tagReference \
        description:"alerted by a friend when in a noncombat state" \
        allowed:#(#sound), \
    tagField \
        name:"alertLostContact" \
        hidden:false \
        type:#tagReference \
        description:"alert friends that target was not at expected location" \
        allowed:#(#sound), \
    tagField \
        name:"alertLostContactRe" \
        hidden:false \
        type:#tagReference \
        description:"alert friends that target was not at expected location" \
        allowed:#(#sound) \
        unit:" response", \
    tagField \
        name:"blocked" \
        hidden:false \
        type:#tagReference \
        description:"friend is blocking us from moving or firing" \
        allowed:#(#sound), \
    tagField \
        name:"blockedRe" \
        hidden:false \
        type:#tagReference \
        description:"friend is blocking us from moving or firing" \
        allowed:#(#sound) \
        unit:" response", \
    tagField \
        name:"searchStart" \
        hidden:false \
        type:#tagReference \
        description:"starting to search" \
        allowed:#(#sound), \
    tagField \
        name:"searchQuery" \
        hidden:false \
        type:#tagReference \
        description:"asking searchers whether they have found anything" \
        allowed:#(#sound), \
    tagField \
        name:"searchQueryRe" \
        hidden:false \
        type:#tagReference \
        description:"asking searchers whether they have found anything" \
        allowed:#(#sound) \
        unit:" response", \
    tagField \
        name:"searchReport" \
        hidden:false \
        type:#tagReference \
        description:"searcher reporting that an area is clear" \
        allowed:#(#sound), \
    tagField \
        name:"searchAbandon" \
        hidden:false \
        type:#tagReference \
        description:"searcher giving up on search" \
        allowed:#(#sound), \
    tagField \
        name:"searchGroupAbandon" \
        hidden:false \
        type:#tagReference \
        description:"search coordinator giving up on search" \
        allowed:#(#sound), \
    tagField \
        name:"groupUncover" \
        hidden:false \
        type:#tagReference \
        description:"starting to uncover target with friend" \
        allowed:#(#sound), \
    tagField \
        name:"groupUncoverRe" \
        hidden:false \
        type:#tagReference \
        description:"starting to uncover target" \
        allowed:#(#sound) \
        unit:" response", \
    tagField \
        name:"advance" \
        hidden:false \
        type:#tagReference \
        description:"our platoon starts to attack or advance" \
        allowed:#(#sound), \
    tagField \
        name:"advanceRe" \
        hidden:false \
        type:#tagReference \
        description:"our platoon starts to attack or advance" \
        allowed:#(#sound) \
        unit:" response", \
    tagField \
        name:"retreat" \
        hidden:false \
        type:#tagReference \
        description:"our platoon starts to defend or retreat" \
        allowed:#(#sound), \
    tagField \
        name:"retreatRe" \
        hidden:false \
        type:#tagReference \
        description:"our platoon starts to defend or retreat" \
        allowed:#(#sound) \
        unit:" response", \
    tagField \
        name:"cover" \
        hidden:false \
        type:#tagReference \
        description:"telling friends to seek cover" \
        allowed:#(#sound), \
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
        name:"sightedFriendPlayer" \
        hidden:false \
        type:#tagReference \
        description:"sighted a new friendly player" \
        allowed:#(#sound), \
    tagField \
        name:"shooting" \
        hidden:false \
        type:#tagReference \
        description:"shooting at an enemy" \
        allowed:#(#sound), \
    tagField \
        name:"shootingVehicle" \
        hidden:false \
        type:#tagReference \
        description:"shooting from a vehicle at an enemy" \
        allowed:#(#sound), \
    tagField \
        name:"shootingBerserk" \
        hidden:false \
        type:#tagReference \
        description:"shooting at an enemy while berserk" \
        allowed:#(#sound), \
    tagField \
        name:"shootingGroup" \
        hidden:false \
        type:#tagReference \
        description:"shooting at a group of enemies" \
        allowed:#(#sound), \
    tagField \
        name:"shootingTraitor" \
        hidden:false \
        type:#tagReference \
        description:"shooting at a traitorous player" \
        allowed:#(#sound), \
    tagField \
        name:"taunt" \
        hidden:false \
        type:#tagReference \
        description:"taunting the enemy" \
        allowed:#(#sound), \
    tagField \
        name:"tauntRe" \
        hidden:false \
        type:#tagReference \
        description:"taunted by an enemy" \
        allowed:#(#sound) \
        unit:" response", \
    tagField \
        name:"flee" \
        hidden:false \
        type:#tagReference \
        description:"fleeing in panic" \
        allowed:#(#sound), \
    tagField \
        name:"fleeRe" \
        hidden:false \
        type:#tagReference \
        description:"fleeing in panic" \
        allowed:#(#sound) \
        unit:" response", \
    tagField \
        name:"fleeLeaderDied" \
        hidden:false \
        type:#tagReference \
        description:"fleeing in panic because our leaders are all dead" \
        allowed:#(#sound), \
    tagField \
        name:"attemptedFlee" \
        hidden:false \
        type:#tagReference \
        description:"unable to flee because a leader is nearby" \
        allowed:#(#sound), \
    tagField \
        name:"attemptedFleeRe" \
        hidden:false \
        type:#tagReference \
        description:"unable to flee because a leader is nearby - response" \
        allowed:#(#sound), \
    tagField \
        name:"lostContact" \
        hidden:false \
        type:#tagReference \
        description:"target was not at expected location" \
        allowed:#(#sound), \
    tagField \
        name:"hidingFinished" \
        hidden:false \
        type:#tagReference \
        description:"stops hiding and pursues target" \
        allowed:#(#sound), \
    tagField \
        name:"vehicleEntry" \
        hidden:false \
        type:#tagReference \
        description:"enters vehicle" \
        allowed:#(#sound), \
    tagField \
        name:"vehicleExit" \
        hidden:false \
        type:#tagReference \
        description:"exits vehicle" \
        allowed:#(#sound), \
    tagField \
        name:"vehicleWoohoo" \
        hidden:false \
        type:#tagReference \
        description:"excited while in vehicle (big air, etc)" \
        allowed:#(#sound), \
    tagField \
        name:"vehicleScared" \
        hidden:false \
        type:#tagReference \
        description:"scared while in vehicle (imminent crash)" \
        allowed:#(#sound), \
    tagField \
        name:"vehicleCollision" \
        hidden:false \
        type:#tagReference \
        description:"riding in a vehicle and the driver collides with something" \
        allowed:#(#sound), \
    tagField \
        name:"partiallySighted" \
        hidden:false \
        type:#tagReference \
        description:"saw something suspicious but not sure it was an enemy" \
        allowed:#(#sound), \
    tagField \
        name:"nothingThere" \
        hidden:false \
        type:#tagReference \
        description:"decided that a suspicious sighting was nothing after all" \
        allowed:#(#sound), \
    tagField \
        name:"pleading" \
        hidden:false \
        type:#tagReference \
        description:"pleading for the player to spare our pitiable lives" \
        allowed:#(#sound), \
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
        count:16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"surprise" \
        hidden:false \
        type:#tagReference \
        description:"surprised by an enemy, noise, body or weapon impact" \
        allowed:#(#sound), \
    tagField \
        name:"berserk" \
        hidden:false \
        type:#tagReference \
        description:"went berserk" \
        allowed:#(#sound), \
    tagField \
        name:"meleeAttack" \
        hidden:false \
        type:#tagReference \
        description:"attacked an enemy in melee" \
        allowed:#(#sound), \
    tagField \
        name:"dive" \
        hidden:false \
        type:#tagReference \
        description:"dove away from danger or into cover" \
        allowed:#(#sound), \
    tagField \
        name:"uncoverExclamation" \
        hidden:false \
        type:#tagReference \
        description:"leapt out of corner to uncover a suspected target" \
        allowed:#(#sound), \
    tagField \
        name:"leapAttack" \
        hidden:false \
        type:#tagReference \
        description:"begin a leap attack" \
        allowed:#(#sound), \
    tagField \
        name:"resurrection" \
        hidden:false \
        type:#tagReference \
        description:"arise and return to life" \
        allowed:#(#sound), \
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
        name:"celebration" \
        hidden:false \
        type:#tagReference \
        description:"all enemies defeated" \
        allowed:#(#sound), \
    tagField \
        name:"checkBodyEnemy" \
        hidden:false \
        type:#tagReference \
        description:"post-combat checking an enemy's dead body" \
        allowed:#(#sound), \
    tagField \
        name:"checkBodyFriend" \
        hidden:false \
        type:#tagReference \
        description:"post-combat checking a friend's dead body" \
        allowed:#(#sound), \
    tagField \
        name:"shootingDeadEnemy" \
        hidden:false \
        type:#tagReference \
        description:"post-combat shooting an enemy's dead body" \
        allowed:#(#sound), \
    tagField \
        name:"shootingDeadEnemyPlayer" \
        hidden:false \
        type:#tagReference \
        description:"post-combat shooting an enemy player's dead body" \
        allowed:#(#sound), \
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
        name:"alone" \
        hidden:false \
        type:#tagReference \
        description:"post-combat all friends killed" \
        allowed:#(#sound), \
    tagField \
        name:"unscathed" \
        hidden:false \
        type:#tagReference \
        description:"post-combat we were not hurt" \
        allowed:#(#sound), \
    tagField \
        name:"seriouslyWounded" \
        hidden:false \
        type:#tagReference \
        description:"post-combat we were badly hurt" \
        allowed:#(#sound), \
    tagField \
        name:"seriouslyWoundedRe" \
        hidden:false \
        type:#tagReference \
        description:"post-combat replying to a friend who was badly hurt" \
        allowed:#(#sound), \
    tagField \
        name:"massacre" \
        hidden:false \
        type:#tagReference \
        description:"post-combat our friends took heavy casualties" \
        allowed:#(#sound), \
    tagField \
        name:"massacreRe" \
        hidden:false \
        type:#tagReference \
        description:"post-combat reply" \
        allowed:#(#sound) \
        unit:" our friends took heavy casualties", \
    tagField \
        name:"rout" \
        hidden:false \
        type:#tagReference \
        description:"post-combat our friends kicked alien ass" \
        allowed:#(#sound), \
    tagField \
        name:"routRe" \
        hidden:false \
        type:#tagReference \
        description:"post-combat reply" \
        allowed:#(#sound) \
        unit:" our friends kicked alien ass", \
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
        count:752
)

dialogueBlock = tagBlock \
    name:"dialogueBlock" \
    length:4112 \
    maximum:1 \
    fields:dialogueFields

dialogueDef = tagDef \
    fourcc:1969515623 \
    supergroup:undefined \
    tagBlock:dialogueBlock
