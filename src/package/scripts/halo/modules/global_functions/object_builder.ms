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

------------------------------------------------------------
-- Halo Marker Object
------------------------------------------------------------

plugin helper HaloMarker
	name:"HCE Marker"
	classID:#(0x7F8A3C12, 0x4E9B6D25)
	category:"Halo CE"
	extends:Point
	replaceUI:true
(
	parameters main rollout:params
	(
		markerType type:#string default:"Marker"
		markerRadius type:#worldunits default:1.0 ui:spn_radius
		markerColor type:#color default:(color 0 255 0) ui:col_color animatable:false
		
		on markerRadius set val do
		(
			delegate.size = val * 4.0
		)
		
		on markerType set val do
		(
			-- Update display properties based on marker type
			if val == "Marker" then
			(
				delegate.cross = false
				delegate.box = true
				delegate.axistripod = true
			)
		)
	)
	
	rollout params "HCE Marker"
	(
		button btn_update_prefix "Update Prefix"
		spinner spn_radius "Radius:" range:[0.01,10000.0,1.0] type:#worldunits
		colorpicker col_color "Color:" color:(color 0 255 0) align:#center

		on btn_update_prefix pressed do
		(
			-- Get owner node to update name
			local ownerNode = refs.dependentNodes this.delegate firstOnly:true
			if ownerNode != undefined do
			(
				-- Get current name and remove old prefix if it exists
				local oldName = ownerNode.name
				local baseName = oldName
				
				-- Remove old prefix (# or +)
				if oldName.count > 0 and (oldName[1] == "#" or oldName[1] == "+") do
					baseName = substring oldName 2 -1
				
				-- Add new prefix (always # for Marker)
				ownerNode.name = "#" + baseName
			)
		)
		
		on col_color changed val do
		(
			markerColor = val
			-- Get owner node and set wirecolor
			local ownerNode = refs.dependentNodes this.delegate firstOnly:true
			if ownerNode != undefined do
				ownerNode.wirecolor = val
		)
		
		on chk_box changed val do
		(
			showBox = val
			completeRedraw()
		)
		
		on chk_axes changed val do
		(
			showAxes = val
			completeRedraw()
		)
		
		on params open do
		(
			-- Sync color picker with current wirecolor
			local ownerNode = refs.dependentNodes this.delegate firstOnly:true
			if ownerNode != undefined do
			(
				col_color.color = ownerNode.wirecolor
				markerColor = ownerNode.wirecolor
			)
		)
	)
)

------------------------------------------------------------
-- Halo Physics Object
------------------------------------------------------------
plugin helper HaloPhysics
	name:"HCE Physics"
	classID:#(0x5A9B2D34, 0x1C7E4F89)
	category:"Halo CE"
	extends:InfluenceHelper
	replaceUI:true
(
	parameters main rollout:params
	(
		--
		physicsRadius type:#worldunits default:1.0 ui:spn_radius
		markerType type:#string default:"Physics"
		
		on physicsRadius set val do
		(
			-- Set farDist to radius and nearDist to half radius
			delegate.farDist = val
			delegate.nearDist = val - val
		)
	)

	rollout params "HCE Physics"
	(
		button btn_update_prefix "Update Prefix"
		spinner spn_radius "Radius:" range:[0.01,10000.0,1.0] type:#worldunits

		on spn_radius changed val do
		(
			physicsRadius = val
		)
		
		on btn_update_prefix pressed do
		(
			-- Get owner node to update name
			local ownerNode = refs.dependentNodes this.delegate firstOnly:true
			if ownerNode != undefined do
			(
				-- Get current name and remove old prefix if it exists
				local oldName = ownerNode.name
				local baseName = oldName
				
				-- Remove old prefix (# or +)
				if oldName.count > 0 and (oldName[1] == "#" or oldName[1] == "+") do
					baseName = substring oldName 2 -1

				-- Add new prefix (always + for Physics/Pathfinding)
				ownerNode.name = "+" + baseName
			)
		)
	)
	
	-- Override creation tool to set fixed radius on creation
	tool create
	(
		on mousePoint click do
		(
			case click of
			(
				1: (
					-- Set position and immediately stop (no dragging for size)
					nodeTM.translation = gridPoint
					-- Set fixed radius values after creation
					delegate.farDist = 1.0
					delegate.nearDist = 0
					physicsRadius = 1.0
					#stop
				)
			)
		)
	)
)

------------------------------------------------------------
-- Helper functions to create Halo objects
------------------------------------------------------------

-- Create a standard Marker helper (uses HaloMarker/Point)
fn createHaloMarker pos:[0,0,0] radius:1.0 name:"marker" wireColor:(color 0 255 0) =
(
	local marker = HaloMarker pos:pos
	marker.markerRadius = radius
	marker.markerType = "Marker"
	marker.markerColor = wireColor
	marker.wirecolor = wireColor
	
	-- Set name with "#" prefix
	if name != "" then
	(
		if name[1] != "#" and name[1] != "+" then
			marker.name = "#" + name
		else
			marker.name = name
	)
	
	marker
)

-- Create a Physics or Pathfinding helper (uses HaloPhysics/InfluenceHelper)
--
fn createHaloPhysics pos:[0,0,0] radius:1.0 markerType:"Physics" name:"massPoint" wireColor:(color 0 200 0) nearColor:(color 0 200 0) farColor:(color 0 200 0) =
(
	local marker = HaloPhysics pos:pos
	marker.physicsRadius = radius
	marker.markerType = markerType
	marker.wirecolor = wireColor
	
	-- Set colors on the delegate (InfluenceHelper)
	marker.delegate.nearColor = nearColor
	marker.delegate.farColor = farColor
	
	-- Set name with "+" prefix
	if name != "" then
	(
		if name[1] != "#" and name[1] != "+" then
			marker.name = "+" + name
		else
			marker.name = name
	)
	marker
)

-- Unified helper function (for backward compatibility)
--fn createHaloHelper pos:[0,0,0] radius:1.0 markerType:"Marker" name:"" wireColor:(color 0 255 0) =
--(
--	if markerType == "Marker" then
--		createHaloMarker pos:pos radius:radius name:name wireColor:wireColor
--	else
--		createHaloPhysics pos:pos radius:radius markerType:markerType name:name wireColor:wireColor
--)

format "\n========================================\n"
format "Halo Marker Helper Loaded Successfully!\n"
format "========================================\n"
format "Usage:\n"
format "  createHaloHelper pos:[0,0,0] radius:5.0 markerType:\"Marker\" name:\"my_helper\"\n"
format "========================================\n\n"
