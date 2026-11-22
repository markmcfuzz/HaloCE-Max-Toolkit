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

-- Physics Points from the templates of lua\generators\templates, for the Create Physics Tag
-- dialog (core\tag_editor\new_physics.py): createFromTemplate, and the tag editor's Fit to Model. Sized to the selected
-- geometry (or the visible one when nothing is selected) and on its wheels (wheeled templates).
-- Loaded at startup (shared\init.ms): the tag editor's "+" on a vehicle's physics opens the dialog.

fileIn (rootEngine + "builders\\tag\\physics\\lua_reader.ms")
fileIn (rootEngine + "builders\\tag\\physics\\build_scene.ms")

-- Not mass point spheres or tag Points
fn newPhysicsModelObject o = not (inLayerKind o "Physics") and not (isObjectTagContainer o)

-- The model's nodes: sceneModelNodes (an imported model, in tag order), else the nodes the JMS
-- exporter finds by name (a model made in Max), in the order they were created
fn newPhysicsModelNodes =
(
	local nodes = sceneModelNodes()
	if nodes.count == 0 do
	(
		nodes = for o in objects where newPhysicsModelObject o and isNodeObject o collect o
		qsort nodes sortByHandle
	)
	nodes
)

fn newPhysicsSelected =
(
	local nodes = #()
	for o in selection where newPhysicsModelObject o do append nodes o
	nodes
)

-- What the physics is made for: the selection, or every visible object when nothing is selected
fn newPhysicsSource =
(
	local nodes = newPhysicsSelected()
	if nodes.count == 0 do
		for o in objects where not o.isHiddenInVpt and newPhysicsModelObject o do append nodes o
	nodes
)

-- Bounding box of the geometry of nodes, in world units; undefined without any
fn newPhysicsBox nodes =
(
	local box = undefined
	for o in nodes where superClassOf o == GeometryClass do
	(
		local lo = o.min / 100.0
		local hi = o.max / 100.0
		if box == undefined then box = #(lo, hi)
		else box = #([amin box[1].x lo.x, amin box[1].y lo.y, amin box[1].z lo.z], \
			[amax box[2].x hi.x, amax box[2].y hi.y, amax box[2].z hi.z])
	)
	box
)

-- #(count, min, max, selected) of newPhysicsSource's geometry; min = max = [0,0,0] without any
fn newPhysicsSourceBox =
(
	local nodes = newPhysicsSource()
	local count = 0
	for o in nodes where superClassOf o == GeometryClass do count += 1
	local box = newPhysicsBox nodes
	if box == undefined do box = #([0, 0, 0], [0, 0, 0])
	#(count, box[1], box[2], (newPhysicsSelected()).count > 0)
)

-- A mesh, not a node (bone, dummy, or named as the JMS exporter's nodes: isNodeObject)
fn newPhysicsIsMesh o = superClassOf o == GeometryClass and classOf o != BoneGeometry and not (isNodeObject o)

-- Named with one of the words ("tire, wheel"), not a steering wheel
fn newPhysicsWheelNamed o words =
(
	local named = false
	if not (matchPattern o.name pattern:"*steering*") do
		for w in filterString words ", " where matchPattern o.name pattern:("*" + w + "*") do named = true
	named
)

-- Objects of newPhysicsSource named like a wheel; a wheel's mesh linked under its node counts
-- once (the node). With wheel nodes, meshes don't count: an imported model has one mesh for all
-- its tires ("tire __base superhigh")
fn newPhysicsWheelNodes words =
(
	local found = #()
	for o in newPhysicsSource() where newPhysicsWheelNamed o words do append found o
	local wheels = #()
	for o in found do
	(
		local inside = false
		local p = o.parent
		while p != undefined and not inside do
		(
			if findItem found p > 0 do inside = true
			p = p.parent
		)
		if not inside do append wheels o
	)
	local wheelNodes = #()
	for o in wheels where not (newPhysicsIsMesh o) do append wheelNodes o
	if wheelNodes.count > 0 then wheelNodes else wheels
)

-- Where the model touches the ground (world units): the bottom of its meshes in newPhysicsSource,
-- or of the visible meshes when only nodes are selected
fn newPhysicsGroundZ =
(
	local meshes = #()
	for o in newPhysicsSource() where newPhysicsIsMesh o do append meshes o
	if meshes.count == 0 do
		for o in objects where not o.isHiddenInVpt and newPhysicsModelObject o and newPhysicsIsMesh o do append meshes o
	local box = newPhysicsBox meshes
	if box == undefined then (newPhysicsSourceBox())[2].z else box[1].z
)

-- Radius of each wheel node (world units) from the visible meshes named like a wheel, one mesh
-- per tire or one for all: each vertex goes to the nearest wheel, and a wheel's radius is half
-- the height of its vertices. 0 for a wheel without vertices
fn newPhysicsWheelRadii wheels words =
(
	local centers = #()
	local lows = #()
	local highs = #()
	for o in wheels do
	(
		append centers o.pos
		append lows 1e9
		append highs -1e9
	)
	if wheels.count > 0 do for o in objects where not o.isHiddenInVpt and newPhysicsModelObject o \
		and newPhysicsIsMesh o and newPhysicsWheelNamed o words do
	(
		-- World space, as deformed by its nodes now
		local m = snapshotAsMesh o
		for v = 1 to m.numVerts do
		(
			local p = getVert m v
			local nearest = 0
			local best = 1e9
			for i = 1 to centers.count do
			(
				local d = distance p centers[i]
				if d < best do (best = d; nearest = i)
			)
			if nearest > 0 do
			(
				lows[nearest] = amin lows[nearest] p.z
				highs[nearest] = amax highs[nearest] p.z
			)
		)
		delete m
	)
	local radii = #()
	for i = 1 to centers.count do append radii (if highs[i] > lows[i] then (highs[i] - lows[i]) / 200.0 else 0.0)
	radii
)

-- #(text, names) of the wheels for lua\generators\physics.lua: "x y z radius node;..." in world
-- units. A mesh: its box center and half its height. A node: its pivot, and the radius of its
-- tire (newPhysicsWheelRadii), else its height over newPhysicsGroundZ (the tire touches the
-- ground there)
fn newPhysicsWheels words =
(
	local ground = newPhysicsGroundZ()
	local modelNodes = newPhysicsModelNodes()
	local wheels = newPhysicsWheelNodes words
	local radii = newPhysicsWheelRadii wheels words
	local text = ""
	local names = #()
	for i = 1 to wheels.count do
	(
		local o = wheels[i]
		local center = o.pos / 100.0
		local radius = if radii[i] > 0 then radii[i] else center.z - ground
		if newPhysicsIsMesh o do
		(
			center = (o.min + o.max) / 200.0
			radius = (o.max.z - o.min.z) / 200.0
		)
		-- Not above the ground: not a wheel
		if radius > 0.001 do
		(
			local nodeIndex = (findItem modelNodes o) - 1
			text += (center.x as string) + " " + (center.y as string) + " " + (center.z as string) + " " + \
				(radius as string) + " " + (nodeIndex as string) + ";"
			append names o.name
		)
	)
	#(text, names)
)

-- Box of the body (world units): the meshes of newPhysicsSource (or the visible ones when only
-- nodes are selected) without the wheel-named ones, so a moved tire doesn't stretch the hull.
-- Undefined without any
fn newPhysicsBodyBox words =
(
	local meshes = #()
	for o in newPhysicsSource() where newPhysicsIsMesh o and not (newPhysicsWheelNamed o words) do append meshes o
	if meshes.count == 0 do
		for o in objects where not o.isHiddenInVpt and newPhysicsModelObject o and newPhysicsIsMesh o \
			and not (newPhysicsWheelNamed o words) do append meshes o
	newPhysicsBox meshes
)

-- Model node index (0-based) of the model's root: the first of newPhysicsModelNodes without a parent
-- among them ("frame hull" in the warthog); -1 without model nodes
fn newPhysicsRootNode =
(
	local modelNodes = newPhysicsModelNodes()
	local root = -1
	for i = 1 to modelNodes.count while root < 0 do
	(
		local parentNode = modelNodes[i].parent
		if parentNode == undefined or findItem modelNodes parentNode == 0 do root = i - 1
	)
	root
)

-- #(keys, values) the template sets on a .vehicle (type, its stock vehicle's fields, wheel
-- circumference), to fill an existing one; undefined on error
fn newVehicleValuesWithLua templateName option wheelsText =
(
	local outPath = luaExportPath "vehicle_values"
	deleteFile outPath
	if not (luaRun "generators.physics" "vehicleValues" #(templateName, option, outPath, wheelsText)) then
		return undefined
	local f = luaOpenOutput outPath "vehicle_values" 1
	if f == undefined then return undefined
	local keys = #()
	local values = #()
	for i = 1 to (luaReadInt f) do
	(
		append keys (readString f)
		append values (readString f)
	)
	luaCloseExport f "vehicle_values"
	#(keys, values)
)

-- Sets the template's .vehicle values on an existing vehicle Point; false on error
fn fillVehicleFromTemplate vehicle templateName option wheelsText =
(
	local filled = newVehicleValuesWithLua templateName option wheelsText
	if filled == undefined then return false
	local keys = for k in vehicle.fieldKeys collect k
	for i = 1 to filled[1].count do
	(
		local j = findItem keys filled[1][i]
		if j > 0 do vehicle.fieldValues[j] = filled[2][i]
	)
	true
)

-- The model's node names in order, "a;b;...": a stock template links its spheres by name
fn newPhysicsNodeNames =
(
	local names = ""
	for n in newPhysicsModelNodes() do names += n.name + ";"
	names
)

-- The template's physics fields (PhysicsTagData) for the scene now: sized to newPhysicsSource's
-- geometry (else the template's size); wheelsText: newPhysicsWheels (with wheelWords) to put the
-- wheels on, or "": then the rest goes on the body (newPhysicsBodyBox) and follows the model's
-- root node. exact: a stock template stays as the original tag. Undefined on error
fn newPhysicsFromTemplate templateName option wheelsText wheelWords exact:false =
(
	local sized = newPhysicsSourceBox()
	local boxMin = sized[2]
	local boxMax = sized[3]
	if wheelsText != "" do
	(
		local body = newPhysicsBodyBox wheelWords
		if body != undefined do (boxMin = body[1]; boxMax = body[2])
	)
	newPhysicsWithLua templateName boxMin boxMax option wheels:wheelsText rootNode:(newPhysicsRootNode()) \
		exact:exact nodeNames:(newPhysicsNodeNames())
)

-- What a physics Point was made from (createFromTemplate), for Fit to Model: user props with a
-- prefix, so getUserProp never turns "3" into a number
fn setPhysicsTemplate obj templateName option wheelWords =
(
	setUserProp obj "hceTemplate" ("t:" + templateName)
	setUserProp obj "hceTemplateOption" ("o:" + option)
	setUserProp obj "hceTemplateWheels" ("w:" + wheelWords)
)

-- #(template, option, wheel words) of a physics Point; template "" when not made from one
fn physicsTemplateOf obj =
(
	local result = #("", "", "")
	local keys = #("hceTemplate", "hceTemplateOption", "hceTemplateWheels")
	for i = 1 to 3 do
	(
		local text = getUserProp obj keys[i]
		if text != undefined do result[i] = substring (text as string) 3 -1
	)
	result
)

-- A physics Point from a template ("ball") and option ("bouncy", or ""), as
-- newPhysicsFromTemplate. wheelWords: "" when its wheels don't go on the model's (kept for Fit
-- to Model). target: an existing vehicle Point (the tag editor's "+"): it gets the template's
-- fields and the physics as its child, and stays selected; undefined: the physics is selected.
-- Undefined on error (details in the log)
fn createFromTemplate templateName option tagName wheelsText wheelWords target =
(
	local data = newPhysicsFromTemplate templateName option wheelsText wheelWords exact:true
	if data == undefined then return undefined
	local physicsPoint
	local filled = true
	undo "Create Physics Tag" on
	(
		physicsPoint = createPhysicsContainer data (tagName + ".physics") modelNodes:(newPhysicsModelNodes()) owner:target
		physicsPoint.tagFile = ""  -- not exported yet
		setPhysicsTemplate physicsPoint templateName option wheelWords
		if target != undefined do filled = fillVehicleFromTemplate target templateName option wheelsText
	)
	logger.info "New physics tag '{}' from template '{}': {} mass points" args:#(physicsPoint.name, templateName, physicsPoint.physicsNodes.count)
	if not filled do logger.error "Could not fill '{}' from template '{}'" args:#(target.name, templateName)
	local shown = if target != undefined then target else physicsPoint
	-- Selecting it opens the tag editor; the vehicle is already selected: show its new fields
	select shown
	if target != undefined do tagEditorSelectionChanged()
	-- Called from Qt, Max doesn't redraw by itself
	redrawViews()
	if filled then shown else undefined
)

fn isMassPointBlockKey k = k == "mass points" or matchPattern k pattern:"mass points[*"

-- obj's fields with its mass points block replaced by the one in keys / values: #(keys, values)
fn replaceMassPointFields obj keys values =
(
	local newKeys = #()
	local newValues = #()
	for i = 1 to obj.fieldKeys.count do
	(
		local k = obj.fieldKeys[i]
		if k == "mass points" then
			for j = 1 to keys.count where isMassPointBlockKey keys[j] do
			(
				append newKeys keys[j]
				append newValues values[j]
			)
		else if not (isMassPointBlockKey k) do
		(
			append newKeys k
			append newValues obj.fieldValues[i]
		)
	)
	#(newKeys, newValues)
)

-- Fit to Model (the tag editor's button on a physics made from a template): its mass points
-- again from that template on the model in the scene now (its wheels, its body, its nodes).
-- The tag's other fields stay. Vehicles linked to it get the new spheres. Returns what was done
fn fitPhysicsToModel obj =
(
	local made = physicsTemplateOf obj
	if made[1] == "" then return "This physics was not made from a template."
	local words = made[3]
	local found = if words != "" then newPhysicsWheels words else #("", #())
	local data = newPhysicsFromTemplate made[1] made[2] found[1] words
	local wheelsNote = ""
	if found[2].count == 0 then
		wheelsNote = if words == "" then "" else "No wheels found (names with: " + words + "): the wheels go by the model's size."
	else if data == undefined then
	(
		-- The template doesn't fit them (another count): by the model's size
		data = newPhysicsFromTemplate made[1] made[2] "" words
		wheelsNote = (found[2].count as string) + " wheels found don't fit the template: the wheels go by the model's size."
	)
	else
	(
		wheelsNote = "On " + (found[2].count as string) + " wheels:"
		for wheelName in found[2] do wheelsNote += "\n  " + wheelName
	)
	if data == undefined then return "Could not fit the physics! See the log for details."

	undo "Fit Physics to Model" on
	(
		local oldKeys = for k in obj.fieldKeys collect k
		local oldValues = for v in obj.fieldValues collect v
		-- The model's nodes now, in their pose now
		obj.modelNodes = newPhysicsModelNodes()
		storePhysicsNodeRests obj
		local merged = replaceMassPointFields obj data.keys data.values
		obj.fieldKeys = merged[1]
		obj.fieldValues = merged[2]
		reconcilePhysicsMassPoints obj oldKeys oldValues
	)
	redrawViews()
	local count = obj.physicsNodes.count
	logger.info "Fit '{}' to the model: {} mass points. {}" args:#(obj.name, count, wheelsNote)
	(count as string) + " mass points fitted to the model, linked to its nodes (" + \
		((obj.modelNodes.count) as string) + " in the scene).\n" + wheelsNote
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
