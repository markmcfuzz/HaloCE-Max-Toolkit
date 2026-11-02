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

-- Custom attribute of an object tag Point: every tag field as text plus the scene nodes that
-- belong to it. Evaluating it again updates the Points of scenes saved with an older version.

-- Same id always, so saved scenes keep working when this definition changes
global haloTagAttributeDef = attributes "Halo Object Tag" attribID:#(0x4A7C1E35, 0x2D9B6F08)
(
	parameters tagParams
	(
		tagGroup type:#string default:""
		tagFile type:#string default:""
		fieldKeys type:#stringTab tabSizeVariable:true
		fieldValues type:#stringTab tabSizeVariable:true
		-- Everything imported or linked (Select Contents, change colors, bounding radius helper)
		memberNodes type:#nodeTab tabSizeVariable:true
		-- Nodes of each reference, imported or linked by hand (eye and link buttons)
		modelNodes type:#nodeTab tabSizeVariable:true
		collisionNodes type:#nodeTab tabSizeVariable:true
		physicsNodes type:#nodeTab tabSizeVariable:true
		-- 0: Point from before the lists above, they are filled from the layers once
		partsVersion type:#integer default:0
	)

	-- No buttons here: this rollout is saved in the .max and Max blocks Python started from it.
	-- Selecting the Point opens the tag editor, which has Select Contents.
	rollout tagRollout "Halo Tag"
	(
		edittext tagFileBox "Tag file" labelOnTop:true readOnly:true
		label editorLabel "Edit it in the Halo Tag Editor tab"
		on tagRollout open do tagFileBox.text = tagFile
	)
)
