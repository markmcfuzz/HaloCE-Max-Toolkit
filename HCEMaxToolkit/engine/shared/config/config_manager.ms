global configManager

------------------------------------------------------------
-- Helper function to create default config content
------------------------------------------------------------
fn getDefaultConfigContent =
(
    local content = ""
    content += "[import_gbxmodel]\n"
    content += "; Controls whether the \"Uncompressed Vertices\" block\n"
    content += "; is omitted during parsing (1 = enable, 0 = disable).\n"
    content += "; The cyborg's fp.gbxmodel from MCC contains model parts\n"
    content += "; without compressed vertices.\n"
    content += "; Disable this option to import that gbxmodel correctly,\n"
    content += "; but note that it will increase import time.\n"
    content += "skip_uncompressed_vertices=0\n"
    content += "; create_nodes=1\n"
    content += "; create_markers=1\n"
    content += "; create_geometry=1\n"
    content += "; create_material_textures=1\n"
    content += "; reuse_scene_nodes=1\n"
    content += "; reuse_scene_materials=1\n\n"
    content += "[import_collision]\n\n"
    content += "[import_jms]\n\n"
    content += "[import_jma]\n\n"
    content += "[import_structure_bsp]\n\n"
    content += "[logger]\n"
    content += "; Enable or disable logging with levels (1 = enable, 0 = disable)\n"
    content += "; Note: The \"default\" level is used when no specific log type is provided.\n"
    content += "; Enable logging can impact import performance, especially if saving log files is enabled,\n"
    content += "; so it's recommended to disable both it for regular use and only enable it when needed for debugging.\n"
    content += "enable_logging=0\n"
    content += "debug=1\n"
    content += "info=1\n"
    content += "warning=1\n"
    content += "error=1\n"
    content += "default=1\n"
    content += "trace=1\n"
    content += "; Enable to save log files to a directory (1 = enable, 0 = disable).\n"
    content += "enable_save_log_file=0\n"
    content += "; Supports path expansion with:\n"
    content += ";   {username}  - Current Windows username\n"
    content += ";   {documents} - Current user's Documents folder\n"
    content += ";   %VARNAME%   - Any Windows environment variable (e.g., %USERPROFILE%, %TEMP%)\n"
    content += "; Examples:\n"
    content += ";   Relative path: logs\\\\importer.log\n"
    content += ";   User's Documents: {documents}\\\\HCE Max Toolkit\\\\logs\\\\importer.log\n"
    content += ";   Environment var: %USERPROFILE%\\\\Documents\\\\HCE Max Toolkit\\\\logs\\\\importer.log\n"
    content += ";   Absolute path: C:\\\\MyLogs\\\\importer.log\n"
    content += "; Note: The actual log filename will be based on the calling script (e.g., import_gbxmodel.log)\n"
    content += "; Log file is saved by default in documents\\HCE Max Toolkit\\logs\\ if enable_save_log_file is enabled\n"
    content += "; but you can specify a custom path.\n"
    content += "; log_file=logs\\\\importer.log\n"
    
    return content
)

struct configManagerStruct
(
    iniPath,
    
    fn init configPath:undefined =
    (
        -- Default path to user's Documents folder
        local defaultPath = "{documents}\\HCE Max Toolkit\\config.ini"
        
        -- Use provided path or default
        local targetPath = if configPath != undefined then configPath else defaultPath
        
        -- Expand path variables (like {documents}, {username}, %USERPROFILE%)
        targetPath = pathUtils.expandPathVariables targetPath
        
        -- Create directory if it doesn't exist
        local configDir = getFilenamePath targetPath
        if configDir != undefined and configDir != "" then
        (
            pathUtils.createDirectoryRecursive configDir
        )
        
        -- Create default config file if it doesn't exist
        if not doesFileExist targetPath then
        (
            format "Config file not found at: %\n" targetPath
            format "Creating default config.ini...\n"
            
            local configFile = createFile targetPath
            if configFile != undefined then
            (
                -- Write the content string directly without format processing
                local defaultContent = getDefaultConfigContent()
                format "%" defaultContent to:configFile
                flush configFile
                close configFile
                format "Default config.ini created successfully at: %\n" targetPath
            )
            else
            (
                format "ERROR: Could not create config file at: %\n" targetPath
                iniPath = undefined
                return undefined
            )
        )
        
        iniPath = targetPath
        format "Config loaded from: %\n" iniPath
    ),
    
    fn getRaw section key =
    (
        if iniPath == undefined then 
            return undefined
        getINISetting iniPath section key
    ),

    fn getString section key defaultValue =
    (
        local val = getRaw section key
        if val == "" or val == undefined then 
            defaultValue
        else
            val
    ),

    fn getInt section key defaultValue =
    (
        local val = getRaw section key
        if val == "" or val == undefined then
            defaultValue
        else
            try (val as integer) catch defaultValue
    ),

    fn getBool section key defaultValue =
    (
        local val = getRaw section key
        if val == "" or val == undefined then
            defaultValue
        else
            try ((val as integer) == 1) catch defaultValue
    )
)

configManager = configManagerStruct()