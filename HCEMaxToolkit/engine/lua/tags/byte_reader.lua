-- Reader over the raw bytes of a tag file (tag.bytes): big-endian like the tag fields,
-- little-endian like some data blobs (compressed animations). Offsets are 0-based.

local ffi = require("ffi")
local bit = require("bit")
local bor, lshift = bit.bor, bit.lshift

ffi.cdef [[ typedef union { int32_t i; float f; } h1bytes_bits; ]]
local bits = ffi.new("h1bytes_bits")

local Reader = {}
Reader.__index = Reader

local bytes = {}

-- data: Lua string (kept referenced so the pointer stays valid); pos: start offset
function bytes.reader(data, pos)
	return setmetatable({ data = data, p = ffi.cast("const uint8_t*", data), pos = pos or 0 }, Reader)
end

function Reader:seek(pos) self.pos = pos end

function Reader:beI16()
	local p, o = self.p, self.pos
	self.pos = o + 2
	local v = p[o] * 256 + p[o + 1]
	return v >= 32768 and v - 65536 or v
end

function Reader:beFloat()
	local p, o = self.p, self.pos
	self.pos = o + 4
	bits.i = bor(lshift(p[o], 24), lshift(p[o + 1], 16), lshift(p[o + 2], 8), p[o + 3])
	return bits.f
end

function Reader:leU16()
	local p, o = self.p, self.pos
	self.pos = o + 2
	return p[o] + p[o + 1] * 256
end

-- Signed 32-bit (unsigned values above 2^31 come back negative, like MAXScript's readLong)
function Reader:leI32()
	local p, o = self.p, self.pos
	self.pos = o + 4
	return bor(p[o], lshift(p[o + 1], 8), lshift(p[o + 2], 16), lshift(p[o + 3], 24))
end

function Reader:leFloat()
	bits.i = self:leI32()
	return bits.f
end

return bytes
