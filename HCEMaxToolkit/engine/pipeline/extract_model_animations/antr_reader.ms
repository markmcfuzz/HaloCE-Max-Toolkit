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

-------------------------------------------------------
-- DIRECT BINARY READER FOR model_animations (.antr) TAGS
--
-- Bypasses the generic parser entirely.  Reads ONLY the nodes and
-- animations blocks needed by the extractor, seeking over everything
-- else with fseek.
--
-- CE tag files use BIG-ENDIAN byte order in their structured fields.
-- The raw frameInfo / defaultData / frameData blobs (read later by
-- animation_extractor.ms) are also big-endian, so all reads here
-- use read.longB / read.shortB / read.floatB.
--
-- Tag binary layout (file offsets):
--   [0   .. 63 ] : BLAM header (skipped by caller before open)
--   [64  .. 191] : tagdata (128 bytes) – 8 reflexive headers + misc fields
--   [192 ..     ] : block data, in this order:
--     objects entries        (20 bytes each)
--     units entries          (100 bytes each + nested sub-blocks)
--     weapons entries        (188 bytes each + nested sub-blocks)
--     vehicles entries       (116 bytes each + nested sub-blocks)
--     devices entries        (96 bytes each + nested sub-blocks)
--     unitDamage entries     (2 bytes each)
--     firstPersonWeapons entries (28 bytes each + nested animations)
--     soundReferences entries    (20 bytes each)
--     soundReferences paths      (null-terminated strings)
--     nodes entries          (64 bytes each)  ← we read these
--     animations entries     (180 bytes each) ← we read these
--     [raw animation data begins here]
-------------------------------------------------------

-- Typed result structs (replace parser tuple-arrays with named fields)
struct AntrNode (
    name,
    nextSiblingNodeIndex,
    firstChildNodeIndex
)

struct AntrAnimation (
    name,
    type,
    frameCount,
    frameInfoType,
    nodeListChecksum,
    nodeCount,
    flags,
    nodeTransFlagData,  -- #(int32, int32)
    nodeRotFlagData,    -- #(int32, int32)
    nodeScaleFlagData,  -- #(int32, int32)
    frameInfoSize,      -- raw data blob sizes (for offset pre-computation)
    defaultDataSize,
    frameDataSize
)

-------------------------------------------------------
-- INTERNAL HELPERS
-------------------------------------------------------

-- Read a 32-byte null-terminated inline string (big-endian tag format).
fn _readString32 f =
(
    local str = ""
    local finished = false
    for i = 1 to 32 do
    (
        local b = readByte f #unsigned
        if b == undefined then ( finished = true; exit )
        if b == 0 then ( finished = true )
        if not finished then str += (bit.intAsChar b)
    )
    -- consumed 32 bytes; build string from non-null chars collected before first null
    -- (no re-seek needed – loop always reads all 32)
    str
)

-- Read big-endian int32 unsigned
fn _readU32 f =
(
    local b1 = readByte f #unsigned
    local b2 = readByte f #unsigned
    local b3 = readByte f #unsigned
    local b4 = readByte f #unsigned
    b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
)

-- Read big-endian int32 signed
fn _readS32 f =
(
    local v = _readU32 f
    if v > 2147483648 then v - 4294967296 else v
)

-- Read big-endian int16 signed
fn _readS16 f =
(
    local b1 = readByte f #unsigned
    local b2 = readByte f #unsigned
    local v = b1 * 256 + b2
    if v > 32768 then v - 65536 else v
)

-- Read big-endian int16 unsigned
fn _readU16 f =
(
    local b1 = readByte f #unsigned
    local b2 = readByte f #unsigned
    b1 * 256 + b2
)

-- Skip N bytes forward
fn _skip f n =
(
    if n > 0 do fseek f n #seek_cur
)

-------------------------------------------------------
-- PRE-NODES BLOCK SKIPPPER
--
-- Seeks past all block data that precedes the nodes block.
-- Handles nested sub-block counts by reading them from the file
-- (so no hard-coded assumptions about sub-counts).
-------------------------------------------------------

-- Skip a simple flat block: count × entryBytes, no nested data.
fn _skipFlat f count entryBytes =
(
    _skip f (count * entryBytes)
)

-- Skip units block.
-- Units entry (100 bytes) contains three reflexive headers:
--   animations at entry+64  (sub-entries: 2 bytes each)
--   ikPoints   at entry+76  (sub-entries: 64 bytes each)
--   weapons    at entry+88  (sub-entries: 188 bytes each + own nested)
-- weapons sub-entry (188 bytes) contains three reflexive headers:
--   animations    at weapons_entry+152  (2 bytes each)
--   ikPoints      at weapons_entry+164  (64 bytes each)
--   weaponTypes   at weapons_entry+176  (60 bytes each + own nested)
-- weaponTypes sub-entry (60 bytes) contains one reflexive header:
--   animations    at weaponTypes_entry+48  (2 bytes each)
--
-- IMPORTANT: CE tag files store ALL entries at a level contiguously first,
-- then the sub-block data for each entry follows in order.  So with N units,
-- all N×100 byte entries appear before any sub-block data.  A two-pass
-- approach (collect counts from all entries, then process sub-data) is required.
fn _skipUnits f count =
(
    -- Pass 1: read all unit entries' fixed data, collect nested sub-block counts
    local unitAnimCounts = #()
    local unitIkCounts   = #()
    local unitWpCounts   = #()
    for i = 1 to count do
    (
        local entryStart = ftell f
        fseek f (entryStart + 64) #seek_set; append unitAnimCounts (_readU32 f)
        fseek f (entryStart + 76) #seek_set; append unitIkCounts   (_readU32 f)
        fseek f (entryStart + 88) #seek_set; append unitWpCounts   (_readU32 f)
        fseek f (entryStart + 100) #seek_set
    )
    -- Pass 2: for each unit, skip its sub-block data in order
    for i = 1 to count do
    (
        local animCount = unitAnimCounts[i]
        local ikCount   = unitIkCounts[i]
        local wpCount   = unitWpCounts[i]
        _skip f (animCount * 2)
        _skip f (ikCount   * 64)
        -- Weapons: pass 1 — read all weapon entries, collect their sub-block counts
        local wpAnimCounts = #()
        local wpIkCounts   = #()
        local wpTypeCounts = #()
        for w = 1 to wpCount do
        (
            local wpStart = ftell f
            fseek f (wpStart + 152) #seek_set; append wpAnimCounts (_readU32 f)
            fseek f (wpStart + 164) #seek_set; append wpIkCounts   (_readU32 f)
            fseek f (wpStart + 176) #seek_set; append wpTypeCounts (_readU32 f)
            fseek f (wpStart + 188) #seek_set
        )
        -- Weapons: pass 2 — skip sub-data for each weapon
        for w = 1 to wpCount do
        (
            _skip f (wpAnimCounts[w] * 2)
            _skip f (wpIkCounts[w]   * 64)
            -- WeaponTypes: pass 1 — read all weaponType entries
            local wtCount = wpTypeCounts[w]
            local wtAnimCounts = #()
            for t = 1 to wtCount do
            (
                local wtStart = ftell f
                fseek f (wtStart + 48) #seek_set; append wtAnimCounts (_readU32 f)
                fseek f (wtStart + 60) #seek_set
            )
            -- WeaponTypes: pass 2 — skip animations for each weaponType
            for t = 1 to wtCount do
                _skip f (wtAnimCounts[t] * 2)
        )
    )
)

-- Skip top-level weapons block (modelAnimationsWeaponsBlock).
-- Entry size: 28 bytes — 16 bytes padding + animations reflexive at +16.
-- This is NOT the same as unit.weapons (188 bytes); it is identical in
-- layout to firstPersonWeapons.
fn _skipWeapons f count =
(
    for i = 1 to count do
    (
        local entryStart = ftell f
        fseek f (entryStart + 16) #seek_set; local animCount = _readU32 f
        fseek f (entryStart + 28) #seek_set
        _skip f (animCount * 2)
    )
)

-- Skip vehicles block.
-- Vehicle entry (116 bytes) has two reflexive headers:
--   animations         at entry+92  (2 bytes each)
--   suspensionAnimations at entry+104 (20 bytes each, no nested)
fn _skipVehicles f count =
(
    for i = 1 to count do
    (
        local entryStart = ftell f
        fseek f (entryStart + 92)  #seek_set; local animCount = _readU32 f
        fseek f (entryStart + 104) #seek_set; local suspCount = _readU32 f
        fseek f (entryStart + 116) #seek_set
        _skip f (animCount * 2)
        _skip f (suspCount * 20)
    )
)

-- Skip devices block.
-- Device entry (96 bytes) has one reflexive header:
--   animations at entry+84 (2 bytes each)
fn _skipDevices f count =
(
    for i = 1 to count do
    (
        local entryStart = ftell f
        fseek f (entryStart + 84) #seek_set; local animCount = _readU32 f
        fseek f (entryStart + 96) #seek_set
        _skip f (animCount * 2)
    )
)

-- Skip firstPersonWeapons block.
-- FP entry (28 bytes) has one reflexive header:
--   animations at entry+16 (2 bytes each)
fn _skipFirstPersonWeapons f count =
(
    for i = 1 to count do
    (
        local entryStart = ftell f
        fseek f (entryStart + 16) #seek_set; local animCount = _readU32 f
        fseek f (entryStart + 28) #seek_set
        _skip f (animCount * 2)
    )
)

-- Skip soundReferences block.
-- SoundRef entry (20 bytes): tagRef(16) + padding(4).
-- pathLen is at entry+8 (big-endian int32 signed).
-- Path strings come immediately after all entry fixed-data, as
-- null-terminated strings.  pathLen==0 means empty (no string).
fn _skipSoundReferences f count =
(
    local pathLengths = #()
    for i = 1 to count do
    (
        local entryStart = ftell f
        fseek f (entryStart + 8) #seek_set
        local pathLen = _readS32 f
        append pathLengths pathLen
        fseek f (entryStart + 20) #seek_set
    )
    -- Now skip the null-terminated path strings
    for pathLen in pathLengths do
    (
        if pathLen > 0 do _skip f (pathLen + 1)  -- +1 for null terminator
    )
)

-------------------------------------------------------
-- DIRECT NODE READER
-- Reads `count` node entries; each is 64 bytes.
-- We only need: name(32), nextSiblingNodeIndex(2), firstChildNodeIndex(2).
-------------------------------------------------------

fn _readNodes f count =
(
    local nodes = #()
    for i = 1 to count do
    (
        local entryStart = ftell f
        local name   = _readString32 f                  -- offset 0..31
        local nextSib = _readS16 f                      -- offset 32..33
        local firstChild = _readS16 f                   -- offset 34..35
        fseek f (entryStart + 64) #seek_set             -- skip rest of entry
        append nodes (AntrNode name:name nextSiblingNodeIndex:nextSib firstChildNodeIndex:firstChild)
    )
    nodes
)

-------------------------------------------------------
-- DIRECT ANIMATION READER
-- Reads `count` animation entries; each is 180 bytes.
-- Field offsets (big-endian, within each 180-byte entry):
--   0   : name (32 bytes)
--   32  : type (int16)
--   34  : frameCount (int16)
--   36  : frameSize (int16)  – skip
--   38  : frameInfoType (int16)
--   40  : nodeListChecksum (int32)
--   44  : nodeCount (int16)
--   46..57 : loopFrame, weight, keyFrame, secondKey, nextAnim – skip
--   58  : flags (int16)
--   60..71 : sound, soundFrame, leftFoot, rightFoot, padding, padding – skip
--   72  : frameInfo tagData (size int32 + 16 bytes skip = 20 bytes total)
--   92  : nodeTransFlagData[0] (int32)
--   96  : nodeTransFlagData[1] (int32)
--   100 : padding 8 bytes – skip
--   108 : nodeRotFlagData[0] (int32)
--   112 : nodeRotFlagData[1] (int32)
--   116 : padding 8 bytes – skip
--   124 : nodeScaleFlagData[0] (int32)
--   128 : nodeScaleFlagData[1] (int32)
--   132 : padding 4 bytes – skip
--   136 : offsetToCompressedData (int32) – skip
--   140 : defaultData tagData → size (int32) then skip 16 bytes
--   160 : frameData tagData → size (int32) then skip 16 bytes
--   180 : end of entry
-------------------------------------------------------

fn _readAnimations f count =
(
    local anims = #()
    for i = 1 to count do
    (
        local e = ftell f

        fseek f (e + 0)   #seek_set; local name          = _readString32 f
        fseek f (e + 32)  #seek_set; local aType         = _readS16 f
        fseek f (e + 34)  #seek_set; local frameCount    = _readS16 f
        fseek f (e + 38)  #seek_set; local frameInfoType = _readS16 f
        fseek f (e + 40)  #seek_set; local checksum      = _readS32 f
        fseek f (e + 44)  #seek_set; local nodeCount     = _readS16 f
        fseek f (e + 58)  #seek_set; local flags         = _readU16 f
        fseek f (e + 72)  #seek_set; local fiSize        = _readS32 f
        fseek f (e + 92)  #seek_set; local transFl0      = _readU32 f
        fseek f (e + 96)  #seek_set; local transFl1      = _readU32 f
        fseek f (e + 108) #seek_set; local rotFl0        = _readU32 f
        fseek f (e + 112) #seek_set; local rotFl1        = _readU32 f
        fseek f (e + 124) #seek_set; local sclFl0        = _readU32 f
        fseek f (e + 128) #seek_set; local sclFl1        = _readU32 f
        fseek f (e + 140) #seek_set; local ddSize        = _readS32 f
        fseek f (e + 160) #seek_set; local fdSize        = _readS32 f

        fseek f (e + 180) #seek_set  -- advance to next entry

        append anims (AntrAnimation \
            name:name \
            type:aType \
            frameCount:frameCount \
            frameInfoType:frameInfoType \
            nodeListChecksum:checksum \
            nodeCount:nodeCount \
            flags:flags \
            nodeTransFlagData:#(transFl0, transFl1) \
            nodeRotFlagData:#(rotFl0, rotFl1) \
            nodeScaleFlagData:#(sclFl0, sclFl1) \
            frameInfoSize:fiSize \
            defaultDataSize:ddSize \
            frameDataSize:fdSize)
    )
    anims
)

-------------------------------------------------------
-- PUBLIC ENTRY POINT
-------------------------------------------------------

-- Read nodes and animations from a model_animations tag file.
-- fileHandle must be seekable and positioned ANYWHERE (function uses fseek).
-- Returns #(nodesList, animationsList, rawDataBaseOffset) on success,
-- or undefined on failure.
fn readAntrTagDirect fileHandle =
(
    local f = fileHandle

    -- -----------------------------------------------
    -- Step 1: Read reflexive counts from the tagdata
    -- header at known absolute offsets.
    -- tagdata starts at file offset 64 (after BLAM header).
    -- Reflexive layout: count(4) + pointer(4) + unused(4) = 12 bytes each.
    -- -----------------------------------------------
    local TDBase = 64  -- start of tagdata in file

    fseek f (TDBase + 0)   #seek_set; local cntObjects   = _readU32 f
    fseek f (TDBase + 12)  #seek_set; local cntUnits      = _readU32 f
    fseek f (TDBase + 24)  #seek_set; local cntWeapons    = _readU32 f
    fseek f (TDBase + 36)  #seek_set; local cntVehicles   = _readU32 f
    fseek f (TDBase + 48)  #seek_set; local cntDevices    = _readU32 f
    fseek f (TDBase + 60)  #seek_set; local cntUnitDmg    = _readU32 f
    fseek f (TDBase + 72)  #seek_set; local cntFPWeapons  = _readU32 f
    fseek f (TDBase + 84)  #seek_set; local cntSoundRefs  = _readU32 f
    fseek f (TDBase + 104) #seek_set; local cntNodes      = _readU32 f
    fseek f (TDBase + 116) #seek_set; local cntAnims      = _readU32 f

    -- -----------------------------------------------
    -- Step 2: Seek to block-data start and walk past
    -- all pre-nodes blocks using fast fseek skips.
    -- File pos after tagdata = 64 + 128 = 192.
    -- -----------------------------------------------
    fseek f 192 #seek_set

    _skipFlat            f cntObjects  20
    _skipUnits           f cntUnits
    _skipWeapons         f cntWeapons
    _skipVehicles        f cntVehicles
    _skipDevices         f cntDevices
    _skipFlat            f cntUnitDmg  2
    _skipFirstPersonWeapons f cntFPWeapons
    _skipSoundReferences f cntSoundRefs

    -- -----------------------------------------------
    -- Step 3: Read nodes.
    -- -----------------------------------------------
    local nodesList = _readNodes f cntNodes

    -- -----------------------------------------------
    -- Step 4: Read animations.
    -- -----------------------------------------------
    local animsList = _readAnimations f cntAnims

    -- rawDataBase is exactly where the cursor now sits –
    -- the sequential raw animation blobs start here.
    local rawDataBase = ftell f

    #(nodesList, animsList, rawDataBase)
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
