lensFlareReflectionsFields = #(
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
        name:"bitmapIndex" \
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
        count:20, \
    tagField \
        name:"position" \
        hidden:false \
        type:#float \
        description:"0 is on top of light, 1 is opposite light, 0.5 is the center of the screen, etc." \
        unit:"along flare axis", \
    tagField \
        name:"rotationOffset" \
        hidden:false \
        type:#float \
        unit:"degrees", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"radius" \
        hidden:false \
        type:#floatBounds \
        description:"interpolated by light scale" \
        unit:"world units", \
    tagField \
        name:"radiusScaledBy" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"brightness" \
        hidden:false \
        type:#floatClamped \
        description:"interpolated by light scale" \
        unit:"[0,1]", \
    tagField \
        name:"brightnessScaledBy" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"tintColor" \
        hidden:false \
        type:#colorARGB \
        description:"if a=r=g=b=0 use light color instead; alpha blends between modulation and tinting", \
    tagField \
        name:"colorLowerBound" \
        hidden:false \
        type:#colorARGB \
        description:"if a=r=g=b=0, default to a=r=g=b=1", \
    tagField \
        name:"colorUpperBound" \
        hidden:false \
        type:#colorARGB \
        description:"if a=r=g=b=0, default to a=r=g=b=1", \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"animationFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"animationPeriod" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1" \
        unit:"seconds", \
    tagField \
        name:"animationPhase" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4
)

lensFlareReflectionsBlock = tagBlock \
    name:"reflectionsBlock" \
    length:128 \
    maximum:32 \
    fields:lensFlareReflectionsFields

lensFlareFields = #(
    tagField \
        name:"falloffAngle" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"cutoffAngle" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"occlusionRadius" \
        hidden:false \
        type:#float \
        description:"radius of the square used to test occlusion" \
        unit:"world units", \
    tagField \
        name:"occlusionOffsetDirection" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"nearFadeDistance" \
        hidden:false \
        type:#float \
        description:"distance at which the lens flare brightness is maximum" \
        unit:"world units", \
    tagField \
        name:"farFadeDistance" \
        hidden:false \
        type:#float \
        description:"distance at which the lens flare brightness is minimum; set to zero to disable distance fading" \
        unit:"world units", \
    tagField \
        name:"bitmap" \
        hidden:false \
        type:#tagReference \
        description:"used by reflections" \
        allowed:#(#bitmap), \
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
        count:76, \
    tagField \
        name:"rotationFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"rotationFunctionScale" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"horizontalScale" \
        hidden:false \
        type:#float \
        description:"amount to stretch the corona along the horizontal axis; 0 defaults to 1", \
    tagField \
        name:"verticalScale" \
        hidden:false \
        type:#float \
        description:"amount to stretch the corona along the vertical axis; 0 defaults to 1", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28, \
    tagField \
        name:"reflections" \
        hidden:false \
        type:#block \
        block:lensFlareReflectionsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

lensFlareBlock = tagBlock \
    name:"lensFlareBlock" \
    length:240 \
    maximum:1 \
    fields:lensFlareFields

lensFlareDef = tagDef \
    fourcc:1818586739 \
    supergroup:undefined \
    tagBlock:lensFlareBlock
