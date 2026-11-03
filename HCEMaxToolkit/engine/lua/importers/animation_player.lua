-- Every animation of a model_animations tag for the Animation Player, decoded once
-- (builders\tag\model_animations\animation_player.ms reads it). Layout:
--   node count, node names; animation count, per animation: name, ext, frame count, node count;
--   message count, per message: level, text; then each animation's poses.
-- Poses: per frame and node, 8 floats: translation (JMA units), rotation i j k w (as in the
-- JMA), scale. Same poses the extracted JMA files have.
local modelAnimations = require "importers.model_animations"

local animationPlayer = {group = "model_animations", version = 1}

local identity = {trans = {0, 0, 0}, rot = {0, 0, 0, 1}, scale = 1}

function animationPlayer.write(root, output, options, tag)
    local messages = {}
    local function log(level, text)
        messages[#messages + 1] = {level, text}
    end
    local nodes, animations = modelAnimations.decodeAll(root, tag, log)

    output:int(#nodes)
    for _, node in ipairs(nodes) do
        output:string(node[1])
    end
    output:int(#animations)
    for _, anim in ipairs(animations) do
        output:string(anim.name)
        output:string(anim.ext)
        output:ints({#anim.keyframes, anim.nodeCount})
    end
    output:int(#messages)
    for _, message in ipairs(messages) do
        output:int(message[1])
        output:string(message[2])
    end

    for _, anim in ipairs(animations) do
        for _, frame in ipairs(anim.keyframes) do
            local values, n = {}, 0
            for nodeIndex = 1, anim.nodeCount do
                local pose = frame[nodeIndex] or identity
                local trans, rot = pose.trans, pose.rot
                values[n + 1], values[n + 2], values[n + 3] = trans[1], trans[2], trans[3]
                values[n + 4], values[n + 5], values[n + 6], values[n + 7] = rot[1], rot[2], rot[3], rot[4]
                values[n + 8] = pose.scale
                n = n + 8
            end
            output:floats(values, n)
        end
    end
end

return animationPlayer
