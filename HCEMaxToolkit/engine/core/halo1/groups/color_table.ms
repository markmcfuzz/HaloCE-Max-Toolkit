colorTableColorsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"color" \
        hidden:false \
        type:#colorARGB
)

colorTableColorsBlock = tagBlock \
    name:"colorsBlock" \
    length:48 \
    maximum:512 \
    fields:colorTableColorsFields

colorTableFields = #(
    tagField \
        name:"colors" \
        hidden:false \
        type:#block \
        block:colorTableColorsBlock
)

colorTableBlock = tagBlock \
    name:"colorTableBlock" \
    length:12 \
    maximum:1 \
    fields:colorTableFields

colorTableDef = tagDef \
    fourcc:1668246639 \
    supergroup:undefined \
    tagBlock:colorTableBlock
