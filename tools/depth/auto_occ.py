"""Find the things on a screen that should hide Pip but that depth occlusion misses, and cut them as shapes
(docs/recipes/screens-layering.md, "Automatic shapes"). Runs in the tools/segment environment.

  ../segment-env/venv/Scripts/python.exe tools/depth/auto_occ.py <screen> [--banks] [--scene]

Two kinds:
  posts  found by words ("wooden post.") and traced with SAM 2.1 (tools/segment), each a shape on the
         bottom-edge rule (scripts/occluder.gd). Depth can't tell a thin post from the planks just behind it.
  banks  only with --banks: low banks along the path, which depth can't tell from the path. Needs the
         screen's layer map from tools/depth/layers.py (Illustrator's Depth) first. Near each walk-area edge
         that faces the camera (its outside is lower on the screen), whatever is on a higher layer than the
         path just inside that edge. Each shape covers Pip only while his feet are behind that edge (its
         `edge` line), since its own lowest pixels can sit below path he walks in front of. The walk area
         runs up onto a bank's lip, so a shape reaches inside it.
         Off by default: beside a bridge or a flat path it also takes flat ground at the edge and hides
         Pip's feet (2026-11-22), so a person decides per screen.

Writes assets/screens/<screen>/auto/<screen>_auto_<k>.png (painting pixels, cropped) and
../segment-env/out/auto/<screen>/manifest.json (and overlay.jpg to look at). --scene also replaces every
Auto_ sprite under Overhead in scenes/screens/<screen>.tscn; Occ_ sprites from Affinity are left alone.
Import afterwards (godot --headless --path . --import).
"""
import json
import os
import re
import sys

import cv2
import numpy as np
import torch
from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "segment"))
import segment  # noqa: E402

POST_WORDS = "wooden post."
BANK_TOL = 0.03        # how much higher a layer than the path (0..1 of the layer map's range) a bank must be
NEAR = 90              # bank shapes reach this many px from their edge, either side
INSIDE = 35            # the path is read further than this inside the edge
MIN_PX = 64


def walk_polygon(tscn: str) -> np.ndarray:
    p = re.search(r'\[node name="WalkArea".*?polygon = PackedVector2Array\(([^)]*)\)', tscn, re.S).group(1)
    return np.array([float(v) for v in p.split(",")]).reshape(-1, 2)


def sam(image, device, box, points=None, labels=None, multi=False):
    proc, model = segment._model("sam", device)
    kw = {"input_boxes": [[[float(v) for v in box]]]}
    if points is not None:
        kw["input_points"] = [[[list(map(float, p)) for p in points]]]
        kw["input_labels"] = [[labels]]
    inputs = proc(images=image, return_tensors="pt", **kw).to(device)
    with torch.no_grad():
        o = model(**inputs, multimask_output=multi)
    ms = proc.post_process_masks(o.pred_masks.cpu(), inputs["original_sizes"])[0][0].numpy()
    return list(zip(ms, o.iou_scores[0, 0].cpu().numpy()))


def main() -> None:
    screen = sys.argv[1]
    write_scene = "--scene" in sys.argv
    banks = "--banks" in sys.argv
    scene_path = f"scenes/screens/{screen}.tscn"
    tscn = open(scene_path, encoding="utf-8").read()
    paint = re.search(r'path="res://(assets/screens/' + screen + r'/[^"]*_bg\.jpg)"', tscn).group(1)
    device = "cuda" if torch.cuda.is_available() else "cpu"
    image = Image.open(paint).convert("RGB")
    W, H = image.size
    poly = walk_polygon(tscn)
    walk = np.zeros((H, W), np.uint8)
    cv2.fillPoly(walk, [poly.astype(np.int32)], 1)
    walk = walk.astype(bool)
    reach = cv2.dilate(walk.astype(np.uint8), np.ones((3, 3), np.uint8), iterations=40) > 0

    shapes = []  # (mask, edge line or None, kind)

    # Posts: one shape per box, kept only if it stands by the walk area (cattail heads read as posts too).
    for b in segment.detect(image, POST_WORDS, 0.25, 0.02, 99999, device):
        m = sam(image, device, b)[0][0]
        if m.sum() >= MIN_PX and (m & reach).any():
            shapes.append((m, None, "post"))
    posts = np.zeros((H, W), bool)
    for m, _, _ in shapes:
        posts |= m

    # Banks.
    if banks:
        layers = np.load(os.path.join(os.path.dirname(__file__), "..", "..", "..", "illustrators-env", "out",
                                      f"{screen}.npy"))
        taken = posts.copy()
        yy, xx = np.mgrid[0:H, 0:W]
        for a, b in zip(poly, np.roll(poly, -1, 0)):
            e = b - a
            L = float(np.hypot(*e))
            if L < 1:
                continue
            n = np.array([e[1], -e[0]]) / L
            mid = (a + b) / 2
            if walk[int(np.clip(mid[1] + n[1] * 6, 0, H - 1)), int(np.clip(mid[0] + n[0] * 6, 0, W - 1))]:
                n = -n  # outward
            if n[1] < 0.25 or min(a[1], b[1]) >= H - 5:  # not camera-facing, or along the screen's bottom
                continue
            t = np.clip(((xx - a[0]) * e[0] + (yy - a[1]) * e[1]) / (L * L), 0, 1)
            dist = np.hypot(xx - (a[0] + t * e[0]), yy - (a[1] + t * e[1]))
            path = walk & (dist > INSIDE) & (dist < NEAR)
            if path.sum() < 50:
                continue
            m = (dist < NEAR) & (layers > np.median(layers[path]) + BANK_TOL) & ~taken
            if m.sum() >= MIN_PX:
                taken |= m
                shapes.append((m, [a.tolist(), b.tolist()], "bank"))

    # Write the pieces.
    out_dir = f"../segment-env/out/auto/{screen}"
    asset_dir = f"assets/screens/{screen}/auto"
    os.makedirs(out_dir, exist_ok=True)
    if os.path.isdir(asset_dir):
        for f in os.listdir(asset_dir):
            os.remove(os.path.join(asset_dir, f))
        if not shapes:
            os.rmdir(asset_dir)
    if shapes:
        os.makedirs(asset_dir, exist_ok=True)
    rgb = np.asarray(image)
    manifest = []
    for k, (m, edge, kind) in enumerate(shapes):
        ys, xs = np.where(m)
        x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        rgba = np.dstack([rgb[y0:y1, x0:x1], m[y0:y1, x0:x1].astype(np.uint8) * 255])
        name = f"{screen}_auto_{k + 1}.png"
        Image.fromarray(rgba).save(os.path.join(asset_dir, name))
        manifest.append({"name": f"auto_{k + 1}", "file": f"{asset_dir}/{name}", "x": int(x0), "y": int(y0),
                         "kind": kind, "edge": edge})
    json.dump(manifest, open(f"{out_dir}/manifest.json", "w"), indent=1)
    ov = rgb.astype(float)
    tint = {"post": (255, 220, 0), "bank": (255, 40, 40)}
    for m, _, kind in shapes:
        ov[m] = ov[m] * 0.4 + np.array(tint[kind]) * 0.6
    cv2.polylines(ov, [poly.astype(np.int32)], True, (0, 255, 255), 2)
    Image.fromarray(ov.astype(np.uint8)).save(f"{out_dir}/overlay.jpg", quality=85)
    n_posts = sum(1 for s in shapes if s[2] == "post")
    print(f"{screen}: {n_posts} posts, {len(shapes) - n_posts} bank pieces -> {asset_dir}, {out_dir}/overlay.jpg")
    if write_scene:
        put_in_scene(scene_path, tscn, manifest)


def put_in_scene(scene_path: str, text: str, manifest: list) -> None:
    """Replace every Auto_ sprite (and its texture line) in the scene with this set, just above DepthOcc."""
    lines, kept, i = text.split("\n"), [], 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith('[node name="Auto_'):
            i += 1
            while i < len(lines) and not lines[i].startswith("["):
                i += 1
            continue
        if ln.startswith("[ext_resource") and ' id="auto_' in ln:
            i += 1
            continue
        kept.append(ln)
        i += 1
    ext = [f'[ext_resource type="Texture2D" path="res://{p["file"]}" id="{p["name"]}"]' for p in manifest]
    if manifest and not any('path="res://scripts/occluder.gd"' in ln for ln in kept):
        ext.insert(0, '[ext_resource type="Script" path="res://scripts/occluder.gd" id="occ_script"]')
    script_id = next((re.search(r' id="([^"]+)"', ln).group(1) for ln in kept + ext
                      if 'path="res://scripts/occluder.gd"' in ln), "occ_script")
    nodes = []
    for p in manifest:
        nodes += [f'[node name="Auto_{p["name"][5:]}" type="Sprite2D" parent="Overhead"]',
                  f'position = Vector2({p["x"]}, {p["y"]})', f'texture = ExtResource("{p["name"]}")',
                  "centered = false", f'script = ExtResource("{script_id}")']
        if p["edge"]:
            (ax, ay), (bx, by) = p["edge"]
            nodes.append(f"edge = PackedVector2Array({ax:g}, {ay:g}, {bx:g}, {by:g})")
        nodes.append("")
    last_ext = max(j for j, ln in enumerate(kept) if ln.startswith("[ext_resource"))
    kept[last_ext + 1:last_ext + 1] = ext
    at = next(j for j, ln in enumerate(kept) if ln.startswith('[node name="DepthOcc"'))
    kept[at:at] = nodes
    open(scene_path, "w", encoding="utf-8", newline="\n").write("\n".join(kept))
    print(f"  {len(manifest)} Auto_ sprites in {scene_path}")


if __name__ == "__main__":
    main()
