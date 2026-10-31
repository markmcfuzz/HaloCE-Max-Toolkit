-- JMS model source files: read and write with the same rules as the previous MAXScript
-- reader (jms_reader.ms) and writer (process_file.ms). A value that is not a number is an
-- error with its line number.
local maxNumbers = require "formats.max_numbers"

local fixed6, floatText = maxNumbers.fixed6, maxNumbers.floatText

local jms = {}

-------------------------------------------------------------------------------
-- Text helpers (MAXScript rules)
-------------------------------------------------------------------------------

-- Lines trimmed like readLineFromStream; nil at the end of the file
local function lineReader(path)
    local file = assert(io.open(path, "rb"))
    local text = file:read("*a")
    file:close()
    local pos, lineNo = 1, 0
    local reader = {}
    function reader.peekLine()
        if pos > #text then
            return nil
        end
        local stop = text:find("\n", pos, true) or (#text + 1)
        return text:sub(pos, stop - 1):match("^%s*(.-)%s*$"), stop + 1
    end
    -- readLine fails at the end of the file
    function reader.line()
        local line, nextPos = reader.peekLine()
        if not line then
            error(("unexpected end of file after line %d"):format(lineNo), 0)
        end
        pos = nextPos
        lineNo = lineNo + 1
        return line
    end
    function reader.atEnd()
        return pos > #text
    end
    function reader.lineNo()
        return lineNo
    end
    return reader
end

-- "x" as integer (MAXScript "as integer"), or nil when it is not a number
local function asInt(text)
    local value = text and tonumber(text)
    if not value then
        return nil
    end
    return value >= 0 and math.floor(value) or math.ceil(value)
end

-- Integer of the current line; "undefined" counts as 0 (old toolkit files have it)
local function toInt(text, reader)
    if text and text:lower() == "undefined" then
        return 0
    end
    local value = asInt(text)
    if not value then
        error(("line %d: '%s' is not a number"):format(reader.lineNo(), tostring(text)), 0)
    end
    return value
end

local function toFloat(text, reader)
    local value = text and tonumber(text)
    if not value then
        error(("line %d: '%s' is not a number"):format(reader.lineNo(), tostring(text)), 0)
    end
    return value
end

local function split(text, separators)
    local parts = {}
    for token in text:gmatch("[^" .. separators .. "]+") do
        parts[#parts + 1] = token
    end
    return parts
end

-- Numbers that went into a Point3/quat: the old reader failed when one did not parse
local function floats(parts, first, count, reader)
    local values = {}
    for i = 0, count - 1 do
        local value = tonumber(parts[first + i])
        if not value then
            error(("line %d: '%s' is not a number"):format(reader.lineNo(),
                                                           tostring(parts[first + i])), 0)
        end
        values[i + 1] = value
    end
    return values
end

-- readVectorValue / readQuatValue: fewer values than needed give the default
local function vectorLine(reader, count, default)
    local parts = split(reader.line(), " \t")
    if #parts < count then
        return default
    end
    return floats(parts, 1, count, reader)
end

-------------------------------------------------------------------------------
-- Inline format (old exporters: one record per line, tab separated)
-------------------------------------------------------------------------------

local function readInline(reader, firstLine, data)
    local header = split(firstLine, " \t")
    data.version, data.checksum = toInt(header[1], reader), toInt(header[2], reader)
    data.nodeCount = toInt(header[3], reader)

    -- Records with too few fields are skipped, as before
    for _ = 1, data.nodeCount do
        local parts = split(reader.line(), "\t")
        if #parts >= 10 then
            data.nodes[#data.nodes + 1] = {
                name = parts[1],
                child = toInt(parts[2], reader),
                sibling = toInt(parts[3], reader),
                rot = floats(parts, 4, 4, reader),
                trans = floats(parts, 8, 3, reader)
            }
        end
    end

    data.shaderCount = toInt(reader.line(), reader)
    for _ = 1, data.shaderCount do
        local parts = split(reader.line(), "\t")
        if #parts >= 2 then
            data.shaders[#data.shaders + 1] = {name = parts[1], bitmap = parts[2]}
        end
    end

    data.markerCount = toInt(reader.line(), reader)
    for _ = 1, data.markerCount do
        local parts = split(reader.line(), "\t")
        if #parts >= 11 then
            data.markers[#data.markers + 1] = {
                name = parts[1],
                region = toInt(parts[2], reader),
                parent = toInt(parts[3], reader),
                rot = floats(parts, 4, 4, reader),
                trans = floats(parts, 8, 3, reader),
                radius = toFloat(parts[11], reader)
            }
        end
    end

    data.regionCount = toInt(reader.line(), reader)
    for _ = 1, data.regionCount do
        local name = reader.line()
        while name == "" do
            name = reader.line()
        end
        data.regions[#data.regions + 1] = name
    end

    data.vertexCount = toInt(reader.line(), reader)
    for i = 1, data.vertexCount do
        local parts = split(reader.line(), "\t")
        if i == 1 and #parts > 50 then
            error(
                "ultra-inline JMS (all vertices on one line) is not supported; convert it with the JMS Formatter first",
                0)
        end
        if #parts >= 12 then
            local uv = floats(parts, 10, 2, reader)
            data.vertices[#data.vertices + 1] = {
                node0 = toInt(parts[1], reader),
                pos = floats(parts, 2, 3, reader),
                normal = floats(parts, 5, 3, reader),
                node1 = toInt(parts[8], reader),
                weight = toFloat(parts[9], reader),
                u = uv[1],
                v = uv[2],
                tex = toInt(parts[12], reader)
            }
        end
    end

    data.triangleCount = toInt(reader.line(), reader)
    for _ = 1, data.triangleCount do
        local parts = split(reader.line(), "\t")
        if #parts >= 5 then
            data.triangles[#data.triangles + 1] = {
                region = toInt(parts[1], reader),
                shader = toInt(parts[2], reader),
                a = toInt(parts[3], reader),
                b = toInt(parts[4], reader),
                c = toInt(parts[5], reader)
            }
        end
    end
end

-------------------------------------------------------------------------------
-- Standard format (toolkit, Blender, invader-recover, fbx-to-jms: one value per line)
-------------------------------------------------------------------------------

-- UV line layouts: "u v index" (invader-recover), "u v" + index line (Blender/fbx),
-- or u, v and index on three lines (toolkit). An empty line gives 0, 0, 0.
local function readUv(reader)
    local parts = split(reader.line(), " \t")
    if #parts >= 3 then
        return toFloat(parts[1], reader), toFloat(parts[2], reader), toInt(parts[3], reader)
    elseif #parts == 2 then
        local u, v = toFloat(parts[1], reader), toFloat(parts[2], reader)
        return u, v, toInt(reader.line(), reader)
    elseif #parts == 1 then
        local u = toFloat(parts[1], reader)
        local v = toFloat(reader.line(), reader)
        return u, v, toInt(reader.line(), reader)
    end
    return 0, 0, 0
end

-- ";### SMOOTHING GROUPS ###" section after the triangles (optional). The old reader stopped
-- quietly at the end of the file; lines that are not numbers count as 0.
local function readSmoothingGroups(reader, data)
    if reader.atEnd() then
        return
    end
    local line = reader.line()
    while line == "" do
        if reader.atEnd() then
            return
        end
        line = reader.line()
    end
    if line ~= ";### SMOOTHING GROUPS ###" or reader.atEnd() then
        return
    end
    local count = asInt(reader.line()) or 0
    for _ = 1, count do
        if reader.atEnd() then
            return
        end
        data.smoothingGroups[#data.smoothingGroups + 1] = asInt(reader.line()) or 0
    end
end

local function readStandard(reader, data)
    data.version = toInt(reader.line(), reader)
    data.checksum = toInt(reader.line(), reader)

    data.nodeCount = toInt(reader.line(), reader)
    for _ = 1, data.nodeCount do
        local name = reader.line()
        local child = toInt(reader.line(), reader)
        local sibling = toInt(reader.line(), reader)
        local rot = vectorLine(reader, 4, {0, 0, 0, 1})
        local trans = vectorLine(reader, 3, {0, 0, 0})
        data.nodes[#data.nodes + 1] = {
            name = name,
            child = child,
            sibling = sibling,
            rot = rot,
            trans = trans
        }
    end

    data.shaderCount = toInt(reader.line(), reader)
    for _ = 1, data.shaderCount do
        local name = reader.line()
        data.shaders[#data.shaders + 1] = {name = name, bitmap = reader.line()}
    end

    data.markerCount = toInt(reader.line(), reader)
    for _ = 1, data.markerCount do
        local name = reader.line()
        local region = toInt(reader.line(), reader)
        local parent = toInt(reader.line(), reader)
        local rot = vectorLine(reader, 4, {0, 0, 0, 1})
        local trans = vectorLine(reader, 3, {0, 0, 0})
        data.markers[#data.markers + 1] = {
            name = name,
            region = region,
            parent = parent,
            rot = rot,
            trans = trans,
            radius = toFloat(reader.line(), reader)
        }
    end

    -- Blank lines are skipped before each region name and before the vertex count
    data.regionCount = toInt(reader.line(), reader)
    for _ = 1, data.regionCount do
        local name = reader.line()
        while name == "" do
            name = reader.line()
        end
        data.regions[#data.regions + 1] = name
    end

    local countLine = reader.line()
    while countLine == "" do
        countLine = reader.line()
    end
    data.vertexCount = toInt(countLine, reader)
    for _ = 1, data.vertexCount do
        local vertex = {}
        vertex.node0 = toInt(reader.line(), reader)
        vertex.pos = vectorLine(reader, 3, {0, 0, 0})
        vertex.normal = vectorLine(reader, 3, {0, 0, 0})
        vertex.node1 = toInt(reader.line(), reader)
        vertex.weight = toFloat(reader.line(), reader)
        vertex.u, vertex.v, vertex.tex = readUv(reader)
        data.vertices[#data.vertices + 1] = vertex
    end

    data.triangleCount = toInt(reader.line(), reader)
    for _ = 1, data.triangleCount do
        local region = toInt(reader.line(), reader)
        local shader = toInt(reader.line(), reader)
        local parts = split(reader.line(), " \t")
        local triangle = {region = region, shader = shader, a = 0, b = 0, c = 0}
        if #parts >= 3 then
            triangle.a, triangle.b, triangle.c = toInt(parts[1], reader), toInt(parts[2], reader),
                                                 toInt(parts[3], reader)
        end
        data.triangles[#data.triangles + 1] = triangle
    end

    readSmoothingGroups(reader, data)
end

-- Returns the JMS data; inline = true for the old one-record-per-line format
-- (its rotations were not normalized; standard ones were, in Max).
function jms.read(path)
    local reader = lineReader(path)
    local data = {
        nodes = {},
        shaders = {},
        markers = {},
        regions = {},
        vertices = {},
        triangles = {},
        smoothingGroups = {}
    }
    local firstLine = reader.line()
    data.inline = #split(firstLine, " \t") >= 3
    if data.inline then
        readInline(reader, firstLine, data)
    else
        -- Read again from the first line
        reader = lineReader(path)
        readStandard(reader, data)
    end
    return data
end

-------------------------------------------------------------------------------
-- Writing (same text as writeJmsFile)
-------------------------------------------------------------------------------

local function fixedList(values)
    local out = {}
    for i, value in ipairs(values) do
        out[i] = fixed6(value)
    end
    return table.concat(out, "\t")
end

-- data uses the read layout; smoothing groups are written only when writeSmoothing is set.
-- The weight is printed like MAXScript format "%", other floats with 6 decimals.
function jms.write(path, data)
    local lines = {}
    local function add(text)
        lines[#lines + 1] = text
    end
    add(tostring(data.version))
    add(tostring(data.checksum))
    add(tostring(data.nodeCount))
    for _, n in ipairs(data.nodes) do
        add(n.name)
        add(tostring(n.child))
        add(tostring(n.sibling))
        add(fixedList(n.rot))
        add(fixedList(n.trans))
    end
    add(tostring(data.shaderCount))
    for _, s in ipairs(data.shaders) do
        add(s.name)
        add(s.bitmap)
    end
    add(tostring(data.markerCount))
    for _, m in ipairs(data.markers) do
        add(m.name)
        add(tostring(m.region))
        add(tostring(m.parent))
        add(fixedList(m.rot))
        add(fixedList(m.trans))
        add(fixed6(m.radius))
    end
    add(tostring(data.regionCount))
    for _, name in ipairs(data.regions) do
        add(name)
    end
    add(tostring(data.vertexCount))
    for _, vertex in ipairs(data.vertices) do
        add(tostring(vertex.node0))
        add(fixedList(vertex.pos))
        add(fixedList(vertex.normal))
        add(tostring(vertex.node1))
        add(floatText(vertex.weight))
        add(fixed6(vertex.u))
        add(fixed6(vertex.v))
        add(tostring(vertex.tex))
    end
    add(tostring(data.triangleCount))
    for _, t in ipairs(data.triangles) do
        add(tostring(t.region))
        add(tostring(t.shader))
        add(tostring(t.a) .. "\t" .. tostring(t.b) .. "\t" .. tostring(t.c))
    end
    if data.writeSmoothing then
        add("")
        add(";### SMOOTHING GROUPS ###")
        add(tostring(#data.smoothingGroups))
        for _, sg in ipairs(data.smoothingGroups) do
            add(tostring(sg))
        end
    end

    local file = io.open(path, "wb")
    if not file then
        return false
    end
    file:write(table.concat(lines, "\r\n"), "\r\n")
    file:close()
    return true
end

return jms
