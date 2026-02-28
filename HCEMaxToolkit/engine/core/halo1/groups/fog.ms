fogFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
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
        count:76, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"maximumDensity" \
        hidden:false \
        type:#floatClamped \
        description:"planar fog density is clamped to this value" \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"opaqueDistance" \
        hidden:false \
        type:#float \
        description:"the fog becomes opaque at this distance from the viewer" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"opaqueDepth" \
        hidden:false \
        type:#float \
        description:"the fog becomes opaque at this distance from its surface" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"distanceToWaterPlane" \
        hidden:false \
        type:#float \
        description:"the fog becomes water at this distance from its surface" \
        unit:"world units", \
    tagField \
        name:"color" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"layerCount" \
        hidden:false \
        type:#int16 \
        description:"0 layers disables the effect" \
        unit:"[0,4]", \
    tagField \
        name:"distanceGradient" \
        hidden:false \
        type:#floatBounds \
        unit:"world units", \
    tagField \
        name:"densityGradient" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
    tagField \
        name:"startDistanceFromFogPlane" \
        hidden:false \
        type:#float \
        description:"do NOT set this to the same value as maximum_depth" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"color" \
        hidden:false \
        type:#color_rgb_int \
        description:"0 defaults to planar fog color", \
    tagField \
        name:"rotationMultiplier" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
    tagField \
        name:"strafingMultiplier" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
    tagField \
        name:"zoomMultiplier" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"mapScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1", \
    tagField \
        name:"map" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"animationPeriod" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"windVelocity" \
        hidden:false \
        type:#floatBounds \
        unit:"world units per second", \
    tagField \
        name:"windPeriod" \
        hidden:false \
        type:#floatBounds \
        description:"0 defaults to 1" \
        unit:"seconds", \
    tagField \
        name:"windAccelerationWeight" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
    tagField \
        name:"windPerpendicularWeight" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"backgroundSound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound_looping), \
    tagField \
        name:"soundEnvironment" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound_environment), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:120
)

fogBlock = tagBlock \
    name:"fogBlock" \
    length:396 \
    maximum:1 \
    fields:fogFields

fogDef = tagDef \
    fourcc:1718576928 \
    supergroup:undefined \
    tagBlock:fogBlock
