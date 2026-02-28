skyShaderfunctionsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"globalFunctionName" \
        hidden:false \
        type:#string \
        description:"the global function that controls this shader value"
)

skyShaderfunctionsBlock = tagBlock \
    name:"shaderFunctionsBlock" \
    length:36 \
    maximum:8 \
    fields:skyShaderfunctionsFields

skyAnimationsFields = #(
    tagField \
        name:"animationIndex" \
        hidden:false \
        type:#int16 \
        description:"the index of the animation in the animation graph", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"period" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28
)

skyAnimationsBlock = tagBlock \
    name:"animationsBlock" \
    length:36 \
    maximum:8 \
    fields:skyAnimationsFields

skyLightsFields = #(
    tagField \
        name:"lensFlare" \
        hidden:false \
        type:#tagReference \
        allowed:#(#lens_flare), \
    tagField \
        name:"lensFlareMarkerName" \
        hidden:false \
        type:#string \
        description:"the lens flare for this light will be attached to the specified marker in the model", \
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
        size:#int32, \
    tagField \
        name:"color" \
        hidden:false \
        type:#colorRGB \
        description:"light color", \
    tagField \
        name:"power" \
        hidden:false \
        type:#float \
        description:"light power from 0 to infinity", \
    tagField \
        name:"testDistance" \
        hidden:false \
        type:#float \
        description:"the length of the ray for shadow testing.", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"direction" \
        hidden:false \
        type:#euler2d \
        description:"direction toward the light source in the sky.", \
    tagField \
        name:"diameter" \
        hidden:false \
        type:#floatAngle \
        description:"angular diameter of the light source in the sky."
)

skyLightsBlock = tagBlock \
    name:"lightsBlock" \
    length:116 \
    maximum:8 \
    fields:skyLightsFields

skyFields = #(
    tagField \
        name:"model" \
        hidden:false \
        type:#tagReference \
        allowed:#(#gbxmodel), \
    tagField \
        name:"animationGraph" \
        hidden:false \
        type:#tagReference \
        allowed:#(#model_animations), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"indoorAmbientRadiosityColor" \
        hidden:false \
        type:#colorRGB \
        description:"the indoor ambient light color", \
    tagField \
        name:"indoorAmbientRadiosityPower" \
        hidden:false \
        type:#float \
        description:"the indoor ambient light power from 0 to infinity", \
    tagField \
        name:"outdoorAmbientRadiosityColor" \
        hidden:false \
        type:#colorRGB \
        description:"the outdoor ambient light color", \
    tagField \
        name:"outdoorAmbientRadiosityPower" \
        hidden:false \
        type:#float \
        description:"the outdoor ambient light power from 0 to infinity", \
    tagField \
        name:"outdoorFogColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"outdoorFogMaximumDensity" \
        hidden:false \
        type:#floatClamped \
        description:"density at opaque distance - 0 defaults to 1" \
        unit:"[0,1]", \
    tagField \
        name:"outdoorFogStartDistance" \
        hidden:false \
        type:#float \
        description:"below this distance there is no fog" \
        unit:"world units", \
    tagField \
        name:"outdoorFogOpaqueDistance" \
        hidden:false \
        type:#float \
        description:"beyond this distance surfaces are completely fogged" \
        unit:"world units", \
    tagField \
        name:"indoorFogColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"indoorFogMaximumDensity" \
        hidden:false \
        type:#floatClamped \
        description:"density at opaque distance - 0 defaults to 1" \
        unit:"[0,1]", \
    tagField \
        name:"indoorFogStartDistance" \
        hidden:false \
        type:#float \
        description:"below this distance there is no fog" \
        unit:"world units", \
    tagField \
        name:"indoorFogOpaqueDistance" \
        hidden:false \
        type:#float \
        description:"beyond this distance surfaces are completely fogged" \
        unit:"world units", \
    tagField \
        name:"indoorFogScreen" \
        hidden:false \
        type:#tagReference \
        description:"used for FOG SCREEN only; not used for planar fog" \
        allowed:#(#fog), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"shaderFunctions" \
        hidden:false \
        type:#block \
        block:skyShaderfunctionsBlock, \
    tagField \
        name:"animations" \
        hidden:false \
        type:#block \
        block:skyAnimationsBlock, \
    tagField \
        name:"lights" \
        hidden:false \
        type:#block \
        block:skyLightsBlock
)

skyBlock = tagBlock \
    name:"skyBlock" \
    length:208 \
    maximum:1 \
    fields:skyFields

skyDef = tagDef \
    fourcc:1936423200 \
    supergroup:undefined \
    tagBlock:skyBlock
