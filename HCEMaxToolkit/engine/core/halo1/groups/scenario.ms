scenarioSkiesFields = #(
    tagField \
        name:"sky" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sky)
)

scenarioSkiesBlock = tagBlock \
    name:"skiesBlock" \
    length:16 \
    maximum:8 \
    fields:scenarioSkiesFields

scenarioChildscenariosFields = #(
    tagField \
        name:"childScenario" \
        hidden:false \
        type:#tagReference \
        allowed:#(#scenario), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16
)

scenarioChildscenariosBlock = tagBlock \
    name:"childScenariosBlock" \
    length:32 \
    maximum:16 \
    fields:scenarioChildscenariosFields

scenarioPredictedresourcesFields = #(
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

scenarioPredictedresourcesBlock = tagBlock \
    name:"predictedResourcesBlock" \
    length:8 \
    maximum:1024 \
    fields:scenarioPredictedresourcesFields

scenarioFunctionsFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"period" \
        hidden:false \
        type:#float \
        description:"this is the period for the above function (lower values make the function oscillate quickly, higher values make it oscillate slowly)" \
        unit:"seconds", \
    tagField \
        name:"scalePeriodBy" \
        hidden:false \
        type:#index \
        description:"multiply this function by the above period", \
    tagField \
        name:"function" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"scaleFunctionBy" \
        hidden:false \
        type:#index \
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
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"scaleResultBy" \
        hidden:false \
        type:#index \
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
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16
)

scenarioFunctionsBlock = tagBlock \
    name:"functionsBlock" \
    length:120 \
    maximum:32 \
    fields:scenarioFunctionsFields

scenarioCommentsFields = #(
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"comment" \
        hidden:false \
        type:#tagData
)

scenarioCommentsBlock = tagBlock \
    name:"commentsBlock" \
    length:48 \
    maximum:1024 \
    fields:scenarioCommentsFields

scenarioObjectnamesFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4
)

scenarioObjectnamesBlock = tagBlock \
    name:"objectNamesBlock" \
    length:36 \
    maximum:512 \
    fields:scenarioObjectnamesFields

scenarioSceneryFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#index, \
    tagField \
        name:"name" \
        hidden:false \
        type:#index, \
    tagField \
        name:"notPlaced" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"desiredPermutation" \
        hidden:false \
        type:#int16 \
        description:"if non-zero, will try to use model permutations with names that end in that number, e.g. 7 would pick 'body-7' and 'head-7'", \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"rotation" \
        hidden:false \
        type:#euler3d, \
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
        count:8
)

scenarioSceneryBlock = tagBlock \
    name:"sceneryBlock" \
    length:72 \
    maximum:2000 \
    fields:scenarioSceneryFields

scenarioScenerypaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#tagReference \
        allowed:#(#scenery), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

scenarioScenerypaletteBlock = tagBlock \
    name:"sceneryPaletteBlock" \
    length:48 \
    maximum:100 \
    fields:scenarioScenerypaletteFields

scenarioBipedsFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#index, \
    tagField \
        name:"name" \
        hidden:false \
        type:#index, \
    tagField \
        name:"notPlaced" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"desiredPermutation" \
        hidden:false \
        type:#int16 \
        description:"if non-zero, will try to use model permutations with names that end in that number, e.g. 7 would pick 'body-7' and 'head-7'", \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"rotation" \
        hidden:false \
        type:#euler3d, \
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
        count:8, \
    tagField \
        name:"bodyVitality" \
        hidden:false \
        type:#float \
        unit:"[0,1]", \
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
        count:8, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

scenarioBipedsBlock = tagBlock \
    name:"bipedsBlock" \
    length:120 \
    maximum:128 \
    fields:scenarioBipedsFields

scenarioBipedpaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#tagReference \
        allowed:#(#biped), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

scenarioBipedpaletteBlock = tagBlock \
    name:"bipedPaletteBlock" \
    length:48 \
    maximum:100 \
    fields:scenarioBipedpaletteFields

scenarioVehiclesFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#index, \
    tagField \
        name:"name" \
        hidden:false \
        type:#index, \
    tagField \
        name:"notPlaced" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"desiredPermutation" \
        hidden:false \
        type:#int16 \
        description:"if non-zero, will try to use model permutations with names that end in that number, e.g. 7 would pick 'body-7' and 'head-7'", \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"rotation" \
        hidden:false \
        type:#euler3d, \
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
        count:8, \
    tagField \
        name:"bodyVitality" \
        hidden:false \
        type:#float \
        unit:"[0,1]", \
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
        count:8, \
    tagField \
        name:"multiplayerTeamIndex" \
        hidden:false \
        type:#int8 \
        description:"on a multiplayer map, this determines which team the vehicle belongs to for custom vehicle sets.", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:1, \
    tagField \
        name:"multiplayerSpawnFlags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28
)

scenarioVehiclesBlock = tagBlock \
    name:"vehiclesBlock" \
    length:120 \
    maximum:80 \
    fields:scenarioVehiclesFields

scenarioVehiclepaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#tagReference \
        allowed:#(#vehicle), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

scenarioVehiclepaletteBlock = tagBlock \
    name:"vehiclePaletteBlock" \
    length:48 \
    maximum:100 \
    fields:scenarioVehiclepaletteFields

scenarioEquipmentFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#index, \
    tagField \
        name:"name" \
        hidden:false \
        type:#index, \
    tagField \
        name:"notPlaced" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"desiredPermutation" \
        hidden:false \
        type:#int16 \
        description:"if non-zero, will try to use model permutations with names that end in that number, e.g. 7 would pick 'body-7' and 'head-7'", \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"rotation" \
        hidden:false \
        type:#euler3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"miscFlags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4
)

scenarioEquipmentBlock = tagBlock \
    name:"equipmentBlock" \
    length:40 \
    maximum:256 \
    fields:scenarioEquipmentFields

scenarioEquipmentpaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#tagReference \
        allowed:#(#equipment), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

scenarioEquipmentpaletteBlock = tagBlock \
    name:"equipmentPaletteBlock" \
    length:48 \
    maximum:100 \
    fields:scenarioEquipmentpaletteFields

scenarioWeaponsFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#index, \
    tagField \
        name:"name" \
        hidden:false \
        type:#index, \
    tagField \
        name:"notPlaced" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"desiredPermutation" \
        hidden:false \
        type:#int16 \
        description:"if non-zero, will try to use model permutations with names that end in that number, e.g. 7 would pick 'body-7' and 'head-7'", \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"rotation" \
        hidden:false \
        type:#euler3d, \
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
        count:8, \
    tagField \
        name:"roundsLeft" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"roundsLoaded" \
        hidden:false \
        type:#int16, \
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
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12
)

scenarioWeaponsBlock = tagBlock \
    name:"weaponsBlock" \
    length:92 \
    maximum:128 \
    fields:scenarioWeaponsFields

scenarioWeaponpaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#tagReference \
        allowed:#(#weapon), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

scenarioWeaponpaletteBlock = tagBlock \
    name:"weaponPaletteBlock" \
    length:48 \
    maximum:100 \
    fields:scenarioWeaponpaletteFields

scenarioDevicegroupsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"initialValue" \
        hidden:false \
        type:#float \
        unit:"[0,1]", \
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
        count:12
)

scenarioDevicegroupsBlock = tagBlock \
    name:"deviceGroupsBlock" \
    length:52 \
    maximum:128 \
    fields:scenarioDevicegroupsFields

scenarioMachinesFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#index, \
    tagField \
        name:"name" \
        hidden:false \
        type:#index, \
    tagField \
        name:"notPlaced" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"desiredPermutation" \
        hidden:false \
        type:#int16 \
        description:"if non-zero, will try to use model permutations with names that end in that number, e.g. 7 would pick 'body-7' and 'head-7'", \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"rotation" \
        hidden:false \
        type:#euler3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"powerGroup" \
        hidden:false \
        type:#index, \
    tagField \
        name:"positionGroup" \
        hidden:false \
        type:#index, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
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
        count:12
)

scenarioMachinesBlock = tagBlock \
    name:"machinesBlock" \
    length:64 \
    maximum:400 \
    fields:scenarioMachinesFields

scenarioMachinepaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#tagReference \
        allowed:#(#device_machine), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

scenarioMachinepaletteBlock = tagBlock \
    name:"machinePaletteBlock" \
    length:48 \
    maximum:100 \
    fields:scenarioMachinepaletteFields

scenarioControlsFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#index, \
    tagField \
        name:"name" \
        hidden:false \
        type:#index, \
    tagField \
        name:"notPlaced" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"desiredPermutation" \
        hidden:false \
        type:#int16 \
        description:"if non-zero, will try to use model permutations with names that end in that number, e.g. 7 would pick 'body-7' and 'head-7'", \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"rotation" \
        hidden:false \
        type:#euler3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"powerGroup" \
        hidden:false \
        type:#index, \
    tagField \
        name:"positionGroup" \
        hidden:false \
        type:#index, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int16 \
        count:1, \
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
        count:8
)

scenarioControlsBlock = tagBlock \
    name:"controlsBlock" \
    length:64 \
    maximum:100 \
    fields:scenarioControlsFields

scenarioControlpaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#tagReference \
        allowed:#(#device_control), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

scenarioControlpaletteBlock = tagBlock \
    name:"controlPaletteBlock" \
    length:48 \
    maximum:100 \
    fields:scenarioControlpaletteFields

scenarioLightfixturesFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#index, \
    tagField \
        name:"name" \
        hidden:false \
        type:#index, \
    tagField \
        name:"notPlaced" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"desiredPermutation" \
        hidden:false \
        type:#int16 \
        description:"if non-zero, will try to use model permutations with names that end in that number, e.g. 7 would pick 'body-7' and 'head-7'", \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"rotation" \
        hidden:false \
        type:#euler3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"powerGroup" \
        hidden:false \
        type:#index, \
    tagField \
        name:"positionGroup" \
        hidden:false \
        type:#index, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"color" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"intensity" \
        hidden:false \
        type:#float, \
    tagField \
        name:"falloffAngle" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"cutoffAngle" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16
)

scenarioLightfixturesBlock = tagBlock \
    name:"lightFixturesBlock" \
    length:88 \
    maximum:500 \
    fields:scenarioLightfixturesFields

scenarioLightfixturespaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#tagReference \
        allowed:#(#device_light_fixture), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

scenarioLightfixturespaletteBlock = tagBlock \
    name:"lightFixturesPaletteBlock" \
    length:48 \
    maximum:100 \
    fields:scenarioLightfixturespaletteFields

scenarioSoundsceneryFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#index, \
    tagField \
        name:"name" \
        hidden:false \
        type:#index, \
    tagField \
        name:"notPlaced" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"desiredPermutation" \
        hidden:false \
        type:#int16 \
        description:"if non-zero, will try to use model permutations with names that end in that number, e.g. 7 would pick 'body-7' and 'head-7'", \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"rotation" \
        hidden:false \
        type:#euler3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8
)

scenarioSoundsceneryBlock = tagBlock \
    name:"soundSceneryBlock" \
    length:40 \
    maximum:256 \
    fields:scenarioSoundsceneryFields

scenarioSoundscenerypaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound_scenery), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

scenarioSoundscenerypaletteBlock = tagBlock \
    name:"soundSceneryPaletteBlock" \
    length:48 \
    maximum:100 \
    fields:scenarioSoundscenerypaletteFields

scenarioPlayerstartingprofileFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"startingHealthModifier" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
    tagField \
        name:"startingShieldModifier" \
        hidden:false \
        type:#floatClamped \
        unit:"[0,1]", \
    tagField \
        name:"primaryWeapon" \
        hidden:false \
        type:#tagReference \
        allowed:#(#weapon), \
    tagField \
        name:"roundsLoaded" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"roundsTotal" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"secondaryWeapon" \
        hidden:false \
        type:#tagReference \
        allowed:#(#weapon), \
    tagField \
        name:"roundsLoaded" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"roundsTotal" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"startingFragmentationGrenadeCount" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"startingPlasmaGrenadeCount" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"starting<unknown>GrenadeCount" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"starting<unknown>GrenadeCount" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20
)

scenarioPlayerstartingprofileBlock = tagBlock \
    name:"playerStartingProfileBlock" \
    length:104 \
    maximum:256 \
    fields:scenarioPlayerstartingprofileFields

scenarioPlayerstartinglocationsFields = #(
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"facing" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"teamIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"bspIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"type0" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"type1" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"type2" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"type3" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24
)

scenarioPlayerstartinglocationsBlock = tagBlock \
    name:"playerStartingLocationsBlock" \
    length:52 \
    maximum:256 \
    fields:scenarioPlayerstartinglocationsFields

scenarioTriggervolumesFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"" \
        hidden:false \
        type:#padding \
        size:#int32 \
        count:15, \
    tagField \
        name:"" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int32 \
        count:1
)

scenarioTriggervolumesBlock = tagBlock \
    name:"triggerVolumesBlock" \
    length:96 \
    maximum:256 \
    fields:scenarioTriggervolumesFields

scenarioRecordedanimationsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"version" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"rawAnimationData" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"unitControlDataVersion" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:1, \
    tagField \
        name:"lengthOfAnimation" \
        hidden:false \
        type:#int16 \
        unit:"ticks", \
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
        name:"recordedAnimationEventStream" \
        hidden:false \
        type:#tagData
)

scenarioRecordedanimationsBlock = tagBlock \
    name:"recordedAnimationsBlock" \
    length:64 \
    maximum:1024 \
    fields:scenarioRecordedanimationsFields

scenarioNetgameflagsFields = #(
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"facing" \
        hidden:false \
        type:#floatAngle \
        unit:"degress", \
    tagField \
        name:"type" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"teamIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"weaponGroup" \
        hidden:false \
        type:#tagReference \
        allowed:#(#item_collection), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:112
)

scenarioNetgameflagsBlock = tagBlock \
    name:"netgameFlagsBlock" \
    length:148 \
    maximum:200 \
    fields:scenarioNetgameflagsFields

scenarioNetgameequipmentFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"type0" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"type1" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"type2" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"type3" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"teamIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"spawnTime(inSeconds,0=Default)" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:48, \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"facing" \
        hidden:false \
        type:#floatAngle \
        unit:"degress", \
    tagField \
        name:"itemCollection" \
        hidden:false \
        type:#tagReference \
        allowed:#(#item_collection), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:48
)

scenarioNetgameequipmentBlock = tagBlock \
    name:"netgameEquipmentBlock" \
    length:144 \
    maximum:200 \
    fields:scenarioNetgameequipmentFields

scenarioStartingequipmentFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"type0" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"type1" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"type2" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"type3" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:48, \
    tagField \
        name:"itemCollection1" \
        hidden:false \
        type:#tagReference \
        allowed:#(#item_collection), \
    tagField \
        name:"itemCollection2" \
        hidden:false \
        type:#tagReference \
        allowed:#(#item_collection), \
    tagField \
        name:"itemCollection3" \
        hidden:false \
        type:#tagReference \
        allowed:#(#item_collection), \
    tagField \
        name:"itemCollection4" \
        hidden:false \
        type:#tagReference \
        allowed:#(#item_collection), \
    tagField \
        name:"itemCollection5" \
        hidden:false \
        type:#tagReference \
        allowed:#(#item_collection), \
    tagField \
        name:"itemCollection6" \
        hidden:false \
        type:#tagReference \
        allowed:#(#item_collection), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:48
)

scenarioStartingequipmentBlock = tagBlock \
    name:"startingEquipmentBlock" \
    length:204 \
    maximum:200 \
    fields:scenarioStartingequipmentFields

scenarioBspswitchtriggervolumesFields = #(
    tagField \
        name:"triggerVolume" \
        hidden:false \
        type:#index, \
    tagField \
        name:"source" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"destination" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2
)

scenarioBspswitchtriggervolumesBlock = tagBlock \
    name:"bspSwitchTriggerVolumesBlock" \
    length:8 \
    maximum:256 \
    fields:scenarioBspswitchtriggervolumesFields

scenarioDecalsFields = #(
    tagField \
        name:"decalType" \
        hidden:false \
        type:#index, \
    tagField \
        name:"yaw[127,127]" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"pitch[127,127]" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d
)

scenarioDecalsBlock = tagBlock \
    name:"decalsBlock" \
    length:16 \
    maximum:65536 \
    fields:scenarioDecalsFields

scenarioDecalpaletteFields = #(
    tagField \
        name:"reference" \
        hidden:false \
        type:#tagReference \
        allowed:#(#decal)
)

scenarioDecalpaletteBlock = tagBlock \
    name:"decalPaletteBlock" \
    length:16 \
    maximum:128 \
    fields:scenarioDecalpaletteFields

scenarioDetailobjectcollectionpaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#tagReference \
        allowed:#(#detail_object_collection), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

scenarioDetailobjectcollectionpaletteBlock = tagBlock \
    name:"detailObjectCollectionPaletteBlock" \
    length:48 \
    maximum:32 \
    fields:scenarioDetailobjectcollectionpaletteFields

scenarioActorpaletteFields = #(
    tagField \
        name:"reference" \
        hidden:false \
        type:#tagReference \
        allowed:#(#actor_variant)
)

scenarioActorpaletteBlock = tagBlock \
    name:"actorPaletteBlock" \
    length:16 \
    maximum:64 \
    fields:scenarioActorpaletteFields

scenarioMovepositionsFields = #(
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"facing" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"weight" \
        hidden:false \
        type:#float, \
    tagField \
        name:"time" \
        hidden:false \
        type:#floatBounds \
        unit:"seconds", \
    tagField \
        name:"animation" \
        hidden:false \
        type:#index, \
    tagField \
        name:"sequenceId" \
        hidden:false \
        type:#int8 \
        description:"identifies this move position as belonging to a sequence, only actors whose starting locations match this sequence ID can use it (zero = no sequence)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:1, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:44, \
    tagField \
        name:"surfaceIndex" \
        hidden:false \
        type:#int32
)

scenarioMovepositionsBlock = tagBlock \
    name:"movePositionsBlock" \
    length:80 \
    maximum:32 \
    fields:scenarioMovepositionsFields

scenarioStartinglocationsFields = #(
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"facing" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"sequenceId" \
        hidden:false \
        type:#int8 \
        description:"which move position sequence we can use (zero = no specific sequences)", \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int8, \
    tagField \
        name:"returnState" \
        hidden:false \
        type:#enum \
        description:"state that this actor will return to when it has nothing to do", \
    tagField \
        name:"initialState" \
        hidden:false \
        type:#enum \
        description:"state that this actor starts in", \
    tagField \
        name:"actorType" \
        hidden:false \
        type:#index, \
    tagField \
        name:"commandList" \
        hidden:false \
        type:#index
)

scenarioStartinglocationsBlock = tagBlock \
    name:"startingLocationsBlock" \
    length:28 \
    maximum:32 \
    fields:scenarioStartinglocationsFields

scenarioSquadsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"actorType" \
        hidden:false \
        type:#index, \
    tagField \
        name:"platoon" \
        hidden:false \
        type:#index, \
    tagField \
        name:"initialState" \
        hidden:false \
        type:#enum \
        description:"state that this actor starts in", \
    tagField \
        name:"returnState" \
        hidden:false \
        type:#enum \
        description:"state that this actor will return to when it has nothing to do", \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"uniqueLeaderType" \
        hidden:false \
        type:#enum \
        description:"what kind of leader this squad has (e.g. a sarge for marines) - 'normal' is based on the size of the squad, 'random' always creates a leader, or you can specify an individual type", \
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
        count:28, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"maneuverToSquad" \
        hidden:false \
        type:#index, \
    tagField \
        name:"squadDelayTime" \
        hidden:false \
        type:#float \
        unit:"seconds", \
    tagField \
        name:"attacking" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"attackingSearch" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"attackingGuard" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"defending" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"defendingSearch" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"defendingGuard" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"pursuing" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
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
        count:8, \
    tagField \
        name:"normalDiffCount" \
        hidden:false \
        type:#int16 \
        description:"initial number of actors on normal difficulty", \
    tagField \
        name:"insaneDiffCount" \
        hidden:false \
        type:#int16 \
        description:"initial number of actors on insane difficulty (hard difficulty is midway between normal and insane)", \
    tagField \
        name:"majorUpgrade" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"respawnMinActors" \
        hidden:false \
        type:#int16 \
        description:"minimum number of actors alive at once (will spawn instantly if less than this number)", \
    tagField \
        name:"respawnMaxActors" \
        hidden:false \
        type:#int16 \
        description:"maximum number of actors alive at once (never spawns above this number)", \
    tagField \
        name:"respawnTotal" \
        hidden:false \
        type:#int16 \
        description:"total number to respawn (zero = infinite)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"respawnDelay" \
        hidden:false \
        type:#floatBounds \
        description:"delay between respawning actors in this squad" \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:48, \
    tagField \
        name:"movePositions" \
        hidden:false \
        type:#block \
        block:scenarioMovepositionsBlock, \
    tagField \
        name:"startingLocations" \
        hidden:false \
        type:#block \
        block:scenarioStartinglocationsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12
)

scenarioSquadsBlock = tagBlock \
    name:"squadsBlock" \
    length:232 \
    maximum:64 \
    fields:scenarioSquadsFields

scenarioPlatoonsFields = #(
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
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"changeAttacking/defendingStateWhen" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"happensTo" \
        hidden:false \
        type:#index, \
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
        count:4, \
    tagField \
        name:"maneuverWhen" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"happensTo" \
        hidden:false \
        type:#index, \
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
        count:4, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:64, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:36
)

scenarioPlatoonsBlock = tagBlock \
    name:"platoonsBlock" \
    length:172 \
    maximum:32 \
    fields:scenarioPlatoonsFields

scenarioFiringpositionsFields = #(
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"groupIndex" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:10, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int16 \
        count:1
)

scenarioFiringpositionsBlock = tagBlock \
    name:"firingPositionsBlock" \
    length:24 \
    maximum:512 \
    fields:scenarioFiringpositionsFields

scenarioEncountersplayerstartinglocationsFields = #(
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"facing" \
        hidden:false \
        type:#floatAngle \
        unit:"degrees", \
    tagField \
        name:"teamIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"bspIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"type0" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"type1" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"type2" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"type3" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24
)

scenarioEncountersplayerstartinglocationsBlock = tagBlock \
    name:"encountersPlayerStartingLocationsBlock" \
    length:52 \
    maximum:256 \
    fields:scenarioEncountersplayerstartinglocationsFields

scenarioEncountersFields = #(
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
        name:"teamIndex" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"searchBehavior" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"manualBspIndex" \
        hidden:false \
        type:#int16 \
        description:"structure bsp index that this encounter belongs to... ignored unless 'manual bsp index' flag is checked. if this flag is not checked, the structure bsp is found automatically (may fail in areas of overlapping geometry)", \
    tagField \
        name:"respawnDelay" \
        hidden:false \
        type:#floatBounds \
        description:"delay between respawning actors in this encounter" \
        unit:"seconds", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:76, \
    tagField \
        name:"squads" \
        hidden:false \
        type:#block \
        block:scenarioSquadsBlock, \
    tagField \
        name:"platoons" \
        hidden:false \
        type:#block \
        block:scenarioPlatoonsBlock, \
    tagField \
        name:"firingPositions" \
        hidden:false \
        type:#block \
        block:scenarioFiringpositionsBlock, \
    tagField \
        name:"playerStartingLocations" \
        hidden:false \
        type:#block \
        block:scenarioEncountersplayerstartinglocationsBlock
)

scenarioEncountersBlock = tagBlock \
    name:"encountersBlock" \
    length:176 \
    maximum:128 \
    fields:scenarioEncountersFields

scenarioCommandsFields = #(
    tagField \
        name:"atomType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"atomModifier" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"parameter1" \
        hidden:false \
        type:#float, \
    tagField \
        name:"parameter2" \
        hidden:false \
        type:#float, \
    tagField \
        name:"point1" \
        hidden:false \
        type:#index, \
    tagField \
        name:"point2" \
        hidden:false \
        type:#index, \
    tagField \
        name:"animation" \
        hidden:false \
        type:#index, \
    tagField \
        name:"script" \
        hidden:false \
        type:#index, \
    tagField \
        name:"recording" \
        hidden:false \
        type:#index, \
    tagField \
        name:"command" \
        hidden:false \
        type:#index, \
    tagField \
        name:"objectName" \
        hidden:false \
        type:#index, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:6
)

scenarioCommandsBlock = tagBlock \
    name:"commandsBlock" \
    length:32 \
    maximum:64 \
    fields:scenarioCommandsFields

scenarioPointsFields = #(
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8
)

scenarioPointsBlock = tagBlock \
    name:"pointsBlock" \
    length:20 \
    maximum:64 \
    fields:scenarioPointsFields

scenarioCommandlistsFields = #(
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
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"manualBspIndex" \
        hidden:false \
        type:#int16 \
        description:"structure bsp index that this encounter belongs to... ignored unless 'manual bsp index' flag is checked. if this flag is not checked, the structure bsp is found automatically (may fail in areas of overlapping geometry)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"commands" \
        hidden:false \
        type:#block \
        block:scenarioCommandsBlock, \
    tagField \
        name:"points" \
        hidden:false \
        type:#block \
        block:scenarioPointsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24
)

scenarioCommandlistsBlock = tagBlock \
    name:"commandListsBlock" \
    length:96 \
    maximum:256 \
    fields:scenarioCommandlistsFields

scenarioAianimationreferencesFields = #(
    tagField \
        name:"animationName" \
        hidden:false \
        type:#string, \
    tagField \
        name:"animationGraph" \
        hidden:false \
        type:#tagReference \
        description:"leave this blank to use the unit's normal animation graph" \
        allowed:#(#model_animations), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12
)

scenarioAianimationreferencesBlock = tagBlock \
    name:"aiAnimationReferencesBlock" \
    length:60 \
    maximum:128 \
    fields:scenarioAianimationreferencesFields

scenarioAiscriptreferencesFields = #(
    tagField \
        name:"scriptName" \
        hidden:false \
        type:#string, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8
)

scenarioAiscriptreferencesBlock = tagBlock \
    name:"aiScriptReferencesBlock" \
    length:40 \
    maximum:128 \
    fields:scenarioAiscriptreferencesFields

scenarioAirecordingreferencesFields = #(
    tagField \
        name:"recordingName" \
        hidden:false \
        type:#string, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8
)

scenarioAirecordingreferencesBlock = tagBlock \
    name:"aiRecordingReferencesBlock" \
    length:40 \
    maximum:128 \
    fields:scenarioAirecordingreferencesFields

scenarioParticipantsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"selectionType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"actorType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"useThisObject" \
        hidden:false \
        type:#index \
        description:"if a unit with this name exists, we try to pick them to start the conversation", \
    tagField \
        name:"setNewName" \
        hidden:false \
        type:#index \
        description:"once we pick a unit, we name it this", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"encounterName" \
        hidden:false \
        type:#string, \
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
        count:12
)

scenarioParticipantsBlock = tagBlock \
    name:"participantsBlock" \
    length:84 \
    maximum:8 \
    fields:scenarioParticipantsFields

scenarioLinesFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"participant" \
        hidden:false \
        type:#index, \
    tagField \
        name:"addressee" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"addresseeParticipant" \
        hidden:false \
        type:#index \
        description:"this field is only used if the addressee type is 'participant'", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"lineDelayTime" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"variant1" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"variant2" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"variant3" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"variant4" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"variant5" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"variant6" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound)
)

scenarioLinesBlock = tagBlock \
    name:"linesBlock" \
    length:124 \
    maximum:32 \
    fields:scenarioLinesFields

scenarioAiconversationsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
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
        name:"triggerDistance" \
        hidden:false \
        type:#float \
        description:"distance the player must enter before the conversation can trigger" \
        unit:"world units", \
    tagField \
        name:"runToPlayerDist" \
        hidden:false \
        type:#float \
        description:"if the 'involves player' flag is set, when triggered the conversation's participant(s) will run to within this distance of the player" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:36, \
    tagField \
        name:"participants" \
        hidden:false \
        type:#block \
        block:scenarioParticipantsBlock, \
    tagField \
        name:"lines" \
        hidden:false \
        type:#block \
        block:scenarioLinesBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12
)

scenarioAiconversationsBlock = tagBlock \
    name:"aiConversationsBlock" \
    length:116 \
    maximum:128 \
    fields:scenarioAiconversationsFields

scenarioScriptsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"scriptType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"returnType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"rootExpressionIndex" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:52
)

scenarioScriptsBlock = tagBlock \
    name:"scriptsBlock" \
    length:92 \
    maximum:512 \
    fields:scenarioScriptsFields

scenarioGlobalsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"type" \
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
        count:4, \
    tagField \
        name:"initializationExpressionIndex" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:48
)

scenarioGlobalsBlock = tagBlock \
    name:"globalsBlock" \
    length:92 \
    maximum:128 \
    fields:scenarioGlobalsFields

scenarioReferencesFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"reference" \
        hidden:false \
        type:#tagReference \
        allowed:#(#ui_widget_definition,#ui_widget_collection,#actor,#actor_variant,#antenna,#model_animations,#biped,#bitmap,#spheroid,#continuous_damage_effect,#model_collision_geometry,#color_table,#contrail,#device_control,#decal,#device,#detail_object_collection,#effect,#lightning,#equipment,#flag,#fog,#font,#material_effects,#garbage,#glow,#grenade_hud_interface,#hud_message_text,#hud_number,#hud_globals,#item,#item_collection,#damage_effect,#lens_flare,#device_light_fixture,#light,#sound_looping,#device_machine,#globals,#meter,#light_volume,#gbxmodel,#model,#multiplayer_scenario_description,#preferences_network_game,#object,#particle,#particle_system,#physics,#placeholder,#point_physics,#projectile,#weather_particle_system,#scenario_structure_bsp,#scenery,#shader_transparent_chicago_extended,#shader_transparent_chicago,#scenario,#shader_environment,#shader_transparent_glass,#shader,#sky,#shader_transparent_meter,#sound,#sound_environment,#shader_model,#shader_transparent_generic,#shader_transparent_plasma,#sound_scenery,#string_list,#shader_transparent_water,#tag_collection,#camera_track,#dialogue,#unit_hud_interface,#unit,#unicode_string_list,#virtual_keyboard,#vehicle,#weapon,#wind,#weapon_hud_interface)
)

scenarioReferencesBlock = tagBlock \
    name:"referencesBlock" \
    length:40 \
    maximum:256 \
    fields:scenarioReferencesFields

scenarioSourcefilesFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"source" \
        hidden:false \
        type:#tagData
)

scenarioSourcefilesBlock = tagBlock \
    name:"sourceFilesBlock" \
    length:52 \
    maximum:8 \
    fields:scenarioSourcefilesFields

scenarioCutsceneflagsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"facing" \
        hidden:false \
        type:#euler2d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:36
)

scenarioCutsceneflagsBlock = tagBlock \
    name:"cutsceneFlagsBlock" \
    length:92 \
    maximum:512 \
    fields:scenarioCutsceneflagsFields

scenarioCutscenecamerapointsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"orientation" \
        hidden:false \
        type:#euler3d, \
    tagField \
        name:"fieldOfView" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:36
)

scenarioCutscenecamerapointsBlock = tagBlock \
    name:"cutsceneCameraPointsBlock" \
    length:104 \
    maximum:512 \
    fields:scenarioCutscenecamerapointsFields

scenarioCutscenetitlesFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"textBounds(onScreen)" \
        hidden:false \
        type:#rectangle, \
    tagField \
        name:"stringIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"justification" \
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
        count:4, \
    tagField \
        name:"textColor" \
        hidden:false \
        type:#color_argb_int, \
    tagField \
        name:"shadowColor" \
        hidden:false \
        type:#color_argb_int, \
    tagField \
        name:"fadeInTime[seconds]" \
        hidden:false \
        type:#float, \
    tagField \
        name:"upTime[seconds]" \
        hidden:false \
        type:#float, \
    tagField \
        name:"fadeOutTime[seconds]" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16
)

scenarioCutscenetitlesBlock = tagBlock \
    name:"cutsceneTitlesBlock" \
    length:96 \
    maximum:64 \
    fields:scenarioCutscenetitlesFields

scenarioStructurebspsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"structureBsp" \
        hidden:false \
        type:#tagReference \
        allowed:#(#scenario_structure_bsp)
)

scenarioStructurebspsBlock = tagBlock \
    name:"structureBspsBlock" \
    length:32 \
    maximum:16 \
    fields:scenarioStructurebspsFields

scenarioFields = #(
    tagField \
        name:"don'tUse" \
        hidden:false \
        type:#tagReference \
        allowed:#(#scenario_structure_bsp), \
    tagField \
        name:"won'tUse" \
        hidden:false \
        type:#tagReference \
        allowed:#(#scenario_structure_bsp), \
    tagField \
        name:"can'tUse" \
        hidden:true \
        type:#tagReference \
        description:"set me" \
        allowed:#(#sky), \
    tagField \
        name:"skies" \
        hidden:false \
        type:#block \
        block:scenarioSkiesBlock, \
    tagField \
        name:"type" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"childScenarios" \
        hidden:false \
        type:#block \
        block:scenarioChildscenariosBlock, \
    tagField \
        name:"localNorth" \
        hidden:false \
        type:#floatAngle, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:136, \
    tagField \
        name:"predictedResources" \
        hidden:false \
        type:#block \
        block:scenarioPredictedresourcesBlock, \
    tagField \
        name:"functions" \
        hidden:false \
        type:#block \
        block:scenarioFunctionsBlock, \
    tagField \
        name:"editorScenarioData" \
        hidden:false \
        type:#tagData, \
    tagField \
        name:"comments" \
        hidden:false \
        type:#block \
        block:scenarioCommentsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:224, \
    tagField \
        name:"objectNames" \
        hidden:false \
        type:#block \
        block:scenarioObjectnamesBlock, \
    tagField \
        name:"scenery" \
        hidden:false \
        type:#block \
        block:scenarioSceneryBlock, \
    tagField \
        name:"sceneryPalette" \
        hidden:false \
        type:#block \
        block:scenarioScenerypaletteBlock, \
    tagField \
        name:"bipeds" \
        hidden:false \
        type:#block \
        block:scenarioBipedsBlock, \
    tagField \
        name:"bipedPalette" \
        hidden:false \
        type:#block \
        block:scenarioBipedpaletteBlock, \
    tagField \
        name:"vehicles" \
        hidden:false \
        type:#block \
        block:scenarioVehiclesBlock, \
    tagField \
        name:"vehiclePalette" \
        hidden:false \
        type:#block \
        block:scenarioVehiclepaletteBlock, \
    tagField \
        name:"equipment" \
        hidden:false \
        type:#block \
        block:scenarioEquipmentBlock, \
    tagField \
        name:"equipmentPalette" \
        hidden:false \
        type:#block \
        block:scenarioEquipmentpaletteBlock, \
    tagField \
        name:"weapons" \
        hidden:false \
        type:#block \
        block:scenarioWeaponsBlock, \
    tagField \
        name:"weaponPalette" \
        hidden:false \
        type:#block \
        block:scenarioWeaponpaletteBlock, \
    tagField \
        name:"deviceGroups" \
        hidden:false \
        type:#block \
        block:scenarioDevicegroupsBlock, \
    tagField \
        name:"machines" \
        hidden:false \
        type:#block \
        block:scenarioMachinesBlock, \
    tagField \
        name:"machinePalette" \
        hidden:false \
        type:#block \
        block:scenarioMachinepaletteBlock, \
    tagField \
        name:"controls" \
        hidden:false \
        type:#block \
        block:scenarioControlsBlock, \
    tagField \
        name:"controlPalette" \
        hidden:false \
        type:#block \
        block:scenarioControlpaletteBlock, \
    tagField \
        name:"lightFixtures" \
        hidden:false \
        type:#block \
        block:scenarioLightfixturesBlock, \
    tagField \
        name:"lightFixturesPalette" \
        hidden:false \
        type:#block \
        block:scenarioLightfixturespaletteBlock, \
    tagField \
        name:"soundScenery" \
        hidden:false \
        type:#block \
        block:scenarioSoundsceneryBlock, \
    tagField \
        name:"soundSceneryPalette" \
        hidden:false \
        type:#block \
        block:scenarioSoundscenerypaletteBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:84, \
    tagField \
        name:"playerStartingProfile" \
        hidden:false \
        type:#block \
        block:scenarioPlayerstartingprofileBlock, \
    tagField \
        name:"playerStartingLocations" \
        hidden:false \
        type:#block \
        block:scenarioPlayerstartinglocationsBlock, \
    tagField \
        name:"triggerVolumes" \
        hidden:false \
        type:#block \
        block:scenarioTriggervolumesBlock, \
    tagField \
        name:"recordedAnimations" \
        hidden:false \
        type:#block \
        block:scenarioRecordedanimationsBlock, \
    tagField \
        name:"netgameFlags" \
        hidden:false \
        type:#block \
        block:scenarioNetgameflagsBlock, \
    tagField \
        name:"netgameEquipment" \
        hidden:false \
        type:#block \
        block:scenarioNetgameequipmentBlock, \
    tagField \
        name:"startingEquipment" \
        hidden:false \
        type:#block \
        block:scenarioStartingequipmentBlock, \
    tagField \
        name:"bspSwitchTriggerVolumes" \
        hidden:false \
        type:#block \
        block:scenarioBspswitchtriggervolumesBlock, \
    tagField \
        name:"decals" \
        hidden:false \
        type:#block \
        block:scenarioDecalsBlock, \
    tagField \
        name:"decalPalette" \
        hidden:false \
        type:#block \
        block:scenarioDecalpaletteBlock, \
    tagField \
        name:"detailObjectCollectionPalette" \
        hidden:false \
        type:#block \
        block:scenarioDetailobjectcollectionpaletteBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:84, \
    tagField \
        name:"actorPalette" \
        hidden:false \
        type:#block \
        block:scenarioActorpaletteBlock, \
    tagField \
        name:"encounters" \
        hidden:false \
        type:#block \
        block:scenarioEncountersBlock, \
    tagField \
        name:"commandLists" \
        hidden:false \
        type:#block \
        block:scenarioCommandlistsBlock, \
    tagField \
        name:"aiAnimationReferences" \
        hidden:false \
        type:#block \
        block:scenarioAianimationreferencesBlock, \
    tagField \
        name:"aiScriptReferences" \
        hidden:false \
        type:#block \
        block:scenarioAiscriptreferencesBlock, \
    tagField \
        name:"aiRecordingReferences" \
        hidden:false \
        type:#block \
        block:scenarioAirecordingreferencesBlock, \
    tagField \
        name:"aiConversations" \
        hidden:false \
        type:#block \
        block:scenarioAiconversationsBlock, \
    tagField \
        name:"scriptSyntaxData" \
        hidden:false \
        type:#tagData, \
    tagField \
        name:"scriptStringData" \
        hidden:false \
        type:#tagData, \
    tagField \
        name:"scripts" \
        hidden:false \
        type:#block \
        block:scenarioScriptsBlock, \
    tagField \
        name:"globals" \
        hidden:false \
        type:#block \
        block:scenarioGlobalsBlock, \
    tagField \
        name:"references" \
        hidden:false \
        type:#block \
        block:scenarioReferencesBlock, \
    tagField \
        name:"sourceFiles" \
        hidden:false \
        type:#block \
        block:scenarioSourcefilesBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"cutsceneFlags" \
        hidden:false \
        type:#block \
        block:scenarioCutsceneflagsBlock, \
    tagField \
        name:"cutsceneCameraPoints" \
        hidden:false \
        type:#block \
        block:scenarioCutscenecamerapointsBlock, \
    tagField \
        name:"cutsceneTitles" \
        hidden:false \
        type:#block \
        block:scenarioCutscenetitlesBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:108, \
    tagField \
        name:"customObjectNames" \
        hidden:false \
        type:#tagReference \
        allowed:#(#unicode_string_list), \
    tagField \
        name:"ingameHelpText" \
        hidden:false \
        type:#tagReference \
        allowed:#(#unicode_string_list), \
    tagField \
        name:"hudMessages" \
        hidden:false \
        type:#tagReference \
        allowed:#(#hud_message_text), \
    tagField \
        name:"structureBsps" \
        hidden:false \
        type:#block \
        block:scenarioStructurebspsBlock
)

scenarioBlock = tagBlock \
    name:"scenarioBlock" \
    length:1456 \
    maximum:1 \
    fields:scenarioFields

scenarioDef = tagDef \
    fourcc:1935896178 \
    supergroup:undefined \
    tagBlock:scenarioBlock
