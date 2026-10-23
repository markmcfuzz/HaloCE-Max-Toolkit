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
--	SKIN BONE LIMITER
--
--	Halo CE vertices take 2 node influences at most. Every vertex of the selected Skin objects
--	with more than 2 bones is rewritten to 2:
--
--	    Hierarchy:        the main bone is the heaviest one. Its partner is the heaviest of the
--	                      vertex's bones that is the parent or a child of the main bone; failing
--	                      that, the heaviest in the same chain (ancestor or descendant); failing
--	                      that, the next heaviest. The weight of each dropped bone goes to the
--	                      kept bone closest to it in the hierarchy (the main bone on a tie).
--
--	    Largest weights:  keeps the 2 heaviest bones and scales them so they add up to 1.
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
    global SkinBoneLimiterRollout
    try (destroyDialog SkinBoneLimiterRollout) catch()

    local toolTitle = "Skin Bone Limiter"
    local maxInfluences = 2
    local minWeight = 0.0001  -- influences below this are ignored
    local unrelated = 100000  -- hierarchy distance of bones in different trees
    local logExamples = 10    -- converted vertices written to the log

    -------------------------------------------------------
    -- SKIN ACCESS
    -------------------------------------------------------

    fn findSkin obj =
    (
        local found = undefined
        if isValidNode obj do
            for m in obj.modifiers while found == undefined where classOf m == Skin do found = m
        found
    )

    fn skinnedObjects objs = for obj in objs where (findSkin obj) != undefined collect obj

    -- Most skinOps calls need the Skin shown in the modify panel
    fn openSkin obj skinMod =
    (
        if getCommandPanelTaskMode() != #modify do setCommandPanelTaskMode #modify
        if selection.count != 1 or selection[1] != obj do select obj
        modPanel.setCurrentObject skinMod node:obj
    )

    fn getBoneNodes skinMod =
    (
        for b = 1 to (skinOps.GetNumberBones skinMod) collect
        (
            local n = try (skinOps.GetBoneNode skinMod b) catch (undefined)
            if not isValidNode n do
            (
                local matches = getNodeByName (skinOps.GetBoneName skinMod b 0) exact:true all:true
                n = if matches.count > 0 then matches[1] else undefined
            )
            n
        )
    )

    -- #(bones, weights) of a vertex, without the tiny influences
    fn readInfluences skinMod v =
    (
        local bones = #()
        local weights = #()
        for w = 1 to (skinOps.GetVertexWeightCount skinMod v) do
        (
            local weight = skinOps.GetVertexWeight skinMod v w
            if weight > minWeight do
            (
                append bones (skinOps.GetVertexWeightBoneID skinMod v w)
                append weights weight
            )
        )
        #(bones, weights)
    )

    fn fmtWeights skinMod bones weights =
    (
        local text = ""
        for k = 1 to bones.count do
            text += (if k > 1 then ", " else "") + (skinOps.GetBoneName skinMod bones[k] 0) + " " + (formattedPrint weights[k] format:".2f")
        text
    )

    -------------------------------------------------------
    -- HIERARCHY
    -------------------------------------------------------

    -- The node and its ancestors, the node first (undefined for a missing bone)
    fn ancestry n =
    (
        if not isValidNode n then undefined
        else
        (
            local chain = #()
            while n != undefined do
            (
                append chain n
                n = n.parent
            )
            chain
        )
    )

    -- Steps between two bones through their closest common ancestor
    fn hierarchyDistance chainA chainB =
    (
        local steps = unrelated
        if chainA != undefined and chainB != undefined do
            for i = 1 to chainA.count while steps == unrelated do
            (
                local j = findItem chainB chainA[i]
                if j > 0 do steps = (i - 1) + (j - 1)
            )
        steps
    )

    -- One bone is an ancestor of the other
    fn sameChain chainA chainB =
        chainA != undefined and chainB != undefined and ((findItem chainA chainB[1]) > 0 or (findItem chainB chainA[1]) > 0)

    fn byWeightDesc a b = if a[1] > b[1] then -1 else if a[1] < b[1] then 1 else 0

    -- Influence indices, heaviest first
    fn weightOrder weights =
    (
        local order = for k = 1 to weights.count collect #(weights[k], k)
        qsort order byWeightDesc
        for o in order collect o[2]
    )

    -------------------------------------------------------
    -- LIMITING
    -------------------------------------------------------

    -- #(bones, weights) with the 2 heaviest bones, scaled to add up to 1
    fn limitLargest bones weights =
    (
        local order = weightOrder weights
        local a = order[1]
        local b = order[2]
        local total = weights[a] + weights[b]
        #(#(bones[a], bones[b]), #(weights[a] / total, weights[b] / total))
    )

    -- #(bones, weights): the heaviest bone and its closest relative among the vertex's bones;
    -- every dropped weight goes to the kept bone closest to it in the hierarchy
    fn limitHierarchy bones weights chains =
    (
        local order = weightOrder weights
        local main = order[1]
        local mainChain = chains[bones[main]]
        local partner = 0
        -- 1: parent or child of the main bone, 2: ancestor or descendant, 3: any
        for level = 1 to 3 while partner == 0 do
            for k in order while partner == 0 where k != main do
            (
                local chain = chains[bones[k]]
                local related = case level of
                (
                    1: (hierarchyDistance mainChain chain) == 1
                    2: sameChain mainChain chain
                    default: true
                )
                if related do partner = k
            )

        local partnerChain = chains[bones[partner]]
        local sums = #(weights[main], weights[partner])
        for k = 1 to bones.count where k != main and k != partner do
        (
            local chain = chains[bones[k]]
            if (hierarchyDistance partnerChain chain) < (hierarchyDistance mainChain chain) then sums[2] += weights[k]
            else sums[1] += weights[k]
        )
        local total = sums[1] + sums[2]
        #(#(bones[main], bones[partner]), #(sums[1] / total, sums[2] / total))
    )

    -------------------------------------------------------
    -- UI
    -------------------------------------------------------

    rollout SkinBoneLimiterRollout "Skin Bone Limiter" width:300
    (
        group "Second Bone"
        (
            radiobuttons rdoMode labels:#("Related to the main bone (hierarchy)", "Second largest weight") columns:1 align:#left
        )
        checkbox chkBoneLimit "Set Skin bone limit to 2" checked:true \
            tooltip:"So later weight painting keeps 2 bones per vertex"
        button btnAnalyze "Analyze Selection" width:135 across:2
        button btnConvert "Limit to 2 Bones" width:135
        listbox lbxReport "" height:6 width:270
        label lblStatus "Select the skinned objects." align:#left width:270

        fn report lines =
        (
            lbxReport.items = lines
            for l in lines do logger.info l
        )

        fn runAnalyze =
        (
            local objs = skinnedObjects (selection as array)
            if objs.count == 0 then messageBox "Select at least one object with a Skin modifier." title:toolTitle
            else
            (
                logger.log "=== SKIN BONE LIMITER: ANALYZE ==="
                local lines = #()
                local total = 0
                for obj in objs do
                (
                    local skinMod = findSkin obj
                    openSkin obj skinMod
                    local vertCount = skinOps.GetNumberVertices skinMod
                    local over = #{}
                    local most = 0
                    for v = 1 to vertCount do
                    (
                        local c = (readInfluences skinMod v)[1].count
                        if c > maxInfluences do over[v] = true
                        most = amax most c
                    )
                    total += over.numberSet
                    append lines (obj.name + ": " + (over.numberSet as string) + " of " + (vertCount as string) + \
                        " vertices over 2 bones (max " + (most as string) + ")")
                    if objs.count == 1 do skinOps.SelectVertices skinMod over
                )
                if objs.count != 1 do select objs
                report lines
                lblStatus.text = (total as string) + " vertices need fixing" + (if objs.count == 1 and total > 0 then " (selected in the Skin)" else "")
            )
        )

        fn runConvert =
        (
            local objs = skinnedObjects (selection as array)
            if objs.count == 0 then messageBox "Select at least one object with a Skin modifier." title:toolTitle
            else
            (
                local byHierarchy = rdoMode.state == 1
                logger.log "=== SKIN BONE LIMITER ==="
                logger.info "Second bone: {}" args:#(if byHierarchy then "hierarchy" else "largest weight")
                local lines = #()
                local converted = 0
                local start = timeStamp()
                for obj in objs do
                (
                    local skinMod = findSkin obj
                    openSkin obj skinMod
                    local chains = for n in (getBoneNodes skinMod) collect ancestry n
                    local missing = for b = 1 to chains.count where chains[b] == undefined collect skinOps.GetBoneName skinMod b 0
                    if byHierarchy and missing.count > 0 do
                        logger.warn "'{}': bones not found in the scene, treated as unrelated: {}" args:#(obj.name, missing)

                    local changed = #()
                    undo "Skin Bone Limiter" on
                    (
                        with redraw off
                        (
                            for v = 1 to (skinOps.GetNumberVertices skinMod) do
                            (
                                local inf = readInfluences skinMod v
                                if inf[1].count > maxInfluences do
                                (
                                    local result = if byHierarchy then limitHierarchy inf[1] inf[2] chains else limitLargest inf[1] inf[2]
                                    skinOps.ReplaceVertexWeights skinMod v result[1] result[2]
                                    if (try (skinOps.isUnNormalizeVertex skinMod v) catch (false)) do
                                        skinOps.unNormalizeVertex skinMod v false
                                    append changed v
                                    if changed.count <= logExamples do
                                        logger.info "'{}' vertex {}: {}  ->  {}" args:#(obj.name, v, \
                                            fmtWeights skinMod inf[1] inf[2], fmtWeights skinMod result[1] result[2])
                                )
                            )
                            if chkBoneLimit.checked do skinMod.bone_Limit = maxInfluences
                        )
                    )
                    converted += changed.count
                    append lines (obj.name + ": " + (changed.count as string) + " vertices limited to 2 bones")
                    if objs.count == 1 do skinOps.SelectVertices skinMod changed
                )
                if objs.count != 1 do select objs
                report lines
                lblStatus.text = "Done: " + (converted as string) + " vertices in " + (formattedPrint ((timeStamp() - start) / 1000.0) format:".1f") + " s"
                completeRedraw()
            )
        )

        on btnAnalyze pressed do runAnalyze()
        on btnConvert pressed do runConvert()
    )

    createDialog SkinBoneLimiterRollout style:#(#style_titlebar, #style_sysmenu, #style_minimizebox)
)
