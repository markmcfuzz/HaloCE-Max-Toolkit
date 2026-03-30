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

-- constants.ms
-- Fallback node definitions for retail Halo CE tags whose model_animations
-- file contains 0 nodes (older engine builds omitted the node block).
-- Ported from reclaimer/animation/constants.py (MEK project).
--
-- Key lookup: getAntrFallbackNodes nodeCount checksum
--   Returns #( #(name, firstChildIdx, nextSiblingIdx), ... ) or undefined.

fn getAntrFallbackNodes nodeCount checksum =
(
    local result = undefined

    -- vehicles\warthog
    if nodeCount == 18 and checksum == -114204588 then result = #(
        #("frame hull",                   1,  -1),
        #("frame gun mount base",         7,   6),
        #("frame left back suspension",   9,  -1),
        #("frame left front suspension",  10,  4),
        #("frame right back suspension",  11,  2),
        #("frame right front suspension", 12,  3),
        #("frame steering wheel",         -1,  5),
        #("frame chain",                  -1,  8),
        #("frame gun",                    13, -1),
        #("frame left back engine",       14, -1),
        #("frame left front engine",      15, -1),
        #("frame right back engine",      16, -1),
        #("frame right front engine",     17, -1),
        #("frame barrels",                -1, -1),
        #("frame left back tire",         -1, -1),
        #("frame left front tire",        -1, -1),
        #("frame right back tire",        -1, -1),
        #("frame right front tire",       -1, -1)
    )

    -- vehicles\ghost
    else if nodeCount == 5 and checksum == -1063303411 then result = #(
        #("frame hull",       4, -1),
        #("frame guns",      -1, -1),
        #("frame left flap", -1,  1),
        #("frame right flap",-1,  2),
        #("frame seat",      -1,  3)
    )

    -- digsite\weapons\plasma_rifle\01_gs\fp
    else if nodeCount == 42 and checksum == 1525243607 then result = #(
        #("frame bone24",        2, -1),
        #("frame l upperarm",    3, -1),
        #("frame r upperarm",    4,  1),
        #("frame l forearm",     5, -1),
        #("frame r forearm",     6, -1),
        #("frame l wriste",     12, -1),
        #("frame r wriste",      7, -1),
        #("frame gun",          29, 15),
        #("frame l index low",  18, -1),
        #("frame l middlelow",  19,  8),
        #("frame l pinky low",  20, 11),
        #("frame l ring low",   21,  9),
        #("frame l thumb low",  22, 10),
        #("frame r index low",  23, 17),
        #("frame r middle low", 24, 13),
        #("frame r pinky low",  25, 16),
        #("frame r ring low",   26, 14),
        #("frame r thumb low",  27, -1),
        #("frame l index mid",  30, -1),
        #("frame l middle mid", 31, -1),
        #("frame l pinky mid",  32, -1),
        #("frame l ring mid",   33, -1),
        #("frame l thumb mid",  34, -1),
        #("frame r index mid",  35, -1),
        #("frame r middle mid", 36, -1),
        #("frame r pinky mid",  37, -1),
        #("frame r ring mid",   38, -1),
        #("frame r thumb mid",  39, -1),
        #("frame rod_left",     40, -1),
        #("frame rod_right",    41, 28),
        #("frame l index tip",  -1, -1),
        #("frame l middle tip", -1, -1),
        #("frame l pinky tip",  -1, -1),
        #("frame l ring tip",   -1, -1),
        #("frame l thumb tip",  -1, -1),
        #("frame r index tip",  -1, -1),
        #("frame r middle tip", -1, -1),
        #("frame r pinky tip",  -1, -1),
        #("frame r ring tip",   -1, -1),
        #("frame r thumb tip",  -1, -1),
        #("frame wing_left",    -1, -1),
        #("frame wing_right",   -1, -1)
    )

    -- characters\engineer\engineer
    else if nodeCount == 25 and checksum == -256390784 then result = #(
        #("frame root",            7, -1),
        #("frame ltop uparm",     11,  3),
        #("frame neck",            9,  6),
        #("frame rtop uparm",     13,  2),
        #("frame sack01",         -1,  5),
        #("frame sack02",         -1,  1),
        #("frame sack03",         -1, -1),
        #("frame sack06",         -1,  8),
        #("frame tail01",         14,  4),
        #("frame head",           -1, -1),
        #("frame lbottom uparm",  19, 16),
        #("frame ltop forarm",    20, -1),
        #("frame rbottom uparm",  21, 10),
        #("frame rtop forarm",    22, -1),
        #("frame sack04",         17, 15),
        #("frame sack05",         18, 12),
        #("frame tail02",         -1, -1),
        #("frame box01",          -1, -1),
        #("frame box02",          -1, -1),
        #("frame lbottom forarm", 23, -1),
        #("frame ltop hand",      -1, -1),
        #("frame rbottom foarm",  24, -1),
        #("frame rtop hand",      -1, -1),
        #("frame lbottom hand",   -1, -1),
        #("frame rbottom hand",   -1, -1)
    )

    -- levels\a10\devices\doors\door airlock
    else if nodeCount == 4 and checksum == -921384993 then result = #(
        #("frame door airlock", 2, -1),
        #("frame in bottom",   -1, -1),
        #("frame in top",      -1,  3),
        #("frame top",         -1,  1)
    )

    -- levels\a10\devices\doors\door cryo chamber
    else if nodeCount == 3 and checksum == -2130918511 then result = #(
        #("frame door cryo",    1, -1),
        #("frame door cryo l", -1,  2),
        #("frame door cryo r", -1, -1)
    )

    -- levels\a10\devices\doors\door jeff tube
    else if nodeCount == 3 and checksum == 303126628 then result = #(
        #("frame door jeff tube", 2, -1),
        #("frame door l",        -1, -1),
        #("frame door r",        -1,  1)
    )

    -- levels\a10\devices\doors\door small / door small no glass
    else if nodeCount == 3 and checksum == -1054070559 then result = #(
        #("frame door small", 2, -1),
        #("frame in bottom", -1, -1),
        #("frame in top",    -1,  1)
    )

    -- levels\a30\devices\beam emitter + test\infinity beam emitter red
    else if nodeCount == 2 and checksum == -1073502840 then result = #(
        #("frame root",  1, -1),
        #("frame beam", -1, -1)
    )

    -- levels\a30\devices\torpedo_bridge
    else if nodeCount == 9 and checksum == 893764757 then result = #(
        #("frame root",           1, -1),
        #("frame bridgeaback",    5,  2),
        #("frame bridgeafront",   6,  3),
        #("frame bridgebback",    7,  4),
        #("frame bridgebfront",   8, -1),
        #("frame emitteraback",  -1, -1),
        #("frame emitterafront", -1, -1),
        #("frame emitterbback",  -1, -1),
        #("frame emitterbfront", -1, -1)
    )

    -- levels\a50\devices\mustering_door
    else if nodeCount == 3 and checksum == 16992281 then result = #(
        #("frame door root",   1, -1),
        #("frame left door",  -1,  2),
        #("frame right door", -1, -1)
    )

    -- levels\b30\devices\holo control equipment
    else if nodeCount == 5 and checksum == -1411630910 then result = #(
        #("frame root",             2, -1),
        #("frame holo circle bot", -1,  3),
        #("frame holo circle top", -1,  1),
        #("frame holo equip bot",  -1,  4),
        #("frame holo equip top",  -1, -1)
    )

    -- levels\b30\devices\holo control room display
    else if nodeCount == 21 and checksum == -1377126976 then result = #(
        #("frame root",            1, -1),
        #("frame hologramb30",     5, -1),
        #("frame big marker01",   -1, -1),
        #("frame big marker02",   -1,  2),
        #("frame big marker03",   -1,  3),
        #("frame sentinel01",     -1, 20),
        #("frame small marker01", -1,  4),
        #("frame small marker02", -1,  6),
        #("frame small marker03", -1,  7),
        #("frame small marker04", -1,  8),
        #("frame small marker05", -1,  9),
        #("frame small marker06", -1, 10),
        #("frame small marker07", -1, 11),
        #("frame small marker08", -1, 12),
        #("frame small marker09", -1, 13),
        #("frame small marker10", -1, 14),
        #("frame small marker11", -1, 15),
        #("frame small marker12", -1, 16),
        #("frame small marker13", -1, 17),
        #("frame small marker14", -1, 18),
        #("frame small marker15", -1, 19)
    )

    -- levels\b30\devices\holo panel
    else if nodeCount == 2 and checksum == 265626 then result = #(
        #("frame root",   1, -1),
        #("frame rotor", -1, -1)
    )

    -- levels\c10\devices\bridge
    else if nodeCount == 5 and checksum == -802003263 then result = #(
        #("frame root",      2, -1),
        #("framen_big01",    3, -1),
        #("frames_big01",    4,  1),
        #("framen_small01", -1, -1),
        #("frames_small01", -1, -1)
    )

    -- levels\c20\devices\door_large
    else if nodeCount == 3 and checksum == 743432 then result = #(
        #("frame root",    2, -1),
        #("frame door l", -1, -1),
        #("frame door r", -1,  1)
    )

    -- levels\c20\devices\holo control
    else if nodeCount == 2 and checksum == 1074060612 then result = #(
        #("frame root",    1, -1),
        #("frame rotate", -1, -1)
    )

    -- levels\c20\devices\holo radial control
    else if nodeCount == 8 and checksum == 1141351629 then result = #(
        #("frame root",      4, -1),
        #("frame rotate01", -1, -1),
        #("frame rotate02", -1,  1),
        #("frame rotate03", -1,  2),
        #("frame rotate04", -1,  5),
        #("frame rotate05", -1,  6),
        #("frame rotate06", -1,  7),
        #("frame rotate07", -1,  3)
    )

    -- levels\c20\devices\holo tri control
    else if nodeCount == 6 and checksum == 16583471 then result = #(
        #("frame root",      1, -1),
        #("frame rotate01", -1,  5),
        #("frame rotate02", -1, -1),
        #("frame rotate03", -1,  2),
        #("frame rotate04", -1,  3),
        #("frame rotate05", -1,  4)
    )

    -- scenery\lightning
    else if nodeCount == 8 and checksum == 830878205 then result = #(
        #("frame root",        3, -1),
        #("frame link01",      4,  2),
        #("frame link05",      5, -1),
        #("frame link06",     -1,  1),
        #("frame link02",      7, -1),
        #("frame link04",      6, -1),
        #("frame link end",   -1, -1),
        #("frame link end01", -1, -1)
    )

    -- c10_bigplant / plant_broadleaf_short
    else if nodeCount == 3 and checksum == 1074195833 then result = #(
        #("frame base", 1, -1),
        #("frame mid",  2, -1),
        #("frame end", -1, -1)
    )

    -- scenery\plants\plant_broadleaf_tall
    else if nodeCount == 7 and checksum == -1033375598 then result = #(
        #("frame trunk",        2, -1),
        #("frame brancha",      4,  3),
        #("frame branchb",      5,  1),
        #("frame branchc",      6, -1),
        #("frame brancha end", -1, -1),
        #("frame branchb end", -1, -1),
        #("frame branchc end", -1, -1)
    )

    -- scenery\trees\tree_leafy_doublewide
    else if nodeCount == 4 and checksum == -1849496914 then result = #(
        #("frame tree root",     1, -1),
        #("frame tree mid",      2, -1),
        #("frame tree top",      3, -1),
        #("frame tree top end", -1, -1)
    )

    -- scenery\trees\tree_leafy_medium
    else if nodeCount == 3 and checksum == 1089048985 then result = #(
        #("frame tree root",    1, -1),
        #("frame tree mid",     2, -1),
        #("frame tree topend", -1, -1)
    )

    -- scenery\trees\tree_pine
    else if nodeCount == 2 and checksum == -2147257918 then result = #(
        #("frame root", 1, -1),
        #("frame mid", -1, -1)
    )

    -- scenery\trees\tree_pine_snow / tree_pine_tall
    else if nodeCount == 4 and checksum == -804395985 then result = #(
        #("frame root", 1, -1),
        #("frame mid",  2, -1),
        #("frame top",  3, -1),
        #("frame end", -1, -1)
    )

    result
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)

