shaderModelFields = #(
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
        count:12, \
    tagField \
        name:"translucency" \
        hidden:false \
        type:#floatClamped \
        description:"amount of light that can illuminate the shader from behind", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"changeColorSource" \
        hidden:false \
        type:#enum, \
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
        count:28, \
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
        name:"colorSource" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"animationFunction" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"animationPeriod" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"animationColorLowerBound" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"animationColorUpperBound" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"mapUScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1; scales all 2D maps simultaneously", \
    tagField \
        name:"mapVScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1; scales all 2D maps simultaneously", \
    tagField \
        name:"baseMap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"multipurposeMap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"detailFunction" \
        hidden:false \
        type:#enum \
        description:"controls how detail map is applied to diffuse map", \
    tagField \
        name:"detailMask" \
        hidden:false \
        type:#enum \
        description:"controls how detail map is masked", \
    tagField \
        name:"detailMapScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1", \
    tagField \
        name:"detailMap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"detailMapVScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1 (applied on top of detail map scale above)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
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
        type:#point2d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"reflectionFalloffDistance" \
        hidden:false \
        type:#float \
        description:"distance at which the reflection begins to fade out" \
        unit:"world units", \
    tagField \
        name:"reflectionCutoffDistance" \
        hidden:false \
        type:#float \
        description:"distance at which the reflection fades out entirely (0 means no cutoff)" \
        unit:"world units", \
    tagField \
        name:"perpendicularBrightness" \
        hidden:false \
        type:#floatClamped \
        description:"reflection brightness when viewed perpendicularly" \
        unit:"[0,1]", \
    tagField \
        name:"perpendicularTintColor" \
        hidden:false \
        type:#colorRGB \
        description:"reflection tint color when viewed perpendicularly", \
    tagField \
        name:"parallelBrightness" \
        hidden:false \
        type:#floatClamped \
        description:"reflection brightness when viewed at a glancing angle" \
        unit:"[0,1]", \
    tagField \
        name:"parallelTintColor" \
        hidden:false \
        type:#colorRGB \
        description:"reflection tint color when viewed at a glancing angle", \
    tagField \
        name:"reflectionCubeMap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
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
        count:32
)

shaderModelBlock = tagBlock \
    name:"shaderModelBlock" \
    length:400 \
    maximum:1 \
    fields:shaderModelFields

shaderModelDef = tagDef \
    fourcc:1936683887 \
    supergroup:#shader \
    tagBlock:shaderModelBlock
