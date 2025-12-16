-------------------------------------------------------
-- AUTOMATIC MODEL/GBXMODEL IMPORTER
-- Detects tag type and uses appropriate importer
-------------------------------------------------------

-------------------------------------------------------
-- Detect Tag Type
-------------------------------------------------------

fn detectTagType filePath =
(
    local f = fopen filePath "rb"
    if f == undefined then
    (
        messageBox ("Failed to open file: " + filePath) title:"Error"
        return undefined
    )
    
    -- Seek to tag class at offset 36
    fseek f 36 #seek_set
    
    -- Read tag class (4 bytes)
    local tagClass = ""
    for i = 1 to 4 do
    (
        local byte = readByte f #unsigned
        if byte != undefined then
            tagClass += bit.intAsChar byte
    )
    
    fclose f
    
    return tagClass
)

-------------------------------------------------------
-- Main Import Function
-------------------------------------------------------

fn importModelAuto filePath =
(
    --format "\n=== AUTO MODEL IMPORTER ===\n"
    --format "File: %\n\n" (filenameFromPath filePath)
    
    -- Detect tag type
    local tagType = detectTagType filePath
    
    if tagType == undefined then
    (
        return false
    )
    
    --format "Detected tag type: '%'\n\n" tagType
    
    -- Route to appropriate importer
    if tagType == "mod2" then
    (
        --format "Using GBXMODEL importer...\n\n"
        local importerPath = getFilenamePath (getThisScriptFilename()) + "import_gbxmodel.ms"
        filein importerPath
        ImportGbxmodelGeometry modelFile:filePath
    )
    else if tagType == "mode" then
    (
        --format "Using MODEL importer...\n\n"
        local importerPath = getFilenamePath (getThisScriptFilename()) + "import_model.ms"
        filein importerPath
        ImportModelGeometry modelFile:filePath
    )
    else
    (
        messageBox ("Unsupported tag type: '" + tagType + "'\nSupported types: mod2 (gbxmodel), mode (model)") title:"Error"
        return false
    )
    
    return true
)

-------------------------------------------------------
-- User Interface
-------------------------------------------------------

fn showImportDialog =
(
    local filePath = getOpenFileName \
        caption:"Select Model or Gbxmodel Tag" \
        types:"Halo Model Tags (*.model;*.gbxmodel)|*.model;*.gbxmodel|All Files (*.*)|*.*"
    
    if filePath != undefined then
    (
        importModelAuto filePath
    )
)

-- Show the dialog
showImportDialog()

--format "\n=== Auto Model Importer Ready ===\n"
--format "Run 'showImportDialog()' to import a model or gbxmodel tag\n\n"
