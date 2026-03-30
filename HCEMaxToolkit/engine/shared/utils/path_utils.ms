------------------------------------------------------------------------------
--	Copyright (C) 2025 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------

global pathUtils

struct pathUtilsStruct (
    -- expandEnvVariables : string -> string
    -- Expands %VARNAME% style environment variables in a string.
    fn expandEnvVariables pathStr = (
        local result = pathStr
        local searchOffset = 0
        local keepSearching = true

        while keepSearching do (
            local remainingStr = substring result (searchOffset + 1) -1
            local percentPos   = findString remainingStr "%"
            if percentPos == undefined then (
                keepSearching = false
                continue
            )
            local actualPercentPos = searchOffset + percentPos
            local afterFirstPercent = substring result (actualPercentPos + 1) -1
            local endPos = findString afterFirstPercent "%"
            if endPos == undefined then (
                keepSearching = false
                continue
            )
            local actualEndPos = actualPercentPos + endPos
            local varName  = substring result (actualPercentPos + 1) (actualEndPos - actualPercentPos - 1)
            local varValue = systemTools.getEnvVariable varName
            if varValue != undefined then (
                result = substituteString result ("%" + varName + "%") varValue
                searchOffset = actualPercentPos - 1
            )
            else (
                searchOffset = actualEndPos
            )
        )
        result
    ),

    -- createDirectoryRecursive : string -> bool
    -- Creates a directory and all its parents if they don't exist.
    fn createDirectoryRecursive dirPath = (
        local cleanPath = dirPath
        while cleanPath.count > 0 and cleanPath[cleanPath.count] == "\\" do
            cleanPath = substring cleanPath 1 (cleanPath.count - 1)

        if cleanPath == "" then return false
        if doesDirectoryExist cleanPath then return true

        local parentDir = getFilenamePath cleanPath
        if parentDir == undefined or parentDir == "" then return false

        while parentDir.count > 0 and parentDir[parentDir.count] == "\\" do
            parentDir = substring parentDir 1 (parentDir.count - 1)

        if parentDir != "" and not doesDirectoryExist parentDir then
            createDirectoryRecursive parentDir

        makeDir cleanPath
        return (doesDirectoryExist cleanPath)
    ),

    -- expandPathVariables : string -> string
    -- Expands {username}, {documents} tokens and %VARNAME% environment variables.
    fn expandPathVariables pathStr = (
        local result = pathStr
        if matchPattern result pattern:"*{username}*" then
            result = substituteString result "{username}" sysInfo.username
        if matchPattern result pattern:"*{documents}*" then (
            local userProfile = systemTools.getEnvVariable "USERPROFILE"
            if userProfile != undefined then
                result = substituteString result "{documents}" (userProfile + "\\Documents")
        )
        expandEnvVariables result
    )
)

pathUtils = pathUtilsStruct()
