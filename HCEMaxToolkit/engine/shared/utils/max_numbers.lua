-- Numbers the way MAXScript computes and prints them, so Lua output matches the old MAXScript
-- files byte for byte. MAXScript Float is a 32-bit float.

local ffi = require("ffi")

local format, floor = string.format, math.floor
local fbox = ffi.new("float[1]")

local max_numbers = {}

-- Rounds to a 32-bit float (apply after every operation MAXScript would do in Float)
function max_numbers.f32(x)
	fbox[0] = x
	return fbox[0]
end

-- formattedPrint x format:".6f": exact halves round to even (32.4765625 -> 32.476562)
-- and "-0.000000" is written "0.000000". x * 1e6 is exact for 32-bit floats.
function max_numbers.fixed6(x)
	local scaled = x * 1e6
	local low = floor(scaled)
	if scaled - low == 0.5 then
		x = (low % 2 == 0 and low or low + 1) / 1e6
	end
	local text = format("%.6f", x)
	return text == "-0.000000" and "0.000000" or text
end

-- C's "%g" (6 significant digits) with exact halves rounded to even like MSVC; LuaJIT rounds
-- them up (0.01953125 -> 0.0195313 instead of 0.0195312). "%.60e" gives LuaJIT's exact digits.
local function g6(x)
	local text = format("%.6g", x)
	local first, rest, exponent = format("%.60e", x):match("^-?(%d)%.(%d+)e([-+]%d+)$")
	if not first then return text end -- inf / nan
	local digits = first .. rest
	if digits:sub(7, 7) == "5" and not digits:find("[1-9]", 8) and tonumber(digits:sub(6, 6)) % 2 == 0 then
		local down = tonumber((x < 0 and "-" or "") .. first .. "." .. digits:sub(2, 6) .. "e" .. exponent)
		text = format("%.6g", down)
	end
	return text
end

-- format "%" of a MAXScript Float: "%g", plus ".0" when it has no point or exponent
-- (1.0 -> "1.0", 1e-05 -> "1e-05", 1234567.0 -> "1.23457e+06"); -0.0 prints "0.0".
function max_numbers.float_text(x)
	local text = g6(x)
	if text == "-0" then return "0.0" end
	if not text:find("[%.e]") and not text:find("[ni]") then text = text .. ".0" end
	return text
end

return max_numbers
