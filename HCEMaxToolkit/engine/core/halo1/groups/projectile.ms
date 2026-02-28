projectileMaterialresponsesFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"response" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"effect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"response" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"skipFraction" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
    tagField \
        name:"between" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"and" \
        hidden:false \
        type:#floatBounds \
        unit:"world units per second", \
    tagField \
        name:"effect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"scaleEffectsBy" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"angularNoise" \
        hidden:false \
        type:#floatAngle \
        description:"the angle of incidence is randomly perturbed by at most this amount to simulate irregularity." \
        unit:"degrees", \
    tagField \
        name:"velocityNoise" \
        hidden:false \
        type:#float \
        description:"the velocity is randomly perturbed by at most this amount to simulate irregularity." \
        unit:"world units per second", \
    tagField \
        name:"detonationEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"initialFriction" \
        hidden:false \
        type:#float \
        description:"the fraction of the projectile's velocity lost on penetration", \
    tagField \
        name:"maximumDistance" \
        hidden:false \
        type:#float \
        description:"the maximum distance the projectile can travel through on object of this material", \
    tagField \
        name:"parallelFriction" \
        hidden:false \
        type:#float \
        description:"the fraction of the projectile's velocity parallel to the surface lost on impact", \
    tagField \
        name:"perpendicularFriction" \
        hidden:false \
        type:#float \
        description:"the fraction of the projectile's velocity perpendicular to the surface lost on impact"
)

projectileMaterialresponsesBlock = tagBlock \
    name:"materialResponsesBlock" \
    length:160 \
    maximum:33 \
    fields:projectileMaterialresponsesFields

projectileFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"detonationTimerStarts" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"impactNoise" \
        hidden:false \
        type:#enum, \
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
        name:"superDetonation" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"aiPerceptionRadius" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"collisionRadius" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"armingTime" \
        hidden:false \
        type:#float \
        description:"won't detonate before this time elapses" \
        unit:"seconds", \
    tagField \
        name:"dangerRadius" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"effect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"timer" \
        hidden:false \
        type:#floatBounds \
        description:"detonation countdown (zero is untimed)" \
        unit:"seconds", \
    tagField \
        name:"minimumVelocity" \
        hidden:false \
        type:#float \
        description:"detonates when slowed below this velocity" \
        unit:"world units per second", \
    tagField \
        name:"maximumRange" \
        hidden:false \
        type:#float \
        description:"detonates after travelling this distance" \
        unit:"world units", \
    tagField \
        name:"airGravityScale" \
        hidden:false \
        type:#float \
        description:"the proportion of normal gravity applied to the projectile when in air.", \
    tagField \
        name:"airDamageRange" \
        hidden:false \
        type:#floatBounds \
        description:"the range over which damage is scaled when the projectile is in air." \
        unit:"world units", \
    tagField \
        name:"waterGravityScale" \
        hidden:false \
        type:#float \
        description:"the proportion of normal gravity applied to the projectile when in water.", \
    tagField \
        name:"waterDamageRange" \
        hidden:false \
        type:#floatBounds \
        description:"the range over which damage is scaled when the projectile is in water." \
        unit:"world units", \
    tagField \
        name:"initialVelocity" \
        hidden:false \
        type:#float \
        description:"bullet's velocity when inflicting maximum damage" \
        unit:"world units per second", \
    tagField \
        name:"finalVelocity" \
        hidden:false \
        type:#float \
        description:"bullet's velocity when inflicting minimum damage" \
        unit:"world units per second", \
    tagField \
        name:"guidedAngularVelocity" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees per second", \
    tagField \
        name:"detonationNoise" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"detonationStarted" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"flybySound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"attachedDetonationDamage" \
        hidden:false \
        type:#tagReference \
        allowed:#(#damage_effect), \
    tagField \
        name:"impactDamage" \
        hidden:false \
        type:#tagReference \
        allowed:#(#damage_effect), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"materialResponses" \
        hidden:false \
        type:#block \
        block:projectileMaterialresponsesBlock
)

projectileBlock = tagBlock \
    name:"projectileBlock" \
    length:208 \
    maximum:1 \
    fields:projectileFields

projectileDef = tagDef \
    fourcc:1886547818 \
    supergroup:#object \
    tagBlock:projectileBlock
