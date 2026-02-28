deviceControlFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"triggersWhen" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"callValue" \
        hidden:false \
        type:#float \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:80, \
    tagField \
        name:"on" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound,#effect), \
    tagField \
        name:"off" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound,#effect), \
    tagField \
        name:"deny" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound,#effect)
)

deviceControlBlock = tagBlock \
    name:"deviceControlBlock" \
    length:136 \
    maximum:1 \
    fields:deviceControlFields

deviceControlDef = tagDef \
    fourcc:1668575852 \
    supergroup:#device \
    tagBlock:deviceControlBlock
