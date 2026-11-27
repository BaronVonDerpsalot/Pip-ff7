# Visual specs, states, tally and asset manifest (built 21 Nov)

Sections 1 and 4 of visual-specs-plan.md. Live version `1795266149-5394` (now superseded: see hooks-shots.md, `1795267757-4ed5`).

## For the planning room
- Manifest collection: **`asset_manifest`**. One doc per spec id (doc id = spec id). Fields: `{spec, state, paths: ["assets/screens/<id>/<file>.png", ...], picked: ISO date, note?}`. Repo paths only, never Flow download names. Overwrite a spec's doc when the pick changes; never delete without Mike saying so. The app only reads it.
- The db rules can't tell writers apart (everyone writes as Mike, owner), so "manifest only" is ground rule 0e by convention, not enforcement.
- States are their own spec ids (e.g. `h1_hyp_courtyard_night_01` has `state_of: h1_courtyard_night_01`), so a state's pick is its own manifest doc; `state` just echoes the spec's state name.

## Data (collection `specs`, owner-only by the default rule; guests never subscribe, verified with asLevel view)
- Doc id = spec id, never renamed. Common: `kind` (screen | character | item | cinematic), `game`, `order` (game order), `status`, `source` (flow_doc | mike | claude), `tag` (canon | mixed | invented), `tag_note`, `mystery`, `note`, `created`, `updated`, `written`.
- Screens: `place`, `beats[]`, `padding` (true when no beats), `contents`, `visible`, `hidden`, `exits[{label?, to, oneway?}]`, `mood`, `time`, `shot` (playable | establishing | layout | reveal | insert), `close`, `text` (exact wording, several signs joined with " / "), `diversion`.
- Characters/items: `record`, `show`. Cinematics: `scene`, `beats`, `happens`, `start`, `end`, `in_shot[]`, `video`.
- States: `state_of` (spec id), `state` (name), `change` (what differs). A base can carry `state` too (e.g. "torn wing").
- Stale = any of place/record/scene/beats/in_shot has `updated` later than the spec's `written`. `written` only moves when content fields change or Mike taps "mark refreshed".

## App
- Routes: `#specs` (tally + list), `#spec-<id>`, `#specedit-<id>`, `#specnew`. Bible tab menu has "Visual specs"; Room page has a summary; place, character, item, beat and scene pages list their specs with "New spec" (prefilled).
- Tally chips: all, stale, no accepted image (no manifest doc), exit problems (dangling or one-way without the one-way tick), records without a spec (characters, items, places of the scoped game), screens with no place. Scope is the header's game filter, or the next unreleased game when it's on All.
- Spec page: stale banner with "mark refreshed" (two taps), accepted image card from the manifest, all fields, states list, Edit / Add a state / Make canon (two taps) / Delete (two taps).
- Code: block "visual specs" just before `/* ---------- actions ---------- */`. `specTally`, `specStaleBy`, `specPick`, `specExitIssues`, `specMissing`, `viewSpecs`, `viewSpec`, `viewSpecEdit`, `specSave`, `specsRecordHtml`, `specsMoreHtml`, `specAct` (all `spec-*` actions, from `extraAct`). `COL` gained `specs` and `manifest`. `undoChange` now honours an op's `check` (a field subset) so big logs needn't carry full `after` copies.

## Migration (21 Nov)
- All 243 Flow prompts from the Pip 2 Flow prompt doc are brainstorm specs (`source: flow_doc`): 203 screens, 12 cinematics (VIDEO BODGE plus the flashback stills with Firefly in shot), 16 characters, 12 items. Camera overrides became shot purpose (LOW reveal, EYE insert, HIGH layout, default playable, establishing for the door still and the hub 2 first sight). EDIT FROM entries became states. Pip's description inside cinematics was cut to "Pip"; "isolated white background, full body" was cut from characters and items (the kind implies it). No style words.
- Undo: claude_changes `ch_21nov_specs_1` to `_5` (one per batch) and `ch_21nov_route_places`.
- New brainstorm route places: `road_h1_h2` (inside monarchs_wallow) and `road_h2_h3`.
- fb_ screens have no place (where the door stood in Pip 1 isn't settled). No exits were migrated: the Flow doc never had them.

## Done since (21 Nov, hooks-shots.md)
- Shot-list export for the flow-assets skill (Room page, Export section).
- Claude drafting specs for records without one: per record or all at once, brainstorm, `source: claude`, undoable.
- NPC hooks, the script-room warning and the contradiction check; the Write tab's record tools set claims and truths.
