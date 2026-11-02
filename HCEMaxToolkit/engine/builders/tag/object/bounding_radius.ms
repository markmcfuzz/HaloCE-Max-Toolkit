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

-- Bounding radius of an object tag as an Influence helper ("warthog.vehicle.boundingRadius"):
-- Near = bounding radius, centered on the bounding offset (tag units x 100).

-- Text of a field of the tag's object struct ("unit.object.bounding radius"); undefined if missing
fn objectFieldText keys values fieldName =
(
	local text = undefined
	local pattern = "*object." + fieldName
	for i = 1 to keys.count while text == undefined do
	(
		local key = keys[i]
		if (matchPattern key pattern:pattern) and (findString key "[" == undefined) do text = values[i]
	)
	text
)

-- "0.1 0 0.25" -> [0.1, 0, 0.25]; [0, 0, 0] when it can't be read
fn tagTextToPoint3 text =
(
	local p = if text == undefined then #() else filterString text " "
	if p.count < 3 then return [0, 0, 0]
	local v = for i = 1 to 3 collect (p[i] as float)
	if findItem v undefined > 0 then [0, 0, 0] else [v[1], v[2], v[3]]
)

-- Sets the helper's Near and position from the fields. Returns true when something changed
fn setBoundingRadiusHelper h keys values =
(
	local radiusText = objectFieldText keys values "bounding radius"
	local radius = if radiusText != undefined then radiusText as float else undefined
	if radius == undefined do radius = 0.0
	local nearDist = radius * 100.0
	local pos = (tagTextToPoint3 (objectFieldText keys values "bounding offset")) * 100.0
	if abs (h.nearDist - nearDist) < 0.0001 and distance h.pos pos < 0.0001 then return false
	h.nearDist = nearDist
	h.pos = pos
	true
)

-- data: ObjectTagData (lua_reader.ms)
fn createBoundingRadiusHelper data tagPath =
(
	local h = InfluenceHelper name:((filenameFromPath tagPath) + ".boundingRadius")
	h.on = false
	h.showNear = true
	h.nearColor = color 255 0 0
	h.farDist = 0.0
	h.showFar = false
	h.farColor = color 255 140 0
	h.FalloffType = 2  -- Smoother
	h.invert = false
	h.EnableBias = true
	h.bias = 0.3
	h.BiasSelected = false
	setBoundingRadiusHelper h data.keys data.values
	h
)

-- Updates the Point's helper after an edit in the tag editor (also on undo / redo)
fn applyObjectBoundingRadius obj =
(
	if not (isObjectTagContainer obj) then return false
	local h = undefined
	for n in obj.memberNodes where isValidNode n and classOf n == InfluenceHelper and matchPattern n.name pattern:"*.boundingRadius" do h = n
	if h == undefined then return false
	local changed = with undo off (setBoundingRadiusHelper h obj.fieldKeys obj.fieldValues)
	if changed do redrawViews()
	changed
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
