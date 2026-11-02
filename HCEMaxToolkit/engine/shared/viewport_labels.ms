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

-- Names beside object tag Points ("cyborg.biped"), Halo markers ("#headlights") and nodes
-- ("bip01 pelvis") in the viewport, in their color. Drawn on every redraw; nothing is saved.

global viewportLabelsDraw
if viewportLabelsDraw != undefined do unregisterRedrawViewsCallback viewportLabelsDraw

-- Settings > General, or hotkeys for the "Toggle Marker Names" / "Toggle Node Names" actions
global showMarkerNames = configManager.getBool "visual" "show_marker_names" true
global showNodeNames = configManager.getBool "visual" "show_node_names" true

-- Box size of a node, so its name starts outside it (bones: width; spheres: diameter)
fn nodeLabelSize o =
(
	local objClass = classOf o
	if objClass == BoneGeometry then o.width else if objClass == Sphere then o.radius * 2.0 else 0.0
)

-- Right of the box, centered on it vertically (wText takes the text's bottom left)
fn drawNodeLabel o boxSize screenRight =
(
	local p = gw.wTransPoint (o.pos + screenRight * (boxSize * 0.35))
	local textSize = gw.getTextExtent o.name
	gw.wText [p.x + 4, p.y + textSize.y / 2, p.z] o.name color:o.wirecolor
)

fn viewportLabelsDraw =
(
	gw.setTransform (matrix3 1)
	local screenRight = (inverse (getViewTM())).row1
	for o in objects where not o.isHiddenInVpt do
	(
		local objClass = classOf o
		-- A marker's box is 4 times its radius (helper_builder.ms)
		if objClass == HaloMarker then (if showMarkerNames do drawNodeLabel o (o.markerRadius * 4.0) screenRight)
		else if objClass == Point and isObjectTagContainer o then drawNodeLabel o o.size screenRight
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
