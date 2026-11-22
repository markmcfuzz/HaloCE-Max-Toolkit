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

-- The game's weapon inverse kinematics (object_inverse_kinematics, inverse_kinematics_adjust_matrices)
-- as keys: a marker of the unit (a hand) is put on a marker of its weapon by turning two bones.

-- The weapon Point an actor variant import gave the unit (import_actor_variant.ms)
fn actorVariantWeapon unitPoint =
(
	local handle = getUserProp unitPoint "hceVariantWeapon"
	if classOf handle != Integer then return undefined
	local weaponPoint = maxOps.getNodeByHandle handle
	if isObjectTagContainer weaponPoint then weaponPoint else undefined
)

-- The game's two-bone solver. Rows are forward, left, up, position. desired: where the hand
-- has to be. Returns #(shoulder, elbow, hand), or undefined when the arm can't be solved
fn solveArmIk desired shoulder elbow hand =
(
	local shoulderPos = shoulder.row4
	local target = desired.row4
	local upperArm = distance shoulderPos elbow.row4
	local forearm = distance elbow.row4 hand.row4
	local handDistance = distance target shoulderPos
	if handDistance < 0.0001 or upperArm < 0.0001 then return undefined
	local handDir = (target - shoulderPos) / handDistance
	-- The elbow bends in the plane it already was in
	local planeNormal = cross handDir (elbow.row4 - shoulderPos)
	if length planeNormal < 0.0001 then return undefined
	local bendDir = cross (normalize planeNormal) handDir

	-- The arm never gets fully straight
	local reach = (upperArm + forearm) * 0.98
	if reach < handDistance do
	(
		target = shoulderPos + handDir * reach
		handDistance = reach
	)
	local along = (handDistance * handDistance + upperArm * upperArm - forearm * forearm) / (2 * handDistance)
	local height = sqrt (amax 0.0 (upperArm * upperArm - along * along))

	local forward = normalize (along * handDir + height * bendDir)
	local up = normalize (cross forward shoulder.row2)
	local newShoulder = matrix3 forward (cross up forward) up shoulderPos
	local elbowPos = shoulderPos + forward * upperArm
	forward = normalize ((handDistance - along) * handDir - height * bendDir)
	up = normalize (cross forward elbow.row2)
	local newElbow = matrix3 forward (cross up forward) up elbowPos
	local newHand = copy desired
	newHand.row4 = target
	#(newShoulder, newElbow, newHand)
)

-- Bones of the unit's model that hang from a node, except one
fn ikOtherChildren parentNode except =
	for c in parentNode.children where c != except and inLayerKind c "Nodes" collect c

-- Keys on the timeline's frames so each unit marker follows its weapon marker ("a|b" lists of
-- names, the weapon class "ik points"). Returns how many pairs were found in the scene
fn actorWeaponIk unitPoint markerList attachList =
(
	if not (isObjectTagContainer unitPoint) then return 0
	local weaponPoint = actorVariantWeapon unitPoint
	if weaponPoint == undefined then return 0
	local markerNames = filterString markerList "|"
	local attachNames = filterString attachList "|"

	-- Per pair: #(hand marker, weapon marker, shoulder, elbow, hand node, bones that stay)
	local chains = #()
	for i = 1 to (amin markerNames.count attachNames.count) do
	(
		local handMarker = findTagMarker unitPoint markerNames[i]
		local weaponMarker = findTagMarker weaponPoint attachNames[i]
		local handNode = if handMarker != undefined then handMarker.parent else undefined
		local elbow = if handNode != undefined then handNode.parent else undefined
		local shoulder = if elbow != undefined then elbow.parent else undefined
		if weaponMarker != undefined and shoulder != undefined do
		(
			-- In the game the other bones don't follow the arm: they keep their place
			local others = (ikOtherChildren shoulder elbow) + (ikOtherChildren elbow handNode) + (ikOtherChildren handNode undefined)
			append chains #(handMarker, weaponMarker, shoulder, elbow, handNode, others)
		)
	)
	if chains.count == 0 then return 0

	with redraw off
	(
		with undo off
		(
			for f = (animationRange.start.frame as integer) to (animationRange.end.frame as integer) do at time f
			(
				for chain in chains do
				(
					local handTM = chain[5].transform
					-- Where the hand node is when its marker is on the weapon's
					local desired = handTM * (inverse chain[1].transform) * chain[2].transform
					local solved = solveArmIk desired chain[3].transform chain[4].transform handTM
					if solved != undefined do
					(
						local othersTM = for o in chain[6] collect o.transform
						with animate on
						(
							chain[3].transform = solved[1]
							chain[4].transform = solved[2]
							chain[5].transform = solved[3]
							for k = 1 to chain[6].count do chain[6][k].transform = othersTM[k]
						)
					)
				)
			)
		)
	)
	-- The IK rewrote the arms' keys (the held weapon is not a bone of the tag)
	local tagBones = animPlayerNodes unitPoint
	local ikBones = #()
	for chain in chains do
		for n in (#(chain[3], chain[4], chain[5]) + chain[6]) where findItem tagBones n > 0 do appendIfUnique ikBones n
	with redraw off (with undo off (for n in ikBones do boneKeysFixAngles n))
	redrawViews()
	chains.count
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
