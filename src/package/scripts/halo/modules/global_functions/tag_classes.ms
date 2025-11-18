/*
Halo CE Tag Classes 
Shared utility functions for reading binary tag data
*/

-- (short_name, full_name, fourcc_binary)
global h1_tag_classes = #(
    #("actr", "actor", 1633907826),
    #("actv", "actor_variant", 1633907830),
    #("ant!", "antenna", 1634628641),
    #("antr", "model_animations", 1634628722),
    #("bipd", "biped", 1651077220),
    #("bitm", "bitmap", 1651078253),
    #("boom", "spheroid", undefined),  -- Leftover tag?
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

-- Convert tag class to readable string with both short and full names
fn tagClassToString tagClass returnFullName:false =
(
    -- Search through the tag class table
    for tagEntry in h1_tag_classes do
    (
        if tagEntry[3] != undefined and tagEntry[3] == tagClass then
        (
            if returnFullName then
                return tagEntry[2]  -- Return full name like "model_collision_geometry"
            else
                return tagEntry[1]  -- Return short name like "coll"
        )
    )
    
    -- Handle special cases
    case tagClass of
    (
        4294967295: if returnFullName then "NONE" else "NONE"
        0: if returnFullName then "NULL" else "NULL"
        default: (tagClass as string)  -- Show raw value for unknown tags
    )
)

-- Get fourcc_binary by short tag name
fn getFourccByTagName tagName =
(
    -- Search through the tag class table
    for tagEntry in h1_tag_classes do
    (
        if tagEntry[1] == tagName and tagEntry[3] != undefined then
            return tagEntry[3]  -- Return fourcc_binary
    )
    undefined  -- Tag not found or fourcc_binary not defined
)

-- Get formatted tag class string with both short and full names
fn getTagClassInfo tagClass =
(
    local shortName = tagClassToString tagClass
    local fullName = tagClassToString tagClass returnFullName:true
    
    if shortName == (tagClass as string) then
        shortName  -- Unknown tag, just return the number
    else if shortName == fullName then
        shortName  -- Same name (like "NONE"), don't duplicate
    else
        (shortName + " (" + fullName + ")")  -- Format: "coll (model_collision_geometry)"
)