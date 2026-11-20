# Recipe: shader motion on a still screen

A still screen made to move by shaders instead of a Flow video: water ripples in place, reeds and grass sway from their roots. No credits, no video in the build, and everything that doesn't move stays at the painting's own sharpness. Trialled on the stream, 2026-11-20 (DECISIONS). For a screen that already has a video loop, use that instead; a screen has one `Loop` or the other.

## Setup (once per PC)
The models run locally (an NVIDIA GTX 1050 Ti with 4 GB is enough). The environment lives next to the repo in `../segment-env/` (outside git, about 6 GB with the models):
1. `py -3.12 -m venv ../segment-env/venv`
2. `../segment-env/venv/Scripts/python.exe -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cu126`, then `pip install transformers pillow numpy opencv-python-headless accelerate` and `pip install --no-deps simple-lama-inpainting`.
3. Set `HF_HOME=../segment-env/hf` and `TORCH_HOME=../segment-env/torch` before running, so the models (Grounding DINO tiny, SAM 2.1 small, big-lama) download there on first use.

## Steps
1. **Spec.** Write `tools/segment/specs/<screen>.json` (copy `stream.json`): the painting, then groups of kind `water`, `sway` or `still`, each found by words and/or by a hand-given box with points inside and outside. Look at the painting to pick them. The script's docstring lists every option.
2. **Segment.** `../segment-env/venv/Scripts/python.exe tools/segment/segment.py tools/segment/specs/<screen>.json ../segment-env/out/<screen>`, about 30 s per screen once the models are cached. Look at `preview.jpg` (blue water, green sway, red still) and fix the spec until it's right.
3. **Into the game.** Copy `plate.png`, `water_mask.png`, `sway_<k>.png` and `manifest.json` to `assets/screens/<screen>/motion/`, import (`godot --headless --path . --import`), then run `MotionToGame.build("<screen>")` with Ziva's `execute_script` (`tools/motion_to_game.gd`). `build("<screen>", false)` gives water only.
4. **Check.** Run the screen and walk Pip behind something. For a capture to approve, run `tools/capture_stream.tscn` (or a copy pointing at the screen) for 7 s; it writes 4 s of half-size JPGs to `user://capture/`. Join them into an animated WebP with PIL (`save_all=True, duration=50`) in `kept-assets/screen-motion/`; a GIF of the same frames was 33 MB, the WebP 4 MB.
   Affinity is only for when a mask is wrong and a spec can't fix it: paint the fix on a copy of `<group>_mask.png` there and rerun from step 3.
5. **Tune** on the `Loop/SubViewport` nodes' materials. A rebuild overwrites hand tuning.
   - Sway (`motion_sway.gdshader`): `amp` (tip travel, px; the builder gives height/60, 4 to 14, and the spec's `pad` must stay above about 1.3 × the largest), `speed` (the builder spreads each clump between 0.16 and 0.28 cycles/s), `gustiness`, `lean`, `stiffness`.
   - Water (`motion_water.gdshader`): a spec's water groups each say `"flow": true` (river: `river_amp`, `river_speed`, `river_flow` as a direction, `river_glints`) or `false` (puddles and ponds: `pond_amp`, `pond_speed`, `pond_glints`, `rings`, `ring_cell`, `ring_rate`); `shimmer` is shared. A river also gets a flow map (`<river>_flow.png`, made automatically), so its ripples follow its bends at `river_px_per_s`; `river_flow` is only used without one.
   Both shaders are our own, built from tricks common on godotshaders.com (noise-driven distortion, crest glints, spawned rings), so there's no licence to track.

## How it fits together
- `Loop` (`scripts/screen_motion.gd`) draws a SubViewport holding the plate and the sway pieces, and hides `Background`. It answers `get_video_texture()` like the video `Loop`, so the `Occ_` sprites draw its moving pixels over Pip unchanged.
- The plate is the painting with LaMa's guess only under the reed blades, so the gaps between blades keep the painting's own pixels at rest. A blade's sway uncovers only a few pixels of the guess.

Gotchas
- **A detector box can swallow the bank** (2026-11-20): asked for "water", Grounding DINO gives one box over half the screen, and SAM traces the grass and the path with it. Ignore big boxes (`max_box`) and give big water a hand box with points instead; SAM's best-scoring guess traced the stream cleanly and left the lily pads out.
- **"cattail reeds. tall grass." missed single cattails** (2026-11-20): two in the left foreground stayed still while the clump swayed. Adding "cattail." (threshold 0.25) to the sway words caught the whole clump with its cattails. When a tall plant is left still, try its plain name as an extra word before reaching for a hand box.
- **"puddle." also finds a river's narrow reach** (2026-11-20): on the stream it boxed the upstream channel (6% of the screen) along with the real puddles (2% or less). With river and puddles moving differently, cap the puddle group at `max_box` 0.03 and give the channel to the river as a hand box.
- **A flow map from one end fans out** (2026-11-20): measuring distance along the water from the upstream end alone pointed the wide foreground stream straight down, radiating from under the bridge. Taking it from both ends (upstream minus distance from the far end) ran it along the channel, and the drift measured in the capture matched the map (cos 0.98 foreground, 0.89 upstream). When ripples look like they flow the wrong way, draw the map as arrows on the painting before touching the shader.
- **Cattail heads read as "mushroom"** (2026-11-20): they then froze while their stems swayed. When a `still` group's words catch tall things, cap it with `max_side`.
- **LaMa can't invent a reed bed** (2026-11-20): with the whole clump inpainted, the plate came out as fog, and the gaps between blades would have shown it at rest. Keep the painting outside the blades (the script does).
- **Don't load and re-save a screen scene headless** (2026-11-20): in `execute_script` the `ScreenChanger` autoload isn't there, so `screen.gd` fails to compile and `PackedScene.pack` writes the scene without its script, uids or Pip's instance. Edit the `.tscn` as text, as `motion_to_game.gd` and `layers_to_game.gd` do.
