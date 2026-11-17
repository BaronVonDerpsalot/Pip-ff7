#!/usr/bin/env bash
# Brings layers sent from Affinity into the game: tools/send_layers.sh <screen> [work folder]
# Run from anywhere. Needs Godot 4.7 (set GODOT, or it uses the path in docs/recipes/godot.md).
# The work folder is where Affinity's "Send layers" script writes (default: Desktop/PipFF7_layering).
set -euo pipefail
cd "$(dirname "$0")/.."
screen="${1:?usage: tools/send_layers.sh <screen> [work folder]}"
work="${2:-${PIP_LAYER_DIR:-}}"
if [ -z "$work" ]; then
  for d in "$USERPROFILE/OneDrive/Desktop/PipFF7_layering" "$USERPROFILE/Desktop/PipFF7_layering"; do
    [ -d "$d" ] && work="$d" && break
  done
fi
[ -d "${work:-}" ] || { echo "No work folder found; pass it as the second argument." >&2; exit 1; }
godot="${GODOT:-C:/Games/Godot/Godot_v4.7.2-stable_win64_console.exe}"
"$godot" --headless --path . -s tools/layers_to_game.gd -- "$screen" "$work" 2>&1 | grep -vE "^\[|Ziva|Godot Engine|^$" || true
# Import the new images so the editor and a run see them (see docs/recipes/godot.md).
"$godot" --headless --path . --import >/dev/null 2>&1
echo "Imported."
