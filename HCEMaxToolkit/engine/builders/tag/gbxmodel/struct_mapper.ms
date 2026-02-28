-------------------------------------------------------
-- QUICK STRUCT CONVERTER - GBX MODEL
-- Converts parser tuple arrays to struct instances for fast property access
-------------------------------------------------------

-- GBX Model Node struct
struct GBXNode (
	name,
	nextSiblingNode,
	firstChildNode,
	parentNode,
	translation,
	rotation,
	distanceFromParent
)

-- GBX Model Region struct
struct GBXRegion (
	name,
	permutations
)

-- GBX Model Permutation struct  
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

-- GBX Model Local Marker struct
struct GBXLocalMarker (
	name,
	nodeIndex,
	rotation,
	translation
)

-- GBX Model Geometry struct
struct GBXGeometry (
	parts
)

-- GBX Model Part struct
struct GBXPart (
	flags,
	shaderIndex,
	previousPartIndex,
	nextPartIndex,
	centroidTranslation,
	uncompressedVerticesReflexive,
	compressedVerticesReflexive,
	trianglesReflexive,
	localNodeIndices,
	dataOffset = 0  -- File offset for on-demand vertex reading (calculated later)
)

-- GBX Model Shader struct
struct GBXShader (
	shader,
	permutationIndex,
	shaderName,
	shaderType
)

-- GBX Model Compressed Vertex struct
struct GBXCompressedVertex (
	position,
	normal,
	binormal,
	tangent,
	textureCoordinateU,
	textureCoordinateV,
	nodeIndex0,
	nodeIndex1,
	nodeWeight0
)

-- GBX Model Uncompressed Vertex struct
struct GBXUncompressedVertex (
	position,
	normal,
	binormal,
	tangent,
	textureCoordinateU,
	textureCoordinateV,
	nodeIndex0,
	nodeIndex1,
	nodeWeight0,
	nodeWeight1
)

-- GBX Model Triangle struct
struct GBXTriangle (
	vertex0,
	vertex1,
	vertex2
)

-- GBX Model Part Local Node struct
struct GBXPartLocalNode (
	nodeIndex
)

-- Convert array of tuples to GBX Model-specific struct instances (optimized)
fn tuplesToGBXModelStructs tupleArrays structType =
(
	if tupleArrays == undefined or tupleArrays.count == 0 then
		return #()
	
	-- Build field index once from first tuple
	local fieldIndex = buildFieldIndex tupleArrays[1]
	
	local result = #()
	
	-- Pre-calculate field positions for direct array access
	case structType of
	(
		#node: (
			local namePos = getFieldPosition fieldIndex "name"
			local nextSiblingNodePos = getFieldPosition fieldIndex "nextSiblingNodeIndex"
			local firstChildNodePos = getFieldPosition fieldIndex "firstChildNodeIndex"
			local parentNodePos = getFieldPosition fieldIndex "parentNodeIndex"
			local translationPos = getFieldPosition fieldIndex "defaultTranslation"
			local rotationPos = getFieldPosition fieldIndex "defaultRotation"
			local distanceFromParentPos = getFieldPosition fieldIndex "nodeDistanceFromParent"
			
			for t in tupleArrays do
			(
				append result (GBXNode \
					name:t[namePos][2] \
					nextSiblingNode:t[nextSiblingNodePos][2] \
					firstChildNode:t[firstChildNodePos][2] \
					parentNode:t[parentNodePos][2] \
					translation:t[translationPos][2] \
					rotation:t[rotationPos][2] \
					distanceFromParent:t[distanceFromParentPos][2])
			)
		)
		#region: (
			local namePos = getFieldPosition fieldIndex "name"
			local permutationsPos = getFieldPosition fieldIndex "permutations"
			
			for t in tupleArrays do
			(
				-- Recursively convert permutations
				local permutationsData = t[permutationsPos][2]
				local permutations = if permutationsData != undefined then \
					tuplesToGBXModelStructs permutationsData #permutation else #()
				
				append result (GBXRegion \
					name:t[namePos][2] \
					permutations:permutations)
			)
		)
		#permutation: (
			local namePos = getFieldPosition fieldIndex "name"
			local flagsPos = getFieldPosition fieldIndex "flags"
			local superLowPos = getFieldPosition fieldIndex "superLow"
			local lowPos = getFieldPosition fieldIndex "low"
			local mediumPos = getFieldPosition fieldIndex "medium"
			local highPos = getFieldPosition fieldIndex "high"
			local superHighPos = getFieldPosition fieldIndex "superHigh"
			local localMarkersPos = getFieldPosition fieldIndex "markers"
			
			for t in tupleArrays do
			(
				-- Recursively convert local markers
				local localMarkersData = t[localMarkersPos][2]
				local localMarkers = if localMarkersData != undefined then \
					tuplesToGBXModelStructs localMarkersData #localMarker else #()
				
				append result (GBXPermutation \
					name:t[namePos][2] \
					flags:t[flagsPos][2] \
					superLowGeometryBlock:t[superLowPos][2] \
					lowGeometryBlock:t[lowPos][2] \
					mediumGeometryBlock:t[mediumPos][2] \
					highGeometryBlock:t[highPos][2] \
					superHighGeometryBlock:t[superHighPos][2] \
					localMarkers:localMarkers)
			)
		)
		#localMarker: (
			local namePos = getFieldPosition fieldIndex "name"
			local nodeIndexPos = getFieldPosition fieldIndex "nodeIndex"
			local rotationPos = getFieldPosition fieldIndex "rotation"
			local translationPos = getFieldPosition fieldIndex "translation"
			
			for t in tupleArrays do
			(
				append result (GBXLocalMarker \
					name:t[namePos][2] \
					nodeIndex:t[nodeIndexPos][2] \
					rotation:t[rotationPos][2] \
					translation:t[translationPos][2])
			)
		)
		#geometry: (
			local partsPos = getFieldPosition fieldIndex "parts"
			
			for t in tupleArrays do
			(
				-- Recursively convert parts
				local partsData = t[partsPos][2]
				local parts = if partsData != undefined then \
					tuplesToGBXModelStructs partsData #part else #()
				
				append result (GBXGeometry parts:parts)
			)
		)
		#part: (
			local flagsPos = getFieldPosition fieldIndex "flags"
			local shaderIndexPos = getFieldPosition fieldIndex "shaderIndex"
			local prevPartPos = getFieldPosition fieldIndex "prevFilthyPartIndex"
			local nextPartPos = getFieldPosition fieldIndex "nextFilthyPartIndex"
			local centroidPos = getFieldPosition fieldIndex "centroid"
			local uncompVertPos = getFieldPosition fieldIndex "uncompressedVertices"
			local compVertPos = getFieldPosition fieldIndex "compressedVertices"
			local trisPos = getFieldPosition fieldIndex "triangles"
			local localNodeCountPos = getFieldPosition fieldIndex "localNodeCount"
			local localNodeIndicesPos = getFieldPosition fieldIndex "localNodeIndices"
			
			for t in tupleArrays do
			(
				-- Extract local node indices (only first N based on count)
				local localNodeCount = if localNodeCountPos > 0 then t[localNodeCountPos][2] else 0
				local localNodesRaw = if localNodeIndicesPos > 0 then t[localNodeIndicesPos][2] else #()
				local localNodes = #()
				
				if localNodeCount != undefined and localNodeCount > 0 and localNodesRaw != undefined then
				(
					for i = 1 to (amin #(localNodeCount, localNodesRaw.count)) do
						append localNodes localNodesRaw[i]
				)
				
				append result (GBXPart \
					flags:t[flagsPos][2] \
					shaderIndex:t[shaderIndexPos][2] \
					previousPartIndex:t[prevPartPos][2] \
					nextPartIndex:t[nextPartPos][2] \
					centroidTranslation:t[centroidPos][2] \
					uncompressedVerticesReflexive:t[uncompVertPos][2] \
					compressedVerticesReflexive:t[compVertPos][2] \
					trianglesReflexive:t[trisPos][2] \
					localNodeIndices:localNodes \
					dataOffset:0)
			)
		)
		#shader: (
			local shaderPos = getFieldPosition fieldIndex "shader"
			local permutationIndexPos = getFieldPosition fieldIndex "permutation"
			
			for t in tupleArrays do
			(
				local shaderTagRef = t[shaderPos][2]
				
				-- Extract shader name from path
				local shaderName = "unknown"
				local shaderType = "shader_model"
				
				if shaderTagRef != undefined and shaderTagRef[#path] != undefined then
				(
					local pathParts = filterString shaderTagRef[#path] "\\"
					if pathParts.count > 0 then
						shaderName = pathParts[pathParts.count]
					
					-- Extract shader type from tag class
					if shaderTagRef[#tagClass] != undefined then
						shaderType = shaderTagRef[#tagClass]
				)
			
				append result (GBXShader \
					shader:shaderTagRef \
					permutationIndex:t[permutationIndexPos][2] \
					shaderName:shaderName \
					shaderType:shaderType)
			)
		)
		#compressedVertex: (
			local posPos = getFieldPosition fieldIndex "position"
			local normalPos = getFieldPosition fieldIndex "normal[111110Bit]"
			local binormalPos = getFieldPosition fieldIndex "binormal[111110Bit]"
			local tangentPos = getFieldPosition fieldIndex "tangent[111110Bit]"
			local texUPos = getFieldPosition fieldIndex "textureCoordinateU[16Bit]"
			local texVPos = getFieldPosition fieldIndex "textureCoordinateV[16Bit]"
			local node0Pos = getFieldPosition fieldIndex "node0Index(x3)"
			local node1Pos = getFieldPosition fieldIndex "node1Index(x3)"
			local weight0Pos = getFieldPosition fieldIndex "node0Weight[16Bit]"
			
			for t in tupleArrays do
			(
				append result (GBXCompressedVertex \
					position:t[posPos][2] \
					normal:t[normalPos][2] \
					binormal:t[binormalPos][2] \
					tangent:t[tangentPos][2] \
					textureCoordinateU:t[texUPos][2] \
					textureCoordinateV:t[texVPos][2] \
					nodeIndex0:t[node0Pos][2] \
					nodeIndex1:t[node1Pos][2] \
					nodeWeight0:t[weight0Pos][2])
			)
		)
		#uncompressedVertex: (
			local posPos = getFieldPosition fieldIndex "position"
			local normalPos = getFieldPosition fieldIndex "normal"
			local binormalPos = getFieldPosition fieldIndex "binormal"
			local tangentPos = getFieldPosition fieldIndex "tangent"
			local texCoordsPos = getFieldPosition fieldIndex "textureCoords"
			local node0Pos = getFieldPosition fieldIndex "node0Index"
			local node1Pos = getFieldPosition fieldIndex "node1Index"
			local weight0Pos = getFieldPosition fieldIndex "node0Weight"
			local weight1Pos = getFieldPosition fieldIndex "node1Weight"

			for t in tupleArrays do
			(
				local texCoords = t[texCoordsPos][2]
				append result (GBXUncompressedVertex \
					position:t[posPos][2] \
					normal:t[normalPos][2] \
					binormal:t[binormalPos][2] \
					tangent:t[tangentPos][2] \
					textureCoordinateU:texCoords.x \
					textureCoordinateV:texCoords.y \
					nodeIndex0:t[node0Pos][2] \
					nodeIndex1:t[node1Pos][2] \
					nodeWeight0:t[weight0Pos][2] \
					nodeWeight1:t[weight1Pos][2])
			)
		)
		#triangle: (
			local v0Pos = getFieldPosition fieldIndex "vertex0Index"
			local v1Pos = getFieldPosition fieldIndex "vertex1Index"
			local v2Pos = getFieldPosition fieldIndex "vertex2Index"
			
			for t in tupleArrays do
			(
				append result (GBXTriangle \
					vertex0:t[v0Pos][2] \
					vertex1:t[v1Pos][2] \
					vertex2:t[v2Pos][2])
			)
		)
		#partLocalNode: (
			local nodeIndexPos = getFieldPosition fieldIndex "nodeIndex"
			
			for t in tupleArrays do
			(
				append result (GBXPartLocalNode \
					nodeIndex:t[nodeIndexPos][2])
			)
		)
	)
	
	result
)

-- Tag Base struct
--struct GBXTagBase (
--	flags,
--	nodeListChecksum,
--	superHighDetailCutoff,
--	highDetailCutoff,
--	mediumDetailCutoff,
--	lowDetailCutoff,
--	superLowDetailCutoff,
--	superLowLodNodes,
--	baseMapUScale,
--	baseMapVScale
--)

-- Convert tag base data
--fn convertTagBaseData tagBaseData =
--(
--	if tagBaseData == undefined then
--		return undefined
--	
--	local fieldIndex = buildFieldIndex tagBaseData
--	
--	local flagsPos = getFieldPosition fieldIndex "flags"
--	local checksumPos = getFieldPosition fieldIndex "nodeListChecksum"
--	local superHighPos = getFieldPosition fieldIndex "superHighDetailCutoff"
--	local highPos = getFieldPosition fieldIndex "highDetailCutoff"
--	local mediumPos = getFieldPosition fieldIndex "mediumDetailCutoff"
--	local lowPos = getFieldPosition fieldIndex "lowDetailCutoff"
--	local superLowPos = getFieldPosition fieldIndex "superLowDetailCutoff"
--	local superLowNodesPos = getFieldPosition fieldIndex "superLowLodNodes"
--	local uScalePos = getFieldPosition fieldIndex "baseMapUScale"
--	local vScalePos = getFieldPosition fieldIndex "baseMapVScale"
--	
--	GBXTagBase \
--		flags:tagBaseData[flagsPos][2] \
--		nodeListChecksum:tagBaseData[checksumPos][2] \
--		superHighDetailCutoff:tagBaseData[superHighPos][2] \
--		highDetailCutoff:tagBaseData[highPos][2] \
--		mediumDetailCutoff:tagBaseData[mediumPos][2] \
--		lowDetailCutoff:tagBaseData[lowPos][2] \
--		superLowDetailCutoff:tagBaseData[superLowPos][2] \
--		superLowLodNodes:tagBaseData[superLowNodesPos][2] \
--		baseMapUScale:tagBaseData[uScalePos][2] \
--		baseMapVScale:tagBaseData[vScalePos][2]
--)



-- Convert GBX Model root data
fn convertGBXModelData tupleData =
(
	local nodes = getFieldValue tupleData "nodes"
	local regions = getFieldValue tupleData "regions"
	local geometries = getFieldValue tupleData "geometries"
	local shaders = getFieldValue tupleData "shaders"
	
	-- Extract tagBase fields from root tupleData (not a nested struct)
	--local tagBaseStruct = GBXTagBase \
	--	flags:(getFieldValue tupleData "flags") \
	--	nodeListChecksum:(getFieldValue tupleData "nodeListChecksum") \
	--	superHighDetailCutoff:(getFieldValue tupleData "superHighDetailCutoff") \
	--	highDetailCutoff:(getFieldValue tupleData "highDetailCutoff") \
	--	mediumDetailCutoff:(getFieldValue tupleData "mediumDetailCutoff") \
	--	lowDetailCutoff:(getFieldValue tupleData "lowDetailCutoff") \
	--	superLowDetailCutoff:(getFieldValue tupleData "superLowCutoff") \
	--	superLowLodNodes:(getFieldValue tupleData "superLowDetailNodeCount") \
	--	baseMapUScale:(getFieldValue tupleData "baseMapUScale") \
	--	baseMapVScale:(getFieldValue tupleData "baseMapVScale")
	
	-- Convert all arrays to structs
	local nodeStructs = if nodes != undefined then tuplesToGBXModelStructs nodes #node else #()
	local regionStructs = if regions != undefined then tuplesToGBXModelStructs regions #region else #()
	local geometryStructs = if geometries != undefined then tuplesToGBXModelStructs geometries #geometry else #()
	local shaderStructs = if shaders != undefined then tuplesToGBXModelStructs shaders #shader else #()
	
	-- Main GBX Model struct
	struct GBXModelData (
		tagBase,
		nodes,
		regions,
		geometries,
		shaders
	)

	GBXModelData \
		tagBase:tagBaseStruct \
		nodes:nodeStructs \
		regions:regionStructs \
		geometries:geometryStructs \
		shaders:shaderStructs
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)