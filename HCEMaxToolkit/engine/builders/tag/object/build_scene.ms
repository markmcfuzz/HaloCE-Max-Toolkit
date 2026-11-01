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

-- Container of an imported object tag: a Point helper with the tag panel (lua\bridge\tag_ui.lua).
-- It is not the parent of what it contains: the JMS exporter needs the frame root without a parent.

-- Highest node handle in the scene; nodes created later have higher ones
fn getLastNodeHandle =
(
	local lastHandle = 0
	for o in objects do lastHandle = amax lastHandle o.inode.handle
	lastHandle
)

fn getNodesAfterHandle lastHandle = for o in objects where o.inode.handle > lastHandle collect o

-- data: ObjectTagData (lua_reader.ms), attributeDef: the panel, memberNodes: what was imported
fn createObjectContainer data tagPath attributeDef memberNodes =
(
	local container = Point name:(filenameFromPath tagPath) size:30 box:true cross:false \
		axistripod:false centermarker:false wirecolor:(color 255 200 0)
	custAttributes.add container attributeDef
	local tagAttributes = custAttributes.get container attributeDef
	tagAttributes.tagGroup = data.group
	tagAttributes.tagFile = tagPath
	tagAttributes.fieldKeys = data.keys
	tagAttributes.fieldValues = data.values
	tagAttributes.memberNodes = memberNodes
	container
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
