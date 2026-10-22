------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

-- Halo CE animation file names for retargeted first person animations (Halo Reach / 4 / 5 /
-- Infinite style names in, stock Halo CE names out), so the output compiles as is:
--   first_person reload_full       -> first-person reload-full
--   first_person fire_1 var1, var2 -> first-person fire-1%0, first-person fire-1%1
--   first_person melee_strike_1, 2 -> first-person melee%0, first-person melee%1
--   first_person ready_initial, ready -> first-person ready%0, first-person ready%1
-- Variants are numbered from %0 in order; an action with a single file gets no %.

-- First person actions stock Halo CE knows
global RETARGET_HCE_FP_ACTIONS = #("idle", "ready", "fire-1", "fire-2", "reload-empty", "melee", "reload-full", \
	"throw-grenade", "moving", "overlays", "o-h-exit", "o-h-s-enter", "overcharged", "overcharged-jitter", \
	"overheated", "overheating", "posing", "enter", "exit-empty", "exit-full", "throw-overheated")

-- "first_person fire_1 var2" -> #("fire-1", 2). Variant 0 = no variant suffix.
-- Names already in Halo CE style ("first-person fire-1%1") parse too. Undefined if not first person.
fn retargetParseFirstPersonName baseName =
(
	local tokens = filterString (toLower baseName) " "
	if tokens.count < 2 or (tokens[1] != "first_person" and tokens[1] != "first-person") do return undefined
	local actionTokens = for i = 2 to tokens.count collect tokens[i]
	local variant = 0

	local last = actionTokens[actionTokens.count]
	if actionTokens.count > 1 and (matchPattern last pattern:"var*") and ((substring last 4 -1) as integer) != undefined do
	(
		variant = (substring last 4 -1) as integer
		actionTokens.count = actionTokens.count - 1
	)
	if actionTokens.count != 1 do return undefined

	local action = substituteString actionTokens[1] "_" "-"
	local percent = findString action "%"
	if percent != undefined do
	(
		local n = (substring action (percent + 1) -1) as integer
		action = substring action 1 (percent - 1)
		if n != undefined do variant = n + 1
	)
	-- The melee strikes are Halo CE's melee variants
	if matchPattern action pattern:"melee-strike-*" do
	(
		local n = (substring action 14 -1) as integer
		if n != undefined do
		(
			action = "melee"
			variant = n
		)
	)
	-- The first time ready is Halo CE's first ready variant (%0), ahead of the plain ready
	if action == "ready-initial" do
	(
		action = "ready"
		variant = -1
	)
	#(action, variant)
)

-- Halo CE base name (no extension) per file, or undefined when it has no Halo CE equivalent.
-- Takes the whole folder at once, since variant numbers depend on the other files.
fn retargetHaloCENames filePaths =
(
	local parsed = for f in filePaths collect retargetParseFirstPersonName (getFilenameFile f)
	local names = #()
	names.count = filePaths.count
	local done = #()
	for i = 1 to filePaths.count where parsed[i] != undefined and (findItem done i) == 0 do
	(
		local action = parsed[i][1]
		if (findItem RETARGET_HCE_FP_ACTIONS action) == 0 do continue
		-- Every file of this action, by variant then name
		local members = for k = 1 to filePaths.count where parsed[k] != undefined and parsed[k][1] == action collect k
		fn compareVariant a b = if a[1] != b[1] then a[1] - b[1] else stricmp a[2] b[2]
		local keyed = for k in members collect #(parsed[k][2], getFilenameFile filePaths[k], k)
		qsort keyed compareVariant
		for v = 1 to keyed.count do
		(
			local k = keyed[v][3]
			names[k] = "first-person " + action + (if keyed.count > 1 then "%" + ((v - 1) as string) else "")
			append done k
		)
	)
	names
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
