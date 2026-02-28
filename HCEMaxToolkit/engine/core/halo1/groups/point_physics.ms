pointPhysicsFields = #(
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
        count:28, \
    tagField \
        name:"density" \
        hidden:false \
        type:#float \
        unit:"g/mL", \
    tagField \
        name:"airFriction" \
        hidden:false \
        type:#float, \
    tagField \
        name:"waterFriction" \
        hidden:false \
        type:#float, \
    tagField \
        name:"surfaceFriction" \
        hidden:false \
        type:#float \
        description:"when hitting the ground or interior, percentage of velocity lost in one collision", \
    tagField \
        name:"elasticity" \
        hidden:false \
        type:#float \
        description:"0.0 is inelastic collisions (no bounce) 1.0 is perfectly elastic (reflected velocity equals incoming velocity)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12
)

pointPhysicsBlock = tagBlock \
    name:"pointPhysicsBlock" \
    length:64 \
    maximum:1 \
    fields:pointPhysicsFields

pointPhysicsDef = tagDef \
    fourcc:1886414969 \
    supergroup:undefined \
    tagBlock:pointPhysicsBlock
