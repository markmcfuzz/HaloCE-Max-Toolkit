modelCollisionGeometryMaterialsFields = #(
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
        name:"materialType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"shieldLeakPercentage" \
        hidden:false \
        type:#floatClamped \
        description:"the percent [0,1] damage the shield always leaks through to the body", \
    tagField \
        name:"shieldDamageMultiplier" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"bodyDamageMultiplier" \
        hidden:false \
        type:#float \
        description:"multiplier to body damage against this material (1.0 is normal)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8
)

modelCollisionGeometryMaterialsBlock = tagBlock \
    name:"materialsBlock" \
    length:72 \
    maximum:32 \
    fields:modelCollisionGeometryMaterialsFields

modelCollisionGeometryPermutationsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string
)

modelCollisionGeometryPermutationsBlock = tagBlock \
    name:"permutationsBlock" \
    length:32 \
    maximum:32 \
    fields:modelCollisionGeometryPermutationsFields

modelCollisionGeometryRegionsFields = #(
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
        count:4, \
    tagField \
        name:"damageThreshold" \
        hidden:false \
        type:#float \
        description:"if this region takes this amount of damage, it will be destroyed", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"destroyedEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"permutations" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryPermutationsBlock
)

modelCollisionGeometryRegionsBlock = tagBlock \
    name:"regionsBlock" \
    length:84 \
    maximum:8 \
    fields:modelCollisionGeometryRegionsFields

modelCollisionGeometryModifiersFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:52
)

modelCollisionGeometryModifiersBlock = tagBlock \
    name:"modifiersBlock" \
    length:52 \
    maximum:0 \
    fields:modelCollisionGeometryModifiersFields

modelCollisionGeometryPathfindingspheresFields = #(
    tagField \
        name:"node" \
        hidden:false \
        type:#index, \
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
        name:"center" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"radius" \
        hidden:false \
        type:#float
)

modelCollisionGeometryPathfindingspheresBlock = tagBlock \
    name:"pathfindingSpheresBlock" \
    length:32 \
    maximum:32 \
    fields:modelCollisionGeometryPathfindingspheresFields

modelCollisionGeometryBsp3dnodesFields = #(
    tagField \
        name:"plane" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"backChild" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"frontChild" \
        hidden:false \
        type:#int32
)

modelCollisionGeometryBsp3dnodesBlock = tagBlock \
    name:"bsp3dNodesBlock" \
    length:12 \
    maximum:131072 \
    fields:modelCollisionGeometryBsp3dnodesFields

modelCollisionGeometryPlanesFields = #(
    tagField \
        name:"plane" \
        hidden:false \
        type:#plane3d
)

modelCollisionGeometryPlanesBlock = tagBlock \
    name:"planesBlock" \
    length:16 \
    maximum:65536 \
    fields:modelCollisionGeometryPlanesFields

modelCollisionGeometryLeavesFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"bsp2dReferenceCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"firstBsp2dReference" \
        hidden:false \
        type:#int32
)

modelCollisionGeometryLeavesBlock = tagBlock \
    name:"leavesBlock" \
    length:8 \
    maximum:65536 \
    fields:modelCollisionGeometryLeavesFields

modelCollisionGeometryBsp2dreferencesFields = #(
    tagField \
        name:"plane" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"bsp2dNode" \
        hidden:false \
        type:#int32
)

modelCollisionGeometryBsp2dreferencesBlock = tagBlock \
    name:"bsp2dReferencesBlock" \
    length:8 \
    maximum:131072 \
    fields:modelCollisionGeometryBsp2dreferencesFields

modelCollisionGeometryBsp2dnodesFields = #(
    tagField \
        name:"plane" \
        hidden:false \
        type:#plane2d, \
    tagField \
        name:"leftChild" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"rightChild" \
        hidden:false \
        type:#int32
)

modelCollisionGeometryBsp2dnodesBlock = tagBlock \
    name:"bsp2dNodesBlock" \
    length:20 \
    maximum:65535 \
    fields:modelCollisionGeometryBsp2dnodesFields

modelCollisionGeometrySurfacesFields = #(
    tagField \
        name:"plane" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"firstEdge" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int8, \
    tagField \
        name:"breakableSurface" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"material" \
        hidden:false \
        type:#int16
)

modelCollisionGeometrySurfacesBlock = tagBlock \
    name:"surfacesBlock" \
    length:12 \
    maximum:131072 \
    fields:modelCollisionGeometrySurfacesFields

modelCollisionGeometryEdgesFields = #(
    tagField \
        name:"startVertex" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"endVertex" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"forwardEdge" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"reverseEdge" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"leftSurface" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"rightSurface" \
        hidden:false \
        type:#int32
)

modelCollisionGeometryEdgesBlock = tagBlock \
    name:"edgesBlock" \
    length:24 \
    maximum:262144 \
    fields:modelCollisionGeometryEdgesFields

modelCollisionGeometryVerticesFields = #(
    tagField \
        name:"point" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"firstEdge" \
        hidden:false \
        type:#int32
)

modelCollisionGeometryVerticesBlock = tagBlock \
    name:"verticesBlock" \
    length:16 \
    maximum:131072 \
    fields:modelCollisionGeometryVerticesFields

modelCollisionGeometryBspsFields = #(
    tagField \
        name:"bsp3dNodes" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryBsp3dnodesBlock, \
    tagField \
        name:"planes" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryPlanesBlock, \
    tagField \
        name:"leaves" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryLeavesBlock, \
    tagField \
        name:"bsp2dReferences" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryBsp2dreferencesBlock, \
    tagField \
        name:"bsp2dNodes" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryBsp2dnodesBlock, \
    tagField \
        name:"surfaces" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometrySurfacesBlock, \
    tagField \
        name:"edges" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryEdgesBlock, \
    tagField \
        name:"vertices" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryVerticesBlock
)

modelCollisionGeometryBspsBlock = tagBlock \
    name:"bspsBlock" \
    length:96 \
    maximum:32 \
    fields:modelCollisionGeometryBspsFields

modelCollisionGeometryNodesFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"region" \
        hidden:false \
        type:#index, \
    tagField \
        name:"parentNode" \
        hidden:false \
        type:#index, \
    tagField \
        name:"nextSiblingNode" \
        hidden:false \
        type:#index, \
    tagField \
        name:"firstChildNode" \
        hidden:false \
        type:#index, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"bsps" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryBspsBlock
)

modelCollisionGeometryNodesBlock = tagBlock \
    name:"nodesBlock" \
    length:64 \
    maximum:64 \
    fields:modelCollisionGeometryNodesFields

modelCollisionGeometryFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"indirectDamageMaterial" \
        hidden:false \
        type:#index \
        description:"the material we use when shielding child objects or getting hit by area of effect damage", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"maximumBodyVitality" \
        hidden:false \
        type:#float \
        description:"the default initial and maximum body vitality of this object", \
    tagField \
        name:"bodySystemShock" \
        hidden:false \
        type:#float \
        description:"anything that kills us (body depleted) doing more than this amount of damage also destroys us", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28, \
    tagField \
        name:"friendlyDamageResistance" \
        hidden:false \
        type:#floatClamped \
        description:"the fraction of damage caused by friendly units ignored by this object (zero means full damage)" \
        unit:"[0,1]", \
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
        count:32, \
    tagField \
        name:"localizedDamageEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"areaDamageEffectThreshold" \
        hidden:false \
        type:#float \
        unit:"[0,1]", \
    tagField \
        name:"areaDamageEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"bodyDamagedThreshold" \
        hidden:false \
        type:#float \
        description:"when passing this vitality the 'body damaged' effect, below, is created", \
    tagField \
        name:"bodyDamagedEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"bodyDepletedEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"bodyDestroyedThreshold" \
        hidden:false \
        type:#float \
        description:"when passing this vitality (usually negative) the object is deleted", \
    tagField \
        name:"bodyDestroyedEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"maximumShieldVitality" \
        hidden:false \
        type:#float \
        description:"the default initial and maximum shield vitality of this object", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"shieldMaterialType" \
        hidden:false \
        type:#enum \
        description:"the material type used when projectiles impact the shield (instead of the body)", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"shieldFailureFunction" \
        hidden:false \
        type:#enum \
        description:"how fast the shield begins to leak", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"shieldFailureThreshold" \
        hidden:false \
        type:#floatClamped \
        description:"when the shield begins to leak (0.5 would cause the shield to begin to fail after taking half damage)", \
    tagField \
        name:"failingShieldLeakFraction" \
        hidden:false \
        type:#floatClamped \
        description:"the maximum percent [0,1] damage a failing shield will leak to the body", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"minimumStunDamage" \
        hidden:false \
        type:#float \
        description:"the minimum damage required to stun this object's shields", \
    tagField \
        name:"stunTime" \
        hidden:false \
        type:#float \
        description:"the length of time the shields stay stunned (do not recharge) after taking damage" \
        unit:"seconds", \
    tagField \
        name:"rechargeTime" \
        hidden:false \
        type:#float \
        description:"the length of time it would take for the shields to fully recharge after being completely depleted" \
        unit:"seconds", \
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
        count:96, \
    tagField \
        name:"shieldDamagedThreshold" \
        hidden:false \
        type:#float, \
    tagField \
        name:"shieldDamagedEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"shieldDepletedEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
    tagField \
        name:"shieldRechargingEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#effect), \
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
        count:112, \
    tagField \
        name:"materials" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryMaterialsBlock, \
    tagField \
        name:"regions" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryRegionsBlock, \
    tagField \
        name:"modifiers" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryModifiersBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"x" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"y" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"z" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"pathfindingSpheres" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryPathfindingspheresBlock, \
    tagField \
        name:"nodes" \
        hidden:false \
        type:#block \
        block:modelCollisionGeometryNodesBlock
)

modelCollisionGeometryBlock = tagBlock \
    name:"modelCollisionGeometryBlock" \
    length:664 \
    maximum:1 \
    fields:modelCollisionGeometryFields

modelCollisionGeometryDef = tagDef \
    fourcc:1668246636 \
    supergroup:undefined \
    tagBlock:modelCollisionGeometryBlock
