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

-- GlyphFX DirectX material -> shader tag operations
-- Inverse of builders\tag\shared\dx_material_builder.ms: reads the effect parameters of a
-- DirectX_9_Shader and turns them into invader-edit operations (block inserts + field sets).
-- Field keys are invader-edit's names; parameter names and bit orders mirror the builder.
-- Viewport-only parameters (lights, DebugMode, ChangeColor, SelfIlluminationColor,
-- MeterValue, noise slice counts, cubemap offsets...) have no tag field and are ignored.

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

-- Collects invader-edit operations from one DirectX material.
-- sets entries: #(key, value, isEnum) - enum values stay as indices until the tool
-- resolves them to option names (see parseInvaderEnums in invader_utils.ms)
struct DxShaderReader
(
	dxMat,
	inserts = #(),    -- #(blockKey, count)
	sets = #(),
	warnings = #(),

	fn getParam p =
	(
		if not (isProperty dxMat p) then return undefined
		try (getProperty dxMat p) catch (undefined)
	),

	fn addSet key fieldValue isEnum:false = append sets #(key, fieldValue, isEnum),

	fn fieldFloat p key =
	(
		local v = getParam p
		if v != undefined then addSet key (invaderFloat v)
	),

	fn fieldInt p key =
	(
		local v = getParam p
		if v != undefined then addSet key ((v as integer) as string)
	),

	fn fieldEnum p key =
	(
		local v = getParam p
		if v != undefined then addSet key (v as integer) isEnum:true
	),

	-- New tags start with every bit cleared, so only set bits are written
	fn fieldFlag p key =
	(
		if (getParam p) == true then addSet key "1"
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

	fn fieldRGB p key =
	(
		local c = _colorComponents (getParam p)
		if c != undefined then
			addSet key (invaderFloat c[1] + "," + invaderFloat c[2] + "," + invaderFloat c[3])
	),

	-- ARGB: the effects expose the alpha as a separate 0-1 slider (alphaParam)
	fn fieldARGB p alphaParam key =
	(
		local c = _colorComponents (getParam p)
		if c == undefined then return undefined
		local a = getParam alphaParam
		if a == undefined then a = c[4]
		addSet key (invaderFloat a + "," + invaderFloat c[1] + "," + invaderFloat c[2] + "," + invaderFloat c[3])
	),

	-- point2d / vector2d from a U/V float pair (float2 params aren't scriptable)
	fn fieldPoint2 pU pV key =
	(
		local u = getParam pU
		local v = getParam pV
		if u != undefined and v != undefined then
			addSet key (invaderFloat u + "," + invaderFloat v)
	),

	fn fieldVector3 pI pJ pK key =
	(
		local i = getParam pI
		local j = getParam pJ
		local k = getParam pK
		if i != undefined and j != undefined and k != undefined then
			addSet key (invaderFloat i + "," + invaderFloat j + "," + invaderFloat k)
	),

	-- Texture param -> bitmap dependency. A texture switched off with its enable param
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
		addSet key (ref + ".bitmap")
	),

	fn addInsert blockKey count = if count > 0 then append inserts #(blockKey, count),

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

-- Parent 'shader' block (inverse of _dxApplyBaseShaderParams)
fn _readBaseShaderOps r =
(
	r.fieldFlag #SimpleParameterization "shader_flags.simple_parameterization"
	r.fieldFlag #IgnoreNormals "shader_flags.ignore_normals"
	r.fieldFlag #TransparentLit "shader_flags.transparent_lit"
	r.fieldEnum #DetailLevel "detail_level"
	r.fieldFloat #Power "power"
	r.fieldRGB #ColorOfEmittedLight "color_of_emitted_light"
	r.fieldRGB #TintColor "tint_color"
	r.fieldEnum #MaterialType "material_type"
)

-- One chicago/generic map entry (inverse of _dxApplyMapStage)
fn _readMapStageOps r blockKey stageIdx layout:#chicago =
(
	local n = stageIdx as string
	local pre = blockKey + "[" + ((stageIdx - 1) as string) + "]."
	local mp = "Map" + n + "_"

	r.fieldFlag ((mp + "Unfiltered") as name) (pre + "flags.unfiltered")
	if layout == #chicago then
		r.fieldFlag ((mp + "AlphaReplicate") as name) (pre + "flags.alpha_replicate")
	r.fieldFlag ((mp + "UClamped") as name) (pre + "flags.u_clamped")
	r.fieldFlag ((mp + "VClamped") as name) (pre + "flags.v_clamped")

	if layout == #chicago then
	(
		r.fieldEnum ((mp + "ColorFunction") as name) (pre + "color_function")
		r.fieldEnum ((mp + "AlphaFunction") as name) (pre + "alpha_function")
	)

	r.fieldFloat ((mp + "UScale") as name) (pre + "map_u_scale")
	r.fieldFloat ((mp + "VScale") as name) (pre + "map_v_scale")
	r.fieldFloat ((mp + "UOffset") as name) (pre + "map_u_offset")
	r.fieldFloat ((mp + "VOffset") as name) (pre + "map_v_offset")
	r.fieldFloat ((mp + "Rotation") as name) (pre + "map_rotation")
	r.fieldFloat ((mp + "MipmapBias") as name) (pre + "mipmap_bias")

	r.fieldBitmap (("Map" + n + "Texture") as name) (pre + "map")

	for axis in #("U", "V", "Rotation") do
	(
		local keyAxis = if axis == "Rotation" then "rotation" else toLower axis
		r.fieldEnum ((axis + "AnimationSource" + n) as name) (pre + keyAxis + "_animation_source")
		r.fieldEnum ((axis + "AnimationFunction" + n) as name) (pre + keyAxis + "_animation_function")
		r.fieldFloat ((axis + "AnimationPeriod" + n) as name) (pre + keyAxis + "_animation_period")
		r.fieldFloat ((axis + "AnimationPhase" + n) as name) (pre + keyAxis + "_animation_phase")
		r.fieldFloat ((axis + "AnimationScale" + n) as name) (pre + keyAxis + "_animation_scale")
	)
	r.fieldPoint2 (("AnimationCenterU" + n) as name) (("AnimationCenterV" + n) as name) (pre + "rotation_animation_center")
)

-- Chicago/generic attributes shared by both groups
fn _readTransparentAttributeOps r flagsKey =
(
	r.fieldInt #NumericCounterLimit "numeric_counter_limit"
	r.fieldFlag #AlphaTested (flagsKey + ".alpha_tested")
	r.fieldFlag #Decal (flagsKey + ".decal")
	r.fieldFlag #TwoSided (flagsKey + ".two_sided")
	r.fieldFlag #FirstMapIsScreenspace (flagsKey + ".first_map_is_in_screenspace")
	r.fieldFlag #DrawBeforeWater (flagsKey + ".draw_before_water")
	r.fieldFlag #IgnoreEffect (flagsKey + ".ignore_effect")
	r.fieldFlag #ScaleFirstMapWithDistance (flagsKey + ".scale_first_map_with_distance")
	r.fieldFlag #Numeric (flagsKey + ".numeric")
	r.fieldEnum #FirstMapType "first_map_type"
	r.fieldEnum #FramebufferBlendFunction "framebuffer_blend_function"
	r.fieldEnum #FramebufferFadeMode "framebuffer_fade_mode"
	r.fieldEnum #FramebufferFadeSource "framebuffer_fade_source"
	r.fieldFloat #LensFlareSpacing "lens_flare_spacing"
)

-------------------------------------------------------
-- shader_model
-------------------------------------------------------
fn readShaderModelOps r =
(
	_readBaseShaderOps r

	r.fieldFlag #DetailAfterReflection "shader_model_flags.detail_after_reflection"
	r.fieldFlag #TwoSided "shader_model_flags.two_sided"
	r.fieldFlag #NotAlphaTested "shader_model_flags.not_alpha_tested"
	r.fieldFlag #AlphaBlendedDecal "shader_model_flags.alpha_blended_decal"
	r.fieldFlag #TrueAtmosphericFog "shader_model_flags.true_atmospheric_fog"
	r.fieldFlag #DisableTwoSidedCulling "shader_model_flags.disable_two_sided_culling"
	r.fieldFlag #UseXboxChannelOrder "shader_model_flags.use_xbox_multipurpose_channel_order"

	r.fieldFloat #Translucency "translucency"
	r.fieldEnum #ChangeColorSource "change_color_source"

	-- Self illumination
	r.fieldFlag #NoRandomPhaseFlag "shader_model_more_flags.no_random_phase"
	r.fieldEnum #SelfIlluminationColorSource "color_source"
	r.fieldEnum #SelfIlluminationAnimationFunction "animation_function"
	r.fieldFloat #SelfIlluminationAnimationPeriod "animation_period"
	r.fieldRGB #AnimationColorLowerBound "animation_color_lower_bound"
	r.fieldRGB #AnimationColorUpperBound "animation_color_upper_bound"

	-- Maps
	r.fieldFloat #MapUScale "map_u_scale"
	r.fieldFloat #MapVScale "map_v_scale"
	r.fieldBitmap #BaseMapTexture "base_map" enableParam:#EnableBaseMap
	r.fieldBitmap #MultipurposeMapTexture "multipurpose_map" enableParam:#EnableMultipurposeMap
	r.fieldEnum #DetailFunction "detail_function"
	r.fieldEnum #DetailMask "detail_mask"
	r.fieldFloat #DetailMapScale "detail_map_scale"
	r.fieldBitmap #DetailMapTexture "detail_map" enableParam:#EnableDetailMap
	r.fieldFloat #DetailMapVScale "detail_map_v_scale"

	-- Texture animation
	for axis in #("U", "V", "Rotation") do
	(
		local keyAxis = if axis == "Rotation" then "rotation" else toLower axis
		r.fieldEnum ((axis + "AnimationSource") as name) (keyAxis + "_animation_source")
		r.fieldEnum ((axis + "AnimationFunction") as name) (keyAxis + "_animation_function")
		r.fieldFloat ((axis + "AnimationPeriod") as name) (keyAxis + "_animation_period")
		r.fieldFloat ((axis + "AnimationPhase") as name) (keyAxis + "_animation_phase")
		r.fieldFloat ((axis + "AnimationScale") as name) (keyAxis + "_animation_scale")
	)
	r.fieldPoint2 #RotationAnimationCenterX #RotationAnimationCenterY "rotation_animation_center"

	-- Reflection
	r.fieldFloat #PerpendicularBrightness "perpendicular_brightness"
	r.fieldRGB #PerpendicularTintColor "perpendicular_tint_color"
	r.fieldFloat #ParallelBrightness "parallel_brightness"
	r.fieldRGB #ParallelTintColor "parallel_tint_color"
	r.fieldBitmap #ReflectionCubeTexture "reflection_cube_map" enableParam:#EnableReflectionCube
)

-------------------------------------------------------
-- shader_model_extended
-------------------------------------------------------
-- EnableExtended is a viewport-only comparison toggle, so the extension is always written
fn readShaderModelExtendedOps r =
(
	readShaderModelOps r

	-- Detail map 2
	r.fieldEnum #Detail2Function "detail_2_function"
	r.fieldEnum #Detail2Mask "detail_2_mask"
	r.fieldFloat #Detail2MapScale "detail_2_map_scale"
	r.fieldBitmap #Detail2MapTexture "detail_2_map" enableParam:#EnableDetail2Map
	r.fieldFloat #Detail2MapVScale "detail_2_map_v_scale"

	-- Bump
	r.fieldBitmap #BaseNormalMapTexture "base_normal_map" enableParam:#EnableBaseNormalMap
	r.fieldFloat #BaseNormalCoefficient "base_normal_coefficient"
	for n in #("1", "2") do
	(
		local pre = "DetailNormal" + n
		local key = "detail_normal_" + n
		r.fieldBitmap ((pre + "MapTexture") as name) (key + "_map") enableParam:((("Enable" + pre + "Map") as name))
		r.fieldFloat ((pre + "Coefficient") as name) (key + "_coefficient")
		r.fieldFloat ((pre + "Scale") as name) (key + "_scale")
		r.fieldFloat ((pre + "VScale") as name) (key + "_v_scale")
	)

	-- Specular
	r.fieldBitmap #SpecularColorMapTexture "specular_color_map" enableParam:#EnableSpecularColorMap
	r.fieldFloat #SpecularColorCoefficient "specular_color_coefficient"
	r.fieldFloat #SpecularColorExponent "specular_color_exponent"
	r.fieldFlag #AlphaAsExponentMask "specular_color_flags.alpha_as_exponent_mask"
	r.fieldFloat #SpecularLightingExponent "specular_lighting_exponent"
	r.fieldFloat #SpecularLightingCoefficient "specular_lighting_coefficient"
	r.fieldFlag #DoNotUseDlmsBsp "diffuse_lighting_flags.do_not_use_dlms_bsp"
)

-------------------------------------------------------
-- shader_transparent_chicago (+ chicago_extended)
-------------------------------------------------------

-- mapsKey/flagsKey: "maps"/"shader_transparent_chicago_flags" for chicago,
-- "maps_4_stage"/"shader_transparent_chicago_extended_flags" for chicago_extended
-- (its 2-stage block is legacy-hardware fallback data and stays empty)
fn readShaderChicagoOps r mapsKey flagsKey =
(
	_readBaseShaderOps r
	_readTransparentAttributeOps r flagsKey

	r.fieldFlag #DontFadeActiveCamouflage "extra_flags.dont_fade_active_camouflage"
	r.fieldFlag #NumericCountdownTimer "extra_flags.numeric_countdown_timer"
	r.fieldFlag #CustomEditionBlending "extra_flags.custom_edition_blending"

	local mapCount = r.countEnabled "EnableMap" 1 4
	r.addInsert mapsKey mapCount
	for j = 1 to mapCount do
		_readMapStageOps r mapsKey j layout:#chicago
)

-------------------------------------------------------
-- shader_transparent_generic
-------------------------------------------------------

-- One combiner stage (inverse of _dxApplyGenericCombinerStage)
fn _readGenericCombinerStageOps r stageIdx =
(
	local pre = "Stage" + (stageIdx as string) + "_"
	local key = "stages[" + ((stageIdx - 1) as string) + "]."

	r.fieldFlag ((pre + "ColorMux") as name) (key + "flags.color_mux")
	r.fieldFlag ((pre + "AlphaMux") as name) (key + "flags.alpha_mux")
	r.fieldFlag ((pre + "AOutControlsColor0Animation") as name) (key + "flags.a_out_controls_color0_animation")

	r.fieldEnum ((pre + "Color0Source") as name) (key + "color0_source")
	r.fieldEnum ((pre + "Color0AnimationFunction") as name) (key + "color0_animation_function")
	r.fieldFloat ((pre + "Color0AnimationPeriod") as name) (key + "color0_animation_period")
	r.fieldARGB ((pre + "Color0AnimationLowerBound") as name) ((pre + "Color0LowerAlpha") as name) (key + "color0_animation_lower_bound")
	r.fieldARGB ((pre + "Color0AnimationUpperBound") as name) ((pre + "Color0UpperAlpha") as name) (key + "color0_animation_upper_bound")
	r.fieldARGB ((pre + "Color1") as name) ((pre + "Color1Alpha") as name) (key + "color1")

	-- Color side
	for inp in #("A", "B", "C", "D") do
	(
		r.fieldEnum ((pre + "ColorInput" + inp) as name) (key + "input_" + toLower inp)
		r.fieldEnum ((pre + "ColorInput" + inp + "Mapping") as name) (key + "input_" + toLower inp + "_mapping")
	)
	r.fieldEnum ((pre + "ColorOutputAB") as name) (key + "output_ab")
	r.fieldEnum ((pre + "ColorOutputABFunction") as name) (key + "output_ab_function")
	-- invader-edit names the color CD output "output_bc"
	r.fieldEnum ((pre + "ColorOutputCD") as name) (key + "output_bc")
	r.fieldEnum ((pre + "ColorOutputCDFunction") as name) (key + "output_cd_function")
	r.fieldEnum ((pre + "ColorOutputABCDMuxSum") as name) (key + "output_ab_cd_mux_sum")
	r.fieldEnum ((pre + "ColorOutputMapping") as name) (key + "output_mapping_color")

	-- Alpha side (AB/CD always multiply, no function fields)
	for inp in #("A", "B", "C", "D") do
	(
		r.fieldEnum ((pre + "AlphaInput" + inp) as name) (key + "input_" + toLower inp + "_alpha")
		r.fieldEnum ((pre + "AlphaInput" + inp + "Mapping") as name) (key + "input_" + toLower inp + "_mapping_alpha")
	)
	r.fieldEnum ((pre + "AlphaOutputAB") as name) (key + "output_ab_alpha")
	r.fieldEnum ((pre + "AlphaOutputCD") as name) (key + "output_cd_alpha")
	r.fieldEnum ((pre + "AlphaOutputABCDMuxSum") as name) (key + "output_ab_cd_mux_sum_alpha")
	r.fieldEnum ((pre + "AlphaOutputMapping") as name) (key + "output_mapping_alpha")
)

fn readShaderGenericOps r =
(
	_readBaseShaderOps r
	_readTransparentAttributeOps r "shader_transparent_generic_flags"

	local mapCount = r.countEnabled "EnableMap" 1 4
	r.addInsert "maps" mapCount
	for j = 1 to mapCount do
		_readMapStageOps r "maps" j layout:#generic

	local stageCount = r.countEnabled "EnableStage" 1 7
	r.addInsert "stages" stageCount
	for j = 1 to stageCount do
		_readGenericCombinerStageOps r j
)

-------------------------------------------------------
-- shader_transparent_meter
-------------------------------------------------------
fn readShaderMeterOps r =
(
	_readBaseShaderOps r

	r.fieldFlag #Decal "meter_flags.decal"
	r.fieldFlag #TwoSided "meter_flags.two_sided"
	r.fieldFlag #FlashColorIsNegative "meter_flags.flash_color_is_negative"
	r.fieldFlag #TintMode2 "meter_flags.tint_mode_2"
	r.fieldFlag #Unfiltered "meter_flags.unfiltered"

	r.fieldBitmap #MeterMap "map"
	r.fieldRGB #GradientMinColor "gradient_min_color"
	r.fieldRGB #GradientMaxColor "gradient_max_color"
	r.fieldRGB #BackgroundColor "background_color"
	r.fieldRGB #FlashColor "flash_color"
	r.fieldRGB #MeterTintColor "meter_tint_color"
	r.fieldFloat #MeterTransparency "meter_transparency"
	r.fieldFloat #BackgroundTransparency "background_transparency"

	-- External sources
	r.fieldEnum #MeterBrightnessSource "meter_brightness_source"
	r.fieldEnum #FlashBrightnessSource "flash_brightness_source"
	r.fieldEnum #ValueSource "value_source"
	r.fieldEnum #GradientSource "gradient_source"
	r.fieldEnum #FlashExtensionSource "flash_extension_source"
)

-------------------------------------------------------
-- shader_transparent_water
-------------------------------------------------------
fn readShaderWaterOps r =
(
	_readBaseShaderOps r

	r.fieldFlag #BaseMapAlphaModulatesReflection "water_flags.base_map_alpha_modulates_reflection"
	r.fieldFlag #BaseMapColorModulatesBackground "water_flags.base_map_color_modulates_background"
	r.fieldFlag #AtmosphericFog "water_flags.atmospheric_fog"
	r.fieldFlag #DrawBeforeFog "water_flags.draw_before_fog"

	r.fieldBitmap #BaseMapTexture "base_map" enableParam:#EnableBaseMap
	r.fieldFloat #ViewPerpendicularBrightness "view_perpendicular_brightness"
	r.fieldRGB #ViewPerpendicularTintColor "view_perpendicular_tint_color"
	r.fieldFloat #ViewParallelBrightness "view_parallel_brightness"
	r.fieldRGB #ViewParallelTintColor "view_parallel_tint_color"
	r.fieldBitmap #ReflectionMapTexture "reflection_map" enableParam:#EnableReflectionMap

	-- Ripple globals (angles are raw radians, as the builder passes them)
	r.fieldFloat #RippleAnimationAngle "ripple_animation_angle"
	r.fieldFloat #RippleAnimationVelocity "ripple_animation_velocity"
	r.fieldFloat #RippleScale "ripple_scale"
	r.fieldBitmap #RippleMapsTexture "ripple_maps" enableParam:#EnableRippleMaps
	r.fieldInt #RippleMipmapLevels "ripple_mipmap_levels"
	r.fieldFloat #RippleMipmapFadeFactor "ripple_mipmap_fade_factor"
	r.fieldFloat #RippleMipmapDetailBias "ripple_mipmap_detail_bias"

	-- Ripple entries (the effect names them 0-based: Ripple0..Ripple3)
	local rippleCount = r.countEnabled "EnableRipple" 0 3 firstAlwaysOn:false
	r.addInsert "ripples" rippleCount
	for j = 0 to rippleCount - 1 do
	(
		local k = j as string
		local pre = "Ripple" + k + "_"
		local key = "ripples[" + k + "]."
		r.fieldFloat ((pre + "ContributionFactor") as name) (key + "contribution_factor")
		r.fieldFloat ((pre + "AnimationAngle") as name) (key + "animation_angle")
		r.fieldFloat ((pre + "AnimationVelocity") as name) (key + "animation_velocity")
		r.fieldPoint2 ((pre + "MapOffsetU") as name) ((pre + "MapOffsetV") as name) (key + "map_offset")
		r.fieldInt ((pre + "MapRepeats") as name) (key + "map_repeats")
		r.fieldInt ((pre + "MapIndex") as name) (key + "map_index")
	)
)

-------------------------------------------------------
-- shader_transparent_plasma
-------------------------------------------------------
fn readShaderPlasmaOps r =
(
	_readBaseShaderOps r

	r.fieldEnum #IntensitySource "intensity_source"
	r.fieldFloat #IntensityExponent "intensity_exponent"
	r.fieldEnum #OffsetSource "offset_source"
	r.fieldFloat #OffsetAmount "offset_amount"
	r.fieldFloat #OffsetExponent "offset_exponent"

	r.fieldFloat #PerpendicularBrightness "perpendicular_brightness"
	r.fieldRGB #PerpendicularTintColor "perpendicular_tint_color"
	r.fieldFloat #ParallelBrightness "parallel_brightness"
	r.fieldRGB #ParallelTintColor "parallel_tint_color"
	r.fieldEnum #TintColorSource "tint_color_source"

	for noise in #("Primary", "Secondary") do
	(
		local key = toLower noise
		r.fieldFloat ((noise + "AnimationPeriod") as name) (key + "_animation_period")
		r.fieldVector3 ((noise + "AnimationDirectionI") as name) ((noise + "AnimationDirectionJ") as name) \
			((noise + "AnimationDirectionK") as name) (key + "_animation_direction")
		r.fieldFloat ((noise + "NoiseMapScale") as name) (key + "_noise_map_scale")
		r.fieldBitmap ((noise + "NoiseMapTexture") as name) (key + "_noise_map") enableParam:((("Enable" + noise + "NoiseMap") as name))
	)
)

-------------------------------------------------------
-- shader_transparent_glass
-------------------------------------------------------
fn readShaderGlassOps r =
(
	_readBaseShaderOps r

	r.fieldFlag #AlphaTested "shader_transparent_glass_flags.alpha_tested"
	r.fieldFlag #Decal "shader_transparent_glass_flags.decal"
	r.fieldFlag #TwoSided "shader_transparent_glass_flags.two_sided"
	r.fieldFlag #BumpMapIsSpecularMask "shader_transparent_glass_flags.bump_map_is_specular_mask"

	-- Background tint
	r.fieldRGB #BackgroundTintColor "background_tint_color"
	r.fieldFloat #BackgroundTintMapScale "background_tint_map_scale"
	r.fieldBitmap #BackgroundTintMapTexture "background_tint_map" enableParam:#EnableBackgroundTintMap

	-- Reflection
	r.fieldEnum #ReflectionType "reflection_type"
	r.fieldFloat #ReflPerpendicularBrightness "perpendicular_brightness"
	r.fieldRGB #ReflPerpendicularTintColor "perpendicular_tint_color"
	r.fieldFloat #ReflParallelBrightness "parallel_brightness"
	r.fieldRGB #ReflParallelTintColor "parallel_tint_color"
	r.fieldBitmap #ReflectionCubeTexture "reflection_map" enableParam:#EnableReflectionCube

	-- Maps
	r.fieldFloat #BumpMapScale "bump_map_scale"
	r.fieldBitmap #BumpMapTexture "bump_map" enableParam:#EnableBumpMap
	r.fieldFloat #DiffuseMapScale "diffuse_map_scale"
	r.fieldBitmap #DiffuseMapTexture "diffuse_map" enableParam:#EnableDiffuseMap
	r.fieldFloat #DiffuseDetailMapScale "diffuse_detail_map_scale"
	r.fieldBitmap #DiffuseDetailMapTexture "diffuse_detail_map" enableParam:#EnableDiffuseDetailMap
	r.fieldFloat #SpecularMapScale "specular_map_scale"
	r.fieldBitmap #SpecularMapTexture "specular_map" enableParam:#EnableSpecularMap
	r.fieldFloat #SpecularDetailMapScale "specular_detail_map_scale"
	r.fieldBitmap #SpecularDetailMapTexture "specular_detail_map" enableParam:#EnableSpecularDetailMap
)

-------------------------------------------------------
-- shader_environment
-------------------------------------------------------
fn readShaderEnvironmentOps r =
(
	_readBaseShaderOps r

	r.fieldFlag #AlphaTested "shader_environment_flags.alpha_tested"
	r.fieldFlag #BumpMapIsSpecularMask "shader_environment_flags.bump_map_is_specular_mask"
	r.fieldFlag #TrueAtmosphericFog "shader_environment_flags.true_atmospheric_fog"
	r.fieldFlag #BumpAttenuation "shader_environment_flags.use_alternate_bump_attenuation"
	r.fieldEnum #EnvironmentType "shader_environment_type"
	r.fieldFloat #LensFlareSpacing "lens_flare_spacing"

	-- Diffuse
	r.fieldFlag #RescaleDetailMaps "diffuse_flags.rescale_detail_maps"
	r.fieldFlag #RescaleBumpMap "diffuse_flags.rescale_bump_map"
	r.fieldBitmap #BaseMapTexture "base_map" enableParam:#EnableBaseMap
	r.fieldEnum #DetailMapFunction "detail_map_function"
	r.fieldFloat #PrimaryDetailMapScale "primary_detail_map_scale"
	r.fieldBitmap #PrimaryDetailMapTexture "primary_detail_map" enableParam:#EnablePrimaryDetailMap
	r.fieldFloat #SecondaryDetailMapScale "secondary_detail_map_scale"
	r.fieldBitmap #SecondaryDetailMapTexture "secondary_detail_map" enableParam:#EnableSecondaryDetailMap
	r.fieldEnum #MicroDetailMapFunction "micro_detail_map_function"
	r.fieldFloat #MicroDetailMapScale "micro_detail_map_scale"
	r.fieldBitmap #MicroDetailMapTexture "micro_detail_map" enableParam:#EnableMicroDetailMap
	r.fieldRGB #MaterialColor "material_color"

	-- Bump
	r.fieldFloat #BumpMapScale "bump_map_scale"
	r.fieldBitmap #BumpMapTexture "bump_map" enableParam:#EnableBumpMap

	-- Texture scrolling animation
	for axis in #("U", "V") do
	(
		local keyAxis = toLower axis
		r.fieldEnum ((axis + "AnimationFunction") as name) (keyAxis + "_animation_function")
		r.fieldFloat ((axis + "AnimationPeriod") as name) (keyAxis + "_animation_period")
		r.fieldFloat ((axis + "AnimationScale") as name) (keyAxis + "_animation_scale")
	)

	-- Self-illumination
	r.fieldFlag #unfilteredFlag "self_illumination_flags.unfiltered"
	for light in #("Primary", "Secondary", "Plasma") do
	(
		local key = toLower light
		r.fieldRGB ((light + "OnColor") as name) (key + "_on_color")
		r.fieldRGB ((light + "OffColor") as name) (key + "_off_color")
		r.fieldEnum ((light + "AnimationFunction") as name) (key + "_animation_function")
		r.fieldFloat ((light + "AnimationPeriod") as name) (key + "_animation_period")
		r.fieldFloat ((light + "AnimationPhase") as name) (key + "_animation_phase")
	)
	r.fieldFloat #SelfIlluminationMapScale "map_scale"
	r.fieldBitmap #SelfIlluminationMapTexture "map" enableParam:#EnableSelfIlluminationMap

	-- Specular
	r.fieldFlag #SpecularOverbright "specular_flags.overbright"
	r.fieldFlag #SpecularExtraShiny "specular_flags.extra_shiny"
	r.fieldFlag #LightmapIsSpecular "specular_flags.lightmap_is_specular"
	r.fieldFloat #SpecBrightness "brightness"
	r.fieldRGB #SpecPerpendicularColor "perpendicular_color"
	r.fieldRGB #SpecParallelColor "parallel_color"

	-- Reflection
	r.fieldFlag #DynamicMirror "reflection_flags.dynamic_mirror"
	r.fieldEnum #ReflectionType "reflection_type"
	r.fieldFloat #LightmapBrightnessScale "lightmap_brightness_scale"
	r.fieldFloat #ReflPerpendicularBrightness "perpendicular_brightness"
	r.fieldFloat #ReflParallelBrightness "parallel_brightness"
	r.fieldBitmap #ReflectionCubeTexture "reflection_cube_map" enableParam:#EnableReflectionCube
)

-------------------------------------------------------
-- Dispatcher
-------------------------------------------------------

-- Read a DirectX material as the given shader type. Returns a DxShaderReader with the
-- collected operations, or undefined for an unsupported type.
fn readDxMaterialShaderOps dxMat shaderType =
(
	local r = DxShaderReader dxMat:dxMat
	case shaderType of
	(
		"shader_model": readShaderModelOps r
		"shader_model_extended": readShaderModelExtendedOps r
		"shader_transparent_chicago": readShaderChicagoOps r "maps" "shader_transparent_chicago_flags"
		"shader_transparent_chicago_extended": readShaderChicagoOps r "maps_4_stage" "shader_transparent_chicago_extended_flags"
		"shader_transparent_generic": readShaderGenericOps r
		"shader_transparent_meter": readShaderMeterOps r
		"shader_transparent_water": readShaderWaterOps r
		"shader_transparent_plasma": readShaderPlasmaOps r
		"shader_transparent_glass": readShaderGlassOps r
		"shader_environment": readShaderEnvironmentOps r
		default: return undefined
	)
	r
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
