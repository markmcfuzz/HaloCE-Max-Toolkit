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

-- Tag helpers for the importers. Tags themselves are read by Lua (lua_bridge.ms).

-- Tag group fourcc from the tag header (bytes 36-39), e.g. "mod2"; undefined if the file can't be opened
fn getTagClass filePath =
(
	local f = fopen filePath "rb"
	if f == undefined then return undefined
	fseek f 36 #seek_set
	local tagClass = ""
	for i = 1 to 4 do tagClass += bit.intAsChar (readByte f #unsigned)
	fclose f
	tagClass
)

-------------------------------------------------------
-- Field tuples #(#(name, value), ...) (luaReadTuples)
-------------------------------------------------------

-- Value of the first field with that name (names compare case-insensitively), or undefined
fn getFieldValue dataArray fieldName =
(
	if classOf dataArray != Array then return undefined
	for i = 1 to dataArray.count do
	(
		if dataArray[i][1] == fieldName then
			return dataArray[i][2]
	)
	undefined
)

-- Nth occurrence of a repeated field name (e.g. the generic shader stage block lists
-- "inputA".."outputMapping" twice: color side first, then alpha side)
fn getFieldValueNth dataArray fieldName occurrence =
(
	if classOf dataArray != Array then return undefined
	local seen = 0
	for i = 1 to dataArray.count do
	(
		if dataArray[i][1] == fieldName then
		(
			seen += 1
			if seen == occurrence then return dataArray[i][2]
		)
	)
	undefined
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
