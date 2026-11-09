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

-- GlyphFX Animation Preview: AnimationTime follows the scene time, and the viewport redraws
-- these materials on every frame (by itself it only does it with the Slate editor open).
-- Loaded at startup (shared\init.ms), after change_colors.ms (collectSubMaterials, glyphFxParamHolder).

-- A reload replaces the function: take the old one out first
try (unRegisterTimeCallback shaderAnimationTimeChanged) catch ()

-- What holds the preview params: the DirectX material, or the OSL map of an OSL material.
-- Filled on import and when a scene opens
global shaderAnimationMaterials = #()

-- AnimationPreview is a bool in the .fx effects and an int (0/1) in the OSL ones
fn shaderPreviewIsOn h = (local v = h.AnimationPreview; v == true or v == 1)
fn setShaderPreview h enable = h.AnimationPreview = if classOf h.AnimationPreview == Integer then (if enable then 1 else 0) else enable

-- The preview holders of these materials (and their sub-materials)
fn shaderPreviewHolders materials =
(
	local holders = #()
	for m in materials do
	(
		local h = glyphFxParamHolder m
		if isProperty h #AnimationPreview then appendIfUnique holders h
	)
	holders
)

-- Timeline length in seconds: frames start..end, the one after end being start again
fn shaderTimelineSeconds = ((animationRange.end - animationRange.start).frame + 1) / frameRate

-- "Loop to Timeline" is on when a material of the scene has a loop length
fn shaderAnimationLoopOn =
(
	local found = false
	for m in shaderAnimationMaterials where not found and isProperty m #AnimationLoopLength do found = m.AnimationLoopLength > 0
	found
)

-- On import (DirectX material or OSL map): AnimationTime = scene time in seconds, preview on,
-- Loop to Timeline as the scene has it. False for effects without it
fn connectShaderAnimation h =
(
	if not (isProperty h #AnimationTime) then return false
	local c = Float_Expression()
	c.setExpression "S"
	h.AnimationTime.controller = c
	setShaderPreview h true
	if isProperty h #AnimationLoopLength and shaderAnimationLoopOn() then h.AnimationLoopLength = shaderTimelineSeconds()
	appendIfUnique shaderAnimationMaterials h
	true
)

-- After open, merge, reset or new. Returns how many it found
fn findShaderAnimationMaterials =
(
	local materials = #()
	for m in sceneMaterials do collectSubMaterials m materials
	shaderAnimationMaterials = shaderPreviewHolders materials
	shaderAnimationMaterials.count
)

-- Preview holders of an object tag Point (its imported nodes) or of a mesh
fn objectPreviewMaterials obj =
(
	local nodes = if isObjectTagContainer obj then obj.memberNodes else #(obj)
	local materials = #()
	for n in nodes where isValidNode n and n.material != undefined do collectSubMaterials n.material materials
	shaderPreviewHolders materials
)

-- For the tag editor: #(preview on, A Out, B Out, C Out, D Out); the outs of the first one that
-- has them (plasma, water and environment don't), else 0. undefined: none
fn tagEditorPreviewState obj =
(
	local mats = objectPreviewMaterials obj
	if mats.count == 0 then return undefined
	local outs = #(0.0, 0.0, 0.0, 0.0)
	local withOuts = undefined
	for m in mats where withOuts == undefined and isProperty m #ObjectFunctionA do withOuts = m
	if withOuts != undefined then
		outs = #(withOuts.ObjectFunctionA, withOuts.ObjectFunctionB, withOuts.ObjectFunctionC, withOuts.ObjectFunctionD)
	#(shaderPreviewIsOn mats[1]) + outs
)

-- Sets "AnimationPreview" or "ObjectFunctionA"-"D" on the ones that have it. Not tag data: no undo
fn tagEditorSetPreview obj param value =
(
	local mats = objectPreviewMaterials obj
	local prop = param as name
	local count = 0
	with undo off
		for m in mats where isProperty m prop do
		(
			if prop == #AnimationPreview then setShaderPreview m value else setProperty m prop value
			notifyDependents m
			count += 1
		)
	redrawViews()
	count
)

-- Shaders tab "Loop to Timeline": on (timeline length) or off (0 = game speed) on every GlyphFX
-- material of the scene that has it. Returns how many
fn setShaderAnimationLoop enable =
(
	findShaderAnimationMaterials()
	local seconds = if enable then shaderTimelineSeconds() else 0.0
	local count = 0
	with undo off
		for m in shaderAnimationMaterials where isProperty m #AnimationLoopLength do
		(
			m.AnimationLoopLength = seconds
			notifyDependents m
			count += 1
		)
	redrawViews()
	count
)

-- Seconds of one cycle of a periodic function: cosine, diagonal wave and slide run 0.7 cycles per
-- period (period 0 = 1). undefined for one, zero and the random ones (no short cycle)
fn shaderFunctionCycle func period =
(
	if func != 2 and func != 4 and func != 6 then return undefined
	(if period == 0.0 then 1.0 else abs period) / 0.7
)

-- A linear move (per second, per axis) repeats every map repeat; slower axes than maxSeconds skipped
fn addShaderMoveCycles cycles perSecond maxSeconds =
(
	for v in perSecond where v != 0.0 and 1.0 / abs v <= maxSeconds do appendIfUnique cycles (1.0 / abs v)
)

-- Cycle lengths (seconds) of what moves in a preview holder, of any GlyphFX type
fn shaderAnimationCycles h maxSeconds =
(
	local cycles = #()
	local c
	-- Map U/V/rotation: maps 1-4 (generic, chicago) or one map (OSL), only with a scale
	for suffix in #("", "1", "2", "3", "4") do
		for axis in #("U", "V", "Rotation") do
		(
			local base = axis + "Animation"
			local func = (base + "Function" + suffix) as name
			local scaleProp = (base + "Scale" + suffix) as name
			if isProperty h func and isProperty h scaleProp and (getProperty h scaleProp) != 0.0 then
			(
				c = shaderFunctionCycle (getProperty h func) (getProperty h ((base + "Period" + suffix) as name))
				if c != undefined then appendIfUnique cycles c
			)
		)
	-- Model self-illumination, environment primary/secondary/plasma
	for base in #("SelfIllumination", "Primary", "Secondary", "Plasma") do
	(
		local func = (base + "AnimationFunction") as name
		if isProperty h func then
		(
			c = shaderFunctionCycle (getProperty h func) (getProperty h ((base + "AnimationPeriod") as name))
			if c != undefined then appendIfUnique cycles c
		)
	)
	-- Generic stage color0, unless A Out drives it
	for n = 1 to 7 do
	(
		local stage = "Stage" + (n as string) + "_"
		local func = (stage + "Color0AnimationFunction") as name
		if isProperty h func and not (getProperty h ((stage + "AOutControlsColor0Animation") as name)) then
		(
			c = shaderFunctionCycle (getProperty h func) (getProperty h ((stage + "Color0AnimationPeriod") as name))
			if c != undefined then appendIfUnique cycles c
		)
	)
	-- Plasma noise maps: direction / period
	for base in #("Primary", "Secondary") do
	(
		local dirI = (base + "AnimationDirectionI") as name
		local p = if isProperty h dirI then getProperty h ((base + "AnimationPeriod") as name) else 0.0
		if p != 0.0 then
		(
			local perSecond = #((getProperty h dirI) / p, (getProperty h ((base + "AnimationDirectionJ") as name)) / p, (getProperty h ((base + "AnimationDirectionK") as name)) / p)
			addShaderMoveCycles cycles perSecond maxSeconds
		)
	)
	-- Water ripples: velocity along the angle (degrees), only the ripples that are on
	if isProperty h #EnableRippleMaps and h.EnableRippleMaps then
		for base in #("Ripple", "Ripple0_", "Ripple1_", "Ripple2_", "Ripple3_") do
		(
			local active = base == "Ripple" or ((getProperty h (("EnableRipple" + base[7]) as name)) and (getProperty h ((base + "ContributionFactor") as name)) > 0.0)
			if active then
			(
				local v = getProperty h ((base + "AnimationVelocity") as name)
				local a = getProperty h ((base + "AnimationAngle") as name)
				addShaderMoveCycles cycles #(v * cos a, v * sin a) maxSeconds
			)
		)
	cycles
)

-- The largest speed change of these cycles in a loop of `seconds` (whole cycles, at least one)
fn shaderLoopError cycles seconds =
(
	local worst = 0.0
	for c in cycles do
	(
		local n = amax 1.0 (floor (seconds / c + 0.5))
		worst = amax worst (abs (n * c / seconds - 1.0))
	)
	worst
)

-- Shaders tab "Fit Timeline to Shader Animation": the timeline lasts the scene's longest cycle (game
-- speed), or the first multiple of it where the rest change speed by maxError at most (up to
-- maxFrames; else the closest). Then Loop to Timeline. Returns #(frames, shaders, error); frames 0 = none
fn fitTimelineToShaderAnimation maxFrames:600 maxError:0.05 =
(
	findShaderAnimationMaterials()
	local fps = frameRate as float
	local cycles = #()
	local count = 0
	for h in shaderAnimationMaterials where shaderPreviewIsOn h do
	(
		local own = shaderAnimationCycles h (maxFrames / fps)
		if own.count > 0 then count += 1
		for c in own do appendIfUnique cycles c
	)
	if cycles.count == 0 then return #(0, 0, 0.0)
	local longest = amax cycles
	local best = 0
	local bestError = 0.0
	local k = 1
	local done = false
	while not done do
	(
		local frames = amax 2 ((floor (k * longest * fps + 0.5)) as integer)
		if k > 1 and frames > maxFrames then done = true
		else
		(
			local err = shaderLoopError cycles (frames / fps)
			if best == 0 or err < bestError then (best = frames; bestError = err)
			if err <= maxError then done = true
			k += 1
		)
	)
	local start = animationRange.start.frame as integer
	animationRange = interval start (start + best - 1)
	setShaderAnimationLoop true
	#(best, count, bestError)
)

-- Time callback: only the ones with the preview on (isProperty: an older effect may be reloaded)
fn shaderAnimationTimeChanged =
(
	local seconds = undefined
	for m in shaderAnimationMaterials where isProperty m #AnimationPreview and shaderPreviewIsOn m do
	(
		-- Loop to Timeline follows a timeline that changed (e.g. an animation imported)
		if isProperty m #AnimationLoopLength and m.AnimationLoopLength > 0 then
		(
			if seconds == undefined then seconds = shaderTimelineSeconds()
			if abs (m.AnimationLoopLength - seconds) > 0.0001 then with undo off m.AnimationLoopLength = seconds
		)
		notifyDependents m
	)
)

registerTimeCallback shaderAnimationTimeChanged
callbacks.removeScripts id:#hceShaderAnimation
for e in #(#filePostOpen, #filePostMerge, #systemPostReset, #systemPostNew) do
	callbacks.addScript e "findShaderAnimationMaterials()" id:#hceShaderAnimation

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
