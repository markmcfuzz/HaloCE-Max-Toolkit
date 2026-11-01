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

-- Writes the selected object tag Point (e.g. warthog.vehicle, made by import_object.ms) back to a
-- tag with its panel's values (lua\exporters\object.lua). The name's extension says the tag class.

clearListener()
gc light:true

scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

logger.log "=== EXPORTING OBJECT TAG ==="

-- Tag classes the exporter writes, with their file dialog filters
objectExportTypes = #(
    #("biped", "Biped (*.biped)|*.biped"),
    #("vehicle", "Vehicle (*.vehicle)|*.vehicle"),
    #("weapon", "Weapon (*.weapon)|*.weapon"),
    #("scenery", "Scenery (*.scenery)|*.scenery"),
    #("device_machine", "Device Machine (*.device_machine)|*.device_machine")
)

-- True for a Point made by import_object.ms (it has the tag panel)
fn isObjectTagContainer obj = isValidNode obj and (try (obj.fieldKeys != undefined) catch (false))

-- Returns true when the tag was written (errors are in the log)
fn exportObjectFile container tagPath =
(
    local keys = container.fieldKeys
    local values = container.fieldValues
    local f = luaOpenTagInput "object" 1
    luaWriteString f container.tagGroup
    luaWriteInt f keys.count
    for i = 1 to keys.count do
    (
        luaWriteString f keys[i]
        luaWriteString f values[i]
    )
    luaWriteTag f "object" tagPath
)

fn ExportObject =
(
    if selection.count != 1 or not (isObjectTagContainer selection[1]) then
    (
        messageBox "Select the Point of an imported object tag (e.g. warthog.vehicle)." title:"Export Object Tag"
        return undefined
    )
    local container = selection[1]

    -- warthog.vehicle -> vehicle
    local group = substring (getFilenameType container.name) 2 -1
    local typeEntry = undefined
    for t in objectExportTypes where t[1] == group do typeEntry = t
    if typeEntry == undefined then
    (
        messageBox ("The Point's name must end with the tag class, e.g. warthog.vehicle.\n\n" + \
                    "Supported: .biped, .vehicle, .weapon, .scenery, .device_machine") title:"Export Object Tag"
        return undefined
    )
    if group != container.tagGroup then
    (
        messageBox ("This Point holds " + container.tagGroup + " fields, so its name must end with ." + \
                    container.tagGroup) title:"Export Object Tag"
        return undefined
    )

    local defaultPath = (getFilenamePath container.tagFile) + container.name
    local tagPath = getSaveFileName caption:"Save Halo CE Object Tag" filename:defaultPath \
        types:(typeEntry[2] + "|All Files (*.*)|*.*") historyCategory:"HaloCEObject"
    if tagPath == undefined then
    (
        logger.warn "Export cancelled by user.\n"
        return undefined
    )

    local startTime = timestamp()
    local ok = exportObjectFile container tagPath
    local elapsedTime = (timestamp() - startTime) / 1000.
    if not ok then
    (
        messageBox "Failed to write the tag! See the log for details." title:"Export Failed"
        return undefined
    )

    logger.info "Written: '{}' in {} seconds" args:#(tagPath, elapsedTime)
    logger.log "Object export complete\n\n"

    local showDialogs = configManager.getBool "feedback" "show_completion_dialogs" true
    if showDialogs then
    (
        messageBox ("Object tag exported successfully!\n\n" + \
                    "File: " + (filenameFromPath tagPath) + "\n" + \
                    "Time: " + (formattedPrint elapsedTime format:".3f") + " seconds") \
                    title:"Export Complete" \
                    beep:false
    )
    tagPath
)

-- Tests set importerNoAutoRun = true to load these functions without exporting.
global importerNoAutoRun
if importerNoAutoRun != true do ExportObject()
