shaderTransparentGenericExtralayersFields = #(
    tagField \
        name:"shader" \
        hidden:false \
        type:#tagReference \
        allowed:#(#shader)
)

shaderTransparentGenericExtralayersBlock = tagBlock \
    name:"extraLayersBlock" \
    length:16 \
    maximum:4 \
    fields:shaderTransparentGenericExtralayersFields

shaderTransparentGenericMapsFields = #(
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

shaderTransparentGenericMapsBlock = tagBlock \
    name:"mapsBlock" \
    length:100 \
    maximum:4 \
    fields:shaderTransparentGenericMapsFields

shaderTransparentGenericStagesFields = #(
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
        name:"color0Source" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"color0AnimationFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"color0AnimationPeriod" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"seconds", \
    tagField \
        name:"color0AnimationLowerBound" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"color0AnimationUpperBound" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"color1" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"inputA" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputAMapping" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputB" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputBMapping" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputC" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputCMapping" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputD" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputDMapping" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"outputAb" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"outputAbFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"outputCd" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"outputCdFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"outputAbCdMux/sum" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"outputMapping" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputA" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputAMapping" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputB" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputBMapping" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputC" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputCMapping" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputD" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"inputDMapping" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"outputAb" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"outputCd" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"outputAbCdMux/sum" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"outputMapping" \
        hidden:false \
        type:#enum
)

shaderTransparentGenericStagesBlock = tagBlock \
    name:"stagesBlock" \
    length:112 \
    maximum:7 \
    fields:shaderTransparentGenericStagesFields

shaderTransparentGenericFields = #(
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
        block:shaderTransparentGenericExtralayersBlock, \
    tagField \
        name:"maps" \
        hidden:false \
        type:#block \
        block:shaderTransparentGenericMapsBlock, \
    tagField \
        name:"stages" \
        hidden:false \
        type:#block \
        block:shaderTransparentGenericStagesBlock
)

shaderTransparentGenericBlock = tagBlock \
    name:"shaderTransparentGenericBlock" \
    length:68 \
    maximum:1 \
    fields:shaderTransparentGenericFields

shaderTransparentGenericDef = tagDef \
    fourcc:1936684146 \
    supergroup:#shader \
    tagBlock:shaderTransparentGenericBlock
