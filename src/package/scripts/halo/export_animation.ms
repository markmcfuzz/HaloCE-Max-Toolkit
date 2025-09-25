-- Halo Custom Edition Animation Exporter
-- Version 2.0.0
-- Created by ZTeam, CtrlAltDestroy
-- Contributions by:
-- 
-- Sledmine
-- Mata
-- Mark Mc'Fuzz
------------------------------------------------------------------------------------------------
-- Features:
-- - Supports all 3ds Max versions
-- - Supports nodes with name prefixes "frame", "bip01", and "b_"
-- - Exports without UI
-- - Add validations for common user errors
------------------------------------------------------------------------------------------------
-- Free to modify for any purpose, as long as credit is given to the original authors.
------------------------------------------------------------------------------------------------
-- Visit the project on GitHub (https://github.com/Sledmine/bluestreak)
------------------------------------------------------------------------------------------------
-- This program is free software; you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by the
-- Free Software Foundation; either version 2 of the License, or (at your
-- option) any later version. This program is distributed in the hope that
-- it will be useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
-- the GNU General Public License for more details. A full copy of this
-- license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

maxVer = undefined
outputPath = undefined
outputFile = undefined

frameCount = 0
nodeListChecksum = 0
nodeNames = #()
nodeArray = #()
nodeArraySorted = #()
nodeChildIndices = #()
nodeFirstChildIndices = #()
nodeNextSiblingIndices = #()
rootSceneNode = undefined

-- Animation export configuration
setChecksumToZero = true  -- Set to false if you want to calculate the actual checksum
exportMethod = "file"     -- "file" or "listener"

print "Starting Animation Export..."
-- Function to calculate node list checksum
fn calcNodeListChecksum =
(
	nodeListCheck = 0
	for i = 1 to nodeArraySorted.count do
	(
		nodeCheck = 0
		for j = 1 to nodeArraySorted[i].name.count do (nodeCheck += bit.charAsInt nodeArraySorted[i].name[j])
		nodeCheck *= (nodeArraySorted.count * (nodeFirstChildIndices[i] + nodeNextSiblingIndices[i]))
		nodeListCheck += nodeCheck
	)
	return nodeListCheck
)
-- Function to flush instances
fn flushInstances =
(
	frameCount = 0
	nodeListChecksum = 0
	nodeNames = #()
	nodeArray = #()
	nodeArraySorted = #()
	nodeChildIndices = #()
	nodeFirstChildIndices = #()
	nodeNextSiblingIndices = #()
	rootSceneNode = undefined
)
-- Function to index nodes
fn indexNodes =
(
	failed = false
	
	try
	(
		nodeArray = (($'bip01*' as array) + ($'b_*' as array) + ($'frame*' as array))--this is the actual initial sort order the next sort func takes, This order is evaluated as hierarchy for some reason
		nodeArray = for i in nodeArray where (not i.isHidden) collect i
		
		-- Check if we have any valid nodes at all
		if nodeArray.count == 0 then (
			failed = true
			messageBox ("Animation export failed:\n\nNo valid nodes (frame| bip01| b_) were found in the scene.") title:"Export Error"
			--print "No valid nodes found in scene. Nodes must have names starting with 'frame', 'bip01', or 'b_'"
			return failed
		)
		
		--print ("Found " + (nodeArray.count as string) + " potential animation nodes")
		
		-- Check for duplicate node names (after prefix)
		local nodeBasenames = #()
		local nodeFullNames = #()
		for w = 1 to nodeArray.count do
		(
			currentNodeName = nodeArray[w].name
			local basename = ""
			
			-- Extract the name after the prefix
			if ((substring currentNodeName 1 2 as name) == ("b_" as name)) then (
				basename = substring currentNodeName 3 -1
			) else if ((substring currentNodeName 1 5 as name) == ("bip01" as name)) then (
				basename = substring currentNodeName 6 -1
			) else if ((substring currentNodeName 1 5 as name) == ("frame" as name)) then (
				basename = substring currentNodeName 6 -1
			)
			
			-- Check if this basename already exists
			local duplicateIndex = findItem nodeBasenames basename
			if (duplicateIndex != 0) then (
				failed = true
				messageBox ("Duplicate node name found:\n\nMultiple nodes have the same name after their prefix: '" + basename + "'\n\nConflicting nodes:\n- " + nodeFullNames[duplicateIndex] + "\n- " + currentNodeName + "\n\nEach node must have a unique name after the prefix (frame*, bip01*, b_*)") title:"Export Error"
				exit
			)
			
			-- Add basename and full name to our tracking arrays
			append nodeBasenames basename
			append nodeFullNames currentNodeName
		)
		
		-- Validate all node names and parent relationships
		for w = 1 to nodeArray.count do
		(
			-- Check if current node has valid name
			currentNodeName = nodeArray[w].name
			if (((substring currentNodeName 1 2 as name) != ("b_" as name)) and
				((substring currentNodeName 1 5 as name) != ("bip01" as name)) and
				((substring currentNodeName 1 5 as name) != ("frame" as name))) then (
				failed = true
				
				messageBox ("Invalid node name:\n\n " + currentNodeName + ". Node names must start with 'frame', 'bip01', or 'b_'") title:"Export Error"
				--print ("Node '" + currentNodeName + "' has invalid name. Node names
				exit
			)
			
			-- Check parent node names if parent exists
			if (nodeArray[w].parent != undefined) then
			(
				parentNodeName = nodeArray[w].parent.name
				if (((substring parentNodeName 1 2 as name) != ("b_" as name)) and
				((substring parentNodeName 1 5 as name) != ("bip01" as name)) and
				((substring parentNodeName 1 5 as name) != ("frame" as name))) then (
					failed = true
					messageBox ("Invalid parent node found:\n\nNode '" + currentNodeName + "' has invalid parent name: '" + parentNodeName + "'.\n\nAll nodes must have names starting with 'frame', 'bip01', or 'b_'\n") title:"Export Error"
					exit
				)
			)
			
			-- Check all children of current node for invalid names
			for c = 1 to nodeArray[w].children.count do
			(
				childNode = nodeArray[w].children[c]
				if (childNode != undefined) then
				(
					childNodeName = childNode.name
					-- Skip validation for editable mesh and editable poly objects
					local childClass = classOf childNode
					local childBaseClass = classOf childNode.baseObject
					
					-- Skip validation for editable mesh, editable poly objects, and markers (names starting with '#')
					if (childClass != Editable_mesh and childClass != Editable_Poly and 
						childBaseClass != Editable_mesh and childBaseClass != Editable_Poly and
						((substring childNodeName 1 1 as name) != ("#" as name))) then (
						-- Check if child has invalid name (not following the naming convention)
						if (((substring childNodeName 1 2 as name) != ("b_" as name)) and
							((substring childNodeName 1 5 as name) != ("bip01" as name)) and
							((substring childNodeName 1 5 as name) != ("frame" as name))) then (
							failed = true
							messageBox ("Invalid child node found:\n\nParent: " + currentNodeName + "\nChild: " + childNodeName + "\n\nAll nodes must have names starting with 'frame', 'bip01', or 'b_'\n\n(Editable mesh/poly objects and markers are excluded from this check)\n") title:"Export Error"
							exit
						)
					)
				)
			)
		)
		
		-- Additional validation: Check all objects in scene for invalid children of animation nodes
		if not failed then (
			print "Performing comprehensive child node validation..."
			allSceneObjects = objects as array
			for obj in allSceneObjects do (
				if (obj.parent != undefined) then (
					-- Check if parent is an animation node
					parentName = obj.parent.name
					if (((substring parentName 1 2 as name) == ("b_" as name)) or
						((substring parentName 1 5 as name) == ("bip01" as name)) or
						((substring parentName 1 5 as name) == ("frame" as name))) then (
						
						-- Skip validation for editable mesh, editable poly objects, and markers (names starting with '#')
						local objClass = classOf obj
						local objBaseClass = classOf obj.baseObject
						
						if (objClass != Editable_mesh and objClass != Editable_Poly and 
							objBaseClass != Editable_mesh and objBaseClass != Editable_Poly and
							((substring obj.name 1 1 as name) != ("#" as name))) then (
							-- Parent is animation node, check if child follows naming convention
							childName = obj.name
							if (((substring childName 1 2 as name) != ("b_" as name)) and
								((substring childName 1 5 as name) != ("bip01" as name)) and
								((substring childName 1 5 as name) != ("frame" as name))) then (
								failed = true
								messageBox ("Invalid object linked to animation hierarchy:\n\nAnimation Parent: " + parentName + "\nInvalid Child: " + childName + "\n\nAll objects linked to animation nodes must follow the naming convention (frame*, bip01*, b_*).\n(Editable mesh/poly objects and markers are excluded from this check)\n\nPlease unlink this object or rename it properly.") title:"Export Error"
								exit
							)
						)
					)
				)
			)
		)
		
		-- Check for orphaned animation-named objects not in nodeArray
		if not failed then (
			print "Checking for orphaned animation nodes..."
			allSceneObjects = objects as array
			for obj in allSceneObjects do (
				objName = obj.name
				-- Skip validation for editable mesh and editable poly objects
				local objClass = classOf obj
				local objBaseClass = classOf obj.baseObject
				
				if (objClass != Editable_mesh and objClass != Editable_Poly and 
					objBaseClass != Editable_mesh and objBaseClass != Editable_Poly) then (
					-- Check if object has animation naming but isn't in our nodeArray
					if (((substring objName 1 2 as name) == ("b_" as name)) or
						((substring objName 1 5 as name) == ("bip01" as name)) or
						((substring objName 1 5 as name) == ("frame" as name))) then (
						-- Object has animation naming, check if it's in our nodeArray
						if (findItem nodeArray obj == 0) then (
							-- Object with animation name not found in nodeArray (might be hidden or have issues)
							if obj.isHidden then (
								print ("Warning: Animation node '" + objName + "' is hidden and will be excluded from export")
							) else (
								failed = true
								messageBox ("Orphaned animation node found:\n\n" + objName + "\n\nThis object has animation naming but couldn't be processed.\nPlease check if it's properly linked to the hierarchy.\n(Note: Editable mesh/poly objects are excluded from this check)") title:"Export Error"
								exit
							)
						)
					)
				)
			)
		)
		
		if not failed then
		(
			for i = 1 to nodeArray.count do
			(
				if (nodeArray[i].parent == undefined) then
				(
					if (rootSceneNode != undefined) then
					(
						failed = true
						print "nodes have wrong hierarchy"
						exit
					)
					else
					(
						rootSceneNode = nodeArray[i]
						nodeArray[i].name = ("01" + nodeArray[i].name)
					)
				)
				else
				(
					tempParentNode = nodeArray[i].parent
					n = 1
					do
					(
						tempRootSceneNode = tempParentNode
						tempParentNode = tempParentNode.parent
						n += 1
					)
					while (tempParentNode != undefined)
					
					if (tempRootSceneNode != rootSceneNode) then
					(
						failed = true
						print "root node doesnt match with hierarchy parent"
						exit
					)
					else
					(
						if n < 10 then (nodeArray[i].name = ("0" + (n as string) + nodeArray[i].name))
						else (nodeArray[i].name = ((n as string) + nodeArray[i].name))
					)
				)
			)
			
			-- Validate that we have a root node
			if (rootSceneNode == undefined) then (
				failed = true
				print "No root node found. At least one node must have no parent (root of hierarchy)"
				return failed
			)
			
			print ("Root node found: " + rootSceneNode.name)
			
			if not failed then
			(
				nodeNames = for j in nodeArray collect j.name
				sort nodeNames
				for k = 1 to nodeArray.count do (nodeArraySorted[k] = getNodeByName nodeNames[k])
				for h = 1 to nodeArray.count do (nodeArray[h].name = (substring nodeArray[h].name 3 -1))
				nodeNames = for j in nodeArray collect j.name
				
				for b = 1 to nodeArraySorted.count do
				(
					tempNodeChildIndices = #()
					for c = 1 to nodeArraySorted[b].children.count do
					(
						tempNodeChild = nodeArraySorted[b].children[c]
						if (tempNodeChild != undefined) then
						(
							tempChildIndex = findItem nodeArraySorted tempNodeChild
							if	(tempChildIndex != 0) then (append tempNodeChildIndices tempChildIndex)
						)
					)
					nodeChildIndices[b] = tempNodeChildIndices
					if (nodeChildIndices[b].count == 0) then (nodeFirstChildIndices[b] = 0)
					else
					(
						sort nodeChildIndices[b]
						nodeFirstChildIndices[b] = nodeChildIndices[b][1]
					)
				)
				
				nodeNextSiblingIndices[1] = 0
				for s = 1 to nodeChildIndices.count do
				(
					if ((nodeChildIndices[s].count < 2) and (nodeChildIndices[s][1] != undefined)) then (nodeNextSiblingIndices[nodeChildIndices[s][1]] = 0)
					else
					(
						for f = 1 to nodeChildIndices[s].count do
						(
							if (f == nodeChildIndices[s].count) then (nodeNextSiblingIndices[nodeChildIndices[s][f]] = 0)
							else (nodeNextSiblingIndices[nodeChildIndices[s][f]] = nodeChildIndices[s][f + 1])
						)
					)
				)
				
				-- Final validation: ensure we have valid sorted nodes
				if (nodeArraySorted.count == 0) then (
					failed = true
					print "Node sorting failed - no valid nodes available for animation export"
					return failed
				)
				
				print ("Successfully processed " + (nodeArraySorted.count as string) + " animation nodes")
			)
		)
		if failed then
		(
			for i in nodeArray do
			(
				if (((substring i.name 1 2 as name) != ("b_" as name)) and
				((substring i.name 1 5 as name) != ("bip01" as name)) and
				((substring i.name 1 5 as name) != ("frame" as name))) then (
					i.name = (substring i.name 3 -1)
				)
				nodeNames = #()
				nodeArraySorted = #()
			)
		)
		
	)
	catch
	(
		failed = true
	)
	
	return failed
)
-- Function to write animation data
fn writeAnim target =
(
	frameCount = ((animationRange.end as integer)/160) + 1
	nodeListChecksum = 0
	if (not setChecksumToZero) then (
		nodeListChecksum = calcNodeListChecksum()
	)
	
	format "%\n" 16392 to:target
	format "%\n" frameCount to:target
	format "%\n" frameRate to:target
	format "%\n" 1 to:target
	format "%\n" "unnamedActor" to:target
	format "%\n" nodeArraySorted.count to:target
	format "%\n" nodeListChecksum to:target
	
	for i = 1 to nodeArraySorted.count do
	(
		format "%\n" nodeArraySorted[i].name to:target
		format "%\n" (nodeFirstChildIndices[i] - 1) to:target
		format "%\n" (nodeNextSiblingIndices[i] - 1) to:target
	)
	
	tempNodes = #()
	for a = 1 to nodeArraySorted.count do
	(
		tempNode = Box length:0.5 width:0.5 height:0.5
		tempNode.name = ("temp__" + nodeArraySorted[a].name)
		tempNode.wirecolor = color 255 0 0
		tempNodes[a] = tempNode
	)
	for b = 1 to tempNodes.count do
	(
		try (tempNodes[b].parent = tempNodes[(findItem nodeArraySorted nodeArraySorted[b].parent)])
		catch ()
	)
	
	max tool animmode
	set animate on
	
	sliderTime = 0
	for j = 1 to frameCount do
	(
		for d = 1 to tempNodes.count do (tempNodes[d].transform = nodeArraySorted[d].transform)
		for k = 1 to nodeArraySorted.count do
		(
			in coordsys parent nodePosition = tempNodes[k].pos
			in coordsys parent tempNodeRotation = tempNodes[k].rotation
			nodeRotation = quat -tempNodeRotation.x -tempNodeRotation.y -tempNodeRotation.z tempNodeRotation.w
			in coordsys parent nodeScale = (tempNodes[k].scale.x + tempNodes[k].scale.y + tempNodes[k].scale.z)/3
			
			format "%\t%\t%\n" nodePosition.x nodePosition.y nodePosition.z to:target
			format "%\t%\t%\t%\n" nodeRotation.x nodeRotation.y nodeRotation.z nodeRotation.w to:target
			format "%\n" nodeScale to:target
		)
		if (j != frameCount) do (sliderTime += 1)
	)
	
	max tool animmode
	set animate off
	try (delete tempNodes)
	catch ()
	tempNodes = #()
	
	sliderTime = 0
)
-- Get 3ds Max version info
maxVer = maxVersion ()
maxVer = maxVer[1]/1000.0
maxVerStr = maxVer as string
if (maxVer == 4.2) then (maxVerStr += " (gmax)")

-- Determine export method based on Max version
if (maxVer <= 4.2) then (
	exportMethod = "listener"  -- Force listener for older versions
)

-- Execute the export
flushInstances ()

-- Check if we have any animation range
if (animationRange.end <= animationRange.start) then (
	messageBox ("No animation range set!\n\nPlease set up your animation timeline before exporting.\nCurrent range: " + (animationRange.start as string) + " to " + (animationRange.end as string)) title:"Animation Error"
) else (
	print ("Animation range: frames " + (animationRange.start as string) + " to " + (animationRange.end as string))
	
	-- Validate keyframe information
	print "Validating keyframe data..."
	local hasValidKeyframes = false
	local totalKeyframes = 0
	local nodesWithKeyframes = 0
	
	-- Get potential animation nodes for keyframe checking
	local animNodes = (($'bip01*' as array) + ($'b_*' as array) + ($'frame*' as array))
	animNodes = for n in animNodes where (not n.isHidden) collect n
	
	if animNodes.count > 0 then (
		for animNode in animNodes do (
			local nodeHasKeys = false
			local nodeKeyCount = 0
			
			-- Check position keys
			if (animNode.pos.controller != undefined and animNode.pos.controller.keys != undefined) then (
				if animNode.pos.controller.keys.count > 0 then (
					nodeHasKeys = true
					nodeKeyCount += animNode.pos.controller.keys.count
				)
			)
			
			-- Check rotation keys
			if (animNode.rotation.controller != undefined and animNode.rotation.controller.keys != undefined) then (
				if animNode.rotation.controller.keys.count > 0 then (
					nodeHasKeys = true
					nodeKeyCount += animNode.rotation.controller.keys.count
				)
			)
			
			-- Check scale keys (if scale controller exists)
			if (animNode.scale != undefined and animNode.scale.controller != undefined and animNode.scale.controller.keys != undefined) then (
				if animNode.scale.controller.keys.count > 0 then (
					nodeHasKeys = true
					nodeKeyCount += animNode.scale.controller.keys.count
				)
			)
			
			if nodeHasKeys then (
				nodesWithKeyframes += 1
				totalKeyframes += nodeKeyCount
				hasValidKeyframes = true
			)
		)
		
		print ("Keyframe validation results:")
		print ("- Nodes with keyframes: " + (nodesWithKeyframes as string) + " of " + (animNodes.count as string))
		print ("- Total keyframes found: " + (totalKeyframes as string))
		
		if not hasValidKeyframes then (
			messageBox ("No keyframes found!\n\nNone of the animation nodes have keyframe data.\n\nTo create valid animation:\n1. Select your animation nodes\n2. Set the timeline to frame 0\n3. Click 'Auto Key' button\n4. Move/rotate nodes and set keyframes\n5. Move timeline and set more keyframes\n\nNodes checked: " + (animNodes.count as string)) title:"Animation Error"
		) else if nodesWithKeyframes < animNodes.count then (
			local noKeyframeNodes = #()
			for animNode in animNodes do (
				local hasKeys = false
				if (animNode.pos.controller != undefined and animNode.pos.controller.keys != undefined and animNode.pos.controller.keys.count > 0) then hasKeys = true
				if (animNode.rotation.controller != undefined and animNode.rotation.controller.keys != undefined and animNode.rotation.controller.keys.count > 0) then hasKeys = true
				if (animNode.scale != undefined and animNode.scale.controller != undefined and animNode.scale.controller.keys != undefined and animNode.scale.controller.keys.count > 0) then hasKeys = true
				if not hasKeys then (
					append noKeyframeNodes animNode.name
				)
			)
			print ("Warning: Some animation nodes have no keyframes:")
			for nodeName in noKeyframeNodes do (
				print ("  - " + nodeName)
			)
		)
	)
	
	if hasValidKeyframes then (
		print "Validating scene nodes..."
		failed = indexNodes ()
		if failed then (
			print "Animation export failed"
			--messageBox ("Animation export failed!\n\nPlease check the Listener window for details.\n\nCommon issues:\n• No nodes with valid names (frame*, bip01*, b_*)\n• Missing root node in hierarchy\n• Invalid parent-child relationships") title:"Export Error"
		) else (
		if (exportMethod == "listener") then (
		-- Export to listener
		try (
			clearListener ()
			format "-----animation starts here---------------------------------------------\n\n" to:listener
			writeAnim listener
			format "-----animation ends here---------------------------------------------\n\n" to:listener
			messageBox "Animation exported to Listener window" title:"Export Complete"
		)
		catch (messageBox "Animation export failed" title:"Error")
	) else (
		-- Export to file
		outputPath = getSaveFileName	caption:"Save Animation Source File" \
										types:"JMA file (*.JMA)|*.JMA|JMO file (*.JMO)|*.JMO|JMR file (*.JMR)|*.JMR|JMM file (*.JMM)|*.JMM|JMT file (*.JMT)|*.JMT|JMW file (*.JMW)|*.JMW|JMZ file (*.JMZ)|*.JMZ|All files (*.*)|*.*|"
		if (outputPath != undefined) then (
			lastPath = getFilenamePath outputPath
			outputFile = createFile outputPath
			if (outputFile != undefined) then (
				try (
					writeAnim outputFile
					messageBox ("Animation exported successfully to:\n\n" + outputPath) title:"Export Complete"
				)
				catch (messageBox "Animation export failed" title:"Error")
				try (close outputFile)
				catch ()
			) else (
				messageBox "File creation failed" title:"Error"
			)
		) else (
			messageBox "Export cancelled by user" title:"Export Cancelled"
		)
		)
	)
	)
)
flushInstances ()