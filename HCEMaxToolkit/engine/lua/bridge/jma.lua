-- JMA files for 3ds Max (formats\jma\jma_reader.ms and process_file.ms):
--   run.lua bridge.jma read <file.jma> <out.bin>    JMA -> binary for Max
--   run.lua bridge.jma write <in.bin> <file.jma>    binary from Max -> JMA

local jma = require("formats.jma")
local maxbin = require("bridge.maxbin")

local jmaBridge = {}

-- Format version of the binaries exchanged with Max (checked on both sides)
local FORMAT = "jma"
local READ_VERSION = 2
local WRITE_VERSION = 1

function jmaBridge.read(jmaPath, outPath)
	local data = jma.read(jmaPath)
	local w = maxbin.open(outPath)
	w:string(FORMAT)
	w:int(READ_VERSION)
	w:ints({ data.version, data.frameCount, data.frameRate, data.actorCount })
	w:string(data.actorName)
	w:ints({ data.nodeCount, data.checksum })
	for _, node in ipairs(data.nodes) do
		w:string(node[1])
		w:ints({ node[2], node[3] })
	end
	-- Per node: translation, raw rotation (Max normalizes it), scale
	for _, frame in ipairs(data.frames) do
		for _, pose in ipairs(frame) do
			w:floats(pose.trans)
			w:floats(pose.rot)
			w:float(pose.scale)
		end
	end
	w:close()
end

function jmaBridge.write(inPath, jmaPath)
	local r = maxbin.readFile(inPath)
	if r:string() ~= FORMAT or r:int() ~= WRITE_VERSION then
		error(("unexpected data from Max (expected %s v%d)"):format(FORMAT, WRITE_VERSION), 0)
	end
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

return jmaBridge
