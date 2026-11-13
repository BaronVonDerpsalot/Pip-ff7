# Recipe: Pip from Blender

Pip is never generated. Every frame comes from his rig. Rig details (bones, axes, weights): `pip-rig.md`.

## Files (kept out of git)
On Mike's PC in `Pip FF7/kept-assets/blender/`:
- `pip3d_named.blend`: the master model. Weights cleaned up, bones renamed. Use this one.
- `pip_sketchtest.blend`: the look setup (Line Art pencil strokes, watercolour fill, camera).
- `pip_sketchtest_sprites.blend`: the same setup with the keyed loops that made the current sprite set.
- `pip3d_bone_map.json`: old bone names to new. `pip_poses_named.json`: the pose spec in the new names.
- The untouched original is in Mike's Eagle library. Always work on a copy.

The current sprite set is in `Pip FF7/kept-assets/sprites/`: walk, idle and bored loops in five directions (down, down-right, right, up, up-right), as GIFs, sheets and single frames. The other three directions are mirrors.

## Steps
1. Pose and key the loop on the rig. Render-only proportion tweaks (head ×1.16, slightly chubbier body) live on the pose, never on the model.
2. Fill: toon shading (one sun light, three hard tone bands, flat eyes, a lighter belly oval) with a soft watercolour blotch multiplied over it.
3. Lines: Line Art traces the model as pencil strokes, which are subdivided, doubled and given a wobble that re-randomises every 2 frames.
4. Camera: orthographic, 22 degrees of elevation, the same for every direction. Rotate the character, not the camera.
5. Render 320px transparent frames with the feet at a fixed anchor (160, 276). Mirror for the left-facing directions.
6. Multiply a paper grain over the frames, then pack them into sheets.

## Gotchas
- Through the Blender MCP, changes made by script don't mark the file as unsaved. Save explicitly.
- Rendered frames come back as base64 up to about 2 MB per call, so render one direction per call.
- Blender 5.2's Line Art modifier type is `LINEART`; it has `radius` and no `thickness`.
- To raise an arm, rotate `upper_arm.*`, never `shoulder.*` (its head is on the body centreline, so the arm swings through the torso). Pose limbs first and any body twist last.
- Use a pose file that matches the `.blend`: `pip_poses_named.json` goes with `pip3d_named.blend`.
- Arms are thin and have no hands: use arm poses for silhouette, not hand detail.
- Don't colour-grade Pip to match a screen. He stays full colour.
