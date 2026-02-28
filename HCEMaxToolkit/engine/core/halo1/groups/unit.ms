unitCameratracksFields = #(
    tagField \
        name:"track" \
        hidden:false \
        type:#tagReference \
        allowed:#(#camera_track), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12
)

unitCameratracksBlock = tagBlock \
    name:"cameraTracksBlock" \
    length:28 \
    maximum:2 \
    fields:unitCameratracksFields

unitNewhudinterfacesFields = #(
    tagField \
        name:"unitHudInterface" \
        hidden:false \
        type:#tagReference \
        allowed:#(#unit_hud_interface), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

unitNewhudinterfacesBlock = tagBlock \
    name:"newHudInterfacesBlock" \
    length:48 \
    maximum:2 \
    fields:unitNewhudinterfacesFields

unitDialoguevariantsFields = #(
    tagField \
        name:"variantNumber" \
        hidden:false \
        type:#int16 \
        description:"variant number to use this dialogue with (must match the suffix in the permutations on the unit's model)", \
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
        count:4, \
    tagField \
        name:"dialogue" \
        hidden:false \
        type:#tagReference \
        allowed:#(#dialogue)
)

unitDialoguevariantsBlock = tagBlock \
    name:"dialogueVariantsBlock" \
    length:24 \
    maximum:16 \
    fields:unitDialoguevariantsFields

unitPoweredseatsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"driverPowerupTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"driverPowerdownTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:56
)

unitPoweredseatsBlock = tagBlock \
    name:"poweredSeatsBlock" \
    length:68 \
    maximum:2 \
    fields:unitPoweredseatsFields

unitWeaponsFields = #(
    tagField \
        name:"weapon" \
        hidden:false \
        type:#tagReference \
        allowed:#(#weapon), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20
)

unitWeaponsBlock = tagBlock \
    name:"weaponsBlock" \
    length:36 \
    maximum:4 \
    fields:unitWeaponsFields

unitSeatscameratracksFields = #(
    tagField \
        name:"track" \
        hidden:false \
        type:#tagReference \
        allowed:#(#camera_track), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12
)

unitSeatscameratracksBlock = tagBlock \
    name:"seatsCameraTracksBlock" \
    length:28 \
    maximum:2 \
    fields:unitSeatscameratracksFields

unitUnithudinterfaceFields = #(
    tagField \
        name:"unitHudInterface" \
        hidden:false \
        type:#tagReference \
        allowed:#(#unit_hud_interface), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

unitUnithudinterfaceBlock = tagBlock \
    name:"unitHudInterfaceBlock" \
    length:48 \
    maximum:2 \
    fields:unitUnithudinterfaceFields

unitSeatsFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"label" \
        hidden:false \
        type:#string, \
    tagField \
        name:"markerName" \
        hidden:false \
        type:#string, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"accelerationScale" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"yawRate" \
        hidden:false \
        type:#float \
        unit:"degrees per second", \
    tagField \
        name:"pitchRate" \
        hidden:false \
        type:#float \
        unit:"degrees per second", \
    tagField \
        name:"cameraMarkerName" \
        hidden:false \
        type:#string, \
    tagField \
        name:"cameraSubmergedMarkerName" \
        hidden:false \
        type:#string, \
    tagField \
        name:"pitchAutoLevel" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"pitchRange" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"cameraTracks" \
        hidden:false \
        type:#block \
        block:unitSeatscameratracksBlock, \
    tagField \
        name:"unitHudInterface" \
        hidden:false \
        type:#block \
        block:unitUnithudinterfaceBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"hudTextMessageIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"yawMinimum" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"yawMaximum" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"builtInGunner" \
        hidden:false \
        type:#tagReference \
        allowed:#(#actor_variant), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20
)

unitSeatsBlock = tagBlock \
    name:"seatsBlock" \
    length:284 \
    maximum:16 \
    fields:unitSeatsFields

unitFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"defaultTeam" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"constantSoundVolume" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"riderDamageFraction" \
        hidden:false \
        type:#float \
        description:"what percent damage applied to us gets applied to our children (i.e., riders)" \
        unit:"[0,+inf]", \
    tagField \
        name:"integratedLightToggle" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
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
        name:"cameraFieldOfView" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"cameraStiffness" \
        hidden:false \
        type:#float, \
    tagField \
        name:"cameraMarkerName" \
        hidden:false \
        type:#string, \
    tagField \
        name:"cameraSubmergedMarkerName" \
        hidden:false \
        type:#string, \
    tagField \
        name:"pitchAutoLevel" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"pitchRange" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"cameraTracks" \
        hidden:false \
        type:#block \
        block:unitCameratracksBlock, \
    tagField \
        name:"seatAccelerationScale" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"softPingThreshold" \
        hidden:false \
        type:#float \
        unit:"[0,1]", \
    tagField \
        name:"softPingInterruptTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"hardPingThreshold" \
        hidden:false \
        type:#float \
        unit:"[0,1]", \
    tagField \
        name:"hardPingInterruptTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"hardDeathThreshold" \
        hidden:false \
        type:#float \
        unit:"[0,1]", \
    tagField \
        name:"feignDeathThreshold" \
        hidden:false \
        type:#float \
        unit:"[0,1]", \
    tagField \
        name:"feignDeathTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"distanceOfEvadeAnim" \
        hidden:false \
        type:#float \
        description:"this must be set to tell the AI how far it should expect our evade animation to move us" \
        unit:"world units", \
    tagField \
        name:"distanceOfDiveAnim" \
        hidden:false \
        type:#float \
        description:"this must be set to tell the AI how far it should expect our dive animation to move us" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"stunnedMovementThreshold" \
        hidden:false \
        type:#float \
        description:"if we take this much damage in a short space of time we will play our 'stunned movement' animations" \
        unit:"[0,1]", \
    tagField \
        name:"feignDeathChance" \
        hidden:false \
        type:#float \
        unit:"[0,1]", \
    tagField \
        name:"feignRepeatChance" \
        hidden:false \
        type:#float \
        unit:"[0,1]", \
    tagField \
        name:"spawnedActor" \
        hidden:false \
        type:#tagReference \
        description:"actor variant which we spawn when we are destroyed or self-destruct" \
        allowed:#(#actor_variant), \
    tagField \
        name:"spawnedActorCount" \
        hidden:false \
        type:#int16 \
        description:"number of actors spawned (lower bound)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"spawnedVelocity" \
        hidden:false \
        type:#float \
        description:"velocity at which we throw spawned actors", \
    tagField \
        name:"aimingVelocityMaximum" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees per second", \
    tagField \
        name:"aimingAccelerationMaximum" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees per second squared", \
    tagField \
        name:"casualAimingModifier" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
    tagField \
        name:"lookingVelocityMaximum" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees per second", \
    tagField \
        name:"lookingAccelerationMaximum" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees per second squared", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"aiVehicleRadius" \
        hidden:false \
        type:#float \
        description:"radius around this unit that the AI tries to avoid when entering it as a vehicle (zero = use bounding sphere radius)", \
    tagField \
        name:"aiDangerRadius" \
        hidden:false \
        type:#float \
        description:"danger radius around this unit that the AI tries to avoid", \
    tagField \
        name:"meleeDamage" \
        hidden:false \
        type:#tagReference \
        allowed:#(#damage_effect), \
    tagField \
        name:"motionSensorBlipSize" \
        hidden:false \
        type:#enum, \
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
        name:"newHudInterfaces" \
        hidden:false \
        type:#block \
        block:unitNewhudinterfacesBlock, \
    tagField \
        name:"dialogueVariants" \
        hidden:false \
        type:#block \
        block:unitDialoguevariantsBlock, \
    tagField \
        name:"grenadeVelocity" \
        hidden:false \
        type:#float \
        unit:"world units per second", \
    tagField \
        name:"grenadeType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"grenadeCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"poweredSeats" \
        hidden:false \
        type:#block \
        block:unitPoweredseatsBlock, \
    tagField \
        name:"weapons" \
        hidden:false \
        type:#block \
        block:unitWeaponsBlock, \
    tagField \
        name:"seats" \
        hidden:false \
        type:#block \
        block:unitSeatsBlock
)

unitBlock = tagBlock \
    name:"unitBlock" \
    length:372 \
    maximum:1 \
    fields:unitFields

unitDef = tagDef \
    fourcc:1970170228 \
    supergroup:#object \
    tagBlock:unitBlock
