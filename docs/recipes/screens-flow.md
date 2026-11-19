# Recipe: screens from Google Flow

## Accounts
Image generation is free but rate-capped per account, so work is spread across five. Each has its own Flow project.

| Suffix | Account |
| --- | --- |
| hsd | headsmartdesign@gmail.com |
| m35 | mike.lewis35@gmail.com |
| wgv6 | wegotvegan6@gmail.com |
| wgv7 | wegotvegan7@gmail.com |
| wgv8 | wegotvegan8@gmail.com |

Before generating, confirm the active account by clicking the username at the top right of Flow. Never trust the user number in the URL. If you can't confirm it, stop and ask Mike.

## Style block
Use Mike's prompt shape, word for word apart from the scene in the middle, and attach the style montage as a reference:

> In the style of Hayao Miyazaki, but slightly more subdued colours, I'd like high angle overhead photo with ray tracing and reflections of **[the scene: a marsh land path, what's in it, what it passes]**. There should be a few very small red and white mushrooms along the path, there should be the occasional puddle. Sunset lighting

- **Reference:** attach `kept-assets/look-reference/flow_style_montage.jpg` (outside git; Mike drags it in, since agents can't upload).
- **Say "photo with ray tracing and reflections", not "image" or "illustration"** (2026-11-13): "photo" alone gave much nicer results, and adding "with ray tracing and reflections" is the look Mike is going for (`kept-assets/style-tests/reeds_bridge_stream_raytraced.jpg`). The montage keeps it painted.
- More looks to aim for, for later screens with people: `kept-assets/look-reference/village_market_squirrels_1.jpg` and `_2.jpg`. Marsh screens still have no characters in them.
- **Keep the artist's name in** (2026-11-13): without it the style drifts.
- The best result so far, and the one to match: `kept-assets/style-tests/reeds_boardwalk_sunset.jpg`, from "…photo of a marsh land path, giant reeds and rushes towering over. There should be a small wooden bridge, uncared for, delapidated, tilted, slightly rotten. …". Pip on it in the style bench looks right: brightest thing on screen, at a size that fits the boardwalk.
- Check each result for stray people (the montage has some) and lettering on signs. If they keep turning up, add "no people, no writing" and see whether the style holds.

## A still screen
1. Generate the painting at 16:9 from the style block, with no characters in it. The block's "high angle overhead" is what sets the camera.
2. Check the camera steepness against the screens already accepted. Pip's sprites are rendered from one angle, so screens must roughly agree.
3. Mike picks. Download at 1K (original size); 2K is an upscale.
4. Cut out anything that should pass in front of a character as a foreground layer.
5. Mark where characters can walk and where the exits are. See "Building a screen in Godot" below.

## Building a screen in Godot
A screen is a flat picture (see DECISIONS, 2026-11-13). Copy `scenes/screens/marsh.tscn` as the template.
1. Put the painting in `assets/screens/<name>/` and set it as the `Background` texture (not centered, at 0,0).
2. Cut out everything that should hide Pip (see "Cut-outs" below). Each one is a `Sprite2D` under `World`, positioned where its **base** touches the ground, with the image pulled up by `offset` (offset y = minus its height). `World` y-sorts, so Pip goes behind anything whose base is lower on screen than his feet. Things that hang overhead (willow leaves) go under `Overhead` instead, which always draws over Pip.
3. Draw the walk area by editing the `WalkArea` polygon's points in the 2D editor. Press F in game to see it.
4. Set the two depth numbers on the screen root: `far_y`/`far_height` and `near_y`/`near_height` are where Pip's feet are and how tall he should be there, in pixels. Judge by eye against something in the painting, like the path's width.
5. Place `Pip` where he enters.
6. Exits: under `Exits`, add a `Polygon2D` with `scripts/screen_exit.gd` over each end of the walk area where the path leaves the picture, and set `to_screen` and `to_entry`. Under `Entries`, add a `Marker2D` with `scripts/screen_entry.gd` for each way in, named to match an exit's `to_entry`, inside the walk area and clear of every exit, with `facing` set to the way he walks in. F shows exits in blue. The fade itself is the `ScreenChanger` autoload (`scripts/screen_changer.gd`). The three marsh screens chain marsh → boardwalk → stream; the marsh's near end and the stream's far end have no exit yet.

## Cut-outs
`tools/cutout.gd` cuts a foreground piece straight out of the painting: it finds the ink lines inside a rough outline, bridges small gaps, fills enclosed shapes (leaves, reed heads) and keeps the painting's own colours. Because the colours are the painting's, a cut-out is invisible until Pip walks behind it, so rough edges don't show.
1. Mike marks what should hide Pip on a screenshot (blue pen works).
2. Run `Cutout.cut(painting, outline, options)` from `execute_script` for each piece and save the PNG to `assets/screens/<name>/`. Useful options: `keep = "tall"` drops flat ground lines, `keep = "top"` keeps only shapes hanging from the outline's top edge (canopies), and `source_alpha` starts from an existing mask instead of finding ink.
3. Play it, look for lines that cross Pip where they shouldn't, and erase them.
4. Works because Flow screens are ink outlines over watercolour. A soft painted shape with no outline won't cut cleanly.

When a person would rather select the pieces by hand in Affinity, use `screens-layering.md` (the `/layering` skill): they draw the layers, press a button, and the agent brings them into the scene.

Godot-side gotchas (stale imports and so on) are in `godot.md`.

## An animated screen
First done on the marsh, 2026-11-19 (M4). Flow's video models change often, so check the model picker rather than trusting a name written here.

1. **Start from the accepted still**, the same 1K download the screen uses. The loop is animated from it, not generated fresh.
2. **Flow, video mode, "First and last frame"**: the same still as both frames, length 3 seconds, prompt `subtle looping animation, seamless, no camera movement`. On the marsh the picker said Omni 1.2.
3. **Make two clips and join them in Scene mode.** "No camera movement" holds better on short clips, and two different clips make the loop harder to spot.
4. **Clean it before it goes near the game.** The cleaning scripts live in `kept-assets/screen-video/` (`flow_loop_motion.py` finds what moves, `flow_loop_clean.py` builds the frames): they're one-offs for now, so read them before reusing them on another screen.
   - Find what moves (per-pixel spread across the frames), turn it into a feathered mask, and composite only those parts over the full-size painting. Everything else stays the painting, pixel for pixel.
   - Drop the audio track and encode Theora `.ogv` at the screen's size (Godot plays nothing else).
5. Keep the raw Flow video, masks and `.ogv` in `kept-assets/screen-video/` until Git LFS is set up; only the `.ogv` goes into the repo, under LFS.

Gotchas
- **Judge the loop by eye, not by numbers** (2026-11-19): measured frame to frame, the marsh clip's join and loop point looked like jumps, so a crossfade was added. Watched, the uncut clip loops cleanly and the crossfade wasn't needed. When a loop is in question, watch it wrap before changing it.
- **The video redraws everything, not just what moves** (2026-11-19): it comes back at 720p with every ink line slightly re-rendered (the colours stay true). Masking keeps everything that doesn't move at the painting's own sharpness. So the screen plays the masked clip (`DECISIONS.md`, 2026-11-19); the full-frame one stays in `kept-assets/screen-video/` only.
- **Some movement sits on the ground, some in front of Pip** (2026-11-19): on the marsh the fronds and bulrushes should cover Pip, and the puddle glints should go under him. Don't make a mask for what covers him: layer the screen in Affinity like a still one (`screens-layering.md`); the sent shapes draw the video's pixels over him.
- **A shape in front of Pip at the bottom of the screen can be behind him further up** (2026-11-19): one front mask drawn over Pip always made the marsh's far bank cover his face while he stood in front of it. When a shape should hide Pip only once he has walked past it, it needs the bottom-edge rule (`screens-layering.md`), not a mask.

## Gotchas
- Flow paints every scene in its own perspective. Asking for a flat top-down view doesn't work; judge steepness across screens instead.
- Don't use Pip's sheet as a style reference: it makes every character look like Pip, and childish. Describe the rendering style in words and ask for grounded proportions.
- Agents can't upload files into Flow (the Chrome file upload fails). Mike drags references in by hand. Don't retry in a loop.
- References and prompt text clear after every submit, so re-attach each run. Check the mode chip says Image before submitting.
- The grid reshuffles. Identify images by title, never by position. Titles are editable and a good place for scores.
- Downloads are JPEG named after the image title.
- Images kept in Drive can't be seen by the planning room. Attach them in the chat.
- **Check what's actually covering Pip** (2026-11-13, M1): a "reed blade across his belly" turned out to be faint grey wash in the old cut-out, not a reed. When judging whether Pip passes behind something, make sure the overlap is the object itself: compare with the cut-out hidden, or look at the cut-out on a bright background.
