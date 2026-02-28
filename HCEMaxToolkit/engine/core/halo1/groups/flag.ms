flagAttachmentpointsFields = #(
    tagField \
        name:"heightToNextAttachment" \
        hidden:false \
        type:#int16 \
        description:"flag vertices between this attachment point and the next" \
        unit:"vertices", \
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
        count:16, \
    tagField \
        name:"markerName" \
        hidden:false \
        type:#string
)

flagAttachmentpointsBlock = tagBlock \
    name:"attachmentPointsBlock" \
    length:52 \
    maximum:5 \
    fields:flagAttachmentpointsFields

flagFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"trailingEdgeShape" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"trailingEdgeShapeOffset" \
        hidden:false \
        type:#int16 \
        description:"zero places the shape exactly on the trailing edge, positive numbers push it off the edge" \
        unit:"vertices", \
    tagField \
        name:"attachedEdgeShape" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"width" \
        hidden:false \
        type:#int16 \
        description:"flag size from attached to trailing edge" \
        unit:"vertices", \
    tagField \
        name:"height" \
        hidden:false \
        type:#int16 \
        description:"flag size along the direction of attachment (should be odd)" \
        unit:"vertices", \
    tagField \
        name:"cellWidth" \
        hidden:false \
        type:#float \
        description:"width of the cell between each pair of vertices" \
        unit:"world units", \
    tagField \
        name:"cellHeight" \
        hidden:false \
        type:#float \
        description:"height of the cell between each pair of vertices" \
        unit:"world units", \
    tagField \
        name:"redFlagShader" \
        hidden:false \
        type:#tagReference \
        allowed:#(#shader), \
    tagField \
        name:"physics" \
        hidden:false \
        type:#tagReference \
        allowed:#(#point_physics), \
    tagField \
        name:"windNoise" \
        hidden:false \
        type:#float \
        unit:"world units per second", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"blueFlagShader" \
        hidden:false \
        type:#tagReference \
        allowed:#(#shader), \
    tagField \
        name:"attachmentPoints" \
        hidden:false \
        type:#block \
        description:"attachment points determine where the flag is attached" \
        block:flagAttachmentpointsBlock
)

flagBlock = tagBlock \
    name:"flagBlock" \
    length:96 \
    maximum:1 \
    fields:flagFields

flagDef = tagDef \
    fourcc:1718378855 \
    supergroup:undefined \
    tagBlock:flagBlock
