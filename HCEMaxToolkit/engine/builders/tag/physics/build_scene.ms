------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

-- Container of an imported physics tag: a Point holding every tag field as text (edited in the
-- Qt tag editor, like an object tag) and parent of one sphere per mass point.

-- haloTagAttributeDef
fileIn (rootEngine + "builders\\tag\\object\\object_tag_ca.ms")
-- reconcilePhysicsMassPoints
fileIn (rootEngine + "builders\\tag\\physics\\mass_points.ms")

-- data: PhysicsTagData (lua_reader.ms); modelNodes: the model's nodes in tag order, undefined =
-- those of the last model imported; owner: its object's Point (undefined = in haloCE.Object).
-- Returns the Point; its spheres are in physicsNodes
fn createPhysicsContainer data tagPath modelNodes:undefined owner:undefined =
(
	if modelNodes == undefined do modelNodes = sceneModelNodes()
	local container = Point name:(filenameFromPath tagPath) size:30 box:false cross:false \
		axistripod:true centermarker:false constantscreensize:true drawontop:true wirecolor:(color 255 150 0)
	custAttributes.add container haloTagAttributeDef
	local tagAttributes = custAttributes.get container haloTagAttributeDef
	tagAttributes.tagGroup = "physics"
	tagAttributes.tagFile = tagPath
	tagAttributes.fieldKeys = data.keys
	tagAttributes.fieldValues = data.values
	tagAttributes.partsVersion = 2
	placePhysicsPoint container owner
	-- Spheres follow their model node (the tag says which one) from its pose now
	tagAttributes.modelNodes = modelNodes
	storePhysicsNodeRests container
	-- No fields before: every mass point gets a new sphere
	reconcilePhysicsMassPoints container #() #()
	container
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
