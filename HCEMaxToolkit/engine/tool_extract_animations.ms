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

-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light: true

-- Log file setup
scriptName = getFilenameFile( getThisScriptFilename() )
logger.loadConfig callerScriptName: scriptName
logger.log "=== EXTRACTING ANIMATIONS ==="

-- Load required modules
include "core\\halo1\\core_defs.ms"
include "core\\halo1\\groups\\model_animations.ms"
include "core\\halo1\\parser.ms"
include "formats\\jma\\jma_struct.ms"
include "formats\\jma\\process_file.ms"
include "pipeline\\extract_model_animations\\constants.ms"
include "pipeline\\extract_model_animations\\struct_mapper.ms"
include "pipeline\\extract_model_animations\\animation_extractor.ms"

-------------------------------------------------------
-- MAIN FUNCTION
-------------------------------------------------------

fn openModelAnimations =  (	
	local tagPath = getOpenFileName caption: "Select model_animations tag" types: "Model Animations (*.model_animations)|*.model_animations|All Files (*.*)|*.*" historyCategory: "HaloCEModelAnimations"
	
	if tagPath == undefined then (		
		logger.warn "Extraction cancelled by user."
		return undefined
	)
	local tagClass = getTagClass tagPath
	logger.info "Detected tagClass: '{}'" args: #( tagClass )
	local tagDef = getTagDefByClass tagClass

	if tagDef == undefined then (		
		logger.error "Unknown or unsupported tag class: '{}'" args: #( tagClass )
		messageBox "Unsupported tag type!" title: "Extraction Failed"
		return undefined
	)
	local tagsIdx = findString tagPath "tags\\"
	local displayPath = if tagsIdx != undefined then (substring tagPath tagsIdx -1) else tagPath
	logger.info "Tag: '{}'" args:#(displayPath)
	local success = extractModelAnimations tagPath tagDef
	
	if success != true then (		
		logger.warn "Extraction did not complete successfully."
		return undefined
	)
	clearListener()
)

openModelAnimations()