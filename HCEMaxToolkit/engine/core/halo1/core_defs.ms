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

-----------------------------------------
-- CORE DEFINITIONS
-----------------------------------------

-- Base Structs
struct tagDef
(
    fourcc,
    supergroup,
    tagBlock
)

struct blockDef
(
    name,
    length,
    maximum,
    fields
)

struct fieldDef
(
    name,
    readOnly,
    hidden,
    type,
    description,
    size,
    count,
    allowedGroups,
    unit,
    fieldBlock
)

booleanValues = #(
    false,
    true
)
boolean = booleanValues

-- Helper to create a fieldDef in a compact way
fn tagField \
    name:string \
    readOnly:boolean \
    hidden:boolean \
    type:#type \
    description:undefined \
    size:undefined \
    count:undefined \
    allowed:undefined \
    unit:undefined \
    block:undefined =
(
    fieldDef \
        name:name \
        readOnly:readOnly \
        hidden:hidden \
        type:type \
        description:description \
        size:size \
        count:count \
        allowedGroups:allowed \
        unit:unit \
        fieldBlock:block
)

-- Helper to create a blockDef with a list of fields
fn tagBlock \
    name:string \
    length:integer \
    maximum:integer \
    fields:array =
(
    blockDef \
        name:name \
        length:length \
        maximum:maximum \
        fields:fields
)

-----------------------------------------
-- TAG CLASS DETECTION
-----------------------------------------

fn getTagClass filePath = 
(	
	local f = fopen filePath "rb"
	if f == undefined then
		return undefined
	-- Read tag class from header (bytes 36-39)
	fseek f 36 #seek_set
	local class1 = ReadByte f #unsigned
	local class2 = ReadByte f #unsigned
	local class3 = ReadByte f #unsigned
	local class4 = ReadByte f #unsigned
	fclose f
	-- Convert to string
	local tagClass = ""
	tagClass += bit.intAsChar class1
	tagClass += bit.intAsChar class2
	tagClass += bit.intAsChar class3
	tagClass += bit.intAsChar class4
	tagClass
)

fn getSuperGroupTagClass superGroup =
(
	-- Map supergroup symbols to their 4-char codes
	case superGroup of
	(
		#object: "obje"
		#device: "devi"
		#item: "item"
		#unit: "unit"
		#shader: "shdr"
		default: "NONE"
	)
)

-- Recursively collect all parent tag definitions from a given tag definition
-- Returns an array of tag definitions in order from top parent to immediate parent
-- Example: for biped -> returns #(objectDef, unitDef)
fn collectParentDefs tagDef =
(
	local parents = #()
	local currentDef = tagDef
	
	-- Traverse up the parent chain
	while currentDef != undefined and currentDef.supergroup != undefined do
	(
		local parentTagClass = getSuperGroupTagClass currentDef.supergroup
		if parentTagClass != "NONE" then
		(
			local parentDef = getTagDefByClass parentTagClass
			if parentDef != undefined then
			(
				-- Insert at beginning to maintain top-down order
				insertItem parentDef parents 1
				currentDef = parentDef
			)
			else
			(
				-- Parent def not found, stop traversal
				currentDef = undefined
			)
		)
		else
		(
			-- No more parents
			currentDef = undefined
		)
	)
	
	parents
)

fn getTagDefByClass tagClass = 
(	
	-- Declare all tag def globals so MaxScript resolves them dynamically at
	-- call time rather than capturing their (undefined) value at compile time
	-- when core_defs.ms is first loaded (before any group files have run).
	global actorDef
	global actorVariantDef
	global antennaDef
	global bipedDef
	global bitmapDef
	global cameraTrackDef
	global colorTableDef
	global continuousDamageEffectDef
	global contrailDef
	global damageEffectDef
	global decalDef
	global detailObjectCollectionDef
	global deviceDef
	global deviceControlDef
	global deviceLightFixtureDef
	global deviceMachineDef
	global dialogueDef
	global effectDef
	global equipmentDef
	global flagDef
	global fogDef
	global fontDef
	global garbageDef
	global gbxmodelDef
	global globalsagDef
	global glowDef
	global grenadeHudInterfaceDef
	global hudGlobalsDef
	global hudMessageTextDef
	global hudNumberDef
	global itemDef
	global itemCollectionDef
	global lensFlareDef
	global lightDef
	global lightningDef
	global lightVolumeDef
	global materialEffectsDef
	global meterDef
	global modelDef
	global modelAnimationsDef
	global modelCollisionGeometryDef
	global multiplayerScenarioDescriptionDef
	global objectDef
	global particleDef
	global particleSystemDef
	global physicsDef
	global placeholderDef
	global pointPhysicsDef
	global preferencesNetworkGameDef
	global projectileDef
	global scenarioDef
	global scenarioStructureBspDef
	global sceneryDef
	global shaderDef
	global shaderEnvironmentDef
	global shaderModelDef
	global shaderTransparentChicagoDef
	global shaderTransparentChicagoExtendedDef
	global shaderTransparentGenericDef
	global shaderTransparentGlassDef
	global shaderTransparentMeterDef
	global shaderTransparentPlasmaDef
	global shaderTransparentWaterDef
	global skyDef
	global soundDef
	global soundEnvironmentDef
	global soundLoopingDef
	global soundSceneryDef
	global stringListDef
	global tagCollectionDef
	global uiWidgetCollectionDef
	global uiWidgetDefinitionDef
	global unicodeStringListDef
	global unitDef
	global unitHudInterfaceDef
	global vehicleDef
	global virtualKeyboardDef
	global weaponDef
	global weaponHudInterfaceDef
	global weatherParticleSystemDef
	global windDef

	-- Map tag class (4-char code) to tagDef variable
	case tagClass of
	(		
		"actr": actorDef
		"actv": actorVariantDef
		"ant!": antennaDef
		"bipd": bipedDef
		"bitm": bitmapDef
		"boom": cameraTrackDef
		"trak": cameraTrackDef
		"colo": colorTableDef
		"cdmg": continuousDamageEffectDef
		"cont": contrailDef
		"jpt!": damageEffectDef
		"deca": decalDef
		"dobc": detailObjectCollectionDef
		"devi": deviceDef
		"ctrl": deviceControlDef
		"lifi": deviceLightFixtureDef
		"mach": deviceMachineDef
		"udlg": dialogueDef
		"effe": effectDef
		"eqip": equipmentDef
		"flag": flagDef
		"fog ": fogDef
		"font": fontDef
		"garb": garbageDef
		"mod2": gbxmodelDef
		"matg": globalsagDef
		"glw!": glowDef
		"grhi": grenadeHudInterfaceDef
		"hudg": hudGlobalsDef
		"hmt ": hudMessageTextDef
		"hud#": hudNumberDef
		"item": itemDef
		"itmc": itemCollectionDef
		"lens": lensFlareDef
		"ligh": lightDef
		"elec": lightningDef
		"mgs2": lightVolumeDef
		"foot": materialEffectsDef
		"metr": meterDef
		"mode": modelDef
		"antr": modelAnimationsDef
		"coll": modelCollisionGeometryDef
		"mply": multiplayerScenarioDescriptionDef
		"obje": objectDef
		"part": particleDef
		"pctl": particleSystemDef
		"phys": physicsDef
		"plac": placeholderDef
		"pphy": pointPhysicsDef
		"ngpr": preferencesNetworkGameDef
		"proj": projectileDef
		"scnr": scenarioDef
		"sbsp": scenarioStructureBspDef
		"scen": sceneryDef
		"shdr": shaderDef
		"senv": shaderEnvironmentDef
		"soso": shaderModelDef
		"schi": shaderTransparentChicagoDef
		"scex": shaderTransparentChicagoExtendedDef
		"sotr": shaderTransparentGenericDef
		"sgla": shaderTransparentGlassDef
		"smet": shaderTransparentMeterDef
		"spla": shaderTransparentPlasmaDef
		"swat": shaderTransparentWaterDef
		"sky ": skyDef
		"snd!": soundDef
		"snde": soundEnvironmentDef
		"lsnd": soundLoopingDef
		"ssce": soundSceneryDef
		"str#": stringListDef
		"tagc": tagCollectionDef
		"Soul": uiWidgetCollectionDef
		"DeLa": uiWidgetDefinitionDef
		"ustr": unicodeStringListDef
		"unit": unitDef
		"unhi": unitHudInterfaceDef
		"vehi": vehicleDef
		"vcky": virtualKeyboardDef
		"weap": weaponDef
		"wphi": weaponHudInterfaceDef
		"rain": weatherParticleSystemDef
		"wind": windDef
		default: undefined
	)
)

-------------------------------------------------------
-- Tag Class Lookup (FourCC by short name)
-------------------------------------------------------

-- (short_name, full_name, fourcc_binary)
global h1_tag_classes_engine = #(
	#("actr", "actor", 1633907826),
	#("actv", "actor_variant", 1633907830),
	#("ant!", "antenna", 1634628641),
	#("antr", "model_animations", 1634628722),
	#("bipd", "biped", 1651077220),
	#("bitm", "bitmap", 1651078253),
	#("cdmg", "continuous_damage_effect", 1667525991),
	#("coll", "model_collision_geometry", 1668246636),
	#("colo", "color_table", 1668246639),
	#("cont", "contrail", 1668247156),
	#("ctrl", "device_control", 1668575852),
	#("deca", "decal", 1684366177),
	#("DeLa", "ui_widget_definition", 1147489377),
	#("devc", "input_device_defaults", 1684371043),
	#("devi", "device", 1684371049),
	#("dobc", "detail_object_collection", 1685021283),
	#("effe", "effect", 1701209701),
	#("elec", "lightning", 1701602659),
	#("eqip", "equipment", 1701931376),
	#("flag", "flag", 1718378855),
	#("fog ", "fog", 1718576928),
	#("font", "font", 1718578804),
	#("foot", "material_effects", 1718579060),
	#("garb", "garbage", 1734439522),
	#("glw!", "glow", 1735161633),
	#("grhi", "grenade_hud_interface", 1735551081),
	#("hmt ", "hud_message_text", 1752003616),
	#("hud#", "hud_number", 1752523811),
	#("hudg", "hud_globals", 1752523879),
	#("item", "item", 1769235821),
	#("itmc", "item_collection", 1769237859),
	#("jpt!", "damage_effect", 1785754657),
	#("lens", "lens_flare", 1818586739),
	#("lifi", "device_light_fixture", 1818846825),
	#("ligh", "light", 1818847080),
	#("lsnd", "sound_looping", 1819504228),
	#("mach", "device_machine", 1835098984),
	#("matg", "globals", 1835103335),
	#("metr", "meter", 1835365490),
	#("mgs2", "light_volume", 1835496242),
	#("mod2", "gbxmodel", 1836016690),
	#("mode", "model", 1836016741),
	#("mply", "multiplayer_scenario_description", 1836084345),
	#("ngpr", "preferences_network_game", 1852272754),
	#("obje", "object", 1868720741),
	#("part", "particle", 1885434484),
	#("pctl", "particle_system", 1885566060),
	#("phys", "physics", 1885895027),
	#("plac", "placeholder", 1886151011),
	#("pphy", "point_physics", 1886414969),
	#("proj", "projectile", 1886547818),
	#("rain", "weather_particle_system", 1918986606),
	#("sbsp", "scenario_structure_bsp", 1935831920),
	#("scen", "scenery", 1935893870),
	#("scex", "shader_transparent_chicago_extended", 1935893880),
	#("schi", "shader_transparent_chicago", 1935894633),
	#("scnr", "scenario", 1935896178),
	#("senv", "shader_environment", 1936027254),
	#("sgla", "shader_transparent_glass", 1936157793),
	#("shdr", "shader", 1936221298),
	#("sky ", "sky", 1936423200),
	#("smet", "shader_transparent_meter", 1936549236),
	#("snd!", "sound", 1936614433),
	#("snde", "sound_environment", 1936614501),
	#("soso", "shader_model", 1936683887),
	#("sotr", "shader_transparent_generic", 1936684146),
	#("Soul", "ui_widget_collection", 1399813484),
	#("spla", "shader_transparent_plasma", 1936747617),
	#("ssce", "sound_scenery", 1936941925),
	#("str#", "string_list", 1937011235),
	#("swat", "shader_transparent_water", 1937203572),
	#("tagc", "tag_collection", 1952540515),
	#("trak", "camera_track", 1953653099),
	#("udlg", "dialogue", 1969515623),
	#("unhi", "unit_hud_interface", 1970169961),
	#("unit", "unit", 1970170228),
	#("ustr", "unicode_string_list", 1970500722),
	#("vcky", "virtual_keyboard", 1986227065),
	#("vehi", "vehicle", 1986357353),
	#("weap", "weapon", 2003132784),
	#("wind", "wind", 2003398244),
	#("wphi", "weapon_hud_interface", 2003855465)
)

-- Get fourcc binary value by short tag name (e.g. "soso" -> 1936683887)
fn getFourccByTagName tagName =
(
	-- Use h1_tag_classes (old module) if loaded, otherwise fall back to engine table
	local tableToSearch = if h1_tag_classes != undefined then h1_tag_classes else h1_tag_classes_engine
	for tagEntry in tableToSearch do
	(
		if tagEntry[1] == tagName and tagEntry[3] != undefined then
			return tagEntry[3]
	)
	undefined
)

-- Convert tag class fourcc to readable display string
fn getTagClassInfo tagClass =
(
	local tableToSearch = if h1_tag_classes != undefined then h1_tag_classes else h1_tag_classes_engine
	for tagEntry in tableToSearch do
	(
		if tagEntry[3] != undefined and tagEntry[3] == tagClass then
			return (tagEntry[1] + " (" + tagEntry[2] + ")")
	)
	tagClass as string
)

-- Convert engine ID to readable string
fn getEngineIdInfo engineId =
(
	if engineId == 1651269997 then "blam (halo_1)"
	else (engineId as string)
)

-------------------------------------------------------
-- Material Type Enum
-------------------------------------------------------

-- Convert material type enum value to readable string
fn materialTypeToString matType =
(
	case matType of
	(
		0: "dirt";
		1: "sand";
		2: "stone";
		3: "snow";
		4: "wood";
		5: "metal hollow";
		6: "metal thin";
		7: "metal thick";
		8: "rubber";
		9: "glass";
		10: "force field";
		11: "grunt";
		12: "hunter armor";
		13: "hunter skin";
		14: "elite";
		15: "jackal";
		16: "jackal energy shield";
		17: "engineer skin";
		18: "engineer force field";
		19: "flood combat form";
		20: "flood carrier form";
		21: "cyborg armor";
		22: "cyborg energy shield";
		23: "human armor";
		24: "human skin";
		25: "sentinel";
		26: "monitor";
		27: "plastic";
		28: "water";
		29: "leaves";
		30: "elite energy shield";
		31: "ice";
		32: "hunter shield";
		default: ("unknown_" + (matType as string))
	)
)