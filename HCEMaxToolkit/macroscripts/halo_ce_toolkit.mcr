macroScript ImportGBX
    category: "Halo CE"
    toolTip: "GBX-Model Tag"
(
    on execute do 
    (
        local thisScript = getThisScriptFilename()
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath thisScript)
        local scriptPath = pluginRoot + "\\io_scene_halo_ce\\import_gbxmodel.ms"
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
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath thisScript)
        local scriptPath = pluginRoot + "\\io_scene_halo_ce\\import_collision.ms"
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
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath thisScript)
        local scriptPath = pluginRoot + "\\io_scene_halo_ce\\import_physics.ms"
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
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath thisScript)
        local scriptPath = pluginRoot + "\\io_scene_halo_ce\\import_camera_track.ms"
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
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath thisScript)
        local scriptPath = pluginRoot + "\\io_scene_halo_ce\\import_animation_data.ms"
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
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath thisScript)
        local scriptPath = pluginRoot + "\\io_scene_halo_ce\\export_jma.ms"
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
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath thisScript)
        local scriptPath = pluginRoot + "\\io_scene_halo_ce\\export_jms.ms"
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
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath thisScript)
        local scriptPath = pluginRoot + "\\io_scene_halo_ce\\export_camera_track.ms"
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
        local pluginRoot = pathConfig.removePathLeaf (getFilenamePath thisScript)
        local scriptPath = pluginRoot + "\\io_scene_halo_ce\\tools\\sphere_to_helper.ms"
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