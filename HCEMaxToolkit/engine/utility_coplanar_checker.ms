------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------
(
    global g_coplanarObjs
    global g_coplanarPrevMats
    global g_hasCoplanarShader
    global g_materialCache
    global CoplanarRollout

    g_coplanarObjs     = #()
    g_coplanarPrevMats = #()
    g_materialCache    = Dictionary #integer

    local scriptDir = getFilenamePath (getThisScriptFilename())
    local fxPath    = scriptDir + @"shaders\hlsl\coplanar_checker.fx"

    fn checkHasCoplanarShader theObj = (
        theObj.material != undefined and
        classOf theObj.material == DirectX_9_Shader and
        theObj.material.name == "Halo CE Coplanar Checker"
    )
    g_hasCoplanarShader = checkHasCoplanarShader

    rollout CoplanarRollout "Halo CE Toolkit" width:220 (

        label lblGroup "Geometry Utilities" align:#left
        checkbox chkCoplanar "Check Coplanar Surfaces" checked:false enabled:true
        label lblStatus "" align:#center

        fn updateCheckboxState = (
            local count = selection.count
            if count == 0 then (
                chkCoplanar.checked = false
                chkCoplanar.enabled = true
                lblStatus.text = ""
            ) 
            else if count == 1 then (
                chkCoplanar.enabled = true
                chkCoplanar.checked = checkHasCoplanarShader selection[1]
                lblStatus.text = ""
            ) 
            else (
                local withShader = 0
                for theObj in selection do (
                    if checkHasCoplanarShader theObj then withShader += 1
                )
                chkCoplanar.enabled = true
                if withShader == count then (
                    chkCoplanar.checked = true
                    lblStatus.text = ""
                ) 
                else if withShader == 0 then (
                    chkCoplanar.checked = false
                    lblStatus.text = ""
                ) 
                else (
                    chkCoplanar.checked = false
                    lblStatus.text = (withShader as string) + "/" + (count as string) + " with shader"
                )
            )
        )

        on CoplanarRollout open do (
            chkCoplanar.enabled = true
            updateCheckboxState()
        )

        on chkCoplanar changed state do (
            if selection.count == 0 then (
                messageBox "Select an object first." title:"Coplanar Checker"
                chkCoplanar.checked = false
                return()
            )
            if state then (
                if not doesFileExist fxPath then (
                    messageBox ("Shader file not found:\n" + fxPath) title:"Coplanar Checker"
                    chkCoplanar.checked = false
                    return()
                )
                local dxMat          = DirectX_9_Shader()
                dxMat.name           = "Halo CE Coplanar Checker"
                dxMat.effectFilename = fxPath

                for theObj in selection do (
                    if not checkHasCoplanarShader theObj then (
                        g_materialCache[theObj.handle] = theObj.material
                        theObj.material = dxMat
                    )
                )
                lblStatus.text = ""
                redrawViews()
            )
            else (
                for theObj in selection do (
                    if checkHasCoplanarShader theObj then (
                        local prevMat = undefined
                        local h = theObj.handle
                        if g_materialCache[h] != undefined then (
                            prevMat = g_materialCache[h]
                            g_materialCache[h] = undefined
                        )
                        theObj.material = prevMat
                    )
                )
                lblStatus.text = ""
                redrawViews()
            )
        )
    )
    local callbackName = #HCECoplanarSelectionChange
    callbacks.removeScripts #selectionSetChanged id:callbackName
    callbacks.addScript #selectionSetChanged "if CoplanarRollout != undefined then CoplanarRollout.updateCheckboxState()" \ 
        id:callbackName

    try( cui.commandPanelOpen = true ) catch()
    try( setCommandPanelTaskMode #utility ) catch()
    try( removeRollout CoplanarRollout ) catch()
    addRollout CoplanarRollout
    try( setCommandPanelTaskMode #modify ) catch()
)
