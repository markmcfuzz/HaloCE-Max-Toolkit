/**
#name utils.ms
"Shared utility functions for reading binary tag data"
*/


-------------------------------------------------------
-- File management functions
-------------------------------------------------------

-- Global file handles (will be set by importing scripts)
global halo_file_handle = undefined
global in_file = undefined

-- Set the global file handle (call this before using any read functions)
fn setFileHandle fileHandle =
(
	halo_file_handle = fileHandle
)

-- Get the current file handle (check both global variables for compatibility)
fn getCurrentFileHandle =
(
	if halo_file_handle != undefined then
		halo_file_handle
	else if in_file != undefined then
		in_file
	else
		undefined
)

-- Get current file position
fn getFilePosition =
(
	local fileHandle = getCurrentFileHandle()
	if fileHandle != undefined then
	(
		-- ftell returns current position in file
		ftell fileHandle
	)
	else
		undefined
)

-- Get current file position
fn getCurrentFilePosition = 
(
	local fileHandle = getCurrentFileHandle()
	if fileHandle != undefined then
		ftell fileHandle
	else
		-1
)

-- Seek to specific position in file
fn seekToPosition position seekMode:#seek_set =
(
	local fileHandle = getCurrentFileHandle()
	if fileHandle != undefined then
		fseek fileHandle position seekMode
)

-- Skip bytes in file
fn skipBytes count =
(
	local fileHandle = getCurrentFileHandle()
	for i = 1 to count do
		readByte fileHandle #unsigned
)

-------------------------------------------------------
-- Binary readers (big-endian)
-------------------------------------------------------
struct tagRefData
(
    tagClass,
    pathPtr,
    pathLen,
    tagID,
    path
)

-- Clear any cached global variable that might override the struct
if reflexiveData != undefined and (classOf reflexiveData) != StructDef then
(
    reflexiveData = undefined
)

struct reflexiveData
(
    count,
    pointer,
    id
)

global read = undefined

struct read (
	
	-- Read big endian short (2 bytes)
	fn shortB strType =
	(
		local fileHandle = getCurrentFileHandle()
		b1 = readByte fileHandle #unsigned
		b2 = readByte fileHandle #unsigned
		bigEndianShort = (b1 * 256) + b2
		if strType == "#signed" then
		(
			if bigEndianShort > 32768 then
				(65536 - bigEndianShort) * -1
			else
				bigEndianShort
		)
		else
		(
			bigEndianShort
		)
	),
	
	-- Read big endian long (4 bytes)
	fn longB strType =
	(
		local fileHandle = getCurrentFileHandle()
		b1 = readByte fileHandle #unsigned
		if b1 == undefined then
		(
			throw "[ERROR] End of file reached during readLongB - file may be corrupted or data extends beyond file bounds"
		)
		b2 = readByte fileHandle #unsigned
		if b2 == undefined then
		(
			throw "[ERROR] End of file reached during readLongB - file may be corrupted or data extends beyond file bounds"
		)
		b3 = readByte fileHandle #unsigned
		if b3 == undefined then
		(
			throw "[ERROR] End of file reached during readLongB - file may be corrupted or data extends beyond file bounds"
		)
		b4 = readByte fileHandle #unsigned
		if b4 == undefined then
		(
			throw "[ERROR] End of file reached during readLongB - file may be corrupted or data extends beyond file bounds"
		)
		bigEndianLong = (b1 * 16777216) + (b2 * 65536) + (b3 * 256) + (b4 * 1)
		if strType == "#signed" then
		(
			if bigEndianLong as float > 2147483648 as float then
				(4294967296 - bigEndianLong) * -1
			else
				bigEndianLong
		)
		else
		(
			bigEndianLong
		)
	),
	
	-- Read big endian float (4 bytes)
	fn floatB =
	(
		local fileHandle = getCurrentFileHandle()
		local myBitArray = #{}
		b1 = readByte fileHandle #unsigned
		b2 = readByte fileHandle #unsigned
		b3 = readByte fileHandle #unsigned
		b4 = readByte fileHandle #unsigned
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
				exp += 2.0 ^ (9 - i)
		)
		exp -= 127.0
		local myFloat = 2.0 ^ exp
		exp -= 1
		for i = 10 to 32 do
		(
			if myBitArray[i] == true then
				myFloat += 2.0 ^ exp
			exp -= 1
		)
		if myBitArray[1] == true then
			-myFloat
		else
			myFloat
	),
	
	-- Read a string from the file (Latin1 encoding)
	fn tagString size =
	(
		local fileHandle = getCurrentFileHandle()
		local str = ""
		for i = 1 to size do
		(
			local char = readByte fileHandle #unsigned
			if char != 0 then
				str += bit.intAsChar char
		)
		str
	),
	
	-- Read a null-terminated string (reads until 0x00 byte)
	fn nullTerminatedString =
	(
		local fileHandle = getCurrentFileHandle()
		local str = ""
		local char = readByte fileHandle #unsigned
		while char != 0 and char != undefined do
		(
			str += bit.intAsChar char
			char = readByte fileHandle #unsigned
		)
		str
	),

	-- Read a string with 4-byte padding alignment (for sequential data structures)
	fn tagStringAligned size =
	(
		local fileHandle = getCurrentFileHandle()
		local str = ""
		
		-- Read the actual string bytes
		for i = 1 to size do
		(
			local char = readByte fileHandle #unsigned
			if char != 0 then
				str += bit.intAsChar char
		)
		
		-- Skip padding bytes to reach 4-byte alignment
		local paddedLen = ((size + 3) / 4) * 4
		local paddingBytes = paddedLen - size
		for i = 1 to paddingBytes do
			readByte fileHandle #unsigned
		
		str
	),

	-- Read TagRef structure (16 bytes)
	fn tagRef =
	(
		local tagClass = read.longB "#unsigned"
		local pathPtr = read.longB "#signed"
		local pathLen = read.longB "#signed"
		local tagID = read.longB "#unsigned"
		--#(tagClass, pathPtr, pathLen, tagID)
		tagRefData tagClass pathPtr pathLen tagID
	),

	-- Read reflexive structure (12 bytes) Legacy function
	fn reflexive =
	(
		local count = read.longB "#signed"
		local pointer = read.longB "#unsigned"
		local id = read.longB "#unsigned"
		#(count, pointer, id)
	),

	-- Read reflexive structure (12 bytes)
	fn reflex =
	(
		local count = read.longB "#signed"
		local pointer = read.longB "#unsigned"
		local id = read.longB "#unsigned"
		reflexiveData count pointer id
	)
)

-------------------------------------------------------
-- Line Text readers
-------------------------------------------------------

-- Read a single line from file and trim whitespace
fn readLineFromStream fileStream =
(
	local line = readLine fileStream
	trimRight (trimLeft line)
)

-- Read an integer value from the next line
fn readIntValue fileStream =
(
	local line = readLine fileStream
	line as integer
)

-- Read a float value from the next line
fn readFloatValue fileStream =
(
	local line = readLine fileStream
	line as float
)

-- Read a 3D point (vector) from the next line (space or tab separated)
fn readVectorValue fileStream =
(
	local line = readLine fileStream
	local values = filterString line " \t"
	
	if values.count >= 3 then
		[values[1] as float, values[2] as float, values[3] as float]
	else
		[0, 0, 0]
)

-- Read a quaternion from the next line (i j k w format, space or tab separated)
fn readQuatValue fileStream =
(
	local line = readLine fileStream
	local values = filterString line " \t"
	
	if values.count >= 4 then
	(
		local i = values[1] as float
		local j = values[2] as float
		local k = values[3] as float
		local w = values[4] as float
		normalize (quat i j k w)
	)
	else
		quat 0 0 0 1
)

-- Read 2D texture coordinates from the next line
fn readUVValue fileStream =
(
	local line = readLine fileStream
	local values = filterString line " \t"
	
	if values.count >= 2 then
		[values[1] as float, values[2] as float]
	else
		[0, 0]
)


-------------------------------------------------------
-- Math readers
-------------------------------------------------------
global math = undefined

struct math (
	
	-- Read quaternion
	fn readQuat =
	(
		i = read.floatB()
		j = read.floatB()
		k = read.floatB()
		w = read.floatB()
		#(i, j, k, w)
	),
	
	-- Read 3D point
	fn readPoint3 =
	(
		x = read.floatB()
		y = read.floatB()
		z = read.floatB()
		#(x, y, z)
	)
)

-- Format point/quaternion/vector for logger output
fn pointFormat value type:default =
(
	case type of
	(
		#quat: (
			"I:" + (value[1] as string) + 
			"  J:" + (value[2] as string) + 
			"  K:" + (value[3] as string) + 
			"  W:" + (value[4] as string)
		)
		#point: (
			"X:" + (value[1] as string) + 
			"  Y:" + (value[2] as string) + 
			"  Z:" + (value[3] as string)
		)
		#vector: (
			"I:" + (value[1] as string) + 
			"  J:" + (value[2] as string) + 
			"  K:" + (value[3] as string)
		)
		default: (value as string)
	)
)

-------------------------------------------------------
-- Halo-specific structure reading functions
-------------------------------------------------------

fn readEnum =
(
	local enumValue = readShortB "#signed"
	skipBytes 2  -- Padding
	enumValue
)

-------------------------------------------------------
-- Utility and conversion functions
-------------------------------------------------------

-- Decode flag bits into readable array
fn decodeFlagBits flagValue flagNames =
(
	local activeFlagsArray = #()
	for i = 1 to flagNames.count do
	(
		if bit.get flagValue i then
			append activeFlagsArray flagNames[i]
	)
	-- Return formatted string with each flag on its own line
	if activeFlagsArray.count == 0 then
		return "none"
	local result = ""
	for flag in activeFlagsArray do
	(
		result += "  - (" + flag + ")"
	)
	result
)

-- Get the flag array for a given number (legacy function)
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

-- Radians to Degrees conversion
fn radiansToDegrees radians =
(
	radians * (180.0 / 3.141592653589793)
)

-- Material Type Enum
-- Convert material type enum to string
fn materialTypeToString matType =
(
	case matType of
	(
		0: "dirt";
        1: "sand";
        2: "stone";
        3: "snow";
        4: "wood";
		5: "metal hollow";
        6: "metal thin";
        7: "metal thick";
        8: "rubber";
        9: "glass";
		10: "force field";
        11: "grunt"; 
        12: "hunter armor";
        13: "hunter skin"; 
        14: "elite";
		15: "jackal";
        16: "jackal energy shield";
        17: "engineer skin";
        18: "engineer force field";
		19: "flood combat form";
        20: "flood carrier form";
        21: "cyborg armor";
        22: "cyborg energy shield";
		23: "human armor";
        24: "human skin";
        25: "sentinel";
        26: "monitor";
        27: "plastic";
		28: "water";
        29: "leaves";
        30: "elite energy shield";
        31: "ice";
        32: "hunter shield";
		default: ("unknown_" + (matType as string))
	)
)

-------------------------------------------------------
-- Tag Reference Path Reader
-------------------------------------------------------

-- Read tag reference path string from file
fn readTagRefPath pathPtr pathLen =
(
    if pathPtr == 0 or pathLen <= 0 then
        return ""
    
    -- Check if pointer looks like a memory address (not a valid file offset)
    -- Valid file offsets are typically small positive numbers (< 100MB)
    -- Memory addresses can be large positive or negative values
    if pathPtr < 0 or pathPtr > 104857600 then  -- 100 MB threshold
    (
        -- This is likely a memory address, not a file offset - skip reading
        return ""
    )
    
    -- Save current position
    local fileHandle = getCurrentFileHandle()
    local savedPos = ftell fileHandle
    
    -- Seek to path location
    seekToPosition pathPtr
    
    -- Read path string
    local pathString = read.tagString pathLen
    
    -- Restore position
    fseek fileHandle savedPos #seek_set
    
    return pathString
)

-- Format tag reference for display
fn formatTagRef tagRef useFullName:true =
(
    if tagRef == undefined then
        return "NULL"
    
    local tagClass = tagRef.tagClass
    local pathPtr = tagRef.pathPtr
    local pathLen = tagRef.pathLen
    
    -- Get tag class name (full name by default)
    local tagClassName = tagClassToString tagClass returnFullName:useFullName
    
    -- Read path if available
    local tagPath = "NULL"
    if pathLen > 0 and pathLen < 10000 then
    (
        -- Check if path was already read and stored
        if tagRef.path != undefined then
            tagPath = tagRef.path
        else if pathPtr > 0 then
            tagPath = readTagRefPath pathPtr pathLen
    )
    
    if tagPath == "" or tagPath == undefined then
        tagPath = "NULL"
    
    return "{" + tagClassName + "}" + " (" + tagPath + ")"
)

-------------------------------------------------------
-- COMPRESSED VERTEX DECOMPRESSION
-------------------------------------------------------

-- Decompress normal from packed 32-bit format (11-11-10 bit)
fn decompressNormal normalPacked =
(
    local nx = (bit.and (bit.shift normalPacked -21) 0x7FF) / 1023.0 * 2.0 - 1.0
    local ny = (bit.and (bit.shift normalPacked -10) 0x7FF) / 1023.0 * 2.0 - 1.0
    local nz = (bit.and normalPacked 0x3FF) / 511.0 * 2.0 - 1.0
    return [nx, ny, nz]
)

-- Decompress UV coordinates from signed 16-bit format
fn decompressUV u16 v16 uScale:1.0 vScale:1.0 =
(
    local u = (u16 / 32767.0) * uScale
    local v_coord = 1.0 - ((v16 / 32767.0) * vScale)
    return [u, v_coord, 0]
)

-- Decompress node indices (stored * 3 in compressed format)
fn decompressNodeIndices node0Raw node1Raw =
(
    local node0Index = (node0Raw / 3) + 1  -- Convert to 1-based
    local node1Index = (node1Raw / 3) + 1  -- Convert to 1-based
    return #(node0Index, node1Index)
)

-- Decompress node weight from signed 16-bit to float (0.0-1.0)
fn decompressNodeWeight weightRaw =
(
    local weight = weightRaw / 32767.0
    return weight
)

-------------------------------------------------------
-- Object detection functions
-------------------------------------------------------

-- Check if object name indicates it should be exported as a node
fn isNodeObject obj =
(
	if obj == undefined then return false
	
	local objName = toLower obj.name
	
	-- Check for node prefixes: 'b', 'b_', 'bone', 'frame', 'bip01'
	local hasPrefix = (matchPattern objName pattern:"b *") or \
	                  (matchPattern objName pattern:"b_*") or \
	                  (matchPattern objName pattern:"bone*") or \
	                  (matchPattern objName pattern:"frame*") or \
	                  (matchPattern objName pattern:"bip01*")
	
	return hasPrefix
)

-- Check if object is a marker (names starting with '#' or '+')
fn isMarkerObject obj =
(
	if obj == undefined then return false
	return (obj.name[1] == "#" or obj.name[1] == "+")
)

-- Check if object is a physics/pathfinding object (names starting with '+')
fn isPhysicsObject obj =
(
	if obj == undefined then return false
	return (obj.name[1] == "+")
)

-- Check if object is geometry (Editable Mesh or Editable Poly)
fn isGeometryObject obj =
(
	if obj == undefined then return false
	
	local objClass = classOf obj
	
	-- Check direct class
	if objClass == Editable_mesh or objClass == Editable_Poly then
		return true
	
	-- Check base object (for objects with modifiers)
	if obj.baseObject != undefined then
	(
		local baseClass = classOf obj.baseObject
		if baseClass == Editable_mesh or baseClass == Editable_Poly then
			return true
	)
	
	return false
)

-- Get the Skin modifier from an object if it exists
fn getSkinModifier obj =
(
	for i = 1 to obj.modifiers.count do
	(
		if classOf obj.modifiers[i] == Skin then
			return obj.modifiers[i]
	)
	return undefined
)

-------------------------------------------------------
-- FORMAT HELPERS
-------------------------------------------------------

-- Format a float value for output with 6 decimal places minimum
fn formatFloat val =
(
	-- Use formattedPrint to ensure at least 6 decimal places
	local str = formattedPrint val format:".6f"
	return str
)

-- Format quaternion rotation (i, j, k, w)
fn formatRotation rotArray =
(
	local str = ""
	str += formatFloat rotArray[1] + "\t"
	str += formatFloat rotArray[2] + "\t"
	str += formatFloat rotArray[3] + "\t"
	str += formatFloat rotArray[4]
	return str
)

-- Format translation (x, y, z)
fn formatTranslation posArray =
(
	local str = ""
	str += formatFloat posArray[1] + "\t"
	str += formatFloat posArray[2] + "\t"
	str += formatFloat posArray[3]
	return str
)

-- Instantiate global structs
read = read()
math = math()

logger "Utilities loaded.\n" logType:#success