"""Score occlusion against a screen's Affinity Occ_ shapes, without Godot (screens-layering.md, "Win").

For Pip's feet at every 12 px of the walk area, compares what the Occ_ shapes hide of his idle silhouette with
what the route would hide: the depth map (depth_occluder.gd's ground rule copied here; doesn't know about Gaps),
plus any automatic shapes on the bottom-edge rule.

  ../segment-env/venv/Scripts/python.exe tools/depth/score.py <repo or extracted copy> <screen> [depth.png]

The scene must still have its Occ_ shapes: they were removed or switched off after commit 4eb7f75, so extract it
(git archive 4eb7f75 scenes/screens assets/screens assets/pip | tar -x -C <dir>) and pass that dir. Without
[depth.png] the depth map comes from that dir too (the old one): pass assets/screens/<screen>/<screen>_depth.png
to score the current map. Automatic shapes are read from the current repo.
Automatic shapes, any of (env):
  SCENE=scenes/screens/<screen>.tscn  every Auto_ sprite in that scene, as the game has them
  MANIFEST=<json>    [{"file", "x", "y", "edge"}] (auto_occ.py's manifest)
  LABELS=<x_labels.png>  cut_banks.py's pieces (with <x>_bottoms.npy beside it)
  AUTO=<mask.png>    each connected piece of a mask
Env: TOL (default 0.01); PIT=0 turns off the gap rule; GAPROW=narrow|max|row picks how rows behind/ahead are read
(row is what the game does); NODEPTH=1 scores the shapes alone.
Prints per Occ_ shape how much of what it hides the route hides too, how much of Pip the route hides that
Affinity doesn't ("hidden wrongly"), the worst spots, and SPOTS: four places where Affinity hides Pip most (for a
probe, tools/depth/probe_sheet.py).
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



if os.environ.get("SCENE"):
    import json as _j2, tempfile as _tf
    _t = open(os.environ["SCENE"], encoding="utf-8").read()
    _ext = {i: p for p, i in re.findall(r'\[ext_resource type="Texture2D" path="res://([^"]+)" id="([^"]+)"\]', _t)}
    _man = []
    for _m in re.finditer(r'\[node name="(Auto_[^"]+)"[^\]]*\]\n(.*?)(?=\n\[|\Z)', _t, re.S):
        _b = _m.group(2)
        _x, _y = re.search(r"position = Vector2\(([\d.-]+), ([\d.-]+)\)", _b).groups()
        _e = re.search(r"edge = PackedVector2Array\(([^)]*)\)", _b)
        _v = [float(q) for q in _e.group(1).split(",")] if _e else None
        _man.append({"file": _ext[re.search(r'texture = ExtResource\("([^"]+)"\)', _b).group(1)],
                     "x": int(float(_x)), "y": int(float(_y)), "edge": [_v[:2], _v[2:4]] if _v else None})
    _f = _tf.NamedTemporaryFile("w", suffix=".json", delete=False); _j2.dump(_man, _f); _f.close()
    os.environ["MANIFEST"] = _f.name

import cv2 as _cv
autos=[]
if os.environ.get("MANIFEST"):
    import json as _j
    for p in _j.load(open(os.environ["MANIFEST"])):
        a=np.array(Image.open(p["file"]))[...,3]>=128; h,w=a.shape
        mk=np.zeros((1080,1920),bool); mk[p["y"]:p["y"]+h,p["x"]:p["x"]+w]=a
        if p["edge"]:
            (ax,ay),(bx,by)=p["edge"]
            b=np.interp(np.arange(1920),[ax,bx] if ax<=bx else [bx,ax],[ay,by] if ax<=bx else [by,ay])
            own=np.full(1920,-1.0); cols=np.where(mk.any(0))[0]
            for x in cols: own[x]=np.where(mk[:,x])[0].max()
            own[:cols[0]]=own[cols[0]]; own[cols[-1]+1:]=own[cols[-1]]
            for x in range(cols[0],cols[-1]+1):
                if own[x]<0: own[x]=own[x-1]
            b=b if os.environ.get("EDGE_ONLY") else np.minimum(own, b+float(os.environ.get("EDGE_DY","0")))
        else:
            cols=np.where(mk.any(0))[0]; b=np.full(1920,-1)
            for x in cols: b[x]=np.where(mk[:,x])[0].max()
            b[:cols[0]]=b[cols[0]]; b[cols[-1]+1:]=b[cols[-1]]
            for x in range(cols[0],cols[-1]+1):
                if b[x]<0: b[x]=b[x-1]
        autos.append((mk,b))
if os.environ.get("LABELS"):
    lab=np.array(Image.open(os.environ["LABELS"])); bots=np.load(os.environ["LABELS"].replace("_labels.png","_bottoms.npy"))
    for i in range(1,lab.max()+1):
        mk=lab==i
        if mk.sum()>=64: autos.append((mk,bots[i-1]))
if os.environ.get("AUTO"):
    am=np.array(Image.open(os.environ["AUTO"]).convert("L"))>=128
    n,lab=_cv.connectedComponents(am.astype(np.uint8)); n-=1
    for i in range(1,n+1):
        mk=lab==i
        if mk.sum()<64: continue
        b=np.full(1920,-1); cols=np.where(mk.any(0))[0]
        for x in cols: b[x]=np.where(mk[:,x])[0].max()
        b[:cols[0]]=b[cols[0]]; b[cols[-1]+1:]=b[cols[-1]]
        for x in range(cols[0],cols[-1]+1):
            if b[x]<0: b[x]=b[x-1]
        autos.append((mk,b))

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


shape_extra = {}
per = {o["name"]: [0, 0] for o in occs}  # [affinity px over Pip, of those also hidden by depth]
extra = total = aff_all = 0
worst = []
spots = []
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
        if os.environ.get("NODEPTH"): dep[:] = False
        dep0 = dep.copy()
        _hits = []
        for _i,(mk,b) in enumerate(autos):
            if fy < b[int(fx)]:
                h = mk[Y0:Y1, X0:X1] & pip
                dep |= h
                _hits.append((_i,h))
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
        for _i,h in _hits:
            shape_extra[_i] = shape_extra.get(_i,0) + int((h & ~aff_union & ~dep0).sum())
        e = int((dep & ~aff_union).sum())
        extra += e
        miss = int((aff_union & ~dep).sum())
        spots.append((int(aff_union.sum()), int(fx), int(fy)))
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

if autos: print("  extra px by auto shape:", sorted(((v,k+1) for k,v in shape_extra.items() if v), reverse=True)[:8])

spots.sort(reverse=True); pick=[]
for c,x,y in spots:
    if all(abs(x-a)+abs(y-b)>120 for _,a,b in pick): pick.append((c,x,y))
    if len(pick)==4: break
print("  SPOTS", [(x,y) for _,x,y in pick])
