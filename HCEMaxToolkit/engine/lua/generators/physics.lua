-- New physics tags from the templates in generators\templates (<name>.json; _index.json groups
-- them in categories), in the same format as importers\physics.lua:
--   run.lua generators.physics preset <name> <minX> <minY> <minZ> <maxX> <maxY> <maxZ> <option> <out.bin>
--       [wheels: "x y z radius node;..."] [root node: model node of the other mass points]
--       [exact: 1 = a stock template as it is] [node names: "a;b;...", for stock templates]
--   run.lua generators.physics list <out.json>    (the categories, for core\tag_editor\new_physics.py)
--   run.lua generators.physics vehicleValues <name> <option> <out.bin> [wheels]    (its .vehicle's fields)
-- The box (world units, forward = +X) is what the physics must fill; an empty box (all zeros)
-- uses the template's size. <option>: one of the template's options (the ball's kinds), else ignored.
--
-- Template: label, summary (one line), notes (what the dialog's numbers can't say), points_per_wheel
-- (a bike: 2), vehicle_type (the .vehicle "type" it needs), size {x, y, z},
-- vehicle = { fields } (its .vehicle's fields, from the stock vehicle of that type),
-- physics = { fields, powered_mass_points, parts }, and optional options = { label, default,
-- items = { { name, label, summary, notes, bounce, size, vehicle, physics = { fields, parts,
-- part_values } } } } added on top of the template's (summary, notes and size replace it);
-- part_values = { [part name] = { key = value } } changes the template's parts (e.g. axle_count).
-- fields: tag field names; a value is a number, a text, or {by_radius = {{radius, value}, ...}}
-- (straight lines by half the box's largest side). powered_mass_points: tag fields of each one.
-- parts (each with a radius, a fraction of the box length unless radius_of says "smallest"/"largest",
-- and mass_point = tag fields for its mass points):
--   shell    the ball: points (1, 12 or 32), point_ratio {min, max} of the ball's radius,
--            optional point_radius (world units, kept between those ratios)
--   corners  one point in each corner of the box
--   wheels   axles = { { name, x (fraction of the length from the center), mass_point } }, a left
--            and a right wheel each (single = one in the middle), sink (radii above the box
--            bottom), half_track (center to wheel, fraction of the box width; default: at the
--            sides); or axle_count, front_x,
--            back_x, max_spacing and front / middle / back mass_point (countedAxles)
--   treads   points_per_side, sink; powered 0 = left, 1 = right
--   hull     four points over the wheels and one on top
--   point    one point: x / y / z = {from = "min"/"center"/"max", radii = offset in radii,
--            of_size = offset in box sizes}; a left and a right point with mirror = radii from
--            the sides, or half_track = center to point in box widths
--   row      count points along X from front_x to back_x, at y / z as point (a fuselage)
--   cylinder rings x points around axis "x"/"y"/"z", filling the box; point_ratio of its radius
--            (a tire, a log, a barrel)
-- A field value can also be {length = k}: k x the box length (a plane's radius)
-- Values come from the stock tags and docs\physics.md.
local tagDefs = require "tags.tag_defs"
local tagFields = require "importers.shared.tag_fields"
local json = require "tags.json"
local maxbin = require "bridge.maxbin"
local physicsImporter = require "importers.physics"

local generator = {}

local floatText = tagFields.floatText

local templatesDir = (debug.getinfo(1, "S").source:match("^@(.*)[/\\]") or ".") .. "/templates"

local function vectorText(x, y, z)
    return floatText(x) .. " " .. floatText(y) .. " " .. floatText(z)
end

-- value at x from {x, value} pairs in order, straight lines between them, flat outside
local function interpolate(pairsList, x)
    if x <= pairsList[1][1] then
        return pairsList[1][2]
    end
    for i = 2, #pairsList do
        local a, b = pairsList[i - 1], pairsList[i]
        if x <= b[1] then
            return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1])
        end
    end
    return pairsList[#pairsList][2]
end

local function clamp(v, low, high)
    return math.max(low, math.min(high, v))
end

-- Box helpers: length (X), width (Y), height (Z) and center
local function boxSize(box)
    return box.max[1] - box.min[1], box.max[2] - box.min[2], box.max[3] - box.min[3]
end

local function boxCenter(box)
    return (box.min[1] + box.max[1]) / 2, (box.min[2] + box.max[2]) / 2, (box.min[3] + box.max[3]) / 2
end

-- Template value -> field text; radius: half the box's largest side, for by_radius; box: for
-- {length = k}, k x the box length
local function valueText(value, radius, box)
    if type(value) == "number" then
        return floatText(value)
    elseif type(value) == "table" and value.by_radius then
        return floatText(interpolate(value.by_radius, radius))
    elseif type(value) == "table" and value.length and box then
        return floatText(value.length * (box.max[1] - box.min[1]))
    end
    return tostring(value)
end

-- Fields shared by the stock vehicles
local function baseFields()
    return {
        ["radius"] = "-1", -- new physics
        ["moment scale"] = "1",
        ["mass"] = "1000",
        ["density"] = "4",
        ["gravity scale"] = "1",
        ["ground friction"] = "0.2",
        ["ground depth"] = "0.15",
        ["ground damp fraction"] = "0.05",
        ["ground normal k1"] = "0.707107",
        ["ground normal k0"] = "0.5",
        ["water friction"] = "0.05",
        ["water depth"] = "0.25",
        ["water density"] = "1",
        ["air friction"] = "0.005",
        ["powered mass points"] = "0",
        ["mass points"] = "0"
    }
end

-- Model node of the mass points that don't set one: the model's root node (generator.fields)
local defaultModelNode = -1

-- values: tag fields of the mass point ("powered mass point", "relative mass", "friction type"...)
local function addMassPoint(fields, name, position, radius, values)
    local index = tonumber(fields["mass points"])
    local prefix = "mass points[" .. index .. "]."
    fields[prefix .. "name"] = name
    fields[prefix .. "powered mass point"] = "-1"
    fields[prefix .. "model node"] = tostring(defaultModelNode)
    fields[prefix .. "relative mass"] = "1"
    fields[prefix .. "relative density"] = "1"
    fields[prefix .. "position"] = vectorText(position[1], position[2], position[3])
    fields[prefix .. "forward"] = "1 0 0"
    fields[prefix .. "up"] = "0 0 1"
    fields[prefix .. "friction type"] = "0"
    fields[prefix .. "friction parallel scale"] = "1"
    fields[prefix .. "friction perpendicular scale"] = "1"
    fields[prefix .. "radius"] = floatText(radius)
    for key, value in pairs(values or {}) do
        fields[prefix .. key] = valueText(value)
    end
    fields["mass points"] = tostring(index + 1)
end

-- values: tag fields; flags 1 = ground friction (wheels, treads), 64 = antigrav
local function addPoweredMassPoint(fields, values)
    local index = tonumber(fields["powered mass points"])
    local prefix = "powered mass points[" .. index .. "]."
    for key, value in pairs(values) do
        fields[prefix .. key] = valueText(value)
    end
    fields["powered mass points"] = tostring(index + 1)
end

-------------------------------------------------------------------------------
-- Parts: each adds its mass points for the box
-------------------------------------------------------------------------------

local parts = {}

local function partRadius(part, box)
    local length, width, height = boxSize(box)
    local of = part.radius_of
    if of == "smallest" then
        return math.min(length, width, height) * part.radius
    elseif of == "largest" then
        return math.max(length, width, height) * part.radius
    end
    return length * part.radius
end

-- Vertices of an icosahedron (12) plus a dodecahedron (32 together), unit length
local function ballDirections(count)
    local phi = (1 + math.sqrt(5)) / 2
    local directions = {}
    local function add(x, y, z)
        local length = math.sqrt(x * x + y * y + z * z)
        directions[#directions + 1] = {x / length, y / length, z / length}
    end
    local function addCyclic(a, b)
        add(0, a, b)
        add(a, b, 0)
        add(b, 0, a)
    end
    for _, a in ipairs({1, -1}) do
        for _, b in ipairs({phi, -phi}) do
            addCyclic(a, b)
        end
    end
    if count > 12 then
        for _, x in ipairs({1, -1}) do
            for _, y in ipairs({1, -1}) do
                for _, z in ipairs({1, -1}) do
                    add(x, y, z)
                end
            end
        end
        for _, a in ipairs({1 / phi, -1 / phi}) do
            for _, b in ipairs({phi, -phi}) do
                addCyclic(a, b)
            end
        end
    end
    return directions
end

-- Balls that bounce need big points of a fixed size (docs\physics.md, section 10)
function parts.shell(fields, part, box)
    local length, width, height = boxSize(box)
    local cx, cy, cz = boxCenter(box)
    local ballRadius = math.max(length, width, height) / 2
    if part.points <= 1 then
        addMassPoint(fields, part.name, {cx, cy, cz}, ballRadius, part.mass_point)
        return
    end
    local low, high = part.point_ratio[1], part.point_ratio[2]
    local ratio = part.point_radius and clamp(part.point_radius / ballRadius, low, high) or low
    local radius = ballRadius * ratio
    local shell = ballRadius - radius
    for i, d in ipairs(ballDirections(part.points)) do
        addMassPoint(fields, part.name .. " " .. i, {cx + d[1] * shell, cy + d[2] * shell, cz + d[3] * shell},
                     radius, part.mass_point)
    end
end

function parts.corners(fields, part, box)
    local radius = partRadius(part, box)
    local names = {"front", "back", "left", "right", "top", "bottom"}
    for xi = 1, 2 do
        for yi = 1, 2 do
            for zi = 1, 2 do
                local x = xi == 1 and box.max[1] - radius or box.min[1] + radius
                local y = yi == 1 and box.max[2] - radius or box.min[2] + radius
                local z = zi == 1 and box.max[3] - radius or box.min[3] + radius
                addMassPoint(fields, names[4 + zi] .. " " .. names[xi] .. " " .. names[2 + yi], {x, y, z}, radius,
                             part.mass_point)
            end
        end
    end
end

-- axle_count axles evenly from front_x to back_x: the front half gets front (powered 0), the back
-- half back (powered 1), and with an odd count the middle one gets middle. Radius at most
-- max_spacing x the distance between axles, so the wheels don't overlap
local function countedAxles(part, length)
    local count = part.axle_count
    local axles = {}
    for i = 1, count do
        local x = count > 1 and part.front_x + (part.back_x - part.front_x) * (i - 1) / (count - 1) or 0
        local group = i <= math.floor(count / 2) and part.front or i > count - math.floor(count / 2) and part.back or
                          part.middle
        axles[i] = {name = tostring(i), x = x, mass_point = group}
    end
    local radius = length * part.radius
    if count > 1 and part.max_spacing then
        radius = math.min(radius, length * math.abs(part.front_x - part.back_x) / (count - 1) * part.max_spacing)
    end
    return axles, radius
end

-- On the scene's wheels (part.fit = groupAxles): each mass point at its wheel's center with
-- fit_radius x the wheel's radius (warthog: 0.26 on a 0.2 tire), its node as model node.
-- A lone wheel on a pair axle (bike) gets two points side by side, half_track apart
local function fittedWheels(fields, part, box)
    local width = box.max[2] - box.min[2]
    local count = #part.fit
    for i, axle in ipairs(part.fit) do
        local name, values, single
        if part.axle_count then
            local half = math.floor(count / 2)
            values = i <= half and part.front or i > count - half and part.back or part.middle
            name = part.name .. " " .. i
        else
            local spec = part.axles[i]
            name, values, single = part.name .. " " .. spec.name, spec.mass_point, spec.single
        end
        local function add(pointName, wheel, y)
            local pointValues = {["model node"] = wheel.node >= 0 and wheel.node or defaultModelNode}
            for key, value in pairs(values or {}) do
                pointValues[key] = value
            end
            addMassPoint(fields, pointName, {wheel.x, y, wheel.z}, wheel.radius * (part.fit_radius or 1.3),
                         pointValues)
        end
        local first, second = axle.wheels[1], axle.wheels[2]
        if second then
            add(name .. " left", first, first.y)
            add(name .. " right", second, second.y)
        elseif single then
            add(name, first, first.y)
        else
            local dy = width * (part.half_track or 0.25)
            add(name .. " left", first, first.y + dy)
            add(name .. " right", first, first.y - dy)
        end
    end
end

-- A bit under the box: the wheels sink into the ground under the weight. axles: { { name, x,
-- mass_point } }, or axle_count (countedAxles); fit: on the scene's wheels (fittedWheels)
function parts.wheels(fields, part, box)
    if part.fit then
        return fittedWheels(fields, part, box)
    end
    local length, width = boxSize(box)
    local cx, cy = boxCenter(box)
    local axles, radius = part.axles, partRadius(part, box)
    if part.axle_count then
        axles, radius = countedAxles(part, length)
    end
    local dy = part.half_track and width * part.half_track or math.max(width / 2 - radius, 0)
    local z = box.min[3] + radius * part.sink
    for _, axle in ipairs(axles) do
        local x = cx + length * axle.x
        local name = part.name .. " " .. axle.name
        if axle.single then
            addMassPoint(fields, name, {x, cy, z}, radius, axle.mass_point)
        else
            addMassPoint(fields, name .. " left", {x, cy + dy, z}, radius, axle.mass_point)
            addMassPoint(fields, name .. " right", {x, cy - dy, z}, radius, axle.mass_point)
        end
    end
end

function parts.treads(fields, part, box)
    local length, width = boxSize(box)
    local cy = (box.min[2] + box.max[2]) / 2
    local radius = partRadius(part, box)
    local dy = math.max(width / 2 - radius, 0)
    local z = box.min[3] + radius * part.sink
    local count = part.points_per_side
    for side = 0, 1 do
        for i = 0, count - 1 do
            local x = box.max[1] - radius - (length - 2 * radius) * i / (count - 1)
            local values = {["powered mass point"] = side}
            for key, value in pairs(part.mass_point or {}) do
                values[key] = value
            end
            addMassPoint(fields, part.name .. " " .. (side == 0 and "left " or "right ") .. (i + 1),
                         {x, side == 0 and cy + dy or cy - dy, z}, radius, values)
        end
    end
end

-- Four points over the wheels and one on top, so the body lands on them when it rolls over
function parts.hull(fields, part, box)
    local length, width = boxSize(box)
    local cx, cy = boxCenter(box)
    local radius = partRadius(part, box)
    local dx = math.max(length / 2 - radius, 0)
    local dy = math.max(width / 2 - radius, 0)
    local z = math.min(box.min[3] + radius * 1.5, box.max[3] - radius)
    addMassPoint(fields, "hull front left", {cx + dx, cy + dy, z}, radius)
    addMassPoint(fields, "hull front right", {cx + dx, cy - dy, z}, radius)
    addMassPoint(fields, "hull back left", {cx - dx, cy + dy, z}, radius)
    addMassPoint(fields, "hull back right", {cx - dx, cy - dy, z}, radius)
    addMassPoint(fields, "hull top", {cx, cy, box.max[3] - radius}, radius, {["relative mass"] = 0.5})
end

-- Coordinate i (1 = x) of a part's point: part.x / y / z = {from = "min"/"center"/"max", radii,
-- of_size = offset as a fraction of the box's size on that axis}
local function partAxis(part, box, i, radius)
    local spec = part[({"x", "y", "z"})[i]] or {}
    local from = spec.from or "center"
    local base = from == "min" and box.min[i] or from == "max" and box.max[i] or (box.min[i] + box.max[i]) / 2
    return base + (spec.radii or 0) * radius + (spec.of_size or 0) * (box.max[i] - box.min[i])
end

function parts.point(fields, part, box)
    local radius = partRadius(part, box)
    local x, y, z = partAxis(part, box, 1, radius), partAxis(part, box, 2, radius), partAxis(part, box, 3, radius)
    if part.mirror or part.half_track then
        local width = box.max[2] - box.min[2]
        local dy = part.half_track and width * part.half_track or math.max(width / 2 - part.mirror * radius, 0)
        addMassPoint(fields, part.name .. " left", {x, y + dy, z}, radius, part.mass_point)
        addMassPoint(fields, part.name .. " right", {x, y - dy, z}, radius, part.mass_point)
    else
        addMassPoint(fields, part.name, {x, y, z}, radius, part.mass_point)
    end
end

-- count points in a line along X, from front_x to back_x (fractions of the length from the
-- center), at y / z as parts.point: a fuselage or a keel
function parts.row(fields, part, box)
    local radius = partRadius(part, box)
    local length = box.max[1] - box.min[1]
    local cx = (box.min[1] + box.max[1]) / 2
    local y, z = partAxis(part, box, 2, radius), partAxis(part, box, 3, radius)
    for i = 1, part.count do
        local t = part.count > 1 and (i - 1) / (part.count - 1) or 0.5
        local x = cx + length * (part.front_x + (part.back_x - part.front_x) * t)
        addMassPoint(fields, part.name .. " " .. i, {x, y, z}, radius, part.mass_point)
    end
end

-- A cylinder along axis ("x", "y" or "z") filling the box: rings of points around it, the
-- first and last at its ends. point_ratio: point radius / cylinder radius. A tire (axis y), a
-- log (x) or a standing barrel (z): it rolls on its rings and rests on its ends
function parts.cylinder(fields, part, box)
    local a = ({x = 1, y = 2, z = 3})[part.axis or "x"]
    local b, c = a % 3 + 1, (a + 1) % 3 + 1
    local center = {(box.min[1] + box.max[1]) / 2, (box.min[2] + box.max[2]) / 2, (box.min[3] + box.max[3]) / 2}
    local cylinderRadius = math.min(box.max[b] - box.min[b], box.max[c] - box.min[c]) / 2
    local radius = cylinderRadius * part.point_ratio
    local circle = cylinderRadius - radius
    local first, last = box.min[a] + radius, box.max[a] - radius
    for ring = 1, part.rings do
        local along = part.rings > 1 and first + (last - first) * (ring - 1) / (part.rings - 1) or center[a]
        for j = 1, part.points do
            local angle = 2 * math.pi * (j - 1) / part.points
            -- cos(90) is 6e-17, not 0
            local cos, sin = math.cos(angle), math.sin(angle)
            cos = math.abs(cos) < 1e-9 and 0 or cos
            sin = math.abs(sin) < 1e-9 and 0 or sin
            local position = {center[1], center[2], center[3]}
            position[a] = along
            position[b] = center[b] + circle * cos
            position[c] = center[c] + circle * sin
            addMassPoint(fields, part.name .. " " .. ring .. "-" .. j, position, radius, part.mass_point)
        end
    end
end

-------------------------------------------------------------------------------
-- Templates
-------------------------------------------------------------------------------

local function loadTemplate(name)
    if not name:match("^[%w_%-]+$") then
        error(("bad template name '%s'"):format(tostring(name)), 0)
    end
    local ok, template = pcall(json.decodeFile, templatesDir .. "/" .. name .. ".json")
    if not ok then
        error(("unknown physics template '%s' (%s)"):format(name, tostring(template)), 0)
    end
    return template
end

-- The chosen option of a template (by name), else its default; nil without options
local function templateOption(template, optionName)
    local options = template.options
    if not options then
        return nil
    end
    local function find(wanted)
        for _, item in ipairs(options.items) do
            if wanted and item.name == tostring(wanted) then
                return item
            end
        end
    end
    return find(optionName) or find(options.default) or options.items[1]
end

-- A copy of part with changes on top
local function changedPart(part, changes)
    local changed = {}
    for key, value in pairs(part) do
        changed[key] = value
    end
    for key, value in pairs(changes) do
        changed[key] = value
    end
    return changed
end

-- partValues: { [part name] = { key = value } } an option changes in the template's parts;
-- fit: the scene's wheels for the wheels part (groupAxles)
local function addPhysics(fields, physics, box, radius, partValues, fit)
    for key, value in pairs(physics.fields or {}) do
        fields[key] = valueText(value, radius, box)
    end
    for _, values in ipairs(physics.powered_mass_points or {}) do
        addPoweredMassPoint(fields, values)
    end
    for _, part in ipairs(physics.parts or {}) do
        local build = parts[part.type]
        if not build then
            error(("unknown template part '%s'"):format(tostring(part.type)), 0)
        end
        local changes = partValues and part.name and partValues[part.name]
        if changes then
            part = changedPart(part, changes)
        end
        if fit and part.type == "wheels" then
            part = changedPart(part, {fit = fit})
        end
        build(fields, part, box)
    end
end

-------------------------------------------------------------------------------
-- Scene wheels (tool_new_physics.ms): "x y z radius node;..." in world units, node = model node
-- index or -1
-------------------------------------------------------------------------------

local function parseWheels(text)
    local wheels = {}
    for chunk in (text or ""):gmatch("[^;]+") do
        local values = {}
        for number in chunk:gmatch("%S+") do
            values[#values + 1] = tonumber(number)
        end
        if #values == 5 then
            wheels[#wheels + 1] = {x = values[1], y = values[2], z = values[3], radius = values[4], node = values[5]}
        end
    end
    return wheels
end

-- Axles from front (+X) to back; wheels closer in X than half the biggest radius share one,
-- left (+Y) first
local function groupAxles(wheels)
    local tolerance = 0
    for _, wheel in ipairs(wheels) do
        tolerance = math.max(tolerance, wheel.radius / 2)
    end
    table.sort(wheels, function(a, b) return a.x > b.x end)
    local axles = {}
    for _, wheel in ipairs(wheels) do
        local last = axles[#axles]
        if last and last.x - wheel.x <= tolerance then
            table.insert(last.wheels, wheel)
        else
            axles[#axles + 1] = {x = wheel.x, wheels = {wheel}}
        end
    end
    for _, axle in ipairs(axles) do
        table.sort(axle.wheels, function(a, b) return a.y > b.y end)
    end
    return axles
end

-- The template's wheels part with an option's changes, or nil
local function wheelsPart(template, option)
    local changes = option and option.physics and option.physics.part_values or {}
    for _, part in ipairs(template.physics and template.physics.parts or {}) do
        if part.type == "wheels" then
            return changes[part.name] and changedPart(part, changes[part.name]) or part
        end
    end
end

-- True when the wheels part can sit on these axles: as many axles, and on each one a single
-- wheel for a single, two for a pair (one for a pair with half_track: the bike)
local function axlesFit(part, axles)
    if part.axle_count then
        if #axles ~= part.axle_count then
            return false
        end
        for _, axle in ipairs(axles) do
            if #axle.wheels ~= 2 then
                return false
            end
        end
        return true
    end
    if #axles ~= #part.axles then
        return false
    end
    for i, axle in ipairs(axles) do
        local count, spec = #axle.wheels, part.axles[i]
        local wanted = (spec.single or part.half_track) and 1 or 2
        local fits = count == wanted
        if not fits then
            return false
        end
    end
    return true
end

-------------------------------------------------------------------------------
-- Stock templates (stock = true): physics.mass_points = { { node, wheel, fields } }, all as text.
-- An exact copy of the tag; with a box (Fit to Model) it is scaled to it
-------------------------------------------------------------------------------

-- Without its prefix ("frame hull" = "bip01 hull"): the importer's Node Prefix can change it
local function nodeKey(name)
    return (name:lower():gsub("^[^ _]+[ _]", "", 1))
end

-- "name;name;..." in model node order -> { key = index }, count
local function parseNodeNames(text)
    local nodes, count = {}, 0
    for name in (text or ""):gmatch("[^;]+") do
        local key = nodeKey(name)
        if nodes[key] == nil then
            nodes[key] = count
        end
        count = count + 1
    end
    return nodes, count
end

local function stockPosition(point)
    local x, y, z = point.fields.position:match("(%S+)%s+(%S+)%s+(%S+)")
    return tonumber(x), tonumber(y), tonumber(z)
end

-- Box of the spheres; without the wheels when those go on the model's
local function stockBounds(points, skipWheels)
    local low, high = {math.huge, math.huge, math.huge}, {-math.huge, -math.huge, -math.huge}
    for _, point in ipairs(points) do
        if not (skipWheels and point.wheel) then
            local position, radius = {stockPosition(point)}, tonumber(point.fields.radius)
            for i = 1, 3 do
                low[i] = math.min(low[i], position[i] - radius)
                high[i] = math.max(high[i], position[i] + radius)
            end
        end
    end
    return low, high
end

-- Each wheel mass point -> the scene's wheel in its place (same axles, front first, left first)
local function pairStockWheels(templateName, points, wheelsText)
    local scene = parseWheels(wheelsText)
    if #scene == 0 then
        return nil
    end
    local own = {}
    for _, point in ipairs(points) do
        if point.wheel then
            local x, y, z = stockPosition(point)
            own[#own + 1] = {x = x, y = y, z = z, radius = tonumber(point.fields.radius), point = point}
        end
    end
    local ownAxles, sceneAxles = groupAxles(own), groupAxles(scene)
    local paired = {}
    local fits = #own == #scene and #ownAxles == #sceneAxles
    for i = 1, fits and #ownAxles or 0 do
        fits = fits and #ownAxles[i].wheels == #sceneAxles[i].wheels
        for j = 1, fits and #ownAxles[i].wheels or 0 do
            paired[ownAxles[i].wheels[j].point] = sceneAxles[i].wheels[j]
        end
    end
    if not fits then
        error(("template '%s' does not fit %d wheels in %d axles"):format(templateName, #scene, #sceneAxles), 0)
    end
    return paired
end

-- box nil: the tag as it is. Scaled evenly: centered on the box, standing on its bottom.
-- Model nodes by name when the scene has nodes (else the model's root); without nodes, the tag's
local function stockFields(templateName, template, box, wheelsText, nodeNames)
    local physics = template.physics
    local points = physics.mass_points
    local fields = {["powered mass points"] = "0", ["mass points"] = "0"}
    for key, value in pairs(physics.fields) do
        fields[key] = value
    end
    for _, values in ipairs(physics.powered_mass_points or {}) do
        addPoweredMassPoint(fields, values)
    end
    local paired = box and pairStockWheels(templateName, points, wheelsText)
    local scale, low, high = 1, nil, nil
    if box then
        low, high = stockBounds(points, paired ~= nil)
        scale = math.huge
        for i = 1, 3 do
            if high[i] > low[i] then
                scale = math.min(scale, (box.max[i] - box.min[i]) / (high[i] - low[i]))
            end
        end
    end
    local nodes, nodeCount = parseNodeNames(nodeNames)
    for _, point in ipairs(points) do
        local values = {}
        for key, value in pairs(point.fields) do
            values[key] = value
        end
        if nodeCount > 0 then
            values["model node"] = tostring(nodes[nodeKey(point.node or "")] or defaultModelNode)
        end
        if box then
            local wheel = paired and paired[point]
            if wheel then
                values.position = vectorText(wheel.x, wheel.y, wheel.z)
                values.radius = floatText(wheel.radius * 1.3)
                if wheel.node >= 0 then
                    values["model node"] = tostring(wheel.node)
                end
            else
                local x, y, z = stockPosition(point)
                local cx, cy = boxCenter(box)
                values.position = vectorText(cx + (x - (low[1] + high[1]) / 2) * scale,
                                             cy + (y - (low[2] + high[2]) / 2) * scale,
                                             box.min[3] + (z - low[3]) * scale)
                values.radius = floatText(tonumber(point.fields.radius) * scale)
            end
        end
        addMassPoint(fields, values.name, {0, 0, 0}, 0, values)
    end
    return fields
end

-- Key -> text fields of a template; box nil or empty = the template's size, standing on the origin.
-- wheelsText: the scene's wheels to fit the wheels on, or nil / "". rootNode: model node of the
-- mass points that don't set one (the model's root), or nil / -1. Stock templates only:
-- exact = the tag as it is (ignores the box); nodeNames = the scene's nodes, "a;b;..."
function generator.fields(templateName, box, optionName, wheelsText, rootNode, exact, nodeNames)
    defaultModelNode = math.floor(tonumber(rootNode) or -1)
    local template = loadTemplate(templateName)
    local empty = not box
    if box then
        local length, width, height = boxSize(box)
        empty = length <= 0 or width <= 0 or height <= 0
    end
    if template.stock then
        return stockFields(templateName, template, not (empty or exact) and box or nil, wheelsText, nodeNames)
    end
    local option = templateOption(template, optionName)
    if empty then
        local size = option and option.size or template.size
        box = {min = {-size[1] / 2, -size[2] / 2, 0}, max = {size[1] / 2, size[2] / 2, size[3]}}
    end
    local radius = math.max(boxSize(box)) / 2
    local fields = baseFields()
    local optionPhysics = option and option.physics or {}
    local fit = nil
    local wheels = parseWheels(wheelsText)
    if #wheels > 0 then
        fit = groupAxles(wheels)
        local part = wheelsPart(template, option)
        if not (part and axlesFit(part, fit)) then
            error(("template '%s' does not fit %d wheels in %d axles"):format(templateName, #wheels, #fit), 0)
        end
    end
    addPhysics(fields, template.physics or {}, box, radius, optionPhysics.part_values, fit)
    addPhysics(fields, optionPhysics, box, radius)
    -- The tag holds 32 of each
    for _, block in ipairs({"mass points", "powered mass points"}) do
        if tonumber(fields[block]) > 32 then
            error(("template '%s' makes %s %s; the tag holds 32"):format(templateName, fields[block], block), 0)
        end
    end
    return fields
end

function generator.preset(templateName, minX, minY, minZ, maxX, maxY, maxZ, optionName, outPath, wheelsText,
                          rootNode, exact, nodeNames)
    if not outPath then
        error("usage: run.lua generators.physics preset <name> <minX> <minY> <minZ> <maxX> <maxY> <maxZ> " ..
                  "<option> <out.bin> [wheels] [root node] [exact: 1] [node names]", 0)
    end
    local box = {
        min = {tonumber(minX), tonumber(minY), tonumber(minZ)},
        max = {tonumber(maxX), tonumber(maxY), tonumber(maxZ)}
    }
    local fields = generator.fields(templateName, box, optionName, wheelsText, rootNode, exact == "1", nodeNames)
    -- Through the tag layout: every field of the tag, in tag order
    local defs = tagDefs.open()
    local rootStruct = defs:rootStruct(defs:group("physics"))
    local root = tagFields.unflatten(defs, rootStruct, fields, "")
    local output = maxbin.open(outPath, "physics", physicsImporter.version)
    physicsImporter.write(root, output, {}, {rootStruct = rootStruct}, defs)
    output:close()
end

-- The .vehicle "type" options, in tag order
local vehicleTypes = {"human tank", "human jeep", "human boat", "human plane", "alien scout", "alien fighter",
                      "turret"}

-- What a template sets on a .vehicle: the type and its vehicle fields (its stock vehicle's speeds,
-- turns, flags). Fitted wheels set wheel circumference: 2 pi x their average radius
local function vehicleFields(templateName, optionName, wheelsText)
    local template = loadTemplate(templateName)
    local option = templateOption(template, optionName)
    local fields = {}
    for _, vehicle in ipairs({template.vehicle or {}, option and option.vehicle or {}}) do
        for key, value in pairs(vehicle.fields or {}) do
            fields[key] = valueText(value)
        end
    end
    for i, name in ipairs(vehicleTypes) do
        if name == (template.vehicle_type or "turret") then
            fields["type"] = tostring(i - 1)
        end
    end
    local wheels = parseWheels(wheelsText)
    if #wheels > 0 then
        local sum = 0
        for _, wheel in ipairs(wheels) do
            sum = sum + wheel.radius
        end
        fields["wheel circumference"] = floatText(2 * math.pi * sum / #wheels)
    end
    return fields
end

-- The fields the template sets, to fill an existing .vehicle (the tag editor's "+" on its
-- physics): count, then key and value texts
--   run.lua generators.physics vehicleValues <name> <option> <out.bin> [wheels]
function generator.vehicleValues(templateName, optionName, outPath, wheelsText)
    if not outPath then
        error("usage: run.lua generators.physics vehicleValues <name> <option> <out.bin> [wheels]", 0)
    end
    local fields = vehicleFields(templateName, optionName, wheelsText)
    local keys = {}
    for key in pairs(fields) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    local output = maxbin.open(outPath, "vehicle_values", 1)
    output:int(#keys)
    for _, key in ipairs(keys) do
        output:string(key)
        output:string(fields[key])
    end
    output:close()
end

-------------------------------------------------------------------------------
-- The dialog's list: the same rows, in the same order, for every template of a vehicle type
-------------------------------------------------------------------------------

local TICKS_PER_SECOND = 30
local METERS_PER_WU = 3.048

-- World units per tick -> "86 km/h (0.26)"
local function speedText(speed)
    local kmh = speed * TICKS_PER_SECOND * METERS_PER_WU * 3.6
    local shown = (kmh > 0 and kmh < 10) and ("%.1f"):format(kmh) or ("%.0f"):format(kmh)
    return ("%s km/h (%g)"):format(shown, speed)
end

-- Antigrav height of each powered mass point, without repeats: "2.3 m / 0.8 m"
local function hoverText(fields)
    local heights, seen = {}, {}
    for i = 0, tonumber(fields["powered mass points"]) - 1 do
        local prefix = "powered mass points[" .. i .. "]."
        if math.floor((tonumber(fields[prefix .. "flags"]) or 0) / 64) % 2 == 1 then
            local text = ("%.1f m"):format((tonumber(fields[prefix .. "antigrav height"]) or 0) * METERS_PER_WU)
            if not seen[text] then
                seen[text] = true
                heights[#heights + 1] = text
            end
        end
    end
    return #heights > 0 and table.concat(heights, " / ") or "None"
end

-- Mass points per side of a tank (powered 0), and "4 of 6 wheels" of a jeep
local function treadPoints(fields)
    local count = 0
    for i = 0, tonumber(fields["mass points"]) - 1 do
        if tonumber(fields["mass points[" .. i .. "].powered mass point"]) == 0 then
            count = count + 1
        end
    end
    return tostring(count)
end

local function tractionText(fields, pointsPerWheel)
    local total, driven = 0, 0
    for i = 0, tonumber(fields["mass points"]) - 1 do
        local prefix = "mass points[" .. i .. "]."
        if fields[prefix .. "name"]:find("^tire") then
            total = total + 1
            if tonumber(fields[prefix .. "powered mass point"]) >= 0 then
                driven = driven + 1
            end
        end
    end
    return ("%d of %d wheels"):format(driven / pointsPerWheel, total / pointsPerWheel)
end

-- Flotation of the whole body: its average density under the water's
local function floatsText(fields)
    local density, water = tonumber(fields["density"]) or 0, tonumber(fields["water density"]) or 0
    local floats = density > 0 and density < water and (tonumber(fields["water depth"]) or 0) > 0
    return floats and "Yes" or "No"
end

-- The rows only this vehicle type has
local function typeRows(vehicleType, fields, vehicle, template)
    local radius = tonumber(fields["radius"]) or 0
    if vehicleType == "human jeep" then
        return {{"Steering", ("%g\194\176"):format(tonumber(vehicle["maximum left turn"]) or 0)},
                {"Traction", tractionText(fields, template.points_per_wheel or 1)}}
    elseif vehicleType == "human tank" then
        return {{"Points per tread", treadPoints(fields)}}
    elseif vehicleType == "alien scout" then
        return {{"Hover height", hoverText(fields)}}
    elseif vehicleType == "alien fighter" then
        -- With old physics (positive radius) the radius turns it, not the turn rate
        local turn = radius > 0 and {"Turn force", ("%g"):format(radius)} or
                         {"Turn rate", ("%g"):format(tonumber(vehicle["turn rate"]) or 0)}
        return {turn, {"Hover height", hoverText(fields)}}
    elseif vehicleType == "human plane" then
        return {{"Turn force", ("%g"):format(math.abs(radius))}, {"Physics", radius > 0 and "Old" or "New"}}
    elseif vehicleType == "human boat" then
        return {{"Lift", "0.003 front and middle, 0.005 back"}, {"Floats", floatsText(fields)}}
    end
    return {{"Floats", floatsText(fields)}}
end

-- What the dialog shows of a template with an option: its summary and its rows
local function templateDetails(templateName, template, optionName)
    local option = templateOption(template, optionName)
    local fields = generator.fields(templateName, nil, optionName)
    local vehicle = vehicleFields(templateName, optionName)
    local vehicleType = template.vehicle_type or "turret"
    local rows = {{"Mass points", fields["mass points"]}, {"Mass", ("%g"):format(tonumber(fields["mass"]) or 0)}}
    if vehicleType ~= "turret" then
        local top = tonumber(vehicle["maximum forward speed"]) or 0
        local acceleration = tonumber(vehicle["speed acceleration"]) or 0
        rows[#rows + 1] = {"Top speed", speedText(top)}
        rows[#rows + 1] = {"Reverse speed", speedText(tonumber(vehicle["maximum reverse speed"]) or 0)}
        rows[#rows + 1] = {"Full throttle", acceleration > 0 and
            ("%.1f s"):format(top / acceleration / TICKS_PER_SECOND) or "-"}
    end
    for _, row in ipairs(typeRows(vehicleType, fields, vehicle, template)) do
        rows[#rows + 1] = row
    end
    local bounce = option and option.bounce
    if bounce then
        rows[#rows + 1] = {"Bounce", bounce}
    end
    local notes = option and option.notes or template.notes
    if notes then
        rows[#rows + 1] = {"Notes", notes}
    end
    return {summary = option and option.summary or template.summary or "", rows = rows}
end

-- For the Create Physics Tag dialog (core\tag_editor\new_physics.py), as JSON: _index.json's
-- categories, each entry with its vehicle type, details (templateDetails) and its options
-- (unless the entry fixes one): { label, default, items = { { name, label, details } } }
function generator.list(outPath)
    if not outPath then
        error("usage: run.lua generators.physics list <out.json>", 0)
    end
    local categories = {}
    for _, category in ipairs(json.decodeFile(templatesDir .. "/_index.json").categories) do
        local entries = {}
        for _, entry in ipairs(category.entries) do
            local template = loadTemplate(entry.template)
            local listed = {
                label = entry.label or template.label or entry.template,
                template = entry.template,
                name = (entry.template:gsub("^stock_", "")),
                option = entry.option or "",
                vehicle_type = template.vehicle_type or "turret",
                details = templateDetails(entry.template, template, entry.option),
                stock = template.stock == true
            }
            for _, point in ipairs(template.physics and template.physics.mass_points or {}) do
                listed.stock_wheels = listed.stock_wheels or point.wheel == true
            end
            local options = template.options
            if options and not entry.option then
                local items = {}
                for i, item in ipairs(options.items) do
                    items[i] = {name = item.name, label = item.label or item.name,
                                details = templateDetails(entry.template, template, item.name)}
                end
                listed.options = {label = options.label or "Option",
                                  default = templateOption(template).name, items = items}
            end
            entries[#entries + 1] = listed
        end
        categories[#categories + 1] = {label = category.label, choice = category.choice or "Template",
                                       fit_wheels = category.fit_wheels == true, entries = entries}
    end
    local f = assert(io.open(outPath, "wb"))
    f:write(json.encode({categories = categories}))
    f:close()
end

-- For the dialog: the scene's wheels in axles (wheels per axle, front first) and the _index.json
-- entries that fit them: { axles = { 2, 2 }, matches = { { template, option } } } (option "" = none)
function generator.fit(wheelsText, outPath)
    if not outPath then
        error("usage: run.lua generators.physics fit <wheels> <out.json>", 0)
    end
    local axles = groupAxles(parseWheels(wheelsText))
    local counts, matches = {}, {}
    for i, axle in ipairs(axles) do
        counts[i] = #axle.wheels
    end
    local function check(templateName, template, option)
        local part = wheelsPart(template, option)
        if part and #axles > 0 and axlesFit(part, axles) then
            matches[#matches + 1] = {template = templateName, option = option and option.name or ""}
        end
    end
    for _, category in ipairs(json.decodeFile(templatesDir .. "/_index.json").categories) do
        for _, entry in ipairs(category.entries) do
            local template = loadTemplate(entry.template)
            if entry.option then
                check(entry.template, template, templateOption(template, entry.option))
            elseif template.options then
                for _, item in ipairs(template.options.items) do
                    check(entry.template, template, item)
                end
            else
                check(entry.template, template, nil)
            end
        end
    end
    local f = assert(io.open(outPath, "wb"))
    f:write(json.encode({axles = counts, matches = matches}))
    f:close()
end

return generator
