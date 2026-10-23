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
--	PACKED UV FIXER
--
--	Halo Campaign Evolved models use textures made of N square images packed side by side in a
--	horizontal strip, but their UVs come in "image" units: U runs 0..N instead of 0..1. Each
--	material ID of the selected objects gets its U scaled from U = 0 (V is left alone):
--
--	    From the texture:   factor = height / width of the material's bitmap (1/N).
--	    From the UV range:  factor = 1 / the number of 0-1 tiles the UVs cover in U.
--	    Manual:             the typed factor.
--
--	The UVs edited are those of the topmost Unwrap UVW on the map channel, or the base Editable
--	Mesh/Poly when there is none. Modifiers above them (Skin) are kept.
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
    global PackedUvFixerRollout
    try (destroyDialog PackedUvFixerRollout) catch()

    local toolTitle = "Packed UV Fixer"
    local fitTolerance = 0.001  -- UVs this far past a tile edge still count as inside it

    -- kind: #unwrap, #mesh or #poly; problem: why the object cannot be edited
    struct uvSource (obj, channel, kind, unwrapMod, positions = #(), faces = #(), matIDs = #(), note, problem)

    -- One material ID of an object: its map vertices, U range and scale
    struct uvIdInfo (id, verts, minU = 1e9, maxU = -1e9, texName = "", texSize, factor = 1.0, reason = "")

    -------------------------------------------------------
    -- UV ACCESS
    -------------------------------------------------------

    fn unwrapChannel m = try (m.getMapChannel()) catch (-1)

    fn uvModifierChannel m =
    (
        case classOf m of
        (
            Unwrap_UVW: unwrapChannel m
            Uvwmap: try (m.mapChannel) catch (-1)
            UVW_Xform: try (m.Map_Channel) catch (-1)
            default: -1
        )
    )

    -- Topmost enabled Unwrap UVW on the channel
    fn findUnwrap obj channel =
    (
        local found = undefined
        for m in obj.modifiers while found == undefined where classOf m == Unwrap_UVW and m.enabled do
            if (unwrapChannel m) == channel do found = m
        found
    )

    -- Unwrap UVW vertex calls need the modifier shown in the modify panel
    fn openModifier obj m =
    (
        if getCommandPanelTaskMode() != #modify do setCommandPanelTaskMode #modify
        if selection.count != 1 or selection[1] != obj do select obj
        modPanel.setCurrentObject m node:obj
    )

    fn meshFaceMatIDs tri = for f = 1 to tri.numfaces collect getFaceMatID tri f

    fn baseFaceMatIDs base =
    (
        if classOf base == Editable_Mesh then meshFaceMatIDs base.mesh
        else if classOf base == Editable_Poly then for f = 1 to (polyop.getNumFaces base) collect polyop.getFaceMatID base f
        else undefined
    )

    fn readMeshFaces base channel =
    (
        for f = 1 to (getNumFaces base.mesh) collect
        (
            local mf = meshop.getMapFace base channel f
            #(mf.x as integer, mf.y as integer, mf.z as integer)
        )
    )

    fn readSource obj channel =
    (
        local src = uvSource obj:obj channel:channel
        local base = obj.baseObject
        src.unwrapMod = findUnwrap obj channel
        if src.unwrapMod != undefined then
        (
            local m = src.unwrapMod
            src.kind = #unwrap
            openModifier obj m
            src.positions = for v = 1 to m.numberVertices() collect m.getVertexPosition currentTime v
            src.faces = for f = 1 to m.numberPolygons() collect
                for k = 1 to (m.numberPointsInFace f) collect m.getVertexIndexFromFace f k
        )
        else if classOf base == Editable_Mesh then
        (
            src.kind = #mesh
            if not (meshop.getMapSupport base channel) then src.problem = "map channel " + (channel as string) + " is empty"
            else
            (
                src.positions = for v = 1 to (meshop.getNumMapVerts base channel) collect meshop.getMapVert base channel v
                src.faces = readMeshFaces base channel
            )
        )
        else if classOf base == Editable_Poly then
        (
            src.kind = #poly
            if not (polyop.getMapSupport base channel) then src.problem = "map channel " + (channel as string) + " is empty"
            else
            (
                src.positions = for v = 1 to (polyop.getNumMapVerts base channel) collect polyop.getMapVert base channel v
                src.faces = for f = 1 to (polyop.getNumFaces base) collect polyop.getMapFace base channel f
            )
        )
        else src.problem = "the base object is " + ((classOf base) as string) + ", convert it to Editable Mesh/Poly or add an Unwrap UVW"

        if src.problem == undefined do
        (
            local ids = baseFaceMatIDs base
            if ids != undefined and ids.count == src.faces.count then src.matIDs = ids
            else
            (
                src.matIDs = for f in src.faces collect 1
                src.note = "faces do not match the base object, material ID 1 used for all of them"
            )
        )
        src
    )

    fn writePositions src verts =
    (
        local base = src.obj.baseObject
        case src.kind of
        (
            #unwrap: for v in verts do src.unwrapMod.setVertexPosition currentTime v src.positions[v]
            #mesh:
            (
                for v in verts do meshop.setMapVert base src.channel v src.positions[v]
                try (update src.obj) catch()
            )
            #poly: for v in verts do polyop.setMapVert base src.channel v src.positions[v]
        )
        try (notifyDependents base) catch()
    )

    -- Names of the UV modifiers on the channel that sit above the edited UVs
    fn overridingModifiers src =
    (
        local mods = for m in src.obj.modifiers collect m
        local last = if src.unwrapMod != undefined then (findItem mods src.unwrapMod) - 1 else mods.count
        for i = 1 to last where mods[i].enabled and (uvModifierChannel mods[i]) == src.channel collect mods[i].name
    )

    -------------------------------------------------------
    -- MATERIALS
    -------------------------------------------------------

    fn subMaterial mat id =
    (
        if classOf mat == Multimaterial then
        (
            local k = findItem mat.materialIDList id
            if k > 0 then mat.materialList[k] else undefined
        )
        else mat
    )

    -- The diffuse bitmap, or the first bitmap found in the material
    fn findBitmap mat =
    (
        local found = undefined
        if mat != undefined do
        (
            for p in #(#diffuseMap, #base_color_map) while found == undefined where isProperty mat p do
            (
                local m = getProperty mat p
                if classOf m == Bitmaptexture do found = m
            )
            if found == undefined do
            (
                local all = try (getClassInstances Bitmaptexture target:mat) catch (#())
                if all.count > 0 do found = all[1]
            )
        )
        found
    )

    -- [width, height], or undefined when the bitmap cannot be loaded
    fn bitmapSize bt cache =
    (
        local key = toLower (bt.filename as string)
        if not (hasDictValue cache key) do
        (
            local size = [0, 0]
            try
            (
                local b = bt.bitmap
                if b != undefined do size = [b.width, b.height]
            )
            catch()
            cache[key] = size
        )
        local size = cache[key]
        if size.x > 0 and size.y > 0 then size else undefined
    )

    -------------------------------------------------------
    -- SCALING
    -------------------------------------------------------

    fn byID a b = a.id - b.id

    fn collectIDs src =
    (
        local infos = #()
        local ids = #()
        for f = 1 to src.faces.count do
        (
            local id = src.matIDs[f]
            local k = findItem ids id
            if k == 0 do
            (
                append ids id
                append infos (uvIdInfo id:id verts:#{})
                k = ids.count
            )
            for v in src.faces[f] where v > 0 and v <= src.positions.count do infos[k].verts[v] = true
        )
        for info in infos do
            for v in info.verts do
            (
                local u = src.positions[v].x
                if u < info.minU do info.minU = u
                if u > info.maxU do info.maxU = u
            )
        qsort infos byID
        infos
    )

    -- mode: 1 from the texture, 2 from the UV range, 3 manual
    fn decideFactor info mat mode manualFactor skipFitted cache =
    (
        local rangeTiles = amax 1 ((ceil (info.maxU - fitTolerance)) as integer)
        local tiles = undefined
        local bt = findBitmap (subMaterial mat info.id)
        if bt != undefined do
        (
            info.texName = filenameFromPath (bt.filename as string)
            info.texSize = bitmapSize bt cache
            if info.texSize != undefined do tiles = info.texSize.x / info.texSize.y
        )

        if skipFitted and info.maxU <= 1.0 + fitTolerance then
        (
            info.factor = 1.0
            info.reason = "already within 0-1"
        )
        else case mode of
        (
            1:
            (
                if tiles == undefined then
                (
                    info.factor = 1.0 / rangeTiles
                    info.reason = "no texture found, UV range used"
                )
                else if tiles <= 1.0 + fitTolerance then
                (
                    info.factor = 1.0
                    info.reason = "texture is not a strip, left alone"
                )
                else
                (
                    info.factor = 1.0 / tiles
                    info.reason = "texture"
                )
            )
            2:
            (
                info.factor = 1.0 / rangeTiles
                info.reason = "UV range"
            )
            default:
            (
                info.factor = manualFactor
                info.reason = "manual"
            )
        )
    )

    -- Scales the U of every map vertex by the factor of its material ID; returns #(changed verts, conflicts)
    fn scaleU src infos =
    (
        local vertFactor = for v = 1 to src.positions.count collect undefined
        local conflicts = 0
        for info in infos do
            for v in info.verts do
            (
                if vertFactor[v] == undefined then vertFactor[v] = info.factor
                else if (abs (vertFactor[v] - info.factor)) > 1e-6 do conflicts += 1
            )
        local changed = for v = 1 to vertFactor.count where vertFactor[v] != undefined and vertFactor[v] != 1.0 collect v
        for v in changed do
        (
            local p = src.positions[v]
            src.positions[v] = [p.x * vertFactor[v], p.y, p.z]
        )
        #(changed, conflicts)
    )

    fn fmtF x = formattedPrint x format:".3f"

    fn describe info =
    (
        local text = "  ID " + (info.id as string) + ": U " + (fmtF info.minU) + " .. " + (fmtF info.maxU)
        if info.texName != "" do
        (
            text += " | " + info.texName
            if info.texSize != undefined do
                text += " " + ((info.texSize.x as integer) as string) + "x" + ((info.texSize.y as integer) as string)
        )
        text + " | x" + (fmtF info.factor) + " (" + info.reason + ")"
    )

    -------------------------------------------------------
    -- UI
    -------------------------------------------------------

    rollout PackedUvFixerRollout "Packed UV Fixer" width:360
    (
        group "U Scale (from U = 0)"
        (
            radiobuttons rdoMode labels:#("From the texture (height / width)", "From the UV range (1 / tiles used)", "Manual factor") columns:1 align:#left
            spinner spnFactor "Factor: " range:[0.001, 100, 0.5] scale:0.01 type:#float fieldwidth:50 align:#left enabled:false
        )
        spinner spnChannel "Map channel: " range:[1, 99, 1] type:#integer fieldwidth:40 align:#left
        checkbox chkSkipFitted "Skip material IDs already within 0-1 in U" checked:true \
            tooltip:"So running the fix twice does not shrink the UVs again"
        button btnAnalyze "Analyze Selection" width:165 across:2
        button btnApply "Fix UVs" width:165
        listbox lbxReport "" height:10 width:330
        label lblStatus "Select the meshes." align:#left width:330

        fn report lines =
        (
            lbxReport.items = lines
            for l in lines do logger.info l
        )

        fn process apply =
        (
            local objs = for o in selection where superClassOf o == GeometryClass collect o
            if objs.count == 0 then messageBox "Select at least one mesh." title:toolTitle
            else
            (
                logger.log (if apply then "=== PACKED UV FIXER ===" else "=== PACKED UV FIXER: ANALYZE ===")
                local original = selection as array
                local cache = Dictionary #string
                local lines = #()
                local changedTotal = 0
                local start = timeStamp()
                for obj in objs do
                (
                    local src = readSource obj spnChannel.value
                    if src.problem != undefined then
                    (
                        append lines (obj.name + ": skipped, " + src.problem)
                        logger.warn "'{}': {}" args:#(obj.name, src.problem)
                    )
                    else
                    (
                        local infos = collectIDs src
                        for info in infos do
                            decideFactor info obj.material rdoMode.state spnFactor.value chkSkipFitted.checked cache
                        local target = case src.kind of (#unwrap: src.unwrapMod.name; #mesh: "Editable Mesh"; default: "Editable Poly")
                        local header = obj.name + " (" + target + ")"
                        if apply do
                        (
                            local result
                            undo "Packed UV Fixer" on
                            (
                                result = scaleU src infos
                                writePositions src result[1]
                            )
                            changedTotal += result[1].count
                            header += ": " + (result[1].count as string) + " UV vertices scaled"
                            if result[2] > 0 do
                                logger.warn "'{}': {} UV vertices are shared by material IDs with different factors, the first ID wins" args:#(obj.name, result[2])
                        )
                        append lines header
                        for info in infos do append lines (describe info)
                        if src.note != undefined do
                        (
                            append lines ("  " + src.note)
                            logger.warn "'{}': {}" args:#(obj.name, src.note)
                        )
                        local over = overridingModifiers src
                        if over.count > 0 do
                        (
                            append lines ("  overridden by: " + (over as string))
                            logger.warn "'{}': these modifiers sit above the edited UVs and may override them: {}" args:#(obj.name, over)
                        )
                    )
                )
                if objs.count != 1 and original.count > 0 do select original
                report lines
                lblStatus.text = if apply then
                    "Done: " + (changedTotal as string) + " UV vertices in " + (formattedPrint ((timeStamp() - start) / 1000.0) format:".1f") + " s"
                else "Analyzed " + (objs.count as string) + " objects"
                completeRedraw()
            )
        )

        on rdoMode changed state do spnFactor.enabled = state == 3
        on btnAnalyze pressed do process false
        on btnApply pressed do process true
    )

    createDialog PackedUvFixerRollout style:#(#style_titlebar, #style_sysmenu, #style_minimizebox)
)
