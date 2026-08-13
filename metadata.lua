return PlaceObj('ModDef', {
	-- ✅ NAMING RATIFIED (owner, 2026-08-13): display "Save Rescue", mod id
	-- SMR_CommunitySaveRescue, log tag [CommunitySaveRescue]. The id, the
	-- global `SMRSaveRescue` and the log tag are code contract; the title is
	-- the only display name, and the release-prep pass owns any change to it.
	'title', "Save Rescue",
	'description', "A one-shot cleanup tool for savegames left behind by the Community Fix Pack and the Community Fix Pack: Opt-In Modules. Install it ONLY AFTER you have uninstalled those mods, load your save once, and it removes what they left in it — most importantly a non-base Drone speed / carry dial, which otherwise keeps boosting your Drones forever. It removes only entries it can name, it keeps the ones that repair your save (the Wind Turbine tech buff), and it writes NOTHING into your save of its own: when it is done you can delete it and nothing of it remains. While either of those mods is still installed this tool deliberately does nothing — they clean up after themselves.",
	'short_description', "Removes what the Community Fix Pack mods left in a savegame after you uninstalled them. One load, no options, stores nothing of its own.",
	'last_changes', "Initial pre-release: the curated removal list derived over both shipped mods (docs/agent/reports/D13_EXPOSED_SET.md in the fix pack repo), two one-shot vanilla-body thread heals for saves left by pre-2026-08 builds, and the player report.",
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
