# Pip's rig

Reference for anyone working with the Pip 3D model. Carried over from the old project's `docs/PIP_RIG.md`.

## Files

| File | What |
|---|---|
| `pip3d_named.blend` | Master. Weights cleaned up and bones renamed. Use this one. |
| Original (Eagle library) | Untouched, original bone names (`Bone`, `Bone.001`, `Bone.002_L.001` ...). |
| `pip3d_bone_map.json` | Old name to new name, and back. |
| `pip_poses_named.json` | Pose spec in the new names. |

## Objects
- `Cube.003`: the body mesh (5,172 verts, one texture), deformed by the armature. The ears are part of it.
- `Cube.001` / `Cube.002`: eyebrows, separate objects, parented to `brow.L` / `brow.R`.
- `Sphere` / `Sphere.001`: eyeballs, parented to `eye.L` / `eye.R`.
- No shape keys, constraints or drivers.

## Axes (armature-local; Pip faces -Y)
+X is Pip's left (the viewer's right when looking at his face), -Y is forward, +Z is up.

## Bones (new name ← original name)
- Spine: `hips` ← Bone, `spine` ← Bone.001, `chest` ← Bone.002, `head` ← Bone.003.
- Arms (L shown, R mirrors): `shoulder.L` ← Bone.002_L, `upper_arm.L` ← Bone.002_L.001, `forearm.L` ← .002, `hand.L` ← .003. Don't rotate `shoulder.*` to raise an arm; rotate `upper_arm.*`.
- Legs: `hip.L` ← Bone_L.005, `thigh.L` ← Bone_L, `shin.L` ← Bone_L.001, `ankle.L` ← Bone_L.004, `foot.L` ← Bone_L.002, `toe.L` ← Bone_L.003.
- Ears: `ear_1.L/R` ← Bone.003_L/R, `ear_2.L/R` ← Bone.003_L/R.001.
- Face (all children of `head`):
  - `jaw` ← Bone.008. Rotate +X to open the mouth; the inside is modelled. Children: `lower_lip` ← Bone.006, `lower_lip.L/R` ← Bone.003_L/R.003.
  - `upper_lip` ← Bone.005, `upper_lip.L/R` ← Bone.003_L/R.004.
  - `mouth_corner.L/R` ← Bone.003_L/R.002.
  - `nose` ← Bone.004.
  - `brow.L/R` ← Bone.003_L/R.005 (drive the eyebrow objects).
  - `lid_upper.L/R` ← Bone.003_L/R.009, `lid_lower.L/R` ← Bone.003_L/R.006 (also lifts the cheek). Both pivot on the eye centre.
  - `eye.L/R` ← Bone.003_L/R.007 (drive the eyeballs).
  - `eye_target`, `eye_target.L/R` ← Bone.007, Bone.003_L/R.008: helper bones that currently do nothing.

## Weights
Cleaned 2026-11-11: normalised per vertex, at most 4 influences per vertex (the usual engine limit), shoulders and neck smoothed, face untouched.

## Known limits
- Arms are thin and have no hands. Extreme poses (arms crossed, hands to chest) look rough.
- A slight crease at the upper back in deep spine bends.

## Posing
Rotations in the pose spec are applied in order, about the bone head, in armature-local axes. Do limbs first and body twist (`spine`, `chest`) last, or the twist turns the limb the wrong way.
