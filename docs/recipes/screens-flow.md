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

> In the style of Hayao Miyazaki, but slightly more subdued colours, I'd like high angle overhead image with ray tracing and reflections of a marsh land path, seen from a raised viewpoint about as high as a two-storey house, looking down at the path at about 45 degrees, close enough that the path is wide and fills the lower half of the picture. **[The scene: where the path runs, what's in it, what it passes.]** Only a thin band of distant marsh and sky along the top. Soft, muted greens and browns. There should be a few very small red and white mushrooms along the path, there should be the occasional puddle. Sunset lighting

- **Reference:** attach `kept-assets/look-reference/flow_style_montage.jpg` (outside git; Mike drags it in, since agents can't upload).
- **Say "image with ray tracing and reflections", not "photo"** (2026-11-19, supersedes 2026-11-13): "photo" sometimes pushes the result too photorealistic. "With ray tracing and reflections" is still the look Mike is after (`kept-assets/style-tests/reeds_bridge_stream_raytraced.jpg`). The montage keeps it painted.
- More looks to aim for, for later screens with people: `kept-assets/look-reference/village_market_squirrels_1.jpg` and `_2.jpg`. Marsh screens still have no characters in them.
- **The camera sentence is fixed** (2026-11-19): "seen from a raised viewpoint about as high as a two-storey house, looking down at the path at about 45 degrees, close enough that the path is wide and fills the lower half of the picture", plus "only a thin band of distant marsh and sky along the top". Without it Flow drifts to ground level; "seen from high above" swung between ground level and a drone shot with a tiny path. With it, 3 of 3 test screens matched the marsh's raised three-quarter view. Keep words like "towering" out of the scene: they pull the camera down.
- **Name the path's route** (bottom left corner to top right, and so on) so exits line up between screens, and leave open ground where characters will stand.
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
2. Layer everything that should hide Pip in Affinity (`screens-layering.md`): each shape hides him only when he's behind it, and "Over..." layers always do. On an animated screen, add the `Loop` node first ("An animated screen" below). The scripted alternative is "Cut-outs" below.
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
Proven on the marsh and the lily pond, 2026-11-19 (M4). Flow's video models change often, so check the model picker rather than trusting a name written here. Cowork's part ends at `preprocessing/<name>/`; masking and putting the loop in the game are Code's (`screens-layering.md`).

1. **Start from the picked still**, the one Mike moved into Flow's "For video" folder.
2. **Flow, Video, "Frames" mode**: the same still as Start and End (pick it from the library; nothing needs uploading), 16:9, 720p, length 3 seconds, **x2**, and the loop prompt below. x2 makes the two clips in one submit (2 × 9 credits). On 2026-11-19 the picker said Omni 1.2 Flash.

   > Cinemagraph: a locked-off, perfectly still shot of this painting where almost nothing moves. Only quiet ambient life: **[2–4 light, water and breeze details for this screen, e.g. warm sunlight shimmering softly on the water, faint ripples spreading under the lily pads, the reflections wavering slightly, the tips of the reeds barely swaying in a light breeze, a few specks of pollen drifting through the low sunbeams]**. The path, ground, trees, sky and every outline stay exactly where they are. No camera movement, no zoom, no new objects or creatures, no gusts. Seamless loop.
3. **Title the clips** `<name>_loop_a` and `_b` and download both at 720p (original size), plus the still at 1K.
4. **Join and colour-lock them here, not in Flow** (Scene mode dropped): `python3 kept-assets/screen-video/flow_loop_colourlock.py <a.mp4> <b.mp4> <still.jpg> <out.ogv>` concatenates a then b, scales to 1920x1080, drops the audio, locks each frame's coarse colour (a 96x54 grid) to the still, and encodes Theora `.ogv` (Godot plays nothing else). Don't crossfade: the marsh clips looped cleanly as they were.
5. **Save to `preprocessing/<name>/`**: `<name>_bg.jpg` and `<name>_loop.ogv`. The raw clips go to `kept-assets/screen-video/`. Only Code moves anything into the repo (`.ogv` under Git LFS).

## Collecting from Flow
Mike sorts picks into two Flow library folders in the project: **Game images** (stills) and **For video** (stills to animate). Cowork then:
1. Downloads each still at 1K (original size). Chrome's download location is `Pip FF7\preprocessing\`, with "Ask where to save" off: the Chrome extension can't drive a Save As window, and desktop control can only look at Chrome, not type in it. Flow adds a short hash to each name (`reedbed_v3_4ae1dc7b.jpg`).
2. Sorts each file into `preprocessing/<name>/<name>_bg.jpg`, using the Flow title without the hash or any `_vN` round suffix.
3. For each For video still, runs "An animated screen" above.

Gotchas
- **Judge the loop by eye, not by numbers** (2026-11-19): measured frame to frame, the marsh clip's join and loop point looked like jumps, so a crossfade was added. Watched, the uncut clip loops cleanly and the crossfade wasn't needed. When a loop is in question, watch it wrap before changing it.
- **Video eats the credits** (2026-11-19): each account gets 50 free credits a day and a video costs 9, so about five clips per account per day; stills are cheap by comparison. A pooled 1000-credit top-up comes every so often (next around 21 Nov). When a batch is big, plan which account does what, and save big video runs for after a top-up.
- **Ask for light, not events** (2026-11-19): with `subtle looping animation, seamless, no camera movement`, Omni spent the motion on one thing flying across the pond. The cinemagraph prompt spreads it over shimmer, reflections and swaying reeds instead, which reads as alive rather than busy. A stronger version (sweeping sunbeams, cloud shadows, waves through the grass) doubled the movement but added sunbeams over open ground that a drawn mask would cut off, so the gentler one was kept. Keep creatures out of stills meant for video: Omni animates them across the frame.
- **Generating in Flow** (2026-11-19): stills cost 0 credits on Nano Banana 2.1, High, x1. Attach the style reference by searching the asset picker for "style" and choosing Add to prompt; it clears after every submit. The X in the prompt box clears the prompt and its references; close the settings popup with Escape instead. Retitle each image by clicking its title in the image view.
- **"Not enough credits" after a submit** (2026-11-20): with x2 at 19 credits, the clips generated and then a "not enough credits" popup appeared, because the 1 credit left can't cover another run. Check the grid for the new clips before assuming the run failed. When regenerating a clip, rename the old one in Flow (`_old`) first, so the titles don't clash.
- **Each clip drifts in colour** (2026-11-20): over its 3 s a Flow clip slowly shifts its overall tint, so the picture snapped every 3 s at the join and the wrap (about 20x a normal frame step). Locking each frame's coarse colour to the still cut the jump by about three quarters and keeps fine motion (shimmer, ripples, reeds); a 96x54 grid beat 48x27 by eye. It also makes the clip match the painting where Code masks it. When a loop jumps every few seconds, check the colour lock ran before regenerating.
- **The video redraws everything, not just what moves** (2026-11-19): it comes back at 720p with every ink line slightly re-rendered (the colours stay true). So the game plays the masked clip, where everything that doesn't move stays at the painting's own sharpness (DECISIONS, 2026-11-19).
- **Some movement sits on the ground, some in front of Pip** (2026-11-19): on the marsh the fronds and bulrushes should cover Pip, and the puddle glints should go under him. Don't make a mask for what covers him: layer the screen in Affinity like a still one (`screens-layering.md`); the sent shapes draw the video's pixels over him.
- **PyAV reads `.ogv` frames on this PC** (2026-11-19, M4): there's no ffmpeg on the PATH, but `import av` (PyAV 18) decoded the marsh loop frame by frame for the motion check. When you need a video's frames in Python, try `av.open(path).decode(video=0)`.
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
- **A sharp corner in a walk area snags Pip** (2026-11-20, M4): Pip slides along an edge one axis at a time, so on the boardwalk the corner at (1335, 303) stopped him walking straight up until he stepped right. When drawing a walk area, keep corners that point into the path shallow.
