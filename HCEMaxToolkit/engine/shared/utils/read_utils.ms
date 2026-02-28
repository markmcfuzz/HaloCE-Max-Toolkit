-------------------------------------------------------
-- File Handle
-------------------------------------------------------

-- Global file handles (will be set by importing scripts)
global halo_file_handle = undefined
global in_file = undefined
global tagMemoryBaseAddress = undefined

-- Set the global file handle (call this before using any read functions)
fn setCurrentFileHandle fileHandle =
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

-- Get the current file size without moving the caller's position
fn getCurrentFileSize =
(
	local f = getCurrentFileHandle()
	if f == undefined then return 0
	local cur = ftell f
	fseek f 0 #seek_end
	local len = ftell f
	fseek f cur #seek_set
	len
)

-- Set the base address for tag memory (read from tag header)
fn setTagMemoryBaseAddress tagAddress = 
(
	tagMemoryBaseAddress = tagAddress
)

fn getTagMemoryBaseAddress = tagMemoryBaseAddress

-- Alias to match old module naming convention
fn setFileHandle fileHandle =
(
	setCurrentFileHandle fileHandle
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

-- Seek to an absolute position in the current file handle
fn seekToPosition position seekMode:#seek_set =
(
	local fileHandle = getCurrentFileHandle()
	if fileHandle != undefined then
		fseek fileHandle position seekMode
)

-- Skip N bytes by reading and discarding them
fn skipBytes count =
(
	local fileHandle = getCurrentFileHandle()
	for i = 1 to count do
		readByte fileHandle #unsigned
)

-- Decode flag bits into an array of active flag name strings
fn decodeFlagBits flagValue flagNames =
(
	local activeFlagsArray = #()
	for i = 1 to flagNames.count do
	(
		if bit.get flagValue i then
			append activeFlagsArray flagNames[i]
	)
	return activeFlagsArray
)

-------------------------------------------------------
-- Parser Data Helpers
-------------------------------------------------------

-- Fast accessor struct - builds field index once for O(1) lookups
struct FastTupleAccess
(
	_data,        -- Original tuple array
	_index,       -- Field name -> array position mapping
	
	fn init tupleArray =
	(
		_data = tupleArray
		_index = #()
		
		-- Build index: array of #(fieldName, arrayIndex) pairs
		for i = 1 to tupleArray.count do
		(
			local fieldName = tupleArray[i][1]
			if fieldName != "" and fieldName != "unnamed" then
				append _index #(fieldName, i)
		)
		ok
	),
	
	-- O(1) access after building index (much faster than searching each time)
	fn get fieldName =
	(
		-- Find in index (small array, very fast)
		for entry in _index do
		(
			if entry[1] == fieldName then
				return _data[entry[2]][2]
		)
		undefined
	)
)

-- Wrap tuple array for fast access
fn wrapTupleArray tupleArray =
(
	if tupleArray == undefined or classOf tupleArray != Array then
		return undefined
	
	local wrapper = FastTupleAccess()
	wrapper.init tupleArray
	wrapper
)

-- Wrap reflexive array (array of tuple arrays)
fn wrapReflexiveArray reflexiveArray =
(
	if reflexiveArray == undefined or classOf reflexiveArray != Array then
		return #()
	
	local wrapped = #()
	for entry in reflexiveArray do
	(
		if classOf entry == Array and entry.count > 0 and classOf entry[1] == Array then
			append wrapped (wrapTupleArray entry)
		else
			append wrapped entry
	)
	wrapped
)

-- Build field index from first tuple - returns position map
fn buildFieldIndex tupleArray =
(
	local index = #()
	for i = 1 to tupleArray.count do
	(
		local fieldName = tupleArray[i][1]
		append index #(fieldName, i)
	)
	index
)

-- Get array position for a field name from index
fn getFieldPosition fieldIndex fieldName =
(
	for i = 1 to fieldIndex.count do
	(
		if fieldIndex[i][1] == fieldName then
			return fieldIndex[i][2]
	)
	0
)

-- Extract a field value from parser tuple array #(#(name, value, fieldDef), ...)
-- Legacy function - prefer using FastTupleAccess for repeated access
fn getFieldValue dataArray fieldName =
(
	if dataArray == undefined then return undefined
	
	-- Type check: ensure dataArray is an array
	if classOf dataArray != Array then return undefined
	
	-- Use indexed access (faster than for-in loop)
	for i = 1 to dataArray.count do
	(
		if dataArray[i][1] == fieldName then
			return dataArray[i][2]
	)
	
	return undefined
)

-- Optimized multi-field extraction - get multiple fields at once
fn getFieldValues dataArray fieldNames =
(
	if dataArray == undefined then return #()
	
	-- Type check: ensure dataArray is an array
	if classOf dataArray != Array then return #()
	
	local results = #()
	results.count = fieldNames.count
	local found = 0
	local needed = fieldNames.count
	
	-- Single pass through data array
	for i = 1 to dataArray.count while found < needed do
	(
		local name = dataArray[i][1]
		for j = 1 to needed do
		(
			if fieldNames[j] == name then
			(
				results[j] = dataArray[i][2]
				found += 1
				exit
			)
		)
	)
	
	return results
)

-------------------------------------------------------
-- Binary Readers
-------------------------------------------------------
-- CE Tag Reference structure
struct tagRefData ( 
	tagClass,   -- 4 bytes: tag class fourcc
	pathPtr,    -- 4 bytes: pointer (0 for CE source tags, >0 for MCC cached)
	pathLen,    -- 4 bytes: path length (can be garbage in CE)
	tagID,      -- 4 bytes: tag ID (signed)
	path        -- null-terminated string (read separately)
)

struct reflexiveData ( 
	count, 
	pointer, 
	id 
)

struct tagData ( 
	size, 
	flags, 
	rawPointer, 
	pointer, 
	id 
)

global read = undefined
struct read
(	
	-- Read big endian short (2 bytes)
	fn shortB strType =
	(
		local f = getCurrentFileHandle()
		local b1 = readByte f #unsigned
		local b2 = readByte f #unsigned
		local val = ( b1 * 256 + b2 )
		if strType == "#signed" do
			if val > 32768 then
			val = val - 65536
		val
	),

	-- Read big endian long (4 bytes)
	fn longB strType =
	(
		local f = getCurrentFileHandle()
		local b1 = readByte f #unsigned
		local b2 = readByte f #unsigned
		local b3 = readByte f #unsigned
		local b4 = readByte f #unsigned
		local val = b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
		if strType == "#signed" do
			if val > 2147483648 then
			val = val - 4294967296
		val
	),

	-- Read big endian float (4 bytes)
	fn floatB =
	(
		local f = getCurrentFileHandle()
		local b1 = readByte f #unsigned
		local b2 = readByte f #unsigned
		local b3 = readByte f #unsigned
		local b4 = readByte f #unsigned
		-- Check for EOF
		if b1 == undefined or b2 == undefined or b3 == undefined or b4 == undefined then
		(			
			--format "ERROR: Unexpected EOF at position % (b1:%, b2:%, b3:%, b4:%)\n"( ftell f ) b1 b2 b3 b4
			return 0.0
		)
		local packed = bit.intAsFloat( ( b1 * 16777216 )+( b2 * 65536 )+( b3 * 256 )+ b4 )
		packed
	),

	fn tagString size = 
	(		
		local f = getCurrentFileHandle()
		local str = ""
		for i = 1 to size do
		(			
			local c = readByte f #unsigned
			if c != 0 do
				str += bit.intAsChar c
		)
		str
	),
	
	fn nullTerminatedString = 
	(		
		local f = getCurrentFileHandle()
		local str = ""
		local c = readByte f #unsigned
		while
			c != 0 and c != undefined do
		(			
			str += bit.intAsChar c
			c = readByte f #unsigned
		)
		str
	),

	fn tagRef deferredTagRefs: = 
	(		
		-- Tag Reference: class(4) + pathPtr(4) + pathLen(4) + tagID(4) = 16 bytes
		-- CE source tags have pathPtr=0, MCC cached tags have pathPtr>0
		local tagClass = read.longB "#unsigned"
		local pathPtr = read.longB "#signed"
		local pathLen = read.longB "#signed"
		local tagID = read.longB "#unsigned"
		
		-- Store tag ref info for deferred path reading
		local tagRefInfo = tagRefData tagClass pathPtr pathLen tagID ""
		
		-- CE source tags (pathPtr==0) always have sequential null-terminated strings
		-- Queue for deferred reading ONLY if pathLen is valid or pathPtr is 0 (CE)
		if deferredTagRefs != unsupplied and (pathLen > 0 or pathPtr == 0) then
		(
			append deferredTagRefs tagRefInfo
		)
		tagRefInfo
	),

	fn padding fieldDef =
	(
		local byteSize = case fieldDef.size of
		(
			#int8: 1
			#int16: 2
			#int32: 4
			default: 1
		)
	    local total = byteSize * fieldDef.count
		local f = getCurrentFileHandle()
		fseek f total #seek_cur
		undefined
	),

	fn rawTagData = 
	(		
		-- RawdataRef structure (20 bytes total)
		-- int32 size, int32 flags, uint32 rawPointer, uint32 pointer, uint32 id
		local dataSize = read.longB "#signed"
		local flags = read.longB "#signed"
		local rawPointer = read.longB "#unsigned"
		local pointer = read.longB "#unsigned"
		local dataId = read.longB "#unsigned"
		
		tagData dataSize flags rawPointer pointer dataId
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
-- Math readers
-------------------------------------------------------
global math = undefined
struct math
(	
	-- Read quaternion
	fn readQuat = 
	(		
		i = read.floatB()
		j = read.floatB()
		k = read.floatB()
		w = read.floatB()
		quat i j k w
		--#( i, j, k, w )
	),
    -- Read 2D Euler angles (yaw, pitch)
    fn readEuler2D = 
    (
        yaw = read.floatB()
        pitch = read.floatB()
		[yaw, pitch]
        --#( yaw, pitch )
    ),
    fn readBounds = 
    (
        a = read.floatB()
        b = read.floatB()
        [a, b]
    ),
	-- Read 2D Point
	fn readPoint2 = 
	(		
		x = read.floatB()
		y = read.floatB()
		point2 x y  -- Return Point2 object
	),
	-- Read 3D point
	fn readPoint3 = 
	(		
		x = read.floatB()
		y = read.floatB()
		z = read.floatB()
		[x, y, z]  -- Return Point3 object (square brackets)
	),
	-- Read 3D vector (same as Point3 in MaxScript)
	fn readVector3D = 
	(		
		x = read.floatB()
		y = read.floatB()
		z = read.floatB()
		[x, y, z]  -- Return Point3 object (vectors and points are both Point3 in MaxScript)
	),
    -- Read RGB color
    fn readColorRGB =
    (
        r = read.floatB()
        g = read.floatB()
        b = read.floatB()
        color r g b  -- Return Color object
    ),
    -- Read ARGB color
    fn readColorARGB =
    (
        a = read.floatB()
        r = read.floatB()
        g = read.floatB()
        b = read.floatB()
        -- MaxScript colors don't have alpha, so return Point4
        point4 r g b a
    ),
	-- Read 2D plane (ax + by + c = 0)
	fn readPlane2D =
	(
		a = read.floatB()
		b = read.floatB()
		c = read.floatB()
		[a, b, c]  -- Return array for plane coefficients
	),
    -- Read 3D plane (normal x, y, z + distance d)
    fn readPlane3D =
    (
        x = read.floatB()
        y = read.floatB()
        z = read.floatB()
        d = read.floatB()
        point4 x y z d  -- Return Point4 for plane
    )
)

-- Instantiate the read struct
read = read()
math = math()

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)