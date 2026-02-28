lightVolumeFramesFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"offsetFromMarker" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"offsetExponent" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1; >1 compresses light near marker, <1 compresses light near far end", \
    tagField \
        name:"length" \
        hidden:false \
        type:#float \
        description:"0 causes light volume not to render" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"radiusHither" \
        hidden:false \
        type:#float \
        description:"radius near the marker" \
        unit:"world units", \
    tagField \
        name:"radiusYon" \
        hidden:false \
        type:#float \
        description:"radius at far end of light volume" \
        unit:"world units", \
    tagField \
        name:"radiusExponent" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1; >1 values are more teardrop-shaped, <1 values are more pill-shaped", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"tintColorHither" \
        hidden:false \
        type:#colorARGB \
        description:"tint color near the marker (alpha is brightness)", \
    tagField \
        name:"tintColorYon" \
        hidden:false \
        type:#colorARGB \
        description:"tint color at far end of light volume (alpha is brightness)", \
    tagField \
        name:"tintColorExponent" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1; affects tint color only, not brightness", \
    tagField \
        name:"brightnessExponent" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

lightVolumeFramesBlock = tagBlock \
    name:"framesBlock" \
    length:176 \
    maximum:2 \
    fields:lightVolumeFramesFields

lightVolumeFields = #(
    tagField \
        name:"attachmentMarker" \
        hidden:false \
        type:#string \
        description:"the marker name that the light volume should be attached to", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
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
        count:16, \
    tagField \
        name:"nearFadeDistance" \
        hidden:false \
        type:#float \
        description:"distance at which light volume is full brightness" \
        unit:"world units", \
    tagField \
        name:"farFadeDistance" \
        hidden:false \
        type:#float \
        description:"distance at which light volume is zero brightness" \
        unit:"world units", \
    tagField \
        name:"perpendicularBrightnessScale" \
        hidden:false \
        type:#floatClamped \
        description:"brightness scale when viewed at a 90-degree angle" \
        unit:"[0,1]", \
    tagField \
        name:"parallelBrightnessScale" \
        hidden:false \
        type:#floatClamped \
        description:"brightness scale when viewed directly" \
        unit:"[0,1]", \
    tagField \
        name:"brightnessScaleSource" \
        hidden:false \
        type:#enum \
        description:"scales brightness based on external value", \
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
        count:20, \
    tagField \
        name:"map" \
        hidden:false \
        type:#tagReference \
        description:"NOT A SPRITE PLATE" \
        allowed:#(#bitmap), \
    tagField \
        name:"sequenceIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"count" \
        hidden:false \
        type:#int16 \
        description:"number of bitmaps to draw (0 causes light volume not to render)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:72, \
    tagField \
        name:"frameAnimationSource" \
        hidden:false \
        type:#enum \
        description:"interpolates between frames based on external value", \
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
        count:36, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:64, \
    tagField \
        name:"frames" \
        hidden:false \
        type:#block \
        block:lightVolumeFramesBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

lightVolumeBlock = tagBlock \
    name:"lightVolumeBlock" \
    length:332 \
    maximum:1 \
    fields:lightVolumeFields

lightVolumeDef = tagDef \
    fourcc:1835496242 \
    supergroup:undefined \
    tagBlock:lightVolumeBlock
