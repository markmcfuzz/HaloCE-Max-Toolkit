"""Halo 5 animation graph/resource reader and transform assembler."""

# Vendored from H5AnimExtractor by Generalkidd (https://github.com/Generalkidd/H5AnimExtractor).
# Local changes are marked with 'HCE Max Toolkit:' comments.

from dataclasses import dataclass, field
import math
import struct
import uuid
from typing import Dict, List, Optional, Tuple

from .anim_codecs import (
    AnimationCodecType,
    DecodedAnimationCodec,
    Quaternion,
    SharedStaticTables,
    Vector,
    decode_animation_codec,
    normalize_quaternion,
)
from .gen5 import Gen5Container

SKELETON_NODES_GUID = uuid.UUID("a1bc3ec9-454c-a8a1-2d3f-898c6813ac2c")
ANIMATION_POOL_GUID = uuid.UUID("ab063e74-4df5-2d12-ebf4-c79f389b6a6b")
ADDITIONAL_NODE_DATA_GUID = uuid.UUID("29a1dd97-48f7-bb89-f9a4-06b6908c72a4")
RESOURCE_GROUPS_GUID = uuid.UUID("47846c50-4af5-26c7-72ed-bd8cf6582497")
SHARED_ROTATIONS_GUID = uuid.UUID("be3bf367-471c-8e12-7493-c18af0dc0c92")
SHARED_TRANSLATIONS_GUID = uuid.UUID("85720f55-4d8e-59dd-7836-ac9072b48b29")
SHARED_SCALES_GUID = uuid.UUID("4269c493-4440-5227-b584-40a1261daa31")
COMPOSITES_GUID = uuid.UUID("ce71bb1a-45ed-50ab-74c8-c79064f67f04")


@dataclass
class SkeletonNode:
    index: int
    name_hash: int
    name: str
    parent_index: int
    rest_translation: Vector = field(default_factory=lambda: Vector((0.0, 0.0, 0.0)))
    rest_rotation: Quaternion = field(default_factory=lambda: Quaternion((1.0, 0.0, 0.0, 0.0)))
    rest_scale: Vector = field(default_factory=lambda: Vector((1.0, 1.0, 1.0)))


@dataclass
class AnimationMetadata:
    index: int
    name_hash: int
    name: str
    frame_count: int
    node_count: int
    animation_type: int  # 1=Base, 2=Overlay, 3=Replacement
    frame_info_type: int
    parent_animation_index: int
    resource_group_index: int
    resource_member_index: int
    # Gen5 user/playback flags (word at 0x0A in the animation-pool record).
    user_flags: int = 0
    frames_per_second: float = 30.0
    # Gen5 stores the composite reference as a short block index at 0x22.  Ordinary
    # animation records contain -1 here; a non-negative value identifies a composite
    # definition in the graph's definitions data.
    composite_index: int = -1


@dataclass
class AnimationResourceGroup:
    index: int
    group_id: int
    resource_file_index: int


@dataclass
class CompositeAxis:
    name: str
    animation_bounds: Tuple[float, float]
    input_bounds: Tuple[float, float]
    blend_limit: float
    clamped: bool
    adjustment: str
    dead_zones: List[Tuple[float, float, float]] = field(default_factory=list)


@dataclass
class CompositeLeaf:
    animation_index: int
    axis_values: List[float] = field(default_factory=list)


@dataclass
class CompositeDefinition:
    index: int
    timing_animation_index: int
    axes: List[CompositeAxis] = field(default_factory=list)
    leaves: List[CompositeLeaf] = field(default_factory=list)

    # Compatibility accessors for the existing import path.
    @property
    def axis_name(self) -> str:
        return self.axes[0].name if self.axes else "movement_speed"

    @property
    def leaf_animation_indices(self) -> List[int]:
        return [leaf.animation_index for leaf in self.leaves]


@dataclass
class Halo5AnimationGraph:
    file_path: str
    nodes: List[SkeletonNode]
    animations: List[AnimationMetadata]
    resource_groups: List[AnimationResourceGroup]
    shared_tables: SharedStaticTables
    composites: List[CompositeDefinition] = field(default_factory=list)
    # Alternate mode/state paths that reference each physical animation. These
    # become Foundry "Renames" rather than duplicate Actions.
    renames_by_animation_index: Dict[int, List[str]] = field(default_factory=dict)
    # The complete game-facing mode paths.  The animation pool only contains
    # physical clips, while the mode graph supplies the action/overlay names
    # that reference them.  Keeping both forms lets the importer use the same
    # base-pose candidate search as Foundry.
    mode_paths_by_animation_index: Dict[int, List[str]] = field(default_factory=dict)
    # Only paths from a set's ``actions`` block (not ``overlay_animations``).
    # Foundry looks for an overlay reference frame in this base-action map.
    mode_action_paths_by_animation_index: Dict[int, List[str]] = field(default_factory=dict)


@dataclass
class PackedAnimationResource:
    file_path: str
    member_index: int
    frame_count: int
    node_count: int
    movement_type: int
    static_data_size: int
    compressed_data_size: int
    static_node_flags_size: int
    animated_node_flags_size: int
    movement_data_size: int
    shared_static_data_size: int
    animation_data: bytes


@dataclass
class AnimationClip:
    source_animation_index: int
    name: str
    frames_per_second: float
    frame_count: int
    animation_type: int
    frame_info_type: int
    parent_animation_index: int
    root_motion_baked: bool
    translations: List[List[Vector]]  # [node_index][frame_index]
    rotations: List[List[Quaternion]]  # [node_index][frame_index]
    scales: List[List[Vector]]  # [node_index][frame_index]
    # True where the animation actually carries data for the node. Everything else is just the
    # rest pose echoed back, which matters for overlays: they only touch a handful of bones.
    tracked_nodes: List[bool] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)


class Halo5AnimationReader:
    """Reads Halo 5 animation graphs and resource tags."""

    @staticmethod
    def read_graph(file_path: str) -> Halo5AnimationGraph:
        container = Gen5Container.open(file_path)

        # 1. Skeleton nodes
        s_struct = container.find_structure(SKELETON_NODES_GUID)
        if not s_struct or s_struct.target_index < 0:
            raise ValueError(f"Graph '{file_path}' has no skeleton nodes block")
        s_data = container.get_block(s_struct.target_index)
        stride = 0x28
        node_count = len(s_data) // stride
        nodes: List[SkeletonNode] = []
        for i in range(node_count):
            item = s_data[i * stride : (i + 1) * stride]
            name_hash = struct.unpack("<I", item[0:4])[0]
            parent_idx = struct.unpack("<h", item[8:10])[0]
            name = container.resolve_string(name_hash, f"bone_{i:03d}")
            nodes.append(SkeletonNode(index=i, name_hash=name_hash, name=name, parent_index=parent_idx))

        # 2. Animations pool
        a_struct = container.find_structure(ANIMATION_POOL_GUID)
        if not a_struct or a_struct.target_index < 0:
            raise ValueError(f"Graph '{file_path}' has no animation pool block")
        a_data = container.get_block(a_struct.target_index)
        stride = 0x5C
        anim_count = len(a_data) // stride
        animations: List[AnimationMetadata] = []
        for i in range(anim_count):
            item = a_data[i * stride : (i + 1) * stride]
            name_hash = struct.unpack("<I", item[0:4])[0]
            frame_cnt = max(1, struct.unpack("<H", item[4:6])[0])
            node_cnt = item[6]
            anim_type = item[7]
            info_type = item[8]
            user_flags = struct.unpack_from("<H", item, 10)[0]
            parent_anim_idx = struct.unpack("<h", item[12:14])[0]
            composite_idx = struct.unpack("<h", item[34:36])[0]
            res_grp_idx = struct.unpack("<h", item[84:86])[0]
            res_mem_idx = struct.unpack("<h", item[86:88])[0]
            name = container.resolve_string(name_hash, f"animation_{i:04d}")
            animations.append(
                AnimationMetadata(
                    index=i,
                    name_hash=name_hash,
                    name=name,
                    frame_count=frame_cnt,
                    node_count=node_cnt,
                    animation_type=anim_type,
                    frame_info_type=info_type,
                    parent_animation_index=parent_anim_idx,
                    resource_group_index=res_grp_idx,
                    resource_member_index=res_mem_idx,
                    user_flags=user_flags,
                    composite_index=composite_idx,
                )
            )

        # 3. Resource groups
        resource_groups: List[AnimationResourceGroup] = []
        rg_struct = container.find_structure(RESOURCE_GROUPS_GUID)
        if rg_struct and rg_struct.target_index >= 0:
            rg_data = container.get_block(rg_struct.target_index)
            stride = 0x14
            for i in range(len(rg_data) // stride):
                item = rg_data[i * stride : (i + 1) * stride]
                gid = struct.unpack_from("<i", item, 0)[0]
                rf_idx = struct.unpack_from("<i", item, 16)[0]
                resource_groups.append(AnimationResourceGroup(index=i, group_id=gid, resource_file_index=rf_idx))

        # 3b. Gen5 composites. Each definition is 124 bytes. Its axes block
        # contains 76-byte records and its shared leaf block has 40-byte
        # records. Each leaf record points to a float block with one blend
        # value per axis.
        composites: List[CompositeDefinition] = []
        c_struct = container.find_structure(COMPOSITES_GUID)
        if c_struct and c_struct.target_index >= 0:
            c_data = container.get_block(c_struct.target_index)
            c_children = {
                s.field_offset: s.target_index for s in container.structures
                if s.field_block == c_struct.target_index and s.target_index >= 0
            }
            children_by_parent: Dict[int, Dict[int, int]] = {}
            for structure in container.structures:
                if structure.target_index >= 0:
                    children_by_parent.setdefault(structure.field_block, {})[structure.field_offset] = structure.target_index
            for i in range(len(c_data) // 124):
                record = c_data[i * 124 : (i + 1) * 124]
                timing_index = struct.unpack_from("<h", record, 120)[0]
                base_offset = i * 124
                axes: List[CompositeAxis] = []
                leaves: List[CompositeLeaf] = []
                axis_block = c_children.get(base_offset + 4, -1)
                leaf_block = c_children.get(base_offset + 32, -1)
                if axis_block >= 0:
                    axis_data = container.get_block(axis_block)
                    axis_children = children_by_parent.get(axis_block, {})
                    for axis_offset in range(0, len(axis_data) - 75, 76):
                        axis = axis_data[axis_offset : axis_offset + 76]
                        name = container.resolve_string(struct.unpack_from("<I", axis, 0)[0], "movement_speed")
                        adjustment = container.resolve_string(struct.unpack_from("<I", axis, 4)[0], "none")
                        dead_zones: List[Tuple[float, float, float]] = []
                        dead_zone_block = axis_children.get(axis_offset + 40, -1)
                        if dead_zone_block >= 0:
                            dead_zone_data = container.get_block(dead_zone_block)
                            # H5 dead-zone entries are 28 bytes. The first
                            # three floats are normalized bounds and rate;
                            # the remaining fields are runtime data that H4
                            # Foundry does not expose. Reading every 12 bytes
                            # incorrectly split each entry into extra zones.
                            for zone_offset in range(0, len(dead_zone_data) - 27, 28):
                                dead_zones.append(struct.unpack_from("<fff", dead_zone_data, zone_offset))
                        axes.append(CompositeAxis(
                            name=name,
                            animation_bounds=struct.unpack_from("<ff", axis, 12),
                            input_bounds=struct.unpack_from("<ff", axis, 20),
                            blend_limit=struct.unpack_from("<f", axis, 28)[0],
                            clamped=bool(struct.unpack_from("<I", axis, 32)[0] & 1),
                            adjustment=adjustment,
                            dead_zones=dead_zones,
                        ))
                if leaf_block >= 0:
                    leaf_data = container.get_block(leaf_block)
                    leaf_children = children_by_parent.get(leaf_block, {})
                    for offset in range(0, len(leaf_data) - 39, 40):
                        leaf_index = struct.unpack_from("<h", leaf_data, offset + 36)[0]
                        if 0 <= leaf_index < len(animations):
                            values_block = leaf_children.get(offset + 4, -1)
                            values = []
                            if values_block >= 0:
                                values_data = container.get_block(values_block)
                                values = [struct.unpack_from("<f", values_data, value_offset)[0]
                                          for value_offset in range(0, len(values_data) - 3, 4)]
                            leaves.append(CompositeLeaf(leaf_index, values))
                composites.append(CompositeDefinition(i, timing_index, axes, leaves))

        # 3c. Mode/state graph. The pool stores each physical animation once;
        # this hierarchy supplies the game-facing names that Foundry exports as
        # renames. Offsets are the Gen5 modes -> weapon classes -> weapon
        # types -> sets -> actions layout.
        renames_by_animation_index: Dict[int, List[str]] = {}
        mode_paths_by_animation_index: Dict[int, List[str]] = {}
        mode_action_paths_by_animation_index: Dict[int, List[str]] = {}
        mode_struct = next((
            s for s in container.structures
            if s.guid == uuid.UUID("8d89d744-433c-83e7-a643-2ab9e4433e06")
        ), None)
        if mode_struct and mode_struct.target_index >= 0:
            child_targets: Dict[int, Dict[int, int]] = {}
            for child in container.structures:
                if child.target_index >= 0:
                    child_targets.setdefault(child.field_block, {})[child.field_offset] = child.target_index

            def child_block(parent: int, field: int) -> int:
                return child_targets.get(parent, {}).get(field, -1)

            def string_at(data: bytes, offset: int) -> str:
                if offset + 4 > len(data):
                    return ""
                return container.resolve_string(struct.unpack_from("<I", data, offset)[0], "")

            paths_by_animation: Dict[int, List[str]] = {}
            action_paths_by_animation: Dict[int, List[str]] = {}

            def add_paths(actions_block: int, prefix: List[str], is_base_action: bool = False) -> None:
                if actions_block < 0:
                    return
                data = container.get_block(actions_block)
                # Action/overlay records are 12 bytes: name StringId at 0 and
                # animation-pool index at 10. -1 means no action is assigned.
                for offset in range(0, len(data) - 11, 12):
                    state = string_at(data, offset)
                    animation_index = struct.unpack_from("<h", data, offset + 10)[0]
                    if state and 0 <= animation_index < len(animations):
                        path = ":".join(prefix + [state])
                        paths_by_animation.setdefault(animation_index, []).append(path)
                        if is_base_action:
                            action_paths_by_animation.setdefault(animation_index, []).append(path)

            modes_data = container.get_block(mode_struct.target_index)
            for mode_offset in range(0, len(modes_data) - 67, 68):
                mode_name = string_at(modes_data, mode_offset)
                classes_block = child_block(mode_struct.target_index, mode_offset + 12)
                if not mode_name or classes_block < 0:
                    continue
                classes_data = container.get_block(classes_block)
                for class_offset in range(0, len(classes_data) - 119, 120):
                    class_name = string_at(classes_data, class_offset)
                    types_block = child_block(classes_block, class_offset + 8)
                    if not class_name or types_block < 0:
                        continue
                    types_data = container.get_block(types_block)
                    for type_offset in range(0, len(types_data) - 35, 36):
                        type_name = string_at(types_data, type_offset)
                        sets_block = child_block(types_block, type_offset + 8)
                        if not type_name or sets_block < 0:
                            continue
                        sets_data = container.get_block(sets_block)
                        for set_offset in range(0, len(sets_data) - 151, 152):
                            set_name = string_at(sets_data, set_offset)
                            if not set_name:
                                continue
                            prefix = [mode_name, class_name, type_name, set_name]
                            add_paths(child_block(sets_block, set_offset + 8), prefix, is_base_action=True)
                            add_paths(child_block(sets_block, set_offset + 36), prefix)

            def normalized_path(path: str) -> str:
                tokens = [token for token in path.replace(" ", ":").split(":") if token]
                tokens = [token for token in tokens if not (token.startswith("var") and token[3:].isdigit())]
                if not tokens:
                    return ""
                # Match Foundry's minimal_path(): mode defaults are trailing
                # "any" tokens in the path head, never part of the exported
                # rename itself. Transition paths preserve their final four
                # tokens, including the special `2` separator.
                if len(tokens) >= 5 and tokens[-3] == "2":
                    head, tail = tokens[:-4], tokens[-4:]
                else:
                    head, tail = tokens[:-1], tokens[-1:]
                while head and head[-1] == "any":
                    head.pop()
                return ":".join(head + tail)

            for animation_index, paths in paths_by_animation.items():
                if len(paths) < 2:
                    continue
                source_name = normalized_path(animations[animation_index].name)
                renames = sorted({normalized_path(path) for path in paths if normalized_path(path) and normalized_path(path) != source_name})
                if renames:
                    renames_by_animation_index[animation_index] = renames

            # Preserve tag traversal order: Foundry considers the first valid
            # candidate first, so alphabetical sorting here could subtly pick a
            # different base pose where multiple variants are valid.
            mode_paths_by_animation_index = {
                index: list(dict.fromkeys(paths)) for index, paths in paths_by_animation.items()
            }
            mode_action_paths_by_animation_index = {
                index: list(dict.fromkeys(paths)) for index, paths in action_paths_by_animation.items()
            }

        # 4. Shared static tables
        rotations = []
        r_struct = container.find_structure(SHARED_ROTATIONS_GUID)
        if r_struct and r_struct.target_index >= 0:
            r_data = container.get_block(r_struct.target_index)
            for offset in range(0, len(r_data), 8):
                i, j, k, w = struct.unpack_from("<hhhh", r_data, offset)
                rotations.append((i, j, k, w))

        translations = []
        t_struct = container.find_structure(SHARED_TRANSLATIONS_GUID)
        if t_struct and t_struct.target_index >= 0:
            t_data = container.get_block(t_struct.target_index)
            for offset in range(0, len(t_data), 12):
                x, y, z = struct.unpack_from("<fff", t_data, offset)
                translations.append(Vector((x, y, z)))

        scales = []
        sc_struct = container.find_structure(SHARED_SCALES_GUID)
        if sc_struct and sc_struct.target_index >= 0:
            sc_data = container.get_block(sc_struct.target_index)
            for offset in range(0, len(sc_data), 4):
                scales.append(struct.unpack_from("<f", sc_data, offset)[0])

        shared_tables = SharedStaticTables(rotations, translations, scales)

        # 5. Additional node data (rest pose override)
        add_struct = container.find_structure(ADDITIONAL_NODE_DATA_GUID)
        if add_struct and add_struct.target_index >= 0:
            add_data = container.get_block(add_struct.target_index)
            stride = 0x3C  # 60 bytes
            by_hash = {node.name_hash: node for node in nodes}
            for offset in range(0, len(add_data), stride):
                item = add_data[offset : offset + stride]
                if len(item) < stride:
                    break  # Guard against truncated buffers

                h = struct.unpack("<I", item[0:4])[0]
                if h in by_hash:
                    node = by_hash[h]
                    qx, qy, qz, qw = struct.unpack("<ffff", item[4:20])
                    tx, ty, tz = struct.unpack("<fff", item[20:32])
                    sc = struct.unpack("<f", item[32:36])[0]
                    node.rest_rotation = normalize_quaternion(Quaternion((qw, qx, qy, qz)))
                    node.rest_translation = Vector((tx, ty, tz))
                    if math.isfinite(sc) and abs(sc) > 1e-8:
                        node.rest_scale = Vector((sc, sc, sc))

        return Halo5AnimationGraph(
            file_path=file_path,
            nodes=nodes,
            animations=animations,
            resource_groups=resource_groups,
            shared_tables=shared_tables,
            composites=composites,
            renames_by_animation_index=renames_by_animation_index,
            mode_paths_by_animation_index=mode_paths_by_animation_index,
            mode_action_paths_by_animation_index=mode_action_paths_by_animation_index,
        )

    @staticmethod
    def locate_resource_file(graph: Halo5AnimationGraph, animation: AnimationMetadata) -> Optional[str]:
        import os
        if animation.resource_group_index < 0 or animation.resource_group_index >= len(graph.resource_groups):
            return None
        grp = graph.resource_groups[animation.resource_group_index]
        # The group's own index selects the sidecar file. Deliberately no fallback: serving a
        # different resource file would decode cleanly and produce a completely wrong animation.
        path = f"{graph.file_path}[{grp.index}_tag_resource]"
        return path if os.path.isfile(path) else None

    @staticmethod
    def read_resources(file_path: str) -> List[PackedAnimationResource]:
        container = Gen5Container.open(file_path)
        main_struct = next((s for s in container.structures if s.type == 0 and s.target_index >= 0), None)
        if not main_struct:
            raise ValueError(f"Resource tag '{file_path}' has no main structure")

        mem_struct = next(
            (s for s in container.structures if s.target_index >= 0 and s.field_block == main_struct.target_index and s.target_index != main_struct.target_index),
            None,
        )
        if not mem_struct:
            raise ValueError(f"Resource tag '{file_path}' has no member structure")

        mem_data = container.get_block(mem_struct.target_index)
        stride = 0x1C0
        actual_count = len(mem_data) // stride

        resources = []
        for i in range(actual_count):
            item = mem_data[i * stride : (i + 1) * stride]
            field_off = i * stride + 0x1A4
            dref = next((r for r in container.data_references if r.field_block == mem_struct.target_index and r.field_offset == field_off), None)

            sizes = [struct.unpack("<i", item[0x15C + j * 4 : 0x160 + j * 4])[0] for j in range(18)]
            anim_data = container.get_block(dref.target_index) if (dref and dref.target_index >= 0) else b""

            frame_cnt = max(1, struct.unpack("<H", item[8:10])[0])
            node_cnt = item[10]
            move_type = item[11]

            resources.append(
                PackedAnimationResource(
                    file_path=file_path,
                    member_index=i,
                    frame_count=frame_cnt,
                    node_count=node_cnt,
                    movement_type=move_type,
                    static_data_size=sizes[0],
                    compressed_data_size=sizes[1],
                    static_node_flags_size=sizes[2],
                    animated_node_flags_size=sizes[3],
                    movement_data_size=sizes[4],
                    shared_static_data_size=sizes[17],
                    animation_data=anim_data,
                )
            )
        return resources


class AnimationAssembler:
    """Assembles raw animation codec tracks into full skeletal node animations."""

    @staticmethod
    def assemble(
        graph: Halo5AnimationGraph,
        metadata: AnimationMetadata,
        packed: PackedAnimationResource,
        fps_override: Optional[float] = None,
        bake_root_motion: bool = True,
        parent_clip: Optional[AnimationClip] = None,
        expand_single_frame_clips: bool = False,
    ) -> AnimationClip:
        if not packed.animation_data:
            raise ValueError(f"Animation '{metadata.name}' resource has no animation data payload")

        static_codec = None
        if packed.shared_static_data_size > 0:
            off = len(packed.animation_data) - packed.shared_static_data_size
            static_codec = decode_animation_codec(packed.animation_data[off : off + packed.shared_static_data_size], packed.frame_count, graph.shared_tables)
        elif packed.static_data_size > 0:
            static_codec = decode_animation_codec(packed.animation_data[: packed.static_data_size], packed.frame_count, graph.shared_tables)

        if packed.compressed_data_size <= 0:
            raise ValueError(f"Animation '{metadata.name}' has no animated codec data")
        animated_codec = decode_animation_codec(
            packed.animation_data[packed.static_data_size : packed.static_data_size + packed.compressed_data_size], packed.frame_count, graph.shared_tables
        )

        static_flags_off = packed.static_data_size + packed.compressed_data_size
        anim_flags_off = static_flags_off + packed.static_node_flags_size
        movement_off = anim_flags_off + packed.animated_node_flags_size

        static_flags = AnimationAssembler._read_flags(packed.animation_data, static_flags_off, packed.static_node_flags_size, packed.node_count)
        animated_flags = AnimationAssembler._read_flags(packed.animation_data, anim_flags_off, packed.animated_node_flags_size, packed.node_count)

        translations = [[Vector() for _ in range(packed.frame_count)] for _ in range(len(graph.nodes))]
        rotations = [[Quaternion() for _ in range(packed.frame_count)] for _ in range(len(graph.nodes))]
        scales = [[Vector((1.0, 1.0, 1.0)) for _ in range(packed.frame_count)] for _ in range(len(graph.nodes))]

        static_track = [0, 0, 0]
        anim_track = [0, 0, 0]
        tracked_nodes = [False] * len(graph.nodes)

        for node_idx, node in enumerate(graph.nodes):
            if node_idx < packed.node_count:
                tracked_nodes[node_idx] = any(
                    static_flags[comp][node_idx] or animated_flags[comp][node_idx] for comp in range(3)
                )
            use_parent = metadata.animation_type in (2, 3) and parent_clip is not None
            ref_rot = parent_clip.rotations[node_idx][0] if (use_parent and node_idx < len(parent_clip.rotations)) else node.rest_rotation
            ref_trans = parent_clip.translations[node_idx][0] if (use_parent and node_idx < len(parent_clip.translations)) else node.rest_translation
            ref_scale = parent_clip.scales[node_idx][0].x if (use_parent and node_idx < len(parent_clip.scales)) else node.rest_scale.x

            for frame in range(packed.frame_count):
                if node_idx < packed.node_count and static_flags[0][node_idx]:
                    rot = AnimationAssembler._sample_rot(static_codec, static_track[0], frame)
                elif node_idx < packed.node_count and animated_flags[0][node_idx]:
                    rot = AnimationAssembler._sample_rot(animated_codec, anim_track[0], frame)
                else:
                    rot = ref_rot.copy()

                if node_idx < packed.node_count and static_flags[1][node_idx]:
                    trans = AnimationAssembler._sample_trans(static_codec, static_track[1], frame)
                elif node_idx < packed.node_count and animated_flags[1][node_idx]:
                    trans = AnimationAssembler._sample_trans(animated_codec, anim_track[1], frame)
                else:
                    trans = ref_trans.copy()

                if node_idx < packed.node_count and static_flags[2][node_idx]:
                    sc = AnimationAssembler._sample_scale(static_codec, static_track[2], frame)
                elif node_idx < packed.node_count and animated_flags[2][node_idx]:
                    sc = AnimationAssembler._sample_scale(animated_codec, anim_track[2], frame)
                else:
                    sc = ref_scale

                if metadata.animation_type == 2:  # Overlay delta composition
                    if node_idx < packed.node_count and (static_flags[0][node_idx] or animated_flags[0][node_idx]):
                        # `@`, not `*`: mathutils composes rotations with @ and multiplies
                        # component-wise with *, which silently produces near-identity garbage.
                        rot = normalize_quaternion(ref_rot @ rot)
                    if node_idx < packed.node_count and (static_flags[1][node_idx] or animated_flags[1][node_idx]):
                        trans = ref_trans + trans
                    if node_idx < packed.node_count and (static_flags[2][node_idx] or animated_flags[2][node_idx]):
                        sc = ref_scale * sc

                rotations[node_idx][frame] = normalize_quaternion(rot)
                translations[node_idx][frame] = trans
                scales[node_idx][frame] = Vector((sc, sc, sc))

            for comp in range(3):
                if node_idx < packed.node_count and static_flags[comp][node_idx]:
                    static_track[comp] += 1
                if node_idx < packed.node_count and animated_flags[comp][node_idx]:
                    anim_track[comp] += 1

        clip = AnimationClip(
            source_animation_index=metadata.index,
            name=metadata.name,
            frames_per_second=fps_override or metadata.frames_per_second,
            frame_count=packed.frame_count,
            animation_type=metadata.animation_type,
            frame_info_type=metadata.frame_info_type,
            parent_animation_index=metadata.parent_animation_index,
            root_motion_baked=bake_root_motion and packed.movement_data_size > 0 and packed.movement_type in (1, 2, 3, 4, 5),
            translations=translations,
            rotations=rotations,
            scales=scales,
            tracked_nodes=tracked_nodes,
        )

        if metadata.animation_type == 2:
            # H4 overlay resources are authored as deltas from a reference
            # pose. Foundry imports them with an explicit frame-zero base pose,
            # then the overlay samples begin at frame one. Without this frame
            # Tool sees sparse channels and lets feet/untracked bones drift.
            for node_idx, node in enumerate(graph.nodes):
                if parent_clip is not None and node_idx < len(parent_clip.rotations):
                    base_rotation = parent_clip.rotations[node_idx][0].copy()
                    base_translation = parent_clip.translations[node_idx][0].copy()
                    base_scale = parent_clip.scales[node_idx][0].copy()
                else:
                    base_rotation = node.rest_rotation.copy()
                    base_translation = node.rest_translation.copy()
                    base_scale = node.rest_scale.copy()
                clip.rotations[node_idx].insert(0, base_rotation)
                clip.translations[node_idx].insert(0, base_translation)
                clip.scales[node_idx].insert(0, base_scale)
            clip.frame_count += 1

        if bake_root_motion and packed.movement_data_size > 0:
            AnimationAssembler._bake_root_motion(clip, graph, packed, movement_off)

        # Foundry's Halo 4 exporter discards an animation's final authored
        # sample. A one-sample H5 clip would therefore become a zero-frame
        # animation on export. Duplicate its sole final transform so Blender
        # and Foundry see a two-frame static clip; no animation data is
        # changed, only a matching terminal sample is added.
        if expand_single_frame_clips and clip.frame_count == 1:
            for node_idx in range(len(clip.rotations)):
                clip.rotations[node_idx].append(clip.rotations[node_idx][-1].copy())
                clip.translations[node_idx].append(clip.translations[node_idx][-1].copy())
                clip.scales[node_idx].append(clip.scales[node_idx][-1].copy())
            clip.frame_count = 2
            clip.warnings.append("expanded one-frame clip to two identical frames for Foundry export")

        return clip

    @staticmethod
    def _read_flags(data: bytes, offset: int, byte_cnt: int, node_cnt: int) -> List[List[bool]]:
        res = [[False] * node_cnt, [False] * node_cnt, [False] * node_cnt]
        if byte_cnt == 0:
            return res
        bytes_per_comp = byte_cnt // 3
        for comp in range(3):
            comp_off = offset + comp * bytes_per_comp
            for node in range(node_cnt):
                word_off = comp_off + (node // 32) * 4
                word = struct.unpack_from("<I", data, word_off)[0]
                res[comp][node] = (word & (1 << (node & 31))) != 0
        return res

    @staticmethod
    def _sample_rot(codec: DecodedAnimationCodec, track: int, frame: int) -> Quaternion:
        vals = codec.rotations[track]
        keys = codec.rotation_keyframes[track]
        if not vals:
            return Quaternion((1.0, 0.0, 0.0, 0.0))
        if len(vals) == 1 or frame <= keys[0]:
            return vals[0].copy()
        if frame >= keys[-1]:
            return vals[-1].copy()

        # Lerp/Slerp between keyframes
        left = 0
        for i, k in enumerate(keys):
            if k <= frame:
                left = i
            else:
                break
        right = min(left + 1, len(keys) - 1)
        if left == right:
            return vals[left].copy()

        amount = (frame - keys[left]) / float(keys[right] - keys[left])
        q1, q2 = vals[left], vals[right]
        # Simple Slerp for Quaternion
        dot = q1.dot(q2)
        if dot < 0.0:
            q2 = q2.copy()
            q2.negate()
            dot = -dot

        if dot > 0.9995:
            # Linear interpolation
            res = Quaternion((
                q1.w + amount * (q2.w - q1.w),
                q1.x + amount * (q2.x - q1.x),
                q1.y + amount * (q2.y - q1.y),
                q1.z + amount * (q2.z - q1.z),
            ))
        else:
            theta_0 = math.acos(max(-1.0, min(1.0, dot)))
            theta = theta_0 * amount
            sin_theta = math.sin(theta)
            sin_theta_0 = math.sin(theta_0)
            s0 = math.cos(theta) - dot * sin_theta / sin_theta_0
            s1 = sin_theta / sin_theta_0
            res = Quaternion((
                s0 * q1.w + s1 * q2.w,
                s0 * q1.x + s1 * q2.x,
                s0 * q1.y + s1 * q2.y,
                s0 * q1.z + s1 * q2.z,
            ))
        return normalize_quaternion(res)

    @staticmethod
    def _sample_trans(codec: DecodedAnimationCodec, track: int, frame: int) -> Vector:
        vals = codec.translations[track]
        keys = codec.translation_keyframes[track]
        if not vals:
            return Vector((0.0, 0.0, 0.0))
        if len(vals) == 1 or frame <= keys[0]:
            v = vals[0]
        elif frame >= keys[-1]:
            v = vals[-1]
        else:
            left = 0
            for i, k in enumerate(keys):
                if k <= frame:
                    left = i
                else:
                    break
            right = min(left + 1, len(keys) - 1)
            amount = (frame - keys[left]) / float(max(1, keys[right] - keys[left]))
            v1, v2 = vals[left], vals[right]
            v = Vector((v1.x + amount * (v2.x - v1.x), v1.y + amount * (v2.y - v1.y), v1.z + amount * (v2.z - v1.z)))

        # Convert JMA 100x scale to Halo world units unless codec 10 (RevisedCurve)
        scale_factor = 1.0 if codec.metadata.codec == AnimationCodecType.REVISED_CURVE else 0.01
        return v * scale_factor

    @staticmethod
    def _sample_scale(codec: DecodedAnimationCodec, track: int, frame: int) -> float:
        vals = codec.scales[track]
        keys = codec.scale_keyframes[track]
        if not vals:
            return 1.0
        if len(vals) == 1 or frame <= keys[0]:
            return vals[0]
        if frame >= keys[-1]:
            return vals[-1]
        left = 0
        for i, k in enumerate(keys):
            if k <= frame:
                left = i
            else:
                break
        right = min(left + 1, len(keys) - 1)
        amount = (frame - keys[left]) / float(max(1, keys[right] - keys[left]))
        return vals[left] + amount * (vals[right] - vals[left])

    @staticmethod
    def _bake_root_motion(clip: AnimationClip, graph: Halo5AnimationGraph, packed: PackedAnimationResource, movement_off: int):
        # H5 uses node zero (the pedestal in the supplied character graphs) as
        # its movement root.  Do not choose a different parentless node here:
        # the movement records are authored for this exact transform.
        root_idx = 0
        stride = {1: 8, 2: 12, 3: 16, 4: 24, 5: 12}.get(packed.movement_type, 0)
        available_bytes = min(
            packed.movement_data_size,
            max(0, len(packed.animation_data) - movement_off),
        )
        record_count = min(clip.frame_count, available_bytes // stride) if stride else 0
        if root_idx >= len(clip.translations) or record_count <= 0:
            return

        accumulated = Vector((0.0, 0.0, 0.0))
        accumulated_rotation = Quaternion((1.0, 0.0, 0.0, 0.0))

        for frame in range(record_count):
            off = movement_off + frame * stride
            if packed.movement_type == 5:  # XYZAbsolute
                # Absolute values replace the accumulated movement value, but
                # remain an offset from the animation's authored pedestal pose.
                x, y, z = struct.unpack_from("<fff", packed.animation_data, off)
                accumulated = Vector((x, y, z))
                clip.translations[root_idx][frame] = clip.translations[root_idx][frame] + accumulated
                continue

            # Every component is a little-endian float32.  Reading dx/dy as
            # half floats consumes only half of each value and produces the
            # erratic direction changes previously seen on b_pedestal.
            dx, dy = struct.unpack_from("<ff", packed.animation_data, off)
            dz = struct.unpack_from("<f", packed.animation_data, off + 8)[0] if packed.movement_type in (3, 4) else 0.0
            local_delta = Vector((dx, dy, dz))

            # Foundry accumulates movement in animation-graph space.  The
            # coordinate conversion happens later, when the full graph-space
            # transform is converted to Blender pose space through the target
            # bone's bind-matrix inverse; do not add a separate 90-degree
            # pedestal conversion here.
            accumulated = accumulated + (accumulated_rotation @ local_delta)

            if packed.movement_type == 2:
                yaw = struct.unpack_from("<f", packed.animation_data, off + 8)[0]
                delta_rotation = Quaternion((math.cos(yaw * 0.5), 0.0, 0.0, math.sin(yaw * 0.5)))
            elif packed.movement_type == 3:
                yaw = struct.unpack_from("<f", packed.animation_data, off + 12)[0]
                delta_rotation = Quaternion((math.cos(yaw * 0.5), 0.0, 0.0, math.sin(yaw * 0.5)))
            elif packed.movement_type == 4:
                angle_axis = Vector(struct.unpack_from("<fff", packed.animation_data, off + 12))
                angle = angle_axis.length
                delta_rotation = Quaternion(angle_axis / angle, angle) if angle > 1e-8 else Quaternion((1.0, 0.0, 0.0, 0.0))
            else:
                delta_rotation = Quaternion((1.0, 0.0, 0.0, 0.0))

            clip.translations[root_idx][frame] = clip.translations[root_idx][frame] + accumulated
            accumulated_rotation = normalize_quaternion(accumulated_rotation @ delta_rotation)
            if packed.movement_type in (2, 3, 4):
                # Match Foundry's ``combined_rotation.rotate(root_rotation)``
                # ordering rather than applying a local-bone rotation here.
                combined_rotation = accumulated_rotation.copy()
                combined_rotation.rotate(clip.rotations[root_idx][frame])
                clip.rotations[root_idx][frame] = normalize_quaternion(combined_rotation)
