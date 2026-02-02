/*
Halo CE Gbxmodel Tag Structure Definition
Contains all struct definitions for Gbxmodel tags
*/

-------------------------------------------------------
-- Gbxmodel tag structure
-------------------------------------------------------

struct gbxmodelTag (
    header = undefined,
    tagBase = undefined,
    nodesTagBlock = undefined,
    nodes = #(),
    regionsTagBlock = undefined,
    regions = #(),
    geometriesTagBlock = undefined,
    geometries = #(),
    shadersTagBlock = undefined,
    shaders = #()
)

fn tagFlags baseFlags =
(
    case baseFlags of
    (
        
        0: "No flags";
        1: "blend shared normals";
        2: "parts have local nodes";
        3: "ignore skinning";
        default: ("unknown_flag_" + (flags as string))
    )
)

-------------------------------------------------------
-- Return structures
-------------------------------------------------------

struct returnHeader (
    tagClass,
    checksum,
    version,
    engineId
)

struct returnTagBase (
    flags,
    nodeListChecksum,
    superHighDetailCutoff,
    highDetailCutoff,
    mediumDetailCutoff,
    lowDetailCutoff,
    superLowDetailCutoff,
    superLowLodNodes,
    baseMapUScale,
    baseMapVScale
)

struct returnReflexives (
    nodes,
    regions,
    geometries,
    shaders
)

struct returnNodes (
    name,
    nextSiblingNode,
    firstChildNode,
    parentNode,
    translation,
    rotation,
    distanceFromParent
)

struct returnRegions (
    name,
    permutationsReflexive,
    permutations = #()
)

struct returnPermutations (
    name,
    flags,
    superLowGeometryBlock,
    lowGeometryBlock,
    mediumGeometryBlock,
    highGeometryBlock,
    superHighGeometryBlock,
    localMarkersReflexive,
    localMarkers = #()
)

struct returnLocalMarkers (
    name,
    nodeIndex,
    rotation,
    translation
)

struct returnGeometries (
    partsReflexive,
    parts = #(),
    partsDataOffset = 0  -- File offset where this geometry's vertex/triangle data starts
)

struct returnParts (
    flags,
    shaderIndex,
    previousPartIndex,
    nextPartIndex,
    centroidTranslation,
    uncompressedVerticesReflexive,
    compressedVerticesReflexive,
    trianglesReflexive,
    localNodeIndices = #(),  -- Array of global node indices for local-to-global mapping
    dataOffset = 0  -- File offset where this part's vertex/triangle data starts
    -- Note: vertices and triangles are now read on-demand, not stored here
)

struct returnUncompressedVertices (
    position,
    normal,
    binormal,
    tangent,
    textureCoords,
    u,
    v,
    node0Index,
    node1Index,
    node0Weight,
    node1Weight
)

struct returnCompressedVertices (
    position,
    normal,
    binormal,
    tangent,
    textureCoordU,
    textureCoordV,
    node0Index,
    node1Index,
    node0Weight
)

struct returnTriangles (
    v0Index,
    v1Index,
    v2Index
)

struct returnShaders (
    shaderType,
    shaderPath,
    shaderName,
    permutationIndex
)

fn shaderTypes enum =
(
	case enum of
	(
		1936221298: "shader";
        1936027254: "shader environment";
        1936683887: "shader model";
        1935894633: "shader transparent chicago";
        1935893880: "shader transparent chicago extended";
        1936684146: "shader transparent generic";
        1936157793: "shader transparent glass";
        1936549236: "shader transparent meter";
        1936747617: "shader transparent plasma";
        1937203572: "shader transparent water";
        4294967295: "NONE";
		default: ("unknown_" + (enum as string))
	)
)

struct nodesBlockResult (
    nodes,
    endOffset
)

struct regionsBlockResult (
    regions,
    endOffset
)

struct geometriesBlockResult (
    geometries,
    endOffset
)

struct shadersBlockResult (
    shaders,
    endOffset
)

struct partsBlockResult (
    parts,
    endOffset
)

struct uncompressedVerticesBlockResult (
    vertices,
    endOffset
)

struct compressedVerticesBlockResult (
    vertices,
    endOffset
)

struct trianglesBlockResult (
    triangles,
    endOffset
)

-- Helper struct for reading shader references
struct shaderRefData (
    tagRef,
    shaderType,
    permutationIndex
)

logger "Gbx/Model tag structure loaded.\n" logType:#success