/*
Halo CE Model Collision Geometry Tag Structure Definition
Contains all struct definitions for model collision geometry tags
*/

-------------------------------------------------------
-- Main model collision geometry tag structure
-------------------------------------------------------

struct collisionTag (
    header = 1668246636 or undefined,
    flags = 0,
    indirect_damage_material = 0,
	body = undefined,
    maximum_body_vitality = 0.0,
    body_system_shock = 0.0,
    friendly_damage_resistance = 0.0,
    localized_damage_effect = undefined,
    area_damage_effect_threshold = 0.0,
    area_damage_effect = undefined,
    body_damaged_threshold = 0.0,
    body_damaged_effect = undefined,
    body_depleted_effect = undefined,
    body_destroyed_threshold = 0.0,
    body_destroyed_effect = undefined,
	shield = undefined,
    maximum_shield_vitality = 0.0,
    shield_material_type = 0,
    shield_failure_function = 0,
    shield_failure_threshold = 0.0,
    shield_failing_leak_fraction = 0.0,
    minimum_stun_damage = 0.0,
    stun_time = 0.0,
    recharge_time = 0.0,
    shield_damaged_threshold = 0.0,
    shield_damaged_effect = undefined,
    shield_depleted_effect = undefined,
    shield_recharging_effect = undefined,
    materials_tag_block = undefined,
    materials = #(),
    regions_tag_block = undefined,
    regions = #(),
    modifiers_tag_block = undefined,
    modifiers = #(),
	pathfinding_box = undefined,
	pathfinding_box_x = #(0.0, 0.0),
    pathfinding_box_y = #(0.0, 0.0),
    pathfinding_box_z = #(0.0, 0.0),
    pathfinding_spheres_tag_block = undefined,
    pathfinding_spheres = #(),
    nodes_tag_block = undefined,
    nodes = #()
)

-------------------------------------------------------
-- Body and Shield sub-structures
-------------------------------------------------------

-- Body Struct
struct collisionBody (
	maximum_body_vitality = 0.0,
    body_system_shock = 0.0,
    friendly_damage_resistance = 0.0,
    localized_damage_effect = undefined,
    area_damage_effect_threshold = 0.0,
    area_damage_effect = undefined,
    body_damaged_threshold = 0.0,
    body_damaged_effect = undefined,
    body_depleted_effect = undefined,
    body_destroyed_threshold = 0.0,
    body_destroyed_effect = undefined
)

-- Shield Struct
struct collisionShield (
	maximum_shield_vitality = 0.0,
	shield_material_type = 0,
	shield_failure_function = 0,
	shield_failure_threshold = 0.0,
	shield_failing_leak_fraction = 0.0,
	minimum_stun_damage = 0.0,
	stun_time = 0.0,
	recharge_time = 0.0,
	shield_damaged_threshold = 0.0,
	shield_damaged_effect = undefined,
	shield_depleted_effect = undefined,
	shield_recharging_effect = undefined
)

-------------------------------------------------------
-- Material structures
-------------------------------------------------------

-- Material Structure
struct collisionMaterials (
    name = "",
    flags = 0,
    material_type = 0,
    shield_leak_percentage = 0.0,
    shield_damage_multiplier = 0.0,
    body_damage_multiplier = 0.0
)

struct materialsFlags (
    head = 0
)

-------------------------------------------------------
-- Region structures
-------------------------------------------------------

-- Region Structure  
struct collisionRegions (
    name = "",
    flags = 0,
    damage_threshold = 0.0,
    destroyed_effect = undefined,
    permutations = #()
)

-- Region Flags
struct regionFlags (
    lives_until_object_dies = 0,
    forces_object_to_die = 1,
    dies_when_object_dies = 2,
    dies_when_object_is_damaged = 3,
    disappears_when_shield_is_off = 4,
    inhibits_melee_attack = 5,
    inhibits_weapon_attack = 6,
    inhibits_walking_attack = 7,
    forces_drop_weapon = 8,
    causes_head_maimed_scream = 9
)

-- Permutation Structure
struct regionPermutations (
    name = ""
)

-------------------------------------------------------
-- Modifier and pathfinding structures
-------------------------------------------------------

struct modifiers (
	null = undefined
)

-- Pathfinding Sphere Structure
struct collisionPathfindingSpheres (
    node = 0,
    center = [0.0, 0.0, 0.0],
    radius = 0.0
)

-------------------------------------------------------
-- Node hierarchy structures
-------------------------------------------------------

-- Node Structure
struct collisionNodes (
    name = "",
    region = 0,
    parent_node = 0,
    next_sibling_node = 0,
    first_child_node = 0,
	unknown0 = undefined,
	unknown1 = undefined,
    damage_region = -1,
    bsps_tag_block = undefined,
    bsps = #()
)

-------------------------------------------------------
-- BSP geometry structures
-------------------------------------------------------

-- BSPs
struct permutationBSP (
    bsp3d_nodes_tag_block = undefined,
    bsp3d_nodes = #(),
    planes_tag_block = undefined,
    planes = #(),
    leaves_tag_block = undefined,
    leaves = #(),
    bsp2d_references_tag_block = undefined,
    bsp2d_references = #(),
    bsp2d_nodes_tag_block = undefined,
    bsp2d_nodes = #(),
    surfaces_tag_block = undefined,
    surfaces = #(),
    edges_tag_block = undefined,
    edges = #(),
    vertices_tag_block = undefined,
    vertices = #()
)

-- BSP3D Node
struct bspsBSP3DNodes (
    plane = 0,
    back_child = 0,
    front_child = 0
)

-- Plane structure
struct bspsPlanes (
	i = 0.0,
	j = 0.0,
	k = 0.0,
	d = 0.0
)

-- Leaf structure
struct bspsLeaves (
    flags = 0,
    bsp2d_reference_count = 0,
    first_bsp2d_reference = 0
)

struct bspLeavesFlags (
	contains_double_sided_surfaces = 0
)

-- BSP2D Reference
struct bspsBSP2DReference (
    plane = 0,
    bsp2d_node = 0
)

-- BSP2D Node
struct bspsBSP2DNode (
    plane_i = 0.0,
    plane_j = 0.0,
    plane_d = 0.0,
    left_child = 0,
    right_child = 0
)

-- Surface structure
struct bspsSurface (
    plane = 0,
    first_edge = 0,
    flags = 0,
    breakable_surface = 0,
    material = 0
)

struct bspsSurfaceFlags (
	two_sided = 0,
	invisible = 1,
	climbable = 2,
	breakable = 3
)

-- Edge structure
struct bspsEdge (
    start_vertex = 0,
    end_vertex = 0,
    forward_edge = 0,
    reverse_edge = 0,
    left_surface = 0,
    right_surface = 0
)

-- Vertex structure
struct bspsVertices (
    point = [0.0, 0.0, 0.0],
    first_edge = 0
)

-- Material Type Enum
-- Convert material type enum to string
fn materialTypeToString matType =
(
	case matType of
	(
		0: "dirt";
        1: "sand";
        2: "stone";
        3: "snow";
        4: "wood";
		5: "metal_hollow";
        6: "metal_thin";
        7: "metal_thick";
        8: "rubber";
        9: "glass";
		10: "force_field";
        11: "grunt"; 
        12: "hunter_armor";
        13: "hunter_skin"; 
        14: "elite";
		15: "jackal";
        16: "jackal_energy_shield";
        17: "engineer_skin";
        18: "engineer_force_field";
		19: "flood_combat_form";
        20: "flood_carrier_form";
        21: "cyborg_armor";
        22: "cyborg_energy_shield";
		23: "human_armor";
        24: "human_skin";
        25: "sentinel";
        26: "monitor";
        27: "plastic";
		28: "water";
        29: "leaves";
        30: "elite_energy_shield";
        31: "ice";
        32: "hunter_shield";
		default: ("unknown_" + (matType as string))
	)
)

-- Shield Failure Function Enum
-- Convert shield failure function to string
fn shieldFailureFunctionToString funcType =
(
	case funcType of
	(
		0: "linear";
        1: "early";
        2: "very_early";
        3: "late";
        4: "very_late";
        5: "cosine";
		default: ("unknown_" + (funcType as string))
	)
)

format "Collision tag structures loaded successfully.\n"