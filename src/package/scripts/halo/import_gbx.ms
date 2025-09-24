-- Halo Custom Edition GBX/XBOX Model Importer
-- (for 3ds Max v5+ and gmax v1.2)
-- Version 5.2.2
-- Created by TheGhost
-- Contributions by:
-- 
-- Moses
-- Mark Mc'Fuzz
------------------------------------------------------------------------------------------------
-- Import Features:
-- - Import any geometry from the tag with many import options
-- - Import perfect UVW coordinates and material ID's
-- - Setup the max material library for the model's shaders
-- - Import model's nodes and/or markers with many options
--     (nodes/markers are perfectly placed and rotated)
-- - Optionally import biped nodes as bone objects
-- - Imports vertex weights for a fully rigged model
-- - Imports xbox models from both Halo and Stubbs the Zombie
------------------------------------------------------------------------------------------------
-- Instructions: Click the "Load GBX/XBOX Model" button and navigate to
-- the desired GBXModel or Xbox Model tag. Select from the import options
-- and press the "Import    GBX/XBOX Model" button to import the tag.
------------------------------------------------------------------------------------------------
-- Visit the project on GitHub
------------------------------------------------------------------------------------------------
-- Copyright (C) 2006 Adam Papamarcos (mailto:papamarcos@gmail.com)
-- This program is free software; you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by the
-- Free Software Foundation; either version 2 of the License, or (at your
-- option) any later version. This program is distributed in the hope that
-- it will be useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
-- the GNU General Public License for more details. A full copy of this
-- license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

-- Detect 3ds max or gmax
gMax = (maxVersion())[1]<=4200
grabListenerPath = getDir #scripts -- Or specify your own path, like "c:\\program files\\autodesk\\3ds max\\scripts"
scriptFilePath = getDir #scripts

aboutString = "Copyright (C) 2006 Adam Papamarcos\n"+ \
		"\n"+ \
		"Contributions by:\n\n"+ \
		"TheGhost (adapted for HaloCE)\n"+ \
        "Moses (fixes for nodes/bones)\n"+ \
        "Mark Mc'Fuzz (improvement script and UI)"

fn dlgAbout = (
	messagebox aboutString title:"About GBX Importer"
)

unknown_blocks = 0

marker_blocks = 0
marker_name = #()
marker_instance_blocks = #()
marker_instance_region_index = #()
marker_instance_permutation_index = #()
marker_instance_node_index = #()
marker_instance_translation = #()
marker_instance_rotation = #()

gbx_node_blocks = 0
gbx_node_name = #()
gbx_node_next_sibling_node_index = #()
gbx_node_first_child_node_index = #()
gbx_node_parent_node_index = #()
gbx_node_translation = #()
gbx_node_rotation = #()
gbx_node_distance_from_parent = #()

region_blocks = 0
region_name = #()
region_permutation_blocks = #()
region_permutation_name = #()
region_permutation_LOD_indices = #()
region_permutation_marker_blocks = #()
region_permutation_marker_name = #()
region_permutation_marker_node_index = #()
region_permutation_marker_rotation = #()
region_permutation_marker_translation = #()

geometry_blocks = 0
geometry_part_blocks = #()
geometry_part_shader_index = #()
geometry_part_vert_offset = #()
geometry_part_tri_offset = #()
geometry_part_uncompressed_vertex_blocks = #()
geometry_part_compressed_vertex_blocks = #()
geometry_part_vertex_blocks = #()
geometry_part_triangle_blocks = #()
geometry_part_local_nodes = #()

uncompressed_vert_sum = 0
compressed_vert_sum   = 0
shader_blocks = 0
shader_name = #()

gbx_node_array = #()
marker_array = #()

model_type = 0
vertex_type = 0
node_list_checksum = 0
gbx_tmp_buffer = undefined
gbx_in_file = undefined
in_name = undefined
local_nodes = false
u_scale = 1.0
v_scale = 1.0
ceRoot = ""
tagLoc = ""
global tagName = ""

v = maxVersion()
maxVer = (v[1] / 1000.0) as string

fn gbxReadUShortB =
(
    b1 = readByte gbx_in_file #unsigned
    b2 = readByte gbx_in_file #unsigned
    (b1 * 256) + b2
)
fn gbxReadShortB =
(
    b1 = readByte gbx_in_file #unsigned
    b2 = readByte gbx_in_file #unsigned
    if b1 > 127 then 
    (
        ((b1 * 256) + b2) - 65536
    )
     else 
     (
        (b1 * 256) + b2
    )
)

fn gbxReadULongB =
(
    b1 = readByte gbx_in_file #unsigned
    b2 = readByte gbx_in_file #unsigned
    b3 = readByte gbx_in_file #unsigned
    b4 = readByte gbx_in_file #unsigned
    (b1 * 16777216) + (b2 * 65536) + (b3 * 256) + (b4 * 1)
)

fn gbxReadLongB =
(
    b1 = readByte gbx_in_file #unsigned
    b2 = readByte gbx_in_file #unsigned
    b3 = readByte gbx_in_file #unsigned
    b4 = readByte gbx_in_file #unsigned
    if b1 > 127 then
    (
        ((b1 * 16777216) + (b2 * 65536) + (b3 * 256) + b4) - 4294967296
    )
    else
    (
        (b1 * 16777216) + (b2 * 65536) + (b3 * 256) + b4
    )
)

fn gbxReadFloatB =
(
    local myBitArray = #{}
    b1 = readByte gbx_in_file #unsigned
    b2 = readByte gbx_in_file #unsigned
    b3 = readByte gbx_in_file #unsigned
    b4 = readByte gbx_in_file #unsigned
    fseek gbx_tmp_buffer 0 #seek_set
    WriteByte gbx_tmp_buffer b4
    WriteByte gbx_tmp_buffer b3
    WriteByte gbx_tmp_buffer b2
    WriteByte gbx_tmp_buffer b1
    fseek gbx_tmp_buffer 0 #seek_set
    readFloat gbx_tmp_buffer
)

fn gbxReadQuat =
(
    q1 = gbxReadFloatB()
    q2 = gbxReadFloatB()
    q3 = gbxReadFloatB()
    q4 = gbxReadFloatB()
    normalize (quat q1 q2 q3 q4)
)

fn gbxReadTrans =
(
    [gbxReadFloatB() * 100, gbxReadFloatB() * 100, gbxReadFloatB() * 100]
)

fn getFlagArray num =
(
    local myBitArray = #{}
    for i = 1 to 8 do
    (
        myBitArray[i] = (mod num 2 > .5)
        num /= 2
    )
    myBitArray
)

rollout gbxImporter "GBX/XBOX Model Importer" width:448 height:584
(
    GroupBox grp2 "User Information" pos:[8, 8] width:432 height:40
	Label edt_info "" pos:[13, grp2.pos.y + 17] width:176 height:18

    GroupBox grp_load "Loaded File" pos:[8, grp2.pos.y + grp2.height + 8] width:432 height:82
    button load_button "Load GBX/XBOX Model" pos:[136, grp_load.pos.y + 17] width:140 height:29
    button unload_button "Unload GBX/XBOX Model" pos:[284, grp_load.pos.y + 17] width:140 height:29
    label lbl_model "Path:" pos:[19, unload_button.pos.y + unload_button.height + 10] width:38 height:16
    edittext edt_model "" pos:[52, unload_button.pos.y + unload_button.height + 8] width:370 height:16 readonly:true

    GroupBox grp_select "LOD / Region / Permutation Selection" pos:[8, grp_load.height + grp_load.pos.y + 8] width:432 height:122
    radiobuttons radio_LOD "Select LOD" pos:[18, grp_select.pos.y + 17] width:72 height:94 labels:#("super high", "high", "medium", "low", "super low") default:1 columns:1
    listbox listbox_permutation "Select Model Permutation" pos:[267, grp_select.pos.y + 24] width:156 height:5
    listbox listbox_region "Select Model Region" pos:[97, grp_select.pos.y + 24] width:160 height:5

    GroupBox grp_import_selection "Import Geometry Selection" pos:[8, grp_select.height + grp_select.pos.y + 8] width:432 height:72
    radiobuttons radio_geometry ""
    pos:[16, grp_import_selection.pos.y + 17]
    width:206 height:51
    labels:#(
        "Selected Permutation from All Regions",
        "All Permutations of Selected Region",
        "Selected Region and Permutation Only"
    )
    checkbox chk_model "Import Model Geometry" pos:[243, radio_geometry.pos.y - 3] width:132 height:17 checked:true
    checkbox chk_node "Import All Nodes" pos:[243, chk_model.pos.y + 17] width:100 height:17 checked:true
    checkbox chk_marker "Import Markers" pos:[243, chk_node.pos.y + 17] width:100 height:17 checked:true

    GroupBox grp_model_options "Model Geometry Options" pos:[8, grp_import_selection.pos.y + grp_import_selection.height + 8] width:220 height:128
    checkbox chk_attach "Attach Parts of Mesh Within Region" pos:[16, grp_model_options.pos.y + 17] width:192 height:17 checked:true
    checkbox chk_uvw "Import UVW Coordinates and MatID's" pos:[16, chk_attach.pos.y + 17] width:204 height:17 checked:true
    checkbox chk_matlib "Setup 3ds Material Library Shaders" pos:[16, chk_uvw.pos.y + 17] width:204 height:17 checked:true
    checkbox chk_weight "Import Vertex Weights (Rigged Model)" pos:[16, chk_matlib.pos.y + 17] width:204 height:17 checked:true

    GroupBox grp_node_marker_options "Node/Marker Options" pos:[grp_model_options.width + 15, grp_import_selection.pos.y + grp_import_selection.height + 8] width:205 height:128
    checkbox chk_bone "Import All Nodes as Bones" pos:[grp_node_marker_options.pos.x + 8, grp_node_marker_options.pos.y + 17] width:144 height:15
    checkbox chk_bip "Only Biped Nodes as Bones" pos:[grp_node_marker_options.pos.x + 8, chk_bone.pos.y + 17] width:150 height:15
    checkbox chk_reuse "Reuse Previously Imported Nodes" pos:[grp_node_marker_options.pos.x + 8, chk_bip.pos.y + 17] width:180 height:15 checked:false
    checkbox chk_detect "Detect Existing Nodes in Scene" pos:[grp_node_marker_options.pos.x + 8, chk_reuse.pos.y + 17] width:180 height:15 checked:false
    label lbl_node "Node Radius" pos:[chk_bone.pos.x + 19, chk_detect.pos.y + 19] width:64 height:13
    label lbl_marker "Marker Radius" pos:[chk_bone.pos.x + 19, lbl_node.pos.y + 19] width:71 height:13
    spinner spn_node "" pos:[lbl_node.pos.x + 72, chk_detect.pos.y + 19] width:42 height:16 range:[0.01,30,1]
    spinner spn_marker "" pos:[lbl_marker.pos.x + 72, lbl_node.pos.y + 19] width:42 height:16 range:[0.01,30,0.5]

    local grpImportCenterSize = 448/2
    local importButtonWidth = 140
    local importButtonCenterSize = importButtonWidth/2
    GroupBox grp_import "Import Button" pos:[8, grp_node_marker_options.pos.y + grp_node_marker_options.height + 8] width:432 height:54
    button import_button "Import GBX/XBOX Model" pos:[grpImportCenterSize - importButtonCenterSize, grp_import.pos.y + 17] width:importButtonWidth height:29
    --label lbl_by "Script by TheGhost/Moses." pos:[16,457] width:130 height:15 enabled:false
    --label lbl_version "v5.2.1" pos:[400,457] width:37 height:15 enabled:false

    button btAbout "About" pos:[8, grp_import.pos.y + grp_import.height + 8] width:150 height:20 across:2
    label versionLbl "v5.2.2" pos:[400, btAbout.pos.y + 2] width:32 height:20

    on btAbout pressed do dlgAbout()

    on gbxImporter open do
    (
        ClearListener()

        if gMax then
		(
			edt_info.text = "  Max version " + maxVer + " (gmax) detected."
		)
		else
		(
			edt_info.text = "  3ds Max version " + maxVer + " detected."
		)

		-- Set the model path
		edt_model.text = (" " + tagLoc + tagName + (if model_type == 0 then ".model" else ".gbxmodel"))

		-- Setup UI with loaded model data
		listbox_region.items = region_name
        if region_name.count > 0 then (
            listbox_permutation.items = region_permutation_name[1]
            listbox_region.selection = 1
            listbox_permutation.selection = 1
        ) else (
            listbox_permutation.items = region_name
            listbox_region.selection = 0
            listbox_permutation.selection = 0
        )
    )
    on gbxImporter close do
    (
        if gbx_in_file != undefined do fclose gbx_in_file
        if gbx_tmp_buffer != undefined do fclose gbx_tmp_buffer
    )
    on unload_button pressed do
    (
        fclose gbx_in_file
        unload_button.enabled = false
        lbl_model.enabled = false
        edt_model.text = ""
        grp_select.enabled = false
        radio_LOD.enabled = false
        listbox_permutation.enabled = false
        listbox_region.enabled = false
        listbox_permutation.items = #()
        listbox_region.items = #()
        grp_import_selection.enabled = false
        radio_geometry.enabled = false
        chk_model.enabled = false
        chk_node.enabled = false
        chk_marker.enabled = false
        grp_model_options.enabled = false
        chk_attach.enabled = false
        chk_uvw.enabled = false
        chk_matlib.enabled = false
        chk_weight.enabled = false
        grp_node_marker_options.enabled = false
        chk_bone.enabled = false
        chk_bip.enabled = false
        chk_reuse.enabled = false
        chk_detect.enabled = false
        lbl_node.enabled = false
        lbl_marker.enabled = false
        spn_node.enabled = false
        spn_marker.enabled = false
        grp_import.enabled = false
        import_button.enabled = false
    )
    on load_button pressed do
        (
        in_name = getOpenFileName \
            filename: "C:\\Program Files\\Microsoft Games\\Halo Custom Edition\\tags\\" \
            types: "GBXModel Tag (*.gbxmodel)|*.gbxmodel|Model Tag (*.model)|*.model|All Tag Files (*.*)|*.*"
            
        if in_name != undefined then
        (
            gbx_in_file = fopen in_name "rbR"
            if gbx_in_file == undefined then
            (
                messageBox "Error in opening file!" title:"File opening error"
            )
            else
            (
                print ("Opened File: " + in_name)
                fseek gbx_in_file 36 #seek_set
                tag_type = gbxReadULongB ()
                print ("Tag type check: " + tag_type as string)
                model_type  = -1
                vertex_type = -1
                --*vertex_type: 0 == compressed   1 == uncompressed*
                if tag_type == 1836016741 then
                (
                    model_type  = 0--*recognized as Xbox Model*
                    vertex_type = 0
                )
                if tag_type == 1836016690 then
                (
                    model_type  = 1--*recognized as GBX Model*
                    vertex_type = 1
                )

                if model_type == -1 then
                (
                    messageBox "Error: Incorrect file type!\n\nPlease select a valid .gbxmodel or .model tag.  " \
                        title:"Incorrect file type error"
                )
                else
                (
                    start1 = timeStamp()
                    
                    local_nodes = false
                    unload_button.enabled = true
                    lbl_model.enabled = true
                    grp_select.enabled = true
                    radio_LOD.enabled = true
                    listbox_permutation.enabled = true
                    listbox_region.enabled = true
                    grp_import_selection.enabled = true
                    radio_geometry.enabled = true
                    chk_model.enabled = true
                    chk_node.enabled = true
                    chk_marker.enabled = true
                    grp_model_options.enabled = true
                    chk_attach.enabled = true
                    chk_uvw.enabled = true
                    chk_matlib.enabled = true
                    chk_weight.enabled = true
                    grp_node_marker_options.enabled = true
                    chk_bone.enabled = true
                    chk_bip.enabled = true
                    chk_reuse.enabled = true
                    chk_detect.enabled = true
                    lbl_node.enabled = true
                    lbl_marker.enabled = true
                    spn_node.enabled = true
                    spn_marker.enabled = true
                    grp_import.enabled = true
                    import_button.enabled = true
                    
                    unknown_blocks = 0
                    marker_blocks = 0
                    marker_name = #()
                    marker_instance_blocks = #()
                    marker_instance_region_index = #()
                    marker_instance_permutation_index = #()
                    marker_instance_node_index = #()
                    marker_instance_translation = #()
                    marker_instance_rotation = #()
                    gbx_node_blocks = 0
                    gbx_node_name = #()
                    gbx_node_next_sibling_node_index = #()
                    gbx_node_first_child_node_index = #()
                    gbx_node_parent_node_index = #()
                    gbx_node_translation = #()
                    gbx_node_rotation = #()
                    gbx_node_distance_from_parent = #()
                    region_blocks = 0
                    region_name = #()
                    region_permutation_blocks = #()
                    region_permutation_name = #()
                    region_permutation_LOD_indices = #()
                    region_permutation_marker_blocks = #()
                    region_permutation_marker_name = #()
                    region_permutation_marker_node_index = #()
                    region_permutation_marker_rotation = #()
                    region_permutation_marker_translation = #()
                    geometry_blocks = 0
                    geometry_part_blocks = #()
                    geometry_part_shader_index = #()
                    geometry_part_vert_offset = #()
                    geometry_part_tri_offset = #()
                    geometry_part_uncompressed_vertex_blocks = #()
                    geometry_part_compressed_vertex_blocks = #()
                    geometry_part_vertex_blocks = #()
                    geometry_part_triangle_blocks = #()
                    geometry_part_local_nodes = #()
                    shader_blocks = 0
                    uncompressed_vert_sum = 0
                    compressed_vert_sum   = 0
                    shader_name = #()
                    
                    ss = in_name as StringStream
                    skipToString ss "tags\\"
                    startPos = filePos ss
                    ceRoot = substring in_name 1 (startPos - 5)
                    global filenamePath = getFilenamePath in_name
                    tagLoc = substring filenamePath (startPos+1) -1
                    global tagName = getFilenameFile in_name
                    if model_type == 0 then
                    (
                        edt_model.text = (" " + tagLoc + tagName + ".model")
                    )
                    else
                    (
                        edt_model.text = (" " + tagLoc + tagName + ".gbxmodel")
                    )
                            
                    print ("-------------------------------------------------------")
                    
                    fseek gbx_in_file 66 #seek_set
                    flags = gbxReadUShortB ()
                    model_flags = getFlagArray flags
                    print ("Model Flags: " + model_flags as string)

                    local_nodes = false--*local nodes were implemented in PC and don't exist on XBOX*
                    if model_flags[2] == true and model_type == 1 then
                    (
                        local_nodes = true
                        print ("Model uses local nodes")
                    )
                    
                    fseek gbx_in_file 68 #seek_set
                    node_list_checksum = gbxReadLongB ()
                    print ("Node List Checksum: " + node_list_checksum as string)
                    
                    fseek gbx_in_file 112 #seek_set
                    u_scale = gbxReadFloatB()
                    fseek gbx_in_file 112 #seek_set
                    if readFloat gbx_in_file == 0.0 do u_scale = 1.0
                    print ("Base Map U-Scale: " + u_scale as string)
                    
                    fseek gbx_in_file 116 #seek_set
                    v_scale = gbxReadFloatB()
                    fseek gbx_in_file 116 #seek_set
                    if readFloat gbx_in_file == 0.0 do v_scale = 1.0
                    print ("Base Map V-Scale: " + v_scale as string)
                    
                    print ("-------------------------------------------------------")

                    fseek gbx_in_file 224 #seek_set
                    unknown_blocks = gbxReadULongB ()
                    print ("Unknown Blocks: " + unknown_blocks as string)

                    fseek gbx_in_file 236 #seek_set
                    marker_blocks = gbxReadULongB ()
                    print ("Marker Blocks: " + marker_blocks as string)
                    
                    fseek gbx_in_file 248 #seek_set
                    gbx_node_blocks = gbxReadULongB ()
                    print ("Node Blocks: " + gbx_node_blocks as string)
                    
                    fseek gbx_in_file 260 #seek_set
                    region_blocks = gbxReadULongB ()
                    print ("Region Blocks: " + region_blocks as string)
                    
                    fseek gbx_in_file 272 #seek_set
                    geometry_blocks = gbxReadULongB ()
                    print ("Geometry Blocks: " + geometry_blocks as string)
                    
                    fseek gbx_in_file 284 #seek_set
                    shader_blocks = gbxReadULongB ()
                    print ("Shader Blocks: " + shader_blocks as string)
                    
                    print ("-------------------------------------------------------")
                    
                    fseek gbx_in_file 296 #seek_set
                    
                    --*skip all the unknown_blocks*
                    fseek gbx_in_file (unknown_blocks*64) #seek_cur
                    
                    print ("Marker block offset: " + (ftell gbx_in_file) as string)
                    
                    for m = 1 to marker_blocks do
                    (
                        offset = (ftell gbx_in_file)
                        marker_name[m] = readString gbx_in_file
                        fseek gbx_in_file (offset + 32) #seek_set
                        fseek gbx_in_file 20 #seek_cur
                        marker_instance_blocks[m] = gbxReadULongB ()
                        fseek gbx_in_file 8 #seek_cur
                    )
                    for m = 1 to marker_blocks do
                    (
                        temp_region_index = #()
                        temp_permutation_index = #()
                        temp_node_index = #()
                        temp_translation = #()
                        temp_rotation = #()
                        for i = 1 to marker_instance_blocks[m] do
                        (
                            temp_region_index[i] = readByte gbx_in_file #unsigned
                            temp_permutation_index[i] = readByte gbx_in_file #unsigned
                            temp_node_index[i] = readByte gbx_in_file #unsigned
                            fseek gbx_in_file 1 #seek_cur
                            temp_translation[i] = gbxReadTrans()
                            temp_rotation[i] = gbxReadQuat()
                        )
                        marker_instance_region_index[m] = temp_region_index
                        marker_instance_permutation_index[m] = temp_permutation_index
                        marker_instance_node_index[m] = temp_node_index
                        marker_instance_translation[m] = temp_translation
                        marker_instance_rotation[m] = temp_rotation
                    )
                    
                    print ("Node block offset: " + (ftell gbx_in_file) as string)
                    
                    for n = 1 to gbx_node_blocks do
                    (
                        offset = (ftell gbx_in_file)
                        gbx_node_name[n] = readString gbx_in_file
                        fseek gbx_in_file (offset + 32) #seek_set
                        gbx_node_next_sibling_node_index[n] = gbxReadShortB ()
                        gbx_node_first_child_node_index[n] = gbxReadShortB ()
                        gbx_node_parent_node_index[n] = gbxReadShortB ()
                        fseek gbx_in_file 2 #seek_cur
                        gbx_node_translation[n] = gbxReadTrans()
                        gbx_node_rotation[n] = gbxReadQuat()
                        gbx_node_distance_from_parent[n] = gbxReadFloatB()
                        fseek gbx_in_file 84 #seek_cur
                    )
                    
                    print ("Region block offset: " + (ftell gbx_in_file) as string)
                    
                    for r = 1 to region_blocks do
                    (
                        offset = (ftell gbx_in_file)
                        region_name[r] = readString gbx_in_file
                        fseek gbx_in_file (offset + 32) #seek_set
                        fseek gbx_in_file 32 #seek_cur
                        region_permutation_blocks[r] = gbxReadULongB ()
                        fseek gbx_in_file 8 #seek_cur
                    )
                    for r = 1 to region_blocks do
                    (
                        temp_permutation_name = #()
                        temp_permutation_LOD_indices = #()
                        temp_permutation_marker_blocks = #()
                        for p = 1 to region_permutation_blocks[r] do
                        (
                            offset = (ftell gbx_in_file)
                            temp_permutation_name[p] = readString gbx_in_file
                            fseek gbx_in_file (offset + 32) #seek_set
                            fseek gbx_in_file 32 #seek_cur
                            superlow = gbxReadShortB ()
                            low = gbxReadShortB ()
                            medium = gbxReadShortB ()
                            high = gbxReadShortB ()
                            superhigh = gbxReadShortB ()
                            temp_permutation_LOD_indices[p] = #(superlow, low, medium, high, superhigh)
                            fseek gbx_in_file 2 #seek_cur
                            temp_permutation_marker_blocks[p] = gbxReadULongB ()
                            fseek gbx_in_file 8 #seek_cur
                        )
                        region_permutation_name[r] = temp_permutation_name
                        region_permutation_LOD_indices[r] = temp_permutation_LOD_indices
                        region_permutation_marker_blocks[r] = temp_permutation_marker_blocks
                        
                        temp_permutation_marker_name = #()
                        temp_permutation_marker_node_index = #()
                        temp_permutation_marker_rotation = #()
                        temp_permutation_marker_translation = #()
                        for p = 1 to region_permutation_blocks[r] do
                        (
                            temp_marker_name = #()
                            temp_marker_node_index = #()
                            temp_marker_rotation = #()
                            temp_marker_translation = #()
                            for m = 1 to region_permutation_marker_blocks[r][p] do
                            (
                                offset = (ftell gbx_in_file)
                                temp_marker_name[m] = readString gbx_in_file
                                fseek gbx_in_file (offset + 32) #seek_set
                                temp_marker_node_index[m] = gbxReadShortB ()
                                fseek gbx_in_file 2 #seek_cur
                                temp_marker_rotation[m] = gbxReadQuat()
                                temp_marker_translation[m] = gbxReadTrans()
                                fseek gbx_in_file 16 #seek_cur
                            )
                            temp_permutation_marker_name[p] = temp_marker_name
                            temp_permutation_marker_node_index[p] = temp_marker_node_index
                            temp_permutation_marker_rotation[p] = temp_marker_rotation
                            temp_permutation_marker_translation[p] = temp_marker_translation
                        )
                        region_permutation_marker_name[r] = temp_permutation_marker_name
                        region_permutation_marker_node_index[r] = temp_permutation_marker_node_index
                        region_permutation_marker_rotation[r] = temp_permutation_marker_rotation
                        region_permutation_marker_translation[r] = temp_permutation_marker_translation
                    )
                    
                    print ("Geometry block offset: " + (ftell gbx_in_file) as string)
                    
                    for g = 1 to geometry_blocks do
                    (
                        fseek gbx_in_file 36 #seek_cur
                        geometry_part_blocks[g] = gbxReadULongB ()
                        fseek gbx_in_file 8 #seek_cur
                    )

                    uncompressed_vert_sum = 0
                    compressed_vert_sum   = 0
                    for g = 1 to geometry_blocks do
                    (
                        temp_part_shader_index = #()
                        temp_part_uncompressed_vertex_blocks = #()
                        temp_part_compressed_vertex_blocks = #()
                        temp_part_vertex_blocks = #()
                        temp_part_triangle_blocks = #()
                        if local_nodes == true do temp_part_local_nodes = #()
                        for p = 1 to geometry_part_blocks[g] do
                        (
                            fseek gbx_in_file 4 #seek_cur
                            temp_part_shader_index[p] = gbxReadShortB ()
                            fseek gbx_in_file 26 #seek_cur
                            temp_part_uncompressed_vertex_blocks[p] = gbxReadULongB ()
                            fseek gbx_in_file 8 #seek_cur
                            temp_part_compressed_vertex_blocks[p] = gbxReadULongB ()
                            fseek gbx_in_file 8 #seek_cur
                            temp_part_triangle_blocks[p] = gbxReadULongB ()
                            
                            uncompressed_vert_sum = uncompressed_vert_sum + temp_part_uncompressed_vertex_blocks[p]
                            compressed_vert_sum   = compressed_vert_sum   + temp_part_compressed_vertex_blocks[p]
                            if model_type == 0 then
                            (
                                fseek gbx_in_file 44 #seek_cur
                            )
                            else
                            (
                                offset = (ftell gbx_in_file)
                                if local_nodes == true then
                                (
                                    fseek gbx_in_file 46 #seek_cur
                                    number_local_nodes = gbxReadUShortB ()
                                    the_local_nodes = #()
                                    for n = 1 to number_local_nodes do
                                    (
                                        append the_local_nodes (readByte gbx_in_file #unsigned)
                                    )
                                    temp_part_local_nodes[p] = the_local_nodes
                                )
                                fseek gbx_in_file (offset + 72) #seek_set
                            )
                        )
                        if model_type == 1 and uncompressed_vert_sum == 0 and compressed_vert_sum > 0 then
                        (
                            vertex_type = 0
                        )
                        if model_type == 0 and compressed_vert_sum == 0 and uncompressed_vert_sum > 0 then
                        (
                            vertex_type = 1
                        )
                        geometry_part_shader_index[g] = temp_part_shader_index
                        geometry_part_compressed_vertex_blocks[g] = temp_part_compressed_vertex_blocks
                        geometry_part_uncompressed_vertex_blocks[g] = temp_part_uncompressed_vertex_blocks
                        geometry_part_triangle_blocks[g] = temp_part_triangle_blocks
                        if vertex_type == 0 then
                        (
                            geometry_part_vertex_blocks[g] = temp_part_compressed_vertex_blocks
                        )
                        else
                        (
                            geometry_part_vertex_blocks[g] = temp_part_uncompressed_vertex_blocks
                        )
                        if local_nodes == true do geometry_part_local_nodes[g] = temp_part_local_nodes
                        
                        temp_part_vert_offset = #()
                        temp_part_tri_offset  = #()
                        for p = 1 to geometry_part_blocks[g] do
                        (
                            if vertex_type == 1 then
                            (
                                temp_part_vert_offset[p] = ftell gbx_in_file
                            )
                            fseek gbx_in_file (geometry_part_uncompressed_vertex_blocks[g][p] * 68) #seek_cur
                            if vertex_type == 0 then
                            (
                                temp_part_vert_offset[p] = ftell gbx_in_file
                            )
                            fseek gbx_in_file (geometry_part_compressed_vertex_blocks[g][p] * 32) #seek_cur
                            temp_part_tri_offset[p] = ftell gbx_in_file
                            fseek gbx_in_file (geometry_part_triangle_blocks[g][p] * 6) #seek_cur
                        )
                        geometry_part_vert_offset[g] = temp_part_vert_offset
                        geometry_part_tri_offset[g]  = temp_part_tri_offset
                    )
                    
                    print ("Shader block offset: " + (ftell gbx_in_file) as string)
                    
                    fseek gbx_in_file (shader_blocks * 32) #seek_cur
                    for s = 1 to shader_blocks do
                    (
                        shader_dir = readString gbx_in_file
                        ss = shader_dir as StringStream
                        d2 = 1
                        d1 = 0
                        while d1 < d2 do
                        (
                            temp_pos = filePos ss
                            skipToString ss "\t"
                            d2 = filePos ss - temp_pos
                            seek ss temp_pos
                            skipToString ss "\\"
                            d1 = filePos ss - temp_pos
                        )
                        seek ss temp_pos
                        shader_name[s] = readDelimitedString ss "\t"
                    )
                    
                    print ("-------------------------------------------------------")
                    
                    end1 = timeStamp()
                    print ("Model indexing took " + ((end1 - start1) as float / 1000.0) as string + " seconds")
                    
                    listbox_region.items = region_name
                    if region_name.count > 0 then (
                        listbox_permutation.items = region_permutation_name[1]
                        listbox_region.selection = 1
                        listbox_permutation.selection = 1
                    ) else (
                        listbox_permutation.items = region_name
                        listbox_region.selection = 0
                        listbox_permutation.selection = 0
                    )
                )
            )
        )
    )
    on listbox_region selected i do
    (
        listbox_permutation.items = region_permutation_name[i]
    )
    on chk_model changed theState do
    (
        if theState == true then
        (
            chk_attach.checked = true
            chk_attach.enabled = true
            chk_uvw.checked = true
            chk_uvw.enabled = true
            chk_matlib.checked = true
            chk_matlib.enabled = true
            chk_weight.enabled = true
            chk_weight.checked = true
            grp_model_options.enabled = true
        )
        else
        (
            chk_attach.checked = false
            chk_attach.enabled = false
            chk_uvw.checked = false
            chk_uvw.enabled = false
            chk_matlib.checked = false
            chk_matlib.enabled = false
            chk_weight.checked = false
            chk_weight.enabled = false
            grp_model_options.enabled = false
        )
    )
    on chk_node changed theState do
    (
        if theState == true then
        (
            chk_bone.enabled = true
            chk_bip.enabled = true
            lbl_node.enabled = true
            spn_node.enabled = true
            grp_node_marker_options.enabled = true
        )
        else
        (
            chk_bone.checked = false
            chk_bone.enabled = false
            chk_bip.checked = false
            chk_bip.enabled = false
            lbl_node.enabled = false
            spn_node.enabled = false
            if chk_marker.checked == false then
            (
                grp_node_marker_options.enabled = false
            )
        )
    )
    on chk_marker changed theState do
    (
        if theState == true then
        (
            lbl_marker.enabled = true
            spn_marker.enabled = true
            grp_node_marker_options.enabled = true
        )
        else
        (
            lbl_marker.enabled = false
            spn_marker.enabled = false
            if chk_node.checked == false then
            (
                grp_node_marker_options.enabled = false
            )
        )
    )
    on chk_bone changed theState do
    (
        if theState == true then
        (
            chk_bip.checked = false
        )
    )
    on chk_bip changed theState do
    (
        if theState == true then
        (
            chk_bone.checked = false
        )
    )
    on chk_detect changed theState do
    (
        if theState == true then
        (
            chk_reuse.checked = false
        )
    )
    on chk_reuse changed theState do
    (
        if theState == true then
        (
            chk_detect.checked = false
        )
    )
    on import_button pressed do
    (
        region_index = listbox_region.selection
        permutation_index = listbox_permutation.selection
        LOD_index = radio_LOD.state
        LOD_switch = #(5, 4, 3, 2, 1)
        reuse_nodes = chk_reuse.checked and (gbx_node_array.count == gbx_node_blocks)
        import_nodes = chk_node.checked

        if region_index == 0 or permutation_index == 0 then (
            messageBox "Error: Nothing to import!" title:"Nothing to import error"
            return undefined
        ) 
        
        if chk_detect.checked == true then (
            detected_count = 0
            scene_objects = objects as array
            detected_nodes = #()
            
            for i = 1 to scene_objects.count do (
                for j = 1 to gbx_node_name.count do (
                    if (detected_nodes[j] == undefined) and scene_objects[i].ishidden == false and
                        (stricmp scene_objects[i].name gbx_node_name[j] == 0) then (
                        detected_nodes[j] = scene_objects[i]
                        detected_count += 1
                    )
                )
            )

            reuse_nodes = detected_count == gbx_node_blocks
            if reuse_nodes == true then (
                gbx_node_array = detected_nodes
            )
        ) else (
            --* make sure nodes are valid. erase them if not
            for n = 1 to gbx_node_array.count do (
                if not isValidNode gbx_node_array[n] then (
                    reuse_nodes = false
                )
            )
        )

        if reuse_nodes == false and chk_detect.checked then (
            messageBox "Error: Could not detect non-hidden objects in the scene with the same name as this models nodes!" title:"Node detect error"
        ) else if gbx_node_array.count != 0 and reuse_nodes == false and chk_reuse.checked then (
            messageBox "Error: Number of reusable nodes is invalid, or some of the nodes were deleted!" title:"Node reuse error"
        )

        if reuse_nodes == false then (
            gbx_node_array = #()
        ) else (
            import_nodes = false
        )

        import_weights = chk_weight.checked and (reuse_nodes or import_nodes)

        if import_nodes == false and chk_marker.checked == false and chk_model.checked == false then
        (
            messageBox "Error: You selected nothing to import!" title:"Import selection error"
        )
        
        global import_region_permutation = #()
        if radio_geometry.state == 1 then
        (
            permutation_name = region_permutation_name[region_index][permutation_index]
            for r = 1 to region_blocks do
            (
                for p = 1 to region_permutation_blocks[r] do
                (
                    if permutation_name as name == region_permutation_name[r][p] as name then
                    (
                        append import_region_permutation #(r, p)
                    )
                )
            )
        )
        else
        (
            if radio_geometry.state == 2 then
            (
                for p = 1 to region_permutation_blocks[region_index] do
                (
                    append import_region_permutation #(region_index, p)
                )
            )
            else
            (
                append import_region_permutation #(region_index, permutation_index)
            )
        )
        
        if import_nodes == true or chk_marker.checked == true then
        (
            marker_array = #()
            delete_imported_nodes = false
            
            if reuse_nodes == false then (
                tmp_node_array = #()
                for n = 1 to gbx_node_blocks do
                (
                    tmp_node_array[n] = sphere radius:spn_node.value
                    tmp_node_array[n].wirecolor = color 6 134 6
                    tmp_node_array[n].name = gbx_node_name[n]
                    if gbx_node_parent_node_index[n] != -1 do
                    (
                        tmp_node_array[n].parent = tmp_node_array[gbx_node_parent_node_index[n] + 1]
                    )
                    rot = (quat -gbx_node_rotation[n].x -gbx_node_rotation[n].y -gbx_node_rotation[n].z gbx_node_rotation[n].w)
                    in coordsys parent tmp_node_array[n].rotation = rot
                    in coordsys parent tmp_node_array[n].pos = gbx_node_translation[n]
                )
                delete_imported_nodes = not import_nodes
            ) else (
                tmp_node_array = gbx_node_array
            )
            
            if chk_bone.checked == true or chk_bip.checked == true then
            (
                for n = 1 to tmp_node_array.count do
                (
                    if chk_bip.checked == false or (substring gbx_node_name[n] 1 5 as name == "bip01" as name) then
                    (
                        if gbx_node_first_child_node_index[n] == -1 then
                        (
                            myBone = BoneSys.createBone tmp_node_array[n].pos [tmp_node_array[n].pos.x + spn_node.value, tmp_node_array[n].pos.y, tmp_node_array[n].pos.z] [0,0,1]
                            myBone.name = tmp_node_array[n].name
                            myBone.width = spn_node.value
                            myBone.height = spn_node.value
                            myBone.taper = 50
                        )
                        else
                        (
                            myBone = BoneSys.createBone tmp_node_array[n].pos tmp_node_array[gbx_node_first_child_node_index[n] + 1].pos [0,0,1]
                            myBone.name = tmp_node_array[n].name
                            myBone.width = spn_node.value
                            myBone.height = spn_node.value
                            myBone.taper = 70
                            
                            if (myBone.name as name == "bip01 spine1" as name) then
                            (
                                myBone.length *= 0.8
                                myBone.width = spn_node.value
                                myBone.height = spn_node.value / 2
                                myBone.taper = -180
                            )
                            if (myBone.name as name == "bip01 pelvis" as name) or (myBone.name as name == "bip01 spine" as name) then
                            (
                                myBone.width = spn_node.value
                                myBone.height = spn_node.value / 2
                                myBone.taper = -180
                            )
                            if (myBone.name as name == "frame bone24" as name) then
                            (
                                myBone.length = spn_node.value * 4
                                myBone.width = spn_node.value * 4
                                myBone.height = spn_node.value * 4
                                myBone.taper = 100
                            )
                            if (myBone.name as name == "frame l wriste" as name) or (myBone.name as name == "frame r wriste" as name) then
                            (
                                myBone.length = 2.8
                                myBone.width = spn_node.value
                                myBone.height = spn_node.value * (.3)
                                myBone.taper = -270
                            )
                            if (myBone.name as name == "frame l forearm" as name) or (myBone.name as name == "frame r forearm" as name) then
                            (
                                myBone.width = spn_node.value * 2
                                myBone.height = spn_node.value * 2
                            )
                            if (myBone.name as name == "frame l upperarm" as name) or (myBone.name as name == "frame r upperarm" as name) then
                            (
                                myBone.width = spn_node.value * 3
                                myBone.height = spn_node.value * 3
                            )
                            
                        )
                        
                        delete tmp_node_array[n]
                        tmp_node_array[n] = myBone
                        
                        if gbx_node_parent_node_index[n] != -1 then
                        (
                            myBone.parent = tmp_node_array[gbx_node_parent_node_index[n] + 1]
                        )
                        
                        rot = (quat -gbx_node_rotation[n].x -gbx_node_rotation[n].y -gbx_node_rotation[n].z gbx_node_rotation[n].w)
                        in coordsys parent myBone.rotation = rot
                        in coordsys parent myBone.pos = gbx_node_translation[n]
                    ) else if gbx_node_parent_node_index[n] != -1 then (
                        tmp_node_array[n].parent = tmp_node_array[gbx_node_parent_node_index[n] + 1]
                    )
                )
            )
            
            if chk_marker.checked == true then
            (
                m = 0
                for b = 1 to marker_blocks do
                (
                    for i = 1 to marker_instance_blocks[b] do
                    (
                        for p = 1 to import_region_permutation.count do
                        (
                            if (marker_instance_region_index[b][i] + 1) == import_region_permutation[p][1] and (marker_instance_permutation_index[b][i] + 1) == import_region_permutation[p][2] then
                            (
                                m += 1
                                marker_array[m] = sphere radius:spn_marker.value
                                marker_array[m].wirecolor = color 28 89 177
                                marker_array[m].name = "#" + marker_name[b]
                                marker_array[m].parent = tmp_node_array[marker_instance_node_index[b][i] + 1]
                                rot = (quat -marker_instance_rotation[b][i].x -marker_instance_rotation[b][i].y -marker_instance_rotation[b][i].z marker_instance_rotation[b][i].w)
                                in coordsys parent marker_array[m].rotation = rot
                                in coordsys parent marker_array[m].pos = marker_instance_translation[b][i]
                            )
                        )
                    )
                )
                for r = 1 to region_blocks do
                (
                    for p = 1 to region_permutation_blocks[r] do
                    (
                        for b = 1 to region_permutation_marker_blocks[r][p] do
                        (
                            for i = 1 to import_region_permutation.count do
                            (
                                if (r == import_region_permutation[i][1]) and (p == import_region_permutation[i][2]) then
                                (
                                    m += 1
                                    marker_array[m] = sphere radius:spn_marker.value
                                    marker_array[m].wirecolor = color 28 89 177
                                    marker_array[m].name = "#" + region_permutation_marker_name[r][p][b]
                                    marker_array[m].parent = tmp_node_array[region_permutation_marker_node_index[r][p][b] + 1]
                                    rot = (quat -region_permutation_marker_rotation[r][p][b].x -region_permutation_marker_rotation[r][p][b].y -region_permutation_marker_rotation[r][p][b].z region_permutation_marker_rotation[r][p][b].w)
                                    in coordsys parent marker_array[m].rotation = rot
                                    in coordsys parent marker_array[m].pos = region_permutation_marker_translation[r][p][b]
                                )
                            )
                        )
                    )
                )
            )
            
            if delete_imported_nodes then (
                for n = 1 to tmp_node_array.count do (
                    delete tmp_node_array[n]
                )
            )
            if import_nodes == true then (
                gbx_node_array = tmp_node_array
            )
        )
        
        if chk_model.checked == true then
        (
            import_geometry_indices = #()
            for i = 1 to import_region_permutation.count do
            (
                import_geometry_indices[i] = (region_permutation_LOD_indices[import_region_permutation[i][1]][import_region_permutation[i][2]][LOD_switch[LOD_index]] + 1)
            )
            
            if chk_matlib.checked == true then
            (
                meditMaterials[1] = multimaterial()
                for s = 1 to shader_name.count do
                (
                    meditMaterials[1].names[s] = shader_name[s]
                    meditMaterials[1].materialList[s].name = shader_name[s]
                    meditMaterials[1].materialIDList[s] = s
                )
            )

            geometry_meshes = #()
            has_meshes = false
            
            for geometry_index = 1 to import_geometry_indices.count do
            (
                g = import_geometry_indices[geometry_index]
                if g <= 0 or g > geometry_part_blocks.count then (
                    continue
                )
                has_meshes = false
                part_meshes = #()
                geometry_meshes[geometry_index] = (part_meshes)

                part_vertex_node_index = #()
                part_vertex_node_weight = #()
                
                for p = 1 to geometry_part_blocks[g] do
                (
                    vertex_xyz = #()
                    vertex_uvw = #()
                    vertex_node_index = #()
                    vertex_node_weight = #()
                    vertex_order = #()
                    triangles = #()
                    has_meshes = true

                    vertex_xyz[geometry_part_vertex_blocks[g][p]] = 0
                    vertex_uvw[geometry_part_vertex_blocks[g][p]] = 0
                    
                    fseek gbx_in_file geometry_part_vert_offset[g][p] #seek_set
                        
                    if vertex_type == 0 then
                    (
                        for v = 1 to geometry_part_vertex_blocks[g][p] do
                        (
                            vertex_xyz[v] = gbxReadTrans()

                            fseek gbx_in_file 12 #seek_cur
                        
                            if chk_uvw.checked == true then
                            (
                                u_coord = ((gbxReadShortB ()) / 32767.0) * u_scale
                                v_coord = 1.0 - (((gbxReadShortB ()) / 32767.0) * v_scale)
                                vertex_uvw[v] = [u_coord,v_coord,0]
                            )
                            else
                            (
                                fseek gbx_in_file 4 #seek_cur
                            )

                            if import_weights then
                            (
                                node0_index = ((readByte gbx_in_file #signed) / 3) + 1
                                node1_index = ((readByte gbx_in_file #signed) / 3) + 1

                                vertex_node_index[v] = #(node0_index, node1_index)
                            
                                append part_vertex_node_index vertex_node_index[v]
                            
                                node0_weight = ((gbxReadShortB ()) / 32767.0) * 1.0
                                node1_weight = (1 - node0_weight ) * 1.0
                                vertex_node_weight[v] = #(node0_weight, node1_weight)
                            
                                append part_vertex_node_weight vertex_node_weight[v]
                            )
                            else
                            (
                                fseek gbx_in_file 4 #seek_cur
                            )
                        )
                    )
                    else
                    (
                        for v = 1 to geometry_part_vertex_blocks[g][p] do
                        (
                            vertex_xyz[v] = gbxReadTrans()

                            fseek gbx_in_file 36 #seek_cur
                        
                            if chk_uvw.checked == true then
                            (
                                u_coord = gbxReadFloatB() * u_scale
                                v_coord = 1 - (gbxReadFloatB() * v_scale)
                                vertex_uvw[v] = [u_coord,v_coord,0]
                            )
                            else
                            (
                                fseek gbx_in_file 8 #seek_cur
                            )

                            if import_weights then
                            (
                                node0_index = (gbxReadShortB ()) + 1
                                node1_index = (gbxReadShortB ()) + 1
                            
                                if local_nodes == true then
                                (
                                    vertex_node_index[v] = #()
                                    if node0_index == 0 then
                                    (
                                        vertex_node_index[v][1] = 0
                                    )
                                    else
                                    (
                                        vertex_node_index[v][1] = geometry_part_local_nodes[g][p][node0_index] + 1
                                    )
                                    if node1_index == 0 then
                                    (
                                        vertex_node_index[v][2] = 0
                                    )
                                    else
                                    (
                                        vertex_node_index[v][2] = geometry_part_local_nodes[g][p][node1_index] + 1
                                    )
                                )
                                else
                                (
                                    vertex_node_index[v] = #(node0_index, node1_index)
                                )
                            
                                append part_vertex_node_index vertex_node_index[v]
                            
                                node0_weight = gbxReadFloatB()
                                node1_weight = gbxReadFloatB()
                                vertex_node_weight[v] = #(node0_weight, node1_weight)
                            
                                append part_vertex_node_weight vertex_node_weight[v]
                            )
                            else
                            (
                                fseek gbx_in_file 12 #seek_cur
                            )
                        )
                    )

                    fseek gbx_in_file geometry_part_tri_offset[g][p] #seek_set

                    triangle_vertices = (geometry_part_triangle_blocks[g][p] * 3)
                    for t = 1 to triangle_vertices do
                    (
                        append vertex_order ((gbxReadShortB ()) + 1)
                    )
                    
                    vo_count = vertex_order.count
                    if vertex_order[vo_count] == 0 do deleteItem vertex_order (vo_count)
                    if vertex_order[vo_count-1] == 0 do deleteItem vertex_order (vo_count-1)
                    
                    for w = 1 to (vertex_order.count - 2) do
                    (
                        triangles[w] = [vertex_order[w],vertex_order[w+1],vertex_order[w+2]]
                    )
                    
                    for r = 1 to triangles.count by 2 do
                    (
                        a = triangles[r][1]
                        triangles[r][1] = triangles[r][3]
                        triangles[r][3] = a
                    )
                    
                    for d = triangles.count to 1 by -1 do
                    (
                        if (triangles[d][1] == triangles[d][2]) or (triangles[d][2] == triangles[d][3]) or (triangles[d][1] == triangles[d][3]) then
                        (
                            deleteItem triangles d
                        )
                    )
                    
                    if chk_uvw.checked != true then
                    (
                        m = mesh vertices:vertex_xyz faces:triangles
                    )
                    else
                    (
                        faces_matID = #()
                        for t = 1 to triangles.count do
                        (
                            faces_matID[t] = geometry_part_shader_index[g][p] + 1
                        )
                        m = mesh vertices:vertex_xyz tverts:vertex_uvw faces:triangles materialIDs:faces_matID
                        mmesh = m.mesh
                        buildTVFaces mmesh
                        for i = 1 to mmesh.numfaces do
                        (
                            setTVFace mmesh i (getFace mmesh i)
                            setFaceSmoothGroup mmesh i 1
                        )
                    )
                    m.name = shader_name[geometry_part_shader_index[g][p] + 1]
                    part_meshes[p] = m

                    if gbx_node_array.count == 1 then (
                        if isValidNode gbx_node_array[1] then (
                            m.parent = gbx_node_array[1]
                        )
                    )
                    else if gbx_node_array.count > 0 and import_weights and chk_attach.checked == false then
                    (

                        theSkin = Skin()
                        max modify mode
                        select m
                        modPanel.addModToSelection theSkin
                        
                        if v[1] > 4200 then
                        (
                            theSkin.bone_Limit = 2
                        )
                        
                        for n = 1 to gbx_node_array.count do
                        (
                            skinOps.addbone theSkin gbx_node_array[n] 1
                        )
                        
                        subobjectLevel = 1
                        
                        skinVerts = skinOps.getNumberVertices theSkin
                        for vt = 1 to skinVerts do
                        (
                            if vertex_node_index[vt][2] == 0 then
                            (
                                skinOps.ReplaceVertexWeights theSkin vt vertex_node_index[vt][1] vertex_node_weight[vt][1]
                            )
                            else
                            (
                                if vertex_node_index[vt][1] == 0 then
                                (
                                    skinOps.ReplaceVertexWeights theSkin vt vertex_node_index[vt][2] vertex_node_weight[vt][2]
                                )
                                else
                                (
                                    if vertex_node_index[vt][1] == vertex_node_index[vt][2] then
                                    (
                                        skinOps.ReplaceVertexWeights theSkin vt vertex_node_index[vt][1] 1.0
                                    )
                                    else
                                    (
                                        skinOps.ReplaceVertexWeights theSkin vt vertex_node_index[vt] vertex_node_weight[vt]
                                    )
                                )
                            )
                        )
                        
                        max create mode
                    )
                    
                )

                
                if chk_attach.checked == true and has_meshes then
                (
                    for a = 2 to part_meshes.count do
                    (
                        attach part_meshes[1] part_meshes[a]
                    )

                    if chk_matlib.checked == true and chk_uvw.checked == true then
                    (
                        part_meshes[1].material = meditMaterials[1]
                        part_meshes[1].name = region_name[import_region_permutation[geometry_index][1]]
                    )
                    
                    if gbx_node_array.count == 1 then (
                        part_meshes[1].parent = gbx_node_array[1]
                    )
                    else if gbx_node_array.count > 0 and import_weights then
                    (
                        theSkin = Skin()
                        max modify mode
                        select part_meshes[1]
                        modPanel.addModToSelection theSkin
                        
                        if v[1] > 4200 then
                        (
                            theSkin.bone_Limit = 2
                        )
                        
                        for n = 1 to gbx_node_array.count do
                        (
                            skinOps.addbone theSkin gbx_node_array[n] 1
                        )
                        
                        subobjectLevel = 1
                        
                        skinVerts = skinOps.getNumberVertices theSkin
                        for vt = 1 to skinVerts do
                        (
                            if part_vertex_node_index[vt][2] == 0 then
                            (
                                skinOps.ReplaceVertexWeights theSkin vt part_vertex_node_index[vt][1] part_vertex_node_weight[vt][1]
                            )
                            else
                            (
                                if part_vertex_node_index[vt][1] == 0 then
                                (
                                    skinOps.ReplaceVertexWeights theSkin vt part_vertex_node_index[vt][2] part_vertex_node_weight[vt][2]
                                )
                                else
                                (
                                    if part_vertex_node_index[vt][1] == part_vertex_node_index[vt][2] then
                                    (
                                        skinOps.ReplaceVertexWeights theSkin vt part_vertex_node_index[vt][1] 1.0
                                    )
                                    else
                                    (
                                        skinOps.ReplaceVertexWeights theSkin vt part_vertex_node_index[vt] part_vertex_node_weight[vt]
                                    )
                                )
                            )
                        )
                        max create mode
                    )
                )
            )


            if chk_attach.checked == false and chk_matlib.checked == true and chk_uvw.checked == true and has_meshes then
            (
                for geometry_index = 1 to import_geometry_indices.count do
                (
                    g = import_geometry_indices[geometry_index]
                    if g <= 0 or g > geometry_part_blocks.count then (
                        continue
                    )

                    part_meshes = geometry_meshes[geometry_index]

                    for p = 1 to geometry_part_blocks[g] do
                    (
                        if isValidNode part_meshes[p] then
                        (
                            part_meshes[p].material = meditMaterials[1]
                        )
                        else
                        (
                            print ("Could not locate part " + (p as string) + " in geometry " + (g as string))
                        )
                    )
                )
            )
        )
    )
)

-- Function to load and process the GBX file
fn loadGBXFile in_name = 
(
    -- Initialize the temporary buffer
    gbx_tmp_buffer = fopen (sysInfo.tempdir + "\\gbxmodel_conv_buf.bin") "wbD+"
    
    gbx_in_file = fopen in_name "rbR"
    if gbx_in_file == undefined then
    (
        messageBox "Error in opening file!" title:"File opening error"
        if gbx_tmp_buffer != undefined do fclose gbx_tmp_buffer
        return false
    )
    else
    (
        print ("Opened File: " + in_name)
        fseek gbx_in_file 36 #seek_set
        tag_type = gbxReadULongB ()
        print ("Tag type check: " + tag_type as string)
        model_type  = -1
        vertex_type = -1
        --*vertex_type: 0 == compressed   1 == uncompressed*
        if tag_type == 1836016741 then
        (
            model_type  = 0--*recognized as Xbox Model*
            vertex_type = 0
        )
        if tag_type == 1836016690 then
        (
            model_type  = 1--*recognized as GBX Model*
            vertex_type = 1
        )

        if model_type == -1 then
        (
            messageBox "Error: Incorrect file type!\n\nPlease select a valid .gbxmodel or .model tag.  " \
                title:"Incorrect file type error"
            fclose gbx_in_file
            return false
        )
        else
        (
            start1 = timeStamp()
            
            local_nodes = false
            
            unknown_blocks = 0
            marker_blocks = 0
            marker_name = #()
            marker_instance_blocks = #()
            marker_instance_region_index = #()
            marker_instance_permutation_index = #()
            marker_instance_node_index = #()
            marker_instance_translation = #()
            marker_instance_rotation = #()
            gbx_node_blocks = 0
            gbx_node_name = #()
            gbx_node_next_sibling_node_index = #()
            gbx_node_first_child_node_index = #()
            gbx_node_parent_node_index = #()
            gbx_node_translation = #()
            gbx_node_rotation = #()
            gbx_node_distance_from_parent = #()
            region_blocks = 0
            region_name = #()
            region_permutation_blocks = #()
            region_permutation_name = #()
            region_permutation_LOD_indices = #()
            region_permutation_marker_blocks = #()
            region_permutation_marker_name = #()
            region_permutation_marker_node_index = #()
            region_permutation_marker_rotation = #()
            region_permutation_marker_translation = #()
            geometry_blocks = 0
            geometry_part_blocks = #()
            geometry_part_shader_index = #()
            geometry_part_vert_offset = #()
            geometry_part_tri_offset = #()
            geometry_part_uncompressed_vertex_blocks = #()
            geometry_part_compressed_vertex_blocks = #()
            geometry_part_vertex_blocks = #()
            geometry_part_triangle_blocks = #()
            geometry_part_local_nodes = #()
            shader_blocks = 0
            uncompressed_vert_sum = 0
            compressed_vert_sum   = 0
            shader_name = #()
            
            ss = in_name as StringStream
            skipToString ss "tags\\"
            startPos = filePos ss
            ceRoot = substring in_name 1 (startPos - 5)
            global filenamePath = getFilenamePath in_name
            tagLoc = substring filenamePath (startPos+1) -1
            global tagName = getFilenameFile in_name
                    
            print ("-------------------------------------------------------")
            
            fseek gbx_in_file 66 #seek_set
            flags = gbxReadUShortB ()
            model_flags = getFlagArray flags
            print ("Model Flags: " + model_flags as string)

            local_nodes = false--*local nodes were implemented in PC and don't exist on XBOX*
            if model_flags[2] == true and model_type == 1 then
            (
                local_nodes = true
                print ("Model uses local nodes")
            )
            
            fseek gbx_in_file 68 #seek_set
            node_list_checksum = gbxReadLongB ()
            print ("Node List Checksum: " + node_list_checksum as string)
            
            fseek gbx_in_file 112 #seek_set
            u_scale = gbxReadFloatB()
            fseek gbx_in_file 112 #seek_set
            if readFloat gbx_in_file == 0.0 do u_scale = 1.0
            print ("Base Map U-Scale: " + u_scale as string)
            
            fseek gbx_in_file 116 #seek_set
            v_scale = gbxReadFloatB()
            fseek gbx_in_file 116 #seek_set
            if readFloat gbx_in_file == 0.0 do v_scale = 1.0
            print ("Base Map V-Scale: " + v_scale as string)
            
            print ("-------------------------------------------------------")

            fseek gbx_in_file 224 #seek_set
            unknown_blocks = gbxReadULongB ()
            print ("Unknown Blocks: " + unknown_blocks as string)

            fseek gbx_in_file 236 #seek_set
            marker_blocks = gbxReadULongB ()
            print ("Marker Blocks: " + marker_blocks as string)
            
            fseek gbx_in_file 248 #seek_set
            gbx_node_blocks = gbxReadULongB ()
            print ("Node Blocks: " + gbx_node_blocks as string)
            
            fseek gbx_in_file 260 #seek_set
            region_blocks = gbxReadULongB ()
            print ("Region Blocks: " + region_blocks as string)
            
            fseek gbx_in_file 272 #seek_set
            geometry_blocks = gbxReadULongB ()
            print ("Geometry Blocks: " + geometry_blocks as string)
            
            fseek gbx_in_file 284 #seek_set
            shader_blocks = gbxReadULongB ()
            print ("Shader Blocks: " + shader_blocks as string)
            
            print ("-------------------------------------------------------")
            
            fseek gbx_in_file 296 #seek_set
            
            --*skip all the unknown_blocks*
            fseek gbx_in_file (unknown_blocks*64) #seek_cur
            
            print ("Marker block offset: " + (ftell gbx_in_file) as string)
            
            for m = 1 to marker_blocks do
            (
                offset = (ftell gbx_in_file)
                marker_name[m] = readString gbx_in_file
                fseek gbx_in_file (offset + 32) #seek_set
                fseek gbx_in_file 20 #seek_cur
                marker_instance_blocks[m] = gbxReadULongB ()
                fseek gbx_in_file 8 #seek_cur
            )
            for m = 1 to marker_blocks do
            (
                temp_region_index = #()
                temp_permutation_index = #()
                temp_node_index = #()
                temp_translation = #()
                temp_rotation = #()
                for i = 1 to marker_instance_blocks[m] do
                (
                    temp_region_index[i] = readByte gbx_in_file #unsigned
                    temp_permutation_index[i] = readByte gbx_in_file #unsigned
                    temp_node_index[i] = readByte gbx_in_file #unsigned
                    fseek gbx_in_file 1 #seek_cur
                    temp_translation[i] = gbxReadTrans()
                    temp_rotation[i] = gbxReadQuat()
                )
                marker_instance_region_index[m] = temp_region_index
                marker_instance_permutation_index[m] = temp_permutation_index
                marker_instance_node_index[m] = temp_node_index
                marker_instance_translation[m] = temp_translation
                marker_instance_rotation[m] = temp_rotation
            )
            
            print ("Node block offset: " + (ftell gbx_in_file) as string)
            
            for n = 1 to gbx_node_blocks do
            (
                offset = (ftell gbx_in_file)
                gbx_node_name[n] = readString gbx_in_file
                fseek gbx_in_file (offset + 32) #seek_set
                gbx_node_next_sibling_node_index[n] = gbxReadShortB ()
                gbx_node_first_child_node_index[n] = gbxReadShortB ()
                gbx_node_parent_node_index[n] = gbxReadShortB ()
                fseek gbx_in_file 2 #seek_cur
                gbx_node_translation[n] = gbxReadTrans()
                gbx_node_rotation[n] = gbxReadQuat()
                gbx_node_distance_from_parent[n] = gbxReadFloatB()
                fseek gbx_in_file 84 #seek_cur
            )
            
            print ("Region block offset: " + (ftell gbx_in_file) as string)
            
            for r = 1 to region_blocks do
            (
                offset = (ftell gbx_in_file)
                region_name[r] = readString gbx_in_file
                fseek gbx_in_file (offset + 32) #seek_set
                fseek gbx_in_file 32 #seek_cur
                region_permutation_blocks[r] = gbxReadULongB ()
                fseek gbx_in_file 8 #seek_cur
            )
            for r = 1 to region_blocks do
            (
                temp_permutation_name = #()
                temp_permutation_LOD_indices = #()
                temp_permutation_marker_blocks = #()
                for p = 1 to region_permutation_blocks[r] do
                (
                    offset = (ftell gbx_in_file)
                    temp_permutation_name[p] = readString gbx_in_file
                    fseek gbx_in_file (offset + 32) #seek_set
                    fseek gbx_in_file 32 #seek_cur
                    superlow = gbxReadShortB ()
                    low = gbxReadShortB ()
                    medium = gbxReadShortB ()
                    high = gbxReadShortB ()
                    superhigh = gbxReadShortB ()
                    temp_permutation_LOD_indices[p] = #(superlow, low, medium, high, superhigh)
                    fseek gbx_in_file 2 #seek_cur
                    temp_permutation_marker_blocks[p] = gbxReadULongB ()
                    fseek gbx_in_file 8 #seek_cur
                )
                region_permutation_name[r] = temp_permutation_name
                region_permutation_LOD_indices[r] = temp_permutation_LOD_indices
                region_permutation_marker_blocks[r] = temp_permutation_marker_blocks
                
                temp_permutation_marker_name = #()
                temp_permutation_marker_node_index = #()
                temp_permutation_marker_rotation = #()
                temp_permutation_marker_translation = #()
                for p = 1 to region_permutation_blocks[r] do
                (
                    temp_marker_name = #()
                    temp_marker_node_index = #()
                    temp_marker_rotation = #()
                    temp_marker_translation = #()
                    for m = 1 to region_permutation_marker_blocks[r][p] do
                    (
                        offset = (ftell gbx_in_file)
                        temp_marker_name[m] = readString gbx_in_file
                        fseek gbx_in_file (offset + 32) #seek_set
                        temp_marker_node_index[m] = gbxReadShortB ()
                        fseek gbx_in_file 2 #seek_cur
                        temp_marker_rotation[m] = gbxReadQuat()
                        temp_marker_translation[m] = gbxReadTrans()
                        fseek gbx_in_file 16 #seek_cur
                    )
                    temp_permutation_marker_name[p] = temp_marker_name
                    temp_permutation_marker_node_index[p] = temp_marker_node_index
                    temp_permutation_marker_rotation[p] = temp_marker_rotation
                    temp_permutation_marker_translation[p] = temp_marker_translation
                )
                region_permutation_marker_name[r] = temp_permutation_marker_name
                region_permutation_marker_node_index[r] = temp_permutation_marker_node_index
                region_permutation_marker_rotation[r] = temp_permutation_marker_rotation
                region_permutation_marker_translation[r] = temp_permutation_marker_translation
            )
            
            print ("Geometry block offset: " + (ftell gbx_in_file) as string)
            
            for g = 1 to geometry_blocks do
            (
                fseek gbx_in_file 36 #seek_cur
                geometry_part_blocks[g] = gbxReadULongB ()
                fseek gbx_in_file 8 #seek_cur
            )

            uncompressed_vert_sum = 0
            compressed_vert_sum   = 0
            for g = 1 to geometry_blocks do
            (
                temp_part_shader_index = #()
                temp_part_uncompressed_vertex_blocks = #()
                temp_part_compressed_vertex_blocks = #()
                temp_part_vertex_blocks = #()
                temp_part_triangle_blocks = #()
                if local_nodes == true do temp_part_local_nodes = #()
                for p = 1 to geometry_part_blocks[g] do
                (
                    fseek gbx_in_file 4 #seek_cur
                    temp_part_shader_index[p] = gbxReadShortB ()
                    fseek gbx_in_file 26 #seek_cur
                    temp_part_uncompressed_vertex_blocks[p] = gbxReadULongB ()
                    fseek gbx_in_file 8 #seek_cur
                    temp_part_compressed_vertex_blocks[p] = gbxReadULongB ()
                    fseek gbx_in_file 8 #seek_cur
                    temp_part_triangle_blocks[p] = gbxReadULongB ()
                    
                    uncompressed_vert_sum = uncompressed_vert_sum + temp_part_uncompressed_vertex_blocks[p]
                    compressed_vert_sum   = compressed_vert_sum   + temp_part_compressed_vertex_blocks[p]
                    if model_type == 0 then
                    (
                        fseek gbx_in_file 44 #seek_cur
                    )
                    else
                    (
                        offset = (ftell gbx_in_file)
                        if local_nodes == true then
                        (
                            fseek gbx_in_file 46 #seek_cur
                            number_local_nodes = gbxReadUShortB ()
                            the_local_nodes = #()
                            for n = 1 to number_local_nodes do
                            (
                                append the_local_nodes (readByte gbx_in_file #unsigned)
                            )
                            temp_part_local_nodes[p] = the_local_nodes
                        )
                        fseek gbx_in_file (offset + 72) #seek_set
                    )
                )
                if model_type == 1 and uncompressed_vert_sum == 0 and compressed_vert_sum > 0 then
                (
                    vertex_type = 0
                )
                if model_type == 0 and compressed_vert_sum == 0 and uncompressed_vert_sum > 0 then
                (
                    vertex_type = 1
                )
                geometry_part_shader_index[g] = temp_part_shader_index
                geometry_part_compressed_vertex_blocks[g] = temp_part_compressed_vertex_blocks
                geometry_part_uncompressed_vertex_blocks[g] = temp_part_uncompressed_vertex_blocks
                geometry_part_triangle_blocks[g] = temp_part_triangle_blocks
                if vertex_type == 0 then
                (
                    geometry_part_vertex_blocks[g] = temp_part_compressed_vertex_blocks
                )
                else
                (
                    geometry_part_vertex_blocks[g] = temp_part_uncompressed_vertex_blocks
                )
                if local_nodes == true do geometry_part_local_nodes[g] = temp_part_local_nodes
                
                temp_part_vert_offset = #()
                temp_part_tri_offset  = #()
                for p = 1 to geometry_part_blocks[g] do
                (
                    if vertex_type == 1 then
                    (
                        temp_part_vert_offset[p] = ftell gbx_in_file
                    )
                    fseek gbx_in_file (geometry_part_uncompressed_vertex_blocks[g][p] * 68) #seek_cur
                    if vertex_type == 0 then
                    (
                        temp_part_vert_offset[p] = ftell gbx_in_file
                    )
                    fseek gbx_in_file (geometry_part_compressed_vertex_blocks[g][p] * 32) #seek_cur
                    temp_part_tri_offset[p] = ftell gbx_in_file
                    fseek gbx_in_file (geometry_part_triangle_blocks[g][p] * 6) #seek_cur
                )
                geometry_part_vert_offset[g] = temp_part_vert_offset
                geometry_part_tri_offset[g]  = temp_part_tri_offset
            )
            
            print ("Shader block offset: " + (ftell gbx_in_file) as string)
            
            fseek gbx_in_file (shader_blocks * 32) #seek_cur
            for s = 1 to shader_blocks do
            (
                shader_dir = readString gbx_in_file
                ss = shader_dir as StringStream
                d2 = 1
                d1 = 0
                while d1 < d2 do
                (
                    temp_pos = filePos ss
                    skipToString ss "\t"
                    d2 = filePos ss - temp_pos
                    seek ss temp_pos
                    skipToString ss "\\"
                    d1 = filePos ss - temp_pos
                )
                seek ss temp_pos
                shader_name[s] = readDelimitedString ss "\t"
            )
            
            print ("-------------------------------------------------------")
            
            end1 = timeStamp()
            print ("Model indexing took " + ((end1 - start1) as float / 1000.0) as string + " seconds")
            
            return true
        )
    )
)

-- Main execution: First get the file, then show UI
in_name = getOpenFileName \
    filename: "C:\\Program Files\\Microsoft Games\\Halo Custom Edition\\tags\\" \
    types: "GBXModel Tag (*.gbxmodel)|*.gbxmodel|Model Tag (*.model)|*.model|All Tag Files (*.*)|*.*"

if in_name != undefined then
(
    if loadGBXFile in_name then
    (
        CreateDialog gbxImporter
    )
)
