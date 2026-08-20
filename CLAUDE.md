# Save Rescue — Surviving Mars: Relaunched

A **cleaner**, not a fix pack: it removes named leftovers from a savegame the
Relaunched Fix Pack mods are no longer installed in, and leaves nothing of its
own behind. Two files of code and a curated table.

> ⭐ 2026-08-17: the family was renamed **Community Fix Pack → Relaunched Fix
> Pack** (owner ruling, fix-pack checklist 36); this repo's title, player
> strings and live surfaces are swept. Earlier records use the old name —
> translate mentally, do not edit records. Ids, globals and log tags are save
> contract and did NOT change.

**Read first, every session: `docs/PROVENANCE.md`** — where the list comes from,
the four bans, what was deliberately not copied from the sibling repos, and the
one load-bearing ordering rule in the pass.

## ⛔ LAUNCH GATE — this mod has no `items.lua`. Settle it BEFORE any upload.

Owner ruling 2026-08-20 (fix-pack checklist 48): **recorded here as a gate
rather than derived now**, because this mod is the held-in-reserve contingency
and is not publishing. ⛔ **Whoever launches it discharges this first.**

**The fact:** there is no `items.lua` in this repo — verified 2026-08-20 —
against `metadata.lua`'s 2-entry `code` list (`Code/00_Core.lua`,
`Code/10_SaveRescue.lua`). The opt-in pack was checked and is correct 9-for-9;
the fix pack was one entry short and would have shipped a fix that never loaded,
which is how the whole class was found (fix-pack checklist 46).

**Why it could matter:** the fix pack's records state that uploading forces the
Mod Editor to save, and that the save rebuilds `metadata.lua`'s `code` list from
the items file ALONE — never from the disk (`Mod.lua:816-840`, `:973`, and both
portals force that save on a first upload, Steam's BEFORE packing). If that is
what happens with the file entirely absent, this mod uploads with an empty code
list and does nothing at all.

⚠️ **BUT THAT CONSEQUENCE IS NOT DERIVED, and must not be repeated as if it
were.** Nobody has read what the engine does when the items file is *missing*
rather than *incomplete*. It may refuse to rebuild rather than rebuild empty,
which would be harmless. **Deriving that is the gate's work** — it is a read of
the source, not a guess, and it is short now that the path is confirmed:

```
A:\SteamLibrary\steamapps\common\Project Spark\ModTools\Src\CommonLua\Classes\Mod.lua
```

(⚠️ The Relaunched install dir is literally `Project Spark`; the old 2018
`Surviving Mars` folder has a `ModTools` with no `Src` and is a decoy —
fix-pack `docs/agent/facts/EF-014.md`, and it cost this session a detour.)

⇒ **Outcome required before upload:** either a derivation showing the absence is
harmless, recorded with its citations, **or** an `items.lua` written to match the
2-entry code list and re-verified after the forced save. Nothing else in this
repo is owed by this gate.

**The list is NOT edited here.** It is derived in the fix pack repo
(`C:\Dev\SMR-BugFixPack\docs\agent\reports\D13_EXPOSED_SET.md` — §2b inventory,
§5 keep/remove reasons, **§10 the frozen spec this mod is built to**). A missing
name is a gap in that derivation: fix it there first.

**The three things that will bite you:**

1. Every `SMRFixPack_*` literal is **save contract** — exact bytes, never
   renamed, including the five the Opt-In Modules mod writes.
2. **Nothing of this mod may enter a save** — no `GameVar`, no field write, no
   latch, no game-time thread of its own (spec §10.7 argues it clause by
   clause). If a change adds persisted state, it is the wrong change.
3. **Detection is by the curated table only** — never an `SMRFixPack_*` pattern
   match for removal. The single prefix match in the file is a read-only census
   for the report and is commented as such.

Parse sweep before any commit touching Lua (`luaparser`, every file). Owner
decisions go in the FIX PACK's `docs/PLAYTEST_CHECKLIST.md`, never here.
✅ **Verified UNATTENDED 2026-08-13** (nine-launch matrix, audit-sustained:
removed 1617 by name / kept both KEEPs / idempotent / residue-zero measured;
record: fix-pack `docs/agent/reports/D13_VERIFICATION.md` + `archive/rs_*`).
✅ **`tested` GRANTED 2026-08-14** — the attended sitting witnessed all three
dialog readings on screen (report dialog, silent reload, stand-down notice;
record: fix-pack `docs/agent/bugs/D13.md` + `archive/cs_*`). *(This line
previously said the attended pass was still owed — stale since 08-14, corrected
2026-08-17.)* ⚠️ The dialog STRINGS were renamed 2026-08-17 (family rename);
if this contingency ever publishes, the item-28 pre-upload re-witness launch
covers the changed text.
