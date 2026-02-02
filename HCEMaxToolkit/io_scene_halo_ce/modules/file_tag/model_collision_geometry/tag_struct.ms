------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

-------------------------------------------------------
-- Main model collision geometry tag structure
-------------------------------------------------------

struct collisionTag (
    header = undefined,
    flags = undefined,
    indirectDamageMaterial = 0,
	body = undefined,
	shield = undefined,
    materialsTagBlock = undefined,
    materials = #(),
    regionsTagBlock = undefined,
    regions = #(),
    modifiersTagBlock = undefined,
    modifiers = #(),
	pathfindingBox = undefined,
	pathfindingBoxX = #(0.0, 0.0),
    pathfindingBoxY = #(0.0, 0.0),
    pathfindingBoxZ = #(0.0, 0.0),
    pathfindingSpheresTagBlock = undefined,
    pathfindingSpheres = #(),
    nodesTagBlock = undefined,
    nodes = #()
)

-------------------------------------------------------
-- Return structures
-------------------------------------------------------

struct returnHeader (
    tagClass,
    checksum,
    version,
    engineId
)

struct returnFlags (
    flags,
    indirectDamageMaterial
)

struct returnBody (
    maximumBodyVitality,
    bodySystemShock,
    friendlyDamageResistance,
    localizedDamageEffect,
    areaDamageEffectThreshold,
    areaDamageEffect,
    bodyDamagedThreshold,
    bodyDamagedEffect,
    bodyDepletedEffect,
    bodyDestroyedThreshold,
    bodyDestroyedEffect
)

struct returnShield (
    maximumShieldVitality,
    shieldMaterialType,
    shieldFailureFunction,
    shieldFailureThreshold,
    shieldFailingLeakFraction,
    minimumStunDamage,
    stunTime,
    rechargeTime,
    shieldDamagedThreshold,
    shieldDamagedEffect,
    shieldDepletedEffect,
    shieldRechargingEffect
)

struct returnReflexives (
    materials,
    regions,
    modifiers,
    spheres,
    nodes,
    boxX,
    boxY,
    boxZ
)

-------------------------------------------------------
-- Data block result structures
-------------------------------------------------------

struct materialsBlockResult (
    materials,
    endOffset
)

-- Regions block result
struct regionsBlockResult (
    regions,
    endOffset
)

-- Spheres block result
struct spheresBlockResult (
    spheres,
    endOffset
)

-- Nodes block result
struct nodesBlockResult (
    nodes,
    endOffset
)

-------------------------------------------------------
-- Material structures
-------------------------------------------------------

struct returnMaterials (
    name,
    flags,
    materialType,
    shieldLeakPercentage,
    shieldDamageMultiplier,
    bodyDamageMultiplier
)

-------------------------------------------------------
-- Region structures
-------------------------------------------------------

struct returnPermutation (
    name
)

struct returnRegions (
    name,
    flags,
    damageThreshold,
    destroyedEffect,
    permutations
)

-------------------------------------------------------
-- Modifier and pathfinding structures
-------------------------------------------------------

struct returnPathfindingSpheres (
    node,
    nodeName,
    center,
    radius
)

-------------------------------------------------------
-- Node structures
-------------------------------------------------------

struct returnNodes (
    name,
    region,
    regionName,
    parentNode,
    nextSiblingNode,
    firstChildNode,
    unknown0,
    unknown1,
    bspsReflexive,
    bsps
)

-------------------------------------------------------
-- BSP geometry structures
-------------------------------------------------------

struct returnBspsReflexives (
    bsp3dNodes,
    planes,
    leaves,
    bsp2dReferences,
    bsp2dNodes,
    surfaces,
    edges,
    vertices
)

struct returnBsp3dNodes (
    plane,
    backChild,
    frontChild
)

struct returnBspsPlanes (
    i,
    j,
    k,
    d
)

struct returnBspsLeaves (
    flags,
    bsp2dReferenceCount,
    firstBsp2dReference
)

struct returnBSP2DReferences (
    plane,
    bsp2dNode
)

struct returnBsp2dNodes (
    planeI,
    planeJ,
    planeD,
    leftChild,
    rightChild
)

struct returnSurfaces (
    plane,
    firstEdge,
    flags,
    breakableSurface,
    material
)

struct returnEdges (
    startVertex,
    endVertex,
    forwardEdge,
    reverseEdge,
    leftSurface,
    rightSurface
)

struct returnVertices (
    point,
    firstEdge
)

fn shieldFailureFunctionToString funcType =
(
	case funcType of
	(
		0: "linear";
        1: "early";
        2: "very_early";
        3: "late";
        4: "very_late";
        5: "cosine";
		default: ("unknown_" + (funcType as string))
	)
)

fn materialTypeToString matType =
(
	case matType of
	(
		0: "dirt";
        1: "sand";
        2: "stone";
        3: "snow";
        4: "wood";
		5: "metal hollow";
        6: "metal thin";
        7: "metal thick";
        8: "rubber";
        9: "glass";
		10: "force field";
        11: "grunt"; 
        12: "hunter armor";
        13: "hunter skin"; 
        14: "elite";
		15: "jackal";
        16: "jackal energy shield";
        17: "engineer skin";
        18: "engineer force field";
		19: "flood combat form";
        20: "flood carrier form";
        21: "cyborg armor";
        22: "cyborg energy shield";
		23: "human armor";
        24: "human skin";
        25: "sentinel";
        26: "monitor";
        27: "plastic";
		28: "water";
        29: "leaves";
        30: "elite energy shield";
        31: "ice";
        32: "hunter shield";
		default: ("unknown_" + (matType as string))
	)
)

logger "Model Collision Geometry tag structure loaded.\n" logType:#success