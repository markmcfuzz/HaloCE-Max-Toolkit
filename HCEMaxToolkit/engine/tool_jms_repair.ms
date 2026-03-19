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
--
--	JMS FORMAT REPAIR TOOL
--	
--	PURPOSE: Repairs ultra-rare JMS edge case formats that cannot be directly imported.
--	
--	SUPPORTED FORMATS:
--	  - Case 2: Ultra-inline format (ALL vertices + triangle count on ONE massive line)
--	
--	NOT NEEDED FOR:
--	  - Standard format (HCE Max Toolkit, invader-recover) - Import directly
--	  - Inline Case 1 format (each object on one line) - Import directly
--	  - Blender format - Import directly
--	
--	All common formats are now natively supported by the JMS importer.
--	Only use this tool for extremely unusual legacy files.
--
------------------------------------------------------------------------------------------------

-- Get script directory
scriptDir = getFilenamePath (getThisScriptFilename())

-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Log file setup
scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

logger.log "=== JMS FORMAT REPAIR TOOL ==="

-- Get the toolkit root directory
fn getToolkitRoot = 
(	
	return( pathConfig.removePathLeaf scriptDir )
)
-- Find Lua executable
fn findLuaExecutable = 
(	
	local toolkitRoot = getToolkitRoot()
	-- Primary: bundled LuaJIT in toolkit runtime
	local luaJitPath = toolkitRoot + "\\engine\\runtime\\bin\\luajit.exe"
	if doesFileExist luaJitPath then
		return #( luaJitPath, true )
	logger.warn "LuaJIT not found at expected runtime path: '{}'" args:#( luaJitPath )
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
		logger.info "Running command: {} {}" args:#( luaExe, process.StartInfo.Arguments )
		process.Start()
		local output = process.StandardOutput.ReadToEnd()
		local errorOutput = process.StandardError.ReadToEnd()
		process.WaitForExit()
		local exitCode = process.ExitCode
		if output != "" then
		(			
			logger.info "Output: '{}'" args:#( output )
		)
		if errorOutput != "" then
		(	
			logger.error "Error output: '{}'" args:#( errorOutput )
		)
		return exitCode == 0
	)

	catch
	(		
		logger.error "Exception running Lua script: '{}'" args:#( getCurrentException() )
		return false
	)
)

fn main =
(	
	-- Get toolkit root
	local toolkitRoot = getToolkitRoot()
	logger.info "Toolkit root: {}" args:#( toolkitRoot )
	-- Find Lua executable
	local luaInfo = findLuaExecutable()
	if luaInfo == undefined then
	(		
		messageBox "LuaJIT executable not found!\n\nExpected location:\n  engine\\runtime\\bin\\luajit.exe\n\nNote: This tool is only for ultra-rare JMS formats.\nMost JMS files can be imported directly." \
		title: "LuaJIT Not Found" \
		beep: false
		
		return false
	)
	
	local luaExe = luaInfo[1]
	local isLuaJIT = luaInfo[2]
	
	logger.info "Lua executable found: '{}' ('{}')" args:#( luaExe, (if isLuaJIT then "LuaJIT" else "Lua") )
	
	-- Get Lua script path
	local luaScriptPath = toolkitRoot + "\\engine\\runtime\\lua\\jms_formatter.lua"
	if not( doesFileExist luaScriptPath ) then
	(		
		messageBox( "Lua script not found at:\n" + luaScriptPath ) title: "Script Not Found" beep: false
		return false
	)
	logger.info "Lua script found: '{}'" args:#( luaScriptPath )

	-- Select input file
	local inputFile = getOpenFileName \
	caption: "Select Corrupted JMS File" \
	types: "JMS Files (*.jms)|*.jms|All Files (*.*)|*.*"

	if inputFile == undefined then
	(		
		logger.info "User cancelled file selection"
		return false
	)
	logger.info "Input file: '{}'" args:#( inputFile )
	
    -- Get output file path
	local defaultOutputPath = ( getFilenamePath inputFile )+( getFilenameFile inputFile )+ "_repaired.jms"
	
    local outputFile = getSaveFileName \
	caption: "Save Repaired JMS File" \
	filename: defaultOutputPath \
	types: "JMS Files (*.jms)|*.jms|All Files (*.*)|*.*"

	if outputFile == undefined then
	(		
		logger.info "User cancelled save location selection"
		return false
	)
	logger.info "Output file: '{}'" args:#( outputFile )
	-- Run repair
	logger.log "Starting repair process..."
	local success = runLuaScript luaExe luaScriptPath inputFile outputFile
	if success then
	(		
		messageBox( "JMS file repaired successfully!\n\nOutput file:\n" + outputFile ) title: "Success" beep: false
		logger.log "JMS file repaired successfully!"
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
		messageBox "Repair failed!\n\nCheck the log file for details.\n\nNote: Standard and inline (Case 1) JMS files are already supported by the importer." title: "Error" beep: false
		logger.error "Repair failed!"
		return false
	)
	clearListener()
)
-- Execute main function
main()