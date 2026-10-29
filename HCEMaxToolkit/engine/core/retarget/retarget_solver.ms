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

-- Retarget solver, the MAXScript counterpart of core\halo5\retarget.py. All transforms are
-- matrix3 values in Max's row-vector convention (world = local * parentWorld). Requires
-- retarget_mapping.ms, jma_struct.ms, jma_reader.ms, process_file.ms (writeJmaFile) and
-- jma\process_scene.ms (collectNodesRecursive).
--
-- Both rigs are captured in their rest (bind) pose; they don't need to look alike. For each
-- mapped bone a "canonical frame" is built the same way on both rigs: X = bone direction (to its
-- mapped child), Z = palm normal of its side (world axes for centre bones). With C the canonical
-- frames at rest:
--   offset = T_rest * inverse C_target * C_source * inverse S_rest
--   rotation(t) = rotation of (offset * S(t))
--   position(t) = target rest local position under the new parent, plus how far the source bone
--                 moved from its rest place (first person animations move the shoulders a lot)
-- The rig root takes the rotation of offset * S(t) and the source position plus the rest position
-- difference as a fixed world vector (as the Halo 5 tool does). Hand IK lines up the middle knuckles of both rigs,
-- sliding the shoulder toward the hand when the arm is too short.
--
-- Followers: unmapped target nodes whose name is also in the source animation (weapon nodes such
-- as b_gun, linked to the target hand before capturing) keep their source placement relative to
-- the nearest mapped source ancestor (the hand). With IK they stay where the source has them,
-- shifted only by what the hand missed its goal by, so the other hand still meets the weapon.

struct retargetContext
(
	names = #(),
	parents = #(),
	restWorld = #(),
	restLocal = #(),
	sourceNames = #(),        -- per target node: mapped source name, or undefined
	sourceParentNames = #(),  -- per target node: source bone's parent (for animated translations)
	sourceRestLocal = #(),    -- per target node: source bone rest position in its parent, or undefined
	offsets = #(),            -- per target node: matrix3, or undefined when unmapped
	rootDeltas = #(),         -- per target node: target rest position - source rest position (world)
	adjusts = #(),            -- per target node: local correction matrix3, or undefined
	hasAdjusts = false,
	ikChains = #(),           -- #(upper, fore, hand, grip) target indices; grip = #(sourceGrip, targetGrip)
	useIK = true,
	copyTranslations = true,
	shoulderReach = 0.0,
	cameraNode = "",          -- source node all poses are taken relative to ("" = none)
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

-- Like rotating the bone in 'Local' in 3ds Max: X, then Y, then Z (degrees)
fn retargetAdjustMatrix angles =
(
	(retargetAxisAngleMatrix [0, 0, 1] angles.z) * (retargetAxisAngleMatrix [0, 1, 0] angles.y) * \
		(retargetAxisAngleMatrix [1, 0, 0] angles.x)
)

-- Rows: X = aim, Z = up made perpendicular to it, Y = Z x X. Undefined when they're parallel.
fn retargetCanonicalFrame aim up =
(
	if (length aim) < 1e-6 do return undefined
	local x = normalize aim
	local z = up - x * (dot up x)
	if (length z) < 1e-6 do return undefined
	z = normalize z
	matrix3 x (cross z x) z [0, 0, 0]
)

-------------------------------------------------------
-- REST POSE ANALYSIS
-------------------------------------------------------

fn retargetPoseFindKey pose key =
(
	for i = 1 to pose.names.count do
		if (retargetBoneKey pose.names[i]) == key do return i
	0
)

-- Hand, middle, index and ring (or pinky) knuckle indices of one side, on the target and on the
-- source through the mapping, so both palms are built from the same fingers.
-- Returns #(targetIndices, sourceIndices) or undefined.
fn retargetPalmBones preset sp tp side =
(
	local keys = #(side + " hand", side + " middle 1", side + " index 1", side + " ring 1")
	local targetIdx = for k in keys collect retargetPoseFindKey tp k
	if targetIdx[4] == 0 do targetIdx[4] = retargetPoseFindKey tp (side + " pinky 1")
	if (findItem targetIdx 0) > 0 do return undefined
	local sourceIdx = for t in targetIdx collect
	(
		local s = retargetGetSource preset tp.names[t]
		if s == undefined then 0 else retargetFindName sp.names s
	)
	if (findItem sourceIdx 0) > 0 do return undefined
	#(targetIdx, sourceIdx)
)

-- (middle - hand) x (index - ring), the twist reference shared by both rigs
fn retargetPalmNormal pose idx =
(
	local p = for i in idx collect pose.worlds[i].row4
	local normal = cross (p[2] - p[1]) (p[3] - p[4])
	if (length normal) < 1e-6 then undefined else normalize normal
)

-- Bone direction on both rigs: toward a mapped direct child (the middle finger for hands), or
-- from the parent for bones without one (finger tips). Returns #(targetDir, sourceDir) or undefined.
fn retargetPoseAims preset sp tp ti si =
(
	local child = 0
	local sourceChild = 0
	for k = 1 to tp.names.count where tp.parents[k] == ti do
	(
		local s = retargetGetSource preset tp.names[k]
		local sk = if s == undefined then 0 else retargetFindName sp.names s
		if sk > 0 and (child == 0 or retargetKeyEndsWith tp.names[k] "middle 1") do
		(
			child = k
			sourceChild = sk
		)
	)
	if child > 0 do
		return #(tp.worlds[child].row4 - tp.worlds[ti].row4, sp.worlds[sourceChild].row4 - sp.worlds[si].row4)
	local tParent = tp.parents[ti]
	local sParent = sp.parents[si]
	if tParent == 0 or sParent == 0 do return undefined
	#(tp.worlds[ti].row4 - tp.worlds[tParent].row4, sp.worlds[si].row4 - sp.worlds[sParent].row4)
)

-------------------------------------------------------
-- SOLVER
-------------------------------------------------------

fn retargetPrepare preset useIK:true copyTranslations:true shoulderReach:0.0 =
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
	ctx.sourceParentNames = #()
	ctx.sourceRestLocal = #()
	ctx.offsets = #()
	ctx.rootDeltas = #()
	ctx.adjusts = #()
	ctx.ikChains = #()
	ctx.warnings = #()
	ctx.useIK = useIK
	ctx.copyTranslations = copyTranslations
	ctx.shoulderReach = shoulderReach
	ctx.rootScale = preset.rootScale
	ctx.cameraNode = preset.cameraNode

	-- Palm normals per side
	local palms = #()
	for side in #("l", "r") do
	(
		local bones = retargetPalmBones preset sp tp side
		local normals = if bones == undefined then undefined else #(retargetPalmNormal tp bones[1], retargetPalmNormal sp bones[2])
		append palms (if normals == undefined or normals[1] == undefined or normals[2] == undefined then undefined else normals)
	)
	for i = 1 to tp.names.count do
	(
		local srcName = retargetGetSource preset tp.names[i]
		local si = if srcName != undefined then retargetFindName sp.names srcName else 0
		if srcName != undefined and si == 0 do
			append ctx.warnings ("Source bone '" + srcName + "' is not in the captured source rest pose")
		local angles = retargetGetAdjust preset tp.names[i]
		append ctx.adjusts (if angles == undefined then undefined else retargetAdjustMatrix angles)
		if angles != undefined do ctx.hasAdjusts = true
		if si == 0 then
		(
			append ctx.sourceNames undefined
			append ctx.sourceParentNames undefined
			append ctx.sourceRestLocal undefined
			append ctx.offsets undefined
			append ctx.rootDeltas undefined
			continue
		)

		-- Canonical frames: side bones twist with their palm, centre bones keep the world axes
		local side = retargetBoneSide tp.names[i]
		local palm = if side == "l" then palms[1] else if side == "r" then palms[2] else undefined
		local cs = undefined
		local ct = undefined
		if palm != undefined do
		(
			local aims = retargetPoseAims preset sp tp i si
			if aims != undefined do
			(
				ct = retargetCanonicalFrame aims[1] palm[1]
				cs = retargetCanonicalFrame aims[2] palm[2]
			)
			if cs == undefined or ct == undefined do
				append ctx.warnings ("No bone direction for '" + tp.names[i] + "', using the rest pose difference")
		)
		if cs == undefined or ct == undefined do
		(
			cs = matrix3 1
			ct = matrix3 1
		)

		append ctx.sourceNames sp.names[si]
		append ctx.offsets (tp.worlds[i] * (inverse ct) * cs * (inverse sp.worlds[si]))
		append ctx.rootDeltas (tp.worlds[i].row4 - sp.worlds[si].row4)
		local sParent = sp.parents[si]
		append ctx.sourceParentNames (if sParent > 0 then sp.names[sParent] else undefined)
		append ctx.sourceRestLocal (if sParent > 0 then (retargetPoseLocal sp si).row4 else undefined)
	)
	for p in preset.pairs where (retargetFindName tp.names p[1]) == 0 do
		append ctx.warnings ("Target bone '" + p[1] + "' is not in the captured target rest pose")

	if useIK do
	(
		for h = 1 to tp.names.count where ctx.offsets[h] != undefined and (retargetKeyEndsWith tp.names[h] "hand") do
		(
			local f = ctx.parents[h]
			local u = if f > 0 then ctx.parents[f] else 0
			if u == 0 or ctx.offsets[f] == undefined or ctx.offsets[u] == undefined do
			(
				append ctx.warnings ("No hand IK for '" + tp.names[h] + "': its parent and grandparent (forearm, upper arm) must be mapped")
				continue
			)
			-- Grip point: the middle knuckle in hand space on each rig, so the hands meet the
			-- weapon at the same place even when the wrist pivots don't match
			local grip = undefined
			local bones = retargetPalmBones preset sp tp (retargetBoneSide tp.names[h])
			if bones != undefined and bones[1][1] == h do
			(
				local sh = bones[2][1]
				local tGrip = (tp.worlds[bones[1][2]].row4 - tp.worlds[h].row4) * (inverse (retargetRotationOnly tp.worlds[h]))
				local sGrip = (sp.worlds[bones[2][2]].row4 - sp.worlds[sh].row4) * (inverse (retargetRotationOnly sp.worlds[sh]))
				grip = #(sGrip, tGrip)
			)
			append ctx.ikChains #(u, f, h, grip)
		)
	)
	ctx
)

-- First target node mapped to the given source bone, or 0
fn retargetTargetOfSource ctx sourceName =
(
	local lowered = toLower sourceName
	for i = 1 to ctx.sourceNames.count do
		if ctx.sourceNames[i] != undefined and (toLower ctx.sourceNames[i]) == lowered do return i
	0
)

-- Followers for one source animation (names + parent indices, 0 = none). Returns, per target node,
-- #(sourceIndex, anchorSourceIndex, anchorTargetIndex) or undefined.
fn retargetResolveFollowers ctx srcNames srcParents =
(
	local follow = #()
	follow.count = ctx.names.count
	for i = 1 to ctx.names.count where ctx.offsets[i] == undefined and ctx.parents[i] > 0 do
	(
		local k = retargetFindName srcNames ctx.names[i]
		if k == 0 or (retargetTargetOfSource ctx srcNames[k]) > 0 do continue
		local a = srcParents[k]
		local ta = 0
		local guard = 0
		while a > 0 and ta == 0 and guard < srcNames.count do
		(
			ta = retargetTargetOfSource ctx srcNames[a]
			if ta == 0 do a = srcParents[a]
			guard += 1
		)
		if ta > 0 do follow[i] = #(k, a, ta)
	)
	follow
)

-- Two-bone IK. Called right after the upper arm got its world transform; replaces it and leaves
-- the forearm rotation in rotOverride. Twist is kept: both bones only swing. residuals[hand] gets
-- how far the hand ended from its goal.
fn retargetSolveChain ctx chain worlds srcWorlds rotOverride residuals =
(
	local u = chain[1]
	local f = chain[2]
	local h = chain[3]
	if srcWorlds[h] == undefined do return false

	local handRot = retargetRotationOnly (ctx.offsets[h] * srcWorlds[h])
	local desired = srcWorlds[h].row4
	if chain[4] != undefined do
		desired = desired + chain[4][1] * (retargetRotationOnly srcWorlds[h]) - chain[4][2] * handRot

	local upperWorld = worlds[u]
	local shoulder = upperWorld.row4
	local foreRot = if srcWorlds[f] != undefined then retargetRotationOnly (ctx.offsets[f] * srcWorlds[f]) \
		else retargetRotationOnly (ctx.restLocal[f] * upperWorld)
	local elbowFK = ctx.restLocal[f].row4 * upperWorld
	local wristFK = ctx.restLocal[h].row4 * (retargetWithPosition foreRot elbowFK)
	local a = distance shoulder elbowFK
	local b = distance elbowFK wristFK
	local toGoal = desired - shoulder
	local d = length toGoal
	if a < 1e-4 or b < 1e-4 or d < 1e-4 do return false
	local dir = toGoal / d

	-- Out of reach: slide the shoulder toward the goal by what's missing, up to shoulderReach
	local reach = a + b - 1e-3
	if d > reach and ctx.shoulderReach > 0 do
	(
		shoulder = shoulder + dir * (amin (d - reach) ctx.shoulderReach)
		d = distance desired shoulder
	)
	local minD = (abs (a - b)) + 1e-3
	if d > reach or d < minD do
	(
		ctx.clampedFrames += 1
		d = amax minD (amin reach d)
	)

	-- Bend like the source elbow: its offset from the source shoulder-wrist line
	local bend = undefined
	local candidates = #()
	if srcWorlds[u] != undefined and srcWorlds[f] != undefined do
	(
		local srcAxis = srcWorlds[h].row4 - srcWorlds[u].row4
		if (length srcAxis) > 1e-5 do
		(
			srcAxis = normalize srcAxis
			local v = srcWorlds[f].row4 - srcWorlds[u].row4
			append candidates (v - srcAxis * (dot v srcAxis))
		)
	)
	append candidates (elbowFK - shoulder)
	for v in candidates while bend == undefined do
	(
		local perpendicular = v - dir * (dot v dir)
		if (length perpendicular) > 1e-5 do bend = normalize perpendicular
	)
	if bend == undefined do return false

	local x = (a * a - b * b + d * d) / (2.0 * d)
	local elbow = shoulder + dir * x + bend * (sqrt (amax 0.0 (a * a - x * x)))
	local wrist = shoulder + dir * d

	local upperRot = retargetRotateAboutPivot (retargetRotationOnly upperWorld) (retargetSwingMatrix (elbowFK - upperWorld.row4) (elbow - shoulder))
	worlds[u] = retargetWithPosition upperRot shoulder
	local foreWorld = retargetWithPosition foreRot elbow
	local wristNow = ctx.restLocal[h].row4 * foreWorld
	rotOverride[f] = retargetRotationOnly (foreWorld * (retargetSwingMatrix (wristNow - elbow) (wrist - elbow)))
	residuals[h] = ctx.restLocal[h].row4 * (retargetWithPosition rotOverride[f] elbow) - desired
	true
)

-- srcWorlds / srcParentWorlds: per target node, the world transform of its source bone and of
-- that bone's parent this frame (or undefined). follow: per target node, #(sourceWorld,
-- anchorSourceWorld, anchorTargetIndex) for followers this frame, or undefined.
-- Returns the target world transforms in rig order.
fn retargetSolveFrame ctx srcWorlds srcParentWorlds follow:undefined =
(
	local count = ctx.names.count
	local worlds = #()
	worlds.count = count
	local rotOverride = #()
	rotOverride.count = count
	local residuals = #()
	residuals.count = count

	for i = 1 to count do
	(
		local p = ctx.parents[i]
		local parentWorld = if p > 0 then worlds[p] else undefined
		local offset = ctx.offsets[i]
		local src = srcWorlds[i]
		local fw = if follow != undefined then follow[i] else undefined

		if fw != undefined and worlds[fw[3]] != undefined then
		(
			-- Follower: source placement relative to the anchor, moved with the target anchor
			local anchorSrc = fw[2]
			local ta = fw[3]
			local anchorPos = if residuals[ta] != undefined then anchorSrc.row4 + residuals[ta] else worlds[ta].row4
			worlds[i] = fw[1] * (inverse anchorSrc) * (retargetWithPosition (retargetRotationOnly anchorSrc) anchorPos)
		)
		else if offset == undefined or src == undefined then
		(
			-- Unmapped: keep the rest pose relative to the parent
			worlds[i] = if parentWorld == undefined then ctx.restWorld[i] else ctx.restLocal[i] * parentWorld
		)
		else if parentWorld == undefined then
		(
			-- Rig root: source rotation with the rest offset; position = source position plus the
			-- rest difference as a fixed world vector, like the Halo 5 tool
			local restPos = ctx.restWorld[i].row4
			local pos = src.row4 + ctx.rootDeltas[i]
			worlds[i] = retargetWithPosition (retargetRotationOnly (offset * src)) (restPos + (pos - restPos) * ctx.rootScale)
		)
		else
		(
			local rotMatrix = if rotOverride[i] != undefined then rotOverride[i] else retargetRotationOnly (offset * src)
			local pos = ctx.restLocal[i].row4 * parentWorld
			-- Plus how far the source bone moved from its rest place, in its parent's space
			local sp = srcParentWorlds[i]
			if ctx.copyTranslations and sp != undefined and ctx.sourceRestLocal[i] != undefined do
			(
				local srcLocal = src.row4 * (inverse sp)
				pos += (srcLocal - ctx.sourceRestLocal[i]) * (retargetRotationOnly sp)
			)
			worlds[i] = retargetWithPosition rotMatrix pos
		)

		if ctx.useIK do
			for chain in ctx.ikChains where chain[1] == i do
				retargetSolveChain ctx chain worlds srcWorlds rotOverride residuals
	)

	-- Adjust angles go on the final local rotations, so children (and a weapon on the hand)
	-- follow them, as when the bone is rotated by hand in 'Local' (same as the Halo 5 tool)
	if ctx.hasAdjusts do
	(
		local adjusted = #()
		adjusted.count = count
		for i = 1 to count do
		(
			local p = ctx.parents[i]
			local localTm = if p > 0 then worlds[i] * inverse worlds[p] else worlds[i]
			if ctx.adjusts[i] != undefined do localTm = ctx.adjusts[i] * localTm
			adjusted[i] = if p > 0 then localTm * adjusted[p] else localTm
		)
		worlds = adjusted
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
	local srcParentIdx = for s in ctx.sourceParentNames collect (if s == undefined then 0 else retargetFindName jmaNames s)
	if (for k in srcIdx where k > 0 collect k).count == 0 do
		return #(false, #("none of the mapped source bones are in this file"))
	local missing = #()
	for i = 1 to srcIdx.count where ctx.sourceNames[i] != undefined and srcIdx[i] == 0 do
		appendIfUnique missing ctx.sourceNames[i]
	if missing.count > 0 do
	(
		local text = "missing source bones, kept at the rest pose:"
		for m in missing do text += " '" + m + "'"
		append messages text
	)

	local camIdx = if ctx.cameraNode != "" then retargetFindName jmaNames ctx.cameraNode else 0
	local followers = retargetResolveFollowers ctx jmaNames parents
	local followCount = (for x in followers where x != undefined collect x).count
	if followCount > 0 do logger.info "{}: {} node(s) follow the animation (weapon)" args:#(filenameFromPath inPath, followCount)

	ctx.clampedFrames = 0
	local prevQuats = #()
	prevQuats.count = ctx.names.count
	local keyframes = for f = 1 to jma.frames.count collect
	(
		local jw = retargetJmaFrameWorlds jma f parents
		-- Remove camera motion: every pose relative to the camera node, like a fixed first person camera
		if camIdx > 0 do
		(
			local toCamera = inverse jw[camIdx]
			jw = for m in jw collect m * toCamera
		)
		local srcWorlds = for k in srcIdx collect (if k > 0 then jw[k] else undefined)
		local srcParentWorlds = for k in srcParentIdx collect (if k > 0 then jw[k] else undefined)
		local follow = for x in followers collect (if x == undefined then undefined else #(jw[x[1]], jw[x[2]], x[3]))
		retargetWorldsToKeyframe ctx (retargetSolveFrame ctx srcWorlds srcParentWorlds follow:follow) prevQuats
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
	local srcParentNodes = for s in ctx.sourceParentNames collect retargetNodeByName sourceRig s
	local tgtNodes = for n in ctx.names collect retargetNodeByName targetRig n
	for i = 1 to ctx.names.count do
	(
		if tgtNodes[i] == undefined do append messages ("Target bone '" + ctx.names[i] + "' is not in the scene rig")
		if ctx.sourceNames[i] != undefined and srcNodes[i] == undefined do
			append messages ("Source bone '" + ctx.sourceNames[i] + "' is not in the scene rig")
	)

	local sourceNames = for n in sourceRig collect n.name
	local sourceParents = for n in sourceRig collect (if n.parent == undefined then 0 else findItem sourceRig n.parent)
	local followers = retargetResolveFollowers ctx sourceNames sourceParents
	local camNode = if ctx.cameraNode == "" then undefined else retargetNodeByName sourceRig ctx.cameraNode
	if camNode == undefined and ctx.cameraNode != "" do camNode = getNodeByName ctx.cameraNode

	local startFrame = animationRange.start.frame as integer
	local endFrame = animationRange.end.frame as integer
	local total = endFrame - startFrame + 1
	ctx.clampedFrames = 0
	local frames = #()
	for f = startFrame to endFrame do
	(
		-- Remove camera motion: every pose relative to the camera node, like a fixed first person camera
		local toCamera = if camNode == undefined then matrix3 1 else inverse (at time f camNode.transform)
		local srcWorlds = for n in srcNodes collect (if n == undefined then undefined else (at time f n.transform) * toCamera)
		local srcParentWorlds = for n in srcParentNodes collect (if n == undefined then undefined else (at time f n.transform) * toCamera)
		local follow = for x in followers collect
			(if x == undefined then undefined else \
				#((at time f sourceRig[x[1]].transform) * toCamera, (at time f sourceRig[x[2]].transform) * toCamera, x[3]))
		append frames (retargetSolveFrame ctx srcWorlds srcParentWorlds follow:follow)
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
