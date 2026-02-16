-- Halo CE Gbxmodel Mesh Builder
-- Builds 3D geometry in 3ds Max from gbxmodel tag data

-- Global scale factor: Halo world units to 3ds Max units
global HALO_SCALE = 100.0

-- Default bone size (matches old importer's spn_node.value default)
global BONE_SIZE = 1.0

-------------------------------------------------------
-- SKELETON DETECTION AND REUSE
-------------------------------------------------------

-- Recursive helper function to collect all children in a hierarchy
-- Must be defined at module level (not nested) due to MaxScript scoping rules
-- Only collects bones and helpers (skeleton nodes), excludes geometry meshes and Markers
fn collectAllChildren parent theArray =
(
    for child in parent.children do
    (
        local childClass = classOf child

        if childClass == BoneGeometry or
        childClass == Sphere or
        childClass == Point or
        childClass == Dummy do
        append theArray child
        
        collectAllChildren child theArray
    )
)

-- Check if a bone hierarchy matches the incoming node data
-- Returns array of existing nodes in correct order if match found, undefined otherwise
fn findMatchingSkeleton nodeDataArray =
(

	logger "\nfindMatchingSkeleton called with % nodes\n"  params:#(nodeDataArray.count) logType:#debug
	
	if nodeDataArray.count == 0 then
		return undefined
	
	-- Get the root node name (first node with parentNode == -1)
	local rootNodeName = undefined
	for nodeData in nodeDataArray do
	(
		if nodeData.parentNode == -1 then
		(
			rootNodeName = nodeData.name
			exit
		)
	)
	
	logger "Root node name: %\n"  params:#(rootNodeName) logType:#debug
	
	if rootNodeName == undefined then
		return undefined
	
	-- Find all potential root nodes in the scene with the same name
	local potentialRoots = for obj in objects where obj.name == rootNodeName collect obj
	logger "Found % potential root objects in scene\n"  params:#(potentialRoots.count) logType:#debug
	
	if potentialRoots.count == 0 then
		return undefined
	
	-- For each potential root, collect its hierarchy and check if it matches
	for rootObj in potentialRoots do
	(
		logger "Checking root object: %\n"  params:#(rootObj.name) logType:#debug
		
		-- Collect all nodes in this hierarchy
		local hierarchyNodes = #(rootObj)
		collectAllChildren rootObj hierarchyNodes

		
		logger "Collected % nodes in hierarchy\n"  params:#(hierarchyNodes.count) logType:#debug
		
		-- Check if node count matches
		if hierarchyNodes.count != nodeDataArray.count then
		(
			logger "Node count mismatch: hierarchy has %, need %\n"  params:#(hierarchyNodes.count, nodeDataArray.count) logType:#error
			continue
		)
		
		logger "Node counts match! Starting node matching...\n" logType:#debug
		
		-- Try to match all nodes by name and parent relationship
		local orderedNodes = #()
		local allMatched = true
		
		for i = 1 to nodeDataArray.count do
		(
			local nodeData = nodeDataArray[i]
			
			-- Find node with matching name in hierarchy
			local foundNode = undefined
			for node in hierarchyNodes where node.name == nodeData.name do
			(
				foundNode = node
				exit
			)
			
			if foundNode == undefined then
			(
				logger "FAILED: Could not find node '%' in hierarchy\n"  params:#(nodeData.name) logType:#error
				allMatched = false
				exit
			)
			logger "Node %: Found '%'\n"  params:#(i, nodeData.name) logType:#debug
			-- Verify parent relationship
			local parentIndex = nodeData.parentNode
			if parentIndex >= 0 and parentIndex < nodeDataArray.count then
			(
				-- Get expected parent name from node data
				local expectedParentName = nodeDataArray[parentIndex + 1].name
				
				-- Check if found node's parent matches
				if foundNode.parent == undefined then
				(
					logger "FAILED: Node '%' has no parent, expected '%'\n"  params:#(nodeData.name, expectedParentName) logType:#error
					allMatched = false
					exit
				)
				else if foundNode.parent.name != expectedParentName then
				(
					logger "FAILED: Node '%' parent is '%', expected '%'\n"  params:#(nodeData.name, foundNode.parent.name, expectedParentName) logType:#error
					allMatched = false
					exit
				)
			)
			else if parentIndex == -1 then
			(
				-- Root node should have no parent
				if foundNode.parent != undefined then
				(
					logger "FAILED: Root node '%' has parent '%'\n"  params:#(nodeData.name, foundNode.parent.name) logType:#error
					allMatched = false
					exit
				)
			)
			append orderedNodes foundNode
		)
		-- If all nodes matched, return the ordered array
		if allMatched then
		(
			logger "SUCCESS! Found matching skeleton: % nodes\n"  params:#(orderedNodes.count) logType:#debug
			return orderedNodes
		)
	)
	return undefined
)

-- Show dialog asking user if they want to reuse existing skeleton
-- Returns true if user wants to reuse, false otherwise
fn askReuseSkeletonDialog =
(
	local result = queryBox "Skeleton detected in the scene!\n\nWould you like to reuse the existing bones?" \
		title:"Reuse Skeleton?" \
		beep:false
	
	return result
)

-------------------------------------------------------
-- NODE/BONE CREATION
-------------------------------------------------------

-- Create a single node (sphere helper) from node data
-- ALL nodes created as spheres initially - will convert to bones later
fn createGbxmodelNode nodeData nodeIndex allNodeData =
(
	local nodeName = nodeData.name
	
	-- Create ALL nodes as spheres at origin (matches old script approach)
	-- Bone nodes will be converted to actual bones in a later pass
	local nodeObj = Sphere radius:BONE_SIZE pos:[0,0,0] name:nodeName smooth:on
	
	-- Use isNodeObject from utils to check if this should be a bone
	if isNodeObject nodeObj then
		nodeObj.wirecolor = color 6 134 6  --#068606 Green for nodes that will become bones
	else
		nodeObj.wirecolor = color 128 128 128  --#808080 Gray for other nodes
	
	-- Assign to "Nodes" layer
	local nodesLayer = LayerManager.getLayerFromName "Nodes"
	if nodesLayer == undefined then
		nodesLayer = LayerManager.newLayerFromName "Nodes"
	nodesLayer.addNode nodeObj
	
	--format "Created sphere: '%'\n" nodeName
	
	return nodeObj
)

-- Link node hierarchy and apply transforms (must be called after all nodes are created)
fn linkNodeHierarchy createdNodes nodeDataArray =
(
	--format "\n=== LINKING NODE HIERARCHY ===\n"
	
	-- First pass: link parent-child relationships
	for i = 1 to createdNodes.count do
	(
		local nodeObj = createdNodes[i]
		local nodeData = nodeDataArray[i]
		local parentIndex = nodeData.parentNode  -- Parent node index (-1 = no parent)
		
		if parentIndex >= 0 and parentIndex < createdNodes.count then
		(
			local parentObj = createdNodes[parentIndex + 1]  -- Convert 0-based to 1-based
			nodeObj.parent = parentObj
			
			--format "  Linked '%' → '%'\n" nodeObj.name parentObj.name
		)
	)
	
	--format "[✓] Node hierarchy linked\n"
	
	-- Second pass: apply transforms in parent-local space  
	--format "\n=== APPLYING TRANSFORMS ===\n"
	
	for i = 1 to createdNodes.count do
	(
		local nodeObj = createdNodes[i]
		if nodeObj == undefined then continue
		
		local nodeData = nodeDataArray[i]
		local nodeName = nodeData.name
		local translation = nodeData.translation
		local rotation = nodeData.rotation  -- Quaternion: #(i, j, k, w)
		
		-- Scale translation from Halo units to 3ds Max units
		local scaledTranslation = [translation[1], translation[2], translation[3]] * HALO_SCALE
		
		-- Apply quaternion directly (matching old importer - no negation)
		local rotQuat = normalize (quat rotation[1] rotation[2] rotation[3] rotation[4])
		
		-- Apply transform in parent-local space (separate statements match old script)
		in coordsys parent nodeObj.rotation = rotQuat
		in coordsys parent nodeObj.pos = scaledTranslation
		
		--format "  Applied transform to '%'\n" nodeName
	)
	
	--format "[✓] Transforms applied\n"
	
	-- Third pass: Convert spheres/helpers to bones for bip01 nodes
	--format "\n=== CONVERTING TO BONES ===\n"
	
	for i = 1 to createdNodes.count do
	(
		local nodeObj = createdNodes[i]
		if nodeObj == undefined then continue
		
		local nodeData = nodeDataArray[i]
		local nodeName = nodeData.name
		local firstChild = nodeData.firstChildNode
		local parentIndex = nodeData.parentNode
		local translation = nodeData.translation
		local rotation = nodeData.rotation
		
		if isNodeObject nodeObj then
		(
			-- Get current WORLD position (already transformed)
			local nodeWorldPos = nodeObj.pos
			
			-- Determine bone end position in WORLD space
			local boneEndPos
			if firstChild >= 0 and firstChild < createdNodes.count then
			(
				local childObj = createdNodes[firstChild + 1]
				if childObj != undefined then
					boneEndPos = childObj.pos  -- Use world position
				else
					boneEndPos = nodeWorldPos + [BONE_SIZE, 0, 0]
			)
			else
			(
				boneEndPos = nodeWorldPos + [BONE_SIZE, 0, 0]
			)
			
			-- Create bone using WORLD positions
			local myBone = BoneSys.createBone nodeWorldPos boneEndPos [0, 0, 1]
			myBone.name = nodeName
			myBone.wirecolor = color 255 180 6 --#ffb406
			myBone.width = BONE_SIZE
			myBone.height = BONE_SIZE
			myBone.setBoneEnable false 0  -- Disable bone scaling on X axis
			myBone.setBoneEnable false 1  -- Disable bone scaling on Y axis  
			myBone.setBoneEnable false 2  -- Disable bone scaling on Z axis
			
			if firstChild >= 0 then
				myBone.taper = 70
			else
				myBone.taper = 50
			
			-- Apply special bone handling (matches old importer)
			local lowerName = toLower nodeName
			
			if lowerName == "bip01 spine1" then
			(
				myBone.length *= 0.8
				myBone.width = BONE_SIZE
				myBone.height = BONE_SIZE / 2.0
				myBone.taper = -180
			)
			else if lowerName == "bip01 pelvis" or lowerName == "bip01 spine" then
			(
				myBone.width = BONE_SIZE
				myBone.height = BONE_SIZE / 2.0
				myBone.taper = -180
			)
			else if lowerName == "frame bone24" then
			(
				myBone.length = BONE_SIZE * 4
				myBone.width = BONE_SIZE * 4
				myBone.height = BONE_SIZE * 4
				myBone.taper = 100
			)
			else if lowerName == "frame l wriste" or lowerName == "frame r wriste" then
			(
				myBone.length = 2.8
				myBone.width = BONE_SIZE
				myBone.height = BONE_SIZE * 0.3
				myBone.taper = -270
			)
			else if lowerName == "frame l forearm" or lowerName == "frame r forearm" then
			(
				myBone.width = BONE_SIZE * 2
				myBone.height = BONE_SIZE * 2
			)
			else if lowerName == "frame l upperarm" or lowerName == "frame r upperarm" then
			(
				myBone.width = BONE_SIZE * 3
				myBone.height = BONE_SIZE * 3
			)
			
			-- Delete old object and replace in array
			delete nodeObj
			createdNodes[i] = myBone
			
			-- Assign bone to "Nodes" layer
			local nodesLayer = LayerManager.getLayerFromName "Nodes"
			if nodesLayer == undefined then
				nodesLayer = LayerManager.newLayerFromName "Nodes"
			nodesLayer.addNode myBone
			
			-- Set parent (matches old script line 1061)
			if parentIndex >= 0 and parentIndex < createdNodes.count then
			(
				local parentObj = createdNodes[parentIndex + 1]
				if parentObj != undefined then
				(
					myBone.parent = parentObj
				)
			)
			
			-- Re-apply transforms (matches old script lines 1063-1064 exactly)
			local scaledTranslation = [translation[1], translation[2], translation[3]] * HALO_SCALE
			local rotQuat = normalize (quat (-rotation[1]) (-rotation[2]) (-rotation[3]) rotation[4])
			in coordsys parent myBone.rotation = rotQuat
			in coordsys parent myBone.pos = scaledTranslation
			
			--format "  Converted '%' to bone\n" nodeName
		)
		else
		(
			-- For non-bone nodes, re-link parent if needed
			if parentIndex >= 0 and parentIndex < createdNodes.count then
			(
				local parentObj = createdNodes[parentIndex + 1]
				if parentObj != undefined then
				(
					nodeObj.parent = parentObj
				)
			)
		)
	)
	
	--format "[✓] Bone conversion complete\n"
)

-- Create all nodes from gbxmodel data
fn createAllNodes nodesArray =
(
	format "\n=== CREATING NODES ===\n"
	format "Total nodes to create: %\n" nodesArray.count
	
	local createdNodes = #()
	
	-- Check if a matching skeleton already exists in the scene
	logger "Checking for matching skeleton...\n" logType:#debug
	local existingSkeleton = findMatchingSkeleton nodesArray
	
	if existingSkeleton != undefined then
	(
		logger "Found existing skeleton! Asking user...\n" logType:#debug
		-- Ask user if they want to reuse the existing skeleton
		local reuseExisting = askReuseSkeletonDialog()
		
		if reuseExisting then
		(
			logger "Reusing existing skeleton from scene\n" logType:#success
			return existingSkeleton
		)
		else
		(
			logger "Creating new skeleton\n" logType:#info
		)
	)
	else
	(
		logger "No matching skeleton found, creating new one\n" logType:#debug
	)
	
	-- First pass: create all nodes
	for i = 1 to nodesArray.count do
	(
		local nodeData = nodesArray[i]
		local nodeObj = createGbxmodelNode nodeData i nodesArray
		
		if nodeObj != undefined then
			append createdNodes nodeObj
		else
			append createdNodes undefined  -- Keep array indices aligned
	)
	
	-- Second pass: link hierarchy
	linkNodeHierarchy createdNodes nodesArray
	
	--format "\n[✓] Created % nodes successfully\n" createdNodes.count
	
	return createdNodes
)

-------------------------------------------------------
-- MARKER CREATION
-------------------------------------------------------

-- Create marker spheres from marker data
-- Markers are positioned relative to their parent nodes
fn createMarkers markersArray nodesArray createdNodes =
(
	--if markersArray.count == 0 then
	--(
	--	format "\n[i] No markers to create\n"
	--	return #()
	--)
	
	--format "\n=== CREATING MARKERS ===\n"
	--format "Total markers to create: %\n" markersArray.count
	
	local createdMarkers = #()
	local markerSize = 1.0  -- Default marker radius (matches old importer's spn_marker.value default)
	
	for i = 1 to markersArray.count do
	(
		local markerData = markersArray[i]
		local markerName = markerData.name
		local nodeIndex = markerData.nodeIndex  -- Node index this marker is attached to
		local rotation = markerData.rotation   -- Quaternion: #(i, j, k, w)
		local translation = markerData.translation -- Position relative to node
		
		-- Marker names in the scene have "#" prefix, but tag data doesn't
		local markerNameWithPrefix = "#" + markerName
		
		--format "[DEBUG MARKER] Checking marker: '%'\n" markerName
		
		-- Check if marker already exists on the target parent node
		local markerExists = false
		if nodeIndex >= 0 and nodeIndex < createdNodes.count then
		(
			local parentNode = createdNodes[nodeIndex + 1]
			if parentNode != undefined then
			(
				--format "[DEBUG MARKER] Parent node: '%' has % children\n" parentNode.name parentNode.children.count
				
				-- Check if a marker with this name already exists as a child of this node
				for child in parentNode.children do
				(
					--format "[DEBUG MARKER]   Child: '%' (class: %)\n" child.name (classOf child)
					
					if child.name == markerNameWithPrefix then
					(
						markerExists = true
						append createdMarkers child  -- Add existing marker to the array
						--format "[DEBUG MARKER] Marker '%' already exists on '%', skipping\n" markerNameWithPrefix parentNode.name
						exit
					)
				)
			)
		)
		
		-- Skip creating this marker if it already exists
		if markerExists then
		(
			--format "[DEBUG MARKER] Skipping duplicate marker '%'\n" markerNameWithPrefix
			continue
		)
		
		--format "[DEBUG MARKER] Creating new marker '%'\n" markerName
		
		-- Create marker using Halo Helper (createHaloHelper handles the "#" prefix automatically)
		local markerObj = createHaloMarker \
			pos:[0,0,0] \
			radius:markerSize \
			markerType:"Marker" \
			name:markerName \
			wireColor:(color 0 240 255)  --#00f0ff
		
		--format "[DEBUG MARKER] Created marker with name: '%'\n" markerObj.name
		
		-- Assign to "Markers" layer
		local markersLayer = LayerManager.getLayerFromName "Markers"
		if markersLayer == undefined then
			markersLayer = LayerManager.newLayerFromName "Markers"
		markersLayer.addNode markerObj
		
		-- Link to corresponding node
		if nodeIndex >= 0 and nodeIndex < createdNodes.count then
		(
			local parentNode = createdNodes[nodeIndex + 1]  -- Convert 0-based to 1-based
			if parentNode != undefined then
			(
			markerObj.parent = parentNode
			
			-- Apply transform in parent-local space
			-- Note: Translation is already scaled in the tag data, don't scale again
			local rotQuat = normalize (quat (-rotation[1]) (-rotation[2]) (-rotation[3]) rotation[4])
			
			in coordsys parent (
				markerObj.rotation = rotQuat
				markerObj.pos = [translation[1], translation[2], translation[3]] * HALO_SCALE
			)
			
			--format "  Created marker '%' linked to '%'\n" markerObj.name parentNode.name
			)
			else
			(
				format "  [!] Warning: Parent node undefined for marker '%'\n" markerName
			)
		)
		else
		(
			format "  [!] Warning: Invalid node index % for marker '%'\n" nodeIndex markerName
		)
		
		append createdMarkers markerObj
	)
	
	--format "Created % markers successfully\n" createdMarkers.count
	
	return createdMarkers
)

-------------------------------------------------------
-- MATERIAL CREATION
-------------------------------------------------------

-- Create Multi/Sub-Object material from shader data
fn createMaterial shadersArray materialName:"Gbxmodel Materials" =
(
	if shadersArray.count == 0 then
	(
		format "\n[i] No shaders to create materials from\n"
		return undefined
	)
	
	--format "\n=== CREATING MATERIALS ===\n"
	--format "Total shaders: %\n" shadersArray.count
	
	-- Create Multi/Sub-Object material
	local multiMat = MultiMaterial numsubs:shadersArray.count
	multiMat.name = materialName
	
	for i = 1 to shadersArray.count do
	(
		local shaderData = shadersArray[i]
		local shaderName = shaderData.shaderName  -- Shader name (extracted from path)
		
		-- Create a standard material for this shader
		local mat = StandardMaterial()
		mat.name = shaderName
		mat.showInViewport = true
		
		-- Apply checker pattern by default
		local checkerMap = Checker()
		checkerMap.color1 = color 25 25 25    --#191919
		checkerMap.color2 = color 136 136 136  --#888888
		checkerMap.coordinates.U_Tiling = 10.0
		checkerMap.coordinates.V_Tiling = 10.0
		
		mat.diffusemap = checkerMap
		mat.showInViewport = true
		
		-- Set material in Multi/Sub-Object
		multiMat.materialList[i] = mat
		multiMat.names[i] = shaderName
		multiMat.materialIDList[i] = i
		
		--format "  Material %: '%'\n" i shaderName
	)
	
	-- Assign to meditMaterials slot 1 (Material Editor)
	meditMaterials[1] = multiMat
	
	--format "[✓] Created Multi/Sub-Object material with % sub-materials\n" shadersArray.count
	
	return multiMat
)

-------------------------------------------------------
-- Create Multi/Sub-Object material with textures resolved from shader tags
fn createMaterialWithTextures gbxmodelPath shadersArray materialName:"Gbxmodel Materials" =
(
	if shadersArray.count == 0 then
	(
		format "\n[i] No shaders to create materials from\n"
		return undefined
	)
	
	-- Resolve shader textures
	local textureResults = resolveAllShaderTextures gbxmodelPath shadersArray
	
	-- If shader module loading failed, textureResults will be empty
	-- Create dummy results so material creation can continue
	if textureResults.count == 0 and shadersArray.count > 0 then
	(
		logger "Shader texture resolution failed, using fallback materials\n" logType:#warning
		for i = 1 to shadersArray.count do
		(
			struct DummyResult (shaderIndex, shaderName, shaderType, shaderPath, shaderFilePath, baseMapPath, textureFilePath, success = false)
			local dummy = DummyResult()
			dummy.shaderIndex = i - 1
			dummy.shaderName = shadersArray[i].shaderName
			append textureResults dummy
		)
	)
	
	-- Create Multi/Sub-Object material
	local multiMat = MultiMaterial numsubs:shadersArray.count
	multiMat.name = materialName
	
	for i = 1 to shadersArray.count do
	(
		local shaderData = shadersArray[i]
		local shaderName = shaderData.shaderName
		
		-- Find the corresponding texture result by shader index (not array position)
		local textureResult = undefined
		for result in textureResults where result != undefined and result.shaderIndex == (i - 1) do
		(
			textureResult = result
			exit
		)
		
		-- Create a standard material for this shader
		local mat = StandardMaterial()
		mat.name = shaderName
		mat.showInViewport = true
		
		-- Apply diffuse texture if resolved successfully
		if textureResult != undefined and textureResult.success and doesFileExist textureResult.textureFilePath then
		(
			local diffuseMap = Bitmaptexture fileName:textureResult.textureFilePath
			mat.diffusemap = diffuseMap
			mat.showInViewport = true
			
			-- For transparent shaders, also apply the texture to opacity channel
			-- This helps visualize alpha channel transparency
			if textureResult.shaderType == "shader transparent glass" or \
				textureResult.shaderType == "shader transparent chicago" or \
				textureResult.shaderType == "shader transparent chicago extended" or \
				textureResult.shaderType == "shader transparent generic" then
			(
				local opacityMap = Bitmaptexture fileName:textureResult.textureFilePath
				-- Use image alpha channel (0=Image Alpha, 1=RGB Intensity, 2=None (opaque))
				opacityMap.alphaSource = 2 
				mat.opacitymap = opacityMap
			)
			
			if textureResult.shaderType == "shader transparent meter" or \
				textureResult.shaderType == "shader transparent water" then
			(
				local opacityMap = Bitmaptexture fileName:textureResult.textureFilePath
				
				opacityMap.rgbOutput = 1
				mat.opacitymap = opacityMap
			)

			--logger "Applied texture to material '%': %\n" params:#(shaderName, textureResult.textureFilePath) logType:#success
		)
		else
		(
			-- Apply checker pattern for missing textures
			local checkerMap = Checker()
			checkerMap.color1 = color 25 25 25    --#191919
			checkerMap.color2 = color 136 136 136  --#888888
			checkerMap.coordinates.U_Tiling = 10.0
			checkerMap.coordinates.V_Tiling = 10.0
			
			mat.diffusemap = checkerMap
			mat.showInViewport = true
						--logger "Applied checker pattern to material '%' (texture not found)\n" params:#(shaderName) logType:#info
		)
		
		-- Set material in Multi/Sub-Object
		multiMat.materialList[i] = mat
		multiMat.names[i] = shaderName
		multiMat.materialIDList[i] = i
	)
	
	-- Assign to meditMaterials slot 1 (Material Editor)
	meditMaterials[1] = multiMat
	
	return multiMat
)


logger "Scene Builder loaded.\n" logType:#success
