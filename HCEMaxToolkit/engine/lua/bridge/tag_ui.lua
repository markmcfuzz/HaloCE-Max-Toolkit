-- Writes the 3ds Max panel of an object tag: a scripted custom attribute made from the tag
-- definitions. Values live in its fieldKeys/fieldValues (keys as in importers\shared\tag_fields.lua).
local tagDefs = require "tags.tag_defs"

local readAs = tagDefs.readAs

local tagUi = {}

local defs -- definitions of the tag being written

-- MAXScript string literal
local function quote(text)
    text = text:gsub("\\", "\\\\"):gsub("\"", "\\\"")
    return "\"" .. text .. "\""
end

local function add(list, line)
    list[#list + 1] = line
end

-- "seats" -> "Seats", "device_machine" -> "Device Machine"
local function capitalize(text)
    text = text:gsub("_(%l)", function(c)
        return " " .. c:upper()
    end)
    return (text:gsub("^%l", string.upper))
end

-- "has e-brake*#NOT YET BACKPORTED from H2" -> "has e-brake" ("region #00 damage" stays)
local function optionName(name)
    name = name:gsub("#%a.*$", ""):gsub("[%*%^!]", "")
    return (name:match("^%s*(.-)%s*$"))
end

local function optionsList(options)
    local quoted = {}
    for i, name in ipairs(options) do
        quoted[i] = quote(optionName(name))
    end
    return "#(" .. table.concat(quoted, ", ") .. ")"
end

-- Enum or flags option names of a field, or nil when the definition has none
local function fieldOptions(field)
    local ok, entry = pcall(defs.lookup, defs, field.owner, "enums_flags", field.definition)
    if ok and entry.options then
        return entry.options
    end
end

-- Key expression: a literal, or elementKey with the selected element of each block
local function keyExpr(pattern, indexVars)
    if #indexVars == 0 then
        return quote(pattern)
    end
    return ("(elementKey %s #(%s))"):format(quote(pattern), table.concat(indexVars, ", "))
end

-------------------------------------------------------------------------------
-- Controls
-------------------------------------------------------------------------------

local intRanges = {
    [readAs.int8] = "[-128,127,0]",
    [readAs.uint8] = "[0,255,0]",
    [readAs.int16] = "[-32768,32767,0]",
    [readAs.uint16] = "[0,65535,0]",
    [readAs.int32] = "[-1e9,1e9,0]"
}

local partCounts = {
    [readAs.float2] = 2,
    [readAs.float3] = 3,
    [readAs.float4] = 4,
    [readAs.int16x2] = 2,
    [readAs.int16x4] = 4
}

-- What control a field gets: kind and, for several numbers, how many
local function fieldKind(field)
    local t, r = field.type, field.readAs
    if t:find("_enum$") and fieldOptions(field) then
        return "enum"
    elseif t:find("_flags$") and fieldOptions(field) then
        return "flags"
    elseif t == "angle" then
        return "angle"
    elseif t == "angle_bounds" or t:find("^real_euler_angles") then
        return "angles", partCounts[r]
    elseif r == readAs.float then
        return "float"
    elseif r == readAs.float2 or r == readAs.float3 or r == readAs.float4 then
        return "floats", partCounts[r]
    elseif r == readAs.int16x2 or r == readAs.int16x4 then
        return "ints", partCounts[r]
    elseif intRanges[r] then
        return "int"
    elseif r == readAs.tagRef then
        return "ref"
    elseif r == readAs.string then
        return "string"
    end
    return "text"
end

local function newName(r, prefix)
    r.count = r.count + 1
    return prefix .. r.count
end

-- Short names go left of the control; long ones on a label above it
local function caption(r, name)
    add(r.controls, ("label %s %s align:#left"):format(newName(r, "l"), quote(name)))
end

-- Adds a field's controls, how to show its value (refresh) and how to store edits (handlers)
local function emitField(r, field, key, enable, refresh)
    local kind, parts = fieldKind(field)
    local name = field.name
    local inline = #name <= 16

    if kind == "float" or kind == "angle" then
        local c = newName(r, "c")
        if inline then
            add(r.controls, ("edittext %s %s fieldWidth:70 align:#right"):format(c, quote(name)))
        else
            caption(r, name)
            add(r.controls, ("edittext %s \"\" fieldWidth:140 align:#right"):format(c))
        end
        if kind == "angle" then
            add(refresh, ("%s.text = angleText (fieldText %s)"):format(c, key))
            add(r.handlers, ("on %s entered t do %s.text = setFieldAngle %s t"):format(c, c, key))
        else
            add(refresh, ("%s.text = fieldText %s"):format(c, key))
            add(r.handlers, ("on %s entered t do %s.text = setFieldFloat %s t"):format(c, c, key))
        end
        add(enable, c)
    elseif kind == "floats" or kind == "angles" then
        caption(r, name)
        local width = math.floor(144 / parts) - 8
        for i = 1, parts do
            local c = newName(r, "c")
            local across = i == 1 and (" across:" .. parts) or ""
            add(r.controls, ("edittext %s \"\" fieldWidth:%d%s"):format(c, width, across))
            if kind == "angles" then
                add(refresh, ("%s.text = angleText (fieldPart %s %d)"):format(c, key, i))
                add(r.handlers,
                    ("on %s entered t do %s.text = setFieldAnglePart %s %d %d t"):format(c, c, key,
                                                                                         i, parts))
            else
                add(refresh, ("%s.text = fieldPart %s %d"):format(c, key, i))
                add(r.handlers,
                    ("on %s entered t do %s.text = setFieldFloatPart %s %d %d t"):format(c, c, key,
                                                                                         i, parts))
            end
            add(enable, c)
        end
    elseif kind == "int" then
        local c = newName(r, "c")
        local range = intRanges[field.readAs]
        if inline then
            add(r.controls,
                ("spinner %s %s type:#integer range:%s fieldWidth:60 align:#right"):format(c,
                                                                                           quote(
                                                                                               name),
                                                                                           range))
        else
            caption(r, name)
            add(r.controls,
                ("spinner %s \"\" type:#integer range:%s fieldWidth:60 align:#right"):format(c,
                                                                                             range))
        end
        add(refresh, ("%s.value = fieldInt %s"):format(c, key))
        add(r.handlers, ("on %s changed v do setFieldText %s (v as string)"):format(c, key))
        add(enable, c)
    elseif kind == "ints" then
        caption(r, name)
        local width = math.floor(144 / parts) - 16
        for i = 1, parts do
            local c = newName(r, "c")
            local across = i == 1 and (" across:" .. parts) or ""
            add(r.controls,
                ("spinner %s \"\" type:#integer range:[-32768,32767,0] fieldWidth:%d%s"):format(c,
                                                                                                width,
                                                                                                across))
            add(refresh, ("%s.value = fieldIntPart %s %d"):format(c, key, i))
            add(r.handlers,
                ("on %s changed v do setFieldPart %s %d %d (v as string)"):format(c, key, i, parts))
            add(enable, c)
        end
    elseif kind == "enum" then
        local c = newName(r, "c")
        local options = fieldOptions(field)
        add(r.controls, ("dropdownList %s %s items:%s"):format(c, quote(name), optionsList(options)))
        add(refresh, ("%s.selection = enumSelection (fieldInt %s) %d"):format(c, key, #options))
        add(r.handlers, ("on %s selected i do setFieldText %s ((i - 1) as string)"):format(c, key))
        add(enable, c)
    elseif kind == "flags" then
        -- One checkbox per bit; bits without a name keep their value
        caption(r, name)
        for i, option in ipairs(fieldOptions(field)) do
            local c = newName(r, "c")
            add(r.controls, ("checkbox %s %s offset:[8,0]"):format(c, quote(optionName(option))))
            add(refresh, ("%s.checked = bit.get (fieldInt %s) %d"):format(c, key, i))
            add(r.handlers,
                ("on %s changed v do setFieldText %s ((bit.set (fieldInt %s) %d v) as string)"):format(
                    c, key, key, i))
            add(enable, c)
        end
    elseif kind == "ref" then
        -- Path without extension; the group is kept in the value and checked on export
        local c = newName(r, "c")
        local allowed = {}
        for _, fourcc in ipairs(field.definition and field.definition.allowed or {}) do
            allowed[#allowed + 1] = defs.byFourcc[fourcc] or fourcc
        end
        local tooltip = quote("Allowed: " .. table.concat(allowed, ", "))
        add(r.controls,
            ("edittext %s %s labelOnTop:true tooltip:%s"):format(c, quote(name), tooltip))
        add(refresh, ("%s.text = refPath (fieldText %s)"):format(c, key))
        add(r.handlers, ("on %s entered t do %s.text = setFieldRef %s t"):format(c, c, key))
        add(enable, c)
    else
        -- Strings and the rest as typed
        local c = newName(r, "c")
        local maxLength = kind == "string" and 31 or 255
        add(r.controls, ("edittext %s %s labelOnTop:true"):format(c, quote(name)))
        add(refresh, ("%s.text = fieldText %s"):format(c, key))
        add(r.handlers,
            ("on %s entered t do %s.text = setFieldString %s t %d"):format(c, c, key, maxLength))
        add(enable, c)
    end
end

-------------------------------------------------------------------------------
-- Structs and blocks
-------------------------------------------------------------------------------

local emitBlock -- emitStruct and emitBlock call each other

-- Fields of one element; structs inside it are shown inline, blocks get their own picker
local function emitStruct(r, structDef, pattern, indexVars, enable, refresh, inGroup)
    for _, field in ipairs(structDef.fields) do
        if field.readAs == readAs.struct then
            emitStruct(r, field.sub, pattern .. field.key .. ".", indexVars, enable, refresh,
                       inGroup)
        elseif field.readAs == readAs.block or field.readAs == readAs.array then
            emitBlock(r, field, pattern .. field.key, indexVars, refresh, inGroup)
        else
            emitField(r, field, keyExpr(pattern .. field.key, indexVars), enable, refresh)
        end
    end
end

-- First text or tag reference of an element, shown next to its number in the picker
local function labelField(structDef)
    for _, field in ipairs(structDef.fields) do
        if field.readAs == readAs.string or field.readAs == readAs.tagRef then
            return field
        end
    end
end

-- A block: element picker, the selected element's fields and a refreshBlock function.
-- The rollout's own block has no group; nested blocks get one (deeper ones only a label).
emitBlock = function(r, field, countPattern, parentVars, parentRefresh, inGroup)
    r.blocks = r.blocks + 1
    local n = r.blocks
    local idx, picker, refreshName = "idx" .. n, "p" .. n, "refreshBlock" .. n
    add(r.locals, ("local %s = 0"):format(idx))

    local nested = #parentVars > 0
    local useGroup = nested and not inGroup
    if useGroup then
        add(r.controls, ("group %s"):format(quote(field.name)))
        add(r.controls, "(")
    elseif nested then
        caption(r, field.name)
    end
    add(r.controls, ("dropdownList %s \"\" items:#()"):format(picker))

    local vars = {}
    for i, v in ipairs(parentVars) do
        vars[i] = v
    end
    vars[#vars + 1] = idx
    local sub = field.readAs == readAs.block and defs:blockStruct(field) or field.sub
    local enable, refresh = {}, {}
    emitStruct(r, sub, countPattern .. "[#].", vars, enable, refresh, inGroup or useGroup)
    if useGroup then
        add(r.controls, ")")
    end

    -- Picker items: "0", or "0: W-driver" when the element has a name or tag reference
    local itemExpr = "(i as string)"
    local named = labelField(sub)
    if named then
        local labelVars = {}
        for i, v in ipairs(parentVars) do
            labelVars[i] = v
        end
        labelVars[#labelVars + 1] = "i"
        local text =
            ("fieldText %s"):format(keyExpr(countPattern .. "[#]." .. named.key, labelVars))
        if named.readAs == readAs.tagRef then
            text = ("filenameFromPath (refPath (%s))"):format(text)
        end
        itemExpr = ("(i as string) + \": \" + (%s)"):format(text)
    end

    local body = {}
    add(body, ("local count = fieldInt %s"):format(keyExpr(countPattern, parentVars)))
    add(body, ("if %s >= count do %s = 0"):format(idx, idx))
    add(body, ("%s.items = for i = 0 to count - 1 collect %s"):format(picker, itemExpr))
    add(body, ("%s.selection = if count > 0 then %s + 1 else 0"):format(picker, idx))
    add(body, "local hasItems = count > 0")
    for _, c in ipairs(enable) do
        add(body, ("%s.enabled = hasItems"):format(c))
    end
    for _, line in ipairs(refresh) do
        add(body, line)
    end
    add(r.functions,
        ("fn %s =\n\t\t(\n\t\t\t%s\n\t\t)"):format(refreshName, table.concat(body, "\n\t\t\t")))
    add(r.handlers, ("on %s selected i do (%s = i - 1; %s())"):format(picker, idx, refreshName))

    -- A new parent element starts at its first child element
    add(parentRefresh, ("%s = 0"):format(idx))
    add(parentRefresh, refreshName .. "()")
end

-------------------------------------------------------------------------------
-- Rollouts
-------------------------------------------------------------------------------

local function newRollout(title, rolledUp)
    return {
        title = title,
        rolledUp = rolledUp,
        locals = {},
        controls = {},
        functions = {},
        handlers = {},
        refresh = {},
        count = 0,
        blocks = 0
    }
end

-- Sections in panel order (object, unit, vehicle): the deepest struct first
local function collectSections(structDef, prefix, title, sections)
    for _, field in ipairs(structDef.fields) do
        if field.readAs == readAs.struct then
            collectSections(field.sub, prefix .. field.key .. ".", field.key, sections)
        end
    end
    sections[#sections + 1] = {structDef = structDef, prefix = prefix, title = capitalize(title)}
end

-- One rollout with the section's own fields, then one per block of the section
local function sectionRollouts(section, isRoot, rollouts)
    local main = newRollout(section.title, not isRoot)
    local blockRollouts = {}
    for _, field in ipairs(section.structDef.fields) do
        if field.readAs == readAs.block or field.readAs == readAs.array then
            local r = newRollout(section.title .. ": " .. capitalize(field.name), true)
            emitBlock(r, field, section.prefix .. field.key, {}, r.refresh, false)
            blockRollouts[#blockRollouts + 1] = r
        elseif field.readAs ~= readAs.struct then
            emitField(main, field, quote(section.prefix .. field.key), {}, main.refresh)
        end
    end
    if #main.controls > 0 then
        rollouts[#rollouts + 1] = main
    end
    for _, r in ipairs(blockRollouts) do
        rollouts[#rollouts + 1] = r
    end
end

local function rolloutText(r, name)
    local lines = {}
    local rolledUp = r.rolledUp and " rolledUp:true" or ""
    add(lines, ("\trollout %s %s%s"):format(name, quote(r.title), rolledUp))
    add(lines, "\t(")
    for _, list in ipairs({r.locals, r.controls, r.functions}) do
        for _, line in ipairs(list) do
            add(lines, "\t\t" .. line)
        end
    end
    add(lines,
        ("\t\tfn refreshAll =\n\t\t(\n\t\t\t%s\n\t\t)"):format(table.concat(r.refresh, "\n\t\t\t")))
    for _, line in ipairs(r.handlers) do
        add(lines, "\t\t" .. line)
    end
    add(lines, ("\t\ton %s open do refreshAll()"):format(name))
    add(lines, "\t)")
    return table.concat(lines, "\n")
end

-- Same id for the same group every time, so a new panel replaces the old one in saved scenes
local function attribId(text, seed)
    local h = seed
    for i = 1, #text do
        h = (h * 31 + text:byte(i)) % 2147483647
    end
    return ("0x%08X"):format(h)
end

-- Functions the controls use to read and write fieldKeys/fieldValues
local commonFunctions = [[
	local keyCache

	-- Position of a field in fieldKeys (0 = missing)
	fn fieldIndex key =
	(
		if keyCache == undefined or keyCache.count != fieldKeys.count do
			keyCache = for k in fieldKeys collect k
		findItem keyCache key
	)

	fn fieldText key =
	(
		local i = fieldIndex key
		if i == 0 then "" else fieldValues[i]
	)

	fn setFieldText key text =
	(
		local i = fieldIndex key
		if i > 0 do fieldValues[i] = text
		text
	)

	fn fieldInt key =
	(
		local v = (fieldText key) as integer
		if v == undefined then 0 else v
	)

	-- "unit.seats[#].yaw rate" + #(2) -> "unit.seats[2].yaw rate"
	fn elementKey pattern indices =
	(
		local parts = filterString pattern "#" splitEmptyTokens:true
		local key = parts[1]
		for i = 2 to parts.count do key += (indices[i - 1] as string) + parts[i]
		key
	)

	-- Part n of a value made of several numbers ("x y z")
	fn fieldPart key n =
	(
		local parts = filterString (fieldText key) " "
		if n <= parts.count then parts[n] else "0"
	)

	fn fieldIntPart key n =
	(
		local v = (fieldPart key n) as integer
		if v == undefined then 0 else v
	)

	fn setFieldPart key n count text =
	(
		local parts = filterString (fieldText key) " "
		while parts.count < count do append parts "0"
		parts[n] = text
		local joined = parts[1]
		for i = 2 to parts.count do joined += " " + parts[i]
		setFieldText key joined
		text
	)

	-- Numbers are stored as typed; an invalid one shows the stored value again
	fn setFieldFloat key text =
	(
		text = trimLeft (trimRight text)
		if (text as float) != undefined then setFieldText key text else fieldText key
	)

	fn setFieldFloatPart key n count text =
	(
		text = trimLeft (trimRight text)
		if (text as float) != undefined then setFieldPart key n count text else fieldPart key n
	)

	-- Angles are stored in radians and shown in degrees
	fn angleText radiansText =
	(
		local r = radiansText as float
		if r == undefined then "0" else formattedPrint (radToDeg r) format:".6g"
	)

	fn radiansText degreesText = formattedPrint (degToRad (degreesText as float)) format:".9g"

	fn setFieldAngle key text =
	(
		text = trimLeft (trimRight text)
		if (text as float) != undefined do setFieldText key (radiansText text)
		angleText (fieldText key)
	)

	fn setFieldAnglePart key n count text =
	(
		text = trimLeft (trimRight text)
		if (text as float) != undefined do setFieldPart key n count (radiansText text)
		angleText (fieldPart key n)
	)

	fn setFieldString key text maxLength =
	(
		text = trimLeft (trimRight text)
		if text.count > maxLength do text = substring text 1 maxLength
		setFieldText key text
	)

	-- Tag references are stored as "group:path" (e.g. "ligh:vehicles\warthog\headlights")
	fn refPath value =
	(
		local i = findString value ":"
		if i == undefined then value else substring value (i + 1) -1
	)

	-- Keeps the group; export picks the right one if the new path is another tag type
	fn setFieldRef key text =
	(
		local value = fieldText key
		local i = findString value ":"
		local group = if i == undefined then "" else substring value 1 (i - 1)
		setFieldText key (group + ":" + (trimLeft (trimRight text)))
		refPath (fieldText key)
	)

	-- Enum value -> dropdown selection (0 = value outside the list)
	fn enumSelection value count = if value >= 0 and value < count then value + 1 else 0

	rollout tagRollout "Halo Tag"
	(
		edittext tagFileBox "Tag file" labelOnTop:true readOnly:true
		button selectButton "Select Contents" width:140
		on tagRollout open do tagFileBox.text = tagFile
		on selectButton pressed do select (for n in memberNodes where isValidNode n collect n)
	)
]]

-- Writes a MAXScript file that sets haloTagAttributeDef to the panel of this tag group
function tagUi.writeScript(tagDefinitions, groupName, rootStruct, path)
    defs = tagDefinitions
    local sections = {}
    collectSections(rootStruct, "", groupName, sections)
    local rollouts = {}
    for i, section in ipairs(sections) do
        sectionRollouts(section, i == #sections, rollouts)
    end

    local lines = {}
    add(lines, "-- Made by lua\\bridge\\tag_ui.lua for " .. groupName .. " tags (import_object.ms)")
    local name = "Halo " .. capitalize(groupName) .. " Tag"
    add(lines,
        ("haloTagAttributeDef = attributes %s attribID:#(%s, %s)"):format(quote(name),
                                                                          attribId(name, 7),
                                                                          attribId(name, 13)))
    add(lines, "(")
    add(lines, "\tparameters tagParams")
    add(lines, "\t(")
    add(lines, ("\t\ttagGroup type:#string default:%s"):format(quote(groupName)))
    add(lines, "\t\ttagFile type:#string default:\"\"")
    add(lines, "\t\tfieldKeys type:#stringTab tabSizeVariable:true")
    add(lines, "\t\tfieldValues type:#stringTab tabSizeVariable:true")
    add(lines, "\t\tmemberNodes type:#nodeTab tabSizeVariable:true")
    add(lines, "\t)")
    add(lines, commonFunctions)
    for i, r in ipairs(rollouts) do
        add(lines, rolloutText(r, "r" .. i))
    end
    add(lines, ")")

    local f = assert(io.open(path, "w"))
    f:write(table.concat(lines, "\n"), "\n")
    f:close()
    defs = nil
end

return tagUi
