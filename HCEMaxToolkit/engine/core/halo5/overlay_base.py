"""Overlay reference-pose resolution and on-demand clip assembly.

Pure-Python port of the Foundry-style base-pose search embedded in H5AnimExtractor's Blender
importer (importer.py, import_animations_stepwise). Halo 5 overlays rarely set their parent
animation, so the base pose is found through the graph's mode/class/type/set action paths.
"""

import os
from typing import Callable, Dict, List, Optional, Tuple

from .assembler import (
    AnimationAssembler,
    AnimationClip,
    AnimationMetadata,
    Halo5AnimationGraph,
    Halo5AnimationReader,
    PackedAnimationResource,
)

DAMAGE_REGIONS = {"gut", "chest", "head", "l_arm", "l_hand", "l_leg", "l_foot", "r_arm", "r_hand", "r_leg", "r_foot"}
DAMAGE_DIRECTIONS = {"front", "left", "right", "back"}
DAMAGE_STATES = {"h_ping", "s_ping", "h_kill", "s_kill"}


def parse_foundry_animation_name(name: str) -> Optional[Tuple[Tuple[str, str, str, str], str]]:
    """Return Foundry's (mode, class, type, set), state interpretation of an animation name."""
    tokens = [token for token in (name or "").replace(" ", ":").split(":") if token]
    if tokens and tokens[-1].startswith("var") and tokens[-1][3:].isdigit():
        tokens.pop()
    if len(tokens) < 2:
        return None
    if len(tokens) > 2 and tokens[-1] in DAMAGE_REGIONS and tokens[-2] in DAMAGE_DIRECTIONS and tokens[-3] in DAMAGE_STATES:
        tokens = tokens[:-2]
    elif len(tokens) > 2 and "2" in tokens:
        separator = tokens.index("2")
        if 0 < separator < len(tokens) - 1:
            tokens = tokens[:separator]
    if not tokens:
        return None
    state = tokens.pop()
    scope = ["any", "any", "any", "any"]
    for i, token in enumerate(tokens[:4]):
        scope[i] = token
    return tuple(scope), state


def normalized_mode_path(path: str) -> str:
    """Foundry's normalized animation-graph path for rename grouping."""
    tokens = [token for token in (path or "").replace(" ", ":").split(":") if token]
    tokens = [token for token in tokens if not (token.startswith("var") and token[3:].isdigit())]
    if not tokens:
        return ""
    if len(tokens) >= 5 and tokens[-3] == "2":
        head, tail = tokens[:-4], tokens[-4:]
    elif len(tokens) >= 5 and tokens[-3] in DAMAGE_STATES:
        head, tail = tokens[:-3], tokens[-3:]
    else:
        head, tail = tokens[:-1], tokens[-1:]
    while head and head[-1] == "any":
        head.pop()
    return ":".join(head + tail)


def base_state_candidates(name: str) -> Tuple[str, ...]:
    """Port of Foundry AnimationTag._base_state_candidates()."""
    parsed = parse_foundry_animation_name(name)
    if parsed is None:
        return ()
    _, state = parsed
    candidates: List[str] = []

    def add(candidate: str) -> None:
        if candidate and candidate not in candidates:
            candidates.append(candidate)

    def add_family(candidate: str) -> None:
        candidate = candidate.strip("_")
        if not candidate:
            return
        add(candidate)
        if candidate.endswith("_fast") or candidate.endswith("_slow"):
            add(candidate.rsplit("_", 1)[0])
        else:
            add(f"{candidate}_fast")
            add(f"{candidate}_slow")

    if state.startswith(("aim_airborne", "look_airborne")):
        return ("airborne",)
    tokens = state.split("_")
    motion_tokens = {"move", "walk", "run", "jog", "locomote", "turn"}
    for index, token in enumerate(tokens):
        if token not in DAMAGE_DIRECTIONS:
            continue
        for start in range(index - 1, -1, -1):
            if tokens[start] not in motion_tokens:
                continue
            add_family("_".join(tokens[start:index + 1]))
            if tokens[start] == "locomote" and start + 1 < index:
                add_family("_".join(tokens[start + 1:index + 1]))
    for prefix in ("aim_", "look_", "acc_", "steer_"):
        if state.startswith(prefix):
            stripped = state[len(prefix):]
            add_family(stripped)
            for suffix in ("_up", "_down", "_left", "_right"):
                if stripped.endswith(suffix):
                    add_family(stripped[: -len(suffix)])
    add("idle")
    return tuple(candidates)


def matching_base_actions(actions: Dict[str, List[int]], state: str) -> List[int]:
    """Port of Foundry AnimationTag._matching_base_actions()."""
    state_key = state.replace(" ", "_").lower()
    matches: List[int] = []

    def add(indices: Optional[List[int]]) -> None:
        for animation_index in indices or ():
            if animation_index not in matches:
                matches.append(animation_index)

    add(actions.get(state))
    for key, indices in actions.items():
        parsed = parse_foundry_animation_name(key)
        key_state = (parsed[1] if parsed else key).replace(" ", "_").lower()
        key_token = key.replace(":", " ").replace(" ", "_").lower()
        if key_state == state_key or key_token.startswith(f"{state_key}_var"):
            add(indices)
    return matches


class ClipResolver:
    """Assembles clips on demand, giving every overlay the base clip it is authored against."""

    def __init__(
        self,
        graph: Halo5AnimationGraph,
        fps: float = 30.0,
        bake_root_motion: bool = True,
        expand_single_frame_clips: bool = True,
    ):
        self.graph = graph
        self.fps = fps
        self.bake_root_motion = bake_root_motion
        self.expand_single_frame_clips = expand_single_frame_clips
        self.meta_by_index = {m.index: m for m in graph.animations}
        self.resource_cache: Dict[str, Dict[int, PackedAnimationResource]] = {}
        self.clips: Dict[int, AnimationClip] = {}
        self.base_index_used: Dict[int, int] = {}
        self._resolving: set = set()

        # mode -> class -> type -> set -> {"actions": {state: [animation indices]}}
        self.mode_graph: Dict[str, dict] = {}
        for animation_index, paths in graph.mode_action_paths_by_animation_index.items():
            for path in paths:
                parsed = parse_foundry_animation_name(path)
                if parsed is None:
                    continue
                scope, state = parsed
                level = self.mode_graph
                for token in scope:
                    level = level.setdefault(token, {})
                level.setdefault("actions", {}).setdefault(state, []).append(animation_index)

    def packed_resource(self, meta: AnimationMetadata) -> Optional[PackedAnimationResource]:
        res_file = Halo5AnimationReader.locate_resource_file(self.graph, meta)
        if not res_file or not os.path.isfile(res_file):
            return None
        if res_file not in self.resource_cache:
            resources = Halo5AnimationReader.read_resources(res_file)
            self.resource_cache[res_file] = {r.member_index: r for r in resources}
        return self.resource_cache[res_file].get(meta.resource_member_index)

    # --- Foundry base-pose search ----------------------------------------------------------

    def _branch_groups(self, level: Dict[str, dict], token: str, depth: int) -> List[str]:
        nested_keys = [key for key, value in level.items() if isinstance(value, dict) and key != "actions"]
        keys: List[str] = []

        def add(key: str) -> None:
            if key not in keys and key in level and isinstance(level[key], dict):
                keys.append(key)

        if depth == 0:
            add(token)
            if token != "any" and token not in level:
                add("any")
        elif depth == 1:
            if token == "any":
                add("rifle")
                add("any")
                for key in nested_keys:
                    add(key)
            else:
                add(token)
                add("any")
        elif token == "any":
            for key in nested_keys:
                add(key)
        else:
            add(token)
            add("any")
        return keys

    def _walk(self, level: Dict[str, dict], remaining: Tuple[str, ...], state: str, depth: int = 0) -> List[int]:
        if not isinstance(level, dict):
            return []
        if not remaining:
            actions = level.get("actions")
            if actions:
                return matching_base_actions(actions, state)
            results: List[int] = []
            for key, branch in level.items():
                if key != "actions" and isinstance(branch, dict):
                    results.extend(self._walk(branch, (), state, depth + 1))
            return results
        results = []
        for key in self._branch_groups(level, remaining[0], depth):
            results.extend(self._walk(level[key], remaining[1:], state, depth + 1))
        return results

    def _base_action_candidates(self, names: List[str]) -> List[int]:
        candidates: List[int] = []
        for name in names:
            parsed = parse_foundry_animation_name(name)
            if parsed is None:
                continue
            scope, _ = parsed
            for state in base_state_candidates(name):
                for animation_index in self._walk(self.mode_graph, scope, state):
                    if animation_index not in candidates:
                        candidates.append(animation_index)
        return candidates

    def _resolved_base_index(self, candidate_index: int) -> int:
        """Resolve a composite candidate to its timing source, as Foundry does."""
        graph = self.graph
        seen: set = set()
        while candidate_index not in seen:
            seen.add(candidate_index)
            candidate = self.meta_by_index.get(candidate_index)
            if candidate is None or candidate.composite_index < 0:
                break
            if candidate.composite_index >= len(graph.composites):
                break
            timing_index = graph.composites[candidate.composite_index].timing_animation_index
            if timing_index < 0 or timing_index >= len(graph.animations):
                break
            candidate_index = timing_index
        candidate = self.meta_by_index.get(candidate_index)
        return candidate_index if candidate and candidate.animation_type in (0, 1) else -1

    def _idle_fallback_index(self, meta: AnimationMetadata) -> int:
        """HCE Max Toolkit: `<mode>:idle`, then any base idle, when the graph search finds nothing."""
        mode = meta.name.split(":", 1)[0]
        preferred = [m for m in self.graph.animations if m.animation_type == 1 and m.name == f"{mode}:idle"]
        if not preferred:
            preferred = [m for m in self.graph.animations if m.animation_type == 1 and m.name.startswith(f"{mode}:") and m.name.endswith(":idle")]
        if not preferred:
            preferred = [m for m in self.graph.animations if m.animation_type == 1 and m.name.endswith(":idle")]
        return preferred[0].index if preferred else -1

    def overlay_base_index(self, meta: AnimationMetadata) -> int:
        if meta.parent_animation_index >= 0:
            return meta.parent_animation_index

        graph = self.graph
        canonical = parse_foundry_animation_name(meta.name)
        canonical_name = meta.name if canonical else ""
        canonical_state = canonical[1] if canonical else ""
        paths = graph.mode_paths_by_animation_index.get(meta.index, [])
        rename_paths = set(graph.renames_by_animation_index.get(meta.index, []))
        primary_paths = [path for path in paths if normalized_mode_path(path) not in rename_paths]
        alternate_paths = [path for path in paths if normalized_mode_path(path) in rename_paths]

        def ordered_names(source_paths: List[str], include_canonical: bool) -> List[str]:
            ordered: List[str] = []
            for path in source_paths:
                parsed = parse_foundry_animation_name(path)
                if canonical_state and parsed and parsed[1] == canonical_state and path not in ordered:
                    ordered.append(path)
            if include_canonical and canonical_name and canonical_name not in ordered:
                ordered.append(canonical_name)
            for path in source_paths:
                if path not in ordered:
                    ordered.append(path)
            return ordered

        groups = [ordered_names(primary_paths, include_canonical=True)]
        alternate_names = ordered_names(alternate_paths, include_canonical=False)
        if alternate_names:
            groups.append(alternate_names)
        for names in groups:
            for candidate_index in self._base_action_candidates(names):
                resolved_index = self._resolved_base_index(candidate_index)
                if resolved_index >= 0:
                    return resolved_index
        return self._idle_fallback_index(meta)

    # --- Assembly --------------------------------------------------------------------------

    def get_clip(self, index: int, keep: bool = False) -> Optional[AnimationClip]:
        """Assemble on demand so an overlay's base is available whatever the order.

        Only clips used as an overlay base are cached (`keep`); a whole character graph held
        in memory at once would be millions of vector objects inside the 3ds Max process.
        """
        if index in self.clips:
            return self.clips[index]
        meta = self.meta_by_index.get(index)
        if meta is None or index in self._resolving:  # guard against a base chain looping back
            return None
        packed = self.packed_resource(meta)
        if not packed or not packed.animation_data:
            return None

        parent_clip = None
        parent_index = meta.parent_animation_index
        if meta.animation_type == 2 and parent_index < 0:
            parent_index = self.overlay_base_index(meta)
        if meta.animation_type in (2, 3) and parent_index >= 0 and parent_index != index:
            self._resolving.add(index)
            try:
                parent_clip = self.get_clip(parent_index, keep=True)
            finally:
                self._resolving.discard(index)
            if parent_clip is not None:
                self.base_index_used[index] = parent_index

        clip = AnimationAssembler.assemble(
            graph=self.graph,
            metadata=meta,
            packed=packed,
            fps_override=self.fps,
            bake_root_motion=self.bake_root_motion,
            parent_clip=parent_clip,
            expand_single_frame_clips=self.expand_single_frame_clips,
        )
        if keep:
            self.clips[index] = clip
        return clip
