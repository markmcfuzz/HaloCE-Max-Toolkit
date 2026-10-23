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
--	NODE RENAMER
--
--	Renames the nodes of JMA-family (JMA, JMM, JMO, JMR, JMT, JMW, JMZ) and JMS source
--	files: add a prefix, replace a prefix, or find/replace text ("pelvis" -> "bip01 pelvis").
--
--	Only the node block of the header is rewritten. Markers, vertices and keyframes reference
--	nodes by index, so the rest of the file is copied byte for byte with Stream.CopyTo, no
--	matter how big it is. The node list checksum is left untouched.
--
------------------------------------------------------------------------------

-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Log file setup
scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

(
    global NodeRenamerRollout
    try (destroyDialog NodeRenamerRollout) catch()

    local toolTitle = "Node Renamer"
    local animationTypes = #(".jma", ".jmm", ".jmo", ".jmr", ".jmt", ".jmw", ".jmz")
    local modelTypes = #(".jms")
    local jmaVersion = 16392
    local jmsVersion = 8200
    local maxNodeCount = 1024
    local maxNameLength = 31  -- Halo CE string fields are 32 bytes, null terminated

    local fileClass = dotNetClass "System.IO.File"
    local seekOrigin = dotNetClass "System.IO.SeekOrigin"
    local latin1 = (dotNetClass "System.Text.Encoding").GetEncoding 28591  -- 1 byte = 1 char, so the bytes round trip
    local regexClass = dotNetClass "System.Text.RegularExpressions.Regex"
    local regexOptions = dotNetClass "System.Text.RegularExpressions.RegexOptions"

    -- mode: 1 add prefix, 2 replace prefix, 3 find / replace
    struct nodeRenamerOptions (mode = 1, a = "", b = "", ignoreCase = true, skipPrefixed = true)

    -- lines: #(text, terminator) of every line read, blank ones included, so they are written back as they were
    -- nameLines: index in lines of each node name; headerEnd: byte offset where the node block ends
    struct nodeRenamerHeader (path, kind, nodeCount = 0, lines = #(), nameLines = #(), names = #(), headerEnd = 0, problem)

    -------------------------------------------------------
    -- HEADER PARSING
    -------------------------------------------------------

    fn normDir dir =
    (
        dir = trimRight (trimLeft dir)
        if dir != "" and dir[dir.count] != "\\" do dir += "\\"
        dir
    )

    -- Reads one line byte by byte, keeping its terminator ("\r\n", "\n", or "" at the end of the file)
    fn readRawLine fs =
    (
        local b = fs.ReadByte()
        if b == -1 then undefined
        else
        (
            local text = ""
            local term = ""
            while b != -1 and term == "" do
            (
                case b of
                (
                    10: term = "\n"
                    13:
                    (
                        local nb = fs.ReadByte()
                        if nb == 10 then term = "\r\n"
                        else
                        (
                            term = "\r"
                            if nb != -1 do fs.Seek (-1) seekOrigin.Current
                        )
                    )
                    default: text += bit.intAsChar b
                )
                if term == "" do b = fs.ReadByte()
            )
            #(text, term)
        )
    )

    -- Reads up to the next non-blank line and returns its index in h.lines (0 at the end of the file)
    fn nextContentLine fs h =
    (
        local index = 0
        local raw = readRawLine fs
        while raw != undefined and index == 0 do
        (
            append h.lines raw
            if (trimRight (trimLeft raw[1])) != "" then index = h.lines.count
            else raw = readRawLine fs
        )
        index
    )

    fn lineValue h index = trimRight (trimLeft h.lines[index][1])

    -- Reads only the header up to the end of the node block:
    --   JMA 16392:  version, frames, frame rate, actor count, actor name, node count, checksum, then name/child/sibling per node
    --   JMS 8200:   version, checksum, node count, then name/child/sibling/rotation/translation per node
    --   JMS inline: "version checksum count", then one tab-separated line per node (name first)
    fn parseHeader path =
    (
        local h = nodeRenamerHeader path:path
        local isModel = (findItem modelTypes (toLower (getFilenameType path))) > 0
        local fs = undefined
        try
        (
            fs = fileClass.OpenRead path
            local first = nextContentLine fs h
            if first == 0 then h.problem = "empty file"
            else
            (
                local parts = filterString (lineValue h first) " \t"
                local version = parts[1] as integer
                if isModel then
                (
                    if version != jmsVersion then
                        h.problem = "unsupported JMS version " + parts[1] + " (expected " + (jmsVersion as string) + ")"
                    else if parts.count >= 3 then
                    (
                        h.kind = #jmsInline
                        h.nodeCount = parts[3] as integer
                    )
                    else
                    (
                        h.kind = #jms
                        nextContentLine fs h  -- checksum
                        local countLine = nextContentLine fs h
                        if countLine > 0 do h.nodeCount = (lineValue h countLine) as integer
                    )
                )
                else
                (
                    if version != jmaVersion then
                        h.problem = "unsupported JMA version " + parts[1] + " (expected " + (jmaVersion as string) + ")"
                    else
                    (
                        h.kind = #jma
                        for i = 1 to 4 do nextContentLine fs h  -- frame count, frame rate, actor count, actor name
                        local countLine = nextContentLine fs h
                        if countLine > 0 do h.nodeCount = (lineValue h countLine) as integer
                        nextContentLine fs h  -- node list checksum
                    )
                )

                if h.problem == undefined and (h.nodeCount == undefined or h.nodeCount <= 0 or h.nodeCount > maxNodeCount) do
                    h.problem = "invalid node count"

                if h.problem == undefined do
                (
                    -- Lines after each name: child + sibling (JMA), child + sibling + rotation + translation (JMS)
                    local extraLines = case h.kind of (#jma: 2; #jms: 4; default: 0)
                    for n = 1 to h.nodeCount while h.problem == undefined do
                    (
                        local nameLine = nextContentLine fs h
                        if nameLine == 0 then h.problem = "the file ends inside the node list"
                        else
                        (
                            append h.nameLines nameLine
                            local text = h.lines[nameLine][1]
                            if h.kind == #jmsInline do
                            (
                                local tab = findString text "\t"
                                if tab != undefined do text = substring text 1 (tab - 1)
                            )
                            append h.names (trimRight (trimLeft text))
                            for e = 1 to extraLines do nextContentLine fs h
                        )
                    )
                    h.headerEnd = fs.Position
                )
            )
        )
        catch
        (
            h.problem = getCurrentException()
        )
        if fs != undefined do fs.Close()
        h
    )

    -------------------------------------------------------
    -- RENAME
    -------------------------------------------------------

    fn startsWithText name prefix ignoreCase =
    (
        if prefix == "" or name.count < prefix.count then false
        else
        (
            local head = substring name 1 prefix.count
            if ignoreCase then (stricmp head prefix) == 0 else head == prefix
        )
    )

    fn applyRename name opts =
    (
        if opts.a == "" then name
        else case opts.mode of
        (
            1: (if opts.skipPrefixed and (startsWithText name opts.a opts.ignoreCase) then name else opts.a + name)
            2: (if (startsWithText name opts.a opts.ignoreCase) then opts.b + (substring name (opts.a.count + 1) -1) else name)
            3:
            (
                local options = if opts.ignoreCase then regexOptions.IgnoreCase else regexOptions.None
                -- "$" in the replacement would be read as a group reference
                regexClass.Replace name (regexClass.Escape opts.a) (substituteString opts.b "$" "$$") options
            )
            default: name
        )
    )

    -- Problems that would make Tool reject the file: empty, too long or duplicated names
    fn validateNames newNames =
    (
        local problems = #()
        local seen = #()
        for i = 1 to newNames.count do
        (
            local name = newNames[i]
            if name == "" then append problems ("node " + (i as string) + " gets an empty name")
            else
            (
                if name.count > maxNameLength do
                    append problems ("'" + name + "' is longer than " + (maxNameLength as string) + " characters")
                if (findString name "\t") != undefined do
                    append problems ("'" + name + "' contains a tab")
                local wide = false
                for c = 1 to name.count while not wide do wide = (bit.charAsInt name[c]) > 255
                if wide do append problems ("'" + name + "' has characters that can't be written to the file")
                local lower = toLower name
                if (findItem seen lower) > 0 then append problems ("duplicate node name '" + name + "'")
                else append seen lower
            )
        )
        problems
    )

    -- Order and case independent, to compare the node lists of two files
    fn nodeListKey names =
    (
        local key = ""
        for n in sort (for x in names collect toLower x) do key += n + "|"
        key
    )

    fn countChanged h newNames =
    (
        local changed = 0
        for i = 1 to newNames.count where newNames[i] != h.names[i] do changed += 1
        changed
    )

    -- Writes the header with the new names, then copies the rest of the source file as is
    fn writeRenamedFile h newNames outPath =
    (
        local nameOfLine = #()
        for n = 1 to h.nameLines.count do nameOfLine[h.nameLines[n]] = n

        local ss = stringStream ""
        for i = 1 to h.lines.count do
        (
            local text = h.lines[i][1]
            local n = nameOfLine[i]
            if n != undefined and newNames[n] != h.names[n] do
            (
                local tab = if h.kind == #jmsInline then findString text "\t" else undefined
                text = if tab == undefined then newNames[n] else newNames[n] + (substring text tab -1)
            )
            format "%%" text h.lines[i][2] to:ss
        )
        local bytes = latin1.GetBytes (ss as string) asDotNetObject:true

        local inFs = undefined
        local outFs = undefined
        local ok = false
        try
        (
            inFs = fileClass.OpenRead h.path
            inFs.Seek h.headerEnd seekOrigin.Begin
            outFs = fileClass.Create outPath
            outFs.Write bytes 0 bytes.Length
            inFs.CopyTo outFs
            ok = true
        )
        catch
        (
            logger.error "Could not write '{}': {}" args:#(outPath, getCurrentException())
        )
        if outFs != undefined do outFs.Close()
        if inFs != undefined do inFs.Close()
        ok
    )

    -- Source files in rootDir (and its subfolders), skipping the output folder
    fn collectFiles rootDir recursive types excludeDir =
    (
        local found = #()
        local pending = #(rootDir)
        while pending.count > 0 do
        (
            local dir = pending[pending.count]
            deleteItem pending pending.count
            for f in getFiles (dir + "*") where (findItem types (toLower (getFilenameType f))) > 0 do append found f
            if recursive do
                for d in getDirectories (dir + "*") where (toLower d) != (toLower excludeDir) do append pending d
        )
        sort found
    )

    -------------------------------------------------------
    -- UI
    -------------------------------------------------------

    rollout NodeRenamerRollout "Node Renamer" width:360
    (
        local files = #()
        local currentHeader = undefined

        group "Input Folder"
        (
            edittext edtInput "" width:300 across:2 readOnly:true
            button btnInput "..." width:30 align:#right offset:[0,-2]
            checkbox chkSubfolders "Include subfolders"
            checkbox chkAnimations "Animations (JMA, JMM, JMO, JMR, JMT, JMW, JMZ)" checked:true
            checkbox chkModels "Models (JMS)" checked:true
            label lblFound "" align:#left width:330
        )
        group "Rename"
        (
            radiobuttons rdoMode labels:#("Add prefix", "Replace prefix", "Find / Replace") columns:3 align:#left
            label lblA "Prefix:" width:75 align:#left across:2
            edittext edtA "" width:250 align:#right offset:[0,-2]
            label lblB "" width:75 align:#left across:2
            edittext edtB "" width:250 align:#right offset:[0,-2] enabled:false
            checkbox chkIgnoreCase "Ignore case" checked:true across:2
            checkbox chkSkipPrefixed "Skip names that have it" checked:true \
                tooltip:"Names that already start with the prefix are left as they are"
        )
        group "Preview"
        (
            dropdownList ddlFile "" width:330
            listbox lbxPreview "" height:12 width:330
            label lblPreview "" align:#left width:330
        )
        group "Output Folder"
        (
            edittext edtOutput "" width:300 across:2
            button btnOutput "..." width:30 align:#right offset:[0,-2]
        )
        button btnRename "Rename Files" width:330 height:30
        progressBar pbProgress width:330 height:10
        label lblStatus "" align:#left width:330

        fn getOptions =
        (
            nodeRenamerOptions mode:rdoMode.state a:edtA.text b:edtB.text \
                ignoreCase:chkIgnoreCase.checked skipPrefixed:chkSkipPrefixed.checked
        )

        -- Names are quoted so a trailing space in the prefix is visible
        fn refreshPreview =
        (
            local items = #()
            local info = ""
            if currentHeader != undefined do
            (
                if currentHeader.problem != undefined then info = "Skipped: " + currentHeader.problem
                else
                (
                    local opts = getOptions()
                    local newNames = for n in currentHeader.names collect applyRename n opts
                    for i = 1 to newNames.count do
                    (
                        local oldName = currentHeader.names[i]
                        append items (if newNames[i] != oldName then "'" + oldName + "'  ->  '" + newNames[i] + "'" else "'" + oldName + "'")
                    )
                    local problems = validateNames newNames
                    for p in problems do append items ("!! " + p)
                    info = (newNames.count as string) + " nodes, " + ((countChanged currentHeader newNames) as string) + " changed"
                    if problems.count > 0 do info += " - " + (problems.count as string) + " problem(s), the file will be skipped"
                )
            )
            lbxPreview.items = items
            lblPreview.text = info
        )

        fn loadPreviewFile =
        (
            currentHeader = if ddlFile.selection > 0 then parseHeader files[ddlFile.selection] else undefined
            refreshPreview()
        )

        fn refreshFiles =
        (
            local inDir = normDir edtInput.text
            files = #()
            if inDir != "" and doesDirectoryExist inDir do
            (
                local types = #()
                if chkAnimations.checked do join types animationTypes
                if chkModels.checked do join types modelTypes
                if types.count > 0 do files = collectFiles inDir chkSubfolders.checked types (normDir edtOutput.text)
            )
            lblFound.text = if inDir == "" then "" else (files.count as string) + " file(s) found"
            ddlFile.items = for f in files collect substring f (inDir.count + 1) -1
            ddlFile.selection = if files.count > 0 then 1 else 0
            loadPreviewFile()
        )

        fn updateModeUI =
        (
            case rdoMode.state of
            (
                1: (lblA.text = "Prefix:"; lblB.text = "")
                2: (lblA.text = "Old prefix:"; lblB.text = "New prefix:")
                3: (lblA.text = "Find:"; lblB.text = "Replace with:")
            )
            edtB.enabled = rdoMode.state != 1
            chkSkipPrefixed.enabled = rdoMode.state == 1
        )

        fn runRename =
        (
            local inDir = normDir edtInput.text
            local outDir = normDir edtOutput.text
            local opts = getOptions()
            local problem = case of
            (
                (files.count == 0): "There are no files to rename. Select an input folder first."
                (outDir == ""): "Select an output folder."
                ((toLower outDir) == (toLower inDir)): "The output folder must be different from the input folder, the original files are never overwritten."
                (opts.a == ""): "Type the text to " + (if opts.mode == 3 then "find." else "add or replace.")
                default: undefined
            )
            if problem != undefined then messageBox problem title:toolTitle
            else
            (
                logger.log "=== NODE RENAMER ==="
                logger.info "Input: '{}'  Output: '{}'" args:#(inDir, outDir)
                logger.info "Mode: {}  A: '{}'  B: '{}'  Ignore case: {}" args:#(#("Add prefix", "Replace prefix", "Find / Replace")[opts.mode], opts.a, opts.b, opts.ignoreCase)

                local written = 0
                local skipped = #()
                local renamedNodes = 0
                local reference = undefined  -- #(file, node list key) of the first written file
                local mismatched = 0
                for i = 1 to files.count do
                (
                    local rel = substring files[i] (inDir.count + 1) -1
                    lblStatus.text = rel
                    local h = parseHeader files[i]
                    if h.problem != undefined then
                    (
                        logger.warn "Skipped '{}': {}" args:#(rel, h.problem)
                        append skipped rel
                    )
                    else
                    (
                        local newNames = for n in h.names collect applyRename n opts
                        local problems = validateNames newNames
                        if problems.count > 0 then
                        (
                            for p in problems do logger.error "'{}': {}" args:#(rel, p)
                            append skipped rel
                        )
                        else
                        (
                            local outPath = outDir + rel
                            makeDir (getFilenamePath outPath) all:true
                            if writeRenamedFile h newNames outPath then
                            (
                                local changed = countChanged h newNames
                                written += 1
                                renamedNodes += changed
                                logger.info "'{}': {} of {} nodes renamed" args:#(rel, changed, newNames.count)

                                -- Files of one model should share the node names
                                local key = nodeListKey newNames
                                if reference == undefined then reference = #(rel, key)
                                else if key != reference[2] do
                                (
                                    mismatched += 1
                                    logger.warn "'{}' has different nodes than '{}'" args:#(rel, reference[1])
                                )
                            )
                            else append skipped rel
                        )
                    )
                    pbProgress.value = 100.0 * i / files.count
                )

                local summary = "Files written: " + (written as string) + " / " + (files.count as string) + \
                    "\nNodes renamed: " + (renamedNodes as string)
                if skipped.count > 0 do
                (
                    summary += "\n\nSkipped (" + (skipped.count as string) + "):"
                    for i = 1 to (amin skipped.count 10) do summary += "\n  " + skipped[i]
                    if skipped.count > 10 do summary += "\n  ..."
                )
                if mismatched > 0 do
                    summary += "\n\n" + (mismatched as string) + " file(s) have different nodes than '" + reference[1] + "'."
                if skipped.count > 0 or mismatched > 0 do summary += "\nSee the log for details."
                logger.log (substituteString summary "\n" " ")
                lblStatus.text = "Done: " + (written as string) + " file(s) written"
                pbProgress.value = 0

                if written > 0 then
                (
                    if queryBox (summary + "\n\nOpen the output folder?") title:toolTitle do
                        ShellLaunch "explorer.exe" outDir
                )
                else messageBox summary title:toolTitle
            )
        )

        on NodeRenamerRollout open do updateModeUI()

        on btnInput pressed do
        (
            local dir = getSavePath caption:"Select the folder with the source files (JMA family / JMS)" \
                initialDir:(if edtInput.text != "" then edtInput.text else maxFilePath)
            if dir != undefined do
            (
                edtInput.text = normDir dir
                edtOutput.text = edtInput.text + "converted\\"
                refreshFiles()
            )
        )
        on btnOutput pressed do
        (
            local dir = getSavePath caption:"Select the output folder" initialDir:edtOutput.text
            if dir != undefined do
            (
                edtOutput.text = normDir dir
                refreshFiles()
            )
        )
        on edtOutput entered txt do refreshFiles()
        on chkSubfolders changed state do refreshFiles()
        on chkAnimations changed state do refreshFiles()
        on chkModels changed state do refreshFiles()
        on ddlFile selected index do loadPreviewFile()
        on rdoMode changed state do
        (
            updateModeUI()
            refreshPreview()
        )
        on edtA changed txt do refreshPreview()
        on edtB changed txt do refreshPreview()
        on chkIgnoreCase changed state do refreshPreview()
        on chkSkipPrefixed changed state do refreshPreview()
        on btnRename pressed do runRename()
    )

    createDialog NodeRenamerRollout style:#(#style_titlebar, #style_sysmenu, #style_minimizebox)
)
