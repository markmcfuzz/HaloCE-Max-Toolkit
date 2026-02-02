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
-- Physics tag structure
-------------------------------------------------------

struct physicsTag (
    header = undefined,
    tagBase = undefined,
    inertiaMatricesBlock = undefined,
    inertiaMatrices = #(),
    poweredMassPointsBlock = undefined,
    poweredMassPoints = #(),
    massPointsBlock = undefined,
    massPoints = #()
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

struct returnTagBase (
    radius,
    momentScale,
    mass,
    centerOfMass,
    density,
    gravityScale,
    groundFriction,
    groundDepth,
    groundDampFraction,
    groundNormalK1,
    groundNormalK0,
    waterFriction,
    waterDepth,
    waterDensity,
    airFriction,
    xxMoment,
    yyMoment,
    zzMoment
)

struct returnReflexives (
    inertiaMatrices,
    poweredMassPoints,
    massPoints
)

struct returnInertiaMatrices (
    inertialMatrix,
    inertialMatrixInverse
)

struct returnInertialMatrix (
    yyZz,
    zzXx,
    xxYy
)

struct returnInertialMatrixInverse (
    yyZz,
    zzXx,
    xxYy
)

struct inertiaMatricesBlockResult (
    inertialMatrices,
    endOffset
)

struct returnPoweredMassPoints (
    name,
    flags,
    antigravStrength,
    antigravOffset,
    antigravHeight,
    antigravDampFraction,
    antigravNormalK1,
    antigravNormalK0
)

struct poweredMassPointsBlockResult (
    poweredMassPoints,
    endOffset
)

struct returnMassPoints (
    name,
    poweredMassPoint,
    modelNode,
    flags,
    relativeMass,
    mass,
    relativeDensity,
    density,
    position,
    forward,
    up,
    frictionType,
    frictionParallelScale,
    frictionPerpendicularScale,
    radius
)

struct massPointsBlockResult (
    massPoints,
    endOffset
)

fn frictionTypeToString funcType =
(
	case funcType of
	(
		0: "point";
        1: "forward";
        2: "left";
        3: "up";
		default: ("unknown_" + (funcType as string))
	)
)

logger "Physics tag structure loaded.\n" logType: #success 