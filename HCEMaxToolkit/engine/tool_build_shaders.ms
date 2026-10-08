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

-- Build Shaders
-- Turns the GlyphFX DirectX materials of a Multi/Sub-Object material whose name
-- contains "gfx" into shader tags, using invader-edit (path set in Settings).
-- Shader type: a "#fourcc" tag in the material name ("armor #soso") wins, otherwise
-- the material's .fx file name decides. chicago_extended shares the chicago effect,
-- so it needs "#scex".

-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Log file setup
scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

include "shared\\utils\\invader_utils.ms"
-- getTagsRootFromTagPath, shaderTagClassStrToString
include "builders\\tag\\shared\\shader_resolver.ms"
include "pipeline\\create_tag\\create_shader.ms"

-- One sub-material of the multimaterial and what will be built from it
struct ShaderBuildEntry (mat, slotId, shaderType, tagName, problem)

(
    global BuildShadersRollout
    try (destroyDialog BuildShadersRollout) catch()

    local toolTitle = "Build Shaders"
    local maxListedIssues = 20

    -------------------------------------------------------
    -- SCENE SCAN
    -------------------------------------------------------

    fn isGfxMultiMaterial mat = classOf mat == Multimaterial and matchPattern mat.name pattern:"*gfx*"

    fn findGfxMultiMaterials =
    (
        local found = #()
        for mat in sceneMaterials where isGfxMultiMaterial mat do appendIfUnique found mat
        for mat in meditMaterials where isGfxMultiMaterial mat do appendIfUnique found mat
        found
    )

    fn analyzeSubMaterial mat slotId =
    (
        local entry = ShaderBuildEntry mat:mat slotId:slotId
        if mat == undefined then
        (
            entry.problem = "empty slot"
            return entry
        )
        if classOf mat != DirectX_9_Shader then
        (
            entry.problem = "not a DirectX material"
            return entry
        )

        local fxType = shaderTypeFromFxFile mat.effectfile
        local fcc = findShaderFourCCInName mat.name
        entry.shaderType = if fcc != undefined then shaderTagClassStrToString fcc else fxType
        entry.tagName = shaderTagNameFromMaterialName mat.name

        entry.problem = case of
        (
            (fxType == undefined): "effect is not a GlyphFX shader"
            ((shaderTypeToFxName entry.shaderType) != fxType): ("#" + fcc + " does not match the effect " + fxType + ".fx")
            (entry.tagName == ""): "empty material name"
            default: undefined
        )
        entry
    )

    fn analyzeMultiMaterial multiMat =
    (
        for i = 1 to multiMat.materialList.count collect
            analyzeSubMaterial multiMat.materialList[i] multiMat.materialIDList[i]
    )

    fn entryLabel entry =
    (
        local matName = if entry.mat != undefined then entry.mat.name else "(none)"
        local label = "[" + entry.slotId as string + "] " + matName
        if entry.problem != undefined then
            label + "   [skip: " + entry.problem + "]"
        else
            label + "   ->   " + entry.tagName + "." + entry.shaderType
    )

    -------------------------------------------------------
    -- OUTPUT FOLDER
    -------------------------------------------------------

    -- Splits a folder inside a tags directory into #(tagsDir, relativeFolder), or undefined
    fn splitTagsFolder folder =
    (
        if folder == undefined or folder == "" then return undefined
        local folderSlash = (trimRight folder "\\") + "\\"
        local tagsRoot = getTagsRootFromTagPath folderSlash
        if tagsRoot == undefined then return undefined
        local relFolder = trimRight (substring folderSlash (tagsRoot.count + 1) -1) "\\"
        #(trimRight tagsRoot "\\", relFolder)
    )

    -------------------------------------------------------
    -- TAG BUILD
    -------------------------------------------------------

    -- Builds one shader tag. Returns #(ok, message, warnings)
    fn buildShaderTag exePath tagsDir relTagPath entry enumCache =
    (
        local reader = readDxMaterialShaderOps entry.mat entry.shaderType
        if reader == undefined then return #(false, "unsupported shader type " + entry.shaderType, #())
        local warnings = reader.warnings

        -- 1. New tag with its blocks (-N overwrites an existing tag)
        local createArgs = #("-N")
        for ins in reader.inserts do join createArgs #("-I", ins[1], ins[2] as string, "end")
        local res = runInvaderEdit exePath tagsDir relTagPath createArgs
        if res[1] != 0 then return #(false, res[3] + res[2], warnings)

        -- 2. Enum option names (invader-edit only takes names), listed once per shader type
        local enums = enumCache[entry.shaderType]
        if enums == undefined then
        (
            res = runInvaderEdit exePath tagsDir relTagPath #("-l")
            if res[1] != 0 then return #(false, res[3] + res[2], warnings)
            enums = parseInvaderEnums res[2]
            enumCache[entry.shaderType] = enums
        )

        -- 3. Field values
        local setArgs = #()
        for op in reader.sets do
        (
            local key = op[1]
            local fieldValue = op[2]
            if op[3] then
            (
                local keyParts = filterString key "."
                local options = enums[keyParts[keyParts.count]]
                if options == undefined or fieldValue < 0 or fieldValue >= options.count then
                (
                    append warnings ("'" + key + "': invalid enum value " + fieldValue as string + ", left at default")
                    continue
                )
                fieldValue = options[fieldValue + 1]
            )
            join setArgs #("-S", key, fieldValue)
        )
        if setArgs.count > 0 then
        (
            res = runInvaderEditChunked exePath tagsDir relTagPath setArgs
            if res[1] != 0 then return #(false, res[3] + res[2], warnings)
        )
        #(true, (reader.sets.count as string) + " field(s)", warnings)
    )

    -- First meaningful line of invader-edit's error output
    fn firstErrorLine text =
    (
        local lines = filterString text "\r\n"
        if lines.count == 0 then "unknown error" else lines[1]
    )

    -------------------------------------------------------
    -- DIALOG
    -------------------------------------------------------

    rollout BuildShadersRollout "Build Shaders" width:440
    (
        local multiMats = #()
        local entries = #()

        group "Source"
        (
            dropdownList ddlMulti "Multi/Sub-Object material (name contains 'gfx'):" width:345 across:2
            button btnRefresh "Refresh" width:60 offset:[42,18]
            multiListBox lbxShaders "Shaders to build:" height:14 width:410
            button btnSelectAll "Select All" width:100 across:2 align:#left
            button btnSelectNone "Select None" width:100 align:#right
        )
        group "Output"
        (
            edittext edtFolder "Tags folder:" width:370 readOnly:true across:2
            button btnBrowse "..." width:28 offset:[78,0] tooltip:"Folder inside a tags directory where the shader tags are saved"
        )
        button btnBuild "Build Shader Tags" width:410 height:36

        fn refreshShaderList =
        (
            entries = if ddlMulti.selection > 0 and ddlMulti.selection <= multiMats.count then
                analyzeMultiMaterial multiMats[ddlMulti.selection]
            else #()
            lbxShaders.items = for e in entries collect entryLabel e
            lbxShaders.selection = (for i = 1 to entries.count where entries[i].problem == undefined collect i) as bitArray
        )

        fn refreshMultiMaterials =
        (
            multiMats = findGfxMultiMaterials()
            ddlMulti.items = for m in multiMats collect m.name
            if multiMats.count > 0 then ddlMulti.selection = 1
            refreshShaderList()
        )

        fn pickFolder =
        (
            local caption = "Select the folder to save the shader tags (inside a 'tags' directory)"
            local folder = if edtFolder.text != "" then getSavePath caption:caption initialDir:edtFolder.text else getSavePath caption:caption
            if folder == undefined then return false
            if (splitTagsFolder folder) == undefined then
            (
                messageBox ("The folder must be inside a 'tags' directory:\n" + folder) title:toolTitle
                return false
            )
            edtFolder.text = folder
            if configManager.iniPath != undefined then
                setINISetting configManager.iniPath "build_shaders" "last_output_folder" folder
            true
        )

        fn build =
        (
            local exePath = getInvaderEditPath()
            if exePath == undefined then
            (
                messageBox "invader-edit.exe was not found.\n\nSet its path in Halo CE Toolkit > Settings > External Tools." title:toolTitle
                return false
            )

            local selected = for i in lbxShaders.selection where entries[i].problem == undefined collect entries[i]
            if selected.count == 0 then
            (
                messageBox "No valid shaders selected." title:toolTitle
                return false
            )

            if edtFolder.text == "" and not (pickFolder()) then return false
            local folderParts = splitTagsFolder edtFolder.text
            if folderParts == undefined then
            (
                messageBox ("The folder must be inside a 'tags' directory:\n" + edtFolder.text) title:toolTitle
                return false
            )
            local tagsDir = folderParts[1]
            local relFolder = folderParts[2]
            -- invader-edit -N does not create missing folders
            pathUtils.createDirectoryRecursive edtFolder.text

            local startTime = timestamp()
            local enumCache = dictionary #string
            local builtPaths = #()
            local created = 0
            local failures = #()
            local issues = #()
            local skipped = 0

            for entry in selected do
            (
                local tagLabel = entry.tagName + "." + entry.shaderType
                local relTagPath = if relFolder == "" then tagLabel else relFolder + "\\" + tagLabel

                -- Two materials resolving to the same tag would overwrite each other
                if (findItem builtPaths (toLower relTagPath)) > 0 then
                (
                    logger.warn "Skipping '{}': '{}' was already built from another material" args:#(entry.mat.name, tagLabel)
                    append issues (tagLabel + ": duplicate name, skipped '" + entry.mat.name + "'")
                    skipped += 1
                    continue
                )
                append builtPaths (toLower relTagPath)

                local existed = doesFileExist (tagsDir + "\\" + relTagPath)
                local result = buildShaderTag exePath tagsDir relTagPath entry enumCache

                for warning in result[3] do
                (
                    logger.warn "{}: {}" args:#(tagLabel, warning)
                    append issues (tagLabel + ": " + warning)
                )

                if result[1] then
                (
                    created += 1
                    logger.info "{} tags\\{} ({})" args:#((if existed then "Overwritten" else "Created"), relTagPath, result[2])
                )
                else
                (
                    logger.error "Failed to build tags\\{}: {}" args:#(relTagPath, result[2])
                    append failures (tagLabel + ": " + firstErrorLine result[2])
                )
            )

            local elapsedTime = (timestamp() - startTime) / 1000.0
            local summary = "Shader tags built: " + created as string + " / " + selected.count as string + "\n" + \
                            "Folder: tags\\" + relFolder + "\n" + \
                            "Time: " + (formattedPrint elapsedTime format:".3f") + " seconds"
            if skipped > 0 then
                summary += "\nSkipped: " + skipped as string

            if failures.count > 0 then
            (
                summary += "\n\nFailed:"
                for i = 1 to (amin failures.count maxListedIssues) do summary += "\n  " + failures[i]
            )
            if issues.count > 0 then
            (
                summary += "\n\nWarnings:"
                for i = 1 to (amin issues.count maxListedIssues) do summary += "\n  " + issues[i]
                if issues.count > maxListedIssues then
                    summary += "\n  ... " + (issues.count - maxListedIssues) as string + " more (see the Max Listener)"
            )

            -- Errors and warnings are shown even when completion dialogs are disabled
            local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true
            if showDialogs or failures.count > 0 or issues.count > 0 then
                messageBox summary title:toolTitle beep:false

            failures.count == 0
        )

        on BuildShadersRollout open do
        (
            local lastFolder = configManager.getString "build_shaders" "last_output_folder" ""
            if lastFolder != "" and doesDirectoryExist lastFolder then edtFolder.text = lastFolder
            refreshMultiMaterials()
        )
        
        on btnRefresh pressed do refreshMultiMaterials()
        on ddlMulti selected i do refreshShaderList()
        on btnSelectAll pressed do
            lbxShaders.selection = (for i = 1 to entries.count where entries[i].problem == undefined collect i) as bitArray
        on btnSelectNone pressed do lbxShaders.selection = #{}
        on btnBrowse pressed do pickFolder()
        on btnBuild pressed do build()
    )

    createDialog BuildShadersRollout style:#(#style_titlebar, #style_sysmenu, #style_minimizebox)
    
    if BuildShadersRollout.multiMats.count == 0 then
        messageBox "No Multi/Sub-Object material with 'gfx' in its name was found in the scene." title:toolTitle
)