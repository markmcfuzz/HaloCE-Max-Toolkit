/*
Halo CE Gbxmodel Tag Structure Definition
Contains all struct definitions for Gbxmodel tags
*/

-------------------------------------------------------
-- Gbxmodel tag structure
-------------------------------------------------------

struct gbxmodelTag (
    header = 1836016690 or undefined,
    flags = 0,
    node_list_checksum = 0,
    super_high_detail_cutoff = 0,
    high_detail_cutoff = 0,
    medium_detail_cutoff = 0,
    low_detail_cutoff = 0,
    super_low_detail_cutoff = 0,
    super_high_lod_nodes = 0,
    high_lod_nodes = 0,
    medium_lod_nodes = 0,
    low_lod_nodes = 0,
    super_low_lod_nodes = 0,
    base_map_u_scale = 0.0,
    base_map_v_scale = 0.0,
    markers = #(),
    markers_tag_block = undefined,
    nodes = #(),
    nodes_tag_block = undefined,
    regions = #(),
    regions_tag_block = undefined,
    geometries = #(),
    geometries_tag_block = undefined,
    shaders = #(),
    shaders_tag_block = undefined
)

struct gbxmodelFlags (
    blend_shared_normals = 0,
    parts_have_local_nodes = 1,
    ignore_skinning = 2
)

struct gbxmodelMarkers (
    name = "",
    magic_identifier = 0,
    marker_instances = #(),
    marker_instances_tag_block = undefined
)

struct markerInstances (
    region_index = 0,
    permutation_index = 0,
    node_index = 0,
    translation = #(0.0, 0.0, 0.0),
    rotation = #(0.0, 0.0, 0.0)
)

struct gbxmodelNodes (
    name = "",
    next_sibling_node = 0,
    first_child_node = 0,
    parent_node = 0,
    translation = #(0.0, 0.0, 0.0),
    rotation = #(0.0, 0.0, 0.0),
    distance_from_parent = 0,
    unknown = 0,
    rot_jj_kk = #(0.0, 0.0, 0.0),
    rot_kk_ii = #(0.0, 0.0, 0.0),
    rot_ii_jj = #(0.0, 0.0, 0.0),
    translation_to_root = #(0.0, 0.0, 0.0)
)

struct gbxmodelRegions (
    name = "",
    permutations = #(),
    permutations_tag_block = undefined
)

struct regionPermutations (
    name = "",
    flags = 0,
    permutation_set = 0,
    superlow_geometry_block = 0,
    low_geometry_block = 0,
    medium_geometry_block = 0,
    high_geometry_block = 0,
    super_high_geometry_block = 0,
    local_markers = #(),
    local_markers_tag_block = undefined
)

struct regionPermutationsFlags (
    cannot_be_choosen_randomly = 0
)

struct permutationLocalMarkers (
    name = "",
    node_index = 0,
    rotation = #(0.0, 0.0, 0.0),
    translation = #(0.0, 0.0, 0.0)
)

struct gbxmodelGeometries (
    parts = #(),
    parts_tag_block = undefined
)

struct geometriesParts (
    flags = 0,
    shader_index = 0,
    previous_part_index = 0,
    next_part_index = 0,
    centroid_primary_node = 0,
    centroid_secondary_node = 0,
    centroid_primary_weight = 0.0,
    centroid_secondary_weight = 0.0,
    centroid_translation = #(0.0, 0.0, 0.0),
    uncompressed_vertices = #(),
    uncompressed_vertices_tag_block = undefined,
    compressed_vertices = #(),
    compressed_vertices_tag_block = undefined,
    triangles = #(),
    triangles_tag_block = undefined,
    model_meta_info = #(),
    model_meta_info_tag_block = undefined,
    local_node_count = 0,
    local_nodes = array 22
)

struct geometriesFlags (
    stripped = 0, -- Internal
    zoner = 1
)

struct partsUncompressedVertices (
    position_x = 0.0,
    position_y = 0.0,
    position_z = 0.0,
    normal_i = 0.0,
    normal_j = 0.0,
    normal_k = 0.0,
    binormal_i = 0.0,
    binormal_j = 0.0,
    binormal_k = 0.0,
    tangent_i = 0.0,
    tangent_j = 0.0,
    tangent_k = 0.0,
    u = 0.0,
    v = 0.0,
    node_0_index = 0,
    node_1_index = 0,
    node_0_weight = 0,
    node1_weight = 0
)

struct partsCompressedVertices (
    position_x = 0,
    position_y = 0,
    position_z = 0,
    normal = 0, --[11.11.10-bit]
    binormal = 0, --[11.11.10-bit]
    tangent = 0, --[11.11.10-bit]
    u = 0, --[16-bit]
    v = 0, --[16-bit]
    node_0_index = 0, --[x3]
    node_1_index = 0, --[x3]
    node_0_weight = 0 --[16-bit]
)

struct partsTriangles (
    v0_index = 0,
    v1_index = 0,
    v2_index = 0
)

-- Not display in guerilla
struct partsMetaInfo (
    index_type = 0,
    index_count = 0,
    indices_magic_offset = 0,
    indices_offset = 0,
    vertex_type = 0,
    vertex_count = 0,
    vertices_magic_offset = 0,
    vertices_offset = 0
)

struct indexTypeEnum (
    uncompressed = 1
)

struct vertexTypeEnum (
    uncompressed = 4,
    compressed = 5
)

---Check if this struct is valid, compare with "mod2_def.txt"
struct gbxmodelShaders (
    shader = 0, undefined,
    permutation = 0
)


fn shaderTypes funcType =
(
	case funcType of
	(
		1936221298: "shader";
        1936027254: "shader_environment";
        1936683887: "shader_model";
        1935894633: "shader_transparent_chicago";
        1935893880: "shader_transparent_chicago_extended";
        1936684146: "shader_transparent_generic";
        1936157793: "shader_transparent_glass";
        1936549236: "shader_transparent_meter";
        1936747617: "shader_transparent_plasma";
        1937203572: "shader_transparent_water";
        4294967295: "NONE";
		default: ("unknown_" + (funcType as string))
	)
)