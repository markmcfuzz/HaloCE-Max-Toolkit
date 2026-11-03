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

-- LOD meshes of an object's model, named "<region> <permutation> <lod>" by the gbxmodel
-- importer. Each permutation keeps its best LOD visible; the others are "LODs" in the editor.

-- 1 = superhigh ... 5 = superlow; 0 = not a LOD mesh
fn modelLodRank n =
(
	local words = filterString n.name " "
	if words.count == 0 then 0 else findItem #("superhigh", "high", "medium", "low", "superlow") words[words.count]
)

-- The LOD meshes that are not the best of their permutation (superhigh, or the best it has)
fn modelLowerLods modelNodes =
(
	local prefixes = #()
	local best = #()
	local lodMeshes = for n in modelNodes where isValidNode n and n.layer.name == "Geometry Model" and modelLodRank n > 0 collect n
	for n in lodMeshes do
	(
		local words = filterString n.name " "
		local prefix = substring n.name 1 (n.name.count - words[words.count].count)
		local i = findItem prefixes prefix
		if i == 0 then (append prefixes prefix; append best n)
		else if modelLodRank n < modelLodRank best[i] do best[i] = n
	)
	for n in lodMeshes where findItem best n == 0 collect n
)

-- On object import. Returns how many were hidden
fn hideModelLods modelNodes =
(
	local lowerLods = modelLowerLods modelNodes
	for n in lowerLods do n.isHidden = true
	lowerLods.count
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
