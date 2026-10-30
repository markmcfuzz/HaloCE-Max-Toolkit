------------------------------------------------------------------------------
--	Copyright (C) 2025 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------

-- Reads a physics tag through physics.lua in this folder (same read order).

-- lua_bridge.ms is loaded by init.ms; reload it if Max still runs an older toolkit.
global luaExportTag
if luaExportTag == undefined and rootEngine != undefined do
	fileIn (rootEngine + "shared\\utils\\lua_bridge.ms")

-- Raw tag values; position/radius in Halo units. poweredMassPoint: 0-based index, -1 = none
struct PhysicsMassPoint (name, poweredMassPoint, modelNode, flags, frictionType, relativeMass, relativeDensity, \
	density, radius, frictionParallelScale, frictionPerpendicularScale, position, forward, up)

struct PhysicsData (mass, density, poweredMassPointNames, massPoints)

-- Returns a PhysicsData, or undefined on error (details in the log)
fn readPhysicsWithLua tagPath =
(
	local f = luaExportTag "builders\\tag\\physics\\physics.lua" 1 tagPath
	if f == undefined then return undefined

	local mass = readFloat f
	local density = readFloat f
	local poweredNames = for i = 1 to (luaReadInt f) collect readString f
	local massPoints = for i = 1 to (luaReadInt f) collect
	(
		local mpName = readString f
		local poweredMassPoint = luaReadInt f
		local modelNode = luaReadInt f
		local flags = luaReadInt f
		local frictionType = luaReadInt f
		local relativeMass = readFloat f
		local relativeDensity = readFloat f
		local mpDensity = readFloat f
		local radius = readFloat f
		local frictionParallel = readFloat f
		local frictionPerpendicular = readFloat f
		local position = luaReadPoint3 f
		local forward = luaReadPoint3 f
		local up = luaReadPoint3 f
		PhysicsMassPoint name:mpName poweredMassPoint:poweredMassPoint modelNode:modelNode flags:flags \
			frictionType:frictionType relativeMass:relativeMass relativeDensity:relativeDensity density:mpDensity \
			radius:radius frictionParallelScale:frictionParallel frictionPerpendicularScale:frictionPerpendicular \
			position:position forward:forward up:up
	)
	luaCloseExport f "physics"

	PhysicsData mass:mass density:density poweredMassPointNames:poweredNames massPoints:massPoints
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
