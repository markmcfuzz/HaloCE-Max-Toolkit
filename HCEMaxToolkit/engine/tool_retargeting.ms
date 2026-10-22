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
--
--	RETARGETING
--
--	Transfers animation between two different skeletons (source -> target), for example two
--	first person arm rigs with different bone names and bone axes.
--
--	1. Pick both rigs and map their bones (Auto Map, then fix by hand).
--	2. With both rigs in their bind pose, Capture Rest Pose. They don't need to look alike.
--	3. Retarget the scene animation onto the target rig, or a folder of JMA-family files.
--
--	Same method as the Halo 5 animation tool: each bone's rest offset is found by lining up a
--	frame built the same way on both rigs (bone direction + palm normal), so bone axes and rest
--	poses can differ. Target bone lengths are kept, animated translations (shoulders) carry over,
--	and optional hand IK lines up the knuckles. Mapping and capture are saved as a preset.
--
------------------------------------------------------------------------------

-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Log file setup
scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

-- Load required modules
include "formats\\jma\\jma_struct.ms"
include "formats\\jma\\jma_reader.ms"
include "formats\\jma\\process_scene.ms"
include "formats\\jma\\process_file.ms"
include "core\\retarget\\retarget_mapping.ms"
include "core\\retarget\\retarget_solver.ms"
include "core\\retarget\\retarget_naming.ms"

(
    global RetargetingRollout
    try (destroyDialog RetargetingRollout) catch()

    local toolTitle = "Retargeting"
    local iniSection = "retargeting"
    local animationTypes = #(".jma", ".jmm", ".jmo", ".jmr", ".jmt", ".jmw", ".jmz")
    local noSource = "-"
    local otherFolder = "not_in_halo_ce"

    fn pickFilter obj = isNodeObject obj

    fn normDir dir =
    (
        if dir == undefined or dir == "" then "" else if dir[dir.count] == "\\" then dir else dir + "\\"
    )

    fn saveSetting key value =
    (
        if configManager.iniPath != undefined do setINISetting configManager.iniPath iniSection key value
    )

    fn loadSetting key = configManager.getString iniSection key ""

    fn joinLines lines maxLines:15 =
    (
        local text = ""
        for i = 1 to (amin lines.count maxLines) do text += lines[i] + "\n"
        if lines.count > maxLines do text += "... (" + ((lines.count - maxLines) as string) + " more, see the listener)\n"
        text
    )

    -- Keys anywhere under the transform controller (Euler rotations keep them on sub controllers)
    fn rigHasKeys rigNodes =
    (
        for n in rigNodes do
        (
            local stack = #(n.controller)
            while stack.count > 0 do
            (
                local c = stack[stack.count]
                stack.count = stack.count - 1
                if c == undefined do continue
                if (try (c.keys.count > 0) catch (false)) do return true
                for k = 1 to c.numSubs do
                (
                    local sub = c[k]
                    if sub != undefined and sub.controller != undefined do append stack sub.controller
                )
            )
        )
        false
    )

    fn findAnimationFiles dir =
    (
        local files = #()
        if dir != "" and doesDirectoryExist dir do
            for f in getFiles (dir + "*.*") where (findItem animationTypes (toLower (getFilenameType f))) > 0 do
                append files f
        sort files
    )

    -------------------------------------------------------
    -- UI
    -------------------------------------------------------

    rollout RetargetingRollout "Retargeting" width:380
    (
        local preset = undefined
        local sourceRig = #()
        local targetRig = #()

        group "Skeletons"
        (
            label lblSourceTitle "Source (animation from):" align:#left across:2
            label lblTargetTitle "Target (animation to):" align:#left
            pickbutton pckSource "Pick source rig" width:170 filter:pickFilter across:2 \
                tooltip:"Pick any bone of the rig that has the animation"
            pickbutton pckTarget "Pick target rig" width:170 filter:pickFilter \
                tooltip:"Pick any bone of the rig that will receive the animation"
            label lblSource "" align:#left across:2
            label lblTarget "" align:#left
            button btnSwap "Swap Source / Target" width:350 \
                tooltip:"Exchanges both rigs and inverts the mapping. The capture stays valid."
        )
        group "Bone Mapping (target  <-  source)"
        (
            listbox lbxMap "" height:16 width:350
            label lblSourceBone "Source bone:" align:#left across:2 offset:[0,3]
            dropdownList ddlSource "" width:270 align:#right
            label lblAdjust "Adjust (deg):" align:#left across:4 offset:[0,1]
            spinner spnAdjustX "X " range:[-180, 180, 0] fieldwidth:40 \
                tooltip:"Constant correction of the selected target bone, like rotating it in Local: X, then Y, then Z"
            spinner spnAdjustY "Y " range:[-180, 180, 0] fieldwidth:40
            spinner spnAdjustZ "Z " range:[-180, 180, 0] fieldwidth:40
            button btnAutoMap "Auto Map" width:84 across:4
            button btnClear "Clear" width:84
            button btnLoad "Load..." width:84
            button btnSave "Save..." width:84
            label lblMap "" align:#left width:350
        )
        group "Rest Pose"
        (
            label lblHelp1 "Both rigs in their bind pose, without animation, at their" align:#left
            label lblHelp2 "imported place. They don't need to look alike." align:#left
            button btnCapture "Capture Rest Pose" width:350 \
                tooltip:"Weapon: link it to the target hand before capturing and leave its nodes unmapped. Nodes with the same name in the animation (b_gun...) then follow it."
            label lblCapture "" align:#left width:350
        )
        group "Options"
        (
            checkbox chkIK "Match hand positions (IK)" checked:true across:2 \
                tooltip:"Moves the target arms so their middle knuckles land on the source ones (needed for weapons to line up). Off: only rotations are copied."
            spinner spnShoulderReach "Shoulder reach: " range:[0, 100, 2] fieldwidth:40 align:#right \
                tooltip:"When a hand can't reach its goal, the shoulder slides toward it by up to this distance (0 = never)"
            checkbox chkTranslations "Copy bone translations" checked:true across:2 \
                tooltip:"Bones the source animation moves (first person shoulders) move the same on the target. Bone lengths are kept."
            spinner spnRootScale "Root move scale: " range:[0, 100, 1] scale:0.01 fieldwidth:40 align:#right \
                tooltip:"Scales how far the root moves away from its rest place"
            checkbox chkCamera "Remove camera motion, node:" checked:true across:2 \
                tooltip:"Takes every source pose relative to this node, like a fixed first person camera (Halo 5: b_camera_control). Ignored when the animation doesn't have it."
            edittext edtCamera "" text:"b_camera_control" fieldWidth:150 align:#right
        )
        group "Scene"
        (
            button btnScene "Retarget Scene Animation" width:350 height:28 \
                tooltip:"Samples the source rig over the animation range and keys the target rig (its old keys are replaced)"
        )
        group "Batch (JMA, JMM, JMO, JMR, JMT, JMW, JMZ)"
        (
            edittext edtIn "Source:" fieldWidth:265 readOnly:true across:2
            button btnIn "..." width:30 align:#right offset:[0,-2]
            edittext edtOut "Output:" fieldWidth:265 across:2
            button btnOut "..." width:30 align:#right offset:[0,-2]
            checkbox chkHaloNames "Halo CE file names (first-person reload-full, fire-1%0...)" checked:true \
                tooltip:"Renames first person animations to stock Halo CE names so the folder compiles as is. Animations Halo CE doesn't have go to a subfolder."
            label lblFiles "" align:#left width:350
            button btnBatch "Retarget Folder" width:350 height:28
        )
        progressBar pbProgress width:350 height:10
        label lblStatus "" align:#left width:350

        fn rigNames rig = for n in rig collect n.name

        -- Scene rig when picked, otherwise the captured pose from the preset
        fn currentTargetNames =
        (
            if targetRig.count > 0 then rigNames targetRig
            else if preset.targetPose != undefined then preset.targetPose.names
            else #()
        )

        fn currentSourceNames =
        (
            if sourceRig.count > 0 then rigNames sourceRig
            else if preset.sourcePose != undefined then preset.sourcePose.names
            else #()
        )

        fn setStatus text = lblStatus.text = text

        fn refreshMapping =
        (
            local targetNames = currentTargetNames()
            local sel = lbxMap.selection
            lbxMap.items = for t in targetNames collect
            (
                local s = retargetGetSource preset t
                t + "   <-   " + (if s == undefined then noSource else s) + \
                    (if (retargetGetAdjust preset t) != undefined then "   (adjusted)" else "")
            )
            if sel > 0 and sel <= targetNames.count then lbxMap.selection = sel
            else if targetNames.count > 0 do lbxMap.selection = 1

            ddlSource.items = #(noSource) + currentSourceNames()
            local mappedCount = (for t in targetNames where (retargetGetSource preset t) != undefined collect t).count
            lblMap.text = (mappedCount as string) + " of " + (targetNames.count as string) + " target bones mapped"
        )

        fn refreshSelection =
        (
            local targetNames = currentTargetNames()
            local sel = lbxMap.selection
            if sel < 1 or sel > targetNames.count do
            (
                ddlSource.selection = 1
                spnAdjustX.value = 0
                spnAdjustY.value = 0
                spnAdjustZ.value = 0
                return false
            )
            local s = retargetGetSource preset targetNames[sel]
            local idx = if s == undefined then 0 else retargetFindName (currentSourceNames()) s
            ddlSource.selection = idx + 1
            local angles = retargetGetAdjust preset targetNames[sel]
            if angles == undefined do angles = [0, 0, 0]
            spnAdjustX.value = angles.x
            spnAdjustY.value = angles.y
            spnAdjustZ.value = angles.z
        )

        fn setAdjust =
        (
            local targetNames = currentTargetNames()
            local sel = lbxMap.selection
            if sel < 1 or sel > targetNames.count do return false
            retargetSetAdjust preset targetNames[sel] [spnAdjustX.value, spnAdjustY.value, spnAdjustZ.value]
            refreshMapping()
        )

        fn refreshCapture =
        (
            if preset.sourcePose == undefined or preset.targetPose == undefined then
                lblCapture.text = "Not captured"
            else
            (
                local missing = for p in preset.pairs where (retargetFindName preset.targetPose.names p[1]) == 0 \
                    or (retargetFindName preset.sourcePose.names p[2]) == 0 collect p
                lblCapture.text = "Captured: " + (preset.sourcePose.names.count as string) + " source / " + \
                    (preset.targetPose.names.count as string) + " target bones" + \
                    (if missing.count > 0 then " - " + (missing.count as string) + " pair(s) not captured, capture again" else "")
            )
        )

        fn refreshRigLabels =
        (
            pckSource.text = if sourceRig.count > 0 then sourceRig[1].name else "Pick source rig"
            pckTarget.text = if targetRig.count > 0 then targetRig[1].name else "Pick target rig"
            lblSource.text = if sourceRig.count > 0 then (sourceRig.count as string) + " bones" else \
                (if preset.sourcePose != undefined then "(from preset)" else "")
            lblTarget.text = if targetRig.count > 0 then (targetRig.count as string) + " bones" else \
                (if preset.targetPose != undefined then "(from preset)" else "")
        )

        fn refreshAll =
        (
            refreshRigLabels()
            refreshMapping()
            refreshSelection()
            refreshCapture()
            spnRootScale.value = preset.rootScale
            chkCamera.checked = preset.cameraNode != ""
            if preset.cameraNode != "" do edtCamera.text = preset.cameraNode
        )

        fn syncCamera =
        (
            preset.cameraNode = if chkCamera.checked then trimRight (trimLeft edtCamera.text) else ""
        )

        fn setRig picked isSource =
        (
            local root = retargetFindRigRoot picked
            local rig = retargetCollectRig root
            if rig.count == 0 do
            (
                messageBox "No visible Halo nodes found under that rig." title:toolTitle
                return false
            )
            if isSource then
            (
                sourceRig = rig
                preset.sourceRoot = root.name
            )
            else
            (
                targetRig = rig
                preset.targetRoot = root.name
            )
            refreshAll()
            true
        )

        -- Rigs named in a preset are picked automatically when they're in the scene
        fn findPresetRigs =
        (
            local src = if preset.sourceRoot != "" then getNodeByName preset.sourceRoot else undefined
            local tgt = if preset.targetRoot != "" then getNodeByName preset.targetRoot else undefined
            sourceRig = if src != undefined and (isNodeObject src) then retargetCollectRig (retargetFindRigRoot src) else #()
            targetRig = if tgt != undefined and (isNodeObject tgt) then retargetCollectRig (retargetFindRigRoot tgt) else #()
        )

        fn loadPresetFile filePath =
        (
            local loaded = retargetReadPreset filePath
            if loaded == undefined do
            (
                messageBox ("Could not read the preset:\n" + filePath) title:toolTitle
                return false
            )
            preset = loaded
            findPresetRigs()
            saveSetting "last_preset" filePath
            refreshAll()
            setStatus ("Preset loaded: " + (filenameFromPath filePath))
            true
        )

        fn checkRigs needScene:true =
        (
            if needScene and (sourceRig.count == 0 or targetRig.count == 0) do
            (
                messageBox "Pick both the source and the target rig first." title:toolTitle
                return false
            )
            if needScene and sourceRig[1] == targetRig[1] do
            (
                messageBox "Source and target are the same rig." title:toolTitle
                return false
            )
            if preset.pairs.count == 0 do
            (
                messageBox "No bones are mapped yet. Use Auto Map or pick source bones in the list." title:toolTitle
                return false
            )
            true
        )

        fn prepareContext =
        (
            if preset.sourcePose == undefined or preset.targetPose == undefined do
            (
                messageBox "Capture the rest pose first (Rest Pose > Capture Rest Pose)." title:toolTitle
                return undefined
            )
            preset.rootScale = spnRootScale.value
            syncCamera()
            local ctx = retargetPrepare preset useIK:chkIK.checked copyTranslations:chkTranslations.checked \
                shoulderReach:spnShoulderReach.value
            for w in ctx.warnings do logger.warn "{}" args:#(w)
            if ctx.warnings.count > 0 and not (queryBox ((joinLines ctx.warnings) + "\nContinue anyway?") title:toolTitle) do
                return undefined
            ctx
        )

        fn runCapture =
        (
            if not (checkRigs()) do return false
            local animated = for rig in #(sourceRig, targetRig) where rigHasKeys rig collect rig[1].name
            if animated.count > 0 and not (queryBox ("These rigs have keyframes: " + (joinLines animated) + \
                "\nThe rest pose must be the bind pose. Capture at the current frame anyway?") title:toolTitle) do
                return false
            preset.sourcePose = retargetCapturePose sourceRig
            preset.targetPose = retargetCapturePose targetRig
            local warnings = (retargetPoseWarnings preset.sourcePose "Source") + (retargetPoseWarnings preset.targetPose "Target")
            refreshCapture()
            setStatus ("Rest pose captured at frame " + ((sliderTime.frame as integer) as string) + ". Save the preset to keep it.")
            if warnings.count > 0 do messageBox (joinLines warnings) title:toolTitle
        )

        fn runScene =
        (
            if not (checkRigs()) do return false
            local ctx = prepareContext()
            if ctx == undefined do return false
            local start = timestamp()
            local result = undefined
            undo "Retarget Animation" on
            (
                with redraw off result = retargetBakeScene ctx sourceRig targetRig progressBar:pbProgress
            )
            pbProgress.value = 0
            redrawViews()
            for m in result[2] do logger.warn "{}" args:#(m)
            setStatus ((result[1] as string) + " frames retargeted in " + (((timestamp() - start) / 1000.0) as string) + " s")
            local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true
            if result[2].count > 0 then messageBox ("Done, with warnings:\n\n" + (joinLines result[2])) title:toolTitle
            else if showDialogs do messageBox ((result[1] as string) + " frames retargeted onto the target rig.") title:toolTitle
        )

        fn refreshFiles =
        (
            local files = findAnimationFiles (normDir edtIn.text)
            lblFiles.text = if edtIn.text == "" then "" else (files.count as string) + " animation file(s)"
        )

        fn runBatch =
        (
            if not (checkRigs needScene:false) do return false
            local inDir = normDir edtIn.text
            local outDir = normDir edtOut.text
            local files = findAnimationFiles inDir
            if files.count == 0 do
            (
                messageBox "Choose a source folder with animation files." title:toolTitle
                return false
            )
            if outDir == "" or (toLower outDir) == (toLower inDir) do
            (
                messageBox "Choose an output folder different from the source folder." title:toolTitle
                return false
            )
            local ctx = prepareContext()
            if ctx == undefined do return false
            if not doesDirectoryExist outDir do makeDir outDir all:true

            -- Halo CE names: files without an equivalent go to a subfolder, so outDir compiles as is
            local ceNames = if chkHaloNames.checked then retargetHaloCENames files else undefined
            local otherDir = outDir + otherFolder + "\\"
            local renamed = 0
            local others = 0

            local start = timestamp()
            local written = 0
            local report = #()
            for i = 1 to files.count do
            (
                local fileName = filenameFromPath files[i]
                local outPath = outDir + fileName
                if ceNames != undefined do
                (
                    if ceNames[i] != undefined then
                    (
                        outPath = outDir + ceNames[i] + (getFilenameType files[i])
                        logger.info "'{}' -> '{}'" args:#(fileName, filenameFromPath outPath)
                        renamed += 1
                    )
                    else
                    (
                        if not doesDirectoryExist otherDir do makeDir otherDir all:true
                        outPath = otherDir + fileName
                        others += 1
                    )
                )
                setStatus ("Retargeting " + fileName + " (" + (i as string) + "/" + (files.count as string) + ")")
                local result = #(false, #("unexpected error"))
                try (result = retargetJmaFile ctx files[i] outPath)
                catch (result = #(false, #(getCurrentException())))
                if result[1] do written += 1
                for m in result[2] do
                (
                    append report (fileName + ": " + m)
                    logger.warn "{}: {}" args:#(fileName, m)
                )
                pbProgress.value = 100.0 * i / files.count
            )
            pbProgress.value = 0
            saveSetting "last_input" inDir
            saveSetting "last_output" outDir
            setStatus ((written as string) + " of " + (files.count as string) + " files written in " + \
                (((timestamp() - start) / 1000.0) as string) + " s")
            local namesText = if ceNames == undefined then "" else \
                "\n" + (renamed as string) + " with Halo CE names, " + (others as string) + " without a Halo CE equivalent (in '" + otherFolder + "')."
            local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true
            if report.count > 0 then
                messageBox ((written as string) + " of " + (files.count as string) + " files written." + namesText + "\n\n" + (joinLines report)) title:toolTitle
            else if showDialogs do
                messageBox ((written as string) + " files written to:\n" + outDir + namesText) title:toolTitle
        )

        on RetargetingRollout open do
        (
            preset = retargetPreset()
            preset.pairs = #()
            preset.adjusts = #()
            preset.cameraNode = "b_camera_control"
            local lastPreset = loadSetting "last_preset"
            if lastPreset != "" and doesFileExist lastPreset then loadPresetFile lastPreset
            else refreshAll()
            edtIn.text = loadSetting "last_input"
            edtOut.text = loadSetting "last_output"
            refreshFiles()
        )

        on pckSource picked obj do setRig obj true
        on pckTarget picked obj do setRig obj false
        on btnSwap pressed do
        (
            preset = retargetSwapPreset preset
            local rig = sourceRig
            sourceRig = targetRig
            targetRig = rig
            refreshAll()
            setStatus "Source and target swapped."
        )

        on lbxMap selected index do refreshSelection()
        on ddlSource selected index do
        (
            local targetNames = currentTargetNames()
            if lbxMap.selection > 0 and lbxMap.selection <= targetNames.count do
            (
                local s = if index <= 1 then undefined else (currentSourceNames())[index - 1]
                retargetSetSource preset targetNames[lbxMap.selection] s
                refreshMapping()
                refreshCapture()
            )
        )
        on btnAutoMap pressed do
        (
            local targetNames = currentTargetNames()
            local sourceNames = currentSourceNames()
            if targetNames.count == 0 or sourceNames.count == 0 then
                messageBox "Pick both rigs first." title:toolTitle
            else
            (
                preset.pairs = retargetAutoMap targetNames sourceNames
                refreshAll()
                setStatus "Auto Map done. Check the list: unmatched bones show '-'."
            )
        )
        on btnClear pressed do
        (
            if queryBox "Clear the whole bone mapping?" title:toolTitle do
            (
                preset.pairs = #()
                refreshAll()
            )
        )
        on btnLoad pressed do
        (
            local filePath = getOpenFileName caption:"Load retarget preset" filename:(retargetPresetDir()) \
                types:"Retarget preset (*.tsv)|*.tsv|All files (*.*)|*.*"
            if filePath != undefined do loadPresetFile filePath
        )
        on btnSave pressed do
        (
            local defaultName = if preset.sourceRoot != "" and preset.targetRoot != "" then \
                (preset.sourceRoot + " to " + preset.targetRoot + ".tsv") else "retarget.tsv"
            local filePath = getSaveFileName caption:"Save retarget preset" filename:(retargetPresetDir() + defaultName) \
                types:"Retarget preset (*.tsv)|*.tsv"
            if filePath != undefined do
            (
                preset.rootScale = spnRootScale.value
                syncCamera()
                if retargetWritePreset filePath preset then
                (
                    saveSetting "last_preset" filePath
                    setStatus ("Preset saved: " + (filenameFromPath filePath))
                )
                else messageBox ("Could not write the preset:\n" + filePath) title:toolTitle
            )
        )
        on spnAdjustX changed val do setAdjust()
        on spnAdjustY changed val do setAdjust()
        on spnAdjustZ changed val do setAdjust()
        on btnCapture pressed do runCapture()
        on spnRootScale changed val do preset.rootScale = val
        on chkCamera changed state do syncCamera()
        on edtCamera changed txt do syncCamera()
        on btnScene pressed do runScene()
        on btnIn pressed do
        (
            local dir = getSavePath caption:"Select the folder with the source animations" \
                initialDir:(if edtIn.text != "" then edtIn.text else maxFilePath)
            if dir != undefined do
            (
                edtIn.text = normDir dir
                if edtOut.text == "" do edtOut.text = edtIn.text + "retargeted\\"
                refreshFiles()
            )
        )
        on btnOut pressed do
        (
            local dir = getSavePath caption:"Select the output folder" initialDir:edtOut.text
            if dir != undefined do edtOut.text = normDir dir
        )
        on btnBatch pressed do runBatch()
    )

    createDialog RetargetingRollout style:#(#style_titlebar, #style_sysmenu, #style_minimizebox)
)
