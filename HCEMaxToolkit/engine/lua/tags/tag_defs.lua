-- Loads the Halo CE JSON tag definitions and compiles each struct into fields with byte offsets.
-- Every struct is checked against its declared size, so layout mistakes fail early.

local json = require("tags.json")

local tagdefs = {}

function tagdefs.defaultDir()
	local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\]") or "."
	return here .. "/definitions"
end

-- Field kinds
local K = {
	SKIP = 0,      -- pad / skip / zero-size UI fields: no value
	I8 = 1, U8 = 2, I16 = 3, U16 = 4, I32 = 5, U32 = 6,
	F32 = 7,
	F32x2 = 8, F32x3 = 9, F32x4 = 10,
	I16x2 = 11, I16x4 = 12,
	STRING = 13,   -- 32-byte inline string
	FOURCC = 14,
	TAGREF = 15,   -- 16 bytes, path stored after the element
	BLOCK = 16,    -- 12 bytes, elements stored after the element
	DATA = 17,     -- 20 bytes, raw bytes stored after the element
	STRUCT = 18,   -- inline struct
	ARRAY = 19,    -- inline fixed-count struct array
}
tagdefs.K = K

-- type name -> { kind, size }
local TYPES = {
	char_integer = { K.I8, 1 },
	short_integer = { K.I16, 2 },
	long_integer = { K.I32, 4 },
	char_enum = { K.I8, 1 },
	short_enum = { K.I16, 2 },
	long_enum = { K.I32, 4 },
	byte_flags = { K.U8, 1 },
	word_flags = { K.U16, 2 },
	long_flags = { K.U32, 4 },
	char_block_index = { K.I8, 1 },
	short_block_index = { K.I16, 2 },
	long_block_index = { K.I32, 4 },
	rgb_color = { K.U32, 4 },
	argb_color = { K.U32, 4 },
	tag = { K.FOURCC, 4 },
	angle = { K.F32, 4 },
	real = { K.F32, 4 },
	real_fraction = { K.F32, 4 },
	point_2d = { K.I16x2, 4 },
	rectangle_2d = { K.I16x4, 8 },
	short_bounds = { K.I16x2, 4 },
	real_point_2d = { K.F32x2, 8 },
	real_vector_2d = { K.F32x2, 8 },
	real_euler_angles_2d = { K.F32x2, 8 },
	real_bounds = { K.F32x2, 8 },
	angle_bounds = { K.F32x2, 8 },
	fraction_bounds = { K.F32x2, 8 },
	real_point_3d = { K.F32x3, 12 },
	real_vector_3d = { K.F32x3, 12 },
	real_euler_angles_3d = { K.F32x3, 12 },
	real_plane_2d = { K.F32x3, 12 },
	real_rgb_color = { K.F32x3, 12 },
	real_hsv_color = { K.F32x3, 12 },
	real_quaternion = { K.F32x4, 16 },
	real_plane_3d = { K.F32x4, 16 },
	real_argb_color = { K.F32x4, 16 },
	real_ahsv_color = { K.F32x4, 16 },
	string = { K.STRING, 32 },
	tag_reference = { K.TAGREF, 16 },
	block = { K.BLOCK, 12 },
	data = { K.DATA, 20 },
	explanation = { K.SKIP, 0 },
	custom = { K.SKIP, 0 },
	terminator = { K.SKIP, 0 },
}

-- "base map u-scale*#0 defaults to 1" -> "base map u-scale" ('#' description, ':' units, '*^!' flags)
local function cleanName(name)
	if type(name) ~= "string" then return nil end
	local cut = name:find("[#:]")
	if cut then name = name:sub(1, cut - 1) end
	name = name:gsub("[%*%^!]", "")
	name = name:match("^%s*(.-)%s*$")
	if name == "" then return nil end
	return name
end
tagdefs.cleanName = cleanName

-------------------------------------------------------------------------------
-- Loading
-------------------------------------------------------------------------------

local Defs = {}
Defs.__index = Defs

-- dir: folder with _meta.json and <group>.json (defaults to core\halo1\tag_definitions)
function tagdefs.open(dir)
	dir = (dir or tagdefs.defaultDir()):gsub("[/\\]$", "")
	local meta = json.decodeFile(dir .. "/_meta.json")
	local self = setmetatable({
		dir = dir,
		meta = meta,
		byFourcc = meta.tag_index or {},
		groups = {},      -- group name -> raw json
		compiled = {},    -- "group/struct" -> compiled struct
	}, Defs)
	return self
end

function Defs:group(name)
	local g = self.groups[name]
	if g then return g end
	g = json.decodeFile(self.dir .. "/" .. name .. ".json")
	self.groups[name] = g
	return g
end

function Defs:groupByFourcc(fourcc)
	local name = self.byFourcc[fourcc]
	if not name then return nil end
	return self:group(name)
end

-- Finds structs/blocks/arrays entries in the group or its parents. Returns entry, owning group.
function Defs:lookup(group, section, name)
	local g = group
	while g do
		local t = g[section]
		if t and t[name] then return t[name], g end
		-- parent_tag is a group name ("unit") or a fourcc ("obje")
		local parent = g.parent_tag
		if type(parent) == "string" then
			g = self:group(self.byFourcc[parent] or parent)
		else
			g = nil
		end
	end
	error(("definition not found: %s '%s' (from group '%s')"):format(section, name, group.name), 0)
end

-------------------------------------------------------------------------------
-- Compiling
-------------------------------------------------------------------------------

-- Returns { name, size, fields = {key, kind, offset, size, sub, ...}, hasExt }.
-- hasExt: the struct holds tag-refs, data or blocks (data stored after the element).
function Defs:compileStruct(group, structName)
	local cacheKey = group.name .. "/" .. structName
	local c = self.compiled[cacheKey]
	if c then return c end

	local def, owner = self:lookup(group, "structs", structName)
	cacheKey = owner.name .. "/" .. structName
	c = self.compiled[cacheKey]
	if c then return c end

	c = { name = structName, size = def.size, fields = {}, hasExt = false }
	self.compiled[cacheKey] = c -- register before recursing (self-referencing blocks)

	local offset = 0
	local used = {}
	for _, fd in ipairs(def.fields) do
		local t = fd.type
		local kind, size, sub, count, maxCount
		if t == "pad" or t == "skip" then
			kind, size = K.SKIP, fd.definition
		elseif t == "struct" then
			kind = K.STRUCT
			sub = self:compileStruct(owner, fd.definition)
			size = sub.size
		elseif t == "array" then
			kind = K.ARRAY
			local arr, arrOwner = self:lookup(owner, "arrays", fd.definition)
			sub = self:compileStruct(arrOwner, arr.struct)
			count = arr.count
			size = sub.size * count
		elseif t == "block" then
			kind, size = K.BLOCK, 12
			local blk, blkOwner = self:lookup(owner, "blocks", fd.definition)
			sub = { owner = blkOwner, struct = blk.struct } -- compiled lazily
			maxCount = blk.max_count
		else
			local info = TYPES[t]
			if not info then
				error(("unknown field type '%s' in %s/%s"):format(t, owner.name, structName), 0)
			end
			kind, size = info[1], info[2]
		end

		if size > 0 and kind ~= K.SKIP then
			local name = cleanName(fd.name)
			local key = name or ("field_" .. offset)
			if used[key] then
				local n = 2
				while used[key .. " " .. n] do n = n + 1 end
				key = key .. " " .. n
			end
			used[key] = true
			-- key is unique within the struct ("flags 2"); name keeps repeats as in the definition
			c.fields[#c.fields + 1] = {
				key = key, name = name or key, kind = kind, offset = offset, size = size,
				sub = sub, count = count, maxCount = maxCount,
				type = t,
			}
			if kind == K.TAGREF or kind == K.DATA or kind == K.BLOCK then
				c.hasExt = true
			elseif (kind == K.STRUCT or kind == K.ARRAY) and sub.hasExt then
				c.hasExt = true
			end
		end
		offset = offset + size
	end

	if offset ~= def.size then
		error(("struct %s/%s: fields add up to %d bytes but definition says %d")
			:format(owner.name, structName, offset, def.size), 0)
	end
	return c
end

-- Compiled struct for a block field's elements
function Defs:blockStruct(field)
	local sub = field.sub
	if not sub.compiled then
		sub.compiled = self:compileStruct(sub.owner, sub.struct)
	end
	return sub.compiled
end

-- Root struct of a group
function Defs:rootStruct(group)
	local blk = group.blocks[group.block]
	return self:compileStruct(group, blk.struct)
end

-- Compiles every struct of every group; returns a list of error strings.
function Defs:validateAll()
	local errors = {}
	for _, name in pairs(self.byFourcc) do
		local ok, err = pcall(function()
			local g = self:group(name)
			for sname in pairs(g.structs) do
				self:compileStruct(g, sname)
			end
		end)
		if not ok then errors[#errors + 1] = name .. ": " .. tostring(err) end
	end
	table.sort(errors)
	return errors
end

return tagdefs
