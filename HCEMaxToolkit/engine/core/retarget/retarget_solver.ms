------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

-- Retarget solver. All transforms are world matrix3 values in Max's row-vector convention
-- (world = local * parentWorld). Requires retarget_mapping.ms, jma_struct.ms, jma_reader.ms,
-- process_file.ms (writeJmaFile) and jma\process_scene.ms (collectNodesRecursive).
--
-- Per mapped target bone T with source bone S, both captured at the match pose:
--   offset = T_match * inverse S_match
--   rotation(t) = rotation of (offset * S(t))     -> same relation to S as in the match pose
--   position(t) = target rest local position under the new parent (keeps target bone lengths)
-- The rig root follows offset * S(t) rigidly (translation delta scaled by rootScale), unmapped
-- bones keep their match pose local transform, and hand IK pins the target hand to
-- offset * S_hand(t) so both hands sit where the source hands are.

struct retargetContext
(
	names = #(),
	parents = #(),
	restWorld = #(),
	restLocal = #(),
	sourceNames = #(),  -- per target node: mapped source name, or undefined
	offsets = #(),      -- per target node: matrix3, or undefined when unmapped
	ikChains = #(),     -- #(upper, fore, hand) target indices
	useIK = true,
	rootScale = 1.0,
	clampedFrames = 0,
	warnings = #()
)

-------------------------------------------------------
-- RIGS
-------------------------------------------------------

-- Any bone of a rig gives the rig: walk up while the parent is still a Halo node
fn retargetFindRigRoot obj =
(
	if obj == undefined or not (isNodeObject obj) do return undefined
	local root = obj
	while root.parent != undefined and (isNodeObject root.parent) do root = root.parent
	root
)

-- Visible Halo nodes under root, in the same order the JMA exporter writes them (parents first)
fn retargetCollectRig rootNode =
(
	local temp = #()
	if rootNode == undefined do return #()
	collectNodesRecursive rootNode 1 temp
	fn compareByPrefixedName a b = (if a[2] < b[2] then -1 else if a[2] > b[2] then 1 else 0)
	qsort temp compareByPrefixedName
	for item in temp collect item[1]
)

fn retargetNodeByName rigNodes nodeName =
(
	if nodeName == undefined do return undefined
	local lowered = toLower nodeName
	for n in rigNodes do
		if (toLower n.name) == lowered do return n
	undefined
)

-- n.transform is the evaluated world TM whatever drives the bone (keys, constraints, IK)
fn retargetCapturePose rigNodes =
(
	local pose = retargetRigPose()
	pose.names = for n in rigNodes collect n.name
	pose.parents = for n in rigNodes collect (if n.parent == undefined then 0 else findItem rigNodes n.parent)
	pose.worlds = for n in rigNodes collect n.transform
	pose
)

-- The rig root's local transform is its world transform, as in the JMA exporter
fn retargetPoseLocal pose idx =
(
	local p = pose.parents[idx]
	if p == 0 then pose.worlds[idx] else pose.worlds[idx] * inverse pose.worlds[p]
)

-- Mirrored (negative scale) bones can't be represented by a JMA quaternion
fn retargetPoseWarnings pose label =
(
	local warnings = #()
	for i = 1 to pose.names.count do
	(
		local m = pose.worlds[i]
		if (dot (cross m.row1 m.row2) m.row3) < 0 do
			append warnings (label + " bone '" + pose.names[i] + "' is mirrored (negative scale)")
	)
	warnings
)

-------------------------------------------------------
-- MATRIX HELPERS
-------------------------------------------------------

fn retargetRotationOnly m =
(
	matrix3 (normalize m.row1) (normalize m.row2) (normalize m.row3) [0, 0, 0]
)

fn retargetWithPosition rotMatrix pos =
(
	matrix3 rotMatrix.row1 rotMatrix.row2 rotMatrix.row3 pos
)

-- Right-handed rotation of the given degrees about a unit axis, as a row-vector matrix
fn retargetAxisAngleMatrix axis degrees =
(
	local c = cos degrees
	local s = sin degrees
	fn rotateVector v axis c s = v * c + (cross axis v) * s + axis * ((dot axis v) * (1.0 - c))
	matrix3 (rotateVector [1, 0, 0] axis c s) (rotateVector [0, 1, 0] axis c s) (rotateVector [0, 0, 1] axis c s) [0, 0, 0]
)

-- Shortest rotation taking direction fromVec onto toVec
fn retargetSwingMatrix fromVec toVec =
(
	local a = normalize fromVec
	local b = normalize toVec
	local axis = cross a b
	local s = length axis
	local c = dot a b
	if s < 1e-6 do
	(
		if c > 0 do return matrix3 1
		axis = cross a [1, 0, 0]
		if (length axis) < 1e-3 do axis = cross a [0, 1, 0]
	)
	retargetAxisAngleMatrix (normalize axis) (atan2 s c)
)

-- Rotate a world transform in place about its own pivot
fn retargetRotateAboutPivot m rotMatrix =
(
	matrix3 (m.row1 * rotMatrix) (m.row2 * rotMatrix) (m.row3 * rotMatrix) m.row4
)

-------------------------------------------------------
-- AUTO ALIGN (helps building the match pose)
-------------------------------------------------------

-- (middle - hand) x (index - ring), built the same way on any rig so both hands' palms agree
fn retargetPalmNormal handNode =
(
	local index = undefined
	local middle = undefined
	local ring = undefined
	local pinky = undefined
	local stack = for c in handNode.children collect c
	while stack.count > 0 do
	(
		local n = stack[stack.count]
		stack.count = stack.count - 1
		if retargetKeyEndsWith n.name "index 1" then index = n.transform.row4
		else if retargetKeyEndsWith n.name "middle 1" then middle = n.transform.row4
		else if retargetKeyEndsWith n.name "ring 1" then ring = n.transform.row4
		else if retargetKeyEndsWith n.name "pinky 1" do pinky = n.transform.row4
		for c in n.children do append stack c
	)
	if ring == undefined do ring = pinky
	if index == undefined or middle == undefined or ring == undefined do return undefined
	local hand = handNode.transform.row4
	local normal = cross (middle - hand) (index - ring)
	if (length normal) < 1e-6 then undefined else normalize normal
)

-- Parents first: point every mapped target bone at its mapped child like the source does,
-- and roll hands so the palms face the same way. The root is left where it is.
-- Changes the scene at the current time; the caller wraps it in undo / animate off.
fn retargetAutoAlign preset sourceRig targetRig =
(
	local aligned = 0
	for i = 2 to targetRig.count do
	(
		local t = targetRig[i]
		local s = retargetNodeByName sourceRig (retargetGetSource preset t.name)
		if s == undefined do continue

		-- Aim child: a mapped direct child, the middle finger for hands
		local child = undefined
		local sourceChild = undefined
		for c in t.children where (findItem targetRig c) > 0 do
		(
			local sc = retargetNodeByName sourceRig (retargetGetSource preset c.name)
			if sc != undefined and (child == undefined or retargetKeyEndsWith c.name "middle 1") do
			(
				child = c
				sourceChild = sc
			)
		)
		if child == undefined do continue

		local targetDir = child.transform.row4 - t.transform.row4
		local sourceDir = sourceChild.transform.row4 - s.transform.row4
		if (length targetDir) < 1e-4 or (length sourceDir) < 1e-4 do continue
		t.transform = retargetRotateAboutPivot t.transform (retargetSwingMatrix targetDir sourceDir)

		if retargetKeyEndsWith t.name "hand" do
		(
			local tn = retargetPalmNormal t
			local sn = retargetPalmNormal s
			if tn != undefined and sn != undefined do
			(
				local axis = normalize sourceDir
				tn = tn - axis * (dot tn axis)
				sn = sn - axis * (dot sn axis)
				if (length tn) > 1e-4 and (length sn) > 1e-4 do
				(
					tn = normalize tn
					sn = normalize sn
					local rollDegrees = atan2 (dot (cross tn sn) axis) (dot tn sn)
					t.transform = retargetRotateAboutPivot t.transform (retargetAxisAngleMatrix axis rollDegrees)
				)
			)
		)
		aligned += 1
	)
	aligned
)

-------------------------------------------------------
-- SOLVER
-------------------------------------------------------

fn retargetPrepare preset useIK:true =
(
	if preset.sourcePose == undefined or preset.targetPose == undefined do return undefined
	local sp = preset.sourcePose
	local tp = preset.targetPose
	local ctx = retargetContext()
	ctx.names = tp.names
	ctx.parents = tp.parents
	ctx.restWorld = tp.worlds
	ctx.restLocal = for i = 1 to tp.names.count collect retargetPoseLocal tp i
	ctx.sourceNames = #()
	ctx.offsets = #()
	ctx.ikChains = #()
	ctx.warnings = #()
	ctx.useIK = useIK
	ctx.rootScale = preset.rootScale

	for i = 1 to tp.names.count do
	(
		local srcName = retargetGetSource preset tp.names[i]
		local srcIdx = if srcName != undefined then retargetFindName sp.names srcName else 0
		if srcName != undefined and srcIdx == 0 do
			append ctx.warnings ("Source bone '" + srcName + "' is not in the captured match pose")
		if srcIdx > 0 then
		(
			append ctx.sourceNames sp.names[srcIdx]
			append ctx.offsets (tp.worlds[i] * inverse sp.worlds[srcIdx])
		)
		else
		(
			append ctx.sourceNames undefined
			append ctx.offsets undefined
		)
	)
	for p in preset.pairs where (retargetFindName tp.names p[1]) == 0 do
		append ctx.warnings ("Target bone '" + p[1] + "' is not in the captured match pose")

	if useIK do
	(
		for h = 1 to tp.names.count where ctx.offsets[h] != undefined and (retargetKeyEndsWith tp.names[h] "hand") do
		(
			local f = ctx.parents[h]
			local u = if f > 0 then ctx.parents[f] else 0
			if u > 0 and ctx.offsets[f] != undefined and ctx.offsets[u] != undefined then
				append ctx.ikChains #(u, f, h)
			else
				append ctx.warnings ("No hand IK for '" + tp.names[h] + "': its parent and grandparent (forearm, upper arm) must be mapped")
		)
	)
	ctx
)

-- Two-bone IK. Called right after the upper arm got its FK world transform; replaces it and
-- leaves the forearm rotation in rotOverride. Twist is kept: both bones only swing.
fn retargetSolveChain ctx chain worlds srcWorlds rotOverride =
(
	local u = chain[1]
	local f = chain[2]
	local h = chain[3]
	if srcWorlds[h] == undefined do return false

	local upperWorld = worlds[u]
	local shoulder = upperWorld.row4
	local goal = (ctx.offsets[h] * srcWorlds[h]).row4

	local foreRot = if srcWorlds[f] != undefined then retargetRotationOnly (ctx.offsets[f] * srcWorlds[f]) \
		else retargetRotationOnly (ctx.restLocal[f] * upperWorld)
	local elbowFK = ctx.restLocal[f].row4 * upperWorld
	local wristFK = ctx.restLocal[h].row4 * (retargetWithPosition foreRot elbowFK)
	local a = distance shoulder elbowFK
	local b = distance elbowFK wristFK
	local toGoal = goal - shoulder
	local d = length toGoal
	if a < 1e-4 or b < 1e-4 or d < 1e-4 do return false
	local dir = toGoal / d

	local minD = (abs (a - b)) + 1e-3
	local maxD = a + b - 1e-3
	if d > maxD or d < minD do
	(
		ctx.clampedFrames += 1
		d = amax minD (amin maxD d)
	)

	-- Bend plane from the FK elbow, so the elbow points where the source elbow points
	local bend = elbowFK - shoulder
	bend = bend - dir * (dot bend dir)
	if (length bend) < 1e-5 do
	(
		bend = cross dir foreRot.row3
		if (length bend) < 1e-5 do bend = cross dir [0, 0, 1]
	)
	bend = normalize bend

	local x = (a * a - b * b + d * d) / (2.0 * d)
	local elbow = shoulder + dir * x + bend * (sqrt (amax 0.0 (a * a - x * x)))
	local wrist = shoulder + dir * d

	worlds[u] = retargetRotateAboutPivot upperWorld (retargetSwingMatrix (elbowFK - shoulder) (elbow - shoulder))
	local foreWorld = retargetWithPosition foreRot elbow
	local wristNow = ctx.restLocal[h].row4 * foreWorld
	rotOverride[f] = retargetRotationOnly (foreWorld * (retargetSwingMatrix (wristNow - elbow) (wrist - elbow)))
	true
)

-- srcWorlds: per target node, the world transform of its source bone this frame (or undefined).
-- Returns the target world transforms in rig order.
fn retargetSolveFrame ctx srcWorlds =
(
	local count = ctx.names.count
	local worlds = #()
	worlds.count = count
	local rotOverride = #()
	rotOverride.count = count

	for i = 1 to count do
	(
		local p = ctx.parents[i]
		local parentWorld = if p > 0 then worlds[p] else undefined
		local offset = ctx.offsets[i]
		local src = srcWorlds[i]

		if offset == undefined or src == undefined then
		(
			-- Unmapped: keep the match pose relative to the parent
			worlds[i] = if parentWorld == undefined then ctx.restWorld[i] else ctx.restLocal[i] * parentWorld
		)
		else if parentWorld == undefined then
		(
			-- Rig root: follows its source bone rigidly
			local w = offset * src
			local restPos = ctx.restWorld[i].row4
			worlds[i] = retargetWithPosition w (restPos + (w.row4 - restPos) * ctx.rootScale)
		)
		else
		(
			local rotMatrix = if rotOverride[i] != undefined then rotOverride[i] else retargetRotationOnly (offset * src)
			worlds[i] = retargetWithPosition rotMatrix (ctx.restLocal[i].row4 * parentWorld)
		)

		if ctx.useIK do
			for chain in ctx.ikChains where chain[1] == i do
				retargetSolveChain ctx chain worlds srcWorlds rotOverride
	)
	worlds
)

-------------------------------------------------------
-- JMA <-> WORLD TRANSFORMS
-------------------------------------------------------

-- Parent index per JMA node (0 = root), from first child / next sibling links
fn retargetJmaParents jmaData =
(
	local count = jmaData.nodes.count
	local parents = for n in jmaData.nodes collect 0
	for i = 1 to count do
	(
		local c = jmaData.nodes[i].firstChildNodeIndex
		local guard = 0
		while c >= 0 and c < count and guard < count do
		(
			parents[c + 1] = i
			c = jmaData.nodes[c + 1].nextSiblingNodeIndex
			guard += 1
		)
	)
	parents
)

-- File quaternions use the same convention as matrix3.rotationpart (see the JMA exporter)
fn retargetJmaFrameWorlds jmaData frameIdx parents =
(
	local frame = jmaData.frames[frameIdx]
	local count = parents.count
	local locals = for i = 1 to count collect
	(
		local nf = frame.nodeFrames[i]
		local m = nf.rotation as matrix3
		if nf.scale != undefined and (abs (nf.scale - 1.0)) > 1e-6 do
			m = matrix3 (m.row1 * nf.scale) (m.row2 * nf.scale) (m.row3 * nf.scale) [0, 0, 0]
		retargetWithPosition m nf.translation
	)
	local worlds = #()
	worlds.count = count
	local pending = true
	for pass = 1 to count while pending do
	(
		pending = false
		for i = 1 to count where worlds[i] == undefined do
		(
			local p = parents[i]
			if p == 0 then worlds[i] = locals[i]
			else if worlds[p] != undefined then worlds[i] = locals[i] * worlds[p]
			else pending = true
		)
	)
	worlds
)

-- prevQuats keeps each node's previous quaternion, so the sign never flips between frames
fn retargetWorldsToKeyframe ctx worlds prevQuats =
(
	local kf = jmaKeyframes nodeTranslation:#() nodeRotation:#() nodeScale:#()
	for i = 1 to worlds.count do
	(
		local p = ctx.parents[i]
		local tm = if p > 0 then worlds[i] * inverse worlds[p] else worlds[i]
		local q = normalize tm.rotationpart
		local prev = prevQuats[i]
		if prev != undefined and (q.x * prev.x + q.y * prev.y + q.z * prev.z + q.w * prev.w) < 0 do
			q = quat (-q.x) (-q.y) (-q.z) (-q.w)
		prevQuats[i] = q
		local t = tm.translationpart
		local sp = tm.scalepart
		append kf.nodeTranslation #(t.x, t.y, t.z)
		append kf.nodeRotation #(q.x, q.y, q.z, q.w)
		append kf.nodeScale ((sp.x + sp.y + sp.z) / 3.0)
	)
	kf
)

-- First child / next sibling links, children in ascending index order like the exporter
fn retargetBuildJmaNodes names parents =
(
	local count = names.count
	local children = for i = 1 to count collect #()
	for i = 1 to count where parents[i] > 0 do append children[parents[i]] i
	local nextSibling = for i = 1 to count collect -1
	for c in children do
		for k = 1 to c.count - 1 do nextSibling[c[k]] = c[k + 1] - 1
	for i = 1 to count collect
		jmaNodes nodeName:names[i] \
			firstChildNodeIndex:(if children[i].count > 0 then children[i][1] - 1 else -1) \
			nextSiblingNodeIndex:nextSibling[i]
)

-------------------------------------------------------
-- RUNS
-------------------------------------------------------

-- Retarget one JMA-family file. Returns #(success, messages)
fn retargetJmaFile ctx inPath outPath =
(
	local messages = #()
	local jma = readJmaFile inPath
	if jma == undefined or jma.frames.count == 0 do return #(false, #("could not be read"))

	local jmaNames = for n in jma.nodes collect n.nodeName
	local parents = retargetJmaParents jma
	local srcIdx = for s in ctx.sourceNames collect (if s == undefined then 0 else retargetFindName jmaNames s)
	local missing = #()
	for i = 1 to srcIdx.count where ctx.sourceNames[i] != undefined and srcIdx[i] == 0 do
		appendIfUnique missing ctx.sourceNames[i]
	if (for k in srcIdx where k > 0 collect k).count == 0 do
		return #(false, #("none of the mapped source bones are in this file"))
	if missing.count > 0 do
	(
		local text = "missing source bones, kept at the match pose:"
		for m in missing do text += " '" + m + "'"
		append messages text
	)

	ctx.clampedFrames = 0
	local prevQuats = #()
	prevQuats.count = ctx.names.count
	local keyframes = for f = 1 to jma.frames.count collect
	(
		local jw = retargetJmaFrameWorlds jma f parents
		local srcWorlds = for k in srcIdx collect (if k > 0 then jw[k] else undefined)
		retargetWorldsToKeyframe ctx (retargetSolveFrame ctx srcWorlds) prevQuats
	)
	if ctx.clampedFrames > 0 do
		append messages ("hand IK out of reach " + (ctx.clampedFrames as string) + " time(s), arm fully stretched")

	local out = jmaFile jmaVersion:SUPPORTED_JMA_VERSION frameCount:keyframes.count frameRate:jma.frameRate \
		actorNamesIndex:jma.actorNamesIndex actorNames:jma.actorNames nodeCount:ctx.names.count nodeChecksum:0
	out.nodes = retargetBuildJmaNodes ctx.names ctx.parents
	out.keyframes = keyframes
	local result = writeJmaFile outPath out
	if not result[1] do append messages "could not be written"
	#(result[1], messages)
)

-- Sample the source rig over the animation range and key the target rig.
-- Every target node of the capture gets a key per frame (its old keys are deleted).
-- Returns #(frameCount, messages)
fn retargetBakeScene ctx sourceRig targetRig progressBar:undefined =
(
	local messages = #()
	local srcNodes = for s in ctx.sourceNames collect retargetNodeByName sourceRig s
	local tgtNodes = for n in ctx.names collect retargetNodeByName targetRig n
	for i = 1 to ctx.names.count do
	(
		if tgtNodes[i] == undefined do append messages ("Target bone '" + ctx.names[i] + "' is not in the scene rig")
		if ctx.sourceNames[i] != undefined and srcNodes[i] == undefined do
			append messages ("Source bone '" + ctx.sourceNames[i] + "' is not in the scene rig")
	)

	local startFrame = animationRange.start.frame as integer
	local endFrame = animationRange.end.frame as integer
	local total = endFrame - startFrame + 1
	ctx.clampedFrames = 0
	local frames = #()
	for f = startFrame to endFrame do
	(
		local srcWorlds = for n in srcNodes collect (if n == undefined then undefined else at time f n.transform)
		append frames (retargetSolveFrame ctx srcWorlds)
		if progressBar != undefined do progressBar.value = 50.0 * (f - startFrame + 1) / total
	)
	if ctx.clampedFrames > 0 do
		append messages ("Hand IK out of reach " + (ctx.clampedFrames as string) + " time(s), arm fully stretched")

	for n in tgtNodes where n != undefined do deleteKeys n.controller #allKeys
	with animate on
	(
		for k = 1 to frames.count do
		(
			at time (startFrame + k - 1)
				for i = 1 to tgtNodes.count where tgtNodes[i] != undefined do tgtNodes[i].transform = frames[k][i]
			if progressBar != undefined do progressBar.value = 50.0 + 50.0 * k / total
		)
	)
	#(frames.count, messages)
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
