try(DestroyDialog Installer_RO)catch()

version = "v1.0.0"


rollout Installer_RO "Halo CE Max ToolKit" width:400 height:160
(
    group "INFO"
    (
        label lbl_Info "Thanks for downloading Halo CE Max ToolKit." align:#left
        label lbl_Info2 "For more info you can go to: " align:#left
        HyperLink hl_github "Github" address:"https://github.com/markmcfuzz/HaloCE-Max-Toolkit" color:(color 190 190 255) visitedColor:(color 128 128 255)
        label lbl_version version align:#right
    )
    button btn_install " Install Halo CE Max ToolKit " width:155 height:40 align:#left across:2
    button btn_uninstall " Uninstall Halo CE Max ToolKit " width:155 height:40 align:#right
    fn RemoveFiles =
    (
        hiddenDOSCommand ("rmdir /s /q \"" + ((getDir #userscripts) + @"\package\") + "\"")
        hiddenDOSCommand ("del \"" +(( getdir #userMacros ) + @"\Macro_HaloCEMaxToolKit.mcr") + "\"")
    )

    fn InstallFiles =
    (
        tempDir = ((getdir #temp) + @"\" + "package" + @"\" )
        
        copyMacroscriptsFolder = ("xcopy " + "\"" + tempDir + "macroScripts" + "\"" + " " + "\"" + (getdir #userMacros) + @"\" + "\"" + " /E")
        copyScriptsFolder = ("xcopy " + "\"" + tempDir + "scripts" + "\"" + " " + "\"" + (getDir #userscripts) + @"\" +  "\""  + " /E")
        
        hiddenDOSCommand copyMacroscriptsFolder
        hiddenDOSCommand copyScriptsFolder
        
        --colorMan.reInitIcons()
        filein (( getdir #userMacros ) + @"\Macro_HaloCEMaxToolKit.mcr")
    )

    on btn_install pressed do
    (
        RemoveFiles()
        InstallFiles()
        
        messageBox "Halo CE Max ToolKit has been succesfully installed! \n Enjoy!"
        DestroyDialog Installer_RO
        --filein ((getdir #userscripts) + "\HaloCEMaxToolKit\HaloCEMaxToolKitInit.ms")
    )

    on btn_uninstall pressed do
    (
        RemoveFiles()
        messageBox "Halo CE Max ToolKit is removed from your computer."
    )

    on Installer_RO close do
    (
        hiddenDOSCommand ("rmdir /s /q \"" + ((getDir #temp) + @"\package\") + "\"")
        hiddenDOSCommand ("del \"" +(( getdir #temp ) + @"\mzp.run") + "\"")
    )
)
createDialog Installer_RO