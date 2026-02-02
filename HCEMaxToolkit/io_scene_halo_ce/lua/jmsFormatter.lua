-- JMS Format Converter (LuaJIT Compatible)
-- Converts old JMS format (single-line) to new JMS format (multi-line)
-- Author: HaloCE Max Toolkit
-- Purpose: Convert legacy JMS files to be compatible with modern importer
-- Compatible with: LuaJIT 2.0+ and Lua 5.1+

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
                    outputFile:write(vertexCount .. "\n")
                    state = "vertices"
                end

                -- Parse vertices
            elseif state == "vertices" then
                if verticesProcessed < vertexCount then
                    local parts = split(line, "\t")
                    -- Format: node0 x y z nx ny nz node1 weight u v w
                    if #parts >= 12 then
                        outputFile:write(parts[1] .. "\n") -- node0_index
                        -- Position (x y z)
                        outputFile:write(string.format("%f\t%f\t%f\n", tonumber(parts[2]),
                                                       tonumber(parts[3]), tonumber(parts[4])))
                        -- Normal (i j k)
                        outputFile:write(string.format("%f\t%f\t%f\t\n", tonumber(parts[5]),
                                                       tonumber(parts[6]), tonumber(parts[7])))
                        outputFile:write(parts[8] .. "\n") -- node1_index
                        outputFile:write(string.format("%f\n", tonumber(parts[9]))) -- node1_weight
                        -- Texture UV (u v w)
                        outputFile:write(string.format("%f\n", tonumber(parts[10])))
                        outputFile:write(string.format("%f\n", tonumber(parts[11])))
                        outputFile:write(parts[12] .. "\n") -- w (integer)
                        verticesProcessed = verticesProcessed + 1
                    end
                else
                    -- Next line should be triangle count
                    triangleCount = tonumber(line)
                    if not triangleCount then
                        inputFile:close()
                        outputFile:close()
                        return false, "Invalid triangle count at line " .. lineNum .. ": '" .. line .. "'"
                    end
                    outputFile:write(triangleCount .. "\n")
                    state = "triangles"
                end

                -- Parse triangles
            elseif state == "triangles" then
                if trianglesProcessed < triangleCount then
                    local parts = split(line, "\t")
                    -- Format: region shader v0 v1 v2
                    if #parts >= 5 then
                        -- Replace "undefined" with "0" for region index
                        local regionIndex = parts[1]
                        if regionIndex:lower() == "undefined" then
                            regionIndex = "0"
                        end
                        outputFile:write(regionIndex .. "\n") -- face_region_index
                        outputFile:write(parts[2] .. "\n") -- face_shader_index
                        -- Vertex indices
                        outputFile:write(string.format("%s\t%s\t%s\n", parts[3], parts[4], parts[5]))
                        trianglesProcessed = trianglesProcessed + 1
                    end
                else
                    -- Finished parsing
                    state = "done"
                end
            end
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
