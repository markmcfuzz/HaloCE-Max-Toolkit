-- ======================================
-- TAG WRITING UTILITIES
-- ======================================
-- Mirrors read_utils.ms structure for writing binary tag data

global write = undefined
struct write
(
	fn dummy = 
	(
		logger.log "Just a dummy function"
		ok
	),
	-- Write big endian short (2 bytes)
	fn shortB file val signed:false = 
	(
		if signed and val < 0 then
			val = val + 65536
		-- Use exact same logic as Mozz script
		WriteByte file (val / 256)
		WriteByte file (mod val 256)
	),
	-- Write big endian long (4 bytes)
	fn longB file val signed:false = 
	(
		if signed and val < 0 then
			val = val + 4294967296
		WriteByte file (bit.and (bit.shift val -24) 0xFF)
		WriteByte file (bit.and (bit.shift val -16) 0xFF)
		WriteByte file (bit.and (bit.shift val -8) 0xFF)
		WriteByte file (bit.and val 0xFF)
	),
	-- Write big endian float (4 bytes)
	fn floatB file floatVal = 
	(
		-- Convert float to integer representation
		local intVal = bit.floatAsInt floatVal
		-- Write as big endian (most significant byte first)
		WriteByte file (bit.and (bit.shift intVal -24) 0xFF)
		WriteByte file (bit.and (bit.shift intVal -16) 0xFF)
		WriteByte file (bit.and (bit.shift intVal -8) 0xFF)
		WriteByte file (bit.and intVal 0xFF)
	),

	-- Write fixed-size string (padded with nulls)
	fn tagString file str size:32 = 
	(
		local actualLen = str.count
		if actualLen > size then
			actualLen = size
		
		for i = 1 to actualLen do
			WriteByte file (bit.charAsInt str[i])
		
		-- Pad remaining bytes with 0
		for i = (actualLen + 1) to size do
			WriteByte file 0
		ok
	),

	-- Write null-terminated string
	fn nullTerminatedString file str = 
	(
		for i = 1 to str.count do
			WriteByte file (bit.charAsInt str[i])
		WriteByte file 0  -- Null terminator
		ok
	),

	-- Write padding bytes
	fn padding file byteCount = 
	(
		for i = 1 to byteCount do
			WriteByte file 0
		ok
	),

	-- Write tag reference structure (16 bytes)
	fn tagRef file tagClass:0 pathPtr:0 pathLen:0 tagID:0xFFFFFFFF = 
	(
		write.longB file tagClass signed:false
		write.longB file pathPtr signed:true
		write.longB file pathLen signed:true
		write.longB file tagID signed:false
		ok
	),

	-- Write raw tag data structure (20 bytes)
	fn rawTagData file dataSize:0 flags:0 rawPointer:0 pointer:0 dataId:0 = 
	(
		write.longB file dataSize signed:true
		write.longB file flags signed:true
		write.longB file rawPointer signed:false
		write.longB file pointer signed:false
		write.longB file dataId signed:false
		ok
	),

	-- Write reflexive structure (12 bytes)
	fn reflexive file count:0 pointer:0 id:0 = 
	(
		write.longB file count signed:true
		write.longB file pointer signed:false
		write.longB file id signed:false
		ok
	)
)

-------------------------------------------------------
-- Math writers
-------------------------------------------------------
global writeMath = undefined
struct writeMath
(
	-- Write quaternion (16 bytes: i, j, k, w)
	fn quaternion file q = 
	(
		write.floatB file q.x
		write.floatB file q.y
		write.floatB file q.z
		write.floatB file q.w
		ok
	),

	-- Write 2D Euler angles (8 bytes: yaw, pitch)
	fn euler2D file val = 
	(
		write.floatB file val[1]
		write.floatB file val[2]
		ok
	),

	-- Write float bounds (8 bytes: lower, upper)
	fn bounds file val = 
	(
		write.floatB file val[1]
		write.floatB file val[2]
		ok
	),

	-- Write 2D point (8 bytes: x, y)
	fn point2D file pt = 
	(
		write.floatB file pt.x
		write.floatB file pt.y
		ok
	),

	-- Write 3D point (12 bytes: x, y, z)
	fn point3D file pt = 
	(
		write.floatB file pt.x
		write.floatB file pt.y
		write.floatB file pt.z
		ok
	),

	-- Write 3D vector (12 bytes: x, y, z)
	fn vector3D file vec = 
	(
		write.floatB file vec.x
		write.floatB file vec.y
		write.floatB file vec.z
		ok
	),

	-- Write RGB color (12 bytes: r, g, b)
	fn colorRGB file col = 
	(
		write.floatB file col.r
		write.floatB file col.g
		write.floatB file col.b
		ok
	),

	-- Write ARGB color (16 bytes: a, r, g, b)
	fn colorARGB file col = 
	(
		-- col is expected to be point4 with (r, g, b, a)
		write.floatB file col.w  -- alpha
		write.floatB file col.x  -- red
		write.floatB file col.y  -- green
		write.floatB file col.z  -- blue
		ok
	),

	-- Write 2D plane (12 bytes: a, b, c)
	fn plane2D file plane = 
	(
		write.floatB file plane[1]
		write.floatB file plane[2]
		write.floatB file plane[3]
		ok
	),

	-- Write 3D plane (16 bytes: x, y, z, d)
	fn plane3D file plane = 
	(
		write.floatB file plane.x
		write.floatB file plane.y
		write.floatB file plane.z
		write.floatB file plane.w
		ok
	)
)

-- Instantiate the write structs
write = write()
writeMath = writeMath()

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)