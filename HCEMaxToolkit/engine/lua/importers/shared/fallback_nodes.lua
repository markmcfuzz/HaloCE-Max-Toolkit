-- Node lists for retail Halo CE model_animations tags that have no nodes block
-- (older builds omitted it). Converted from the toolkit's previous MAXScript table,
-- itself ported from reclaimer/animation/constants.py (MEK project).
-- Each node: { name, first child index, next sibling index }.

local fallback = {
	-- vehicles\warthog
	{ count = 18, checksum = -114204588, nodes = {
		{ "frame hull", 1, -1 },
		{ "frame gun mount base", 7, 6 },
		{ "frame left back suspension", 9, -1 },
		{ "frame left front suspension", 10, 4 },
		{ "frame right back suspension", 11, 2 },
		{ "frame right front suspension", 12, 3 },
		{ "frame steering wheel", -1, 5 },
		{ "frame chain", -1, 8 },
		{ "frame gun", 13, -1 },
		{ "frame left back engine", 14, -1 },
		{ "frame left front engine", 15, -1 },
		{ "frame right back engine", 16, -1 },
		{ "frame right front engine", 17, -1 },
		{ "frame barrels", -1, -1 },
		{ "frame left back tire", -1, -1 },
		{ "frame left front tire", -1, -1 },
		{ "frame right back tire", -1, -1 },
		{ "frame right front tire", -1, -1 },
	} },
	-- vehicles\ghost
	{ count = 5, checksum = -1063303411, nodes = {
		{ "frame hull", 4, -1 },
		{ "frame guns", -1, -1 },
		{ "frame left flap", -1, 1 },
		{ "frame right flap", -1, 2 },
		{ "frame seat", -1, 3 },
	} },
	-- digsite\weapons\plasma_rifle\01_gs\fp
	{ count = 42, checksum = 1525243607, nodes = {
		{ "frame bone24", 2, -1 },
		{ "frame l upperarm", 3, -1 },
		{ "frame r upperarm", 4, 1 },
		{ "frame l forearm", 5, -1 },
		{ "frame r forearm", 6, -1 },
		{ "frame l wriste", 12, -1 },
		{ "frame r wriste", 7, -1 },
		{ "frame gun", 29, 15 },
		{ "frame l index low", 18, -1 },
		{ "frame l middlelow", 19, 8 },
		{ "frame l pinky low", 20, 11 },
		{ "frame l ring low", 21, 9 },
		{ "frame l thumb low", 22, 10 },
		{ "frame r index low", 23, 17 },
		{ "frame r middle low", 24, 13 },
		{ "frame r pinky low", 25, 16 },
		{ "frame r ring low", 26, 14 },
		{ "frame r thumb low", 27, -1 },
		{ "frame l index mid", 30, -1 },
		{ "frame l middle mid", 31, -1 },
		{ "frame l pinky mid", 32, -1 },
		{ "frame l ring mid", 33, -1 },
		{ "frame l thumb mid", 34, -1 },
		{ "frame r index mid", 35, -1 },
		{ "frame r middle mid", 36, -1 },
		{ "frame r pinky mid", 37, -1 },
		{ "frame r ring mid", 38, -1 },
		{ "frame r thumb mid", 39, -1 },
		{ "frame rod_left", 40, -1 },
		{ "frame rod_right", 41, 28 },
		{ "frame l index tip", -1, -1 },
		{ "frame l middle tip", -1, -1 },
		{ "frame l pinky tip", -1, -1 },
		{ "frame l ring tip", -1, -1 },
		{ "frame l thumb tip", -1, -1 },
		{ "frame r index tip", -1, -1 },
		{ "frame r middle tip", -1, -1 },
		{ "frame r pinky tip", -1, -1 },
		{ "frame r ring tip", -1, -1 },
		{ "frame r thumb tip", -1, -1 },
		{ "frame wing_left", -1, -1 },
		{ "frame wing_right", -1, -1 },
	} },
	-- characters\engineer\engineer
	{ count = 25, checksum = -256390784, nodes = {
		{ "frame root", 7, -1 },
		{ "frame ltop uparm", 11, 3 },
		{ "frame neck", 9, 6 },
		{ "frame rtop uparm", 13, 2 },
		{ "frame sack01", -1, 5 },
		{ "frame sack02", -1, 1 },
		{ "frame sack03", -1, -1 },
		{ "frame sack06", -1, 8 },
		{ "frame tail01", 14, 4 },
		{ "frame head", -1, -1 },
		{ "frame lbottom uparm", 19, 16 },
		{ "frame ltop forarm", 20, -1 },
		{ "frame rbottom uparm", 21, 10 },
		{ "frame rtop forarm", 22, -1 },
		{ "frame sack04", 17, 15 },
		{ "frame sack05", 18, 12 },
		{ "frame tail02", -1, -1 },
		{ "frame box01", -1, -1 },
		{ "frame box02", -1, -1 },
		{ "frame lbottom forarm", 23, -1 },
		{ "frame ltop hand", -1, -1 },
		{ "frame rbottom foarm", 24, -1 },
		{ "frame rtop hand", -1, -1 },
		{ "frame lbottom hand", -1, -1 },
		{ "frame rbottom hand", -1, -1 },
	} },
	-- levels\a10\devices\doors\door airlock
	{ count = 4, checksum = -921384993, nodes = {
		{ "frame door airlock", 2, -1 },
		{ "frame in bottom", -1, -1 },
		{ "frame in top", -1, 3 },
		{ "frame top", -1, 1 },
	} },
	-- levels\a10\devices\doors\door cryo chamber
	{ count = 3, checksum = -2130918511, nodes = {
		{ "frame door cryo", 1, -1 },
		{ "frame door cryo l", -1, 2 },
		{ "frame door cryo r", -1, -1 },
	} },
	-- levels\a10\devices\doors\door jeff tube
	{ count = 3, checksum = 303126628, nodes = {
		{ "frame door jeff tube", 2, -1 },
		{ "frame door l", -1, -1 },
		{ "frame door r", -1, 1 },
	} },
	-- levels\a10\devices\doors\door small / door small no glass
	{ count = 3, checksum = -1054070559, nodes = {
		{ "frame door small", 2, -1 },
		{ "frame in bottom", -1, -1 },
		{ "frame in top", -1, 1 },
	} },
	-- levels\a30\devices\beam emitter + test\infinity beam emitter red
	{ count = 2, checksum = -1073502840, nodes = {
		{ "frame root", 1, -1 },
		{ "frame beam", -1, -1 },
	} },
	-- levels\a30\devices\torpedo_bridge
	{ count = 9, checksum = 893764757, nodes = {
		{ "frame root", 1, -1 },
		{ "frame bridgeaback", 5, 2 },
		{ "frame bridgeafront", 6, 3 },
		{ "frame bridgebback", 7, 4 },
		{ "frame bridgebfront", 8, -1 },
		{ "frame emitteraback", -1, -1 },
		{ "frame emitterafront", -1, -1 },
		{ "frame emitterbback", -1, -1 },
		{ "frame emitterbfront", -1, -1 },
	} },
	-- levels\a50\devices\mustering_door
	{ count = 3, checksum = 16992281, nodes = {
		{ "frame door root", 1, -1 },
		{ "frame left door", -1, 2 },
		{ "frame right door", -1, -1 },
	} },
	-- levels\b30\devices\holo control equipment
	{ count = 5, checksum = -1411630910, nodes = {
		{ "frame root", 2, -1 },
		{ "frame holo circle bot", -1, 3 },
		{ "frame holo circle top", -1, 1 },
		{ "frame holo equip bot", -1, 4 },
		{ "frame holo equip top", -1, -1 },
	} },
	-- levels\b30\devices\holo control room display
	{ count = 21, checksum = -1377126976, nodes = {
		{ "frame root", 1, -1 },
		{ "frame hologramb30", 5, -1 },
		{ "frame big marker01", -1, -1 },
		{ "frame big marker02", -1, 2 },
		{ "frame big marker03", -1, 3 },
		{ "frame sentinel01", -1, 20 },
		{ "frame small marker01", -1, 4 },
		{ "frame small marker02", -1, 6 },
		{ "frame small marker03", -1, 7 },
		{ "frame small marker04", -1, 8 },
		{ "frame small marker05", -1, 9 },
		{ "frame small marker06", -1, 10 },
		{ "frame small marker07", -1, 11 },
		{ "frame small marker08", -1, 12 },
		{ "frame small marker09", -1, 13 },
		{ "frame small marker10", -1, 14 },
		{ "frame small marker11", -1, 15 },
		{ "frame small marker12", -1, 16 },
		{ "frame small marker13", -1, 17 },
		{ "frame small marker14", -1, 18 },
		{ "frame small marker15", -1, 19 },
	} },
	-- levels\b30\devices\holo panel
	{ count = 2, checksum = 265626, nodes = {
		{ "frame root", 1, -1 },
		{ "frame rotor", -1, -1 },
	} },
	-- levels\c10\devices\bridge
	{ count = 5, checksum = -802003263, nodes = {
		{ "frame root", 2, -1 },
		{ "framen_big01", 3, -1 },
		{ "frames_big01", 4, 1 },
		{ "framen_small01", -1, -1 },
		{ "frames_small01", -1, -1 },
	} },
	-- levels\c20\devices\door_large
	{ count = 3, checksum = 743432, nodes = {
		{ "frame root", 2, -1 },
		{ "frame door l", -1, -1 },
		{ "frame door r", -1, 1 },
	} },
	-- levels\c20\devices\holo control
	{ count = 2, checksum = 1074060612, nodes = {
		{ "frame root", 1, -1 },
		{ "frame rotate", -1, -1 },
	} },
	-- levels\c20\devices\holo radial control
	{ count = 8, checksum = 1141351629, nodes = {
		{ "frame root", 4, -1 },
		{ "frame rotate01", -1, -1 },
		{ "frame rotate02", -1, 1 },
		{ "frame rotate03", -1, 2 },
		{ "frame rotate04", -1, 5 },
		{ "frame rotate05", -1, 6 },
		{ "frame rotate06", -1, 7 },
		{ "frame rotate07", -1, 3 },
	} },
	-- levels\c20\devices\holo tri control
	{ count = 6, checksum = 16583471, nodes = {
		{ "frame root", 1, -1 },
		{ "frame rotate01", -1, 5 },
		{ "frame rotate02", -1, -1 },
		{ "frame rotate03", -1, 2 },
		{ "frame rotate04", -1, 3 },
		{ "frame rotate05", -1, 4 },
	} },
	-- scenery\lightning
	{ count = 8, checksum = 830878205, nodes = {
		{ "frame root", 3, -1 },
		{ "frame link01", 4, 2 },
		{ "frame link05", 5, -1 },
		{ "frame link06", -1, 1 },
		{ "frame link02", 7, -1 },
		{ "frame link04", 6, -1 },
		{ "frame link end", -1, -1 },
		{ "frame link end01", -1, -1 },
	} },
	-- c10_bigplant / plant_broadleaf_short
	{ count = 3, checksum = 1074195833, nodes = {
		{ "frame base", 1, -1 },
		{ "frame mid", 2, -1 },
		{ "frame end", -1, -1 },
	} },
	-- scenery\plants\plant_broadleaf_tall
	{ count = 7, checksum = -1033375598, nodes = {
		{ "frame trunk", 2, -1 },
		{ "frame brancha", 4, 3 },
		{ "frame branchb", 5, 1 },
		{ "frame branchc", 6, -1 },
		{ "frame brancha end", -1, -1 },
		{ "frame branchb end", -1, -1 },
		{ "frame branchc end", -1, -1 },
	} },
	-- scenery\trees\tree_leafy_doublewide
	{ count = 4, checksum = -1849496914, nodes = {
		{ "frame tree root", 1, -1 },
		{ "frame tree mid", 2, -1 },
		{ "frame tree top", 3, -1 },
		{ "frame tree top end", -1, -1 },
	} },
	-- scenery\trees\tree_leafy_medium
	{ count = 3, checksum = 1089048985, nodes = {
		{ "frame tree root", 1, -1 },
		{ "frame tree mid", 2, -1 },
		{ "frame tree topend", -1, -1 },
	} },
	-- scenery\trees\tree_pine
	{ count = 2, checksum = -2147257918, nodes = {
		{ "frame root", 1, -1 },
		{ "frame mid", -1, -1 },
	} },
	-- scenery\trees\tree_pine_snow / tree_pine_tall
	{ count = 4, checksum = -804395985, nodes = {
		{ "frame root", 1, -1 },
		{ "frame mid", 2, -1 },
		{ "frame top", 3, -1 },
		{ "frame end", -1, -1 },
	} },
}

local M = {}

-- Node list for a node count and checksum, or nil
function M.find(count, checksum)
	for _, entry in ipairs(fallback) do
		if entry.count == count and entry.checksum == checksum then return entry.nodes end
	end
	return nil
end

return M
