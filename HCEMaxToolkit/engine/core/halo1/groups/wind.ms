windFields = #(
    tagField \
        name:"velocity" \
        hidden:false \
        type:#floatBounds \
        description:"the wind magnitude in the weather region scales the wind between these bounds" \
        unit:"world units", \
    tagField \
        name:"variationArea" \
        hidden:false \
        type:#euler2d \
        description:"the wind direction varies inside a box defined by these angles on either side of the direction from the weather region.", \
    tagField \
        name:"localVariationWeight" \
        hidden:false \
        type:#float, \
    tagField \
        name:"localVariationRate" \
        hidden:false \
        type:#float, \
    tagField \
        name:"damping" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:36
)

windBlock = tagBlock \
    name:"windBlock" \
    length:64 \
    maximum:1 \
    fields:windFields

windDef = tagDef \
    fourcc:2003398244 \
    supergroup:undefined \
    tagBlock:windBlock
