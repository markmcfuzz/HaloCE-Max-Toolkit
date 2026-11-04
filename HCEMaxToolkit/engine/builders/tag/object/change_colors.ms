------------------------------------------------------------------------------
--	Copyright (C) 2026 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------

-- Shows an object's change colors on its GlyphFX materials: shader_transparent_generic gets all
-- four (ChangeColorA-D), shader_model the one its source points to (see materialChangeColorSlots).

-- "0.34 0.40 0.14" (0-1) -> Max color; white when it can't be read
fn tagTextToColor text =
(
	local p = filterString text " "
	if p.count < 3 then return white
	local c = for i = 1 to 3 collect (p[i] as float)
	if findItem c undefined > 0 then return white
	color ((amax 0 (amin 1 c[1])) * 255) ((amax 0 (amin 1 c[2])) * 255) ((amax 0 (amin 1 c[3])) * 255)
)

-- Element count of a block key; 0 when missing
fn fieldCount fields key =
(
	local n = if hasDictValue fields key then fields[key] as integer else undefined
	if n == undefined then 0 else n
)

-- Color of change color index (0 = A): the first permutation's lower bound when it has
-- permutations, else its own lower bound
fn objectChangeColor fields blockKey index =
(
	local prefix = blockKey + "[" + (index as string) + "]."
	local colorKey = prefix + "color lower bound"
	if (fieldCount fields (prefix + "permutations")) > 0 do
		colorKey = prefix + "permutations[0].color lower bound"
	if hasDictValue fields colorKey then tagTextToColor fields[colorKey] else white
)

-- Change color parameters of a GlyphFX material: #(#(parameter, source 1=A .. 4=D, 0 none), ...).
-- Empty for materials without change color
fn materialChangeColorSlots m =
(
	if isProperty m #ChangeColorA then
		return #(#(#ChangeColorA, 1), #(#ChangeColorB, 2), #(#ChangeColorC, 3), #(#ChangeColorD, 4))
	if isProperty m #ChangeColor and isProperty m #ChangeColorSource then
		return #(#(#ChangeColor, m.ChangeColorSource))
	#()
)

-- A material and every material inside it (Multi/Sub-Object)
fn collectSubMaterials mat out =
(
	if mat != undefined and appendIfUnique out mat do
		for i = 1 to getNumSubMtls mat do collectSubMaterials (getSubMtl mat i) out
	out
)

-- Updates the materials of the Point's imported nodes; none (0) or a missing change color is
-- white. Returns how many materials changed
fn applyObjectChangeColors obj =
(
	if not (isObjectTagContainer obj) then return 0
	local fields = Dictionary #string
	local keys = obj.fieldKeys
	local values = obj.fieldValues
	for i = 1 to keys.count do fields[keys[i]] = values[i]

	-- The object's block ("unit.object.change colors"), not one inside another block
	local blockKey = undefined
	for k in fields.keys where blockKey == undefined and matchPattern k pattern:"*change colors" and findString k "[" == undefined do
		blockKey = k
	local count = if blockKey == undefined then 0 else fieldCount fields blockKey
	-- A to D; white when the object has fewer
	local colors = #()
	for i = 1 to 4 do append colors (if i <= count then objectChangeColor fields blockKey (i - 1) else white)

	local nodes = for n in obj.memberNodes where isValidNode n and n.material != undefined collect n
	local materials = #()
	for n in nodes do collectSubMaterials n.material materials
	local changed = 0
	with undo off
	(
		for m in materials do
		(
			local matChanged = false
			for slot in materialChangeColorSlots m do
			(
				local source = slot[2]
				local c = if source >= 1 and source <= 4 then colors[source] else white
				-- Only when it changed: refreshing the viewport on every selection would be slow
				if ((getProperty m slot[1]) as string) != (c as string) do
				(
					setProperty m slot[1] c
					matChanged = true
				)
			)
			if matChanged do
			(
				notifyDependents m
				changed += 1
			)
		)
		-- The viewport keeps the old DirectX material until it is assigned again
		if changed > 0 do
		(
			for n in nodes do n.material = n.material
			redrawViews()
		)
	)
	changed
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
