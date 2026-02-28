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

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())

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
    catch
    (
        return false
    )
)

-------------------------------------------------------
-- Mass Point Custom Attributes UI
-------------------------------------------------------

massPointAttributes = attributes "MassPointProperties"
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
		
		spinner spRelativeMass "Rel. Mass:" type:#float range:[0,10000,1.0] readOnly:true
		spinner spMass "Mass:" type:#float range:[0,10000,1.0] readOnly:true
		spinner spRelativeDensity "Rel. Density:" type:#float range:[0,10000,1.0] readOnly:true
		spinner spDensity "Density:" type:#float range:[0,10000,1.0] readOnly:true
		
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
        -- Collect all valid node objects
        for obj in objects where (classOf obj == Dummy or classOf obj == Point or classOf obj == BoneGeometry) do
        (
            append allNodes obj
        )
        
        -- Filter out hidden or frozen nodes
        allNodes = for obj in allNodes where not (obj.isHidden or obj.isFrozen) collect obj
        
        return allNodes
    )
    catch
    (
        return #()
    )
)

-------------------------------------------------------
-- Creation spheres
-------------------------------------------------------

fn createMassPointSpheres massPointsArray poweredMassPointsArray baseMass baseDensity =
(
	if massPointsArray == undefined or massPointsArray.count == 0 then
	(
		return undefined
	)
	
	-- Calculate base values per unit by summing all relative values
	local totalRelativeMass = 0.0
	local totalRelativeDensity = 0.0
	
	for mp in massPointsArray do
	(
		totalRelativeMass += (getFieldValue mp "relativeMass")
		totalRelativeDensity += (getFieldValue mp "relativeDensity")
	)
	
	local baseMassPerUnit = if totalRelativeMass > 0 then baseMass / totalRelativeMass else 0.0
	local baseDensityPerUnit = if totalRelativeDensity > 0 then baseDensity / totalRelativeDensity else 0.0
	
	local sceneNodes = collectSceneNodes()
	local createdSpheres = #()
	
	for mp in massPointsArray do
	(
		-- Parser returns Point3 objects directly, so use them as-is
		local spherePos = (getFieldValue mp "position") * 100
		local sphereRadius = (getFieldValue mp "radius") * 100

		local sphereName = "+" + (getFieldValue mp "name")
		
		local newSphere = sphere radius:sphereRadius pos:spherePos name:sphereName smooth:on
		local frictionType = getFieldValue mp "frictionType"
		local sphereColor = case frictionType of
		(
			0: (color 255 36 16)       --#ff2410 | Orange - point friction (most common)
			1: (color 0 236 176)       --#00ebb0 | Cyan - forward friction (wheels/treads)
			2: (color 255 33 67)       --#ff2143 | Rose - left friction (side forces)
			3: (color 30 230 0)        --#1ee600 | Green - up friction (vertical forces)
			default: (color 255 255 0) --#ffff00 | Yellow - unknown friction type
		)
		newSphere.wirecolor = sphereColor

		local physicsLayer = LayerManager.getLayerFromName "Physics"
		if physicsLayer == undefined then
			physicsLayer = LayerManager.newLayerFromName "Physics"
		physicsLayer.addNode newSphere

		custAttributes.add newSphere massPointAttributes
		
		-- Calculate individual mass and density using the old working formula
		local mpRelativeMass = getFieldValue mp "relativeMass"
		local mpDensity = getFieldValue mp "density"
		local mpRelativeDensity = getFieldValue mp "relativeDensity"
		local calculatedMass = baseMassPerUnit * mpRelativeMass
		
		-- Density calculation with special cases from old code
		local calculatedDensity = 0.0
		if mpDensity > 0.0 and (abs(mpDensity - (baseDensity * mpRelativeDensity)) < 0.1) then
		(
			-- Stored density appears correct (simple cases)
			calculatedDensity = mpDensity
		)
		else if totalRelativeDensity == massPointsArray.count then
		(
			-- Simple case: all relative densities are 1.0
			calculatedDensity = baseDensity * mpRelativeDensity
		)
		else
		(
			-- Complex case: mixed relative densities
			local referenceMass = 149.266
			local densityModifier = baseMassPerUnit / referenceMass
			calculatedDensity = baseDensity * mpRelativeDensity * densityModifier
		)
		
		-- Set parameter values explicitly after adding custom attributes
		local mpName = getFieldValue mp "name"
		local mpModelNode = getFieldValue mp "modelNode"
		local mpPoweredMassPoint = getFieldValue mp "poweredMassPoint"
		local mpFlags = getFieldValue mp "flags"
		local mpFrictionParallelScale = getFieldValue mp "frictionParallelScale"
		local mpFrictionPerpendicularScale = getFieldValue mp "frictionPerpendicularScale"
		local mpForward = getFieldValue mp "forward"
		local mpUp = getFieldValue mp "up"
		
		newSphere.mpName = mpName
		newSphere.modelNodeIndex = mpModelNode
		newSphere.relativeMass = mpRelativeMass
		newSphere.massValue = calculatedMass
		newSphere.relativeDensity = mpRelativeDensity
		newSphere.densityValue = calculatedDensity
		
		if mpPoweredMassPoint >= 0 and mpPoweredMassPoint < poweredMassPointsArray.count then
		(
			local pmpName = getFieldValue poweredMassPointsArray[mpPoweredMassPoint + 1] "name"
			newSphere.poweredMassPointName = pmpName
		)
		else
		(
			newSphere.poweredMassPointName = "None"
		)
		
		local frictionTypeName = case frictionType of
		(
			0: "point"
			1: "forward"
			2: "left"
			3: "up"
			default: "unknown"
		)
		newSphere.frictionType = frictionTypeName
		newSphere.frictionParallel = mpFrictionParallelScale
		newSphere.frictionPerpendicular = mpFrictionPerpendicularScale
		newSphere.isMetallic = (mpFlags == 1)

		-- Parser returns Vector3D objects directly
		orientMassPointSphere newSphere mpForward mpUp
		
		if (mpModelNode >= 0 and mpModelNode < sceneNodes.count) then
		(
			local targetNode = sceneNodes[mpModelNode + 1]
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

logger.info "{} loaded." args:#(scriptName)