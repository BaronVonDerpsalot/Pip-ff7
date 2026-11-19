# Decisions

Append-only. One dated line each. A later line supersedes an earlier one. Lines marked "(carried)" were decided in the old Phaser project and still stand.

- 2026-11-09 — (carried) Pip is a chibi creature: not a mouse, not a demigod. Small round pom-pom tail, disc ears, smooth bald head.
- 2026-11-10 — (carried) The Xbox controller is the main way to play; the keyboard is fully supported. The phone is not part of the slice.
- 2026-11-12 — (carried) Look: hand-sketched watercolour at full HD on FF7-style painted screens.
- 2026-11-12 — (carried) Pip's sprites are rendered from his Blender rig, never generated. Flow makes the screens and other stills.
- 2026-11-12 — (carried) Pip is the only chibi character. Characters stay full colour against muted screens.
- 2026-11-12 — Fresh start: new repo, Claude Project and board. Only Pip's Blender setup, his sheets and GIFs, and the marsh walk prototype (as a look reference) carry over. The Phaser repo is archived, not deleted.
- 2026-11-12 — The board is Asana, laid out as milestones in order plus a Parking lot. Status lives only there.
- 2026-11-12 — The slice's one mechanic is the fart (it wakes the hypnotised villager). Sword combat comes after the slice.
- 2026-11-12 — Flow video is back in the plan, for animated screen loops only. Untested.
- 2026-11-12 — The engine is Godot 4.7 (latest 4.7.x patch). Not the 4.8 beta; move up only as a deliberate step once 4.8 is stable.
- 2026-11-12 — The repo is BaronVonDerpsalot/Pip-ff7 (private, main).
- 2026-11-12 — Mark joins as an equal partner across art, code and story, with his own Claude Project and agents on the same repo and board.
- 2026-11-12 — Changing the brief, changing direction and ticking a milestone each need a yes from both Mike and Mark.
- 2026-11-12 — Supersedes the line above: a yes from either Mike or Mark is enough. Mark works on the project as and when, so nothing waits on him.
- 2026-11-13 — A screen is built as a flat picture: the painting as a 2D backdrop, cut-out foreground layers, a drawn walk area, and two numbers for Pip's size near and far. Not a 3D scene with a matched camera. (Mike)
- 2026-11-13 — Picked, game-ready screen art (paintings and their cut-outs) is committed under `assets/screens/`. "Raw Flow output" in CLAUDE.md means unpicked generations and video. (Mike)
- 2026-11-13 — The Ziva editor plugin (`addons/ziva_agent/`) stays out of git; each person installs it in their own editor. (Mike)
- 2026-11-13 — Pip walks and idles in eight directions: five rendered (down, down-right, right, up-right, up) and three mirrored. Supersedes the brief's four. (Mike)
- 2026-11-13 — The project's name is Pip FF7, everywhere: docs, board, Godot. ("Pip 2" in older lines means the same project.) (Mike)
- 2026-11-13 — ◆ M1's pad check moved into ◆ M3's Done when, since no pad was to hand; M1 was ticked after a keyboard play. (Mike)
- 2026-11-13 — Delivery: a web link on itch.io (a private page), with a Windows .exe as the fallback. Both are exported from `export_presets.cfg` into `../builds/`, outside git. (Mike)
- 2026-11-13 — Christine only ever gets finished products. Milestones and the slice are signed off by Mike or Mark playing them; nothing in progress goes to her. Supersedes the brief and board lines that had her playing M3 and the slice. (Mike)
- 2026-11-13 — Pip runs (toggled with L3 or Shift) and creeps (a gentle push of the stick, or holding C) as well as walking. Both are in the slice. Until their loops are rendered, the walk loop stands in. (Mike)
- 2026-11-13 — Moving between screens: Pip and the whole screen fade out together, then the next screen fades in with Pip already at his entry point. (Mike)
- 2026-11-13 — Pip's paper grain is light (strength 0.15): one fixed grain multiplied over every frame of every sheet (idle, walk, run, creep), so his texture never changes between gaits. (Mike)
- 2026-11-13 — Pip's run and creep loops are signed off as they are: speeds stay at run_speed 3.0 and creep_speed 0.6, and the feet sliding a little faster than the legs (as the walk already does) is fine. (Mike)
- 2026-11-13 — Screen style: hand-painted animated-film backgrounds in the style of Hayao Miyazaki, with subdued colours and warm low sunset light (Mike's pick from the style tests: `kept-assets/style-tests/Path_fork_in_marsh_land_920427ef.jpg`). The artist's name stays in the prompt, because the style drifts without it. Replaces the hand-sketched storybook look for screens; Pip's own look is unchanged. The marsh is repainted in this style so all three M4 screens match. The prompt is in `recipes/screens-flow.md`, "Style block". (Mike)
- 2026-11-14 — Screens are layered in Affinity: every layer above the painting is an overlay drawn in front of Pip, no naming. A screen counts as layered when its scene's Overhead node carries `metadata/layered = true`, set by any send, including an empty one ("needs none"); there is no separate tracking file, and the plan lives on the board. See `recipes/screens-layering.md`. (Mike and Mark)
- 2026-11-19 — Layered shapes cover Pip by the bottom-edge rule: each separate shape in a sent layer covers him only while his feet are above its bottom edge at his x, read from its pixels. Layers named "Over..." always cover him (hanging fronds). Same workflow for still and animated screens: on a screen with a video loop the shapes draw the video's pixels. Replaces "every layer is always in front of Pip" (2026-11-14). See `recipes/screens-layering.md`. (Mike)
- 2026-11-19 — Animated screens play the masked clip (the painting, with only the moving parts animated), not the full-frame one: everything that doesn't move stays at the painting's sharpness. The marsh's full-frame clip is removed from the repo. (Mike)
- 2026-11-19 — Flow prompts for screens say "image", not "photo": "photo" sometimes comes out too photorealistic. The rest of the style block stands, ray tracing and reflections included. See `recipes/screens-flow.md`, "Style block". (Mike)
- 2026-11-19 — Asset pipeline split. A story workflow turns a scene into Flow prompts with file names; Cowork generates them in Flow, titled with those names. Mike moves picks into Flow library folders: "game images" (stills) and "for video". Cowork downloads stills at 1K and, for video screens, makes two 3 s first-and-last-frame clips from the still, joins them itself (no Flow Scene mode) and converts to .ogv; everything lands in `preprocessing/<name>/`, next to `kept-assets/` and outside git. Code takes it from there (Affinity layering, video masks, into the game). M4 is widened to include this. (Mike)
- 2026-11-19 — Supersedes part of the line above: M4 needs only the Cowork asset workflow proven (pasted named prompts → Flow → preprocessing/). The story → prompts workflow comes later, once the story is further on (Parking lot). (Mike)
- 2026-11-19 — The style block gains a fixed camera sentence ("seen from a raised viewpoint about as high as a two-storey house, looking down at the path at about 45 degrees, close enough that the path is wide and fills the lower half of the picture"), a thin band of sky at the top, and "soft, muted greens and browns". Three test screens all matched the marsh camera with it. See `recipes/screens-flow.md`, "Style block". (Mike)
- 2026-11-19 — The video loop prompt is the cinemagraph one in `recipes/screens-flow.md` ("An animated screen"): light, water and breeze only, everything else frozen. Replaces "subtle looping animation, seamless, no camera movement". A stronger light version was tried and not taken. (Mike)
