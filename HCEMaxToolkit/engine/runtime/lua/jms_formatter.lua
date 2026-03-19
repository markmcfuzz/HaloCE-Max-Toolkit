------------------------------------------------------------------------------------------------
--	Copyright (C) 2025-present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	JMS FORMAT REPAIR TOOL - Handles ultra-rare edge case formats
--	Specifically designed for "ultra-inline" Case 2 format where ALL vertices
--	are on a single line followed by triangle count.
--
--	Standard and inline (Case 1) formats are natively supported by the importer.
--	This tool is ONLY for extremely unusual formats that can't be directly imported.
------------------------------------------------------------------------------------------------


local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function split(str, delimiter)
    local result = {}
    local pattern = string.format("([^\t]+)")
    for match in str:gmatch(pattern) do
        table.insert(result, trim(match))
    end
    return result
end

local function convertJMS(inputPath, outputPath)
    local inputFile = io.open(inputPath, "r")
    if not inputFile then
        return false, "Failed to open input file: " .. inputPath
    end

    local outputFile = io.open(outputPath, "w")
    if not outputFile then
        inputFile:close()
        return false, "Failed to create output file: " .. outputPath
    end

    local lineNum = 0
    local state = "header"
    local nodeCount = 0
    local shaderCount = 0
    local markerCount = 0
    local regionCount = 0
    local vertexCount = 0
    local triangleCount = 0

    local nodesProcessed = 0
    local shadersProcessed = 0
    local markersProcessed = 0
    local regionsProcessed = 0
    local verticesProcessed = 0
    local trianglesProcessed = 0
    
    -- Triangle validation buffer
    local triangleBuffer = {}
    local triangleCountWritten = false
    local validTriangleCount = 0

    for rawLine in inputFile:lines() do
        lineNum = lineNum + 1
        local line = trim(rawLine)

        -- Skip empty lines
        if line ~= "" then
            -- Parse header (version, checksum, node count)
            if state == "header" then
                local parts = split(line, "\t")
                if #parts >= 3 then
                    outputFile:write(parts[1] .. "\n") -- version
                    outputFile:write(parts[2] .. "\n") -- checksum
                    nodeCount = tonumber(parts[3])
                    outputFile:write(nodeCount .. "\n") -- node count
                    state = "nodes"
                end

                -- Parse nodes
            elseif state == "nodes" then
                if nodesProcessed < nodeCount then
                    local parts = split(line, "\t")
                    -- Format: name child sibling i j k w x y z
                    if #parts >= 10 then
                        outputFile:write(parts[1] .. "\n") -- name (preserve original)
                        outputFile:write(parts[2] .. "\n") -- first_child_node_index
                        outputFile:write(parts[3] .. "\n") -- next_sibling_node_index
                        -- Rotation (i j k w)
                        outputFile:write(string.format("%f\t%f\t%f\t%f\n", tonumber(parts[4]),
                                                        tonumber(parts[5]), tonumber(parts[6]),
                                                        tonumber(parts[7])))
                        -- Translation (x y z)
                        outputFile:write(string.format("%f\t%f\t%f\n", tonumber(parts[8]),
                                                        tonumber(parts[9]), tonumber(parts[10])))
                        nodesProcessed = nodesProcessed + 1
                    end
                else
                    -- Next line should be shader count
                    shaderCount = tonumber(line)
                    if not shaderCount then
                        inputFile:close()
                        outputFile:close()
                        return false, "Invalid shader count at line " .. lineNum .. ": '" .. line .. "'"
                    end
                    outputFile:write(shaderCount .. "\n")
                    state = "shaders"
                end

                -- Parse shaders
            elseif state == "shaders" then
                if shadersProcessed < shaderCount then
                    local parts = split(line, "\t")
                    -- Format: name path
                    if #parts >= 2 then
                        outputFile:write(parts[1] .. "\n") -- name
                        outputFile:write(parts[2] .. "\n") -- path
                        shadersProcessed = shadersProcessed + 1
                    end
                else
                    -- Next line should be marker count
                    markerCount = tonumber(line)
                    if not markerCount then
                        inputFile:close()
                        outputFile:close()
                        return false, "Invalid marker count at line " .. lineNum .. ": '" .. line .. "'"
                    end
                    outputFile:write(markerCount .. "\n")
                    state = "markers"
                end

                -- Parse markers
            elseif state == "markers" then
                if markersProcessed < markerCount then
                    local parts = split(line, "\t")
                    -- Format: name region parent i j k w x y z radius
                    if #parts >= 11 then
                        outputFile:write(parts[1] .. "\n") -- name
                        outputFile:write(parts[2] .. "\n") -- region
                        outputFile:write(parts[3] .. "\n") -- parent_node_index
                        -- Rotation (i j k w)
                        outputFile:write(string.format("%f\t%f\t%f\t%f\n", tonumber(parts[4]),
                                                        tonumber(parts[5]), tonumber(parts[6]),
                                                        tonumber(parts[7])))
                        -- Translation (x y z)
                        outputFile:write(string.format("%f\t%f\t%f\n", tonumber(parts[8]),
                                                        tonumber(parts[9]), tonumber(parts[10])))
                        -- Radius
                        outputFile:write(string.format("%f\n", tonumber(parts[11])))
                        markersProcessed = markersProcessed + 1
                    end
                else
                    -- Next line should be region count
                    regionCount = tonumber(line)
                    if not regionCount then
                        inputFile:close()
                        outputFile:close()
                        return false, "Invalid region count at line " .. lineNum .. ": '" .. line .. "'"
                    end
                    outputFile:write(regionCount .. "\n")
                    state = "regions"
                end

                -- Parse regions
            elseif state == "regions" then
                if regionsProcessed < regionCount then
                    outputFile:write(line .. "\n") -- region name
                    regionsProcessed = regionsProcessed + 1
                else
                    -- Next line should be vertex count
                    vertexCount = tonumber(line)
                    if not vertexCount then
                        inputFile:close()
                        outputFile:close()
                        return false, "Invalid vertex count at line " .. lineNum .. ": '" .. line .. "'"
                    end
                    -- DON'T write vertex count yet - wait until after processing vertices
                    -- in case we need to correct it (Case 2 data mismatch)
                    state = "vertices"
                end

                -- Parse vertices
            elseif state == "vertices" then
                if verticesProcessed < vertexCount then
                    local parts = split(line, "\t")
                    
                    -- DETECTION: Determine if this is ultra-inline Case 2 or regular inline Case 1
                    if verticesProcessed == 0 then
                        local fieldsPerVertex = 12
                        local expectedFieldsCase1 = fieldsPerVertex
                        local expectedFieldsCase2 = (vertexCount * fieldsPerVertex) + 1  -- +1 for triangle count
                        
                        print(string.format("Detected %d fields on first vertex line", #parts))
                        print(string.format("Expected for Case 1 (inline per vertex): %d", expectedFieldsCase1))
                        print(string.format("Expected for Case 2 (ultra-inline): ~%d", expectedFieldsCase2))
                        
                        -- Case 1: Each vertex on separate line (NOW NATIVELY SUPPORTED!)
                        if #parts >= 12 and #parts < 50 then
                            inputFile:close()
                            outputFile:close()
                            return false, "ERROR: This file uses standard inline format (Case 1), which is now natively supported by the JMS importer.\n\n" ..
                                         "Please import this file directly using:\n" ..
                                         "  Tools > HCE Max Toolkit > Import JMS\n\n" ..
                                         "The repair tool is only needed for ultra-rare Case 2 format (all vertices on one line)."
                        end
                        
                        -- Case 2: ALL vertices on one massive line (ULTRA-INLINE)
                        if #parts > 50 then
                            print("Ultra-inline Case 2 format detected - processing...")
                            
                            -- Calculate actual vertex count from available data
                            -- Last field should be triangle count, so: (totalFields - 1) / 12 = actual vertices
                            local actualVertexCount = math.floor((#parts - 1) / fieldsPerVertex)
                            local vertexFieldCount = actualVertexCount * fieldsPerVertex
                            
                            -- Show warning if declared count doesn't match actual data
                            if actualVertexCount ~= vertexCount then
                                print(string.format("WARNING: Declared vertex count (%d) doesn't match actual data (%d vertices found)", 
                                                   vertexCount, actualVertexCount))
                                print(string.format("  - Declared: %d vertices = %d fields expected", vertexCount, vertexCount * fieldsPerVertex))
                                print(string.format("  - Found: %d fields total, %d vertex fields + 1 triangle count", #parts, vertexFieldCount))
                                print("  - Using actual vertex count from data...")
                                vertexCount = actualVertexCount
                            end
                            
                            if vertexFieldCount + 1 > #parts then
                                inputFile:close()
                                outputFile:close()
                                return false, string.format("ERROR: Insufficient vertex data - need at least %d fields, found %d", 
                                                           vertexFieldCount + 1, #parts)
                            end
                            
                            -- Write corrected vertex count to output
                            outputFile:write(vertexCount .. "\n")
                            
                            -- Parse vertices from the massive line in chunks of 12
                            for v = 1, vertexCount do
                                local offset = (v - 1) * fieldsPerVertex
                                
                                outputFile:write(parts[offset + 1] .. "\n") -- node0_index
                                -- Position (x y z)
                                outputFile:write(string.format("%f\t%f\t%f\n", 
                                    tonumber(parts[offset + 2]), tonumber(parts[offset + 3]), tonumber(parts[offset + 4])))
                                -- Normal (nx ny nz)
                                outputFile:write(string.format("%f\t%f\t%f\n", 
                                    tonumber(parts[offset + 5]), tonumber(parts[offset + 6]), tonumber(parts[offset + 7])))
                                outputFile:write(parts[offset + 8] .. "\n") -- node1_index
                                outputFile:write(string.format("%f\n", tonumber(parts[offset + 9]))) -- node1_weight
                                -- Texture coordinates
                                outputFile:write(string.format("%f\n", tonumber(parts[offset + 10]))) -- texU
                                outputFile:write(string.format("%f\n", tonumber(parts[offset + 11]))) -- texV
                                outputFile:write(parts[offset + 12] .. "\n") -- texIndex
                            end
                            
                            -- Extract triangle count from the end of the same line
                            local triangleCountIndex = (vertexCount * fieldsPerVertex) + 1
                            if triangleCountIndex <= #parts then
                                triangleCount = tonumber(parts[triangleCountIndex])
                                if triangleCount then
                                    -- DON'T write triangle count yet - we need to validate triangles first
                                    print(string.format("Extracted triangle count: %d (will validate before writing)", triangleCount))
                                else
                                    inputFile:close()
                                    outputFile:close()
                                    return false, "ERROR: Could not parse triangle count from ultra-inline vertex line"
                                end
                            else
                                inputFile:close()
                                outputFile:close()
                                return false, "ERROR: Triangle count not found at expected position in ultra-inline format"
                            end
                            
                            verticesProcessed = vertexCount  -- Mark all vertices as processed
                            state = "triangles"
                        else
                            inputFile:close()
                            outputFile:close()
                            return false, string.format("ERROR: Unexpected format - found %d fields on first vertex line", #parts)
                        end
                    end
                else
                    -- This branch shouldn't be reached for ultra-inline Case 2
                    -- Next line should be triangle count (for non ultra-inline formats)
                    triangleCount = tonumber(line)
                    if not triangleCount then
                        inputFile:close()
                        outputFile:close()
                        return false, "Invalid triangle count at line " .. lineNum .. ": '" .. line .. "'"
                    end
                    -- DON'T write triangle count yet - we'll write it after validation
                    state = "triangles"
                end

                -- Parse triangles
            elseif state == "triangles" then
                if trianglesProcessed < triangleCount then
                    local parts = split(line, "\t")
                    -- Format: region shader v0 v1 v2
                    if #parts >= 5 then
                        -- Validate vertex indices against corrected vertex count
                        local v0 = tonumber(parts[3])
                        local v1 = tonumber(parts[4])
                        local v2 = tonumber(parts[5])
                        
                        -- Check if any vertex index is out of bounds (>= vertexCount since indices are 0-based)
                        if v0 >= vertexCount or v1 >= vertexCount or v2 >= vertexCount then
                            print(string.format("WARNING: Skipping triangle %d with out-of-bounds vertex indices [%d, %d, %d] (valid range: 0-%d)", 
                                               trianglesProcessed + 1, v0, v1, v2, vertexCount - 1))
                        else
                            -- Replace "undefined" with "0" for region index
                            local regionIndex = parts[1]
                            if regionIndex:lower() == "undefined" then
                                regionIndex = "0"
                            end
                            
                            -- Buffer valid triangle
                            table.insert(triangleBuffer, {
                                region = regionIndex,
                                shader = parts[2],
                                v0 = parts[3],
                                v1 = parts[4],
                                v2 = parts[5]
                            })
                            validTriangleCount = validTriangleCount + 1
                        end
                        trianglesProcessed = trianglesProcessed + 1
                    end
                else
                    -- Write corrected triangle count if not already written
                    if not triangleCountWritten then
                        outputFile:write(validTriangleCount .. "\n")
                        triangleCountWritten = true
                        
                        if validTriangleCount < triangleCount then
                            print(string.format("Corrected triangle count: %d valid triangles (skipped %d with invalid indices)", 
                                               validTriangleCount, triangleCount - validTriangleCount))
                        end
                        
                        -- Write all buffered valid triangles
                        for _, tri in ipairs(triangleBuffer) do
                            outputFile:write(tri.region .. "\n")
                            outputFile:write(tri.shader .. "\n")
                            outputFile:write(string.format("%s\t%s\t%s\n", tri.v0, tri.v1, tri.v2))
                        end
                    end
                    
                    -- Finished parsing
                    state = "done"
                end
            end
        end
    end

    -- Write triangle count and buffered triangles if not already written
    -- (handles case where we finish reading all triangles)
    if triangleCount > 0 and not triangleCountWritten then
        outputFile:write(validTriangleCount .. "\n")
        triangleCountWritten = true
        
        if validTriangleCount < triangleCount then
            print(string.format("Corrected triangle count: %d valid triangles (skipped %d with invalid indices)", 
                               validTriangleCount, triangleCount - validTriangleCount))
        end
        
        -- Write all buffered valid triangles
        for _, tri in ipairs(triangleBuffer) do
            outputFile:write(tri.region .. "\n")
            outputFile:write(tri.shader .. "\n")
            outputFile:write(string.format("%s\t%s\t%s\n", tri.v0, tri.v1, tri.v2))
        end
    end

    inputFile:close()
    outputFile:close()

    return true, "Conversion successful"
end

-- Main execution
local function main(args)
    if #args < 2 then
        print("Error: Not enough arguments")
        print("Usage: luajit jmsFormatterJIT.lua <input_file> <output_file>")
        return 1
    end

    local inputPath = args[1]
    local outputPath = args[2]

    local success, message = convertJMS(inputPath, outputPath)

    if success then
        print("SUCCESS: " .. message)
        return 0
    else
        print("ERROR: " .. message)
        return 1
    end
end

-- Execute main function
local result = main(arg)
os.exit(result)
