materialEffectsMaterialsFields = #(
    tagField \
        name:"effect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"sound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16
)

materialEffectsMaterialsBlock = tagBlock \
    name:"materialsBlock" \
    length:48 \
    maximum:33 \
    fields:materialEffectsMaterialsFields

materialEffectsEffectsFields = #(
    tagField \
        name:"materials" \
        hidden:false \
        type:#block \
        block:materialEffectsMaterialsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16
)

materialEffectsEffectsBlock = tagBlock \
    name:"effectsBlock" \
    length:28 \
    maximum:13 \
    fields:materialEffectsEffectsFields

materialEffectsFields = #(
    tagField \
        name:"effects" \
        hidden:false \
        type:#block \
        block:materialEffectsEffectsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:128
)

materialEffectsBlock = tagBlock \
    name:"materialEffectsBlock" \
    length:140 \
    maximum:1 \
    fields:materialEffectsFields

materialEffectsDef = tagDef \
    fourcc:1718579060 \
    supergroup:undefined \
    tagBlock:materialEffectsBlock
