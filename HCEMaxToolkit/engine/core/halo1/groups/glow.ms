glowFields = #(
    tagField \
        name:"attachmentMarker" \
        hidden:false \
        type:#string \
        description:"the marker name that the glow should be attached to", \
    tagField \
        name:"numberOfParticles" \
        hidden:false \
        type:#int16 \
        description:"the number of particles that comprise the glow system", \
    tagField \
        name:"boundaryEffect" \
        hidden:false \
        type:#enum \
        description:"particles behavior on reaching the end of an object", \
    tagField \
        name:"normalParticleDistribution" \
        hidden:false \
        type:#enum \
        description:"distribution of the normal particles about the object", \
    tagField \
        name:"trailingParticleDistribution" \
        hidden:false \
        type:#enum \
        description:"distribution of the trailing particles about the object", \
    tagField \
        name:"glowFlags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28, \
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
        count:4, \
    tagField \
        name:"attachment" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"particleRotationalVelocity" \
        hidden:false \
        type:#float \
        description:"radians per second", \
    tagField \
        name:"particleRotVelMulLow" \
        hidden:false \
        type:#float \
        description:"multiplied by overall velocity; only used if controlled by attachment", \
    tagField \
        name:"particleRotVelMulHigh" \
        hidden:false \
        type:#float \
        description:"multiplied by overall velocity; only used if controlled by attachment", \
    tagField \
        name:"attachment" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"effectRotationalVelocity" \
        hidden:false \
        type:#float \
        description:"in radians per second", \
    tagField \
        name:"effectRotVelMulLow" \
        hidden:false \
        type:#float \
        description:"multiplied by overall velocity; only used if controlled by attachment", \
    tagField \
        name:"effectRotVelMulHigh" \
        hidden:false \
        type:#float \
        description:"multiplied by overall velocity; only used if controlled by attachment", \
    tagField \
        name:"attachment" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"effectTranslationalVelocity" \
        hidden:false \
        type:#float \
        description:"in world units per second", \
    tagField \
        name:"effectTransVelMulLow" \
        hidden:false \
        type:#float \
        description:"multiplied by overall velocity; only used if controlled by attachment", \
    tagField \
        name:"effectTransVelMulHigh" \
        hidden:false \
        type:#float \
        description:"multiplied by overall velocity; only used if controlled by attachment", \
    tagField \
        name:"attachment" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"minDistanceParticleToObject" \
        hidden:false \
        type:#float \
        description:"in world units", \
    tagField \
        name:"maxDistanceParticleToObject" \
        hidden:false \
        type:#float \
        description:"in world units", \
    tagField \
        name:"distanceToObjectMulLow" \
        hidden:false \
        type:#float \
        description:"multiplied by particle distance; only used if controlled by attachment", \
    tagField \
        name:"distanceToObjectMulHigh" \
        hidden:false \
        type:#float \
        description:"multiplied by particle distance; only used if controlled by attachment", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"attachment" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"particleSizeBounds" \
        hidden:false \
        type:#floatBounds \
        description:"size of particles" \
        unit:"world units", \
    tagField \
        name:"sizeAttachmentMultiplier" \
        hidden:false \
        type:#floatBounds \
        description:"multiplied by particle size; only used if controlled by attachment", \
    tagField \
        name:"attachment" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"colorBound0" \
        hidden:false \
        type:#colorARGB \
        description:"the color of all particles will vary between color bound 0 and color bound 1", \
    tagField \
        name:"colorBound1" \
        hidden:false \
        type:#colorARGB \
        description:"the color of all particles will vary between color bound 0 and color bound 1", \
    tagField \
        name:"scaleColor0" \
        hidden:false \
        type:#colorARGB \
        description:"used to scale the particle color; only used if controlled by attachment", \
    tagField \
        name:"scaleColor1" \
        hidden:false \
        type:#colorARGB \
        description:"used to scale the particle color; only used if controlled by attachment", \
    tagField \
        name:"colorRateOfChange" \
        hidden:false \
        type:#float \
        description:"for glow effects that dynamically control particle color; sets rate of change", \
    tagField \
        name:"fadingPercentageOfGlow" \
        hidden:false \
        type:#float \
        description:"percentage of the glow that is fading at any given time", \
    tagField \
        name:"particleGenerationFreq" \
        hidden:false \
        type:#float \
        description:"frequency in Hz that trailing particles are generated" \
        unit:"Hz", \
    tagField \
        name:"lifetimeOfTrailingParticles" \
        hidden:false \
        type:#float \
        description:"seconds that a trailing particle remains in existence" \
        unit:"s", \
    tagField \
        name:"velocityOfTrailingParticles" \
        hidden:false \
        type:#float \
        unit:"wu/s", \
    tagField \
        name:"trailingParticleMinimumT" \
        hidden:false \
        type:#float, \
    tagField \
        name:"trailingParticleMaximumT" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:52, \
    tagField \
        name:"texture" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap)
)

glowBlock = tagBlock \
    name:"glowBlock" \
    length:340 \
    maximum:1 \
    fields:glowFields

glowDef = tagDef \
    fourcc:1735161633 \
    supergroup:undefined \
    tagBlock:glowBlock
