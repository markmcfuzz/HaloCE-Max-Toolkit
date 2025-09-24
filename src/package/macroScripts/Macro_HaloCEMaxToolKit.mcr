macroScript ImportGBX
    category: "Halo CE"
    toolTip: "GBX-Model Tag"
    buttonText:"Import model tag from Halo CE"
(
    on execute do 
    (
        local scriptsDir = GetDir #userscripts
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
    toolTip: "Camera Track Tag"
    buttonText:"Import camera track from Halo CE"
(
    on execute do 
    (
        local scriptsDir = GetDir #userscripts
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
    toolTip: "Jointed Model Animation (JMA)"

(
    on execute do 
    (
        local scriptsDir = GetDir #userscripts
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
    buttonText:"Export Jointed Model Animation"
(
    on execute do 
    (
        local scriptsDir = GetDir #userscripts
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
    buttonText:"Export Jointed Model Skeleton"
(
    on execute do 
    (
        local scriptsDir = GetDir #userscripts
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
    toolTip: "Camera Track Tag"
    buttonText:"Export camera track to Halo CE"
(
    on execute do 
    (
        local scriptsDir = GetDir #userscripts
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