-------------------------------------------------------
-- COMPRESSED VERTEX DECOMPRESSION
-------------------------------------------------------

-- Decompress normal vector from packed 32-bit format | Fixed
fn decompressNormal normalPacked =
(
    local i = (bit.and normalPacked 1023) / 1023.0
    local j = (bit.and (bit.shift normalPacked -11) 1023) / 1023.0
    local k = (bit.and (bit.shift normalPacked -22) 511) / 511.0

    if (bit.and normalPacked (bit.shift 1 10)) != 0 do i -= 1.0
    if (bit.and normalPacked (bit.shift 1 21)) != 0 do j -= 1.0
    if (bit.and normalPacked (bit.shift 1 31)) != 0 do k -= 1.0

    normalize [i, j, k]
)

-- Decompress UV coordinates from signed 16-bit format
fn decompressUV u16 v16 uScale:1.0 vScale:1.0 =
(
    local u = (u16 / 32767.0) * uScale
    local v_coord = (1.0 - (v16 / 32767.0)) * vScale
    return [u, v_coord, 0]
)

-- Decompress node indices (stored * 3 in compressed format)
fn decompressNodeIndices node0Raw node1Raw =
(
    local node0Index = (node0Raw / 3) + 1  -- Convert to 1-based
    local node1Index = (node1Raw / 3) + 1  -- Convert to 1-based
    return #(node0Index, node1Index)
)

-- Decompress node weight from signed 16-bit to float (0.0-1.0)
fn decompressNodeWeight weightRaw =
(
    local weight = weightRaw / 32767.0
    return weight
)

-------------------------------------------------------
-- Object detection functions
-------------------------------------------------------

-- Check if object name indicates it should be exported as a node
fn isNodeObject obj =
(
	if obj == undefined then return false
	
	local objName = toLower obj.name
	
	-- Check for node prefixes: 'b', 'b_', 'bone', 'frame', 'bip01'
	local hasPrefix = (matchPattern objName pattern:"b *") or \
                        (matchPattern objName pattern:"b_*") or \
                        (matchPattern objName pattern:"bone*") or \
                        (matchPattern objName pattern:"frame*") or \
                        (matchPattern objName pattern:"bip01*")
	
	return hasPrefix
)

-- Check if object is a marker (names starting with '#' or '+')
fn isMarkerObject obj =
(
	if obj == undefined then return false
	return (obj.name[1] == "#" or obj.name[1] == "+")
)

-- Check if object is a physics/pathfinding object (names starting with '+')
fn isPhysicsObject obj =
(
	if obj == undefined then return false
	return (obj.name[1] == "+")
)

-- Check if object is geometry (Editable Mesh or Editable Poly)
fn isGeometryObject obj =
(
	if obj == undefined then return false
	
	local objClass = classOf obj
	
	-- Check direct class
	if objClass == Editable_mesh or objClass == Editable_Poly then
		return true
	
	-- Check base object (for objects with modifiers)
	if obj.baseObject != undefined then
	(
		local baseClass = classOf obj.baseObject
		if baseClass == Editable_mesh or baseClass == Editable_Poly then
			return true
	)
	
	return false
)

-- Get the Skin modifier from an object if it exists
fn getSkinModifier obj =
(
	for i = 1 to obj.modifiers.count do
	(
		if classOf obj.modifiers[i] == Skin then
			return obj.modifiers[i]
	)
	return undefined
)

------------------------------------------------------------
-- Helper functions to create Halo objects
------------------------------------------------------------

-- Create a standard Marker helper (uses HaloMarker/Point)
fn createHaloMarker pos:[0,0,0] radius:1.0 name:"marker" wireColor:(color 0 255 0) =
(
	local marker = HaloMarker pos:pos
	marker.markerRadius = radius
	marker.markerType = "Marker"
	marker.markerColor = wireColor
	marker.wirecolor = wireColor
	
	-- Set name with "#" prefix
	if name != "" then
	(
		if name[1] != "#" and name[1] != "+" then
			marker.name = "#" + name
		else
			marker.name = name
	)
	
	marker
)

-- Create a Physics or Pathfinding helper (uses HaloPhysics/InfluenceHelper)
--
fn createHaloPhysics pos:[0,0,0] radius:1.0 markerType:"Physics" name:"massPoint" wireColor:(color 0 200 0) nearColor:(color 0 200 0) farColor:(color 0 200 0) =
(
	local marker = HaloPhysics pos:pos
	marker.physicsRadius = radius
	marker.markerType = markerType
	marker.wirecolor = wireColor
	
	-- Set colors on the delegate (InfluenceHelper)
	marker.delegate.nearColor = nearColor
	marker.delegate.farColor = farColor
	
	-- Set name with "+" prefix
	if name != "" then
	(
		if name[1] != "#" and name[1] != "+" then
			marker.name = "+" + name
		else
			marker.name = name
	)
	marker
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)