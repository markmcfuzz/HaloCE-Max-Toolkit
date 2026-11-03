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

-- Animation Player (engine\core\tag_editor\player.py): every animation of a model_animations
-- tag is decoded once by lua\importers\animation_player.lua; a picked one goes as keys on the
-- bones of an object tag Point's model. Loaded by tag_editor.ms (uses tagRefNodes).

struct AnimPlayerTagData (tagPath, modDate, dataPath, nodeNames, names, exts, frameCounts, nodeCounts, offsets)
global animPlayerTag

-- Decodes the tag (one LuaJIT run), unless it is the one already loaded. Returns an
-- AnimPlayerTagData (also in animPlayerTag), or undefined on error (see the log)
fn animPlayerLoadTag tagPath =
(
	local modDate = getFileModDate tagPath
	if animPlayerTag != undefined and animPlayerTag.tagPath == tagPath and animPlayerTag.modDate == modDate \
		and doesFileExist animPlayerTag.dataPath then return animPlayerTag
	animPlayerTag = undefined
	local f = luaExportTag "animation_player" 1 tagPath
	if f == undefined then return undefined
	local nodeCount = luaReadInt f
	local nodeNames = for i = 1 to nodeCount collect readString f
	local count = luaReadInt f
	local names = #()
	local exts = #()
	local frameCounts = #()
	local nodeCounts = #()
	for i = 1 to count do
	(
		append names (readString f)
		append exts (readString f)
		append frameCounts (luaReadInt f)
		append nodeCounts (luaReadInt f)
	)
	local messageCount = luaReadInt f
	for i = 1 to messageCount do
	(
		local level = luaReadInt f
		local text = readString f
		if level >= 2 then logger.warn "{}" args:#(text) else logger.debug "{}" args:#(text)
	)
	-- The poses follow: 8 floats (32 bytes) per node and frame
	local offsets = #()
	local offset = ftell f
	for i = 1 to count do
	(
		append offsets offset
		offset += frameCounts[i] * nodeCounts[i] * 32
	)
	fclose f
	animPlayerTag = AnimPlayerTagData tagPath:tagPath modDate:modDate dataPath:(luaExportPath "animation_player") \
		nodeNames:nodeNames names:names exts:exts frameCounts:frameCounts nodeCounts:nodeCounts offsets:offsets
)

-- Poses of animation i: #(positions, rotations, scales), each per node then frame. Rotations
-- as "in coordsys parent node.rotation" takes them (i, j, k negated, as the JMA importer does)
fn animPlayerRead i =
(
	local data = animPlayerTag
	local frameCount = data.frameCounts[i]
	local nodeCount = data.nodeCounts[i]
	local positions = for n = 1 to nodeCount collect #()
	local rotations = for n = 1 to nodeCount collect #()
	local scales = for n = 1 to nodeCount collect #()
	local f = fopen data.dataPath "rb"
	if f == undefined then return undefined
	fseek f data.offsets[i] #seek_set
	for fr = 1 to frameCount do
		for n = 1 to nodeCount do
		(
			local x = readFloat f
			local y = readFloat f
			local z = readFloat f
			append positions[n] [x, y, z]
			local qi = readFloat f
			local qj = readFloat f
			local qk = readFloat f
			local qw = readFloat f
			append rotations[n] (quat (-qi) (-qj) (-qk) qw)
			append scales[n] (readFloat f)
		)
	fclose f
	#(positions, rotations, scales)
)

-- The Point's model bones for each tag node, by name (undefined when missing or not PRS).
-- Only that model: another object in the scene can have bones with the same names
fn animPlayerNodes obj =
(
	local byName = #()
	local modelNodes = #()
	for n in tagRefNodes obj "model" do
	(
		append byName (toLower n.name)
		append modelNodes n
	)
	for nodeName in animPlayerTag.nodeNames collect
	(
		local i = findItem byName (toLower nodeName)
		if i > 0 and classOf modelNodes[i].controller == prs then modelNodes[i] else undefined
	)
)

fn animPlayerQuatDot a b = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w

-- True when the rotation controller's value is the inverse of "in coordsys parent rotation".
-- Checked on the node where the two differ most, not assumed
fn animPlayerControllerInverted nodes =
(
	local inverted = true
	local clearest = 0.0
	for n in nodes where n != undefined do
	(
		local parentRot = in coordsys parent n.rotation
		local ctrlRot = n.rotation.controller.value
		local same = abs (animPlayerQuatDot parentRot ctrlRot)
		local opposite = abs (animPlayerQuatDot parentRot (inverse ctrlRot))
		if abs (same - opposite) > clearest do
		(
			clearest = abs (same - opposite)
			inverted = opposite > same
		)
	)
	inverted
)

-- Pose and timeline before the player first touched a Point's bones, for Stop.
-- Per Point handle: #(nodes, rotations, positions, scales, animation range, slider time)
global animPlayerRestHandles = #()
global animPlayerRestPoses = #()

fn animPlayerSaveRest obj nodes =
(
	if findItem animPlayerRestHandles obj.inode.handle > 0 then return ok
	local kept = for n in nodes where n != undefined collect n
	local rotations = for n in kept collect n.rotation.controller.value
	local positions = for n in kept collect n.position.controller.value
	local scales = for n in kept collect n.scale.controller.value
	append animPlayerRestHandles obj.inode.handle
	append animPlayerRestPoses #(kept, rotations, positions, scales, animationRange, sliderTime)
)

-- Handles are reused by the next scene
callbacks.removeScripts id:#hceAnimPlayer
for e in #(#filePostOpen, #systemPostReset, #systemPostNew) do
	callbacks.addScript e "animPlayerRestHandles = #(); animPlayerRestPoses = #()" id:#hceAnimPlayer

-- Keys of animation i (1-based) on the Point's bones from frame 0, replacing theirs (not
-- undoable). Returns the time it took in ms, or -1 when it can't be applied
fn animPlayerApply obj i =
(
	local data = animPlayerTag
	if data == undefined or not (isObjectTagContainer obj) or i < 1 or i > data.names.count then return -1
	local frameCount = data.frameCounts[i]
	if frameCount == 0 then return -1
	local startTime = timestamp()
	local poses = animPlayerRead i
	local nodes = animPlayerNodes obj
	if poses == undefined then return -1
	animPlayerSaveRest obj nodes
	local inverted = animPlayerControllerInverted nodes
	stopAnimation()
	with redraw off
	(
		with undo off
		(
			frameRate = 30
			animationRange = interval 0 (frameCount - 1)
			for n = 1 to data.nodeCounts[i] where nodes[n] != undefined do
			(
				local sceneNode = nodes[n]
				deleteKeys sceneNode.controller #allKeys
				-- Straight on the PRS controllers (no coordsys work per key)
				local rotationCtrl = sceneNode.rotation.controller
				local positionCtrl = sceneNode.position.controller
				local scaleCtrl = sceneNode.scale.controller
				local rotations = poses[2][n]
				local scaled = false
				for s in poses[3][n] while not scaled do scaled = abs (s - 1.0) > 0.0001
				with animate on
					for fr = 1 to frameCount do at time (fr - 1)
					(
						rotationCtrl.value = if inverted then inverse rotations[fr] else rotations[fr]
						positionCtrl.value = poses[1][n][fr]
						if scaled do scaleCtrl.value = [1, 1, 1] * poses[3][n][fr]
					)
				if not scaled do scaleCtrl.value = [1, 1, 1]
			)
		)
	)
	sliderTime = 0
	redrawViews()
	timestamp() - startTime
)

-- Removes the player's keys and puts the bones and timeline of rest entry i back
fn animPlayerRestore i =
(
	local rest = animPlayerRestPoses[i]
	with redraw off
	(
		with undo off
		(
			for k = 1 to rest[1].count where isValidNode rest[1][k] do
			(
				local n = rest[1][k]
				deleteKeys n.controller #allKeys
				n.rotation.controller.value = rest[2][k]
				n.position.controller.value = rest[3][k]
				n.scale.controller.value = rest[4][k]
			)
			animationRange = rest[5]
			sliderTime = rest[6]
		)
	)
	deleteItem animPlayerRestHandles i
	deleteItem animPlayerRestPoses i
	redrawViews()
	true
)

-- Stop: back to how the bones were before the player first played on this Point.
-- Returns false when there was nothing to restore
fn animPlayerStop obj =
(
	stopAnimation()
	if not (isValidNode obj) then return false
	local i = findItem animPlayerRestHandles obj.inode.handle
	if i == 0 then return false
	animPlayerRestore i
)

-- When the player closes: every Point it played on, also ones deleted meanwhile (their
-- bones are kept in the entry). Returns how many were restored
fn animPlayerStopAll =
(
	stopAnimation()
	local count = animPlayerRestPoses.count
	-- Last to first: the timeline ends as it was before the first one
	for i = count to 1 by -1 do animPlayerRestore i
	count
)

-- For the panel: #(tag name, names, exts, frame counts, bones found, tag node count), or the
-- error text
fn animPlayerOpen obj tagPath =
(
	if not (isObjectTagContainer obj) then return "The object tag Point is gone"
	if not (doesFileExist tagPath) then return ("Tag not found: " + tagPath)
	local data = animPlayerLoadTag tagPath
	if data == undefined then return "Could not read the animations (see the Max log)"
	local found = 0
	for n in animPlayerNodes obj where n != undefined do found += 1
	#(filenameFromPath tagPath, data.names, data.exts, data.frameCounts, found, data.nodeNames.count)
)

-- Playback, on Max's own timeline. The panel reads this a few times per second:
-- #(current frame, first frame, last frame, playing)
fn animPlayerTimeState = #(sliderTime.frame as integer, animationRange.start.frame as integer, \
	animationRange.end.frame as integer, isAnimPlaying())

fn animPlayerSetFrame f = sliderTime = f

-- speedIndex: 1 = 1/4x, 2 = 1/2x, 3 = 1x, 4 = 2x, 5 = 4x (Max's real-time playback speeds)
fn animPlayerPlay loop speedIndex =
(
	timeConfiguration.realTimePlayback = true
	timeConfiguration.playbackLoop = loop
	timeConfiguration.playbackSpeed = speedIndex
	-- From the start when a non-looping animation already reached its end
	if not loop and sliderTime >= animationRange.end do sliderTime = animationRange.start
	playAnimation immediateReturn:true
)

fn animPlayerPause = stopAnimation()

-- Loop and speed changed while playing apply right away
fn animPlayerSetPlayback loop speedIndex =
(
	timeConfiguration.playbackLoop = loop
	timeConfiguration.playbackSpeed = speedIndex
)

-- Extraction, by the Extract Animations tool (lua\importers\model_animations.lua)
fileIn (rootEngine + "pipeline\\extract_model_animations\\animation_extractor.ms")

-- "D:\halo\tags\characters\cyborg\cyborg.model_animations" -> "D:\halo\data\characters\cyborg\animations"
fn animPlayerDataFolder tagPath =
(
	local p = substituteString tagPath "/" "\\"
	local tagsAt = findString (toLower p) "\\tags\\"
	if tagsAt == undefined then return undefined
	(substring p 1 tagsAt) + "data\\" + (substring (getFilenamePath p) (tagsAt + 6) -1) + "animations"
)

-- Last folder picked in "Extract to..."
global animPlayerExtractDir

-- indexText: "3,7,12" (1-based). toData: to the tag's data folder, else asks for one.
-- Returns the folder, "" when cancelled, or undefined on error (see the log)
fn animPlayerExtract tagPath indexText toData =
(
	local folder = animPlayerDataFolder tagPath
	if not toData do
	(
		local start = if animPlayerExtractDir != undefined then animPlayerExtractDir else folder
		folder = getSavePath caption:"Extract the animations to" initialDir:start
		if folder == undefined then return ""
		animPlayerExtractDir = folder
	)
	if folder == undefined then return undefined
	if extractModelAnimations tagPath outputDir:folder only:indexText then folder else undefined
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
