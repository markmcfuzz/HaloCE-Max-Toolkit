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
	local line = readLineFromStream fileStream
	-- Handle special case: "undefined" string in old JMS files
	if line == "undefined" then
		return 0
	line as integer
)

-- Read a float value from the next line
fn readFloatValue fileStream =
(
	local line = readLineFromStream fileStream
	line as float
)

-- Read a 3D point (vector) from the next line (space or tab separated)
fn readVectorValue fileStream =
(
	local line = readLineFromStream fileStream
	local values = filterString line " \t"
	
	if values.count >= 3 then
		[values[1] as float, values[2] as float, values[3] as float]
	else
		[0, 0, 0]
)

-- Read a quaternion from the next line (i j k w format, space or tab separated)
fn readQuatValue fileStream =
(
	local line = readLineFromStream fileStream
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
	local line = readLineFromStream fileStream
	local values = filterString line " \t"
	
	if values.count >= 2 then
		[values[1] as float, values[2] as float]
	else
		[0, 0]
)

-- Legacy function for compatibility
fn clearTokenBuffer =
(
	-- No-op - kept for compatibility
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

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)