"""A probe sheet for a screen's automatic shapes: Pip placed where each Auto_ shape should hide him, in the game,
with the shapes on (left) and off (right), for a person to judge before walking the screen.

  ../segment-env/venv/Scripts/python.exe tools/depth/probe_sheet.py <screen> [--max=10]   writes tools/_probe/
  (run res://tools/_probe/probe.tscn with Ziva's run_scene, about 8 s; it quits by itself)
  ../segment-env/venv/Scripts/python.exe tools/depth/probe_sheet.py <screen> --finish     keeps the sheet, deletes tools/_probe/

Spots: for each Auto_ shape, the walk-area point (on a 10 px grid, clear of exits) where his frame overlaps most of
the shape while his feet are above its bottom edge (so it should hide him), spread apart. The sheet ends up at
../segment-env/out/probe/<screen>.png. Pip's frame: 320 wide, feet 277 px down, scaled by the screen's depth numbers.
"""
import os
import re
import shutil
import sys

import cv2
import numpy as np
from PIL import Image

W, H = 1920, 1080
PROBE = "tools/_probe"

GD = '''extends Node
## Throwaway probe from tools/depth/probe_sheet.py (deleted by its --finish).
const SCREEN := "%s"
const SPOTS := [%s]
const CW := 300
const CH := 340
var _screen: Node = null
var _spot := 0
var _mode := 0
var _wait := 20
var _sheet: Image = null

func _ready() -> void:
	_screen = load("res://scenes/screens/%%s.tscn" %% SCREEN).instantiate()
	add_child(_screen)
	_sheet = Image.create(CW * 2, CH * SPOTS.size(), false, Image.FORMAT_RGBA8)
	_set_mode()

func _set_mode() -> void:
	for c in _screen.get_node("Overhead").get_children():
		if c.name.begins_with("Auto_"):
			c.visible = _mode == 0
			c.process_mode = Node.PROCESS_MODE_INHERIT if _mode == 0 else Node.PROCESS_MODE_DISABLED
	_screen.get_node("World/Pip").arrive_at(SPOTS[_spot], Vector2.DOWN)

func _process(_delta: float) -> void:
	_wait -= 1
	if _wait > 0:
		return
	var img := get_viewport().get_texture().get_image()
	img.resize(1920, 1080)
	var p: Vector2 = SPOTS[_spot]
	var r := Rect2i(int(p.x - CW * 0.5), int(p.y) - CH + 40, CW, CH)
	r.position.x = clampi(r.position.x, 0, 1920 - CW)
	r.position.y = clampi(r.position.y, 0, 1080 - CH)
	_sheet.blit_rect(img, r, Vector2i(CW * _mode, CH * _spot))
	_mode += 1
	if _mode > 1:
		_mode = 0
		_spot += 1
	if _spot >= SPOTS.size():
		_sheet.save_png("res://tools/_probe/out.png")
		print("PROBE DONE")
		get_tree().quit()
		return
	_set_mode()
	_wait = 8
'''

TSCN = '''[gd_scene format=3]

[ext_resource type="Script" path="res://tools/_probe/probe.gd" id="1"]

[node name="Probe" type="Node"]
script = ExtResource("1")
'''


def num(tscn: str, name: str, default: float) -> float:
    m = re.search(rf"^{name} = ([\d.\-]+)", tscn, re.M)
    return float(m.group(1)) if m else default


def shapes(tscn: str) -> list:
    ext = {i: p for p, i in re.findall(r'\[ext_resource type="Texture2D" path="res://([^"]+)" id="([^"]+)"\]', tscn)}
    out = []
    for m in re.finditer(r'\[node name="(Auto_[^"]+)"[^\]]*\]\n(.*?)(?=\n\[|\Z)', tscn, re.S):
        b = m.group(2)
        if "visible = false" in b:
            continue
        x, y = (int(float(v)) for v in re.search(r"position = Vector2\(([\d.-]+), ([\d.-]+)\)", b).groups())
        a = np.array(Image.open(ext[re.search(r'texture = ExtResource\("([^"]+)"\)', b).group(1)]))[..., 3] >= 128
        mk = np.zeros((H, W), bool)
        h, w = a.shape
        mk[y:y + h, x:x + w] = a[:H - y, :W - x]
        cols = np.where(mk.any(0))[0]
        bottom = np.full(W, -1)
        for c in cols:
            bottom[c] = np.where(mk[:, c])[0].max()
        bottom[:cols[0]] = bottom[cols[0]]
        bottom[cols[-1] + 1:] = bottom[cols[-1]]
        for c in range(cols[0], cols[-1] + 1):
            if bottom[c] < 0:
                bottom[c] = bottom[c - 1]
        out.append((m.group(1), mk, bottom))
    return out


def spots(screen: str, most: int) -> list:
    tscn = open(f"scenes/screens/{screen}.tscn", encoding="utf-8").read()
    p = re.search(r'\[node name="WalkArea".*?polygon = PackedVector2Array\(([^)]*)\)', tscn, re.S).group(1)
    walk = np.zeros((H, W), np.uint8)
    cv2.fillPoly(walk, [np.array([float(v) for v in p.split(",")]).reshape(-1, 2).round().astype(np.int32)], 1)
    for e in re.findall(r'parent="Exits"[^\]]*\]\n(?:[^\[]*?\n)?polygon = PackedVector2Array\(([^)]*)\)', tscn):
        cv2.fillPoly(walk, [np.array([float(v) for v in e.split(",")]).reshape(-1, 2).round().astype(np.int32)], 0)
    far_y, near_y = num(tscn, "far_y", 215), num(tscn, "near_y", 1075)
    far_h, near_h = num(tscn, "far_height", 72), num(tscn, "near_height", 253)
    ys, xs = np.mgrid[0:H:10, 0:W:10]
    pts = [(int(x), int(y)) for x, y in zip(xs.ravel(), ys.ravel()) if walk[y, x]]
    picked = []
    for name, mk, bottom in shapes(tscn):
        integral = cv2.integral(mk.astype(np.uint8))
        cands = []
        for x, y in pts:
            if y >= bottom[x]:
                continue
            s = (far_h + (near_h - far_h) * (y - far_y) / (near_y - far_y)) / 245.0
            x0, x1 = max(0, int(x - 120 * s)), min(W, int(x + 120 * s))
            y0, y1 = max(0, int(y - 260 * s)), min(H, y)
            n = integral[y1, x1] - integral[y0, x1] - integral[y1, x0] + integral[y0, x0]
            if n > 200:
                cands.append((int(n), (x, y)))
        cands.sort(reverse=True)
        mine = []  # up to three per shape, spread along it
        for n, pt in cands:
            if len(mine) == 3:
                break
            if all(abs(pt[0] - a) + abs(pt[1] - b) > 150 for _, (a, b) in mine + picked):
                mine.append((n, pt))
        picked += mine
    picked.sort(reverse=True)
    return [pt for _, pt in picked[:most]]


def main() -> None:
    screen = sys.argv[1]
    if "--finish" in sys.argv:
        os.makedirs("../segment-env/out/probe", exist_ok=True)
        shutil.copy(f"{PROBE}/out.png", f"../segment-env/out/probe/{screen}.png")
        shutil.rmtree(PROBE)
        print(f"../segment-env/out/probe/{screen}.png; {PROBE}/ deleted")
        return
    most = int(next((a.split("=")[1] for a in sys.argv if a.startswith("--max=")), 10))
    sp = spots(screen, most)
    os.makedirs(PROBE, exist_ok=True)
    open(f"{PROBE}/probe.gd", "w", encoding="utf-8", newline="\n").write(
        GD % (screen, ", ".join(f"Vector2({x}, {y})" for x, y in sp)))
    open(f"{PROBE}/probe.tscn", "w", encoding="utf-8", newline="\n").write(TSCN)
    print(f"{screen}: {len(sp)} spots {sp}; run res://{PROBE}/probe.tscn, then --finish")


if __name__ == "__main__":
    main()
