preferencesNetworkGameFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"primaryColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"secondaryColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"pattern" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"bitmapIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"decal" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"bitmapIndex" \
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
        count:800
)

preferencesNetworkGameBlock = tagBlock \
    name:"preferencesNetworkGameBlock" \
    length:896 \
    maximum:1 \
    fields:preferencesNetworkGameFields

preferencesNetworkGameDef = tagDef \
    fourcc:1852272754 \
    supergroup:undefined \
    tagBlock:preferencesNetworkGameBlock
