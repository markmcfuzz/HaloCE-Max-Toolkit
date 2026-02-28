effectLocationsFields = #(
    tagField \
        name:"markerName" \
        hidden:false \
        type:#string
)

effectLocationsBlock = tagBlock \
    name:"locationsBlock" \
    length:32 \
    maximum:32 \
    fields:effectLocationsFields

effectPartsFields = #(
    tagField \
        name:"createIn" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"createIn" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"location" \
        hidden:false \
        type:#index, \
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
        count:16, \
    tagField \
        name:"type" \
        hidden:false \
        type:#tagReference \
        allowed:#(#damage_effect,#object,#particle_system,#sound,#decal,#light), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"velocityBounds" \
        hidden:false \
        type:#floatBounds \
        description:"initial velocity along the location's forward" \
        unit:"world units per second", \
    tagField \
        name:"velocityConeAngle" \
        hidden:false \
        type:#floatAngle \
        description:"initial velocity will be inside the cone defined by this angle." \
        unit:"degrees", \
    tagField \
        name:"angularVelocityBounds" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees per second", \
    tagField \
        name:"radiusModifierBounds" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"aScalesValues" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"bScalesValues" \
        hidden:false \
        type:#bitfield \
        size:#int32
)

effectPartsBlock = tagBlock \
    name:"partsBlock" \
    length:104 \
    maximum:32 \
    fields:effectPartsFields

effectParticlesFields = #(
    tagField \
        name:"createIn" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"createIn" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"create" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"location" \
        hidden:false \
        type:#index, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"relativeDirection" \
        hidden:false \
        type:#euler2d \
        description:"particle initial velocity direction relative to the location's forward", \
    tagField \
        name:"relativeOffset" \
        hidden:false \
        type:#vector3d \
        description:"particle initial position offset relative to the locatin's forward", \
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
        count:40, \
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
        name:"distributionFunction" \
        hidden:false \
        type:#enum \
        description:"describes how the part creations are distributed over the event duration", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"count" \
        hidden:false \
        type:#int16 \
        description:"number of particles created", \
    tagField \
        name:"distributionRadius" \
        hidden:false \
        type:#floatBounds \
        description:"initial distance from the location's origin" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"velocity" \
        hidden:false \
        type:#floatBounds \
        description:"initial velocity along the specified direction" \
        unit:"world units per second", \
    tagField \
        name:"velocityConeAngle" \
        hidden:false \
        type:#floatAngle \
        description:"particle initial velocities will be inside the cone defined by this angle and the specified direction" \
        unit:"degrees", \
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
        count:16, \
    tagField \
        name:"aScalesValues" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"bScalesValues" \
        hidden:false \
        type:#bitfield \
        size:#int32
)

effectParticlesBlock = tagBlock \
    name:"particlesBlock" \
    length:232 \
    maximum:32 \
    fields:effectParticlesFields

effectEventsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"skipFraction" \
        hidden:false \
        type:#floatClamped \
        description:"chance that this event will be skipped entirely", \
    tagField \
        name:"delayBounds" \
        hidden:false \
        type:#floatBounds \
        description:"delay before this event takes place" \
        unit:"seconds", \
    tagField \
        name:"durationBounds" \
        hidden:false \
        type:#floatBounds \
        description:"duration of this event" \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20, \
    tagField \
        name:"parts" \
        hidden:false \
        type:#block \
        block:effectPartsBlock, \
    tagField \
        name:"particles" \
        hidden:false \
        type:#block \
        block:effectParticlesBlock
)

effectEventsBlock = tagBlock \
    name:"eventsBlock" \
    length:68 \
    maximum:32 \
    fields:effectEventsFields

effectFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"loopStartEvent" \
        hidden:false \
        type:#index, \
    tagField \
        name:"loopStopEvent" \
        hidden:false \
        type:#index, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"locations" \
        hidden:false \
        type:#block \
        block:effectLocationsBlock, \
    tagField \
        name:"events" \
        hidden:false \
        type:#block \
        block:effectEventsBlock
)

effectBlock = tagBlock \
    name:"effectBlock" \
    length:64 \
    maximum:1 \
    fields:effectFields

effectDef = tagDef \
    fourcc:1701209701 \
    supergroup:undefined \
    tagBlock:effectBlock
