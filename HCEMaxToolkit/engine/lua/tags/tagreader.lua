-- Halo CE tag file reader (LuaJIT): big-endian tag -> Lua tables keyed by field name.
-- After each element come its tag-ref paths, data bytes and child blocks, in field order.
local ffi = require("ffi")
local bit = require("bit")
local tagdefs = require("core.halo1.tagdefs")

local K = tagdefs.K
local bor, lshift = bit.bor, bit.lshift
local ffi_string = ffi.string

ffi.cdef [[ typedef union { int32_t i; float f; } h1tag_i32f; ]]
local conv = ffi.new("h1tag_i32f")

local tagreader = {}

-- Current file buffer (0-based byte pointer) and its Lua string anchor
local p, anchor, file_size

local function i8(o)
    local v = p[o];
    if v >= 128 then
        return v - 256
    end
    return v
end

local function u16(o)
    return p[o] * 256 + p[o + 1]
end

local function i16(o)
    local v = p[o] * 256 + p[o + 1];
    if v >= 32768 then
        return v - 65536
    end
    return v
end

local function i32(o)
    return bor(lshift(p[o], 24), lshift(p[o + 1], 16), lshift(p[o + 2], 8), p[o + 3])
end

local function u32(o)
    local v = i32(o);
    if v < 0 then
        return v + 4294967296
    end
    return v
end

local function f32(o)
    conv.i = i32(o);
    return conv.f
end

local function fourcc(o)
    if p[o] == 0xFF and p[o + 1] == 0xFF and p[o + 2] == 0xFF and p[o + 3] == 0xFF then
        return nil
    end
    return ffi_string(p + o, 4)
end

local function cstring(o, max)
    local n = 0
    while n < max and p[o + n] ~= 0 do
        n = n + 1
    end
    return ffi_string(p + o, n)
end

local defs -- tagdefs instance used by the current read
local warnings -- list of strings for the current read

-- Fixed part of one element; blocks/data keep their count/size until read_ext.
local read_struct

read_struct = function(c, base)
    local e = {}
    local fields = c.fields
    for i = 1, #fields do
        local fd = fields[i]
        local o = base + fd.offset
        local k = fd.kind
        local v
        if k == K.F32 then
            v = f32(o)
        elseif k == K.I16 then
            v = i16(o)
        elseif k == K.F32x3 then
            v = {f32(o), f32(o + 4), f32(o + 8)}
        elseif k == K.I32 then
            v = i32(o)
        elseif k == K.U32 then
            v = u32(o)
        elseif k == K.U16 then
            v = u16(o)
        elseif k == K.I8 then
            v = i8(o)
        elseif k == K.U8 then
            v = p[o]
        elseif k == K.F32x2 then
            v = {f32(o), f32(o + 4)}
        elseif k == K.F32x4 then
            v = {f32(o), f32(o + 4), f32(o + 8), f32(o + 12)}
        elseif k == K.TAGREF then
            v = {group = fourcc(o), path = ""}
        elseif k == K.BLOCK then
            v = i32(o) -- count for now
        elseif k == K.DATA then
            v = i32(o) -- size for now
        elseif k == K.STRING then
            v = cstring(o, 32)
        elseif k == K.STRUCT then
            v = read_struct(fd.sub, o)
        elseif k == K.ARRAY then
            v = {}
            local sub, size = fd.sub, fd.sub.size
            for j = 1, fd.count do
                v[j] = read_struct(sub, o + (j - 1) * size)
            end
        elseif k == K.I16x2 then
            v = {i16(o), i16(o + 2)}
        elseif k == K.I16x4 then
            v = {i16(o), i16(o + 2), i16(o + 4), i16(o + 6)}
        elseif k == K.FOURCC then
            v = fourcc(o)
        end
        e[fd.key] = v
    end
    return e
end

local read_block

-- Reads the data stored after an element (paths, data, child blocks); returns new cursor.
local function read_ext(c, base, e, cursor)
    local fields = c.fields
    for i = 1, #fields do
        local fd = fields[i]
        local k = fd.kind
        if k == K.TAGREF then
            local len = i32(base + fd.offset + 8)
            if len > 0 then
                if cursor + len >= file_size then
                    error(
                        ("tag reference '%s' path runs past end of file at 0x%X (desync)"):format(
                            fd.key, cursor), 0)
                end
                local path = ffi_string(p + cursor, len)
                if p[cursor + len] ~= 0 then
                    error(("tag reference '%s' path not null-terminated at 0x%X (desync)"):format(
                              fd.key, cursor), 0)
                end
                e[fd.key].path = path
                cursor = cursor + len + 1
            end
        elseif k == K.DATA then
            local size = e[fd.key]
            if size > 0 then
                if size > file_size - cursor then
                    error(("data '%s' (%d bytes) runs past end of file at 0x%X (desync)"):format(
                              fd.key, size, cursor), 0)
                end
                e[fd.key] = {offset = cursor, size = size}
                cursor = cursor + size
            else
                e[fd.key] = {offset = cursor, size = 0}
            end
        elseif k == K.BLOCK then
            local count = e[fd.key]
            if count < 0 then
                error(
                    ("block '%s' has invalid count %d at element 0x%X (desync or corrupt tag)"):format(
                        fd.key, count, base), 0)
            end
            -- Modded tags exceed stock limits; a real desync is caught by the end-of-file checks.
            if count > fd.max_count then
                warnings[#warnings + 1] = ("block '%s' has %d elements (stock maximum %d)"):format(
                                              fd.key, count, fd.max_count)
            end
            if count > 0 then
                e[fd.key], cursor = read_block(defs:block_struct(fd), count, cursor)
            else
                e[fd.key] = {}
            end
        elseif k == K.STRUCT then
            if fd.sub.has_ext then
                cursor = read_ext(fd.sub, base + fd.offset, e[fd.key], cursor)
            end
        elseif k == K.ARRAY then
            local sub = fd.sub
            if sub.has_ext then
                local arr = e[fd.key]
                for j = 1, fd.count do
                    cursor = read_ext(sub, base + fd.offset + (j - 1) * sub.size, arr[j], cursor)
                end
            end
        end
    end
    return cursor
end

read_block = function(c, count, cursor)
    local size = c.size
    if cursor + count * size > file_size then
        error(("block '%s' (%d x %d bytes) runs past end of file at 0x%X"):format(c.name, count,
                                                                                  size, cursor), 0)
    end
    local list = {}
    for j = 1, count do
        list[j] = read_struct(c, cursor + (j - 1) * size)
    end
    local ext = cursor + count * size
    if c.has_ext then
        for j = 1, count do
            ext = read_ext(c, cursor + (j - 1) * size, list[j], ext)
        end
    end
    return list, ext
end

-------------------------------------------------------------------------------

-- Returns { group, fourcc, version, root = <element table>, root_struct, size, warnings, bytes }.
function tagreader.read_file(d, path)
    local f, err = io.open(path, "rb")
    if not f then
        error("cannot open " .. path .. ": " .. tostring(err), 0)
    end
    local data = f:read("*a")
    f:close()
    return tagreader.read_string(d, data)
end

function tagreader.read_string(d, data)
    if #data < 64 then
        error("file too small to be a tag", 0)
    end
    anchor = data
    file_size = #data
    p = ffi.cast("const uint8_t*", data)
    defs = d
    warnings = {}

    local group_fourcc = ffi_string(p + 36, 4)
    if ffi_string(p + 60, 4) ~= "blam" then
        error("not a Halo tag file (no 'blam' signature)", 0)
    end
    local group = d:group_by_fourcc(group_fourcc)
    if not group then
        error("unknown tag group '" .. group_fourcc .. "'", 0)
    end

    local root_c = d:root_struct(group)
    local list, cursor = read_block(root_c, 1, 64)
    if cursor ~= file_size then
        error(
            ("tag read ended at byte %d but file has %d bytes (definition does not match tag)"):format(
                cursor, file_size), 0)
    end

    local result = {
        group = group.name,
        fourcc = group_fourcc,
        version = u16(56),
        root = list[1],
        root_struct = root_c, -- compiled struct of root (field order, names and types)
        size = file_size,
        warnings = warnings,
        bytes = data -- whole file; data fields are { offset, size } into it
    }
    p, anchor, defs, warnings = nil, nil, nil, nil
    return result
end

return tagreader
