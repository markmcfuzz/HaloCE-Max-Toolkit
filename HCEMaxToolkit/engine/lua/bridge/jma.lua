-- JMA files for 3ds Max (formats\jma\jma_reader.ms and process_file.ms):
--   run.lua bridge.jma read <file.jma> <out.bin>    JMA -> binary for Max
--   run.lua bridge.jma write <in.bin> <file.jma>    binary from Max -> JMA
local jma = require "formats.jma"
local maxbin = require "bridge.maxbin"

local jmaBridge = {}

-- Name and version at the start of each binary (Max checks the same values)
local binaryName = "jma"
local readVersion = 2 -- JMA -> Max
local writeVersion = 1 -- Max -> JMA

function jmaBridge.read(jmaPath, outPath)
    local data = jma.read(jmaPath)
    local output = maxbin.open(outPath, binaryName, readVersion)
    output:ints({data.version, data.frameCount, data.frameRate, data.actorCount})
    output:string(data.actorName)
    output:ints({data.nodeCount, data.checksum})
    for _, node in ipairs(data.nodes) do
        output:string(node[1])
        output:ints({node[2], node[3]})
    end
    -- Per node: translation, raw rotation (Max normalizes it), scale
    for _, frame in ipairs(data.frames) do
        for _, pose in ipairs(frame) do
            output:floats(pose.trans)
            output:floats(pose.rot)
            output:float(pose.scale)
        end
    end
    output:close()
end

function jmaBridge.write(inPath, jmaPath)
    local input = maxbin.readFile(inPath, binaryName, writeVersion)
    local data = {nodes = {}, frames = {}}
    data.version, data.frameCount, data.frameRate, data.actorCount = input:int(), input:int(),
                                                                     input:int(), input:int()
    data.actorName = input:string()
    data.nodeCount, data.checksum = input:int(), input:int()
    for n = 1, input:int() do
        local name = input:string()
        data.nodes[n] = {name, input:int(), input:int()}
    end
    -- Each written frame has its own node count (writeJmaFile wrote every entry it had)
    for f = 1, input:int() do
        local frame = {}
        for n = 1, input:int() do
            local trans = {input:float(), input:float(), input:float()}
            local rot = {input:float(), input:float(), input:float(), input:float()}
            frame[n] = {trans = trans, rot = rot, scale = input:float()}
        end
        data.frames[f] = frame
    end
    if not jma.write(jmaPath, data) then
        error("cannot write " .. jmaPath, 0)
    end
end

return jmaBridge
