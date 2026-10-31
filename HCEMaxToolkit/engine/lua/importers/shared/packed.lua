-- Packed vertex values shared by the importers (same rules as the previous MAXScript importers).

local bit = require("bit")
local band, rshift = bit.band, bit.rshift
local sqrt = math.sqrt

local packed = {}

function packed.normalize(x, y, z)
	local len = sqrt(x * x + y * y + z * z)
	if len == 0 then return 0, 0, 0 end
	return x / len, y / len, z / len
end

-- 11.11.10-bit packed normal, sign bits 10, 21 and 31 (decompressNormal in the previous MAXScript importers)
function packed.decompressNormal(n)
	local i = band(n, 1023) / 1023
	local j = band(rshift(n, 11), 1023) / 1023
	local k = band(rshift(n, 22), 511) / 511
	if band(n, 0x400) ~= 0 then i = i - 1 end
	if band(n, 0x200000) ~= 0 then j = j - 1 end
	if band(n, 0x80000000) ~= 0 then k = k - 1 end
	return packed.normalize(i, j, k)
end

return packed
