# Save Rescue — Surviving Mars: Relaunched

A one-shot cleanup tool for savegames that were played with the
**Community Fix Pack** or the **Community Fix Pack: Opt-In Modules** and then
lost them.

**Install it only AFTER you have uninstalled those mods.** Load your save once,
read what it says, and you can delete it again. While either of those mods is
still installed this tool deliberately does nothing — they clean up after
themselves, which is what makes this one unnecessary until they are gone.

## What it actually removes

Almost everything those mods leave in a save is inert once they are gone: a few
timestamps and flags nothing reads any more. One thing is not:

⭐ **A non-base Drone speed or carry dial keeps working forever.** The dial is
stored as one of the game's own modifiers under the mod's name, so with the mod
uninstalled your Drones keep the boost and nothing is left to take it off. That
is the reason this tool exists.

It also, for saves that lost an **older** build of the Fix Pack, restarts two
things onto the game's own machinery: a meteor timer that was left dead, and a
rain cycle still running the old mod's copy of the game's loop. Both cost one
re-roll of that timer, once, and the tool says so on screen when it does it.

## What it will not do

* **It never deletes a repair.** The Fix Pack repairs a real bug in the game's
  Large Wind Turbine tech buff, and that repair *lives in your save*. Removing
  it would bring the bug back permanently, with no mod left installed to redo
  it — so the tool keeps it, and tells you it kept it.
* **It removes only entries it can name.** There is no pattern matching and no
  guessing: the list is fixed, and a name that is not on it is left alone.
* **It writes nothing into your save.** No flags of its own, no saved variables,
  no background threads. Delete the mod and nothing of it remains — a save this
  tool has run on is a save with less in it, never more.
* **It never renames anything.** Names already inside savegames are contract.

## Where the list comes from

Not from a guess and not from a pattern sweep: from an item-by-item derivation
over the shipped code of both mods, reviewed adversarially before a line of this
was written. It lives in the Fix Pack's repository as
`docs/agent/reports/D13_EXPOSED_SET.md` — §2b is the inventory, §5 is the
keep/remove reasoning with a stated reason per entry, and §10 is the
specification this mod is built to. `docs/PROVENANCE.md` here records what came
from where.

## Status

**Pre-release 0.1.0 — built, and verified UNATTENDED in a running game
(2026-08-13; audit-sustained the same day).** A nine-launch matrix measured the
pass on a witness save carrying every removable entry: the automatic pass
removed **1617 entries by name**, kept both keep-list repairs, healed a dead
meteor timer and a legacy rain loop (both threads valid afterwards), removed
**0** on the second load, and a save cleaned by this mod then loaded *without*
it carried **zero** names of this mod's across 4510 objects and all 440
persistable globals. Zero Lua errors in any launch. Full record + archived
logs: the Fix Pack repo, `docs/agent/reports/D13_VERIFICATION.md` +
`docs/archive/rs_*` (verification), §5 there (audit).

✅ **The attended pass ran 2026-08-14, and the UI is witnessed.** On a save that
came by its leftovers honestly — no manufactured residue — the automatic pass
removed **1566 entries by name**, matching a prediction committed before the
first launch row for row, and kept the keep-list repair. The three readings no
log can hold were all watched on screen: the report dialog raised with text
matching the built function, a cleaned-then-saved save reloaded **silent** with
the mod still active beside it, and the stand-down notice raised exactly once
with the packs restored. The parent project granted **`tested`** — its strictest
tier, reserved for a keyboard pass. Full record: the Fix Pack repo,
`docs/agent/bugs/D13.md` + `docs/archive/cs_*` logs.

---

*Development repo. `docs/` and `.claude/` never ship — see `metadata.lua`'s
`ignore_files`.*
