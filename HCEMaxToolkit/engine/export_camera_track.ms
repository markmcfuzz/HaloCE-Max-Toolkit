----------------------------------------------------------------------------
--	HCE Max Toolkit - Export Camera Track
--	Copyright (C) 2026 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--
--	Exports camera track control points from 3ds Max scene to .camera_track tag
--
--	Usage:
--	1. Create helpers in scene named 'control_point01', 'control_point02', etc.
--	2. Position and orient helpers to define camera path
--	3. Run this script to export .camera_track file
--
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version.
----------------------------------------------------------------------------

-- Clear listener
clearListener()

-- Force garbage collection
gc light:true

-- Log file setup
scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

logger.log "=== EXPORTING CAMERA TRACK ==="

-- Load required modules
include "core\\halo1\\core_defs.ms"
include "core\\halo1\\groups\\camera_track.ms"
include "core\\halo1\\writer.ms"
include "pipeline\\create_tag\\create_camera_track.ms"

-------------------------------------------------------
-- MAIN EXPORT FUNCTION
-------------------------------------------------------

fn exportCameraTrack =
(
	local startTime = timestamp()
	
	-- Gather data from scene
	local cameraTrackData = gatherCameraTrackControlPoints()
	
	if cameraTrackData == undefined then
	(
		logger.error "Failed to gather camera track data from scene"
		return undefined
	)
	
	-- Validate data
	if not (validateCameraTrackData cameraTrackData cameraTrackDef) then
	(
		logger.error "Camera track data validation failed"
		messageBox "Camera track data is invalid!" title:"Export Failed"
		return undefined
	)
	
	-- Get save path from user
	local savePath = getSaveFileName \
		caption:"Save Camera Track Tag" \
		types:"Camera Track (*.camera_track)|*.camera_track|All Files (*.*)|*.*"
	
	if savePath == undefined then
	(
		logger.warn "Export cancelled by user"
		return undefined
	)
	
	-- Ensure file extension
	if (getFilenameType savePath) != ".camera_track" then
		savePath = savePath + ".camera_track"
	
	logger.info "Export path: '{}'" args:#(savePath)
	
	-- Write tag file
	local success = writeTag savePath cameraTrackDef cameraTrackData
	
	if success then
	(
		local elapsedTime = (timestamp() - startTime) / 1000.0
		local cpCount = cameraTrackData[#controlPoints].count
		
		logger.info "Export completed in {} seconds" args:#(elapsedTime)
		logger.info "Exported {} control points" args:#(cpCount)
		
		messageBox ("Successfully exported camera track!\n\n" + \
                    (cpCount as string) + " control points\n" + \
                    "File: " + (filenameFromPath savePath)) \
			title:"Export Complete"
		
		return savePath
	)
	else
	(
		logger.error "Failed to write camera track file"
		messageBox "Failed to export camera track!" title:"Export Failed"
		return undefined
	)
)

-------------------------------------------------------
-- EXECUTE
-------------------------------------------------------

result = exportCameraTrack()

if result != undefined then
	logger.log "Camera track exported to: '{}'" args:#(result)
else
	logger.log "Camera track export failed or cancelled"
