"""Layer order of a screen painting with Illustrator's Depth (Adobe, CVPR 2026), for the bank shapes in
tools/depth/auto_occ.py --banks (docs/recipes/screens-layering.md, "Automatic shapes"). Its own environment:
../illustrators-env (setup in the recipe). Non-commercial licence (Adobe Research License).

  ../illustrators-env/venv/Scripts/python.exe tools/depth/layers.py <screen>

The model predicts which painted layer each pixel is on (larger = further forward), not distance: the whole
path is one layer from the horizon to the camera, so it can't replace the depth map. Near a path's edge it
does tell a bank's lip from the path, which depth can't. Each run also averages the painting with its mirror
image. About 100 s a screen in fp16 on a GTX 1050 Ti.

Writes ../illustrators-env/out/<screen>.npy (float32, 1080x1920, scaled 0..1) and <screen>_preview.jpg.
"""
import os
import re
import sys
import time

import numpy as np
import torch
from PIL import Image

ENV = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "illustrators-env"))
sys.path.insert(0, os.path.join(ENV, "src"))
from src.model.illustrators_depth_model import load_illustrators_depth_model  # noqa: E402

SIDE = 1536  # the model's input size


def main() -> None:
    screen = sys.argv[1]
    tscn = open(f"scenes/screens/{screen}.tscn", encoding="utf-8").read()
    paint = re.search(r'path="res://(assets/screens/' + screen + r'/[^"]*_bg\.jpg)"', tscn).group(1)
    device = "cuda" if torch.cuda.is_available() else "cpu"
    dtype = torch.float16 if device == "cuda" else torch.float32
    t0 = time.time()
    ckpt = os.path.join(ENV, "checkpoints", "mmsvg_model", "checkpoints", "id_model.ckpt").replace("\\", "/")
    model, _ = load_illustrators_depth_model(ckpt, device="cpu")  # loaded on the CPU, then halved: 4 GB cards
    model = model.to(device, dtype)
    image = Image.open(paint).convert("RGB")
    W, H = image.size

    def run(im: Image.Image) -> np.ndarray:
        x = torch.from_numpy(np.asarray(im.resize((SIDE, SIDE), Image.BICUBIC))).permute(2, 0, 1).float() / 255
        with torch.no_grad():
            d = model(((x - 0.5) / 0.5)[None].to(device, dtype)).float()
        d = torch.nn.functional.interpolate(d.reshape(1, 1, *d.shape[-2:]), size=(H, W), mode="bilinear",
                                            align_corners=False)
        return d[0, 0].cpu().numpy()

    d = (run(image) + run(image.transpose(Image.FLIP_LEFT_RIGHT))[:, ::-1]) / 2
    lo, hi = np.percentile(d, 0.5), np.percentile(d, 99.5)
    d = np.clip((d - lo) / max(hi - lo, 1e-9), 0, 1).astype(np.float32)
    out = os.path.join(ENV, "out")
    os.makedirs(out, exist_ok=True)
    np.save(os.path.join(out, f"{screen}.npy"), d)
    Image.fromarray((d * 255).astype(np.uint8)).save(os.path.join(out, f"{screen}_preview.jpg"), quality=90)
    print(f"{screen}: {device}, {time.time() - t0:.0f} s -> {out}/{screen}.npy")


if __name__ == "__main__":
    main()
