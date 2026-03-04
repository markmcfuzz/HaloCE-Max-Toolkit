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
        -- Compatible with 3ds Max 2023 and older (findString only accepts 2 parameters)
        local searchOffset = 0
        local keepSearching = true
        while keepSearching do
        (
            -- Search in the remaining part of the string
            local remainingStr = substring result (searchOffset + 1) -1
            local percentPos = findString remainingStr "%"
            
            if percentPos != undefined then
            (
                -- Adjust position to full string coordinates
                local actualPercentPos = searchOffset + percentPos
                
                -- Look for closing % in the substring after the first %
                local afterFirstPercent = substring result (actualPercentPos + 1) -1
                local endPos = findString afterFirstPercent "%"
                
                if endPos != undefined then
                (
                    -- Adjust end position to full string coordinates
                    local actualEndPos = actualPercentPos + endPos
                    
                    local varName = substring result (actualPercentPos + 1) (actualEndPos - actualPercentPos - 1)
                    local varValue = systemTools.getEnvVariable varName
                    
                    if varValue != undefined then
                    (
                        local varToken = "%" + varName + "%"
                        result = substituteString result varToken varValue
                        -- Continue searching from the same position (string has changed)
                        searchOffset = actualPercentPos - 1
                    )
                    else
                    (
                        -- Variable not found, skip past this pair
                        searchOffset = actualEndPos
                    )
                )
                else
                (
                    -- No closing %, stop searching
                    keepSearching = false
                )
            )
            else
            (
                -- No more % found
                keepSearching = false
            )
        )
        return result
    )
)

pathUtils = pathUtilsStruct()
