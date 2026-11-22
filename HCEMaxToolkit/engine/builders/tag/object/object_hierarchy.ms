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

-- Organizes the tag dummies: haloCE.Object > object > its physics and bounding radius, and the
-- "Halo Object" layers. Model nodes are never linked: the JMS exporter needs a root without parent.

global haloObjectGroups = #("biped", "vehicle", "weapon", "scenery", "device_machine")
global haloObjectTypes = #("Biped", "Vehicle", "Weapon", "Scenery", "Device Machine")
global haloObjectPartKinds = #("Nodes", "Markers", "Geometry Model", "Collision Model", "Pathfinding Spheres", "Physics")

-- "Vehicle Nodes" -> "Nodes": Max layer names are unique, so each object type has its own
fn baseLayerName layerName =
(
	local base = layerName
	for t in haloObjectTypes while base == layerName do
		if matchPattern layerName pattern:(t + " *") do base = substring layerName (t.count + 2) -1
	base
)

fn inLayerKind n kind = baseLayerName n.layer.name == kind

-- The layer with that name inside parentLayer (undefined = where it is), created if missing
fn haloLayer layerName parentLayer =
(
	local found = LayerManager.getLayerFromName layerName
	if found == undefined do found = LayerManager.newLayerFromName layerName
	if parentLayer != undefined do
	(
		local currentParent = found.getParent()
		if currentParent == undefined or currentParent.name != parentLayer.name do found.setParent parentLayer
	)
	found
)

fn haloObjectLayer = haloLayer "Halo Object" undefined

fn objectTypeName tagGroup = haloObjectTypes[findItem haloObjectGroups tagGroup]

fn objectTypeLayer tagGroup = haloLayer (objectTypeName tagGroup) (haloObjectLayer())

-- "Vehicle Nodes" inside "Vehicle Gbxmodel", "Vehicle Physics" inside "Vehicle"...
fn objectPartLayer tagGroup kind =
(
	local typeName = objectTypeName tagGroup
	local parentLayer = objectTypeLayer tagGroup
	if findItem #("Nodes", "Markers", "Geometry Model") kind > 0 then
		parentLayer = haloLayer (typeName + " Gbxmodel") parentLayer
	else if findItem #("Collision Model", "Pathfinding Spheres") kind > 0 do
		parentLayer = haloLayer (typeName + " Collision") parentLayer
	haloLayer (typeName + " " + kind) parentLayer
)

-- The scene's one haloCE.Object; locked because the model doesn't follow it
fn haloObjectRoot =
(
	local root = getNodeByName "haloCE.Object"
	if not (isValidNode root) do
	(
		root = Point name:"haloCE.Object" size:30 box:false cross:true axistripod:false \
			centermarker:false constantscreensize:true drawontop:true wirecolor:(color 255 255 255)
		(haloObjectLayer()).addNode root
		setTransformLockFlags root #all
	)
	root
)

fn placeObjectPoint tagPoint =
(
	tagPoint.parent = haloObjectRoot()
	(objectTypeLayer tagPoint.tagGroup).addNode tagPoint
	setTransformLockFlags tagPoint #all
)

-- owner: its object's Point; undefined = directly in haloCE.Object. Spheres keep their parents
fn placePhysicsPoint physicsPoint owner =
(
	physicsPoint.parent = if owner != undefined then owner else haloObjectRoot()
	local physicsLayer = if owner != undefined then objectPartLayer owner.tagGroup "Physics" \
		else haloLayer "Physics" (haloObjectLayer())
	physicsLayer.addNode physicsPoint
	for n in physicsPoint.physicsNodes where isValidNode n do physicsLayer.addNode n
)

fn placeBoundingRadius h owner =
(
	h.parent = owner
	(objectPartLayer owner.tagGroup "Bounding Radius").addNode h
)

-- Moves what the importers left in their plain layers to those of the object's type
fn moveToObjectLayers nodes tagGroup =
(
	local layers = Dictionary #string
	for n in nodes where isValidNode n do
	(
		local kind = baseLayerName n.layer.name
		if findItem haloObjectPartKinds kind > 0 do
		(
			if not (hasDictValue layers kind) do layers[kind] = objectPartLayer tagGroup kind
			layers[kind].addNode n
		)
	)
)

-- The plain layers an object import emptied
fn deleteEmptyImportLayers =
(
	for kind in haloObjectPartKinds do
	(
		local found = LayerManager.getLayerFromName kind
		if found != undefined and not found.current and found.getNumChildren() == 0 do
		(
			local layerNodes
			found.nodes &layerNodes
			if layerNodes.count == 0 do LayerManager.deleteLayerByName kind
		)
	)
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
