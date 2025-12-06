#!/usr/bin/env luajit

--[[
Simple MZP Package Creator for HaloCE Max Toolkit
Creates .mzp packages for 3ds Max from manifest.json

This version uses only built-in Lua capabilities + PowerShell for maximum compatibility.

Usage: luajit simple_mzp.lua
]] -- Simple JSON parser (subset for our needs)
local function parse_json_simple(json_str)
    local result = {}

    -- Remove whitespace and braces
    json_str = json_str:gsub("^%s*{%s*", ""):gsub("%s*}%s*$", "")

    -- Parse each key-value pair
    for line in json_str:gmatch("[^\r\n]+") do
        local key, value = line:match("\"([^\"]+)\"%s*:%s*\"([^\"]+)\"")
        if key and value then
            result[key] = value
        end
    end

    return result
end

-- Helper functions
local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function read_file(path)
    local file = io.open(path, "r")
    if not file then
        error("Could not open file: " .. path)
    end
    local content = file:read("*all")
    file:close()
    return content
end

local function get_script_directory()
    local script_path = arg[0]
    local dir = script_path:match("^(.*[/\\])")
    return dir or "./"
end

local function create_mzp_package()
    print("HaloCE Max Toolkit - Simple MZP Creator")
    print("=====================================")

    local script_dir = get_script_directory()
    -- manifest.json is in the same directory (build/)
    local manifest_path = script_dir .. "manifest.json"
    -- But source directory is in parent
    local parent_dir = script_dir .. "../"

    -- Check if manifest.json exists
    if not file_exists(manifest_path) then
        error("manifest.json not found at: " .. manifest_path)
    end

    -- Read and parse manifest.json
    print("Reading manifest.json...")
    local manifest_content = read_file(manifest_path)
    local manifest = parse_json_simple(manifest_content)

    -- Validate required fields
    if not manifest.packageVersion then
        error("packageVersion not found in manifest.json")
    end
    if not manifest.fileName then
        error("fileName not found in manifest.json")
    end
    if not manifest.filesAndFoldersToCompress then
        error("filesAndFoldersToCompress not found in manifest.json")
    end

    -- Build paths
    local source_dir = parent_dir .. manifest.filesAndFoldersToCompress
    local output_name = manifest.fileName .. manifest.packageVersion
    local zip_path = parent_dir .. output_name .. ".zip"
    local mzp_path = parent_dir .. output_name .. ".mzp"

    print("Package version: " .. manifest.packageVersion)
    print("Source directory: " .. source_dir)
    print("Output file: " .. output_name .. ".mzp")
    print("")

    -- Convert paths to Windows format
    source_dir = source_dir:gsub("/", "\\")
    zip_path = zip_path:gsub("/", "\\")
    mzp_path = mzp_path:gsub("/", "\\")

    -- Remove existing files
    if file_exists(zip_path) then
        os.remove(zip_path)
        print("Removed existing ZIP file")
    end
    if file_exists(mzp_path) then
        os.remove(mzp_path)
        print("Removed existing MZP file")
    end

    -- Create PowerShell script for ZIP creation
    local ps_script = string.format([[
$ErrorActionPreference = "Stop"
$source = '%s'
$destination = '%s'

if (!(Test-Path $source)) {
    Write-Error "Source directory not found: $source"
    exit 1
}

if (Test-Path $destination) { 
    Remove-Item $destination -Force
}

try {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    
    # Get absolute path and normalize
    $source = (Resolve-Path $source).Path.TrimEnd('\')
    
    # Create the ZIP archive
    $archive = [System.IO.Compression.ZipFile]::Open($destination, [System.IO.Compression.ZipArchiveMode]::Create)
    
    try {
        # Get all files recursively, excluding .7z files
        $files = Get-ChildItem -Path $source -Recurse -File | Where-Object { $_.Extension -ne '.7z' }
        
        foreach ($file in $files) {
            # Calculate relative path from source directory
            $relativePath = $file.FullName.Substring($source.Length).TrimStart('\')
            $entry = $archive.CreateEntry($relativePath)
            $entryStream = $entry.Open()
            try {
                $fileStream = [System.IO.File]::OpenRead($file.FullName)
                try {
                    $fileStream.CopyTo($entryStream)
                } finally {
                    $fileStream.Close()
                }
            } finally {
                $entryStream.Close()
            }
        }
    } finally {
        $archive.Dispose()
    }
    
    if (Test-Path $destination) {
        Write-Host "ZIP created successfully!"
        exit 0
    } else {
        Write-Error "ZIP file was not created"
        exit 1
    }
} catch {
    Write-Error "Failed to create ZIP: $($_.Exception.Message)"
    exit 1
}
]], source_dir, zip_path)

    -- Write PowerShell script to temp file
    local temp_ps = os.tmpname() .. ".ps1"
    local ps_file = io.open(temp_ps, "w")
    if not ps_file then
        error("Could not create temporary PowerShell script")
    end
    ps_file:write(ps_script)
    ps_file:close()

    print("Creating ZIP file...")

    -- Execute PowerShell script
    local cmd = string.format("powershell.exe -ExecutionPolicy Bypass -File \"%s\"", temp_ps)
    os.execute(cmd)

    -- Clean up temp file
    os.remove(temp_ps)

    -- Verify ZIP was created (more reliable than exit code)
    if not file_exists(zip_path) then
        error("ZIP file was not created: " .. zip_path)
    end

    print("ZIP file created successfully!")

    -- Rename .zip to .mzp using PowerShell
    print("Renaming to .mzp extension...")
    local rename_cmd = string.format("powershell.exe -Command \"Rename-Item -Path '%s' -NewName '%s'\"", 
                                     zip_path:gsub("\\", "/"), 
                                     (output_name .. ".mzp"))
    os.execute(rename_cmd)

    -- Verify final MZP file exists (more reliable than exit code)
    if not file_exists(mzp_path) then
        error("MZP file was not created: " .. mzp_path)
    end

    print("Successfully renamed to .mzp!")

    -- Get file size for final report
    local size_kb = "Unknown"
    local size_handle = io.popen(string.format("powershell.exe -Command \"(Get-Item '%s').Length\"",
                                               mzp_path))

    if size_handle then
        local size_str = size_handle:read("*a")
        size_handle:close()
        if size_str then
            local size_bytes = tonumber(size_str:match("%d+"))
            if size_bytes then
                size_kb = tostring(math.floor(size_bytes / 1024 * 100) / 100)
            end
        end
    end

    print("")
    print("SUCCESS!")
    print("Created: " .. output_name .. ".mzp")
    print("Size: " .. size_kb .. " KB")
    print("Location: " .. mzp_path)
    print("")
    print("Ready to install in 3ds Max!")
    print("Just double-click the .mzp file or use 3ds Max's plugin installer")

    return true
end

-- Main execution with error handling
local function main()
    local success, err = pcall(create_mzp_package)
    if not success then
        print("")
        print("ERROR: " .. err)
        print("")
        print("Requirements:")
        print("- LuaJIT installed and in PATH")
        print("- PowerShell available (Windows)")
        print("- manifest.json in the same directory")
        print("- src/ folder with toolkit files")
        print("")
        print("Make sure you're running this from the HaloCE-Max-Toolkit root directory.")
        os.exit(1)
    end
end

main()
