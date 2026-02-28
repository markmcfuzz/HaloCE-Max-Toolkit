soundSceneryFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:128
)

soundSceneryBlock = tagBlock \
    name:"soundSceneryBlock" \
    length:128 \
    maximum:1 \
    fields:soundSceneryFields

soundSceneryDef = tagDef \
    fourcc:1936941925 \
    supergroup:#object \
    tagBlock:soundSceneryBlock
