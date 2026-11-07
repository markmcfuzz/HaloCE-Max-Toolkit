------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but MERCHANTABILITY ANY WARRANTY; without the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

-- GlyphFX Material Builder
-- Creates GlyphFX materials from parsed shader tag data (ShaderTextureResult) and fills every
-- exposed effect parameter with the tag values. shader_model, shader_model_extended and
-- shader_environment are OSL maps (src\osl) in a Standard material; the rest DirectX_9_Shader.
-- Currently supported: shader_model, shader_model_extended, shader_transparent_chicago,
-- shader_transparent_chicago_extended (rendered with the chicago effect using its
-- 4-stage maps only; the 2-stage fallback block exists solely for legacy hardware),
-- shader_transparent_generic (maps + combiner stages), shader_transparent_meter,
-- shader_transparent_water (ripples included), shader_transparent_plasma (dual
-- noise-map atlases), shader_transparent_glass and shader_environment.
-- Unsupported types return undefined so the caller falls back to a StandardMaterial.
-- Shared by every tag importer that builds shader materials (gbxmodel,
-- scenario_structure_bsp, and future JMS) via buildShaderViewportMaterial
-- (viewport_material.ms).
--
-- NOTE: 3ds Max only exposes .fx parameters that carry an ACTIVE 'string UIName'
-- annotation in the params.fxh. Parameters without it (e.g. Translucency while
-- its UIName is commented out) are skipped silently at debug log level.

-------------------------------------------------------
-- GlyphFX effects location
-------------------------------------------------------

global _glyphFxDir = undefined

if _glyphFxDir == undefined then
(
	-- builders\tag\shared\ -> builders\tag\ -> builders\ -> engine\
	local builderDir  = getFilenamePath (getThisScriptFilename())
	local tagDir      = getFilenamePath (trimRight builderDir "\\")
	local buildersDir = getFilenamePath (trimRight tagDir "\\")
	local engineDir   = getFilenamePath (trimRight buildersDir "\\")
	_glyphFxDir = engineDir + "shaders\\GlyphFX\\src\\fx\\"
)
-- The opaque shaders (OSL), next to fx\
global _glyphFxOslDir = (getFilenamePath (trimRight _glyphFxDir "\\")) + "osl\\"

-------------------------------------------------------
-- Helpers
-------------------------------------------------------

-- Set an effect parameter only if the effect exposes it. Returns true on success.
-- dxMat: a DirectX material or an OSL map (its bools are int 0/1)
fn dxSetParam dxMat propName value =
(
	if value == undefined then return false
	if classOf value == BooleanClass and classOf dxMat == OSLMap do value = if value then 1 else 0
	local wasSet = false
	try
	(
		if isProperty dxMat propName then
		(
			setProperty dxMat propName value
			wasSet = true
		)
	)
	catch ()
	if not wasSet then
		logger.debug "  DX param '{}' not exposed by effect (or set failed)" args:#(propName as string)
	wasSet
)

-- Tag colors come from the parser as color values with 0-1 components
-- (raw floats stored in Max's 0-255 space); rescale them for DX color params
fn tagColorToMaxColor tagColor =
(
	if tagColor == undefined then return undefined
	case classOf tagColor of
	(
		Color:  color (amin (tagColor.r * 255.0) 255.0) (amin (tagColor.g * 255.0) 255.0) (amin (tagColor.b * 255.0) 255.0)
		Point3: color (amin (tagColor.x * 255.0) 255.0) (amin (tagColor.y * 255.0) 255.0) (amin (tagColor.z * 255.0) 255.0)
		default: undefined
	)
)

-- Brighter of two Max colors by luminance (Rec. 709 weights); ties keep the first.
-- Either may be undefined, in which case the other one is returned.
fn brighterMaxColor colorA colorB =
(
	if colorA == undefined then return colorB
	if colorB == undefined then return colorA
	local lumA = 0.2126 * colorA.r + 0.7152 * colorA.g + 0.0722 * colorA.b
	local lumB = 0.2126 * colorB.r + 0.7152 * colorB.g + 0.0722 * colorB.b
	if lumB > lumA then colorB else colorA
)

-- Tag semantics: a black colorRGB (0,0,0) means "default to white" (1,1,1) -
-- same convention as a 0 scale defaulting to 1
fn zeroColorDefaultsToWhite tagColor =
(
	local maxColor = tagColorToMaxColor tagColor
	if maxColor == undefined then return undefined
	if (abs maxColor.r) < 0.0001 and (abs maxColor.g) < 0.0001 and (abs maxColor.b) < 0.0001 then
		color 255 255 255
	else
		maxColor
)

-- Tag ARGB colors come from the parser as Point4 (r, g, b, a) with 0-1 floats;
-- rescale into a Max color (with alpha) for DX color params
fn tagARGBToMaxColor p4 =
(
	if p4 == undefined or classOf p4 != Point4 then return undefined
	color (amin (p4.x * 255.0) 255.0) (amin (p4.y * 255.0) 255.0) (amin (p4.z * 255.0) 255.0) (amin (p4.w * 255.0) 255.0)
)

-- Tag semantics: a scale of 0 means "default to 1"
fn zeroDefaultsToOne v =
(
	if v == undefined then undefined
	else if (abs v) < 0.0001 then 1.0
	else v
)

-- Set a tag point2d into effect parameters. DX11 float2 params are drawn in the
-- UI but NOT published as MAXScript properties, so the reliable form is a pair of
-- float params. Tries "<base>U<suffix>"/"<base>V<suffix>" first (e.g.
-- AnimationCenterU2/AnimationCenterV2), then falls back to "<base><suffix>" as
-- Point2/Point3/Point4 in case the effect exposes the packed form.
fn dxSetParamCenter dxMat baseName suffix p2 =
(
	if p2 == undefined or classOf p2 != Point2 then return false

	local uName = (baseName + "U" + suffix) as name
	local vName = (baseName + "V" + suffix) as name
	if (isProperty dxMat uName) and (isProperty dxMat vName) then
	(
		local okU = dxSetParam dxMat uName p2.x
		local okV = dxSetParam dxMat vName p2.y
		return (okU and okV)
	)

	local packedName = (baseName + suffix) as name
	if not (isProperty dxMat packedName) then
	(
		logger.debug "  DX param '{}' not exposed (float2 is not scriptable; expose it as '{}'/'{}' floats)" args:#(baseName + suffix, baseName + "U" + suffix, baseName + "V" + suffix)
		return false
	)
	if dxSetParam dxMat packedName p2 then return true
	if dxSetParam dxMat packedName (Point3 p2.x p2.y 0.0) then return true
	dxSetParam dxMat packedName (Point4 p2.x p2.y 0.0 0.0)
)

-- Open the resolved disk texture of a map key as a bitmap value (DX texture params).
-- Each file is opened once per import (_dxBitmapCache, cleared by resetShaderResolverCache).
global _dxBitmapCache
fn dxLoadBitmapForKey textureResult mapKey =
(
	if textureResult.mapFiles == undefined then return undefined
	local filePath = textureResult.mapFiles[mapKey]
	if filePath == undefined then return undefined
	if _dxBitmapCache == undefined then _dxBitmapCache = dictionary #string
	local bmp = _dxBitmapCache[filePath]
	if bmp != undefined then return bmp
	try ( bmp = openBitMap filePath ) catch ( bmp = undefined )
	if bmp == undefined then
		logger.warn "Could not open bitmap: {}" args:#(filePath)
	else
		_dxBitmapCache[filePath] = bmp
	bmp
)

-- Texture of a map key for a texture param: the file path for an OSL map (nothing to open),
-- the bitmap for a DirectX material. Undefined when the map has no file on disk
fn dxTextureForKey dxMat textureResult mapKey =
(
	if classOf dxMat != OSLMap then return dxLoadBitmapForKey textureResult mapKey
	if textureResult.mapFiles == undefined then undefined else textureResult.mapFiles[mapKey]
)

-- Parent 'shader' block (radiosity + physics), exposed by every GlyphFX effect
fn _dxApplyBaseShaderParams dxMat shaderEntry =
(
	if shaderEntry == undefined then return false
	local radFlags = getFieldValue shaderEntry "flags"
	if classOf radFlags == Integer then
	(
		dxSetParam dxMat #SimpleParameterization (bit.get radFlags 1)
		dxSetParam dxMat #IgnoreNormals (bit.get radFlags 2)
		dxSetParam dxMat #TransparentLit (bit.get radFlags 3)
	)
	dxSetParam dxMat #DetailLevel (getFieldValue shaderEntry "detailLevel")
	dxSetParam dxMat #Power (getFieldValue shaderEntry "power")
	dxSetParam dxMat #ColorOfEmittedLight (tagColorToMaxColor (getFieldValue shaderEntry "colorOfEmittedLight"))
	dxSetParam dxMat #TintColor (tagColorToMaxColor (getFieldValue shaderEntry "tintColor"))
	dxSetParam dxMat #MaterialType (getFieldValue shaderEntry "materialType")
	true
)

-------------------------------------------------------
-- shader_model -> shader_model.fx
-------------------------------------------------------
-- Sets every parameter from the tag data, also on a material built before (tag editor edits)
fn applyShaderModelParams dxMat textureResult =
(
	local mainEntry = textureResult.mainEntry
	_dxApplyBaseShaderParams dxMat textureResult.shaderEntry

	-- Model flags bitfield (first 'flags' field of the soso block)
	local flagsVal = getFieldValue mainEntry "flags"
	if classOf flagsVal == Integer then
	(
		dxSetParam dxMat #DetailAfterReflection (bit.get flagsVal 1)
		dxSetParam dxMat #TwoSided (bit.get flagsVal 2)
		dxSetParam dxMat #NotAlphaTested (bit.get flagsVal 3)
		dxSetParam dxMat #AlphaBlendedDecal (bit.get flagsVal 4)
		dxSetParam dxMat #TrueAtmosphericFog (bit.get flagsVal 5)
		dxSetParam dxMat #DisableTwoSidedCulling (bit.get flagsVal 6)
		dxSetParam dxMat #UseXboxChannelOrder (bit.get flagsVal 7)
	)

	-- Exposed only when its UIName is active in shader_model.params.fxh
	dxSetParam dxMat #Translucency (getFieldValue mainEntry "translucency")

	-- Change color (ChangeColor itself stays manual/3ds-Max-only per its UIName)
	dxSetParam dxMat #ChangeColorSource (getFieldValue mainEntry "changeColorSource")

	-- Self illumination block: second 'flags' occurrence (first is the model flags above)
	local selfIllumFlags = getFieldValueNth mainEntry "flags" 2
	if classOf selfIllumFlags == Integer then
		dxSetParam dxMat #NoRandomPhaseFlag (bit.get selfIllumFlags 1)

	dxSetParam dxMat #SelfIlluminationColorSource (getFieldValue mainEntry "colorSource")
	dxSetParam dxMat #SelfIlluminationAnimationFunction (getFieldValue mainEntry "animationFunction")
	dxSetParam dxMat #SelfIlluminationAnimationPeriod (getFieldValue mainEntry "animationPeriod")
	local lowerBound = tagColorToMaxColor (getFieldValue mainEntry "animationColorLowerBound")
	local upperBound = tagColorToMaxColor (getFieldValue mainEntry "animationColorUpperBound")
	dxSetParam dxMat #AnimationColorLowerBound lowerBound
	dxSetParam dxMat #AnimationColorUpperBound upperBound

	-- SelfIlluminationColor (3ds Max only) starts from the brighter bound - it's the
	-- artist-facing color for viewport visualization, kept as its own param so it can
	-- still be overridden by hand independently of the raw Lower/Upper Bound fields.
	dxSetParam dxMat #SelfIlluminationColor (brighterMaxColor lowerBound upperBound)

	-- Base map UV scales (tag: 0 defaults to 1)
	dxSetParam dxMat #MapUScale (zeroDefaultsToOne (getFieldValue mainEntry "mapUScale"))
	dxSetParam dxMat #MapVScale (zeroDefaultsToOne (getFieldValue mainEntry "mapVScale"))

	-- Detail properties
	dxSetParam dxMat #DetailFunction (getFieldValue mainEntry "detailFunction")
	dxSetParam dxMat #DetailMask (getFieldValue mainEntry "detailMask")
	dxSetParam dxMat #DetailMapScale (zeroDefaultsToOne (getFieldValue mainEntry "detailMapScale"))
	-- 0 means "copy DetailMapScale"; the vertex shader handles that case itself
	dxSetParam dxMat #DetailMapVScale (getFieldValue mainEntry "detailMapVScale")

	-- 2D texture animation (values passed raw from the tag)
	dxSetParam dxMat #UAnimationSource (getFieldValue mainEntry "uAnimationSource")
	dxSetParam dxMat #UAnimationFunction (getFieldValue mainEntry "uAnimationFunction")
	dxSetParam dxMat #UAnimationPeriod (getFieldValue mainEntry "uAnimationPeriod")
	dxSetParam dxMat #UAnimationPhase (getFieldValue mainEntry "uAnimationPhase")
	dxSetParam dxMat #UAnimationScale (getFieldValue mainEntry "uAnimationScale")
	dxSetParam dxMat #VAnimationSource (getFieldValue mainEntry "vAnimationSource")
	dxSetParam dxMat #VAnimationFunction (getFieldValue mainEntry "vAnimationFunction")
	dxSetParam dxMat #VAnimationPeriod (getFieldValue mainEntry "vAnimationPeriod")
	dxSetParam dxMat #VAnimationPhase (getFieldValue mainEntry "vAnimationPhase")
	dxSetParam dxMat #VAnimationScale (getFieldValue mainEntry "vAnimationScale")
	dxSetParam dxMat #RotationAnimationSource (getFieldValue mainEntry "rotationAnimationSource")
	dxSetParam dxMat #RotationAnimationFunction (getFieldValue mainEntry "rotationAnimationFunction")
	dxSetParam dxMat #RotationAnimationPeriod (getFieldValue mainEntry "rotationAnimationPeriod")
	dxSetParam dxMat #RotationAnimationPhase (getFieldValue mainEntry "rotationAnimationPhase")
	dxSetParam dxMat #RotationAnimationScale (getFieldValue mainEntry "rotationAnimationScale")

	local animCenter = getFieldValue mainEntry "rotationAnimationCenter"
	if animCenter != undefined and classOf animCenter == Point2 then
	(
		dxSetParam dxMat #RotationAnimationCenterX animCenter.x
		dxSetParam dxMat #RotationAnimationCenterY animCenter.y
	)

	-- Reflection properties
	dxSetParam dxMat #PerpendicularBrightness (getFieldValue mainEntry "perpendicularBrightness")
	dxSetParam dxMat #PerpendicularTintColor (tagColorToMaxColor (getFieldValue mainEntry "perpendicularTintColor"))
	dxSetParam dxMat #ParallelBrightness (getFieldValue mainEntry "parallelBrightness")
	dxSetParam dxMat #ParallelTintColor (tagColorToMaxColor (getFieldValue mainEntry "parallelTintColor"))

	-- Textures + enable flags (unbound DX11 textures sample black, so disable missing ones)
	local baseBmp   = dxTextureForKey dxMat textureResult "baseMap"
	local multiBmp  = dxTextureForKey dxMat textureResult "multipurposeMap"
	local detailBmp = dxTextureForKey dxMat textureResult "detailMap"
	local cubeBmp   = dxTextureForKey dxMat textureResult "reflectionCubeMap"

	if baseBmp != undefined then dxSetParam dxMat #BaseMapTexture baseBmp
	dxSetParam dxMat #EnableBaseMap (baseBmp != undefined)

	if multiBmp != undefined then dxSetParam dxMat #MultipurposeMapTexture multiBmp
	dxSetParam dxMat #EnableMultipurposeMap (multiBmp != undefined)

	if detailBmp != undefined then dxSetParam dxMat #DetailMapTexture detailBmp
	dxSetParam dxMat #EnableDetailMap (detailBmp != undefined)

	if cubeBmp != undefined then dxSetParam dxMat #ReflectionCubeTexture cubeBmp
	dxSetParam dxMat #EnableReflectionCube (cubeBmp != undefined)
	ok
)

-------------------------------------------------------
-- shader_model_extended -> shader_model_extended.fx
-------------------------------------------------------
-- Same fields as shader_model plus the extension appended after the cube map:
-- detail map 2, base/detail normal maps, specular color map + lighting, DLM flag.
-- "0 = 1" fields of the extension stay raw; the effect substitutes 1 itself.
fn applyShaderModelExtendedParams dxMat textureResult =
(
	applyShaderModelParams dxMat textureResult
	local mainEntry = textureResult.mainEntry

	-- Detail map 2 (scale: tag 0 defaults to 1, V scale 0 is handled by the effect)
	dxSetParam dxMat #Detail2Function (getFieldValue mainEntry "detail2Function")
	dxSetParam dxMat #Detail2Mask (getFieldValue mainEntry "detail2Mask")
	dxSetParam dxMat #Detail2MapScale (zeroDefaultsToOne (getFieldValue mainEntry "detail2MapScale"))
	dxSetParam dxMat #Detail2MapVScale (getFieldValue mainEntry "detail2MapVscale")

	-- Bump properties
	dxSetParam dxMat #BaseNormalCoefficient (getFieldValue mainEntry "baseNormalCoefficient")
	for n in #("1", "2") do
	(
		local pre = "DetailNormal" + n
		local fieldPre = "detailNormal" + n
		dxSetParam dxMat ((pre + "Coefficient") as name) (getFieldValue mainEntry (fieldPre + "Coefficient"))
		dxSetParam dxMat ((pre + "Scale") as name) (getFieldValue mainEntry (fieldPre + "Scale"))
		dxSetParam dxMat ((pre + "VScale") as name) (getFieldValue mainEntry (fieldPre + "Vscale"))
	)

	-- Specular properties
	dxSetParam dxMat #SpecularColorCoefficient (getFieldValue mainEntry "specularColorCoefficient")
	dxSetParam dxMat #SpecularColorExponent (getFieldValue mainEntry "specularColorExponent")
	local specFlags = getFieldValue mainEntry "specularColorFlags"
	if classOf specFlags == Integer then
		dxSetParam dxMat #AlphaAsExponentMask (bit.get specFlags 1)
	dxSetParam dxMat #SpecularLightingExponent (getFieldValue mainEntry "specularLightingExponent")
	dxSetParam dxMat #SpecularLightingCoefficient (getFieldValue mainEntry "specularLightingCoefficient")

	local diffuseFlags = getFieldValue mainEntry "diffuseLightingFlags"
	if classOf diffuseFlags == Integer then
		dxSetParam dxMat #DoNotUseDlmsBsp (bit.get diffuseFlags 1)

	-- Textures + enable flags (unbound DX11 textures sample black, so disable missing ones)
	for slot in #(#("detail2Map", "Detail2Map"), #("baseNormalMap", "BaseNormalMap"), \
		#("detailNormal1Map", "DetailNormal1Map"), #("detailNormal2Map", "DetailNormal2Map"), \
		#("specularColorMap", "SpecularColorMap")) do
	(
		local bmp = dxTextureForKey dxMat textureResult slot[1]
		if bmp != undefined then dxSetParam dxMat ((slot[2] + "Texture") as name) bmp
		dxSetParam dxMat (("Enable" + slot[2]) as name) (bmp != undefined)
	)
	ok
)

-------------------------------------------------------
-- Shared transparent-shader helpers
-------------------------------------------------------

-- Apply one map stage (flags, blend functions, UV transform, texture, animation).
-- layout:#chicago has alpha-replicate + per-map color/alpha functions;
-- layout:#generic has neither (its blending lives in the combiner stages)
fn _dxApplyMapStage dxMat textureResult mapEntry stageIdx mapKeyPrefix layout:#chicago =
(
	local n = stageIdx as string

	local mapFlags = getFieldValue mapEntry "flags"
	if classOf mapFlags == Integer then
	(
		if layout == #generic then
		(
			-- Generic map flags: unfiltered, u-clamped, v-clamped
			dxSetParam dxMat (("Map" + n + "_Unfiltered") as name) (bit.get mapFlags 1)
			dxSetParam dxMat (("Map" + n + "_UClamped") as name) (bit.get mapFlags 2)
			dxSetParam dxMat (("Map" + n + "_VClamped") as name) (bit.get mapFlags 3)
		)
		else
		(
			-- Chicago map flags: unfiltered, alpha replicate, u-clamped, v-clamped
			dxSetParam dxMat (("Map" + n + "_Unfiltered") as name) (bit.get mapFlags 1)
			dxSetParam dxMat (("Map" + n + "_AlphaReplicate") as name) (bit.get mapFlags 2)
			dxSetParam dxMat (("Map" + n + "_UClamped") as name) (bit.get mapFlags 3)
			dxSetParam dxMat (("Map" + n + "_VClamped") as name) (bit.get mapFlags 4)
		)
	)

	if layout == #chicago then
	(
		dxSetParam dxMat (("Map" + n + "_ColorFunction") as name) (getFieldValue mapEntry "colorFunction")
		dxSetParam dxMat (("Map" + n + "_AlphaFunction") as name) (getFieldValue mapEntry "alphaFunction")
	)

	-- UV transform (tag: scale 0 defaults to 1)
	dxSetParam dxMat (("Map" + n + "_UScale") as name) (zeroDefaultsToOne (getFieldValue mapEntry "mapUScale"))
	dxSetParam dxMat (("Map" + n + "_VScale") as name) (zeroDefaultsToOne (getFieldValue mapEntry "mapVScale"))
	dxSetParam dxMat (("Map" + n + "_UOffset") as name) (getFieldValue mapEntry "mapUOffset")
	dxSetParam dxMat (("Map" + n + "_VOffset") as name) (getFieldValue mapEntry "mapVOffset")
	dxSetParam dxMat (("Map" + n + "_Rotation") as name) (getFieldValue mapEntry "mapRotation")
	dxSetParam dxMat (("Map" + n + "_MipmapBias") as name) (getFieldValue mapEntry "mipmapBias")

	-- Texture (Map 1 is always active; stages 2-4 use EnableMapN)
	local stageBmp = dxTextureForKey dxMat textureResult (mapKeyPrefix + n)
	if stageBmp != undefined then dxSetParam dxMat (("Map" + n + "Texture") as name) stageBmp
	if stageIdx >= 2 then
		dxSetParam dxMat (("EnableMap" + n) as name) (stageBmp != undefined)

	-- 2D texture animation (values passed raw from the tag)
	dxSetParam dxMat (("UAnimationSource" + n) as name) (getFieldValue mapEntry "uAnimationSource")
	dxSetParam dxMat (("UAnimationFunction" + n) as name) (getFieldValue mapEntry "uAnimationFunction")
	dxSetParam dxMat (("UAnimationPeriod" + n) as name) (getFieldValue mapEntry "uAnimationPeriod")
	dxSetParam dxMat (("UAnimationPhase" + n) as name) (getFieldValue mapEntry "uAnimationPhase")
	dxSetParam dxMat (("UAnimationScale" + n) as name) (getFieldValue mapEntry "uAnimationScale")
	dxSetParam dxMat (("VAnimationSource" + n) as name) (getFieldValue mapEntry "vAnimationSource")
	dxSetParam dxMat (("VAnimationFunction" + n) as name) (getFieldValue mapEntry "vAnimationFunction")
	dxSetParam dxMat (("VAnimationPeriod" + n) as name) (getFieldValue mapEntry "vAnimationPeriod")
	dxSetParam dxMat (("VAnimationPhase" + n) as name) (getFieldValue mapEntry "vAnimationPhase")
	dxSetParam dxMat (("VAnimationScale" + n) as name) (getFieldValue mapEntry "vAnimationScale")
	dxSetParam dxMat (("RotationAnimationSource" + n) as name) (getFieldValue mapEntry "rotationAnimationSource")
	dxSetParam dxMat (("RotationAnimationFunction" + n) as name) (getFieldValue mapEntry "rotationAnimationFunction")
	dxSetParam dxMat (("RotationAnimationPeriod" + n) as name) (getFieldValue mapEntry "rotationAnimationPeriod")
	dxSetParam dxMat (("RotationAnimationPhase" + n) as name) (getFieldValue mapEntry "rotationAnimationPhase")
	dxSetParam dxMat (("RotationAnimationScale" + n) as name) (getFieldValue mapEntry "rotationAnimationScale")
	dxSetParamCenter dxMat "AnimationCenter" n (getFieldValue mapEntry "rotationAnimationCenter")
	ok
)

-------------------------------------------------------
-- shader_transparent_chicago (+ chicago_extended) -> shader_transparent_chicago.fx
-------------------------------------------------------

-- mapsFieldName/mapKeyPrefix: "maps"/"map" for chicago, "4StageMaps"/"4StageMap"
-- for chicago_extended (its 2-stage block is legacy-hardware fallback data and is omitted)
fn applyShaderChicagoParams dxMat textureResult mapsFieldName mapKeyPrefix =
(
	local mainEntry = textureResult.mainEntry
	local shaderEntry = textureResult.shaderEntry

	-- Parent 'shader' block: radiosity + physics properties
	_dxApplyBaseShaderParams dxMat shaderEntry

	-- Chicago attributes
	dxSetParam dxMat #NumericCounterLimit (getFieldValue mainEntry "numericCounterLimit")

	local chiFlags = getFieldValue mainEntry "flags"
	if classOf chiFlags == Integer then
	(
		dxSetParam dxMat #AlphaTested (bit.get chiFlags 1)
		dxSetParam dxMat #Decal (bit.get chiFlags 2)
		dxSetParam dxMat #TwoSided (bit.get chiFlags 3)
		dxSetParam dxMat #FirstMapIsScreenspace (bit.get chiFlags 4)
		dxSetParam dxMat #DrawBeforeWater (bit.get chiFlags 5)
		dxSetParam dxMat #IgnoreEffect (bit.get chiFlags 6)
		dxSetParam dxMat #ScaleFirstMapWithDistance (bit.get chiFlags 7)
		dxSetParam dxMat #Numeric (bit.get chiFlags 8)
	)

	dxSetParam dxMat #FirstMapType (getFieldValue mainEntry "firstMapType")
	dxSetParam dxMat #FramebufferBlendFunction (getFieldValue mainEntry "framebufferBlendFunction")
	dxSetParam dxMat #FramebufferFadeMode (getFieldValue mainEntry "framebufferFadeMode")
	dxSetParam dxMat #FramebufferFadeSource (getFieldValue mainEntry "framebufferFadeSource")

	local lfSpacing = getFieldValue mainEntry "lensFlareSpacing"
	if lfSpacing != undefined then
		dxSetParam dxMat #LensFlareSpacing (lfSpacing as integer)

	-- Extra flags
	local extraFlags = getFieldValue mainEntry "extraFlags"
	if classOf extraFlags == Integer then
	(
		dxSetParam dxMat #DontFadeActiveCamouflage (bit.get extraFlags 1)
		dxSetParam dxMat #NumericCountdownTimer (bit.get extraFlags 2)
		dxSetParam dxMat #CustomEditionBlending (bit.get extraFlags 3)
	)

	-- The effect has one technique: FramebufferBlendFunction (set above) picks the blend

	-- Map stages (up to 4)
	local mapEntries = getFieldValue mainEntry mapsFieldName
	local stageCount = 0
	if mapEntries != undefined and classOf mapEntries == Array then
		stageCount = amin mapEntries.count 4
	for j = 1 to stageCount do
		_dxApplyMapStage dxMat textureResult mapEntries[j] j mapKeyPrefix layout:#chicago
	-- Maps the tag no longer has (tag editor edits)
	for j = (amax 2 (stageCount + 1)) to 4 do
		dxSetParam dxMat (("EnableMap" + (j as string)) as name) false
	ok
)

-------------------------------------------------------
-- shader_transparent_generic -> shader_transparent_generic.fx
-------------------------------------------------------

-- Apply one combiner stage. The tag stage block declares the same field names
-- twice (color side first, then alpha side), so values are fetched by occurrence.
fn _dxApplyGenericCombinerStage dxMat stageEntry stageIdx =
(
	local pre = "Stage" + (stageIdx as string) + "_"

	-- Stage flags: color mux, alpha mux, a-out controls color0 animation
	local stFlags = getFieldValue stageEntry "flags"
	if classOf stFlags == Integer then
	(
		dxSetParam dxMat ((pre + "ColorMux") as name) (bit.get stFlags 1)
		dxSetParam dxMat ((pre + "AlphaMux") as name) (bit.get stFlags 2)
		dxSetParam dxMat ((pre + "AOutControlsColor0Animation") as name) (bit.get stFlags 3)
	)

	-- Constants and color0 animation (ARGB colors)
	dxSetParam dxMat ((pre + "Color0Source") as name) (getFieldValue stageEntry "color0Source")
	dxSetParam dxMat ((pre + "Color0AnimationFunction") as name) (getFieldValue stageEntry "color0AnimationFunction")
	dxSetParam dxMat ((pre + "Color0AnimationPeriod") as name) (getFieldValue stageEntry "color0AnimationPeriod")
	dxSetParam dxMat ((pre + "Color0AnimationLowerBound") as name) (tagARGBToMaxColor (getFieldValue stageEntry "color0AnimationLowerBound"))
	dxSetParam dxMat ((pre + "Color0AnimationUpperBound") as name) (tagARGBToMaxColor (getFieldValue stageEntry "color0AnimationUpperBound"))
	dxSetParam dxMat ((pre + "Color1") as name) (tagARGBToMaxColor (getFieldValue stageEntry "color1"))
	-- The effect reads each ARGB alpha from its own slider ("Alpha (A of ARGB)"), not the color widget
	for argb in #(#("color0AnimationLowerBound", "Color0LowerAlpha"), #("color0AnimationUpperBound", "Color0UpperAlpha"), #("color1", "Color1Alpha")) do
	(
		local p4 = getFieldValue stageEntry argb[1]
		if classOf p4 == Point4 do dxSetParam dxMat ((pre + argb[2]) as name) p4.w
	)

	-- Inputs/outputs: occurrence 1 = color side, occurrence 2 = alpha side
	for side in #(#("Color", 1), #("Alpha", 2)) do
	(
		local sideName = side[1]
		local occ = side[2]
		dxSetParam dxMat ((pre + sideName + "InputA") as name) (getFieldValueNth stageEntry "inputA" occ)
		dxSetParam dxMat ((pre + sideName + "InputAMapping") as name) (getFieldValueNth stageEntry "inputAMapping" occ)
		dxSetParam dxMat ((pre + sideName + "InputB") as name) (getFieldValueNth stageEntry "inputB" occ)
		dxSetParam dxMat ((pre + sideName + "InputBMapping") as name) (getFieldValueNth stageEntry "inputBMapping" occ)
		dxSetParam dxMat ((pre + sideName + "InputC") as name) (getFieldValueNth stageEntry "inputC" occ)
		dxSetParam dxMat ((pre + sideName + "InputCMapping") as name) (getFieldValueNth stageEntry "inputCMapping" occ)
		dxSetParam dxMat ((pre + sideName + "InputD") as name) (getFieldValueNth stageEntry "inputD" occ)
		dxSetParam dxMat ((pre + sideName + "InputDMapping") as name) (getFieldValueNth stageEntry "inputDMapping" occ)
		dxSetParam dxMat ((pre + sideName + "OutputAB") as name) (getFieldValueNth stageEntry "outputAB" occ)
		dxSetParam dxMat ((pre + sideName + "OutputCD") as name) (getFieldValueNth stageEntry "outputCD" occ)
		dxSetParam dxMat ((pre + sideName + "OutputABCDMuxSum") as name) (getFieldValueNth stageEntry "outputABCDMux/sum" occ)
		dxSetParam dxMat ((pre + sideName + "OutputMapping") as name) (getFieldValueNth stageEntry "outputMapping" occ)
	)

	-- AB/CD combine functions exist on the color side only (alpha always multiplies)
	dxSetParam dxMat ((pre + "ColorOutputABFunction") as name) (getFieldValueNth stageEntry "outputABFunction" 1)
	dxSetParam dxMat ((pre + "ColorOutputCDFunction") as name) (getFieldValueNth stageEntry "outputCDFunction" 1)

	-- Stage 1 is always active; stages 2-7 are switched on per tag entry
	if stageIdx >= 2 then
		dxSetParam dxMat (("EnableStage" + (stageIdx as string)) as name) true
	ok
)

-- Sets every parameter from the tag data, also on a material built before (tag editor edits):
-- maps and stages the tag no longer has are switched off
fn applyShaderGenericParams dxMat textureResult =
(
	local mainEntry = textureResult.mainEntry

	-- Parent 'shader' block: radiosity + physics properties
	_dxApplyBaseShaderParams dxMat textureResult.shaderEntry

	-- Generic attributes (same layout as chicago)
	dxSetParam dxMat #NumericCounterLimit (getFieldValue mainEntry "numericCounterLimit")

	local genFlags = getFieldValue mainEntry "flags"
	if classOf genFlags == Integer then
	(
		dxSetParam dxMat #AlphaTested (bit.get genFlags 1)
		dxSetParam dxMat #Decal (bit.get genFlags 2)
		dxSetParam dxMat #TwoSided (bit.get genFlags 3)
		dxSetParam dxMat #FirstMapIsScreenspace (bit.get genFlags 4)
		dxSetParam dxMat #DrawBeforeWater (bit.get genFlags 5)
		dxSetParam dxMat #IgnoreEffect (bit.get genFlags 6)
		dxSetParam dxMat #ScaleFirstMapWithDistance (bit.get genFlags 7)
		dxSetParam dxMat #Numeric (bit.get genFlags 8)
	)

	dxSetParam dxMat #FirstMapType (getFieldValue mainEntry "firstMapType")
	dxSetParam dxMat #FramebufferBlendFunction (getFieldValue mainEntry "framebufferBlendFunction")
	dxSetParam dxMat #FramebufferFadeMode (getFieldValue mainEntry "framebufferFadeMode")
	dxSetParam dxMat #FramebufferFadeSource (getFieldValue mainEntry "framebufferFadeSource")
	dxSetParam dxMat #LensFlareSpacing (getFieldValue mainEntry "lensFlareSpacing")

	-- The effect has one technique: FramebufferBlendFunction (set above) picks the blend

	-- Map stages (up to 4)
	local mapEntries = getFieldValue mainEntry "maps"
	local mapCount = 0
	if mapEntries != undefined and classOf mapEntries == Array then
		mapCount = amin mapEntries.count 4
	for j = 1 to mapCount do
		_dxApplyMapStage dxMat textureResult mapEntries[j] j "map" layout:#generic
	for j = (amax 2 (mapCount + 1)) to 4 do
		dxSetParam dxMat (("EnableMap" + (j as string)) as name) false

	-- Combiner stages (up to 7)
	local stageEntries = getFieldValue mainEntry "stages"
	local stageCount = 0
	if stageEntries != undefined and classOf stageEntries == Array then
		stageCount = amin stageEntries.count 7
	for j = 1 to stageCount do
		_dxApplyGenericCombinerStage dxMat stageEntries[j] j
	for j = (amax 2 (stageCount + 1)) to 7 do
		dxSetParam dxMat (("EnableStage" + (j as string)) as name) false

	ok
)

-------------------------------------------------------
-- shader_transparent_meter -> shader_transparent_meter.fx
-------------------------------------------------------

fn applyShaderMeterParams dxMat textureResult =
(
	local mainEntry = textureResult.mainEntry

	-- Parent 'shader' block: radiosity + physics properties (fills the radiosity TintColor)
	_dxApplyBaseShaderParams dxMat textureResult.shaderEntry

	-- Meter flags: decal, two-sided, flash color is negative, tint mode-2, unfiltered
	local flagsVal = getFieldValue mainEntry "flags"
	if classOf flagsVal == Integer then
	(
		dxSetParam dxMat #Decal (bit.get flagsVal 1)
		dxSetParam dxMat #TwoSided (bit.get flagsVal 2)
		dxSetParam dxMat #FlashColorIsNegative (bit.get flagsVal 3)
		dxSetParam dxMat #TintMode2 (bit.get flagsVal 4)
		dxSetParam dxMat #Unfiltered (bit.get flagsVal 5)
	)

	-- Colors
	dxSetParam dxMat #GradientMinColor (tagColorToMaxColor (getFieldValue mainEntry "gradientMinColor"))
	dxSetParam dxMat #GradientMaxColor (tagColorToMaxColor (getFieldValue mainEntry "gradientMaxColor"))
	dxSetParam dxMat #BackgroundColor (tagColorToMaxColor (getFieldValue mainEntry "backgroundColor"))
	dxSetParam dxMat #FlashColor (tagColorToMaxColor (getFieldValue mainEntry "flashColor"))
	-- The meter group's own tint is exposed as MeterTintColor; #TintColor is the
	-- base-shader radiosity tint applied above by _dxApplyBaseShaderParams
	dxSetParam dxMat #MeterTintColor (tagColorToMaxColor (getFieldValue mainEntry "tintColor"))

	-- Transparencies (used when 'tint mode-2' is set)
	dxSetParam dxMat #MeterTransparency (getFieldValue mainEntry "meterTransparency")
	dxSetParam dxMat #BackgroundTransparency (getFieldValue mainEntry "backgroundTransparency")

	-- Meter map (MeterValue/FlashBrightness are viewport preview controls, not tag data)
	local meterBmp = dxTextureForKey dxMat textureResult "map"
	if meterBmp != undefined then dxSetParam dxMat #MeterMap meterBmp
	ok
)

-------------------------------------------------------
-- shader_transparent_water -> shader_transparent_water.fx
-------------------------------------------------------

fn applyShaderWaterParams dxMat textureResult =
(
	local mainEntry = textureResult.mainEntry

	-- Parent 'shader' block: radiosity + physics properties
	_dxApplyBaseShaderParams dxMat textureResult.shaderEntry

	-- Water flags
	local flagsVal = getFieldValue mainEntry "flags"
	if classOf flagsVal == Integer then
	(
		dxSetParam dxMat #BaseMapAlphaModulatesReflection (bit.get flagsVal 1)
		dxSetParam dxMat #BaseMapColorModulatesBackground (bit.get flagsVal 2)
		dxSetParam dxMat #AtmosphericFog (bit.get flagsVal 3)
		dxSetParam dxMat #DrawBeforeFog (bit.get flagsVal 4)
	)

	-- View brightness/tint
	dxSetParam dxMat #ViewPerpendicularBrightness (getFieldValue mainEntry "viewPerpendicularBrightness")
	dxSetParam dxMat #ViewPerpendicularTintColor (tagColorToMaxColor (getFieldValue mainEntry "viewPerpendicularTintColor"))
	dxSetParam dxMat #ViewParallelBrightness (zeroDefaultsToOne (getFieldValue mainEntry "viewParallelBrightness"))
	dxSetParam dxMat #ViewParallelTintColor (tagColorToMaxColor (getFieldValue mainEntry "viewParallelTintColor"))

	-- Ripple globals
	dxSetParam dxMat #RippleAnimationAngle (getFieldValue mainEntry "rippleAnimationAngle")
	dxSetParam dxMat #RippleAnimationVelocity (getFieldValue mainEntry "rippleAnimationVelocity")
	dxSetParam dxMat #RippleScale (zeroDefaultsToOne (getFieldValue mainEntry "rippleScale"))
	dxSetParam dxMat #RippleMipmapLevels (zeroDefaultsToOne (getFieldValue mainEntry "rippleMipmapLevels"))
	dxSetParam dxMat #RippleMipmapFadeFactor (getFieldValue mainEntry "rippleMipmapFadeFactor")
	dxSetParam dxMat #RippleMipmapDetailBias (getFieldValue mainEntry "rippleMipmapDetailBias")

	-- Textures + enable flags (unbound DX11 textures sample black, so disable missing ones)
	local baseBmp   = dxTextureForKey dxMat textureResult "baseMap"
	local reflBmp   = dxTextureForKey dxMat textureResult "reflectionMap"
	local rippleBmp = dxTextureForKey dxMat textureResult "rippleMaps"

	if baseBmp != undefined then dxSetParam dxMat #BaseMapTexture baseBmp
	dxSetParam dxMat #EnableBaseMap (baseBmp != undefined)

	if reflBmp != undefined then dxSetParam dxMat #ReflectionMapTexture reflBmp
	dxSetParam dxMat #EnableReflectionMap (reflBmp != undefined)

	if rippleBmp != undefined then dxSetParam dxMat #RippleMapsTexture rippleBmp
	dxSetParam dxMat #EnableRippleMaps (rippleBmp != undefined)

	-- Ripple entries (the effect names them 0-based: Ripple0..Ripple3)
	local rippleEntries = getFieldValue mainEntry "ripples"
	local rippleCount = 0
	if rippleEntries != undefined and classOf rippleEntries == Array then
		rippleCount = amin rippleEntries.count 4
	for j = 1 to rippleCount do
	(
		local rippleEntry = rippleEntries[j]
		local k = (j - 1) as string
		dxSetParam dxMat (("EnableRipple" + k) as name) true
		dxSetParam dxMat (("Ripple" + k + "_ContributionFactor") as name) (zeroDefaultsToOne (getFieldValue rippleEntry "contributionFactor"))
		dxSetParam dxMat (("Ripple" + k + "_AnimationAngle") as name) (getFieldValue rippleEntry "animationAngle")
		dxSetParam dxMat (("Ripple" + k + "_AnimationVelocity") as name) (getFieldValue rippleEntry "animationVelocity")
		dxSetParamCenter dxMat ("Ripple" + k + "_MapOffset") "" (getFieldValue rippleEntry "mapOffset")
		dxSetParam dxMat (("Ripple" + k + "_MapRepeats") as name) (zeroDefaultsToOne (getFieldValue rippleEntry "mapRepeats"))
		dxSetParam dxMat (("Ripple" + k + "_MapIndex") as name) (getFieldValue rippleEntry "mapIndex")
	)
	-- Ripples the tag no longer has (tag editor edits)
	for j = rippleCount + 1 to 4 do
		dxSetParam dxMat (("EnableRipple" + ((j - 1) as string)) as name) false
	ok
)

-------------------------------------------------------
-- shader_transparent_plasma -> shader_transparent_plasma.fx
-------------------------------------------------------

fn applyShaderPlasmaParams dxMat textureResult =
(
	local mainEntry = textureResult.mainEntry

	-- Parent 'shader' block: radiosity + physics properties
	_dxApplyBaseShaderParams dxMat textureResult.shaderEntry

	-- Intensity (external object-function driven; kept for tag fidelity, tag: 0 exponent defaults to 1)
	dxSetParam dxMat #IntensitySource (getFieldValue mainEntry "intensitySource")
	dxSetParam dxMat #IntensityExponent (zeroDefaultsToOne (getFieldValue mainEntry "intensityExponent"))

	-- Offset (offset amount pushes vertices along their normal in the .vsh; tag: 0 exponent defaults to 1)
	dxSetParam dxMat #OffsetSource (getFieldValue mainEntry "offsetSource")
	dxSetParam dxMat #OffsetAmount (getFieldValue mainEntry "offsetAmount")
	dxSetParam dxMat #OffsetExponent (zeroDefaultsToOne (getFieldValue mainEntry "offsetExponent"))

	-- Color: tint colors + Fresnel brightness
	dxSetParam dxMat #PerpendicularBrightness (getFieldValue mainEntry "perpendicularBrightness")
	dxSetParam dxMat #PerpendicularTintColor (tagColorToMaxColor (getFieldValue mainEntry "perpendicularTintColor"))
	dxSetParam dxMat #ParallelBrightness (getFieldValue mainEntry "parallelBrightness")
	dxSetParam dxMat #ParallelTintColor (tagColorToMaxColor (getFieldValue mainEntry "parallelTintColor"))
	dxSetParam dxMat #TintColorSource (getFieldValue mainEntry "tintColorSource")

	-- Primary noise map animation (direction is a 3D vector; float2 packing is not scriptable so use I/J/K floats)
	dxSetParam dxMat #PrimaryAnimationPeriod (getFieldValue mainEntry "primaryAnimationPeriod")
	local primDir = getFieldValue mainEntry "primaryAnimationDirection"
	if classOf primDir == Point3 then
	(
		dxSetParam dxMat #PrimaryAnimationDirectionI primDir.x
		dxSetParam dxMat #PrimaryAnimationDirectionJ primDir.y
		dxSetParam dxMat #PrimaryAnimationDirectionK primDir.z
	)
	dxSetParam dxMat #PrimaryNoiseMapScale (getFieldValue mainEntry "primaryNoiseMapScale")

	-- Secondary noise map animation
	dxSetParam dxMat #SecondaryAnimationPeriod (getFieldValue mainEntry "secondaryAnimationPeriod")
	local secDir = getFieldValue mainEntry "secondaryAnimationDirection"
	if classOf secDir == Point3 then
	(
		dxSetParam dxMat #SecondaryAnimationDirectionI secDir.x
		dxSetParam dxMat #SecondaryAnimationDirectionJ secDir.y
		dxSetParam dxMat #SecondaryAnimationDirectionK secDir.z
	)
	dxSetParam dxMat #SecondaryNoiseMapScale (getFieldValue mainEntry "secondaryNoiseMapScale")

	-- Textures + enable flags (unbound DX11 textures sample black, so disable missing ones).
	-- The noise maps are filmstrip atlases; slice count / border texels are viewport-only
	-- controls (not tag data) that the artist tunes to the loaded image, so they are left at
	-- the effect defaults here.
	local primaryBmp   = dxTextureForKey dxMat textureResult "primaryNoiseMap"
	local secondaryBmp = dxTextureForKey dxMat textureResult "secondaryNoiseMap"

	if primaryBmp != undefined then dxSetParam dxMat #PrimaryNoiseMapTexture primaryBmp
	dxSetParam dxMat #EnablePrimaryNoiseMap (primaryBmp != undefined)

	if secondaryBmp != undefined then dxSetParam dxMat #SecondaryNoiseMapTexture secondaryBmp
	dxSetParam dxMat #EnableSecondaryNoiseMap (secondaryBmp != undefined)
	ok
)

-------------------------------------------------------
-- shader_transparent_glass -> shader_transparent_glass.fx
-------------------------------------------------------

fn applyShaderGlassParams dxMat textureResult =
(
	local mainEntry = textureResult.mainEntry

	-- Glass flags: alpha-tested, decal, two-sided, bump map is specular mask
	local flagsVal = getFieldValue mainEntry "flags"
	if classOf flagsVal == Integer then
	(
		dxSetParam dxMat #AlphaTested (bit.get flagsVal 1)
		dxSetParam dxMat #Decal (bit.get flagsVal 2)
		dxSetParam dxMat #TwoSided (bit.get flagsVal 3)
		dxSetParam dxMat #BumpMapIsSpecularMask (bit.get flagsVal 4)
	)

	-- Background tint properties
	dxSetParam dxMat #BackgroundTintColor (tagColorToMaxColor (getFieldValue mainEntry "backgroundTintColor"))
	dxSetParam dxMat #BackgroundTintMapScale (zeroDefaultsToOne (getFieldValue mainEntry "backgroundTintMapScale"))

	-- Reflection properties
	dxSetParam dxMat #ReflectionType (getFieldValue mainEntry "reflectionType")
	dxSetParam dxMat #ReflPerpendicularBrightness (getFieldValue mainEntry "perpendicularBrightness")
	dxSetParam dxMat #ReflPerpendicularTintColor (tagColorToMaxColor (getFieldValue mainEntry "perpendicularTintColor"))
	dxSetParam dxMat #ReflParallelBrightness (getFieldValue mainEntry "parallelBrightness")
	dxSetParam dxMat #ReflParallelTintColor (tagColorToMaxColor (getFieldValue mainEntry "parallelTintColor"))

	-- Map scales (tag: 0 defaults to 1)
	dxSetParam dxMat #BumpMapScale (zeroDefaultsToOne (getFieldValue mainEntry "bumpMapScale"))
	dxSetParam dxMat #DiffuseMapScale (zeroDefaultsToOne (getFieldValue mainEntry "diffuseMapScale"))
	dxSetParam dxMat #DiffuseDetailMapScale (zeroDefaultsToOne (getFieldValue mainEntry "diffuseDetailMapScale"))
	dxSetParam dxMat #SpecularMapScale (zeroDefaultsToOne (getFieldValue mainEntry "specularMapScale"))
	dxSetParam dxMat #SpecularDetailMapScale (zeroDefaultsToOne (getFieldValue mainEntry "specularDetailMapScale"))

	-- Textures + enable flags (unbound DX11 textures sample black, so disable missing ones)
	local tintBmp       = dxTextureForKey dxMat textureResult "backgroundTintMap"
	local reflBmp       = dxTextureForKey dxMat textureResult "reflectionMap"
	local bumpBmp       = dxTextureForKey dxMat textureResult "bumpMap"
	local diffuseBmp    = dxTextureForKey dxMat textureResult "diffuseMap"
	local diffDetailBmp = dxTextureForKey dxMat textureResult "diffuseDetailMap"
	local specBmp       = dxTextureForKey dxMat textureResult "specularMap"
	local specDetailBmp = dxTextureForKey dxMat textureResult "specularDetailMap"

	if tintBmp != undefined then dxSetParam dxMat #BackgroundTintMapTexture tintBmp
	dxSetParam dxMat #EnableBackgroundTintMap (tintBmp != undefined)

	if reflBmp != undefined then dxSetParam dxMat #ReflectionCubeTexture reflBmp
	dxSetParam dxMat #EnableReflectionCube (reflBmp != undefined)

	if bumpBmp != undefined then dxSetParam dxMat #BumpMapTexture bumpBmp
	dxSetParam dxMat #EnableBumpMap (bumpBmp != undefined)

	if diffuseBmp != undefined then dxSetParam dxMat #DiffuseMapTexture diffuseBmp
	dxSetParam dxMat #EnableDiffuseMap (diffuseBmp != undefined)

	if diffDetailBmp != undefined then dxSetParam dxMat #DiffuseDetailMapTexture diffDetailBmp
	dxSetParam dxMat #EnableDiffuseDetailMap (diffDetailBmp != undefined)

	if specBmp != undefined then dxSetParam dxMat #SpecularMapTexture specBmp
	dxSetParam dxMat #EnableSpecularMap (specBmp != undefined)

	if specDetailBmp != undefined then dxSetParam dxMat #SpecularDetailMapTexture specDetailBmp
	dxSetParam dxMat #EnableSpecularDetailMap (specDetailBmp != undefined)
	ok
)

-------------------------------------------------------
-- shader_environment -> shader_environment.fx
-------------------------------------------------------

-- The senv block declares "flags" five times (environment, diffuse,
-- self-illumination, specular, reflection) and "type" twice (environment,
-- reflection), so those are fetched by occurrence.
fn applyShaderEnvironmentParams dxMat textureResult =
(
	local mainEntry = textureResult.mainEntry

	-- Parent 'shader' block: radiosity + physics properties
	_dxApplyBaseShaderParams dxMat textureResult.shaderEntry

	-- Environment flags (flags occurrence 1)
	local envFlags = getFieldValueNth mainEntry "flags" 1
	if classOf envFlags == Integer then
	(
		dxSetParam dxMat #AlphaTested (bit.get envFlags 1)
		dxSetParam dxMat #BumpMapIsSpecularMask (bit.get envFlags 2)
		dxSetParam dxMat #TrueAtmosphericFog (bit.get envFlags 3)
		dxSetParam dxMat #BumpAttenuation (bit.get envFlags 4)
	)

	dxSetParam dxMat #EnvironmentType (getFieldValueNth mainEntry "type" 1)

	local lfSpacing = getFieldValue mainEntry "lensFlareSpacing"
	if lfSpacing != undefined then
		dxSetParam dxMat #LensFlareSpacing (lfSpacing as integer)

	-- Diffuse flags (flags occurrence 2)
	local diffFlags = getFieldValueNth mainEntry "flags" 2
	if classOf diffFlags == Integer then
	(
		dxSetParam dxMat #RescaleDetailMaps (bit.get diffFlags 1)
		dxSetParam dxMat #RescaleBumpMap (bit.get diffFlags 2)
	)

	-- Diffuse maps
	dxSetParam dxMat #DetailMapFunction (getFieldValue mainEntry "detailMapFunction")
	dxSetParam dxMat #PrimaryDetailMapScale (zeroDefaultsToOne (getFieldValue mainEntry "primaryDetailMapScale"))
	dxSetParam dxMat #SecondaryDetailMapScale (zeroDefaultsToOne (getFieldValue mainEntry "secondaryDetailMapScale"))
	dxSetParam dxMat #MicroDetailMapFunction (getFieldValue mainEntry "microDetailMapFunction")
	dxSetParam dxMat #MicroDetailMapScale (zeroDefaultsToOne (getFieldValue mainEntry "microDetailMapScale"))
	dxSetParam dxMat #MaterialColor (zeroColorDefaultsToWhite (getFieldValue mainEntry "materialColor"))
	dxSetParam dxMat #BumpMapScale (zeroDefaultsToOne (getFieldValue mainEntry "bumpMapScale"))

	-- Texture scrolling animation (values passed raw from the tag)
	dxSetParam dxMat #UAnimationFunction (getFieldValue mainEntry "uAnimationFunction")
	dxSetParam dxMat #UAnimationPeriod (getFieldValue mainEntry "uAnimationPeriod")
	dxSetParam dxMat #UAnimationScale (getFieldValue mainEntry "uAnimationScale")
	dxSetParam dxMat #VAnimationFunction (getFieldValue mainEntry "vAnimationFunction")
	dxSetParam dxMat #VAnimationPeriod (getFieldValue mainEntry "vAnimationPeriod")
	dxSetParam dxMat #VAnimationScale (getFieldValue mainEntry "vAnimationScale")

	-- Self-illumination (flags occurrence 3)
	local siFlags = getFieldValueNth mainEntry "flags" 3
	if classOf siFlags == Integer then
		dxSetParam dxMat #unfilteredFlag (bit.get siFlags 1)

	dxSetParam dxMat #PrimaryOnColor (tagColorToMaxColor (getFieldValue mainEntry "primaryOnColor"))
	dxSetParam dxMat #PrimaryOffColor (tagColorToMaxColor (getFieldValue mainEntry "primaryOffColor"))
	dxSetParam dxMat #PrimaryAnimationFunction (getFieldValue mainEntry "primaryAnimationFunction")
	dxSetParam dxMat #PrimaryAnimationPeriod (getFieldValue mainEntry "primaryAnimationPeriod")
	dxSetParam dxMat #PrimaryAnimationPhase (getFieldValue mainEntry "primaryAnimationPhase")
	dxSetParam dxMat #SecondaryOnColor (tagColorToMaxColor (getFieldValue mainEntry "secondaryOnColor"))
	dxSetParam dxMat #SecondaryOffColor (tagColorToMaxColor (getFieldValue mainEntry "secondaryOffColor"))
	dxSetParam dxMat #SecondaryAnimationFunction (getFieldValue mainEntry "secondaryAnimationFunction")
	dxSetParam dxMat #SecondaryAnimationPeriod (getFieldValue mainEntry "secondaryAnimationPeriod")
	dxSetParam dxMat #SecondaryAnimationPhase (getFieldValue mainEntry "secondaryAnimationPhase")
	dxSetParam dxMat #PlasmaOnColor (tagColorToMaxColor (getFieldValue mainEntry "plasmaOnColor"))
	dxSetParam dxMat #PlasmaOffColor (tagColorToMaxColor (getFieldValue mainEntry "plasmaOffColor"))
	dxSetParam dxMat #PlasmaAnimationFunction (getFieldValue mainEntry "plasmaAnimationFunction")
	dxSetParam dxMat #PlasmaAnimationPeriod (getFieldValue mainEntry "plasmaAnimationPeriod")
	dxSetParam dxMat #PlasmaAnimationPhase (getFieldValue mainEntry "plasmaAnimationPhase")
	dxSetParam dxMat #SelfIlluminationMapScale (zeroDefaultsToOne (getFieldValue mainEntry "mapScale"))

	-- Specular (flags occurrence 4)
	local specFlags = getFieldValueNth mainEntry "flags" 4
	if classOf specFlags == Integer then
	(
		dxSetParam dxMat #SpecularOverbright (bit.get specFlags 1)
		dxSetParam dxMat #SpecularExtraShiny (bit.get specFlags 2)
		dxSetParam dxMat #LightmapIsSpecular (bit.get specFlags 3)
	)
	dxSetParam dxMat #SpecBrightness (getFieldValue mainEntry "brightness")
	dxSetParam dxMat #SpecPerpendicularColor (tagColorToMaxColor (getFieldValue mainEntry "perpendicularColor"))
	dxSetParam dxMat #SpecParallelColor (tagColorToMaxColor (getFieldValue mainEntry "parallelColor"))

	-- Reflection (flags occurrence 5, type occurrence 2)
	local reflFlags = getFieldValueNth mainEntry "flags" 5
	if classOf reflFlags == Integer then
		dxSetParam dxMat #DynamicMirror (bit.get reflFlags 1)
	dxSetParam dxMat #ReflectionType (getFieldValueNth mainEntry "type" 2)
	dxSetParam dxMat #LightmapBrightnessScale (getFieldValue mainEntry "lightmapBrightnessScale")
	dxSetParam dxMat #ReflPerpendicularBrightness (getFieldValue mainEntry "perpendicularBrightness")
	dxSetParam dxMat #ReflParallelBrightness (getFieldValue mainEntry "parallelBrightness")

	-- Textures + enable flags (unbound DX11 textures sample black, so disable missing ones)
	local baseBmp    = dxTextureForKey dxMat textureResult "baseMap"
	local priBmp     = dxTextureForKey dxMat textureResult "primaryDetailMap"
	local secBmp     = dxTextureForKey dxMat textureResult "secondaryDetailMap"
	local microBmp   = dxTextureForKey dxMat textureResult "microDetailMap"
	local bumpBmp    = dxTextureForKey dxMat textureResult "bumpMap"
	local selfIllBmp = dxTextureForKey dxMat textureResult "map"
	local cubeBmp    = dxTextureForKey dxMat textureResult "reflectionCubeMap"

	if baseBmp != undefined then dxSetParam dxMat #BaseMapTexture baseBmp
	dxSetParam dxMat #EnableBaseMap (baseBmp != undefined)

	if priBmp != undefined then dxSetParam dxMat #PrimaryDetailMapTexture priBmp
	dxSetParam dxMat #EnablePrimaryDetailMap (priBmp != undefined)

	if secBmp != undefined then dxSetParam dxMat #SecondaryDetailMapTexture secBmp
	dxSetParam dxMat #EnableSecondaryDetailMap (secBmp != undefined)

	if microBmp != undefined then dxSetParam dxMat #MicroDetailMapTexture microBmp
	dxSetParam dxMat #EnableMicroDetailMap (microBmp != undefined)

	if bumpBmp != undefined then dxSetParam dxMat #BumpMapTexture bumpBmp
	dxSetParam dxMat #EnableBumpMap (bumpBmp != undefined)

	if selfIllBmp != undefined then dxSetParam dxMat #SelfIlluminationMapTexture selfIllBmp
	dxSetParam dxMat #EnableSelfIlluminationMap (selfIllBmp != undefined)

	if cubeBmp != undefined then dxSetParam dxMat #ReflectionCubeTexture cubeBmp
	dxSetParam dxMat #EnableReflectionCube (cubeBmp != undefined)
	ok
)

-------------------------------------------------------
-- Dispatcher
-------------------------------------------------------

-- #(effect file, a parameter that only exists when the effect compiled), or undefined.
-- Opaque types are OSL: Nitrous draws every DirectX Shader in one camera-sorted group, so an
-- opaque DirectX one could cover a transparent one. A native material is drawn before them
fn _dxEffectOf shaderType = case shaderType of
(
	"shader_model": #("shader_model.osl", #BaseMapTexture)
	"shader_model_extended": #("shader_model_extended.osl", #BaseMapTexture)
	"shader_transparent_chicago": #("shader_transparent_chicago.fx", #Map1Texture)
	"shader_transparent_chicago_extended": #("shader_transparent_chicago.fx", #Map1Texture)
	"shader_transparent_generic": #("shader_transparent_generic.fx", #Map1Texture)
	"shader_transparent_meter": #("shader_transparent_meter.fx", #MeterMap)
	"shader_transparent_water": #("shader_transparent_water.fx", #BaseMapTexture)
	"shader_transparent_plasma": #("shader_transparent_plasma.fx", #PrimaryNoiseMapTexture)
	"shader_transparent_glass": #("shader_transparent_glass.fx", #DiffuseMapTexture)
	"shader_environment": #("shader_environment.osl", #BaseMapTexture)
	default: undefined
)

-- Sets every parameter from the tag data: on import, and again on a material built before
-- (applyShaderTagFields, after a tag editor edit). False for an unknown type
fn applyShaderParams mat textureResult =
(
	local dxMat = glyphFxParamHolder mat
	case textureResult.shaderType of
	(
		"shader_model": applyShaderModelParams dxMat textureResult
		"shader_model_extended": applyShaderModelExtendedParams dxMat textureResult
		"shader_transparent_chicago": applyShaderChicagoParams dxMat textureResult "maps" "map"
		"shader_transparent_chicago_extended": applyShaderChicagoParams dxMat textureResult "4StageMaps" "4StageMap"
		"shader_transparent_generic": applyShaderGenericParams dxMat textureResult
		"shader_transparent_meter": applyShaderMeterParams dxMat textureResult
		"shader_transparent_water": applyShaderWaterParams dxMat textureResult
		"shader_transparent_plasma": applyShaderPlasmaParams dxMat textureResult
		"shader_transparent_glass": applyShaderGlassParams dxMat textureResult
		"shader_environment": applyShaderEnvironmentParams dxMat textureResult
		default: return false
	)
	true
)

-- Standard material with the OSL map in the Diffuse. The OSL does all the lighting:
-- Self-Illumination 100 keeps Max lights off it (in the Self-Illum map it shows black)
fn _buildOslMaterial oslFile shaderName =
(
	local o = OSLMap()
	o.OSLPath = oslFile
	o.OSLAutoUpdate = true
	local m = StandardMaterial name:shaderName
	m.diffuseMap = o
	m.diffuseMapEnable = true
	m.useSelfIllumColor = false
	m.selfIllumAmount = 100
	m.specularLevel = 0
	m.glossiness = 0
	m
)

-- Returns the GlyphFX material for the shader (OSL in a Standard material for the opaque
-- types, DirectX_9_Shader for the rest), or undefined if the type is not supported yet /
-- the effect is missing / anything fails (caller falls back)
fn buildDxMaterialForShader textureResult =
(
	if textureResult == undefined or textureResult.mainEntry == undefined then return undefined

	local effect = _dxEffectOf textureResult.shaderType
	if effect == undefined then return undefined

	local isOsl = getFilenameType effect[1] == ".osl"
	local fxFile = (if isOsl then _glyphFxOslDir else _glyphFxDir) + effect[1]
	if not doesFileExist fxFile then
	(
		logger.warn "GlyphFX effect not found: {}" args:#(fxFile)
		return undefined
	)

	local dxMat = undefined
	local startTime = timestamp()
	try
	(
		if isOsl then
			dxMat = _buildOslMaterial fxFile textureResult.shaderName
		else
		(
			dxMat = DirectX_9_Shader()
			dxMat.name = textureResult.shaderName
			dxMat.effectfile = fxFile
		)
		-- If the effect compiled, its parameters exist as properties
		if not (isProperty (glyphFxParamHolder dxMat) effect[2]) then
		(
			logger.error "GlyphFX effect failed to load: {}" args:#(fxFile)
			dxMat = undefined
		)
		else
		(
			applyShaderParams dxMat textureResult
			-- Animation Preview on, following the timeline (effects that have it, shader_animation.ms)
			if isOsl then showTextureMap dxMat true else connectShaderAnimation dxMat
			logger.info "GlyphFX material created: '{}' ({}) in {} ms" args:#(textureResult.shaderName, textureResult.shaderType, timestamp() - startTime)
		)
	)
	catch
	(
		logger.error "GlyphFX material build failed for '{}': {}" args:#(textureResult.shaderName, getCurrentException())
		dxMat = undefined
	)

	-- Max auto-assigns a software-render proxy material (OpenPBR) to the
	-- DirectX Shader; clear it so only the DX effect remains
	if dxMat != undefined and classOf dxMat == DirectX_9_Shader then
	(
		try ( dxMat.renderMaterial = undefined )
		catch ( logger.debug "Could not clear renderMaterial for '{}'" args:#(textureResult.shaderName) )
	)

	-- Every tag field, for the tag editor (shader_tag_ca.ms, also has editableShaderTypes)
	if dxMat != undefined and textureResult.fieldKeys != undefined and findItem editableShaderTypes textureResult.shaderType > 0 do
		setShaderTagFields dxMat textureResult.shaderType textureResult.shaderFilePath textureResult.fieldKeys textureResult.fieldValues

	return dxMat
)

-------------------------------------------------------
-- Opacity of the OSL materials (alpha test and decal)
-------------------------------------------------------
-- As the game (rasterizer_xbox_models.c): models cut alpha < 127 unless "Not Alpha Tested",
-- "Alpha Blended Decal" blends instead, environment cuts the bump alpha with "Alpha Tested".
-- Connected only when it changes something: with an Opacity Max treats the material as transparent.

fn _oslParam o p dflt = if isProperty o p then getProperty o p else dflt

-- #(texture file, alpha limit 0-255, whole texture) to look at; undefined when nothing is cut
fn _oslOpacityCheck o =
(
	local check = undefined
	if isProperty o #AlphaTested then
	(
		-- shader_environment: the whole bump map (it is not mapped like the faces' base UV)
		if (_oslParam o #AlphaTested 0) == 1 and (_oslParam o #EnableBumpMap 1) == 1 do
			check = #(_oslParam o #BumpMapTexture "", 127, true)
	)
	else if (_oslParam o #EnableBaseMap 1) == 1 then
	(
		local file = _oslParam o #BaseMapTexture ""
		if (_oslParam o #AlphaBlendedDecal 0) == 1 then check = #(file, 255, false)
		else if (_oslParam o #NotAlphaTested 1) == 0 do check = #(file, 127, false)
	)
	if check != undefined and check[1] == "" then undefined else check
)

-- #(bitmap, rows read so far) of a texture with alpha, opened once per run; false otherwise
fn _oslAlphaImage images file =
(
	if hasDictValue images file then return images[file]
	local img = false
	local bm = if doesFileExist file then (try (openBitmap file) catch (undefined)) else undefined
	if bm != undefined do
	(
		if bm.hasAlpha then
		(
			local rows = #()
			rows[bm.height] = undefined
			img = #(bm, rows)
		)
		else close bm
	)
	images[file] = img
	img
)

-- True if some texel of the whole texture has alpha below limit
fn _oslTextureAlphaBelow img limit =
(
	local bm = img[1]
	local found = false
	for y = 0 to bm.height - 1 while not found do
		for c in (getPixels bm [0, y] bm.width) while not found do
			if c.a < limit do found = true
	found
)

-- True if a point of the faces with material ID id (undefined: all) falls on a texel with alpha
-- below limit. Base UV scaled by Map U/V Scale, V flipped (row 0 is the top), 15 points per face
fn _oslFacesAlphaBelow msh id img limit us vs =
(
	local bm = img[1]
	local rows = img[2]
	local w = bm.width
	local h = bm.height
	local steps = 4
	local found = false
	for f = 1 to msh.numfaces while not found do
	(
		if id == undefined or (getFaceMatID msh f) == id do
		(
			local tf = getTVFace msh f
			local ta = getTVert msh tf.x
			local tb = getTVert msh tf.y
			local tc = getTVert msh tf.z
			for i = 0 to steps while not found do
				for j = 0 to (steps - i) while not found do
				(
					local uv = (ta * i + tb * j + tc * (steps - i - j)) / steps
					local su = uv.x * us
					local sv = (1.0 - uv.y) * vs
					su -= floor su
					sv -= floor sv
					local x = amin (w - 1) (amax 0 ((floor (su * w)) as integer))
					local y = amin (h - 1) (amax 0 ((floor (sv * h)) as integer))
					if rows[y + 1] == undefined do rows[y + 1] = getPixels bm [0, y] w
					if rows[y + 1][x + 1].a < limit do found = true
				)
		)
	)
	found
)

-- What each material was last decided from (anim handle -> text): a tag editor edit of an
-- unrelated field does not read the textures again
global _oslOpacityChecked = Dictionary #string

-- Connects the Opacity output of the same OSL map on the OSL materials of the nodes whose faces
-- get cut or blended, and takes it off the ones that don't. onlyMat: just that material.
-- An Opacity set by hand (not this OSL's) is left alone. Returns how many changed
fn updateGlyphFxOpacity nodes onlyMat:undefined =
(
	-- Each OSL material and #(node, material ID) where it is used
	local mats = #()
	local uses = #()
	for n in nodes where isValidNode n and n.material != undefined do
	(
		local root = n.material
		local pairs = #()
		if classOf root == MultiMaterial then
		(
			for i = 1 to root.materialList.count do append pairs #(root.materialList[i], root.materialIDList[i])
		)
		else append pairs #(root, undefined)
		for p in pairs where p[1] != undefined and (onlyMat == undefined or p[1] == onlyMat) do
		(
			if classOf (glyphFxParamHolder p[1]) == OSLMap do
			(
				local k = findItem mats p[1]
				if k == 0 do
				(
					append mats p[1]
					append uses #()
					k = mats.count
				)
				append uses[k] #(n, p[2])
			)
		)
	)

	local images = Dictionary #string
	local meshNodes = #()
	local meshes = #()
	local changed = 0
	for k = 1 to mats.count do
	(
		local m = mats[k]
		local o = glyphFxParamHolder m
		local check = _oslOpacityCheck o
		local us = _oslParam o #MapUScale 1.0
		local vs = _oslParam o #MapVScale 1.0
		local current = m.opacityMap
		local ours = current != undefined and classOf current == MultiOutputChannelTexmapToTexmap and current.sourceMap == o
		local handle = (getHandleByAnim m) as string
		local key = (check as string) + " " + (us as string) + " " + (vs as string)
		-- Same as last time and still as it was left: nothing to read
		if hasDictValue _oslOpacityChecked handle and _oslOpacityChecked[handle] == key and (ours or current == undefined) do continue

		local needed = false
		local img = if check != undefined then _oslAlphaImage images check[1] else false
		if img != false do
		(
			if check[3] then needed = _oslTextureAlphaBelow img check[2]
			else
			(
				for u in uses[k] while not needed do
				(
					local mi = findItem meshNodes u[1]
					if mi == 0 do
					(
						append meshNodes u[1]
						append meshes (snapshotAsMesh u[1])
						mi = meshes.count
					)
					local msh = meshes[mi]
					needed = if getNumTVerts msh == 0 then _oslTextureAlphaBelow img check[2] \
						else _oslFacesAlphaBelow msh u[2] img check[2] us vs
				)
			)
		)
		_oslOpacityChecked[handle] = key

		-- Never the OSL map itself: that is its Col output and the material turns ghostly
		if needed and current == undefined then
		(
			m.opacityMap = MultiOutputChannelTexmapToTexmap sourceMap:o outputChannelIndex:2
			m.opacityMapEnable = true
			changed += 1
		)
		else if not needed and ours do
		(
			m.opacityMap = undefined
			m.opacityMapEnable = false
			changed += 1
		)
		logger.debug "OSL opacity '{}': cut/blend {}, opacity {}" args:#(m.name, needed, (m.opacityMap != undefined))
	)
	for f in images.keys where images[f] != false do close images[f][1]
	for msh in meshes do delete msh

	-- Nitrous sorts the faces of a material that just got an Opacity wrong until the
	-- transparency level is set again. The same level is enough (another one costs ~2 s)
	if changed > 0 do
	(
		try (viewport.SetTransparencyLevel (viewport.GetTransparencyLevel()))
		catch (logger.debug "Could not refresh the viewport transparency")
		redrawViews()
	)
	changed
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
