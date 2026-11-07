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
-- Loaded at startup (shared\init.ms), after change_colors.ms (collectSubMaterials).

-- A reload replaces the function: take the old one out first
try (unRegisterTimeCallback shaderAnimationTimeChanged) catch ()

-- Materials with Animation Preview in the scene, filled on import and when a scene opens
global shaderAnimationMaterials = #()

-- On import: AnimationTime = scene time in seconds, preview on. False for effects without it
fn connectShaderAnimation dxMat =
(
	if not (isProperty dxMat #AnimationTime) then return false
	local c = Float_Expression()
	c.setExpression "S"
	dxMat.AnimationTime.controller = c
	dxMat.AnimationPreview = true
	appendIfUnique shaderAnimationMaterials dxMat
	true
)

-- After open, merge, reset or new. Returns how many it found
fn findShaderAnimationMaterials =
(
	shaderAnimationMaterials = #()
	for m in sceneMaterials do
	(
		local subs = collectSubMaterials m #()
		for s in subs where isProperty s #AnimationPreview do appendIfUnique shaderAnimationMaterials s
	)
	shaderAnimationMaterials.count
)

-- Materials with Animation Preview of an object tag Point (its imported nodes) or of a mesh
fn objectPreviewMaterials obj =
(
	local nodes = if isObjectTagContainer obj then obj.memberNodes else #(obj)
	local materials = #()
	for n in nodes where isValidNode n and n.material != undefined do collectSubMaterials n.material materials
	for m in materials where isProperty m #AnimationPreview collect m
)

-- For the tag editor: #(preview on, A Out, B Out, C Out, D Out) of the first one; undefined: none
fn tagEditorPreviewState obj =
(
	local mats = objectPreviewMaterials obj
	if mats.count == 0 then return undefined
	local m = mats[1]
	#(m.AnimationPreview, m.ObjectFunctionA, m.ObjectFunctionB, m.ObjectFunctionC, m.ObjectFunctionD)
)

-- Sets "AnimationPreview" or "ObjectFunctionA"-"D" on all of them. Not tag data: no undo
fn tagEditorSetPreview obj param value =
(
	local mats = objectPreviewMaterials obj
	local prop = param as name
	with undo off
		for m in mats do (setProperty m prop value; notifyDependents m)
	redrawViews()
	mats.count
)

-- Time callback: only the materials with the preview on (isProperty: an older .fx may be reloaded)
fn shaderAnimationTimeChanged =
(
	for m in shaderAnimationMaterials where isProperty m #AnimationPreview and m.AnimationPreview do notifyDependents m
)

registerTimeCallback shaderAnimationTimeChanged
callbacks.removeScripts id:#hceShaderAnimation
for e in #(#filePostOpen, #filePostMerge, #systemPostReset, #systemPostNew) do
	callbacks.addScript e "findShaderAnimationMaterials()" id:#hceShaderAnimation

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
