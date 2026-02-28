lightFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"radius" \
        hidden:false \
        type:#float \
        description:"the radius where illumination is zero. (lens flare only if this is 0)", \
    tagField \
        name:"radiusModifer" \
        hidden:false \
        type:#floatBounds \
        description:"how the radius changes with external scale", \
    tagField \
        name:"falloffAngle" \
        hidden:false \
        type:#floatAngle \
        description:"the angle at which the light begins to fade.", \
    tagField \
        name:"cutoffAngle" \
        hidden:false \
        type:#floatAngle \
        description:"the angle at which the illumination is zero.", \
    tagField \
        name:"lensFlareOnlyRadius" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"interpolationFlags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"colorLowerBound" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"colorUpperBound" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"primaryCubeMap" \
        hidden:false \
        type:#tagReference \
        description:"used for diffuse and specular light" \
        allowed:#(#bitmap), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"textureAnimationFunction" \
        hidden:false \
        type:#enum \
        description:"a function to control texture animation", \
    tagField \
        name:"textureAnimationPeriod" \
        hidden:false \
        type:#float \
        description:"time between repeats" \
        unit:"seconds", \
    tagField \
        name:"secondaryCubeMap" \
        hidden:false \
        type:#tagReference \
        description:"used for specular light" \
        allowed:#(#bitmap), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"yawFunction" \
        hidden:false \
        type:#enum \
        description:"a function to control rotation of the gel in yaw", \
    tagField \
        name:"yawPeriod" \
        hidden:false \
        type:#float \
        description:"time between repeats" \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"rollFunction" \
        hidden:false \
        type:#enum \
        description:"a function to control rotation of the gel in roll", \
    tagField \
        name:"rollPeriod" \
        hidden:false \
        type:#float \
        description:"time between repeats" \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"pitchFunction" \
        hidden:false \
        type:#enum \
        description:"a function to control rotation of the gel in pitch", \
    tagField \
        name:"pitchPeriod" \
        hidden:false \
        type:#float \
        description:"time between repeats" \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"lensFlare" \
        hidden:false \
        type:#tagReference \
        allowed:#(#lens_flare), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"intensity" \
        hidden:false \
        type:#float, \
    tagField \
        name:"color" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"duration" \
        hidden:false \
        type:#float \
        description:"the light will last this long when created by an effect" \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"falloffFunction" \
        hidden:false \
        type:#enum \
        description:"the scale of the light will diminish over time according to this function", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:92
)

lightBlock = tagBlock \
    name:"lightBlock" \
    length:352 \
    maximum:1 \
    fields:lightFields

lightDef = tagDef \
    fourcc:1818847080 \
    supergroup:undefined \
    tagBlock:lightBlock
