shaderTransparentMeterFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
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
        count:32, \
    tagField \
        name:"map" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"gradientMinColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"gradientMaxColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"backgroundColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"flashColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"tintColor" \
        hidden:false \
        type:#colorRGB \
        description:"modulates framebuffer color unless map alpha is zero", \
    tagField \
        name:"meterTransparency" \
        hidden:false \
        type:#floatClamped \
        description:"used only when 'tint mode-2' is set" \
        unit:"[0,1]", \
    tagField \
        name:"backgroundTransparency" \
        hidden:false \
        type:#floatClamped \
        description:"used only when 'tint mode-2' is set" \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"meterBrightnessSource" \
        hidden:false \
        type:#enum \
        description:"overall meter brightness (default is 1)", \
    tagField \
        name:"flashBrightnessSource" \
        hidden:false \
        type:#enum \
        description:"brightness of flash (default is 1)", \
    tagField \
        name:"valueSource" \
        hidden:false \
        type:#enum \
        description:"position of flash leading edge (default is 1)", \
    tagField \
        name:"gradientSource" \
        hidden:false \
        type:#enum \
        description:"high color leading edge (default is 1)", \
    tagField \
        name:"flashExtensionSource" \
        hidden:false \
        type:#enum \
        description:"position of flash extension leading edge (default is 1)", \
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
        count:32
)

shaderTransparentMeterBlock = tagBlock \
    name:"shaderTransparentMeterBlock" \
    length:220 \
    maximum:1 \
    fields:shaderTransparentMeterFields

shaderTransparentMeterDef = tagDef \
    fourcc:1936549236 \
    supergroup:#shader \
    tagBlock:shaderTransparentMeterBlock
