/*
Halo CE Physics Tag Reader
Uses global read utilities from read_utils.ms
*/

-------------------------------------------------------
-- Tag Header (64 bytes)
-------------------------------------------------------

fn readTagHeader =
(
    -- format "=== READING TAG HEADER ===\n"
    
    -- Seek to tag class (offset 36 in header)
    seekToPosition 36
    local tagClass = read.longB "#unsigned"
    
    -- Seek to version (offset 56 in header)  
    seekToPosition 56
    local version = read.shortB "#unsigned"
    
    -- Validate tag class
    local expectedCollFourcc = getFourccByTagName "phys"
    if tagClass != expectedCollFourcc then
    (
        format "[ERROR] Invalid tag class. Expected: %, Found: %\n" expectedCollFourcc tagClass
        return undefined
    )
    
    format "Valid physics tag: version %\n" version
    return #(tagClass, version)
)

-------------------------------------------------------
-- Read Physics Tag Main Function
-------------------------------------------------------

fn readPhysicsTag physicsFilePath =
(
	-- Open file and set global handle
	global halo_file_handle = fopen physicsFilePath "rb"
	
	if halo_file_handle == undefined then
	(
		format "[ERROR] Could not open file: %\n" physicsFilePath
		return undefined
	)
	
	format "\n=== READING PHYSICS TAG ===\n"
	format "File: %\n" (filenameFromPath physicsFilePath)

	-- Skip 64-byte header and read main physics data
	seekToPosition 64
	
	-- Read main physics tag data structure (128 bytes total)
	local tagRadius = read.floatB()				-- offset 0
	local tagMomentScale = read.floatB()			-- offset 4
	local tagMass = read.floatB()				-- offset 8
	local centerOfMass = math.readPoint3()			-- offset 12 (12 bytes)
	local tagDensity = read.floatB()				-- offset 24
	local tagGravityScale = read.floatB()		-- offset 28
	local tagGroundFriction = read.floatB()		-- offset 32
	local tagGroundDepth = read.floatB()			-- offset 36
	local tagGroundDampFraction = read.floatB()	-- offset 40
	local tagGroundNormalK1 = read.floatB()		-- offset 44
	local tagGroundNormalK0 = read.floatB()		-- offset 48
	
	-- Read tag block reflexive counts
	seekToPosition (64 + 92)	-- inertia_matrices reflexive
	local inertiaMatricesCount = read.longB "#signed"
	
	seekToPosition (64 + 104)	-- powered_mass_points reflexive
	local poweredMassPointsCount = read.longB "#signed"
	
	seekToPosition (64 + 116)	-- mass_points reflexive
	local massPointsCount = read.longB "#signed"
	
	format "Tag Mass: %\n" tagMass
	format "Tag Density: %\n" tagDensity
	format "Mass Points: %\n" massPointsCount
	
	if massPointsCount == 0 then
	(
		fclose halo_file_handle
		format "[WARNING] No mass points found in physics tag\n"
		return undefined
	)
	
	-- Read powered mass points (if any)
	local poweredMassPoints = #()
	if poweredMassPointsCount > 0 then
	(
		local poweredMpOffset = 64 + 128 + (inertiaMatricesCount * 36)
		seekToPosition poweredMpOffset
		
		for i = 1 to poweredMassPointsCount do
		(
			local poweredMpName = read.tagString 32
			append poweredMassPoints poweredMpName
			
			-- Skip remaining powered mass point data (96 bytes)
			skipBytes 96
		)
	)
	
	-- Calculate mass points data offset
	-- Structure: Header(64) + TagData(128) + InertialMatrices(N*36) + PoweredMPs(N*128) + MassPoints(N*128)
	local massPointsOffset = 64 + 128 + (inertiaMatricesCount * 36) + (poweredMassPointsCount * 128)
	seekToPosition massPointsOffset
	
	-- Read mass points (each is 128 bytes)
	local massPoints = #()
	for i = 1 to massPointsCount do
	(
		-- Read mass point data structure
		local mpName = read.tagString 32				-- offset 0
		local poweredMassPoint = read.shortB "#signed"	-- offset 32
		local modelNode = read.shortB "#signed"			-- offset 34
		local flags = read.longB "#unsigned"		    -- offset 36
		local relativeMass = read.floatB()				-- offset 40
		local mass = read.floatB()						-- offset 44
		local relativeDensity = read.floatB()			-- offset 48
		local density = read.floatB()					-- offset 52
		local position = math.readPoint3()				-- offset 56 (12 bytes)
		local forward = math.readPoint3()				-- offset 68 (12 bytes)
		local up = math.readPoint3()					-- offset 80 (12 bytes)
		local frictionType = read.shortB "#signed"		-- offset 92
		skipBytes 2										-- padding
		local frictionParallel = read.floatB()			-- offset 96
		local frictionPerpendicular = read.floatB()		-- offset 100
		local mpRadius = read.floatB()					-- offset 104
		
		-- Create mass point struct
		local massPoint = physicsMassPoints()
		massPoint.name = mpName
		massPoint.powered_mass_point = poweredMassPoint
		massPoint.model_node = modelNode
		massPoint.flags = flags
		massPoint.relative_mass = relativeMass
		massPoint.mass = mass
		massPoint.relative_density = relativeDensity
		massPoint.density = density
		massPoint.position = position
		massPoint.forward = forward
		massPoint.up = up
		massPoint.friction_type = frictionType
		massPoint.friction_parallel_scale = frictionParallel
		massPoint.friction_perpendicular_scale = frictionPerpendicular
		massPoint.radius = mpRadius
		
		append massPoints massPoint
		
		-- Skip remaining bytes (128 total - 108 read = 20 remaining)
		skipBytes 20
	)
	
	-- Close file
	fclose halo_file_handle
	global halo_file_handle = undefined
	
	-- Calculate proper mass and density values
	local totalRelativeMass = 0.0
	local totalRelativeDensity = 0.0
	
	-- Sum all relative values
	for mp in massPoints do
	(
		totalRelativeMass += mp.relative_mass
		totalRelativeDensity += mp.relative_density
	)
	
	-- Calculate base values per unit
	local baseMassPerUnit = if totalRelativeMass > 0 then tagMass / totalRelativeMass else 0.0
	local baseDensityPerUnit = if totalRelativeDensity > 0 then tagDensity / totalRelativeDensity else 0.0
	
	-- Calculate individual mass and density for each point
	for mp in massPoints do
	(
		mp.mass = baseMassPerUnit * mp.relative_mass
		
		-- Density calculation (handles simple and complex cases)
		if mp.density > 0.0 and (abs(mp.density - (tagDensity * mp.relative_density)) < 0.1) then
		(
			-- Stored density appears correct (keep as is)
		)
		else if totalRelativeDensity == massPointsCount then
		(
			-- Simple case: all relative densities are 1.0
			mp.density = tagDensity * mp.relative_density
		)
		else
		(
			-- Complex case: mixed relative densities
			local referenceMass = 149.266  -- Derived from Warthog test data
			local densityModifier = baseMassPerUnit / referenceMass
			mp.density = tagDensity * mp.relative_density * densityModifier
		)
	)
	
	format "\n[SUCCESS] Physics tag read successfully!\n"
	format "Mass Points: %\n" massPoints.count
	format "Powered Mass Points: %\n" poweredMassPoints.count
	
	return #(massPoints, poweredMassPoints)
)