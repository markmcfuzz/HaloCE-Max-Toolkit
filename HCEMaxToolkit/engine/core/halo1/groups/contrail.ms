contrailPointstatesFields = #(
    tagField \
        name:"duration" \
        hidden:false \
        type:#floatBounds \
        description:"the time a point spends in this state" \
        unit:"seconds", \
    tagField \
        name:"transitionDuration" \
        hidden:false \
        type:#floatBounds \
        description:"the time a point takes to transition to the next state" \
        unit:"seconds", \
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
        count:32, \
    tagField \
        name:"width" \
        hidden:false \
        type:#float \
        description:"contrail width at this point" \
        unit:"world units", \
    tagField \
        name:"colorLowerBound" \
        hidden:false \
        type:#colorARGB \
        description:"contrail color at this point", \
    tagField \
        name:"colorUpperBound" \
        hidden:false \
        type:#colorARGB \
        description:"contrail color at this point", \
    tagField \
        name:"scaleFlags" \
        hidden:false \
        type:#bitfield \
        description:"these flags determine which fields are scaled by the contrail density" \
        size:#int32
)

contrailPointstatesBlock = tagBlock \
    name:"pointStatesBlock" \
    length:104 \
    maximum:16 \
    fields:contrailPointstatesFields

contrailFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"scaleFlags" \
        hidden:false \
        type:#bitfield \
        description:"these flags determine which fields are scaled by the contrail density" \
        size:#int16, \
    tagField \
        name:"pointGenerationRate" \
        hidden:false \
        type:#float \
        description:"this many points are generated per second" \
        unit:"points per second", \
    tagField \
        name:"pointVelocity" \
        hidden:false \
        type:#floatBounds \
        description:"velocity added to each point's initial velocity" \
        unit:"world units per second", \
    tagField \
        name:"pointVelocityConeAngle" \
        hidden:false \
        type:#floatAngle \
        description:"initial velocity is inside the cone defined by the marker's forward vector and this angle" \
        unit:"degrees", \
    tagField \
        name:"inheritedVelocityFraction" \
        hidden:false \
        type:#floatClamped \
        description:"fraction of parent object's velocity that is inherited by contrail points.", \
    tagField \
        name:"renderType" \
        hidden:false \
        type:#enum \
        description:"this specifies how the contrail is oriented in space", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"textureRepeatsU" \
        hidden:false \
        type:#float \
        description:"texture repeats per contrail segment", \
    tagField \
        name:"textureRepeatsV" \
        hidden:false \
        type:#float \
        description:"texture repeats across contrail width", \
    tagField \
        name:"textureAnimationU" \
        hidden:false \
        type:#float \
        description:"the texture along the contrail is animated by this value" \
        unit:"repeats per second", \
    tagField \
        name:"textureAnimationV" \
        hidden:false \
        type:#float \
        description:"the texture across the contrail is animated by this value" \
        unit:"repeats per second", \
    tagField \
        name:"animationRate" \
        hidden:false \
        type:#float \
        unit:"frames per second", \
    tagField \
        name:"bitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"firstSequenceIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"sequenceCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:64, \
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
        name:"pointStates" \
        hidden:false \
        type:#block \
        block:contrailPointstatesBlock
)

contrailBlock = tagBlock \
    name:"contrailBlock" \
    length:324 \
    maximum:1 \
    fields:contrailFields

contrailDef = tagDef \
    fourcc:1668247156 \
    supergroup:undefined \
    tagBlock:contrailBlock
