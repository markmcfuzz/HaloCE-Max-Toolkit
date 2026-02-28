particleSystemPhysicsconstantsFields = #(
    tagField \
        name:"k" \
        hidden:false \
        type:#float \
        description:"The meaning of this constant depends on the selected physics creation/update function."
)

particleSystemPhysicsconstantsBlock = tagBlock \
    name:"physicsConstantsBlock" \
    length:4 \
    maximum:16 \
    fields:particleSystemPhysicsconstantsFields

particleSystemParticletypesphysicsconstantsFields = #(
    tagField \
        name:"k" \
        hidden:false \
        type:#float \
        description:"The meaning of this constant depends on the selected physics creation/update function."
)

particleSystemParticletypesphysicsconstantsBlock = tagBlock \
    name:"particleTypesPhysicsConstantsBlock" \
    length:4 \
    maximum:16 \
    fields:particleSystemParticletypesphysicsconstantsFields

particleSystemStatesphysicsconstantsFields = #(
    tagField \
        name:"k" \
        hidden:false \
        type:#float \
        description:"The meaning of this constant depends on the selected physics creation/update function."
)

particleSystemStatesphysicsconstantsBlock = tagBlock \
    name:"statesPhysicsConstantsBlock" \
    length:4 \
    maximum:16 \
    fields:particleSystemStatesphysicsconstantsFields

particleSystemStatesFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"durationBounds" \
        hidden:false \
        type:#floatBounds \
        description:"Time in this state." \
        unit:"seconds", \
    tagField \
        name:"transitionTimeBounds" \
        hidden:false \
        type:#floatBounds \
        description:"Time spent in transition to next state." \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"scaleMultiplier" \
        hidden:false \
        type:#float \
        description:"This value will be multiplied into the scale computed by the particles' state.", \
    tagField \
        name:"animationRateMultiplier" \
        hidden:false \
        type:#float \
        description:"This value will be multiplied into the animation rate computed by the particles' state.", \
    tagField \
        name:"rotationRateMultiplier" \
        hidden:false \
        type:#float \
        description:"This value will be multiplied into the rotation rate computed by the particles' state.", \
    tagField \
        name:"colorMultiplier" \
        hidden:false \
        type:#colorARGB \
        description:"This value will be multiplied into the color computed by the particles' state.", \
    tagField \
        name:"radiusMultiplier" \
        hidden:false \
        type:#float \
        description:"This value will be multiplied into the radius computed by the type.", \
    tagField \
        name:"minimumParticleCount" \
        hidden:false \
        type:#float, \
    tagField \
        name:"particleCreationRate" \
        hidden:false \
        type:#float \
        unit:"particles per second", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:84, \
    tagField \
        name:"particleCreationPhysics" \
        hidden:false \
        type:#enum \
        description:"This controls the placement of particles created during this state.", \
    tagField \
        name:"particleUpdatePhysics" \
        hidden:false \
        type:#enum \
        description:"This controls the motion of particles during this state.", \
    tagField \
        name:"physicsConstants" \
        hidden:false \
        type:#block \
        block:particleSystemStatesphysicsconstantsBlock
)

particleSystemStatesBlock = tagBlock \
    name:"statesBlock" \
    length:192 \
    maximum:8 \
    fields:particleSystemStatesFields

particleSystemParticlestatesphysicsconstantsFields = #(
    tagField \
        name:"k" \
        hidden:false \
        type:#float \
        description:"The meaning of this constant depends on the selected physics creation/update function."
)

particleSystemParticlestatesphysicsconstantsBlock = tagBlock \
    name:"particleStatesPhysicsConstantsBlock" \
    length:4 \
    maximum:16 \
    fields:particleSystemParticlestatesphysicsconstantsFields

particleSystemParticlestatesFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"durationBounds" \
        hidden:false \
        type:#floatBounds \
        description:"Time in this state." \
        unit:"seconds", \
    tagField \
        name:"transitionTimeBounds" \
        hidden:false \
        type:#floatBounds \
        description:"Time spent in transition to next state." \
        unit:"seconds", \
    tagField \
        name:"bitmaps" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"sequenceIndex" \
        hidden:false \
        type:#int16, \
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
        name:"scale" \
        hidden:false \
        type:#floatBounds \
        description:"Apparent size of the particles." \
        unit:"world units per pixel", \
    tagField \
        name:"animationRate" \
        hidden:false \
        type:#floatBounds \
        description:"Rate of sprite animation." \
        unit:"frames per second", \
    tagField \
        name:"rotationRate" \
        hidden:false \
        type:#floatAngle \
        description:"Rate of texture rotation." \
        unit:"degrees per second", \
    tagField \
        name:"color1" \
        hidden:false \
        type:#colorARGB \
        description:"Particle will have a random color in the range determined by these two colors.", \
    tagField \
        name:"color2" \
        hidden:false \
        type:#colorARGB \
        description:"Particle will have a random color in the range determined by these two colors.", \
    tagField \
        name:"radiusMultiplier" \
        hidden:false \
        type:#float \
        description:"This value will be multiplied into the radius computed by the type.", \
    tagField \
        name:"pointPhysics" \
        hidden:false \
        type:#tagReference \
        allowed:#(#point_physics), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:36, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:40, \
    tagField \
        name:"shaderFlags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"framebufferBlendFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"framebufferFadeMode" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"mapFlags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28, \
    tagField \
        name:"bitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"anchor" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"uAnimationSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"uAnimationFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"uAnimationPeriod" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"seconds", \
    tagField \
        name:"uAnimationPhase" \
        hidden:false \
        type:#float, \
    tagField \
        name:"uAnimationScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"repeats", \
    tagField \
        name:"vAnimationSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"vAnimationFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"vAnimationPeriod" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"seconds", \
    tagField \
        name:"vAnimationPhase" \
        hidden:false \
        type:#float, \
    tagField \
        name:"vAnimationScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"repeats", \
    tagField \
        name:"rotationAnimationSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"rotationAnimationFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"rotationAnimationPeriod" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"seconds", \
    tagField \
        name:"rotationAnimationPhase" \
        hidden:false \
        type:#float, \
    tagField \
        name:"rotationAnimationScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 360" \
        unit:"degrees", \
    tagField \
        name:"rotationAnimationCenter" \
        hidden:false \
        type:#point2d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"zspriteRadiusScale" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20, \
    tagField \
        name:"physicsConstants" \
        hidden:false \
        type:#block \
        block:particleSystemParticlestatesphysicsconstantsBlock
)

particleSystemParticlestatesBlock = tagBlock \
    name:"particleStatesBlock" \
    length:376 \
    maximum:8 \
    fields:particleSystemParticlestatesFields

particleSystemParticletypesFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"initialParticleCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"complexSpriteRenderModes" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"radius" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:36, \
    tagField \
        name:"particleCreationPhysics" \
        hidden:false \
        type:#enum \
        description:"This controls the initial placement of particles.", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"physicsFlags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"physicsConstants" \
        hidden:false \
        type:#block \
        block:particleSystemParticletypesphysicsconstantsBlock, \
    tagField \
        name:"states" \
        hidden:false \
        type:#block \
        block:particleSystemStatesBlock, \
    tagField \
        name:"particleStates" \
        hidden:false \
        type:#block \
        block:particleSystemParticlestatesBlock
)

particleSystemParticletypesBlock = tagBlock \
    name:"particleTypesBlock" \
    length:128 \
    maximum:4 \
    fields:particleSystemParticletypesFields

particleSystemFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:52, \
    tagField \
        name:"pointPhysics" \
        hidden:false \
        type:#tagReference \
        allowed:#(#point_physics), \
    tagField \
        name:"systemUpdatePhysics" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"physicsFlags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"physicsConstants" \
        hidden:false \
        type:#block \
        block:particleSystemPhysicsconstantsBlock, \
    tagField \
        name:"particleTypes" \
        hidden:false \
        type:#block \
        block:particleSystemParticletypesBlock
)

particleSystemBlock = tagBlock \
    name:"particleSystemBlock" \
    length:104 \
    maximum:1 \
    fields:particleSystemFields

particleSystemDef = tagDef \
    fourcc:1885566060 \
    supergroup:undefined \
    tagBlock:particleSystemBlock
