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

-- Writes animation keys on bones, fast and without false turns between frames.
-- Used by the Animation Player, the JMA importer and the weapon IK.

fn boneKeysQuatDot a b = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w

-- True when the rotation controller's value is the inverse of "in coordsys parent rotation".
-- Checked on the node where the two differ most, not assumed
fn boneKeysInverted nodes =
(
	local inverted = true
	local clearest = 0.0
	for n in nodes where n != undefined do
	(
		local parentRot = in coordsys parent n.rotation
		local ctrlRot = n.rotation.controller.value
		local same = abs (boneKeysQuatDot parentRot ctrlRot)
		local opposite = abs (boneKeysQuatDot parentRot (inverse ctrlRot))
		if abs (same - opposite) > clearest do
		(
			clearest = abs (same - opposite)
			inverted = opposite > same
		)
	)
	inverted
)

-- The same angle, give or take full turns, closest to prevAngle
fn boneKeysNearAngle a prevAngle = a + 360.0 * floor ((prevAngle - a) / 360.0 + 0.5)

fn boneKeysAngleDistance a b = abs (a[1] - b[1]) + abs (a[2] - b[2]) + abs (a[3] - b[3])

fn boneKeysSetAngles c angles =
(
	c.x_rotation = angles[1]
	c.y_rotation = angles[2]
	c.z_rotation = angles[3]
)

-- Rewrites this key with the angles closest to the previous frame, same pose. Returns them.
-- With Y at 90 degrees X and Z turn alike: X can stay still and Z takes the whole turn
fn boneKeysCloseAngles c prev =
(
	local a = #(c.x_rotation, c.y_rotation, c.z_rotation)
	local best = #(boneKeysNearAngle a[1] prev[1], boneKeysNearAngle a[2] prev[2], boneKeysNearAngle a[3] prev[3])
	local bestDistance = boneKeysAngleDistance best prev
	if bestDistance >= 30.0 then
	(
		local pose = c.value
		local turn = prev[1] - a[1]
		local options = #( \
			#(boneKeysNearAngle (a[1] + 180.0) prev[1], boneKeysNearAngle (180.0 - a[2]) prev[2], boneKeysNearAngle (a[3] + 180.0) prev[3]), \
			#(prev[1], best[2], boneKeysNearAngle (a[3] + turn) prev[3]), \
			#(prev[1], best[2], boneKeysNearAngle (a[3] - turn) prev[3]))
		for option in options where boneKeysAngleDistance option prev < bestDistance do
		(
			boneKeysSetAngles c option
			if abs (boneKeysQuatDot c.value pose) > 0.999999 do
			(
				best = option
				bestDistance = boneKeysAngleDistance option prev
			)
		)
		boneKeysSetAngles c best
	)
	else if boneKeysAngleDistance best a > 0.0 do boneKeysSetAngles c best
	best
)

-- Same poses on every frame, without false turns between keys.
-- c is a copy outside the scene: on the bone each write would update all its children
fn boneKeysKeepAngles c =
(
	if classOf c != Euler_XYZ then return ok
	local first = animationRange.start.frame as integer
	local last = animationRange.end.frame as integer
	with animate on
	(
		local prev = (at time first #(c.x_rotation, c.y_rotation, c.z_rotation))
		for f = first + 1 to last do at time f (prev = boneKeysCloseAngles c prev)
	)
	ok
)

-- For keys already on a bone (the weapon IK's)
fn boneKeysFixAngles n =
(
	if classOf n.rotation.controller != Euler_XYZ then return ok
	local fixed = copy n.rotation.controller
	for f = (animationRange.start.frame as integer) to (animationRange.end.frame as integer) do
		addNewKey fixed f
	boneKeysKeepAngles fixed
	n.rotation.controller = fixed
	ok
)

-- Replaces a bone's keys from frame 0. One value per frame: rotations as "in coordsys parent"
-- takes them, positions and uniform scales. inverted: from boneKeysInverted
fn boneKeysWrite n rotations positions scales inverted =
(
	deleteKeys n.controller #allKeys
	-- On copies outside the scene: each key on the bone would update all its children
	local rotationCtrl = copy n.rotation.controller
	local positionCtrl = copy n.position.controller
	local scaleCtrl = copy n.scale.controller
	local scaled = false
	for s in scales while not scaled do scaled = abs (s - 1.0) > 0.0001
	with animate on
		for fr = 1 to rotations.count do at time (fr - 1)
		(
			-- A key on every frame, also where a value holds still
			addNewKey rotationCtrl (fr - 1)
			addNewKey positionCtrl (fr - 1)
			if scaled do addNewKey scaleCtrl (fr - 1)
			rotationCtrl.value = if inverted then inverse rotations[fr] else rotations[fr]
			positionCtrl.value = positions[fr]
			if scaled do scaleCtrl.value = [1, 1, 1] * scales[fr]
		)
	if not scaled do scaleCtrl.value = [1, 1, 1]
	boneKeysKeepAngles rotationCtrl
	n.rotation.controller = rotationCtrl
	n.position.controller = positionCtrl
	n.scale.controller = scaleCtrl
	ok
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
