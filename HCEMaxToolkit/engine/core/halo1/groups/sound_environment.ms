soundEnvironmentFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"priority" \
        hidden:false \
        type:#int16 \
        description:"when multiple listeners are in different sound environments in split screen, the combined environment will be the one with the highest priority.", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"roomIntensity" \
        hidden:false \
        type:#floatClamped \
        description:"intensity of the room effect", \
    tagField \
        name:"roomIntensityHf" \
        hidden:false \
        type:#floatClamped \
        description:"intensity of the room effect above the reference high frequency", \
    tagField \
        name:"roomRolloff(0To10)" \
        hidden:false \
        type:#float \
        description:"how quickly the room effect rolls off, from 0.0 to 10.0", \
    tagField \
        name:"decayTime(1To20)" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"decayHfRatio(1To2)" \
        hidden:false \
        type:#float, \
    tagField \
        name:"reflectionsIntensity" \
        hidden:false \
        type:#floatClamped, \
    tagField \
        name:"reflectionsDelay(0To3)" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"reverbIntensity" \
        hidden:false \
        type:#floatClamped, \
    tagField \
        name:"reverbDelay(0To1)" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"diffusion" \
        hidden:false \
        type:#float, \
    tagField \
        name:"density" \
        hidden:false \
        type:#float, \
    tagField \
        name:"hfReference(20To20,000)" \
        hidden:false \
        type:#float \
        description:"for hf values, what frequency defines hf, from 20 to 20,000" \
        unit:"Hz", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16
)

soundEnvironmentBlock = tagBlock \
    name:"soundEnvironmentBlock" \
    length:72 \
    maximum:1 \
    fields:soundEnvironmentFields

soundEnvironmentDef = tagDef \
    fourcc:1936614501 \
    supergroup:undefined \
    tagBlock:soundEnvironmentBlock
