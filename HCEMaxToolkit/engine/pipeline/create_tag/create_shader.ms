------------------------------------------------------------------------------------------------
--	Copyright (C) 2026 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

-- GlyphFX DirectX material -> shader tag fields (inverse of builders\tag\shared\dx_material_builder.ms),
-- written by lua\exporters\shader.lua. Viewport-only parameters have no tag field and are ignored.

-------------------------------------------------------
-- Shader type detection
-------------------------------------------------------

-- FourCC name tags accepted in material names ("armor #soso")
global _shaderFourCCs = #("soso", "sose", "schi", "scex", "sotr", "sgla", "smet", "swat", "spla", "senv")

-- Effect file each shader type is previewed with (chicago_extended shares chicago's)
fn shaderTypeToFxName shaderType =
(
	case shaderType of
	(
		"shader_transparent_chicago_extended": "shader_transparent_chicago"
		default: shaderType
	)
)

-- Shader type of a DirectX material's effect file, or undefined for non-GlyphFX effects
fn shaderTypeFromFxFile fxFile =
(
	if fxFile == undefined or fxFile == "" then return undefined
	local fxName = toLower (getFilenameFile fxFile)
	local known = #("shader_model", "shader_model_extended", "shader_transparent_chicago", "shader_transparent_generic", "shader_transparent_glass", \
		"shader_transparent_meter", "shader_transparent_water", "shader_transparent_plasma", "shader_environment")
	if (findItem known fxName) > 0 then fxName else undefined
)

-- FourCC tag found in a material name ("armor #soso" -> "soso"), or undefined
fn findShaderFourCCInName matName =
(
	local lowerName = toLower matName
	for fcc in _shaderFourCCs where (findString lowerName ("#" + fcc)) != undefined do return fcc
	undefined
)

-- Tag file name from a material name: FourCC tag removed, invalid file name characters replaced
fn shaderTagNameFromMaterialName matName =
(
	local tagName = matName
	local fcc = findShaderFourCCInName matName
	if fcc != undefined then
	(
		local pos = findString (toLower tagName) ("#" + fcc)
		tagName = replace tagName pos (fcc.count + 1) ""
	)
	local invalidChars = "\\/:*?\"<>|"
	for i = 1 to tagName.count where (findString invalidChars tagName[i]) != undefined do
		tagName[i] = "_"
	trimLeft (trimRight tagName)
)

-------------------------------------------------------
-- Bitmap references
-------------------------------------------------------

-- Texture file -> bitmap tag reference: everything up to and including "\data\" and the
-- extension are dropped ("D:\halo\data\test\bitmaps\a.png" -> "test\bitmaps\a").
-- Returns undefined if the file isn't inside a data folder.
fn textureFileToBitmapRef filePath =
(
	if filePath == undefined or filePath == "" then return undefined
	local p = substituteString filePath "/" "\\"
	local pos = findString (toLower p) "\\data\\"
	if pos == undefined then return undefined
	local rel = substring p (pos + 6) -1
	(getFilenamePath rel) + (getFilenameFile rel)
)

-------------------------------------------------------
-- Material reader
-------------------------------------------------------

-- 9 digits keep 32-bit floats exact
fn _shaderFloatText v = formattedPrint (v as float) format:".9g"

-- Collects the tag fields of one DirectX material as key/text pairs
struct DxShaderReader
(
	dxMat,
	keys = #(),
	values = #(),
	warnings = #(),

	fn getParam p =
	(
		if not (isProperty dxMat p) then return undefined
		try (getProperty dxMat p) catch (undefined)
	),

	-- A key set again keeps the last text
	fn addField key text =
	(
		local i = findItem keys key
		if i == 0 then
		(
			append keys key
			append values text
		)
		else values[i] = text
	),

	fn fieldFloat p key =
	(
		local v = getParam p
		if v != undefined then addField key (_shaderFloatText v)
	),

	fn fieldInt p key =
	(
		local v = getParam p
		if v != undefined then addField key ((v as integer) as string)
	),

	-- Enums are written as their index
	fn fieldEnum p key = fieldInt p key,

	-- New tags start with every bit cleared, so only set bits are added
	fn fieldFlag p key bitIndex =
	(
		if (getParam p) != true then return undefined
		local i = findItem keys key
		local bits = if i == 0 then 0 else (values[i] as integer)
		addField key ((bit.set bits bitIndex true) as string)
	),

	-- Max colors are 0-255, tag colors 0-1 (inverse of tagColorToMaxColor)
	fn _colorComponents v =
	(
		case classOf v of
		(
			Color:  #(v.r / 255.0, v.g / 255.0, v.b / 255.0, v.a / 255.0)
			Point4: #(v.x, v.y, v.z, v.w)
			Point3: #(v.x, v.y, v.z, 1.0)
			default: undefined
		)
	),

	fn _floatsText list =
	(
		local text = ""
		for i = 1 to list.count do text += (if i > 1 then " " else "") + _shaderFloatText list[i]
		text
	),

	fn fieldRGB p key =
	(
		local c = _colorComponents (getParam p)
		if c != undefined then addField key (_floatsText #(c[1], c[2], c[3]))
	),

	-- ARGB: the effects expose the alpha as a separate 0-1 slider (alphaParam)
	fn fieldARGB p alphaParam key =
	(
		local c = _colorComponents (getParam p)
		if c == undefined then return undefined
		local a = getParam alphaParam
		if a == undefined then a = c[4]
		addField key (_floatsText #(a, c[1], c[2], c[3]))
	),

	-- point2d / vector2d from a U/V float pair (float2 params aren't scriptable)
	fn fieldPoint2 pU pV key =
	(
		local u = getParam pU
		local v = getParam pV
		if u != undefined and v != undefined then addField key (_floatsText #(u, v))
	),

	fn fieldVector3 pI pJ pK key =
	(
		local i = getParam pI
		local j = getParam pJ
		local k = getParam pK
		if i != undefined and j != undefined and k != undefined then
			addField key (_floatsText #(i, j, k))
	),

	-- Texture param -> bitmap reference. A texture switched off with its enable param
	-- is skipped, as the builder disables slots without a texture.
	fn fieldBitmap texParam key enableParam:undefined =
	(
		if enableParam != undefined and (getParam enableParam) == false then return undefined
		local tex = getParam texParam
		if tex == undefined then return undefined
		local filePath = try (tex.filename) catch (undefined)
		if filePath == undefined or filePath == "" then return undefined
		local ref = textureFileToBitmapRef filePath
		if ref == undefined then
		(
			append warnings ("'" + key + "': texture is not inside a data folder, reference left empty (" + filePath + ")")
			return undefined
		)
		addField key ("bitm:" + ref)
	),

	fn addBlock blockKey count = if count > 0 then addField blockKey (count as string),

	-- Number of block entries: the highest enabled entry (firstAlwaysOn: entry 1 needs no enable flag)
	fn countEnabled enablePrefix firstIdx lastIdx firstAlwaysOn:true =
	(
		local count = 0
		for n = firstIdx to lastIdx do
		(
			local enabled = if firstAlwaysOn and n == firstIdx then true else (getParam ((enablePrefix + (n as string)) as name)) == true
			if enabled then count = n - firstIdx + 1
		)
		count
	)
)

-------------------------------------------------------
-- Shared blocks
-------------------------------------------------------

-- Parent 'shader' struct (inverse of _dxApplyBaseShaderParams)
fn _readBaseShaderFields r =
(
	r.fieldFlag #SimpleParameterization "shader.flags" 1
	r.fieldFlag #IgnoreNormals "shader.flags" 2
	r.fieldFlag #TransparentLit "shader.flags" 3
	r.fieldEnum #DetailLevel "shader.detailLevel"
	r.fieldFloat #Power "shader.power"
	r.fieldRGB #ColorOfEmittedLight "shader.colorOfEmittedLight"
	r.fieldRGB #TintColor "shader.tintColor"
	r.fieldEnum #MaterialType "shader.materialType"
)

-- One chicago/generic map entry (inverse of _dxApplyMapStage)
fn _readMapStageFields r blockKey stageIdx layout:#chicago =
(
	local n = stageIdx as string
	local pre = blockKey + "[" + ((stageIdx - 1) as string) + "]."
	local mp = "Map" + n + "_"

	-- Chicago flags: unfiltered, alpha replicate, u-clamped, v-clamped; generic has no alpha replicate
	local clampBit = if layout == #chicago then 3 else 2
	r.fieldFlag ((mp + "Unfiltered") as name) (pre + "flags") 1
	if layout == #chicago then
		r.fieldFlag ((mp + "AlphaReplicate") as name) (pre + "flags") 2
	r.fieldFlag ((mp + "UClamped") as name) (pre + "flags") clampBit
	r.fieldFlag ((mp + "VClamped") as name) (pre + "flags") (clampBit + 1)

	if layout == #chicago then
	(
		r.fieldEnum ((mp + "ColorFunction") as name) (pre + "colorFunction")
		r.fieldEnum ((mp + "AlphaFunction") as name) (pre + "alphaFunction")
	)

	r.fieldFloat ((mp + "UScale") as name) (pre + "mapUScale")
	r.fieldFloat ((mp + "VScale") as name) (pre + "mapVScale")
	r.fieldFloat ((mp + "UOffset") as name) (pre + "mapUOffset")
	r.fieldFloat ((mp + "VOffset") as name) (pre + "mapVOffset")
	r.fieldFloat ((mp + "Rotation") as name) (pre + "mapRotation")
	r.fieldFloat ((mp + "MipmapBias") as name) (pre + "mipmapBias")

	r.fieldBitmap (("Map" + n + "Texture") as name) (pre + "map")

	for axis in #("U", "V", "Rotation") do
	(
		local keyAxis = pre + axis + "Animation"
		r.fieldEnum ((axis + "AnimationSource" + n) as name) (keyAxis + "Source")
		r.fieldEnum ((axis + "AnimationFunction" + n) as name) (keyAxis + "Function")
		r.fieldFloat ((axis + "AnimationPeriod" + n) as name) (keyAxis + "Period")
		r.fieldFloat ((axis + "AnimationPhase" + n) as name) (keyAxis + "Phase")
		r.fieldFloat ((axis + "AnimationScale" + n) as name) (keyAxis + "Scale")
	)
	r.fieldPoint2 (("AnimationCenterU" + n) as name) (("AnimationCenterV" + n) as name) (pre + "rotationAnimationCenter")
)

-- Chicago/generic attributes shared by both groups
fn _readTransparentAttributeFields r =
(
	r.fieldInt #NumericCounterLimit "numericCounterLimit"
	r.fieldFlag #AlphaTested "flags" 1
	r.fieldFlag #Decal "flags" 2
	r.fieldFlag #TwoSided "flags" 3
	r.fieldFlag #FirstMapIsScreenspace "flags" 4
	r.fieldFlag #DrawBeforeWater "flags" 5
	r.fieldFlag #IgnoreEffect "flags" 6
	r.fieldFlag #ScaleFirstMapWithDistance "flags" 7
	r.fieldFlag #Numeric "flags" 8
	r.fieldEnum #FirstMapType "firstMapType"
	r.fieldEnum #FramebufferBlendFunction "framebufferBlendFunction"
	r.fieldEnum #FramebufferFadeMode "framebufferFadeMode"
	r.fieldEnum #FramebufferFadeSource "framebufferFadeSource"
	r.fieldFloat #LensFlareSpacing "lensFlareSpacing"
)

-------------------------------------------------------
-- shader_model
-------------------------------------------------------
fn readShaderModelFields r =
(
	_readBaseShaderFields r

	r.fieldFlag #DetailAfterReflection "flags" 1
	r.fieldFlag #TwoSided "flags" 2
	r.fieldFlag #NotAlphaTested "flags" 3
	r.fieldFlag #AlphaBlendedDecal "flags" 4
	r.fieldFlag #TrueAtmosphericFog "flags" 5
	r.fieldFlag #DisableTwoSidedCulling "flags" 6
	r.fieldFlag #UseXboxChannelOrder "flags" 7

	r.fieldFloat #Translucency "translucency"
	r.fieldEnum #ChangeColorSource "changeColorSource"

	-- Self illumination
	r.fieldFlag #NoRandomPhaseFlag "flags2" 1
	r.fieldEnum #SelfIlluminationColorSource "colorSource"
	r.fieldEnum #SelfIlluminationAnimationFunction "animationFunction"
	r.fieldFloat #SelfIlluminationAnimationPeriod "animationPeriod"
	r.fieldRGB #AnimationColorLowerBound "animationColorLowerBound"
	r.fieldRGB #AnimationColorUpperBound "animationColorUpperBound"

	-- Maps
	r.fieldFloat #MapUScale "mapUScale"
	r.fieldFloat #MapVScale "mapVScale"
	r.fieldBitmap #BaseMapTexture "baseMap" enableParam:#EnableBaseMap
	r.fieldBitmap #MultipurposeMapTexture "multipurposeMap" enableParam:#EnableMultipurposeMap
	r.fieldEnum #DetailFunction "detailFunction"
	r.fieldEnum #DetailMask "detailMask"
	r.fieldFloat #DetailMapScale "detailMapScale"
	r.fieldBitmap #DetailMapTexture "detailMap" enableParam:#EnableDetailMap
	r.fieldFloat #DetailMapVScale "detailMapVScale"

	-- Texture animation
	for axis in #("U", "V", "Rotation") do
	(
		local keyAxis = axis + "Animation"
		r.fieldEnum ((axis + "AnimationSource") as name) (keyAxis + "Source")
		r.fieldEnum ((axis + "AnimationFunction") as name) (keyAxis + "Function")
		r.fieldFloat ((axis + "AnimationPeriod") as name) (keyAxis + "Period")
		r.fieldFloat ((axis + "AnimationPhase") as name) (keyAxis + "Phase")
		r.fieldFloat ((axis + "AnimationScale") as name) (keyAxis + "Scale")
	)
	r.fieldPoint2 #RotationAnimationCenterX #RotationAnimationCenterY "rotationAnimationCenter"

	-- Reflection
	r.fieldFloat #PerpendicularBrightness "perpendicularBrightness"
	r.fieldRGB #PerpendicularTintColor "perpendicularTintColor"
	r.fieldFloat #ParallelBrightness "parallelBrightness"
	r.fieldRGB #ParallelTintColor "parallelTintColor"
	r.fieldBitmap #ReflectionCubeTexture "reflectionCubeMap" enableParam:#EnableReflectionCube
)

-------------------------------------------------------
-- shader_model_extended
-------------------------------------------------------
-- EnableExtended is a viewport-only comparison toggle, so the extension is always written
fn readShaderModelExtendedFields r =
(
	readShaderModelFields r

	-- Detail map 2
	r.fieldEnum #Detail2Function "detail2Function"
	r.fieldEnum #Detail2Mask "detail2Mask"
	r.fieldFloat #Detail2MapScale "detail2MapScale"
	r.fieldBitmap #Detail2MapTexture "detail2Map" enableParam:#EnableDetail2Map
	r.fieldFloat #Detail2MapVScale "detail2MapVScale"

	-- Bump
	r.fieldBitmap #BaseNormalMapTexture "baseNormalMap" enableParam:#EnableBaseNormalMap
	r.fieldFloat #BaseNormalCoefficient "baseNormalCoefficient"
	for n in #("1", "2") do
	(
		local pre = "DetailNormal" + n
		r.fieldBitmap ((pre + "MapTexture") as name) (pre + "Map") enableParam:((("Enable" + pre + "Map") as name))
		r.fieldFloat ((pre + "Coefficient") as name) (pre + "Coefficient")
		r.fieldFloat ((pre + "Scale") as name) (pre + "Scale")
		r.fieldFloat ((pre + "VScale") as name) (pre + "VScale")
	)

	-- Specular
	r.fieldBitmap #SpecularColorMapTexture "specularColorMap" enableParam:#EnableSpecularColorMap
	r.fieldFloat #SpecularColorCoefficient "specularColorCoefficient"
	r.fieldFloat #SpecularColorExponent "specularColorExponent"
	r.fieldFlag #AlphaAsExponentMask "specularColorFlags" 1
	r.fieldFloat #SpecularLightingExponent "specularLightingExponent"
	r.fieldFloat #SpecularLightingCoefficient "specularLightingCoefficient"
	r.fieldFlag #DoNotUseDlmsBsp "diffuseLightingFlags" 1
)

-------------------------------------------------------
-- shader_transparent_chicago (+ chicago_extended)
-------------------------------------------------------

-- mapsKey: "maps" for chicago, "4StageMaps" for chicago_extended
-- (its 2-stage block is legacy-hardware fallback data and stays empty)
fn readShaderChicagoFields r mapsKey =
(
	_readBaseShaderFields r
	_readTransparentAttributeFields r

	r.fieldFlag #DontFadeActiveCamouflage "extraFlags" 1
	r.fieldFlag #NumericCountdownTimer "extraFlags" 2
	r.fieldFlag #CustomEditionBlending "extraFlags" 3

	local mapCount = r.countEnabled "EnableMap" 1 4
	r.addBlock mapsKey mapCount
	for j = 1 to mapCount do
		_readMapStageFields r mapsKey j layout:#chicago
)

-------------------------------------------------------
-- shader_transparent_generic
-------------------------------------------------------

-- One combiner stage (inverse of _dxApplyGenericCombinerStage). The stage repeats its
-- field names: color side first, then alpha side ("inputA2")
fn _readGenericCombinerStageFields r stageIdx =
(
	local pre = "Stage" + (stageIdx as string) + "_"
	local key = "stages[" + ((stageIdx - 1) as string) + "]."

	r.fieldFlag ((pre + "ColorMux") as name) (key + "flags") 1
	r.fieldFlag ((pre + "AlphaMux") as name) (key + "flags") 2
	r.fieldFlag ((pre + "AOutControlsColor0Animation") as name) (key + "flags") 3

	r.fieldEnum ((pre + "Color0Source") as name) (key + "color0Source")
	r.fieldEnum ((pre + "Color0AnimationFunction") as name) (key + "color0AnimationFunction")
	r.fieldFloat ((pre + "Color0AnimationPeriod") as name) (key + "color0AnimationPeriod")
	r.fieldARGB ((pre + "Color0AnimationLowerBound") as name) ((pre + "Color0LowerAlpha") as name) (key + "color0AnimationLowerBound")
	r.fieldARGB ((pre + "Color0AnimationUpperBound") as name) ((pre + "Color0UpperAlpha") as name) (key + "color0AnimationUpperBound")
	r.fieldARGB ((pre + "Color1") as name) ((pre + "Color1Alpha") as name) (key + "color1")

	for side in #(#("Color", ""), #("Alpha", "2")) do
	(
		local p = pre + side[1]
		local suffix = side[2]
		for inp in #("A", "B", "C", "D") do
		(
			r.fieldEnum ((p + "Input" + inp) as name) (key + "input" + inp + suffix)
			r.fieldEnum ((p + "Input" + inp + "Mapping") as name) (key + "input" + inp + "Mapping" + suffix)
		)
		r.fieldEnum ((p + "OutputAB") as name) (key + "outputAB" + suffix)
		r.fieldEnum ((p + "OutputCD") as name) (key + "outputCD" + suffix)
		r.fieldEnum ((p + "OutputABCDMuxSum") as name) (key + "outputABCDMuxSum" + suffix)
		r.fieldEnum ((p + "OutputMapping") as name) (key + "outputMapping" + suffix)
	)
	-- AB/CD functions exist on the color side only (alpha always multiplies)
	r.fieldEnum ((pre + "ColorOutputABFunction") as name) (key + "outputABFunction")
	r.fieldEnum ((pre + "ColorOutputCDFunction") as name) (key + "outputCDFunction")
)

fn readShaderGenericFields r =
(
	_readBaseShaderFields r
	_readTransparentAttributeFields r

	local mapCount = r.countEnabled "EnableMap" 1 4
	r.addBlock "maps" mapCount
	for j = 1 to mapCount do
		_readMapStageFields r "maps" j layout:#generic

	local stageCount = r.countEnabled "EnableStage" 1 7
	r.addBlock "stages" stageCount
	for j = 1 to stageCount do
		_readGenericCombinerStageFields r j
)

-------------------------------------------------------
-- shader_transparent_meter
-------------------------------------------------------
fn readShaderMeterFields r =
(
	_readBaseShaderFields r

	r.fieldFlag #Decal "flags" 1
	r.fieldFlag #TwoSided "flags" 2
	r.fieldFlag #FlashColorIsNegative "flags" 3
	r.fieldFlag #TintMode2 "flags" 4
	r.fieldFlag #Unfiltered "flags" 5

	r.fieldBitmap #MeterMap "map"
	r.fieldRGB #GradientMinColor "gradientMinColor"
	r.fieldRGB #GradientMaxColor "gradientMaxColor"
	r.fieldRGB #BackgroundColor "backgroundColor"
	r.fieldRGB #FlashColor "flashColor"
	r.fieldRGB #MeterTintColor "tintColor"
	r.fieldFloat #MeterTransparency "meterTransparency"
	r.fieldFloat #BackgroundTransparency "backgroundTransparency"

	-- External sources
	r.fieldEnum #MeterBrightnessSource "meterBrightnessSource"
	r.fieldEnum #FlashBrightnessSource "flashBrightnessSource"
	r.fieldEnum #ValueSource "valueSource"
	r.fieldEnum #GradientSource "gradientSource"
	r.fieldEnum #FlashExtensionSource "flashExtensionSource"
)

-------------------------------------------------------
-- shader_transparent_water
-------------------------------------------------------
fn readShaderWaterFields r =
(
	_readBaseShaderFields r

	r.fieldFlag #BaseMapAlphaModulatesReflection "flags" 1
	r.fieldFlag #BaseMapColorModulatesBackground "flags" 2
	r.fieldFlag #AtmosphericFog "flags" 3
	r.fieldFlag #DrawBeforeFog "flags" 4

	r.fieldBitmap #BaseMapTexture "baseMap" enableParam:#EnableBaseMap
	r.fieldFloat #ViewPerpendicularBrightness "viewPerpendicularBrightness"
	r.fieldRGB #ViewPerpendicularTintColor "viewPerpendicularTintColor"
	r.fieldFloat #ViewParallelBrightness "viewParallelBrightness"
	r.fieldRGB #ViewParallelTintColor "viewParallelTintColor"
	r.fieldBitmap #ReflectionMapTexture "reflectionMap" enableParam:#EnableReflectionMap

	-- Ripple globals (angles are raw radians, as the builder passes them)
	r.fieldFloat #RippleAnimationAngle "rippleAnimationAngle"
	r.fieldFloat #RippleAnimationVelocity "rippleAnimationVelocity"
	r.fieldFloat #RippleScale "rippleScale"
	r.fieldBitmap #RippleMapsTexture "rippleMaps" enableParam:#EnableRippleMaps
	r.fieldInt #RippleMipmapLevels "rippleMipmapLevels"
	r.fieldFloat #RippleMipmapFadeFactor "rippleMipmapFadeFactor"
	r.fieldFloat #RippleMipmapDetailBias "rippleMipmapDetailBias"

	-- Ripple entries (the effect names them 0-based: Ripple0..Ripple3)
	local rippleCount = r.countEnabled "EnableRipple" 0 3 firstAlwaysOn:false
	r.addBlock "ripples" rippleCount
	for j = 0 to rippleCount - 1 do
	(
		local k = j as string
		local pre = "Ripple" + k + "_"
		local key = "ripples[" + k + "]."
		r.fieldFloat ((pre + "ContributionFactor") as name) (key + "contributionFactor")
		r.fieldFloat ((pre + "AnimationAngle") as name) (key + "animationAngle")
		r.fieldFloat ((pre + "AnimationVelocity") as name) (key + "animationVelocity")
		r.fieldPoint2 ((pre + "MapOffsetU") as name) ((pre + "MapOffsetV") as name) (key + "mapOffset")
		r.fieldInt ((pre + "MapRepeats") as name) (key + "mapRepeats")
		r.fieldInt ((pre + "MapIndex") as name) (key + "mapIndex")
	)
)

-------------------------------------------------------
-- shader_transparent_plasma
-------------------------------------------------------
fn readShaderPlasmaFields r =
(
	_readBaseShaderFields r

	r.fieldEnum #IntensitySource "intensitySource"
	r.fieldFloat #IntensityExponent "intensityExponent"
	r.fieldEnum #OffsetSource "offsetSource"
	r.fieldFloat #OffsetAmount "offsetAmount"
	r.fieldFloat #OffsetExponent "offsetExponent"

	r.fieldFloat #PerpendicularBrightness "perpendicularBrightness"
	r.fieldRGB #PerpendicularTintColor "perpendicularTintColor"
	r.fieldFloat #ParallelBrightness "parallelBrightness"
	r.fieldRGB #ParallelTintColor "parallelTintColor"
	r.fieldEnum #TintColorSource "tintColorSource"

	for noise in #("Primary", "Secondary") do
	(
		r.fieldFloat ((noise + "AnimationPeriod") as name) (noise + "AnimationPeriod")
		r.fieldVector3 ((noise + "AnimationDirectionI") as name) ((noise + "AnimationDirectionJ") as name) \
			((noise + "AnimationDirectionK") as name) (noise + "AnimationDirection")
		r.fieldFloat ((noise + "NoiseMapScale") as name) (noise + "NoiseMapScale")
		r.fieldBitmap ((noise + "NoiseMapTexture") as name) (noise + "NoiseMap") enableParam:((("Enable" + noise + "NoiseMap") as name))
	)
)

-------------------------------------------------------
-- shader_transparent_glass
-------------------------------------------------------
fn readShaderGlassFields r =
(
	_readBaseShaderFields r

	r.fieldFlag #AlphaTested "flags" 1
	r.fieldFlag #Decal "flags" 2
	r.fieldFlag #TwoSided "flags" 3
	r.fieldFlag #BumpMapIsSpecularMask "flags" 4

	-- Background tint
	r.fieldRGB #BackgroundTintColor "backgroundTintColor"
	r.fieldFloat #BackgroundTintMapScale "backgroundTintMapScale"
	r.fieldBitmap #BackgroundTintMapTexture "backgroundTintMap" enableParam:#EnableBackgroundTintMap

	-- Reflection
	r.fieldEnum #ReflectionType "reflectionType"
	r.fieldFloat #ReflPerpendicularBrightness "perpendicularBrightness"
	r.fieldRGB #ReflPerpendicularTintColor "perpendicularTintColor"
	r.fieldFloat #ReflParallelBrightness "parallelBrightness"
	r.fieldRGB #ReflParallelTintColor "parallelTintColor"
	r.fieldBitmap #ReflectionCubeTexture "reflectionMap" enableParam:#EnableReflectionCube

	-- Maps
	r.fieldFloat #BumpMapScale "bumpMapScale"
	r.fieldBitmap #BumpMapTexture "bumpMap" enableParam:#EnableBumpMap
	r.fieldFloat #DiffuseMapScale "diffuseMapScale"
	r.fieldBitmap #DiffuseMapTexture "diffuseMap" enableParam:#EnableDiffuseMap
	r.fieldFloat #DiffuseDetailMapScale "diffuseDetailMapScale"
	r.fieldBitmap #DiffuseDetailMapTexture "diffuseDetailMap" enableParam:#EnableDiffuseDetailMap
	r.fieldFloat #SpecularMapScale "specularMapScale"
	r.fieldBitmap #SpecularMapTexture "specularMap" enableParam:#EnableSpecularMap
	r.fieldFloat #SpecularDetailMapScale "specularDetailMapScale"
	r.fieldBitmap #SpecularDetailMapTexture "specularDetailMap" enableParam:#EnableSpecularDetailMap
)

-------------------------------------------------------
-- shader_environment
-------------------------------------------------------
-- Repeated names: flags (environment, diffuse, self-illumination, specular, reflection), type
fn readShaderEnvironmentFields r =
(
	_readBaseShaderFields r

	r.fieldFlag #AlphaTested "flags" 1
	r.fieldFlag #BumpMapIsSpecularMask "flags" 2
	r.fieldFlag #TrueAtmosphericFog "flags" 3
	r.fieldFlag #BumpAttenuation "flags" 4
	r.fieldEnum #EnvironmentType "type"
	r.fieldFloat #LensFlareSpacing "lensFlareSpacing"

	-- Diffuse
	r.fieldFlag #RescaleDetailMaps "flags2" 1
	r.fieldFlag #RescaleBumpMap "flags2" 2
	r.fieldBitmap #BaseMapTexture "baseMap" enableParam:#EnableBaseMap
	r.fieldEnum #DetailMapFunction "detailMapFunction"
	r.fieldFloat #PrimaryDetailMapScale "primaryDetailMapScale"
	r.fieldBitmap #PrimaryDetailMapTexture "primaryDetailMap" enableParam:#EnablePrimaryDetailMap
	r.fieldFloat #SecondaryDetailMapScale "secondaryDetailMapScale"
	r.fieldBitmap #SecondaryDetailMapTexture "secondaryDetailMap" enableParam:#EnableSecondaryDetailMap
	r.fieldEnum #MicroDetailMapFunction "microDetailMapFunction"
	r.fieldFloat #MicroDetailMapScale "microDetailMapScale"
	r.fieldBitmap #MicroDetailMapTexture "microDetailMap" enableParam:#EnableMicroDetailMap
	r.fieldRGB #MaterialColor "materialColor"

	-- Bump
	r.fieldFloat #BumpMapScale "bumpMapScale"
	r.fieldBitmap #BumpMapTexture "bumpMap" enableParam:#EnableBumpMap

	-- Texture scrolling animation
	for axis in #("U", "V") do
	(
		r.fieldEnum ((axis + "AnimationFunction") as name) (axis + "AnimationFunction")
		r.fieldFloat ((axis + "AnimationPeriod") as name) (axis + "AnimationPeriod")
		r.fieldFloat ((axis + "AnimationScale") as name) (axis + "AnimationScale")
	)

	-- Self-illumination
	r.fieldFlag #unfilteredFlag "flags3" 1
	for light in #("Primary", "Secondary", "Plasma") do
	(
		r.fieldRGB ((light + "OnColor") as name) (light + "OnColor")
		r.fieldRGB ((light + "OffColor") as name) (light + "OffColor")
		r.fieldEnum ((light + "AnimationFunction") as name) (light + "AnimationFunction")
		r.fieldFloat ((light + "AnimationPeriod") as name) (light + "AnimationPeriod")
		r.fieldFloat ((light + "AnimationPhase") as name) (light + "AnimationPhase")
	)
	r.fieldFloat #SelfIlluminationMapScale "mapScale"
	r.fieldBitmap #SelfIlluminationMapTexture "map" enableParam:#EnableSelfIlluminationMap

	-- Specular
	r.fieldFlag #SpecularOverbright "flags4" 1
	r.fieldFlag #SpecularExtraShiny "flags4" 2
	r.fieldFlag #LightmapIsSpecular "flags4" 3
	r.fieldFloat #SpecBrightness "brightness"
	r.fieldRGB #SpecPerpendicularColor "perpendicularColor"
	r.fieldRGB #SpecParallelColor "parallelColor"

	-- Reflection
	r.fieldFlag #DynamicMirror "flags5" 1
	r.fieldEnum #ReflectionType "type2"
	r.fieldFloat #LightmapBrightnessScale "lightmapBrightnessScale"
	r.fieldFloat #ReflPerpendicularBrightness "perpendicularBrightness"
	r.fieldFloat #ReflParallelBrightness "parallelBrightness"
	r.fieldBitmap #ReflectionCubeTexture "reflectionCubeMap" enableParam:#EnableReflectionCube
)

-------------------------------------------------------
-- Dispatcher and writer
-------------------------------------------------------

-- Reads a DirectX material as the given shader type. Returns a DxShaderReader with the
-- collected fields, or undefined for an unsupported type.
fn readDxMaterialShaderFields dxMat shaderType =
(
	local r = DxShaderReader dxMat:dxMat
	case shaderType of
	(
		"shader_model": readShaderModelFields r
		"shader_model_extended": readShaderModelExtendedFields r
		"shader_transparent_chicago": readShaderChicagoFields r "maps"
		"shader_transparent_chicago_extended": readShaderChicagoFields r "4StageMaps"
		"shader_transparent_generic": readShaderGenericFields r
		"shader_transparent_meter": readShaderMeterFields r
		"shader_transparent_water": readShaderWaterFields r
		"shader_transparent_plasma": readShaderPlasmaFields r
		"shader_transparent_glass": readShaderGlassFields r
		"shader_environment": readShaderEnvironmentFields r
		default: return undefined
	)
	r
)

-- Writes the reader's fields as a shader tag. Returns true when it worked (errors are in the log)
fn writeDxShaderTag reader shaderType tagPath =
(
	local f = luaOpenTagInput "shader" 1
	luaWriteString f shaderType
	luaWriteInt f reader.keys.count
	for i = 1 to reader.keys.count do
	(
		luaWriteString f reader.keys[i]
		luaWriteString f reader.values[i]
	)
	luaWriteTag f "shader" tagPath
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
