/*
Halo CE Model Tag Structure Definition
Contains all struct definitions for Model tags
*/

-------------------------------------------------------
-- Model tag structure
-------------------------------------------------------

struct modelTag (
    header = 1836016741 or undefined,
    flags = 0,
    node_list_checksum = 0,
    super_low_detail_cutoff = 0,
    low_detail_cutoff = 0,
    medium_detail_cutoff = 0,
    high_detail_cutoff = 0,
    super_high_detail_cutoff = 0,
    low_lod_nodes = 0,
    medium_lod_nodes = 0,
    high_lod_nodes = 0,
    super_high_lod_nodes = 0,
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

struct modelFlags (
    blend_shared_normals = 0
)

struct modelMarkers (
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

struct modelNodes (
    name = "",
    next_sibling_node_index = 0,
    first_child_node_index = 0,
    parent_node_index = 0,
    default_translation = #(0.0, 0.0, 0.0),
    default_rotation = #(0.0, 0.0, 0.0, 0.0),
    node_distance_from_parent = 0
)

struct modelRegions (
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
    super_high_geometry_block = 0
)

struct regionPermutationsFlags (
    cannot_be_choosen_randomly = 0
)

struct modelGeometries (
    parts = #(),
    parts_tag_block = undefined
)

struct geometriesParts (
    flags = 0,
    shader_index = 0,
    prev_filthy_part_index = 0,
    next_filthy_part_index = 0,
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
    model_meta_info_tag_block = undefined
)

struct geometriesFlags (
    stripped = 0 -- Internal
)

struct partsUncompressedVertices (
    position = #(0.0, 0.0, 0.0),
    normal = #(0.0, 0.0, 0.0),
    binormal = #(0.0, 0.0, 0.0),
    tangent = #(0.0, 0.0, 0.0),
    texture_coords = #(0.0, 0.0),
    node0_index = 0,
    node1_index = 0,
    node0_weight = 0,
    node1_weight = 0
)

struct partsCompressedVertices (
    position = #(0.0, 0.0, 0.0),
    normal = 0, --[11.11.10-bit]
    binormal = 0, --[11.11.10-bit]
    tangent = 0, --[11.11.10-bit]
    texture_coordinate_u = 0, --[16-bit]
    texture_coordinate_v = 0, --[16-bit]
    node0_index = 0, --[x3]
    node1_index = 0, --[x3]
    node0_weight = 0 --[16-bit]
)

struct partsTriangles (
    vertex0_index = 0,
    vertex1_index = 0,
    vertex2_index = 0
)

-- Not display in guerilla
struct modelMetaInfo (
    index_type = 0,
    index_count = 0,
    indices_offset = 0,
    indices_reflexive_offset = 0,
    vertex_type = 0,
    vertex_count = 0,
    vertices_offset = 0,
    vertices_reflexive_offset = 0
)

---Check if this struct is valid, compare with "mod2_def.txt"
struct modelShaders (
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