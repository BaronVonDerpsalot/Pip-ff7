# NPC hooks, shot list, Claude-drafted specs, claims in the Write tools (built 21 Nov)

Finishes visual-specs-plan.md: section 3 (NPC hooks), the shot-list export, ground rule 0a (Claude drafts specs for gaps), and the claims/truths gap in the Write tab's tools. Live version `1795270909-6a2d` (built as `1795267757-4ed5`, then the open-questions fix, field-level undo and the game project's shot-list changes below).

"The planning room" in these docs is the Pip FF7 game project (the Pip 2 game, built in its own Claude project, with the flow-assets agent).

## Mike's choices (21 Nov, asked before building)
1. Contradiction check: plain mentions, no model. An NPC is flagged when their lines or record mention a contested record (one with claims) and they have no belief about it.
2. Minor NPCs: a tick on a normal character record. The Bible folds them into one "Minor NPCs (N)" row; the editor is short.
3. Who needs a hook: every character except Pip, Pip 1's cast included.
4. Drafting specs: a button on each record plus "Draft all N" (two taps), one undoable change.

## NPC hooks (entries, characters except Pip)
- `hook: {type, text?, on?, claim?}`. type is obsession | grudge | hobby | affiliation | belief. `on` is the entry it touches (needed for belief and affiliation). A wrong belief names `claim`, the key of a claim on `on`.
- Minor NPCs: `minor: true`, plus `place` (where they are). The editor for a minor NPC shows name, status, kind, game, one line, hook and place only (no tags, claims, sealed-until).
- Record page: a Hook card above Claims ("Believes: …" with the record it's about). Claims show "Believed by" (worked out from hooks, not stored on the claim). Backlinks: "has a wrong belief about it", "hook touches it", "found here".
- Editor: hook type buttons, the record (datalist, factions and lore first), for a belief a select of that record's claims plus "A new claim", which adds the claim to the lore record on save (Mike's own edit, via `put`). "No hook" clears it.
- Script room: a red dashed bar under the header names any speaker in the scene (or the selected composer speaker) who has no hook, with a link to their editor.
- Health (deterministic, three sections): "NPCs talking about contested lore with no belief" (mentions in their lines or record, skipping lore figures: records with claims or the world-lore tag; a belief is a belief hook on that record or being named in one of its claims' Held by), "Hooks pointing at something that's gone", "NPCs speaking with no hook". None of these count toward the urgent banner.
- Roleplay: it did not actually send claims or hooks before (`recordDump` sent the body only). `recordDump` now adds `minor_npc`, a `hook:` line (with "they believe it and say so with confidence; one claim among several") and `claim k=… (unconfirmed)` lines. Never the truth. The hook's target record is also added to "things their record mentions". This reaches the Write tab and Christine's request checks too, since they use the same dump.
- Briefs get a `Hook:` line per character; the Full export a `Hook:` line. Christine's view only gets bodies, so hooks never reach her.
- Code: block "NPC hooks and minor NPCs" just before "record page extras". `hookOf`, `hookClaim`, `hookProblem`, `hookPlain`, `believersOf`, `npcBeliefOn`, `hookRecordHtml`, `hookEditorHtml`, `syncHook`, `tidyHook` (async, called in `saveDraft`), `hookAct` (`hk-*`), `scHookBar`, `hookHealth`, `briefHook`.

## Shot-list export (Room page, Export section)
- "Shot list for the planning room": Download or Copy. Uses the Export game chip (All and Series mean every game). Pip 2 downloads as `shots-pip-ff7.md` (the game project's name, `SHOT_FILE`); other games use their id.
- Shaped for the flow-assets skill's Generate step: one numbered list, each item `N. <spec id>` (the image title), then `kind: screen | character | item | cinematic` with shot purpose, time, mood and mystery on the same line, then: screens: Path route, Characters stand, Place, Beats (or padding), Contents, Must be visible, Must not be visible, Exits; characters/items: Record, Must show, "isolated, full body, whole and unobstructed"; cinematics: Scene, What happens, Start/End frame, In shot. Then any camera words to leave out, and Text on screen (exact wording, painted or overlaid is the game project's call).
- Order: sections Screens (by area: flashback, marsh, hub 1, road…), Characters, Items, Cinematics, each in game order.
- Never in the numbered list, each held back in its own section: picked (has an `asset_manifest` doc; left out entirely), stale (with what changed), Pip in shot (`in_shot` has pip, or "Pip" in a positive field; "must not be visible: Pip" doesn't count), states (variants with `state_of`; made by editing source images, which the game project has parked). Precedence in that order.
- A screen with no route says "Path route: NOT SET YET … Ask Mike before generating."
- Code: block "shot list for the flow-assets skill…" just before `SPEC_CONTENT`. `SHOT_FILE`, `shotFileSlug`, `shotHasPip`, `shotItem`, `shotList`, `shotText`, `shotsExportHtml`, `shotsAct` (`exp-shots`, `exp-shots-copy`, called from `expAct`).

## The game project's feedback on the shot list (21 Nov, `1795270909-6a2d`)
They asked for, and got: the `shots-pip-ff7.md` name; a kind on every item; screens naming the path's route and where characters stand; camera words like "towering" kept out; no item asking for Pip; and, since they won't edit images for states or write the manifest yet, states held back. Story Room side:
- Screen specs gained `route` (which edges the path enters and leaves by) and `stand` (where characters will stand), in the editor, the spec page (route shows "not set" in red) and `SPEC_CONTENT` (editing them re-dates the spec). New tally chip "Screens with no route". No existing screen has either yet.
- `CAMERA_WORDS` / `cameraWords(s)`: towering, looming, looking up/down/across…, seen from, from just/high above, from below, aerial, bird's-eye, close-up, close view, wide shot, frame words, in the foreground. Flagged, not stripped: a red banner on the spec page, a "Camera words" tally chip listing the words, and a line in the shot-list item. Many migrated specs use these on purpose (the Flow camera overrides were folded into the text as well as into shot purpose).
- Their answer on the manifest's `state` field: it's the variant (b), an echo of the spec's own `state`, not a pick status, and it's optional, since every state is its own spec id.
- Known conflict, not resolved: the agreed plan (Mike and the game project, 21 Nov) says cinematics are the only specs where Pip may appear. The game project says Pip comes only from his Blender rig until docs/DECISIONS.md logs that decision. The export follows the game project for now.
- They asked that no story work depend on the manifest being filled in yet.

## Claude drafts specs for gaps
- Visual specs → "Records without a spec": "Draft with Claude" on each row, "Draft all N with Claude" (two taps), Stop while running, a banner listing what was drafted.
- One stateless call per record (`specGenPrompt`): the record dump, for places the parent chain, beats there, child places and one nearby spec for level of detail. Asks for JSON only, facts only, no style words. Places become screens (`place` set, beats linked if any, else padding); characters and items get `show`. (It doesn't yet draft `route` or `stand`.)
- Open questions (`1795268197-ea89`): `specOpenQs(rid)` finds open loose ends that link the record, that its body mentions, or that mention it. Such records show "Open: <question>" in orange; Draft all leaves them out; their button reads "Draft anyway" and needs a second tap. When drafted anyway, the prompt lists the open questions and tells Claude not to answer them. Why: a character spec is the character's look, so drafting the worried fairy (name and look open) or hub 4 (what it is open) would settle Mike's open questions for him.
- Saved as `status: brainstorm, source: "claude", edited_by: "claude"`, owner-only like every spec, `written` now, and a note saying Claude drafted it. A sentence-level filter (`STYLE_WORDS`) cuts any sentence with medium or style words and the note says how many were cut.
- Ids: `c_<name>`, `p_<name>`, and for screens the area prefix most used by specs in that place or its parents (`specGuessPrefix`), else `x_`, plus `_01`.
- All drafts in a run are one `claude_changes` entry, undoable from the Inbox change list. Model follows the Write tab's model pick.
- Code: `specOpenQs`, `specGenPrompt`, `specGenId`, `specGenOne`, `specGenRun`, `specGenBarHtml`; actions `spec-gen`, `spec-gen-all`, `spec-gen-stop`, `spec-gen-ok`.

## Write tab: claims, truths, hooks
- `update_record` and `file_record` take `claims` (the complete list; keep one by passing its `k`, shown in the record dump), `truth_state` / `truth_text`, `hook_type` / `hook_text` / `hook_on` / `hook_claim`, `minor`, `found_at`.
- Setting what actually happened always needs Mike's exact words in `authority`. Edits to canon records still become a proposal with Apply/Discard (as before), so a truth on a canon event waits for his tap.
- Removing a claim that someone believes returns a warning in `dropped`.
- Code: `loreFields` and `LORE_PROPS` inside `actionTools`.

## Field-level undo (`1795268608-9166`)
- A `claude_changes` op may carry `unset: [fields]` instead of a full `before`; undo then removes just those fields from the current record. Use it when a chat adds fields to an existing record. Code: top of the loop in `undoChange`.

## Data work done from chat (21 Nov, after the build)
- Stale specs: checked against the real data, none.
- Records without a spec in Pip 2: three. Drafted `h3_garden_village_day_01` (undo `ch_21nov_spec_h3_garden`). Left out on purpose: `the_worried_fairy` and `pip_2_hub_4` (open questions).
- NPC hooks (Mike picked each by multiple choice): firefly (grudge: rationing), owl (belief: Treaty of Wetfoot, "the dry lands won", wet2), old_mole (obsession: proper ice cream), badger (hobby: counting loads), snail (hobby: sitting on important things), the_foreman (obsession: the clipboard), the_general (obsession: his vow, on pip), wardens (affiliation: the_shrooms), dartwold_local (hobby: rating passers-by as fruit), orlan_whistlewick (obsession: his own title), the squirrel post-runner (belief: three Mothrags, moth2), the frog drummer (affiliation: the_frogmatists), the_worried_fairy (affiliation: reformed_church_of_the_damp). New minor NPC `toad_who_wont` (brainstorm, at monarchs_wallow, affiliation: the_unwrung). `updated` left alone on the 13 existing records so their specs don't go stale. Undo `ch_21nov_npc_hooks`.
- Spec `c_toad_grump` now points at `toad_who_wont` (re-dated so it isn't stale; undo `ch_21nov_toad_spec`).
- Skipped on purpose, Mike's to decide: the woman, the kind folk, Bessie, Purl, Toaf, the Queen, the mushroom king, and the groups (workers, shroom grunts, warrior shrooms, Sturrymead villagers).

## Tested
Playwright with a mock db/sample and synthetic data (40 checks), including the game project's changes: pip-ff7 file name, kinds named, Pip and states held back, missing route flagged, camera words flagged. Screenshots at 390px, light and dark.

## Not done
- No screen spec has a route or standing spots yet, so every screen in the shot list says "NOT SET YET". Backfilling them is a data job (about 200 screens) waiting on Mike.
- Camera words are flagged, not rewritten.
- The skipped characters and groups still show in Health as speaking with no hook, wherever they have lines.
- Truth isn't in any prompt, so the Write tab can set a truth but can't read the current one.
- The shot list isn't kept live in the database like briefs.
