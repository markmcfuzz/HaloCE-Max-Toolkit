detailObjectCollectionTypesFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"sequenceIndex" \
        hidden:false \
        type:#int8 \
        unit:"[0,15]", \
    tagField \
        name:"typeFlags" \
        hidden:false \
        type:#bitfield \
        size:#int8, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"colorOverrideFactor" \
        hidden:false \
        type:#floatClamped \
        description:"fraction of detail object color to use instead of the base map color in the environment" \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"nearFadeDistance" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"farFadeDistance" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"size" \
        hidden:false \
        type:#float \
        unit:"world units per pixel", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"minimumColor" \
        hidden:false \
        type:#colorRGB \
        unit:"[0,1]", \
    tagField \
        name:"maximumColor" \
        hidden:false \
        type:#colorRGB \
        unit:"[0,1]", \
    tagField \
        name:"ambientColor" \
        hidden:false \
        type:#color_argb_int \
        unit:"[0,255]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4
)

detailObjectCollectionTypesBlock = tagBlock \
    name:"typesBlock" \
    length:96 \
    maximum:16 \
    fields:detailObjectCollectionTypesFields

detailObjectCollectionFields = #(
    tagField \
        name:"collectionType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"globalZOffset" \
        hidden:false \
        type:#float \
        unit:"applied to all detail objects of in this collection so they don't float above the ground", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:44, \
    tagField \
        name:"spritePlate" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"types" \
        hidden:false \
        type:#block \
        block:detailObjectCollectionTypesBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:48
)

detailObjectCollectionBlock = tagBlock \
    name:"detailObjectCollectionBlock" \
    length:128 \
    maximum:1 \
    fields:detailObjectCollectionFields

detailObjectCollectionDef = tagDef \
    fourcc:1685021283 \
    supergroup:undefined \
    tagBlock:detailObjectCollectionBlock
