"""Put shapes from a text-prompt mask (SAM 3 on ComfyUI, tools/depth/comfy/<screen>/) into a screen as Auto_ sprites
on the bottom-edge rule (scripts/occluder.gd), beside whatever Auto_ sprites are already there.

  ../segment-env/venv/Scripts/python.exe tools/depth/mask_shapes.py <screen> <kind> <mask.png>[,<mask.png>...]
      [--banks [--raised=<mask.png>]] [--clear]

Several masks, comma-separated, are joined first. --raised adds bank a person has marked as raised that SAM 3
missed (tools/depth/comfy/marsh/marsh_bank_hand_mask.png, the mossy bank by the bend, 2026-11-24): it counts
inside the walk area too, so Pip standing in it is hidden by it.

<kind> names the set (reeds, bank, ...): sprites go to assets/screens/<screen>/auto/<screen>_<kind>_<k>.png and
nodes Auto_<kind>_<k> under Overhead, just above DepthOcc. A rerun replaces that kind only. --clear also removes
every other Auto_ sprite (for replacing the Illustrator's Depth banks); their PNGs are left for git rm.
Without --banks, each connected piece of 64 px or more is a shape, and its own lowest pixels are its bottom edge.
With --banks, the mask is first cut at the walk area by tools/depth/cut_banks.py (behind / in front / lip), since
a bank mask merged with what lies below it would hide Pip almost anywhere.
Writes ../segment-env/out/auto/<screen>/<kind>_overlay.jpg to look at. Import afterwards
(godot --headless --path . --import).
"""
import os
import re
import sys

import cv2
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import cut_banks  # noqa: E402

MIN_PX = 64


def load(paths: str) -> np.ndarray:
    m = np.zeros((cut_banks.H, cut_banks.W), bool)
    for p in paths.split(","):
        m |= np.array(Image.open(p).convert("L")) >= 128
    return m


def pieces(mask_path: str, banks: bool, tscn: str, painting: str, raised_path: str | None) -> list:
    m = load(mask_path)
    if not banks:
        n, lab = cv2.connectedComponents(m.astype(np.uint8))
        return [lab == i for i in range(1, n) if (lab == i).sum() >= MIN_PX]
    raised = load(raised_path) if raised_path else None
    if raised is not None:
        m |= raised
    return cut_banks.cut(cut_banks.grow_ink(m, painting), cut_banks.walk_polygon(tscn), raised)[0]


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    screen, kind, mask_path = args
    missing = [p for p in mask_path.split(",") if not os.path.exists(p)]
    if missing:
        sys.exit(f"{screen}: no {', '.join(missing)}; nothing changed (that prompt wasn't run for this screen)")
    banks, clear = "--banks" in sys.argv, "--clear" in sys.argv
    raised_path = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--raised=")), None)
    scene_path = f"scenes/screens/{screen}.tscn"
    tscn = open(scene_path, encoding="utf-8").read()
    bg = re.search(rf'path="res://(assets/screens/{screen}/[^"]+_bg\.jpg)"', tscn)
    painting = bg.group(1) if bg else next(f"assets/screens/{screen}/{f}" for f in os.listdir(f"assets/screens/{screen}")
                                            if f.endswith("_bg.jpg"))
    rgb = np.asarray(Image.open(painting).convert("RGB"))
    asset_dir = f"assets/screens/{screen}/auto"
    os.makedirs(asset_dir, exist_ok=True)
    for f in os.listdir(asset_dir):
        if f.startswith(f"{screen}_{kind}_") and f.endswith(".png"):  # .import files keep their uids
            os.remove(os.path.join(asset_dir, f))

    shapes = pieces(mask_path, banks, tscn, painting, raised_path)
    entries = []
    for k, mk in enumerate(shapes, 1):
        ys, xs = np.where(mk)
        x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        rgba = np.dstack([rgb[y0:y1, x0:x1], mk[y0:y1, x0:x1].astype(np.uint8) * 255])
        name = f"{screen}_{kind}_{k}.png"
        Image.fromarray(rgba).save(os.path.join(asset_dir, name))
        entries.append((f"auto_{kind}_{k}", f"{asset_dir}/{name}", int(x0), int(y0)))

    lines, kept, i = tscn.split("\n"), [], 0
    drop_node = (lambda ln: ln.startswith('[node name="Auto_')) if clear else \
        (lambda ln: ln.startswith(f'[node name="Auto_{kind}_'))
    drop_ext = (lambda ln: ' id="auto_' in ln) if clear else (lambda ln: f' id="auto_{kind}_' in ln)
    while i < len(lines):
        ln = lines[i]
        if drop_node(ln):
            i += 1
            while i < len(lines) and not lines[i].startswith("["):
                i += 1
            continue
        if ln.startswith("[ext_resource") and drop_ext(ln):
            i += 1
            continue
        kept.append(ln)
        i += 1
    ext = [f'[ext_resource type="Texture2D" path="res://{f}" id="{n}"]' for n, f, _, _ in entries]
    if entries and not any('path="res://scripts/occluder.gd"' in ln for ln in kept):
        ext.insert(0, '[ext_resource type="Script" path="res://scripts/occluder.gd" id="occ_script"]')
    script_id = next((re.search(r' id="([^"]+)"', ln).group(1) for ln in kept + ext
                      if 'path="res://scripts/occluder.gd"' in ln), "occ_script")
    nodes = []
    for n, _, x, y in entries:
        nodes += [f'[node name="A{n[1:]}" type="Sprite2D" parent="Overhead"]', f"position = Vector2({x}, {y})",
                  f'texture = ExtResource("{n}")', "centered = false", f'script = ExtResource("{script_id}")', ""]
    last_ext = max(j for j, ln in enumerate(kept) if ln.startswith("[ext_resource"))
    kept[last_ext + 1:last_ext + 1] = ext
    at = next(j for j, ln in enumerate(kept) if ln.startswith('[node name="DepthOcc"'))
    kept[at:at] = nodes
    open(scene_path, "w", encoding="utf-8", newline="\n").write("\n".join(kept))

    out_dir = f"../segment-env/out/auto/{screen}"
    os.makedirs(out_dir, exist_ok=True)
    ov = rgb.astype(float)
    for k, mk in enumerate(shapes):
        c = np.array(((80, 120, 255), (60, 220, 90), (255, 200, 0), (255, 80, 200))[k % 4])
        ov[mk] = ov[mk] * 0.4 + c * 0.6
    Image.fromarray(ov.astype(np.uint8)).save(f"{out_dir}/{kind}_overlay.jpg", quality=85)
    print(f"{screen}: {len(entries)} {kind} shapes -> {asset_dir}, {scene_path}, {out_dir}/{kind}_overlay.jpg")


if __name__ == "__main__":
    main()
