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
-- BSPs Tag Block
-------------------------------------------------------

fn readNodeReflexives nodeIndex nodeName bspsReflexive bspsDataOffset =
(
	local bspsCount = bspsReflexive.count
	
	if bspsCount == 0 then
	(
		return #()
	)
	seekToPosition bspsDataOffset
	
	local bsps = #()
	for i = 1 to bspsCount do
	(
		local currentPos = getFilePosition()
		local bsp3dNodesReflexive = read.reflex()
		local afterPos = getFilePosition()

		local planesReflexive = read.reflex()
		local leavesReflexive = read.reflex()

		local bsp2dReferencesReflexive = read.reflex()
		local bsp2dNodesReflexive = read.reflex()
		local surfacesReflexive = read.reflex()
		local edgesReflexive = read.reflex()
		local verticesReflexive = read.reflex()
		
		local bsp = returnBspsReflexives()
		bsp.bsp3dNodes = bsp3dNodesReflexive
		bsp.planes = planesReflexive
		bsp.leaves = leavesReflexive
		bsp.bsp2dReferences = bsp2dReferencesReflexive
		bsp.bsp2dNodes = bsp2dNodesReflexive
		bsp.surfaces = surfacesReflexive
		bsp.edges = edgesReflexive
		bsp.vertices = verticesReflexive

		append bsps bsp
		
	)
	return bsps
)

-------------------------------------------------------
-- BSP3D Nodes Tag Block
-------------------------------------------------------

fn readBSP3DNodes bsp3dNodesReflexive dataOffset =
(
	local count = bsp3dNodesReflexive.count
	if count == 0 then 
	(
		return #()
	)
	seekToPosition dataOffset
	local nodes = #()
	for i = 1 to count do
	(
		local plane = read.longB "#signed"
		local backChild = read.longB "#signed"
		local frontChild = read.longB "#signed"
		
		local node = returnBsp3dNodes()
		node.plane = plane
		node.backChild = backChild
		node.frontChild = frontChild
		
		append nodes node
	)
	return nodes
)

-------------------------------------------------------
-- Planes Tag Block
-------------------------------------------------------

fn readPlanes planesReflexive dataOffset =
(
	local count = planesReflexive.count
	if count == 0 then 
	(
		return #()
	)
	seekToPosition dataOffset
	local planes = #()
	for i = 1 to count do
	(
		local i = read.floatB()
		local j = read.floatB()
		local k = read.floatB()
		local d = read.floatB()
		
		local plane = returnBspsPlanes()
		plane.i = i
		plane.j = j
		plane.k = k
		plane.d = d
		
		append planes plane
	)
	return planes
)

-------------------------------------------------------
-- Leaves Tag Block
-------------------------------------------------------

fn readLeaves leavesReflexive dataOffset =
(
	local count = leavesReflexive.count
	if count == 0 then 
	(
		return #()
	)
	seekToPosition dataOffset
	local leaves = #()
	for i = 1 to count do
	(
		local flagsValue = read.shortB "#unsigned"
		local flags = if (bit.get flagsValue 1) then ("contains_double_sided_surfaces") else ("none")
		local bsp2dReferenceCount = read.shortB "#signed"
		local firstBsp2dReference = read.longB "#signed"
		
		local leaf = returnBspsLeaves()
		leaf.flags = flags
		leaf.bsp2dReferenceCount = bsp2dReferenceCount
		leaf.firstBsp2dReference = firstBsp2dReference
		
		append leaves leaf
	)
	return leaves
)

-------------------------------------------------------
-- BSP2D References Tag Block
-------------------------------------------------------

fn readBSP2DReferences bsp2dRefsReflexive dataOffset =
(
	local count = bsp2dRefsReflexive.count
	if count == 0 then 
	(
		return #()
	)
	seekToPosition dataOffset
	local bsp2dRefs = #()
	for i = 1 to count do
	(
		local plane = read.longB "#signed"
		local bsp2dNode = read.longB "#signed"
		
		local ref = returnBSP2DReferences()
		ref.plane = plane
		ref.bsp2dNode = bsp2dNode
		
		append bsp2dRefs ref
	)
	return bsp2dRefs
)

-------------------------------------------------------
-- BSP2D Nodes Tag Block
-------------------------------------------------------

fn readBSP2DNodes bsp2dNodesReflexive dataOffset =
(
	local count = bsp2dNodesReflexive.count
	if count == 0 then 
	(
		return #()
	)
	seekToPosition dataOffset
	local nodes = #()
	for i = 1 to count do
	(
		local planeI = read.floatB()
		local planeJ = read.floatB()
		local planeD = read.floatB()
		local leftChild = read.longB "#signed"
		local rightChild = read.longB "#signed"

		local node = returnBsp2dNodes()
		node.planeI = planeI
		node.planeJ = planeJ
		node.planeD = planeD
		node.leftChild = leftChild
		node.rightChild = rightChild
		append nodes node
	)
	return nodes
)	

-------------------------------------------------------
-- Surfaces Tag Block
-------------------------------------------------------

fn readSurfaces surfacesReflexive dataOffset =
(
	local count = surfacesReflexive.count
	if count == 0 then 
	(
		return #()
	)
	seekToPosition dataOffset
	local surfaces = #()
	for i = 1 to count do
	(
		local plane = read.longB "#signed"
		local firstEdge = read.longB "#signed"
		
		local fileHandle = getCurrentFileHandle()
		local flagsValue = readByte fileHandle #unsigned
		local surfaceFlagNames = #("two_sided", "invisible", "climbable", "breakable")
		local flags = decodeFlagBits flagsValue surfaceFlagNames
		
		local breakableSurface = readByte fileHandle #signed
		local material = read.shortB "#signed"
		
		local surface = returnSurfaces()
		surface.plane = plane
		surface.firstEdge = firstEdge
		surface.flags = flags
		surface.breakableSurface = breakableSurface
		surface.material = material
		
		append surfaces surface
	)
	return surfaces
)

-------------------------------------------------------
-- Edges Tag Block
-------------------------------------------------------

fn readEdges edgesReflexive dataOffset =
(
	local count = edgesReflexive.count
	if count == 0 then 
	(
		return #()
	)
	seekToPosition dataOffset
	local edges = #()
	for i = 1 to count do
	(
		local startVertex = read.longB "#signed"
		local endVertex = read.longB "#signed"
		local forwardEdge = read.longB "#signed"
		local reverseEdge = read.longB "#signed"
		local leftSurface = read.longB "#signed"
		local rightSurface = read.longB "#signed"
		
		local edge = returnEdges()
		edge.startVertex = startVertex
		edge.endVertex = endVertex
		edge.forwardEdge = forwardEdge
		edge.reverseEdge = reverseEdge
		edge.leftSurface = leftSurface
		edge.rightSurface = rightSurface
		
		append edges edge
	)
	return edges
)

-------------------------------------------------------
-- Vertices Tag Block
-------------------------------------------------------

fn readVertices verticesReflexive dataOffset =
(
	local count = verticesReflexive.count
	if count == 0 then 
	(
		return #()
	)
	seekToPosition dataOffset
	local vertices = #()
	for i = 1 to count do
	(
		local x = read.floatB()
		local y = read.floatB()
		local z = read.floatB()
		local point = [x, y, z]
		local firstEdge = read.longB "#signed"
		
		local vertex = returnVertices()
		vertex.point = point
		vertex.firstEdge = firstEdge
		
		append vertices vertex
	)
	return vertices
)

-------------------------------------------------------
-- Read All Nodes BSP Geometry
-------------------------------------------------------

fn readAllNodesBSPGeometry nodes nodesDataOffset =
(
	if nodes.count == 0 then
	(
		return nodes
	)	
	local fileHandle = getCurrentFileHandle()
	local currentPos = ftell fileHandle
	fseek fileHandle 0 #seek_end
	local fileSize = ftell fileHandle
	fseek fileHandle currentPos #seek_set

	local bspsDataStartOffset = nodesDataOffset + (nodes.count * 64)
	local currentBSPOffset = bspsDataStartOffset
		
	for i = 1 to nodes.count do
	(
		local node = nodes[i]
		local bspsReflexive = node.bspsReflexive
		
		if bspsReflexive.count > 0 then
		(			
			node.bsps = readNodeReflexives i node.name bspsReflexive currentBSPOffset
			currentBSPOffset += (bspsReflexive.count * 96)
			
			for bspIdx = 1 to node.bsps.count do
			(
				local bsp = node.bsps[bspIdx]
				if bsp.bsp3dNodes.count > 0 then
				(
					bsp.bsp3dNodes = readBSP3DNodes bsp.bsp3dNodes currentBSPOffset
					currentBSPOffset += (bsp.bsp3dNodes.count * 12)
				)
				if bsp.planes.count > 0 then
				(
					bsp.planes = readPlanes bsp.planes currentBSPOffset
					currentBSPOffset += (bsp.planes.count * 16)
				)
				if bsp.leaves.count > 0 then
				(
					bsp.leaves = readLeaves bsp.leaves currentBSPOffset
					currentBSPOffset += (bsp.leaves.count * 8)
				)
				if bsp.bsp2dReferences.count > 0 then
				(
					bsp.bsp2dReferences = readBSP2DReferences bsp.bsp2dReferences currentBSPOffset
					currentBSPOffset += (bsp.bsp2dReferences.count * 8)
				)
				if bsp.bsp2dNodes.count > 0 then
				(
					bsp.bsp2dNodes = readBSP2DNodes bsp.bsp2dNodes currentBSPOffset
					currentBSPOffset += (bsp.bsp2dNodes.count * 20)
				)
				if bsp.surfaces.count > 0 then
				(
					bsp.surfaces = readSurfaces bsp.surfaces currentBSPOffset
					currentBSPOffset += (bsp.surfaces.count * 12)
				)
				if bsp.edges.count > 0 then
				(
					bsp.edges = readEdges bsp.edges currentBSPOffset
					currentBSPOffset += (bsp.edges.count * 24)
				)
				if bsp.vertices.count > 0 then
				(
					bsp.vertices = readVertices bsp.vertices currentBSPOffset
					currentBSPOffset += (bsp.vertices.count * 16)
				)
			)
		)
	)
	return nodes
)

logger "Geometry tag reader loaded.\n" logType:#success
