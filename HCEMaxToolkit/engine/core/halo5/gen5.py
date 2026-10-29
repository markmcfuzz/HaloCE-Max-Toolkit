"""Halo 5 Gen5 tag container reader (decompressed 'ucsh' files)."""

# Vendored from H5AnimExtractor by Generalkidd (https://github.com/Generalkidd/H5AnimExtractor).
# Local changes are marked with 'HCE Max Toolkit:' comments.

from dataclasses import dataclass
import struct
import uuid
from typing import Dict, List, Optional, Tuple


def murmur3_32(text: str, seed: int = 0) -> int:
    """MurmurHash3 x86 32-bit (seed 0) matching Halo 5 StringId hashing."""
    data = text.encode("utf-8")
    length = len(data)
    c1 = 0xCC9E2D51
    c2 = 0x1B873593
    h1 = seed & 0xFFFFFFFF

    block_count = length // 4
    for i in range(block_count):
        k1 = struct.unpack("<I", data[i * 4 : (i + 1) * 4])[0]
        k1 = (k1 * c1) & 0xFFFFFFFF
        k1 = ((k1 << 15) | (k1 >> 17)) & 0xFFFFFFFF
        k1 = (k1 * c2) & 0xFFFFFFFF

        h1 ^= k1
        h1 = ((h1 << 13) | (h1 >> 19)) & 0xFFFFFFFF
        h1 = (h1 * 5 + 0xE6546B64) & 0xFFFFFFFF

    tail_offset = block_count * 4
    tail_len = length & 3
    k1 = 0
    if tail_len == 3:
        k1 ^= data[tail_offset + 2] << 16
    if tail_len >= 2:
        k1 ^= data[tail_offset + 1] << 8
    if tail_len >= 1:
        k1 ^= data[tail_offset]
        k1 = (k1 * c1) & 0xFFFFFFFF
        k1 = ((k1 << 15) | (k1 >> 17)) & 0xFFFFFFFF
        k1 = (k1 * c2) & 0xFFFFFFFF
        h1 ^= k1

    h1 ^= length
    h1 ^= h1 >> 16
    h1 = (h1 * 0x85EBCA6B) & 0xFFFFFFFF
    h1 ^= h1 >> 13
    h1 = (h1 * 0xC2B2AE35) & 0xFFFFFFFF
    h1 ^= h1 >> 16
    return h1


@dataclass
class Gen5TagHeader:
    magic: int
    version: int
    asset_checksum: int
    dependency_count: int
    data_block_count: int
    structure_count: int
    data_reference_count: int
    tag_reference_count: int
    string_id_count: int
    string_table_size: int
    zoneset_data_size: int
    header_size: int
    data_size: int
    resource_data_size: int


@dataclass
class Gen5DataBlock:
    index: int
    size: int
    section: int
    offset: int


@dataclass
class Gen5Structure:
    guid: uuid.UUID
    type: int
    target_index: int
    field_block: int
    field_offset: int


@dataclass
class Gen5DataReference:
    parent_structure_index: int
    target_index: int
    field_block: int
    field_offset: int


class Gen5Container:
    """Parser for decompressed Halo 5 'ucsh' tag files."""

    FIXED_HEADER_SIZE = 80

    def __init__(self, file_path: str, data: bytes):
        self.file_path = file_path
        self.data = data
        if len(data) < self.FIXED_HEADER_SIZE:
            raise ValueError(f"File '{file_path}' is too small to be a Gen5 tag ({len(data)} bytes)")

        magic = struct.unpack_from("<i", data, 0)[0]
        version = struct.unpack_from("<i", data, 4)[0]
        asset_checksum = struct.unpack_from("<q", data, 16)[0]
        dependency_count = struct.unpack_from("<i", data, 28)[0]
        data_block_count = struct.unpack_from("<i", data, 32)[0]
        structure_count = struct.unpack_from("<i", data, 36)[0]
        data_reference_count = struct.unpack_from("<i", data, 40)[0]
        tag_reference_count = struct.unpack_from("<i", data, 44)[0]
        string_id_count = struct.unpack_from("<i", data, 48)[0]
        string_table_size = struct.unpack_from("<i", data, 52)[0]
        zoneset_data_size = struct.unpack_from("<i", data, 56)[0]
        header_size = struct.unpack_from("<i", data, 60)[0]
        data_size = struct.unpack_from("<i", data, 64)[0]
        resource_data_size = struct.unpack_from("<i", data, 68)[0]

        if magic != 0x68736375:  # ASCII 'ucsh'
            raise ValueError(f"File '{file_path}' is not a decompressed Halo 5 tag (magic 0x{magic:08x} != 'ucsh')")

        self.header = Gen5TagHeader(
            magic=magic,
            version=version,
            asset_checksum=asset_checksum,
            dependency_count=dependency_count,
            data_block_count=data_block_count,
            structure_count=structure_count,
            data_reference_count=data_reference_count,
            tag_reference_count=tag_reference_count,
            string_id_count=string_id_count,
            string_table_size=string_table_size,
            zoneset_data_size=zoneset_data_size,
            header_size=header_size,
            data_size=data_size,
            resource_data_size=resource_data_size,
        )

        cursor = self.FIXED_HEADER_SIZE
        cursor += dependency_count * 24

        self.data_blocks: List[Gen5DataBlock] = []
        for i in range(data_block_count):
            size, _, section, offset = struct.unpack("<iHhQ", data[cursor : cursor + 16])
            self.data_blocks.append(Gen5DataBlock(i, size, section, offset))
            cursor += 16

        self.structures: List[Gen5Structure] = []
        for i in range(structure_count):
            raw_guid = data[cursor : cursor + 16]
            struct_guid = uuid.UUID(bytes_le=raw_guid)
            stype, _, target_idx, field_blk, field_off = struct.unpack("<hhiii", data[cursor + 16 : cursor + 32])
            self.structures.append(Gen5Structure(struct_guid, stype, target_idx, field_blk, field_off))
            cursor += 32

        self.data_references: List[Gen5DataReference] = []
        for i in range(data_reference_count):
            parent_struct, _, target_idx, field_blk, field_off = struct.unpack("<iiiii", data[cursor : cursor + 20])
            self.data_references.append(Gen5DataReference(parent_struct, target_idx, field_blk, field_off))
            cursor += 20

        cursor += tag_reference_count * 16
        cursor += string_id_count * 8

        strings_end = cursor + string_table_size
        if strings_end > len(data):
            raise ValueError(f"String table extends past end of file in '{file_path}'")

        self.strings_by_hash: Dict[int, str] = {}
        while cursor < strings_end:
            term = data.find(b"\x00", cursor, strings_end)
            if term < 0:
                term = strings_end
            s_bytes = data[cursor:term]
            if s_bytes:
                text = s_bytes.decode("utf-8", errors="replace")
                h = murmur3_32(text)
                if h not in self.strings_by_hash:
                    self.strings_by_hash[h] = text
            cursor = term + 1

    @classmethod
    def open(cls, file_path: str) -> "Gen5Container":
        with open(file_path, "rb") as f:
            data = f.read()
        return cls(file_path, data)

    def resolve_string(self, hash_val: int, fallback_prefix: str) -> str:
        return self.strings_by_hash.get(hash_val, f"{fallback_prefix}_{hash_val:08X}")

    def get_block(self, index: int) -> bytes:
        if index < 0 or index >= len(self.data_blocks):
            raise IndexError(f"Data block index {index} out of range (0..{len(self.data_blocks) - 1})")
        block = self.data_blocks[index]
        if block.section == 0:
            section_base = 0
        else:
            section_base = self.header.header_size + sum(
                b.size for b in self.data_blocks if b.section < block.section
            )
        absolute_offset = section_base + block.offset
        if absolute_offset < 0 or absolute_offset + block.size > len(self.data):
            raise ValueError(f"Data block {index} offset range [{absolute_offset}, {absolute_offset + block.size}) exceeds container size {len(self.data)}")
        return self.data[absolute_offset : absolute_offset + block.size]

    def find_structure(self, target_guid: uuid.UUID) -> Optional[Gen5Structure]:
        for s in self.structures:
            if s.guid == target_guid:
                return s
        return None
