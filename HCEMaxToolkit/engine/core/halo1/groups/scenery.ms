sceneryFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:128
)

sceneryBlock = tagBlock \
    name:"sceneryBlock" \
    length:128 \
    maximum:1 \
    fields:sceneryFields

sceneryDef = tagDef \
    fourcc:1935893870 \
    supergroup:#object \
    tagBlock:sceneryBlock
