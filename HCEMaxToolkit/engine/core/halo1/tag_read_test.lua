-- Console test for the Lua tag reader:
--   luajit tag_read_test.lua [--defs <dir>] --validate | <tag or folder>...

-- Modules are required from the engine folder: require("core.halo1.tagreader")
local engine_dir = ((arg[0]:match("^(.*)[/\\]") or ".") .. "/../..")
package.path = engine_dir .. "/?.lua;" .. package.path

local tagdefs = require("core.halo1.tagdefs")
local tagreader = require("core.halo1.tagreader")

local args, defs_dir = {}, nil
local i = 1
while i <= #arg do
	if arg[i] == "--defs" then
		defs_dir = arg[i + 1]
		i = i + 2
	else
		args[#args + 1] = arg[i]
		i = i + 1
	end
end
if #args == 0 then
	io.stderr:write("usage: luajit tag_read_test.lua [--defs <dir>] --validate | <tag or folder>...\n")
	os.exit(2)
end

local defs = tagdefs.open(defs_dir)

if args[1] == "--validate" then
	local t0 = os.clock()
	local errors = defs:validate_all()
	local n = 0
	for _ in pairs(defs.compiled) do n = n + 1 end
	print(("Compiled %d structs in %.3f s"):format(n, os.clock() - t0))
	for _, e in ipairs(errors) do print("  ERROR " .. e) end
	print(#errors == 0 and "All struct sizes match." or (#errors .. " group(s) with errors."))
	os.exit(#errors == 0 and 0 or 1)
end

-- A path that cannot be read as a file is treated as a folder (Windows `dir`)
local function list_files(path)
	local f = io.open(path, "rb")
	if f then
		local ok = f:read(0)
		f:close()
		if ok then return { path } end
	end
	local files = {}
	local pipe = io.popen('dir /s /b /a-d "' .. path:gsub("/", "\\") .. '" 2>nul')
	for line in pipe:lines() do files[#files + 1] = line end
	pipe:close()
	return files
end

-- Element count per block path, e.g. "geometries/parts" -> 153
local function count_blocks(e, out, prefix)
	for k, v in pairs(e) do
		if type(v) == "table" and type(v[1]) == "table" and v[1].path == nil then
			out[prefix .. k] = (out[prefix .. k] or 0) + #v
			for _, child in ipairs(v) do count_blocks(child, out, prefix .. k .. "/") end
		end
	end
end

local files = {}
for _, a in ipairs(args) do
	for _, f in ipairs(list_files(a)) do files[#files + 1] = f end
end

local ok_count, fail_count, skip_count, total_bytes = 0, 0, 0, 0
local t0 = os.clock()
for _, path in ipairs(files) do
	local ok, res = pcall(tagreader.read_file, defs, path)
	local msg = tostring(res)
	if ok then
		ok_count = ok_count + 1
		total_bytes = total_bytes + res.size
		if #files == 1 then
			print(("%s: %s v%d, %d bytes, %.3f s"):format(path, res.group, res.version, res.size, os.clock() - t0))
			for _, w in ipairs(res.warnings) do print("  warning: " .. w) end
			local counts, keys = {}, {}
			count_blocks(res.root, counts, "")
			for k in pairs(counts) do keys[#keys + 1] = k end
			table.sort(keys)
			for _, k in ipairs(keys) do print(("  %-60s %d"):format(k, counts[k])) end
		end
	elseif msg:find("^unknown tag group") or msg:find("^not a Halo tag") or msg:find("too small") then
		skip_count = skip_count + 1
	else
		fail_count = fail_count + 1
		if fail_count <= 30 then print("FAIL " .. path .. "\n     " .. msg) end
	end
end
print(("\nRead %d tags (%.1f MB) in %.2f s; %d failed; %d skipped (not tags)")
	:format(ok_count, total_bytes / 1048576, os.clock() - t0, fail_count, skip_count))
