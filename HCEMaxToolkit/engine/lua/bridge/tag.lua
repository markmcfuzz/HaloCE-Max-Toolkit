-- Reads tags and writes what a 3ds Max importer needs (luaExportTag in lua_bridge.ms).
--   run.lua bridge.tag export <importer> <tag> <output.bin> [importer options...]
--   run.lua bridge.tag export <importer> @<list.txt> <output.bin> [...]   (one tag path per line)
-- <importer> is a script name in lua\importers (e.g. gbxmodel). A list writes the tag count,
-- then per tag: int 1 + importer data, or int 0 + error message.

local tagDefs = require "tags.tag_defs"
local tagReader = require "tags.tag_reader"
local maxbin = require "bridge.maxbin"

local tag = {}

local function accepts(importer, group)
	if type(importer.group) == "string" then return importer.group == group end
	for _, g in ipairs(importer.group) do
		if g == group then return true end
	end
	return false
end

-- Reads one tag and writes the importer's data to output; warnings go to stdout
local function exportOne(importerName, importer, defs, path, output, options)
	local tagData = tagReader.readFile(defs, path)
	if not accepts(importer, tagData.group) then
		error(("importer '%s' does not read %s tags"):format(importerName, tagData.group), 0)
	end
	for _, warning in ipairs(tagData.warnings) do io.stdout:write("warning: ", path, ": ", warning, "\n") end
	-- tagData.bytes (raw file) and tagData.rootStruct are there for importers that need them
	importer.write(tagData.root, output, options, tagData)
end

function tag.export(importerName, tagArg, outPath, ...)
	if not (importerName and tagArg and outPath) then
		error("usage: run.lua bridge.tag export <importer> <tag | @list.txt> <output.bin> [importer options...]", 0)
	end
	local options = { ... }
	if not package.searchpath("importers." .. importerName, package.path) then
		error(("no Lua importer '%s' in lua\\importers"):format(importerName), 0)
	end
	local importer = require("importers." .. importerName)
	local defs = tagDefs.open()

	-- The header (importer name and version) is checked by luaOpenOutput in lua_bridge.ms
	local output = maxbin.open(outPath, importerName, importer.version)

	if tagArg:sub(1, 1) ~= "@" then
		exportOne(importerName, importer, defs, tagArg, output, options)
	else
		local paths = {}
		for line in assert(io.open(tagArg:sub(2), "r")):lines() do
			line = line:gsub("^\239\187\191", ""):gsub("\r$", "") -- UTF-8 BOM, CR
			if line ~= "" then paths[#paths + 1] = line end
		end
		output:int(#paths)
		for _, path in ipairs(paths) do
			-- Each tag goes to memory first, so a failing tag leaves nothing half-written
			local memory = maxbin.memory()
			local tagOk, tagErr = pcall(exportOne, importerName, importer, defs, path, memory, options)
			if tagOk then
				output:int(1)
				output:bytes(memory:contents())
			else
				output:int(0)
				output:string(tostring(tagErr))
			end
		end
	end
	output:close()
end

return tag
