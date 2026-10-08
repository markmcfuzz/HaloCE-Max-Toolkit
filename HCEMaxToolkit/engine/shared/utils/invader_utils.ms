------------------------------------------------------------------------------
--	Copyright (C) 2026 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------

-- invader-edit wrapper
-- The executable is not shipped with the toolkit: each user sets its path in
-- Settings -> External Tools (config.ini [paths] invader_edit_path).
--
-- invader-edit value formats (checked against invader-edit.exe):
--   enum       -> option name only ("double_biased_multiply"), indices are rejected
--   bitfield   -> "<bitmask>.<bit> 1" (the whole bitmask can't be set at once)
--   colorRGB   -> "r,g,b"   colorARGB -> "a,r,g,b"   point2d -> "x,y"   vector3d -> "i,j,k"
--   float      -> fixed point ("0.000010"); exponent notation ("1e-05") is misparsed
--   angle      -> raw radians on -S (-G prints degrees)
--   dependency -> tags-relative path WITH extension ("test\bitmaps\a.bitmap")
--   -N         -> overwrites an existing tag

-------------------------------------------------------
-- Executable path
-------------------------------------------------------

-- Configured invader-edit.exe path, or undefined if not set / missing on disk
fn getInvaderEditPath =
(
	local exePath = configManager.getString "paths" "invader_edit_path" ""
	if exePath == "" or not (doesFileExist exePath) then undefined else exePath
)

-------------------------------------------------------
-- Value formatting
-------------------------------------------------------

fn invaderFloat v = formattedPrint (v as float) format:".6f"

-------------------------------------------------------
-- Process execution
-------------------------------------------------------

-- Quote one command line argument (Windows CommandLineToArgv rules)
fn _invaderQuoteArg arg =
(
	arg = arg as string
	if arg != "" and (findString arg " ") == undefined and (findString arg "\"") == undefined then
		return arg
	arg = substituteString arg "\"" "\\\""
	-- Backslashes right before the closing quote must be doubled
	local trailing = ""
	local i = arg.count
	while i > 0 and arg[i] == "\\" do
	(
		trailing += "\\"
		i -= 1
	)
	"\"" + arg + trailing + "\""
)

fn _invaderJoinArgs args =
(
	local ss = stringStream ""
	for i = 1 to args.count do
	(
		if i > 1 then format " " to:ss
		format "%" (_invaderQuoteArg args[i]) to:ss
	)
	ss as string
)

-- Run invader-edit on one tag. args are the operations (-N, -I, -S, -l ...);
-- "-t <tagsDir>" and the tag path are added here.
-- Returns #(exitCode, stdout, stderr)
fn runInvaderEdit exePath tagsDir relTagPath args =
(
	local allArgs = #("-t", tagsDir) + args + #(relTagPath)
	local argString = _invaderJoinArgs allArgs
	logger.debug "invader-edit {}" args:#(argString)

	local psi = dotNetObject "System.Diagnostics.ProcessStartInfo" exePath argString
	psi.UseShellExecute = false
	psi.CreateNoWindow = true
	psi.RedirectStandardOutput = true
	psi.RedirectStandardError = true
	psi.StandardOutputEncoding = (dotNetClass "System.Text.Encoding").UTF8
	psi.WorkingDirectory = tagsDir

	local proc = undefined
	try ( proc = (dotNetClass "System.Diagnostics.Process").Start psi )
	catch ( return #(-1, "", ("Could not start invader-edit: " + getCurrentException())) )

	-- invader-edit writes little to stderr, so reading the streams in sequence can't deadlock
	local stdOut = proc.StandardOutput.ReadToEnd()
	local stdErr = proc.StandardError.ReadToEnd()
	proc.WaitForExit()
	local exitCode = proc.ExitCode
	proc.Dispose()
	#(exitCode, stdOut, stdErr)
)

-- Run -S operations in as few calls as the command line length allows.
-- setArgs is a flat array: #("-S", key, value, "-S", key, value, ...)
-- Returns #(exitCode, stdout, stderr) of the first failing call (or the last one)
fn runInvaderEditChunked exePath tagsDir relTagPath setArgs maxChars:24000 =
(
	local result = #(0, "", "")
	local chunk = #()
	local chunkLen = 0
	local i = 1
	while i <= setArgs.count do
	(
		local triple = #(setArgs[i], setArgs[i + 1], setArgs[i + 2])
		local tripleLen = 0
		for a in triple do tripleLen += (a as string).count + 4
		if chunk.count > 0 and chunkLen + tripleLen > maxChars then
		(
			result = runInvaderEdit exePath tagsDir relTagPath chunk
			if result[1] != 0 then return result
			chunk = #()
			chunkLen = 0
		)
		join chunk triple
		chunkLen += tripleLen
		i += 3
	)
	if chunk.count > 0 then
		result = runInvaderEdit exePath tagsDir relTagPath chunk
	result
)

-------------------------------------------------------
-- Enum discovery
-------------------------------------------------------

-- Strip the tree drawing prefix (box-drawing characters) from a -l output token
fn _invaderStripTree token =
(
	local valid = "abcdefghijklmnopqrstuvwxyz0123456789_"
	local i = 1
	while i <= token.count and (findString valid (toLower token[i])) == undefined do i += 1
	substring token i -1
)

-- Parse "invader-edit -l" output into a Dictionary: enum field name -> #(option names)
-- (option index = array index - 1). Enums nested in blocks are keyed by their leaf name.
fn parseInvaderEnums listOutput =
(
	local enums = dictionary #string
	local currentName = undefined
	local currentValues = #()
	for rawLine in (filterString listOutput "\r\n") do
	(
		local line = trimRight rawLine
		local isValue = matchPattern line pattern:"* enum value"
		local isEnum = (not isValue) and (matchPattern line pattern:"* enum")
		if isValue and currentName != undefined then
		(
			local tokens = filterString (substring line 1 (line.count - 10)) " "
			if tokens.count > 0 then append currentValues (_invaderStripTree tokens[tokens.count])
		)
		else
		(
			if currentName != undefined and not (hasDictValue enums currentName) then
				enums[currentName] = currentValues
			currentName = undefined
			currentValues = #()
			if isEnum then
			(
				local tokens = filterString (substring line 1 (line.count - 4)) " "
				if tokens.count > 0 then currentName = _invaderStripTree tokens[tokens.count]
			)
		)
	)
	if currentName != undefined and not (hasDictValue enums currentName) then
		enums[currentName] = currentValues
	enums
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
