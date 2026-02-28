shaderTransparentWaterRipplesFields = #(
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
        count:2, \
    tagField \
        name:"contributionFactor" \
        hidden:false \
        type:#floatClamped \
        description:"0 defaults to 1" \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"animationAngle" \
        hidden:false \
        type:#floatAngle \
        unit:"[0,360]", \
    tagField \
        name:"animationVelocity" \
        hidden:false \
        type:#float, \
    tagField \
        name:"mapOffset" \
        hidden:false \
        type:#vector2d, \
    tagField \
        name:"mapRepeats" \
        hidden:false \
        type:#int16 \
        description:"0 defaults to 1", \
    tagField \
        name:"mapIndex" \
        hidden:false \
        type:#int16 \
        description:"index into ripple maps", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16
)

shaderTransparentWaterRipplesBlock = tagBlock \
    name:"ripplesBlock" \
    length:76 \
    maximum:4 \
    fields:shaderTransparentWaterRipplesFields

shaderTransparentWaterFields = #(
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
        name:"baseMap" \
        hidden:false \
        type:#tagReference \
        description:"controls reflection brightness and background tint" \
        allowed:#(#bitmap), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"viewPerpendicularBrightness" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
    tagField \
        name:"viewPerpendicularTintColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"viewParallelBrightness" \
        hidden:false \
        type:#floatClamped \
        description:"0 defaults to 1" \
        unit:"[0,1]", \
    tagField \
        name:"viewParallelTintColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"reflectionMap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap) \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"rippleAnimationAngle" \
        hidden:false \
        type:#floatAngle \
        unit:"[0,360]", \
    tagField \
        name:"rippleAnimationVelocity" \
        hidden:false \
        type:#float, \
    tagField \
        name:"rippleScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1", \
    tagField \
        name:"rippleMaps" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"rippleMipmapLevels" \
        hidden:false \
        type:#int16 \
        description:"0 defaults to 1", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"rippleMipmapFadeFactor" \
        hidden:false \
        type:#floatClamped \
        description:"flatness of last mipmap" \
        unit:"[0,1]", \
    tagField \
        name:"rippleMipmapDetailBias" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:64, \
    tagField \
        name:"ripples" \
        hidden:false \
        type:#block \
        block:shaderTransparentWaterRipplesBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16
)

shaderTransparentWaterBlock = tagBlock \
    name:"shaderTransparentWaterBlock" \
    length:280 \
    maximum:1 \
    fields:shaderTransparentWaterFields

shaderTransparentWaterDef = tagDef \
    fourcc:1937203572 \
    supergroup:#shader \
    tagBlock:shaderTransparentWaterBlock
