/*
Halo CE Physics Tag Structure Definition
Contains all struct definitions for physics tags
*/

-------------------------------------------------------
-- Physics tag structure
-------------------------------------------------------

struct physicsTag (
    header = 1885895027 or undefined,
    radius = 0.0,
    moment_scale = 0.0,
    mass = 0.0,
    density = 0.0,
    gravity_scale = 0.0,
    ground_friction = 0.0,
    ground_depth = 0.0,
    ground_damp_fraction = 0.0,
    ground_normal_k1 = 0.0,
    ground_normal_k0 = 0.0,
    water_friction = 0.0,
    water_depth = 0.0,
    water_density = 0.0,
    air_friction = 0.0,
    xx_moment = 0.0,
    yy_moment = 0.0,
    zz_moment = 0.0,
    inertial_matrix_and_inverse = #(),
    powered_mass_points = #(),
    mass_points = #(),
    intertial_matrix_and_inverse_tag_block = undefined,
    powered_mass_points_tag_block = undefined,
    mass_points_tag_block = undefined
)

struct physicsInertialMatrixAndInverse (
    inertial_matrix = #(),
    inertial_matrix_inverse = #()
)

struct inertialMatrix (
    yy_zz = [0.0, 0.0, 0.0],
    zz_xx = [0.0, 0.0, 0.0],
    xx_yy = [0.0, 0.0, 0.0]
)

struct intertialMatrixInverse (
    yy_zz = [0.0, 0.0, 0.0],
    zz_xx = [0.0, 0.0, 0.0],
    xx_yy = [0.0, 0.0, 0.0]
)

struct physicsPoweredMassPoints (
    name = "",
    flags = 0,
    antigrav_strength = 0.0,
    antigrav_offset = 0.0,
    antigrav_height = 0.0,
    antigrav_damp_fraction = 0.0,
    antigrav_normal_k1 = 0.0,
    antigrav_normal_k0 = 0.0
)

struct poweredMassPointsFlags (
    ground_friction = 0,
    water_friction = 1,
    water_density = 2,
    water_lift = 3,
    air_lift = 4,
    thrust = 5,
    antigrav = 6
)

struct physicsMassPoints (
    name = "",
    powered_mass_point = 0,
    model_node = 0,
    flags = 0,
    relative_mass = 0.0,
    mass = 0.0,
    relative_density = 0.0,
    density = 0.0,
    position = [0.0, 0.0, 0.0],
    forward = [1.0, 0.0, 0.0], -- quaternion
    up = [0.0, 0.0, 1.0], -- quaternion
    friction_type = 0,
    friction_parallel_scale = 0.0,
    friction_perpendicular_scale = 0.0,
    radius = 0.0
)

struct massPointsFlags (
    metallic = 0
)

struct frictionTypeEnum (
    point = 0,
    forward = 1,
    left = 2,
    up = 3
)