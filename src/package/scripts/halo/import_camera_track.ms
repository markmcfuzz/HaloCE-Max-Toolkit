-- Halo Custom Edition Camera Track Importer
-- (for 3ds Max v5+)
-- Version 2.0.0
-- Created by ?
-- Contributions by:
--
-- Mark Mc'Fuzz
------------------------------------------------------------------------------------------------
-- Features:
-- - Import a camera_track tag from Halo Custom Edition.
-- - Added some validations
------------------------------------------------------------------------------------------------
--	Instructions: Run the script and select a camera_track tag. The import will execute automatically.
------------------------------------------------------------------------------------------------
-- Visit the project on GitHub
------------------------------------------------------------------------------------------------
--	Copyright (C) 2019 Mark Rizzo (mailto:mrizzo2291@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.			
------------------------------------------------------------------------------------------------

struct binReader
(
	lastPath = "C:\\",
	path = undefined,
	file = undefined,
	endianness = undefined,
	length = 0,
	
	fn load filePath endian: =
	(
		local success = false
		
		path = filePath
		if (path != undefined) then
		(
			lastPath = getFilenamePath filePath
			try
			(
				file = fopen path "rb"
				
				fseek file 0 #seek_end
				length = ftell file
				fseek file 0 #seek_set
				
				if (endian == unsupplied) then (endianness = #little)
				else
				(
					endianness = case endian of
					(
						#big : #big
						default : #little
					)
				)
				
				success = true
			)
			catch ()
		)
		
		success
	),
	fn promptPath titleStr typeStr endian: =
	(
		local success = false
		local filePath = getOpenFileName	caption:titleStr \
											fileName:lastPath \
											types:typeStr
		
		if  (filePath != undefined) then
		(
			if (endian == unsupplied) then (success = load filePath)
			else (success = load filePath endian:endian)
		)
		
		success
	),
	fn unload =
	(
		try
		(
			path = undefined
			try (fclose file) catch ()
			file = undefined
			endianness = undefined
			length = 0
			true
		)
		catch (false)
	),
	
	fn getPosition = (ftell file),
	fn setPosition val = (fseek file val #seek_set),
	fn advPosition val = (fseek file val #seek_cur),
	
	fn readInt8 type: =
	(
		local readFormat = undefined
		if (type == unsupplied) then (readFormat = #unsigned)
		else
		(
			readFormat = case type of
			(
				#signed : #signed
				default : #unsigned
			)
		)
		
		readByte file readFormat
	),
	fn readInt16 type: =
	(
		local readFormat = undefined
		if (type == unsupplied) then (readFormat = #signed)
		else
		(
			readFormat = case type of
			(
				#unsigned : #unsigned
				default : #signed
			)
		)
		
		if (endianness == #little) then
		(
			local byte2 = readByte file #unsigned
			local byte1 = readByte file #unsigned
		)
		else
		(
			local byte1 = readByte file #unsigned
			local byte2 = readByte file #unsigned
		)
		
		local returnValue = (byte1 * 256) + byte2
		if (readFormat == #signed) then
		(
			if (returnValue > 32768) then ((65536 - returnValue) * -1)
			else (returnValue)
		)
		else (returnValue)
	),
	fn readInt32 type: =
	(
		local readFormat = undefined
		if (type == unsupplied) then (readFormat = #signed)
		else
		(
			readFormat = case type of
			(
				#unsigned : #unsigned
				default : #signed
			)
		)
		
		if (endianness == #little) then
		(
			local byte4 = readByte file #unsigned
			local byte3 = readByte file #unsigned
			local byte2 = readByte file #unsigned
			local byte1 = readByte file #unsigned
		)
		else
		(
			local byte1 = readByte file #unsigned
			local byte2 = readByte file #unsigned
			local byte3 = readByte file #unsigned
			local byte4 = readByte file #unsigned
		)
		
		local returnValue = (byte1 * 16777216) + (byte2 * 65536) + (byte3 * 256) + byte4
		if (readFormat == #signed) then
		(
			if (returnValue as float > 2147483648.0) then ((4294967296 - returnValue) * -1)
			else (returnValue)
		)
		else (returnValue)
	),
	
	fn readFloat32 =
	(
		local floatBitArray = #{}
		if (endianness == #little) then
		(
			local byte4 = readByte file #unsigned
			local byte3 = readByte file #unsigned
			local byte2 = readByte file #unsigned
			local byte1 = readByte file #unsigned
		)
		else
		(
			local byte1 = readByte file #unsigned
			local byte2 = readByte file #unsigned
			local byte3 = readByte file #unsigned
			local byte4 = readByte file #unsigned
		)
		
		for i = 8 to 1 by -1 do
		(
			floatBitArray[i] = (mod byte1 2) > 0.5
			byte1 /= 2
		)
		for i = 16 to 9 by -1 do
		(
			floatBitArray[i] = (mod byte2 2) > 0.5
			byte2 /= 2
		)
		for i = 24 to 17 by -1 do
		(
			floatBitArray[i] = (mod byte3 2) > 0.5
			byte3 /= 2
		)
		for i = 32 to 25 by -1 do
		(
			floatBitArray[i] = (mod byte4 2) > 0.5
			byte4 /= 2
		)
		local exponent = 0.0
		for i = 9 to 2 by -1 do
		(
			if floatBitArray[i] then (exponent += 2.0 ^ (9 - i))
		)
		exponent -= 127.0
		local returnValue = 2.0 ^ exponent
		exponent -= 1
		for i = 10 to 32 do
		(
			if floatBitArray[i] then (returnValue += 2.0 ^ exponent)
			exponent -= 1
		)
		if floatBitArray[1] then (returnValue * -1)
		else (returnValue)
	),
	
	fn readStringToNull =
	(
		local returnString = ""
		local complete = false
		while not complete do
		(
			local byte = readByte file #unsigned
			if (byte != 0) then
			(
				local char = bit.intAsChar byte
				returnString += char
			)
			else (complete = true)
		)
		returnString
	),
	fn readStringFixed length =
	(
		local returnString = ""
		for i = 1 to length do
		(
			local byte = readByte file #unsigned
			local char = bit.intAsChar byte
			returnString += char
		)
		returnString
	)
)

struct control_point
(
	position = [0.0,0.0,0.0],
	orientation = quat 0.0 0.0 0.0 1.0
)

controlPoints = #()
trakFile = binReader ()
trakFile.lastPath = "C:\\Program Files\\Microsoft Games\\Halo Custom Edition\\tags\\camera\\"

print "Camera Track Importer - Starting..."
loaded = trakFile.promptPath "Load Camera Track" "Camera Track Tag (*.camera_track)|*.camera_track|All Files (*.*)|*.*" endian:#big
if loaded then
(
	try (
		trakFile.setPosition 0x46
		local controlPointCount = trakFile.readInt16 type:#unsigned
		print ("Found " + (controlPointCount as string) + " control points")
		
		if controlPointCount > 0 then (
			trakFile.setPosition 0x70
			for c = 1 to controlPointCount do
			(
				controlPoints[c] = control_point ()
				local pos_x = trakFile.readFloat32 ()
				local pos_y = trakFile.readFloat32 ()
				local pos_z = trakFile.readFloat32 ()
				controlPoints[c].position = [pos_x,pos_y,pos_z] * 100
				local rot_i = trakFile.readFloat32 ()
				local rot_j = trakFile.readFloat32 ()
				local rot_k = trakFile.readFloat32 ()
				local rot_w = trakFile.readFloat32 ()
				controlPoints[c].orientation = inverse (quat rot_i rot_j rot_k rot_w)
				trakFile.advPosition 0x20
				
				local ctrlPoint = pyramid ()
				ctrlPoint.width = 25
				ctrlPoint.depth = 25
				ctrlPoint.height = 25
				ctrlPoint.objectOffsetRot = quat 0.0 -0.707107 0.0 0.707107
				ctrlPoint.wirecolor = color 86 86 86
				
				ctrlPoint.rotation = controlPoints[c].orientation
				ctrlPoint.position = controlPoints[c].position
				local numberString = if ((c - 1) < 10) then ("0" + (c - 1) as string) else ((c - 1) as string)
				ctrlPoint.name = "control_point" + numberString
			)
			messageBox ("Successfully imported " + (controlPointCount as string) + " camera track control points") title:"Import Successful"
		) else (
			messageBox "No control points found in the camera track file!" title:"Import Warning"
		)
	) catch (
		messageBox "Error reading camera track file. The file may be corrupted or not a valid camera track tag." title:"Import Error"
	)
) else (
	messageBox "Camera track import cancelled by user" title: "Import Cancelled"
)
try (
	trakFile.unload ()
) catch (
	print "Warning: Could not properly close camera track file"
)