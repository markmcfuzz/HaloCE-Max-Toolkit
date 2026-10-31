-- JMA files for 3ds Max (formats\jma\jma_reader.ms and process_file.ms):
--   luajit jma_cli.lua read <file.jma> <out.bin>    JMA -> binary for Max
--   luajit jma_cli.lua write <in.bin> <file.jma>    binary from Max -> JMA
-- Errors go to stderr with exit code 1.

-- Modules are required from the lua folder: require("formats.jma")
local luaDir = ((arg[0]:match("^(.*)[/\\]") or ".") .. "/..")
package.path = luaDir .. "/?.lua;" .. package.path

local jma = require("formats.jma")
local maxbin = require("bridge.maxbin")

-- Format version of the binaries exchanged with Max (checked on both sides)
local FORMAT = "jma"
local VERSION = 1

local function read(jmaPath, outPath)
	local data = jma.read(jmaPath)
	local w = maxbin.open(outPath)
	w:string(FORMAT)
	w:int(VERSION)
	w:ints({ data.version, data.frameCount, data.frameRate, data.actorCount })
	w:string(data.actorName)
	w:ints({ data.nodeCount, data.checksum })
	for _, node in ipairs(data.nodes) do
		w:string(node[1])
		w:ints({ node[2], node[3] })
	end
	-- Per node: translation, raw rotation (Max normalizes it), scale; then the scales that
	-- were not numbers, as (frame, node) pairs, so Max can leave them undefined like before
	local missing = {}
	for f, frame in ipairs(data.frames) do
		for n, pose in ipairs(frame) do
			w:floats(pose.trans)
			w:floats(pose.rot)
			w:float(pose.scale or 1)
			if not pose.scale then missing[#missing + 1] = { f, n } end
		end
	end
	w:int(#missing)
	for _, m in ipairs(missing) do w:ints(m) end
	w:close()
end

local function write(inPath, jmaPath)
	local r = maxbin.readFile(inPath)
	if r:string() ~= FORMAT or r:int() ~= VERSION then error("unexpected data from Max (expected jma v1)", 0) end
	local data = { nodes = {}, frames = {} }
	data.version, data.frameCount, data.frameRate, data.actorCount = r:int(), r:int(), r:int(), r:int()
	data.actorName = r:string()
	data.nodeCount, data.checksum = r:int(), r:int()
	for n = 1, r:int() do
		local name = r:string()
		data.nodes[n] = { name, r:int(), r:int() }
	end
	-- Each written frame has its own node count (writeJmaFile wrote every entry it had)
	for f = 1, r:int() do
		local frame = {}
		for n = 1, r:int() do
			local trans = { r:float(), r:float(), r:float() }
			local rot = { r:float(), r:float(), r:float(), r:float() }
			frame[n] = { trans = trans, rot = rot, scale = r:float() }
		end
		data.frames[f] = frame
	end
	if not jma.write(jmaPath, data) then error("cannot write " .. jmaPath, 0) end
end

local command, a, b = arg[1], arg[2], arg[3]
local ok, err = pcall(function()
	if command == "read" and a and b then read(a, b)
	elseif command == "write" and a and b then write(a, b)
	else error("usage: luajit jma_cli.lua read <file.jma> <out.bin> | write <in.bin> <file.jma>", 0)
	end
end)
if not ok then
	io.stderr:write(tostring(err), "\n")
	os.exit(1)
end
