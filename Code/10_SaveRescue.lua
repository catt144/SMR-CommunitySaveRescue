-- Save Rescue — the clean pass.
--
-- WHAT THIS IS. The Community Fix Pack and its Opt-In Modules leave named data
-- in a savegame. Almost all of it is inert once the mods are gone; two things
-- are not, and one of them keeps changing the game forever: a non-base Drone
-- speed / carry dial persists as a vanilla `Modifier` under our string id, and
-- with the mod uninstalled nothing is left to take it off again. This module
-- removes that, and the rest of the named leftovers with it.
--
-- WHERE THE LIST COMES FROM. `ROWS` below is the curated detection table of the
-- authoritative exposed-set derivation over BOTH shipped mods —
-- `docs/agent/reports/D13_EXPOSED_SET.md` in the Community Fix Pack repo (§2b
-- for the sites, §5 for the KEEP/REMOVE reasoning, §10 for this spec). Every
-- persisted name either mod has ever written has a row, and every row has an
-- action. ⛔ DETECTION IS BY THIS TABLE ONLY. Never by an `SMRFixPack_*`
-- pattern: a 2026-07-31 pattern sweep false-positived on 192 buildings twice,
-- and a pattern sweep would delete the F35 turbine modifiers, which ARE a
-- repair — removing them re-breaks the save permanently, with no mod left
-- installed to redo them.
--
-- THE THREE RULES THIS FILE IS WRITTEN UNDER:
--   1. Remove only what is named here. A name on neither list is a gap in the
--      derivation, to be fixed there — never a judgement call made at runtime.
--   2. Never write anything. Every mutation below is `= nil` or a vanilla
--      removal/restart call. This mod must be deletable with no trace.
--   3. Ambiguity is reported, never guessed (see the meteor heal).
--
-- ⛔ NOTHING HERE HAS BEEN RUN IN A GAME. Every claim in these comments is
-- source-derived; the measured claims belong to the verification pass.

local ID = "SaveRescue"
local log = SMRSaveRescue.Log

--------------------------------------------------------------------------------
-- The curated table (spec §10.2)
--
-- owner  — which mod wrote it: "FP" = Community Fix Pack, "OP" = Opt-In Modules.
--          A row acts only while ITS OWNER IS ABSENT (see stand_down below).
-- kind   — "label-modifier" | "object-field" | "entry-field" | "colony-field"
--          | "gamevar"
-- action — "REMOVE" | "KEEP" | "NONE" (unreachable by construction)
--          | "NOTHUNTED" (reachable in principle, deliberately not touched)
-- noun   — how the row is counted in the player-facing report; rows sharing a
--          noun are summed into one line.
--
-- ⛔ The `name` strings are SAVE CONTRACT — the exact bytes sitting in players'
-- savegames. The five opt-in-side names keep the legacy `SMRFixPack_` prefix on
-- purpose (that mod was split out of the fix pack and its names could not
-- change). Never "tidy" one of them.
local ROWS = {
	-- ⭐ the reason this tool exists: a live boost that outlives its mod
	{ id = "D15a", owner = "OP", name = "SMRFixPack_DroneSpeedDial", kind = "label-modifier",
	  label = "Drone", action = "REMOVE", noun = "drone stat dial",
	  why = "a vanilla Modifier under our id; SetLabelModifier(label, id, nil) is the removal path the module itself uses at its base position" },
	{ id = "D15b", owner = "OP", name = "SMRFixPack_DroneCarryDial", kind = "label-modifier",
	  label = "Consts", action = "REMOVE", noun = "drone stat dial",
	  why = "same" },

	-- inert object fields: absence is the pre-mod state each module tolerates
	{ id = "D5",  owner = "FP", name = "SMRFixPack_reserved_at", kind = "object-field",
	  label = "Colonist", action = "REMOVE", noun = "reservation timestamp",
	  why = "read only by Fix_StaleReservations' daily sweep, which treats absence as 'start the clock now'" },
	{ id = "D6",  owner = "FP", name = "SMRFixPack_shelter_try", kind = "object-field",
	  label = "Colonist", action = "REMOVE", noun = "shelter timer",
	  why = "rate-limit timestamp read only by the Colonist:Idle shelter branch" },
	{ id = "D7",  owner = "FP", name = "SMRFixPack_payload_set", kind = "object-field",
	  label = "AllRockets", action = "REMOVE", noun = "rocket payload flag",
	  why = "boolean read only by Fix_PayloadTemplateRefill; absence IS the pre-fix behaviour" },
	{ id = "D8",  owner = "FP", name = "SMRFixPack_rocket_fuel_key", kind = "object-field",
	  label = "DroneControl", action = "REMOVE", noun = "drone hub key",
	  why = "legacy: the current pack deletes it itself, so only saves that never loaded under it still carry one" },
	{ id = "D12", owner = "OP", name = "SMRFixPack_ack_notworking", kind = "object-field",
	  label = "Building", action = "REMOVE", noun = "building flag",
	  why = "inert stamp; the module's own header states stale stamps do nothing" },
	{ id = "D13", owner = "OP", name = "SMRFixPack_closed_to_new_residents", kind = "object-field",
	  label = "Community", action = "REMOVE", noun = "dome flag",
	  why = "nil means vanilla by the module's own contract" },
	{ id = "D14", owner = "OP", name = "SMRFixPack_no_homeless", kind = "object-field",
	  label = "Community", action = "REMOVE", noun = "dome flag",
	  why = "nil means vanilla" },

	-- fields our packs wrote INSIDE vanilla's own RainsDisasterThreads entries
	{ id = "D3",  owner = "FP", name = "SMRFixPack_loop_version", kind = "entry-field",
	  action = "REMOVE", noun = "rain loop stamp",
	  why = "version stamp; vanilla ignores unknown fields on entry reuse" },
	{ id = "D4",  owner = "FP", name = "SMRFixPack_fixed_loop", kind = "entry-field",
	  action = "REMOVE", noun = "rain loop stamp",
	  why = "legacy stamp — AND the only detector the rain heal has, so it is read in step 1 and removed in step 4 of the same pass" },

	-- ⛔⛔ KEEP. Removing these breaks the save, and no mod is left to repair it.
	{ id = "D10", owner = "FP", name = "SMRFixPack_F35_", kind = "label-modifier-prefix",
	  action = "KEEP", noun = "wind turbine repair",
	  why = "THE RESIDUE IS THE REPAIR: these are the Frictionless Composites buff the game's own migration fixup never re-applied to Large Wind Turbines" },
	{ id = "D11", owner = "FP", name = "SMRFixPack_F48_StationConnectors", kind = "colony-field",
	  action = "KEEP", noun = "track re-order latch",
	  why = "one-shot latch; dropping it silently invites a second re-ordering pass over a save that already had one" },

	-- unreachable by construction, and stated so rather than omitted
	{ id = "D1",  owner = "FP", name = "SMRFixPack_MeteorLatch", kind = "gamevar",
	  action = "NONE",
	  why = "mod-registered GameVar: PersistLoad restores only names still in PersistableGlobals and PersistSave writes only registered names (persist.lua:119-143), so a load without the pack drops the value and the next save omits it. A cleaner could only reach it by REGISTERING the name — which would persist it as OUR residue" },
	{ id = "D2",  owner = "FP", name = "SMRFixPack_FirstAsteroidPrefabs", kind = "gamevar",
	  action = "NONE",
	  why = "same mechanism, same conclusion: self-clearing, and unreachable without violating this tool's own bar" },

	-- reachable in principle, deliberately left alone
	{ id = "D9",  owner = "FP", name = "SMRFixPack_spawn_gate", kind = "thread-local",
	  action = "NOTHUNTED",
	  why = "it lives on a descriptor copy held in a vanilla scheduler thread's local and self-replaces within one wave (measured); reaching it would mean touching another thread's locals" },
}

-- Fast lookups built once from the table above. Nothing else may add to them.
local FIELD_ROWS, ENTRY_ROWS, MODIFIER_ROWS = {}, {}, {}
for _, row in ipairs(ROWS) do
	if row.action == "REMOVE" then
		if row.kind == "object-field" then
			FIELD_ROWS[row.name] = row
		elseif row.kind == "entry-field" then
			ENTRY_ROWS[row.name] = row
		elseif row.kind == "label-modifier" then
			MODIFIER_ROWS[#MODIFIER_ROWS + 1] = row
		end
	end
end
-- The KEEP prefix is used for a READ-ONLY census only (the report's "kept on
-- purpose" line). It is never used to select anything for removal — that is
-- exactly the pattern-matching this tool is forbidden to do.
local KEEP_MODIFIER_PREFIX = "SMRFixPack_F35_"
local KEEP_COLONY_FIELD = "SMRFixPack_F48_StationConnectors"

--------------------------------------------------------------------------------
-- Gates

-- ⭐ THE STAND-DOWN GATE, and it is PER-MOD rather than global (spec §10.1).
-- This tool serves saves whose mod is ALREADY GONE: an installed pack cleans up
-- after itself on load, and the Opt-In Modules' dial module reconciles its own
-- modifiers on PostLoadGame — so acting under a loaded pack is churn at best
-- and a fight at worst (both write on the same message; order is not
-- guaranteed). Per-mod, because the mixed case is the common one: a player who
-- removed the Opt-In Modules but kept the Fix Pack has permanent dial residue
-- and no in-pack cleaner for it.
--
-- ⚠️ "Installed" here is the pack=n/n sense: a pack whose code is live reads as
-- PRESENT even if the player has toggled it off, or disabled it in the Mod
-- Manager without the full game restart that a disable actually needs. That is
-- correct — they still have the mod — but it means this tool is not a
-- substitute for uninstalling, and the report says so.
local function owner_present(owner)
	if owner == "FP" then return rawget(_G, "SMRFixPack") ~= nil end
	if owner == "OP" then return rawget(_G, "SMROptInPack") ~= nil end
	return false
end

-- Is this row's owner standing in the way? `opts.force` (probes, console)
-- bypasses THIS gate and nothing else — never the KEEP list, never an
-- ambiguity skip. The rig's normal configuration has both packs loaded, so
-- without this door no probe could ever sample the pass at all (the recorded
-- lesson: a direct call that short-circuits on its own gate returns a zero
-- that samples nothing).
local function owner_blocked(opts, owner)
	return not (opts and opts.force) and owner_present(owner)
end

--------------------------------------------------------------------------------
-- Result bookkeeping

local function new_result()
	return {
		removed = 0,                -- total entries removed
		by_noun = {},               -- player-facing noun -> count
		by_name = {},               -- exact persisted name -> count (log/probe)
		kept = {},                  -- noun -> count (census only, never touched)
		heals = { meteors = 0, rains_restarted = 0, rains_finished = 0 },
		skipped = {},               -- human-readable reasons, in order
		stood_down = {},            -- "FP" / "OP" -> true
		scanned = false,            -- true when this was a read-only census
	}
end

local function count(res, row, n)
	n = n or 1
	res.removed = res.removed + n
	res.by_noun[row.noun] = (res.by_noun[row.noun] or 0) + n
	res.by_name[row.name] = (res.by_name[row.name] or 0) + n
end

local function skip(res, fmt, ...)
	local msg = string.format(fmt, ...)
	res.skipped[#res.skipped + 1] = msg
	log("skipped: %s", msg)
end

--------------------------------------------------------------------------------
-- Step 1 — the two one-shot bounded thread heals (spec §10.4)
--
-- WHO THESE ARE FOR. Saves whose pack was removed BEFORE the 2026-08 rewrite:
-- they never ran the pack's own latched meteor heal or its rains migration, so
-- they can still carry a dead Meteors thread or a rain loop running the pack's
-- OLD replaced body, captured by value with the save.
--
-- ⛔ WHAT THEY ARE NOT. They do not touch captured FRAMES — a mod frame sitting
-- inside some vanilla thread's stack. Nothing in this engine can reach into
-- another thread's stack from Lua, `debug` is blacklisted for mod code, and
-- those frames are all layer-2 shaped anyway (they finish on vanilla code and
-- return). Whole ORPHANED THREADS with a stale entry body are a different
-- thing, and they are what these two heals address.
--
-- Both heals use VANILLA primitives and recreate VANILLA bodies, so nothing of
-- this mod can be captured by the save.

-- (1a) Rains. Detector-driven, therefore precise rather than blanket.
local function heal_rains(res)
	local threads = rawget(_G, "RainsDisasterThreads")
	if type(threads) ~= "table" then
		return -- nothing persisted. ⛔ NOT recreated: RainsDisasterThreads is
		       -- vanilla's own GameVar and its structure is not our residue.
	end

	local presets = rawget(_G, "Presets")
	presets = type(presets) == "table" and presets.MapSettings or nil
	presets = type(presets) == "table" and presets.RainsDisaster or nil

	-- stale-ACTIVE: the save says a rain is running, but no thread runs it.
	-- Healed through VANILLA's own FinishRainProcedure, which clears the entry's
	-- fields, label modifiers and notifications, sets g_RainDisaster false and
	-- posts RainDisasterEnd — which also frees a loop still blocked in WaitMsg.
	-- COST: the phantom rain ends. That IS the repair.
	local active = rawget(_G, "g_RainDisaster")
	if active then
		local entry = type(threads[active]) == "table" and threads[active] or nil
		if not (entry and IsValidThread(entry.main_thread)) then
			local known = entry ~= nil
			if not known and presets then
				for _, s in ipairs(presets) do
					if s.type == active then known = true break end
				end
			end
			local finish = rawget(_G, "FinishRainProcedure")
			if known and type(finish) == "function" then
				log("stale-ACTIVE rain '%s' (no live main_thread) — healing through vanilla FinishRainProcedure",
					tostring(active))
				finish(active)
				res.heals.rains_finished = res.heals.rains_finished + 1
			elseif not known then
				-- an unknown value cannot go through FinishRainProcedure (its
				-- notif_prefix lookup would concatenate nil) — the pack's own
				-- manual fallback, and both writes are vanilla-valued
				log("g_RainDisaster held '%s', which is no known rain type — cleared manually",
					tostring(active))
				g_RainDisaster = false
				Msg("RainDisasterEnd", MainMap, "normal")
				res.heals.rains_finished = res.heals.rains_finished + 1
			else
				skip(res, "stale-ACTIVE rain '%s' left alone — FinishRainProcedure is missing (game update?)",
					tostring(active))
			end
		end
	end

	-- Legacy loop bodies. `SMRFixPack_fixed_loop` marks an activation thread
	-- created by the pack's OLD replaced loop body — the one an uninstalled
	-- player could otherwise never shed. An entry carrying `loop_version`
	-- instead was already migrated onto vanilla's body by the pack itself: its
	-- thread is left strictly alone and only the stamp goes (step 4).
	-- COST: one rain re-roll for that type — the recreated loop restarts its
	-- Sleep(spawntime + AsyncRand(spawntime_random)).
	local loop = rawget(_G, "RainsDisasterLoop")
	local del, create = rawget(_G, "DeleteThread"), rawget(_G, "CreateGameTimeThread")
	for rain_type, data in pairs(threads) do
		if type(data) == "table" and rawget(data, "SMRFixPack_fixed_loop") == true
				and IsValidThread(data.activation_thread) then
			if type(loop) ~= "function" or type(del) ~= "function" or type(create) ~= "function" then
				skip(res, "'%s' rain loop left as-is — RainsDisasterLoop/DeleteThread/CreateGameTimeThread not found (game update?)",
					tostring(rain_type))
			else
				local settings = presets and data.id and presets[data.id] or nil
				if not settings and presets then
					-- the id-less case: a UNIQUE type match resolves it, and
					-- anything ambiguous is left alone and reported
					local match, hits = nil, 0
					for _, s in ipairs(presets) do
						if s.type == rain_type then match, hits = s, hits + 1 end
					end
					if hits == 1 then settings = match end
				end
				if settings then
					del(data.activation_thread)
					-- ⭐ the entry body is VANILLA's global, read live right
					-- here: with this mod's own code nowhere in it, the thread
					-- the save captures next is a vanilla thread.
					data.activation_thread = create(loop, settings)
					res.heals.rains_restarted = res.heals.rains_restarted + 1
					log("'%s' rain loop was running the pack's old body — recreated on the game's own loop (settings '%s'); one rain re-roll",
						tostring(rain_type), tostring(settings.id))
				else
					skip(res, "'%s' rain loop left as-is — its settings could not be resolved (id '%s')",
						tostring(rain_type), tostring(data.id))
				end
			end
		end
	end
end

-- (1b) Meteors. DEAD OR ABSENT ONLY.
local function heal_meteors(res)
	local funcs = rawget(_G, "GlobalGameTimeThreadFuncs")
	local restart = rawget(_G, "RestartGlobalGameTimeThread")
	if type(funcs) ~= "table" or type(funcs.Meteors) ~= "function"
			or type(restart) ~= "function" then
		skip(res, "meteor thread not checked — RestartGlobalGameTimeThread/GlobalGameTimeThreadFuncs.Meteors not found (game update?)")
		return
	end
	-- The pack's own designed-silence guards. Without them this tool would
	-- "repair" a map that is supposed to be quiet.
	if not rawget(_G, "MainMap") or not MainMap then
		skip(res, "meteor thread not checked — no map loaded")
		return
	end
	local rule_active = rawget(_G, "IsGameRuleActive")
	if type(rule_active) == "function" and rule_active("NoDisasters") then
		skip(res, "meteor thread left alone — the No Disasters game rule is on (the silence is designed)")
		return
	end
	local get_descr = rawget(_G, "GetMeteorsDescr")
	local descr = type(get_descr) == "function" and get_descr() or nil
	if not descr or descr.forbidden then
		skip(res, "meteor thread left alone — this map has no meteors, or they are forbidden (the silence is designed)")
		return
	end

	local thread = rawget(_G, "Meteors")
	if IsValidThread(thread) then
		-- ⛔ AMBIGUITY → REPORT, NEVER GUESS. A live thread might be running a
		-- captured pack-era body, and there is no way to read another thread's
		-- entry function from Lua. Restarting a healthy thread would re-roll the
		-- meteor timer on every single load, forever — the exact trap this
		-- tool's design bans.
		skip(res, "meteor thread is alive and left alone — whether a live thread carries an old body cannot be read from Lua, and restarting a healthy one would re-roll the timer on every load")
		return
	end

	-- With no pack loaded, GlobalGameTimeThreadFuncs.Meteors IS the game's own
	-- body, so the restart rebuilds vanilla. COST: one re-roll of the next
	-- strike from the descriptor's own 35-115h window, and any pending warning
	-- is lost. It happens only on a load that finds the thread dead, and a
	-- restarted thread is alive on the next load, so it cannot repeat.
	log("the persisted Meteors thread was %s — restarting it on the game's own body; the next meteor is re-rolled",
		thread == false and "never created" or "dead")
	restart("Meteors")
	res.heals.meteors = res.heals.meteors + 1
end

--------------------------------------------------------------------------------
-- Step 2 — label modifiers (the drone dials)

local function clear_modifiers(res, opts)
	local scan_only = opts and opts.scan_only
	local colony = rawget(_G, "UIColony")
	if type(colony) ~= "table" or type(colony.SetLabelModifier) ~= "function"
			or type(colony.label_modifiers) ~= "table" then
		skip(res, "label modifiers not checked — UIColony/SetLabelModifier not available")
		return
	end
	local by_label = colony.label_modifiers
	for _, row in ipairs(MODIFIER_ROWS) do
		if not owner_blocked(opts, row.owner) then
			local mods = by_label[row.label]
			if type(mods) == "table" and mods[row.name] ~= nil then
				if not scan_only then
					-- vanilla's own removal path: it un-applies the modifier
					-- from every object in the label before dropping the entry
					-- (LabelContainer.lua:59-78) — the same call the module
					-- itself makes when its dial is set back to base.
					colony:SetLabelModifier(row.label, row.name, nil)
				end
				count(res, row)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Step 3 — object fields
--
-- A LABEL WALK, not a map-wide object sweep: for every city, every list in
-- city.labels, each object visited once. The labels named in ROWS are
-- documentation — the walk covers them all, so a mis-guessed label name cannot
-- silently skip a carrier, and only the exact names above are ever tested.
--
-- ⚠️ KNOWN INCOMPLETENESS, stated rather than hidden: an object in no label is
-- not visited. The real case is a colonist riding a rocket — CargoTransporter
-- sets keep_cargo_in_labels = false, so cargo colonists leave the labels. Their
-- (inert) timestamps survive that load. This pass is idempotent and runs on
-- every load, so they are cleared the first time they are back in a label.

local function clear_fields(res, opts)
	local scan_only = opts and opts.scan_only
	local cities = rawget(_G, "Cities")
	if type(cities) ~= "table" then
		skip(res, "object fields not checked — Cities not available")
		return
	end
	local seen = {}
	local function visit(obj)
		if type(obj) ~= "table" or seen[obj] then return end
		seen[obj] = true
		for name, row in pairs(FIELD_ROWS) do
			-- rawget, so a class-table default could never read as an instance
			-- field: these names are only ever written on instances.
			if not owner_blocked(opts, row.owner) and rawget(obj, name) ~= nil then
				if not scan_only then obj[name] = nil end
				count(res, row)
			end
		end
	end

	for _, city in ipairs(cities) do
		if type(city) == "table" then
			visit(city)
			local labels = city.labels
			if type(labels) == "table" then
				for _, list in pairs(labels) do
					if type(list) == "table" then
						for _, obj in ipairs(list) do visit(obj) end
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Step 4 — fields our packs wrote inside vanilla's RainsDisasterThreads entries
--
-- ⛔ ORDER: this runs AFTER the rain heal, which reads SMRFixPack_fixed_loop as
-- its only detector. Removing the detector here is what makes the heal
-- self-limiting: a second load finds no stamp and does no work — which is how
-- this tool stays idempotent WITHOUT a latch of its own. A latch would be
-- persisted state, and this tool is not allowed any.

local function clear_entry_fields(res, opts)
	local scan_only = opts and opts.scan_only
	local threads = rawget(_G, "RainsDisasterThreads")
	if type(threads) ~= "table" then return end
	for _, data in pairs(threads) do
		if type(data) == "table" then
			for name, row in pairs(ENTRY_ROWS) do
				if not owner_blocked(opts, row.owner) and rawget(data, name) ~= nil then
					if not scan_only then data[name] = nil end
					count(res, row)
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Step 5 — GameVars: a no-op, on purpose, and the reason is the whole design
--
-- D1/D2 are mod-registered GameVars. A load without the registering mod drops
-- them and the next save omits them, so they are already gone by the time this
-- tool can look — and the only way to "reach" one would be to register the name
-- ourselves, which would persist it as OUR residue. There is therefore no code
-- here, and that absence is the compliant answer rather than an oversight.

--------------------------------------------------------------------------------
-- The KEEP census — READ ONLY, and never a selector
--
-- The report's "kept on purpose" line needs a count of the F35 turbine repairs.
-- This is the ONLY place a prefix is matched, it is matched to COUNT and never
-- to select for removal, and nothing it finds is touched.

local function census_kept(res)
	local colony = rawget(_G, "UIColony")
	if type(colony) ~= "table" then return end
	local by_label = colony.label_modifiers
	if type(by_label) == "table" then
		local n = 0
		for _, mods in pairs(by_label) do
			if type(mods) == "table" then
				for id in pairs(mods) do
					if type(id) == "string" and id:sub(1, #KEEP_MODIFIER_PREFIX) == KEEP_MODIFIER_PREFIX then
						n = n + 1
					end
				end
			end
		end
		if n > 0 then res.kept["wind turbine repair"] = n end
	end
	if rawget(colony, KEEP_COLONY_FIELD) ~= nil then
		res.kept["track re-order latch"] = 1
	end
end

--------------------------------------------------------------------------------
-- The report (spec §10.5)

local function plural(n, noun)
	return string.format("%d %s%s", n, noun, n == 1 and "" or "s")
end

local function join(t)
	local parts = {}
	for noun, n in pairs(t) do parts[#parts + 1] = plural(n, noun) end
	table.sort(parts)
	return table.concat(parts, " · ")
end

local function report_text(res)
	local lines = {
		"This save still carried leftovers from the Community Fix Pack mods. They are now removed. Nothing was added to your save.",
	}
	if next(res.by_noun) then
		lines[#lines + 1] = "\nRemoved: " .. join(res.by_noun)
	end
	local repairs = {}
	if res.heals.meteors > 0 then
		repairs[#repairs + 1] = "the meteor timer was restarted — the next meteor is re-rolled from its normal 35-115 hour window"
	end
	if res.heals.rains_restarted > 0 then
		repairs[#repairs + 1] = string.format(
			"%s restarted on the game's own timer (one re-roll each)",
			plural(res.heals.rains_restarted, "rain cycle"))
	end
	if res.heals.rains_finished > 0 then
		repairs[#repairs + 1] = string.format("%s that the save thought was still running was ended",
			plural(res.heals.rains_finished, "rain"))
	end
	if #repairs > 0 then
		lines[#lines + 1] = "\nRepaired: " .. table.concat(repairs, " · ")
	end
	if next(res.kept) then
		lines[#lines + 1] = "\nKept on purpose: " .. join(res.kept)
			.. ". These entries repair a bug in your save; deleting them would bring it back."
	end
	lines[#lines + 1] = "\nYou can remove Save Rescue whenever you like — it stores nothing in your save."
	return table.concat(lines, "\n")
end

-- Session-local, never persisted: the stand-down notice is worth saying once,
-- not on every load.
local stand_down_told = false

local function show(title, text)
	-- ⛔ THE DIALOG MUST RIDE A REAL-TIME THREAD. WaitMessage yields, and a
	-- yield on the load-path game-time frame would leave a blocked mod frame in
	-- the very save this tool exists to clean. Real-time threads are persisted
	-- only when flagged threadPersist (persist.lua:128-131) and this one is
	-- not, so it cannot enter a save. The clean pass itself stays synchronous.
	CreateRealTimeThread(function()
		-- let the load settle before putting a dialog over it
		Sleep(2000)
		local wait_message = rawget(_G, "WaitMessage")
		if type(wait_message) == "function" then
			wait_message(nil, Untranslated(title), Untranslated(text))
		end
	end)
end

--------------------------------------------------------------------------------
-- The pass

local function log_summary(res)
	-- ⛔ Printed even when every number is zero, and that is the point: an
	-- absence of lines cannot be told from an absence of the pass.
	log("pass: removed %d entr%s%s%s | heals: meteors %d, rains restarted %d, rains ended %d | skipped %d",
		res.removed, res.removed == 1 and "y" or "ies",
		next(res.by_name) and (" (" .. (function()
			local parts = {}
			for name, n in pairs(res.by_name) do parts[#parts + 1] = name .. "=" .. n end
			table.sort(parts)
			return table.concat(parts, ", ")
		end)() .. ")") or "",
		next(res.kept) and (" | kept " .. join(res.kept)) or "",
		res.heals.meteors, res.heals.rains_restarted, res.heals.rains_finished,
		#res.skipped)
end

-- opts.force     — bypass ONLY the stand-down gate (never the KEEP list, never
--                  the ambiguity skips). For probes and the console.
-- opts.scan_only — count what is present, change nothing.
-- opts.quiet     — no player dialog (the log line is always written).
function SMRSaveRescue.RunPass(opts)
	opts = opts or {}
	local res = new_result()
	res.scanned = opts.scan_only and true or false

	log("Save Rescue %s — list derived over Community Fix Pack cdbcd9d / Opt-In Modules e17586b (2026-08-13)",
		tostring(SMRSaveRescue.ModVersion() or "version unreadable"))

	if not SMRSaveRescue.IsActive(ID) then
		local m = SMRSaveRescue.modules[ID]
		skip(res, "module is %s%s", m and m.status or "not registered",
			m and m.detail and m.detail ~= "" and (" — " .. m.detail) or "")
		log_summary(res)
		return res
	end

	if not opts.force then
		for _, owner in ipairs({ "FP", "OP" }) do
			if owner_present(owner) then res.stood_down[owner] = true end
		end
	end

	local steps = {
		{ "thread heals", function()
			-- FP-owned: an installed pack heals its own threads on load.
			if owner_blocked(opts, "FP") then
				skip(res, "thread heals skipped — the Community Fix Pack is installed and heals its own")
				return
			end
			if opts.scan_only then
				skip(res, "thread heals skipped — scan only")
				return
			end
			heal_rains(res)
			heal_meteors(res)
		end },
		{ "label modifiers", function() clear_modifiers(res, opts) end },
		{ "object fields", function() clear_fields(res, opts) end },
		{ "rain entry fields", function() clear_entry_fields(res, opts) end },
		{ "keep census", function() census_kept(res) end },
	}
	for _, step in ipairs(steps) do
		-- one pcall per step: a step that raises costs that step and not the
		-- pass, and says which one it was.
		local ok, err = pcall(step[2])
		if not ok then
			skip(res, "the '%s' step failed: %s", step[1], tostring(err))
		end
	end

	log_summary(res)
	return res
end

-- Read-only census: what of the list is in this save right now.
function SMRSaveRescue.Scan()
	return SMRSaveRescue.RunPass({ scan_only = true, force = true, quiet = true })
end

-- The heals alone (probe surface).
function SMRSaveRescue.HealThreads(opts)
	opts = opts or {}
	local res = new_result()
	if owner_blocked(opts, "FP") then
		skip(res, "thread heals skipped — the Community Fix Pack is installed and heals its own")
	else
		local ok, err = pcall(function() heal_rains(res) heal_meteors(res) end)
		if not ok then skip(res, "the thread heals failed: %s", tostring(err)) end
	end
	log_summary(res)
	return res
end

-- Console helper: the whole curated table, with its actions and reasons.
function SMRSaveRescue.ListResidue()
	log("curated residue table — %d rows (source: D13_EXPOSED_SET.md in the Community Fix Pack repo)", #ROWS)
	for _, row in ipairs(ROWS) do
		log("  %-5s %-2s %-9s %-22s %s", row.id, row.owner, row.action, row.kind, row.name)
	end
end

--------------------------------------------------------------------------------

SMRSaveRescue.Register(ID, {
	title = "Removes Community Fix Pack leftovers from a savegame it is no longer installed in",
	apply = function()
		-- Everything this module touches is savegame state, so there is nothing
		-- to patch at load time. The self-check is that the API the pass calls
		-- still exists; the game objects themselves are re-checked on every run.
		return SMRSaveRescue.Require({
			{ class = "LabelContainer", method = "SetLabelModifier" },
			{ global = "IsValidThread" },
		})
	end,
})

-- PostLoadGame, NOT LoadGame: UnpersistGame fires Msg("LoadGame"), then runs
-- FixupSavegame, then fires Msg("PostLoadGame") (CommonLua\Savegame.lua:810-813).
-- The game's own savegame fixups must have run before anything is judged; the
-- fix pack's own sanitizer rides the same message for the same reason.
--
-- No latch, on purpose: the pass is idempotent (removing an absent field is a
-- no-op and the second load simply counts zero), so a once-per-save flag would
-- buy nothing and would be the one piece of persisted state this tool is not
-- allowed to have.
function OnMsg.PostLoadGame()
	if SMRSaveRescue.Vetoed(ID) then return end
	local ok, res = pcall(SMRSaveRescue.RunPass)
	if not ok then
		log("the clean pass failed: %s", tostring(res))
		return
	end

	if res.removed == 0 and res.heals.meteors == 0
			and res.heals.rains_restarted == 0 and res.heals.rains_finished == 0 then
		-- Silence is the correct answer for a save with nothing to clean —
		-- otherwise a player who keeps this mod installed gets a dialog on every
		-- single load, forever.
		if (res.stood_down.FP or res.stood_down.OP) and not stand_down_told then
			stand_down_told = true
			show("Save Rescue",
				"The Community Fix Pack (or its Opt-In Modules) is still installed, so there is nothing for this tool to do: while those mods are installed they clean up after themselves.\n\nUninstall them first, then load this save again.")
		end
		return
	end

	show("Save Rescue", report_text(res))
end
