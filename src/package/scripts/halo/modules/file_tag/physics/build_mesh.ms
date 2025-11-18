/*
Halo CE Physics Mesh Builder
Creates sphere geometry for physics mass points
*/

-------------------------------------------------------
-- Sphere orientation function
-------------------------------------------------------

-- Orient sphere using forward and up vectors from physics data
fn orientMassPointSphere sphereObj forwardVec upVec =
(
    try
    (
        -- Store current position
        local currentPos = sphereObj.transform.row4
        
        -- Create transformation matrix where:
        -- X-axis = forward vector (from physics forward)
        -- Z-axis = up vector (from physics up)  
        -- Y-axis = cross product of up and forward (right-hand rule)
        local rightVec = cross upVec forwardVec
        local transformMatrix = matrix3 forwardVec rightVec upVec currentPos
        
        -- Apply the transformation
        sphereObj.transform = transformMatrix
        
        return true
    )
    catch (e)
    (
        return false
    )
)

-------------------------------------------------------
-- Mass Point Custom Attributes
-------------------------------------------------------

-- Custom attributes for mass point data display in Modify panel
massPointAttributes = attributes "Mass Point Properties"
(
	parameters massPointParams rollout:massPointRollout
	(
		-- Basic properties (parameters are writable, UI controls will be read-only)
		mpName type:#string ui:etName default:""
		poweredMassPointName type:#string ui:etPoweredMassPoint default:""
		modelNodeIndex type:#integer ui:spModelNode default:-1
		linkedNodeName type:#string ui:etLinkedNode default:""
		
		-- Mass and density
		relativeMass type:#float ui:spRelativeMass default:0.0
		massValue type:#float ui:spMass default:0.0
		relativeDensity type:#float ui:spRelativeDensity default:0.0
		densityValue type:#float ui:spDensity default:0.0
		
		-- Friction properties
		frictionType type:#string ui:etFrictionType default:"point"
		frictionParallel type:#float ui:spFrictionPara default:0.0
		frictionPerpendicular type:#float ui:spFrictionPerp default:0.0
		
		-- Flags
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

-- Collect scene nodes for mass point linking
fn collectSceneNodes =
(
    try
    (
        local allNodes = #()
        
        -- Collect frame* nodes (common Halo naming convention)
        local frameNodes = for obj in objects where (matchPattern obj.name pattern:"frame*") and (isValidNode obj) collect obj
        
        -- Collect b_* nodes (bone naming convention)
        local boneNodes = for obj in objects where (matchPattern obj.name pattern:"b_*") and (isValidNode obj) collect obj
        
        -- Collect bip01* nodes (biped naming convention)
        local bipedNodes = for obj in objects where (matchPattern obj.name pattern:"bip01*") and (isValidNode obj) collect obj
        
        -- Combine all node types
        join allNodes frameNodes
        join allNodes boneNodes
        join allNodes bipedNodes
        
        -- Filter out hidden and frozen nodes
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
-- Create spheres in 3ds Max for each mass point
fn createMassPointSpheres massPointsArray poweredMassPointsArray =
(
	if massPointsArray == undefined or massPointsArray.count == 0 then
	(
		return undefined
	)

	-- Collect scene nodes for potential linking
	local sceneNodes = collectSceneNodes()
	
	local createdSpheres = #()

	for mp in massPointsArray do
	(
		-- Convert world units to 3ds Max units (1 world unit = 100 3ds Max units)
		local spherePos = mp.position * 100
		local sphereRadius = mp.radius * 100

		-- Create sphere with # prefix in name
		local sphereName = "#" + mp.name

		-- Create the sphere
		local newSphere = sphere radius:sphereRadius pos:spherePos name:sphereName smooth:on

		-- Set sphere color based on friction type for visual distinction
		local sphereColor = case mp.friction_type of
		(
			0: (color 255 19 10)       --#ff130a | Orange - point friction (most common)
			1: (color 48 255 203)      --#30ffcb | Cyan - forward friction (wheels/treads)
			2: (color 255 111 133)     --#ff6f85 | Rose - left friction (side forces)
			3: (color 129 255 110)     --#81ff6e | Green - up friction (vertical forces)
			default: (color 255 255 0) --#ffff00 | Yellow - unknown friction type
		)
		newSphere.wirecolor = sphereColor

		-- Assign to "Physics" layer
		local physicsLayer = LayerManager.getLayerFromName "Physics"
		if physicsLayer == undefined then
			physicsLayer = LayerManager.newLayerFromName "Physics"
		physicsLayer.addNode newSphere

		-- Add custom attributes to display mass point data in Modify panel
		custAttributes.add newSphere massPointAttributes
		
		-- Set all the mass point data in the custom attributes
		newSphere.mpName = mp.name
		newSphere.modelNodeIndex = mp.model_node
		newSphere.relativeMass = mp.relative_mass
		newSphere.massValue = mp.mass  -- Now use the actual mass value from mass point
		newSphere.relativeDensity = mp.relative_density
		newSphere.densityValue = mp.density  -- Now use the actual density value from mass point
		
		-- Resolve powered mass point name
		if mp.powered_mass_point >= 0 and mp.powered_mass_point < poweredMassPointsArray.count then
		(
			newSphere.poweredMassPointName = poweredMassPointsArray[mp.powered_mass_point + 1]
		)
		else
		(
			newSphere.poweredMassPointName = "None"
		)
		
		-- Convert friction type to readable name
		local frictionTypeName = case mp.friction_type of
		(
			0: "point"
			1: "forward"
			2: "left"
			3: "up"
			default: "unknown"
		)
		newSphere.frictionType = frictionTypeName
		newSphere.frictionParallel = mp.friction_parallel_scale
		newSphere.frictionPerpendicular = mp.friction_perpendicular_scale
		newSphere.isMetallic = (mp.flags == 1)

		-- Apply orientation using forward and up vectors from physics data
		orientMassPointSphere newSphere mp.forward mp.up

		-- Try to link sphere to scene node
		if (mp.model_node >= 0 and mp.model_node < sceneNodes.count) then
		(
			local targetNode = sceneNodes[mp.model_node + 1]
			newSphere.parent = targetNode
			newSphere.linkedNodeName = targetNode.name  -- Update custom attribute
		)
		else
		(
			newSphere.linkedNodeName = "None"  -- Update custom attribute
		)
	
		append createdSpheres newSphere
	)

	return createdSpheres
)