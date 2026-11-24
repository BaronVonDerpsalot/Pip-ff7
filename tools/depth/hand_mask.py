"""Turn a person's red marks on an image back into a mask at screen size, for what SAM 3 missed.

  ../segment-env/venv/Scripts/python.exe tools/depth/hand_mask.py <sent.png> <marked image> <out_mask.png> [--crop=x0,y0,x1,y1]

<sent.png> is the image they were sent (e.g. ../segment-env/out/auto/<screen>/bank_overlay.jpg, the whole screen,
or a crop of it, with --crop giving the crop's box on the 1920x1080 screen); <marked image> is it back with red
painted over what should hide Pip (any opacity from about 40%; any size, it's scaled to the sent image). Painted
pixels are where the marked image is redder than the sent one. Writes <out_mask.png> (white = marked); show the
person the marks over the painting before using them. Use the mask with
mask_shapes.py --raised=<out_mask.png> for raised bank (marsh, 2026-11-24).
"""
import sys

import cv2
import numpy as np
from PIL import Image


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    sent_path, marked_path, out = args
    crop = next((a.split("=")[1] for a in sys.argv if a.startswith("--crop=")), "0,0,1920,1080")
    x0, y0, x1, y1 = (int(v) for v in crop.split(","))
    sent = Image.open(sent_path).convert("RGB")
    sent_a = np.array(sent).astype(float)
    marked = np.array(Image.open(marked_path).convert("RGB").resize(sent.size, Image.LANCZOS)).astype(float)
    d = marked - sent_a
    red = ((d[..., 0] > 15) & (d[..., 1] < -20) & (d[..., 2] < -10)).astype(np.uint8)
    red = cv2.morphologyEx(red, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    n, lab, st, _ = cv2.connectedComponentsWithStats(red)
    keep = np.zeros_like(red)
    for i in range(1, n):
        if st[i, 4] > 0.0002 * red.size:
            keep[lab == i] = 1
    keep = cv2.morphologyEx(keep, cv2.MORPH_CLOSE, np.ones((9, 9), np.uint8))
    keep = cv2.morphologyEx(keep, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
    full = np.zeros((1080, 1920), np.uint8)
    full[y0:y1, x0:x1] = cv2.resize(keep, (x1 - x0, y1 - y0), interpolation=cv2.INTER_NEAREST)
    Image.fromarray(full * 255).save(out)
    print(f"{int(full.sum())} px marked -> {out}")


if __name__ == "__main__":
    main()
