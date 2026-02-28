objectAttachmentsFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#tagReference \
        allowed:#(#light,#light_volume,#contrail,#particle_system,#effect,#sound_looping), \
    tagField \
        name:"marker" \
        hidden:false \
        type:#string, \
    tagField \
        name:"primaryScale" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"secondaryScale" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"changeColor" \
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
        count:16
)

objectAttachmentsBlock = tagBlock \
    name:"attachmentsBlock" \
    length:72 \
    maximum:8 \
    fields:objectAttachmentsFields

objectWidgetsFields = #(
    tagField \
        name:"reference" \
        hidden:false \
        type:#tagReference \
        allowed:#(#flag,#antenna,#glow,#light_volume,#lightning), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16
)

objectWidgetsBlock = tagBlock \
    name:"widgetsBlock" \
    length:32 \
    maximum:4 \
    fields:objectWidgetsFields

objectFunctionsFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"period" \
        hidden:false \
        type:#float \
        description:"this is the period for the above function (lower values make the function oscillate quickly, higher values make it oscillate slowly)" \
        unit:"seconds", \
    tagField \
        name:"scalePeriodBy" \
        hidden:false \
        type:#enum \
        description:"multiply this function by the above period", \
    tagField \
        name:"function" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"scaleFunctionBy" \
        hidden:false \
        type:#enum \
        description:"multiply this function by the result of the above function", \
    tagField \
        name:"wobbleFunction" \
        hidden:false \
        type:#enum \
        description:"the curve used for the wobble", \
    tagField \
        name:"wobblePeriod" \
        hidden:false \
        type:#float \
        description:"the length of time it takes for the magnitude of this function to complete a wobble" \
        unit:"seconds", \
    tagField \
        name:"wobbleMagnitude" \
        hidden:false \
        type:#float \
        description:"the amount of random wobble in the magnitude" \
        unit:"percent", \
    tagField \
        name:"squareWaveThreshold" \
        hidden:false \
        type:#floatClamped \
        description:"if non-zero, all values above the square wave threshold are snapped to 1.0, and all values below it are snapped to 0.0 to create a square wave.", \
    tagField \
        name:"stepCount" \
        hidden:false \
        type:#int16 \
        description:"the number of discrete values to snap to (e.g., a step count of 5 would snap the function to 0.00,0.25,0.50,0.75 or 1.00)", \
    tagField \
        name:"mapTo" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"sawtoothCount" \
        hidden:false \
        type:#int16 \
        description:"the number of times this function should repeat (e.g., a sawtooth count of 5 would give the function a value of 1.0 at each of 0.25,0.50,0.75 as well as at 1.0", \
    tagField \
        name:"add" \
        hidden:false \
        type:#enum \
        description:"add this function to the final result of all of the above math", \
    tagField \
        name:"scaleResultBy" \
        hidden:false \
        type:#enum \
        description:"multiply this function (from a weapon, vehicle, etc.) final result of all of the above math", \
    tagField \
        name:"boundsMode" \
        hidden:false \
        type:#enum \
        description:"controls how the bounds, below, are used", \
    tagField \
        name:"bounds" \
        hidden:false \
        type:#floatClamped, \
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
        count:2, \
    tagField \
        name:"turnOffWith" \
        hidden:false \
        type:#index \
        description:"if the specified function is off, so is this function", \
    tagField \
        name:"scaleBy" \
        hidden:false \
        type:#float \
        description:"applied before clip, ignored if zero", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:252, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"usage" \
        hidden:false \
        type:#string
)

objectFunctionsBlock = tagBlock \
    name:"functionsBlock" \
    length:360 \
    maximum:4 \
    fields:objectFunctionsFields

objectPermutationsFields = #(
    tagField \
        name:"weight" \
        hidden:false \
        type:#float, \
    tagField \
        name:"colorLowerBound" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"colorUpperBound" \
        hidden:false \
        type:#colorRGB
)

objectPermutationsBlock = tagBlock \
    name:"permutationsBlock" \
    length:28 \
    maximum:8 \
    fields:objectPermutationsFields

objectChangecolorsFields = #(
    tagField \
        name:"darkenBy" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"scaleBy" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"scaleFlags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"colorLowerBound" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"colorUpperBound" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"permutations" \
        hidden:false \
        type:#block \
        block:objectPermutationsBlock
)

objectChangecolorsBlock = tagBlock \
    name:"changeColorsBlock" \
    length:44 \
    maximum:4 \
    fields:objectChangecolorsFields

objectPredictedresourcesFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"resourceIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"tagIndex" \
        hidden:false \
        type:#int32
)

objectPredictedresourcesBlock = tagBlock \
    name:"predictedResourcesBlock" \
    length:8 \
    maximum:1024 \
    fields:objectPredictedresourcesFields

objectFields = #(
    tagField \
        name:"objectType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"boundingRadius" \
        hidden:false \
        type:#float \
        unit:"world units", \
    tagField \
        name:"boundingOffset" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"originOffset" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"accelerationScale" \
        hidden:false \
        type:#float \
        description:"marine 1.0, grunt 1.4, elite 0.9, hunter 0.5, etc." \
        unit:"[0,+inf]", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
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
        count:40, \
    tagField \
        name:"collisionModel" \
        hidden:false \
        type:#tagReference \
        allowed:#(#model_collision_geometry), \
    tagField \
        name:"physics" \
        hidden:false \
        type:#tagReference \
        allowed:#(#physics), \
    tagField \
        name:"modifierShader" \
        hidden:false \
        type:#tagReference \
        allowed:#(#shader), \
    tagField \
        name:"creationEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:84, \
    tagField \
        name:"renderBoundingRadius" \
        hidden:false \
        type:#float \
        description:"if set, this radius is used to determine if the object is visible. set it for the pelican." \
        unit:"world units", \
    tagField \
        name:"aIn" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"bIn" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"cIn" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"dIn" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:44, \
    tagField \
        name:"hudTextMessageIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"forcedShaderPermuationIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"attachments" \
        hidden:false \
        type:#block \
        block:objectAttachmentsBlock, \
    tagField \
        name:"widgets" \
        hidden:false \
        type:#block \
        block:objectWidgetsBlock, \
    tagField \
        name:"functions" \
        hidden:false \
        type:#block \
        block:objectFunctionsBlock, \
    tagField \
        name:"changeColors" \
        hidden:false \
        type:#block \
        block:objectChangecolorsBlock, \
    tagField \
        name:"predictedResources" \
        hidden:false \
        type:#block \
        block:objectPredictedresourcesBlock
)

objectBlock = tagBlock \
    name:"objectBlock" \
    length:380 \
    maximum:1 \
    fields:objectFields

objectDef = tagDef \
    fourcc:1868720741 \
    supergroup:undefined \
    tagBlock:objectBlock
