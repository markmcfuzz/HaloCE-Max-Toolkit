modelAnimationsObjectsFields = #(
    tagField \
        name:"animation" \
        hidden:false \
        type:#index, \
    tagField \
        name:"function" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"functionControls" \
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
        count:12
)

modelAnimationsObjectsBlock = tagBlock \
    name:"objectsBlock" \
    length:20 \
    maximum:4 \
    fields:modelAnimationsObjectsFields

modelAnimationsAnimationsFields = #(
    tagField \
        name:"animation" \
        hidden:false \
        type:#index
)

modelAnimationsAnimationsBlock = tagBlock \
    name:"animationsBlock" \
    length:2 \
    maximum:30 \
    fields:modelAnimationsAnimationsFields

modelAnimationsIkpointsFields = #(
    tagField \
        name:"marker" \
        hidden:false \
        type:#string \
        description:"the marker name on the object being attached", \
    tagField \
        name:"attachToMarker" \
        hidden:false \
        type:#string \
        description:"the marker name object (weapon, vehicle, etc.) the above marker is being attached to"
)

modelAnimationsIkpointsBlock = tagBlock \
    name:"ikPointsBlock" \
    length:64 \
    maximum:4 \
    fields:modelAnimationsIkpointsFields

modelAnimationsWeaponsanimationsFields = #(
    tagField \
        name:"animation" \
        hidden:false \
        type:#index
)

modelAnimationsWeaponsanimationsBlock = tagBlock \
    name:"weaponsAnimationsBlock" \
    length:2 \
    maximum:55 \
    fields:modelAnimationsWeaponsanimationsFields

modelAnimationsWeaponsikpointsFields = #(
    tagField \
        name:"marker" \
        hidden:false \
        type:#string \
        description:"the marker name on the object being attached", \
    tagField \
        name:"attachToMarker" \
        hidden:false \
        type:#string \
        description:"the marker name object (weapon, vehicle, etc.) the above marker is being attached to"
)

modelAnimationsWeaponsikpointsBlock = tagBlock \
    name:"weaponsIkPointsBlock" \
    length:64 \
    maximum:4 \
    fields:modelAnimationsWeaponsikpointsFields

modelAnimationsWeapontypesanimationsFields = #(
    tagField \
        name:"animation" \
        hidden:false \
        type:#index
)

modelAnimationsWeapontypesanimationsBlock = tagBlock \
    name:"weaponTypesAnimationsBlock" \
    length:2 \
    maximum:10 \
    fields:modelAnimationsWeapontypesanimationsFields

modelAnimationsWeapontypesFields = #(
    tagField \
        name:"label" \
        hidden:false \
        type:#string, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"animations" \
        hidden:false \
        type:#block \
        block:modelAnimationsWeapontypesanimationsBlock
)

modelAnimationsWeapontypesBlock = tagBlock \
    name:"weaponTypesBlock" \
    length:60 \
    maximum:16 \
    fields:modelAnimationsWeapontypesFields

modelAnimationsWeaponsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"gripMarker" \
        hidden:false \
        type:#string \
        description:"the marker name on the weapon to which the hand is attached (leave blank to use origin)", \
    tagField \
        name:"handMarker" \
        hidden:false \
        type:#string \
        description:"the marker name on the unit to which the weapon is attached", \
    tagField \
        name:"rightYawPerFrame" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"leftYawPerFrame" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"rightFrameCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"leftFrameCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"downPitchPerFrame" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"upPitchPerFrame" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"downPitchFrameCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"upPitchFrameCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"animations" \
        hidden:false \
        type:#block \
        block:modelAnimationsWeaponsanimationsBlock, \
    tagField \
        name:"ikPoints" \
        hidden:false \
        type:#block \
        block:modelAnimationsWeaponsikpointsBlock, \
    tagField \
        name:"weaponTypes" \
        hidden:false \
        type:#block \
        block:modelAnimationsWeapontypesBlock
)

modelAnimationsWeaponsBlock = tagBlock \
    name:"weaponsBlock" \
    length:188 \
    maximum:16 \
    fields:modelAnimationsWeaponsFields

modelAnimationsUnitsFields = #(
    tagField \
        name:"label" \
        hidden:false \
        type:#string, \
    tagField \
        name:"rightYawPerFrame" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"leftYawPerFrame" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"rightFrameCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"leftFrameCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"downPitchPerFrame" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"upPitchPerFrame" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"downPitchFrameCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"upPitchFrameCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"animations" \
        hidden:false \
        type:#block \
        block:modelAnimationsAnimationsBlock, \
    tagField \
        name:"ikPoints" \
        hidden:false \
        type:#block \
        block:modelAnimationsIkpointsBlock, \
    tagField \
        name:"weapons" \
        hidden:false \
        type:#block \
        block:modelAnimationsWeaponsBlock
)

modelAnimationsUnitsBlock = tagBlock \
    name:"unitsBlock" \
    length:100 \
    maximum:32 \
    fields:modelAnimationsUnitsFields

modelAnimationsModelanimationsweaponsanimationsFields = #(
    tagField \
        name:"animation" \
        hidden:false \
        type:#index
)

modelAnimationsModelanimationsweaponsanimationsBlock = tagBlock \
    name:"modelAnimationsWeaponsAnimationsBlock" \
    length:2 \
    maximum:11 \
    fields:modelAnimationsModelanimationsweaponsanimationsFields

modelAnimationsModelanimationsweaponsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"animations" \
        hidden:false \
        type:#block \
        block:modelAnimationsModelanimationsweaponsanimationsBlock
)

modelAnimationsModelanimationsweaponsBlock = tagBlock \
    name:"modelAnimationsWeaponsBlock" \
    length:28 \
    maximum:1 \
    fields:modelAnimationsModelanimationsweaponsFields

modelAnimationsVehiclesanimationsFields = #(
    tagField \
        name:"animation" \
        hidden:false \
        type:#index
)

modelAnimationsVehiclesanimationsBlock = tagBlock \
    name:"vehiclesAnimationsBlock" \
    length:2 \
    maximum:8 \
    fields:modelAnimationsVehiclesanimationsFields

modelAnimationsSuspensionanimationsFields = #(
    tagField \
        name:"massPointIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"animation" \
        hidden:false \
        type:#index, \
    tagField \
        name:"fullExtensionGroundDepth" \
        hidden:false \
        type:#float, \
    tagField \
        name:"fullCompressionGroundDepth" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8
)

modelAnimationsSuspensionanimationsBlock = tagBlock \
    name:"suspensionAnimationsBlock" \
    length:20 \
    maximum:8 \
    fields:modelAnimationsSuspensionanimationsFields

modelAnimationsVehiclesFields = #(
    tagField \
        name:"rightYawPerFrame" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"leftYawPerFrame" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"rightFrameCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"leftFrameCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"downPitchPerFrame" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"upPitchPerFrame" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"downPitchFrameCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"upPitchFrameCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:68, \
    tagField \
        name:"animations" \
        hidden:false \
        type:#block \
        block:modelAnimationsVehiclesanimationsBlock, \
    tagField \
        name:"suspensionAnimations" \
        hidden:false \
        type:#block \
        block:modelAnimationsSuspensionanimationsBlock
)

modelAnimationsVehiclesBlock = tagBlock \
    name:"vehiclesBlock" \
    length:116 \
    maximum:1 \
    fields:modelAnimationsVehiclesFields

modelAnimationsDevicesanimationsFields = #(
    tagField \
        name:"animation" \
        hidden:false \
        type:#index
)

modelAnimationsDevicesanimationsBlock = tagBlock \
    name:"devicesAnimationsBlock" \
    length:2 \
    maximum:2 \
    fields:modelAnimationsDevicesanimationsFields

modelAnimationsDevicesFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:84, \
    tagField \
        name:"animations" \
        hidden:false \
        type:#block \
        block:modelAnimationsDevicesanimationsBlock
)

modelAnimationsDevicesBlock = tagBlock \
    name:"devicesBlock" \
    length:96 \
    maximum:1 \
    fields:modelAnimationsDevicesFields

modelAnimationsUnitdamageFields = #(
    tagField \
        name:"animation" \
        hidden:false \
        type:#index
)

modelAnimationsUnitdamageBlock = tagBlock \
    name:"unitDamageBlock" \
    length:2 \
    maximum:176 \
    fields:modelAnimationsUnitdamageFields

modelAnimationsFirstpersonweaponsanimationsFields = #(
    tagField \
        name:"animation" \
        hidden:false \
        type:#index
)

modelAnimationsFirstpersonweaponsanimationsBlock = tagBlock \
    name:"firstPersonWeaponsAnimationsBlock" \
    length:2 \
    maximum:28 \
    fields:modelAnimationsFirstpersonweaponsanimationsFields

modelAnimationsFirstpersonweaponsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"animations" \
        hidden:false \
        type:#block \
        block:modelAnimationsFirstpersonweaponsanimationsBlock
)

modelAnimationsFirstpersonweaponsBlock = tagBlock \
    name:"firstPersonWeaponsBlock" \
    length:28 \
    maximum:1 \
    fields:modelAnimationsFirstpersonweaponsFields

modelAnimationsSoundreferencesFields = #(
    tagField \
        name:"sound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4
)

modelAnimationsSoundreferencesBlock = tagBlock \
    name:"soundReferencesBlock" \
    length:20 \
    maximum:257 \
    fields:modelAnimationsSoundreferencesFields

modelAnimationsNodesFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"nextSiblingNodeIndex" \
        hidden:false \
        type:#index, \
    tagField \
        name:"firstChildNodeIndex" \
        hidden:false \
        type:#index, \
    tagField \
        name:"parentNodeIndex" \
        hidden:false \
        type:#index, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"nodeJointFlags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"baseVector" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"vectorRange" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4
)

modelAnimationsNodesBlock = tagBlock \
    name:"nodesBlock" \
    length:64 \
    maximum:64 \
    fields:modelAnimationsNodesFields

modelAnimationsModelanimationsanimationsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"type" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"frameCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"frameSize" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"frameInfoType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"nodeListChecksum" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"nodeCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"loopFrameIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"weight" \
        hidden:false \
        type:#floatClamped, \
    tagField \
        name:"keyFrameIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"secondKeyFrameIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"nextAnimation" \
        hidden:false \
        type:#index, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"sound" \
        hidden:false \
        type:#index, \
    tagField \
        name:"soundFrameIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"leftFootFrameIndex" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"rightFootFrameIndex" \
        hidden:false \
        type:#int8, \
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
        count:4, \
    tagField \
        name:"frameInfo" \
        hidden:false \
        type:#tagData, \
    tagField \
        name:"nodeTransFlagData" \
        hidden:false \
        type:#int32 \
        count:2, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"nodeRotationFlagData" \
        hidden:false \
        type:#int32 \
        count:2, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"nodeScaleFlagData" \
        hidden:false \
        type:#int32 \
        count:2, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"offsetToCompressedData" \
        hidden:false \
        type:#int32 \
        unit:"bytes", \
    tagField \
        name:"defaultData" \
        hidden:false \
        type:#tagData, \
    tagField \
        name:"frameData" \
        hidden:false \
        type:#tagData
)

modelAnimationsModelanimationsanimationsBlock = tagBlock \
    name:"modelAnimationsAnimationsBlock" \
    length:180 \
    maximum:256 \
    fields:modelAnimationsModelanimationsanimationsFields

modelAnimationsFields = #(
    tagField \
        name:"objects" \
        hidden:false \
        type:#block \
        block:modelAnimationsObjectsBlock, \
    tagField \
        name:"units" \
        hidden:false \
        type:#block \
        block:modelAnimationsUnitsBlock, \
    tagField \
        name:"weapons" \
        hidden:false \
        type:#block \
        block:modelAnimationsModelanimationsweaponsBlock, \
    tagField \
        name:"vehicles" \
        hidden:false \
        type:#block \
        block:modelAnimationsVehiclesBlock, \
    tagField \
        name:"devices" \
        hidden:false \
        type:#block \
        block:modelAnimationsDevicesBlock, \
    tagField \
        name:"unitDamage" \
        hidden:false \
        type:#block \
        block:modelAnimationsUnitdamageBlock, \
    tagField \
        name:"firstPersonWeapons" \
        hidden:false \
        type:#block \
        block:modelAnimationsFirstpersonweaponsBlock, \
    tagField \
        name:"soundReferences" \
        hidden:false \
        type:#block \
        block:modelAnimationsSoundreferencesBlock, \
    tagField \
        name:"limpBodyNodeRadius" \
        hidden:false \
        type:#float \
        description:"0 uses 0.04 default", \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"nodes" \
        hidden:false \
        type:#block \
        block:modelAnimationsNodesBlock, \
    tagField \
        name:"animations" \
        hidden:false \
        type:#block \
        block:modelAnimationsModelanimationsanimationsBlock
)

modelAnimationsBlock = tagBlock \
    name:"modelAnimationsBlock" \
    length:128 \
    maximum:1 \
    fields:modelAnimationsFields

modelAnimationsDef = tagDef \
    fourcc:1634628722 \
    supergroup:undefined \
    tagBlock:modelAnimationsBlock
