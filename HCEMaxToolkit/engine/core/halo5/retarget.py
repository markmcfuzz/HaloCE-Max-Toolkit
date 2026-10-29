"""Retargets converted Halo 5 animations (JMA files written by convert.py) onto another skeleton.

The target skeleton is captured from the 3ds Max scene (world matrices of its nodes in their rest
pose), and a preset maps Halo 5 nodes to target nodes. Every mapped bone gets the Halo 5 bone's
world rotation times a constant offset. The offset aligns a "canonical frame" built the same way
on both skeletons (bone direction + palm normal), so the rest poses and bone axes can differ.
Optionally a two-bone IK puts the target wrists where the Halo 5 wrists are, and the Halo 5 weapon
nodes keep their placement relative to the target hand.

All math is column-vector: a transform is (R, p) with world = R * local + p.
"""

import math
import os
import re
import traceback
from typing import Dict, List, Optional, Tuple

from .convert import FRAME_RATE, JMA_VERSION, _fmt, _hierarchy_links

Mat = List[List[float]]
Vec = List[float]
Xform = Tuple[Mat, Vec]

IDENTITY: Mat = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
JMA_EXTENSIONS = (".jmm", ".jma", ".jmt", ".jmz", ".jmw", ".jmo", ".jmr")

# --------------------------------------------------------------------------------------------
# Math
# --------------------------------------------------------------------------------------------


def mmul(a: Mat, b: Mat) -> Mat:
    return [[a[i][0] * b[0][j] + a[i][1] * b[1][j] + a[i][2] * b[2][j] for j in range(3)] for i in range(3)]


def mvec(a: Mat, v: Vec) -> Vec:
    return [a[i][0] * v[0] + a[i][1] * v[1] + a[i][2] * v[2] for i in range(3)]


def transpose(a: Mat) -> Mat:
    return [[a[j][i] for j in range(3)] for i in range(3)]


def add(a: Vec, b: Vec) -> Vec:
    return [a[0] + b[0], a[1] + b[1], a[2] + b[2]]


def sub(a: Vec, b: Vec) -> Vec:
    return [a[0] - b[0], a[1] - b[1], a[2] - b[2]]


def scale(a: Vec, s: float) -> Vec:
    return [a[0] * s, a[1] * s, a[2] * s]


def dot(a: Vec, b: Vec) -> float:
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def cross(a: Vec, b: Vec) -> Vec:
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


def length(a: Vec) -> float:
    return math.sqrt(dot(a, a))


def normalize(a: Vec) -> Optional[Vec]:
    n = length(a)
    return scale(a, 1.0 / n) if n > 1e-9 else None


def compose(a: Xform, b: Xform) -> Xform:
    return mmul(a[0], b[0]), add(a[1], mvec(a[0], b[1]))


def inverse(a: Xform) -> Xform:
    rt = transpose(a[0])
    return rt, scale(mvec(rt, a[1]), -1.0)


def quat_to_mat(x: float, y: float, z: float, w: float) -> Mat:
    n = math.sqrt(x * x + y * y + z * z + w * w) or 1.0
    x, y, z, w = x / n, y / n, z / n, w / n
    return [
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ]


def mat_to_quat(r: Mat) -> Tuple[float, float, float, float]:
    """(x, y, z, w) of a rotation matrix, w >= 0."""
    trace = r[0][0] + r[1][1] + r[2][2]
    if trace > 0.0:
        s = math.sqrt(trace + 1.0) * 2.0
        w, x, y, z = 0.25 * s, (r[2][1] - r[1][2]) / s, (r[0][2] - r[2][0]) / s, (r[1][0] - r[0][1]) / s
    elif r[0][0] > r[1][1] and r[0][0] > r[2][2]:
        s = math.sqrt(1.0 + r[0][0] - r[1][1] - r[2][2]) * 2.0
        w, x, y, z = (r[2][1] - r[1][2]) / s, 0.25 * s, (r[0][1] + r[1][0]) / s, (r[0][2] + r[2][0]) / s
    elif r[1][1] > r[2][2]:
        s = math.sqrt(1.0 + r[1][1] - r[0][0] - r[2][2]) * 2.0
        w, x, y, z = (r[0][2] - r[2][0]) / s, (r[0][1] + r[1][0]) / s, 0.25 * s, (r[1][2] + r[2][1]) / s
    else:
        s = math.sqrt(1.0 + r[2][2] - r[0][0] - r[1][1]) * 2.0
        w, x, y, z = (r[1][0] - r[0][1]) / s, (r[0][2] + r[2][0]) / s, (r[1][2] + r[2][1]) / s, 0.25 * s
    n = math.sqrt(x * x + y * y + z * z + w * w) or 1.0
    if w < 0.0:
        n = -n
    return x / n, y / n, z / n, w / n


def orthonormalize(r: Mat) -> Mat:
    """Removes scale/shear from a rotation given by its columns (Gram-Schmidt on X, then Y)."""
    x = normalize([r[0][0], r[1][0], r[2][0]]) or [1.0, 0.0, 0.0]
    y = [r[0][1], r[1][1], r[2][1]]
    y = normalize(sub(y, scale(x, dot(x, y)))) or [0.0, 1.0, 0.0]
    z = cross(x, y)
    return [[x[i], y[i], z[i]] for i in range(3)]


def axis_rotation(axis: int, degrees: float) -> Mat:
    """Right-handed rotation about X (0), Y (1) or Z (2), as 3ds Max applies a positive angle."""
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    i, j = [(1, 2), (2, 0), (0, 1)][axis]
    r = [row[:] for row in IDENTITY]
    r[i][i], r[i][j], r[j][i], r[j][j] = c, -s, s, c
    return r


def rotation_between(u: Vec, v: Vec) -> Mat:
    """Smallest rotation turning unit vector u onto unit vector v."""
    axis = cross(u, v)
    s = length(axis)
    c = max(-1.0, min(1.0, dot(u, v)))
    if s < 1e-9:
        if c > 0.0:
            return [row[:] for row in IDENTITY]
        # 180 degrees about any axis perpendicular to u
        helper = [1.0, 0.0, 0.0] if abs(u[0]) < 0.9 else [0.0, 1.0, 0.0]
        axis = normalize(cross(u, helper))
        s, c = 0.0, -1.0
    else:
        axis = scale(axis, 1.0 / s)
    x, y, z = axis
    t = 1.0 - c
    return [
        [t * x * x + c, t * x * y - s * z, t * x * z + s * y],
        [t * x * y + s * z, t * y * y + c, t * y * z - s * x],
        [t * x * z - s * y, t * y * z + s * x, t * z * z + c],
    ]


def canonical_frame(aim: Optional[Vec], up: Optional[Vec]) -> Optional[Mat]:
    """Rotation whose X axis is `aim` and whose Z axis is `up` made perpendicular to it."""
    if aim is None or up is None:
        return None
    x = normalize(aim)
    if x is None:
        return None
    z = normalize(sub(up, scale(x, dot(up, x))))
    if z is None:
        return None
    y = cross(z, x)
    return [[x[i], y[i], z[i]] for i in range(3)]


# --------------------------------------------------------------------------------------------
# Files
# --------------------------------------------------------------------------------------------


def _parse_vec(text: str) -> Vec:
    return [float(v) for v in text.split()[:3]]


def read_jma(path: str, conjugate: bool):
    """Returns (node names, parent indices, frames) with frames[f][n] = local (R, p)."""
    with open(path, "r", encoding="utf-8", errors="replace") as stream:
        lines = [line.strip() for line in stream.read().split("\n")]
    frame_count = int(lines[1])
    node_count = int(lines[5])
    cursor = 7
    names, first_child, next_sibling = [], [], []
    for _ in range(node_count):
        names.append(lines[cursor])
        first_child.append(int(lines[cursor + 1]))
        next_sibling.append(int(lines[cursor + 2]))
        cursor += 3

    parents = [-1] * node_count
    for index in range(node_count):
        child = first_child[index]
        while 0 <= child < node_count and parents[child] == -1:
            parents[child] = index
            child = next_sibling[child]

    sign = -1.0 if conjugate else 1.0
    frames = []
    for _ in range(frame_count):
        frame = []
        for _ in range(node_count):
            p = _parse_vec(lines[cursor])
            q = [float(v) for v in lines[cursor + 1].split()[:4]]
            frame.append((quat_to_mat(sign * q[0], sign * q[1], sign * q[2], q[3]), p))
            cursor += 3
        frames.append(frame)
    return names, parents, frames


def write_jma(path: str, names: List[str], parents: List[int], frames, conjugate: bool) -> None:
    """frames[f][n] = local (R, p). Same layout as convert.write_jma."""
    first_child, next_sibling = _hierarchy_links(parents)
    lines = [str(JMA_VERSION), str(len(frames)), str(FRAME_RATE), "1", "unnamedActor", str(len(names)), "0"]
    for index, name in enumerate(names):
        lines += [name, str(first_child[index]), str(next_sibling[index])]
    sign = -1.0 if conjugate else 1.0
    for frame in frames:
        for rotation, position in frame:
            x, y, z, w = mat_to_quat(rotation)
            lines.append(f"{_fmt(position[0])}\t{_fmt(position[1])}\t{_fmt(position[2])}")
            lines.append(f"{_fmt(sign * x)}\t{_fmt(sign * y)}\t{_fmt(sign * z)}\t{_fmt(w)}")
            lines.append("1.000000")
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        stream.write("\n".join(lines) + "\n")


def read_skeleton_tsv(path: str) -> Dict[str, Xform]:
    """Halo 5 rest pose in world space (written by convert.write_skeleton_tsv)."""
    rest: Dict[str, Xform] = {}
    with open(path, "r", encoding="utf-8") as stream:
        for line in stream.read().splitlines():
            if not line or line.startswith("#"):
                continue
            f = line.split("\t")
            axes = [_parse_vec(a) for a in f[4:7]]
            rest[f[1]] = ([[axes[c][r] for c in range(3)] for r in range(3)], _parse_vec(f[3]))
    return rest


def _max_rows_to_xform(rows: List[Vec]) -> Xform:
    # 3ds Max matrix rows are the local axes in world space: they are the columns of R.
    return orthonormalize([[rows[c][r] for c in range(3)] for r in range(3)]), rows[3]


def read_target_tsv(path: str):
    """Target rest pose captured in 3ds Max: name, parent, 4 world rows, 4 parent world rows."""
    nodes = []
    with open(path, "r", encoding="utf-8") as stream:
        for line in stream.read().splitlines():
            if not line or line.startswith("#"):
                continue
            f = line.split("\t")
            if len(f) < 10:
                continue
            nodes.append({
                "name": f[0],
                "parent": f[1],
                "world": _max_rows_to_xform([_parse_vec(v) for v in f[2:6]]),
                "parent_world": _max_rows_to_xform([_parse_vec(v) for v in f[6:10]]),
            })
    return nodes


def read_preset(path: str) -> Dict[str, list]:
    preset = {"bone": [], "palm": [], "ik": [], "gun": [], "camera": [], "adjust": []}
    with open(path, "r", encoding="utf-8") as stream:
        for line in stream.read().splitlines():
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            # Tabs, or two or more spaces (editors often turn Tab into spaces); a single space is part of a name
            f = [field.strip() for field in re.split(r"\t| {2,}", line.strip()) if field.strip()]
            if f[0] in preset:
                preset[f[0]].append(f[1:])
    return preset


# --------------------------------------------------------------------------------------------
# Retargeting
# --------------------------------------------------------------------------------------------


class Retargeter:
    def __init__(self, src_names: List[str], src_parents: List[int], src_rest: Dict[str, Xform],
                 target_nodes, preset, use_ik: bool = True, camera_relative: bool = True,
                 shoulder_reach: float = 0.0):
        self.src_names = src_names
        self.src_parents = src_parents
        self.src_index = {name: i for i, name in enumerate(src_names)}
        self.src_rest = src_rest
        self.use_ik = use_ik
        self.shoulder_reach = max(0.0, float(shoulder_reach))
        self.residuals: Dict[str, Vec] = {}
        self.warnings: List[str] = []

        self.target = {node["name"]: node for node in target_nodes}
        self.target_order = [node["name"] for node in target_nodes]

        def resolve(names: str) -> Optional[str]:
            for name in names.split("|"):
                if name in self.target:
                    return name
            return None

        def target_parent_world(name: str) -> Xform:
            parent = self.target[name]["parent"]
            return self.target[parent]["world"] if parent in self.target else self.target[name]["parent_world"]

        # Target rest local transforms (keeps the target bone lengths)
        self.rest_local = {name: compose(inverse(target_parent_world(name)), self.target[name]["world"]) for name in self.target}

        def src_pos(name):
            return self.src_rest[name][1] if name in self.src_rest else None

        def tgt_pos(name):
            return self.target[name]["world"][1] if name in self.target else None

        # Palm normals: the shared twist reference
        palm_src: Dict[str, Vec] = {}
        palm_tgt: Dict[str, Vec] = {}
        # Grip point per side: the middle finger knuckle in hand space, on each skeleton. The hands
        # have different proportions, so the IK lines up the knuckles rather than the wrist pivots.
        grips: Dict[str, Tuple[Vec, Vec]] = {}
        for f in preset["palm"]:
            if len(f) < 9:
                continue
            side = f[0]
            s = [src_pos(n) for n in f[1:5]]
            t = [tgt_pos(resolve(n)) if resolve(n) else None for n in f[5:9]]
            if all(v is not None for v in s):
                palm_src[side] = normalize(cross(sub(s[1], s[0]), sub(s[2], s[3])))
            if all(v is not None for v in t):
                palm_tgt[side] = normalize(cross(sub(t[1], t[0]), sub(t[2], t[3])))
            if s[0] is not None and s[1] is not None and t[0] is not None and t[1] is not None:
                s_hand_r = self.src_rest[f[1]][0]
                t_hand_r = self.target[resolve(f[5])]["world"][0]
                grips[side] = (mvec(transpose(s_hand_r), sub(s[1], s[0])), mvec(transpose(t_hand_r), sub(t[1], t[0])))

        # Manual corrections, in degrees about the target bone's local axes (X, then Y, then Z). Applied
        # to the local rotation, so the children follow, as when the bone is rotated by hand in 3ds Max.
        self.adjustments: Dict[str, Mat] = {}
        adjustments = self.adjustments
        for f in preset["adjust"]:
            # One bone per line: the name is tab separated (names contain spaces); the angles may use tabs or spaces
            line = "adjust\t" + "\t".join(f)
            try:
                angles = [float(v) for v in " ".join(f[1:]).split()]
                if not f or len(angles) != 3:
                    raise ValueError
            except ValueError:
                self.warnings.append(f"Ignored preset line (expected 'adjust<TAB>bone<TAB>x<TAB>y<TAB>z'): {line}")
                continue
            tgt = resolve(f[0])
            if tgt is None:
                self.warnings.append(f"Ignored adjust: '{f[0]}' is not in the captured target skeleton")
                continue
            adjustments[tgt] = mmul(mmul(axis_rotation(0, angles[0]), axis_rotation(1, angles[1])), axis_rotation(2, angles[2]))

        # Bone mapping with the constant per-bone rotation offsets
        self.mapping: Dict[str, dict] = {}
        for f in preset["bone"]:
            if len(f) < 5:
                continue
            src, tgt = f[0], resolve(f[1])
            if tgt is None or src not in self.src_index or src not in self.src_rest:
                continue
            src_aim_child, tgt_aim_child = f[2], (resolve(f[3]) if f[3] != "-" else "-")
            up_ref = f[4]
            is_root = len(f) > 5 and f[5] == "root"

            if up_ref == "world":
                cs = ct = IDENTITY
            else:
                side = up_ref.split("_")[-1]
                up_s, up_t = palm_src.get(side), palm_tgt.get(side)
                aim_s = self._aim(src_aim_child, src, src_pos, lambda n: self.src_names[self.src_parents[self.src_index[n]]]
                                  if self.src_parents[self.src_index[n]] >= 0 else None)
                aim_t = self._aim(tgt_aim_child, tgt, tgt_pos, lambda n: self.target[n]["parent"] or None)
                cs, ct = canonical_frame(aim_s, up_s), canonical_frame(aim_t, up_t)
                if cs is None or ct is None:
                    self.warnings.append(f"No canonical frame for {src} -> {tgt}; using the rest pose difference")
                    cs = ct = IDENTITY

            s_rest_r = self.src_rest[src][0]
            t_rest_r = self.target[tgt]["world"][0]
            offset = mmul(mmul(transpose(s_rest_r), cs), mmul(transpose(ct), t_rest_r))
            # Halo 5 parent and rest local position, to carry over animated translations (Halo 5 first
            # person animations move the shoulders a lot; pinning them leaves the hands short)
            src_parent_index = self.src_parents[self.src_index[src]]
            src_parent = self.src_names[src_parent_index] if src_parent_index >= 0 else None
            src_rest_local = None
            if src_parent in self.src_rest:
                parent_rest = self.src_rest[src_parent]
                src_rest_local = mvec(transpose(parent_rest[0]), sub(self.src_rest[src][1], parent_rest[1]))
            self.mapping[tgt] = {
                "src": src,
                "offset": offset,
                "root": is_root,
                "rest_delta": sub(self.target[tgt]["world"][1], self.src_rest[src][1]),
                "src_parent": src_parent if src_rest_local is not None else None,
                "src_rest_local": src_rest_local,
            }

        # Two-bone IK chains
        self.ik_chains: Dict[str, dict] = {}
        for f in preset["ik"]:
            if len(f) < 7:
                continue
            src_chain = f[1:4]
            tgt_chain = [resolve(n) for n in f[4:7]]
            if None in tgt_chain or any(n not in self.src_index for n in src_chain):
                continue
            upper, fore, hand = tgt_chain
            if self.target[fore]["parent"] != upper or self.target[hand]["parent"] != fore:
                self.warnings.append(f"IK skipped for side '{f[0]}': {upper} > {fore} > {hand} is not a direct chain")
                continue
            if not all(n in self.mapping for n in tgt_chain):
                continue
            self.ik_chains[upper] = {"src": src_chain, "tgt": tgt_chain, "grip": grips.get(f[0])}

        # Weapon nodes: Halo 5 nodes under the gun that also exist in the scene
        self.gun = None
        self.weapon_nodes: List[str] = []
        if preset["gun"]:
            f = preset["gun"][0]
            src_gun, src_hand, tgt_hand = f[0], f[1], resolve(f[2]) if len(f) > 2 else None
            if src_gun in self.src_index and src_hand in self.src_index:
                self.gun = {"src": src_gun, "src_hand": src_hand, "tgt_hand": tgt_hand}
                for name in self.target_order:
                    if name in self.src_index and name not in self.mapping and self._under(name, src_gun):
                        self.weapon_nodes.append(name)

        self.camera = None
        if camera_relative and preset["camera"] and preset["camera"][0][0] in self.src_index:
            self.camera = preset["camera"][0][0]

        # Output: mapped target nodes (parents first), then the weapon nodes
        mapped = [name for name in self.target_order if name in self.mapping]
        self.output = sorted(mapped, key=self._target_depth) + sorted(self.weapon_nodes, key=self._target_depth)
        out_set = set(self.output)
        self.output_parents = [self.output.index(self.target[n]["parent"]) if self.target[n]["parent"] in out_set else -1
                               for n in self.output]

    def _aim(self, child: str, node: str, pos, parent_of) -> Optional[Vec]:
        if child not in ("-", None) and pos(child) is not None:
            return sub(pos(child), pos(node))
        parent = parent_of(node)
        if parent and pos(parent) is not None:
            return sub(pos(node), pos(parent))
        return None

    def _under(self, name: str, ancestor: str) -> bool:
        index = self.src_index[name]
        while index >= 0:
            if self.src_names[index] == ancestor:
                return True
            index = self.src_parents[index]
        return False

    def _target_depth(self, name: str) -> int:
        depth = 0
        parent = self.target[name]["parent"]
        while parent in self.target and depth < 256:
            depth += 1
            parent = self.target[parent]["parent"]
        return depth

    def summary(self) -> str:
        return (f"{len(self.mapping)} bone(s) mapped, IK on {len(self.ik_chains) if self.use_ik else 0} arm(s), "
                f"shoulder reach {self.shoulder_reach:g}, "
                f"{len(self.weapon_nodes)} weapon node(s), camera motion {'removed' if self.camera else 'kept'}")

    # --- per frame ------------------------------------------------------------------------

    def _solve_ik(self, chain, src_world, world):
        upper, fore, hand = chain["tgt"]
        s_upper, s_fore, s_hand = chain["src"]
        r_upper = world[upper][0]
        r_fore = mmul(src_world[s_fore][0], self.mapping[fore]["offset"])
        r_hand = mmul(src_world[s_hand][0], self.mapping[hand]["offset"])
        local_fore = self.rest_local[fore][1]
        local_hand = self.rest_local[hand][1]
        a, b = length(local_fore), length(local_hand)

        # Wrist goal: where the target wrist must be for its middle knuckle to land on the Halo 5 one
        desired = src_world[s_hand][1]
        if chain["grip"] is not None:
            s_grip, t_grip = chain["grip"]
            desired = sub(add(desired, mvec(src_world[s_hand][0], s_grip)), mvec(r_hand, t_grip))

        shoulder = world[upper][1]
        to_goal = sub(desired, shoulder)
        d = length(to_goal)
        if d < 1e-6 or a < 1e-6 or b < 1e-6:
            return False
        direction = scale(to_goal, 1.0 / d)
        # Out of reach (narrower Halo 5 shoulders, other proportions): slide the shoulder toward the
        # goal by what is missing, up to shoulder_reach, instead of leaving the hand short
        reach = a + b - 1e-4
        if d > reach and self.shoulder_reach > 0.0:
            shoulder = add(shoulder, scale(direction, min(d - reach, self.shoulder_reach)))
            d = length(sub(desired, shoulder))
        d = min(max(d, abs(a - b) + 1e-4), reach)
        goal = add(shoulder, scale(direction, d))

        # Bend the way the Halo 5 elbow bends: its offset from the Halo 5 shoulder-wrist line. Using the
        # elbow point itself would tilt the bend plane, since the shoulders are not in the same place.
        # Falls back to the forward-kinematics elbow when the Halo 5 arm is straight.
        src_shoulder = src_world[s_upper][1]
        src_axis = normalize(sub(src_world[s_hand][1], src_shoulder))
        candidates = []
        if src_axis is not None:
            v = sub(src_world[s_fore][1], src_shoulder)
            candidates.append(sub(v, scale(src_axis, dot(v, src_axis))))
        candidates.append(sub(compose(world[upper], self.rest_local[fore])[1], shoulder))
        bend = None
        for v in candidates:
            bend = normalize(sub(v, scale(direction, dot(v, direction))))
            if bend is not None:
                break
        if bend is None:
            return False
        x = (a * a - b * b + d * d) / (2.0 * d)
        h = math.sqrt(max(0.0, a * a - x * x))
        elbow = add(shoulder, add(scale(direction, x), scale(bend, h)))

        aim_upper = normalize(mvec(r_upper, local_fore))
        r_upper = mmul(rotation_between(aim_upper, normalize(sub(elbow, shoulder))), r_upper)
        world[upper] = (r_upper, shoulder)
        fore_pos = compose(world[upper], self.rest_local[fore])[1]

        aim_fore = normalize(mvec(r_fore, local_hand))
        target_dir = normalize(sub(goal, fore_pos))
        if aim_fore is not None and target_dir is not None:
            r_fore = mmul(rotation_between(aim_fore, target_dir), r_fore)
        world[fore] = (r_fore, fore_pos)
        world[hand] = (r_hand, compose(world[fore], self.rest_local[hand])[1])
        # How far the hand ended from its goal (zero unless the arm still could not reach)
        self.residuals[hand] = sub(world[hand][1], desired)
        return True

    def retarget_frame(self, local_frame) -> List[Xform]:
        # Halo 5 world transforms (the graph lists parents before children)
        src_world: Dict[str, Xform] = {}
        for index, name in enumerate(self.src_names):
            parent = self.src_parents[index]
            local = local_frame[index]
            src_world[name] = compose(src_world[self.src_names[parent]], local) if parent >= 0 else local
        if self.camera:
            to_camera = inverse(src_world[self.camera])
            src_world = {name: compose(to_camera, xf) for name, xf in src_world.items()}

        world: Dict[str, Xform] = {}
        self.residuals = {}

        def parent_world(name: str) -> Xform:
            parent = self.target[name]["parent"]
            if parent in world:
                return world[parent]
            if parent in self.target:
                return self.target[parent]["world"]
            return self.target[name]["parent_world"]

        done = set()
        for name in self.output:
            if name in done or name not in self.mapping:
                continue
            m = self.mapping[name]
            rotation = mmul(src_world[m["src"]][0], m["offset"])
            if m["root"]:
                position = add(src_world[m["src"]][1], m["rest_delta"])
            else:
                position = compose(parent_world(name), self.rest_local[name])[1]
                # Plus how far the Halo 5 bone moved from its rest place, in its parent's space
                if m["src_parent"] is not None:
                    src_parent = src_world[m["src_parent"]]
                    src_local = mvec(transpose(src_parent[0]), sub(src_world[m["src"]][1], src_parent[1]))
                    position = add(position, mvec(src_parent[0], sub(src_local, m["src_rest_local"])))
            world[name] = (rotation, position)
            done.add(name)
            if self.use_ik and name in self.ik_chains:
                if self._solve_ik(self.ik_chains[name], src_world, world):
                    done.update(self.ik_chains[name]["tgt"])

        # Weapon nodes follow the target hand with their Halo 5 placement relative to the hand. With IK
        # the weapon stays where Halo 5 has it, shifted only by what the hand missed its goal by, so the
        # other hand (aimed at the Halo 5 weapon) still meets it.
        if self.gun:
            src_gun, src_hand, tgt_hand = self.gun["src"], self.gun["src_hand"], self.gun["tgt_hand"]
            if tgt_hand in self.residuals:
                hand_frame = (src_world[src_hand][0], add(src_world[src_hand][1], self.residuals[tgt_hand]))
            elif tgt_hand in world:
                hand_frame = (src_world[src_hand][0], world[tgt_hand][1])
            else:
                hand_frame = src_world[src_hand]
            for name in self.output:
                if name not in self.weapon_nodes:
                    continue
                if name == src_gun:
                    world[name] = compose(hand_frame, compose(inverse(src_world[src_hand]), src_world[name]))
                else:
                    src_parent = self.src_names[self.src_parents[self.src_index[name]]]
                    base = world.get(src_parent, src_world[src_parent])
                    world[name] = compose(base, compose(inverse(src_world[src_parent]), src_world[name]))

        locals_out = []
        for name in self.output:
            rotation, position = compose(inverse(parent_world(name)), world[name])
            if name in self.adjustments:
                rotation = mmul(rotation, self.adjustments[name])
            locals_out.append((orthonormalize(rotation), position))
        return locals_out


def retarget_folder(
    src_files: str,
    skeleton_tsv: str,
    target_tsv: str,
    preset_path: str,
    out_dir: str,
    src_conjugate: bool,
    out_conjugate: bool,
    use_ik: bool = True,
    camera_relative: bool = True,
    shoulder_reach: float = 0.0,
) -> str:
    """Retargets the '|' separated JMA-family files (or every one in a folder) into out_dir.

    Returns a tab-separated report: #info text / #warn text / #error text / out source_file out_file frames
    """
    report: List[str] = []
    try:
        src_files = str(src_files)
        if os.path.isdir(src_files):
            files = sorted(os.path.join(src_files, f) for f in os.listdir(src_files)
                           if os.path.splitext(f)[1].lower() in JMA_EXTENSIONS)
        else:
            files = [f for f in src_files.split("|") if f.strip()]
        if not files:
            return "#error\tNo animation files to retarget"
        os.makedirs(str(out_dir), exist_ok=True)

        retargeter = None
        for src_file in files:
            try:
                names, parents, frames = read_jma(src_file, bool(src_conjugate))
                if retargeter is None or retargeter.src_names != names:
                    retargeter = Retargeter(names, parents, read_skeleton_tsv(str(skeleton_tsv)),
                                            read_target_tsv(str(target_tsv)), read_preset(str(preset_path)),
                                            bool(use_ik), bool(camera_relative), float(shoulder_reach))
                    report.append(f"#info\t{retargeter.summary()}")
                    report.extend(f"#warn\t{w}" for w in retargeter.warnings)
                    if not retargeter.mapping:
                        return "\n".join(report + ["#error\tNo preset bone was found in the captured target skeleton"])
                out_frames = [retargeter.retarget_frame(frame) for frame in frames]
                out_file = os.path.join(str(out_dir), os.path.basename(src_file))
                write_jma(out_file, retargeter.output, retargeter.output_parents, out_frames, bool(out_conjugate))
                report.append(f"out\t{src_file}\t{out_file}\t{len(out_frames)}")
            except Exception as error:
                report.append(f"#warn\tFailed '{os.path.basename(src_file)}': {error!r}")
    except Exception:
        report.append("#error\t" + traceback.format_exc().replace("\n", " | "))
    return "\n".join(report)
