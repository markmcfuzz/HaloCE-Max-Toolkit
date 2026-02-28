physicsInertialmatrixandinverseFields = #(
    tagField \
        name:"yyZzXyZx" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"xyZzXxYz" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"zxYzXxYy" \
        hidden:false \
        type:#vector3d
)

physicsInertialmatrixandinverseBlock = tagBlock \
    name:"inertialMatrixAndInverseBlock" \
    length:36 \
    maximum:2 \
    fields:physicsInertialmatrixandinverseFields

physicsPoweredmasspointsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"antigravStrength" \
        hidden:false \
        type:#float, \
    tagField \
        name:"antigravOffset" \
        hidden:false \
        type:#float, \
    tagField \
        name:"antigravHeight" \
        hidden:false \
        type:#float, \
    tagField \
        name:"antigravDampFraction" \
        hidden:false \
        type:#float, \
    tagField \
        name:"antigravNormalK1" \
        hidden:false \
        type:#float, \
    tagField \
        name:"antigravNormalK0" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:68
)

physicsPoweredmasspointsBlock = tagBlock \
    name:"poweredMassPointsBlock" \
    length:128 \
    maximum:32 \
    fields:physicsPoweredmasspointsFields

physicsMasspointsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"poweredMassPoint" \
        hidden:false \
        type:#index, \
    tagField \
        name:"modelNode" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"relativeMass" \
        hidden:false \
        type:#float, \
    tagField \
        name:"mass" \
        hidden:false \
        type:#float, \
    tagField \
        name:"relativeDensity" \
        hidden:false \
        type:#float, \
    tagField \
        name:"density" \
        hidden:false \
        type:#float, \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"forward" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"up" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"frictionType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"frictionParallelScale" \
        hidden:false \
        type:#float, \
    tagField \
        name:"frictionPerpendicularScale" \
        hidden:false \
        type:#float, \
    tagField \
        name:"radius" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20
)

physicsMasspointsBlock = tagBlock \
    name:"massPointsBlock" \
    length:128 \
    maximum:32 \
    fields:physicsMasspointsFields

physicsFields = #(
    tagField \
        name:"radius" \
        hidden:false \
        type:#float \
        description:"positive uses old inferior physics, negative uses new improved physics", \
    tagField \
        name:"momentScale" \
        hidden:false \
        type:#floatClamped, \
    tagField \
        name:"mass" \
        hidden:false \
        type:#float, \
    tagField \
        name:"centerOfMass" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"density" \
        hidden:false \
        type:#float, \
    tagField \
        name:"gravityScale" \
        hidden:false \
        type:#float, \
    tagField \
        name:"groundFriction" \
        hidden:false \
        type:#float, \
    tagField \
        name:"groundDepth" \
        hidden:false \
        type:#float, \
    tagField \
        name:"groundDampFraction" \
        hidden:false \
        type:#floatClamped, \
    tagField \
        name:"groundNormalK1" \
        hidden:false \
        type:#float, \
    tagField \
        name:"groundNormalK0" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"waterFriction" \
        hidden:false \
        type:#float, \
    tagField \
        name:"waterDepth" \
        hidden:false \
        type:#float, \
    tagField \
        name:"waterDensity" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"airFriction" \
        hidden:false \
        type:#floatClamped, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"xxMoment" \
        hidden:false \
        type:#float, \
    tagField \
        name:"yyMoment" \
        hidden:false \
        type:#float, \
    tagField \
        name:"zzMoment" \
        hidden:false \
        type:#float, \
    tagField \
        name:"inertialMatrixAndInverse" \
        hidden:false \
        type:#block \
        block:physicsInertialmatrixandinverseBlock, \
    tagField \
        name:"poweredMassPoints" \
        hidden:false \
        type:#block \
        block:physicsPoweredmasspointsBlock, \
    tagField \
        name:"massPoints" \
        hidden:false \
        type:#block \
        block:physicsMasspointsBlock
)

physicsBlock = tagBlock \
    name:"physicsBlock" \
    length:128 \
    maximum:1 \
    fields:physicsFields

physicsDef = tagDef \
    fourcc:1885895027 \
    supergroup:undefined \
    tagBlock:physicsBlock
