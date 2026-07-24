------------------------------------------------------------------------------------------------
--	Copyright (C) 2026 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but MERCHANTABILITY ANY WARRANTY; without the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

-- Shared Viewport Material Builder
-- Turns a resolved ShaderTextureResult (see shader_resolver.ms) into a single Max
-- material for one shader slot: a GlyphFX DirectX material when supported/enabled,
-- otherwise a StandardMaterial with the resolved texture (or a checker placeholder
-- when nothing could be resolved). Shared by every tag importer that assigns one
-- material per shader reference (gbxmodel, scenario_structure_bsp, and future JMS).
-- Requires shader_resolver.ms and dx_material_builder.ms to be included first.

fn buildShaderViewportMaterial textureResult shaderName useDxMaterials:true =
(
	if textureResult != undefined then
		logger.debug "Material '{}': textureFilePath: '{}'" args:#(shaderName, textureResult.textureFilePath)

	-- Try a GlyphFX DirectX material first (fills every field from the parsed tag)
	local subMat = undefined
	if useDxMaterials and textureResult != undefined then
		subMat = buildDxMaterialForShader textureResult
	local isDxMaterial = (subMat != undefined)
	if not isDxMaterial then
	(
		subMat = StandardMaterial()
		subMat.showInViewport = true
	)

	if not isDxMaterial and textureResult != undefined and textureResult.success and doesFileExist textureResult.textureFilePath then
	(
		logger.debug "Applying texture {} to material: '{}'" args:#((getFilenameFile textureResult.textureFilePath + getFilenameType textureResult.textureFilePath), shaderName)
		local diffuseMap = Bitmaptexture fileName:textureResult.textureFilePath
		subMat.diffusemap = diffuseMap
		subMat.showInViewport = true

		-- For transparent shaders, apply texture to opacity channel
		local shaderType = textureResult.shaderType
		if shaderType == "shader_transparent_glass" or \
			shaderType == "shader_transparent_chicago" or \
			shaderType == "shader_transparent_chicago_extended" or \
			shaderType == "shader_transparent_generic" then
		(
			local opacityMap = Bitmaptexture fileName:textureResult.textureFilePath
			opacityMap.alphaSource = 2  -- Use image alpha
			subMat.opacitymap = opacityMap
		)
		else if shaderType == "shader_transparent_meter" or \
			shaderType == "shader_transparent_water" then
		(
			local opacityMap = Bitmaptexture fileName:textureResult.textureFilePath
			opacityMap.rgbOutput = 1
			subMat.opacitymap = opacityMap
		)
	)
	else if not isDxMaterial then
	(
		-- Apply checker pattern for missing textures
		if textureResult == undefined then
			logger.warn "Material '{}': No texture result ('applying checker')" args:#(shaderName)
		else if not textureResult.success then
			logger.warn "Material '{}': Texture resolution failed ('applying checker')" args:#(shaderName)
		else if textureResult.textureFilePath == undefined then
			logger.warn "Material '{}': No texture file path ('applying checker')" args:#(shaderName)
		else
			logger.warn "Material '{}': Texture file not found ('applying checker'): {}" args:#(shaderName, textureResult.textureFilePath)

		local checkerMap = Checker()
		checkerMap.color1 = color 25 25 25    -- #191919
		checkerMap.color2 = color 136 136 136  -- #888888
		checkerMap.coordinates.U_Tiling = 10.0
		checkerMap.coordinates.V_Tiling = 10.0

		subMat.diffusemap = checkerMap
		subMat.showInViewport = true
	)

	subMat.name = shaderName
	return subMat
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
