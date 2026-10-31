-- Little-endian binary writer for the files 3ds Max reads (shared\utils\lua_bridge.ms).
-- Strings are null-terminated; ints are int32; floats are float32.

local ffi = require("ffi")
local tobit = require("bit").tobit

local Writer = {}
Writer.__index = Writer

local maxbin = {}

function maxbin.open(path)
	local f = assert(io.open(path, "wb"))
	return setmetatable({ f = f }, Writer)
end

-- Writer that keeps the bytes in memory; :contents() returns them
function maxbin.memory()
	local parts = {}
	local sink = { write = function(_, ...) for i = 1, select("#", ...) do parts[#parts + 1] = select(i, ...) end end }
	local w = setmetatable({ f = sink }, Writer)
	function w:contents() return table.concat(parts) end
	return w
end

function Writer:string(s) self.f:write(s, "\0") end

function Writer:ints(t, n)
	n = n or #t
	if n == 0 then return end
	local buf = ffi.new("int32_t[?]", n)
	-- tobit wraps unsigned values (flags >= 2^31) to int32, as MAXScript reads them
	for i = 1, n do buf[i - 1] = tobit(t[i]) end
	self.f:write(ffi.string(buf, n * 4))
end

function Writer:floats(t, n)
	n = n or #t
	if n == 0 then return end
	local buf = ffi.new("float[?]", n)
	for i = 1, n do buf[i - 1] = t[i] end
	self.f:write(ffi.string(buf, n * 4))
end

function Writer:int(v) self:ints({ v }, 1) end
function Writer:float(v) self:floats({ v }, 1) end
function Writer:close() self.f:close() end

-- Tag fourcc string -> integer as stored in the tag ("soso" -> 0x736F736F), -1 for none
function maxbin.fourcc_int(s)
	if not s then return -1 end
	local a, b, c, d = s:byte(1, 4)
	return ((a * 256 + b) * 256 + c) * 256 + d
end

-- Tag reference { group, path }: path string, then group fourcc (luaReadTagRef in lua_bridge.ms)
function Writer:tagref(ref)
	self:string(ref.path)
	self:int(maxbin.fourcc_int(ref.group))
end

-------------------------------------------------------------------------------
-- Reading files that 3ds Max wrote (luaWrite* in lua_bridge.ms), same layout
-------------------------------------------------------------------------------

local Reader = {}
Reader.__index = Reader

function maxbin.read_file(path)
	local f = assert(io.open(path, "rb"))
	local data = f:read("*a")
	f:close()
	return setmetatable({ data = data, p = ffi.cast("const uint8_t*", data), pos = 0, size = #data }, Reader)
end

local function need(self, n)
	if self.pos + n > self.size then error("unexpected end of the data written by Max", 0) end
end

function Reader:int()
	need(self, 4)
	local v = ffi.cast("const int32_t*", self.p + self.pos)[0]
	self.pos = self.pos + 4
	return v
end

function Reader:float()
	need(self, 4)
	local v = ffi.cast("const float*", self.p + self.pos)[0]
	self.pos = self.pos + 4
	return v
end

function Reader:string()
	local stop = self.data:find("\0", self.pos + 1, true)
	if not stop then error("unterminated string in the data written by Max", 0) end
	local s = self.data:sub(self.pos + 1, stop - 1)
	self.pos = stop
	return s
end

return maxbin
