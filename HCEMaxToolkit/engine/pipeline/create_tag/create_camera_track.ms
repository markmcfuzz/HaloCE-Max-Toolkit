------------------------------------------------------------------------------------------------
--	Copyright (C) 2026 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

-------------------------------------------------------
-- GATHER CONTROL POINTS FROM SCENE
-------------------------------------------------------

fn gatherCameraTrackControlPoints =
(
	logger.log "=== GATHERING CAMERA TRACK DATA ==="
	
	-- Get all control point helpers from scene
	local controlPoints = $'control_point_*' as array
	
	if controlPoints.count == 0 then
	(
		logger.error "No control points found in scene!"
		logger.info "Create helpers named 'control_point_01', 'control_point_02', etc."
		messageBox "No control points detected!\n\nName each point to export as 'control_pointXX' where XX is the point number." \
			title:"Camera Track Export"
		return undefined
	)
	
	-- Check maximum reflexive count (16 for camera track)
	if controlPoints.count > 16 then
	(
		logger.warn "Camera track supports maximum 16 control points, found {}. Only first 16 will be exported." \
			args:#(controlPoints.count)
		controlPoints = for i = 1 to 16 collect controlPoints[i]
	)
	
	logger.info "Found {} control points" args:#(controlPoints.count)
	
	-- Prepare data structure
	local cameraTrackData = dictionary #name
	
	-- Flags (int32) - default 0
	cameraTrackData[#flags] = 0
	
	-- Control points array (reflexive)
	local controlPointsArray = #()
	
	for i = 1 to controlPoints.count do
	(
		local cp = controlPoints[i]
		local cpData = dictionary #name
		
		-- Position (vector3d) - convert from Max units (jms) to Halo units (world units)
		-- Halo uses world units where 1 unit = 100 jms = 3.048 meters
		cpData[#position] = [cp.position.x / 100.0, cp.position.y / 100.0, cp.position.z / 100.0]
		
		-- Orientation (quaternion) - Halo uses negative x,y,z for rotations
		cpData[#orientation] = quat (-cp.rotation.x) (-cp.rotation.y) (-cp.rotation.z) cp.rotation.w
		
		append controlPointsArray cpData
		
		logger.debug "  Point {}: pos=[{}, {}, {}] rot=[{}, {}, {}, {}]" args:#(
			i,
			cpData[#position].x, cpData[#position].y, cpData[#position].z,
			cpData[#orientation].x, cpData[#orientation].y, cpData[#orientation].z, cpData[#orientation].w
		)
	)
	
	cameraTrackData[#controlPoints] = controlPointsArray
	--
	logger.info "Gathered {} control points successfully" args:#(controlPoints.count)
	
	return cameraTrackData
)

-------------------------------------------------------
-- VALIDATE CAMERA TRACK DATA
-------------------------------------------------------

fn validateCameraTrackData cameraTrackData tagDef =
(
	if cameraTrackData == undefined then
		return false
	
	-- Check required fields exist
	if cameraTrackData[#controlPoints] == undefined then
	(
		logger.error "Missing controlPoints in camera track data"
		return false
	)
	
	-- Check control points count
	local cpCount = cameraTrackData[#controlPoints].count
	if cpCount == 0 then
	(
		logger.error "No control points in data"
		return false
	)
	
	if cpCount > 16 then
	(
		logger.error "Too many control points: {} (max: 16)" args:#(cpCount)
		return false
	)
	
	logger.info "Data validation passed: {} control points" args:#(cpCount)
	return true
)

-- Module loaded
scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)