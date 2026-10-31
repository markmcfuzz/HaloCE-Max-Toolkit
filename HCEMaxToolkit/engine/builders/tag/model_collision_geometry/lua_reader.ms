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

-- Reads a model_collision_geometry tag through lua\importers\model_collision_geometry.lua (same read order).

-- Raw tag values: 0-based indices (-1 = none), positions in Halo units
struct CollisionMaterial (name, materialType)
struct CollisionRegion (name, permutationNames)
struct CollisionPathfindingSphere (node, center, radius)
struct CollisionNode (name, region, bsps)
struct CollisionData (materials, regions, pathfindingSpheres, nodes)

-- Returns a CollisionData, or undefined on error (details in the log)
fn readCollisionWithLua tagPath =
(
	local f = luaExportTag "model_collision_geometry" 1 tagPath
	if f == undefined then return undefined

	local materials = for i = 1 to (luaReadInt f) collect
	(
		local matName = readString f
		local materialType = luaReadInt f
		CollisionMaterial name:matName materialType:materialType
	)
	local regions = for i = 1 to (luaReadInt f) collect
	(
		local regionName = readString f
		local permutationNames = for p = 1 to (luaReadInt f) collect readString f
		CollisionRegion name:regionName permutationNames:permutationNames
	)
	local spheres = for i = 1 to (luaReadInt f) collect
	(
		local sphereNode = luaReadInt f
		local center = luaReadPoint3 f
		local radius = readFloat f
		CollisionPathfindingSphere node:sphereNode center:center radius:radius
	)
	local nodes = for i = 1 to (luaReadInt f) collect
	(
		local nodeName = readString f
		local region = luaReadInt f
		local bsps = for b = 1 to (luaReadInt f) collect luaReadCollisionBsp f
		CollisionNode name:nodeName region:region bsps:bsps
	)
	luaCloseExport f "model_collision_geometry"

	CollisionData materials:materials regions:regions pathfindingSpheres:spheres nodes:nodes
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
