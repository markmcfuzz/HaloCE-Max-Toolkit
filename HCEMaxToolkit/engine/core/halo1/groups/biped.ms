bipedContactpointsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"markerName" \
        hidden:false \
        type:#string
)

bipedContactpointsBlock = tagBlock \
    name:"contactPointsBlock" \
    length:64 \
    maximum:2 \
    fields:bipedContactpointsFields

bipedFields = #(
    tagField \
        name:"movingTurningSpeed" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees per second", \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"stationaryTurningThreshold" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
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
        name:"don'tUse" \
        hidden:false \
        type:#tagReference \
        allowed:#(#damage_effect), \
    tagField \
        name:"bankAngle" \
        hidden:false \
        type:#floatAngle \
        description:"angle at which we bank left/right when sidestepping or turning while moving forwards" \
        unit:"degrees", \
    tagField \
        name:"bankApplyTime" \
        hidden:false \
        type:#float \
        description:"time it takes us to apply a bank" \
        unit:"seconds", \
    tagField \
        name:"bankDecayTime" \
        hidden:false \
        type:#float \
        description:"time it takes us to recover from a bank" \
        unit:"seconds", \
    tagField \
        name:"pitchRatio" \
        hidden:false \
        type:#float \
        description:"amount that we pitch up/down when moving up or down", \
    tagField \
        name:"maxVelocity" \
        hidden:false \
        type:#float \
        description:"max velocity when not crouching" \
        unit:"world units per second", \
    tagField \
        name:"maxSidestepVelocity" \
        hidden:false \
        type:#float \
        description:"max sideways or up/down velocity when not crouching" \
        unit:"world units per second", \
    tagField \
        name:"acceleration" \
        hidden:false \
        type:#float \
        unit:"world units per second squared", \
    tagField \
        name:"deceleration" \
        hidden:false \
        type:#float \
        unit:"world units per second squared", \
    tagField \
        name:"angularVelocityMaximum" \
        hidden:false \
        type:#floatAngle \
        description:"turn rate" \
        unit:"degrees per second", \
    tagField \
        name:"angularAccelerationMaximum" \
        hidden:false \
        type:#floatAngle \
        description:"turn acceleration rate" \
        unit:"degrees per second squared", \
    tagField \
        name:"crouchVelocityModifier" \
        hidden:false \
        type:#float \
        description:"how much slower we fly if crouching (zero = same speed)" \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"maximumSlopeAngle" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"downhillFalloffAngle" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"downhillCutoffAngle" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"downhillVelocityScale" \
        hidden:false \
        type:#float, \
    tagField \
        name:"uphillFalloffAngle" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"uphillCutoffAngle" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"uphillVelocityScale" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"footsteps" \
        hidden:false \
        type:#tagReference \
        allowed:#(#material_effects), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"jumpVelocity" \
        hidden:false \
        type:#float \
        unit:"world units per second", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28, \
    tagField \
        name:"maximumSoftLandingTime" \
        hidden:false \
        type:#float \
        description:"the longest amount of time the biped can take to recover from a soft landing" \
        unit:"seconds", \
    tagField \
        name:"maximumHardLandingTime" \
        hidden:false \
        type:#float \
        description:"the longest amount of time the biped can take to recover from a hard landing" \
        unit:"seconds", \
    tagField \
        name:"minimumSoftLandingVelocity" \
        hidden:false \
        type:#float \
        description:"below this velocity the biped does not react when landing" \
        unit:"world units per second", \
    tagField \
        name:"minimumHardLandingVelocity" \
        hidden:false \
        type:#float \
        description:"below this velocity the biped will not do a soft landing when returning to the ground" \
        unit:"world units per second", \
    tagField \
        name:"maximumHardLandingVelocity" \
        hidden:false \
        type:#float \
        description:"the velocity corresponding to the maximum landing time" \
        unit:"world units per second", \
    tagField \
        name:"deathHardLandingVelocity" \
        hidden:false \
        type:#float \
        description:"the maximum velocity with which a character can strike the ground and live" \
        unit:"world units per second", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20, \
    tagField \
        name:"standingCameraHeight" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"crouchingCameraHeight" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"crouchTransitionTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"standingCollisionHeight" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"crouchingCollisionHeight" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"collisionRadius" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:40, \
    tagField \
        name:"autoaimWidth" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:140, \
    tagField \
        name:"contactPoints" \
        hidden:false \
        type:#block \
        description:"these are the points where the biped touches the ground" \
        block:bipedContactpointsBlock
)

bipedBlock = tagBlock \
    name:"bipedBlock" \
    length:516 \
    maximum:1 \
    fields:bipedFields

bipedDef = tagDef \
    fourcc:1651077220 \
    supergroup:#unit \
    tagBlock:bipedBlock
