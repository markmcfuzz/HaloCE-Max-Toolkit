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

-- gbxmodel data filled by lua_reader.ms and consumed by build_scene.ms.

struct GBXNode (
	name,
	nextSiblingNode,
	firstChildNode,
	parentNode,
	translation,
	rotation,
	distanceFromParent
)

struct GBXRegion (
	name,
	permutations
)

-- *GeometryBlock: 0-based index into GBXModel.geometries (-1 = none)
struct GBXPermutation (
	name,
	flags,
	superLowGeometryBlock,
	lowGeometryBlock,
	mediumGeometryBlock,
	highGeometryBlock,
	superHighGeometryBlock,
	localMarkers
)

struct GBXLocalMarker (
	name,
	nodeIndex,
	rotation,
	translation
)

-- One geometry with all its parts merged. Per vertex: nodeIndices #(i0, i1) 1-based, nodeWeights #(w0, w1).
struct GBXGeometryMesh (positions, normals, uvs, nodeIndices, nodeWeights, faces, matIDs)

-- shaders keeps the parser's entry shape (#("shader", tagRef) ...) for the shader resolver.
struct GBXModel (nodes, regions, geometries, shaders, uScale, vScale)

fn newGeometryMesh =
(
	GBXGeometryMesh positions:#() normals:#() uvs:#() nodeIndices:#() nodeWeights:#() faces:#() matIDs:#()
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
