scenarioStructureBspCollisionmaterialsFields = #(
    tagField \
        name:"shader" \
        hidden:false \
        type:#tagReference \
        allowed:#(#shader), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4
)

scenarioStructureBspCollisionmaterialsBlock = tagBlock \
    name:"collisionMaterialsBlock" \
    length:20 \
    maximum:512 \
    fields:scenarioStructureBspCollisionmaterialsFields

scenarioStructureBspBsp3dnodesFields = #(
    tagField \
        name:"plane" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"backChild" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"frontChild" \
        hidden:false \
        type:#int32
)

scenarioStructureBspBsp3dnodesBlock = tagBlock \
    name:"bsp3dNodesBlock" \
    length:12 \
    maximum:131072 \
    fields:scenarioStructureBspBsp3dnodesFields

scenarioStructureBspPlanesFields = #(
    tagField \
        name:"plane" \
        hidden:false \
        type:#plane3d
)

scenarioStructureBspPlanesBlock = tagBlock \
    name:"planesBlock" \
    length:16 \
    maximum:65536 \
    fields:scenarioStructureBspPlanesFields

scenarioStructureBspLeavesFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"bsp2dReferenceCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"firstBsp2dReference" \
        hidden:false \
        type:#int32
)

scenarioStructureBspLeavesBlock = tagBlock \
    name:"leavesBlock" \
    length:8 \
    maximum:65536 \
    fields:scenarioStructureBspLeavesFields

scenarioStructureBspBsp2dreferencesFields = #(
    tagField \
        name:"plane" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"bsp2dNode" \
        hidden:false \
        type:#int32
)

scenarioStructureBspBsp2dreferencesBlock = tagBlock \
    name:"bsp2dReferencesBlock" \
    length:8 \
    maximum:131072 \
    fields:scenarioStructureBspBsp2dreferencesFields

scenarioStructureBspBsp2dnodesFields = #(
    tagField \
        name:"plane" \
        hidden:false \
        type:#plane2d, \
    tagField \
        name:"leftChild" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"rightChild" \
        hidden:false \
        type:#int32
)

scenarioStructureBspBsp2dnodesBlock = tagBlock \
    name:"bsp2dNodesBlock" \
    length:20 \
    maximum:65535 \
    fields:scenarioStructureBspBsp2dnodesFields

scenarioStructureBspSurfacesFields = #(
    tagField \
        name:"plane" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"firstEdge" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int8, \
    tagField \
        name:"breakableSurface" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"material" \
        hidden:false \
        type:#int16
)

scenarioStructureBspSurfacesBlock = tagBlock \
    name:"surfacesBlock" \
    length:12 \
    maximum:131072 \
    fields:scenarioStructureBspSurfacesFields

scenarioStructureBspEdgesFields = #(
    tagField \
        name:"startVertex" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"endVertex" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"forwardEdge" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"reverseEdge" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"leftSurface" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"rightSurface" \
        hidden:false \
        type:#int32
)

scenarioStructureBspEdgesBlock = tagBlock \
    name:"edgesBlock" \
    length:24 \
    maximum:262144 \
    fields:scenarioStructureBspEdgesFields

scenarioStructureBspVerticesFields = #(
    tagField \
        name:"point" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"firstEdge" \
        hidden:false \
        type:#int32
)

scenarioStructureBspVerticesBlock = tagBlock \
    name:"verticesBlock" \
    length:16 \
    maximum:131072 \
    fields:scenarioStructureBspVerticesFields

scenarioStructureBspCollisionbspFields = #(
    tagField \
        name:"bsp3dNodes" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspBsp3dnodesBlock, \
    tagField \
        name:"planes" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspPlanesBlock, \
    tagField \
        name:"leaves" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspLeavesBlock, \
    tagField \
        name:"bsp2dReferences" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspBsp2dreferencesBlock, \
    tagField \
        name:"bsp2dNodes" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspBsp2dnodesBlock, \
    tagField \
        name:"surfaces" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspSurfacesBlock, \
    tagField \
        name:"edges" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspEdgesBlock, \
    tagField \
        name:"vertices" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspVerticesBlock
)

scenarioStructureBspCollisionbspBlock = tagBlock \
    name:"collisionBspBlock" \
    length:96 \
    maximum:1 \
    fields:scenarioStructureBspCollisionbspFields

scenarioStructureBspNodesFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:6
)

scenarioStructureBspNodesBlock = tagBlock \
    name:"nodesBlock" \
    length:6 \
    maximum:131072 \
    fields:scenarioStructureBspNodesFields

scenarioStructureBspScenariostructurebspleavesFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:6, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"cluster" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"surfaceReferenceCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"surfaceReferences" \
        hidden:false \
        type:#index
)

scenarioStructureBspScenariostructurebspleavesBlock = tagBlock \
    name:"scenarioStructureBspLeavesBlock" \
    length:16 \
    maximum:65536 \
    fields:scenarioStructureBspScenariostructurebspleavesFields

scenarioStructureBspLeafsurfacesFields = #(
    tagField \
        name:"surface" \
        hidden:false \
        type:#index, \
    tagField \
        name:"node" \
        hidden:false \
        type:#index
)

scenarioStructureBspLeafsurfacesBlock = tagBlock \
    name:"leafSurfacesBlock" \
    length:8 \
    maximum:262144 \
    fields:scenarioStructureBspLeafsurfacesFields

scenarioStructureBspScenariostructurebspsurfacesFields = #(
    tagField \
        name:"vertices" \
        hidden:false \
        type:#int32 \
        count:3, \
    tagField \
        name:"a" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int32 \
        count:1
)

scenarioStructureBspScenariostructurebspsurfacesBlock = tagBlock \
    name:"scenarioStructureBspSurfacesBlock" \
    length:6 \
    maximum:131072 \
    fields:scenarioStructureBspScenariostructurebspsurfacesFields

scenarioStructureBspMaterialsFields = #(
    tagField \
        name:"shader" \
        hidden:false \
        type:#tagReference \
        allowed:#(#shader), \
    tagField \
        name:"shaderPermutation" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"surfaces" \
        hidden:false \
        type:#index, \
    tagField \
        name:"surfaceCount" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"centroid" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"ambientColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"distantLightCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"distantLight0Color" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"distantLight0Direction" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"distantLight1Color" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"distantLight1Direction" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"reflectionTint" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"shadowVector" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"shadowColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"plane" \
        hidden:false \
        type:#plane3d, \
    tagField \
        name:"breakableSurface" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"vertexBuffers" \
        hidden:false \
        type:#int32 \
        count:2, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"count" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"offset" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int32 \
        count:1, \
    tagField \
        name:"uncompressedVertices" \
        hidden:false \
        type:#tagData, \
    tagField \
        name:"compressedVertices" \
        hidden:false \
        type:#tagData
)

scenarioStructureBspMaterialsBlock = tagBlock \
    name:"materialsBlock" \
    length:256 \
    maximum:2048 \
    fields:scenarioStructureBspMaterialsFields

scenarioStructureBspLightmapsFields = #(
    tagField \
        name:"bitmap" \
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
        name:"materials" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspMaterialsBlock
)

scenarioStructureBspLightmapsBlock = tagBlock \
    name:"lightmapsBlock" \
    length:32 \
    maximum:128 \
    fields:scenarioStructureBspLightmapsFields

scenarioStructureBspLensflaresFields = #(
    tagField \
        name:"lensFlare" \
        hidden:false \
        type:#tagReference \
        allowed:#(#lens_flare)
)

scenarioStructureBspLensflaresBlock = tagBlock \
    name:"lensFlaresBlock" \
    length:16 \
    maximum:256 \
    fields:scenarioStructureBspLensflaresFields

scenarioStructureBspLensflaremarkersFields = #(
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"directionIComponent" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"directionJComponent" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"directionKComponent" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"lensFlareIndex" \
        hidden:false \
        type:#int8
)

scenarioStructureBspLensflaremarkersBlock = tagBlock \
    name:"lensFlareMarkersBlock" \
    length:16 \
    maximum:65536 \
    fields:scenarioStructureBspLensflaremarkersFields

scenarioStructureBspPredictedresourcesFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"resourceIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"tagIndex" \
        hidden:false \
        type:#int32
)

scenarioStructureBspPredictedresourcesBlock = tagBlock \
    name:"predictedResourcesBlock" \
    length:8 \
    maximum:1024 \
    fields:scenarioStructureBspPredictedresourcesFields

scenarioStructureBspSurfaceindicesFields = #(
    tagField \
        name:"index" \
        hidden:false \
        type:#int32
)

scenarioStructureBspSurfaceindicesBlock = tagBlock \
    name:"surfaceIndicesBlock" \
    length:4 \
    maximum:128 \
    fields:scenarioStructureBspSurfaceindicesFields

scenarioStructureBspSubclustersFields = #(
    tagField \
        name:"worldBoundsX" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"worldBoundsY" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"worldBoundsZ" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"surfaceIndices" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspSurfaceindicesBlock
)

scenarioStructureBspSubclustersBlock = tagBlock \
    name:"subclustersBlock" \
    length:36 \
    maximum:4096 \
    fields:scenarioStructureBspSubclustersFields

scenarioStructureBspClusterssurfaceindicesFields = #(
    tagField \
        name:"index" \
        hidden:false \
        type:#int32
)

scenarioStructureBspClusterssurfaceindicesBlock = tagBlock \
    name:"clustersSurfaceIndicesBlock" \
    length:4 \
    maximum:32768 \
    fields:scenarioStructureBspClusterssurfaceindicesFields

scenarioStructureBspMirrorsverticesFields = #(
    tagField \
        name:"point" \
        hidden:false \
        type:#point3d
)

scenarioStructureBspMirrorsverticesBlock = tagBlock \
    name:"mirrorsVerticesBlock" \
    length:12 \
    maximum:512 \
    fields:scenarioStructureBspMirrorsverticesFields

scenarioStructureBspMirrorsFields = #(
    tagField \
        name:"plane" \
        hidden:false \
        type:#plane3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20, \
    tagField \
        name:"shader" \
        hidden:false \
        type:#tagReference \
        allowed:#(#shader), \
    tagField \
        name:"vertices" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspMirrorsverticesBlock
)

scenarioStructureBspMirrorsBlock = tagBlock \
    name:"mirrorsBlock" \
    length:64 \
    maximum:16 \
    fields:scenarioStructureBspMirrorsFields

scenarioStructureBspPortalsFields = #(
    tagField \
        name:"portal" \
        hidden:false \
        type:#int16
)

scenarioStructureBspPortalsBlock = tagBlock \
    name:"portalsBlock" \
    length:2 \
    maximum:128 \
    fields:scenarioStructureBspPortalsFields

scenarioStructureBspClustersFields = #(
    tagField \
        name:"sky" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"fog" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"backgroundSound" \
        hidden:false \
        type:#index, \
    tagField \
        name:"soundEnvironment" \
        hidden:false \
        type:#index, \
    tagField \
        name:"weather" \
        hidden:false \
        type:#index, \
    tagField \
        name:"transitionStructureBsp" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"predictedResources" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspPredictedresourcesBlock, \
    tagField \
        name:"subclusters" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspSubclustersBlock, \
    tagField \
        name:"firstLensFlareMarkerIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"lensFlareMarkerCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"surfaceIndices" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspClusterssurfaceindicesBlock, \
    tagField \
        name:"mirrors" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspMirrorsBlock, \
    tagField \
        name:"portals" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspPortalsBlock
)

scenarioStructureBspClustersBlock = tagBlock \
    name:"clustersBlock" \
    length:104 \
    maximum:8192 \
    fields:scenarioStructureBspClustersFields

scenarioStructureBspClusterportalsverticesFields = #(
    tagField \
        name:"point" \
        hidden:false \
        type:#point3d
)

scenarioStructureBspClusterportalsverticesBlock = tagBlock \
    name:"clusterPortalsVerticesBlock" \
    length:12 \
    maximum:128 \
    fields:scenarioStructureBspClusterportalsverticesFields

scenarioStructureBspClusterportalsFields = #(
    tagField \
        name:"frontCluster" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"backCluster" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"planeIndex" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"centroid" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"boundingRadius" \
        hidden:false \
        type:#float, \
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
        count:24, \
    tagField \
        name:"vertices" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspClusterportalsverticesBlock
)

scenarioStructureBspClusterportalsBlock = tagBlock \
    name:"clusterPortalsBlock" \
    length:64 \
    maximum:512 \
    fields:scenarioStructureBspClusterportalsFields

scenarioStructureBspBreakablesurfacesFields = #(
    tagField \
        name:"centroid" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"radius" \
        hidden:false \
        type:#float, \
    tagField \
        name:"collisionSurfaceIndex" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:28
)

scenarioStructureBspBreakablesurfacesBlock = tagBlock \
    name:"breakableSurfacesBlock" \
    length:48 \
    maximum:256 \
    fields:scenarioStructureBspBreakablesurfacesFields

scenarioStructureBspFogplanesverticesFields = #(
    tagField \
        name:"point" \
        hidden:false \
        type:#point3d
)

scenarioStructureBspFogplanesverticesBlock = tagBlock \
    name:"fogPlanesVerticesBlock" \
    length:12 \
    maximum:4096 \
    fields:scenarioStructureBspFogplanesverticesFields

scenarioStructureBspFogplanesFields = #(
    tagField \
        name:"frontRegion" \
        hidden:false \
        type:#index, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"plane" \
        hidden:false \
        type:#plane3d, \
    tagField \
        name:"vertices" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspFogplanesverticesBlock
)

scenarioStructureBspFogplanesBlock = tagBlock \
    name:"fogPlanesBlock" \
    length:32 \
    maximum:32 \
    fields:scenarioStructureBspFogplanesFields

scenarioStructureBspFogregionsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:36, \
    tagField \
        name:"fogPalette" \
        hidden:false \
        type:#index, \
    tagField \
        name:"weatherPalette" \
        hidden:false \
        type:#index
)

scenarioStructureBspFogregionsBlock = tagBlock \
    name:"fogRegionsBlock" \
    length:40 \
    maximum:32 \
    fields:scenarioStructureBspFogregionsFields

scenarioStructureBspFogpaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"fog" \
        hidden:false \
        type:#tagReference \
        allowed:#(#fog), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"fogScaleFunction" \
        hidden:false \
        type:#string, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:52
)

scenarioStructureBspFogpaletteBlock = tagBlock \
    name:"fogPaletteBlock" \
    length:136 \
    maximum:32 \
    fields:scenarioStructureBspFogpaletteFields

scenarioStructureBspWeatherpaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"particleSystem" \
        hidden:false \
        type:#tagReference \
        allowed:#(#weather_particle_system), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"particleSystemScaleFunction" \
        hidden:false \
        type:#string, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:44, \
    tagField \
        name:"wind" \
        hidden:false \
        type:#tagReference \
        allowed:#(#wind), \
    tagField \
        name:"windDirection" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"windMagnitude" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"windScaleFunction" \
        hidden:false \
        type:#string, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:44
)

scenarioStructureBspWeatherpaletteBlock = tagBlock \
    name:"weatherPaletteBlock" \
    length:240 \
    maximum:32 \
    fields:scenarioStructureBspWeatherpaletteFields

scenarioStructureBspWeatherpolyhedraplanesFields = #(
    tagField \
        name:"plane" \
        hidden:false \
        type:#plane3d
)

scenarioStructureBspWeatherpolyhedraplanesBlock = tagBlock \
    name:"weatherPolyhedraPlanesBlock" \
    length:16 \
    maximum:16 \
    fields:scenarioStructureBspWeatherpolyhedraplanesFields

scenarioStructureBspWeatherpolyhedraFields = #(
    tagField \
        name:"boundingSphereCenter" \
        hidden:false \
        type:#point3d, \
    tagField \
        name:"boundingSphereRadius" \
        hidden:false \
        type:#float, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"planes" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspWeatherpolyhedraplanesBlock
)

scenarioStructureBspWeatherpolyhedraBlock = tagBlock \
    name:"weatherPolyhedraBlock" \
    length:32 \
    maximum:32 \
    fields:scenarioStructureBspWeatherpolyhedraFields

scenarioStructureBspPathfindingsurfacesFields = #(
    tagField \
        name:"data" \
        hidden:false \
        type:#int8
)

scenarioStructureBspPathfindingsurfacesBlock = tagBlock \
    name:"pathfindingSurfacesBlock" \
    length:1 \
    maximum:131072 \
    fields:scenarioStructureBspPathfindingsurfacesFields

scenarioStructureBspPathfindingedgesFields = #(
    tagField \
        name:"midpoint" \
        hidden:false \
        type:#int8
)

scenarioStructureBspPathfindingedgesBlock = tagBlock \
    name:"pathfindingEdgesBlock" \
    length:1 \
    maximum:262144 \
    fields:scenarioStructureBspPathfindingedgesFields

scenarioStructureBspBackgroundsoundpaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"backgroundSound" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound_looping), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"scaleFunction" \
        hidden:false \
        type:#string, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

scenarioStructureBspBackgroundsoundpaletteBlock = tagBlock \
    name:"backgroundSoundPaletteBlock" \
    length:116 \
    maximum:64 \
    fields:scenarioStructureBspBackgroundsoundpaletteFields

scenarioStructureBspSoundenvironmentpaletteFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"soundEnvironment" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound_environment), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

scenarioStructureBspSoundenvironmentpaletteBlock = tagBlock \
    name:"soundEnvironmentPaletteBlock" \
    length:80 \
    maximum:64 \
    fields:scenarioStructureBspSoundenvironmentpaletteFields

scenarioStructureBspMarkersFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"rotation" \
        hidden:false \
        type:#quaternion, \
    tagField \
        name:"position" \
        hidden:false \
        type:#point3d
)

scenarioStructureBspMarkersBlock = tagBlock \
    name:"markersBlock" \
    length:60 \
    maximum:1024 \
    fields:scenarioStructureBspMarkersFields

scenarioStructureBspCellsFields = #(
    tagField \
        name:"" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12
)

scenarioStructureBspCellsBlock = tagBlock \
    name:"cellsBlock" \
    length:32 \
    maximum:262144 \
    fields:scenarioStructureBspCellsFields

scenarioStructureBspInstancesFields = #(
    tagField \
        name:"" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"" \
        hidden:false \
        type:#int16
)

scenarioStructureBspInstancesBlock = tagBlock \
    name:"instancesBlock" \
    length:6 \
    maximum:2097152 \
    fields:scenarioStructureBspInstancesFields

scenarioStructureBspCountsFields = #(
    tagField \
        name:"" \
        hidden:false \
        type:#int16
)

scenarioStructureBspCountsBlock = tagBlock \
    name:"countsBlock" \
    length:2 \
    maximum:8388608 \
    fields:scenarioStructureBspCountsFields

scenarioStructureBspZreferencevectorsFields = #(
    tagField \
        name:"" \
        hidden:false \
        type:#float, \
    tagField \
        name:"" \
        hidden:false \
        type:#float, \
    tagField \
        name:"" \
        hidden:false \
        type:#float, \
    tagField \
        name:"" \
        hidden:false \
        type:#float
)

scenarioStructureBspZreferencevectorsBlock = tagBlock \
    name:"zReferenceVectorsBlock" \
    length:16 \
    maximum:262144 \
    fields:scenarioStructureBspZreferencevectorsFields

scenarioStructureBspDetailobjectsFields = #(
    tagField \
        name:"cells" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspCellsBlock, \
    tagField \
        name:"instances" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspInstancesBlock, \
    tagField \
        name:"counts" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspCountsBlock, \
    tagField \
        name:"zReferenceVectors" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspZreferencevectorsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16
)

scenarioStructureBspDetailobjectsBlock = tagBlock \
    name:"detailObjectsBlock" \
    length:64 \
    maximum:1 \
    fields:scenarioStructureBspDetailobjectsFields

scenarioStructureBspRuntimedecalsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16
)

scenarioStructureBspRuntimedecalsBlock = tagBlock \
    name:"runtimeDecalsBlock" \
    length:16 \
    maximum:6144 \
    fields:scenarioStructureBspRuntimedecalsFields

scenarioStructureBspFacesverticesFields = #(
    tagField \
        name:"vertex" \
        hidden:false \
        type:#point2d
)

scenarioStructureBspFacesverticesBlock = tagBlock \
    name:"facesVerticesBlock" \
    length:8 \
    maximum:64 \
    fields:scenarioStructureBspFacesverticesFields

scenarioStructureBspFacesFields = #(
    tagField \
        name:"nodeIndex" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"vertices" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspFacesverticesBlock
)

scenarioStructureBspFacesBlock = tagBlock \
    name:"facesBlock" \
    length:16 \
    maximum:256 \
    fields:scenarioStructureBspFacesFields

scenarioStructureBspPortalindicesFields = #(
    tagField \
        name:"portalIndex" \
        hidden:false \
        type:#int32
)

scenarioStructureBspPortalindicesBlock = tagBlock \
    name:"portalIndicesBlock" \
    length:4 \
    maximum:256 \
    fields:scenarioStructureBspPortalindicesFields

scenarioStructureBspLeafmapleavesFields = #(
    tagField \
        name:"faces" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspFacesBlock, \
    tagField \
        name:"portalIndices" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspPortalindicesBlock
)

scenarioStructureBspLeafmapleavesBlock = tagBlock \
    name:"leafMapLeavesBlock" \
    length:24 \
    maximum:65536 \
    fields:scenarioStructureBspLeafmapleavesFields

scenarioStructureBspLeafmapportalsverticesFields = #(
    tagField \
        name:"point" \
        hidden:false \
        type:#point3d
)

scenarioStructureBspLeafmapportalsverticesBlock = tagBlock \
    name:"leafMapPortalsVerticesBlock" \
    length:12 \
    maximum:64 \
    fields:scenarioStructureBspLeafmapportalsverticesFields

scenarioStructureBspLeafmapportalsFields = #(
    tagField \
        name:"planeIndex" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"backLeafIndex" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"frontLeafIndex" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"vertices" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspLeafmapportalsverticesBlock
)

scenarioStructureBspLeafmapportalsBlock = tagBlock \
    name:"leafMapPortalsBlock" \
    length:24 \
    maximum:524288 \
    fields:scenarioStructureBspLeafmapportalsFields

scenarioStructureBspFields = #(
    tagField \
        name:"lightmaps" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"vehicleFloor" \
        hidden:false \
        type:#float \
        description:"height below which vehicles get pushed up by an unstoppable force" \
        unit:"world units", \
    tagField \
        name:"vehicleCeiling" \
        hidden:false \
        type:#float \
        description:"height above which vehicles get pushed down by an unstoppable force" \
        unit:"world units", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:20, \
    tagField \
        name:"defaultAmbientColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"defaultDistantLight0Color" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"defaultDistantLight0Direction" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"defaultDistantLight1Color" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"defaultDistantLight1Direction" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"defaultReflectionTint" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"defaultShadowVector" \
        hidden:false \
        type:#vector3d, \
    tagField \
        name:"defaultShadowColor" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"collisionMaterials" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspCollisionmaterialsBlock, \
    tagField \
        name:"collisionBsp" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspCollisionbspBlock, \
    tagField \
        name:"nodes" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspNodesBlock, \
    tagField \
        name:"worldBoundsX" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"worldBoundsY" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"worldBoundsZ" \
        hidden:false \
        type:#floatBounds, \
    tagField \
        name:"leaves" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspScenariostructurebspleavesBlock, \
    tagField \
        name:"leafSurfaces" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspLeafsurfacesBlock, \
    tagField \
        name:"surfaces" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspScenariostructurebspsurfacesBlock, \
    tagField \
        name:"lightmaps" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspLightmapsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"lensFlares" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspLensflaresBlock, \
    tagField \
        name:"lensFlareMarkers" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspLensflaremarkersBlock, \
    tagField \
        name:"clusters" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspClustersBlock, \
    tagField \
        name:"clusterData" \
        hidden:false \
        type:#tagData, \
    tagField \
        name:"clusterPortals" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspClusterportalsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"breakableSurfaces" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspBreakablesurfacesBlock, \
    tagField \
        name:"fogPlanes" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspFogplanesBlock, \
    tagField \
        name:"fogRegions" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspFogregionsBlock, \
    tagField \
        name:"fogPalette" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspFogpaletteBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"weatherPalette" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspWeatherpaletteBlock, \
    tagField \
        name:"weatherPolyhedra" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspWeatherpolyhedraBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"pathfindingSurfaces" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspPathfindingsurfacesBlock, \
    tagField \
        name:"pathfindingEdges" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspPathfindingedgesBlock, \
    tagField \
        name:"backgroundSoundPalette" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspBackgroundsoundpaletteBlock, \
    tagField \
        name:"soundEnvironmentPalette" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspSoundenvironmentpaletteBlock, \
    tagField \
        name:"soundPasData" \
        hidden:false \
        type:#tagData, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24, \
    tagField \
        name:"markers" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspMarkersBlock, \
    tagField \
        name:"detailObjects" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspDetailobjectsBlock, \
    tagField \
        name:"runtimeDecals" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspRuntimedecalsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"leafMapLeaves" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspLeafmapleavesBlock, \
    tagField \
        name:"leafMapPortals" \
        hidden:false \
        type:#block \
        block:scenarioStructureBspLeafmapportalsBlock
)

scenarioStructureBspBlock = tagBlock \
    name:"scenarioStructureBspBlock" \
    length:648 \
    maximum:1 \
    fields:scenarioStructureBspFields

scenarioStructureBspDef = tagDef \
    fourcc:1935831920 \
    supergroup:undefined \
    tagBlock:scenarioStructureBspBlock
