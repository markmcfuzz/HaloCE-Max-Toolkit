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

-- Reads a gbxmodel into a GBXModel (model_data.ms). The read order must match
-- gbxmodel.write() in gbxmodel.lua (this folder).

-- lua_bridge.ms is loaded by init.ms; reload it if Max still runs an older toolkit.
global luaExportTag
if luaExportTag == undefined and rootEngine != undefined do
	fileIn (rootEngine + "shared\\utils\\lua_bridge.ms")

fn gbxReadNodes f =
(
	for n = 1 to (luaReadInt f) collect
	(
		local nodeName = readString f
		local nextSibling = luaReadInt f
		local firstChild = luaReadInt f
		local parentIndex = luaReadInt f
		local translation = luaReadPoint3 f
		local rotation = luaReadQuat f
		local distanceFromParent = readFloat f
		GBXNode name:nodeName nextSiblingNode:nextSibling firstChildNode:firstChild parentNode:parentIndex \
			translation:translation rotation:rotation distanceFromParent:distanceFromParent
	)
)

fn gbxReadMarkers f =
(
	for m = 1 to (luaReadInt f) collect
	(
		local markerName = readString f
		local nodeIndex = luaReadInt f
		local rotation = luaReadQuat f
		local translation = luaReadPoint3 f
		GBXLocalMarker name:markerName nodeIndex:nodeIndex rotation:rotation translation:translation
	)
)

fn gbxReadRegions f =
(
	for r = 1 to (luaReadInt f) collect
	(
		local regionName = readString f
		local permutations = for p = 1 to (luaReadInt f) collect
		(
			local permName = readString f
			local flags = luaReadInt f
			local superLow = luaReadInt f
			local low = luaReadInt f
			local medium = luaReadInt f
			local high = luaReadInt f
			local superHigh = luaReadInt f
			local markers = gbxReadMarkers f
			GBXPermutation name:permName flags:flags superLowGeometryBlock:superLow lowGeometryBlock:low \
				mediumGeometryBlock:medium highGeometryBlock:high superHighGeometryBlock:superHigh localMarkers:markers
		)
		GBXRegion name:regionName permutations:permutations
	)
)

-- Same entry shape as the MAXScript parser output, so the shader resolver works unchanged
fn gbxReadShaders f =
(
	for s = 1 to (luaReadInt f) collect
	(
		local tagRef = luaReadTagRef f
		local permutation = luaReadInt f
		#(#("shader", tagRef), #("permutation", permutation))
	)
)

fn gbxReadGeometry f =
(
	local vertexCount = luaReadInt f
	local faceCount = luaReadInt f
	local geoMesh = newGeometryMesh()
	geoMesh.positions = for v = 1 to vertexCount collect luaReadPoint3 f
	geoMesh.normals = for v = 1 to vertexCount collect luaReadPoint3 f
	geoMesh.uvs = for v = 1 to vertexCount collect
	(
		local u = readFloat f
		local uv = readFloat f
		[u, uv, 0]
	)
	geoMesh.nodeIndices = for v = 1 to vertexCount collect
	(
		local idx0 = luaReadInt f
		local idx1 = luaReadInt f
		#(idx0, idx1)
	)
	geoMesh.nodeWeights = for v = 1 to vertexCount collect
	(
		local w0 = readFloat f
		local w1 = readFloat f
		#(w0, w1)
	)
	geoMesh.faces = for i = 1 to faceCount collect
	(
		local a = luaReadInt f
		local b = luaReadInt f
		local c = luaReadInt f
		[a, b, c]
	)
	geoMesh.matIDs = for i = 1 to faceCount collect luaReadInt f
	geoMesh
)

-- Returns a GBXModel, or undefined on error (details in the log)
fn readGbxModelWithLua tagPath =
(
	local f = luaExportTag "builders\\tag\\gbxmodel\\gbxmodel.lua" 1 tagPath options:#(haloScale)
	if f == undefined then return undefined

	local uScale = readFloat f
	local vScale = readFloat f
	local nodes = gbxReadNodes f
	local regions = gbxReadRegions f
	local shaders = gbxReadShaders f
	local geometries = for g = 1 to (luaReadInt f) collect gbxReadGeometry f
	luaCloseExport f "gbxmodel"

	GBXModel nodes:nodes regions:regions geometries:geometries shaders:shaders uScale:uScale vScale:vScale
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
