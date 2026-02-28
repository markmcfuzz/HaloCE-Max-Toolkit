weatherParticleSystemParticletypesFields = #(
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
        name:"fadeInStartDistance" \
        hidden:false \
        type:#float \
        description:"Particles begin to fade into visibility beyond this distance" \
        unit:"world units", \
    tagField \
        name:"fadeInEndDistance" \
        hidden:false \
        type:#float \
        description:"Particles become fully visible beyond this distance" \
        unit:"world units", \
    tagField \
        name:"fadeOutStartDistance" \
        hidden:false \
        type:#float \
        description:"Particles begin to fade out of visibility beyond this distance" \
        unit:"world units", \
    tagField \
        name:"fadeOutEndDistance" \
        hidden:false \
        type:#float \
        description:"Particles become fully invisible beyond this distance" \
        unit:"world units", \
    tagField \
        name:"fadeInStartHeight" \
        hidden:false \
        type:#float \
        description:"Particles begin to fade into visibility above this height" \
        unit:"world units", \
    tagField \
        name:"fadeInEndHeight" \
        hidden:false \
        type:#float \
        description:"Particles become fully visible above this height" \
        unit:"world units", \
    tagField \
        name:"fadeOutStartHeight" \
        hidden:false \
        type:#float \
        description:"Particles begin to fade out of visibility above this height" \
        unit:"world units", \
    tagField \
        name:"fadeOutEndHeight" \
        hidden:false \
        type:#float \
        description:"Particles become fully invisible above this height" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:96, \
    tagField \
        name:"particleCount" \
        hidden:false \
        type:#floatBounds \
        unit:"particles per cubic world unit", \
    tagField \
        name:"physics" \
        hidden:false \
        type:#tagReference \
        allowed:#(#point_physics), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"accelerationMagnitude" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"accelerationTurningRate" \
        hidden:false \
        type:#floatClamped, \
    tagField \
        name:"accelerationChangeRate" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"particleRadius" \
        hidden:false \
        type:#floatBounds \
        unit:"world units", \
    tagField \
        name:"animationRate" \
        hidden:false \
        type:#floatBounds \
        unit:"frames per second", \
    tagField \
        name:"rotationRate" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees per second", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"colorLowerBound" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"colorUpperBound" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:64, \
    tagField \
        name:"spriteBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"renderMode" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"renderDirectionSource" \
        hidden:false \
        type:#enum \
        description:"Render modes that depend on an direction will use this vector.", \
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
        count:20
)

weatherParticleSystemParticletypesBlock = tagBlock \
    name:"particleTypesBlock" \
    length:604 \
    maximum:8 \
    fields:weatherParticleSystemParticletypesFields

weatherParticleSystemFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"particleTypes" \
        hidden:false \
        type:#block \
        block:weatherParticleSystemParticletypesBlock
)

weatherParticleSystemBlock = tagBlock \
    name:"weatherParticleSystemBlock" \
    length:48 \
    maximum:1 \
    fields:weatherParticleSystemFields

weatherParticleSystemDef = tagDef \
    fourcc:1918986606 \
    supergroup:undefined \
    tagBlock:weatherParticleSystemBlock
