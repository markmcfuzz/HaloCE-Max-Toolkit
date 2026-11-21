------------------------------------------------------------------------------
--	Copyright (C) 2026 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------

-- Names beside object tag Points ("cyborg.biped"), their bounding radius, Halo markers
-- ("#headlights") and nodes ("bip01 pelvis") in the viewport. Drawn on every redraw; nothing is saved.

global viewportLabelsDraw
if viewportLabelsDraw != undefined do unregisterRedrawViewsCallback viewportLabelsDraw

-- Settings > General, or hotkeys for the "Toggle Marker Names" / "Toggle Node Names" actions
global showMarkerNames = configManager.getBool "visual" "show_marker_names" false
global showNodeNames = configManager.getBool "visual" "show_node_names" false

-- Box size of a node, so its name starts outside it (bones: width; spheres: diameter)
fn nodeLabelSize o =
(
	local objClass = classOf o
	if objClass == BoneGeometry then o.width else if objClass == Sphere then o.radius * 2.0 else 0.0
)

-- Labels drawn in this redraw as [left, bottom, width] on screen (viewportLabelsDraw empties it)
global viewportLabelSpots = #()

-- Text starting at pos (world), centered on it vertically (wText takes the text's bottom left).
-- A label over another one goes one line lower, so objects in one place stay readable
fn drawLabelAt pos text textColor =
(
	local p = gw.wTransPoint pos
	local textSize = gw.getTextExtent text
	local x = p.x + 4
	local y = p.y + textSize.y / 2
	local moved = true
	while moved do
	(
		moved = false
		for s in viewportLabelSpots where abs (s.y - y) < textSize.y and x < s.x + s.z and s.x < x + textSize.x do
		(
			y = s.y + textSize.y + 1
			moved = true
		)
	)
	append viewportLabelSpots [x, y, textSize.x]
	gw.wText [x, y, p.z] text color:textColor
)

-- Size a Point shows in the world; with Constant Screen Size it follows the zoom (as Max's
-- point helper: size x non-scaling object size x viewport width at it / 360)
fn pointLabelSize o nonScaling =
(
	if not o.constantscreensize then return o.size
	try (o.size * nonScaling * (getScreenScaleFactor o.pos) / 360.0) catch (o.size)
)

-- Right of the box; factor: where the text starts, in box sizes from its center
fn drawNodeLabel o boxSize screenRight factor:0.375 =
	drawLabelAt (o.pos + screenRight * (boxSize * factor)) o.name o.wirecolor

-- "bounding radius: 0.45 World Units" at the sphere's edge, with the number as in the tag
-- (bounding_radius.ms); helpers whose Point is gone use Near / 100
fn drawBoundingRadiusLabel h screenRight =
(
	local tagPoint = getNodeByName (substring h.name 1 (h.name.count - ".boundingRadius".count))
	local radiusText = if isObjectTagContainer tagPoint then objectFieldText tagPoint.fieldKeys tagPoint.fieldValues "bounding radius" else undefined
	if radiusText == undefined do radiusText = (h.nearDist / 100.0) as string
	drawLabelAt (h.pos + screenRight * h.nearDist) ("bounding radius: " + radiusText + " World Units") h.nearColor
)

fn viewportLabelsDraw =
(
	gw.setTransform (matrix3 1)
	viewportLabelSpots = #()
	local screenRight = (inverse (getViewTM())).row1
	local nonScaling = try (gw.nonScalingObjectSize()) catch (1.0)
	for o in objects where not o.isHiddenInVpt do
	(
		local objClass = classOf o
		-- A marker's box is 4 times its radius (helper_builder.ms)
		if objClass == HaloMarker then (if showMarkerNames do drawNodeLabel o (o.markerRadius * 4.0) screenRight)
		else if objClass == Point and isObjectTagContainer o then drawNodeLabel o (pointLabelSize o nonScaling) screenRight factor:0.75
		else if objClass == InfluenceHelper and matchPattern o.name pattern:"*.boundingRadius" then drawBoundingRadiusLabel o screenRight
		-- Nodes by name, as the JMS exporter finds them (build_utils.ms); meshes never
		else if showNodeNames and isNodeObject o and not (isGeometryObject o) do drawNodeLabel o (nodeLabelSize o) screenRight
	)
	gw.enlargeUpdateRect #whole
	gw.updateScreen()
)

fn setShowMarkerNames val =
(
	showMarkerNames = val
	setINISetting configManager.iniPath "visual" "show_marker_names" (if val then "1" else "0")
	redrawViews()
)

fn setShowNodeNames val =
(
	showNodeNames = val
	setINISetting configManager.iniPath "visual" "show_node_names" (if val then "1" else "0")
	redrawViews()
)

registerRedrawViewsCallback viewportLabelsDraw

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
