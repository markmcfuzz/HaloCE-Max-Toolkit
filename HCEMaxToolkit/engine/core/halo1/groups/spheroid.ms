spheroidFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4
)

spheroidBlock = tagBlock \
    name:"spheroidBlock" \
    length:4 \
    maximum:1 \
    fields:spheroidFields

spheroidDef = tagDef \
    fourcc:1651470189 \
    supergroup:undefined \
    tagBlock:spheroidBlock
