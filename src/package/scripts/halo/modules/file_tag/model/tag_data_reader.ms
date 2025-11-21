-------------------------------------------------------
-- MODEL TAG DATA READER
-- Wraps gbxmodel data reader but uses model-specific
-- geometry reader for 104-byte parts
-- NOTE: gbxmodel_readAllShaders is set in import_gbxmodel.ms
-------------------------------------------------------

-------------------------------------------------------
-- Read All Shaders with Model-Specific Geometry Processing
-------------------------------------------------------

fn readAllModelShaders shadersReflex geometriesArray currentOffset =
(
    local shadersArray = #()
    local newOffset = currentOffset
    
    if shadersReflex[1] > 0 then
    (
        -- ALWAYS process geometries first (even if shader pointer > 0)
        -- This populates geometriesArray with actual part data
        local processResult = processAllModelGeometries geometriesArray newOffset
        if processResult[1] == true then
        (
            geometriesArray = processResult[2]
            newOffset = processResult[3]  -- Update offset to position after all geometry data
        )
        else
        (
            format "[ERROR] Failed to process geometries\n"
            return #(shadersArray, newOffset, geometriesArray)
        )
        
        -- Now seek to shader block (should be at current position after geometry processing)
        local shadersOffset = if shadersReflex[2] > 0 then shadersReflex[2] else newOffset
        seekToPosition shadersOffset
        
        -- Read shader headers (32 bytes each)
        local shaderHeaders = #()
        for i = 1 to shadersReflex[1] do
        (
            local fileHandle = getCurrentFileHandle()
            local shaderHeaderPos = ftell fileHandle
            
            -- Shader type (4 bytes enum)
            local shaderType = read.longB "#unsigned"
            
            -- Shader path pointer (4 bytes)
            local shaderPathPtr = read.longB "#unsigned"
            
            -- Shader path length (4 bytes)
            local shaderPathLen = read.longB "#unsigned"
            
            -- Skip remaining header data (20 bytes)
            skipBytes 20
            
            -- Store header with permutation info
            local shaderData = #(#(shaderType, shaderPathPtr, shaderPathLen, shaderHeaderPos + 32))
            append shaderHeaders shaderData
            
        )
        newOffset += (shadersReflex[1] * 32)
        
        -- Now read shader paths (sequential null-terminated strings, NOT fixed blocks)
        local fileHandle = getCurrentFileHandle()

        for i = 1 to shaderHeaders.count do
        (
            -- Read shader path - just use null-terminated reader, no skipping needed
            local shaderPath = read.nullTerminatedString()
            
            -- Extract shader type from header
            local shaderHeader = shaderHeaders[i][1]
            local shaderType = shaderHeader[1]
            local pathPtr = shaderHeader[2]
            local pathLen = shaderHeader[3]
            
            -- Calculate permutation number from pointer value
            -- This is a heuristic - actual calculation may vary 
            local permutationNum = (bit.shift pathPtr -16) + (bit.and pathLen 0xFFFF)
            
            -- Convert type to string
            local shaderTypeName = "unknown_" + (shaderType as string)
            
            if shaderPath == "" then
                shaderPath = "<no path>"
            
            -- Extract shader name from path (last component)
            local shaderName = "<no name>"
            if shaderPath != "<no path>" then
            (
                local pathParts = filterString shaderPath "\\"
                if pathParts.count > 0 then
                    shaderName = pathParts[pathParts.count]
                else
                    shaderName = shaderPath
            )
            
            local shaderData = #(shaderHeader, shaderPath, shaderName, shaderTypeName)
            append shadersArray shaderData
            
        )
        -- Note: newOffset is approximate since paths are variable-length
    )
    
    return #(shadersArray, newOffset, geometriesArray)
)

format "Model Data Reader loaded successfully.\n"
