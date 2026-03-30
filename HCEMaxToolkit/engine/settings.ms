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

-- Ensure configManager is available and initialized
if configManager == undefined or configManager.iniPath == undefined then (
	local engineDir = getFilenamePath (getThisScriptFilename())
	fileIn (engineDir + "shared\\init.ms")
)

fn writeSetting section key val = (
	if configManager.iniPath != undefined then
		setINISetting configManager.iniPath section key (if val then "1" else "0")
)

global settingsFloater

-- Close existing dialog if already open
try (destroyDialog settingsImportRollout) catch ()

-- Import Rollout
rollout settingsImportRollout "Import Settings" width:225 (
	group "Gbx/Model Importer" (
		checkbox chk_skipUncompressedVertices "Skip Uncompressed Vertices"
			tooltip:"Skips importing uncompressed vertex data for models that have both compressed and uncompressed vertices. This can reduce import times and memory usage, but may cause issues with certain models that rely on uncompressed vertex data."
	)

	group "Collision Importer" (
		--checkbox chk_importPathfindingSpheres "Import Pathfinding Spheres"
			--tooltip:"Imports pathfinding spheres, which are used for AI navigation in Halo CE. These spheres define areas where AI must avoid."
		label lbl_collision "No options yet" align:#left
	)

	group "JMS Importer" (
		checkbox chk_reuseNodes "Reuse Existing Nodes" checked:true
			tooltip:"Reuses existing nodes in the scene with the same name as the imported nodes. This only works for scenes that have the same bone hierarchy as the file."
		checkbox chk_reuseMarkers "Reuse Existing Markers" checked:true
			tooltip:"Reuses existing markers in the scene with the same name as the imported markers."
	)

	group "JMA Importer" (
		label lbl_jma "No options yet" align:#left
	)

	group "Scenario Structure BSP" (
		checkbox chk_mergeClusters       "Merge Render Geometry"
			tooltip:"Merges all clusters into a single mesh and multi-sub object material. This can impact performance."
		checkbox chk_singleSidedCollMesh "Single-Sided Collision Mesh"
			tooltip:"Imports the single-sided collision mesh, which is used for most bsp collision in Halo CE. If disabled, the single-sided collision mesh will be ignored and only the sky and special collision meshes will be imported."
		checkbox chk_skyCollMesh         "Sky Collision Mesh"
			tooltip:"Imports the sky collision mesh, which is used for sky-related collision in Halo CE."
		checkbox chk_twoSidedCollMesh    "Special Collision Mesh"
			tooltip:"Imports the special collision mesh, which is used for collision with special properties in Halo CE, such as two-sided, breakable, invisible and climbable."
		checkbox chk_portals             "Portals"
			tooltip:"Imports portal planes, which are used for visibility determination in Halo CE."
		checkbox chk_fogPlanes           "Fog Planes"
			tooltip:"Imports fog plane data, which is used for rendering fog effects in Halo CE."
		checkbox chk_weatherPolyhedra    "Weather Polyhedra"
			tooltip:"Imports weather polyhedra, which are used for weather effects in Halo CE."
		checkbox chk_markers             "Markers"
			tooltip:"Imports scenario structure bsp markers, which are used to place objects in the marker position when 'snap to markers' is enabled in sapien."
	)

	group "Camera Track" (
		checkbox chk_cameraAnimation "Keyframe Animation"
			tooltip:"Imports camera animation keyframes. If disabled, the camera with animation will not be imported."
	)

	on settingsImportRollout open do (
		chk_skipUncompressedVertices.checked  = configManager.getBool "import_gbxmodel"     "skip_uncompressed_vertices"    false
		--chk_importPathfindingSpheres.checked  = configManager.getBool "import_collision"    "import_pathfinding_spheres"    false
		chk_reuseNodes.checked			      = configManager.getBool "import_jms"           "reuse_existing_nodes"          true
		chk_reuseMarkers.checked              = configManager.getBool "import_jms"           "reuse_existing_markers"        true
		chk_mergeClusters.checked             = configManager.getBool "import_structure_bsp" "merge_all_clusters"            true
		chk_singleSidedCollMesh.checked       = configManager.getBool "import_structure_bsp" "import_single_sided_coll_mesh" false
		chk_skyCollMesh.checked               = configManager.getBool "import_structure_bsp" "import_sky_coll_mesh"          true
		chk_twoSidedCollMesh.checked          = configManager.getBool "import_structure_bsp" "import_special_coll_mesh"    false
		chk_portals.checked                   = configManager.getBool "import_structure_bsp" "import_portals"                true
		chk_fogPlanes.checked                 = configManager.getBool "import_structure_bsp" "import_fog_planes"             true
		chk_weatherPolyhedra.checked          = configManager.getBool "import_structure_bsp" "import_weather_polyhedra"      true
		chk_markers.checked                   = configManager.getBool "import_structure_bsp" "import_markers"                true
		chk_cameraAnimation.checked           = configManager.getBool "import_camera_track" "import_camera_animation"      true
	)

	on chk_skipUncompressedVertices  changed val do writeSetting "import_gbxmodel"     "skip_uncompressed_vertices"    val
	--on chk_importPathfindingSpheres  changed val do writeSetting "import_collision"    "import_pathfinding_spheres"    val
	on chk_reuseNodes                changed val do writeSetting "import_jms"           "reuse_existing_nodes"          val
	on chk_reuseMarkers              changed val do writeSetting "import_jms"           "reuse_existing_markers"        val
	on chk_mergeClusters             changed val do writeSetting "import_structure_bsp" "merge_all_clusters"            val
	on chk_singleSidedCollMesh       changed val do writeSetting "import_structure_bsp" "import_single_sided_coll_mesh" val
	on chk_skyCollMesh               changed val do writeSetting "import_structure_bsp" "import_sky_coll_mesh"          val
	on chk_twoSidedCollMesh          changed val do writeSetting "import_structure_bsp" "import_special_coll_mesh"    val
	on chk_portals                   changed val do writeSetting "import_structure_bsp" "import_portals"                val
	on chk_fogPlanes                 changed val do writeSetting "import_structure_bsp" "import_fog_planes"             val
	on chk_weatherPolyhedra          changed val do writeSetting "import_structure_bsp" "import_weather_polyhedra"      val
	on chk_markers                   changed val do writeSetting "import_structure_bsp" "import_markers"                val
	on chk_cameraAnimation           changed val do writeSetting "import_camera_track" "import_camera_animation"      val
)

-- Export Rollout
rollout settingsExportRollout "Export Settings" width:225 (
	group "JMS/JMA Exporter" (
		checkbox chk_extendedMetadata "Include Extended Metadata"
			tooltip:"Writes smoothing group data as extended metadata at the end of the JMS file.\nJMA files don't support extended metadata yet."
	)

	on settingsExportRollout open do (
		chk_extendedMetadata.checked = configManager.getBool "export_jms_jma" "export_extended_metadata" true
	)

	on chk_extendedMetadata changed val do writeSetting "export_jms_jma" "export_extended_metadata" val
)

-- General Rollout
rollout settingsGeneralRollout "General Settings" width:225 (
	group "Feedback" (
		checkbox chk_showDialogs "Show Completion Dialogs"
			tooltip:"Displays a dialog box upon completion of operations."
	)
	group "Developer" (
		checkbox chk_enableLogging "Enable Debug Logging"
			tooltip:"Enables detailed logging for debugging purposes in Max Listener. Can impact performance."
			--checkbox chk_enableTrace "Enable Trace Logging" tooltip:"Includes even more detailed logs, such as function entry/exit and variable values. Only effective if Enable Debug Logging is also enabled."
		checkbox chk_saveLogFile "Save Log File"
			tooltip:"Saves log output to a file in the logs directory. Can impact performance."
	)

	on settingsGeneralRollout open do (
		chk_showDialogs.checked   = configManager.getBool "feedback" "show_completion_dialogs" true
		chk_enableLogging.checked = configManager.getBool "logger" "enable_logging" false
		chk_saveLogFile.checked   = configManager.getBool "logger" "enable_save_log_file" false
	)

	on chk_showDialogs changed val do writeSetting "feedback" "show_completion_dialogs" val
	on chk_enableLogging changed val do writeSetting "logger" "enable_logging" val
	on chk_saveLogFile changed val do writeSetting "logger" "enable_save_log_file" val
)

-- Close previous instance if it exists
if settingsFloater != undefined then (
	try( closeRolloutFloater settingsFloater ) catch()
)

settingsFloater = newRolloutFloater "HCE Toolkit Settings" 270 675
addRollout settingsImportRollout settingsFloater
addRollout settingsExportRollout settingsFloater
addRollout settingsGeneralRollout settingsFloater
--createDialog settingsImportRollout
