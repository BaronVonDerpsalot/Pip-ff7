"""Score depth occlusion against a screen's Affinity Occ_ shapes, without Godot (screens-layering.md, "Win").

For Pip's feet at every 12 px of the walk area, compares what the Occ_ shapes hide of his idle silhouette with
what depth_occluder.gd would hide (its ground rule copied here; doesn't know about Gaps).

  ../segment-env/venv/Scripts/python.exe tools/depth/score.py <repo or extracted copy> <screen> [depth.png]

The scene must still have its Occ_ shapes: for the stream and boardwalk, extract them from commit 4eb7f75
(git archive 4eb7f75 scenes/screens assets/screens assets/pip | tar -x -C <dir>) and pass that dir.
Env: TOL (default 0.01); PIT=0 turns off the gap rule; GAPROW=narrow|max|row picks how rows behind/ahead are read
(row is what the game does).
"""
import re
import sys

import numpy as np
from PIL import Image

repo, screen = sys.argv[1], sys.argv[2]
depth_path = sys.argv[3] if len(sys.argv) > 3 else f"{repo}/assets/screens/{screen}/{screen}_depth.png"
import os
TOL, GROW, STEP = float(os.environ.get("TOL", "0.01")), 3.0, 12
tscn = open(f"{repo}/scenes/screens/{screen}.tscn", encoding="utf-8").read()


def num(name: str, default: float) -> float:
    m = re.search(rf"^{name} = ([\d.\-]+)", tscn, re.M)
    return float(m.group(1)) if m else default


far_y, near_y = num("far_y", 215), num("near_y", 1075)
far_h, near_h = num("far_height", 72), num("near_height", 253)
poly = re.search(r'\[node name="WalkArea".*?polygon = PackedVector2Array\(([^)]*)\)', tscn, re.S).group(1)
poly = np.array([float(v) for v in poly.split(",")]).reshape(-1, 2)

res = dict(re.findall(r'\[ext_resource type="Texture2D"[^\]]*path="res://([^"]+)" id="([^"]+)"\]', tscn))
res = {v: k for k, v in res.items()}
occs = []
for m in re.finditer(r'\[node name="(Occ_[^"]+)"[^\]]*\]\n(.*?)(?=\n\[|\Z)', tscn, re.S):
    body = m.group(2)
    pos = re.search(r"position = Vector2\(([\d.\-]+), ([\d.\-]+)\)", body)
    tex = re.search(r'texture = ExtResource\("([^"]+)"\)', body).group(1)
    a = np.array(Image.open(f"{repo}/{res[tex]}").convert("RGBA"))[..., 3] >= 128
    x0, y0 = int(float(pos.group(1))), int(float(pos.group(2)))
    full = np.zeros((1080, 1920), bool)
    h, w = a.shape
    full[y0:y0 + h, x0:x0 + w] = a[: 1080 - y0, : 1920 - x0]
    sort = "sort = false" not in body
    bottom = np.full(1920, -1)
    if sort:
        cols = np.where(a.any(0))[0]
        last = -1
        b = np.full(w, -1)
        for x in range(w):
            ys = np.where(a[:, x])[0]
            b[x] = ys.max() if len(ys) else last
            last = b[x]
        first = b[b >= 0][0]
        b[b < 0] = first
        bottom[x0:x0 + w] = (b + y0)[: 1920 - x0]
        bottom[:x0] = bottom[x0]
        bottom[x0 + w:] = bottom[min(1919, x0 + w - 1)]
    occs.append(dict(name=m.group(1), mask=full, sort=sort, bottom=bottom))

d = np.array(Image.open(depth_path).convert("RGB")).astype(np.float64)
near = (d[..., 0] * 256 + d[..., 1]) / 65535.0
grown = near.copy()
for i in range(8):
    ang = i * 0.785398
    for r in (GROW, GROW * 0.5):
        dx, dy = int(round(np.cos(ang) * r)), int(round(np.sin(ang) * r))
        grown = np.maximum(grown, np.roll(np.roll(near, -dy, 0), -dx, 1))

sheet = np.array(Image.open(f"{repo}/assets/pip/pip_idle_down_sheet.png").convert("RGBA"))[..., 3]
sil = sheet[:320, :320] >= 128  # feet at row 277, centre x 160


def inside(px: float, py: float) -> bool:
    x, y = poly[:, 0], poly[:, 1]
    xn, yn = np.roll(x, -1), np.roll(y, -1)
    c = ((y > py) != (yn > py)) & (px < (xn - x) * (py - y) / (yn - y + 1e-12) + x)
    return bool(c.sum() % 2)


def row(fx, y, s):
    vals = sorted(near[int(np.clip(y, 0, 1079)), int(np.clip(fx + k * 10 * s, 0, 1919))]
                  for k in range(-7, 8) if inside(fx + k * 10 * s, y))
    return vals[len(vals) >> 1] if vals else None


def rownarrow(fx, y, s):
    K = int(os.environ.get("K", "2"))
    vals = sorted(near[int(np.clip(y, 0, 1079)), int(np.clip(fx + k * 10 * s, 0, 1919))]
                  for k in range(-K, K + 1) if inside(fx + k * 10 * s, y))
    return vals[len(vals) >> 1] if vals else None


def rowmax(fx, y, s):
    vals = [near[int(np.clip(y, 0, 1079)), int(np.clip(fx + k * 10 * s, 0, 1919))]
            for k in range(-7, 8) if inside(fx + k * 10 * s, y)]
    return max(vals) if vals else None


def ground(fx: float, fy: float, s: float) -> float:
    g = row(fx, fy + 2, s)
    if g is None:
        return near[min(1079, int(fy)), int(fx)]
    if os.environ.get("PIT", "1") == "1":
        H = 80 * s
        R = {'max': rowmax, 'narrow': rownarrow}.get(os.environ.get('GAPROW', 'row'), row)
        above = [m for dy in np.arange(4, H, 4) if (m := R(fx, fy + 2 - dy, s)) is not None]
        below = [m for dy in np.arange(4, H, 4) if (m := R(fx, fy + 2 + dy, s)) is not None]
        if above and below:
            g = max(g, min(max(above), max(below)))
    return g


per = {o["name"]: [0, 0] for o in occs}  # [affinity px over Pip, of those also hidden by depth]
extra = total = aff_all = 0
worst = []
ys = np.arange(poly[:, 1].min(), min(1079, poly[:, 1].max()), STEP)
xs = np.arange(max(0, poly[:, 0].min()), min(1919, poly[:, 0].max()), STEP)
for fy in ys:
    s = (far_h + (near_h - far_h) * (fy - far_y) / (near_y - far_y)) / 245.0
    if s <= 0:
        continue
    small = np.array(Image.fromarray(sil.astype(np.uint8) * 255).resize(
        (max(1, int(320 * s)), max(1, int(320 * s))), Image.NEAREST)) > 0
    for fx in xs:
        if not inside(fx, fy):
            continue
        ox, oy = int(fx - 160 * s), int(fy - 277 * s)
        h, w = small.shape
        X0, Y0, X1, Y1 = max(0, ox), max(0, oy), min(1920, ox + w), min(int(fy), oy + h, 1080)
        if X1 <= X0 or Y1 <= Y0:
            continue
        pip = small[Y0 - oy:Y1 - oy, X0 - ox:X1 - ox]
        g = ground(fx, fy, s)
        dep = (grown[Y0:Y1, X0:X1] > g + TOL) & pip
        aff_union = np.zeros_like(pip)
        for o in occs:
            if o["sort"] and not fy < o["bottom"][int(fx)]:
                continue
            a = o["mask"][Y0:Y1, X0:X1] & pip
            n = int(a.sum())
            if n:
                per[o["name"]][0] += n
                per[o["name"]][1] += int((a & dep).sum())
                aff_union |= a
        total += int(pip.sum())
        aff_all += int(aff_union.sum())
        e = int((dep & ~aff_union).sum())
        extra += e
        miss = int((aff_union & ~dep).sum())
        worst.append((miss, e, int(pip.sum()), int(fx), int(fy)))

print(f"{screen}: {depth_path.split('/')[-1]}")
for k, (a, b) in per.items():
    print(f"  {k:14s} Affinity covers {a:9d} px of Pip; depth covers {100 * b / max(a, 1):5.1f}% of that")
print(f"  depth hides {extra} px Affinity doesn't = {100 * extra / max(total, 1):.2f}% of all Pip px sampled "
      f"(Affinity hides {100 * aff_all / max(total, 1):.2f}%)")
worst.sort(reverse=True)
print("  worst misses (Affinity px not hidden by depth, extra, pip px, x, y):", worst[:5])
worst.sort(key=lambda t: -t[1])
print("  worst extras:", worst[:5])
