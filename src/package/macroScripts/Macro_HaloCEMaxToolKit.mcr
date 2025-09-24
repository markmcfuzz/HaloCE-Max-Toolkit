macroScript ImportGBX
    category: "Halo CE"
    toolTip: "Import GBX"
    --buttonText:"Import model tag from Halo CE"
(
    on execute do 
    (
        local scriptsDir = GetDir #scripts
        local scriptPath = scriptsDir + "\\halo\\import_gbx.ms"
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
    toolTip: "Camera Track"
    --buttonText:"Import camera track from Halo CE"
(
    on execute do 
    (
        local scriptsDir = GetDir #scripts
        local scriptPath = scriptsDir + "\\halo\\import_camera_track.ms"
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
    toolTip: "Import Animation Data"

(
    on execute do 
    (
        local scriptsDir = GetDir #scripts
        local scriptPath = scriptsDir + "\\halo\\import_animation_data.ms"
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
    --buttonText:"Export model tag to Halo CE"
(
    on execute do 
    (
        local scriptsDir = GetDir #scripts
        local scriptPath = scriptsDir + "\\halo\\export_animation.ms"
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
    --buttonText:"Export model tag to Halo CE"
(
    on execute do 
    (
        local scriptsDir = GetDir #scripts
        local scriptPath = scriptsDir + "\\halo\\export_jms.ms"
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
    toolTip: "Camera Track"
    --buttonText:"Export camera track to Halo CE"
(
    on execute do 
    (|
        local scriptsDir = GetDir #scripts
        local scriptPath = scriptsDir + "\\halo\\export_camera_track.ms"
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