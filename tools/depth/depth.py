"""Make a depth map of a screen painting with Depth Anything V2 Small, for Pip's depth occlusion
(scripts/depth_occluder.gd). Runs in the same environment as tools/segment (see
docs/recipes/screens-shader-motion.md, "Setup").

  ../segment-env/venv/Scripts/python.exe tools/depth/depth.py <painting> <out.png>

The model sees the whole painting at 1036 px high, then each of six overlapping tiles (3 x 2) zoomed to the
same size. Each tile's depth is fitted to the whole-painting run (scale and offset, least squares) and
blended in with feathered edges. The zoomed passes are what separate bridge posts from the planks behind
them: on the stream the posts went from 4% and 39% covered to 99% and 98% (2026-11-20). Each run also
averages the painting with its mirror image.

Writes <out.png> at the painting's size: nearness (the model's relative inverse depth, 0 = farthest,
1 = nearest) stored as 16 bits split over red (high byte) and green (low byte), so Godot's 8-bit import keeps
the precision. Also writes <out>_preview.jpg, the same as plain grey.
"""
import sys
import time

import numpy as np
import torch
from PIL import Image

MODEL = "depth-anything/Depth-Anything-V2-Small-hf"


SIDE = 1036
TILES = (3, 2)
OVERLAP = 0.25  # of a tile's size, shared with each neighbour
FEATHER = 60    # px over which a tile fades in


def predict(proc, model, image, device) -> np.ndarray:
    """Relative inverse depth (larger = nearer) at the image's size, averaged with its mirror image."""
    x = proc(images=image, return_tensors="pt", size={"height": SIDE, "width": SIDE})["pixel_values"].to(device)
    with torch.no_grad():
        d = model(pixel_values=x).predicted_depth
        d = (d + model(pixel_values=torch.flip(x, [3])).predicted_depth.flip([2])) / 2
    W, H = image.size
    return torch.nn.functional.interpolate(d[:, None].float(), size=(H, W), mode="bicubic", align_corners=False)[0, 0].cpu().numpy()


def main() -> None:
    src, out = sys.argv[1], sys.argv[2]
    from transformers import AutoImageProcessor, AutoModelForDepthEstimation

    device = "cuda" if torch.cuda.is_available() else "cpu"
    t0 = time.time()
    proc = AutoImageProcessor.from_pretrained(MODEL)
    model = AutoModelForDepthEstimation.from_pretrained(MODEL).to(device).eval()
    image = Image.open(src).convert("RGB")
    W, H = image.size
    whole = predict(proc, model, image, device)
    acc = whole * 1e-3
    weight = np.full((H, W), 1e-3)
    tw, th = W / (TILES[0] - (TILES[0] - 1) * OVERLAP), H / (TILES[1] - (TILES[1] - 1) * OVERLAP)
    for j in range(TILES[1]):
        for i in range(TILES[0]):
            x0, y0 = int(i * tw * (1 - OVERLAP)), int(j * th * (1 - OVERLAP))
            x1, y1 = min(W, int(x0 + tw)), min(H, int(y0 + th))
            tile = predict(proc, model, image.crop((x0, y0, x1, y1)), device)
            ref = whole[y0:y1, x0:x1]
            a, b = np.linalg.lstsq(np.stack([tile.ravel(), np.ones(tile.size)], 1), ref.ravel(), rcond=None)[0]
            # Fade in from the tile's edges, except where the edge is the painting's own edge.
            ry, rx = np.arange(y1 - y0), np.arange(x1 - x0)
            dy = np.minimum(ry + (FEATHER if y0 == 0 else 0), (y1 - y0 - 1 - ry) + (FEATHER if y1 == H else 0))
            dx = np.minimum(rx + (FEATHER if x0 == 0 else 0), (x1 - x0 - 1 - rx) + (FEATHER if x1 == W else 0))
            w = np.clip(np.minimum(dy[:, None], dx[None, :]) / FEATHER, 0, 1) + 1e-6
            acc[y0:y1, x0:x1] += (a * tile + b) * w
            weight[y0:y1, x0:x1] += w
    depth = acc / weight
    lo, hi = np.percentile(depth, 0.5), np.percentile(depth, 99.5)
    near = np.clip((depth - lo) / max(hi - lo, 1e-6), 0.0, 1.0)
    q = np.round(near * 65535).astype(np.uint32)
    rgb = np.zeros((H, W, 3), np.uint8)
    rgb[..., 0] = q >> 8
    rgb[..., 1] = q & 255
    Image.fromarray(rgb).save(out)
    Image.fromarray((near * 255).astype(np.uint8)).save(out.rsplit(".", 1)[0] + "_preview.jpg", quality=90)
    print(f"{src}: {W}x{H}, whole + {TILES[0] * TILES[1]} tiles at {SIDE} px, {device}, {time.time() - t0:.1f} s -> {out}")


if __name__ == "__main__":
    main()
