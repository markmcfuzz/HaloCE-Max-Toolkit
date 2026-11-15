-- actor_variant -> 3ds Max: its unit, weapon and actor paths, the markers that hold the weapon
-- and its change colors. Read in Max by builders\tag\actor_variant\lua_reader.ms.
local tagReader = require "tags.tag_reader"
local tagDefs = require "tags.tag_defs"
local tagFields = require "importers.shared.tag_fields"

local readAs = tagDefs.readAs

local actorVariant = {group = "actor_variant", version = 1}

local function warn(text)
    io.stdout:write("warning: ", text, "\n")
end

-- Value of the first field with that key, also looking inside structs (unit.object...)
local function findField(structDef, element, key)
    for _, field in ipairs(structDef.fields) do
        if field.key == key then
            return element[key]
        end
    end
    for _, field in ipairs(structDef.fields) do
        if field.readAs == readAs.struct then
            local found = findField(field.sub, element[field.key], key)
            if found ~= nil then
                return found
            end
        end
    end
    return nil
end

-- Reads the tag a reference points to; nil (with a warning) when it can't be read
local function readRef(defs, tagsRoot, refText)
    if refText == "" then
        return nil
    end
    local readOk, tagData = pcall(tagReader.readFile, defs, tagsRoot .. refText)
    if not readOk then
        warn(tostring(tagData))
        return nil
    end
    return tagData
end

-- Same rule as the game (unit_set_or_test_seat_and_weapon_label): "unarmed" matches the
-- empty label, the rest ignore case
local function typeMatches(typeLabel, weaponLabel)
    if weaponLabel == "unarmed" and typeLabel == "" then
        return true
    end
    return typeLabel:lower() == weaponLabel:lower()
end

-- The weapon class of the seat that animates that weapon. Like the game, the last class
-- that matches wins; with no match, the last class that has weapon types (found = false)
local function findWeaponClass(seat, weaponLabel)
    local matched, fallback
    for _, weaponClass in ipairs(seat["weapons"]) do
        local types = weaponClass["weapon types"]
        if #types > 0 then
            fallback = weaponClass
        end
        for _, weaponType in ipairs(types) do
            if typeMatches(weaponType["label"], weaponLabel) then
                matched = weaponClass
                break
            end
        end
    end
    return matched or fallback, matched ~= nil
end

-- Units start in the "stand" seat; the first seat when the graph has none
local function findSeat(graph, label)
    local seats = graph["UNITS"]
    for _, seat in ipairs(seats) do
        if seat["label"]:lower() == label then
            return seat
        end
    end
    return seats[1]
end

-- options[1]: tags folder, to read the unit, weapon and animation tags
function actorVariant.write(root, output, options, tagData, defs)
    local tagsRoot = (options[1] or ""):gsub("[/\\]+$", "") .. "\\"
    local unitRef = tagFields.refText(defs, root["unit"])
    local weaponRef = tagFields.refText(defs, root["weapon"])
    output:string(unitRef)
    output:string(weaponRef)
    output:string(tagFields.refText(defs, root["actor definition"]))

    local weaponLabel = "unarmed"
    local weapon = readRef(defs, tagsRoot, weaponRef)
    if weapon then
        weaponLabel = findField(weapon.rootStruct, weapon.root, "label") or ""
    end

    local seatLabel, handMarker, gripMarker, found = "", "", "", false
    local unit = readRef(defs, tagsRoot, unitRef)
    local graphRef = unit and findField(unit.rootStruct, unit.root, "animation graph")
    local graph = graphRef and readRef(defs, tagsRoot, tagFields.refText(defs, graphRef))
    local seat = graph and findSeat(graph.root, "stand")
    if seat then
        seatLabel = seat["label"]
        local weaponClass
        weaponClass, found = findWeaponClass(seat, weaponLabel)
        if weaponClass then
            handMarker = weaponClass["hand marker"]
            gripMarker = weaponClass["grip marker"]
        end
        if not found and weaponRef ~= "" then
            warn(("stance '%s' has no animations for weapon '%s'"):format(seatLabel, weaponLabel))
        end
    end
    output:string(weaponLabel)
    output:string(seatLabel)
    output:string(handMarker)
    output:string(gripMarker)
    output:int(found and 1 or 0)

    -- The game only uses the first four
    local colors = root["change colors"]
    local count = math.min(#colors, 4)
    output:int(count)
    for i = 1, count do
        output:floats(colors[i]["color lower bound"], 3)
        output:floats(colors[i]["color upper bound"], 3)
    end
end

-- Shared with bridge\actor_ui.lua
actorVariant.findField = findField
actorVariant.readRef = readRef
actorVariant.findWeaponClass = findWeaponClass

return actorVariant
