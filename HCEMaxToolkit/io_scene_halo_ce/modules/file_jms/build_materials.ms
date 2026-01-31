----------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
----------------------------------------------------------------------------

-------------------------------------------------------
-- JMS MATERIAL BUILDER MODULE
-------------------------------------------------------

-- Build materials from JMS shader data
fn buildMaterials jmsData tagsPath dataPath =
(
	if jmsData.shaderCount == 0 then
	(
		logger "No shaders defined, creating default material..." logType: #info
		
		-- Create a single default material
		local mat = StandardMaterial()
		mat.name = "Default"
		mat.diffuse = color 180 180 180
		mat.twoSided = false
		
		return mat
	)
	
	logger ("Building " + jmsData.shaderCount as string + " materials...") logType: #info
	
	-- Create multi/sub-object material
	local multiMat = MultiMaterial numsubs:jmsData.shaderCount
	multiMat.name = "JMS Materials"
	
	for i = 1 to jmsData.shaderCount do
	(
		local shaderData = jmsData.shaders[i]
		local shaderName = shaderData.shaderName
		local shaderPath = shaderData.shaderPath
		
		-- Create standard material
		local mat = StandardMaterial()
		mat.name = shaderName
		mat.diffuse = color 180 180 180
		mat.specular = color 128 128 128
		mat.ambient = color 64 64 64
		mat.twoSided = false
		
		-- Check if we have extended metadata with bitmap paths
		local bitmapPath = undefined
		if jmsData.shaderBitmaps != undefined and i <= jmsData.shaderBitmaps.count then
		(
			local pathFromMetadata = jmsData.shaderBitmaps[i]
			--logger ("  Shader " + i as string + " (" + shaderName + ") metadata path: " + pathFromMetadata as string) logType: #info
			if pathFromMetadata != undefined and pathFromMetadata != "<none>" and pathFromMetadata != "" then
				bitmapPath = pathFromMetadata
		)
		else
		(
			logger ("  No extended metadata for shader " + i as string) logType: #info
		)
		
		-- If we have a bitmap path from extended metadata, use it
		if bitmapPath != undefined and doesFileExist bitmapPath then
		(
			--logger ("  Applying bitmap: " + bitmapPath) logType: #info
			mat.diffuseMap = Bitmaptexture filename:bitmapPath
			mat.showInViewport = true
		)
		-- Otherwise, try to find texture from shader path
		else if tagsPath != undefined and dataPath != undefined and shaderPath != "" then
		(
			local texturePath = findShaderTexture shaderPath tagsPath dataPath
			if texturePath != undefined and doesFileExist texturePath then
			(
				mat.diffuseMap = Bitmaptexture filename:texturePath
				mat.showInViewport = true
			)
			else
			(
				-- Apply checker pattern if no texture found
				local checkerMap = Checker()
				checkerMap.color1 = color 25 25 25    --#191919
				checkerMap.color2 = color 136 136 136  --#888888
				checkerMap.coordinates.U_Tiling = 10.0
				checkerMap.coordinates.V_Tiling = 10.0
				
				mat.diffusemap = checkerMap
				mat.showInViewport = true
			)
		)
		else
		(
			-- Apply checker pattern by default
			local checkerMap = Checker()
			checkerMap.color1 = color 25 25 25    --#191919
			checkerMap.color2 = color 136 136 136  --#888888
			checkerMap.coordinates.U_Tiling = 10.0
			checkerMap.coordinates.V_Tiling = 10.0
			
			mat.diffusemap = checkerMap
			mat.showInViewport = true
		)
		
		-- Assign to multi-material
		multiMat[i] = mat
		multiMat.names[i] = shaderName
		multiMat.materialIDList[i] = i
	)
	
	logger "Materials built successfully!" logType: #success
	
	return multiMat
)

-- Find texture file from shader path
fn findShaderTexture shaderPath tagsPath dataPath =
(
	-- shaderPath format: "shaders\shader_name"
	-- Try to find corresponding bitmap
	
	-- Remove "shaders\" prefix if present
	local cleanPath = shaderPath
	if matchPattern cleanPath pattern:"shaders\\*" then
		cleanPath = substring cleanPath 9 -1
	
	-- Common texture extensions
	local extensions = #(".tif", ".tiff", ".tga", ".png", ".bmp", ".dds")
	
	-- Search in data\bitmaps folder
	local bitmapsPath = dataPath + "\\bitmaps\\"
	
	for ext in extensions do
	(
		local texPath = bitmapsPath + cleanPath + ext
		if doesFileExist texPath then
			return texPath
	)
	
	-- Try without extension
	local texPath = bitmapsPath + cleanPath
	if doesFileExist texPath then
		return texPath
	
	return undefined
)

logger "JMS Material Builder module loaded." logType: #success
