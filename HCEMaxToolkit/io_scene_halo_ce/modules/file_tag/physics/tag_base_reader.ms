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
-- Tag Header (64 bytes)
-------------------------------------------------------

fn readTagHeader =
(
    seekToPosition 36
    local tagClass = read.longB "#unsigned"
    
    seekToPosition 40
    local checksum = read.longB "#unsigned"
    
    seekToPosition 56
    local version = read.shortB "#unsigned"
    
    seekToPosition 60
    local engineId = read.longB "#unsigned"
    
    local expectedGbxFourcc = getFourccByTagName "phys"
    if tagClass != expectedGbxFourcc then
    (
        logger "Invalid tag class. Expected: %, Found: %\n" params:#(expectedGbxFourcc, tagClass) logType:#error
        return undefined
    )
    local header = returnHeader()
    header.tagClass = tagClass
    header.checksum = checksum
    header.version = version
    header.engineId = engineId

    return header
)

-------------------------------------------------------
-- Read Physics Tag Base
-------------------------------------------------------

fn readBaseTag =
(
	seekToPosition 64
	
	local radius = read.floatB()
	local momentScale = read.floatB()
	local mass = read.floatB()
	local centerOfMass = math.readPoint3()
	local density = read.floatB()
	local gravityScale = read.floatB()
	local groundFriction = read.floatB()
	local groundDepth = read.floatB()
	local groundDampFraction = read.floatB()
	local groundNormalK1 = read.floatB()
	local groundNormalK0 = read.floatB()

	skipBytes 4

	local waterFriction = read.floatB()
	local waterDepth = read.floatB()
	local waterDensity = read.floatB()

	skipBytes 4

	local airFriction = read.floatB()

	skipBytes 4

	local xxMoment = read.floatB()
	local yyMoment = read.floatB()
	local zzMoment = read.floatB()

	local physics = returnTagBase()
	physics.radius = radius
	physics.momentScale = momentScale
	physics.mass = mass
	physics.centerOfMass = centerOfMass
	physics.density = density
	physics.gravityScale = gravityScale
	physics.groundFriction = groundFriction
	physics.groundDepth = groundDepth
	physics.groundDampFraction = groundDampFraction
	physics.groundNormalK1 = groundNormalK1
	physics.groundNormalK0 = groundNormalK0
	physics.waterFriction = waterFriction
	physics.waterDepth = waterDepth
	physics.waterDensity = waterDensity
	physics.airFriction = airFriction
	physics.xxMoment = xxMoment
	physics.yyMoment = yyMoment
	physics.zzMoment = zzMoment

	return physics
)

-------------------------------------------------------
-- Reflexive Headers Reading (at offset 156)
-------------------------------------------------------

fn readReflexiveHeaders =
(
	local actualReflexiveStart = 156
	seekToPosition actualReflexiveStart
	
	local inertiaMatricesReflexive = read.reflex()
	local pMassPointsReflexive = read.reflex()
	local massPointsReflexive = read.reflex()
	
	local reflexives = returnReflexives()
	reflexives.inertiaMatrices = inertiaMatricesReflexive
	reflexives.poweredMassPoints = pMassPointsReflexive
	reflexives.massPoints = massPointsReflexive
	return reflexives
)

-------------------------------------------------------
-- Read Inertia Matrices
-------------------------------------------------------

fn readInertiaMatrices inertiaMatricesReflex =
(
    local count = inertiaMatricesReflex.count
    if count == 0 then
    (
        local result = inertiaMatricesBlockResult()
        result.inertialMatrices = #()
        result.endOffset = 64 + 128
        return result
    )
    local dataOffset = if inertiaMatricesReflex.pointer == 0 then (64 + 128) else inertiaMatricesReflex.pointer
    seekToPosition dataOffset
    
    local inertiaMatrices = #()
    local pairCount = count / 2
    for i = 1 to pairCount do
    (
        local yyZz = math.readPoint3()
        local zzXx = math.readPoint3()
        local xxYy = math.readPoint3()
        
        local inertialMatrix = returnInertialMatrix()
        inertialMatrix.yyZz = yyZz
        inertialMatrix.zzXx = zzXx
        inertialMatrix.xxYy = xxYy
        
        local yyZzInv = math.readPoint3()
        local zzXxInv = math.readPoint3()
        local xxYyInv = math.readPoint3()
        
        local inertialMatrixInverse = returnInertialMatrixInverse()
        inertialMatrixInverse.yyZz = yyZzInv
        inertialMatrixInverse.zzXx = zzXxInv
        inertialMatrixInverse.xxYy = xxYyInv
        
        local matrixPair = returnInertiaMatrices()
        matrixPair.inertialMatrix = inertialMatrix
        matrixPair.inertialMatrixInverse = inertialMatrixInverse
        
        append inertiaMatrices matrixPair
    )
    local endOffset = dataOffset + (pairCount * 72)
    
    local result = inertiaMatricesBlockResult()
    result.inertialMatrices = inertiaMatrices
    result.endOffset = endOffset
    
    return result
)

-------------------------------------------------------
-- Read Powered Mass Points
-------------------------------------------------------

fn readPoweredMassPoints pMassPointReflexive iMinvEndOffset =
(
	local pMassPointsCount = pMassPointReflexive.count
	
	if pMassPointsCount == 0 then	
	(
		local result = poweredMassPointsBlockResult()
		result.poweredMassPoints = #()
		result.endOffset = iMinvEndOffset
		return result
	)
	local pMpDataOffset = if pMassPointReflexive.pointer == 0 then iMinvEndOffset else pMassPointReflexive.pointer
	seekToPosition pMpDataOffset

	local poweredMassPoints = #()
	for i = 1 to pMassPointsCount do
	(
		local name = read.tagString 32
		local flagsValue = read.longB "#unsigned"
		local flagNames = #(
			"ground friction",
			"water friction",
			"air friction",
			"water lift",
			"air lift",
			"thrust",
			"antigrav"
		)
		local flags = decodeFlagBits flagsValue flagNames
		local antigravStrength = read.floatB()
		local antigravOffset = read.floatB()
		local antigravHeight = read.floatB()
		local antigravDampFraction = read.floatB()
		local antigravNormalK1 = read.floatB()
		local antigravNormalK0 = read.floatB()
		
		skipBytes 68

		local pMassPoint = returnPoweredMassPoints()
		pMassPoint.name = name
		pMassPoint.flags = flags
		pMassPoint.antigravStrength = antigravStrength
		pMassPoint.antigravOffset = antigravOffset
		pMassPoint.antigravHeight = antigravHeight
		pMassPoint.antigravDampFraction = antigravDampFraction
		pMassPoint.antigravNormalK1 = antigravNormalK1
		pMassPoint.antigravNormalK0 = antigravNormalK0

		append poweredMassPoints pMassPoint
	)
	local pMassPointEndOffset = pMpDataOffset + (pMassPointsCount * 128)

	local result = poweredMassPointsBlockResult()
	result.poweredMassPoints = poweredMassPoints
	result.endOffset = pMassPointEndOffset
	return result
)

-------------------------------------------------------
-- Read Mass Points
-------------------------------------------------------

fn readMassPoints massPointsReflexive pMassPointEndOffset =
(
	local massPointsCount = massPointsReflexive.count
	if massPointsCount == 0 then	
	(
		local result = massPointsBlockResult()
		result.massPoints = #()
		result.endOffset = pMassPointEndOffset
		return result
	)
	local mpDataOffset = if massPointsReflexive.pointer == 0 then pMassPointEndOffset else massPointsReflexive.pointer

	seekToPosition mpDataOffset

	local massPoints = #()
	for i = 1 to massPointsCount do
	(
		local name = read.tagString 32
		local poweredMassPoint = read.shortB "#signed"
		local modelNode = read.shortB "#signed"
		local flagsValue = read.longB "#unsigned"
		local flags = if flagsValue == 1 then ("metallic") else ("none")
		local relativeMass = read.floatB()
		local massValue = read.floatB()
		local relativeDensity = read.floatB()
		local densityValue = read.floatB()
		local position = math.readPoint3()
		local forward = math.readPoint3()
		local up = math.readPoint3()
		local frictionType = read.shortB "#signed"
		skipBytes 2
		local frictionParallel = read.floatB()
		local frictionPerpendicular = read.floatB()
		local radiusValue = read.floatB()
		
		skipBytes 20
		
		local massPoint = returnMassPoints()
		massPoint.name = name
		massPoint.poweredMassPoint = poweredMassPoint
		massPoint.modelNode = modelNode
		massPoint.flags = flags
		massPoint.relativeMass = relativeMass
		massPoint.mass = massValue
		massPoint.relativeDensity = relativeDensity
		massPoint.density = densityValue
		massPoint.position = position
		massPoint.forward = forward
		massPoint.up = up
		massPoint.frictionType = frictionType
		massPoint.frictionParallelScale = frictionParallel
		massPoint.frictionPerpendicularScale = frictionPerpendicular
		massPoint.radius = radiusValue

		append massPoints massPoint
	)
	local mpEndOffset = mpDataOffset + (massPointsCount * 128)

	local result = massPointsBlockResult()
	result.massPoints = massPoints
	result.endOffset = mpEndOffset
	return result
)

-------------------------------------------------------
-- Read Physics Tag Main Function
-------------------------------------------------------

fn readPhysicsTag physicsFilePath =
(
    local fileHandle = fopen physicsFilePath "rb"
    if fileHandle == undefined then
    (
        logger "Could not open file: %\n" params:#(physicsFilePath) logType:#error
        return undefined
    )
    
    setFileHandle fileHandle
    in_file = fileHandle
    
    local tagStruct = physicsTag()
    
    local tagHeader = readTagHeader()
    if tagHeader == undefined then
    (
        fclose fileHandle
        return undefined
    )
    tagStruct.header = tagHeader
    
    local tagBase = readBaseTag()
    if tagBase == undefined then
    (
        logger "Failed to read base tag data\n" logType:#error
        fclose fileHandle
        return undefined
    )
    tagStruct.tagBase = tagBase
    
    local physReflex = readReflexiveHeaders()
    if physReflex == undefined then
    (
        logger "Failed to read reflexive headers\n" logType:#error
        fclose fileHandle
        return undefined
    )
    tagStruct.inertiaMatricesBlock = physReflex.inertiaMatrices
    tagStruct.poweredMassPointsBlock = physReflex.poweredMassPoints
    tagStruct.massPointsBlock = physReflex.massPoints
    
    local inertiaResult = readInertiaMatrices physReflex.inertiaMatrices
    if inertiaResult == undefined then
    (
        logger "Failed to read inertia matrices\n" logType:#error
        fclose fileHandle
        return undefined
    )
    tagStruct.inertiaMatrices = inertiaResult.inertialMatrices
    
    local poweredResult = readPoweredMassPoints physReflex.poweredMassPoints inertiaResult.endOffset
    tagStruct.poweredMassPoints = poweredResult.poweredMassPoints
    
    local massResult = readMassPoints physReflex.massPoints poweredResult.endOffset
    tagStruct.massPoints = massResult.massPoints
    
	fclose fileHandle
	logger "Physics tag read successfully\n" logType:#success
	return tagStruct
)