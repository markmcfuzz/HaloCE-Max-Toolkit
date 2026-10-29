"""Halo 5 render_model node reader (rest pose source for animation graphs)."""

from dataclasses import dataclass
import struct
import uuid
from typing import List, Tuple

from .gen5 import Gen5Container

RENDER_MODEL_NODES_GUID = uuid.UUID("b74453b7-402e-d6e3-d087-158aea22bfef")
NODE_STRIDE = 124


@dataclass
class RenderModelNode:
    index: int
    name: str
    parent_index: int
    translation: Tuple[float, float, float]  # parent-local, world units
    rotation: Tuple[float, float, float, float]  # parent-local (x, y, z, w), standard math convention
    scale: float


def read_render_model_nodes(file_path: str) -> List[RenderModelNode]:
    """Reads the node block of a decompressed Halo 5 render_model tag.

    Record layout (124 bytes): name StringId @0, parent/first child/next sibling shorts @4,
    default translation @12, default rotation (xyzw) @24, default scale @40, inverse
    forward/left/up/position @44 and distance from parent @92. The rotations were checked
    against the stored inverse matrices: they compose as standard column-vector rotations.
    """
    container = Gen5Container.open(file_path)
    structure = container.find_structure(RENDER_MODEL_NODES_GUID)
    if structure is None or structure.target_index < 0:
        raise ValueError(f"Render model '{file_path}' has no nodes block")

    data = container.get_block(structure.target_index)
    nodes: List[RenderModelNode] = []
    for i in range(len(data) // NODE_STRIDE):
        offset = i * NODE_STRIDE
        name_hash = struct.unpack_from("<I", data, offset)[0]
        nodes.append(RenderModelNode(
            index=i,
            name=container.resolve_string(name_hash, f"node_{i:03d}"),
            parent_index=struct.unpack_from("<h", data, offset + 4)[0],
            translation=struct.unpack_from("<3f", data, offset + 12),
            rotation=struct.unpack_from("<4f", data, offset + 24),
            scale=struct.unpack_from("<f", data, offset + 40)[0],
        ))
    return nodes
