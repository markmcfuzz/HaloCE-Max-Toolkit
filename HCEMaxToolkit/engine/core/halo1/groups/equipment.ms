equipmentFields = #(
    tagField \
        name:"powerupType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"grenadeType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"powerupTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"pickupSound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:144
)

equipmentBlock = tagBlock \
    name:"equipmentBlock" \
    length:168 \
    maximum:1 \
    fields:equipmentFields

equipmentDef = tagDef \
    fourcc:1701931376 \
    supergroup:#item \
    tagBlock:equipmentBlock
