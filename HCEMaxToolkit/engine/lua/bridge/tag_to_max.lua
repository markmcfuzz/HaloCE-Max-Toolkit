-- Reads tags and writes what a 3ds Max importer needs. <importer> is the importer's Lua script,
-- relative to the engine folder (e.g. builders\tag\gbxmodel\gbxmodel.lua).
--   luajit tag_to_max.lua <importer> <tag> <output.bin> [importer options...]
--   luajit tag_to_max.lua <importer> @<list.txt> <output.bin> [...]   (one tag path per line)
-- A list writes the tag count, then per tag: int 1 + importer data, or int 0 + error message.

-- Modules are required from the engine folder: require("core.halo1.tagreader")
local engine_dir = ((arg[0]:match("^(.*)[/\\]") or ".") .. "/../..")
package.path = engine_dir .. "/?.lua;" .. package.path

local tagdefs = require("core.halo1.tagdefs")
local tagreader = require("core.halo1.tagreader")
local maxbin = require("core.halo1.maxbin")

local importer_name, tag_arg, out_path = arg[1], arg[2], arg[3]
if not (importer_name and tag_arg and out_path) then
	io.stderr:write("usage: luajit tag_to_max.lua <importer.lua> <tag | @list.txt> <output.bin> [importer options...]\n")
	os.exit(2)
end
local options = {}
for i = 4, #arg do options[#options + 1] = arg[i] end

local function accepts(importer, group)
	if type(importer.group) == "string" then return importer.group == group end
	for _, g in ipairs(importer.group) do
		if g == group then return true end
	end
	return false
end

-- Reads one tag and writes the importer's data to w; warnings go to stdout
local function export(importer, defs, path, w)
	local tag = tagreader.read_file(defs, path)
	if not accepts(importer, tag.group) then
		error(("importer '%s' does not read %s tags"):format(importer_name, tag.group), 0)
	end
	for _, warning in ipairs(tag.warnings) do io.stdout:write("warning: ", path, ": ", warning, "\n") end
	-- tag.bytes (raw file) and tag.root_struct are there for importers that need them
	importer.write(tag.root, w, options, tag)
end

local ok, err = pcall(function()
	local script = engine_dir .. "/" .. importer_name
	local file = io.open(script, "r")
	if not file then error("no Lua importer at '" .. importer_name .. "'", 0) end
	file:close()
	local importer = dofile(script)
	local defs = tagdefs.open()

	-- Header checked by luaExportTag in lua_bridge.ms (the same script path it passed)
	local w = maxbin.open(out_path)
	w:string(importer_name)
	w:int(importer.version)

	if tag_arg:sub(1, 1) ~= "@" then
		export(importer, defs, tag_arg, w)
	else
		local paths = {}
		for line in assert(io.open(tag_arg:sub(2), "r")):lines() do
			line = line:gsub("^\239\187\191", ""):gsub("\r$", "") -- UTF-8 BOM, CR
			if line ~= "" then paths[#paths + 1] = line end
		end
		w:int(#paths)
		for _, path in ipairs(paths) do
			-- Each tag goes to memory first, so a failing tag leaves nothing half-written
			local mem = maxbin.memory()
			local tag_ok, tag_err = pcall(export, importer, defs, path, mem)
			if tag_ok then
				w:int(1)
				w.f:write(mem:contents())
			else
				w:int(0)
				w:string(tostring(tag_err))
			end
		end
	end
	w:close()
end)
if not ok then
	io.stderr:write(tostring(err), "\n")
	os.exit(1)
end
