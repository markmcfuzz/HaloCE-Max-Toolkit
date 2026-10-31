-- Packed vertex values shared by the importers (same rules as the previous MAXScript importers).
local bit = require "bit"
local band, rshift = bit.band, bit.rshift
local sqrt = math.sqrt

local packed = {}

-- Vector scaled to length 1 (0, 0, 0 stays 0, 0, 0)
function packed.normalize(x, y, z)
    local length = sqrt(x * x + y * y + z * z)
    if length == 0 then
        return 0, 0, 0
    end
    return x / length, y / length, z / length
end

-- Normal packed in one 32-bit integer: x in bits 0-10, y in 11-21, z in 22-31, each with a sign
-- bit (10, 21 and 31). Same as decompressNormal in the previous MAXScript importers.
function packed.decompressNormal(packedNormal)
    local x = band(packedNormal, 1023) / 1023
    local y = band(rshift(packedNormal, 11), 1023) / 1023
    local z = band(rshift(packedNormal, 22), 511) / 511
    if band(packedNormal, 0x400) ~= 0 then
        x = x - 1
    end
    if band(packedNormal, 0x200000) ~= 0 then
        y = y - 1
    end
    if band(packedNormal, 0x80000000) ~= 0 then
        z = z - 1
    end
    return packed.normalize(x, y, z)
end

return packed
