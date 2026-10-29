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

-- Halo 5 animation importer (experimental).
-- The Python package in core\halo5 decodes a Halo 5 model_animation_graph into JMA-family
-- files; the existing JMA reader/builder then keys them onto the scene skeleton by node name.

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
include "builders\\jma\\build_scene.ms"

(
    global H5AnimationsRollout
    try (destroyDialog H5AnimationsRollout) catch()

    local toolTitle = "H5 Animation Tool"
    local corePath = (getFilenamePath (getThisScriptFilename())) + "core"
    local restPoseLabel = "[rest pose]"
    local manifestName = "_h5_manifest.tsv"  -- written by halo5.convert (MANIFEST_NAME)

    struct h5AnimEntry (name, type, frames, movement, file, base)
    struct h5SkeletonNode (index, name, parent, pos, xAxis, yAxis, zAxis)

    -------------------------------------------------------
    -- PYTHON CONVERTER
    -------------------------------------------------------

    -- Imports a halo5 module from engine\core, dropping cached halo5 modules so edits are picked up
    fn loadPythonModule moduleName =
    (
        local cmd = "import sys\n" + \
                    "if r'" + corePath + "' not in sys.path: sys.path.insert(0, r'" + corePath + "')\n" + \
                    "for _m in [m for m in list(sys.modules) if m == 'halo5' or m.startswith('halo5.')]: del sys.modules[_m]\n"
        python.Execute cmd
        python.import moduleName
    )

    -- The JMA builder sets 'in coordsys parent rotation' from (-i, -j, -k, w). Apply a known
    -- standard-convention rotation (+90 deg about Z) the same way: if local X does not land on
    -- world +Y, the files must carry conjugated quaternions instead.
    fn jmaNeedsConjugate =
    (
        local fileQuat = quat 0 0 0.70710678 0.70710678
        local landedOnY = false
        with undo off with redraw off
        (
            local probe = Point name:(uniqueName "h5_rotation_probe")
            in coordsys parent probe.rotation = quat (-fileQuat.x) (-fileQuat.y) (-fileQuat.z) fileQuat.w
            landedOnY = probe.transform.row1.y > 0.5
            delete probe
        )
        not landedOnY
    )

    -------------------------------------------------------
    -- FILE HELPERS
    -------------------------------------------------------

    fn parsePoint3 text =
    (
        local v = filterString text " "
        if v.count >= 3 then [v[1] as float, v[2] as float, v[3] as float] else [0,0,0]
    )

    fn readSkeletonTsv filePath =
    (
        local result = #()
        if filePath == undefined or not doesFileExist filePath then return result
        local lines = (dotNetClass "System.IO.File").ReadAllLines filePath
        for line in lines where line.count > 0 and line[1] != "#" do
        (
            local f = filterString line "\t"
            if f.count >= 7 then
            (
                local n = h5SkeletonNode()
                n.index = f[1] as integer
                n.name = f[2]
                n.parent = f[3] as integer
                n.pos = parsePoint3 f[4]
                n.xAxis = parsePoint3 f[5]
                n.yAxis = parsePoint3 f[6]
                n.zAxis = parsePoint3 f[7]
                append result n
            )
        )
        result
    )

    -- Report/manifest paths are absolute; fall back to the same file name inside the folder
    -- so a converted folder still loads after being moved.
    fn resolveInFolder filePath folder =
    (
        local result = undefined
        if filePath != undefined and filePath != "" then
        (
            result = filePath
            if not doesFileExist result then
                result = pathConfig.appendPath folder (filenameFromPath (substituteString filePath "/" "\\"))
        )
        result
    )

    fn readJmaFrameCount filePath =
    (
        local frames = 0
        local fs = openFile filePath mode:"r"
        if fs != undefined then
        (
            try (readLine fs; frames = (readLine fs) as integer) catch()
            close fs
        )
        if frames == undefined then 0 else frames
    )

    fn compareEntryNames a b = stricmp a.name b.name

    -- Folders converted before the manifest existed: list the JMA-family files directly
    fn scanConvertedFolder folder =
    (
        local entries = #()
        for ext in #("jmm", "jma", "jmt", "jmz", "jmw", "jmo", "jmr") do
            for f in getFiles (folder + "\\*." + ext) where (getFilenameFile f) != "_rest_pose" do
            (
                local animType = case ext of ("jmo": "overlay"; "jmr": "replacement"; default: "base")
                append entries (h5AnimEntry name:(getFilenameFile f) type:animType frames:(readJmaFrameCount f) movement:0 file:f base:"")
            )
        qsort entries compareEntryNames
        entries
    )

    -- Arms + weapon for first person graphs, '<graph>.render_model' next to anything else
    fn guessRenderModels graphPath =
    (
        local result = #()
        local lowerPath = toLower graphPath
        local fpIdx = findString lowerPath "\\storm_fp\\weapons\\"
        local objIdx = findString lowerPath "\\objects\\"

        if fpIdx != undefined then
        (
            local armsPath = (substring graphPath 1 fpIdx) + "storm_fp\\storm_fp.render_model"
            if doesFileExist armsPath then append result armsPath

            -- ...\storm_fp\weapons\<class>\fp_osiris_<weapon>\... -> objects\weapons\<class>\<weapon>\<weapon>.render_model
            local parts = filterString (substring graphPath (fpIdx + 18) -1) "\\"
            if parts.count >= 2 and objIdx != undefined then
            (
                local weaponName = parts[2]
                for prefix in #("fp_osiris_", "fp_") while weaponName == parts[2] do
                    if matchPattern weaponName pattern:(prefix + "*") then
                        weaponName = substring weaponName (prefix.count + 1) -1
                local weaponPath = (substring graphPath 1 (objIdx + 8)) + "weapons\\" + parts[1] + "\\" + weaponName + "\\" + weaponName + ".render_model"
                if doesFileExist weaponPath then append result weaponPath
            )
        )
        else
        (
            local graphName = getFilenameFile graphPath
            local candidates = #((getFilenamePath graphPath) + graphName + ".render_model")
            if matchPattern graphName pattern:"*_player" then
                append candidates ((getFilenamePath graphPath) + (substring graphName 1 (graphName.count - 7)) + ".render_model")
            for c in candidates where doesFileExist c and (findItem result c) == 0 do append result c
        )
        result
    )

    -------------------------------------------------------
    -- SKELETON
    -------------------------------------------------------

    fn buildH5Skeleton skeleton unitScale =
    (
        local boneSize = 0.01 * unitScale
        local layer = LayerManager.getLayerFromName "H5 Skeleton"
        if layer == undefined then layer = LayerManager.newLayerFromName "H5 Skeleton"

        local childOf = for n in skeleton collect 0
        for n in skeleton where n.parent >= 0 and childOf[n.parent + 1] == 0 do childOf[n.parent + 1] = n.index + 1

        local created = #()
        for i = 1 to skeleton.count do
        (
            local n = skeleton[i]
            local boneLength = boneSize * 2.0
            if childOf[i] > 0 then
            (
                local d = distance n.pos skeleton[childOf[i]].pos
                if d > 0.001 then boneLength = d
            )
            local b = BoneSys.createBone n.pos (n.pos + n.xAxis * boneLength) n.zAxis
            b.name = n.name
            b.width = boneSize * 0.5
            b.height = boneSize * 0.5
            b.taper = 70
            b.wirecolor = color 255 180 6
            b.setBoneEnable false 0
            b.transform = matrix3 n.xAxis n.yAxis n.zAxis n.pos
            layer.addNode b
            append created b
        )
        -- Parent after placing: linking keeps world transforms
        for i = 1 to skeleton.count where skeleton[i].parent >= 0 do
            created[i].parent = created[skeleton[i].parent + 1]
        created
    )

    -- Compares the scene nodes (current frame) with the expected Halo 5 rest pose.
    -- Returns #(reportText, mismatchedLinks) where each link is #(node, expectedParentNode).
    fn checkSceneSkeleton skeleton unitScale =
    (
        local found = for n in skeleton collect (getNodeByName n.name)
        local foundCount = 0
        for f in found where isValidNode f do foundCount += 1
        if foundCount == 0 then return #("None of the " + skeleton.count as string + " graph nodes exist in the scene.", #())

        local rootIdx = 0
        for i = 1 to skeleton.count while rootIdx == 0 do
            if isValidNode found[i] and skeleton[i].parent < 0 then rootIdx = i
        if rootIdx == 0 then
            for i = 1 to skeleton.count while rootIdx == 0 do if isValidNode found[i] then rootIdx = i

        local expRoot = skeleton[rootIdx].pos
        local sceneRoot = found[rootIdx].transform.pos

        -- Unit scale: median length ratio of root-relative offsets
        local ratios = #()
        for i = 1 to skeleton.count where i != rootIdx and isValidNode found[i] do
        (
            local e = length (skeleton[i].pos - expRoot)
            if e > 0.5 then append ratios ((length (found[i].transform.pos - sceneRoot)) / e)
        )
        sort ratios
        local scaleRatio = if ratios.count > 0 then ratios[(ratios.count + 1) / 2] else 1.0

        local maxPosErr = 0.0
        local maxAngErr = 0.0
        local worst = #()
        local links = #()
        for i = 1 to skeleton.count where isValidNode found[i] do
        (
            local n = skeleton[i]
            local tm = found[i].transform
            local posErr = length ((tm.pos - sceneRoot) - (n.pos - expRoot) * scaleRatio)
            local angErr = 0.0
            local rows = #(normalize tm.row1, normalize tm.row2, normalize tm.row3)
            local axes = #(n.xAxis, n.yAxis, n.zAxis)
            for a = 1 to 3 do angErr = amax angErr (acos (amin 1.0 (amax (-1.0) (dot rows[a] axes[a]))))
            maxPosErr = amax maxPosErr posErr
            maxAngErr = amax maxAngErr angErr
            if angErr > 5.0 or posErr > 0.5 then append worst (n.name + " (" + (formattedPrint angErr format:".1f") + " deg, " + (formattedPrint posErr format:".2f") + " units)")

            if n.parent >= 0 and isValidNode found[n.parent + 1] and found[i].parent != found[n.parent + 1] then
                append links #(found[i], found[n.parent + 1])
        )

        local text = "Nodes found: " + foundCount as string + " / " + skeleton.count as string + "\n" + \
                     "Scale ratio (scene / converted): " + (formattedPrint scaleRatio format:".4f") + "\n" + \
                     "Max position error: " + (formattedPrint maxPosErr format:".3f") + " units\n" + \
                     "Max axis error: " + (formattedPrint maxAngErr format:".2f") + " degrees"
        if abs (scaleRatio - 1.0) > 0.02 then
            text += "\n\nThe scene rig uses a different unit scale: set 'Units per WU' to " + \
                    (formattedPrint (scaleRatio * unitScale) format:".3f") + " and convert again."
        if worst.count > 0 then
        (
            text += "\n\nNodes that do not match the Halo 5 rest pose (first 12):"
            for i = 1 to (amin 12 worst.count) do text += "\n  " + worst[i]
        )
        if links.count > 0 then
        (
            text += "\n\nNodes linked to a different parent than in the graph:"
            for i = 1 to (amin 12 links.count) do text += "\n  " + links[i][1].name + " -> should be under " + links[i][2].name
        )
        #(text, links)
    )

    -------------------------------------------------------
    -- RETARGET
    -------------------------------------------------------

    fn getRetargetPresets = getFiles (corePath + "\\halo5\\presets\\*.tsv")

    -- One capture per preset, shared by every converted graph
    fn getTargetCapturePath presetPath = (getDir #temp) + "\\h5_animations\\_targets\\" + (getFilenameFile presetPath) + ".tsv"

    fn formatRow p = (p.x as string) + " " + (p.y as string) + " " + (p.z as string)

    fn formatMatrixRows tm = (formatRow tm.row1) + "\t" + (formatRow tm.row2) + "\t" + (formatRow tm.row3) + "\t" + (formatRow tm.row4)

    -- Target node names of a preset ('bone' lines, alternatives split on '|')
    fn readPresetTargetNames presetPath =
    (
        local names = #()
        for line in ((dotNetClass "System.IO.File").ReadAllLines presetPath) where matchPattern line pattern:"bone\t*" do
        (
            local f = filterString line "\t"
            if f.count >= 3 then for n in (filterString f[3] "|") where (findItem names n) == 0 do append names n
        )
        names
    )

    -- Writes the world matrices of the preset's target nodes, plus any Halo 5 named nodes in the
    -- scene (the weapon rig), at the current frame. Returns #(nodeCount, animatedCount).
    fn captureTargetRest presetPath skeleton outPath =
    (
        local candidates = readPresetTargetNames presetPath
        for n in skeleton where (findItem candidates n.name) == 0 do append candidates n.name

        local found = #()
        for n in candidates do
        (
            local sceneNode = getNodeByName n
            if isValidNode sceneNode and (findItem found sceneNode) == 0 then append found sceneNode
        )
        if found.count == 0 then return #(0, 0)

        local animatedCount = 0
        local lines = #("#name\tparent\tworld rows\tparent world rows")
        for n in found do
        (
            if n.isAnimated then animatedCount += 1
            local parentName = if isValidNode n.parent then n.parent.name else ""
            local parentTm = if isValidNode n.parent then n.parent.transform else (matrix3 1)
            append lines (n.name + "\t" + parentName + "\t" + (formatMatrixRows n.transform) + "\t" + (formatMatrixRows parentTm))
        )
        makeDir (getFilenamePath outPath) all:true
        local fs = createFile outPath
        for line in lines do format "%\n" line to:fs
        close fs
        #(found.count, animatedCount)
    )

    -------------------------------------------------------
    -- ANIMATION IMPORT
    -------------------------------------------------------

    fn importAnimationFile filePath =
    (
        local jmaData = readJmaFile filePath
        if jmaData == undefined then return false

        local missing = getMissingNodes jmaData
        with undo off
        (
            -- Replace any previous animation instead of layering keys on top of it
            for nd in jmaData.nodes do
            (
                local sceneNode = getNodeByName nd.nodeName
                if isValidNode sceneNode then deleteKeys sceneNode.controller #allKeys
            )
            buildJmaAnimation jmaData
        )
        sliderTime = 0
        if missing.count > 0 then
            logger.warn "{} graph node(s) are not in the scene and were skipped" args:#(missing.count)
        true
    )

    -------------------------------------------------------
    -- UI
    -------------------------------------------------------

    rollout H5AnimationsRollout "H5 Animation Tool" width:360
    (
        local anims = #()
        local shown = #()
        local skeleton = #()
        local skeletonPath = undefined
        local restPosePath = undefined
        local filesConjugate = undefined  -- quaternion convention of the converted files (from the manifest)
        local presets = #()

        group "Animation Graph"
        (
            edittext edtGraph "" width:300 across:2 readOnly:true
            button btnGraph "..." width:30 align:#right offset:[0,-2]
        )
        group "Rest Pose (render_model tags)"
        (
            listbox lbxModels "" height:3 width:330
            button btnAddModel "Add..." width:105 across:3
            button btnRemoveModel "Remove" width:105
            button btnAutoModels "Auto Detect" width:105
        )
        group "Conversion"
        (
            edittext edtOut "Output:" width:300 across:2
            button btnOut "..." width:30 align:#right offset:[0,-2]
            spinner spnScale "Units per WU: " range:[0.001,100000,100] type:#float fieldwidth:60 align:#right \
                tooltip:"Halo 5 world units -> 3ds Max units. 100 matches the toolkit's JMS/JMA scale."
            checkbox chkRootMotion "Bake root motion into b_pedestal" checked:true
            button btnConvert "Convert Graph" width:215 height:30 across:2 align:#left \
                tooltip:"Decodes every animation of the graph again and overwrites the output folder"
            button btnLoadFolder "Load Folder..." width:105 height:30 align:#right \
                tooltip:"Loads a folder converted before, without converting again"
            label lblStatus "" width:330 align:#left
        )
        group "Scene Skeleton"
        (
            button btnBuild "Build H5 Skeleton" width:160 across:2 \
                tooltip:"Creates bones in the exact Halo 5 rest pose (no mesh)"
            button btnCheck "Check Scene Skeleton" width:160 \
                tooltip:"Compares the scene bones (current frame) with the Halo 5 rest pose"
        )
        group "Retarget (other skeleton)"
        (
            dropdownList ddlPreset "Target:" width:330 \
                tooltip:"None applies the animation to nodes with the Halo 5 names; a preset retargets it to another skeleton"
            checkbox chkIK "Match hand positions (IK)" checked:true across:2 \
                tooltip:"Moves the target hands so their knuckles land on the Halo 5 ones, so the hands stay on the weapon"
            spinner spnShoulderReach "Shoulder reach: " range:[0,100,2] type:#float fieldwidth:40 align:#right \
                tooltip:"When a hand can't reach its goal, the shoulder slides toward it by up to this distance (0 = never)"
            checkbox chkCamera "Remove camera motion" checked:true \
                tooltip:"Takes every pose relative to b_camera_control, like a fixed first person camera"
            button btnCapture "Capture Target Rest Pose" width:215 across:2 align:#left \
                tooltip:"Stores the target skeleton as it is now. Do it on the rest pose, before importing animations."
            button btnRetargetAll "Retarget All..." width:105 align:#right \
                tooltip:"Writes every converted animation retargeted to the target skeleton into a folder"
            label lblTarget "" width:330 align:#left
        )
        group "Animations"
        (
            edittext edtFilter "Filter:" width:330
            listbox lbxAnims "" height:16 width:330
            label lblInfo "" width:330 align:#left
            button btnImport "Import Selected" width:330 height:30
        )

        fn refreshAnimList =
        (
            local filterText = toLower (trimRight (trimLeft edtFilter.text))
            shown = for a in anims where filterText == "" or (findString (toLower a.name) filterText) != undefined collect a
            lbxAnims.items = for a in shown collect a.name
            lblInfo.text = if anims.count == 0 then "" else (shown.count as string + " of " + anims.count as string + " animation(s)")
        )

        fn selectedEntry = if lbxAnims.selection > 0 and lbxAnims.selection <= shown.count then shown[lbxAnims.selection] else undefined

        -- Parses converter report / manifest lines into anims, skeleton and the rest pose entry.
        -- Returns #(missing, warnings, errorText, #(source, models, settings)).
        fn applyReportLines lines folder =
        (
            anims = #()
            skeletonPath = undefined
            restPosePath = undefined
            local missing = #()
            local warnings = #()
            local errorText = undefined
            local info = #(undefined, undefined, undefined)
            for line in lines where line.count > 0 do
            (
                local f = filterString line "\t"
                case f[1] of
                (
                    "#source": info[1] = f[2]
                    "#models": info[2] = if f.count >= 2 then filterString f[2] "|" else #()
                    "#settings": info[3] = f
                    "#skeleton": skeletonPath = resolveInFolder f[2] folder
                    "#rest": restPosePath = resolveInFolder f[2] folder
                    "#missing": append missing f[2]
                    "#warn": append warnings f[2]
                    "#error": errorText = f[2]
                    "anim": append anims (h5AnimEntry name:f[3] type:f[4] frames:(f[5] as integer) movement:(f[6] as integer) \
                                file:(resolveInFolder f[7] folder) base:(if f.count >= 8 then f[8] else ""))
                )
            )
            if restPosePath != undefined and doesFileExist restPosePath then
                insertItem (h5AnimEntry name:restPoseLabel type:"rest" frames:2 movement:0 file:restPosePath base:"") anims 1
            skeleton = readSkeletonTsv skeletonPath
            #(missing, warnings, errorText, info)
        )

        fn readManifestSource folder =
        (
            local source = undefined
            local manifestPath = pathConfig.appendPath folder manifestName
            if doesFileExist manifestPath then
                for line in ((dotNetClass "System.IO.File").ReadAllLines manifestPath) while source == undefined do
                    if matchPattern line pattern:"#source\t*" then source = substring line 9 -1
            source
        )

        -- Loads a folder written by Convert Graph (manifest), or an older conversion by scanning its files
        fn loadConversion folder showMessages:true =
        (
            local otherConvention = false
            filesConjugate = undefined
            local manifestPath = pathConfig.appendPath folder manifestName
            if doesFileExist manifestPath then
            (
                local result = applyReportLines ((dotNetClass "System.IO.File").ReadAllLines manifestPath) folder
                local info = result[4]
                if info[1] != undefined then edtGraph.text = info[1]
                if info[2] != undefined then lbxModels.items = info[2]
                local settings = info[3]
                if settings != undefined and settings.count >= 4 then
                (
                    spnScale.value = settings[2] as float
                    chkRootMotion.checked = settings[3] == "1"
                    filesConjugate = settings[4] == "1"
                    otherConvention = filesConjugate != jmaNeedsConjugate()
                )
            )
            else
            (
                anims = scanConvertedFolder folder
                local tsvFiles = getFiles (pathConfig.appendPath folder "*_skeleton.tsv")
                skeletonPath = if tsvFiles.count > 0 then tsvFiles[1] else undefined
                restPosePath = pathConfig.appendPath folder "_rest_pose.JMM"
                if doesFileExist restPosePath then
                    insertItem (h5AnimEntry name:restPoseLabel type:"rest" frames:2 movement:0 file:restPosePath base:"") anims 1
                else
                    restPosePath = undefined
                skeleton = readSkeletonTsv skeletonPath
            )

            if anims.count == 0 then
            (
                refreshAnimList()
                if showMessages then messageBox ("No converted animations found in:\n" + folder) title:toolTitle
                return false
            )

            edtOut.text = folder
            refreshAnimList()
            local animCount = (for a in anims where a.type != "rest" collect a).count
            lblStatus.text = "Loaded " + animCount as string + " converted animation(s), no conversion needed"
            logger.info "Loaded {} converted animation(s) from '{}'" args:#(animCount, folder)
            if skeleton.count == 0 then
                logger.warn "No '*_skeleton.tsv' in '{}': Build/Check Scene Skeleton are unavailable" args:#(folder)
            if otherConvention then
                messageBox ("This folder was converted with a different rotation convention than this 3ds Max applies.\n\n" + \
                            "Press Convert Graph to write the animations again.") title:toolTitle
            true
        )

        fn setGraph graphPath =
        (
            edtGraph.text = graphPath
            lbxModels.items = guessRenderModels graphPath
            edtOut.text = (getDir #temp) + "\\h5_animations\\" + (getFilenameFile graphPath)
            anims = #()
            skeleton = #()
            lblStatus.text = ""
            refreshAnimList()

            -- Reuse a previous conversion of this graph instead of decoding it again
            local source = readManifestSource edtOut.text
            local legacy = source == undefined and \
                doesFileExist (pathConfig.appendPath edtOut.text ((getFilenameFile graphPath) + "_skeleton.tsv"))
            if legacy or (source != undefined and (stricmp source graphPath) == 0) then
                loadConversion edtOut.text showMessages:false
        )

        fn convertGraph =
        (
            local problem = case of
            (
                (not doesFileExist edtGraph.text): "Pick a model_animation_graph tag first."
                (lbxModels.items.count == 0): "Add the render_model tag(s) that own the graph's nodes.\nHalo 5 graphs do not store a rest pose."
                (edtOut.text == ""): "Pick an output folder."
                default: undefined
            )
            if problem != undefined then
            (
                messageBox problem title:toolTitle
                return false
            )

            local converter = try (loadPythonModule "halo5.convert") catch
            (
                logger.error "Could not load the Python converter: {}" args:#(getCurrentException())
                messageBox ("Could not load the Python converter from:\n" + corePath + "\n\nSee the MAXScript Listener for details.") title:toolTitle
                return false
            )

            local conjugate = jmaNeedsConjugate()
            logger.info "JMA rotation convention: {}" args:#(if conjugate then "conjugated" else "standard")

            local startTime = timestamp()
            local modelText = ""
            for m in lbxModels.items do modelText += m + "|"
            local report = ""
            with redraw off
            (
                report = converter.convert_graph edtGraph.text modelText edtOut.text spnScale.value chkRootMotion.checked conjugate
            )
            local elapsedTime = (timestamp() - startTime) / 1000.0

            local result = applyReportLines (filterString report "\n") edtOut.text
            local missing = result[1]
            local warnings = result[2]
            local errorText = result[3]
            for w in warnings do logger.warn "{}" args:#(w)

            if errorText != undefined then
            (
                logger.error "{}" args:#(errorText)
                messageBox ("Conversion failed:\n\n" + (substituteString errorText " | " "\n")) title:toolTitle
                return false
            )

            filesConjugate = conjugate
            refreshAnimList()
            lblStatus.text = "Converted " + (anims.count - 1) as string + " animation(s)"
            logger.info "Converted {} animation(s) in {} seconds to '{}'" args:#(anims.count - 1, elapsedTime, edtOut.text)

            local summary = "Converted " + (anims.count - 1) as string + " animation(s) in " + (formattedPrint elapsedTime format:".1f") + " seconds."
            if missing.count > 0 then
            (
                summary += "\n\n" + missing.count as string + " graph node(s) are not in the render models (they will use an identity rest pose):"
                for i = 1 to (amin 10 missing.count) do summary += "\n  " + missing[i]
            )
            if warnings.count > 0 then
                summary += "\n\n" + warnings.count as string + " warning(s), see the MAXScript Listener."
            local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true
            if showDialogs or missing.count > 0 then
                messageBox summary title:toolTitle beep:false
            true
        )

        fn selectedPreset = if ddlPreset.selection > 1 then presets[ddlPreset.selection - 1] else undefined

        fn refreshTargetStatus =
        (
            local presetPath = selectedPreset()
            local enabled = presetPath != undefined
            chkIK.enabled = enabled
            spnShoulderReach.enabled = enabled
            chkCamera.enabled = enabled
            btnCapture.enabled = enabled
            btnRetargetAll.enabled = enabled
            lblTarget.text = case of
            (
                (not enabled): "Animations are applied to the nodes with the Halo 5 names."
                (doesFileExist (getTargetCapturePath presetPath)): "Target captured: " + (getFileModDate (getTargetCapturePath presetPath))
                default: "Capture the target skeleton (rest pose) before importing."
            )
        )

        -- Retargets JMA files ('|' separated, or a folder) with the selected preset.
        -- Returns the output file of each source, or undefined on failure.
        fn retargetFiles sourceFiles outDir =
        (
            local presetPath = selectedPreset()
            local capturePath = getTargetCapturePath presetPath
            local problem = case of
            (
                (not doesFileExist capturePath): "Capture the target skeleton first:\nput it in its rest pose and press 'Capture Target Rest Pose'."
                (skeletonPath == undefined or not doesFileExist skeletonPath): "The converted folder has no '*_skeleton.tsv'. Convert the graph again."
                default: undefined
            )
            if problem != undefined then
            (
                messageBox problem title:toolTitle
                return undefined
            )

            local retargeter = try (loadPythonModule "halo5.retarget") catch
            (
                logger.error "Could not load the Python retargeter: {}" args:#(getCurrentException())
                messageBox "Could not load the Python retargeter. See the MAXScript Listener for details." title:toolTitle
                return undefined
            )

            local outConjugate = jmaNeedsConjugate()
            local srcConjugate = if filesConjugate != undefined then filesConjugate else outConjugate
            local report = ""
            with redraw off
            (
                report = retargeter.retarget_folder sourceFiles skeletonPath capturePath presetPath outDir \
                    srcConjugate outConjugate chkIK.checked chkCamera.checked spnShoulderReach.value
            )

            local outFiles = #()
            local errorText = undefined
            for line in (filterString report "\n") do
            (
                local f = filterString line "\t"
                case f[1] of
                (
                    "#info": logger.info "Retarget: {}" args:#(f[2])
                    "#warn": logger.warn "Retarget: {}" args:#(f[2])
                    "#error": errorText = f[2]
                    "out": append outFiles f[3]
                )
            )
            if errorText != undefined then
            (
                logger.error "{}" args:#(errorText)
                messageBox ("Retarget failed:\n\n" + (substituteString errorText " | " "\n")) title:toolTitle
                return undefined
            )
            outFiles
        )

        fn importSelected =
        (
            local a = selectedEntry()
            if a == undefined then return messageBox "Select an animation first." title:toolTitle
            if not doesFileExist a.file then return messageBox ("File not found:\n" + a.file) title:toolTitle
            local startTime = timestamp()
            local fileToImport = a.file
            local presetPath = selectedPreset()
            if presetPath != undefined then
            (
                local outDir = pathConfig.appendPath edtOut.text ("_retarget_" + (getFilenameFile presetPath))
                local outFiles = retargetFiles a.file outDir
                if outFiles == undefined then return false
                if outFiles.count == 0 then
                    return messageBox ("Could not retarget '" + a.name + "'. See the MAXScript Listener for details.") title:toolTitle
                fileToImport = outFiles[1]
            )
            if importAnimationFile fileToImport then
                logger.info "Imported '{}' ({} frames) in {} seconds" args:#(a.name, a.frames, (timestamp() - startTime) / 1000.0)
            completeRedraw()
        )

        on H5AnimationsRollout open do
        (
            presets = getRetargetPresets()
            local items = #("None (Halo 5 node names)")
            join items (for p in presets collect getFilenameFile p)
            ddlPreset.items = items
            refreshTargetStatus()
            refreshAnimList()
        )

        on ddlPreset selected idx do refreshTargetStatus()

        on btnCapture pressed do
        (
            if skeleton.count == 0 then
                return messageBox "Convert or load a graph first: the capture also records the Halo 5 weapon nodes in the scene." title:toolTitle
            local presetPath = selectedPreset()
            local capturePath = getTargetCapturePath presetPath
            local result = captureTargetRest presetPath skeleton capturePath
            if result[1] == 0 then
            (
                deleteFile capturePath
                messageBox ("None of the '" + (getFilenameFile presetPath) + "' target nodes are in the scene.") title:toolTitle
            )
            else
            (
                logger.info "Captured {} target node(s) to '{}'" args:#(result[1], capturePath)
                local text = "Captured " + result[1] as string + " node(s) at frame " + (sliderTime.frame as integer) as string + "."
                if result[2] > 0 then
                    text += "\n\nWarning: " + result[2] as string + " of them have animation keys. The capture must be the rest pose:\n" + \
                            "if they are not in it now, delete their keys (or reimport the skeleton) and capture again."
                messageBox text title:toolTitle beep:false
            )
            refreshTargetStatus()
        )

        on btnRetargetAll pressed do
        (
            local converted = for a in anims where a.type != "rest" collect a
            if converted.count == 0 then return messageBox "Convert or load a graph first." title:toolTitle
            local presetPath = selectedPreset()
            local outDir = getSavePath caption:"Select the folder for the retargeted animations" \
                initialDir:(pathConfig.appendPath edtOut.text ("_retarget_" + (getFilenameFile presetPath)))
            if outDir == undefined then return false
            local sourceFiles = ""
            for a in anims do sourceFiles += a.file + "|"
            local startTime = timestamp()
            local outFiles = retargetFiles sourceFiles outDir
            if outFiles == undefined then return false
            local elapsedTime = (timestamp() - startTime) / 1000.0
            logger.info "Retargeted {} animation(s) in {} seconds to '{}'" args:#(outFiles.count, elapsedTime, outDir)
            messageBox ("Retargeted " + outFiles.count as string + " of " + anims.count as string + " animation(s) in " + \
                        (formattedPrint elapsedTime format:".1f") + " seconds:\n" + outDir) title:toolTitle beep:false
        )

        on btnGraph pressed do
        (
            local graphPath = getOpenFileName caption:"Select Halo 5 model_animation_graph" \
                types:"Animation Graph (*.model_animation_graph)|*.model_animation_graph|All Files (*.*)|*.*" \
                historyCategory:"Halo5AnimationGraph"
            if graphPath != undefined then setGraph graphPath
        )
        on btnAddModel pressed do
        (
            local modelPath = getOpenFileName caption:"Select Halo 5 render_model" \
                types:"Render Model (*.render_model)|*.render_model|All Files (*.*)|*.*" \
                historyCategory:"Halo5RenderModel"
            if modelPath != undefined and (findItem lbxModels.items modelPath) == 0 then
                lbxModels.items = append lbxModels.items modelPath
        )
        on btnRemoveModel pressed do
            if lbxModels.selection > 0 then lbxModels.items = deleteItem lbxModels.items lbxModels.selection
        on btnAutoModels pressed do
            if doesFileExist edtGraph.text then lbxModels.items = guessRenderModels edtGraph.text
        on btnOut pressed do
        (
            local outPath = getSavePath caption:"Select output folder for the converted animations" initialDir:edtOut.text
            if outPath != undefined then edtOut.text = outPath
        )
        on btnConvert pressed do convertGraph()
        on btnLoadFolder pressed do
        (
            local folder = getSavePath caption:"Select a folder converted with Convert Graph" initialDir:edtOut.text
            if folder != undefined then loadConversion folder
        )

        on btnBuild pressed do
        (
            if skeleton.count == 0 then
                return messageBox "Convert a graph first." title:toolTitle
            local existing = for n in skeleton where (getNodeByName n.name) != undefined collect n.name
            if existing.count > 0 and not (queryBox (existing.count as string + " node(s) with these names already exist (e.g. '" + existing[1] + "').\nAnimations are applied by name, so duplicates will be ambiguous.\n\nBuild anyway?") title:toolTitle) then
                return false
            local created = undefined
            undo "Build H5 Skeleton" on created = buildH5Skeleton skeleton spnScale.value
            select created
            completeRedraw()
            logger.info "Built {} bone(s)" args:#(created.count)
        )

        on btnCheck pressed do
        (
            if skeleton.count == 0 then
                return messageBox "Convert a graph first." title:toolTitle
            local result = checkSceneSkeleton skeleton spnScale.value
            logger.info "{}" args:#(result[1])
            if result[2].count > 0 then
            (
                if queryBox (result[1] + "\n\nLink these nodes to their graph parents now?") title:toolTitle then
                    undo "Link H5 Nodes" on (for link in result[2] do link[1].parent = link[2])
            )
            else
                messageBox result[1] title:toolTitle beep:false
        )

        on edtFilter changed txt do refreshAnimList()

        on lbxAnims selected idx do
        (
            local a = selectedEntry()
            if a != undefined then
                lblInfo.text = a.type + ", " + a.frames as string + " frames" + \
                    (if a.movement > 0 then ", movement " + a.movement as string else "") + \
                    (if a.base != "" then ", base: " + a.base else "")
        )

        on btnImport pressed do importSelected()
        on lbxAnims doubleClicked idx do importSelected()
    )

    createDialog H5AnimationsRollout style:#(#style_titlebar, #style_sysmenu, #style_minimizebox)
)
