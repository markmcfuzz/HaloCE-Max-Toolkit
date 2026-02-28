modelInstancesFields = #(
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

modelInstancesBlock = tagBlock \
    name:"instancesBlock" \
    length:32 \
    maximum:32 \
    fields:modelInstancesFields

modelMarkersFields = #(
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
        block:modelInstancesBlock
)

modelMarkersBlock = tagBlock \
    name:"markersBlock" \
    length:64 \
    maximum:256 \
    fields:modelMarkersFields

modelNodesFields = #(
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

modelNodesBlock = tagBlock \
    name:"nodesBlock" \
    length:156 \
    maximum:64 \
    fields:modelNodesFields

modelPermutationsmarkersFields = #(
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

modelPermutationsmarkersBlock = tagBlock \
    name:"permutationsMarkersBlock" \
    length:80 \
    maximum:64 \
    fields:modelPermutationsmarkersFields

modelPermutationsFields = #(
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
        block:modelPermutationsmarkersBlock
)

modelPermutationsBlock = tagBlock \
    name:"permutationsBlock" \
    length:88 \
    maximum:32 \
    fields:modelPermutationsFields

modelRegionsFields = #(
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
        block:modelPermutationsBlock
)

modelRegionsBlock = tagBlock \
    name:"regionsBlock" \
    length:76 \
    maximum:32 \
    fields:modelRegionsFields

modelUncompressedverticesFields = #(
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

modelUncompressedverticesBlock = tagBlock \
    name:"uncompressedVerticesBlock" \
    length:68 \
    maximum:65535 \
    fields:modelUncompressedverticesFields

modelCompressedverticesFields = #(
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

modelCompressedverticesBlock = tagBlock \
    name:"compressedVerticesBlock" \
    length:32 \
    maximum:65535 \
    fields:modelCompressedverticesFields

modelTrianglesFields = #(
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

modelTrianglesBlock = tagBlock \
    name:"trianglesBlock" \
    length:6 \
    maximum:65535 \
    fields:modelTrianglesFields

modelPartsFields = #(
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
        block:modelUncompressedverticesBlock, \
    tagField \
        name:"compressedVertices" \
        hidden:false \
        type:#block \
        block:modelCompressedverticesBlock, \
    tagField \
        name:"triangles" \
        hidden:false \
        type:#block \
        block:modelTrianglesBlock, \
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
        count:16
)

modelPartsBlock = tagBlock \
    name:"partsBlock" \
    length:104 \
    maximum:32 \
    fields:modelPartsFields

modelGeometriesFields = #(
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
        block:modelPartsBlock
)

modelGeometriesBlock = tagBlock \
    name:"geometriesBlock" \
    length:48 \
    maximum:256 \
    fields:modelGeometriesFields

modelShadersFields = #(
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

modelShadersBlock = tagBlock \
    name:"shadersBlock" \
    length:32 \
    maximum:32 \
    fields:modelShadersFields

modelFields = #(
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
        block:modelMarkersBlock, \
    tagField \
        name:"nodes" \
        hidden:false \
        type:#block \
        block:modelNodesBlock, \
    tagField \
        name:"regions" \
        hidden:false \
        type:#block \
        block:modelRegionsBlock, \
    tagField \
        name:"geometries" \
        hidden:false \
        type:#block \
        block:modelGeometriesBlock, \
    tagField \
        name:"shaders" \
        hidden:false \
        type:#block \
        block:modelShadersBlock
)

modelBlock = tagBlock \
    name:"modelBlock" \
    length:232 \
    maximum:1 \
    fields:modelFields

modelDef = tagDef \
    fourcc:1836016741 \
    supergroup:undefined \
    tagBlock:modelBlock
