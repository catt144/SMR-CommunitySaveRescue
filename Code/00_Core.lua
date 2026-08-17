-- Save Rescue — core.
--
-- ⛔ READ THIS FIRST. This mod is a CLEANER, not a fix pack. Its whole contract
-- is that it removes named leftovers from a savegame and leaves NOTHING of its
-- own behind (the "6d" bar of the derivation that specced it —
-- `docs/agent/reports/D13_EXPOSED_SET.md` §10 in the Relaunched Fix Pack repo,
-- summarised in docs/PROVENANCE.md). Concretely, and these are bans:
--   * it NEVER calls GameVar. Not even to reach a value: registering a name in
--     order to clean it would persist that name as OUR residue.
--   * it NEVER writes a field, a modifier or a global into the save. Every
--     mutation it makes is `= nil` or a vanilla removal call.
--   * it creates NO game-time thread of its own. The two thread heals recreate
--     VANILLA's bodies through vanilla's own primitives; the player report
--     rides a REAL-TIME thread, which the engine persists only when flagged
--     `threadPersist` (persist.lua:128-131) and nothing here flags one.
--   * it has NO Mod Options page, no toggles, no `optional` machinery.
--
-- This file is deliberately a fraction of the fix pack's 00_Core: a registry, a
-- logger, and the declarative self-check helper. Everything else that core
-- carries (Mod Options reconciliation, the DataPatch/OnDataReady scaffolds, the
-- update-suspect report) exists for a pack of 74 modules that patch shipped
-- code. This mod patches nothing.

-- Pre-load veto surface for the console, a probe, or another mod. Accepts
-- either form:  SMRSaveRescue_Disabled = true          (whole mod)
--               SMRSaveRescue_Disabled = { SaveRescue = true }   (by id)
-- ⚠️ This is a plain mod-created global, NOT save state: names enter a savegame
-- only through PersistableGlobals (persist.lua:117-134) and this one is not in
-- it — the same proof that clears the packs' own `_Disabled` tables.
SMRSaveRescue_Disabled = rawget(_G, "SMRSaveRescue_Disabled") or {}

SMRSaveRescue = rawget(_G, "SMRSaveRescue") or {
	modules = {},   -- id -> { title, status, detail }
	order = {},     -- registration order
}

-- The one true logger. The log tag is contract (owner-ratified 2026-08-13) and
-- is what an owner's log grep looks for.
function SMRSaveRescue.Log(fmt, ...)
	local msg = string.format("[CommunitySaveRescue] " .. fmt, ...)
	-- ModLog stores the message unformatted, but its ModPrint output path is a
	-- printf-style CreatePrint (Mod.lua:109-132, lib.lua:164-174) that formats
	-- the single argument AGAIN — a literal '%' in an already-formatted message
	-- raises "bad argument #2" there. Escape it for the second pass.
	if rawget(_G, "ModLog") then ModLog((msg:gsub("%%", "%%%%"))) else print(msg) end
end
local log = SMRSaveRescue.Log

-- Is the mod (or one module) vetoed?
function SMRSaveRescue.Vetoed(id)
	local d = rawget(_G, "SMRSaveRescue_Disabled")
	if d == true then return true end
	return type(d) == "table" and id ~= nil and d[id] and true or false
end

-- Mod version string ("major.minor.revision"), read from the loaded ModDef —
-- metadata.lua stays the single source. Returns false when the registry is not
-- readable; callers LOG the version, they never branch on it (this tool cannot
-- and must not key its behaviour on a version — see the spec's §10.6).
function SMRSaveRescue.ModVersion()
	local mods = rawget(_G, "Mods")
	local def = type(mods) == "table" and mods["SMR_CommunitySaveRescue"]
	if type(def) ~= "table" then return false end
	return tostring(def.version_major or 0) .. "." .. tostring(def.version_minor or 0)
		.. "." .. tostring(def.version or 0)
end

-- Declarative preflight checker, the fix pack's shape minus the parts a
-- one-module mod cannot use. `spec` is a LIST of checks evaluated in order; the
-- FIRST failure returns its reason string, nil when everything passes.
--
--   { global = "Name" }                    -- rawget(_G, Name) is a function
--   { global = "Name", kind = "table" }    -- ... is a table ("any" = not nil)
--   { class = "LabelContainer", method = "SetLabelModifier" }
--   { test = function() return truthy end, reason = "..." }
--
-- ⚠️ Pre-flattening rule (the fix pack's F64 lesson): mod code runs before
-- class flattening, so a class global is a plain classdef exposing only members
-- it declares ITSELF. Every `class`/`method` pair used here must therefore name
-- the DECLARING class — `LabelContainer` declares SetLabelModifier at
-- LabelContainer.lua:59. The pack's core carries an ancestor-walk diagnostic
-- for authors who get that wrong; with exactly one such check in this mod,
-- hand-verified, the walk would be scaffolding for its own sake.
function SMRSaveRescue.Require(spec)
	for _, c in ipairs(spec) do
		local ok, name
		if c.test then
			ok = c.test()
			name = "(custom check)"
		elseif c.global then
			local v = rawget(_G, c.global)
			local kind = c.kind or "function"
			ok = (kind == "any") and v ~= nil or type(v) == kind
			name = c.global
		elseif c.class and c.method then
			local C = rawget(_G, c.class)
			ok = type(C) == "table" and type(C[c.method]) == "function"
			name = c.class .. "." .. c.method
		elseif c.class then
			ok = type(rawget(_G, c.class)) == "table"
			name = c.class
		end
		if not ok then
			return c.reason or (name .. " not found (game update changed it?)")
		end
	end
end

-- Register a module and run its apply immediately. apply() returns nil on
-- success or a STRING explaining why it stood down — never an error
-- (FIX_POLICY §2: fail-safe, never loud).
function SMRSaveRescue.Register(id, def)
	local entry = { title = def.title, status = "pending", detail = "" }
	SMRSaveRescue.modules[id] = entry
	SMRSaveRescue.order[#SMRSaveRescue.order + 1] = id

	if SMRSaveRescue.Vetoed(id) then
		entry.status = "disabled"
		log("%s: disabled by user/mod setting", id)
		return
	end

	local ok, res = pcall(def.apply)
	if not ok then
		entry.status = "error"
		entry.detail = tostring(res)
		log("%s: FAILED to apply: %s", id, tostring(res))
	elseif type(res) == "string" then
		entry.status = "inactive"
		entry.detail = res
		log("%s: inactive (%s)", id, res)
	else
		entry.status = "active"
		entry.detail = ""
		log("%s: ready", id)
	end
end

function SMRSaveRescue.IsActive(id)
	local m = SMRSaveRescue.modules[id]
	return m ~= nil and m.status == "active"
end

-- Console helper: what is loaded and what state is it in.
function SMRSaveRescue.List()
	log("Save Rescue %s", tostring(SMRSaveRescue.ModVersion() or "version unreadable"))
	for _, id in ipairs(SMRSaveRescue.order) do
		local m = SMRSaveRescue.modules[id]
		local detail = m.detail or ""
		log("%s [%s] %s%s", id, m.status, m.title, detail ~= "" and (" — " .. detail) or "")
	end
end
