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

-- Custom attribute of a GlyphFX material: every field of its shader tag as text, like the object
-- tag Point (object_tag_ca.ms). The tag editor edits them; GlyphFX parameters are built from them.
-- Loaded at startup (shared\init.ms).

-- Same id always, so saved scenes keep working when this definition changes. No rollout: it
-- would slow the material's UI and Max blocks Python started from it
global haloShaderAttributeDef = attributes "Halo Shader Tag" attribID:#(0x5C3E91A7, 0x1B6D4F22)
(
	parameters shaderTagParams
	(
		tagGroup type:#string default:""
		tagFile type:#string default:""
		fieldKeys type:#stringTab tabSizeVariable:true
		fieldValues type:#stringTab tabSizeVariable:true
	)
)

-- True for a material that keeps its shader tag fields
fn hasShaderTagFields mat = mat != undefined and (try (mat.fieldKeys != undefined and mat.tagGroup != undefined) catch (false))

-- Stores the fields on the material (adds the attribute the first time)
fn setShaderTagFields mat group tagFile keys values =
(
	if not (hasShaderTagFields mat) do custAttributes.add mat haloShaderAttributeDef
	mat.tagGroup = group
	mat.tagFile = if tagFile == undefined then "" else tagFile
	mat.fieldKeys = keys
	mat.fieldValues = values
	ok
)

-- Shader types the tag editor edits: they keep their fields. chicago_extended is not used
-- anymore (chicago instead), so it is only imported
global editableShaderTypes = #("shader_model", "shader_model_extended", "shader_transparent_chicago", \
	"shader_transparent_generic", "shader_transparent_meter", "shader_transparent_water", \
	"shader_transparent_plasma", "shader_transparent_glass", "shader_environment")

-- Shader type of a GlyphFX material from its .fx or .osl file (named after the type); undefined otherwise
fn glyphFxShaderType mat =
(
	local effectFile = glyphFxEffectFile mat
	if effectFile == undefined then return undefined
	local fxName = toLower (getFilenameFile effectFile)
	if findItem editableShaderTypes fxName > 0 then fxName else undefined
)

-- "D:\halo\tags\" from the first texture of the material inside a data folder, "" when none.
-- Finds the bitmaps of a tag not exported yet (it has no tag file). OSL textures are paths
fn shaderMaterialTagsFolder mat =
(
	local holder = glyphFxParamHolder mat
	for p in getPropNames holder where p != #OSLPath do
	(
		local v = try (getProperty holder p) catch (undefined)
		local file = if classOf v == Bitmap or classOf v == BitmapTexture then v.filename else if classOf v == String then v else undefined
		if classOf file == String do
		(
			file = substituteString file "/" "\\"
			local pos = findString (toLower file) "\\data\\"
			if pos != undefined do return (substring file 1 pos) + "tags\\"
		)
	)
	""
)

-- A tag path that tells which tags folder the material's bitmaps are in ("" when unknown)
fn shaderTagPathHint mat =
(
	if mat.tagFile != "" then return mat.tagFile
	local folder = shaderMaterialTagsFolder mat
	if folder == "" then "" else folder + "new." + mat.tagGroup
)

-- From shader_resolver.ms and dx_material_builder.ms, loaded by loadShaderBuilder
global ShaderTextureResult, resolveShaderMaps, applyShaderParams, updateGlyphFxOpacity

-- The importers include the builder; the tag editor can run before any import
fn loadShaderBuilder =
(
	if applyShaderParams == undefined do
	(
		fileIn (rootEngine + "builders\\tag\\shared\\shader_resolver.ms")
		fileIn (rootEngine + "builders\\tag\\shared\\dx_material_builder.ms")
	)
)

-- Sets the GlyphFX parameters again from the stored fields (after a tag editor edit). Lua turns
-- the fields into the data an import reads (importers\shader.lua fromFields). True when it worked
fn applyShaderTagFields mat =
(
	if not (hasShaderTagFields mat) then return false
	loadShaderBuilder()

	local inPath = luaTagInputPath "shaderFields"
	local f = luaOpenTagInput "shaderFields" 1
	luaWriteString f mat.tagGroup
	luaWriteInt f mat.fieldKeys.count
	for i = 1 to mat.fieldKeys.count do
	(
		luaWriteString f mat.fieldKeys[i]
		luaWriteString f mat.fieldValues[i]
	)
	fclose f
	local outPath = luaExportPath "shader"
	deleteFile outPath
	local ran = luaRun "importers.shader" "fromFields" #(inPath, outPath)
	deleteFile inPath
	if not ran then return false

	f = luaOpenOutput outPath "shader" 2
	if f == undefined then return false
	local result = ShaderTextureResult shaderName:mat.name shaderType:mat.tagGroup shaderFilePath:mat.tagFile
	result.shaderEntry = luaReadTuples f
	result.mainEntry = luaReadTuples f
	luaCloseExport f "shader"

	-- Bitmaps are found from the shader tag's own tags folder (shaderTagPathHint)
	resolveShaderMaps result (shaderTagPathHint mat)
	local applied = false
	with undo off
	(
		applied = applyShaderParams mat result
		-- An OSL material may now cut or blend its faces, or stop doing it
		if applied do updateGlyphFxOpacity (refs.dependentNodes mat) onlyMat:mat
	)
	notifyDependents mat
	applied
)

-------------------------------------------------------
-- Tag editor (core\tag_editor\shaders.py)
-------------------------------------------------------

-- GlyphFX materials of some nodes (Multi/Sub-Object included): with tag fields, or made by hand
-- (shaderEditorCreateFields makes them)
fn shaderMaterialsOfNodes nodes =
(
	local materials = #()
	for n in nodes where isValidNode n and n.material != undefined do collectSubMaterials n.material materials
	for m in materials where hasShaderTagFields m or glyphFxShaderType m != undefined collect m
)

-- For the shader list: #(has fields, tag group or the effect's type)
fn shaderEditorListInfo mat =
	if hasShaderTagFields mat then #(true, mat.tagGroup) else #(false, glyphFxShaderType mat)

-- Of an object tag Point (its imported nodes)
fn shaderEditorObjectShaders obj = shaderMaterialsOfNodes obj.memberNodes

-- Of the one selected node: an object tag Point (its imported nodes) or a mesh. Empty otherwise
fn shaderEditorSelectionShaders =
(
	if selection.count != 1 then return #()
	if isObjectTagContainer selection[1] then shaderEditorObjectShaders selection[1] else shaderMaterialsOfNodes #(selection[1])
)

-- #(material id, name, tag group, tag file, keys, values, tags folder of its bitmaps for a new tag)
fn shaderEditorFields mat =
(
	local keys = for k in mat.fieldKeys collect k
	local values = for v in mat.fieldValues collect v
	local folder = if mat.tagFile == "" then shaderMaterialTagsFolder mat else ""
	#(getHandleByAnim mat, mat.name, mat.tagGroup, mat.tagFile, keys, values, folder)
)

-- Build Shaders' reader (readDxMaterialShaderFields), loaded when first needed
global readDxMaterialShaderFields

-- "Create Tag Fields" for a GlyphFX material made by hand: what the material has (Build Shaders'
-- reader) plus every other field of the tag, zero (importers\shader.lua fromMax). Undoable.
-- Returns #(ok, warnings)
fn shaderEditorCreateFields mat =
(
	local group = glyphFxShaderType mat
	if group == undefined then return #(false, #("not a GlyphFX material"))
	if readDxMaterialShaderFields == undefined do
		fileIn (rootEngine + "pipeline\\create_tag\\create_shader.ms")
	local reader = readDxMaterialShaderFields mat group
	if reader == undefined then return #(false, #("unsupported shader type " + group))

	local inPath = luaTagInputPath "shader"
	local f = luaOpenTagInput "shader" 1
	luaWriteString f group
	luaWriteInt f reader.keys.count
	for i = 1 to reader.keys.count do
	(
		luaWriteString f reader.keys[i]
		luaWriteString f reader.values[i]
	)
	fclose f
	local outPath = luaExportPath "shaderFields"
	deleteFile outPath
	local ran = luaRun "importers.shader" "fromMax" #(inPath, outPath)
	deleteFile inPath
	if not ran then return #(false, #("Lua could not make the fields (see the log)"))

	f = luaOpenOutput outPath "shaderFields" 1
	if f == undefined then return #(false, #("Lua could not make the fields (see the log)"))
	readString f  -- group, the same
	local keys = #()
	local values = #()
	for i = 1 to (luaReadInt f) do
	(
		append keys (readString f)
		append values (readString f)
	)
	luaCloseExport f "shaderFields"

	undo "Create Shader Tag Fields" on setShaderTagFields mat group "" keys values
	#(true, reader.warnings)
)

-- The objects whose nodes use the material show their change colors on it again (change_colors.ms):
-- a shader edit can change which one it takes ("change color source")
fn applyShaderChangeColors mat =
(
	for p in helpers where isObjectTagContainer p do
	(
		local materials = #()
		for n in p.memberNodes where isValidNode n and n.material != undefined do collectSubMaterials n.material materials
		if findItem materials mat > 0 do applyObjectChangeColors p
	)
	ok
)

-- Stores one field (undoable) and sets the GlyphFX parameters again. False when the key is not there
fn shaderEditorSetField mat key text =
(
	local keys = for k in mat.fieldKeys collect k
	local i = findItem keys key
	if i == 0 then return false
	undo "Edit Shader Field" on mat.fieldValues[i] = text
	applyShaderTagFields mat
	applyShaderChangeColors mat
	redrawViews()
	true
)

-- Replaces every field (block elements added, duplicated or deleted), as one undo step
fn shaderEditorSetFields mat keys values =
(
	local keyTexts = for k in keys collect (k as string)
	local valueTexts = for v in values collect (v as string)
	undo "Edit Shader Block" on
	(
		mat.fieldKeys = keyTexts
		mat.fieldValues = valueTexts
	)
	applyShaderTagFields mat
	applyShaderChangeColors mat
	redrawViews()
	true
)

-- Writes the stored fields as the shader tag: lua\exporters\shader.lua takes them as they are.
-- Also used by Build Shaders. True when the tag was written (errors are in the log)
fn writeShaderTagFields mat tagPath =
(
	local f = luaOpenTagInput "shader" 1
	luaWriteString f mat.tagGroup
	luaWriteInt f mat.fieldKeys.count
	for i = 1 to mat.fieldKeys.count do
	(
		luaWriteString f mat.fieldKeys[i]
		luaWriteString f mat.fieldValues[i]
	)
	luaWriteTag f "shader" tagPath
)

-- "Export Tag..." of the shader view. Always asks where to save (starts at the imported tag, or
-- for a new one at the tags folder of its bitmaps). Returns the written path, or undefined
fn shaderEditorExport mat =
(
	local group = mat.tagGroup
	local fileName = mat.name
	if getFilenameType fileName != ("." + group) do fileName += "." + group
	local folder = if mat.tagFile != "" then getFilenamePath mat.tagFile else shaderMaterialTagsFolder mat
	local tagPath = getSaveFileName caption:"Export Halo CE Shader Tag" \
		filename:(folder + fileName) \
		types:((substituteString group "_" " ") + " (*." + group + ")|*." + group + "|All Files (*.*)|*.*") \
		historyCategory:"HaloCEShader"
	if tagPath == undefined then return undefined
	if getFilenameType tagPath != ("." + group) do tagPath += "." + group

	local startTime = timestamp()
	if not (writeShaderTagFields mat tagPath) then
	(
		messageBox "Failed to write the tag! See the log for details." title:"Export Failed"
		return undefined
	)
	-- The next export starts here
	with undo off mat.tagFile = tagPath
	logger.info "Written: '{}' in {} seconds" args:#(tagPath, (timestamp() - startTime) / 1000.)
	if configManager.getBool "feedback" "show_completion_dialogs" true do
		messageBox ("Shader tag exported successfully!\n\nFile: " + (filenameFromPath tagPath)) title:"Export Complete" beep:false
	tagPath
)

-- After undo / redo the fields changed but the parameters did not
fn shaderEditorApply mat = (applyShaderTagFields mat; applyShaderChangeColors mat; redrawViews(); ok)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
