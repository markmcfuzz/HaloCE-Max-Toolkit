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

-- Convert array of tuples to collision-specific struct instances (optimized)
fn tuplesToCollisionStructs tupleArrays structType =
(
	if tupleArrays == undefined or tupleArrays.count == 0 then
		return #()
	
	-- Build field index once from first tuple
	local fieldIndex = buildFieldIndex tupleArrays[1]
	
	local result = #()
	
	-- Pre-calculate field positions for direct array access
	case structType of
	(
		#vertex: (
			local pointPos = getFieldPosition fieldIndex "point"
			local firstEdgePos = getFieldPosition fieldIndex "firstEdge"
			
			for t in tupleArrays do
			(
				append result (BSPVertex \
					point:t[pointPos][2] \
					firstEdge:t[firstEdgePos][2])
			)
		)
		#edge: (
			local startVertexPos = getFieldPosition fieldIndex "startVertex"
			local endVertexPos = getFieldPosition fieldIndex "endVertex"
			local forwardEdgePos = getFieldPosition fieldIndex "forwardEdge"
			local reverseEdgePos = getFieldPosition fieldIndex "reverseEdge"
			local leftSurfacePos = getFieldPosition fieldIndex "leftSurface"
			local rightSurfacePos = getFieldPosition fieldIndex "rightSurface"
			
			for t in tupleArrays do
			(
				append result (BSPEdge \
					startVertex:t[startVertexPos][2] \
					endVertex:t[endVertexPos][2] \
					forwardEdge:t[forwardEdgePos][2] \
					reverseEdge:t[reverseEdgePos][2] \
					leftSurface:t[leftSurfacePos][2] \
					rightSurface:t[rightSurfacePos][2])
			)
		)
		#surface: (
			local planePos = getFieldPosition fieldIndex "plane"
			local firstEdgePos = getFieldPosition fieldIndex "firstEdge"
			local flagsPos = getFieldPosition fieldIndex "flags"
			local breakableSurfacePos = getFieldPosition fieldIndex "breakableSurface"
			local materialPos = getFieldPosition fieldIndex "material"
			
			for t in tupleArrays do
			(
				append result (BSPSurface \
					plane:t[planePos][2] \
					firstEdge:t[firstEdgePos][2] \
					flags:t[flagsPos][2] \
					breakableSurface:t[breakableSurfacePos][2] \
					material:t[materialPos][2])
			)
		)
	)
	
	result
)

-- Convert BSP data tuple to struct with converted sub-arrays
fn convertBSPData bspData =
(
	local vertices = getFieldValue bspData "vertices"
	local edges = getFieldValue bspData "edges"
	local surfaces = getFieldValue bspData "surfaces"
	
	-- Convert all arrays to structs
	local vertStructs = if vertices != undefined then tuplesToCollisionStructs vertices #vertex else #()
	local edgeStructs = if edges != undefined then tuplesToCollisionStructs edges #edge else #()
	local surfStructs = if surfaces != undefined then tuplesToCollisionStructs surfaces #surface else #()
	
	-- Return a simple struct with the converted data
	struct BSPData (vertices, edges, surfaces)
	BSPData \
		vertices:vertStructs \
		edges:edgeStructs \
		surfaces:surfStructs
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)