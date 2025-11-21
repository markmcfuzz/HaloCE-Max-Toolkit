/**
#name utils.ms
"Shared utility functions for reading binary tag data"
*/

-- Global file handles (will be set by importing scripts)
global halo_file_handle = undefined
global in_file = undefined

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

-------------------------------------------------------
-- Binary readers (big-endian)
-------------------------------------------------------
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

	-- Read TagRef structure (16 bytes)
	fn tagRef =
	(
		local tagClass = read.longB "#unsigned"
		local pathPtr = read.longB "#signed"
		local pathLen = read.longB "#signed"
		local tagID = read.longB "#unsigned"
		#(tagClass, pathPtr, pathLen, tagID)
	),

	-- Read reflexive structure (12 bytes)
	fn reflexive =
	(
		local count = read.longB "#signed"
		local pointer = read.longB "#unsigned"
		local id = read.longB "#unsigned"
		#(count, pointer, id)
	)
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

-- Skip bytes in file
fn skipBytes count =
(
	local fileHandle = getCurrentFileHandle()
	for i = 1 to count do
		readByte fileHandle #unsigned
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
	if activeFlagsArray.count == 0 then
		activeFlagsArray = #("none")
	activeFlagsArray
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

-------------------------------------------------------
-- File management functions
-------------------------------------------------------

-- Set the global file handle (call this before using any read functions)
fn setFileHandle fileHandle =
(
	halo_file_handle = fileHandle
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

--------------------------------------------------------
-- Decompression functions
--------------------------------------------------------

--fn decompressNormal32 n =
--(
--    local xMask = 1023
--    local yMask = 1023
--    local zMask = 511
--    
--    local x = (bit.and n xMask) / xMask
--    local y = (bit.and (bit.shift n -11) yMask) / yMask
--    local z = (bit.and (bit.shift n -22) zMask) / zMask
--    
--    if bit.and n (bit.shift 1 10) != 0 do x -= 1.0
--    if bit.and n (bit.shift 1 21) != 0 do y -= 1.0
--    if bit.and n (bit.shift 1 31) != 0 do z -= 1.0
--    
--    return [x, y, z]
--)

-- Instantiate global structs
read = read()
math = math()


logger "Utilities loaded.\n" logType:#success