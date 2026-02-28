placeholderFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:128
)

placeholderBlock = tagBlock \
    name:"placeholderBlock" \
    length:128 \
    maximum:1 \
    fields:placeholderFields

placeholderDef = tagDef \
    fourcc:1886151011 \
    supergroup:#object \
    tagBlock:placeholderBlock
