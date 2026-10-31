-- Minimal JSON decoder (objects, arrays, strings, numbers, true/false/null).
-- Enough for the tag definition files; not a general-purpose validator.

local json = {}

local byte, sub, find, char = string.byte, string.sub, string.find, string.char
local tonumber, concat = tonumber, table.concat

local escapes = {
	[34] = '"', [92] = "\\", [47] = "/",
	[98] = "\b", [102] = "\f", [110] = "\n", [114] = "\r", [116] = "\t",
}

local function utf8_char(cp)
	if cp < 0x80 then return char(cp) end
	if cp < 0x800 then
		return char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
	end
	if cp < 0x10000 then
		return char(0xE0 + math.floor(cp / 0x1000), 0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
	end
	return char(0xF0 + math.floor(cp / 0x40000), 0x80 + math.floor(cp / 0x1000) % 0x40,
		0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
end

local function decode_error(s, pos, msg)
	error(("JSON error at byte %d: %s near '%s'"):format(pos, msg, sub(s, pos, pos + 20)), 0)
end

local parse_value

local function skip_ws(s, pos)
	local _, e = find(s, "^[ \t\r\n]*", pos)
	return e + 1
end

local function parse_string(s, pos)
	-- pos points at the opening quote
	local parts, n = {}, 0
	local i = pos + 1
	while true do
		local a, b = find(s, '["\\]', i)
		if not a then decode_error(s, pos, "unterminated string") end
		if a > i then
			n = n + 1; parts[n] = sub(s, i, a - 1)
		end
		if byte(s, a) == 34 then
			return concat(parts), a + 1
		end
		local c = byte(s, a + 1)
		if c == 117 then -- \uXXXX
			local cp = tonumber(sub(s, a + 2, a + 5), 16)
			local nexti = a + 6
			if cp >= 0xD800 and cp <= 0xDBFF and sub(s, a + 6, a + 7) == "\\u" then
				local lo = tonumber(sub(s, a + 8, a + 11), 16)
				cp = 0x10000 + (cp - 0xD800) * 0x400 + (lo - 0xDC00)
				nexti = a + 12
			end
			n = n + 1; parts[n] = utf8_char(cp)
			i = nexti
		else
			local e = escapes[c]
			if not e then decode_error(s, a, "bad escape") end
			n = n + 1; parts[n] = e
			i = a + 2
		end
	end
end

local function parse_object(s, pos)
	local obj = {}
	pos = skip_ws(s, pos + 1)
	if byte(s, pos) == 125 then return obj, pos + 1 end
	while true do
		if byte(s, pos) ~= 34 then decode_error(s, pos, "expected key") end
		local key
		key, pos = parse_string(s, pos)
		pos = skip_ws(s, pos)
		if byte(s, pos) ~= 58 then decode_error(s, pos, "expected ':'") end
		local val
		val, pos = parse_value(s, skip_ws(s, pos + 1))
		obj[key] = val
		pos = skip_ws(s, pos)
		local c = byte(s, pos)
		if c == 125 then return obj, pos + 1 end
		if c ~= 44 then decode_error(s, pos, "expected ',' or '}'") end
		pos = skip_ws(s, pos + 1)
	end
end

local function parse_array(s, pos)
	local arr, n = {}, 0
	pos = skip_ws(s, pos + 1)
	if byte(s, pos) == 93 then return arr, pos + 1 end
	while true do
		local val
		val, pos = parse_value(s, pos)
		n = n + 1; arr[n] = val
		pos = skip_ws(s, pos)
		local c = byte(s, pos)
		if c == 93 then return arr, pos + 1 end
		if c ~= 44 then decode_error(s, pos, "expected ',' or ']'") end
		pos = skip_ws(s, pos + 1)
	end
end

parse_value = function(s, pos)
	pos = skip_ws(s, pos)
	local c = byte(s, pos)
	if c == 123 then return parse_object(s, pos) end
	if c == 91 then return parse_array(s, pos) end
	if c == 34 then return parse_string(s, pos) end
	if sub(s, pos, pos + 3) == "true" then return true, pos + 4 end
	if sub(s, pos, pos + 4) == "false" then return false, pos + 5 end
	if sub(s, pos, pos + 3) == "null" then return json.null, pos + 4 end
	local a, b = find(s, "^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
	if not a then decode_error(s, pos, "unexpected character") end
	return tonumber(sub(s, a, b)), b + 1
end

-- Sentinel for JSON null (so keys with null values still exist)
json.null = setmetatable({}, { __tostring = function() return "null" end })

function json.decode(s)
	local val, pos = parse_value(s, 1)
	pos = skip_ws(s, pos)
	if pos <= #s then decode_error(s, pos, "trailing data") end
	return val
end

function json.decode_file(path)
	local f, err = io.open(path, "rb")
	if not f then error("cannot open " .. path .. ": " .. tostring(err), 0) end
	local s = f:read("*a")
	f:close()
	return json.decode(s)
end

return json
