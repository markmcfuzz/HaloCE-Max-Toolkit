lightningMarkersFields = #(
    tagField \
        name:"attachmentMarker" \
        hidden:false \
        type:#string, \
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
        name:"octavesToNextMarker" \
        hidden:false \
        type:#int16, \
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
        count:76, \
    tagField \
        name:"randomPositionBounds" \
        hidden:false \
        type:#vector3d \
        unit:"world units", \
    tagField \
        name:"randomJitter" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"thickness" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"tint" \
        hidden:false \
        type:#colorARGB \
        description:"alpha is brightness", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:76
)

lightningMarkersBlock = tagBlock \
    name:"markersBlock" \
    length:228 \
    maximum:16 \
    fields:lightningMarkersFields

lightningShaderFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:40, \
    tagField \
        name:"shaderFlags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"framebufferBlendFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"framebufferFadeMode" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"mapFlags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28, \
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
        count:2, \
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
        count:56, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28
)

lightningShaderBlock = tagBlock \
    name:"shaderBlock" \
    length:180 \
    maximum:1 \
    fields:lightningShaderFields

lightningFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"count" \
        hidden:false \
        type:#int16 \
        description:"number of overlapping lightning effects to render; 0 defaults to 1", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"nearFadeDistance" \
        hidden:false \
        type:#float \
        description:"distance at which lightning is at full brightness" \
        unit:"world units", \
    tagField \
        name:"farFadeDistance" \
        hidden:false \
        type:#float \
        description:"distance at which lightning is at zero brightness" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"jitterScaleSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"thicknessScaleSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"tintModulationSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"brightnessScaleSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"bitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:84, \
    tagField \
        name:"markers" \
        hidden:false \
        type:#block \
        block:lightningMarkersBlock, \
    tagField \
        name:"shader" \
        hidden:false \
        type:#block \
        block:lightningShaderBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:88
)

lightningBlock = tagBlock \
    name:"lightningBlock" \
    length:264 \
    maximum:1 \
    fields:lightningFields

lightningDef = tagDef \
    fourcc:1701602659 \
    supergroup:undefined \
    tagBlock:lightningBlock
