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

-- Retarget preset: bone mapping (target <- source) plus the captured "match pose" of both rigs.
-- The match pose is what makes the retarget independent of bone axis conventions: every mapped
-- target bone keeps, over time, the same offset to its source bone it had in that pose.

-- A rig captured in Halo node order (parents first)
struct retargetRigPose
(
	names = #(),
	parents = #(),  -- 1-based parent index, 0 = rig root
	worlds = #()    -- matrix3 world transform at the match pose
)

struct retargetPreset
(
	sourceRoot = "",
	targetRoot = "",
	pairs = #(),       -- #(targetName, sourceName)
	rootScale = 1.0,
	sourcePose = undefined,
	targetPose = undefined
)

global RETARGET_PRESET_VERSION = 1

-------------------------------------------------------
-- NAMES
-------------------------------------------------------

-- Case-insensitive lookup (Halo node names are case-insensitive)
fn retargetFindName names nodeName =
(
	local lowered = toLower nodeName
	for i = 1 to names.count do
		if (toLower names[i]) == lowered do return i
	0
)

-- Canonical key used by the auto mapper, so differently named rigs line up:
--   "frame l index low" / "b_l_index1"  -> "l index 1"
--   "frame l wriste"    / "b_l_hand"    -> "l hand"
fn retargetBoneKey nodeName =
(
	local fingers = #("thumb", "index", "middle", "ring", "pinky")
	local raw = filterString (toLower nodeName) " _-."
	while raw.count > 1 and (findItem #("frame", "b", "bip01", "bone") raw[1]) > 0 do
		deleteItem raw 1

	local side = ""
	local tokens = #()
	for t in raw do
	(
		if t == "l" or t == "left" then side = "l"
		else if t == "r" or t == "right" then side = "r"
		else
		(
			-- Split glued finger segments: "index1", "pinky0", "middlelow"
			local split = false
			for f in fingers while not split do
			(
				if t.count > f.count and (substring t 1 f.count) == f do
				(
					append tokens f
					append tokens (substring t (f.count + 1) -1)
					split = true
				)
			)
			if not split do append tokens t
		)
	)

	for i = 1 to tokens.count do
	(
		tokens[i] = case tokens[i] of
		(
			"wriste": "hand"
			"wrist": "hand"
			"lowerarm": "forearm"
			"uparm": "upperarm"
			"low": "1"
			"mid": "2"
			"tip": "3"
			default: tokens[i]
		)
	)

	local key = side
	for t in tokens do key += " " + t
	trimLeft key
)

-- Whether the canonical key ends with suffix ("frame l wriste" ends with "hand")
fn retargetKeyEndsWith nodeName suffix =
(
	local key = retargetBoneKey nodeName
	key.count >= suffix.count and (substring key (key.count - suffix.count + 1) -1) == suffix
)

-------------------------------------------------------
-- MAPPING
-------------------------------------------------------

fn retargetGetSource preset targetName =
(
	local lowered = toLower targetName
	for p in preset.pairs do
		if (toLower p[1]) == lowered do return p[2]
	undefined
)

-- sourceName undefined removes the pair
fn retargetSetSource preset targetName sourceName =
(
	local lowered = toLower targetName
	for i = preset.pairs.count to 1 by -1 do
		if (toLower preset.pairs[i][1]) == lowered do deleteItem preset.pairs i
	if sourceName != undefined do append preset.pairs #(targetName, sourceName)
)

-- Both name lists in rig order, so index 1 is each rig's root and the roots always pair up.
-- Identical names win, then canonical keys. A source bone is used once.
fn retargetAutoMap targetNames sourceNames =
(
	local pairs = #()
	local used = #()
	local sourceKeys = for n in sourceNames collect retargetBoneKey n

	for i = 1 to targetNames.count do
	(
		local idx = 0
		if i == 1 and sourceNames.count > 0 then idx = 1
		else
		(
			idx = retargetFindName sourceNames targetNames[i]
			if idx > 0 and (findItem used idx) > 0 do idx = 0
			if idx == 0 do
			(
				local key = retargetBoneKey targetNames[i]
				for j = 1 to sourceKeys.count while idx == 0 do
					if sourceKeys[j] == key and (findItem used j) == 0 do idx = j
			)
		)
		if idx > 0 do
		(
			append pairs #(targetNames[i], sourceNames[idx])
			append used idx
		)
	)
	pairs
)

-- Same preset with source and target exchanged. The match pose is symmetric, so the
-- capture stays valid.
fn retargetSwapPreset preset =
(
	local swapped = retargetPreset sourceRoot:preset.targetRoot targetRoot:preset.sourceRoot \
		rootScale:preset.rootScale sourcePose:preset.targetPose targetPose:preset.sourcePose
	swapped.pairs = #()
	for p in preset.pairs do
		if (retargetGetSource swapped p[2]) == undefined do append swapped.pairs #(p[2], p[1])
	swapped
)

-------------------------------------------------------
-- PRESET FILES
-------------------------------------------------------

-- Presets live next to config.ini so plugin updates leave them alone
fn retargetPresetDir =
(
	local baseDir = if configManager.iniPath != undefined then getFilenamePath configManager.iniPath else (getDir #userScripts) + "\\"
	local dir = baseDir + "retarget_presets\\"
	if not doesDirectoryExist dir do makeDir dir all:true
	dir
)

fn retargetMatrixToString m =
(
	local s = ""
	for r in #(m.row1, m.row2, m.row3, m.row4) do
		for k = 1 to 3 do s += "\t" + (formatFloat r[k])
	s
)

fn retargetMatrixFromTokens tokens first =
(
	local v = for k = first to first + 11 collect (tokens[k] as float)
	matrix3 [v[1], v[2], v[3]] [v[4], v[5], v[6]] [v[7], v[8], v[9]] [v[10], v[11], v[12]]
)

fn retargetWritePoseLines fileStream tag pose =
(
	for i = 1 to pose.names.count do
	(
		local parentName = if pose.parents[i] > 0 then pose.names[pose.parents[i]] else "-"
		format "%\t%\t%%\n" tag pose.names[i] parentName (retargetMatrixToString pose.worlds[i]) to:fileStream
	)
)

fn retargetWritePreset filePath preset =
(
	local fileStream = createFile filePath
	if fileStream == undefined do return false
	format "# HCE Max Toolkit retarget preset\n" to:fileStream
	format "version\t%\n" RETARGET_PRESET_VERSION to:fileStream
	format "source_root\t%\n" preset.sourceRoot to:fileStream
	format "target_root\t%\n" preset.targetRoot to:fileStream
	format "root_scale\t%\n" (formatFloat preset.rootScale) to:fileStream
	for p in preset.pairs do format "map\t%\t%\n" p[1] p[2] to:fileStream
	if preset.sourcePose != undefined do retargetWritePoseLines fileStream "source_node" preset.sourcePose
	if preset.targetPose != undefined do retargetWritePoseLines fileStream "target_node" preset.targetPose
	close fileStream
	true
)

fn retargetAddPoseLine pose tokens =
(
	if tokens.count < 15 do return false
	append pose.names tokens[2]
	append pose.parents (if tokens[3] == "-" then 0 else retargetFindName pose.names tokens[3])
	append pose.worlds (retargetMatrixFromTokens tokens 4)
	true
)

fn retargetReadPreset filePath =
(
	local fileStream = openFile filePath mode:"r"
	if fileStream == undefined do return undefined
	local preset = retargetPreset()
	preset.pairs = #()
	local sourcePose = retargetRigPose()
	local targetPose = retargetRigPose()
	while not eof fileStream do
	(
		local line = readLine fileStream
		if line.count == 0 or line[1] == "#" do continue
		local tokens = filterString line "\t"
		case tokens[1] of
		(
			"source_root": if tokens.count > 1 do preset.sourceRoot = tokens[2]
			"target_root": if tokens.count > 1 do preset.targetRoot = tokens[2]
			"root_scale": if tokens.count > 1 do preset.rootScale = tokens[2] as float
			"map": if tokens.count > 2 do append preset.pairs #(tokens[2], tokens[3])
			"source_node": retargetAddPoseLine sourcePose tokens
			"target_node": retargetAddPoseLine targetPose tokens
		)
	)
	close fileStream
	if preset.rootScale == undefined do preset.rootScale = 1.0
	if sourcePose.names.count > 0 do preset.sourcePose = sourcePose
	if targetPose.names.count > 0 do preset.targetPose = targetPose
	preset
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
