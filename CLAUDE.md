# Save Rescue — Surviving Mars: Relaunched

A **cleaner**, not a fix pack: it removes named leftovers from a savegame the
Community Fix Pack mods are no longer installed in, and leaves nothing of its
own behind. Two files of code and a curated table.

**Read first, every session: `docs/PROVENANCE.md`** — where the list comes from,
the four bans, what was deliberately not copied from the sibling repos, and the
one load-bearing ordering rule in the pass.

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
⛔ Nothing in this repo has been run in a game yet.
