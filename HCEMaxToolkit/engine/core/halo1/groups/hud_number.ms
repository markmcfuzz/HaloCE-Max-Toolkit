hudNumberFields = #(
    tagField \
        name:"digitsBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"bitmapDigitWidth" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"screenDigitWidth" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"xOffset" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"yOffset" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"decimalPointWidth" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"colonWidth" \
        hidden:false \
        type:#int8, \
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
        count:76
)

hudNumberBlock = tagBlock \
    name:"hudNumberBlock" \
    length:100 \
    maximum:1 \
    fields:hudNumberFields

hudNumberDef = tagDef \
    fourcc:1752523811 \
    supergroup:undefined \
    tagBlock:hudNumberBlock
