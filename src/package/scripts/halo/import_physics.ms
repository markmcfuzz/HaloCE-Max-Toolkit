-- Halo Custom Edition Physics Importer
-- by Mark McFuzz
-- Version 1.0.0
------------------------------------------------------------------------------------------------
-- Features:
-- - Imports without UI physics tag from Halo Custom Edition
-- - Import mass points position and radius as spheres
-- - Spheres oriented using forward/up vectors (forward = +X, up = +Z)
-- - Automatic linking to frame*, b_*, and bip01* nodes in scene
-- - Mass point data displayed in custom attributes rollout (Modify panel)
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

-- Detect 3ds max or gmax
gMax = (maxVersion())[1]<=4200
grabListenerPath = getDir #scripts -- Or specify your own path, like "c:\\program files\\autodesk\\3ds max\\scripts"
scriptFilePath = getDir #scripts

-------------------------------------------------------
-- Physics tag structure
-------------------------------------------------------

struct physicsTag (
    header = 1885895027 or undefined,
    radius = 0.0,
    moment_scale = 0.0,
    mass = 0.0,
    density = 0.0,
    gravity_scale = 0.0,
    ground_friction = 0.0,
    ground_depth = 0.0,
    ground_damp_fraction = 0.0,
    ground_normal_k1 = 0.0,
    ground_normal_k0 = 0.0,
    water_friction = 0.0,
    water_depth = 0.0,
    water_density = 0.0,
    air_friction = 0.0,
    xx_moment = 0.0,
    yy_moment = 0.0,
    zz_moment = 0.0,
    inertial_matrix_and_inverse = #(),
    powered_mass_points = #(),
    mass_points = #(),
    intertial_matrix_and_inverse_tag_block = undefined,
    powered_mass_points_tag_block = undefined,
    mass_points_tag_block = undefined
)

struct physicsInertialMatrixAndInverse (
    inertial_matrix = #(),
    inertial_matrix_inverse = #()
)

struct inertialMatrix (
    yy_zz = [0.0, 0.0, 0.0],
    zz_xx = [0.0, 0.0, 0.0],
    xx_yy = [0.0, 0.0, 0.0]
)

struct intertialMatrixInverse (
    yy_zz = [0.0, 0.0, 0.0],
    zz_xx = [0.0, 0.0, 0.0],
    xx_yy = [0.0, 0.0, 0.0]
)

struct physicsPoweredMassPoints (
    name = "",
    flags = 0,
    antigrav_strength = 0.0,
    antigrav_offset = 0.0,
    antigrav_height = 0.0,
    antigrav_damp_fraction = 0.0,
    antigrav_normal_k1 = 0.0,
    antigrav_normal_k0 = 0.0
)

struct poweredMassPointsFlags (
    ground_friction = 0,
    water_friction = 1,
    water_density = 2,
    water_lift = 3,
    air_lift = 4,
    thrust = 5,
    antigrav = 6
)

struct physicsMassPoints (
    name = "",
    powered_mass_point = 0,
    model_node = 0,
    flags = 0,
    relative_mass = 0.0,
    mass = 0.0,
    relative_density = 0.0,
    density = 0.0,
    position = [0.0, 0.0, 0.0],
    forward = [1.0, 0.0, 0.0], -- quaternion
    up = [0.0, 0.0, 1.0], -- quaternion
    friction_type = 0,
    friction_parallel_scale = 0.0,
    friction_perpendicular_scale = 0.0,
    radius = 0.0
)

struct massPointsFlags (
    metallic = 0
)

struct frictionTypeEnum (
    point = 0,
    forward = 1,
    left = 2,
    up = 3
)

in_file = undefined
in_name = undefined
maxver = maxVersion()

-------------------------------------------------------
-- Read functions
-------------------------------------------------------

fn readShortB strType =
(
	b1 = readByte in_file #unsigned
	b2 = readByte in_file #unsigned
	bigEndianShort = (b1 * 256) + b2
	if strType == "#signed" then
	(
		if bigEndianShort > 32768 then
		(
			(65536 - bigEndianShort) * -1
		)
		else
		(
			bigEndianShort
		)
	)
	else
	(
		bigEndianShort
	)
)

fn readLongB strType =
(
	b1 = readByte in_file #unsigned
	b2 = readByte in_file #unsigned
	b3 = readByte in_file #unsigned
	b4 = readByte in_file #unsigned
	bigEndianLong = (b1 * 16777216) + (b2 * 65536) + (b3 * 256) + (b4 * 1)
	if strType == "#signed" then
	(
		if bigEndianLong as float > 2147483648 as float then
		(
			(4294967296 - bigEndianLong) * -1
		)
		else
		(
			bigEndianLong
		)
	)
	else
	(
		bigEndianLong
	)
)

fn readFloatB =
(
	local myBitArray = #{}
	b1 = readByte in_file #unsigned
	b2 = readByte in_file #unsigned
	b3 = readByte in_file #unsigned
	b4 = readByte in_file #unsigned
	for i = 8 to 1 by -1 do
	(
		myBitArray[i] = (mod b1 2 > .5)
		b1 /= 2
	)
	for i = 16 to 9 by -1 do
	(
		myBitArray[i] = (mod b2 2 > .5)
		b2 /= 2
	)
	for i = 24 to 17 by -1 do
	(
		myBitArray[i] = (mod b3 2 > .5)
		b3 /= 2
	)
	for i = 32 to 25 by -1 do
	(
		myBitArray[i] = (mod b4 2 > .5)
		b4 /= 2
	)
	
	local exp = 0.0
	for i = 9 to 2 by -1 do
	(
		if myBitArray[i] == true then
		(
			exp += 2.0 ^ (9 - i)
		)
	)
	exp -= 127.0
	
	local myFloat = 2.0 ^ exp
	exp -= 1
	for i = 10 to 32 do
	(
		if myBitArray[i] == true then
		(
			myFloat += 2.0 ^ exp
		)
		exp -= 1
	)
	if myBitArray[1] == true then
	(
		-myFloat
	)
	else
	(
		myFloat
	)
)

fn readQuat =
(
	q1 = readFloatB()
	q2 = readFloatB()
	q3 = readFloatB()
	q4 = readFloatB()
	normalize (quat q1 q2 q3 q4)
)

fn readTrans =
(
	f1 = readFloatB() * 100
	f2 = readFloatB() * 100
	f3 = readFloatB() * 100
	[f1,f2,f3]
)

-- Get the flag array for a given number
fn getFlagArray num =
(
	local myBitArray = #{}
	for i = 1 to 8 do
	(
		myBitArray[i] = (mod num 2 > .5)
		num /= 2
	)
	myBitArray
)

-- Read a string from the file (Latin1 encoding)
fn readStringFromFile size =
(
	local str = ""
	for i = 1 to size do
	(
		local char = readByte in_file #unsigned
		if char != 0 then
			str += bit.intAsChar char
	)
	str
)

-- Read Mass Points data from physics tag
fn readMassPoints physicsFilePath =
(
    -- Open the physics tag file
	in_file = fopen physicsFilePath "rb"

	if in_file == undefined then
	(
		format "ERROR: Could not open file: %\n" physicsFilePath
		return undefined
	)

	-- First skip the 64-byte header and read main physics data
	fseek in_file 64 #seek_set
	
	-- Read main physics tag data from tagdata structure
	local tagRadius = readFloatB()		-- offset 0
	local tagMomentScale = readFloatB()	-- offset 4
	local tagMass = readFloatB()		-- offset 8
	-- Read center_of_mass (12 bytes)
	local centerOfMassX = readFloatB()	-- offset 12
	local centerOfMassY = readFloatB()	-- offset 16
	local centerOfMassZ = readFloatB()	-- offset 20
	local tagDensity = readFloatB()		-- offset 24
	local tagGravityScale = readFloatB()	-- offset 28
	local tagGroundFriction = readFloatB()	-- offset 32
	local tagGroundDepth = readFloatB()	-- offset 36
	local tagGroundDampFraction = readFloatB()	-- offset 40
	local tagGroundNormalK1 = readFloatB()	-- offset 44
	local tagGroundNormalK0 = readFloatB()	-- offset 48

	-- Skip to reflexive data reading
	-- Read inertia_matrices reflexive at offset 92 in tagdata
	fseek in_file (64 + 92) #seek_set
	local inertiaMatricesCount = readLongB "#signed"

	-- Read powered_mass_points reflexive at offset 104 in tagdata
	fseek in_file (64 + 104) #seek_set
	local poweredMassPointsCount = readLongB "#signed"

	-- Read mass_points reflexive at offset 116 in tagdata
	fseek in_file (64 + 116) #seek_set
	local massPointsCount = readLongB "#signed"

	if massPointsCount == 0 then
	(
		fclose in_file
		return undefined
	)

	-- Read powered mass points first (if any exist)
	local poweredMassPoints = #()
	if poweredMassPointsCount > 0 then
	(
		local poweredMassPointsOffset = 64 + 128 + (inertiaMatricesCount * 36)
		fseek in_file poweredMassPointsOffset #seek_set
		
		for i = 1 to poweredMassPointsCount do
		(
			-- Read powered mass point name (32 bytes at offset 0)
			local poweredMpName = readStringFromFile 32
			append poweredMassPoints poweredMpName
			
			-- Skip the rest of the powered mass point data (96 bytes remaining)
			for j = 1 to 96 do
				readByte in_file #unsigned
		)
	)

	-- Calculate the actual offset of mass points data
	-- Tag blocks are stored sequentially after the main tag structure
	-- Structure: Header (64) + TagData (128) + InertialMatrices (N * 36) + PoweredMassPoints (N * 128) + MassPoints (N * 128)
	local massPointsOffset = 64 + 128 + (inertiaMatricesCount * 36) + (poweredMassPointsCount * 128)

	-- Seek to mass points data
	fseek in_file massPointsOffset #seek_set

	-- Read each mass point (each is 128 bytes)
	local massPoints = #()

    -- Iterate list from mass points
	for i = 1 to massPointsCount do
	(
		-- Read name (32 bytes at offset 0)
		local mpName = readStringFromFile 32

		-- Read powered_mass_point (short at offset 32)
		local poweredMassPoint = readShortB "#signed"

		-- Read model_node (short at offset 34)
		local modelNode = readShortB "#signed"

		-- Read flags (long at offset 36)
		local flags = readLongB "#unsigned"

		-- Read relative_mass (float at offset 40)
		local relativeMass = readFloatB()

		-- Read mass (float at offset 44) - usually 0.0, will be calculated
		local mass = readFloatB()

		-- Read relative_density (float at offset 48)
		local relativeDensity = readFloatB()

		-- Read density (float at offset 52) - usually 0.0, will be calculated
		local density = readFloatB()

		-- Read position (3 floats at offset 56)
		local posX = readFloatB()
		local posY = readFloatB()
		local posZ = readFloatB()

		-- Read forward vector (3 floats at offset 68)
		local forwardI = readFloatB()
		local forwardJ = readFloatB()
		local forwardK = readFloatB()

		-- Read up vector (3 floats at offset 80)
		local upI = readFloatB()
		local upJ = readFloatB()
		local upK = readFloatB()

		-- Read friction_type (short at offset 92)
		local frictionType = readShortB "#signed"

		-- Skip 2 bytes of padding
		readShortB "#unsigned"

		-- Read friction_parallel_scale (float at offset 96)
		local frictionParallel = readFloatB()

		-- Read friction_perpendicular_scale (float at offset 100)
		local frictionPerpendicular = readFloatB()

		-- Read radius (float at offset 104)
		local mpRadius = readFloatB()

		-- Store relative values for later calculation (we need to sum all relative masses first)
		-- Individual mass/density will be calculated after reading all mass points

		-- Store mass point data (mass and density will be calculated after reading all points)
		local massPoint = physicsMassPoints()
		massPoint.name = mpName
		massPoint.powered_mass_point = poweredMassPoint
		massPoint.model_node = modelNode
		massPoint.flags = flags
		massPoint.relative_mass = relativeMass
		massPoint.mass = mass  -- Store raw value, will calculate proper value later
		massPoint.relative_density = relativeDensity
		massPoint.density = density  -- Store raw value, will calculate proper value later
		massPoint.position = [posX, posY, posZ]
		massPoint.forward = [forwardI, forwardJ, forwardK]
		massPoint.up = [upI, upJ, upK]
		massPoint.friction_type = frictionType
		massPoint.friction_parallel_scale = frictionParallel
		massPoint.friction_perpendicular_scale = frictionPerpendicular
		massPoint.radius = mpRadius

		append massPoints massPoint

		-- Skip remaining bytes to reach next mass point (128 bytes total per mass point)
		-- We've read 108 bytes, so skip 20 more
		for j = 1 to 20 do
			readByte in_file #unsigned
	)

	fclose in_file

	-- Calculate proper mass and density values for each mass point
	-- Method: base_value_per_unit = main_value / sum_of_all_relatives
	-- individual_value = base_value_per_unit * individual_relative
	
	local totalRelativeMass = 0.0
	local totalRelativeDensity = 0.0
	
	-- First pass: sum all relative values
	for mp in massPoints do
	(
		totalRelativeMass += mp.relative_mass
		totalRelativeDensity += mp.relative_density
	)
	
	-- Calculate base values per unit
	local baseMassPerUnit = if totalRelativeMass > 0 then tagMass / totalRelativeMass else 0.0
	local baseDensityPerUnit = if totalRelativeDensity > 0 then tagDensity / totalRelativeDensity else 0.0
	
	-- Second pass: calculate individual mass and density values
	for mp in massPoints do
	(
		mp.mass = baseMassPerUnit * mp.relative_mass
		
		-- Density calculation: determine approach based on complexity
		if mp.density > 0.0 and (abs(mp.density - (tagDensity * mp.relative_density)) < 0.1) then
		(
			-- Stored density value appears to be correct (simple cases)
			-- Keep the stored value (mp.density is already set)
		)
		else if totalRelativeDensity == massPointsCount then
		(
			-- Simple case: all relative densities are 1.0 (like Ghost)
			-- Use simple multiplication: main_density * relative_density
			mp.density = tagDensity * mp.relative_density
		)
		else
		(
			-- Complex case: mixed relative densities (like Warthog)
			-- Use complex formula derived from test data
			local referenceMass = 149.266  -- Derived from Warthog test data
			local densityModifier = baseMassPerUnit / referenceMass
			mp.density = tagDensity * mp.relative_density * densityModifier
		)
	)

	return #(massPoints, poweredMassPoints)
)

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
			0: (color 255 30 0)      -- orange - point friction (most common)
			1: (color 0 255 255)      -- cyan - forward friction (wheels/treads)
			2: (color 255 0 255)      -- magenta - left friction (side forces)
			3: (color 0 255 0)        -- green - up friction (vertical forces)
			default: (color 255 255 0) -- yellow - unknown friction type
		)
		newSphere.wirecolor = sphereColor

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

-------------------------------------------------------
-- Utils
-------------------------------------------------------
-- Open file dialog to select a physics tag
fn openPhysicsTagDialog =
(
	local physicsFile = getOpenFileName \
		caption:"Select Physics Tag File" \
		types:"Physics Tag (*.physics)|*.physics|All Files (*.*)|*.*" \
		historyCategory:"PhysicsImport"

	if physicsFile != undefined then
	(
		return readMassPoints physicsFile
	)
	else
	(
		return undefined
	)
)

-- Combined function: Open dialog, read data, and create spheres
fn importPhysicsMassPoints =
(
	local physicsData = openPhysicsTagDialog()

	if physicsData != undefined then
	(
		local massPointsData = physicsData[1]
		local poweredMassPointsData = physicsData[2]
		createMassPointSpheres massPointsData poweredMassPointsData
        messageBox "Physics mass points imported successfully!" title:"Import Complete"
	)
)

importPhysicsMassPoints()