------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- Logger Configuration (must be defined FIRST)
------------------------------------------------------------
-- Logger output control flags
global loggerDebug = false        -- Debug messages
global loggerInfo = false         -- Info messages
global loggerWarning = false      -- Warning messages
global loggerError = false        -- Error messages
global loggerSuccess = false     -- Success messages
global loggerDefault = false      -- Default messages
global loggerTimestamp = false   -- Timestamp messages

-- File logging
-- Set to true to enable log file output
global enableFileLogging = false  
global logFile = undefined        

fn logger text params:#() logType:#default =
(
    local actualType = logType
    local actualText = text
    local actualParams = params
    
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
            flush logFile
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
    local verboseGeometryLogging = false
    -- WARNING: This reads ALL vertex/triangle data twice (once for logging, once for mesh building)
    -- Only enable when debugging specific geometry issues
    initDefaultGlobal "readVertexDataLogger" verboseGeometryLogging
    initDefaultGlobal "readTriangleDataLogger" verboseGeometryLogging
    initDefaultGlobal "readNodesBspLogger" verboseGeometryLogging
    
    local shadersLogging = false
    initDefaultGlobal "gbxShadersLogger" shadersLogging

    local tagBaseDebug = false
    -- Enable detailed logging for tag base reading
    initDefaultGlobal "tagHeaderLogger" tagBaseDebug
    initDefaultGlobal "tagMainDataLogger" tagBaseDebug
    initDefaultGlobal "tagSummaryLogger" tagBaseDebug

    local tagTimeStampDebug = false
    -- Enable timestamp logging for tag reading performance
    initDefaultGlobal "timeStampLogger" tagTimeStampDebug
)

-- Initialize configuration
initConfig()

logger "Config loaded.\n" logType:#success
