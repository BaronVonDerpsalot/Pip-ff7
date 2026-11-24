"""First guess at a screen's walk area, from SAM 3's masks of the walkable surface (tools/depth/comfy_queue.js asks
for "dirt path", "wooden boardwalk" and "footbridge"). A person then adjusts it in the editor (screens-flow.md,
step 3).

  ../segment-env/venv/Scripts/python.exe tools/depth/walk_guess.py <screen> [--write] [--from=<mask.png>,...]

Joins the masks, bridges small gaps (between planks), fills holes, rounds off spurs and sharp inward corners (a
sharp corner snags Pip, screens-flow.md), and keeps the biggest piece. Prints how much it agrees with the scene's
current WalkArea (overlap as a share of both together) and where it meets the edge of the picture (exits, step 7).
--write replaces the WalkArea polygon in scenes/screens/<screen>.tscn. Writes
../segment-env/out/walk/<screen>.jpg: new guess red, current walk area yellow.
"""
import os
import re
import sys

import cv2
import numpy as np
from PIL import Image

W, H = 1920, 1080
WALK = ["dirt_path", "wooden_boardwalk", "footbridge"]
GAP = 15       # px: gaps narrower than this are bridged (planks, puddle edges)
ROUND = 11     # px: spurs and inward corners smaller than this are rounded off
SIMPLIFY = 3.0  # px: how far the polygon may stray from the mask's outline
MIN_SHARE = 0.002  # pieces smaller than this share of the picture are dropped before joining


def guess(masks: list) -> np.ndarray:
    m = np.zeros((H, W), np.uint8)
    for p in masks:
        a = (np.array(Image.open(p).convert("L")) >= 128).astype(np.uint8)
        n, lab, st, _ = cv2.connectedComponentsWithStats(a)
        for i in range(1, n):
            if st[i, 4] >= MIN_SHARE * W * H:
                m[lab == i] = 1
    m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (GAP, GAP)))
    cs, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    filled = np.zeros_like(m)
    cv2.drawContours(filled, cs, -1, 1, cv2.FILLED)
    m = cv2.morphologyEx(filled, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (ROUND, ROUND)))
    m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (ROUND, ROUND)))
    n, lab, st, _ = cv2.connectedComponentsWithStats(m)
    if n < 2:
        sys.exit("no walkable surface found in the masks")
    return lab == 1 + int(np.argmax(st[1:, 4]))


def polygon(mask: np.ndarray) -> np.ndarray:
    cs, _ = cv2.findContours(mask.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    c = max(cs, key=cv2.contourArea)
    p = cv2.approxPolyDP(c, SIMPLIFY, True)[:, 0, :].copy()
    # Points within a few px of the picture's edge go onto it, so a path leaving the screen reaches the edge.
    p[:, 0] = np.where(p[:, 0] <= 4, 0, np.where(p[:, 0] >= W - 5, W, p[:, 0]))
    p[:, 1] = np.where(p[:, 1] <= 4, 0, np.where(p[:, 1] >= H - 5, H, p[:, 1]))
    return p


def exits(poly: np.ndarray) -> list:
    """Stretches of the outline that run along the picture's edge: where the path leaves the screen."""
    out, near = [], lambda p: p[0] <= 0 or p[0] >= W or p[1] <= 0 or p[1] >= H
    for a, b in zip(poly, np.roll(poly, -1, 0)):
        if near(a) and near(b) and np.hypot(*(b - a)) > 20:
            out.append((tuple(int(v) for v in a), tuple(int(v) for v in b)))
    return out


def main() -> None:
    screen = sys.argv[1]
    scene_path = f"scenes/screens/{screen}.tscn"
    tscn = open(scene_path, encoding="utf-8").read()
    frm = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--from=")), None)
    masks = frm.split(",") if frm else [p for p in (f"tools/depth/comfy/{screen}/{screen}_sam3_{k}_mask.png" for k in WALK)
                                        if os.path.exists(p)]
    if not masks:
        sys.exit(f"no walk masks for {screen} in tools/depth/comfy/{screen}/ (run comfy_queue.js, then comfy_import.py)")
    new = guess(masks)
    poly = polygon(new)

    pm = re.search(r'(\[node name="WalkArea"[^\]]*\]\n(?:[^\[]*?\n)?polygon = PackedVector2Array\()([^)]*)(\))', tscn)
    cur = None
    if pm:
        pts = np.array([float(v) for v in pm.group(2).split(",")]).reshape(-1, 2).round().astype(np.int32)
        cur = np.zeros((H, W), np.uint8)
        cv2.fillPoly(cur, [pts], 1)
        cur = cur.astype(bool)
        print(f"{screen}: agrees with the current walk area {100 * (new & cur).sum() / (new | cur).sum():.0f}% "
              f"(new {new.sum()} px, current {cur.sum()} px)")
    print(f"{screen}: {len(poly)} points; meets the picture's edge at {exits(poly) or 'nowhere'}")

    bg = re.search(rf'path="res://(assets/screens/{screen}/[^"]+_bg\.jpg)"', tscn)
    painting = bg.group(1) if bg else next(f"assets/screens/{screen}/{f}" for f in os.listdir(f"assets/screens/{screen}")
                                            if f.endswith("_bg.jpg"))
    v = np.array(Image.open(painting).convert("RGB"))
    if cur is not None:
        cv2.polylines(v, [pts], True, (255, 220, 0), 2)
    cv2.polylines(v, [poly.astype(np.int32)], True, (255, 40, 40), 3)
    os.makedirs("../segment-env/out/walk", exist_ok=True)
    Image.fromarray(v).save(f"../segment-env/out/walk/{screen}.jpg", quality=85)

    if "--write" in sys.argv:
        if not pm:
            sys.exit(f"{scene_path} has no WalkArea polygon to replace (build the screen first, screens-flow.md)")
        flat = ", ".join(f"{int(x)}, {int(y)}" for x, y in poly)
        tscn = tscn[:pm.start(2)] + flat + tscn[pm.end(2):]
        open(scene_path, "w", encoding="utf-8", newline="\n").write(tscn)
        print(f"wrote the WalkArea in {scene_path}")


if __name__ == "__main__":
    main()
