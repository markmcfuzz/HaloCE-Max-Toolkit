-- Halo Custom Edition Physics Importer
-- by Mark McFuzz
-- Version 1.0.0
------------------------------------------------------------------------------------------------
-- Features:
-- - Imports without UI physics tag from Halo Custom Edition
-- - Import mass points position and radius
-- - No support for mass points attached to nodes yet
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
    relative_density = 0.0,
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

	format "\n=== Reading Physics Tag: % ===\n" (getFilenameFile physicsFilePath)

	-- First skip the 64-byte header
	fseek in_file 64 #seek_set

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
		format "No mass points found in this physics tag.\n"
		fclose in_file
		return undefined
	)

	-- Calculate the actual offset of mass points data
	-- Tag blocks are stored sequentially after the main tag structure
	-- Structure: Header (64) + TagData (128) + InertialMatrices (N * 36) + PoweredMassPoints (N * 128) + MassPoints (N * 128)
	local massPointsOffset = 64 + 128 + (inertiaMatricesCount * 36) + (poweredMassPointsCount * 128)

	-- Seek to mass points data
	fseek in_file massPointsOffset #seek_set

    format "\n--- DEBUG DATA ---\n"
    format "Inertia Matrices Count: %\n" inertiaMatricesCount
	format "Powered Mass Points Count: %\n" poweredMassPointsCount
	format "Calculated Offset: %\n\n" massPointsOffset

    format "\n--- MASS POINTS ---\n"
	format "Number of Mass Points: %\n\n" massPointsCount

	-- Read each mass point (each is 128 bytes)
	local massPoints = #()

    -- Iterate list from mass points
	for i = 1 to massPointsCount do
	(
		format "\nMass Point %:\n" i

		-- Read name (32 bytes at offset 0)
		local mpName = readStringFromFile 32
		format "  Name: %\n" mpName

		-- Read powered_mass_point (short at offset 32)
		local poweredMassPoint = readShortB "#signed"
        --if poweredMassPoint < 0 then
        --(
        --    poweredMassPoint = "Null"
        --    format "  Powered Mass Point Index: %\n" poweredMassPoint
        --)
        --else
        --    format "  Powered Mass Point Index: %\n" poweredMassPoint

		-- Read model_node (short at offset 34)
		local modelNode = readShortB "#signed"

		-- Read flags (long at offset 36)
		local flags = readLongB "#unsigned"

        local flagsName = case flags of
        (
            0: "No flags selected"
            1: "metallic"
            default: "unknown"
        )
        -- format "  Flags: % (%)\n" flagsName flags

		-- Read relative_mass (float at offset 40)
		local relativeMass = readFloatB()

		-- Read mass (float at offset 44)
		local mass = readFloatB()

		-- Read relative_density (float at offset 48)
		local relativeDensity = readFloatB()

		-- Read density (float at offset 52)
		local density = readFloatB()

		-- Read position (3 floats at offset 56)
		local posX = readFloatB()
		local posY = readFloatB()
		local posZ = readFloatB()
		format "  Position: [%, %, %]\n" posX posY posZ

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
		
		-- Convert friction type number to name
		local frictionTypeName = case frictionType of
		(
			0: "point"
			1: "forward"
			2: "left"
			3: "up"
			default: "unknown"
		)
		-- format "  Friction Type: % (%)\n" frictionTypeName frictionType

		-- Skip 2 bytes of padding
		readShortB "#unsigned"

		-- Read friction_parallel_scale (float at offset 96)
		local frictionParallel = readFloatB()

		-- Read friction_perpendicular_scale (float at offset 100)
		local frictionPerpendicular = readFloatB()

		-- Read radius (float at offset 104)
		local mpRadius = readFloatB()
		format "  Radius: %\n\n" mpRadius

		-- Store mass point data
		local massPoint = physicsMassPoints()
		massPoint.name = mpName
		massPoint.powered_mass_point = poweredMassPoint
		massPoint.model_node = modelNode
		massPoint.flags = flags
		massPoint.relative_mass = relativeMass
		massPoint.relative_density = relativeDensity
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

	format "=== Finished reading % mass points ===\n\n" massPointsCount

	return massPoints
)

-------------------------------------------------------
-- Creation spheres
-------------------------------------------------------
-- Create spheres in 3ds Max for each mass point
fn createMassPointSpheres massPointsArray =
(
	if massPointsArray == undefined or massPointsArray.count == 0 then
	(
		format "No mass points data to create spheres.\n"
		return undefined
	)

	format "\n=== Creating Mass Point Spheres ===\n"

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
	
		format "Created sphere: % at position [%, %, %] with radius %\n" \
			sphereName spherePos.x spherePos.y spherePos.z sphereRadius
	
		append createdSpheres newSphere
	)

	format "\n=== Created % spheres ===\n\n" createdSpheres.count

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
		format "No file selected.\n"
		return undefined
	)
)

-- Combined function: Open dialog, read data, and create spheres
fn importPhysicsMassPoints =
(
	local massPointsData = openPhysicsTagDialog()

	if massPointsData != undefined then
	(
		createMassPointSpheres massPointsData
        messageBox "Physics mass points imported successfully!" title:"Import Complete"
	)
	else
	(
		format "Import cancelled or failed.\n"
	)
)

importPhysicsMassPoints()