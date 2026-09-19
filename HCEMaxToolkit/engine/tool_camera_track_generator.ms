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

-- Clear listener
clearListener()

-- Force garbage collection to clear old structs from memory
gc light:true

-- Log file setup
scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

-- Camera setup + animation are shared with the camera_track importer
include "builders\\tag\\camera_track\\build_scene.ms"

(
    global CameraTrackGeneratorRollout
    try (destroyDialog CameraTrackGeneratorRollout) catch()

    local toolTitle = "Camera Track Generator"
    local centerSampleCount = 128
    local epsilon = 0.0001

    -------------------------------------------------------
    -- VECTOR HELPERS
    -------------------------------------------------------

    -- Normalized component of v perpendicular to the unit vector dir (undefined when parallel)
    fn perpendicularTo v dir =
    (
        local perp = v - (dot v dir) * dir
        if (length perp) < epsilon then undefined else normalize perp
    )

    -------------------------------------------------------
    -- SPLINE SAMPLING
    -------------------------------------------------------

    fn isSplineClosed splineNode splineIndex =
    (
        local closedFlag = try (isClosed splineNode splineIndex) catch (false)
        -- Open splines whose ends touch count as closed, so the first and last points don't overlap
        local endGap = distance (lengthInterp splineNode splineIndex 0.0) (lengthInterp splineNode splineIndex 1.0)
        closedFlag or endGap < epsilon
    )

    -- Evenly spaced (by length) world-space points along the spline
    fn sampleSpline splineNode splineIndex sampleCount closedSpline =
    (
        for i = 0 to sampleCount - 1 collect
        (
            local t = if closedSpline then (i as float / sampleCount) else (i as float / (sampleCount - 1))
            lengthInterp splineNode splineIndex t
        )
    )

    -------------------------------------------------------
    -- AIM CENTER
    -------------------------------------------------------

    fn getCentroid pts =
    (
        local total = [0,0,0]
        for p in pts do total += p
        total / pts.count
    )

    fn getBoundingBoxCenter pts =
    (
        local minPt = pts[1]
        local maxPt = pts[1]
        for p in pts do
        (
            minPt = [(amin minPt.x p.x), (amin minPt.y p.y), (amin minPt.z p.z)]
            maxPt = [(amax maxPt.x p.x), (amax maxPt.y p.y), (amax maxPt.z p.z)]
        )
        (minPt + maxPt) * 0.5
    )

    -- Least-squares circle fit (Kasa) in the curve's plane. Exact for arcs and circles,
    -- symmetric shapes (rectangles, ellipses) land on their middle, straight lines fall back to the centroid.
    fn getFittedCircleCenter pts =
    (
        local centroid = getCentroid pts

        -- Newell's method: plane normal of the (implicitly closed) polyline
        local planeNormal = [0,0,0]
        local meanSq = 0.0
        for i = 1 to pts.count do
        (
            local a = pts[i] - centroid
            local b = pts[(if i == pts.count then 1 else i + 1)] - centroid
            planeNormal += cross a b
            meanSq += dot a a
        )
        meanSq /= pts.count
        if meanSq < epsilon or (length planeNormal) < 0.0001 * meanSq then return centroid

        planeNormal = normalize planeNormal
        local helperAxis = if (abs planeNormal.z) < 0.9 then [0,0,1] else [1,0,0]
        local axisU = normalize (cross helperAxis planeNormal)
        local axisV = cross planeNormal axisU

        local suu = 0.0
        local suv = 0.0
        local svv = 0.0
        local suz = 0.0
        local svz = 0.0
        for p in pts do
        (
            local d = p - centroid
            local u = dot d axisU
            local v = dot d axisV
            local z = u * u + v * v
            suu += u * u
            suv += u * v
            svv += v * v
            suz += u * z
            svz += v * z
        )

        local det = suu * svv - suv * suv
        local trace = suu + svv
        if det < 0.000001 * trace * trace then return centroid

        local cu = (suz * svv - svz * suv) / (2.0 * det)
        local cv = (svz * suu - suz * suv) / (2.0 * det)
        centroid + axisU * cu + axisV * cv
    )

    -------------------------------------------------------
    -- CONTROL POINT TRANSFORMS
    -------------------------------------------------------

    -- World transforms for pyramids from createCameraControlPoint: local +X (tip) looks at aimCenter, local +Z up
    fn computeControlPointTransforms splineNode splineIndex closedSpline pointCount aimCenter radialOffset reverseOrder =
    (
        local positions = #()
        local forwards = #()

        for i = 1 to pointCount do
        (
            local t = 0.0
            if closedSpline then t = (i - 1) as float / pointCount
            else if pointCount > 1 then t = (i - 1) as float / (pointCount - 1)
            if reverseOrder and (not closedSpline or t > 0.0) then t = 1.0 - t

            local pointPos = lengthInterp splineNode splineIndex t
            local radialDir = pointPos - aimCenter
            if (length radialDir) > epsilon then pointPos += (normalize radialDir) * radialOffset

            local toCenter = aimCenter - pointPos
            local forwardDir = if (length toCenter) > epsilon then normalize toCenter else normalize (lengthTangent splineNode splineIndex t)

            append positions pointPos
            append forwards forwardDir
        )

        -- Keep the horizon level (world Z up), like a camera
        local worldUp = [0,0,1]
        local ups = for f in forwards collect (if (abs (dot f worldUp)) > 0.9995 then undefined else perpendicularTo worldUp f)

        -- Looking straight up/down has no horizon: borrow the neighbour's up so the roll stays continuous
        local lastUp = undefined
        for i = 1 to ups.count do
        (
            if ups[i] == undefined and lastUp != undefined then ups[i] = perpendicularTo lastUp forwards[i]
            if ups[i] != undefined then lastUp = ups[i]
        )
        lastUp = undefined
        for i = ups.count to 1 by -1 do
        (
            if ups[i] == undefined and lastUp != undefined then ups[i] = perpendicularTo lastUp forwards[i]
            if ups[i] != undefined then lastUp = ups[i]
        )
        for i = 1 to ups.count where ups[i] == undefined do
            ups[i] = perpendicularTo [0,1,0] forwards[i]

        -- Right-handed frame: X = forward, Z = up, Y = Z x X
        for i = 1 to pointCount collect
            matrix3 forwards[i] (cross ups[i] forwards[i]) ups[i] positions[i]
    )

    fn createControlPoints transforms =
    (
        local camLayer = LayerManager.getLayerFromName "Camera Control Points"
        if camLayer == undefined then
            camLayer = LayerManager.newLayerFromName "Camera Control Points"

        for i = 1 to transforms.count collect
        (
            local ctrlPoint = createCameraControlPoint (i - 1)
            ctrlPoint.transform = transforms[i]
            camLayer.addNode ctrlPoint
            ctrlPoint
        )
    )

    -------------------------------------------------------
    -- SCENE CAMERA TRACK NODES
    -------------------------------------------------------

    -- Every control_point_* node in the scene (what the exporter collects), sorted by name
    fn getSceneControlPoints =
    (
        local ctrlPoints = for obj in objects where matchPattern obj.name pattern:"control_point_*" collect obj
        qsort ctrlPoints (fn compareByName a b = stricmp a.name b.name)
        ctrlPoints
    )

    -- Removes the camera, target and dummy made by createCameraSetup (build_scene.ms)
    fn deleteCameraSetup =
    (
        local cameraNames = #("camera_track_cam", "camera_track_target", "camera_track_dummy")
        local oldNodes = for obj in objects where (findItem cameraNames (toLower obj.name)) > 0 collect obj
        -- Deleting the camera also deletes its target, so re-check each node
        for obj in oldNodes where isValidNode obj do delete obj
        oldNodes.count
    )

    fn rebuildCameraSetup ctrlPoints =
    (
        deleteCameraSetup()
        local cameraSetup = createCameraSetup ctrlPoints
        animateCameraPath cameraSetup[2] ctrlPoints
    )

    -------------------------------------------------------
    -- DIALOG
    -------------------------------------------------------

    rollout CameraTrackGeneratorRollout "Camera Track Generator" width:300
    (
        fn shapeFilter obj = superClassOf obj == Shape

        group "Path Spline"
        (
            pickButton btnSpline "Pick Path Spline" width:270 height:26 filter:shapeFilter
            spinner spnSplineIndex "Spline index: " range:[1,100,1] type:#integer fieldwidth:50 align:#right
        )
        group "Camera Points"
        (
            spinner spnCount "Camera points: " range:[2,16,8] type:#integer fieldwidth:50 align:#right
            spinner spnOffset "Radial offset: " range:[-100000,100000,0] type:#worldunits fieldwidth:50 align:#right
            checkbox chkReverse "Reverse direction"
        )
        group "Aim"
        (
            dropdownList ddlCenter "Look at:" items:#("Curve center (best-fit circle)", "Spline pivot", "Bounding box center", "Custom object") width:270
            pickButton btnTarget "Pick Target Object" width:270 height:26 enabled:false
        )
        group "Output"
        (
            checkbox chkDeleteExisting "Delete existing camera points" checked:true \
                tooltip:"Deletes every control_point_* object in the scene before generating"
            checkbox chkAnimate "Create camera animation" checked:false \
                tooltip:"Replaces the existing camera_track camera with a new animated one"
        )
        button btnGenerate "Generate Camera Points" width:270 height:36
        button btnRebuildCamera "Rebuild Camera" width:270 height:28 \
            tooltip:"Deletes the existing camera and animates a new one along the control_point_* objects in the scene"

        fn refreshControls =
        (
            btnSpline.text = if isValidNode btnSpline.object then btnSpline.object.name else "Pick Path Spline"
            btnTarget.text = if isValidNode btnTarget.object then btnTarget.object.name else "Pick Target Object"

            local splineCount = if isValidNode btnSpline.object then amax 1 (numSplines btnSpline.object) else 1
            spnSplineIndex.range = [1, splineCount, (amin spnSplineIndex.value splineCount)]
            spnSplineIndex.enabled = splineCount > 1
            btnTarget.enabled = ddlCenter.selection == 4
        )

        fn generate =
        (
            local splineNode = btnSpline.object
            local targetNode = btnTarget.object
            local centerMode = ddlCenter.selection
            local splineIndex = spnSplineIndex.value

            local problem = case of
            (
                (not isValidNode splineNode): "Pick a path spline first."
                (splineIndex > numSplines splineNode): "Invalid spline index."
                (centerMode == 4 and not isValidNode targetNode): "Pick a target object to look at."
                default: undefined
            )
            if problem != undefined then
            (
                messageBox problem title:toolTitle
                return false
            )

            local startTime = timestamp()

            local closedSpline = isSplineClosed splineNode splineIndex
            local samples = sampleSpline splineNode splineIndex centerSampleCount closedSpline
            local aimCenter = case centerMode of
            (
                1: getFittedCircleCenter samples
                2: splineNode.transform.translation
                3: getBoundingBoxCenter samples
                4: targetNode.transform.translation
            )
            logger.debug "Aim center: {} (closed spline: {})" args:#(aimCenter, closedSpline)

            local transforms = computeControlPointTransforms splineNode splineIndex closedSpline spnCount.value aimCenter \
                spnOffset.value chkReverse.checked

            local ctrlPoints = #()
            local deletedCount = 0
            undo "Generate Camera Points" on
            (
                if chkDeleteExisting.checked then
                (
                    local oldPoints = for obj in getSceneControlPoints() where obj != splineNode and obj != targetNode collect obj
                    deletedCount = oldPoints.count
                    delete oldPoints
                )

                ctrlPoints = createControlPoints transforms
                if chkAnimate.checked then rebuildCameraSetup ctrlPoints

                select ctrlPoints
            )
            completeRedraw()

            local elapsedTime = (timestamp() - startTime) / 1000.0
            logger.info "Generated {} camera point(s) along '{}' (spline {})" args:#(ctrlPoints.count, splineNode.name, splineIndex)

            -- The camera_track exporter collects every control_point_* node, not just these ones
            local strays = for obj in objects where (matchPattern obj.name pattern:"control_point_*") and (findItem ctrlPoints obj) == 0 collect obj
            if strays.count > 0 then
                logger.warn "{} other 'control_point_*' object(s) in the scene, the camera track exporter will pick them up too." args:#(strays.count)

            local summary = "Camera points generated successfully!\n\n" + \
                            "Path Spline: " + splineNode.name + "\n" + \
                            "Camera Points created: " + ctrlPoints.count as string + "\n" + \
                            "Time: " + (formattedPrint elapsedTime format:".3f") + " seconds"
            if deletedCount > 0 then
                summary += "\nExisting camera points deleted: " + deletedCount as string
            if chkAnimate.checked then
                summary += "\nCamera animation: frames 0 - " + ((ctrlPoints.count - 1) * 5) as string
            if strays.count > 0 then
                summary += "\n\nWarning: " + strays.count as string + " other 'control_point_*' object(s) are in the scene.\n" + \
                           "The camera track exporter will include them too."

            -- Warnings are shown even when completion dialogs are disabled
            local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true
            if showDialogs or strays.count > 0 then
                messageBox summary title:toolTitle beep:false

            true
        )

        fn rebuildCamera =
        (
            local ctrlPoints = getSceneControlPoints()
            if ctrlPoints.count < 2 then
            (
                messageBox "At least 2 'control_point_*' objects are needed in the scene to animate the camera." title:toolTitle
                return false
            )

            local startTime = timestamp()
            undo "Rebuild Camera" on rebuildCameraSetup ctrlPoints
            completeRedraw()

            local elapsedTime = (timestamp() - startTime) / 1000.0
            logger.info "Rebuilt camera along {} camera point(s)" args:#(ctrlPoints.count)

            local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true
            if showDialogs then
                messageBox ("Camera rebuilt successfully!\n\n" + \
                            "Camera Points: " + ctrlPoints.count as string + "\n" + \
                            "Camera animation: frames 0 - " + ((ctrlPoints.count - 1) * 5) as string + "\n" + \
                            "Time: " + (formattedPrint elapsedTime format:".3f") + " seconds") \
                            title:toolTitle \
                            beep:false
            true
        )

        on CameraTrackGeneratorRollout open do
        (
            -- Prefill the path spline from the current selection
            local selectedShapes = for obj in selection where shapeFilter obj collect obj
            if selectedShapes.count > 0 then btnSpline.object = selectedShapes[1]
            refreshControls()
        )

        on btnSpline picked obj do refreshControls()
        on btnTarget picked obj do refreshControls()
        on ddlCenter selected i do refreshControls()
        on btnGenerate pressed do generate()
        on btnRebuildCamera pressed do rebuildCamera()
    )

    createDialog CameraTrackGeneratorRollout style:#(#style_titlebar, #style_sysmenu, #style_minimizebox)
)
