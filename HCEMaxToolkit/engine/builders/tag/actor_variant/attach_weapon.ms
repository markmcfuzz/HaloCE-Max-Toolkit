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

-- Puts a weapon in a unit's hand like the game does (object_attach_to_marker): the weapon's
-- grip marker goes on the unit's hand marker and the weapon follows the hand's node.

-- Marker of an imported object tag by name (no "#"), ignoring case; undefined when missing
fn findTagMarker container markerName =
(
	if markerName == "" then return undefined
	local found = undefined
	for n in container.modelNodes where found == undefined and isValidNode n and inLayerKind n "Markers" do
		if stricmp n.name ("#" + markerName) == 0 do found = n
	found
)

-- First node of the model (the root of its skeleton); undefined when it has none
fn findTagRootNode container =
(
	local found = undefined
	for n in container.modelNodes where found == undefined and isValidNode n and inLayerKind n "Nodes" do
		if n.parent == undefined do found = n
	found
)

-- unitPoint, weaponPoint: Points of imported object tags. Returns the node the weapon hangs from,
-- or undefined when the unit has no nodes
fn attachWeaponToUnit unitPoint weaponPoint handMarker gripMarker =
(
	-- Like the game, a missing marker means the first node (the weapon's is at the origin)
	local hand = findTagMarker unitPoint handMarker
	local handNode = if hand != undefined then hand.parent else findTagRootNode unitPoint
	if handNode == undefined then return undefined
	local handTM = if hand != undefined then hand.transform else handNode.transform
	local grip = findTagMarker weaponPoint gripMarker
	local gripTM = if grip != undefined then grip.transform else matrix3 1
	local moveTM = (inverse gripTM) * handTM

	-- Skinned meshes follow their bones, moving them too would move them twice
	for n in weaponPoint.memberNodes where isValidNode n and n.parent == undefined and n.modifiers[#Skin] == undefined do
	(
		n.transform = n.transform * moveTM
		n.parent = handNode
	)
	-- Its Point stays in haloCE.Object and follows the hand, with its physics and bounding radius
	local pointTM = weaponPoint.transform * moveTM
	local follow = Link_Constraint()
	weaponPoint.transform.controller = follow
	follow.addTarget handNode (animationRange.start.frame as integer)
	weaponPoint.transform = pointTM
	handNode
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
