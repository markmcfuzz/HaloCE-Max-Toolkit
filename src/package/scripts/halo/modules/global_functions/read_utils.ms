/*
Halo CE Tag Reading Utilities
Shared utility functions for reading binary tag data
*/

-- Global file handle (will be set by importing scripts)
global halo_file_handle = undefined

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
-- Binary reading functions
-------------------------------------------------------

-- Read big endian short (2 bytes)
fn readShortB strType =
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
)

-- Read little endian short (2 bytes)
fn readShortL strType =
(
	local fileHandle = getCurrentFileHandle()
	b1 = readByte fileHandle #unsigned
	b2 = readByte fileHandle #unsigned
	littleEndianShort = (b2 * 256) + b1
	if strType == "#signed" then
	(
		if littleEndianShort > 32768 then
			(65536 - littleEndianShort) * -1
		else
			littleEndianShort
	)
	else
	(
		littleEndianShort
	)
)

-- Read big endian long (4 bytes)
fn readLongB strType =
(
	local fileHandle = getCurrentFileHandle()
	b1 = readByte fileHandle #unsigned
	if b1 == undefined then
	(
		throw "[ERROR] End of file reached during readLongB - file may be corrupted or BSP data extends beyond file bounds"
	)
	b2 = readByte fileHandle #unsigned
	if b2 == undefined then
	(
		throw "[ERROR] End of file reached during readLongB - file may be corrupted or BSP data extends beyond file bounds"
	)
	b3 = readByte fileHandle #unsigned
	if b3 == undefined then
	(
		throw "[ERROR] End of file reached during readLongB - file may be corrupted or BSP data extends beyond file bounds"
	)
	b4 = readByte fileHandle #unsigned
	if b4 == undefined then
	(
		throw "[ERROR] End of file reached during readLongB - file may be corrupted or BSP data extends beyond file bounds"
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
)

-- Read big endian float (4 bytes)
fn readFloatB =
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
)

-- Read little endian float (4 bytes)
fn readFloatL =
(
	local fileHandle = getCurrentFileHandle()
	local myBitArray = #{}
	b1 = readByte fileHandle #unsigned
	b2 = readByte fileHandle #unsigned
	b3 = readByte fileHandle #unsigned
	b4 = readByte fileHandle #unsigned
	
	-- Little-endian: b1 is LSB, b4 is MSB
	for i = 8 to 1 by -1 do
	(
		myBitArray[i] = (mod b4 2 > .5)
		b4 /= 2
	)
	for i = 16 to 9 by -1 do
	(
		myBitArray[i] = (mod b3 2 > .5)
		b3 /= 2
	)
	for i = 24 to 17 by -1 do
	(
		myBitArray[i] = (mod b2 2 > .5)
		b2 /= 2
	)
	for i = 32 to 25 by -1 do
	(
		myBitArray[i] = (mod b1 2 > .5)
		b1 /= 2
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
)

-- Read quaternion (4 floats)
fn readQuat =
(
	q1 = readFloatB()
	q2 = readFloatB()
	q3 = readFloatB()
	q4 = readFloatB()
	normalize (quat q1 q2 q3 q4)
)

-- Read translation/position (3 floats, scaled to 3ds Max units)
fn readTrans =
(
	f1 = readFloatB() * 100
	f2 = readFloatB() * 100
	f3 = readFloatB() * 100
	[f1, f2, f3]
)

-- Read 3D point without scaling
fn readPoint3D =
(
	x = readFloatB()
	y = readFloatB()
	z = readFloatB()
	[x, y, z]
)

-- Read 3D point with scaling (for physics, same as readPoint3D)
fn readPoint3B =
(
	x = readFloatB()
	y = readFloatB()
	z = readFloatB()
	[x, y, z]
)

-- Read 3D vector (for physics forward/up vectors)
fn readVector3B =
(
	x = readFloatB()
	y = readFloatB()
	z = readFloatB()
	[x, y, z]
)

-------------------------------------------------------
-- String and data parsing functions
-------------------------------------------------------

-- Read a string from the file (Latin1 encoding)
fn readStringFromFile size =
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
)

-- Read a fixed-size string (32 bytes, null-terminated)
fn readFixedString32 =
(
	readStringFromFile 32
)

-- Read a null-terminated string (reads until 0x00 byte)
fn readNullTerminatedString =
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
)

-- Read a fixed-size string (generic size)
fn readFixedString size =
(
	readStringFromFile size
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

-- Read TagRef structure (16 bytes)
fn readTagRef =
(
	local tagClass = readLongB "#unsigned"
	local pathPtr = readLongB "#signed"
	local pathLen = readLongB "#signed"
	local tagID = readLongB "#unsigned"
	#(tagClass, pathPtr, pathLen, tagID)
)

-- Read reflexive structure (12 bytes)
fn readReflexive =
(
	local count = readLongB "#signed"
	local pointer = readLongB "#unsigned"
	local id = readLongB "#unsigned"
	#(count, pointer, id)
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

format "Halo CE Tag Reading Utilities loaded successfully.\n"