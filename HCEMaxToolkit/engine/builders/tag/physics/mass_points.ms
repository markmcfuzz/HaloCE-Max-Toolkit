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

-- Mass point spheres of a physics tag Point, in its physicsNodes in tag order; each one is a child
-- of its "model node" (the Point's modelNodes) or of the Point. Fields <-> spheres both ways.

-- baseLayerName, inLayerKind, placePhysicsPoint
fileIn (rootEngine + "builders\\tag\\object\\object_hierarchy.ms")

-- True for the Point of an imported physics tag
fn isPhysicsTagContainer obj = isValidNode obj and (try (obj.tagGroup == "physics") catch (false))

-- "0.1 0 0.25" -> [0.1, 0, 0.25]; fallback when it can't be read
fn massPointTextToPoint3 text fallback =
(
	local p = filterString text " "
	if p.count < 3 then return fallback
	local x = p[1] as float
	local y = p[2] as float
	local z = p[3] as float
	if x == undefined or y == undefined or z == undefined then fallback else [x, y, z]
)

fn massPointFloatText v =
(
	if abs v < 0.0000001 then "0" else formattedPrint v format:".6g"
)

fn massPointPoint3Text p = (massPointFloatText p.x) + " " + (massPointFloatText p.y) + " " + (massPointFloatText p.z)

-- Wire color by friction type: point, forward, left, up
fn massPointColor frictionType = case frictionType of
(
	0: (color 255 36 16)
	1: (color 0 236 176)
	2: (color 255 33 67)
	3: (color 30 230 0)
	default: (color 255 255 0)
)

-- Field key -> its index in the Point's fieldKeys / fieldValues
fn physicsFieldIndices obj =
(
	local indices = Dictionary #string
	local keys = obj.fieldKeys
	for i = 1 to keys.count do indices[keys[i]] = i
	indices
)

-- Text of a field, "" when missing
fn physicsFieldText obj indices key =
(
	local i = indices[key]
	if i == undefined then "" else obj.fieldValues[i]
)

fn setPhysicsFieldText obj indices key text =
(
	local i = indices[key]
	if i != undefined do obj.fieldValues[i] = text
)

-- index: 1-based mass point
fn massPointKey index fieldName = "mass points[" + ((index - 1) as string) + "]." + fieldName

-- Rows forward, left, up; zero or parallel vectors (a new element) give the world axes
fn massPointMatrix forward up pos =
(
	if length forward < 0.0001 or length up < 0.0001 or length (cross up forward) < 0.0001 do
	(
		forward = [1, 0, 0]
		up = [0, 0, 1]
	)
	forward = normalize forward
	local left = normalize (cross up forward)
	matrix3 forward left (cross forward left) pos
)

-------------------------------------------------------
-- Model nodes: the tag positions are in the model's default pose, so each node's transform at
-- import is kept ("rest") and spheres are placed against it, whatever frame the scene shows
-------------------------------------------------------

fn sortByHandle a b = a.inode.handle - b.inode.handle

-- Nodes of the last imported model, in tag order (the gbxmodel importer makes them in that order)
fn sceneModelNodes =
(
	local nodes = for o in objects where inLayerKind o "Nodes" collect o
	qsort nodes sortByHandle
	nodes
)

-- Stores every model node's current transform as its rest pose (user props of the Point)
fn storePhysicsNodeRests obj =
(
	local nodes = obj.modelNodes
	for i = 1 to nodes.count where isValidNode nodes[i] do
	(
		local tm = nodes[i].transform
		local text = ""
		for row in #(tm.row1, tm.row2, tm.row3, tm.row4) do text += (massPointPoint3Text row) + " "
		setUserProp obj ("hceNodeRest" + (i as string)) text
	)
)

-- Rest transform of the i-th model node (1-based); its current one when none was stored
fn physicsNodeRest obj i =
(
	local text = getUserProp obj ("hceNodeRest" + (i as string))
	local p = if classOf text == String then filterString text " " else #()
	local v = for t in p collect (t as float)
	if v.count < 12 or findItem v undefined > 0 then return obj.modelNodes[i].transform
	matrix3 [v[1], v[2], v[3]] [v[4], v[5], v[6]] [v[7], v[8], v[9]] [v[10], v[11], v[12]]
)

-- 1-based index of the mass point's model node in the Point's modelNodes, 0 when none in the scene
fn massPointNodeIndex obj index indices =
(
	local nodeIndex = (physicsFieldText obj indices (massPointKey index "model node")) as integer
	if nodeIndex == undefined or nodeIndex < 0 or nodeIndex >= obj.modelNodes.count then return 0
	if isValidNode obj.modelNodes[nodeIndex + 1] then nodeIndex + 1 else 0
)

-- Max won't link a sphere to the Point that lists it: out of its lists while linking
fn linkSphereToPoint obj sphereNode =
(
	local listed = for n in obj.physicsNodes collect n
	local members = for n in obj.memberNodes collect n
	obj.physicsNodes = for n in listed where n != sphereNode collect n
	obj.memberNodes = for n in members where n != sphereNode collect n
	sphereNode.parent = obj
	obj.physicsNodes = listed
	obj.memberNodes = members
)

-- Fields -> sphere: parent, place, size, color and name of one mass point
fn applyMassPointSphere obj sphereNode index indices =
(
	local pos = massPointTextToPoint3 (physicsFieldText obj indices (massPointKey index "position")) [0, 0, 0]
	local forward = massPointTextToPoint3 (physicsFieldText obj indices (massPointKey index "forward")) [1, 0, 0]
	local up = massPointTextToPoint3 (physicsFieldText obj indices (massPointKey index "up")) [0, 0, 1]
	local radius = (physicsFieldText obj indices (massPointKey index "radius")) as float
	if radius == undefined do radius = 0.0
	local frictionType = (physicsFieldText obj indices (massPointKey index "friction type")) as integer

	-- Where it is in the default pose; on a node it keeps the same offset from it as at rest
	local restTm = (massPointMatrix forward up (pos * 100.0)) * obj.transform
	local nodeIndex = massPointNodeIndex obj index indices
	if nodeIndex > 0 then
	(
		local parentNode = obj.modelNodes[nodeIndex]
		sphereNode.parent = parentNode
		sphereNode.transform = restTm * (inverse (physicsNodeRest obj nodeIndex)) * parentNode.transform
	)
	else
	(
		if sphereNode.parent != obj do linkSphereToPoint obj sphereNode
		sphereNode.transform = restTm
	)
	if isProperty sphereNode #radius do sphereNode.radius = radius * 100.0
	sphereNode.wirecolor = massPointColor frictionType
	sphereNode.name = "+" + (physicsFieldText obj indices (massPointKey index "name"))
)

-- Writes a vector field when the scene value differs from it. Returns 1 when written
fn syncMassPointVector obj indices key value =
(
	local current = massPointTextToPoint3 (physicsFieldText obj indices key) undefined
	if current != undefined and distance current value < 0.00001 then return 0
	setPhysicsFieldText obj indices key (massPointPoint3Text value)
	1
)

-- Sphere -> fields: model node, position, forward, up and radius as they are in the scene (in the
-- default pose). Only what changed is written. Returns how many fields changed
fn syncPhysicsFromScene obj =
(
	if not (isPhysicsTagContainer obj) then return 0
	local indices = physicsFieldIndices obj
	local nodes = obj.physicsNodes
	local modelNodes = for n in obj.modelNodes collect n
	local inverseTm = inverse obj.transform
	local changed = 0
	with undo off
	(
		for i = 1 to nodes.count where isValidNode nodes[i] do
		(
			-- Linked by hand to another model node: that is its model node now
			local nodeIndex = if nodes[i].parent == undefined then 0 else findItem modelNodes nodes[i].parent
			if nodeIndex > 0 and nodeIndex != massPointNodeIndex obj i indices do
			(
				setPhysicsFieldText obj indices (massPointKey i "model node") ((nodeIndex - 1) as string)
				changed += 1
			)
			local worldTm = nodes[i].transform
			if nodeIndex > 0 do
				worldTm = worldTm * (inverse nodes[i].parent.transform) * (physicsNodeRest obj nodeIndex)
			local tm = worldTm * inverseTm
			-- Scaling a sphere counts as a bigger radius
			local scale = length tm.row1
			if scale > 0.0001 do
			(
				changed += syncMassPointVector obj indices (massPointKey i "position") (tm.row4 / 100.0)
				changed += syncMassPointVector obj indices (massPointKey i "forward") (tm.row1 / scale)
				changed += syncMassPointVector obj indices (massPointKey i "up") (normalize tm.row3)
				if isProperty nodes[i] #radius do
				(
					local radius = nodes[i].radius * scale / 100.0
					local radiusKey = massPointKey i "radius"
					local current = (physicsFieldText obj indices radiusKey) as float
					if current == undefined or abs (current - radius) >= 0.00001 do
					(
						setPhysicsFieldText obj indices radiusKey (massPointFloatText radius)
						changed += 1
					)
				)
			)
		)
	)
	changed
)

fn createMassPointSphere obj =
(
	local newSphere = sphere radius:10 smooth:on name:"+mass point"
	-- The Point's layer; Points from older scenes aren't in a physics layer
	local physicsLayer = obj.layer
	if baseLayerName physicsLayer.name != "Physics" do physicsLayer = haloLayer "Physics" undefined
	physicsLayer.addNode newSphere
	newSphere.parent = obj
	newSphere
)

-- One text per mass point holding all its fields: tells elements apart after a block change
fn massPointSignatures keys values =
(
	local count = 0
	for i = 1 to keys.count where keys[i] == "mass points" do count = values[i] as integer
	if count == undefined do count = 0
	local parts = #()
	for i = 1 to count do append parts #()
	for i = 1 to keys.count do
	(
		local key = keys[i]
		-- "mass points[3].radius": the index starts at character 13
		if matchPattern key pattern:"mass points[*" do
		(
			local close = findString key "]"
			local index = (substring key 13 (close - 13)) as integer
			if index != undefined and index < count do
				append parts[index + 1] ((substring key (close + 1) -1) + "=" + values[i])
		)
	)
	local signatures = #()
	for p in parts do
	(
		sort p
		local text = ""
		for t in p do text += t + "\n"
		append signatures text
	)
	signatures
)

-- A mass point added in the editor is all zeros: give it values the game accepts
fn setNewMassPointDefaults obj index indices =
(
	local radius = (physicsFieldText obj indices (massPointKey index "radius")) as float
	local forward = massPointTextToPoint3 (physicsFieldText obj indices (massPointKey index "forward")) [0, 0, 0]
	if (radius != undefined and radius != 0.0) or length forward > 0.0 then return false
	setPhysicsFieldText obj indices (massPointKey index "name") "mass point"
	setPhysicsFieldText obj indices (massPointKey index "powered mass point") "-1"
	setPhysicsFieldText obj indices (massPointKey index "model node") "-1"
	setPhysicsFieldText obj indices (massPointKey index "relative mass") "1"
	setPhysicsFieldText obj indices (massPointKey index "relative density") "1"
	setPhysicsFieldText obj indices (massPointKey index "forward") "1 0 0"
	setPhysicsFieldText obj indices (massPointKey index "up") "0 0 1"
	setPhysicsFieldText obj indices (massPointKey index "friction parallel scale") "1"
	setPhysicsFieldText obj indices (massPointKey index "friction perpendicular scale") "1"
	setPhysicsFieldText obj indices (massPointKey index "radius") "0.1"
	true
)

-- Makes the spheres match the mass points; oldKeys / oldValues: the fields before (import: none).
-- Kept mass points keep their sphere, new ones get one, spheres of deleted ones are deleted
fn reconcilePhysicsMassPoints obj oldKeys oldValues =
(
	local oldSignatures = massPointSignatures oldKeys oldValues
	local newKeys = for k in obj.fieldKeys collect k
	local newValues = for v in obj.fieldValues collect v
	local newSignatures = massPointSignatures newKeys newValues
	local oldNodes = for n in obj.physicsNodes collect n
	local used = #{}
	local newNodes = #()
	local indices = physicsFieldIndices obj

	for i = 1 to newSignatures.count do
	(
		-- The same place first, then any unused mass point with the same fields
		local found = 0
		if i <= oldSignatures.count and not used[i] and oldSignatures[i] == newSignatures[i] do found = i
		for j = 1 to oldSignatures.count while found == 0 do
			if not used[j] and oldSignatures[j] == newSignatures[i] do found = j
		local sphereNode = undefined
		if found > 0 do
		(
			used[found] = true
			if found <= oldNodes.count do sphereNode = oldNodes[found]
		)
		if not (isValidNode sphereNode) do
		(
			if found == 0 do setNewMassPointDefaults obj i indices
			sphereNode = createMassPointSphere obj
		)
		append newNodes sphereNode
	)
	for j = 1 to oldNodes.count where not used[j] and isValidNode oldNodes[j] do delete oldNodes[j]

	obj.physicsNodes = newNodes
	obj.memberNodes = newNodes
	for i = 1 to newNodes.count do applyMassPointSphere obj newNodes[i] i indices
	newNodes.count
)

-- After one field was edited ("mass points[3].radius"): updates that mass point's sphere
fn applyPhysicsField obj key =
(
	if not (matchPattern key pattern:"mass points[*") then return false
	local close = findString key "]"
	local index = (substring key 13 (close - 13)) as integer
	if index == undefined then return false
	local nodes = obj.physicsNodes
	if index + 1 > nodes.count or not (isValidNode nodes[index + 1]) then return false
	applyMassPointSphere obj nodes[index + 1] (index + 1) (physicsFieldIndices obj)
	redrawViews()
	true
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
