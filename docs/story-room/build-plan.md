# Story Room build plan and handover

Last updated: 19 Nov 2026

## Where things stand

The Story Room is the artifact titled "Story Room" (slug `33b2ae54-843a-4414-acb0-6c4694fb84a4`). It is a single index.html of about 4,900 lines, data in the artifact's own database. Live version after the export work: `1795110759-fb80`.

Mike agreed a feature plan on 14 Nov 2026, taking inspiration from articy:draft X (features only, personal use). Items 1, 2 and 3 are built and live, plus two extras (3b, agreed 17 Nov; 3c, agreed 19 Nov).

## The plan, in order

1. **Story map (nested flow view).** DONE 14 Nov. Beats tab, "Story map" view. Series > game > beat > scene, dashed slots for anything missing, a "next gap" banner for the next unreleased game.
2. **Script room: write and read.** DONE 14 Nov. See "Script room" below.
3. **Script room: roleplay.** DONE 14 Nov. See "Roleplay" below.
3b. **Tell it back: answer gaps in place.** DONE 17 Nov (Mike's idea from an artifact comment; he agreed it goes before flags). See "Gap cards" below.
3c. **Export filter, brief layout, live briefs.** DONE 19 Nov, for voice sessions. See "Export and live briefs" below.
4. **Story state flags plus conditional lines.** NEXT. Smaller than first thought: scene lines already have free-text `cond` ("only if") and `sets` fields. What is missing is a real flag ledger with stable ids that beats and lines refer to.
5. **Playthrough checking.** Folded into read mode: walk a game in order, track flags, report things used before they are set. The table read already chains scene to scene within a game ("Next: …" on the end card), so this extends `viewRead`.
6. **Export with engine templates.** One neutral export format with stable ids, then a thin template per engine. Godot and Phaser now; must stay open to more engines.
7. **Later:** dependency chains (beats already have `requires` and `leads_to`, plus a flow graph with loop detection), change history (a `claude_changes` log with undo already exists).

## Export and live briefs (item 3c, built 19 Nov)

Why: Mike runs story sessions in voice mode. The raw collections are noisy for that (ids, versions, gloss arrays, change-log copies), and the old story.md was every game at once.

- **Export section** (Room page, `exportHtml`): game chips (All, Series, each game; defaults to the next unreleased game), the Bible's filter box (`filterBox("export")`, same syntax, `S.q.export`), Layout Brief/Full, toggles for settled questions (closed loose ends), scene lines and inbox. Options live in `S.exp`, saved in localStorage `sr_exp`. Download names: `brief-pip-2.md`, `story-pip-2.md`; story.json stays the full unfiltered snapshot.
- **Scope** (`expSel(game, filter)`): a game's own records, plus series-wide records one hop away in either direction (links via `linksOf`, plus scene speakers), plus every canon series `rule_*` entry. Then the filter narrows it with `matchRec`. `null` means everything.
- **Brief layout** (`toBrief(gid, sel, o)`): header with how to read it (status marks, ids for mapping back, B/Q numbers, parked etiquette, "rules records that say not to reveal something stay that way"), spine, Rules and lore first, beats in story order as B1… with scenes and lines, open questions as Q1… (open loose ends not parked, then unfinished readiness items), Parked (parked loose ends, parked readiness items, `gap_parked`), Already settled (closed loose ends with resolutions), Cast, places and the rest by kind, optional inbox. Links become names (`plainSnip`). No volatile timestamps in the text: the header date is the latest `updated` of the records covered, so the text only changes when the story does.
- **Full layout**: `toMarkdown(sel, o)` now takes the same selection and options.
- **Live briefs**: collection `briefs`, one doc per game (not series): `{game, name, text, chars, generated, layout:"brief", about}`. Written by the owner's app only (`briefReady`: owner, not preview, not read-only, all collections loaded), debounced 4s after any data snapshot (`queueBriefSync` is called next to `queueShareSync`), and only when the text differs, so no churn. Default owner-only db rule covers it; guests never subscribe or write (verified in test). "Rewrite now" on the Export section forces a check.
- Catch: briefs only refresh while Mike has the app open. Records Claude writes straight into the database (as on 19 Nov) show up in the brief the next time he opens the room.
- How a chat uses it: `db_get` on `briefs/pip_2` in this artifact and read `text`. For voice, either read it in text first in the same chat, or download brief.md and add it to the project.
- Code landmarks: block "export scope, the brief layout, live briefs" just before `/* ---------- ask claude ---------- */`. `expOpts`, `expSel`, `expSummary`, `exportHtml`, `expAct` (all `exp-*` actions, called first from `extraAct`), `toBrief`, `syncBriefs`, `briefFor`. `filterRefresh` calls `expRefresh` for the export box.

## Script room (item 2, built 14 Nov)

Two routes, both owner-only (guests render through `renderGuest`, which never reaches them):

- `#script-<scene>`: write mode. Screenplay layout (speaker name centred in caps with a per-speaker colour, dialogue in a centred column, narration italic full width, `cond` as a parenthetical, `sets` and an over-140-character warning under the line). Sticky composer at the bottom: speaker chips (cast of the scene, Pip, Narration, "Someone else…" select), a textarea, Add. Enter adds the line (also caught through `beforeinput` for phone keyboards; Shift+Enter is a newline). Typing `pip:` / `firefly:` / `n:` at the start of a line switches speaker. After each line the speaker flips back to whoever spoke before, for dialogue ping-pong. Tap a line to edit it in place (speaker, text, flags, move, add below, delete with a second tap); the composer hides while editing. Canon scenes show the lock bar and no composer. Bottom tabs are hidden on this route. Header has ▶ Read and 🎭 Play.
- `#read-<scene>`: table read. Title card (game, beat, place, cast), then one line at a time in a game-style text box with the last three lines above for context. Tap to advance, tap the left edge (28%) to go back; arrow keys and space on desktop. ✎ jumps to write mode with that line open in the editor. End card: next scene in the same game, read again, edit, done. Top bar and tabs hidden.
- Entry points: the scene record page ("Open/Write the script", "▶ Table read", "🎭 Roleplay"), and "▶ Read" / "🎭 Play" in write mode.

Code landmarks: block "script room" just before the gap-cards and roleplay blocks. `viewScript`, `scLinesHtml`, `scComposerHtml`, `scRefresh` (updates the page, chips and draft bar without touching the textarea when data arrives), `scAdd`, `scEditSave`, `scMove`, `scDelete`, `scSave` (optimistic local write, then `put`), `scDraftBar`, `viewRead`, `rdStep`, `rdNextScene`, `scriptAct` (all `sc-*` and `rd-*` actions except the older `rd-park`, `rd-interview`, `rd-tellback`, `rd-brain`; called first from `extraAct`). State in `S.sc` (reset when leaving a script route) and `S.rd`. Body classes `scripting` (script and play routes) and `reading` set in `render()`.

Line keys: edits find lines by `k`. Lines that never had one get a temporary `i<index>` key in memory, replaced by a real `lineKey()` on the first save from the script room (`S.scRemap` keeps scrolling pointed at the right line).

Writes from the script room are Mike's own, so they go straight through `put`, not `commit`, and do not change the scene's status.

## Roleplay (item 3, built 14 Nov)

Mike's design choices (asked before building): Mike picks one character, Claude plays **everyone else** in the scene plus short narration; the roleplay **continues the scene** (picks up after the last line by default, or after a line he chooses, or from the top); kept lines land in the scene with a **per-line draft mark**.

- Route `#play-<scene>`, owner-only (guest path never reaches it). Uses the script room's screenplay layout and sticky composer; tabs hidden (body class `scripting`).
- **Setup** (no session yet): "You play" chips (suggested cast: scene speakers + characters the scene/beat mention + Pip, plus "Someone else…"), "Claude plays" toggle chips plus "Add someone…", "Picks up" select, optional note for the take, Start. "New take" remembers the last setup in `S.pl.lastSetup`.
- **Play**: "In the script so far" (last 3 context lines, faded, tap to show earlier), then the roleplay. Composer chips: Mike's character, Narration, 🎬 Direction. Typing `(…)`, `[…]` or `ooc:` also makes a direction (steers Claude, not dialogue, can't be kept). `n:` / `firefly:` prefixes work as in the script room. Send button reads "Go on" when empty: Claude carries on or opens the scene. Stop while streaming. Each line has a ☆ keep button (46px); tap the line to edit/delete it. "↻ Another take" replaces Claude's last reply (two taps if it had a ★). "New take…" (two taps) discards the session.
- **Drop**: "★ N → script" chip opens a sheet: where (at the end, at the very start, after any line; defaults to where the take started if that wasn't the end), "Drop them in". Lines go into the scene via `scSave` with `draft:"roleplay"`; session lines get `dropped:true, into:<new key>` (shown ✓ "in the script", and excluded from the take's context). Canon locked scenes show Unlock first. Nothing reaches the scene without this tap.
- **Draft lines in the script**: dashed outline and "draft from roleplay" tag; editor shows "Keep as written" (clears the mark); saving a changed text or speaker also clears it; a bar above the page offers "Keep all" (two taps). Table read shows a "draft from roleplay" flag; record page shows "draft"; `sceneLineText` (what the Write tab sends Claude) adds "[draft from roleplay, not approved]"; Markdown export adds "draft". The old form editor (Edit) preserves the mark. Drafts do not change scene status; canon is still only set by Mike.
- **Claude's knowledge**: one stateless `S.sample` call per turn (`plPrompt`), not the story bible dump. Contains: scene title/notes, beat record, place record, Mike's take note, each Claude character's full record plus up to 8 things that record mentions (short), Mike's character's record framed as writer background only, the script so far (up to the pick-up point), the improv so far, rules (never speak/act for Mike's character, ≤140 chars per line, 1–3 lines a turn, character only knows record/beat/place/what's been said, no new named characters, no big lore). Output is `id: text` / `N: text` lines, parsed by `plParse` (resolves ids or names, drops any line for Mike's character, joins unprefixed text onto the previous line). Model follows the Write tab's model pick; "auto" means the default tier; `cache:false`.
- **Storage**: collection `roleplays`, doc id = scene id: `{scene, you, them[], after (scene line key, "" = from the top), note, lines:[{k,speaker,text,by:"mike"|"claude"|"dir",keep?,dropped?,into?}], created, updated}`. Covered by the default owner-only db rule; no capability change was needed. Subscribed in `boot` only when `S.mode==="owner"` (guests never subscribe; verified in test). Sessions survive closing the app: reopening the scene resumes it (record page button reads "Back to the roleplay").
- Code landmarks: block "roleplay" just before `/* ---------- actions ---------- */`. `viewPlay`, `plSetupHtml`, `plLinesHtml`, `plLineHtml`, `plComposerHtml`, `plDropHtml`, `plRefresh` (data refresh without touching the textarea), `plPrompt`, `plParse`, `plRun` (stream, abort, errors; state in `S.plRun`, survives leaving the route), `plSend`, `plDrop`, `plSave`, `plDiscard`, `playAct` (all `pl-*` actions, called from `extraAct`). UI state in `S.pl` (reset when leaving a play route). Setup inputs carry `data-fresh` so `restoreInputs` doesn't carry values between scenes.
- Not done, possible later: speaking NPC lines aloud (the `tts` capability exists), dictation for Mike's lines (`dictation` capability), a scene-alias rename doesn't move a roleplay session to the new scene id.

## Gap cards in Tell it back (item 3b, built 17 Nov)

Mike's choices: an answer goes **straight onto the record the gap is about**, marked as his words, falling back to the inbox when no record fits; built before flags.

- Tell it back's prompt (`tellbackTask`) now asks for `[GAP @record_id: question | question]`: the record the answer belongs on (usually the beat where the hole bites), one question per `|`, names not [[links]] inside. Older answers in the `[GAP: …]` form still work: points are split on `?` and `;`, no target.
- `gapRender` (used by `viewAsk` for every turn that isn't streaming) swaps each marker for a card in place: one row per question, each with a textarea, a "Goes on" select (the suggested record, the game's beats, the game's own notes, or Inbox), and Save / Finding it as I go / Skip. Cards are `span`s styled as blocks so they can sit inside paragraphs and list items.
- **Save** appends `Mike’s answer: … (to the gap “…”)` to the record's body (or the game's `note`), or adds an inbox item `Gap: … / My answer: …` (`source:"gap"`). Written with `put`, since these are Mike's own words; not undoable from the card (edit the record instead). Locked canon records are written too, on purpose: it's his answer.
- **Finding it as I go** adds `{q, at}` to the game record's `gap_parked`; `gapParkedRule` feeds that list into the next Tell it back, which writes `[PARKED: label]` (shown as a grey chip) instead of raising it again. Undo removes it.
- **Skip** only hides the row for that telling. Undo brings it back.
- Row state lives on the thread turn as `t.gaps["<gap>.<point>"]`, saved with the thread in localStorage (`loadThread` keeps it).
- A footer counts settled/open and offers "▶ Tell it back again with my answers" (`gap-again`), which runs a fresh Tell it back for the same game. The prompt tells Claude to treat "Mike’s answer:" lines as fact even on brainstorm or maybe records.
- Code landmarks: block "tell it back: answer the gaps where they sit" before the roleplay block. `gapScan` (balanced-bracket parse), `gapPoints`, `gapGame`, `gapTargets`, `gapCardHtml`, `gapRender`, `gapAnswerText`, `gapAct` (all `gap-*` actions, called from `extraAct`); `gapParkedRule` next to `tellbackTask`.
- Not done: the interview mode doesn't read `gap_parked` yet. If a released game's beat gets an answer, the "Mike’s answer" line is part of the body Christine's view would receive if that beat is shared.

## Decisions and rules

- Canon is only ever set by Mike. Claude-written content lands as brainstorm (or, for roleplay lines, as draft-marked lines Mike chose to drop in).
- Stable snake_case ids, never renamed (an alias system exists for renames).
- Phone-first: Android Claude app, often used in bed. Keep taps few and text large.
- Christine's spoiler-free guest view must hold for every new feature. Guests render through a separate path (`renderGuest`), so owner-only views are safe by default; anything shown to guests must go through the shared/sealed data. Scene lines never go to guests (only record bodies are shared).
- Mike's actual problem is getting the story written, not getting it into the engine. Order work accordingly.
- Mike writes by discovery: he does not have Pip 2's ending yet and expects to find it as he goes. The room must never treat an undecided ending as being behind. New features that list gaps or ask questions have to respect parked items (see below).
- Left out on purpose: an "area" nesting level in the story map. Beats show their place as a tag; grouping by place would scramble story order.
- Mike prefers to discuss design in chat rather than in artifact comment threads ("in artifact is clunky").
- Story sessions: Mike likes doing them in voice. The loop is: read the live brief, talk, get a write-up doc at the end, then a text chat applies it to the records (as on 19 Nov), with the change list shown first for veto by number.

## Parking ("finding it as I go")

Added 14 Nov. Any readiness checklist item except loose ends can be parked from the story map or the spine view. Stored on the game record as `parked: {key: true}` using the readiness keys (`logline`, `want`, `threat`, `joy`, `ending`, `handoff`, `middle`, `role_opening`, `role_climax`, `role_ending`). `readiness()` marks each item `parked` and returns `parkedN`. Parked items drop out of `mapGaps`, the next-gap banner and the interview prompt, and show as a solid "finding it as you go" marker. Parking the ending beat also parks the ending image; hand-off stays open on purpose, and the next game's slot says it is waiting on the ending. An item that gets filled in stops counting as parked by itself. Free-text gaps parked from Tell it back live separately in the game's `gap_parked` (see "Gap cards"). Loose ends park by `needed_by` ("later" or a later game).

## What already existed (do not rebuild)

Beats with roles (opening, climax, ending, stinger), order, `requires`, `leads_to`; scenes attached to beats with speaker lines; spine fields and an 11-item readiness checklist per game; flow graph; place tree; loose ends with "needed by"; in-joke stubs ("needs explaining"); Christine's ideas and requests; pitch shelf; health check; Markdown export (now filterable, with a Brief layout and live briefs); a Write tab that calls Claude (brainstorm, interview, tell it back with gap cards, map an arc) with tools that write records; the script room (write + table read + roleplay).

## Code landmarks

- Views are functions returning HTML strings: `viewBeats`, `viewBible`, `viewRecord`, `viewAsk`, `viewScript`, `viewRead`, `viewPlay`, `viewMore` (Room page, includes `exportHtml`). `render()` picks by `S.route`.
- Beats tab modes live in `S.beatsMode` (map, spine, list, graph, scenes); menu entries in `tabMenuItems`.
- Clicks: one delegated handler on `data-act`; newer actions go in `extraAct` (export in `expAct`, script room actions in `scriptAct`, roleplay in `playAct`, gap cards in `gapAct`).
- Story map code: `mapHtml`, `mapGameHtml`, `mapGameBody`, `mapBeatHtml`, `mapSceneRow`, `mapGaps`, `parkBtn`, `mapParked`; action `rd-park`.
- Scenes: `sceneBodyHtml` (read view on the record page), `lineEditorHtml` (the old form editor, still used by Edit), `draftScene` and `draftSceneForBeat` (write lines with Claude).
- Writes go through `put(type,id,data)`; Claude-made changes through `commit(ops,label)` so they can be undone. Roleplay sessions write directly to the `roleplays` collection (`plSave`), and live briefs to `briefs` (`syncBriefs`), both outside `COL`.
- Record bodies render through `glossMark`, which does not do Markdown bold; keep text written into bodies plain.

## Practical notes for whoever builds next

- `read_artifact` saves an oversized result to a JSON file (array of 4 text blocks; the document is the third block, index 2, wrapped in an `untrusted-document-…` tag). Strip the tag and you have the real page.
- `read_file` and `list_files` refuse on this artifact; `publish_files` with slug, base_version and `index.html` from disk works.
- Test in Playwright with a mock `window.claude.use("db"|"user"|"sample")` (Firestore-like `collection().doc().set()/delete()` and `onSnapshot`; a `sample` function that streams through `onText` and honours `signal`) and sample data shaped like the real collections, then screenshot at 390px wide in light and dark before publishing. Block the Google Fonts requests in the test. Chromium is at /opt/pw-browsers (set `PLAYWRIGHT_BROWSERS_PATH`). To test the Write tab, seed `localStorage.sr_ask` with a thread, guarded by a flag kept in localStorage (a sessionStorage flag doesn't reliably survive reloads in the harness).
- Writing records straight into the database from a chat (db_write): read each doc first, use `update` with only the changed fields plus `ifVersion`, and log a `claude_changes` doc (`{label, ops:[{type, id, before, after}], authority, created, undone:false}`, type is the `S` key, e.g. `loose` for `loose_ends`) so Mike can undo from the app. Done this way on 19 Nov in five groups (`ch_19nov_pip2_1` to `_5`).
- Pip 2 beats: only the climax role is set (`hub_4_the_general`, 19 Nov). Opening and ending are unset on purpose for now.
- Artifact comment threads: this artifact counts as possibly shared, so replies need `reply_shared_comment` with `shared_live:"others"`.
