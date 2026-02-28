antennaVerticesFields = #(
    tagField \
        name:"springStrengthCoefficient" \
        hidden:false \
        type:#floatClamped \
        description:"strength of the spring (larger values make the spring stronger)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"angles" \
        hidden:false \
        type:#euler2d \
        description:"direction toward next vertex", \
    tagField \
        name:"length" \
        hidden:false \
        type:#float \
        description:"distance between this vertex and the next" \
        unit:"world units", \
    tagField \
        name:"sequenceIndex" \
        hidden:false \
        type:#int16 \
        description:"bitmap group sequence index for this vertex's texture", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"color" \
        hidden:false \
        type:#colorARGB \
        description:"color at this vertex", \
    tagField \
        name:"lodColor" \
        hidden:false \
        type:#colorARGB \
        description:"color at this vertex for the low-LOD line primitives", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:40, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12
)

antennaVerticesBlock = tagBlock \
    name:"verticesBlock" \
    length:128 \
    maximum:20 \
    fields:antennaVerticesFields

antennaFields = #(
    tagField \
        name:"attachmentMarkerName" \
        hidden:false \
        type:#string \
        description:"the marker name where the antenna should be attached", \
    tagField \
        name:"bitmaps" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"physics" \
        hidden:false \
        type:#tagReference \
        allowed:#(#point_physics), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:80, \
    tagField \
        name:"springStrengthCoefficient" \
        hidden:false \
        type:#floatClamped \
        description:"strength of the spring (larger values make the spring stronger)", \
    tagField \
        name:"falloffPixels" \
        hidden:false \
        type:#float, \
    tagField \
        name:"cutoffPixels" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:40, \
    tagField \
        name:"vertices" \
        hidden:false \
        type:#block \
        block:antennaVerticesBlock
)

antennaBlock = tagBlock \
    name:"antennaBlock" \
    length:208 \
    maximum:1 \
    fields:antennaFields

antennaDef = tagDef \
    fourcc:1634628641 \
    supergroup:undefined \
    tagBlock:antennaBlock
