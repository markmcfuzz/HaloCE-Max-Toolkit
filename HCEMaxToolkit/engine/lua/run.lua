-- The only script 3ds Max runs (luaRun in shared\utils\lua_bridge.ms):
--   luajit run.lua <module> <function> [arguments...]    e.g. run.lua bridge.jms read <file.jms> <out.bin>
-- Errors go to stderr with exit code 1; anything printed goes to the Max log.

-- Modules are required from this folder: require("tags.tagreader")
local luaDir = arg[0]:match("^(.*)[/\\]") or "."
package.path = luaDir .. "/?.lua;" .. package.path

local moduleName, functionName = arg[1], arg[2]
local ok, err = pcall(function()
	if not (moduleName and functionName) then
		error("usage: luajit run.lua <module> <function> [arguments...]", 0)
	end
	local fn = require(moduleName)[functionName]
	if type(fn) ~= "function" then
		error(("module '%s' has no function '%s'"):format(moduleName, functionName), 0)
	end
	fn(unpack(arg, 3, #arg))
end)
if not ok then
	io.stderr:write(tostring(err), "\n")
	os.exit(1)
end
