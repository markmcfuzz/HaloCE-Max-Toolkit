shaderTransparentChicagoExtendedExtralayersFields = #(
    tagField \
        name:"shader" \
        hidden:false \
        type:#tagReference \
        allowed:#(#shader)
)

shaderTransparentChicagoExtendedExtralayersBlock = tagBlock \
    name:"extraLayersBlock" \
    length:16 \
    maximum:4 \
    fields:shaderTransparentChicagoExtendedExtralayersFields

shaderTransparentChicagoExtendedNum4stagemapsFields = #(
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
        count:40, \
    tagField \
        name:"colorFunction" \
        hidden:false \
        type:#enum \
        description:"ignored for last map", \
    tagField \
        name:"alphaFunction" \
        hidden:false \
        type:#enum \
        description:"ignored for last map", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:36, \
    tagField \
        name:"mapUScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1", \
    tagField \
        name:"mapVScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1", \
    tagField \
        name:"mapUOffset" \
        hidden:false \
        type:#float, \
    tagField \
        name:"mapVOffset" \
        hidden:false \
        type:#float, \
    tagField \
        name:"mapRotation" \
        hidden:false \
        type:#float \
        unit:"degrees", \
    tagField \
        name:"mipmapBias" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
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
        count:40, \
    tagField \
        name:"uAnimationSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"uAnimationFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"uAnimationPeriod" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"seconds", \
    tagField \
        name:"uAnimationPhase" \
        hidden:false \
        type:#float, \
    tagField \
        name:"uAnimationScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"repeats", \
    tagField \
        name:"vAnimationSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"vAnimationFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"vAnimationPeriod" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"seconds", \
    tagField \
        name:"vAnimationPhase" \
        hidden:false \
        type:#float, \
    tagField \
        name:"vAnimationScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"repeats", \
    tagField \
        name:"rotationAnimationSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"rotationAnimationFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"rotationAnimationPeriod" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"seconds", \
    tagField \
        name:"rotationAnimationPhase" \
        hidden:false \
        type:#float, \
    tagField \
        name:"rotationAnimationScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 360" \
        unit:"degrees", \
    tagField \
        name:"rotationAnimationCenter" \
        hidden:false \
        type:#point2d
)

shaderTransparentChicagoExtendedNum4stagemapsBlock = tagBlock \
    name:"num4StageMapsBlock" \
    length:220 \
    maximum:4 \
    fields:shaderTransparentChicagoExtendedNum4stagemapsFields

shaderTransparentChicagoExtendedNum2stagemapsFields = #(
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
        count:40, \
    tagField \
        name:"colorFunction" \
        hidden:false \
        type:#enum \
        description:"ignored for last map", \
    tagField \
        name:"alphaFunction" \
        hidden:false \
        type:#enum \
        description:"ignored for last map", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:36, \
    tagField \
        name:"mapUScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1", \
    tagField \
        name:"mapVScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1", \
    tagField \
        name:"mapUOffset" \
        hidden:false \
        type:#float, \
    tagField \
        name:"mapVOffset" \
        hidden:false \
        type:#float, \
    tagField \
        name:"mapRotation" \
        hidden:false \
        type:#float \
        unit:"degrees", \
    tagField \
        name:"mipmapBias" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
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
        count:40, \
    tagField \
        name:"uAnimationSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"uAnimationFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"uAnimationPeriod" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"seconds", \
    tagField \
        name:"uAnimationPhase" \
        hidden:false \
        type:#float, \
    tagField \
        name:"uAnimationScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"repeats", \
    tagField \
        name:"vAnimationSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"vAnimationFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"vAnimationPeriod" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"seconds", \
    tagField \
        name:"vAnimationPhase" \
        hidden:false \
        type:#float, \
    tagField \
        name:"vAnimationScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"repeats", \
    tagField \
        name:"rotationAnimationSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"rotationAnimationFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"rotationAnimationPeriod" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"seconds", \
    tagField \
        name:"rotationAnimationPhase" \
        hidden:false \
        type:#float, \
    tagField \
        name:"rotationAnimationScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 360" \
        unit:"degrees", \
    tagField \
        name:"rotationAnimationCenter" \
        hidden:false \
        type:#point2d
)

shaderTransparentChicagoExtendedNum2stagemapsBlock = tagBlock \
    name:"num2StageMapsBlock" \
    length:220 \
    maximum:4 \
    fields:shaderTransparentChicagoExtendedNum2stagemapsFields

shaderTransparentChicagoExtendedFields = #(
    tagField \
        name:"numericCounterLimit" \
        hidden:false \
        type:#int8 \
        unit:"[0,255]", \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int8, \
    tagField \
        name:"firstMapType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"framebufferBlendFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"framebufferFadeMode" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"framebufferFadeSource" \
        hidden:false \
        type:#enum \
        description:"fade is multiplied by this external value", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"lensFlareSpacing" \
        hidden:false \
        type:#float \
        description:"0 places a single lens flare" \
        unit:"world units", \
    tagField \
        name:"lensFlare" \
        hidden:false \
        type:#tagReference \
        allowed:#(#lens_flare), \
    tagField \
        name:"extraLayers" \
        hidden:false \
        type:#block \
        block:shaderTransparentChicagoExtendedExtralayersBlock, \
    tagField \
        name:"4StageMaps" \
        hidden:false \
        type:#block \
        block:shaderTransparentChicagoExtendedNum4stagemapsBlock, \
    tagField \
        name:"2StageMaps" \
        hidden:false \
        type:#block \
        block:shaderTransparentChicagoExtendedNum2stagemapsBlock, \
    tagField \
        name:"extraFlags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8
)

shaderTransparentChicagoExtendedBlock = tagBlock \
    name:"shaderTransparentChicagoExtendedBlock" \
    length:80 \
    maximum:1 \
    fields:shaderTransparentChicagoExtendedFields

shaderTransparentChicagoExtendedDef = tagDef \
    fourcc:1935893880 \
    supergroup:#shader \
    tagBlock:shaderTransparentChicagoExtendedBlock
