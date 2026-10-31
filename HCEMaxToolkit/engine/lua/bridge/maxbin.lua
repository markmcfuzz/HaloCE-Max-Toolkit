-- Binary files exchanged with 3ds Max (read and written there by shared\utils\lua_bridge.ms).
-- Little-endian: ints are int32, floats are float32, strings end with a zero byte.
-- Each file starts with a name and a version, so both sides know they speak the same format.
local ffi = require "ffi" -- LuaJIT: C types and direct memory access
local tobit = require("bit").tobit

local maxbin = {}

-------------------------------------------------------------------------------
-- Writing files for Max (read there with luaReadInt, readFloat, readString...)
-------------------------------------------------------------------------------

-- Functions shared by every writer
local writer = {}
writer.__index = writer

-- Writer to a file. With a name and version, writes them first (luaOpenOutput checks them in Max).
function maxbin.open(path, name, version)
    local output = setmetatable({file = assert(io.open(path, "wb"))}, writer)
    if name then
        output:string(name)
        output:int(version)
    end
    return output
end

-- Writer that keeps the bytes in memory; :contents() returns them
function maxbin.memory()
    local parts = {}
    local memoryFile = {
        write = function(_, text)
            parts[#parts + 1] = text
        end
    }
    local output = setmetatable({file = memoryFile}, writer)
    function output:contents()
        return table.concat(parts)
    end
    return output
end

-- Bytes as they are (e.g. the contents of a memory writer)
function writer:bytes(data)
    self.file:write(data)
end

-- Text followed by a zero byte
function writer:string(text)
    self.file:write(text .. "\0")
end

-- The first count values of a list (default: all) as int32
function writer:ints(values, count)
    count = count or #values
    if count == 0 then
        return
    end
    local buffer = ffi.new("int32_t[?]", count)
    -- tobit wraps unsigned values (flags >= 2^31) to int32, as MAXScript reads them
    for i = 1, count do
        buffer[i - 1] = tobit(values[i])
    end
    self.file:write(ffi.string(buffer, count * 4))
end

-- The first count values of a list (default: all) as float32
function writer:floats(values, count)
    count = count or #values
    if count == 0 then
        return
    end
    local buffer = ffi.new("float[?]", count)
    for i = 1, count do
        buffer[i - 1] = values[i]
    end
    self.file:write(ffi.string(buffer, count * 4))
end

function writer:int(value)
    self:ints({value}, 1)
end
function writer:float(value)
    self:floats({value}, 1)
end
function writer:close()
    self.file:close()
end

-- Tag fourcc text -> integer as stored in the tag ("soso" -> 0x736F736F), -1 for none
local function fourccInt(fourcc)
    if not fourcc then
        return -1
    end
    local a, b, c, d = fourcc:byte(1, 4)
    return ((a * 256 + b) * 256 + c) * 256 + d
end

-- Tag reference { group, path }: path, then group fourcc (luaReadTagRef in Max)
function writer:tagref(ref)
    self:string(ref.path)
    self:int(fourccInt(ref.group))
end

-------------------------------------------------------------------------------
-- Reading files that Max wrote (luaWriteInt, luaWriteFloat, luaWriteString in Max)
-------------------------------------------------------------------------------

-- Functions shared by every reader
local reader = {}
reader.__index = reader

-- Reader of a whole file. With a name and version, the file must start with them.
function maxbin.readFile(path, name, version)
    local f = assert(io.open(path, "rb"))
    local data = f:read("*a")
    f:close()
    local input = setmetatable({
        data = data,
        p = ffi.cast("const uint8_t*", data),
        pos = 0,
        size = #data
    }, reader)
    if name and (input:string() ~= name or input:int() ~= version) then
        error(("unexpected data from Max (expected %s v%d)"):format(name, version), 0)
    end
    return input
end

-- Errors when fewer than count bytes are left
local function checkLeft(input, count)
    if input.pos + count > input.size then
        error("unexpected end of the data written by Max", 0)
    end
end

function reader:int()
    checkLeft(self, 4)
    local value = ffi.cast("const int32_t*", self.p + self.pos)[0]
    self.pos = self.pos + 4
    return value
end

function reader:float()
    checkLeft(self, 4)
    local value = ffi.cast("const float*", self.p + self.pos)[0]
    self.pos = self.pos + 4
    return value
end

-- Text up to the next zero byte
function reader:string()
    local stop = self.data:find("\0", self.pos + 1, true)
    if not stop then
        error("unterminated string in the data written by Max", 0)
    end
    local text = self.data:sub(self.pos + 1, stop - 1)
    self.pos = stop
    return text
end

return maxbin
