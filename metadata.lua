return PlaceObj('ModDef', {
	-- ✅ NAMING RATIFIED (owner, 2026-08-13): display "Save Rescue", mod id
	-- SMR_CommunitySaveRescue, log tag [CommunitySaveRescue]. The id, the
	-- global `SMRSaveRescue` and the log tag are code contract; the title is
	-- the only display name, and the release-prep pass owns any change to it.
	'title', "Save Rescue",
	-- ⛔ CORRECTED 2026-08-14 (release-3 prompt 2, the terminal audit; licence:
	-- the owner's standing 22b word, text-only, no behaviour, no version bump).
	-- TWO defects: (1) "load once … delete it" never said to SAVE — the clean
	-- pass edits the loaded colony, and only the player's next save writes that
	-- into the file; delete-without-saving keeps the residue forever, with the
	-- tool gone. (2) "while either of those mods is still installed this tool
	-- deliberately does nothing" contradicted the shipped PER-MOD stand-down
	-- (10_SaveRescue.lua owner_present/owner_blocked): with only one mod removed
	-- the tool DOES clean that mod's leftovers — the mixed case is the design's
	-- own stated common case.
	'description', "A one-shot cleanup tool for savegames left behind by the Community Fix Pack and the Community Fix Pack: Opt-In Modules. Install it ONLY AFTER you have uninstalled those mods, load your save once, and it removes what they left in it — most importantly a non-base Drone speed / carry dial, which otherwise keeps boosting your Drones forever. Then save: saving is what writes the cleaned colony into the file. It removes only entries it can name, it keeps the ones that repair your save (the Wind Turbine tech buff), and it writes NOTHING into your save of its own: once you have saved, you can delete it and nothing of it remains. An installed mod cleans up after itself, so this tool only removes what a mod that is gone left behind.",
	'short_description', "Removes what the Community Fix Pack mods left in a savegame after you uninstalled them. One load and a save, no options, stores nothing of its own.",
	-- ⛔ CORRECTED 2026-08-14 (release-3 prompt 1): this string carried a repo
	-- FILE PATH and two house words. Player-facing strings may not carry either
	-- (the release chain's rule 4), and the path is doubly wrong here: `docs/` is
	-- in `ignore_files` below, so the file it names is not in the shipped package
	-- at all. Licence: the owner's standing 22b word ("change any wordings to
	-- their accurate versions"); text-only, no behaviour, no version bump.
	'last_changes', "Initial pre-release. The removal list is derived item by item over the shipped code of both mods rather than by pattern matching, so the tool removes only what it can name. Also included: two one-shot repairs that put a dead meteor timer and an old rain cycle back onto the game's own machinery, for saves left behind by earlier Fix Pack builds, and the on-screen summary of what was removed, what was repaired and what was deliberately kept.",
	'id', "SMR_CommunitySaveRescue",
	'author', "catt144",
	-- pre-release 0.1.0 (major.minor.version); launch prep sets the ship value
	'version', 0,
	'version_major', 0,
	'version_minor', 1,
	'lua_revision', 350453,
	-- a save made with this mod loads fine without it — it persists nothing at
	-- all (spec §10.7, see docs/PROVENANCE.md), so never nag with the
	-- missing-mods prompt
	'optional_mod', true,
	-- the packer includes EVERYTHING recursively minus this list (Mod.lua:250-256,
	-- GedModEditor.lua:716-732) — without the extra patterns docs/, README.md,
	-- .gitignore and .claude/ all ship inside the .hpk. LICENSE ships on purpose.
	'ignore_files', {
		"*.git/*",
		"*.svn/*",
		"*/Source/*",
		"*/SourceData/*",
		"*/docs/*",
		"*/.claude/*",
		"*README.md",
		"*CLAUDE.md",
		"*.gitignore",
	},
	-- ⛔ NO 'default_options': this mod has no Mod Options page and no toggles.
	-- ⛔ ORDER IS LOAD-BEARING: ModDef:LoadCode iterates THIS list and scans no
	-- directory (Mod.lua:490-521), so 00_Core.lua must stay first — the module
	-- calls SMRSaveRescue.Register at file scope.
	'code', {
		"Code/00_Core.lua",
		"Code/10_SaveRescue.lua",
	},
	'TagTools', true,
})
