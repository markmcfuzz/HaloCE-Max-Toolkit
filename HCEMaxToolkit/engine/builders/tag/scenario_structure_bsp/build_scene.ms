------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

global haloScale = 100.0

-------------------------------------------------------
-- BITFIELD FLAG HELPERS
-------------------------------------------------------

-- Surface flags bit positions (8-bit bitfield)
fn isTwoSidedFlag flagValue = (bit.and flagValue 1) != 0  -- Bit 0
fn isInvisibleFlag flagValue = (bit.and flagValue 2) != 0  -- Bit 1
fn isClimbableFlag flagValue = (bit.and flagValue 4) != 0  -- Bit 2
fn isBreakableFlag flagValue = (bit.and flagValue 8) != 0  -- Bit 3

fn surfaceFlagsToArray flagValue =
(
	local flagArray = #()
	if flagValue == undefined then return flagArray

	if isTwoSidedFlag flagValue then append flagArray "two_sided"
	if isInvisibleFlag flagValue then append flagArray "invisible"
	if isClimbableFlag flagValue then append flagArray "climbable"
	if isBreakableFlag flagValue then append flagArray "breakable"

	return flagArray
)

-------------------------------------------------------
-- UTILITIES
-------------------------------------------------------

fn stringToColor str =
(
	local hash = 0
	for i = 1 to str.count do
		hash += (bit.charasint str[i]) * (i * 31)

	local r = (mod (hash * 73) 156) + 100
	local g = (mod (hash * 151) 156) + 100
	local b = (mod (hash * 257) 156) + 100

	return (color r g b)
)

-------------------------------------------------------
-- LAYER HELPERS
-------------------------------------------------------

fn getOrCreateChildLayer parentLayerName childLayerName =
(
	local parentLayer = LayerManager.getLayerFromName parentLayerName
	if parentLayer == undefined then
		parentLayer = LayerManager.newLayerFromName parentLayerName

	local childLayer = LayerManager.getLayerFromName childLayerName
	if childLayer == undefined then
		childLayer = LayerManager.newLayerFromName childLayerName

	try (childLayer.setParent parentLayer) catch ()

	return childLayer
)

-------------------------------------------------------
-- FRAME NODE
-------------------------------------------------------

fn getOrCreateFrameNode =
(
	local nodesLayer = LayerManager.getLayerFromName "Nodes"
	if nodesLayer == undefined then
		nodesLayer = LayerManager.newLayerFromName "Nodes"

	local existing = getNodeByName "frame"
	if existing != undefined then return existing

	local frameNode = Dummy()
	frameNode.name = "frame"
	frameNode.pos = [0, 0, 0]
	frameNode.wirecolor = color 255 255 0
	nodesLayer.addNode frameNode

	return frameNode
)

-------------------------------------------------------
-- COLLISION MATERIAL CREATION
-------------------------------------------------------
/**
---@param collisionMaterials array
---@param bspName string
---@param surfaceFlagsArray array
*/
fn createBSPCollisionMaterial collisionMaterials bspName surfaceFlagsArray =
(
    if collisionMaterials == undefined or classOf collisionMaterials != array do
    (
        logger.error "collisionMaterials must be an array"
        return undefined
    ) 
    if bspName == undefined or classOf bspName != string do
    (
        logger.error "bspName must be a string"
        return undefined
    )

	local matColCount = collisionMaterials.count
	local multiMat = MultiMaterial numSubs:(matColCount + 1)
	multiMat.name = bspName

	-- Slot 1: +sky (always first so "+" names sort to the top)
	local skyMat = StandardMaterial()
	skyMat.name = "+sky"
    -- rgb(10, 148, 255)
	skyMat.diffuse = color 10 148 255
	skyMat.opacity = 50
	skyMat.opacityType = 0  -- filter transparency
	multiMat[1] = skyMat
	multiMat.names[1] = "+sky"

	-- Slots 2..N+1: collision materials
	for i = 1 to matColCount do
	(
		local mat = collisionMaterials[i]
		local shaderRef = getFieldValue mat "shader"
		-- shaderRef is a #name Dictionary; keys are name literals, access with [#key]
		local shaderPathStr = if shaderRef != undefined and classOf shaderRef == Dictionary \
			then shaderRef[#path] \
			else undefined
		local matName = if shaderPathStr != undefined and shaderPathStr != "" \
			then filenameFromPath shaderPathStr \
			else ("material_" + i as string)

		local flags = if surfaceFlagsArray != undefined and i <= surfaceFlagsArray.count \
			then surfaceFlagsArray[i] \
			else #()

		local hasTwoSided  = findItem flags "two_sided" > 0
		local hasInvisible = findItem flags "invisible" > 0
		local hasClimbable = findItem flags "climbable" > 0
		local hasBreakable = findItem flags "breakable" > 0

		-- two_sided + invisible = "*"; two_sided alone = "%"
		if hasTwoSided and hasInvisible then
			matName += "*"
		else if hasTwoSided then
			matName += "%"
		if hasClimbable then matName += "^"
		if hasBreakable then matName += "-"

		local subMat = StandardMaterial()
		subMat.name = matName
		subMat.diffuse = stringToColor matName
		multiMat[i + 1] = subMat
		multiMat.names[i + 1] = matName
	)

	return multiMat
)

-------------------------------------------------------
-- MESH BUILDING
-------------------------------------------------------

-- Builds a compact MultiMaterial containing only the slots referenced in matIDArray.
-- Remaps matIDArray in-place so face matIDs stay consistent with the new slot indices
-- Returns undefined if multiMat is undefined or matIDArray is empty.
fn buildCompactMultiMat multiMat matIDArray suffix = (
    if multiMat == undefined or matIDArray.count == 0 then return undefined

    local usedIDs = #()
    for id in matIDArray do if findItem usedIDs id == 0 do append usedIDs id
    qsort usedIDs (fn cmp a b = a - b)

    local remap = #()
    remap.count = multiMat.numsubs
    for newID = 1 to usedIDs.count do remap[usedIDs[newID]] = newID
    for i = 1 to matIDArray.count do matIDArray[i] = remap[matIDArray[i]]

    local compactMat = MultiMaterial numSubs:usedIDs.count
    compactMat.name = multiMat.name + suffix
    for newID = 1 to usedIDs.count do (
        compactMat[newID] = multiMat[usedIDs[newID]]
        compactMat.names[newID] = multiMat.names[usedIDs[newID]]
    )
    compactMat
)

-- Build collision mesh(es) from BSP surface/edge/vertex data.
-- Single-sided surfaces go into one mesh; two-sided (%) surfaces go into a
-- separate mesh with back-face duplicates removed.
-- Duplicate detection for two-sided surfaces: the BSP stores both windings, so
-- front and back of each polygon share the same vertex SET.  Sorting the vertex
-- indices into a canonical key uniquely identifies each unique polygon regardless
-- of traversal direction.
-- Returns #(singleSidedMesh, twoSidedMesh, skyMesh, ssMat, tsMat).
-- Mesh entries may be undefined when the import flag is off or no faces exist.
-- ssMat/tsMat are always built when faces exist, regardless of import flags,
-- so render post-processing can use them even when the meshes are suppressed.
fn buildBSPCollisionMesh bsp multiMat meshName frameNode bspModelLayer \
	importSingleSided:true importSpecial:true importSky:true = (
		
	if bsp == undefined or bsp.vertices.count == 0 then
		return #(undefined, undefined, undefined, undefined, undefined)

	-- +sky is slot 1; collision materials occupy slots 2..N+1
	local skyMatID = 1
	-- Scale vertices (pre-allocated)
	local vertArray = #()
	vertArray.count = bsp.vertices.count
	for i = 1 to bsp.vertices.count do
		vertArray[i] = bsp.vertices[i].point * haloScale
	-- Single-sided geometry
	local ssFaceArray  = #()
	local ssMatIDArray = #()
	-- Two-sided geometry (deduplicated)
	local tsFaceArray  = #()
	local tsMatIDArray = #()
	local seenTSKeys   = #()  -- sorted-vertex-index string keys for duplicate detection
	-- Sky geometry (+sky material)
	local skyFaceArray  = #()
	local skyMatIDArray = #()

	local edgeCount = bsp.edges.count

	for surfIndex = 1 to bsp.surfaces.count do (
		local surf = bsp.surfaces[surfIndex]
		local surfaceIndex0Based = surfIndex - 1
		local matID = if surf.material == -1 then skyMatID else (surf.material + 2)
		local isTwoSided = surf.flags != undefined and isTwoSidedFlag surf.flags

		-- Walk edges to collect polygon vertices
		local faceVerts = #()
		local currentEdgeIndex = surf.firstEdge
		local startEdgeIndex   = surf.firstEdge
		local edgesProcessed   = 0

		while edgesProcessed < edgeCount do (
			if currentEdgeIndex < 0 or currentEdgeIndex >= edgeCount then exit
			local edge = bsp.edges[currentEdgeIndex + 1]
			local isLeftSurface = (edge.leftSurface == surfaceIndex0Based)

			if isLeftSurface then (
				append faceVerts (edge.startVertex + 1)
				currentEdgeIndex = edge.forwardEdge
			)
			else if edge.rightSurface == surfaceIndex0Based then (
				append faceVerts (edge.endVertex + 1)
				currentEdgeIndex = edge.reverseEdge
			)
			else exit
			edgesProcessed += 1
			if currentEdgeIndex == startEdgeIndex then exit
		)

		if faceVerts.count < 3 then continue

		if isTwoSided then (
			-- Build a sorted-vertex key to detect back-face duplicates.
			-- Front winding [v1,v2,v3] and back winding [v3,v2,v1] both sort to the
			-- same key; the second occurrence is the duplicate and is skipped.
			local sortedVerts = #()
			join sortedVerts faceVerts
			qsort sortedVerts (fn cmp a b = a - b)
			local key = sortedVerts as string

			if findItem seenTSKeys key > 0 then continue  -- back-face duplicate
			append seenTSKeys key

			for i = 2 to (faceVerts.count - 1) do (
				append tsFaceArray  [faceVerts[1], faceVerts[i], faceVerts[i + 1]]
				append tsMatIDArray matID
			)
		)
		else if matID == skyMatID then (
			for i = 2 to (faceVerts.count - 1) do (
				append skyFaceArray  [faceVerts[1], faceVerts[i], faceVerts[i + 1]]
				append skyMatIDArray matID
			)
		)
		else (
			for i = 2 to (faceVerts.count - 1) do (
				append ssFaceArray  [faceVerts[1], faceVerts[i], faceVerts[i + 1]]
				append ssMatIDArray matID
			)
		)
	)

	local tsMeshName = substituteString meshName "level_collision " "level_collision special "
	local skyMeshName = substituteString meshName "level_collision " "level_collision +sky "

	-- Build compact per-mesh MultiMaterials so each mesh only carries the slots it uses.
	-- Collect unique matIDs for each mesh, sort them, build an old→new remap, then
	-- rewrite the matID arrays in-place before handing them to the mesh() constructor.
	local ssMat  = buildCompactMultiMat multiMat ssMatIDArray  " single_sided"
	local tsMat  = buildCompactMultiMat multiMat tsMatIDArray  " special"
	local skyMat = buildCompactMultiMat multiMat skyMatIDArray " +sky"

	-- Build single-sided mesh
	local ssMesh = undefined
	if importSingleSided and ssFaceArray.count > 0 then (
		ssMesh = mesh vertices:vertArray faces:ssFaceArray materialIDs:ssMatIDArray
		ssMesh.name = meshName
		ssMesh.wirecolor = (color 0 0 0)
		ssMesh.backfacecull = true
		ssMesh.material = ssMat
		disableRefMsgs()
		for f = 1 to ssMesh.numfaces do setFaceSmoothGroup ssMesh f 0
		enableRefMsgs()
		update ssMesh
		ssMesh.parent = frameNode
		bspModelLayer.addNode ssMesh
		logger.debug "Created collision mesh '{}' ({} faces)" args:#(meshName, ssFaceArray.count)
	)
	-- Build two-sided mesh
	local tsMesh = undefined
	if importSpecial and tsFaceArray.count > 0 then (
		tsMesh = mesh vertices:vertArray faces:tsFaceArray materialIDs:tsMatIDArray
		tsMesh.name = tsMeshName
		tsMesh.wirecolor = (color 0 0 0)
		tsMesh.backfacecull = false
		tsMesh.material = tsMat
		disableRefMsgs()
		for f = 1 to tsMesh.numfaces do setFaceSmoothGroup tsMesh f 0
		enableRefMsgs()
		update tsMesh
		tsMesh.parent = frameNode
		bspModelLayer.addNode tsMesh
		logger.debug "Created collision mesh '{}' ({} faces)" args:#(tsMeshName, tsFaceArray.count)
	)
	-- Build sky mesh
	local skyMesh = undefined
	if importSky and skyFaceArray.count > 0 then (
		local skyMat = undefined
		if multiMat != undefined then (
			local skyUsed = #()
			for id in skyMatIDArray do if findItem skyUsed id == 0 do append skyUsed id
			
			qsort skyUsed (fn cmp a b = a - b)
			local skyRemap = #()
			skyRemap.count = multiMat.numsubs
			
			for newID = 1 to skyUsed.count do skyRemap[skyUsed[newID]] = newID
			
			for i = 1 to skyMatIDArray.count do skyMatIDArray[i] = skyRemap[skyMatIDArray[i]]
			
			skyMat = MultiMaterial numSubs:skyUsed.count
			skyMat.name = multiMat.name + " +sky"
			
			for newID = 1 to skyUsed.count do (
				skyMat[newID] = multiMat[skyUsed[newID]]
				skyMat.names[newID] = multiMat.names[skyUsed[newID]]
			)
		)
		skyMesh = mesh vertices:vertArray faces:skyFaceArray materialIDs:skyMatIDArray
		skyMesh.name = skyMeshName
		skyMesh.wirecolor = (color 66 191 245) -- rgb(66, 191, 245)
		skyMesh.backfacecull = true
		skyMesh.material = skyMat
		disableRefMsgs()
		for f = 1 to skyMesh.numfaces do setFaceSmoothGroup skyMesh f 0
		enableRefMsgs()
		update skyMesh
		skyMesh.parent = frameNode
		bspModelLayer.addNode skyMesh
		logger.debug "Created collision mesh '{}' ({} faces)" args:#(skyMeshName, skyFaceArray.count)
	)
	#(ssMesh, tsMesh, skyMesh, ssMat, tsMat)
)

-------------------------------------------------------
-- RENDER GEOMETRY BUILDER
-------------------------------------------------------

-- Strips trailing HEK material symbol characters from a shader name.
-- Recognised symbols: % * # ! ^ - $ @
fn stripTrailingSymbols name = (
	local i = name.count
	while i >= 1 do (
		local ch = substring name i 1
		if ch == "%" or ch == "*" or ch == "#" or ch == "!" or \
			ch == "^" or ch == "-" or ch == "$" or ch == "@" then
			i -= 1
		else
			exit
	)
	substring name 1 i
)

-------------------------------------------------------
-- RENDER GEOMETRY BUILDER
-------------------------------------------------------

-- Build render geometry from BSP lightmap data.
--
-- mergeAllClusters:true  (config: import_structure_bsp/merge_all_clusters=1)
--   All clusters merged into one mesh "level_render bspName" with a single
--   "main bspName" MultiMaterial. Symbols are restored from ssMat/tsMat;
--   materials with no collision counterpart receive the "!" suffix.
--
-- mergeAllClusters:false (default)
--   One mesh per cluster ("cluster_N bspName") each with its own MultiMaterial.
--
-- ssMat : "bspName single_sided" collision MultiMaterial  (used for "!" detection)
-- tsMat : "bspName symbols"      collision MultiMaterial  (used for symbol restoration)
fn buildBSPRenderMeshes lightmapsRenderData globalSurfaces bspName frameNode bspModelLayer \
	mergeAllClusters:false ssMat:undefined tsMat:undefined = (
	if lightmapsRenderData == undefined or lightmapsRenderData.count == 0 then
		return #()

	local createdMeshes = #()

	if not mergeAllClusters then (
		-----------------------------------------------------------
		-- PER-CLUSTER MODE (original behaviour)
		-----------------------------------------------------------
		for li = 1 to lightmapsRenderData.count do (
			local lm = lightmapsRenderData[li]
			if lm.materials.count == 0 then continue

			-- Accumulate totals for pre-allocation
			local totalVerts = 0
			local totalFaces = 0
			for mat in lm.materials do (
				totalVerts += mat.vertexCount
				totalFaces += mat.surfaceCount
			)
			if totalVerts == 0 or totalFaces == 0 then continue

			-- Pre-allocate geometry and UV arrays
			local vertArray   = #()
			local uvArray     = #()
			local normalArray = #()
			local faceArray   = #()
			local matIDArray  = #()
			vertArray.count   = totalVerts
			uvArray.count     = totalVerts
			normalArray.count = totalVerts
			faceArray.count   = totalFaces
			matIDArray.count  = totalFaces

			-- Build MultiMaterial for this lightmap cluster
			local multiMat = MultiMaterial numSubs:lm.materials.count

			local vertOffset = 0
			local faceOffset = 0

			for mi = 1 to lm.materials.count do (
				local mat = lm.materials[mi]

				-- Vertices, UVs, and normals
				for vi = 1 to mat.vertices.count do (
					local v = mat.vertices[vi]
					vertArray[vertOffset + vi]   = v.pos
					uvArray[vertOffset + vi]     = v.uv
					normalArray[vertOffset + vi] = v.normal
				)
				-- Faces: surfaces are indexed from the global surfaces array.
				-- Winding is reversed (v2, v1, v0) to correct face normals (same as Blender).
				local surfStart = mat.surfacesStart + 1  -- convert from 0-based to 1-based
				for si = 1 to mat.surfaceCount do (
					local surf = globalSurfaces[surfStart + si - 1]
					if surf == undefined then continue
					faceArray[faceOffset + si]  = [surf[3] + vertOffset + 1, surf[2] + vertOffset + 1, surf[1] + vertOffset + 1]
					matIDArray[faceOffset + si] = mi
				)
				-- Sub-material for this shader
				local subMat = StandardMaterial()
				local matName = if mat.shaderName != "" then mat.shaderName else ("material_" + mi as string)
				subMat.name         = matName
				subMat.diffuse      = stringToColor matName
				subMat.showInViewport = true
				multiMat[mi]       = subMat
				multiMat.names[mi] = matName
				vertOffset += mat.vertexCount
				faceOffset += mat.surfaceCount
			)
			-- Create the mesh object
			local clusterName = "cluster_" + (li - 1) as string + " " + bspName
			multiMat.name = clusterName
			local newMesh = mesh vertices:vertArray faces:faceArray materialIDs:matIDArray
			newMesh.backfacecull = true
			newMesh.wirecolor = (color 0 0 0)
			newMesh.name     = clusterName
			newMesh.material = multiMat
			newMesh.parent   = frameNode
			bspModelLayer.addNode newMesh
			-- Apply UVs, clear smoothing groups, set normals — all under disableRefMsgs
			-- so Max only fires one cache-invalidation (the final update) instead of one per element.
			disableRefMsgs()
			setNumTVerts newMesh uvArray.count
			buildTVFaces newMesh
			for i = 1 to uvArray.count do setTVert newMesh i uvArray[i]
			for i = 1 to faceArray.count do setTVFace newMesh i faceArray[i]
			for i = 1 to newMesh.numfaces do setFaceSmoothGroup newMesh i 0
			if normalArray.count == newMesh.numverts then
				for i = 1 to normalArray.count do setNormal newMesh i normalArray[i]
			enableRefMsgs()
			update newMesh
			append createdMeshes newMesh
			logger.info "Render cluster '{}' built: {} verts, {} faces, {} materials" \
				args:#(clusterName, totalVerts, totalFaces, lm.materials.count)
		)
	)
	else (
		-----------------------------------------------------------
		-- MERGED MODE  (merge_all_clusters=1)
		-- All lightmap clusters joined into a single mesh.
		-----------------------------------------------------------

		-- Global shader-name → matID map and material list (de-duplicated)
		local globalNameToID  = Dictionary #string
		local globalNames     = #()   -- raw shader names (no symbols yet)
		local globalMaterials = #()   -- StandardMaterial objects

		-- Global geometry buffers (appended per-cluster)
		local allVerts   = #()
		local allUVs     = #()
		local allNormals = #()
		local allFaces   = #()
		local allMatIDs  = #()

		local gVertOffset = 0  -- cumulative vertex count already in allVerts

		for li = 1 to lightmapsRenderData.count do
		(
			local lm = lightmapsRenderData[li]
			if lm.materials.count == 0 then continue

			-- Count cluster vertices for pre-allocation
			local clusterVerts = 0
			for mat in lm.materials do clusterVerts += mat.vertexCount
			if clusterVerts == 0 then continue

			-- Pre-allocate per-cluster vertex arrays
			local vertArray   = #()
			local uvArray     = #()
			local normalArray = #()
			vertArray.count   = clusterVerts
			uvArray.count     = clusterVerts
			normalArray.count = clusterVerts

			-- Per-cluster face/matID lists (append; undefined surfs are skipped)
			local clusterFaces  = #()
			local clusterMatIDs = #()
			local vOff = 0

			for mi = 1 to lm.materials.count do (
				local mat = lm.materials[mi]
				-- Vertices, UVs, normals
				for vi = 1 to mat.vertices.count do (
					local v = mat.vertices[vi]
					vertArray[vOff + vi]   = v.pos
					uvArray[vOff + vi]     = v.uv
					normalArray[vOff + vi] = v.normal
				)
				-- Register or look up global material ID
				local shaderName = if mat.shaderName != "" then mat.shaderName else "material_unknown"
				local gMatID = globalNameToID[shaderName]
				if gMatID == undefined then (
					local subMat = StandardMaterial()
					subMat.name = shaderName
					subMat.diffuse = stringToColor shaderName
					subMat.showInViewport = true
					append globalMaterials subMat
					append globalNames shaderName
					gMatID = globalMaterials.count
					globalNameToID[shaderName] = gMatID
				)
				-- Faces with cluster-local 1-based vertex indices (winding reversed)
				local surfStart = mat.surfacesStart + 1
				for si = 1 to mat.surfaceCount do (
					local surf = globalSurfaces[surfStart + si - 1]
					if surf == undefined then continue
					append clusterFaces  [surf[3] + vOff + 1, surf[2] + vOff + 1, surf[1] + vOff + 1]
					append clusterMatIDs gMatID
				)
				vOff += mat.vertexCount
			)
			-- Merge cluster data into global buffers.
			-- Face vertex indices are shifted by gVertOffset so they reference
			-- the correct positions in the concatenated allVerts array.
			join allVerts   vertArray
			join allUVs     uvArray
			join allNormals normalArray
			for i = 1 to clusterFaces.count do (
				local f = clusterFaces[i]
				append allFaces [f.x + gVertOffset, f.y + gVertOffset, f.z + gVertOffset]
			)
			join allMatIDs clusterMatIDs
			gVertOffset += clusterVerts
		)
		if allFaces.count == 0 then return #()

		-- -----------------------------------------------------------
		-- Material post-processing
		-- -----------------------------------------------------------
		-- Collect Two Side Mat (symbols) sub-material names and their stripped base names.
		local tsNames = #()
		local tsBaseNames = #()
		if tsMat != undefined then (
			for si = 1 to tsMat.numsubs do (
				local n = tsMat.names[si]
				append tsNames n
				append tsBaseNames (stripTrailingSymbols n)
			)
		)

		-- Collect ssMat (single_sided) base names, skipping +sky.
		local ssBaseNames = #()
		if ssMat != undefined then (
			for si = 1 to ssMat.numsubs do (
				local n = ssMat.names[si]
				if n != "+sky" then
					append ssBaseNames (stripTrailingSymbols n)
			)
		)
		-- a) Restore collision symbols: "floor" -> "floor%" if tsMat has "floor%"
		-- b) Add "!" for materials with no collision counterpart (render-only)
		for gi = 1 to globalMaterials.count do (
			local rawName  = globalNames[gi]
			local finalName = rawName
			-- a) Symbol restoration from tsMat
			local tsIdx = findItem tsBaseNames rawName
			if tsIdx > 0 then (
				local symSuffix = substring tsNames[tsIdx] (tsBaseNames[tsIdx].count + 1) -1
				finalName = rawName + symSuffix
			)
			-- b) Render-only detection: not in ssMat and not in tsMat → add "!"
			local inSingle  = ssMat != undefined and findItem ssBaseNames rawName > 0
			local inSymbols = tsMat != undefined and findItem tsBaseNames rawName > 0
			if not inSingle and not inSymbols then
				finalName += "!"

			globalMaterials[gi].name   = finalName
			globalMaterials[gi].diffuse = stringToColor finalName
		)
		-- Build the single "main bspName" MultiMaterial.
		-- IDs 1-5 are reserved special-surface slots; shader materials start at ID 6.
		local specialNames = #("+sky", "+portal", "+exactportal", "+weatherpoly", "+unused")
		local specialCount = specialNames.count  -- 5
		local mainMat = MultiMaterial numSubs:(specialCount + globalMaterials.count)
		mainMat.name = "main " + bspName
		local specialColors    = #(color 10 148 255, color 79 255 10, color 226 10 255, color 255 10 10, color 255 177 10)
		local specialOpacities = #(50, 40, 40, 40, 25)
		
		for si = 1 to specialCount do (
			local sm = StandardMaterial()
			sm.name           = specialNames[si]
			sm.diffuse        = specialColors[si]
			sm.opacity        = specialOpacities[si]
			sm.showInViewport = true
			mainMat[si]       = sm
			mainMat.names[si] = specialNames[si]
		)
		for gi = 1 to globalMaterials.count do (
			local mi = specialCount + gi
			mainMat[mi]       = globalMaterials[gi]
			mainMat.names[mi] = globalMaterials[gi].name
		)
		-- Deduplicate vertices by (position, normal) pair.
		-- Keys are quantized to 1/1000 for position and 1/10000 for normals.
		--   Same position + same normal  → merge  (cluster seam vertices)
		--   Same position + diff normal  → keep separate (hard edge corners)
		-- Vertex dedup is skipped: allVerts/allNormals/allFaces are used directly.
		-- Cluster seam vertices will overlap but remain separate; users can weld
		-- manually with a threshold weld if a seamless result is needed.
		-- Only the matID array needs processing: shift every ID past the 5 reserved slots.
		local masterVerts   = allVerts
		local masterNormals = allNormals
		local masterFaces   = allFaces
		for f = 1 to allMatIDs.count do allMatIDs[f] += specialCount
		local masterMatIDs  = allMatIDs

		-- Create the merged mesh.
		-- The UV channel uses the same allUVs / allFaces arrays so UV seams
		-- are independent of any geometry topology.
		local mergedName = "level_render " + bspName
		local mergedMesh = mesh vertices:masterVerts faces:masterFaces materialIDs:masterMatIDs
		mergedMesh.name         = mergedName
		mergedMesh.backfacecull = true
		mergedMesh.wirecolor    = (color 0 0 0)
		mergedMesh.material     = mainMat
		mergedMesh.parent       = frameNode
		bspModelLayer.addNode mergedMesh

		-- Apply UVs, clear smoothing groups, and set normals in one locked block
		-- so Max fires only a single cache invalidation (the final update).
		disableRefMsgs()
		setNumTVerts mergedMesh allUVs.count
		buildTVFaces mergedMesh
		for i = 1 to allUVs.count do setTVert mergedMesh i allUVs[i]
		for i = 1 to masterFaces.count do setTVFace mergedMesh i allFaces[i]
		for i = 1 to masterFaces.count do setFaceSmoothGroup mergedMesh i 0
		for i = 1 to masterVerts.count do setNormal mergedMesh i masterNormals[i]
		enableRefMsgs()
		update mergedMesh

		-- Remove duplicate faces in "%" materials (two-sided surfaces).
		-- Both winding copies of a two-sided poly have opposite normals, so the
		-- (pos+normal) dedup above gives them different master vertex indices.
		-- We therefore key each face by its three corner POSITIONS (not indices),
		-- sorted lexicographically so both winding orders produce the same key.
		-- percentMatIDs is a BitArray built once so the per-face check is O(1)
		-- instead of a string search + array access per face.
		-- masterFaces/masterMatIDs are used directly to avoid per-face API calls.
		local percentMatIDs = #{}
		for gi = 1 to globalMaterials.count do (
			if findString globalMaterials[gi].name "%" != undefined then
				percentMatIDs[(gi + specialCount)] = true
		)
		local seenFaceKeys = Dictionary #string
		local dupFaces     = #{}
		for f = 1 to masterFaces.count do (
			if percentMatIDs[masterMatIDs[f]] then (
				local fv = masterFaces[f]
				local p1 = masterVerts[fv.x as integer]
				local p2 = masterVerts[fv.y as integer]
				local p3 = masterVerts[fv.z as integer]
				local k1 = (((floor (p1.x * 100 + 0.5)) as integer) as string) + "," + \
				           (((floor (p1.y * 100 + 0.5)) as integer) as string) + "," + \
				           (((floor (p1.z * 100 + 0.5)) as integer) as string)
				local k2 = (((floor (p2.x * 100 + 0.5)) as integer) as string) + "," + \
				           (((floor (p2.y * 100 + 0.5)) as integer) as string) + "," + \
				           (((floor (p2.z * 100 + 0.5)) as integer) as string)
				local k3 = (((floor (p3.x * 100 + 0.5)) as integer) as string) + "," + \
				           (((floor (p3.y * 100 + 0.5)) as integer) as string) + "," + \
				           (((floor (p3.z * 100 + 0.5)) as integer) as string)
				local pks = #(k1, k2, k3)
				sort pks
				local key = pks[1] + "|" + pks[2] + "|" + pks[3]
				if seenFaceKeys[key] == undefined then
					seenFaceKeys[key] = true
				else
					dupFaces[f] = true
			)
		)
		if dupFaces.numberSet > 0 then (
			meshop.deleteFaces mergedMesh dupFaces
			update mergedMesh
		)
		append createdMeshes mergedMesh
		logger.info "level_render '{}' built (merged): {} verts, {} faces, {} materials" \
			args:#(mergedName, masterVerts.count, mergedMesh.numfaces, globalMaterials.count)
	)
	createdMeshes
)

-------------------------------------------------------
-- PORTAL BUILDER
-------------------------------------------------------
fn buildBSPPortals portalsData frameNode portalsLayer \
    importPortals:true = (
	if not importPortals then return #()
	if portalsData == undefined or portalsData.count == 0 then return #()

	local portalsMat = StandardMaterial()
	portalsMat.name = "+portal"
    -- rgb(79, 255, 10) 
	portalsMat.diffuse = color 79 255 10
	portalsMat.opacity = 40
	portalsMat.opacityType = 0  -- filter transparency
	portalsMat.twoSided = true

	local createdMeshes = #()

	for pi = 1 to portalsData.count do (
		local portal    = portalsData[pi]
		local vertArray = portal.vertices
		if vertArray.count < 3 then continue

		-- Fan triangulation from vertex 1
		local faceArray = #()
		for i = 2 to (vertArray.count - 1) do
			append faceArray [1, i, i + 1]

		if faceArray.count == 0 then continue

		local newMesh = mesh vertices:vertArray faces:faceArray
		newMesh.name = "portal_" + pi as string
        newMesh.wirecolor = color 79 255 10
		newMesh.material = portalsMat
		newMesh.parent = frameNode
		portalsLayer.addNode newMesh

		for f = 1 to newMesh.numfaces do
			setFaceSmoothGroup newMesh f 0
		append createdMeshes newMesh
	)
	logger.info "BSP portals built: {} mesh(es)" args:#(createdMeshes.count)
	return createdMeshes
)

-------------------------------------------------------
-- FOG PLANE BUILDER
-------------------------------------------------------

fn buildBSPFogPlanes fogPlanesData frameNode fogPlanesLayer \
    importFogPlanes:true = (
	if not importFogPlanes then return #()
	if fogPlanesData == undefined or fogPlanesData.count == 0 then return #()

	local fogMat = StandardMaterial()
	fogMat.name = "+unused$"
    -- rgb(255, 177, 10)
	fogMat.diffuse = color 255 177 10
	fogMat.opacity = 25
	fogMat.opacityType = 0  -- filter transparency
	fogMat.twoSided = true

	local createdMeshes = #()

	for fi = 1 to fogPlanesData.count do (
		local plane     = fogPlanesData[fi]
		local vertArray = plane.vertices
		if vertArray.count < 3 then continue

		-- Fan triangulation from vertex 1
		local faceArray = #()
		for i = 2 to (vertArray.count - 1) do
			append faceArray [1, i, i + 1]

		if faceArray.count == 0 then continue

		local newMesh = mesh vertices:vertArray faces:faceArray
		newMesh.name = "fog_plane_" + fi as string
		newMesh.material = fogMat
		newMesh.wirecolor = (color 255 177 10)
		newMesh.parent = frameNode
		fogPlanesLayer.addNode newMesh

		for f = 1 to newMesh.numfaces do
			setFaceSmoothGroup newMesh f 0

		append createdMeshes newMesh
	)
	logger.info "BSP fog planes built: {} mesh(es)" args:#(createdMeshes.count)
	return createdMeshes
)

-------------------------------------------------------
-- WEATHER POLYHEDRA BUILDER
-------------------------------------------------------
fn buildBSPWeatherPolyhedra weatherPolyData frameNode weatherPolyLayer \
    importWeatherPolyhedra:true = (
	if not importWeatherPolyhedra then return #()
	if weatherPolyData == undefined or weatherPolyData.count == 0 then return #()

	local weatherMat = StandardMaterial()
	weatherMat.name = "+weatherpoly"
    -- rgb(255, 10, 10)
	weatherMat.diffuse = color 255 10 10
	weatherMat.opacity = 40
	weatherMat.opacityType = 0  -- filter transparency
	weatherMat.twoSided = true

	local createdMeshes = #()

	for wi = 1 to weatherPolyData.count do (
		local poly   = weatherPolyData[wi]
		local planes = poly.planes
		if planes.count < 4 then continue
		-- back to Halo units for tolerance
		local centerHalo = poly.center / haloScale  
		local tol = (length centerHalo) * 0.00001
		-- Triple-plane intersection: find all candidate vertices
		local verts = #()
		local n = planes.count
		for i = 1 to n do
			for j = (i + 1) to n do
				for k = (j + 1) to n do (
					local pt = wpIntersect3Planes planes[i] planes[j] planes[k]
					if pt == undefined then continue
					if wpIsInsideAllPlanes pt planes tol then
						append verts (pt * haloScale)
				)
		if verts.count < 3 then continue
		-- Build faces: for each plane, find which verts lie on it, sort by angle, fan-tri
		local faceArray = #()
		for pi = 1 to n do (
			local pln = planes[pi]
			local norm = point3 pln.x pln.y pln.z
			local d    = pln.w
			local faceTol = abs(d) * 0.001 + 0.0001
			-- Collect indices of verts on this plane
			local faceIdx = #()
			for vi = 1 to verts.count do (
				local ptHalo = verts[vi] / haloScale
				if abs(dot ptHalo norm - d) < faceTol then
					append faceIdx vi
			)
			if faceIdx.count < 3 then continue
			-- Deduplicate near-identical vertices in this face (from triple intersections)
			local uniqueIdx = #(faceIdx[1])
			for a = 2 to faceIdx.count do (
				local duplicate = false
				for b = 1 to uniqueIdx.count do
					if length(verts[faceIdx[a]] - verts[uniqueIdx[b]]) < 0.01 then (
						duplicate = true; exit
					)
				if not duplicate then append uniqueIdx faceIdx[a]
			)
			if uniqueIdx.count < 3 then continue
			-- Sort by angle around face center
			local sorted = wpSortVertsByAngle uniqueIdx verts norm
			-- Fan triangulate from first vertex
			for t = 2 to (sorted.count - 1) do
				append faceArray [sorted[1], sorted[t], sorted[t+1]]
		)
		if faceArray.count == 0 then continue
		local newMesh = mesh vertices:verts faces:faceArray
		newMesh.name = "weather_polyhedra_" + wi as string
        newMesh.wirecolor = color 255 10 10
		newMesh.material = weatherMat
		newMesh.parent = frameNode
		weatherPolyLayer.addNode newMesh
		for f = 1 to newMesh.numfaces do
			setFaceSmoothGroup newMesh f 0
		append createdMeshes newMesh
	)
	logger.info "BSP weather polyhedra built: {} mesh(es)" args:#(createdMeshes.count)
	return createdMeshes
)

-------------------------------------------------------
-- MARKERS BUILDER
-------------------------------------------------------

-- Build marker helper objects from the BSP markers block.
-- Each marker becomes a HaloMarker helper named "#markerName", parented to a
-- "/Markers" container Dummy that is itself linked to the frame node.
fn buildBSPMarkers markersData frameNode markersLayer \
    importMarkers:true = (
	if not importMarkers then return #()
	if markersData == undefined or markersData.count == 0 then return #()

	local createdMarkers = #()

	for m in markersData do (
		local hx    = m.markerPos.x
		local hy    = m.markerPos.y
		local hz    = m.markerPos.z
		local qx    = m.markerRot.x
		local qy    = m.markerRot.y
		local qz    = m.markerRot.z
		local qw    = m.markerRot.w
		local mName = m.name

		local markerObj = createHaloMarker \
			pos:[0,0,0] \
			radius:5.0 \
			name:mName \
			wireColor:(color 0 240 255) -- rgb(0, 240, 255)

		-- Halo stores quaternion as (i,j,k,w); the position is in the marker's local frame.
		-- World position = inverted_quat * local_pos * haloScale
		-- For a unit quaternion, inverse = conjugate: negate xyz, keep w.
		local rotQuat      = normalize (quat (-qx) (-qy) (-qz) qw)
		local worldPos     = [hx, hy, hz] * (rotQuat as matrix3)
		markerObj.pos      = worldPos
		markerObj.rotation = rotQuat

		markersLayer.addNode markerObj
		markerObj.parent = frameNode

		append createdMarkers markerObj
	)
	logger.info "BSP markers built: {}" args:#(createdMarkers.count)
	return createdMarkers
)

-------------------------------------------------------
-- MAIN ENTRY POINT
-------------------------------------------------------

fn buildBSPMesh bspData lightmapsRenderData bspName = (
	-- Read import settings
	local mergeAllClusters    = configManager.getBool "import_structure_bsp" "merge_all_clusters"          false
	local importSSColl         = configManager.getBool "import_structure_bsp" "import_single_sided_coll_mesh" true
	local importSpecialColl    = configManager.getBool "import_structure_bsp" "import_special_coll_mesh"    true
	local importSkyColl        = configManager.getBool "import_structure_bsp" "import_sky_coll_mesh"          true
	local importPortalsCfg     = configManager.getBool "import_structure_bsp" "import_portals"                true
	local importFogPlanesCfg   = configManager.getBool "import_structure_bsp" "import_fog_planes"             true
	local importWeatherPolyCfg = configManager.getBool "import_structure_bsp" "import_weather_polyhedra"      true
	local importMarkersCfg     = configManager.getBool "import_structure_bsp" "import_markers"                true

	-- Set up layers
	local bspSceneLayer = LayerManager.getLayerFromName "BSP Scene"
	if bspSceneLayer == undefined then
		bspSceneLayer = LayerManager.newLayerFromName "BSP Scene"

	local bspModelLayer    = getOrCreateChildLayer "BSP Scene" "BSP Collision"
	local renderBspLayer   = getOrCreateChildLayer "BSP Scene" "BSP Render"
	local portalsLayer     = getOrCreateChildLayer "BSP Scene" "BSP Portals"
	local fogPlanesLayer   = getOrCreateChildLayer "BSP Scene" "BSP Fog Planes"
	local weatherPolyLayer = getOrCreateChildLayer "BSP Scene" "BSP Weather Polyhedra"
	local markersLayer     = getOrCreateChildLayer "BSP Scene" "BSP Markers"

	-- Create (or find existing) frame node
	local frameNode = getOrCreateFrameNode()

	-- Get collision materials from parsed data
	local collisionMaterials = getFieldValue bspData "collisionMaterials"
	if collisionMaterials == undefined then collisionMaterials = #()

	-- Convert collisionBsp to fast-access structs
	local bsp = convertCollisionBspData bspData
	if bsp == undefined then (
		logger.warn "No collision BSP data found."
		return #()
	)

	-- Scan surfaces to accumulate which flags each material has
	local materialSurfaceFlags = #()
	for i = 1 to collisionMaterials.count do
		append materialSurfaceFlags #()

	for surf in bsp.surfaces do (
		if surf.material == -1 then continue
		local matIndex = surf.material + 1
		if matIndex < 1 or matIndex > materialSurfaceFlags.count then continue

		local flagNames = surfaceFlagsToArray surf.flags
		for flag in flagNames do (
			if findItem materialSurfaceFlags[matIndex] flag == 0 then
				append materialSurfaceFlags[matIndex] flag
		)
	)

	-- Build multi-material (collision materials + sky)
	local multiMat = createBSPCollisionMaterial collisionMaterials bspName materialSurfaceFlags
	if multiMat != undefined then
		meditMaterials[1] = multiMat

	-- Build the collision meshes (returns #(singleSidedMesh, twoSidedMesh, skyMesh)).
	-- Each mesh receives its own compact MultiMaterial (only the slots it uses).
	local meshName = "level_collision " + bspName
	local bspContainer = createHaloContainer \
            name:"/BSP" \
            size:150 \
            wireColor:(color 0 0 0)
	bspContainer.parent = frameNode
	bspSceneLayer.addNode bspContainer
    
	local collMeshes = buildBSPCollisionMesh bsp multiMat meshName bspContainer bspModelLayer \
		importSingleSided:importSSColl importSpecial:importSpecialColl importSky:importSkyColl

	-- Extract the compact collision materials for render post-processing.
	-- ssMat/tsMat are always built inside buildBSPCollisionMesh when faces exist,
	-- regardless of the import flags — so they're available even when the meshes
	-- themselves were suppressed (e.g. importSingleSided=false).
	local createdMeshes = #()
	local ssMat = collMeshes[4]
	local tsMat = collMeshes[5]
	for i = 1 to 3 do (
		local m = collMeshes[i]
		if m != undefined then append createdMeshes m
	)
    --
	-- Build render geometry from lightmaps data
	local globalSurfaceTuples = getFieldValue bspData "surfaces"
	local globalSurfaces = if globalSurfaceTuples != undefined then \
		mapBSPRenderSurfaces globalSurfaceTuples else #()

	if lightmapsRenderData != undefined and lightmapsRenderData.count > 0 then (
		local renderMeshes = buildBSPRenderMeshes lightmapsRenderData globalSurfaces bspName bspContainer renderBspLayer \
			mergeAllClusters:mergeAllClusters ssMat:ssMat tsMat:tsMat
		for m in renderMeshes do append createdMeshes m
	)

	-- Build portals
	local clusterPortalsRaw = getFieldValue bspData "clusterPortals"
	local portalsData = mapBSPPortals clusterPortalsRaw
	if importPortalsCfg and portalsData.count > 0 then (
		local portalContainer = createHaloContainer \
            name:"/Portal" \
            size:100 \
            wireColor:(color 79 255 10)
		portalContainer.parent = frameNode
		portalsLayer.addNode portalContainer
		local portalMeshes = buildBSPPortals portalsData portalContainer portalsLayer importPortals:importPortalsCfg
		for m in portalMeshes do append createdMeshes m
	)

	-- Build fog planes
	local fogPlanesRaw = getFieldValue bspData "fogPlanes"
	local fogPlanesData = mapBSPFogPlanes fogPlanesRaw
	if importFogPlanesCfg and fogPlanesData.count > 0 then (
		local fogContainer = createHaloContainer \
            name:"/Fog Plane" \
            size:50 \
            wireColor:(color 255 177 10)
		fogContainer.parent = frameNode
		fogPlanesLayer.addNode fogContainer
		local fogMeshes = buildBSPFogPlanes fogPlanesData fogContainer fogPlanesLayer importFogPlanes:importFogPlanesCfg
		for m in fogMeshes do append createdMeshes m
	)

	-- Build weather polyhedra
	local weatherPolyRaw = getFieldValue bspData "weatherPolyhedra"
	local weatherPolyData = mapBSPWeatherPolyhedra weatherPolyRaw
	if importWeatherPolyCfg and weatherPolyData.count > 0 then (
		local weatherContainer = createHaloContainer \
            name:"/Weather Polyhedra" \
            size:25 \
            wireColor:(color 255 10 10)
		weatherContainer.parent = frameNode
		weatherPolyLayer.addNode weatherContainer
		local weatherMeshes = buildBSPWeatherPolyhedra weatherPolyData weatherContainer weatherPolyLayer importWeatherPolyhedra:importWeatherPolyCfg
		for m in weatherMeshes do append createdMeshes m
	)

	-- Build markers
	local markersRaw = getFieldValue bspData "markers"
	local markersData = mapBSPMarkers markersRaw
	if importMarkersCfg and markersData.count > 0 then (
		local markerContainer = createHaloContainer \
            name:"/Markers" \
            size:12.5 \
            wireColor:(color 0 240 255)

		markerContainer.parent = frameNode
		markersLayer.addNode markerContainer
		buildBSPMarkers markersData markerContainer markersLayer importMarkers:importMarkersCfg
	)
	logger.info "BSP scene built: {} mesh(es) total" args:#(createdMeshes.count)
	return createdMeshes
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
