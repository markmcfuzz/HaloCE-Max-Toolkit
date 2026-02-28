soundPermutationsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string \
        description:"name of the file from which this sample was imported", \
    tagField \
        name:"skipFraction" \
        hidden:false \
        type:#floatClamped \
        description:"fraction of requests to play this permutation that are ignored (a different permutation is selected.)", \
    tagField \
        name:"gain" \
        hidden:false \
        type:#floatClamped \
        description:"fraction of recorded volume to play at.", \
    tagField \
        name:"compression" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"nextPermutationIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20, \
    tagField \
        name:"samples" \
        hidden:false \
        type:#tagData \
        description:"sampled sound data", \
    tagField \
        name:"mouthData" \
        hidden:false \
        type:#tagData, \
    tagField \
        name:"subtitleData" \
        hidden:false \
        type:#tagData
)

soundPermutationsBlock = tagBlock \
    name:"permutationsBlock" \
    length:124 \
    maximum:256 \
    fields:soundPermutationsFields

soundPitchrangesFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string \
        description:"the name of the imported pitch range directory", \
    tagField \
        name:"naturalPitch" \
        hidden:false \
        type:#float \
        description:"the apparent pitch when these samples are played at their recorded pitch.", \
    tagField \
        name:"bendBounds" \
        hidden:false \
        type:#floatBounds \
        description:"the range of pitches that will be represented using this sample. this should always contain the natural pitch.", \
    tagField \
        name:"actualPermutationCount" \
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
        count:12, \
    tagField \
        name:"permutations" \
        hidden:false \
        type:#block \
        description:"permutations represent equivalent variations of this sound." \
        block:soundPermutationsBlock
)

soundPitchrangesBlock = tagBlock \
    name:"pitchRangesBlock" \
    length:72 \
    maximum:8 \
    fields:soundPitchrangesFields

soundFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"class" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"sampleRate" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"minimumDistance" \
        hidden:false \
        type:#float \
        description:"the distance below which this sound no longer gets louder" \
        unit:"world units", \
    tagField \
        name:"maximumDistance" \
        hidden:false \
        type:#float \
        description:"the distance beyond which this sound is no longer audible" \
        unit:"world units", \
    tagField \
        name:"skipFraction" \
        hidden:false \
        type:#floatClamped \
        description:"fraction of requests to play this sound that will be ignored (0 means always play.)", \
    tagField \
        name:"randomPitchBounds" \
        hidden:false \
        type:#floatBounds \
        description:"the sound's pitch will be randomly selected and will be in this range. (1.0 is the recorded pitch.)", \
    tagField \
        name:"innerConeAngle" \
        hidden:false \
        type:#floatAngle \
        description:"within the cone defined by this angle and the sound's direction, the sound plays with a gain of 1.0." \
        unit:"degrees", \
    tagField \
        name:"outerConeAngle" \
        hidden:false \
        type:#floatAngle \
        description:"outside the cone defined by this angle and the sound's direction, the sound plays with a gain of OUTER CONE GAIN. (0 means the sound does not attenuate with direction.)" \
        unit:"degrees", \
    tagField \
        name:"outerConeGain" \
        hidden:false \
        type:#floatClamped \
        description:"the gain to use when the sound is directed away from the listener", \
    tagField \
        name:"gainModifier" \
        hidden:false \
        type:#float, \
    tagField \
        name:"maximumBendPerSecond" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"skipFractionModifier" \
        hidden:false \
        type:#float, \
    tagField \
        name:"gainModifier" \
        hidden:false \
        type:#float, \
    tagField \
        name:"pitchModifier" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"skipFractionModifier" \
        hidden:false \
        type:#float, \
    tagField \
        name:"gainModifier" \
        hidden:false \
        type:#float, \
    tagField \
        name:"pitchModifier" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"encoding" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"compression" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"promotionSound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"promotionCount" \
        hidden:false \
        type:#int16 \
        description:"when there are this many instances of the sound, promote to the new sound.", \
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
        name:"pitchRanges" \
        hidden:false \
        type:#block \
        description:"pitch ranges allow multiple samples to represent the same sound at different pitches" \
        block:soundPitchrangesBlock
)

soundBlock = tagBlock \
    name:"soundBlock" \
    length:164 \
    maximum:1 \
    fields:soundFields

soundDef = tagDef \
    fourcc:1936614433 \
    supergroup:undefined \
    tagBlock:soundBlock
