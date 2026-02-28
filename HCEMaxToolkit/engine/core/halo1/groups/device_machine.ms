deviceMachineFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"doorOpenTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:80, \
    tagField \
        name:"collisionResponse" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"elevatorNode" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:52, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4
)

deviceMachineBlock = tagBlock \
    name:"deviceMachineBlock" \
    length:148 \
    maximum:1 \
    fields:deviceMachineFields

deviceMachineDef = tagDef \
    fourcc:1835098984 \
    supergroup:#device \
    tagBlock:deviceMachineBlock
