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

-- Container of an imported object tag: a Point helper holding every tag field as text; they are
-- edited in the Qt tag editor (tag_editor.ms). It is the parent of its dummies only (physics,
-- bounding radius): the JMS exporter needs the frame root without a parent.

-- haloTagAttributeDef
fileIn (rootEngine + "builders\\tag\\object\\object_tag_ca.ms")

-- Highest node handle in the scene; nodes created later have higher ones
fn getLastNodeHandle =
(
	local lastHandle = 0
	for o in objects do lastHandle = amax lastHandle o.inode.handle
	lastHandle
)

-- Nodes created between two getLastNodeHandle calls
fn getNodesBetweenHandles firstHandle lastHandle =
	for o in objects where o.inode.handle > firstHandle and o.inode.handle <= lastHandle collect o

-- data: ObjectTagData (lua_reader.ms), memberNodes: what it imported, without its dummies
-- parts: #(model nodes, collision nodes)
fn createObjectContainer data tagPath memberNodes parts:#(#(), #()) =
(
	local container = Point name:(filenameFromPath tagPath) size:30 box:true cross:false \
		axistripod:false centermarker:false constantscreensize:true drawontop:true wirecolor:(color 80 230 40)
	custAttributes.add container haloTagAttributeDef
	local tagAttributes = custAttributes.get container haloTagAttributeDef
	tagAttributes.tagGroup = data.group
	tagAttributes.tagFile = tagPath
	tagAttributes.fieldKeys = data.keys
	tagAttributes.fieldValues = data.values
	tagAttributes.memberNodes = memberNodes
	tagAttributes.modelNodes = parts[1]
	tagAttributes.collisionNodes = parts[2]
	tagAttributes.partsVersion = 2
	placeObjectPoint container
	container
)

-- After an import: its dummies under the Point and everything in the layers of its type.
-- physicsPoint: undefined when it has none
fn organizeObjectParts container physicsPoint radiusHelper =
(
	if physicsPoint != undefined do placePhysicsPoint physicsPoint container
	placeBoundingRadius radiusHelper container
	moveToObjectLayers container.memberNodes container.tagGroup
	deleteEmptyImportLayers()
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
