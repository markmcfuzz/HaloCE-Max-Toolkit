soundLoopingTracksFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"gain" \
        hidden:false \
        type:#floatClamped, \
    tagField \
        name:"fadeInDuration" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"fadeOutDuration" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"start" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"loop" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"end" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"alternateLoop" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"alternateEnd" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int16 \
        count:1
)

soundLoopingTracksBlock = tagBlock \
    name:"tracksBlock" \
    length:160 \
    maximum:4 \
    fields:soundLoopingTracksFields

soundLoopingDetailsoundsFields = #(
    tagField \
        name:"sound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"randomPeriodBounds" \
        hidden:false \
        type:#floatBounds \
        description:"the time between successive playings of this sound will be randomly selected from this range." \
        unit:"seconds", \
    tagField \
        name:"gain" \
        hidden:false \
        type:#floatClamped, \
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
        count:48, \
    tagField \
        name:"yawBounds" \
        hidden:false \
        type:#floatAngle \
        description:"the sound's position along the horizon will be randomly selected from this range." \
        unit:"degrees", \
    tagField \
        name:"pitchBounds" \
        hidden:false \
        type:#floatAngle \
        description:"the sound's position above (positive values) or below (negative values) the horizon will be randomly selected from this range." \
        unit:"degrees", \
    tagField \
        name:"distanceBounds" \
        hidden:false \
        type:#floatBounds \
        description:"the sound's distance (from its spatialized looping sound or from the listener if the looping sound is stereo) will be randomly selected from this range." \
        unit:"world units"
)

soundLoopingDetailsoundsBlock = tagBlock \
    name:"detailSoundsBlock" \
    length:104 \
    maximum:32 \
    fields:soundLoopingDetailsoundsFields

soundLoopingFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"detailSoundPeriod" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"detailSoundPeriod" \
        hidden:false \
        type:#float, \
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
        count:16, \
    tagField \
        name:"continuousDamageEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#continuous_damage_effect), \
    tagField \
        name:"tracks" \
        hidden:false \
        type:#block \
        description:"tracks play in parallel and loop continuously for the duration of the looping sound." \
        block:soundLoopingTracksBlock, \
    tagField \
        name:"detailSounds" \
        hidden:false \
        type:#block \
        description:"detail sounds play at random throughout the duration of the looping sound." \
        block:soundLoopingDetailsoundsBlock
)

soundLoopingBlock = tagBlock \
    name:"soundLoopingBlock" \
    length:84 \
    maximum:1 \
    fields:soundLoopingFields

soundLoopingDef = tagDef \
    fourcc:1819504228 \
    supergroup:undefined \
    tagBlock:soundLoopingBlock
