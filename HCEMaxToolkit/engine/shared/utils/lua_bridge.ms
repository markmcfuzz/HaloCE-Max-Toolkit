------------------------------------------------------------------------------
--	Copyright (C) 2025 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------

-- Every Lua call goes through lua\run.lua: luaRun "<module>" "<function>" #(arguments).
-- Data comes back in little-endian files (lua\bridge\maxbin.lua) read with the functions below.

-------------------------------------------------------
-- RUN LUAJIT
-------------------------------------------------------

-- Returns #(exitCode, stdout, stderr)
fn runLuaJit args =
(
	local process = dotNetObject "System.Diagnostics.Process"
	process.StartInfo.FileName = rootEngine + "runtime\\bin\\luajit.exe"
	process.StartInfo.Arguments = args
	process.StartInfo.UseShellExecute = false
	process.StartInfo.RedirectStandardOutput = true
	process.StartInfo.RedirectStandardError = true
	process.StartInfo.CreateNoWindow = true
	process.Start()
	-- Read stderr asynchronously so a full pipe cannot block the process
	local errorTask = process.StandardError.ReadToEndAsync()
	local output = process.StandardOutput.ReadToEnd()
	process.WaitForExit()
	#(process.ExitCode, output, errorTask.Result)
)

-- Runs a function of a Lua module, e.g. luaRun "bridge.jms" "read" #(jmsPath, outPath).
-- Logs what it prints; returns true when it succeeded (errors are logged).
fn luaRun moduleName functionName args =
(
	local cmd = "\"" + rootEngine + "lua\\run.lua\" " + moduleName + " " + functionName
	-- Quoted: arguments can be paths with spaces (no trailing backslash, it would escape the quote)
	for a in args do cmd += " \"" + (a as string) + "\""

	local result = runLuaJit cmd
	if result[2] != "" do logger.info "Lua: {}" args:#(result[2])
	if result[1] != 0 do logger.error "Lua {}.{} failed: {}" args:#(moduleName, functionName, result[3])
	result[1] == 0
)

-- Opens a binary written by a Lua script and checks its header (format name and version).
-- Returns the open file, or undefined (the file is deleted) when it is not the expected format.
fn luaOpenOutput outPath formatName version =
(
	local f = fopen outPath "rb"
	if f == undefined then
	(
		logger.error "Lua output not found: '{}'" args:#(outPath)
		return undefined
	)
	if (readString f) != formatName or (readLong f #signed) != version do
	(
		logger.error "Unexpected Lua output format in '{}' (expected {} v{})" args:#(outPath, formatName, version)
		fclose f
		deleteFile outPath
		return undefined
	)
	f
)

fn luaExportPath importerName = (getDir #temp) + "\\hce_" + importerName + ".bin"

fn luaCloseExport f importerName =
(
	fclose f
	deleteFile (luaExportPath importerName)
)

-- Runs an importer of lua\importers (e.g. "gbxmodel") on the tag. Returns the open output file
-- (close it with luaCloseExport and the importer name), or undefined on error (see the log).
fn luaExportTag importerName version tagPath options:#() =
(
	local outPath = luaExportPath importerName
	deleteFile outPath
	if not (luaRun "bridge.tag" "export" (#(importerName, tagPath, outPath) + options)) then
		return undefined
	-- The header repeats the importer name and its format version
	luaOpenOutput outPath importerName version
)

-- Same as luaExportTag for several tags in one LuaJIT run. The file then holds the tag count
-- and, per tag, luaReadInt 1 + the importer data, or 0 + an error message (readString).
fn luaExportTags importerName version tagPaths options:#() =
(
	local listPath = (getDir #temp) + "\\hce_" + importerName + "_list.txt"
	local listFile = createFile listPath
	for p in tagPaths do format "%\n" p to:listFile
	close listFile
	local f = luaExportTag importerName version ("@" + listPath) options:options
	deleteFile listPath
	f
)

-------------------------------------------------------
-- READERS (match lua\bridge\maxbin.lua)
-------------------------------------------------------

fn luaReadInt f = readLong f #signed

fn luaReadPoint3 f =
(
	local x = readFloat f
	local y = readFloat f
	local z = readFloat f
	[x, y, z]
)

-- Stored as i, j, k, w (tag order)
fn luaReadQuat f =
(
	local i = readFloat f
	local j = readFloat f
	local k = readFloat f
	local w = readFloat f
	quat i j k w
)

-- Tag reference in the same shape the MAXScript parser produced (#path, #tagClass)
fn luaReadTagRef f =
(
	local tagRef = dictionary #name
	tagRef[#path] = readString f
	tagRef[#tagClass] = luaReadInt f
	tagRef
)

fn luaReadPoint2 f =
(
	local x = readFloat f
	local y = readFloat f
	point2 x y
)

fn luaReadColor f =
(
	local r = readFloat f
	local g = readFloat f
	local b = readFloat f
	color r g b
)

-- ARGB colors arrive as r, g, b, a: point4, as the MAXScript parser stored them
fn luaReadARGB f =
(
	local r = readFloat f
	local g = readFloat f
	local b = readFloat f
	local a = readFloat f
	point4 r g b a
)

-- Field tuples written by lua\importers\shared\tuples.lua, as the MAXScript parser made them:
-- #(#(name, value), ...); blocks are arrays of these. Read with getFieldValue.
fn luaReadTuples f =
(
	for i = 1 to (luaReadInt f) collect
	(
		local fieldName = readString f
		local value = case (luaReadInt f) of
		(
			1: luaReadInt f
			2: readFloat f
			3: luaReadColor f
			4: luaReadARGB f
			5: luaReadPoint2 f
			6: luaReadPoint3 f
			7: luaReadTagRef f
			8: for b = 1 to (luaReadInt f) collect luaReadTuples f
			9: readString f
			default: throw ("Unknown Lua tuple value code in field '" + fieldName + "'")
		)
		#(fieldName, value)
	)
)

-------------------------------------------------------
-- WRITERS: data for a Lua script (read by maxbin.readFile in lua\bridge\maxbin.lua)
-------------------------------------------------------

fn luaWriteInt f v = writeLong f (v as integer) #signed
fn luaWriteFloat f v = writeFloat f (v as float)
-- Names can be numbers (e.g. a "region" user property): written as their text
fn luaWriteString f s = writeString f (s as string)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
