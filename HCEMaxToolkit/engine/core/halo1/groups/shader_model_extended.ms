-- shader_model_extended ('sose') - Ringworld extension of shader_model.
-- Reconstructed by hand from tag binaries + invader-edit field listing:
-- the full 400-byte shader_model body (including its trailing padding) is kept
-- as-is and a 284-byte extension is appended after it (block length 684).

shaderModelExtendedFields = #(
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
        count:32, \
    tagField \
        name:"detail2Function" \
        hidden:false \
        type:#enum \
        description:"controls how detail map 2 is applied to diffuse map", \
    tagField \
        name:"detail2Mask" \
        hidden:false \
        type:#enum \
        description:"controls how detail map 2 is masked", \
    tagField \
        name:"detail2MapScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1", \
    tagField \
        name:"detail2Map" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"detail2MapVScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1 (applied on top of detail map 2 scale above)", \
    tagField \
        name:"baseNormalMap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"baseNormalCoefficient" \
        hidden:false \
        type:#float \
        description:"height/visibility of the base normal map", \
    tagField \
        name:"detailNormal1Map" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"detailNormal1Coefficient" \
        hidden:false \
        type:#float, \
    tagField \
        name:"detailNormal1Scale" \
        hidden:false \
        type:#float, \
    tagField \
        name:"detailNormal1VScale" \
        hidden:false \
        type:#float, \
    tagField \
        name:"detailNormal2Map" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"detailNormal2Coefficient" \
        hidden:false \
        type:#float, \
    tagField \
        name:"detailNormal2Scale" \
        hidden:false \
        type:#float, \
    tagField \
        name:"detailNormal2VScale" \
        hidden:false \
        type:#float, \
    tagField \
        name:"specularColorMap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap) \
        description:"RGB multiplies the stock specular color; alpha can be used as exponent mask", \
    tagField \
        name:"specularColorCoefficient" \
        hidden:false \
        type:#float, \
    tagField \
        name:"specularColorExponent" \
        hidden:false \
        type:#float, \
    tagField \
        name:"specularColorFlags" \
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
        name:"specularLightingExponent" \
        hidden:false \
        type:#float \
        description:"bigger exponent means smaller highlight", \
    tagField \
        name:"specularLightingCoefficient" \
        hidden:false \
        type:#float \
        description:"brightness of the specular highlights", \
    tagField \
        name:"diffuseLightingFlags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:142
)

shaderModelExtendedBlock = tagBlock \
    name:"shaderModelExtendedBlock" \
    length:684 \
    maximum:1 \
    fields:shaderModelExtendedFields

shaderModelExtendedDef = tagDef \
    fourcc:1936683877 \
    supergroup:#shader \
    tagBlock:shaderModelExtendedBlock
