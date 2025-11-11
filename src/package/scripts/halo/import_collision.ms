-- Ultimate Collision Importer for 3ds Max
-- Uses Python collision_converter.py + existing GBX importer
-- Provides full bone hierarchy, materials, and complex geometry support


global collisionUltimateImporter

rollout collisionUltimateImporter "Collision Params" width:485 height:240
(
    local scriptVersion = "v1.0.0"
    local aboutString = "Import Halo CE Collision Geometry\n" +
                        "Version: " + scriptVersion + "\n\n" +
                        "This tool allows you to import Halo CE collision geometry files into 3ds Max.\n\n" +
                        "Features:\n" +
                        "- Import full bone hierarchy if you have a valid gbxmodel file in the same directory.\n" +
                        "- Supports raw geometry import without skeletons.\n" +
                        "- Options for materials, skin weights, and node reusage.\n\n" +
                        "Developed by Mark Mc'Fuzz.\n\n" +
                        "Special Thanks:\n"+ \
		                "Sigmmma (MEK and Reclaimer library)."

    fn dlgAbout = (
	    messagebox aboutString title:"About Collision Geometry Importer"
    )
    -- UI Elements
    
    GroupBox grp_options "Import Options" pos:[10,10] width:465 height:130
    checkbox chk_raw_geometry "Raw Mode (No Skeleton Required)" pos:[20,30] width:230 height:16 checked:false
    checkbox chk_create_materials "Create Collision Materials" pos:[20,50] width:200 height:16 checked:true
    checkbox chk_attach "Split Mesh by Material" pos:[20,70] width:180 height:16 checked:false

    checkbox chk_weights "Import Weights (Rigged Model)" pos:[260,30] width:200 height:16 checked:true
    checkbox chk_use_existing_nodes "Reuse Imported Nodes" pos:[260,50] width:150 height:16 checked:false
    checkbox chk_bones "Swap Nodes to Bones" pos:[260,70] width:150 height:16 checked:false

    label lbl_file "Collision File:" pos:[20,110] width:80 height:16
    edittext edt_file "" pos:[105,108] width:360 height:20 readonly:true

    GroupBox grp_import "Import File" pos:[10,153] width:465 height:50
    button btn_import "Import" pos:[200,165] width:100 height:30 enabled:true
    
    -- About Elements
    button btAbout "About" pos:[10,210] width:70 height:20
    label versionLbl scriptVersion pos:[440,214] width:70 height:16

    -- Hiden options with out of bounds
    checkbox chk_cleanup "Clean up temporary files" pos:[20,335] width:180 height:16 checked:true
    label lbl_output "Output GBX:" pos:[20,325] width:80 height:16
    edittext edt_output "" pos:[105,323] width:360 height:20 readonly:true

    -- Variables
    local collisionFilePath = undefined
    local gbxOutputPath = undefined
    local pythonRunnerPath = undefined
    
    on btAbout pressed do dlgAbout()

    -- Enhanced cleanup function to prevent file locking issues
    fn forceFileCleanup filePath =
    (
        try
        (
            print ("Forcing cleanup of file handles for: " + filePath)
            
            local handlesFound = false
            
            -- Close any known file handles
            if gbx_in_file != undefined then
            (
                try (fclose gbx_in_file) catch()
                gbx_in_file = undefined
                handlesFound = true
                print "Force closed gbx_in_file"
            )
            if gbx_tmp_buffer != undefined then
            (
                try (fclose gbx_tmp_buffer) catch()
                gbx_tmp_buffer = undefined
                handlesFound = true
                print "Force closed gbx_tmp_buffer"
            )
            
            if handlesFound then
            (
                -- Force garbage collection only if we found handles
                gc light:false
                gc()
                print "Forced garbage collection after handle cleanup"
                sleep 0.1
            )
            else
            (
                print "No file handles found to cleanup"
            )
            
            return true
        )
        catch e
        (
            print ("Error in forceFileCleanup: " + (e as string))
            return false
        )
    )
    
    -- Functions
    fn updateOutputPath = 
    (
        if collisionFilePath != undefined then
        (
            local inputPath = collisionFilePath as string
            local baseName = getFilenameFile inputPath
            local dirName = getFilenamePath inputPath
            gbxOutputPath = dirName + baseName + "_COLL.gbxmodel"
            edt_output.text = gbxOutputPath
            btn_import.enabled = true
        )
    )
    
    fn findPythonRunner = 
    (
        -- Find the Python runner script in the new organized module structure
        local thisScriptPath = getSourceFileName()
        local thisScriptDir = getFilenamePath thisScriptPath
        local runnerPath = thisScriptDir + "collision\\modules\\run_collision_converter.py"
        
        if doesFileExist runnerPath then
            return runnerPath
        else
        (
            messageBox ("Python runner script not found at: " + runnerPath) title:"Missing Runner"
            return undefined
        )
    )
    
    fn runPythonConverter collisionPath rawMode:false =
    (
        if pythonRunnerPath == undefined then
            pythonRunnerPath = findPythonRunner()
            
        if pythonRunnerPath == undefined then
            return false
            
        -- Build Python command with optional raw mode parameter
        local pythonCmd = "python \"" + pythonRunnerPath + "\" \"" + collisionPath + "\""
        if rawMode then
            pythonCmd += " raw"
        
        print ("Running Python converter: " + pythonCmd)
        --pb_progress.visible = true
        --pb_progress.value = 25
        
        -- Execute Python converter
        local result = DOSCommand pythonCmd
        
        --pb_progress.value = 50
        
        if result == 0 then
        (
            print "Python conversion successful"
            return true
        )
        else
        (
            print ("Python conversion failed with exit code: " + result as string)
            messageBox "Python conversion failed. Check the Listener for details." title:"Conversion Error"
            return false
        )
    )
    
    fn importGBXModel gbxPath =
    (
        --pb_progress.value = 75
        
        print ("Starting GBX import for: " + gbxPath)
        
        -- First check if the file actually exists
        if not doesFileExist gbxPath then
        (
            print ("ERROR: GBX file does not exist at path: " + gbxPath)
            messageBox ("GBX file not found: " + gbxPath) title:"File Not Found"
            return false
        )
        
        -- Check file size
        local fileSize = getFileSize gbxPath
        print ("GBX file size: " + fileSize as string + " bytes")
        if fileSize == 0 then
        (
            print "ERROR: GBX file is empty (0 bytes)"
            messageBox "GBX file is empty or corrupted" title:"File Error"
            return false
        )
        
        -- Clean up any existing GBX importer state first
        try
        (
            if gbx_tmp_buffer != undefined then
            (
                try (fclose gbx_tmp_buffer) catch()
                gbx_tmp_buffer = undefined
                print "Cleaned up existing temp buffer"
            )
            if gbx_in_file != undefined then
            (
                try (fclose gbx_in_file) catch()
                gbx_in_file = undefined
                print "Cleaned up existing file handle"
            )
        )
        catch
        (
            print "No existing buffers to clean up"
        )
        
        -- Load the working GBX importer script
        local thisScriptPath = getSourceFileName()
        local thisScriptDir = getFilenamePath thisScriptPath
        local gbxImporterPath = thisScriptDir + "collision\\import_gbx_coll.ms"
        
        print ("Looking for GBX importer at: " + gbxImporterPath)
        
        if not doesFileExist gbxImporterPath then
        (
            print ("GBX importer not found at: " + gbxImporterPath)
            messageBox ("GBX importer not found at: " + gbxImporterPath) title:"Missing GBX Importer"
            return false
        )
        
        print "GBX importer found, loading script..."
        
        try
        (
            -- Load the working GBX importer
            fileIn gbxImporterPath
            print "GBX importer script loaded successfully"
            
            -- Call loadGBXFile directly with the path
            print ("Loading GBX file directly: " + gbxPath)
            local loadResult = loadGBXFile gbxPath
            print ("loadGBXFile returned: " + loadResult as string)
            
            if loadResult == true then
            (
                print "File loaded successfully, importing automatically..."
                
                -- Set default import parameters for collision models
                try
                (
                    sel_region = 1      -- First region
                    sel_perm = 1        -- First permutation
                    import_node = true  -- Import hierarchy
                    import_bone = chk_bones.checked
                    attach_geo = chk_attach.checked
                    import_weight = chk_weights.checked
                    detect_node = chk_use_existing_nodes.checked
                    reuse_node = false
                    lod_sel = 3         -- Medium LOD
                    
                    print "Calling import function directly..."
                    
                    -- Try multiple approaches to trigger the import
                    if (execute "gbxImporter != undefined") then
                    (
                        print "GBX importer dialog exists, will use it silently..."
                        createDialog gbxImporter pos:[10000,10000] visible:false
                        
                        -- Set the dialog controls
                        if gbxImporter.listbox_region.items.count > 0 then
                            gbxImporter.listbox_region.selection = 1
                        if gbxImporter.listbox_permutation.items.count > 0 then
                            gbxImporter.listbox_permutation.selection = 1
                        
                        gbxImporter.chk_node.checked = true
                        gbxImporter.chk_bone.checked = chk_bones.checked --swap to bones
                        gbxImporter.chk_attach.checked = chk_attach.checked
                        gbxImporter.chk_weight.checked = chk_weights.checked
                        gbxImporter.chk_detect.checked = chk_use_existing_nodes.checked
                        gbxImporter.chk_matlib.checked = chk_create_materials.checked
                        gbxImporter.chk_reuse.checked = false
                        --gbxImporter.radio_LOD.state = 3
                        
                        -- Trigger import
                        gbxImporter.import_button.pressed()
                        
                        -- Clean up
                        destroyDialog gbxImporter
                    )
                    else if (execute "import_gbx_model != undefined") then
                    (
                        print "Direct import function found, calling..."
                        execute "import_gbx_model()"
                    )
                    else
                    (
                        print "No known import function found, creating minimal dialog approach..."
                        messageBox "Could not find automatic import method. Please manually import the converted file:\n\n" + gbxPath title:"Manual Import Required"
                    )
                    
                    print "Import process completed!"
                    --pb_progress.value = 100
                    
                    -- Enhanced cleanup - close ALL possible file handles
                    try
                    (
                        print "Closing file handles..."
                        
                        -- Close any GBX file handles (check if they exist first)
                        local closedHandles = false
                        if gbx_tmp_buffer != undefined then
                        (
                            try
                            (
                                fclose gbx_tmp_buffer
                                gbx_tmp_buffer = undefined
                                print "Closed gbx_tmp_buffer"
                                closedHandles = true
                            )
                            catch()
                        )
                        if gbx_in_file != undefined then
                        (
                            try
                            (
                                fclose gbx_in_file
                                gbx_in_file = undefined
                                print "Closed gbx_in_file"
                                closedHandles = true
                            )
                            catch()
                        )
                        
                        if closedHandles then
                        (
                            -- Only do GC if we actually closed handles
                            gc light:false
                            print "Forced garbage collection"
                        )
                        else
                        (
                            print "No file handles to close"
                        )
                        
                        -- Small delay to ensure files are released
                        sleep 0.2
                        
                    )
                    catch e
                    (
                        print ("Error during file handle cleanup: " + (e as string))
                    )
                    
                    return true
                )
                catch (importErr)
                (
                    print ("Import failed: " + importErr as string)
                    messageBox ("Import failed: " + importErr as string) title:"Import Error"
                    return false
                )
            )
            else
            (
                print "loadGBXFile returned false - failed to load file"
                messageBox "Failed to load GBX file for import" title:"Load Error"
                return false
            )
        )
        catch e
        (
            local errorMsg = "Unknown error"
            if e != undefined then
                errorMsg = e as string
            print ("Error loading or importing GBX file: " + errorMsg)
            
            -- Force cleanup on error to prevent file locking
            print "Forcing cleanup due to error..."
            forceFileCleanup gbxPath
            
            messageBox ("Failed to load GBX importer or import file: " + errorMsg) title:"GBX Import Error"
            --pb_progress.visible = false
            return false
        )
    )
    
    --TODO Make an automatic import file system
    -- Event Handlers
    on chk_raw_geometry changed state do
    (
        -- When raw geometry mode is enabled, some options don't apply
        if state then
        (
            -- Disable skeleton-related options
            chk_weights.enabled = false
            --chk_bones.enabled = false
            chk_use_existing_nodes.enabled = false
            --chk_attach.enabled = false
            
            -- Uncheck skeleton-related options
            chk_weights.checked = false
            --chk_bones.checked = false
            chk_use_existing_nodes.checked = false
            chk_attach.checked = true

            
            print "Raw geometry mode enabled - skeleton-related options disabled"
        )
        else
        (
            -- Re-enable skeleton-related options
            chk_weights.enabled = true
            chk_bones.enabled = true
            chk_use_existing_nodes.enabled = true
            --chk_attach.enabled = false
            
            -- Reset to default values
            chk_weights.checked = true
            chk_attach.checked = false
            
            print "Raw geometry mode disabled - skeleton-related options enabled"
        )
    )
    
    on btn_import pressed do
    (
        if collisionFilePath == undefined then
        (
            messageBox "Please select a collision file first!" title:"No File Selected"
            return()
        )
        
        print ("Starting ultimate collision import for: " + collisionFilePath)
        
        -- Validate input file first
        if not doesFileExist collisionFilePath then
        (
            print ("ERROR: Input collision file does not exist: " + collisionFilePath)
            messageBox ("Input file not found: " + collisionFilePath) title:"Input File Error"
            return()
        )
        
        print ("Input file validated, size: " + (getFileSize collisionFilePath) as string + " bytes")
        
        -- Step 1: Convert collision to GBX using Python
        print "Starting Python conversion step..."
        if runPythonConverter collisionFilePath rawMode:chk_raw_geometry.checked then
        (
            print "Python converter returned success, checking output file..."
            -- Check if conversion was successful
            if doesFileExist gbxOutputPath then
            (
                print ("Conversion successful! Output file: " + gbxOutputPath)
                
                -- Step 2: Import using robust silent function
                local thisScriptPath = getSourceFileName()
                local thisScriptDir = getFilenamePath thisScriptPath  
                local gbxImporterPath = thisScriptDir + "collision\\import_gbx_coll.ms"
                
                -- Always reload GBX importer to ensure function availability
                print "Loading GBX importer for silent import..."
                fileIn gbxImporterPath
                
                -- Give MaxScript time to process the loaded functions
                windows.processPostedMessages()
                sleep 0.1  -- Additional delay to ensure function registration
                
                -- Try to get the function reference with retries
                local importGBXFileSilently = undefined
                local retries = 5
                for i = 1 to retries do
                (
                    try
                    (
                        -- Try to get the actual function reference
                        importGBXFileSilently = execute "importGBXFileSilently"
                        if importGBXFileSilently != undefined then
                        (
                            print ("Silent import function loaded successfully on attempt " + i as string)
                            exit
                        )
                        else
                        (
                            print ("Function not loaded, retry " + i as string + "/" + retries as string)
                            windows.processPostedMessages()
                            sleep 0.2  -- Longer delay between retries
                        )
                    )
                    catch
                    (
                        print ("Function loading failed, retry " + i as string + "/" + retries as string)
                        windows.processPostedMessages()
                        sleep 0.2
                    )
                )
                
                -- Try silent import first, fallback to normal if needed
                local importSuccess = false
                if importGBXFileSilently != undefined then
                (
                    print "Using silent import with user options..."
                    
                    -- Call silent import function - don't use try/catch since it works but may throw undefined after success
                    local silentResult = importGBXFileSilently gbxOutputPath useBones:chk_bones.checked attachParts:chk_attach.checked importWeights:chk_weights.checked reuseBones:chk_use_existing_nodes.checked createMaterials:chk_create_materials.checked
                    
                    -- Check the result (the function correctly returns true/false)
                    if silentResult == true then
                    (
                        print "Silent import function returned success!"
                        importSuccess = true
                    )
                    else
                    (
                        print ("Silent import function returned: " + (silentResult as string) + ", trying fallback...")
                        try
                        (
                            importSuccess = importGBXModel gbxOutputPath
                        )
                        catch (fallbackError)
                        (
                            print ("Fallback import also failed: " + (fallbackError as string))
                            importSuccess = false
                        )
                    )
                )
                else
                (
                    print "Silent import function not available after retries, using fallback..."
                    try
                    (
                        importSuccess = importGBXModel gbxOutputPath
                    )
                    catch (errorMsg)
                    (
                        print ("Fallback import also failed: " + (errorMsg as string))
                        importSuccess = false
                    )
                )
                
                if importSuccess then
                (
                    print "Ultimate collision import completed successfully!"
                    messageBox "Collision geometry imported successfully!" title:"Import Complete"
                    
                    -- Enhanced cleanup if requested
                    if chk_cleanup.checked then
                    (
                        print "Starting file cleanup..."
                        
                        -- Wait a moment to ensure import is fully complete
                        sleep 0.2
                        
                        -- Simple, direct file deletion
                        try
                        (
                            if doesFileExist gbxOutputPath then
                            (
                                deleteFile gbxOutputPath
                                print "Temporary GBX file deleted successfully"
                            )
                            else
                            (
                                print "Temporary file already cleaned up"
                            )
                        )
                        catch e
                        (
                            print ("Note: File cleanup encountered minor issue: " + (e as string))
                            print "File may have been deleted by another process - this is normal"
                        )
                    )
                    else
                    (
                        print "Cleanup disabled - temporary GBX file preserved"
                    )
                )
                else
                (
                    print "GBX import failed"
                    
                    -- Cleanup temporary file even on failure
                    if chk_cleanup.checked then
                    (
                        print "Cleaning up temporary file after import failure..."
                        try
                        (
                            if doesFileExist gbxOutputPath then
                            (
                                deleteFile gbxOutputPath
                                print "Temporary GBX file deleted after failure"
                            )
                        )
                        catch (cleanupError)
                        (
                            print ("Cleanup failed: " + (cleanupError as string))
                        )
                    )
                )
            )
            else
            (
                print ("ERROR: Expected output file not found after conversion: " + gbxOutputPath)
                print "Python conversion may have failed silently"
                messageBox "Python conversion completed but output file not found!\nCheck the Listener for Python error messages." title:"Conversion Error"
            )
        )
        else
        (
            print "ERROR: Python conversion failed"
            print "Check the Listener above for Python error messages"
            
            -- Check if this might be a skeleton mismatch and suggest raw mode
            if not chk_raw_geometry.checked then
            (
                local errorMsg = "Conversion failed!\n\nThis might be caused by:"
                errorMsg += "\n• Skeleton mismatch (collision references non-existent bones)"
                errorMsg += "\n• Wrong or modified .gbxmodel file"
                errorMsg += "\n• File compatibility issues"
                errorMsg += "\n\nTry enabling 'Raw geometry mode' to import without skeleton dependency."
                
                messageBox errorMsg title:"Conversion Failed - Try Raw Mode?"
            )
            else
            (
                messageBox "Python conversion failed!\nCheck the Listener for detailed error messages." title:"Python Error"
            )
        )
        
        --pb_progress.visible = false
    )
)

-- Main function to prompt for file FIRST, then show dialog
fn createUltimateCollisionImporter =
(
    print "Ultimate Collision Importer - Select collision file..."
    
    -- First, prompt for file selection
    local inputFile = getOpenFileName caption:"Select Halo CE Collision File" \
                      types:"Collision Files (*.model_collision_geometry)|*.model_collision_geometry|All Files (*.*)|*.*"
    
    if inputFile != undefined then
    (
        print ("File selected: " + inputFile)
        print "Creating Ultimate Collision Importer dialog..."
        
        -- Now create the dialog with the selected file
        createDialog collisionUltimateImporter
        
        -- Set the file path and update UI
        collisionUltimateImporter.collisionFilePath = inputFile
        collisionUltimateImporter.edt_file.text = inputFile
        collisionUltimateImporter.updateOutputPath()
        
        print "Ultimate Collision Importer ready!"
    )
    else
    (
        print "No file selected - Ultimate Collision Importer cancelled"
    )
)

-- Auto-run when script is loaded
print "Ultimate Collision Importer loaded. Starting file selection..."
createUltimateCollisionImporter()