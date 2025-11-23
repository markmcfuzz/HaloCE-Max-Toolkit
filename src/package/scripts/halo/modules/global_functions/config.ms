-- Config File for Global Functions Module

------------------------------------------------------------
-- Logger Configuration (must be defined FIRST)
------------------------------------------------------------
-- Logger output control flags
global loggerDebug = true        -- Debug messages
global loggerInfo = true         -- Info messages
global loggerWarning = false      -- Warning messages
global loggerError = true        -- Error messages
global loggerSuccess = true     -- Success messages
global loggerDefault = true      -- Default messages
global loggerTimestamp = false   -- Timestamp messages

-- File logging
global enableFileLogging = false  -- Set to true to enable log file output
global logFile = undefined        -- Will hold the file handle when logging to file

fn logger text params:#() logType:#default =
(
    local actualType = logType
    local actualText = text
    local actualParams = params
    
    -- Check if this logger type is enabled
    local shouldLog = case actualType of
    (
        #debug: loggerDebug
        #info: loggerInfo
        #warning: loggerWarning
        #error: loggerError
        #success: loggerSuccess
        #default: loggerDefault
        #timestamp: loggerTimestamp
    )
    
    if shouldLog do
    (
        -- Add prefix based on type
        local prefix = case actualType of
        (
            #debug: "[DEBUG] "
            #info: "[INFO] "
            #warning: "[WARNING] "
            #error: "[ERROR] "
            #success: "[SUCCESS] "
            #default: ""
            #timestamp: "[TIMESTAMP] "
        )
        
        local fullText = prefix + actualText
        
        case actualParams.count of
        (
            0: format fullText
            1: format fullText actualParams[1]
            2: format fullText actualParams[1] actualParams[2]
            3: format fullText actualParams[1] actualParams[2] actualParams[3]
            4: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4]
            5: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5]
            6: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5] actualParams[6]
            7: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5] actualParams[6] actualParams[7]
            8: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5] actualParams[6] actualParams[7] actualParams[8]
            9: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5] actualParams[6] actualParams[7] actualParams[8] actualParams[9]
            10: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5] actualParams[6] actualParams[7] actualParams[8] actualParams[9] actualParams[10]
            default: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5] actualParams[6] actualParams[7] actualParams[8] actualParams[9] actualParams[10] actualParams[11]
        )
        
        -- Write to log file if enabled
        if enableFileLogging and logFile != undefined do
        (
            case actualParams.count of
            (
                0: format fullText to:logFile
                1: format fullText actualParams[1] to:logFile
                2: format fullText actualParams[1] actualParams[2] to:logFile
                3: format fullText actualParams[1] actualParams[2] actualParams[3] to:logFile
                4: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] to:logFile
                5: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5] to:logFile
                6: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5] actualParams[6] to:logFile
                7: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5] actualParams[6] actualParams[7] to:logFile
                8: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5] actualParams[6] actualParams[7] actualParams[8] to:logFile
                9: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5] actualParams[6] actualParams[7] actualParams[8] actualParams[9] to:logFile
                10: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5] actualParams[6] actualParams[7] actualParams[8] actualParams[9] actualParams[10] to:logFile
                default: format fullText actualParams[1] actualParams[2] actualParams[3] actualParams[4] actualParams[5] actualParams[6] actualParams[7] actualParams[8] actualParams[9] actualParams[10] actualParams[11] to:logFile
            )
            flush logFile  -- Ensure it writes immediately
        )
    )
)

-----------------------------------------------------------
-- Global Values Init (Just for Debugging)
------------------------------------------------------------
fn setGlobalValue varName value =
(
    -- Helper function to safely set a global variable by name
    -- Use string formatting to properly embed the value
    local valueStr = case (classOf value) of
    (
        BooleanClass: (if value then "true" else "false")
        String: ("\"" + value + "\"")
        default: (value as string)
    )
    local code = "global " + varName + " = " + valueStr
    execute code
)

fn initDefaultGlobal name defaultValue forceUpdate:false =
(
    local current = execute name

    if current == undefined then
    (
        logger "Config: Initializing % to %\n" params:#(name, defaultValue) logType:#warning
        setGlobalValue name defaultValue
    )
    else if forceUpdate or current != defaultValue then
    (
        -- Convert values to strings for proper display
        local currentStr = current as string
        local defaultStr = defaultValue as string
        logger "Config: Updating % from (%) to (%)\n" params:#(name, currentStr, defaultStr) logType:#warning
        setGlobalValue name defaultValue
    )
    else
    (
        logger "Config: % already exists as (%).\n" params:#(name, current) logType:#warning
    )
)

------------------------------------------------------------
-- Configuration Initialization
------------------------------------------------------------
fn initConfig =
(
    -- Don't touch this!
    local isCompressed = true
    -- Enable compressed-only mode for faster import.
    -- Compressed vertices: ~1.2s import, 16-bit precision (0.00001 weight accuracy)
    -- Uncompressed vertices: ~3.8s import, 32-bit precision (full accuracy)
    initDefaultGlobal "USE_COMPRESSED_ONLY" isCompressed

    local tagDataDebug = false
    -- Enable detailed logging for tag data reading
    initDefaultGlobal "readNodesLogger" tagDataDebug
    initDefaultGlobal "readRegionsLogger" tagDataDebug
    initDefaultGlobal "readPermutationsLogger" tagDataDebug
    initDefaultGlobal "readLocalMarkersLogger" tagDataDebug
    initDefaultGlobal "readGeometriesLogger" tagDataDebug
    initDefaultGlobal "readShadersLogger" tagDataDebug
    initDefaultGlobal "readPartsLogger" tagDataDebug
    
    local verboseGeometryLogging = false
    -- WARNING: This reads ALL vertex/triangle data twice (once for logging, once for mesh building)
    -- Only enable when debugging specific geometry issues
    initDefaultGlobal "readVertexDataLogger" verboseGeometryLogging
    initDefaultGlobal "readTriangleDataLogger" verboseGeometryLogging
    
    local cacheVertexData = false
    -- EXPERIMENTAL: Cache vertex data in memory during reading to avoid double file I/O
    -- When false, vertices are read from file during mesh building (current proven behavior)
    -- When true, vertices are read once and cached in memory (faster but uses more RAM)
    initDefaultGlobal "CACHE_VERTEX_DATA" cacheVertexData

    local tagBaseDebug = true
    -- Enable detailed logging for tag base reading
    initDefaultGlobal "tagHeaderLogger" tagBaseDebug
    initDefaultGlobal "tagMainDataLogger" tagBaseDebug
    initDefaultGlobal "tagSummaryLogger" tagBaseDebug

    local tagTimeStampDebug = true
    -- Enable timestamp logging for tag reading performance
    initDefaultGlobal "timeStampLogger" tagTimeStampDebug
)

-- Initialize configuration
initConfig()



logger "Config loaded.\n" logType:#success
