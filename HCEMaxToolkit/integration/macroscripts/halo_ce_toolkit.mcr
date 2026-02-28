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

macroScript ImportGBX
    category: "Halo CE"
    toolTip: "GBX-Model Tag"
(
    on execute do 
    (
        local thisScript = getThisScriptFilename()
        local leafPath = pathConfig.removePathLeaf thisScript
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath leafPath)
        local scriptPath = pluginRoot + "\\engine\\import_gbxmodel.ms"
        if doesFileExist scriptPath then
        (
            fileIn scriptPath
        )
        else
        (
            messageBox ("Script file not found:\n" + scriptPath) title:"Error"
        )
    )
)

macroScript ImportCollisionGeometry
    category: "Halo CE"
    toolTip: "Collision Geometry Tag"
(
    on execute do 
    (
        local thisScript = getThisScriptFilename()
        local leafPath = pathConfig.removePathLeaf thisScript
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath leafPath)
        local scriptPath = pluginRoot + "\\engine\\import_collision.ms"
        if doesFileExist scriptPath then
        (
            fileIn scriptPath
        )
        else
        (
            messageBox ("Script file not found:\n" + scriptPath) title:"Error"
        )
    )
)

macroScript ImportPhysics
    category: "Halo CE"
    toolTip: "Physics Tag"
(
    on execute do 
    (
        local thisScript = getThisScriptFilename()
        local leafPath = pathConfig.removePathLeaf thisScript
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath leafPath)
        local scriptPath = pluginRoot + "\\engine\\import_physics.ms"
        if doesFileExist scriptPath then
        (
            fileIn scriptPath
        )
        else
        (
            messageBox ("Script file not found:\n" + scriptPath) title:"Error"
        )
    )
)

macroScript ImportCameraTrack
    category: "Halo CE"
    toolTip: "Camera Track Tag"
(
    on execute do 
    (
        local thisScript = getThisScriptFilename()
        local leafPath = pathConfig.removePathLeaf thisScript
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath leafPath)
        local scriptPath = pluginRoot + "\\engine\\import_camera_track.ms"
        if doesFileExist scriptPath then
        (
            fileIn scriptPath
        )
        else
        (
            messageBox ("Script file not found:\n" + scriptPath) title:"Error"
        )
    )
)

macroScript ImportAnimationData
    category: "Halo CE"
    toolTip: "Jointed Model Animation (JMA)"
(
    on execute do 
    (
        local thisScript = getThisScriptFilename()
        local leafPath = pathConfig.removePathLeaf thisScript
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath leafPath)
        local scriptPath = pluginRoot + "\\engine\\import_jma.ms"
        if doesFileExist scriptPath then
        (
            fileIn scriptPath
        )
        else
        (
            messageBox ("Script file not found:\n" + scriptPath) title:"Error"
        )
    )
)

macroScript ImportJMS
    category: "Halo CE"
    toolTip: "Jointed Model Skeleton (JMS)"
(
    on execute do 
    (
        local thisScript = getThisScriptFilename()
        local leafPath = pathConfig.removePathLeaf thisScript
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath leafPath)
        local scriptPath = pluginRoot + "\\engine\\import_jms.ms"
        if doesFileExist scriptPath then
        (
            fileIn scriptPath
        )
        else
        (
            messageBox ("Script file not found:\n" + scriptPath) title:"Error"
        )
    )
)


-- Export Scripts

macroScript ExportJointedModelAnimation
    category: "Halo CE"
    toolTip: "Jointed Model Animation (JMA)"
(
    on execute do 
    (
        local thisScript = getThisScriptFilename()
        local leafPath = pathConfig.removePathLeaf thisScript
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath leafPath)
        local scriptPath = pluginRoot + "\\engine\\export_jma.ms"
        if doesFileExist scriptPath then
        (
            fileIn scriptPath
        )
        else
        (
            messageBox ("Script file not found:\n" + scriptPath) title:"Error"
        )
    )
)

macroScript ExportJMS
    category: "Halo CE"
    toolTip: "Jointed Model Skeleton (JMS)"
(
    on execute do 
    (
        local thisScript = getThisScriptFilename()
        local leafPath = pathConfig.removePathLeaf thisScript
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath leafPath)
        local scriptPath = pluginRoot + "\\engine\\export_jms.ms"
        if doesFileExist scriptPath then
        (
            fileIn scriptPath
        )
        else
        (
            messageBox ("Script file not found:\n" + scriptPath) title:"Error"
        )
    )
)

macroScript ExportCameraTrack
    category: "Halo CE"
    toolTip: "Camera Track Tag"
(
    on execute do 
    (
        local thisScript = getThisScriptFilename()
        local leafPath = pathConfig.removePathLeaf thisScript
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath leafPath)
        local scriptPath = pluginRoot + "\\engine\\export_camera_track.ms"
        if doesFileExist scriptPath then
        (
            fileIn scriptPath
        )
        else
        (
            messageBox ("Script file not found:\n" + scriptPath) title:"Error"
        )
    )
)

-- Tools
macroScript SphereToHaloMarkerHelper
    category: "Halo CE"
    toolTip: "Sphere to Helper Converter"
(
    on execute do 
    (
        local thisScript = getThisScriptFilename()
        local leafPath = pathConfig.removePathLeaf thisScript
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath leafPath)
        local scriptPath = pluginRoot + "\\engine\\tool_sphere_to_helper.ms"
        if doesFileExist scriptPath then
        (
            fileIn scriptPath
        )
        else
        (
            messageBox ("Script file not found:\n" + scriptPath) title:"Error"
        )
    )
)

macroScript JmsFormatter
    category: "Halo CE"
    toolTip: "JMS Format Converter"
(
    on execute do 
    (
        local thisScript = getThisScriptFilename()
        local leafPath = pathConfig.removePathLeaf thisScript
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath leafPath)
        local scriptPath = pluginRoot + "\\engine\\tool_jms_formatter.ms"
        if doesFileExist scriptPath then
        (
            fileIn scriptPath
        )
        else
        (
            messageBox ("Script file not found:\n" + scriptPath) title:"Error"
        )
    )
)

macroScript ModelAnimationsExtractor
    category: "Halo CE"
    toolTip: "Model Animations To Source"
(
    on execute do 
    (
        local thisScript = getThisScriptFilename()
        local leafPath = pathConfig.removePathLeaf thisScript
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath leafPath)
        local scriptPath = pluginRoot + "\\engine\\tool_extract_model_animations.ms"
        if doesFileExist scriptPath then
        (
            fileIn scriptPath
        )
        else
        (
            messageBox ("Script file not found:\n" + scriptPath) title:"Error"
        )
    )
)