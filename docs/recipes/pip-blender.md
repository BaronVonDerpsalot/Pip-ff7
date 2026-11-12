# Recipe: Pip from Blender

Pip is never generated. Every frame comes from his rig.

## Files (kept out of git)
- `pip_sketchtest.blend`: the working setup (Line Art pencil strokes, watercolour fill, camera).
- `pip3d_fixed_weights.blend`: the cleaned-up model (weights normalised, shoulders and neck smoothed).
- The original is in Mike's Eagle library. Always work on a copy.

## Steps
1. Pose and key the loop on the rig. Render-only proportion tweaks (head ×1.16, slightly chubbier body) live on the pose, never on the model.
2. Fill: toon shading (one sun light, three hard tone bands, flat eyes, a lighter belly oval) with a soft watercolour blotch multiplied over it.
3. Lines: Line Art traces the model as pencil strokes, which are subdivided, doubled and given a wobble that re-randomises every 2 frames.
4. Camera: orthographic, 22 degrees of elevation, the same for every direction. Rotate the character, not the camera.
5. Render 320px transparent frames with the feet at a fixed anchor (160, 276). Render down, up and right; left is right mirrored.
6. Multiply a paper grain over the frames, then pack them into sheets.

## Gotchas
- Through the Blender MCP, changes made by script don't mark the file as unsaved. Save explicitly.
- Rendered frames come back as base64 up to about 2 MB per call, so render one direction per call.
- Blender 5.2's Line Art modifier type is `LINEART`; it has `radius` and no `thickness`.
- The rig has no meaningful bone names: `Bone.002_L.001` is the left upper arm, `Bone_L` the left thigh, `Bone.003` the head.
- Rotate the upper-arm bone, not the shoulder root (`Bone.002_L/R`), or the arm swings through the torso. Pose limbs first and any body twist last.
- Arms are thin with tiny hands: use arm poses for silhouette, not hand detail.
- Don't colour-grade Pip to match a screen. He stays full colour.
