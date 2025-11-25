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

-------------------------------------------------------
-- Sphere orientation function
-------------------------------------------------------

fn orientMassPointSphere sphereObj forwardVec upVec =
(
    try
    (
        local currentPos = sphereObj.transform.row4
        local rightVec = cross upVec forwardVec
        local transformMatrix = matrix3 forwardVec rightVec upVec currentPos

        sphereObj.transform = transformMatrix
        
        return true
    )
    catch (e)
    (
        return false
    )
)

-------------------------------------------------------
-- Mass Point Custom Attributes UI
-------------------------------------------------------

massPointAttributes = attributes "Mass Point Properties"
(
	parameters massPointParams rollout:massPointRollout
	(
		mpName type:#string ui:etName default:""
		poweredMassPointName type:#string ui:etPoweredMassPoint default:""
		modelNodeIndex type:#integer ui:spModelNode default:-1
		linkedNodeName type:#string ui:etLinkedNode default:""
		
		relativeMass type:#float ui:spRelativeMass default:0.0
		massValue type:#float ui:spMass default:0.0
		relativeDensity type:#float ui:spRelativeDensity default:0.0
		densityValue type:#float ui:spDensity default:0.0
		
		frictionType type:#string ui:etFrictionType default:"point"
		frictionParallel type:#float ui:spFrictionPara default:0.0
		frictionPerpendicular type:#float ui:spFrictionPerp default:0.0
		
		isMetallic type:#boolean ui:chkMetallic default:false
	)
	
	rollout massPointRollout "Mass Point Data"
	(
		editText etName "Name" readOnly:true
		
		editText etPoweredMassPoint "Powered MP:" readOnly:true
		
		spinner spModelNode "Node Index:" type:#integer range:[-1,64,0] readOnly:true
		
		editText etLinkedNode "Linked to:" readOnly:true
		
		checkbox chkMetallic "Metallic" enabled:false
		
		spinner spRelativeMass "Rel. Mass:" type:#float range:[0,10000,0] readOnly:true
		spinner spMass "Mass:" type:#float range:[0,10000,0] readOnly:true
		spinner spRelativeDensity "Rel. Density:" type:#float range:[0,10000,0] readOnly:true
		spinner spDensity "Density:" type:#float range:[0,10000,0] readOnly:true
		
		editText etFrictionType "Friction Type:" readOnly:true
		
		spinner spFrictionPara "Parallel:" type:#float range:[0,1000,0] readOnly:true
		spinner spFrictionPerp "Perpendicular:" type:#float range:[0,1000,0] readOnly:true
	)
)

-------------------------------------------------------
-- Node collection and linking functions
-------------------------------------------------------

fn collectSceneNodes =
(
    try
    (
        local allNodes = #()

        local frameNodes = for obj in objects where (matchPattern obj.name pattern:"frame*") and (isValidNode obj) collect obj
        
        local boneNodes = for obj in objects where (matchPattern obj.name pattern:"b_*") and (isValidNode obj) collect obj
        
        local bipedNodes = for obj in objects where (matchPattern obj.name pattern:"bip01*") and (isValidNode obj) collect obj
        
        join allNodes frameNodes
        join allNodes boneNodes
        join allNodes bipedNodes
        
        allNodes = for obj in allNodes where not (obj.isHidden or obj.isFrozen) collect obj
        
        return allNodes
    )
    catch (e)
    (
        return #()
    )
)

-------------------------------------------------------
-- Creation spheres
-------------------------------------------------------

fn createMassPointSpheres massPointsArray poweredMassPointsArray =
(
	if massPointsArray == undefined or massPointsArray.count == 0 then
	(
		return undefined
	)
	local sceneNodes = collectSceneNodes()
	local createdSpheres = #()
	for mp in massPointsArray do
	(
		local spherePos = (Point3 mp.position[1] mp.position[2] mp.position[3]) * 100
		local sphereRadius = mp.radius * 100

		local sphereName = "#" + mp.name

		local newSphere = sphere radius:sphereRadius pos:spherePos name:sphereName smooth:on

		local sphereColor = case mp.frictionType of
		(
			0: (color 255 82 13)       --#ff5210 | Orange - point friction (most common)
			1: (color 48 255 203)      --#30ffcb | Cyan - forward friction (wheels/treads)
			2: (color 255 111 133)     --#ff6f85 | Rose - left friction (side forces)
			3: (color 129 255 110)     --#81ff6e | Green - up friction (vertical forces)
			default: (color 255 255 0) --#ffff00 | Yellow - unknown friction type
		)
		newSphere.wirecolor = sphereColor

		local physicsLayer = LayerManager.getLayerFromName "Physics"
		if physicsLayer == undefined then
			physicsLayer = LayerManager.newLayerFromName "Physics"
		physicsLayer.addNode newSphere

		custAttributes.add newSphere massPointAttributes
		
		newSphere.mpName = mp.name
		newSphere.modelNodeIndex = mp.modelNode
		newSphere.relativeMass = mp.relativeMass
		newSphere.massValue = mp.mass
		newSphere.relativeDensity = mp.relativeDensity
		newSphere.densityValue = mp.density
		
		if mp.poweredMassPoint >= 0 and mp.poweredMassPoint < poweredMassPointsArray.count then
		(
			newSphere.poweredMassPointName = poweredMassPointsArray[mp.poweredMassPoint + 1].name
		)
		else
		(
			newSphere.poweredMassPointName = "None"
		)
		local frictionTypeName = case mp.frictionType of
		(
			0: "point"
			1: "forward"
			2: "left"
			3: "up"
			default: "unknown"
		)
		newSphere.frictionType = frictionTypeName
		newSphere.frictionParallel = mp.frictionParallelScale
		newSphere.frictionPerpendicular = mp.frictionPerpendicularScale
		newSphere.isMetallic = (mp.flags == 1)

		orientMassPointSphere newSphere mp.forward mp.up
		if (mp.modelNode >= 0 and mp.modelNode < sceneNodes.count) then
		(
			local targetNode = sceneNodes[mp.modelNode + 1]
			newSphere.parent = targetNode
			newSphere.linkedNodeName = targetNode.name
		)
		else
		(
			newSphere.linkedNodeName = "None"
		)
		append createdSpheres newSphere
	)
	return createdSpheres
)