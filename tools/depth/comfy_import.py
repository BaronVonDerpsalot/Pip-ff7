"""Bring a ComfyUI occlusion run (tools/depth/comfy_queue.js) into the repo.

  ../segment-env/venv/Scripts/python.exe tools/depth/comfy_import.py <zip or folder> [<screen> ...] [--no-depth]

Reads <screen>_depth_dav2l_*.png and <screen>_sam3_<thing>_mask_*.png (the newest of each, by ComfyUI's counter)
from the zip MimicPC's storage panel makes (Chrome saves it to ../preprocessing/_inbox), for the screens named, or
every screen found. Writes tools/depth/comfy/<screen>/<screen>_depth_dav2l.png and <screen>_sam3_<thing>_mask.png,
and copies the depth map to assets/screens/<screen>/<screen>_depth.png (unless --no-depth). ComfyUI saves 8-bit
grey; the game's depth maps keep 16 bits split over red (high byte) and green (low byte), so grey v becomes red v,
green v. Nearer is whiter. Import afterwards (godot --headless --path . --import).
"""
import io
import os
import re
import sys
import zipfile
from collections import defaultdict

import numpy as np
from PIL import Image

PATTERN = re.compile(r"(?:^|/)([a-z0-9_]+?)_(depth_dav2l|sam3_[a-z0-9_]+?_mask)_(\d+)_\.png$")


def sources(src: str) -> dict:
    """{(screen, kind): (counter, loader)} for the newest file of each."""
    found = {}
    if zipfile.is_zipfile(src):
        z = zipfile.ZipFile(src)
        names = [(n, (lambda n=n: z.read(n))) for n in z.namelist()]
    else:
        names = [(os.path.join(r, f).replace("\\", "/"), (lambda p=os.path.join(r, f): open(p, "rb").read()))
                 for r, _, fs in os.walk(src) for f in fs]
    for name, load in names:
        m = PATTERN.search(name)
        if not m:
            continue
        key = (m.group(1), m.group(2))
        n = int(m.group(3))
        if key not in found or n > found[key][0]:
            found[key] = (n, load)
    return found


def to_game_depth(grey: np.ndarray) -> Image.Image:
    v = grey.astype(np.uint32) * 257
    rgb = np.zeros(grey.shape + (3,), np.uint8)
    rgb[..., 0] = v >> 8
    rgb[..., 1] = v & 255
    return Image.fromarray(rgb)


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    src, wanted = args[0], set(args[1:])
    found = sources(src)
    by_screen = defaultdict(list)
    for (screen, kind), (_, load) in found.items():
        if not wanted or screen in wanted:
            by_screen[screen].append((kind, load))
    if not by_screen:
        sys.exit(f"nothing for {sorted(wanted) or 'any screen'} in {src}")
    for screen, items in sorted(by_screen.items()):
        out = f"tools/depth/comfy/{screen}"
        os.makedirs(out, exist_ok=True)
        names = []
        for kind, load in sorted(items):
            img = Image.open(io.BytesIO(load()))
            if kind == "depth_dav2l":
                game = to_game_depth(np.array(img.convert("L")))
                game.save(f"{out}/{screen}_{kind}.png")
                if "--no-depth" not in sys.argv:
                    if not os.path.isdir(f"assets/screens/{screen}"):
                        sys.exit(f"assets/screens/{screen} doesn't exist: build the screen first (screens-flow.md)")
                    game.save(f"assets/screens/{screen}/{screen}_depth.png")
            else:
                img.convert("L").save(f"{out}/{screen}_{kind}.png")
            names.append(kind)
        print(f"{screen}: {', '.join(names)} -> {out}" + ("" if "--no-depth" in sys.argv else
                                                         f", assets/screens/{screen}/{screen}_depth.png"))


if __name__ == "__main__":
    main()
