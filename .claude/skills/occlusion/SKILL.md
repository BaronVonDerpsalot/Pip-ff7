---
name: occlusion
description: Make Pip hide correctly on a Pip FF7 screen, mostly automatically. Runs Depth Anything V2 Large and SAM 3 on ComfyUI (MimicPC, hosted GPU) through the person's Chrome, imports the depth map and masks, proposes a first-guess walk area, turns posts, reeds and banks into Auto_ shapes, probes them in Godot and hands the person a probe sheet to judge, then folds in anything they mark by hand. Use for /occlusion <screen>, /occlusion <screen> <screen>, "do the occlusion for <screen>", "hide Pip on the new screen", or when a new screen needs its walk area and hide-Pip shapes.
---

# Occlusion for a screen

How it works, its tools and gotchas: `docs/recipes/screens-layering.md`, "Depth occlusion", and for the MimicPC machine
itself `docs/recipes/comfyui.md`. Read them first. The screen's
scene must exist (`docs/recipes/screens-flow.md`): `scenes/screens/<screen>.tscn` with its painting
`assets/screens/<screen>/<screen>_bg.jpg` and a `WalkArea` (any rough polygon will do; step 3 replaces it).
Python: `PY=../segment-env/venv/Scripts/python.exe`, run from the repo root. Board: claim the card first, and say on it
what you did and saw.

## 1. GPU run on ComfyUI (the person starts the machine)
1. Ask the person to start MimicPC from their saved ComfyUI template (it has the nodes and `models/sam3/sam3.pt`) and
   paste its URL. Don't extend or stop the machine yourself: it costs money. Don't install nodes on it: `comfyui.md` says
   which packs break it.
2. Claude in Chrome (load its tools in one ToolSearch): `tabs_context_mcp`, then a new tab at the URL.
3. Upload the paintings: with `javascript_tool`, add `<input type=file multiple id=pipup aria-label="pip upload">` to
   the page, `find` it, `file_upload` the `_bg.jpg` paths to it.
4. Paste the whole of `tools/depth/comfy_queue.js` into `javascript_tool`, then run
   `await pipOcc.upload(document.getElementById('pipup'), ["<screen>", ...])` (same order as the files), and
   `await pipOcc.queue("<screen>")` for each screen. Poll `await pipOcc.status()` every ~40 s (a call longer than
   ~40 s times out) until "all done". About 1 min a screen on a T4. Errors: read the status line; a gated-model
   error on SAM 3 means `sam3.pt` is missing from `models/sam3/` (the person puts it there, `comfyui.md`).
5. Download: in MimicPC's right-hand storage panel open `output` → `pip` → `comfy`, tick the select-all box by "Name",
   click ⋮ (next to the refresh icon) → Download → Zip File, wait for "files packed successfully", click its
   Download button. Chrome saves to `../preprocessing/_inbox/` (newest `public_temporary_task_compression_*.zip`).
6. Tell the person the GPU part is done and they can stop the machine.

## 2. Import
`$PY tools/depth/comfy_import.py "<zip>" <screen> ...`: masks to `tools/depth/comfy/<screen>/`, the depth map into
the game's format at `assets/screens/<screen>/<screen>_depth.png`. Look at the depth map (nearer whiter, sky dark).

## 3. Walk area (first guess, the person adjusts)
`$PY tools/depth/walk_guess.py <screen>` and look at `../segment-env/out/walk/<screen>.jpg` (guess red, current yellow).
For a new screen, `--write` it into the scene and send the picture: the person adjusts the points in the editor (F
shows it in game) and says when. The guess runs onto bank lips; that's wanted (Pip walks up to the bank and is
hidden by it, recipe). Also suggest exits where the guess meets the picture's edge (printed), per screens-flow.md
step 7. On a screen whose walk area the person has already adjusted, don't `--write`: just report the agreement.

## 4. Shapes
After the walk area is settled (banks are cut along it, so redo this whenever it moves):
```bash
$PY tools/depth/mask_shapes.py <screen> post  tools/depth/comfy/<screen>/<screen>_sam3_wooden_post_mask.png
$PY tools/depth/mask_shapes.py <screen> reeds tools/depth/comfy/<screen>/<screen>_sam3_reeds_mask.png
$PY tools/depth/mask_shapes.py <screen> bank  tools/depth/comfy/<screen>/<screen>_sam3_grassy_bank_mask.png --banks
```
Add `--raised=<hand mask>` to the bank line once the person has marked raised bank (step 6). A screen with older
`Auto_` sprites from `auto_occ.py` (`Auto_1`, ...) keeps them unless you pass `--clear` on the first line.
Look at each `../segment-env/out/auto/<screen>/<kind>_overlay.jpg`. Then `godot --headless --path . --import` (or let
the editor import), and run the screen once with Ziva's `run_scene` for errors.

## 5. Probe sheet
`$PY tools/depth/probe_sheet.py <screen>`, then `run_scene res://tools/_probe/probe.tscn` (duration ~8000; it quits by
itself, and an "Integer division" warning is harmless), then `$PY tools/depth/probe_sheet.py <screen> --finish`.
Look at `../segment-env/out/probe/<screen>.png` yourself (left shapes on, right off) and send it with SendUserFile.
`run_scene` refuses while the person is playing the game: say what you want to run and wait for them to stop it.

## 6. The person walks it; fold in what they mark
Ask them to walk Pip on the screen. For anything not hidden that should be (SAM 3 misses some raised bank), send
`../segment-env/out/auto/<screen>/bank_overlay.jpg` (or a crop of it) and ask them to paint red, about 60%
opacity, over everything that should hide Pip. Then
`$PY tools/depth/hand_mask.py <what you sent> <their image> tools/depth/comfy/<screen>/<screen>_bank_hand_mask.png [--crop=x0,y0,x1,y1]`,
show them the marks over the painting, and redo step 4's bank line with `--raised=` that mask, then step 5.
Don't trim the walk area to fix a bank: being able to walk behind a bank is wanted (Mike, 2026-11-24).

## 7. Finish
Stage files by name (`git status` first): the depth map, `tools/depth/comfy/<screen>/`, `assets/screens/<screen>/auto/`
(PNGs and `.import`), the scene. One outcome per commit, push. On the card: what ran, the probe sheet's verdict,
what the person marked. The card goes to the person until they've walked the screen. If a screen still has
Affinity `Occ_` shapes, they can stay switched off (`process_mode = 4`, `visible = false`) as the slice screens' are.
