"""Halo 5 model_animation_graph -> Halo CE JMA-family text files.

Called from 3ds Max (engine/tool_h5_animations.ms) through pymxs, or from a shell:

    python -I convert.py <graph> "<render_model>|<render_model>" <out_dir> [--scale 100] [--no-root-motion] [--conjugate]

Halo 5 graphs carry no rest pose, so the render model(s) that own the graph's nodes supply it
(a first person graph needs the arms render model and the weapon render model). Everything is
written in the toolkit's existing JMA 16392 layout, so the existing JMA importer applies it.
"""

import math
import os
import sys
import traceback

if __name__ == "__main__" and not __package__:
    # Running as a script: make the package importable so the relative imports below resolve.
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    import halo5  # noqa: F401

    __package__ = "halo5"

from typing import Dict, List, Optional, Tuple

from .anim_codecs import Quaternion, Vector
from .assembler import Halo5AnimationGraph, Halo5AnimationReader
from .overlay_base import ClipResolver
from .render_model import read_render_model_nodes

JMA_VERSION = 16392
MANIFEST_NAME = "_h5_manifest.tsv"
MANIFEST_VERSION = 1
FRAME_RATE = 30
INVALID_FILENAME_CHARS = '<>"/\\|?*'

# Pool record movement type -> JMA-family extension for base animations.
BASE_EXTENSION_BY_MOVEMENT = {0: ".JMM", 1: ".JMA", 2: ".JMT", 3: ".JMZ", 4: ".JMZ", 5: ".JMZ"}
TYPE_NAMES = {0: "none", 1: "base", 2: "overlay", 3: "replacement"}


def _fmt(value: float) -> str:
    text = f"{value:.6f}"
    return "0.000000" if text == "-0.000000" else text


def _quat_matrix(x: float, y: float, z: float, w: float) -> List[List[float]]:
    """Standard (column-vector) rotation matrix of a unit quaternion."""
    return [
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ]


def _mat_mul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]


def _mat_vec(a, v):
    return [sum(a[i][k] * v[k] for k in range(3)) for i in range(3)]


def _safe_filename(name: str) -> str:
    text = name.replace(":", " ")
    for ch in INVALID_FILENAME_CHARS:
        text = text.replace(ch, "_")
    return text.strip() or "unnamed"


def _hierarchy_links(parents: List[int]) -> Tuple[List[int], List[int]]:
    """First child / next sibling indices (0-based, -1 = none) from parent indices."""
    count = len(parents)
    first_child = [-1] * count
    next_sibling = [-1] * count
    last_child: Dict[int, int] = {}
    for index, parent in enumerate(parents):
        if 0 <= parent < count:
            if first_child[parent] < 0:
                first_child[parent] = index
            else:
                next_sibling[last_child[parent]] = index
            last_child[parent] = index
    # Roots are chained as siblings of the first root, as the JMA/JMS layout expects.
    roots = [index for index, parent in enumerate(parents) if not 0 <= parent < count]
    for current, following in zip(roots, roots[1:]):
        next_sibling[current] = following
    return first_child, next_sibling


def seed_rest_pose(graph: Halo5AnimationGraph, render_model_paths: List[str]) -> List[str]:
    """Copies node rest transforms from the render model(s) into the graph. Returns missing node names."""
    rest: Dict[str, object] = {}
    for path in render_model_paths:
        for node in read_render_model_nodes(path):
            rest.setdefault(node.name, node)  # the first render model listed wins

    missing: List[str] = []
    for node in graph.nodes:
        source = rest.get(node.name)
        if source is None:
            missing.append(node.name)
            continue
        x, y, z, w = source.rotation
        rotation = Quaternion((w, x, y, z))
        rotation.normalize()
        if rotation.w < 0.0:
            rotation.negate()
        scale = source.scale if math.isfinite(source.scale) and abs(source.scale) > 1e-8 else 1.0
        node.rest_translation = Vector(source.translation)
        node.rest_rotation = rotation
        node.rest_scale = Vector((scale, scale, scale))
    return missing


def rest_world_transforms(graph: Halo5AnimationGraph):
    """World (rotation matrix, position) of every node in its rest pose, in world units."""
    world = []
    for node in graph.nodes:
        q = node.rest_rotation
        local_rot = _quat_matrix(q.x, q.y, q.z, q.w)
        local_pos = [node.rest_translation.x, node.rest_translation.y, node.rest_translation.z]
        parent = node.parent_index
        if 0 <= parent < len(world):
            parent_rot, parent_pos = world[parent]
            rotation = _mat_mul(parent_rot, local_rot)
            position = [a + b for a, b in zip(parent_pos, _mat_vec(parent_rot, local_pos))]
        else:
            rotation, position = local_rot, local_pos
        world.append((rotation, position))
    return world


def write_skeleton_tsv(path: str, graph: Halo5AnimationGraph, unit_scale: float) -> None:
    """Expected rest pose in world space: name, parent, position and the X/Y/Z axes.

    Axes and positions do not depend on any quaternion convention, so the 3ds Max side can
    build the skeleton from them directly and compare a scene rig against them.
    """
    lines = ["#index\tname\tparent\tpos\txaxis\tyaxis\tzaxis"]
    for node, (rotation, position) in zip(graph.nodes, rest_world_transforms(graph)):
        axes = [[rotation[0][c], rotation[1][c], rotation[2][c]] for c in range(3)]  # matrix columns
        fields = [str(node.index), node.name, str(node.parent_index)]
        fields.append(" ".join(_fmt(v * unit_scale) for v in position))
        fields.extend(" ".join(_fmt(v) for v in axis) for axis in axes)
        lines.append("\t".join(fields))
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        stream.write("\n".join(lines) + "\n")


def write_jma(path: str, graph: Halo5AnimationGraph, frames, unit_scale: float, conjugate: bool) -> None:
    """Writes a JMA 16392 file in the layout of formats/jma/process_file.ms.

    `frames` is a list of per-frame lists of (translation Vector, rotation Quaternion, scale float).
    """
    parents = [node.parent_index for node in graph.nodes]
    first_child, next_sibling = _hierarchy_links(parents)
    lines = [
        str(JMA_VERSION),
        str(len(frames)),
        str(FRAME_RATE),
        "1",
        "unnamedActor",
        str(len(graph.nodes)),
        "0",
    ]
    for index, node in enumerate(graph.nodes):
        lines.append(node.name)
        lines.append(str(first_child[index]))
        lines.append(str(next_sibling[index]))

    sign = -1.0 if conjugate else 1.0
    for frame in frames:
        for translation, rotation, scale in frame:
            lines.append(f"{_fmt(translation.x * unit_scale)}\t{_fmt(translation.y * unit_scale)}\t{_fmt(translation.z * unit_scale)}")
            lines.append(f"{_fmt(sign * rotation.x)}\t{_fmt(sign * rotation.y)}\t{_fmt(sign * rotation.z)}\t{_fmt(rotation.w)}")
            lines.append(_fmt(scale))
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        stream.write("\n".join(lines) + "\n")


def clip_frames(clip):
    node_count = len(clip.translations)
    return [
        [(clip.translations[n][f], clip.rotations[n][f], clip.scales[n][f].x) for n in range(node_count)]
        for f in range(clip.frame_count)
    ]


def rest_frames(graph: Halo5AnimationGraph, frame_count: int = 2):
    # Two identical frames: 3ds Max refuses a zero-length animation range.
    frame = [(node.rest_translation, node.rest_rotation, node.rest_scale.x) for node in graph.nodes]
    return [frame for _ in range(frame_count)]


def animation_extension(animation_type: int, movement_type: int, has_movement: bool) -> str:
    if animation_type == 2:
        return ".JMO"
    if animation_type == 3:
        return ".JMR"
    return BASE_EXTENSION_BY_MOVEMENT.get(movement_type, ".JMM") if has_movement else ".JMM"


def write_manifest(out_dir: str, graph_path: str, model_paths: List[str], unit_scale: float,
                   bake_root_motion: bool, conjugate: bool, report: List[str]) -> None:
    """Records a finished conversion so the 3ds Max tool can reload the folder without converting again.

    Same lines as the returned report, preceded by the source tags and the settings used.
    """
    lines = [
        f"#h5manifest\t{MANIFEST_VERSION}",
        f"#source\t{graph_path}",
        f"#models\t{'|'.join(model_paths)}",
        f"#settings\t{unit_scale:g}\t{int(bool(bake_root_motion))}\t{int(bool(conjugate))}",
    ] + report
    with open(os.path.join(out_dir, MANIFEST_NAME), "w", encoding="utf-8", newline="\n") as stream:
        stream.write("\n".join(lines) + "\n")


def convert_graph(
    graph_path: str,
    render_models: str,
    out_dir: str,
    unit_scale: float = 100.0,
    bake_root_motion: bool = True,
    conjugate: bool = False,
) -> str:
    """Converts every animation of a graph. Returns a tab-separated report, one record per line:

    #graph name nodes animations / #skeleton path / #rest path / #missing node / #warn text /
    #error text / anim index name type frames movement file base
    """
    report: List[str] = []
    try:
        graph_path = str(graph_path)
        out_dir = str(out_dir)
        unit_scale = float(unit_scale)
        model_paths = [p.strip() for p in str(render_models).split("|") if p.strip()]
        if not model_paths:
            return "#error\tAt least one render_model is needed: Halo 5 graphs do not store a rest pose."
        for model_path in model_paths:
            if not os.path.isfile(model_path):
                return f"#error\tRender model not found: {model_path}"

        graph = Halo5AnimationReader.read_graph(graph_path)
        graph_name = os.path.splitext(os.path.basename(graph_path))[0]
        report.append(f"#graph\t{graph_name}\t{len(graph.nodes)}\t{len(graph.animations)}")

        missing = seed_rest_pose(graph, model_paths)
        report.extend(f"#missing\t{name}" for name in missing)

        os.makedirs(out_dir, exist_ok=True)
        skeleton_path = os.path.join(out_dir, f"{graph_name}_skeleton.tsv")
        write_skeleton_tsv(skeleton_path, graph, unit_scale)
        report.append(f"#skeleton\t{skeleton_path}")

        rest_path = os.path.join(out_dir, "_rest_pose.JMM")
        write_jma(rest_path, graph, rest_frames(graph), unit_scale, conjugate)
        report.append(f"#rest\t{rest_path}")

        resolver = ClipResolver(graph, fps=FRAME_RATE, bake_root_motion=bake_root_motion, expand_single_frame_clips=True)
        used_names = set()
        for meta in graph.animations:
            try:
                packed = resolver.packed_resource(meta)
                clip = resolver.get_clip(meta.index) if packed else None
                if clip is None:
                    report.append(f"#warn\tSkipped '{meta.name}': its '[N_tag_resource]' file is missing")
                    continue
                has_movement = bake_root_motion and packed.movement_data_size > 0
                extension = animation_extension(meta.animation_type, packed.movement_type, has_movement)
                base_name = _safe_filename(meta.name)
                file_name = base_name + extension
                if file_name.lower() in used_names:
                    file_name = f"{base_name} ({meta.index}){extension}"
                used_names.add(file_name.lower())

                file_path = os.path.join(out_dir, file_name)
                write_jma(file_path, graph, clip_frames(clip), unit_scale, conjugate)

                base_index = resolver.base_index_used.get(meta.index, -1)
                base_name_used = graph.animations[base_index].name if base_index >= 0 else ""
                if meta.animation_type == 2 and not base_name_used:
                    report.append(f"#warn\tOverlay '{meta.name}' has no base pose; composed over the rest pose")
                report.append("\t".join([
                    "anim", str(meta.index), meta.name, TYPE_NAMES.get(meta.animation_type, str(meta.animation_type)),
                    str(clip.frame_count), str(packed.movement_type), file_path, base_name_used,
                ]))
            except Exception as error:  # keep converting the rest of the graph
                report.append(f"#warn\tFailed '{meta.name}': {error!r}")

        write_manifest(out_dir, graph_path, model_paths, unit_scale, bake_root_motion, conjugate, report)
    except Exception:
        report.append("#error\t" + traceback.format_exc().replace("\n", " | "))
    return "\n".join(report)


def main(argv: Optional[List[str]] = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(description="Convert a Halo 5 model_animation_graph to JMA-family files.")
    parser.add_argument("graph")
    parser.add_argument("render_models", help="render_model paths separated by '|'")
    parser.add_argument("out_dir")
    parser.add_argument("--scale", type=float, default=100.0, help="world units -> JMA units (default 100)")
    parser.add_argument("--no-root-motion", action="store_true")
    parser.add_argument("--conjugate", action="store_true", help="write conjugated quaternions")
    args = parser.parse_args(argv)
    report = convert_graph(args.graph, args.render_models, args.out_dir, args.scale, not args.no_root_motion, args.conjugate)
    print(report)
    return 1 if "#error\t" in report else 0


if __name__ == "__main__":
    sys.exit(main())
