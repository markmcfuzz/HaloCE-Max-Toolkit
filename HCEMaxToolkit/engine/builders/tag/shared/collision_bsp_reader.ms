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

-- Collision BSP geometry written by lua\importers\shared\collision_bsp.lua, shared by the
-- model_collision_geometry and scenario_structure_bsp readers.

-- Raw tag values: 0-based indices (-1 = none; surface material -1 = sky in a BSP), vertices in Halo units
struct CollisionSurface (firstEdge, flags, material)
struct CollisionEdge (startVertex, endVertex, forwardEdge, reverseEdge, leftSurface, rightSurface)
struct CollisionBsp (surfaces, edges, vertices)

fn luaReadCollisionBsp f =
(
	local surfaces = for i = 1 to (luaReadInt f) collect
	(
		local firstEdge = luaReadInt f
		local flags = luaReadInt f
		local material = luaReadInt f
		CollisionSurface firstEdge:firstEdge flags:flags material:material
	)
	local edges = for i = 1 to (luaReadInt f) collect
	(
		local startVertex = luaReadInt f
		local endVertex = luaReadInt f
		local forwardEdge = luaReadInt f
		local reverseEdge = luaReadInt f
		local leftSurface = luaReadInt f
		local rightSurface = luaReadInt f
		CollisionEdge startVertex:startVertex endVertex:endVertex forwardEdge:forwardEdge \
			reverseEdge:reverseEdge leftSurface:leftSurface rightSurface:rightSurface
	)
	local vertices = for i = 1 to (luaReadInt f) collect luaReadPoint3 f
	CollisionBsp surfaces:surfaces edges:edges vertices:vertices
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
