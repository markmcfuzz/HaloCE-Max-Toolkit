-- Reads a Halo CE tag file into Lua tables keyed by field name (tag_defs.lua says where each field is).
-- Every element has a fixed part and, after it, a tail: tag-ref paths, data bytes and child blocks.
-- openBytes reads the raw bytes inside data fields (e.g. animation frames).
local ffi = require "ffi" -- LuaJIT: C types and direct memory access
local bit = require "bit" -- LuaJIT: bit operations on 32-bit integers
local tagDefs = require "tags.tag_defs"

local readAs = tagDefs.readAs
local bor, lshift = bit.bor, bit.lshift
local ffiString = ffi.string

-- The same 4 bytes as an integer or a float: write .i, read .f
ffi.cdef [[ typedef union { int32_t i; float f; } h1tag_i32f; ]]
local bits = ffi.new("h1tag_i32f")

local tagReader = {}

-- The tag being read: byte pointer into its text (positions start at 0), size, definitions
-- and warnings. readTag keeps the text alive while tagBytes points into it.
local tagBytes, fileSize, definitions, warnings

-------------------------------------------------------------------------------
-- Numbers at byte position at of the bytes p points to. Tag fields are big-endian (the high
-- byte comes first); compressed animation data is little-endian (the low byte comes first).
-------------------------------------------------------------------------------

local function int8(p, at)
    local v = p[at]
    if v >= 128 then
        return v - 256
    end
    return v
end

local function uint16(p, at)
    return p[at] * 256 + p[at + 1]
end

local function int16(p, at)
    local v = p[at] * 256 + p[at + 1]
    if v >= 32768 then
        return v - 65536
    end
    return v
end

local function int32(p, at)
    return bor(lshift(p[at], 24), lshift(p[at + 1], 16), lshift(p[at + 2], 8), p[at + 3])
end

local function uint32(p, at)
    local v = int32(p, at)
    if v < 0 then
        return v + 4294967296
    end
    return v
end

local function float(p, at)
    bits.i = int32(p, at)
    return bits.f
end

-- 4-letter tag group ("bitm"), or nil when empty (FF FF FF FF)
local function fourcc(p, at)
    if p[at] == 0xFF and p[at + 1] == 0xFF and p[at + 2] == 0xFF and p[at + 3] == 0xFF then
        return nil
    end
    return ffiString(p + at, 4)
end

-- Text up to the first zero byte, at most maxLength bytes
local function text(p, at, maxLength)
    local n = 0
    while n < maxLength and p[at + n] ~= 0 do
        n = n + 1
    end
    return ffiString(p + at, n)
end

local function leUint16(p, at)
    return p[at] + p[at + 1] * 256
end

-- Values above 2^31 come back negative, like MAXScript's readLong
local function leInt32(p, at)
    return bor(p[at], lshift(p[at + 1], 8), lshift(p[at + 2], 16), lshift(p[at + 3], 24))
end

local function leFloat(p, at)
    bits.i = leInt32(p, at)
    return bits.f
end

-------------------------------------------------------------------------------
-- Elements
-------------------------------------------------------------------------------

-- Fixed part of one element starting at byte elementStart. Blocks and data keep their count
-- and size until readTail; tag refs get their group now and their path in readTail.
-- The most common kinds are checked first (it runs for every field of every element).
local function readFixed(structDef, elementStart)
    local element = {}
    local fields = structDef.fields
    for i = 1, #fields do
        local field = fields[i]
        local at = elementStart + field.offset
        local fieldReadAs = field.readAs
        local value
        if fieldReadAs == readAs.float then
            value = float(tagBytes, at)
        elseif fieldReadAs == readAs.int16 then
            value = int16(tagBytes, at)
        elseif fieldReadAs == readAs.float3 then
            value = {float(tagBytes, at), float(tagBytes, at + 4), float(tagBytes, at + 8)}
        elseif fieldReadAs == readAs.int32 then
            value = int32(tagBytes, at)
        elseif fieldReadAs == readAs.uint32 then
            value = uint32(tagBytes, at)
        elseif fieldReadAs == readAs.uint16 then
            value = uint16(tagBytes, at)
        elseif fieldReadAs == readAs.int8 then
            value = int8(tagBytes, at)
        elseif fieldReadAs == readAs.uint8 then
            value = tagBytes[at]
        elseif fieldReadAs == readAs.float2 then
            value = {float(tagBytes, at), float(tagBytes, at + 4)}
        elseif fieldReadAs == readAs.float4 then
            value = {
                float(tagBytes, at),
                float(tagBytes, at + 4),
                float(tagBytes, at + 8),
                float(tagBytes, at + 12)
            }
        elseif fieldReadAs == readAs.tagRef then
            value = {group = fourcc(tagBytes, at), path = ""}
        elseif fieldReadAs == readAs.block then
            value = int32(tagBytes, at) -- element count for now
        elseif fieldReadAs == readAs.data then
            value = int32(tagBytes, at) -- byte size for now
        elseif fieldReadAs == readAs.string then
            value = text(tagBytes, at, 32)
        elseif fieldReadAs == readAs.struct then
            value = readFixed(field.sub, at)
        elseif fieldReadAs == readAs.array then
            value = {}
            local sub = field.sub
            for j = 1, field.count do
                value[j] = readFixed(sub, at + (j - 1) * sub.size)
            end
        elseif fieldReadAs == readAs.int16x2 then
            value = {int16(tagBytes, at), int16(tagBytes, at + 2)}
        elseif fieldReadAs == readAs.int16x4 then
            value = {
                int16(tagBytes, at),
                int16(tagBytes, at + 2),
                int16(tagBytes, at + 4),
                int16(tagBytes, at + 6)
            }
        elseif fieldReadAs == readAs.fourcc then
            value = fourcc(tagBytes, at)
        end
        element[field.key] = value
    end
    return element
end

local readBlock -- defined below; readTail and readBlock call each other

-- Reads the tail of one element (its tag-ref paths, data and child blocks, in field order),
-- which starts at tailPos. Returns where the next tail starts.
local function readTail(structDef, elementStart, element, tailPos)
    local fields = structDef.fields
    for i = 1, #fields do
        local field = fields[i]
        local fieldReadAs = field.readAs
        if fieldReadAs == readAs.tagRef then
            -- Path length is at byte 8 of the tag ref; the path ends with a zero byte
            local length = int32(tagBytes, elementStart + field.offset + 8)
            if length > 0 then
                if tailPos + length >= fileSize then
                    error(
                        ("tag reference '%s' path runs past end of file at 0x%X (desync)"):format(
                            field.key, tailPos), 0)
                end
                local path = ffiString(tagBytes + tailPos, length)
                if tagBytes[tailPos + length] ~= 0 then
                    error(("tag reference '%s' path not null-terminated at 0x%X (desync)"):format(
                              field.key, tailPos), 0)
                end
                element[field.key].path = path
                tailPos = tailPos + length + 1
            end
        elseif fieldReadAs == readAs.data then
            -- Data stays in the file: { offset, size } into tag.bytes
            local size = element[field.key]
            if size > 0 then
                if size > fileSize - tailPos then
                    error(("data '%s' (%d bytes) runs past end of file at 0x%X (desync)"):format(
                              field.key, size, tailPos), 0)
                end
                element[field.key] = {offset = tailPos, size = size}
                tailPos = tailPos + size
            else
                element[field.key] = {offset = tailPos, size = 0}
            end
        elseif fieldReadAs == readAs.block then
            local count = element[field.key]
            if count < 0 then
                error(
                    ("block '%s' has invalid count %d at element 0x%X (desync or corrupt tag)"):format(
                        field.key, count, elementStart), 0)
            end
            -- Modded tags exceed stock limits; a real desync is caught by the end-of-file checks
            if count > field.maxCount then
                warnings[#warnings + 1] = ("block '%s' has %d elements (stock maximum %d)"):format(
                                              field.key, count, field.maxCount)
            end
            if count > 0 then
                element[field.key], tailPos = readBlock(definitions:blockStruct(field), count,
                                                        tailPos)
            else
                element[field.key] = {}
            end
        elseif fieldReadAs == readAs.struct then
            if field.sub.hasTail then
                tailPos = readTail(field.sub, elementStart + field.offset, element[field.key],
                                   tailPos)
            end
        elseif fieldReadAs == readAs.array then
            local sub = field.sub
            if sub.hasTail then
                local list = element[field.key]
                for j = 1, field.count do
                    tailPos = readTail(sub, elementStart + field.offset + (j - 1) * sub.size,
                                       list[j], tailPos)
                end
            end
        end
    end
    return tailPos
end

-- Reads count elements starting at blockStart: first all their fixed parts, then the tail of
-- each one in order. Returns the element list and where the block ends.
readBlock = function(structDef, count, blockStart)
    local size = structDef.size
    if blockStart + count * size > fileSize then
        error(("block '%s' (%d x %d bytes) runs past end of file at 0x%X"):format(structDef.name,
                                                                                  count, size,
                                                                                  blockStart), 0)
    end
    local list = {}
    for j = 1, count do
        list[j] = readFixed(structDef, blockStart + (j - 1) * size)
    end
    local tailPos = blockStart + count * size
    if structDef.hasTail then
        for j = 1, count do
            tailPos = readTail(structDef, blockStart + (j - 1) * size, list[j], tailPos)
        end
    end
    return list, tailPos
end

-------------------------------------------------------------------------------

-- Reads a tag already loaded as a Lua string. The 64-byte header has the group fourcc at
-- byte 36, the version at 56 and "blam" at 60; the tag's main element starts at byte 64.
local function readTag(defs, tagData)
    if #tagData < 64 then
        error("file too small to be a tag", 0)
    end
    fileSize = #tagData
    tagBytes = ffi.cast("const uint8_t*", tagData)
    definitions = defs
    warnings = {}

    local groupFourcc = ffiString(tagBytes + 36, 4)
    if ffiString(tagBytes + 60, 4) ~= "blam" then
        error("not a Halo tag file (no 'blam' signature)", 0)
    end
    local group = defs:groupByFourcc(groupFourcc)
    if not group then
        error("unknown tag group '" .. groupFourcc .. "'", 0)
    end

    local rootStruct = defs:rootStruct(group)
    local list, endPos = readBlock(rootStruct, 1, 64)
    if endPos ~= fileSize then
        error(
            ("tag read ended at byte %d but file has %d bytes (definition does not match tag)"):format(
                endPos, fileSize), 0)
    end

    local result = {
        group = group.name,
        fourcc = groupFourcc,
        version = uint16(tagBytes, 56),
        root = list[1],
        rootStruct = rootStruct, -- compiled struct of root (field order, names and types)
        size = fileSize,
        warnings = warnings,
        bytes = tagData -- whole file; data fields are { offset, size } into it
    }
    tagBytes, definitions, warnings = nil, nil, nil
    return result
end

-- defs: from tagDefs.open(). Returns { group, fourcc, version, root = <main element>,
-- rootStruct, size, warnings, bytes }.
function tagReader.readFile(defs, path)
    local f, err = io.open(path, "rb")
    if not f then
        error("cannot open " .. path .. ": " .. tostring(err), 0)
    end
    local tagData = f:read("*a")
    f:close()
    return readTag(defs, tagData)
end

-------------------------------------------------------------------------------
-- Raw bytes (the contents of data fields, e.g. animation frames)
-------------------------------------------------------------------------------

-- Functions shared by every reader that tagReader.openBytes returns
local bytesReader = {}
bytesReader.__index = bytesReader

-- Reader that moves forward as it reads. data: the bytes as a Lua string (e.g. tag.bytes,
-- kept so the pointer stays valid); pos: start position (0 = first byte).
function tagReader.openBytes(data, pos)
    return setmetatable({data = data, p = ffi.cast("const uint8_t*", data), pos = pos or 0},
                        bytesReader)
end

-- Moves to a position
function bytesReader:seek(pos)
    self.pos = pos
end

-- Signed 16-bit, big-endian
function bytesReader:beI16()
    local at = self.pos
    self.pos = at + 2
    return int16(self.p, at)
end

-- 32-bit float, big-endian
function bytesReader:beFloat()
    local at = self.pos
    self.pos = at + 4
    return float(self.p, at)
end

-- Unsigned 16-bit, little-endian
function bytesReader:leU16()
    local at = self.pos
    self.pos = at + 2
    return leUint16(self.p, at)
end

-- Signed 32-bit, little-endian
function bytesReader:leI32()
    local at = self.pos
    self.pos = at + 4
    return leInt32(self.p, at)
end

-- 32-bit float, little-endian
function bytesReader:leFloat()
    local at = self.pos
    self.pos = at + 4
    return leFloat(self.p, at)
end

return tagReader
