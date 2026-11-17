#!/usr/bin/env bash
# Which screens still need layering? tools/layering_status.sh
# A screen counts as layered when its scene's Overhead node carries `metadata/layered = true`, which
# tools/layers_to_game.gd sets on every send (an empty send means "needs none"). Nothing else is recorded.
# Output, one line per screen, tab separated:  TODO|DONE  screen  painting  note
set -euo pipefail
cd "$(dirname "$0")/.."
work="${PIP_LAYER_DIR:-}"
if [ -z "$work" ]; then
  for d in "${USERPROFILE:-$HOME}/OneDrive/Desktop/PipFF7_layering" "${USERPROFILE:-$HOME}/Desktop/PipFF7_layering"; do
    [ -d "$d" ] && work="$d" && break
  done
fi
todo=0
for scene in scenes/screens/*.tscn; do
  s=$(basename "$scene" .tscn)
  painting=$(ls assets/screens/"$s"/*_bg.* 2>/dev/null | grep -v '\.import$' | head -1 || true)
  if grep -q '^metadata/layered = true' "$scene"; then
    printf 'DONE\t%s\t%s\t%s overlay sprite(s)\n' "$s" "${painting:--}" "$(grep -c '^\[node name="Occ_' "$scene" || true)"
  else
    todo=$((todo + 1))
    note=""
    [ -n "$work" ] && [ -f "$work/$s.afdesign" ] && note="already open in the work folder, nothing sent"
    printf 'TODO\t%s\t%s\t%s\n' "$s" "${painting:--}" "$note"
  fi
done
echo "$todo screen(s) still to layer" >&2
