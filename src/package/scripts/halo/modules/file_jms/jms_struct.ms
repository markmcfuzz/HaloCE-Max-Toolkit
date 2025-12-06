/*
Jms file structure 
*/

struct jmsFile (
    jmsVersion = undefined,
    jmsChecksum = undefined,
    nodeCount = undefined,
    nodes = #(),
    shaderCount = undefined,
    shaders = #(),
    markerCount = undefined,
    markers = #(),
    regionCount = undefined,
    regions = #(),
    vertexCount = undefined,
    vertices = #(),
    triangleCount = undefined,
    triangles = #()
)

struct nodes (
    nodeName,
    firstChildNodeIndex,
    nextSiblingNodeIndex,
    nodeRotation,
    nodeTranslation
)

struct shaders (
    shaderName,
    shaderPath
)

struct markers (
    markerName,
    markerRegion,
    parentNodeIndex,
    markerRotation,
    markerTranslation,
    markerRadius
)

struct region (
    regionName
)

struct vertices (
    node0Index,
    position,
    normal,
    node1Index,
    node1Weight,
    texturePos
)

struct triangles (
    regionIndex,
    shaderIndex,
    vertexIndices
)

logger "Jms Struct loaded.\n" logType:#success