-- Behaviors of an actor variant for the Python Actor panel (engine\core\tag_editor\actor.py):
--   run.lua bridge.actor_ui behaviors <actor_variant tag> <out.json>
-- Which animation of the unit's animation graph each unit state and AI impulse plays, per
-- actor mode, with the game's rules (units.c: unit_update_animation, unit_animation_set_state,
-- unit_start_animation_impulse).
local tagDefs = require "tags.tag_defs"
local tagReader = require "tags.tag_reader"
local tagFields = require "importers.shared.tag_fields"
local actorVariant = require "importers.actor_variant"
local json = require "tags.json"

local actorUi = {}

-- Order of a seat's animation list (units.h), first = 0
local seatSlots = {
    "airborne dead", "landing dead", "acceleration front back", "acceleration left right",
    "acceleration up down", "push impact", "twist impact", "seat enter", "seat exit", "looking",
    "mouth aperture", "emotions", "unused3", "user0", "user1", "user2", "user3", "user4", "user5",
    "user6", "user7", "user8", "user9", "flying front", "flying back", "flying left",
    "flying right", "opening", "closing", "hovering"
}

-- Order of a weapon class's animation list (units.h), first = 0
local classSlots = {
    "idle", "gesture", "turning left", "turning right", "diving front", "diving back",
    "diving left", "diving right", "moving front", "moving back", "moving left", "moving right",
    "sliding front", "sliding back", "sliding left", "sliding right", "airborne", "land soft",
    "land hard", "land mine", "throw grenade", "disarm", "drop", "ready", "put away",
    "aiming still", "aiming moving", "surprise front", "surprise back", "berserk", "evade left",
    "evade right", "signal move", "signal attack", "signal warn", "moving wounded front",
    "moving wounded back", "moving wounded left", "moving wounded right", "melee attack",
    "celebrate", "panic", "melee airborne", "flaming", "resurrect front", "resurrect back",
    "melee continuous", "feeding", "leap start", "leap airborne", "leap melee", "zapping"
}

local function indexByName(names)
    local index = {}
    for i, name in ipairs(names) do
        index[name] = i
    end
    return index
end
local seatSlotIndex = indexByName(seatSlots)
local classSlotIndex = indexByName(classSlots)

-- Actor modes: {name, stance label, when the game uses it} (ai/actor_moving.c, units.c)
local modes = {
    {"Asleep", "asleep", "The actor is asleep (actor mode asleep)."},
    {"Alert", "alert", "The actor knows of no enemy yet: idle, patrolling or searching (actor mode alert)."},
    {"Combat Crouch", "crouch", "Combat while crouching: taking cover, guarding, stalking or by a command list."},
    {"Combat Stand", "stand", "Combat standing up. Units start in this stance, and players always use it."},
    {"Flee", "flee", "The actor panics and runs away. Also while berserk charging, when the .actor"
        .. " has 'berserking uses panic movement'."},
    {"Flaming", "flaming", "Blind panic: a grenade or sticky projectile stuck to it, something"
        .. " attached in melee, or burning to death."}
}

-- {name, list ("class" or "seat"), slot, missing, when}. missing: what the game does without
-- the animation: "rest" = the state starts with no animation, "skip" = it does not start
local never = "The game code never sets this state: no character animates it."
local stunned = "Moving while stunned: body stun over 0.2, or recent damage over the unit's"
    .. " 'stunned movement threshold'."
local states = {
    {"idle", "class", "idle", "rest", "Standing still."},
    {"gesture", "class", "gesture", "rest", never},
    {"turn left", "class", "turning left", "rest", "Turning in place towards where it wants to face."},
    {"turn right", "class", "turning right", "rest", "Turning in place towards where it wants to face."},
    {"move front", "class", "moving front", "rest", "Moving forward."},
    {"move back", "class", "moving back", "rest", "Moving backwards."},
    {"move left", "class", "moving left", "rest", "Strafing left."},
    {"move right", "class", "moving right", "rest", "Strafing right."},
    {"stunned move front", "class", "moving wounded front", "rest", stunned},
    {"stunned move back", "class", "moving wounded back", "rest", stunned},
    {"stunned move left", "class", "moving wounded left", "rest", stunned},
    {"stunned move right", "class", "moving wounded right", "rest", stunned},
    {"slide front", "class", "sliding front", "rest", never},
    {"slide back", "class", "sliding back", "rest", never},
    {"slide left", "class", "sliding left", "rest", never},
    {"slide right", "class", "sliding right", "rest", never},
    {"airborne", "class", "airborne", "rest", "In the air: jumping, falling or thrown by an explosion."},
    {"land soft", "class", "land soft", "rest", "Landing faster than the biped's 'minimum soft landing velocity'."},
    {"land hard", "class", "land hard", "rest", "Landing faster than the biped's 'minimum hard landing velocity'."},
    {"throw grenade", "class", "throw grenade", "skip", "Throws a grenade."},
    {"melee attack", "class", "melee attack", "skip", "Melee attack on the ground."},
    {"melee airborne", "class", "melee airborne", "skip", "Melee attack in the air."},
    {"melee continuous", "class", "melee continuous", "skip", "Attached to a living unit (Flood infection form)."},
    {"resurrect front", "class", "resurrect front", "rest",
        "A Flood combat form that played dead gets up (it fell on its front)."},
    {"resurrect back", "class", "resurrect back", "rest",
        "A Flood combat form that played dead gets up (it fell on its back)."},
    {"feeding", "class", "feeding", "rest", "Attached to a dead body (Flood infection form)."},
    {"leap start", "class", "leap start", "skip", "The AI leaps at its target (Flood combat forms)."},
    {"leap airborne", "class", "leap airborne", "rest", "In the air during a leap."},
    {"leap melee", "class", "leap melee", "skip", "Melee attack at the end of a leap."},
    {"flying front", "seat", "flying front", "rest", never},
    {"flying back", "seat", "flying back", "rest", never},
    {"flying left", "seat", "flying left", "rest", never},
    {"flying right", "seat", "flying right", "rest", never},
    {"dying airborne", "seat", "airborne dead", "rest",
        "The dead body is in the air (3 ticks or more), unless the biped has 'has no dying airborne'."},
    {"dying", "seat", "landing dead", "rest",
        "The dead body on the ground. The death animation itself comes from the damage animations."},
    {"opening", "seat", "opening", "rest",
        "Played by a unit when someone enters one of its seats (vehicles), not by a character on foot."},
    {"closing", "seat", "closing", "rest",
        "Played by a unit when someone exits one of its seats (vehicles), not by a character on foot."},
    {"hovering", "seat", "hovering", "rest", never}
}

-- The AI impulses a unit on foot can play (celebrate and panic are for vehicle seats)
local impulses = {
    {"berserk", "class", "berserk", "skip", "The actor goes berserk."},
    {"signal move", "class", "signal move", "skip", "Dialogue: a friend blocks its way."},
    {"signal attack", "class", "signal attack", "skip", "Dialogue: advancing, or leaving cover to attack."},
    {"signal warn", "class", "signal warn", "skip", "Dialogue: it sights or finds an enemy, or sights a friendly player."},
    {"surprise front", "class", "surprise front", "skip", "Surprised by something in front of it."},
    {"surprise back", "class", "surprise back", "skip", "Surprised by something behind it."},
    {"evade left", "class", "evade left", "skip", "Dodges fire to the left. Also a grenade dive when there is no dive left."},
    {"evade right", "class", "evade right", "skip", "Dodges fire to the right. Also a grenade dive when there is no dive right."},
    {"dive front", "class", "diving front", "skip", "Dives forward away from a grenade."},
    {"dive back", "class", "diving back", "skip", "Dives backwards away from a grenade."},
    {"dive left", "class", "diving left", "skip", "Dives left away from a grenade (preferred over evade left)."},
    {"dive right", "class", "diving right", "skip", "Dives right away from a grenade (preferred over evade right)."}
}

-- Unit states that turn the weapon IK off (unit_animation_weapon_ik); AI impulses all do
local noWeaponIk = {}
for _, name in ipairs({
    "flying front", "flying back", "flying left", "flying right", "dying airborne", "dying",
    "melee attack", "melee airborne", "melee continuous", "throw grenade", "resurrect front",
    "resurrect back", "leap start", "leap airborne", "leap melee"
}) do
    noWeaponIk[name] = true
end

-- "D:\halo\tags\characters\x.actor_variant" -> "D:\halo\tags\"
local function tagsRootOf(path)
    local lower = path:lower():gsub("/", "\\")
    local at
    local from = 1
    while true do
        local found = lower:find("\\tags\\", from, true)
        if not found then
            break
        end
        at = found
        from = found + 1
    end
    if not at then
        error("the actor variant is not inside a tags folder", 0)
    end
    return path:sub(1, at + 5)
end

-- The animation of a slot and its permutations ("next animation" chain), as the player
-- lists them: {{index (first = 0), name, frames}, ...}; empty when the slot has none
local function slotAnimations(list, slot, animations)
    local entry = list[slot]
    local index = entry and entry["animation"] or -1
    local found = {}
    local seen = {}
    while index >= 0 and index < #animations and not seen[index] do
        seen[index] = true
        local animation = animations[index + 1]
        found[#found + 1] = {index = index, name = animation["name"], frames = animation["frame count"]}
        index = animation["next animation"]
    end
    return found
end

local function addBehaviors(out, group, rows, seat, weaponClass, animations)
    for _, row in ipairs(rows) do
        local list, slot
        if row[2] == "seat" then
            list, slot = seat["animations"], seatSlotIndex[row[3]]
        else
            list, slot = weaponClass["animations"], classSlotIndex[row[3]]
        end
        local found = slotAnimations(list, slot, animations)
        out[#out + 1] = {
            group = group,
            name = row[1],
            missing = row[4],
            ik = not noWeaponIk[row[1]] and group == "Unit states",
            about = row[5],
            never = row[5] == never,
            count = #found,
            animations = found
        }
    end
end

-- The seat with that label that animates the weapon, and its weapon class (nil when none)
local function findModeSeat(graph, label, weaponLabel)
    local labelFound = false
    for _, seat in ipairs(graph["UNITS"]) do
        if seat["label"]:lower() == label then
            labelFound = true
            local weaponClass, matched = actorVariant.findWeaponClass(seat, weaponLabel)
            if matched then
                return seat, weaponClass, true
            end
        end
    end
    return nil, nil, labelFound
end

function actorUi.behaviors(variantPath, outPath)
    if not (variantPath and outPath) then
        error("usage: run.lua bridge.actor_ui behaviors <actor_variant tag> <out.json>", 0)
    end
    local defs = tagDefs.open()
    local tagsRoot = tagsRootOf(variantPath)
    local variant = tagReader.readFile(defs, variantPath)
    if variant.group ~= "actor_variant" then
        error("not an actor_variant tag", 0)
    end
    local unitRef = tagFields.refText(defs, variant.root["unit"])
    local weaponRef = tagFields.refText(defs, variant.root["weapon"])

    local weaponLabel = "unarmed"
    local weapon = actorVariant.readRef(defs, tagsRoot, weaponRef)
    if weapon then
        weaponLabel = actorVariant.findField(weapon.rootStruct, weapon.root, "label") or ""
    end

    local unit = actorVariant.readRef(defs, tagsRoot, unitRef)
    if not unit then
        error("could not read the unit '" .. unitRef .. "'", 0)
    end
    local graphRef = actorVariant.findField(unit.rootStruct, unit.root, "animation graph")
    local graphText = graphRef and tagFields.refText(defs, graphRef) or ""
    local graph = actorVariant.readRef(defs, tagsRoot, graphText)
    if not graph then
        error("could not read the animation graph '" .. graphText .. "' of the unit", 0)
    end
    local animations = graph.root["animations"]

    local result = {
        unit = unitRef,
        weapon = weaponRef,
        actor = tagFields.refText(defs, variant.root["actor definition"]),
        weaponLabel = weaponLabel,
        graph = graphText,
        graphPath = tagsRoot .. graphText,
        modes = {}
    }
    for _, mode in ipairs(modes) do
        local seat, weaponClass, labelFound = findModeSeat(graph.root, mode[2], weaponLabel)
        local entry = {name = mode[1], seat = mode[2], about = mode[3], found = seat ~= nil, behaviors = {}}
        if seat then
            -- Unit markers the game puts on weapon markers (inverse kinematics)
            entry.ikMarkers, entry.ikAttach = {}, {}
            for _, point in ipairs(weaponClass["ik points"]) do
                entry.ikMarkers[#entry.ikMarkers + 1] = point["marker"]
                entry.ikAttach[#entry.ikAttach + 1] = point["attach to marker"]
            end
            addBehaviors(entry.behaviors, "Unit states", states, seat, weaponClass, animations)
            addBehaviors(entry.behaviors, "AI impulses", impulses, seat, weaponClass, animations)
        elseif labelFound then
            entry.note = ("Stance '%s' has no animations for weapon '%s': the unit stays in the stance it was in.")
                :format(mode[2], weaponLabel)
        else
            entry.note = ("The animation graph has no '%s' stance: the unit stays in the stance it was in.")
                :format(mode[2])
        end
        result.modes[#result.modes + 1] = entry
    end

    local f = assert(io.open(outPath, "wb"))
    f:write(json.encode(result))
    f:close()
end

return actorUi
