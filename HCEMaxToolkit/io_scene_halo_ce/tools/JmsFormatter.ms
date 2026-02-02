------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

-- Get script directory
scriptDir = getFilenamePath( getThisScriptFilename() )
-- Clear listener
clearListener()
-- Force garbage collection to clear old structs from memory
gc light: true
filein( scriptDir + "..\\modules\\global_functions\\config.ms" )
filein( scriptDir + "..\\modules\\global_functions\\utils.ms" )
-- Get the toolkit root directory
fn getToolkitRoot = 
(	
	return( pathConfig.removePathLeaf scriptDir )
)
-- Find Lua executable
fn findLuaExecutable = 
(	
	local toolkitRoot = getToolkitRoot()
	local possiblePaths = #(		
		-- Check toolkit bin folder first (bundled Lua) - prefer LuaJIT
		#( toolkitRoot + "\\bin\\luajit.exe", true ),
		#( toolkitRoot + "\\bin\\lua.exe", false ),
		#( toolkitRoot + "\\bin\\lua55.exe", false ),
		#( toolkitRoot + "\\bin\\lua54.exe", false ),
		#( toolkitRoot + "\\bin\\lua53.exe", false ),
		#( toolkitRoot + "\\bin\\lua52.exe", false ),
		#( toolkitRoot + "\\bin\\lua51.exe", false ),
		-- Check system installations
		#( getDir #maxroot + "lua\\luajit.exe", true ),
		#( getDir #maxroot + "lua\\lua.exe", false ),
		#( getDir #maxroot + "lua54.exe", false ),
		#( getDir #maxroot + "lua53.exe", false ),
		#( getDir #maxroot + "lua52.exe", false ),
		#( getDir #maxroot + "lua51.exe", false )
	)
	for pathInfo in possiblePaths do
	(
		if doesFileExist pathInfo[1] then
		(
			return pathInfo
		)
	)
	-- Try to find it in system PATH
	try
	(		
		local testCmd = "where lua 2>nul"
		local result = ( dotNetObject "System.Diagnostics.Process" )
		result.StartInfo.FileName = "cmd.exe"
		result.StartInfo.Arguments = "/c " + testCmd
		result.StartInfo.UseShellExecute = false
		result.StartInfo.RedirectStandardOutput = true
		result.StartInfo.CreateNoWindow = true
		result.Start()
		local output = result.StandardOutput.ReadToEnd()
		result.WaitForExit()
		if output != "" then
		(			
			local lines = filterString output "\n"
			if lines.count > 0 then
			(
				local exePath = trimLeft( trimRight lines[1] )
				local isJIT = (findString (toLower exePath) "luajit") != undefined
				return #( exePath, isJIT )
			)
		)
	)
	catch()
	return undefined
)
-- Run Lua script with arguments
fn runLuaScript luaExe scriptPath inputFile outputFile = 
(	
	try
	(		
		local process = dotNetObject "System.Diagnostics.Process"
		process.StartInfo.FileName = luaExe
		process.StartInfo.Arguments = "\"" + scriptPath + "\" \"" + inputFile + "\" \"" + outputFile + "\""
		process.StartInfo.UseShellExecute = false
		process.StartInfo.RedirectStandardOutput = true
		process.StartInfo.RedirectStandardError = true
		process.StartInfo.CreateNoWindow = true
		logger "Running command: % %\n" params: #( luaExe, process.StartInfo.Arguments ) logType: #info
		process.Start()
		local output = process.StandardOutput.ReadToEnd()
		local errorOutput = process.StandardError.ReadToEnd()
		process.WaitForExit()
		local exitCode = process.ExitCode
		if output != "" then
		(			
			logger "Output: %\n" params: #( output ) logType: #info
		)
		if errorOutput != "" then
		(	
            logger "Error output: %\n" params: #( errorOutput ) logType: #error
		)
		return exitCode == 0
	)

	catch

	(		
		logger "Exception running Lua script: %\n" params: #( getCurrentException() ) logType: #error
		return false
	)
)

fn main = 
(	
	logger "\n=== JMS Format Converter ===\n"
	-- Get toolkit root
	local toolkitRoot = getToolkitRoot()
	logger "Toolkit root: %\n" params: #( toolkitRoot ) logType: #info
	-- Find Lua executable
	local luaInfo = findLuaExecutable()
	if luaInfo == undefined then
	(		
		messageBox "Lua executable not found!\n\nPlease ensure the toolkit's bin folder contains lua.exe, lua55.exe, or luajit.exe.\n\nAlternatively, you can install Lua from: https://luabinaries.sourceforge.net/" title: "Lua Not Found" beep: false
		return false
	)
	
	local luaExe = luaInfo[1]
	local isLuaJIT = luaInfo[2]
	
	logger "Lua executable found: % (%)\n" params: #( luaExe, (if isLuaJIT then "LuaJIT" else "Lua") ) logType: #info
	
	-- Get Lua script path (always use jmsFormatter.lua)
	local luaScriptPath = toolkitRoot + "\\lua\\jmsFormatter.lua"
	if not( doesFileExist luaScriptPath ) then
	(		
		messageBox( "Lua script not found at:\n" + luaScriptPath ) title: "Script Not Found" beep: false
		return false
	)
	logger "Lua script found: %\n" params: #( luaScriptPath ) logType: #info
	-- Select input file
	local inputFile = getOpenFileName caption: "Select Old Format JMS File" types: "JMS Files (*.jms)|*.jms|All Files (*.*)|*.*"
	if inputFile == undefined then
	(		
		logger "User cancelled file selection\n" logType: #info
		return false
	)
    logger "Input file: %\n" params: #( inputFile ) logType: #info
	
    -- Get output file path
	local defaultOutputPath = ( getFilenamePath inputFile )+( getFilenameFile inputFile )+ "_converted.jms"
	
    local outputFile = getSaveFileName caption: "Save Converted JMS File" filename: defaultOutputPath types: "JMS Files (*.jms)|*.jms|All Files (*.*)|*.*"
	if outputFile == undefined then
	(		
		logger "User cancelled save location selection\n" logType: #info
		return false
	)
	
    logger "Output file: %\n" params: #( outputFile ) logType: #info
	-- Run conversion
	logger "\nStarting conversion...\n"
	local success = runLuaScript luaExe luaScriptPath inputFile outputFile
	if success then
	(		
		messageBox( "Conversion completed successfully!\n\nOutput file:\n" + outputFile ) title: "Success" beep: false
		logger "Conversion completed successfully!\n"
		-- Ask if user wants to open the output folder
		if queryBox "Do you want to open the output folder?" title: "Open Folder?" then
		(			
			local outputDir = getFilenamePath outputFile
			ShellLaunch "explorer.exe" outputDir
		)
		return true
	)
	else
	(		
		messageBox "Conversion failed! Check the MaxScript Listener for details." title: "Error" beep: false
		logger "Conversion failed!\n"
		return false
	)
)
-- Execute main function
main()