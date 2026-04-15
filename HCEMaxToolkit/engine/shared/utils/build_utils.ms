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

global haloScale = 100.0

-------------------------------------------------------
-- DECOMPRESSION UTILITIES
-------------------------------------------------------

-- Decompress normal vector from packed 32-bit format | Fixed
fn decompressNormal normalPacked = (
    local i = (bit.and normalPacked 1023) / 1023.0
    local j = (bit.and (bit.shift normalPacked -11) 1023) / 1023.0
    local k = (bit.and (bit.shift normalPacked -22) 511) / 511.0

    if (bit.and normalPacked (bit.shift 1 10)) != 0 do i -= 1.0
    if (bit.and normalPacked (bit.shift 1 21)) != 0 do j -= 1.0
    if (bit.and normalPacked (bit.shift 1 31)) != 0 do k -= 1.0

    normalize [i, j, k]
)

-- Decompress UV coordinates from signed 16-bit format
fn decompressUV u16 v16 uScale:1.0 vScale:1.0 = (
    local u = (u16 / 32767.0) * uScale
    local v_coord = (1.0 - (v16 / 32767.0)) * vScale
    return [u, v_coord, 0]
)

-- Decompress node indices (stored * 3 in compressed format)
fn decompressNodeIndices node0Raw node1Raw = (
    local node0Index = (node0Raw / 3) + 1  -- Convert to 1-based
    local node1Index = (node1Raw / 3) + 1  -- Convert to 1-based
    return #(node0Index, node1Index)
)

-- Decompress node weight from signed 16-bit to float (0.0-1.0)
fn decompressNodeWeight weightRaw = (
    local weight = weightRaw / 32767.0
    return weight
)
-- Decompress quaternion from four 12-bit signed integers packed into 3 words
fn decompressQuaternion w0 w1 w2 =
(
    local ww = bit.and w2 0x0FFF
    local kk = bit.or (bit.shift w2 -12) (bit.shift (bit.and w1 0x00FF) 4)
    local jj = bit.or (bit.shift w1 -8)  (bit.shift (bit.and w0 0x000F) 8)
    local ii = bit.shift w0 -4

    if (bit.and ww 0x800) != 0 then ww -= 4095
    if (bit.and kk 0x800) != 0 then kk -= 4095
    if (bit.and jj 0x800) != 0 then jj -= 4095
    if (bit.and ii 0x800) != 0 then ii -= 4095

    local mag2 = (ii as float)^2 + (jj as float)^2 \
		+ (kk as float)^2 + (ww as float)^2
    if mag2 == 0.0 then 
		return #(0.0, 0.0, 0.0, 1.0)

    local inv = 1.0 / (sqrt mag2)
    #(ii * inv, jj * inv, kk * inv, ww * inv)
)

-------------------------------------------------------
-- Blending functions for animation interpolation
-------------------------------------------------------
-- Normalized linear quaternion blend (NLERP) with anti-flip.
-- Returns a possibly-unnormalized #(i,j,k,w); caller normalizes.
fn blendQuaternion a b ratio =
(
    local r0 = 1.0 - ratio
    local r1 = ratio
    local dot = a[1]*b[1] + a[2]*b[2] + a[3]*b[3] + a[4]*b[4]
    if dot < 0.0 then r1 = -r1
    #(a[1]*r0 + b[1]*r1, a[2]*r0 + b[2]*r1, a[3]*r0 + b[3]*r1, a[4]*r0 + b[4]*r1)
)
-- Linear interpolation of two 3-element translation arrays.
fn blendVector3 a b ratio =
(
    local r1 = if ratio < 0.0 then 0.0 else if ratio > 1.0 then 1.0 else ratio
    local r0 = 1.0 - r1
    #(a[1]*r0 + b[1]*r1, a[2]*r0 + b[2]*r1, a[3]*r0 + b[3]*r1)
)
-- Linear interpolation of two float scalars (for scale).
fn blendScalar a b ratio =
(
    local r1 = if ratio < 0.0 then 0.0 else if ratio > 1.0 then 1.0 else ratio
    a * (1.0 - r1) + b * r1
)

-------------------------------------------------------
-- Object detection functions
-------------------------------------------------------

-- Check if object name indicates it should be exported as a node
fn isNodeObject obj = (
	if obj == undefined then return false
	
	local objName = toLower obj.name
	
	-- Check for node prefixes: 'b', 'b_', 'bone', 'frame', 'bip01'
	local hasPrefix = (matchPattern objName pattern:"b *") or \
                        (matchPattern objName pattern:"b_*") or \
                        (matchPattern objName pattern:"bone*") or \
                        (matchPattern objName pattern:"frame*") or \
                        (matchPattern objName pattern:"bip01*")
	
	return hasPrefix
)

-- Check if object is a marker (names starting with '#' or '+')
fn isMarkerObject obj = (
	if obj == undefined then return false
	return (obj.name[1] == "#" or obj.name[1] == "+")
)

-- Check if object is a physics/pathfinding object (names starting with '+')
fn isPhysicsObject obj = (
	if obj == undefined then return false
	return (obj.name[1] == "+")
)

-- Check if object is geometry (Editable Mesh or Editable Poly)
fn isGeometryObject obj = (
	if obj == undefined then return false
	
	local objClass = classOf obj
	
	-- Check direct class
	if objClass == Editable_mesh or objClass == Editable_Poly then
		return true
	
	-- Check base object (for objects with modifiers)
	if obj.baseObject != undefined then (
		local baseClass = classOf obj.baseObject
		if baseClass == Editable_mesh or baseClass == Editable_Poly then
			return true
	)
	
	return false
)

-- Check if object is a helper container (non-node/non-geometry object used for rotation/transform helpers)
-- These include shapes (Editable Spline), dummies, points, helpers
fn isHelperContainer obj = (
	if obj == undefined then return false
	
	-- Skip if it's already a node object
	if isNodeObject obj then return false
	
	-- Skip if it's geometry
	if isGeometryObject obj then return false
	
	-- Skip if it's a marker
	if isMarkerObject obj then return false
	
	local objClass = classOf obj
	
	-- Check for common helper types
	if objClass == Dummy or \
		objClass == Point or \
		objClass == SplineShape or \
		superClassOf obj == shape or \
		superClassOf obj == Helper then
		return true
	
	return false
)

-- Find the actual root node, looking through helper containers if necessary
-- Returns the node object that should be treated as root, or undefined
fn findActualRootNode obj = (
	if obj == undefined then return undefined
	-- If it's already a node, return it
	if isNodeObject obj then return obj
	-- If it's a helper container with exactly one child that's a node, return that child
	if isHelperContainer obj then (
		local nodeChildren = #()
		for child in obj.children do (
			if isNodeObject child and not child.isHidden then
				append nodeChildren child
		)
		-- Only return child if there's exactly one valid node child
		if nodeChildren.count == 1 then
			return nodeChildren[1]
	)
	return undefined
)

-- Get the Skin modifier from an object if it exists
fn getSkinModifier obj = (
	for i = 1 to obj.modifiers.count do (
		if classOf obj.modifiers[i] == Skin then
			return obj.modifiers[i]
	)
	return undefined
)

------------------------------------------------------------
-- Helper functions to create Halo objects
------------------------------------------------------------

-- Create a standard Marker helper (uses HaloMarker/Point)
fn createHaloMarker pos:[0,0,0] radius:1.0 name:"marker" wireColor:(color 0 255 0) = (
	local marker = HaloMarker pos:pos
	marker.markerRadius = radius
	marker.markerType = "Marker"
	marker.markerColor = wireColor
	marker.wirecolor = wireColor
	
	-- Set name with "#" prefix
	if name != "" then (
		if name[1] != "#" and name[1] != "+" then
			marker.name = "#" + name
		else
			marker.name = name
	)
	
	marker
)

-- Create a Physics or Pathfinding helper (uses HaloPhysics/InfluenceHelper)
--
fn createHaloPhysics pos:[0,0,0] radius:1.0 markerType:"Physics" name:"massPoint" \ 
	wireColor:(color 0 200 0) nearColor:(color 0 200 0) farColor:(color 0 200 0) = (
	local marker = HaloPhysics pos:pos
	marker.physicsRadius = radius
	marker.markerType = markerType
	marker.wirecolor = wireColor
	
	-- Set colors on the delegate (InfluenceHelper)
	marker.delegate.nearColor = nearColor
	marker.delegate.farColor = farColor
	
	-- Set name with "+" prefix
	if name != "" then
	(
		if name[1] != "#" and name[1] != "+" then
			marker.name = "+" + name
		else
			marker.name = name
	)
	marker
)

-- Create a Container helper
fn createHaloContainer name:"haloContainer" size:25 displayLabel:on \
	contentBoundingBox:on displayStatus:on pos:[0, 0, 0] wireColor:(color 255 255 255) = (
	-- Create "/Markers" container and parent to frame
    local haloContainer = Container()
	haloContainer.name = name
    haloContainer.size = size
    haloContainer.displayLabel = displayLabel
    haloContainer.contentBoundingBox = contentBoundingBox
    haloContainer.displayStatus = displayStatus
	haloContainer.pos = pos
	haloContainer.wirecolor = wireColor
	haloContainer
)


-------------------------------------------------------
-- GEOMETRY UTILITIES
-------------------------------------------------------

fn getSurfaceEdgeSet edges surf surfaceIndex0Based = (
	local edgeSet = #()
	local faceVerts = #()
	local currentEdgeIndex = surf.firstEdge
	local startEdgeIndex = surf.firstEdge
	local edgesProcessed = 0
	local maxEdges = edges.count

	while edgesProcessed < maxEdges do (
		if currentEdgeIndex < 0 or currentEdgeIndex >= edges.count then
			exit
		local edge = edges[currentEdgeIndex + 1]
		local isLeftSurface = (edge.leftSurface == surfaceIndex0Based)
		if isLeftSurface then (
			append faceVerts (edge.startVertex + 1)
			currentEdgeIndex = edge.forwardEdge
		)
		else if edge.rightSurface == surfaceIndex0Based then (
			append faceVerts (edge.endVertex + 1)
			currentEdgeIndex = edge.reverseEdge
		)
		else
			exit
		edgesProcessed += 1
		if currentEdgeIndex == startEdgeIndex then
			exit
	)
	for i = 1 to faceVerts.count do (
		local v1 = faceVerts[i]
		local v2 = if i < faceVerts.count then faceVerts[i + 1] else faceVerts[1]
		if v1 < v2 then
			append edgeSet #(v1, v2)
		else
			append edgeSet #(v2, v1)
	)
	qsort edgeSet (fn comparer a b = (if a[1] < b[1] then -1 else if a[1] > b[1] then 1 else (if a[2] < b[2] then -1 else if a[2] > b[2] then 1 else 0)))
	return edgeSet
)

fn edgeSetsMatch edgeSet1 edgeSet2 = (
	if edgeSet1.count != edgeSet2.count then
		return false
	for i = 1 to edgeSet1.count do (
		if edgeSet1[i][1] != edgeSet2[i][1] or edgeSet1[i][2] != edgeSet2[i][2] then
			return false
	)
	return true
)

-- Compute the intersection point of 3 planes using scalar triple product formula.
-- Each plane: point4(nx, ny, nz, d)  →  n·p = d
-- Returns point3, or undefined if planes are parallel/degenerate.
fn wpIntersect3Planes p1 p2 p3 = (
	local n1 = point3 p1.x p1.y p1.z
	local n2 = point3 p2.x p2.y p2.z
	local n3 = point3 p3.x p3.y p3.z
	local n2xn3 = cross n2 n3
	local det   = dot n1 n2xn3
	if abs det < 0.0001 then return undefined
	((n2xn3 * p1.w) + ((cross n3 n1) * p2.w) + ((cross n1 n2) * p3.w)) / det
)

-- Return true if point pt is on the positive side (or on) every plane.
fn wpIsInsideAllPlanes pt planes tol = (
	for p in planes do (
		local n = point3 p.x p.y p.z
		if (dot pt n) < p.w - tol then return false
	)
	true
)

-- Sort vertex indices by angle around centroid projected onto a plane.
fn wpSortVertsByAngle idxArray verts normal = (
	if idxArray.count < 2 then return idxArray
	local center = [0,0,0]
	for idx in idxArray do center += verts[idx]
	center /= idxArray.count

	local ref = verts[idxArray[1]] - center
	if length ref < 0.0001 then return idxArray
	ref = normalize ref
	local orth = normalize (cross normal ref)

	local pairs = #()
	for idx in idxArray do (
		local d = verts[idx] - center
		append pairs #( (atan2 (dot d orth) (dot d ref)), idx )
	)
	-- bubble sort by angle
	for i = 1 to pairs.count - 1 do
		for j = 1 to pairs.count - i do
			if pairs[j][1] > pairs[j+1][1] then (
				local tmp = pairs[j]; pairs[j] = pairs[j+1]; pairs[j+1] = tmp
			)
	local result = #()
	for pair in pairs do append result pair[2]
	result
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)