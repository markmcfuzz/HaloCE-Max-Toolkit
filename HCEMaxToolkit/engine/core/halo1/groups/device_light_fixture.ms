deviceLightFixtureFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:64
)

deviceLightFixtureBlock = tagBlock \
    name:"deviceLightFixtureBlock" \
    length:64 \
    maximum:1 \
    fields:deviceLightFixtureFields

deviceLightFixtureDef = tagDef \
    fourcc:1818846825 \
    supergroup:#device \
    tagBlock:deviceLightFixtureBlock
