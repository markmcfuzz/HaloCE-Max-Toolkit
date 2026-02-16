----------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
----------------------------------------------------------------------------

-- Get script directory
scriptDir = getFilenamePath (getThisScriptFilename())

clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Load required modules
filein (scriptDir + "modules\\global_functions\\config.ms")
filein (scriptDir + "modules\\global_functions\\utils.ms")
filein (scriptDir + "modules\\file_jma\\jma_struct.ms")
filein (scriptDir + "modules\\file_jma\\jma_reader.ms")
filein (scriptDir + "modules\\file_jma\\build_scene.ms")

-------------------------------------------------------
-- Main Import Function
-------------------------------------------------------

fn importJmaFile jmaFile:undefined =
(
	-- Get JMA file if not provided
	if jmaFile == undefined then
	(
		jmaFile = getOpenFileName \
			caption:"Select Halo Animation File" \
			types:"Animation Files (*.jma;*.jmm;*.jmo;*.jmr;*.jmt;*.jmw;*.jmz)|*.jma;*.jmm;*.jmo;*.jmr;*.jmt;*.jmw;*.jmz|All Files (*.*)|*.*"
		
		if jmaFile == undefined then
		(
			logger "Import cancelled by user.\n"
			return undefined
		)
	)
	
	-- Read the JMA file
	local startTime = timestamp()
	local jmaData = readJmaFile jmaFile
	local readTime = (timestamp() - startTime) / 1000.0
	
	if jmaData == undefined then
	(
		logger "Could not read JMA file\n" logType:#error
		messageBox "Failed to read animation file!\n\nThe file may be corrupted, not a valid animation file, or an unsupported version." title:"Import Failed"
		return undefined
	)
	
	logger "File loaded in % seconds\n" params:#(readTime) logType:#timestamp
	
	-- Check for missing nodes before import
	local missingNodes = getMissingNodes jmaData
	local proceed = true
	
	if missingNodes.count > 0 then
	(
		local warningMsg = "Warning: The following nodes were not found in the scene:\n\n"
		
		-- Show up to 10 missing nodes
		local showCount = amin missingNodes.count 10
		for i = 1 to showCount do
			warningMsg += "  - " + missingNodes[i] + "\n"
		
		if missingNodes.count > 10 then
			warningMsg += "  ... and " + ((missingNodes.count - 10) as string) + " more\n"
		
		warningMsg += "\nAnimation will only be applied to existing nodes.\nProceed with import?"
		
		proceed = queryBox warningMsg title:"Missing Nodes"
	)
	
	if not proceed then
	(
		logger "Import cancelled by user.\n"
		return undefined
	)
	
	-- Apply animation to scene
	local buildStartTime = timestamp()
	local success = buildJmaAnimation jmaData
	local buildTime = (timestamp() - buildStartTime) / 1000.0
	
	logger "Animation applied in % seconds\n" params:#(buildTime) logType:#timestamp
	
	if success then
	(
		local totalTime = readTime + buildTime
		local fileName = filenameFromPath jmaFile
		
		logger "\n=== IMPORT COMPLETE ===\n"
		logger "Total time: % seconds\n" params:#(totalTime) logType:#timestamp
		
		local successMsg = "Animation imported successfully!\n\n"
		successMsg += "File: " + fileName + "\n"
		successMsg += "Frames: " + (jmaData.frameCount as string) + "\n"
		successMsg += "Frame Rate: " + (jmaData.frameRate as string) + " fps\n"
		
		if missingNodes.count > 0 then
			successMsg += "\nNote: " + (missingNodes.count as string) + " node(s) were not found in scene."
		
		messageBox successMsg title:"Import Complete" beep:false
		
		return jmaData
	)
	else
	(
		logger "Animation import failed\n" logType:#error
		messageBox "Animation import failed!\n\nSee the MaxScript Listener for details." title:"Import Failed"
		return undefined
	)
)

importJmaFile()