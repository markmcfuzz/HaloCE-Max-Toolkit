meterFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"stencilBitmaps" \
        hidden:false \
        type:#tagReference \
        description:"two bitmaps specifying the mask and the meter levels" \
        allowed:#(#bitmap), \
    tagField \
        name:"sourceBitmap" \
        hidden:false \
        type:#tagReference \
        description:"optional bitmap to draw into the unmasked regions of the meter (modulated by the colors below)" \
        allowed:#(#bitmap), \
    tagField \
        name:"stencilSequenceIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"sourceSequenceIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"interpolateColors" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"anchorColors" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"emptyColor" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"fullColor" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20, \
    tagField \
        name:"unmaskDistance" \
        hidden:false \
        type:#float \
        description:"fade from fully masked to fully unmasked this distance beyond full (and below empty)" \
        unit:"meter units", \
    tagField \
        name:"maskDistance" \
        hidden:false \
        type:#float \
        description:"fade from fully unmasked to fully masked this distance below full (and beyond empty)" \
        unit:"meter units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20, \
    tagField \
        name:"encodedStencil" \
        hidden:false \
        type:#tagData
)

meterBlock = tagBlock \
    name:"meterBlock" \
    length:172 \
    maximum:1 \
    fields:meterFields

meterDef = tagDef \
    fourcc:1835365490 \
    supergroup:undefined \
    tagBlock:meterBlock
