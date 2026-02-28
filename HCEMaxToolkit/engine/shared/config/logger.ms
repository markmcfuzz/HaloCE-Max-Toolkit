struct Logger
(
    ------------------------------------------------------------------
    -- PROPERTIES
    ------------------------------------------------------------------
    enableLogging = false,
    loggerDebug = false,
    loggerInfo = false,
    loggerWarning = false,
    loggerError = false,
    loggerTrace = false,
    loggerDefault = false,
    enableSaveLogFile = false,
    logFile = undefined,
    ------------------------------------------------------------------
    -- LOAD CONFIG
    ------------------------------------------------------------------
    fn loadConfig callerScriptName:undefined =
    (
        enableLogging     = configManager.getBool "logger" "enable_logging" false
        loggerDebug       = configManager.getBool "logger" "debug" false
        loggerInfo        = configManager.getBool "logger" "info" false
        loggerWarning     = configManager.getBool "logger" "warning" false
        loggerError       = configManager.getBool "logger" "error" false
        loggerTrace       = configManager.getBool "logger" "trace" false
        loggerDefault     = configManager.getBool "logger" "default" false
        enableSaveLogFile = configManager.getBool "logger" "enable_save_log_file" false
        
        local logFileSetting = configManager.getString \
            "logger" "log_file" "{documents}\\HCE Max Toolkit\\logs\\importer.log"
        logFileSetting = pathUtils.expandPathVariables logFileSetting
        local baseDir = getFilenamePath (getThisScriptFilename())
        local scriptName = if callerScriptName != undefined \
                            then callerScriptName \
                            else getFilenameFile (getThisScriptFilename())
        local isAbsolutePath = (logFileSetting.count >= 3 and \
                                logFileSetting[2] == ":" and \
                                logFileSetting[3] == "\\")
        local logDir
        if isAbsolutePath then
        (
            logDir = getFilenamePath logFileSetting
        )
        else
        (
            local logDirRelative = getFilenamePath logFileSetting
            while baseDir[baseDir.count] == "\\" do
                baseDir = substring baseDir 1 (baseDir.count - 1)
                
            while logDirRelative[logDirRelative.count] == "\\" do
                logDirRelative = substring logDirRelative 1 (logDirRelative.count - 1)
            logDir = baseDir + "\\" + logDirRelative
        )
        pathUtils.createDirectoryRecursive logDir
        while logDir[logDir.count] == "\\" do
            logDir = substring logDir 1 (logDir.count - 1)
        local logFileName = scriptName + ".log"
        local logFilePath = logDir + "\\" + logFileName
        if enableSaveLogFile then
        (
            if not doesFileExist logFilePath then
            (
                local f = createFile logFilePath
                if f != undefined then
                (
                    format "Log created for %\n\n" scriptName to:f
                    flush f
                    close f
                )
            )
            logFile = logFilePath
        )
        else
        (
            logFile = undefined
        )
    ),
    ------------------------------------------------------------------
    -- TIMESTAMP
    ------------------------------------------------------------------
    fn formatTimestamp =
    (
        local t = localTime
        local timeStr = t as string
        local spaceParts = filterString timeStr " "
        if spaceParts.count >= 3 then
        (
            local datePart = spaceParts[1]
            local timePart = spaceParts[2]
            local ampm1 = spaceParts[3]
            local timeParts = filterString timePart ":"
            if timeParts.count >= 3 then
            (
                local hour = timeParts[1] as integer
                local minute = timeParts[2]
                local second = timeParts[3]
                if ampm1 == "p." and hour != 12 then hour += 12
                else if ampm1 == "a." and hour == 12 then hour = 0
                local hourStr = if hour < 10 then \
                                ("0" + hour as string) \
                                else hour as string
                return (datePart + " " + hourStr + ":" + minute + ":" + second)
            )
        )
        timeStr
    ),
    ------------------------------------------------------------------
    -- APPLY ARGS
    ------------------------------------------------------------------
    fn _applyArgs text args =
    (
        local result = text
        for i = 1 to args.count do
        (
            local pos = findString result "{}"
            if pos != undefined then
            (
                local before = substring result 1 (pos - 1)
                local after = substring result (pos + 2) -1
                result = before + (args[i] as string) + after
            )
        )
        result
    ),
    ------------------------------------------------------------------
    -- CORE LOG
    ------------------------------------------------------------------
    fn _log levelStr levelFlag text args:#() =
    (
        if (not enableLogging or not levelFlag) and \
            (not enableSaveLogFile or logFile == undefined) then
            return undefined

        local ts = formatTimestamp()
        local prefix = if levelStr != "" \
                        then ts + " " + levelStr + " " \
                        else ts + " "

        local fullText = prefix + text
        local finalText = _applyArgs fullText args

        if enableLogging and levelFlag do
            print (finalText + "\n")

        if enableSaveLogFile and logFile != undefined do
        (
            try
            (
                local f = openFile logFile mode:"a"
                if f != undefined do
                (
                    format "%\n" finalText to:f
                    flush f
                    close f
                )
            )
            catch()
        )
    ),
    ------------------------------------------------------------------
    -- PUBLIC API
    ------------------------------------------------------------------
    fn debug text args:#() = _log "DEBUG" loggerDebug text args:args,
    fn info  text args:#() = _log "INFO"  loggerInfo text args:args,
    fn warn  text args:#() = _log "WARN"  loggerWarning text args:args,
    fn error text args:#() = _log "ERROR" loggerError text args:args,
    fn trace text args:#() = _log "TRACE" loggerTrace text args:args,
    fn log   text args:#() = _log "" loggerDefault text args:args
)

-- Singleton limpio
global logger = Logger()