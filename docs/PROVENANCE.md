# PROVENANCE — what came from where, and what this repo may not decide alone

This mod is the third repo of the Community Fix Pack family and by far the
smallest. It exists to answer a question the other two cannot: **what happens to
a savegame after those mods are uninstalled.** Everything below is here so a
future session does not have to re-derive it — and so it cannot silently drift
from the two repos that own the facts.

## 1. Where it was built, and from what

| | |
|---|---|
| built | 2026-08-13, chain `d13-rescue` prompt 3 (`03_OPUS_BUILD.md`), in the Community Fix Pack repo |
| against | fix pack `cdbcd9d` · opt-in pack `e17586b` · TestKit `62f03da` (all three clean at build time) |
| spec | **`docs/agent/reports/D13_EXPOSED_SET.md` §10** in `C:\Dev\SMR-BugFixPack` — the frozen build contract |
| list | the same report, §2b (the inventory) and §5 (KEEP/REMOVE with a reason per name) |
| review | the derivation was re-derived independently and adversarially before the build (chain prompt 2, verdict BUILD with must-fixes, all applied) |
| owner rulings | display name / mod id / log tag ratified 2026-08-13; the public remote was pre-created by the owner; "the packs are their own cleaner, this tool serves only the already-uninstalled" is the owner's ruling, not a design preference (checklist items 17/18) |
| ⛔ measured? | **NO.** Nothing here has been run in a game. Every claim in the code comments is derived from the game's shipped Lua. |

## 2. ⛔ The bans

1. **PERSISTED NAMES ARE SAVE CONTRACT.** Every `SMRFixPack_*` string in
   `Code/10_SaveRescue.lua` is a literal that exists in players' savegames. They
   may not be renamed, reformatted, or "tidied" to match this mod's namespace —
   including the five that the Opt-In Modules mod writes, which kept the fix
   pack's prefix through the 2026-08-12 split for exactly this reason.
2. **NOTHING OF THIS MOD MAY ENTER A SAVE.** No `GameVar` call, no field write,
   no modifier id, no persisted global, no game-time thread of its own, no
   latch. The full argument, clause by clause with its mechanism, is spec §10.7.
   If a change would add persisted state, it is the wrong change.
3. **DETECTION IS BY THE CURATED TABLE ONLY.** Never a `SMRFixPack_*` pattern
   match for removal. A 2026-07-31 pattern sweep in the fix pack false-positived
   on 192 buildings, twice — and a pattern sweep here would delete the F35
   turbine modifiers, which ARE a repair. The one prefix match in the file is a
   read-only census for the report and is marked as such.
4. **THE LIST IS NOT EDITED HERE.** It is derived in the fix pack's report. A
   name that turns out to be missing is a gap in that derivation: fix it there,
   then mirror it here in the same effort.

## 3. Names and ids (contract, not display)

| thing | value | changeable? |
|---|---|---|
| mod id | `SMR_CommunitySaveRescue` | ⛔ no — it is what the engine and savegames record |
| global namespace | `SMRSaveRescue` | ⛔ no |
| veto global | `SMRSaveRescue_Disabled` | ⛔ no (probes and the console use it) |
| log tag | `[CommunitySaveRescue]` | ⛔ no — owner's log greps use it |
| display title | "Save Rescue" | ⚠️ owner-ratified 2026-08-13; the release-prep pass owns any change. ⚠️ Note the sibling mod took a family prefix the same day ("Community Fix Pack: Opt-In Modules") — if the family should be visually consistent in mod lists, this is the title that would move, and it is an owner call |
| repo folder | `C:\Dev\SMR-CommunitySaveRescue` | aligned to the remote the owner pre-created |
| remote | `github.com/catt144/SMR-CommunitySaveRescue` (PUBLIC) | owner-created |

## 4. What was deliberately NOT copied from the other two repos

The opt-in pack's split carried a whole apparatus across. This mod is a
single-purpose tool and takes almost none of it, on purpose — every one of these
absences is a decision, not an omission:

| not here | why |
|---|---|
| Mod Options page / `default_options` / `optional` machinery / `ApplyModOptions` | nothing to toggle. The tool either has work to do or it does not |
| `DataPatch` / `OnDataReady` / `ClassesBuilt` scaffolding | it patches no shipped code and constructs no presets |
| the update-suspect report (`UpdateSuspects` + its dialog) | that surface exists to tell a player that fixes switched themselves off after a game patch. This mod has no fixes to switch off; a missing API is one log line and a skipped step |
| `WhenActive` wrapper family | one module, no wrappers installed anywhere |
| `bugs/` + `facts/` indexes, `doccheck.py`, `tools/`, `STATE.md`, `WORKFLOW.md` | its findings belong in the fix pack's records, which is where the derivation, the entry (`D13`) and the engine facts already live. A second set of indexes would be a second thing to keep true |
| its own `PLAYTEST_CHECKLIST.md` | owner decisions are single-sourced in the fix pack's checklist |

**Kept:** MIT `LICENSE` (same terms, same author), `.gitignore`, the logger's
`%%` escaping (`ModLog`'s output path formats its argument a second time), the
declarative `Require` self-check shape, and the `PostLoadGame`-not-`LoadGame`
rule — that one is load-bearing: the game's own savegame fixups must have run
before anything judges the save.

## 5. The one thing to read before changing the pass

`Code/10_SaveRescue.lua`'s step order has exactly one load-bearing dependency:
**the rain heal (step 1) reads `SMRFixPack_fixed_loop`, and step 4 removes it.**
That is not incidental tidiness — consuming its own detector is what makes the
heal one-shot without a latch, and a latch is the one piece of persisted state
this mod is not allowed to have. Reordering those two steps would either make
the heal re-fire on every load (re-rolling the player's rain timer forever) or
require a stamp that breaks ban 2.
