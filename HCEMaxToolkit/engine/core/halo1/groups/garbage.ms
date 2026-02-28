garbageFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:168
)

garbageBlock = tagBlock \
    name:"garbageBlock" \
    length:168 \
    maximum:1 \
    fields:garbageFields

garbageDef = tagDef \
    fourcc:1734439522 \
    supergroup:#item \
    tagBlock:garbageBlock
