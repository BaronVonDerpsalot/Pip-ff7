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

## A still screen
1. Generate the painting at 16:9 from the style block, with no characters in it. Ask for "a raised three-quarter view".
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

## Cut-outs
`tools/cutout.gd` cuts a foreground piece straight out of the painting: it finds the ink lines inside a rough outline, bridges small gaps, fills enclosed shapes (leaves, reed heads) and keeps the painting's own colours. Because the colours are the painting's, a cut-out is invisible until Pip walks behind it, so rough edges don't show.
1. Mike marks what should hide Pip on a screenshot (blue pen works).
2. Run `Cutout.cut(painting, outline, options)` from `execute_script` for each piece and save the PNG to `assets/screens/<name>/`. Useful options: `keep = "tall"` drops flat ground lines, `keep = "top"` keeps only shapes hanging from the outline's top edge (canopies), and `source_alpha` starts from an existing mask instead of finding ink.
3. Play it, look for lines that cross Pip where they shouldn't, and erase them.
4. Works because Flow screens are ink outlines over watercolour. A soft painted shape with no outline won't cut cleanly.

Godot-side gotchas (stale imports and so on) are in `godot.md`.

## An animated screen
Untested. Written during the screen pipeline milestone. Flow's video models change often, so check the model picker rather than trusting a name written here.

## Gotchas
- Flow paints every scene in its own perspective. Asking for a flat top-down view doesn't work; judge steepness across screens instead.
- Don't use Pip's sheet as a style reference: it makes every character look like Pip, and childish. Describe the rendering style in words and ask for grounded proportions.
- Agents can't upload files into Flow (the Chrome file upload fails). Mike drags references in by hand. Don't retry in a loop.
- References and prompt text clear after every submit, so re-attach each run. Check the mode chip says Image before submitting.
- The grid reshuffles. Identify images by title, never by position. Titles are editable and a good place for scores.
- Downloads are JPEG named after the image title.
- Images kept in Drive can't be seen by the planning room. Attach them in the chat.
- **Check what's actually covering Pip** (2026-11-13, M1): a "reed blade across his belly" turned out to be faint grey wash in the old cut-out, not a reed. When judging whether Pip passes behind something, make sure the overlap is the object itself: compare with the cut-out hidden, or look at the cut-out on a bright background.
