-------------------------------------------------------
-- QUICK STRUCT CONVERTER
-- Converts parser tuple arrays to struct instances for fast property access
-------------------------------------------------------

-- BSP Vertex struct
struct BSPVertex (
	point,
	firstEdge
)

-- BSP Edge struct
struct BSPEdge (
	startVertex,
	endVertex,
	forwardEdge,
	reverseEdge,
	leftSurface,
	rightSurface
)

-- BSP Surface struct
struct BSPSurface (
	plane,
	firstEdge,
	flags,
	breakableSurface,
	material
)

-- Convert array of tuples to BSP struct instances (optimized)
fn tuplesToBSPStructs tupleArrays structType =
(
	if tupleArrays == undefined or tupleArrays.count == 0 then
		return #()

	local fieldIndex = buildFieldIndex tupleArrays[1]
	local result = #()

	local n = tupleArrays.count
	result.count = n

	case structType of
	(
		#vertex: (
			local pointPos = getFieldPosition fieldIndex "point"
			local firstEdgePos = getFieldPosition fieldIndex "firstEdge"

			for i = 1 to n do
			(
				local t = tupleArrays[i]
				result[i] = BSPVertex \
					point:t[pointPos][2] \
					firstEdge:t[firstEdgePos][2]
			)
		)
		#edge: (
			local startVertexPos  = getFieldPosition fieldIndex "startVertex"
			local endVertexPos    = getFieldPosition fieldIndex "endVertex"
			local forwardEdgePos  = getFieldPosition fieldIndex "forwardEdge"
			local reverseEdgePos  = getFieldPosition fieldIndex "reverseEdge"
			local leftSurfacePos  = getFieldPosition fieldIndex "leftSurface"
			local rightSurfacePos = getFieldPosition fieldIndex "rightSurface"

			for i = 1 to n do
			(
				local t = tupleArrays[i]
				result[i] = BSPEdge \
					startVertex:t[startVertexPos][2] \
					endVertex:t[endVertexPos][2] \
					forwardEdge:t[forwardEdgePos][2] \
					reverseEdge:t[reverseEdgePos][2] \
					leftSurface:t[leftSurfacePos][2] \
					rightSurface:t[rightSurfacePos][2]
			)
		)
		#surface: (
			local planePos            = getFieldPosition fieldIndex "plane"
			local firstEdgePos        = getFieldPosition fieldIndex "firstEdge"
			local flagsPos            = getFieldPosition fieldIndex "flags"
			local breakableSurfacePos = getFieldPosition fieldIndex "breakableSurface"
			local materialPos         = getFieldPosition fieldIndex "material"

			for i = 1 to n do
			(
				local t = tupleArrays[i]
				result[i] = BSPSurface \
					plane:t[planePos][2] \
					firstEdge:t[firstEdgePos][2] \
					flags:t[flagsPos][2] \
					breakableSurface:t[breakableSurfacePos][2] \
					material:t[materialPos][2]
			)
		)
	)

	result
)

-- Extract and convert collision BSP data from the parsed tag data
fn convertCollisionBspData bspData =
(
	local collisionBspArray = getFieldValue bspData "collisionBsp"
	if collisionBspArray == undefined or collisionBspArray.count == 0 then
		return undefined

	local cBsp = collisionBspArray[1]

	local vertices = getFieldValue cBsp "vertices"
	local edges    = getFieldValue cBsp "edges"
	local surfaces = getFieldValue cBsp "surfaces"

	struct CollisionBspData (vertices, edges, surfaces)
	CollisionBspData \
		vertices:(tuplesToBSPStructs vertices #vertex) \
		edges:(tuplesToBSPStructs edges #edge) \
		surfaces:(tuplesToBSPStructs surfaces #surface)
)

-------------------------------------------------------
-- RENDER MESH DATA STRUCTS
-------------------------------------------------------

-- One render vertex from the uncompressed render-vertex raw data
struct BSPRenderVertex (
	pos,    -- point3 in Max world units (haloScale applied)
	uv,     -- point3: [u, 1-v, 0]
	normal  -- point3: decompressed from packed uint32 (compressed) or raw floats (uncompressed)
)

-- Per-material data extracted from a lightmap's materials sub-block
struct BSPRenderMaterialData (
	shaderName,    -- string: shader filename (basename only)
	surfacesStart, -- int: 0-based start index into global surfaces array
	surfaceCount,  -- int: number of triangles for this material
	vertexCount,   -- int: number of render vertices
	vertices       -- array of BSPRenderVertex
)

-- Per-lightmap render data (one per entry in the top-level lightmaps block)
struct BSPLightmapData (
	bitmapIndex,  -- int: lightmap bitmap index (-1 if no bitmap assigned)
	materials     -- array of BSPRenderMaterialData
)

-- Map the top-level render surfaces tuples to simple #(v0, v1, v2) triplets.
-- v0/v1/v2 are 0-based vertex indices local to each lightmap material's vertex array.
fn mapBSPRenderSurfaces surfaceTuples =
(
	if surfaceTuples == undefined or surfaceTuples.count == 0 then
		return #()

	local fieldIndex = buildFieldIndex surfaceTuples[1]
	local v0Pos = getFieldPosition fieldIndex "vertex0Index"
	local v1Pos = getFieldPosition fieldIndex "vertex1Index"
	local v2Pos = getFieldPosition fieldIndex "vertex2Index"

	local result = #()
	result.count = surfaceTuples.count

	for i = 1 to surfaceTuples.count do
	(
		local t = surfaceTuples[i]
		result[i] = #(t[v0Pos][2], t[v1Pos][2], t[v2Pos][2])
	)

	result
)

-------------------------------------------------------
-- PORTAL DATA STRUCTS
-------------------------------------------------------

-- One portal's vertex list (world-space point3, pre-scaled to haloScale)
struct BSPPortalData (
	vertices  -- array of point3, world-space (haloScale applied)
)

-- Convert top-level clusterPortals block to BSPPortalData array.
fn mapBSPPortals clusterPortals =
(
	if clusterPortals == undefined or clusterPortals.count == 0 then
		return #()

	local result = #()
	result.count = clusterPortals.count

	for pi = 1 to clusterPortals.count do
	(
		local portal    = clusterPortals[pi]
		local vertsData = getFieldValue portal "vertices"
		if vertsData == undefined or vertsData.count == 0 then
		(
			result[pi] = BSPPortalData vertices:#()
			continue
		)

		local fieldIndex = buildFieldIndex vertsData[1]
		local pointPos   = getFieldPosition fieldIndex "point"

		local verts = #()
		verts.count = vertsData.count
		for vi = 1 to vertsData.count do
			verts[vi] = vertsData[vi][pointPos][2] * haloScale

		result[pi] = BSPPortalData vertices:verts
	)

	result
)

-------------------------------------------------------
-- FOG PLANE DATA STRUCTS
-------------------------------------------------------

-- One fog plane's vertex list (world-space point3, pre-scaled to haloScale)
struct BSPFogPlaneData (
	vertices  -- array of point3, world-space (haloScale applied)
)

-- Convert top-level fogPlanes block to BSPFogPlaneData array.
fn mapBSPFogPlanes fogPlanes =
(
	if fogPlanes == undefined or fogPlanes.count == 0 then
		return #()

	local result = #()
	result.count = fogPlanes.count

	for fi = 1 to fogPlanes.count do
	(
		local plane     = fogPlanes[fi]
		local vertsData = getFieldValue plane "vertices"
		if vertsData == undefined or vertsData.count == 0 then
		(
			result[fi] = BSPFogPlaneData vertices:#()
			continue
		)

		local fieldIndex = buildFieldIndex vertsData[1]
		local pointPos   = getFieldPosition fieldIndex "point"

		local verts = #()
		verts.count = vertsData.count
		for vi = 1 to vertsData.count do
			verts[vi] = vertsData[vi][pointPos][2] * haloScale

		result[fi] = BSPFogPlaneData vertices:verts
	)

	result
)

-------------------------------------------------------
-- WEATHER POLYHEDRA DATA STRUCTS
-------------------------------------------------------

-- One weather polyhedra: bounding sphere + array of planes (point4: xyz=normal, w=dist)
struct BSPWeatherPolyData (
	center,   -- point3, world-space (haloScale applied)
	radius,   -- float, world-space (haloScale applied)
	planes    -- array of point4, normal xyz + distance w (Halo units, NOT yet scaled)
)

-- Convert top-level weatherPolyhedra block to BSPWeatherPolyData array.
fn mapBSPWeatherPolyhedra weatherPolyhedra =
(
	if weatherPolyhedra == undefined or weatherPolyhedra.count == 0 then
		return #()

	local result = #()
	result.count = weatherPolyhedra.count

	for wi = 1 to weatherPolyhedra.count do
	(
		local poly       = weatherPolyhedra[wi]
		local center     = getFieldValue poly "boundingSphereCenter"
		local radius     = getFieldValue poly "boundingSphereRadius"
		local planesData = getFieldValue poly "planes"

		if planesData == undefined or planesData.count == 0 then
		(
			result[wi] = BSPWeatherPolyData center:[0,0,0] radius:0 planes:#()
			continue
		)

		local fieldIndex = buildFieldIndex planesData[1]
		local planePos   = getFieldPosition fieldIndex "plane"

		local planeArr = #()
		planeArr.count = planesData.count
		for pi = 1 to planesData.count do
			planeArr[pi] = planesData[pi][planePos][2]  -- point4 (nx ny nz d)

		result[wi] = BSPWeatherPolyData \
			center:(center * haloScale) \
			radius:(radius * haloScale) \
			planes:planeArr
	)

	result
)

-------------------------------------------------------
-- MARKERS DATA STRUCTS
-------------------------------------------------------

struct BSPMarkerData (
	name,       -- string
	markerRot,  -- quaternion (Halo convention)  [NOT 'rotation' — reserved MaxScript node property]
	markerPos   -- point3, world-space (haloScale applied)  [NOT 'position' — reserved MaxScript node property]
)

-- Convert top-level markers block to BSPMarkerData array.
fn mapBSPMarkers markers =
(
	if markers == undefined or markers.count == 0 then
		return #()

	local result = #()
	result.count = markers.count

	for mi = 1 to markers.count do
	(
		local m        = markers[mi]
		local name     = getFieldValue m "name"
		local rotation = getFieldValue m "rotation"
		local position = getFieldValue m "position"

		result[mi] = BSPMarkerData \
			name:(if name != undefined then name else "unnamed") \
			markerRot:(if rotation != undefined then rotation else (quat 0 0 0 1)) \
			markerPos:(if position != undefined then (position * haloScale) else [0,0,0])
	)

	result
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
