gbxmodelInstancesFields = #(
    tagField \
        name:"regionIndex" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"permutationIndex" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"nodeIndex" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:1, \
    tagField \
        name:"translation" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"rotation" \
        hidden:false \
        type:#quaternion
)

gbxmodelInstancesBlock = tagBlock \
    name:"instancesBlock" \
    length:32 \
    maximum:32 \
    fields:gbxmodelInstancesFields

gbxmodelMarkersFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"magicIdentifier" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"instances" \
        hidden:false \
        type:#block \
        block:gbxmodelInstancesBlock
)

gbxmodelMarkersBlock = tagBlock \
    name:"markersBlock" \
    length:64 \
    maximum:256 \
    fields:gbxmodelMarkersFields

gbxmodelNodesFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"nextSiblingNodeIndex" \
        hidden:false \
        type:#index, \
    tagField \
        name:"firstChildNodeIndex" \
        hidden:false \
        type:#index, \
    tagField \
        name:"parentNodeIndex" \
        hidden:false \
        type:#index, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"defaultTranslation" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"defaultRotation" \
        hidden:false \
        type:#quaternion, \
    tagField \
        name:"nodeDistanceFromParent" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:52
)

gbxmodelNodesBlock = tagBlock \
    name:"nodesBlock" \
    length:156 \
    maximum:64 \
    fields:gbxmodelNodesFields

gbxmodelPermutationsmarkersFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"nodeIndex" \
        hidden:false \
        type:#index, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"rotation" \
        hidden:false \
        type:#quaternion, \
    tagField \
        name:"translation" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16
)

gbxmodelPermutationsmarkersBlock = tagBlock \
    name:"permutationsMarkersBlock" \
    length:80 \
    maximum:64 \
    fields:gbxmodelPermutationsmarkersFields

gbxmodelPermutationsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28, \
    tagField \
        name:"superLow" \
        hidden:false \
        type:#index, \
    tagField \
        name:"low" \
        hidden:false \
        type:#index, \
    tagField \
        name:"medium" \
        hidden:false \
        type:#index, \
    tagField \
        name:"high" \
        hidden:false \
        type:#index, \
    tagField \
        name:"superHigh" \
        hidden:false \
        type:#index, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"markers" \
        hidden:false \
        type:#block \
        block:gbxmodelPermutationsmarkersBlock
)

gbxmodelPermutationsBlock = tagBlock \
    name:"permutationsBlock" \
    length:88 \
    maximum:32 \
    fields:gbxmodelPermutationsFields

gbxmodelRegionsFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"permutations" \
        hidden:false \
        type:#block \
        block:gbxmodelPermutationsBlock
)

gbxmodelRegionsBlock = tagBlock \
    name:"regionsBlock" \
    length:76 \
    maximum:32 \
    fields:gbxmodelRegionsFields

gbxmodelUncompressedverticesFields = #(
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"normal" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"binormal" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"tangent" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"textureCoords" \
        hidden:false \
        type:#point2d, \
    tagField \
        name:"node0Index" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"node1Index" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"node0Weight" \
        hidden:false \
        type:#float, \
    tagField \
        name:"node1Weight" \
        hidden:false \
        type:#float
)

gbxmodelUncompressedverticesBlock = tagBlock \
    name:"uncompressedVerticesBlock" \
    length:68 \
    maximum:65535 \
    fields:gbxmodelUncompressedverticesFields

gbxmodelCompressedverticesFields = #(
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"normal[111110Bit]" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"binormal[111110Bit]" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"tangent[111110Bit]" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"textureCoordinateU[16Bit]" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"textureCoordinateV[16Bit]" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"node0Index(x3)" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"node1Index(x3)" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"node0Weight[16Bit]" \
        hidden:false \
        type:#int16
)

gbxmodelCompressedverticesBlock = tagBlock \
    name:"compressedVerticesBlock" \
    length:32 \
    maximum:65535 \
    fields:gbxmodelCompressedverticesFields

gbxmodelTrianglesFields = #(
    tagField \
        name:"vertex0Index" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"vertex1Index" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"vertex2Index" \
        hidden:false \
        type:#int16
)

gbxmodelTrianglesBlock = tagBlock \
    name:"trianglesBlock" \
    length:6 \
    maximum:65535 \
    fields:gbxmodelTrianglesFields

gbxmodelPartsFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"shaderIndex" \
        hidden:false \
        type:#index, \
    tagField \
        name:"prevFilthyPartIndex" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"nextFilthyPartIndex" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"centroidPrimaryNode" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"centroidSecondaryNode" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"centroidPrimaryWeight" \
        hidden:false \
        type:#floatClamped, \
    tagField \
        name:"centroidSecondaryWeight" \
        hidden:false \
        type:#floatClamped, \
    tagField \
        name:"centroid" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"uncompressedVertices" \
        hidden:false \
        type:#block \
        block:gbxmodelUncompressedverticesBlock, \
    tagField \
        name:"compressedVertices" \
        hidden:false \
        type:#block \
        block:gbxmodelCompressedverticesBlock, \
    tagField \
        name:"triangles" \
        hidden:false \
        type:#block \
        block:gbxmodelTrianglesBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:3, \
    tagField \
        name:"localNodeCount" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"localNodeIndices" \
        hidden:false \
        type:#int8 \
        count:22, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2
)

gbxmodelPartsBlock = tagBlock \
    name:"partsBlock" \
    length:132 \
    maximum:32 \
    fields:gbxmodelPartsFields

gbxmodelGeometriesFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"parts" \
        hidden:false \
        type:#block \
        block:gbxmodelPartsBlock
)

gbxmodelGeometriesBlock = tagBlock \
    name:"geometriesBlock" \
    length:48 \
    maximum:256 \
    fields:gbxmodelGeometriesFields

gbxmodelShadersFields = #(
    tagField \
        name:"shader" \
        hidden:false \
        type:#tagReference \
        allowed:#(#shader), \
    tagField \
        name:"permutation" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12
)

gbxmodelShadersBlock = tagBlock \
    name:"shadersBlock" \
    length:32 \
    maximum:32 \
    fields:gbxmodelShadersFields

gbxmodelFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"nodeListChecksum" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"superHighDetailCutoff" \
        hidden:false \
        type:#float \
        unit:"pixels", \
    tagField \
        name:"highDetailCutoff" \
        hidden:false \
        type:#float \
        unit:"pixels", \
    tagField \
        name:"mediumDetailCutoff" \
        hidden:false \
        type:#float \
        unit:"pixels", \
    tagField \
        name:"lowDetailCutoff" \
        hidden:false \
        type:#float \
        unit:"pixels", \
    tagField \
        name:"superLowCutoff" \
        hidden:false \
        type:#float \
        unit:"pixels", \
    tagField \
        name:"superHighDetailNodeCount" \
        hidden:false \
        type:#int16 \
        unit:"nodes", \
    tagField \
        name:"highDetailNodeCount" \
        hidden:false \
        type:#int16 \
        unit:"nodes", \
    tagField \
        name:"mediumDetailNodeCount" \
        hidden:false \
        type:#int16 \
        unit:"nodes", \
    tagField \
        name:"lowDetailNodeCount" \
        hidden:false \
        type:#int16 \
        unit:"nodes", \
    tagField \
        name:"superLowDetailNodeCount" \
        hidden:false \
        type:#int16 \
        unit:"nodes", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"baseMapUScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1", \
    tagField \
        name:"baseMapVScale" \
        hidden:false \
        type:#float \
        description:"0 defaults to 1", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:116, \
    tagField \
        name:"markers" \
        hidden:false \
        type:#block \
        block:gbxmodelMarkersBlock, \
    tagField \
        name:"nodes" \
        hidden:false \
        type:#block \
        block:gbxmodelNodesBlock, \
    tagField \
        name:"regions" \
        hidden:false \
        type:#block \
        block:gbxmodelRegionsBlock, \
    tagField \
        name:"geometries" \
        hidden:false \
        type:#block \
        block:gbxmodelGeometriesBlock, \
    tagField \
        name:"shaders" \
        hidden:false \
        type:#block \
        block:gbxmodelShadersBlock
)

gbxmodelBlock = tagBlock \
    name:"gbxmodelBlock" \
    length:232 \
    maximum:1 \
    fields:gbxmodelFields

gbxmodelDef = tagDef \
    fourcc:1836016690 \
    supergroup:undefined \
    tagBlock:gbxmodelBlock
