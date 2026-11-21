# Recipe: Pip from Blender

Pip is never generated. Every frame comes from his rig. Rig details (bones, axes, weights): `pip-rig.md`.

## Files (kept out of git)
On Mike's PC in `Pip FF7/kept-assets/blender/`:
- `pip3d_named.blend`: the master model. Weights cleaned up, bones renamed. Use this one.
- `pip_sketchtest.blend`: the look setup (Line Art pencil strokes, watercolour fill, camera).
- `pip_sketchtest_sprites.blend`: the same setup with the keyed loops that made the current sprite set.
- `pip3d_bone_map.json`: old bone names to new. `pip_poses_named.json`: the pose spec in the new names.
- The untouched original is in Mike's Eagle library. Always work on a copy.

## Where the sprites live
- **The game's sheets are in the repo**, in `assets/pip/`: one `pip_<kind>_<direction>_sheet.png` per loop, 320px frames side by side. This is the copy that counts.
- `Pip FF7/kept-assets/sprites/` (outside git) keeps the extras: GIFs, single frames, and loops the game doesn't use yet (bored).
- Five directions are rendered (down, down-right, right, up-right, up); the game mirrors them for the other three.

## Steps
1. Pose and key the loop on the rig. Render-only proportion tweaks (head ×1.16, slightly chubbier body) live on the pose, never on the model.
2. Fill: toon shading (one sun light, three hard tone bands, flat eyes, a lighter belly oval) with a soft watercolour blotch multiplied over it.
3. Lines: Line Art traces the model as pencil strokes, which are subdivided, doubled and given a wobble that re-randomises every 2 frames.
4. Camera: orthographic, 22 degrees of elevation, the same for every direction. Rotate the character, not the camera.
5. Render 320px transparent frames with the feet at a fixed anchor (160, 276). Mirror for the left-facing directions.
6. Multiply a paper grain over the frames, then pack them into sheets. The grain is one fixed 320px texture used on every frame of every sheet, at strength 0.15 (light), normalised so his overall brightness doesn't shift: `kept-assets/sprites/_grain/grain.py` (`make_grain()`, `apply()`), with the texture saved as `pip_paper_grain_320.png` beside it. Grain the clean sheets kept in `kept-assets/sprites/`, never sheets that are already grained. Name each `pip_<kind>_<direction>_sheet.png` and put it in the repo's `assets/pip/` (GIFs and single frames go to `kept-assets/sprites/`).
7. Let the editor import the sheets, then rebuild Pip's animations with `BuildPipFrames.build()` (`tools/build_pip_frames.gd`, e.g. from Ziva's `execute_script`). Every sheet becomes an animation named `<kind>_<direction>`. Run the marsh scene and check he walks.

## Run and creep
The game handles running (L3 or Shift) and creeping (a gentle push, or holding C), with its own loop for each in all five directions. To re-render them:
1. Key a run loop and a creep loop on the rig. A run leans forward with longer strides and both feet briefly off the ground. A creep is low, slow and careful, with the knees bent.
2. Render and pack them exactly like the walk (steps 2–6 above): the same five directions, 320px frames, feet at (160, 276), the same camera, lines and paper grain.
3. Name them `pip_run_<direction>_sheet.png` and `pip_creep_<direction>_sheet.png`, with `<direction>` one of `down`, `downright`, `right`, `upright`, `up`. That's ten sheets in all, in the repo's `assets/pip/`.
4. Rebuild with `BuildPipFrames.build()`. It makes `run_<direction>` and `creep_<direction>`, at 12 and 7 frames a second (`FPS` in `tools/build_pip_frames.gd`). The game switches to them on its own, and the stand-in and flash stop for any direction that has a real sheet.
5. Run the marsh and check each gait in a few directions. If a loop's stride doesn't match how fast Pip slides, adjust `run_speed`/`creep_speed` on Pip (`scripts/pip.gd`) or the loop's frame rate.

## Other characters (villagers)
Villagers are Meshy rigged models rendered with Pip's look (DECISIONS 2026-11-20). The first is the mole tinker: `kept-assets/blender/villager_mole_trial.blend`, sheets in `kept-assets/sprites/_villager_mole/`.
1. Open a copy of `pip_sketchtest.blend`, delete Pip, and import the Meshy `.glb` (Mixamo rig, several actions). Delete the stray Icosphere it brings.
2. Give the mesh the toon material (Diffuse → Shader to RGB → constant ramp → multiply with the base colour → Emission) and link it into the `PipLA` collection, or Line Art draws no pencil lines.
3. Scale the armature so the character's height relative to Pip is right (the mole: x3.37, about 1.25x Pip). Keep Pip's pixel density by growing the frame with the height: Pip is 320px at ortho 6, so a 1.25x character is 400px at ortho 7.5.
4. Anchor on the rig's origin, not the bounding box: shift the camera so the world origin lands at the same fraction of the frame as Pip's (276/320 of the height, so (200, 345) in a 400px frame). Tails and leans push the bounding box around; the origin sits under the hips and stays put.
5. Walk: sample the Mixamo `Walking` action at 8 evenly spaced times across its cycle (it walks on the spot and loops). Idle: Mixamo packs have no idle, so hold the first frame of a gesture action, clear the action, and add a small breathing sway on the spine, neck and shoulders over 8 frames.
6. Render the five directions by turning the armature (0, 45, 90, 135, 180 degrees about Z), calling `bpy.context.view_layer.update()` after each turn or every direction renders the same. Save with `bpy.ops.render.render(write_still=True)` and `scene.render.filepath`; `render_viewport_to_path` writes to Blender's temp folder.
7. Grain with `grain.py` as for Pip, but `make_grain(size=400)` for 400px frames, at 0.15. Sheets are `mole_<kind>_<direction>_sheet.png` (grained) beside a `_clean` copy.

## Gotchas
- Through the Blender MCP, changes made by script don't mark the file as unsaved. Save explicitly.
- Rendered frames come back as base64 up to about 2 MB per call, so render one direction per call.
- Blender 5.2's Line Art modifier type is `LINEART`; it has `radius` and no `thickness`.
- To raise an arm, rotate `upper_arm.*`, never `shoulder.*` (its head is on the body centreline, so the arm swings through the torso). Pose limbs first and any body twist last.
- Use a pose file that matches the `.blend`: `pip_poses_named.json` goes with `pip3d_named.blend`.
- Arms are thin and have no hands: use arm poses for silhouette, not hand detail.
- Don't colour-grade Pip to match a screen. He stays full colour.
- Every sheet needs the same grain at the same strength, or his texture changes when he switches gait.
- Run and creep are keyed by `kept-assets/blender/pip_runcreep_gen.py` (also a text block in `pip_runcreep_work.blend`). It poses legs by phase, then plants each stance foot by adjusting hip height and leg extension.
- **Rebuilding Pip's frames from a script drops their uids** (2026-11-13, M4): `BuildPipFrames.build()` run from `execute_script` saved `pip_frames.tres` without its own uid (`uid://dt72edp4e1f1l`) or the sheets' uids. It was committed and pushed like that. When you rebuild from a script, compare the file's header with the last commit before committing, and put the uids back from each sheet's `.import` file if they've gone. Nothing broke this time, because `pip.tscn` loads the file by path.
- **Win: measure the feet, not the whole frame** (2026-11-13, M4): in the side and diagonal views, the run and creep leans move the body's bounding box 25–30px ahead of centre, though the feet stay centred. When checking that the feet sit on the contact shadow, try `get_used_rect` on just the bottom 25 rows of each frame.
