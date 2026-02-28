global pathUtils

struct pathUtilsStruct
(
    fn createDirectoryRecursive dirPath =
    (
        -- Remove trailing backslashes
        local cleanPath = dirPath
        while cleanPath.count > 0 and cleanPath[cleanPath.count] == "\\" do 
            cleanPath = substring cleanPath 1 (cleanPath.count - 1)
        if cleanPath == "" then return false
        if doesDirectoryExist cleanPath then return true
        -- Get parent directory
        local parentDir = getFilenamePath cleanPath
        if parentDir != undefined and parentDir != "" then
        (
            -- Remove trailing backslash for parent
            while parentDir.count > 0 and parentDir[parentDir.count] == "\\" do 
                parentDir = substring parentDir 1 (parentDir.count - 1)
            -- Create parent if it doesn't exist
            if parentDir != "" and not doesDirectoryExist parentDir then
                createDirectoryRecursive parentDir
        )
        -- Create this directory
        makeDir cleanPath
        return (doesDirectoryExist cleanPath)
    ),

    fn expandPathVariables pathStr =
    (
        local result = pathStr
        -- Expand {username} token
        if matchPattern result pattern:"*{username}*" then
        (
            local username = sysInfo.username
            result = substituteString result "{username}" username
        )
        -- Expand {documents} token - get user's Documents folder
        if matchPattern result pattern:"*{documents}*" then
        (
            local userProfile = systemTools.getEnvVariable "USERPROFILE"
            if userProfile != undefined then
            (
                local documentsPath = userProfile + "\\Documents"
                result = substituteString result "{documents}" documentsPath
            )
        )
        -- Expand environment variables like %USERPROFILE%, %TEMP%, etc.
        local startPos = 1
        while startPos <= result.count do
        (
            local percentPos = findString result "%" startPos:startPos
            if percentPos != undefined then
            (
                local endPos = findString result "%" startPos:(percentPos + 1)
                if endPos != undefined then
                (
                    local varName = substring result (percentPos + 1) (endPos - percentPos - 1)
                    local varValue = systemTools.getEnvVariable varName
                    if varValue != undefined then
                    (
                        local varToken = "%" + varName + "%"
                        result = substituteString result varToken varValue
                        startPos = percentPos  -- Re-check from same position
                    )
                    else
                    (
                        startPos = endPos + 1
                    )
                )
                else
                (
                    startPos = result.count + 1  -- No closing %, stop searching
                )
            )
            else
            (
                startPos = result.count + 1  -- No more % found
            )
        )
        return result
    )
)

pathUtils = pathUtilsStruct()
