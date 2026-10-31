-- Reader over the raw bytes of a tag file (tag.bytes): reads numbers and moves forward.
-- Tag fields are big-endian (be), compressed animation data little-endian (le). Positions start at 0.

local ffi = require "ffi" -- LuaJIT: C types and direct memory access
local bit = require "bit" -- LuaJIT: bit operations on 32-bit integers
local bor, lshift = bit.bor, bit.lshift

-- The same 4 bytes as an integer or a float: write .i, read .f
ffi.cdef [[ typedef union { int32_t i; float f; } h1bytes_bits; ]]
local bits = ffi.new("h1bytes_bits")

-- Functions shared by every reader that byteReader.open creates
local reader = {}
reader.__index = reader

local byteReader = {}

-- data: the file as a Lua string (kept so the pointer stays valid); pos: start position
function byteReader.open(data, pos)
	return setmetatable({ data = data, p = ffi.cast("const uint8_t*", data), pos = pos or 0 }, reader)
end

-- Moves to a position
function reader:seek(pos) self.pos = pos end

-- Signed 16-bit, big-endian
function reader:beI16()
	local p, o = self.p, self.pos
	self.pos = o + 2
	local v = p[o] * 256 + p[o + 1]
	return v >= 32768 and v - 65536 or v
end

-- 32-bit float, big-endian
function reader:beFloat()
	local p, o = self.p, self.pos
	self.pos = o + 4
	bits.i = bor(lshift(p[o], 24), lshift(p[o + 1], 16), lshift(p[o + 2], 8), p[o + 3])
	return bits.f
end

-- Unsigned 16-bit, little-endian
function reader:leU16()
	local p, o = self.p, self.pos
	self.pos = o + 2
	return p[o] + p[o + 1] * 256
end

-- Signed 32-bit, little-endian (values above 2^31 come back negative, like MAXScript's readLong)
function reader:leI32()
	local p, o = self.p, self.pos
	self.pos = o + 4
	return bor(p[o], lshift(p[o + 1], 8), lshift(p[o + 2], 16), lshift(p[o + 3], 24))
end

-- 32-bit float, little-endian
function reader:leFloat()
	bits.i = self:leI32()
	return bits.f
end

return byteReader
