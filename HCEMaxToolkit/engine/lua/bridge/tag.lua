-- Reads tags and writes what a 3ds Max importer needs. <importer> is the importer's Lua script,
-- relative to the engine folder (e.g. lua\importers\gbxmodel.lua).
--   luajit tag_to_max.lua <importer> <tag> <output.bin> [importer options...]
--   luajit tag_to_max.lua <importer> @<list.txt> <output.bin> [...]   (one tag path per line)
-- A list writes the tag count, then per tag: int 1 + importer data, or int 0 + error message.

-- Modules are required from the lua folder: require("tags.tagreader")
local luaDir = ((arg[0]:match("^(.*)[/\\]") or ".") .. "/..")
local engineDir = luaDir .. "/.."
package.path = luaDir .. "/?.lua;" .. package.path

local tagdefs = require("tags.tagdefs")
local tagreader = require("tags.tagreader")
local maxbin = require("bridge.maxbin")

local importerName, tagArg, outPath = arg[1], arg[2], arg[3]
if not (importerName and tagArg and outPath) then
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
	local tag = tagreader.readFile(defs, path)
	if not accepts(importer, tag.group) then
		error(("importer '%s' does not read %s tags"):format(importerName, tag.group), 0)
	end
	for _, warning in ipairs(tag.warnings) do io.stdout:write("warning: ", path, ": ", warning, "\n") end
	-- tag.bytes (raw file) and tag.rootStruct are there for importers that need them
	importer.write(tag.root, w, options, tag)
end

local ok, err = pcall(function()
	local script = engineDir .. "/" .. importerName
	local file = io.open(script, "r")
	if not file then error("no Lua importer at '" .. importerName .. "'", 0) end
	file:close()
	local importer = dofile(script)
	local defs = tagdefs.open()

	-- Header checked by luaExportTag in lua_bridge.ms (the same script path it passed)
	local w = maxbin.open(outPath)
	w:string(importerName)
	w:int(importer.version)

	if tagArg:sub(1, 1) ~= "@" then
		export(importer, defs, tagArg, w)
	else
		local paths = {}
		for line in assert(io.open(tagArg:sub(2), "r")):lines() do
			line = line:gsub("^\239\187\191", ""):gsub("\r$", "") -- UTF-8 BOM, CR
			if line ~= "" then paths[#paths + 1] = line end
		end
		w:int(#paths)
		for _, path in ipairs(paths) do
			-- Each tag goes to memory first, so a failing tag leaves nothing half-written
			local mem = maxbin.memory()
			local tagOk, tagErr = pcall(export, importer, defs, path, mem)
			if tagOk then
				w:int(1)
				w.f:write(mem:contents())
			else
				w:int(0)
				w:string(tostring(tagErr))
			end
		end
	end
	w:close()
end)
if not ok then
	io.stderr:write(tostring(err), "\n")
	os.exit(1)
end
