# Shot-list batches: the opening marsh (22 Nov), then everything (27 Nov)

Follows hooks-shots.md. Live version `1795368574-7020`.

## App changes (22 Nov)
- Specs can carry `pip_ok: true` ("Pip may appear" tick on cinematics). Pip specs without it are held back in the shot list; with it they go in the numbered list with a line saying it's one of Mike's vital Pip cinematics. The spec page shows whether a Pip spec is approved.
- The shot list has an Area chooser (Export section). The file name gains the area, e.g. `shots-pip-ff7-m1.md`; "All" gives `shots-pip-ff7.md`. Code: `shotArea()`, stored in `S.exp.shotArea`.
- Undo ops can carry `restore: {field: old value}` alongside `unset`, so a chat that rewrites a few fields can log an exact undo without copying whole records.

## Mike's decisions
- 22 Nov: Pip appears only in the most vital cinematics: `fb_vanish_day_01` and `h1_organ_wrong_tune_night_01`. Everything else with Pip (the chase, the Organ rearing, the Organ back in time, the barrow race stills) stays rig-only. The game project needs this logged in its docs/DECISIONS.md.
- 22 Nov: camera words come out of playable screens; layout, reveal, establishing and insert stills keep them, since that's their point.
- 27 Nov: one batch with everything, fixed now.

## Data
- 22 Nov (undo `ch_22nov_m1_routes`): all 31 `m1_` screens got `route` and `stand`; frame words rewritten out of five.
- 27 Nov (undo `ch_27nov_routes_1` to `_4`, one per batch): every other screen got `route` and `stand`: the flashback stills, hub 1 (52), the road to hub 2 (41), hub 2 (39), the road to hub 3 (38), the garden village (1). Camera words rewritten out of h1_courtyard_north_day_01 and r23_b_tunnel_exit_morning_01 (undo restores the old wording).
- Conventions: the main path runs up the screen (in at the bottom edge, out at the top) unless the contents say otherwise; side exits match edge to edge with the next screen (out on the right means in on the left). Each road's three routes leave its fork left, top and right, and meet again at the far end. Hubs have a hub screen with exits on several edges. Interiors are entered by a door at the bottom edge. Reveal, insert, layout and establishing stills say "None: … not a playable screen". States say "Same as <source>" (states stay held back in the export anyway).
- Stale: the ~70 specs made stale by the 21 Nov quest sessions were checked. The changes were quest givers and rewards, nothing visual, so everything was re-dated (`written` 27 Nov). Eight items and characters with no route change got `refreshed` too.
- Standing spots name the 21 Nov NPCs where the record puts them there (Croaksworth and Spawnbury at the hub 2 split, Lodgemoor at the sluice house, Fennick on the bandstand, the squirrel committee at the festival, Teeterlow at the bunting tree).

## Gaps noticed (no spec yet)
- Hub 2 quest screens: the beached barge, the halfway path, the listing houses (the stilt-lickers screen is covered by h2_beached_underside_day_01).
- Hub 3 has only one screen (the establishing still): nothing yet for the greenhouse, the prize marrow, the shade garden or the sunflower square.
- Hub 4: none (what it is as a place is still open).
- Characters: Mistle (her look is now decided) and the 12 named minor NPCs from 21 Nov. The game project's recipe can't do characters yet anyway.
- `the_first_puddle` beat (22 Nov) has no screen of its own.

## Still true
- `asset_manifest` is empty; the game project won't write to it yet.
- Characters, items and cinematics stop the game project's agent until its recipe has a style block for them.
