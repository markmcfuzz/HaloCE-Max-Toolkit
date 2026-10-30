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

-- Reads a scenario_structure_bsp tag through scenario_structure_bsp.lua in this folder (same read order).

-- lua_bridge.ms is loaded by init.ms; reload it if Max still runs an older toolkit.
global luaExportTag
if luaExportTag == undefined and rootEngine != undefined do
	fileIn (rootEngine + "shared\\utils\\lua_bridge.ms")

-- Render data of one lightmap material. Vertices are scaled; uvs are [u, 1 - v, 0].
-- shaderStruct has the "shader" field that resolveShaderTexture reads.
struct BSPRenderMaterialData (shaderName, shaderStruct, surfacesStart, surfaceCount, vertexCount, positions, uvs, normals)
struct BSPLightmapData (bitmapIndex, materials)

-- Positions and radius are scaled; weather planes are Point4 (normal xyz, distance w) in Halo units
struct BSPPortalData (vertices)
struct BSPFogPlaneData (vertices)
struct BSPWeatherPolyData (center, radius, planes)
struct BSPMarkerData (name, markerRot, markerPos)

-- renderSurfaces: #(v0, v1, v2) per triangle, 0-based and local to its lightmap material
struct StructureBspData (collisionMaterials, collisionBsp, renderSurfaces, lightmaps, portals, fogPlanes, weatherPolyhedra, markers)

fn bspReadRenderMaterial f =
(
	local shaderRef = luaReadTagRef f
	local surfacesStart = luaReadInt f
	local surfaceCount = luaReadInt f
	local vertexCount = luaReadInt f
	local n = luaReadInt f
	local positions = for i = 1 to n collect luaReadPoint3 f
	local uvs = for i = 1 to n collect
	(
		local u = readFloat f
		local v = readFloat f
		[u, v, 0]
	)
	local normals = for i = 1 to n collect luaReadPoint3 f
	local shaderName = if shaderRef[#path] != "" then filenameFromPath shaderRef[#path] else ""
	BSPRenderMaterialData shaderName:shaderName shaderStruct:#(#("shader", shaderRef)) \
		surfacesStart:surfacesStart surfaceCount:surfaceCount vertexCount:vertexCount \
		positions:positions uvs:uvs normals:normals
)

fn bspReadPointLists f = for i = 1 to (luaReadInt f) collect (for v = 1 to (luaReadInt f) collect luaReadPoint3 f)

-- Returns a StructureBspData, or undefined on error (details in the log)
fn readStructureBspWithLua tagPath =
(
	local f = luaExportTag "builders\\tag\\scenario_structure_bsp\\scenario_structure_bsp.lua" 1 tagPath options:#(haloScale)
	if f == undefined then return undefined

	local collisionMaterials = for i = 1 to (luaReadInt f) collect luaReadTagRef f
	local bspCollision = if (luaReadInt f) > 0 then luaReadCollisionBsp f else undefined
	local renderSurfaces = for i = 1 to (luaReadInt f) collect
	(
		local v0 = luaReadInt f
		local v1 = luaReadInt f
		local v2 = luaReadInt f
		#(v0, v1, v2)
	)
	local lightmaps = for i = 1 to (luaReadInt f) collect
	(
		local bitmapIndex = luaReadInt f
		local materials = for m = 1 to (luaReadInt f) collect bspReadRenderMaterial f
		BSPLightmapData bitmapIndex:bitmapIndex materials:materials
	)
	local portals = for verts in (bspReadPointLists f) collect BSPPortalData vertices:verts
	local fogPlanes = for verts in (bspReadPointLists f) collect BSPFogPlaneData vertices:verts
	local weatherPolyhedra = for i = 1 to (luaReadInt f) collect
	(
		local center = luaReadPoint3 f
		local radius = readFloat f
		local planes = for p = 1 to (luaReadInt f) collect
		(
			local nx = readFloat f
			local ny = readFloat f
			local nz = readFloat f
			local d = readFloat f
			point4 nx ny nz d
		)
		BSPWeatherPolyData center:center radius:radius planes:planes
	)
	local markers = for i = 1 to (luaReadInt f) collect
	(
		local markerName = readString f
		local markerRot = luaReadQuat f
		local markerPos = luaReadPoint3 f
		BSPMarkerData name:markerName markerRot:markerRot markerPos:markerPos
	)
	luaCloseExport f "scenario_structure_bsp"

	StructureBspData collisionMaterials:collisionMaterials collisionBsp:bspCollision renderSurfaces:renderSurfaces \
		lightmaps:lightmaps portals:portals fogPlanes:fogPlanes weatherPolyhedra:weatherPolyhedra markers:markers
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
