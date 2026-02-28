cameraTrackControlpointsFields = #(
    tagField \
        name:"position" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"orientation" \
        hidden:false \
        type:#quaternion, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

cameraTrackControlpointsBlock = tagBlock \
    name:"controlPointsBlock" \
    length:60 \
    maximum:16 \
    fields:cameraTrackControlpointsFields

cameraTrackFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"controlPoints" \
        hidden:false \
        type:#block \
        block:cameraTrackControlpointsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

cameraTrackBlock = tagBlock \
    name:"cameraTrackBlock" \
    length:48 \
    maximum:1 \
    fields:cameraTrackFields

cameraTrackDef = tagDef \
    fourcc:1953653099 \
    supergroup:undefined \
    tagBlock:cameraTrackBlock
