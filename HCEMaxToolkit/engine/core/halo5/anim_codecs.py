"""Pure Python decoders for Halo 5 animation codecs (0-11)."""

# Vendored from H5AnimExtractor by Generalkidd (https://github.com/Generalkidd/H5AnimExtractor).
# Local changes are marked with 'HCE Max Toolkit:' comments.

from dataclasses import dataclass, field
from enum import IntEnum
import math
import struct
from typing import List, Optional, Tuple, Union

try:
    from mathutils import Quaternion, Vector
except ImportError:
    # Pure Python fallback when running unit tests outside Blender
    class Quaternion:
        def __init__(self, values=(1.0, 0.0, 0.0, 0.0), angle=None):
            # HCE Max Toolkit: mathutils' axis-angle form, used by movement type 4 root motion.
            if angle is not None:
                half = angle * 0.5
                s = math.sin(half)
                self.w, self.x, self.y, self.z = math.cos(half), values.x * s, values.y * s, values.z * s
            elif len(values) == 4:
                self.w, self.x, self.y, self.z = (float(v) for v in values)
            else:
                raise ValueError("Quaternion requires 4 values (w, x, y, z)")

        def copy(self):
            return Quaternion((self.w, self.x, self.y, self.z))

        def dot(self, other):
            return self.w * other.w + self.x * other.x + self.y * other.y + self.z * other.z

        def negate(self):
            self.w, self.x, self.y, self.z = -self.w, -self.x, -self.y, -self.z

        def magnitude(self):
            return math.sqrt(self.w * self.w + self.x * self.x + self.y * self.y + self.z * self.z)

        def normalize(self):
            mag = self.magnitude()
            if mag > 1e-12:
                inv = 1.0 / mag
                self.w *= inv
                self.x *= inv
                self.y *= inv
                self.z *= inv
            else:
                self.w, self.x, self.y, self.z = 1.0, 0.0, 0.0, 0.0

        def __mul__(self, other):
            if isinstance(other, (int, float)):
                return Quaternion((self.w * other, self.x * other, self.y * other, self.z * other))
            if isinstance(other, Quaternion):
                return self.__matmul__(other)
            raise TypeError(f"Cannot multiply Quaternion by {type(other)}")

        def __matmul__(self, other):
            """Rotation composition. Mirrors mathutils, where `@` composes and `*` does not."""
            if isinstance(other, Vector):
                # HCE Max Toolkit: mathutils rotates a vector with `q @ v` (root motion baking).
                rotated = self.__matmul__(Quaternion((0.0, other.x, other.y, other.z))).__matmul__(
                    Quaternion((self.w, -self.x, -self.y, -self.z))
                )
                return Vector((rotated.x, rotated.y, rotated.z))
            if not isinstance(other, Quaternion):
                raise TypeError(f"Cannot compose Quaternion with {type(other)}")
            w1, x1, y1, z1 = self.w, self.x, self.y, self.z
            w2, x2, y2, z2 = other.w, other.x, other.y, other.z
            return Quaternion((
                w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2,
                w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
                w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
                w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2,
            ))

        def rotate(self, other):
            """HCE Max Toolkit: in-place `self = other @ self`, as mathutils.Quaternion.rotate does."""
            result = other.__matmul__(self)
            self.w, self.x, self.y, self.z = result.w, result.x, result.y, result.z

        def __repr__(self):
            return f"Quaternion(({self.w:.4f}, {self.x:.4f}, {self.y:.4f}, {self.z:.4f}))"

    class Vector:
        def __init__(self, values=(0.0, 0.0, 0.0)):
            self.x, self.y, self.z = (float(v) for v in values[:3])

        def copy(self):
            return Vector((self.x, self.y, self.z))

        @property
        def length(self):
            return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)

        def __add__(self, other):
            return Vector((self.x + other.x, self.y + other.y, self.z + other.z))

        def __sub__(self, other):
            return Vector((self.x - other.x, self.y - other.y, self.z - other.z))

        def __mul__(self, other):
            if isinstance(other, (int, float)):
                return Vector((self.x * other, self.y * other, self.z * other))
            raise TypeError(f"Cannot multiply Vector by {type(other)}")

        # HCE Max Toolkit: used by movement type 4 root motion (axis / angle).
        def __truediv__(self, other):
            return Vector((self.x / other, self.y / other, self.z / other))

        def __neg__(self):
            return Vector((-self.x, -self.y, -self.z))

        def __repr__(self):
            return f"Vector(({self.x:.4f}, {self.y:.4f}, {self.z:.4f}))"


class AnimationCodecType(IntEnum):
    NO_COMPRESSION = 0
    UNCOMPRESSED_STATIC = 1
    UNCOMPRESSED_ANIMATED = 2
    QUANTIZED_ROTATION_ONLY = 3
    BYTE_KEYFRAME_LIGHTLY_QUANTIZED = 4
    WORD_KEYFRAME_LIGHTLY_QUANTIZED = 5
    REVERSE_BYTE_KEYFRAME_LIGHTLY_QUANTIZED = 6
    REVERSE_WORD_KEYFRAME_LIGHTLY_QUANTIZED = 7
    BLEND_SCREEN = 8
    CURVE = 9
    REVISED_CURVE = 10
    SHARED_STATIC = 11


@dataclass
class SharedStaticTables:
    rotations: List[Tuple[int, int, int, int]] = field(default_factory=list)
    translations: List[Vector] = field(default_factory=list)
    scales: List[float] = field(default_factory=list)


@dataclass
class AnimationCodecMetadata:
    codec: AnimationCodecType
    frame_count: int
    rotation_track_count: int
    translation_track_count: int
    scale_track_count: int
    error_percentage: float
    playback_rate: float
    bytes_consumed: int
    rotation_data_offset: int = 0
    translation_data_offset: int = 0
    scale_data_offset: int = 0
    rotation_track_block_size: int = 0
    translation_track_block_size: int = 0
    scale_track_block_size: int = 0
    is_dense: bool = False


@dataclass
class DecodedAnimationCodec:
    metadata: AnimationCodecMetadata
    rotations: List[List[Quaternion]]
    translations: List[List[Vector]]
    scales: List[List[float]]
    rotation_keyframes: List[List[int]]
    translation_keyframes: List[List[int]]
    scale_keyframes: List[List[int]]


class BinaryBufferReader:
    def __init__(self, data: bytes):
        self.data = data
        self.position = 0
        self.limit = len(data)

    @property
    def length(self) -> int:
        return len(self.data)

    def ensure_range(self, offset: int, count: int, label: str):
        if offset < 0 or count < 0 or offset + count > self.limit:
            raise ValueError(f"Truncated {label}: range [{offset}, {offset + count}) exceeds limit {self.limit}")

    def read_u8(self, label: str = "") -> int:
        self.ensure_range(self.position, 1, label)
        val = self.data[self.position]
        self.position += 1
        return val

    def read_s16(self, label: str = "") -> int:
        self.ensure_range(self.position, 2, label)
        val = struct.unpack_from("<h", self.data, self.position)[0]
        self.position += 2
        return val

    def read_u16(self, label: str = "") -> int:
        self.ensure_range(self.position, 2, label)
        val = struct.unpack_from("<H", self.data, self.position)[0]
        self.position += 2
        return val

    def read_u32(self, label: str = "") -> int:
        self.ensure_range(self.position, 4, label)
        val = struct.unpack_from("<I", self.data, self.position)[0]
        self.position += 4
        return val

    def read_f32(self, label: str = "") -> float:
        self.ensure_range(self.position, 4, label)
        val = struct.unpack_from("<f", self.data, self.position)[0]
        self.position += 4
        if not math.isfinite(val):
            raise ValueError(f"Non-finite float value in {label} at offset {self.position - 4}")
        return val


def normalize_quaternion(q: Quaternion, previous: Optional[Quaternion] = None) -> Quaternion:
    res = q.copy()
    res.normalize()
    if previous is not None:
        if previous.dot(res) < 0.0:
            res.negate()
    elif res.w < 0.0:
        res.negate()
    return res


def decompress_curve_quaternion(a: int, b: int, c: int) -> Quaternion:
    i = a / 32767.0
    j = b / 32767.0
    encoded_w = c / 32767.0
    k = math.sqrt(max(1.0 - i * i - j * j, 0.0))
    if encoded_w < 0.0:
        k = -k
    w = 2.0 * abs(encoded_w) - 1.0
    vec_scale = math.sqrt(max(1.0 - w * w, 0.0))
    return Quaternion((w, i * vec_scale, j * vec_scale, k * vec_scale))


def decompress_revised_quaternion(a: int, b: int, c: int) -> Quaternion:
    inv_sqrt2 = 0.70710677
    v0 = ((a & 0xFFFE) - (0x10000 if (a & 0x8000) else 0)) / 32767.0 * inv_sqrt2
    v1 = ((b & 0xFFFE) - (0x10000 if (b & 0x8000) else 0)) / 32767.0 * inv_sqrt2
    v2 = ((c & 0xFFFE) - (0x10000 if (c & 0x8000) else 0)) / 32767.0 * inv_sqrt2
    omitted = math.sqrt(max(0.0, 1.0 - v0 * v0 - v1 * v1 - v2 * v2))
    if a & 1:
        omitted = -omitted
    omitted_idx = (c & 1) | (2 * (b & 1))
    out = [0.0] * 4
    out[(omitted_idx + 1) & 3] = v0
    out[(omitted_idx - 2) & 3] = v1
    out[(omitted_idx - 1) & 3] = v2
    out[omitted_idx] = omitted
    return Quaternion((out[3], out[0], out[1], out[2]))


def calculate_tangent_scalar(encoded: int, p1: float, p2: float) -> float:
    norm = encoded / 7.0
    return abs(norm) * (norm * 0.300000011920929) + (p2 - p1)


def hermite_scalar(t: float, tan1: float, tan2: float, p1: float, p2: float) -> float:
    t2 = t * t
    t3 = t2 * t
    return (2.0 * t3 - 3.0 * t2 + 1.0) * p1 + (t3 - 2.0 * t2 + t) * tan1 + (3.0 * t2 - 2.0 * t3) * p2 + (t3 - t2) * tan2


def decode_animation_codec(
    payload: bytes, frame_count: int, shared_tables: Optional[SharedStaticTables] = None
) -> DecodedAnimationCodec:
    """Main entry point to decode any Halo 5 animation codec payload."""
    if len(payload) < 12:
        raise ValueError(f"Codec payload is too small ({len(payload)} bytes)")

    reader = BinaryBufferReader(payload)
    codec = AnimationCodecType(reader.read_u8("codec type"))
    rot_count = reader.read_u8("rotation track count")
    trans_count = reader.read_u8("translation track count")
    scale_count = reader.read_u8("scale track count")
    error_pct = reader.read_f32("error percentage")
    playback_rate = reader.read_f32("playback rate")

    if codec == AnimationCodecType.UNCOMPRESSED_STATIC:
        return _decode_uncompressed_static(reader, codec, rot_count, trans_count, scale_count, error_pct, playback_rate, frame_count)
    elif codec == AnimationCodecType.SHARED_STATIC:
        if shared_tables is None:
            raise ValueError("Codec 11 (SHARED_STATIC) requires graph shared_tables")
        return _decode_shared_static(reader, codec, rot_count, trans_count, scale_count, error_pct, playback_rate, frame_count, shared_tables)
    elif codec in (AnimationCodecType.QUANTIZED_ROTATION_ONLY, AnimationCodecType.BLEND_SCREEN):
        quantized_rot = codec == AnimationCodecType.QUANTIZED_ROTATION_ONLY
        return _decode_dense_static_header(reader, codec, rot_count, trans_count, scale_count, error_pct, playback_rate, frame_count, quantized_rot)
    elif codec in (
        AnimationCodecType.BYTE_KEYFRAME_LIGHTLY_QUANTIZED,
        AnimationCodecType.WORD_KEYFRAME_LIGHTLY_QUANTIZED,
        AnimationCodecType.REVERSE_BYTE_KEYFRAME_LIGHTLY_QUANTIZED,
        AnimationCodecType.REVERSE_WORD_KEYFRAME_LIGHTLY_QUANTIZED,
    ):
        key_size = 1 if codec in (AnimationCodecType.BYTE_KEYFRAME_LIGHTLY_QUANTIZED, AnimationCodecType.REVERSE_BYTE_KEYFRAME_LIGHTLY_QUANTIZED) else 2
        reverse = codec in (AnimationCodecType.REVERSE_BYTE_KEYFRAME_LIGHTLY_QUANTIZED, AnimationCodecType.REVERSE_WORD_KEYFRAME_LIGHTLY_QUANTIZED)
        return _decode_keyframed(reader, codec, rot_count, trans_count, scale_count, error_pct, playback_rate, frame_count, key_size, reverse)
    elif codec in (AnimationCodecType.CURVE, AnimationCodecType.REVISED_CURVE):
        revised = codec == AnimationCodecType.REVISED_CURVE
        return _decode_curve(reader, codec, rot_count, trans_count, scale_count, error_pct, playback_rate, frame_count, revised)
    else:
        raise NotImplementedError(f"Halo 5 animation codec {codec.name} ({codec.value}) is not supported")


def _read_quantized_quaternion(reader: BinaryBufferReader, previous: Optional[Quaternion] = None) -> Quaternion:
    x = reader.read_s16("rot X") / 32767.0
    y = reader.read_s16("rot Y") / 32767.0
    z = reader.read_s16("rot Z") / 32767.0
    w = reader.read_s16("rot W") / 32767.0
    return normalize_quaternion(Quaternion((w, x, y, z)), previous)


def _decode_uncompressed_static(reader, codec, rot_count, trans_count, scale_count, error_pct, playback_rate, frame_count):
    reader.position = 32
    rotations = [[_read_quantized_quaternion(reader)] for _ in range(rot_count)]
    trans_off = reader.position
    translations = [[Vector((reader.read_f32() * 100.0, reader.read_f32() * 100.0, reader.read_f32() * 100.0))] for _ in range(trans_count)]
    scale_off = reader.position
    scales = [[reader.read_f32()] for _ in range(scale_count)]

    meta = AnimationCodecMetadata(
        codec=codec, frame_count=frame_count, rotation_track_count=rot_count, translation_track_count=trans_count,
        scale_track_count=scale_count, error_percentage=error_pct, playback_rate=playback_rate, bytes_consumed=reader.position,
        rotation_data_offset=32, translation_data_offset=trans_off, scale_data_offset=scale_off, is_dense=False
    )
    return DecodedAnimationCodec(meta, rotations, translations, scales, [[0]] * rot_count, [[0]] * trans_count, [[0]] * scale_count)


def _decode_shared_static(reader, codec, rot_count, trans_count, scale_count, error_pct, playback_rate, frame_count, tables):
    reader.position = 32
    rotations = []
    for t in range(rot_count):
        idx = reader.read_s16()
        if 0 <= idx < len(tables.rotations):
            i, j, k, w = tables.rotations[idx]
            q = normalize_quaternion(Quaternion((w / 32767.0, i / 32767.0, j / 32767.0, k / 32767.0)))
        else:
            q = Quaternion((1.0, 0.0, 0.0, 0.0))
        rotations.append([q])

    trans_off = reader.position
    translations = []
    for t in range(trans_count):
        idx = reader.read_s16()
        if 0 <= idx < len(tables.translations):
            v = tables.translations[idx] * 100.0
        else:
            v = Vector((0.0, 0.0, 0.0))
        translations.append([v])

    scale_off = reader.position
    scales = []
    for t in range(scale_count):
        idx = reader.read_s16()
        s = tables.scales[idx] if 0 <= idx < len(tables.scales) else 1.0
        scales.append([s])

    meta = AnimationCodecMetadata(
        codec=codec, frame_count=frame_count, rotation_track_count=rot_count, translation_track_count=trans_count,
        scale_track_count=scale_count, error_percentage=error_pct, playback_rate=playback_rate, bytes_consumed=reader.position,
        rotation_data_offset=32, translation_data_offset=trans_off, scale_data_offset=scale_off, is_dense=False
    )
    return DecodedAnimationCodec(meta, rotations, translations, scales, [[0]] * rot_count, [[0]] * trans_count, [[0]] * scale_count)


def _decode_dense_static_header(reader, codec, rot_count, trans_count, scale_count, error_pct, playback_rate, frame_count, quantized_rot):
    rot_blk_size = struct.unpack_from("<I", reader.data, 20)[0]
    trans_blk_size = struct.unpack_from("<I", reader.data, 24)[0]
    scale_blk_size = struct.unpack_from("<I", reader.data, 28)[0]

    rot_off = 32
    trans_off = rot_off + rot_blk_size * rot_count
    scale_off = trans_off + trans_blk_size * trans_count
    end_off = scale_off + scale_blk_size * scale_count

    full_keys = list(range(frame_count))

    rotations = []
    for t in range(rot_count):
        reader.position = rot_off + t * rot_blk_size
        track = []
        prev = None
        for f in range(frame_count):
            if quantized_rot:
                q = _read_quantized_quaternion(reader, prev)
            else:
                x, y, z, w = reader.read_f32(), reader.read_f32(), reader.read_f32(), reader.read_f32()
                q = normalize_quaternion(Quaternion((w, x, y, z)), prev)
            track.append(q)
            prev = q
        rotations.append(track)

    translations = []
    for t in range(trans_count):
        reader.position = trans_off + t * trans_blk_size
        track = []
        for f in range(frame_count):
            track.append(Vector((reader.read_f32() * 100.0, reader.read_f32() * 100.0, reader.read_f32() * 100.0)))
        translations.append(track)

    scales = []
    for t in range(scale_count):
        reader.position = scale_off + t * scale_blk_size
        track = [reader.read_f32() for _ in range(frame_count)]
        scales.append(track)

    meta = AnimationCodecMetadata(
        codec=codec, frame_count=frame_count, rotation_track_count=rot_count, translation_track_count=trans_count,
        scale_track_count=scale_count, error_percentage=error_pct, playback_rate=playback_rate, bytes_consumed=end_off,
        rotation_data_offset=rot_off, translation_data_offset=trans_off, scale_data_offset=scale_off, is_dense=True
    )
    return DecodedAnimationCodec(
        meta, rotations, translations, scales, [full_keys.copy() for _ in range(rot_count)],
        [full_keys.copy() for _ in range(trans_count)], [full_keys.copy() for _ in range(scale_count)]
    )


def _decode_keyframed(reader, codec, rot_count, trans_count, scale_count, error_pct, playback_rate, frame_count, key_size, reverse):
    reader.position = 12
    rot_key_off = reader.read_u32()
    trans_key_off = reader.read_u32()
    scale_key_off = reader.read_u32()
    rot_data_off = reader.read_u32()
    trans_data_off = reader.read_u32()
    scale_data_off = reader.read_u32()

    total_tracks = rot_count + trans_count + scale_count
    frame_info_end = 48 + total_tracks * 4

    def resolve_key_start(decl, count, fallback):
        if count == 0:
            return fallback
        return fallback if decl == 0 else decl

    first_data_off = min(x for x in (rot_data_off, trans_data_off, scale_data_off, len(reader.data)) if x > 0)
    rot_key_start = resolve_key_start(rot_key_off, rot_count, frame_info_end)
    trans_key_start = resolve_key_start(trans_key_off, trans_count, rot_key_start)
    scale_key_start = resolve_key_start(scale_key_off, scale_count, trans_key_start)

    rot_key_end = min((x for x in (trans_key_start, scale_key_start, first_data_off) if x > rot_key_start), default=first_data_off)
    trans_key_end = min((x for x in (scale_key_start, first_data_off) if x > trans_key_start), default=first_data_off)
    scale_key_end = first_data_off

    def read_keys(start, end, track_cnt, label):
        if track_cnt == 0:
            return []
        reader.position = start
        tracks = []
        for _ in range(track_cnt):
            keys = []
            while reader.position + key_size <= end:
                v = reader.read_u8() if key_size == 1 else reader.read_u16()
                if v <= frame_count and (not keys or keys[-1] <= v):
                    keys.append(v)
                else:
                    reader.position -= key_size
                    break
            if not keys:
                keys = [0]
            tracks.append(keys)
        return tracks

    rot_keys = read_keys(rot_key_start, rot_key_end, rot_count, "rotation")
    trans_keys = read_keys(trans_key_start, trans_key_end, trans_count, "translation")
    scale_keys = read_keys(scale_key_start, scale_key_end, scale_count, "scale")

    rotations = []
    if rot_count > 0:
        reader.position = rot_data_off
        for t in range(rot_count):
            track = []
            prev = None
            for _ in range(len(rot_keys[t])):
                q = _read_quantized_quaternion(reader, prev)
                track.append(q)
                prev = q
            rotations.append(track)

    translations = []
    if trans_count > 0:
        reader.position = trans_data_off
        for t in range(trans_count):
            track = []
            for _ in range(len(trans_keys[t])):
                track.append(Vector((reader.read_f32() * 100.0, reader.read_f32() * 100.0, reader.read_f32() * 100.0)))
            translations.append(track)

    scales = []
    if scale_count > 0:
        reader.position = scale_data_off
        for t in range(scale_count):
            track = [reader.read_f32() for _ in range(len(scale_keys[t]))]
            scales.append(track)

    if reverse:
        rotations.reverse()
        rot_keys.reverse()
        translations.reverse()
        trans_keys.reverse()
        scales.reverse()
        scale_keys.reverse()

    meta = AnimationCodecMetadata(
        codec=codec, frame_count=frame_count, rotation_track_count=rot_count, translation_track_count=trans_count,
        scale_track_count=scale_count, error_percentage=error_pct, playback_rate=playback_rate, bytes_consumed=reader.position,
        rotation_data_offset=rot_data_off, translation_data_offset=trans_data_off, scale_data_offset=scale_data_off, is_dense=False
    )
    return DecodedAnimationCodec(meta, rotations, translations, scales, rot_keys, trans_keys, scale_keys)


def _decode_curve(reader, codec, rot_count, trans_count, scale_count, error_pct, playback_rate, frame_count, revised):
    reader.position = 12
    trans_table_rel = reader.read_u32()
    scale_table_rel = reader.read_u32()
    payload_off = reader.read_u32()
    total_size = reader.read_u32()
    reader.read_u32()

    reader.limit = total_size

    def read_offsets(table_off, count):
        if count == 0:
            return []
        reader.position = table_off
        return [payload_off + reader.read_u32() for _ in range(count)]

    rot_offsets = read_offsets(32, rot_count)
    trans_offsets = read_offsets(payload_off + trans_table_rel, trans_count)
    scale_offsets = read_offsets(payload_off + scale_table_rel, scale_count)

    full_keys = list(range(frame_count))

    rotations = []
    for t in range(rot_count):
        rotations.append(_decode_curve_rot_track(reader, rot_offsets[t], frame_count, revised))

    unit_scale = 1.0 if revised else 100.0
    translations = []
    for t in range(trans_count):
        translations.append(_decode_curve_trans_track(reader, trans_offsets[t], frame_count, unit_scale))

    scales = []
    for t in range(scale_count):
        scales.append(_decode_curve_scale_track(reader, scale_offsets[t], frame_count))

    meta = AnimationCodecMetadata(
        codec=codec, frame_count=frame_count, rotation_track_count=rot_count, translation_track_count=trans_count,
        scale_track_count=scale_count, error_percentage=error_pct, playback_rate=playback_rate, bytes_consumed=total_size,
        rotation_data_offset=payload_off, translation_data_offset=payload_off + trans_table_rel,
        scale_data_offset=payload_off + scale_table_rel, is_dense=True
    )
    return DecodedAnimationCodec(
        meta, rotations, translations, scales, [full_keys.copy() for _ in range(rot_count)],
        [full_keys.copy() for _ in range(trans_count)], [full_keys.copy() for _ in range(scale_count)]
    )


def _decode_curve_rot_track(reader, offset, frame_count, revised):
    reader.position = offset
    reader.read_u16()
    key_count = reader.read_u16()
    flags = reader.read_u8()
    reader.read_u8()
    reader.read_s16()

    dense = (flags & 1) != 0
    if not dense:
        keys = [0]
        cur = 0
        for _ in range(key_count):
            cur += reader.read_u8()
            keys.append(cur)
    else:
        keys = []

    output = []
    prev = None
    if dense:
        for _ in range(frame_count):
            a, b, c = reader.read_s16(), reader.read_s16(), reader.read_s16()
            raw = decompress_revised_quaternion(a, b, c) if revised else decompress_curve_quaternion(a, b, c)
            q = normalize_quaternion(raw, prev)
            output.append(q)
            prev = q
        return output

    if frame_count == 1:
        a, b, c = reader.read_s16(), reader.read_s16(), reader.read_s16()
        raw = decompress_revised_quaternion(a, b, c) if revised else decompress_curve_quaternion(a, b, c)
        return [normalize_quaternion(raw)]

    p1, p2 = None, None
    tx, ty, tz, tw = 0, 0, 0, 0
    seg = 0
    cur_k, next_k = 0, 0

    for f in range(frame_count):
        if seg < len(keys) - 1 and keys[seg] == f and f < frame_count - 1:
            a, b, c = reader.read_s16(), reader.read_s16(), reader.read_s16()
            p1 = decompress_revised_quaternion(a, b, c) if revised else decompress_curve_quaternion(a, b, c)
            tx = reader.read_u8()
            ty = reader.read_u8()
            tz = reader.read_u8()
            tw = reader.read_u8()
            a, b, c = reader.read_s16(), reader.read_s16(), reader.read_s16()
            p2 = decompress_revised_quaternion(a, b, c) if revised else decompress_curve_quaternion(a, b, c)
            cur_k = keys[seg]
            next_k = keys[seg + 1]
            seg += 1
            reader.position -= 6

        t = (f - cur_k) / float(max(1, next_k - cur_k))
        tan1 = Quaternion((
            calculate_tangent_scalar((tw >> 4) - 7, p1.w, p2.w),
            calculate_tangent_scalar((tx >> 4) - 7, p1.x, p2.x),
            calculate_tangent_scalar((ty >> 4) - 7, p1.y, p2.y),
            calculate_tangent_scalar((tz >> 4) - 7, p1.z, p2.z),
        ))
        tan2 = Quaternion((
            calculate_tangent_scalar((tw & 15) - 7, p1.w, p2.w),
            calculate_tangent_scalar((tx & 15) - 7, p1.x, p2.x),
            calculate_tangent_scalar((ty & 15) - 7, p1.y, p2.y),
            calculate_tangent_scalar((tz & 15) - 7, p1.z, p2.z),
        ))
        raw = Quaternion((
            hermite_scalar(t, tan1.w, tan2.w, p1.w, p2.w),
            hermite_scalar(t, tan1.x, tan2.x, p1.x, p2.x),
            hermite_scalar(t, tan1.y, tan2.y, p1.y, p2.y),
            hermite_scalar(t, tan1.z, tan2.z, p1.z, p2.z),
        ))
        q = normalize_quaternion(raw, prev)
        output.append(q)
        prev = q
    return output


def _decode_curve_trans_track(reader, offset, frame_count, unit_scale):
    reader.position = offset
    reader.read_u16()
    key_count = reader.read_u16()
    flags = reader.read_u8()
    reader.read_u8()
    reader.read_u16()
    off_x, off_y, off_z = reader.read_f32(), reader.read_f32(), reader.read_f32()
    rng = reader.read_f32()

    dense = (flags & 1) != 0
    if not dense:
        keys = [0]
        cur = 0
        for _ in range(key_count):
            cur += reader.read_u8()
            keys.append(cur)
    else:
        keys = []

    def expand(v):
        return Vector((
            (v.x * rng + off_x) * unit_scale,
            (v.y * rng + off_y) * unit_scale,
            (v.z * rng + off_z) * unit_scale,
        ))

    def read_norm_vec():
        return Vector((reader.read_s16() / 32767.0, reader.read_s16() / 32767.0, reader.read_s16() / 32767.0))

    if dense:
        return [expand(read_norm_vec()) for _ in range(frame_count)]

    if frame_count == 1:
        return [expand(read_norm_vec())]

    output = []
    p1, p2 = None, None
    tx, ty, tz = 0, 0, 0
    seg = 0
    cur_k, next_k = 0, 0

    for f in range(frame_count):
        if seg < len(keys) - 1 and keys[seg] == f and f < frame_count - 1:
            p1 = read_norm_vec()
            tx = reader.read_u8()
            ty = reader.read_u8()
            tz = reader.read_u8()
            p2 = read_norm_vec()
            cur_k = keys[seg]
            next_k = keys[seg + 1]
            seg += 1
            reader.position -= 6

        t = (f - cur_k) / float(max(1, next_k - cur_k))
        tan1 = Vector((
            calculate_tangent_scalar((tx >> 4) - 7, p1.x, p2.x),
            calculate_tangent_scalar((ty >> 4) - 7, p1.y, p2.y),
            calculate_tangent_scalar((tz >> 4) - 7, p1.z, p2.z),
        ))
        tan2 = Vector((
            calculate_tangent_scalar((tx & 15) - 7, p1.x, p2.x),
            calculate_tangent_scalar((ty & 15) - 7, p1.y, p2.y),
            calculate_tangent_scalar((tz & 15) - 7, p1.z, p2.z),
        ))
        raw = Vector((
            hermite_scalar(t, tan1.x, tan2.x, p1.x, p2.x),
            hermite_scalar(t, tan1.y, tan2.y, p1.y, p2.y),
            hermite_scalar(t, tan1.z, tan2.z, p1.z, p2.z),
        ))
        output.append(expand(raw))
    return output


def _decode_curve_scale_track(reader, offset, frame_count):
    reader.position = offset
    reader.read_u16()
    key_count = reader.read_u16()
    flags = reader.read_u8()
    reader.read_u8()
    reader.read_u16()
    off_val = reader.read_f32()
    rng = reader.read_f32()

    dense = (flags & 1) != 0
    if not dense:
        keys = [0]
        cur = 0
        for _ in range(key_count):
            cur += reader.read_u8()
            keys.append(cur)
    else:
        keys = []

    def expand(v):
        return v * rng + off_val

    def read_norm_s16():
        return reader.read_s16() / 32767.0

    if dense:
        return [expand(read_norm_s16()) for _ in range(frame_count)]

    if frame_count == 1:
        return [expand(read_norm_s16())]

    output = []
    p1, p2 = 0.0, 0.0
    tan_byte = 0
    seg = 0
    cur_k, next_k = 0, 0

    for f in range(frame_count):
        if seg < len(keys) - 1 and keys[seg] == f and f < frame_count - 1:
            p1 = read_norm_s16()
            tan_byte = reader.read_u8()
            p2 = read_norm_s16()
            cur_k = keys[seg]
            next_k = keys[seg + 1]
            seg += 1
            reader.position -= 2

        t = (f - cur_k) / float(max(1, next_k - cur_k))
        tan1 = calculate_tangent_scalar((tan_byte >> 4) - 7, p1, p2)
        tan2 = calculate_tangent_scalar((tan_byte & 15) - 7, p1, p2)
        raw = hermite_scalar(t, tan1, tan2, p1, p2)
        output.append(expand(raw))
    return output
