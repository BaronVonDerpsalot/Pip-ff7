---
name: layering
description: Layer Pip FF7 screens with the person in Affinity. Opens the painting of one screen, several, or every screen not yet layered, then watches for their "Send layers" and brings each layer into the game as an overlay sprite, runs it and shows the result. Use for /layering <screen>, /layering all, "layer the marsh", "layer the rest", "open <screen> in Affinity", or when the person says they've sent layers.
---

# Layering screens in Affinity

How it works, what a layer is, and gotchas: `docs/recipes/screens-layering.md`. Read it first. Screens are the scenes in `scenes/screens/<screen>.tscn`.

Work in the Affinity MCP: load the tools with ToolSearch, and read the SDK `preamble` topic before the first script.

## 0. Which screens
- `/layering marsh` or `/layering marsh stream`: just those.
- `/layering all` (or "the rest"): run `bash tools/layering_status.sh`. Every `TODO` line is a screen whose scene doesn't carry `metadata/layered = true` yet. Screens that don't have a scene yet aren't listed: they need building first (`screens-flow.md`), and then appear here on their own. Tell the person the list before opening anything.
- A screen already `DONE` is only reopened when they ask for it by name (re-layering is always allowed).

## 1. Open the screens
For each screen:
1. Copy its painting (third column of the status line, or `assets/screens/<screen>/<screen>_bg.jpg`) into the work folder, because Affinity can only read the Desktop:
   ```bash
   mkdir -p "$USERPROFILE/OneDrive/Desktop/PipFF7_layering"
   cp assets/screens/<screen>/<screen>_bg.jpg "$USERPROFILE/OneDrive/Desktop/PipFF7_layering/"
   ```
   (`$USERPROFILE/Desktop` if there's no OneDrive Desktop.)
2. In `execute_script`: `const d = Document.load(<desktop>/PipFF7_layering/<painting>); d.saveAs(<desktop>/PipFF7_layering/<screen>.afdesign);`. The document name must be the screen name. If `<screen>.afdesign` already exists, `Document.load` that instead so earlier work isn't overwritten, and check `Document.all` first for one that's already open. Do all the screens in one script.
3. Check **Pip FF7 - Send layers v2** is in the library (`list_library_scripts`). If not, save `tools/affinity/send_to_game.js` with `save_script_to_library`. The library can't overwrite or delete, so a changed script needs a new title (v3, ...) and the person deleting the old one in the Scripts panel.
4. Tell the person what's open and how it works: no naming needed. The bottom layer is the painting; every visible layer above it is an overlay drawn in front of Pip, whatever it's called. Run the script from the Scripts panel. **A screen with no layers above the painting, sent as it is, means "this needs none"** and still counts as done.

## 2. Watch for sends
Start a Monitor (timeout 30 minutes, re-arm when it expires) on the `*__READY` files in the work folder, one event per change:
```bash
d="$USERPROFILE/OneDrive/Desktop/PipFF7_layering"; declare -A seen
for f in "$d"/*__READY; do [ -e "$f" ] && seen["$f"]=$(stat -c %Y "$f"); done
while true; do for f in "$d"/*__READY; do [ -e "$f" ] || continue; m=$(stat -c %Y "$f")
  if [ "${seen[$f]:-}" != "$m" ]; then seen["$f"]=$m; echo "SENT $(basename "$f" __READY)"; fi; done; sleep 1; done
```
It watches every screen at once, so a batch needs only one watcher. Don't poll in any other way. It only works while this chat is open.

## 3. On `SENT <screen>`
1. `bash tools/send_layers.sh <screen>`. It prints each layer's position, anything skipped, and `DONE`. If a layer is missing, say why (hidden, empty, not a pixel layer). An empty send prints `DONE 0 layer(s)`: say the screen is marked as needing none.
2. One screen: run it with Ziva's `run_scene` (if it refuses because the person is playing, ask them to stop their game), walk Pip where a layer should hide him (about 360 px per second; the walk area is `WalkArea` in the scene), zoom in on the screenshot if the overlap is small, and say what you saw: which layers cover him and where, and anything wrong. A batch: don't stop after each screen. Collect the lines and review at the end (step 4).
3. Don't tick any card for it; judging by eye is the person's call.

## 4. End of a run
Run `bash tools/layering_status.sh` again and report what's left. For a batch, run each screen sent in this run once with `run_scene`, with Pip standing where the overlays should meet him, and give one screenshot each so they can be reviewed together. Say what's still `TODO`. Suggest a board card for any large run to come, but don't create one.

Nothing here is committed unless the person asks.
