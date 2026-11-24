"""Cut a text-prompt bank mask (SAM 3 "grassy bank", tools/depth/comfy/<screen>/) into shapes that hide Pip,
using the screen's walk area. Scoring material for now: it writes label files for score_mix.py, not game sprites.

  ../segment-env/venv/Scripts/python.exe tools/depth/cut_banks.py <scene.tscn> <mask.png> <out prefix> <painting>

Why: SAM 3 finds the banks well, but merges each bank with whatever lies below it, into shapes that reach the
bottom of the screen. On the bottom-edge rule (scripts/occluder.gd) such a shape hides Pip almost anywhere.

First the mask grows up to 12 px into dark ink (grow_ink), to take in the bank's outline.
Rules, per column of the painting:
  behind  a bank pixel outside the walk area with walk area anywhere below it. Pip on that lower path is in front
          of it. This covers a wedge of bank in the crook of a bend: in front of the upper path, behind the lower.
  front   a bank pixel outside the walk area with no walk area below it.
  lip     a bank pixel inside the walk area (the walk polygon runs up onto a bank's lip, and the lip is what cuts
          Pip's legs). Kept, with the front pieces, only where the nearest walk edge faces the camera (outward
          normal pointing down, y > FACE, default 0.3): the same edges auto_occ.py --banks uses. Elsewhere dropped.
  Columns with no walk area are left out: front and behind can't be told apart there, and Pip never stands there.
Each connected piece (64 px or more) gets its own bottom line, its lowest pixel in each column.

Writes <out>_labels.png (16-bit, piece ids from 1), <out>_bottoms.npy (one bottom line per piece) and
<out>_preview.jpg (behind blue, front green, walk edge white). Score with
  LABELS=<out>_labels.png python ../kept-assets/depth-trials/score_mix.py <gt dir> <screen> <depth.png>

Marsh, 2026-11-24 (DA V2 Large depth): main bank 79.7% of Affinity, Pip hidden wrongly 0.13% (66.9% / 0.09%
before growing into the ink). Illustrator's Depth
banks (non-commercial licence): 71.6% / 0.12%. The raw mask: 67% / 3.3%.
"""
import os
import re
import sys

import cv2
import numpy as np
from PIL import Image

FACE = float(os.environ.get("FACE", "0.3"))
MIN_PX = 64
W, H = 1920, 1080


def walk_polygon(tscn: str) -> np.ndarray:
    p = re.search(r'\[node name="WalkArea".*?polygon = PackedVector2Array\(([^)]*)\)', tscn, re.S).group(1)
    return np.array([float(v) for v in p.split(",")]).reshape(-1, 2)


def facing_lip(poly: np.ndarray, walk: np.ndarray) -> np.ndarray:
    """True where the nearest walk edge faces the camera."""
    edges = np.zeros((H, W), np.uint8)  # 0 none, 1 faces away, 2 faces the camera
    pts = np.vstack([poly, poly[:1]])
    for a, b in zip(pts[:-1], pts[1:]):
        d = b - a
        length = np.hypot(*d)
        if length < 1:
            continue
        n = np.array([d[1], -d[0]]) / length
        t = (a + b) / 2 + n * 3
        if walk[int(np.clip(t[1], 0, H - 1)), int(np.clip(t[0], 0, W - 1))]:
            n = -n
        cv2.line(edges, tuple(a.round().astype(int)), tuple(b.round().astype(int)), 2 if n[1] > FACE else 1, 3)
    src = (edges > 0).astype(np.uint8)
    _, nearest = cv2.distanceTransformWithLabels(1 - src, cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
    ys, xs = np.where(src > 0)
    kind = np.zeros(nearest.max() + 1, np.uint8)
    kind[nearest[ys, xs]] = edges[ys, xs]
    return kind[nearest] == 2


def bottom_line(mk: np.ndarray) -> np.ndarray:
    b = np.full(W, -1)
    cols = np.where(mk.any(0))[0]
    for x in cols:
        b[x] = np.where(mk[:, x])[0].max()
    b[:cols[0]] = b[cols[0]]
    b[cols[-1] + 1:] = b[cols[-1]]
    for x in range(cols[0], cols[-1] + 1):
        if b[x] < 0:
            b[x] = b[x - 1]
    return b


def grow_ink(m: np.ndarray, painting: str, px: int = 12, dark: int = 55) -> np.ndarray:
    """Grow the mask up to px pixels, stepping only through pixels darker than `dark` (0-255 grey). SAM 3 stops
    just inside a bank's inked outline, and along the path that outline is the lip that cuts Pip's legs
    (2026-11-24: marsh main bank 66.9% -> 79.7% of Affinity, Pip hidden wrongly 0.09% -> 0.13%)."""
    g = np.array(Image.open(painting).convert("L")) < dark
    m = m.copy()
    for _ in range(px):
        m |= cv2.dilate(m.astype(np.uint8), np.ones((3, 3), np.uint8)).astype(bool) & g
    return m


def cut(m: np.ndarray, poly: np.ndarray, raised: np.ndarray | None = None) -> tuple:
    """The mask's pieces (boolean arrays, 64 px or more) and their kinds ("behind" or "front"), and the walk area.
    `raised`: bank a person has marked as raised. Inside the walk area too it follows the column rule (behind if
    there's walk area below it), instead of the lip rule, so Pip standing in it is hidden by it."""
    walk = np.zeros((H, W), np.uint8)
    cv2.fillPoly(walk, [poly.round().astype(np.int32)], 1)
    walk = walk.astype(bool)
    behind = np.zeros_like(m)
    front = np.zeros_like(m)
    for x in range(W):
        w = walk[:, x]
        if not w.any():
            continue
        walk_below = np.r_[(np.flip(np.cumsum(np.flip(w))) > 0)[1:], False]
        outside = m[:, x] & ~w
        if raised is not None:
            outside |= raised[:, x]
        behind[outside & walk_below, x] = True
        front[outside & ~walk_below, x] = True
    front |= m & walk & facing_lip(poly, walk) & ~behind
    pieces, kinds = [], []
    for kind, cls in (("behind", behind), ("front", front)):
        n, lab = cv2.connectedComponents(cls.astype(np.uint8))
        for i in range(1, n):
            mk = lab == i
            if mk.sum() >= MIN_PX:
                pieces.append(mk)
                kinds.append(kind)
    return pieces, kinds, walk


def main() -> None:
    tscn_path, mask_path, out, painting = sys.argv[1:5]
    poly = walk_polygon(open(tscn_path, encoding="utf-8").read())
    m = grow_ink(np.array(Image.open(mask_path).convert("L")) >= 128, painting)
    pieces, kinds, walk = cut(m, poly)
    labels = np.zeros((H, W), np.int32)
    bottoms = []
    for i, mk in enumerate(pieces, 1):
        labels[mk] = i
        bottoms.append(bottom_line(mk))
    Image.fromarray(labels.astype(np.uint16)).save(out + "_labels.png")
    np.save(out + "_bottoms.npy", np.array(bottoms))

    vis = np.array(Image.open(painting).convert("RGB"))
    for i, kind in enumerate(kinds, 1):
        c = np.array((80, 120, 255) if kind == "behind" else (60, 220, 90))
        vis[labels == i] = (vis[labels == i] * 0.4 + c * 0.6).astype(np.uint8)
    vis[walk ^ cv2.erode(walk.astype(np.uint8), None, iterations=2).astype(bool)] = (255, 255, 255)
    Image.fromarray(vis).resize((960, 540)).save(out + "_preview.jpg")
    print(f"{len(bottoms)} pieces: {kinds.count('behind')} behind the path, {kinds.count('front')} in front")


if __name__ == "__main__":
    main()
