tagCollectionTagreferencesFields = #(
    tagField \
        name:"tag" \
        hidden:false \
        type:#tagReference \
        allowed:#(#ui_widget_definition,#ui_widget_collection,#actor,#actor_variant,#antenna,#model_animations,#biped,#bitmap,#spheroid,#continuous_damage_effect,#model_collision_geometry,#color_table,#contrail,#device_control,#decal,#device,#detail_object_collection,#effect,#lightning,#equipment,#flag,#fog,#font,#material_effects,#garbage,#glow,#grenade_hud_interface,#hud_message_text,#hud_number,#hud_globals,#item,#item_collection,#damage_effect,#lens_flare,#device_light_fixture,#light,#sound_looping,#device_machine,#globals,#meter,#light_volume,#gbxmodel,#model,#multiplayer_scenario_description,#preferences_network_game,#object,#particle,#particle_system,#physics,#placeholder,#point_physics,#projectile,#weather_particle_system,#scenario_structure_bsp,#scenery,#shader_transparent_chicago_extended,#shader_transparent_chicago,#scenario,#shader_environment,#shader_transparent_glass,#shader,#sky,#shader_transparent_meter,#sound,#sound_environment,#shader_model,#shader_transparent_generic,#shader_transparent_plasma,#sound_scenery,#string_list,#shader_transparent_water,#tag_collection,#camera_track,#dialogue,#unit_hud_interface,#unit,#unicode_string_list,#virtual_keyboard,#vehicle,#weapon,#wind,#weapon_hud_interface)
)

tagCollectionTagreferencesBlock = tagBlock \
    name:"tagReferencesBlock" \
    length:16 \
    maximum:200 \
    fields:tagCollectionTagreferencesFields

tagCollectionFields = #(
    tagField \
        name:"tagReferences" \
        hidden:false \
        type:#block \
        block:tagCollectionTagreferencesBlock
)

tagCollectionBlock = tagBlock \
    name:"tagCollectionBlock" \
    length:12 \
    maximum:1 \
    fields:tagCollectionFields

tagCollectionDef = tagDef \
    fourcc:1952540515 \
    supergroup:undefined \
    tagBlock:tagCollectionBlock
