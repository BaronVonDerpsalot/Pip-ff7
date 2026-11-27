# Story Room twin: working on the story from the other account

The Story Room artifact belongs to one account, and the other account can't open or edit it. When Mike needs to work on the story from the other account (for example, the owning account is out of quota for a few days), that account runs a **twin**: its own copy of the app, loaded from a handover pack. Changes made in the twin go back to the original as a return file, which Mike reviews and imports there.

One copy is live at a time. While the twin is in use, don't write in the original; send the twin's changes back before carrying on there. If both get edited anyway, the import marks every clash and asks which to keep.

## Making the twin (once per account)

1. Publish the app as a new artifact on this account. The page is `tools/story_room/index.html` in this repo, or `app/index.html` from the newest handover pack if that's newer (the pack's copy is always the version the original was running). Title it "Story Room (twin)".
2. Declare its capabilities, after publishing, exactly as the original has them:
   ```json
   {"assets":{},"db":{"rules":[{"path":"","read":"owner","write":"owner"},{"path":"shared_entries","read":"view","write":"owner"},{"path":"ideas","read":"admin","write":"admin"},{"path":"requests","read":"admin","write":"admin"}]},"downloads":{},"sample":{},"user":{}}
   ```
3. Don't share the twin with anyone. Christine's spoiler-free view belongs to the original; the twin never writes to it.

When the original's app changes, republish the twin from the newer `app/index.html` (its data is kept).

## The round trip

1. **Original account:** Room → Export → Hand over… → Download .zip. The defaults are right (brief, data.json, the app). Give the zip to the other account: leave it in a folder on the PC, or attach it to the chat.
2. **Twin:** Room → Twin → Load a handover… → pick the zip (or its `data.json`, or the one-file .md). A handover loads only into an empty room or an existing twin, never into a room that has a story of its own, so the original can't be overwritten by mistake. Loading a newer handover into a twin replaces everything in it and warns first if changes haven't been sent back.
3. **Twin:** work as normal. Every page shows a "Twin" banner. The Write tab, roleplay and Claude drafting run on this account's quota.
4. **Twin:** Room → Twin → Send changes back. It compares the room with the handover it was loaded from and saves `story-return-<handover id>.json` (or copies it). Commit it to `docs/story/returns/`, or hand the file over directly.
5. **Original account:** Room → Bring changes back → Open a return file… (or Paste one). Each change is a card. Clean ones start accepted; anything Mike changed in the original since the handover shows was / yours now / from the twin, and waits for a pick. Apply takes two taps, and the whole import is one entry in the Inbox's change list, so Undo takes it all back out.
6. Next time, start from a fresh handover (step 1). Don't keep writing in the old twin.

## What comes back, and what doesn't

Comes back: games (spine, parked items, notes), entries, beats, scenes and their lines, loose ends, inbox notes. New records, changed fields and deletions.

Stays in the twin: roleplay sessions, the pitch shelf, the twin's own change log, visual specs (loaded for reference only), renamed ids, settings. If any of these matter, redo them in the original by hand.

From a twin, Mike's own edits come back as his, canon included. From an agent's return file (one written by hand from a pack's RETURN.md), canon records and deletions are locked, and a new record asking to be canon comes in as brainstorm.

## How it works (for whoever builds next)

- Block "bring changes back (import) and twin mode" just before `/* ---------- ask claude ---------- */`. `twinBoot`, `imReadFile` / `imUnzip` / `imParseText`, `imBuild`, `imCardHtml`, `viewImport` (route `#import`), `imApply`, `twinLoad`, `twinDiff`, `twinSend`, `imRoomHtml` (Room page, after Export), `twinBannerHtml` (prepended in `render()`), `imAct` (all `data-im` actions; own capture-phase listeners, plus a swipe handler on `.imcard`).
- Collections: `twin/meta` `{handover, fingerprint, made, loaded, sent, records}` marks a room as a twin; `twin_base/<type>__<id>` `{type, id, rec}` holds the handover's records to diff against. Both are covered by the default owner-only rule.
- Return format `story_room_return_v1`: `{source:"twin"|absent, based_on, fingerprint, by, summary, changes:[{op:"update", type, id, fields:{k:{from,to}}} | {op:"create", type, id, data} | {op:"delete", type, id, from} | {op:"note", about, text}]}`. A field set to null means "remove it". `created`, `updated` and `edited_by` are never compared.
- A clash is a field whose current value matches neither `from` nor `to`. Picks default to "Keep yours".
- `queueShareSync` does nothing in a twin.
- Tested in Playwright with two mock rooms (36 checks): the real 27 Nov pack loaded into an empty twin, edits there (a body, a canon record's tags, a new loose end, a deleted one, a game's spine), send back, a clashing edit in the original, the import with "take theirs", undo of the whole import, an agent's file pasted inside a chat reply (canon edit and delete locked, canon create demoted, note to inbox, missing id locked), and the original refusing to load a pack. Screenshots at 390px, light and dark.
