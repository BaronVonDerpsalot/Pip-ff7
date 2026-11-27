# Story Room: hand-over pack (cross-account export, batch 1)

Built 27 Nov 2026. Live version `1795792205-d9d3` (edit over `1795368574-7020`).

## Why
Mike works from two accounts. When the account that owns the Story Room is out of quota for a few days, the other (mostly coding) account may need to pick up story work cold. The other account can't open or edit the artifact, so the route is: export a pack from the Story Room, the other account works from it, and changes come back as a return file that the Story Room imports.

## Agreed plan (Mike, 27 Nov)
1. One "Hand over" sheet: presets, live size meter, section chips, advanced options folded away. Built.
2. Handover pack: START-HERE, story brief, optional full story, data.json (+ schema in START-HERE), RETURN.md. Zip or one .md file. Built.
7. Agent oath: START-HERE asks the agent to repeat the three house rules back before touching anything. Built.
3. Fingerprint on every handover, three-way conflict card on import (yours / theirs / original). The fingerprint and per-field `from` values are in place; the import isn't built yet.
4. Swipe-to-review import on the phone: one card per change, canon and ids untouchable, accepted changes go into `claude_changes` so they can be undone. Not built yet.
5. "Since last handover" export (only what changed). Later.
6. Android share sheet straight into the Claude app (test whether the in-app webview accepts it; fall back to a download). Later.

## What was built
- Room page → Export: a "Hand over to another account" card at the top opens the sheet in `#overlay`.
- All page code, no `sample` calls, so it works with no quota left.
- Presets: Story work (brief + data), Coding agent (brief + data + visual specs), Light (brief only, canon and maybe), The lot. A preset shows as pressed when the current options match it.
- Game chips share `S.exp.game` with the Export section; the Export filter box (`S.q.export`) also narrows the pack. Advanced: record floor (everything / maybe and canon / canon only), settled questions, scene lines, inbox (all shared with `S.exp`), file format (zip / one .md).
- The note for the agent goes at the top of START-HERE.
- Meter: rough tokens (chars/4) with a bar, green under 60k, amber under 150k, red above. File list with sizes; tap a file to preview its first 6,000 characters.
- Download through `downloads.save` (zip as a Blob, a store-only zip written by hand, `hoZip`), falling back to clipboard copy, then to a select-all textarea.
- Options and the last handover (`{id, at, hash}`) are kept in localStorage `sr_ho`.

## Pack contents
- `START-HERE.md`: handover id `ho-YYYYMMDD-HHMM-<hash6>`, fingerprint (FNV-1a of `snapshot()` without `exported_at`), scope, Mike's note, the oath (three house rules: only Mike makes canon; ids are permanent; changes go back as a return file), what the series is, house rules (status, [[id]] links, shipped canon, reveal_from, claims, parked questions and deliberate gaps, in-jokes, lore voice), where things stand (games, released, the game being written now, counts, live/parked questions), contents table, coding-agent note, data model with field lists taken from the live data.
- `story-<game>.md`: `toBrief(game, sel, S.exp)`.
- `story-full-<game>.md` (optional): `toMarkdown(sel, S.exp)`.
- `data.json` (optional): `snapshot()` filtered to the selection, with `handover`, `fingerprint`, `made`; specs added when switched on.
- `RETURN.md`: format `story_room_return_v1`. `{based_on, fingerprint, by, summary, changes:[…]}`. Ops: `update` (fields as `{from, to}`, with `from` exactly as in the pack, which gives the import its three-way base), `create` (new id, brainstorm, data), `note` (anything not allowed: canon, deletes, renames). Types: entries, beats, scenes, loose, inbox. File name `story-return-<handover id>.json`, committed to `docs/story/returns/`.

## Code landmarks
Block "hand over: a pack another account's agent can pick up cold" just before `/* ---------- ask claude ---------- */`. `hoOpts`, `hoSave`, `hoSel`, `hoFingerprint`, `hoStart`, `hoReturn`, `hoData`, `hoBuild`, `hoSingle`, `hoZip`, `hoSheetHtml`, `hoRender`, `hoAct`, `hoEntryHtml`. Its own capture-phase click and input listeners on `[data-ho]` and `#ho-note`, separate from the main `data-act` dispatcher. CSS `.ho*` just before the `.sfield` media query. `exportHtml` calls `hoEntryHtml()`.

## Testing note
Tested outside the page: the block ran in Node with stubbed helpers (pack built, zip checked with Python's zipfile, data.json parses), and the sheet was screenshotted at 390px in light and dark with the app's base styles. It wasn't run inside the live page, because the full page wasn't pulled to disk, so the first real open on Mike's phone is the check.
