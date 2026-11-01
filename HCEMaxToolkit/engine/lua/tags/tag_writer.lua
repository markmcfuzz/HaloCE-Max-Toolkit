-- Writes a Halo CE tag file from Lua tables shaped like tag_reader.lua's (fields keyed by name).
-- Same layout as the reader: each element's fixed part, then its tail (ref paths, child blocks).
local ffi = require "ffi"
local bit = require "bit"
local tagDefs = require "tags.tag_defs"

local readAs = tagDefs.readAs
local band, bnot, bxor, rshift = bit.band, bit.bnot, bit.bxor, bit.rshift

ffi.cdef [[ typedef union { int32_t i; float f; } h1tag_w_i32f; ]]
local bits = ffi.new("h1tag_w_i32f")

local tagWriter = {}

local definitions -- definitions of the tag being written

-------------------------------------------------------------------------------
-- Numbers into a byte buffer at position at, big-endian like the reader
-------------------------------------------------------------------------------

local function put8(p, at, v)
    p[at] = band(v, 0xFF)
end

local function put16(p, at, v)
    p[at] = band(rshift(v, 8), 0xFF)
    p[at + 1] = band(v, 0xFF)
end

local function put32(p, at, v)
    v = bit.tobit(v % 4294967296)
    p[at] = band(rshift(v, 24), 0xFF)
    p[at + 1] = band(rshift(v, 16), 0xFF)
    p[at + 2] = band(rshift(v, 8), 0xFF)
    p[at + 3] = band(v, 0xFF)
end

local function putFloat(p, at, v)
    bits.f = v
    put32(p, at, bits.i)
end

-- 4-letter tag group, or FF FF FF FF when there is none
local function putFourcc(p, at, fourcc)
    if fourcc == nil or fourcc == "" then
        put32(p, at, -1)
        return
    end
    for i = 1, 4 do
        p[at + i - 1] = fourcc:byte(i) or 0
    end
end

-------------------------------------------------------------------------------
-- Elements
-------------------------------------------------------------------------------

-- Fixed part of one element into p at elementStart (padding stays zero)
local function writeFixed(structDef, element, p, elementStart)
    for _, field in ipairs(structDef.fields) do
        local at = elementStart + field.offset
        local value = element[field.key]
        local r = field.readAs
        if r == readAs.float then
            putFloat(p, at, value)
        elseif r == readAs.float2 or r == readAs.float3 or r == readAs.float4 then
            for i, v in ipairs(value) do
                putFloat(p, at + (i - 1) * 4, v)
            end
        elseif r == readAs.int8 or r == readAs.uint8 then
            put8(p, at, value)
        elseif r == readAs.int16 or r == readAs.uint16 then
            put16(p, at, value)
        elseif r == readAs.int32 or r == readAs.uint32 then
            put32(p, at, value)
        elseif r == readAs.int16x2 or r == readAs.int16x4 then
            for i, v in ipairs(value) do
                put16(p, at + (i - 1) * 2, v)
            end
        elseif r == readAs.string then
            local text = value:sub(1, 31)
            for i = 1, #text do
                p[at + i - 1] = text:byte(i)
            end
        elseif r == readAs.fourcc then
            putFourcc(p, at, value)
        elseif r == readAs.tagRef then
            -- group, pointer (0), path length, tag index (-1)
            putFourcc(p, at, value.group)
            put32(p, at + 8, #value.path)
            put32(p, at + 12, -1)
        elseif r == readAs.block then
            put32(p, at, #value)
        elseif r == readAs.struct then
            writeFixed(field.sub, value, p, at)
        elseif r == readAs.array then
            for j = 1, field.count do
                writeFixed(field.sub, value[j], p, at + (j - 1) * field.sub.size)
            end
        elseif r == readAs.data then
            error(("data field '%s' can't be written yet"):format(field.key), 0)
        end
    end
end

local writeBlock -- writeTail and writeBlock call each other

-- Tail of one element (ref paths and child blocks, in field order) appended to out
local function writeTail(structDef, element, out)
    for _, field in ipairs(structDef.fields) do
        local r = field.readAs
        if r == readAs.tagRef then
            local path = element[field.key].path
            if #path > 0 then
                out[#out + 1] = path .. "\0"
            end
        elseif r == readAs.block then
            writeBlock(definitions:blockStruct(field), element[field.key], out)
        elseif r == readAs.struct then
            if field.sub.hasTail then
                writeTail(field.sub, element[field.key], out)
            end
        elseif r == readAs.array then
            if field.sub.hasTail then
                for j = 1, field.count do
                    writeTail(field.sub, element[field.key][j], out)
                end
            end
        end
    end
end

-- All the fixed parts of a block, then the tail of each element
writeBlock = function(structDef, list, out)
    local size = structDef.size
    for _, element in ipairs(list) do
        local p = ffi.new("uint8_t[?]", size)
        writeFixed(structDef, element, p, 0)
        out[#out + 1] = ffi.string(p, size)
    end
    if structDef.hasTail then
        for _, element in ipairs(list) do
            writeTail(structDef, element, out)
        end
    end
end

-------------------------------------------------------------------------------
-- Header checksum: CRC-32 of everything after the header, without the final inversion
-------------------------------------------------------------------------------

local crcTable
local function crc32NotFinal(text)
    if not crcTable then
        crcTable = {}
        for i = 0, 255 do
            local c = i
            for _ = 1, 8 do
                if band(c, 1) == 1 then
                    c = bxor(rshift(c, 1), 0xEDB88320)
                else
                    c = rshift(c, 1)
                end
            end
            crcTable[i] = c
        end
    end
    local crc = bnot(0)
    for i = 1, #text do
        crc = bxor(crcTable[band(bxor(crc, text:byte(i)), 0xFF)], rshift(crc, 8))
    end
    return crc
end

-------------------------------------------------------------------------------

-- Tag file bytes. groupName: "vehicle"; root: the main element (as tag_reader returns it)
function tagWriter.toBytes(defs, groupName, root)
    definitions = defs
    local group = defs:group(groupName)
    local out = {}
    writeBlock(defs:rootStruct(group), {root}, out)
    local body = table.concat(out)
    definitions = nil

    -- 64-byte header: group at 36, checksum at 40, header size, version at 56, "blam" at 60
    local header = ffi.new("uint8_t[64]")
    putFourcc(header, 36, group.tag)
    put32(header, 40, crc32NotFinal(body))
    put32(header, 44, 64)
    put16(header, 56, group.version)
    header[59] = 0xFF
    putFourcc(header, 60, "blam")
    return ffi.string(header, 64) .. body
end

function tagWriter.writeFile(defs, groupName, root, path)
    local bytes = tagWriter.toBytes(defs, groupName, root)
    local f, err = io.open(path, "wb")
    if not f then
        error("cannot write " .. path .. ": " .. tostring(err), 0)
    end
    f:write(bytes)
    f:close()
end

return tagWriter
