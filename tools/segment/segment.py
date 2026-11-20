"""Find what should move on a screen painting and cut it into layers for Affinity and Godot.
How to run it and what to check: docs/recipes/screens-shader-motion.md.

  ../segment-env/venv/Scripts/python.exe tools/segment/segment.py tools/segment/specs/<screen>.json <out_dir>

The spec names the painting and its groups. Each group is found by words (Grounding DINO finds boxes,
SAM 2 traces them) and/or by regions given by hand (a box plus optional points inside and outside), for
things the words can't pin down, like a stream that fills half the screen.
  "kind": "water"  ripples in place: only a mask is written. "flow": true for a river or stream (the
                   pattern drifts downstream), false for puddles and ponds (it wobbles where it is).
                   A screen can have one of each. A flowing group also gets <name>_flow.png, the way the
                   water runs at each point, worked out along the water from each stretch's end nearest
                   the horizon; "source": [x, y] picks the upstream end by hand if that's wrong.
  "kind": "sway"   cut into one padded piece per clump, and inpainted out of the clean plate (LaMa)
  "kind": "hang"   like sway, but pinned at the top edge (willow fronds, hanging moss, vines)
  "kind": "still"  never moves: subtracted from the other groups (bridges, mushrooms, posts)
  "minus": [...]   other groups subtracted from this one
  "max_box": 0.3   ignore detector boxes larger than this share of the screen (they swallow the banks)
  "max_side": 90   ignore detector boxes with a side longer than this, in pixels
  "within": [x0, y0, x1, y1]  keep only the part of the group inside this box (words that also match
                   something elsewhere, like reeds read as willow leaves)

Writes to out_dir: <group>_mask.png, <group>_<k>.png pieces, plate.png, preview.jpg, manifest.json.
"""
import json
import os
import sys
import time

import numpy as np
import torch
from PIL import Image, ImageFilter

DINO = "IDEA-Research/grounding-dino-tiny"
SAM = "facebook/sam2.1-hiera-small"
TINTS = {"water": (60, 140, 255), "sway": (60, 220, 90), "hang": (240, 200, 40), "still": (255, 60, 60)}
_models = {}


def _model(kind, device):
    if kind not in _models:
        from transformers import AutoModelForZeroShotObjectDetection, AutoProcessor, Sam2Model, Sam2Processor

        if kind == "dino":
            _models[kind] = (AutoProcessor.from_pretrained(DINO),
                             AutoModelForZeroShotObjectDetection.from_pretrained(DINO).to(device).float().eval())
        else:
            _models[kind] = (Sam2Processor.from_pretrained(SAM), Sam2Model.from_pretrained(SAM).to(device).float().eval())
    return _models[kind]


def detect(image, words, threshold, max_box, max_side, device):
    proc, model = _model("dino", device)
    inputs = proc(images=image, text=words, return_tensors="pt").to(device)
    with torch.no_grad():
        out = model(**inputs)
    res = proc.post_process_grounded_object_detection(
        out, inputs.input_ids, threshold=threshold, text_threshold=threshold, target_sizes=[image.size[::-1]])[0]
    W, H = image.size
    boxes = []
    for b, s, l in zip(res["boxes"].tolist(), res["scores"].tolist(), res["labels"]):
        share = (b[2] - b[0]) * (b[3] - b[1]) / (W * H)
        kept = share <= max_box and max(b[2] - b[0], b[3] - b[1]) <= max_side
        print(f"  {l} {s:.2f} box {[round(v) for v in b]} {share * 100:.0f}% {'' if kept else '(too big, ignored)'}")
        if kept:
            boxes.append(b)
    return boxes


def trace_boxes(image, boxes, device):
    proc, model = _model("sam", device)
    union = np.zeros(image.size[::-1], dtype=bool)
    for i in range(0, len(boxes), 8):
        inputs = proc(images=image, input_boxes=[boxes[i:i + 8]], return_tensors="pt").to(device)
        with torch.no_grad():
            out = model(**inputs, multimask_output=False)
        union |= proc.post_process_masks(out.pred_masks.cpu(), inputs["original_sizes"])[0].squeeze(1).any(0).numpy()
    return union


def trace_region(image, region, device):
    """A hand-given box, with points inside (pos) and outside (neg); SAM's best-scoring guess."""
    proc, model = _model("sam", device)
    pts = region.get("pos", []) + region.get("neg", [])
    kw = {"input_boxes": [[region["box"]]]}
    if pts:
        kw["input_points"] = [[pts]]
        kw["input_labels"] = [[[1] * len(region.get("pos", [])) + [0] * len(region.get("neg", []))]]
    inputs = proc(images=image, return_tensors="pt", **kw).to(device)
    with torch.no_grad():
        out = model(**inputs, multimask_output=True)
    masks = proc.post_process_masks(out.pred_masks.cpu(), inputs["original_sizes"])[0][0]
    best = int(out.iou_scores[0, 0].argmax())
    print(f"  region {region['box']} score {out.iou_scores[0, 0, best].item():.2f}")
    return masks[best].numpy()


def flow_map(mask, source=None, scale=4):
    """Which way a river runs at each pixel, as an RGB image (R, G = direction x, y mapped to 0..1).

    Distance is measured along the water from the upstream end of each separate stretch (its pixel nearest
    the top of the screen, i.e. the horizon, unless `source` is given), and the flow points the way that
    distance grows, so it follows every bend. Worked out at 1/scale size; the shader filters it smooth.
    """
    import heapq

    import cv2

    small = cv2.resize(mask.astype(np.uint8), (mask.shape[1] // scale, mask.shape[0] // scale),
                       interpolation=cv2.INTER_AREA) > 0
    h, w = small.shape
    steps = [(-1, 0, 1.0), (1, 0, 1.0), (0, -1, 1.0), (0, 1, 1.0),
             (-1, -1, 1.414), (-1, 1, 1.414), (1, -1, 1.414), (1, 1, 1.414)]

    def along(starts):
        """Distance along the water from the given (y, x) points."""
        dist = np.full((h, w), np.inf)
        heap = [(0.0, y, x) for y, x in starts]
        for _, y, x in heap:
            dist[y, x] = 0.0
        heapq.heapify(heap)
        while heap:
            d, y, x = heapq.heappop(heap)
            if d > dist[y, x]:
                continue
            for dy, dx, c in steps:
                yy, xx = y + dy, x + dx
                if 0 <= yy < h and 0 <= xx < w and small[yy, xx] and d + c < dist[yy, xx]:
                    dist[yy, xx] = d + c
                    heapq.heappush(heap, (d + c, yy, xx))
        return dist

    n, labels = cv2.connectedComponents(small.astype(np.uint8), connectivity=8)
    ups = []
    for i in range(1, n):
        ys, xs = np.nonzero(labels == i)
        if len(ys) < 20:
            continue
        if source is not None and labels[min(h - 1, source[1] // scale), min(w - 1, source[0] // scale)] == i:
            ups.append((source[1] // scale, source[0] // scale))
        else:
            k = int(np.argmin(ys))
            ups.append((ys[k], xs[k]))
    d_up = along(ups)
    reached = np.isfinite(d_up)
    # Each stretch's downstream end is the point furthest along the water from its upstream end.
    downs = []
    for y, x in ups:
        comp = labels == labels[y, x]
        k = np.argmax(np.where(comp & reached, d_up, -1))
        downs.append(np.unravel_index(k, d_up.shape))
    d_down = along(downs)
    # Downhill from the upstream end and uphill toward the downstream one: in a wide stretch, distance from
    # one point alone fans out; the difference of the two runs end to end along the channel.
    pot = np.where(reached, d_up - np.where(np.isfinite(d_down), d_down, 0.0), 0.0)
    gy, gx = np.gradient(cv2.GaussianBlur(pot, (0, 0), 2) / np.maximum(cv2.GaussianBlur(reached * 1.0, (0, 0), 2), 1e-3))
    # Smooth the directions inside the water only, so the shore doesn't bend them.
    m = reached.astype(np.float64)
    gx = cv2.GaussianBlur(gx * m, (0, 0), 3) / np.maximum(cv2.GaussianBlur(m, (0, 0), 3), 1e-3)
    gy = cv2.GaussianBlur(gy * m, (0, 0), 3) / np.maximum(cv2.GaussianBlur(m, (0, 0), 3), 1e-3)
    length = np.maximum(np.hypot(gx, gy), 1e-6)
    gx, gy = np.where(reached, gx / length, 0.0), np.where(reached, gy / length, 0.0)
    rgb = np.stack([gx * 0.5 + 0.5, gy * 0.5 + 0.5, m], -1)
    return Image.fromarray((rgb * 255).astype(np.uint8))


def split(cut, mask, name, out_dir, pad, hang=False, min_area=600):
    """Each separate clump becomes its own padded piece, so it sways from its own bottom edge (or, for
    hanging things, its top edge): no padding on the root side, `pad` on the other three."""
    import cv2

    n, labels, stats, _ = cv2.connectedComponentsWithStats(mask.astype(np.uint8), connectivity=8)
    W, H = cut.size
    rgba = np.asarray(cut)
    pieces = []
    for i in range(1, n):
        x, y, w, h, area = stats[i]
        if area < min_area:
            continue
        x0, x1 = max(0, x - pad), min(W, x + w + pad)
        y0, y1 = (y, min(H, y + h + pad)) if hang else (max(0, y - pad), y + h)
        piece = rgba[y0:y1, x0:x1].copy()
        piece[..., 3] = np.where(labels[y0:y1, x0:x1] == i, piece[..., 3], 0)
        k = len(pieces) + 1
        Image.fromarray(piece).save(os.path.join(out_dir, f"{name}_{k}.png"))
        pieces.append({"file": f"{name}_{k}.png", "group": name, "hang": hang,
                       "rect": [int(x0), int(y0), int(x1 - x0), int(y1 - y0)]})
    print(f"  {len(pieces)} pieces (clumps under {min_area} px dropped)")
    return pieces


def main():
    spec_path, out_dir = sys.argv[1], sys.argv[2]
    spec = json.load(open(spec_path))
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))  # the repo
    device = "cuda" if torch.cuda.is_available() else "cpu"
    os.makedirs(out_dir, exist_ok=True)
    # Clear what an earlier run wrote here, so stale pieces can't be copied into the game with the new ones.
    old = os.path.join(out_dir, "manifest.json")
    if os.path.exists(old):
        prev = json.load(open(old))
        for f in [p["file"] for p in prev.get("pieces", [])] + [w["file"] for w in prev.get("water_masks", [])]:
            for stale in (f, f.replace("_mask.png", "_flow.png")):
                if os.path.exists(os.path.join(out_dir, stale)):
                    os.remove(os.path.join(out_dir, stale))
    image = Image.open(os.path.join(root, spec["painting"])).convert("RGB")
    t0 = time.time()

    masks = {}
    for name, g in spec["groups"].items():
        print(f"{name}:")
        m = np.zeros(image.size[::-1], dtype=bool)
        if g.get("words"):
            boxes = detect(image, g["words"], g.get("threshold", 0.3), g.get("max_box", 1.0), g.get("max_side", 99999), device)
            if boxes:
                m |= trace_boxes(image, boxes, device)
        for r in g.get("regions", []):
            m |= trace_region(image, r, device)
        if "within" in g:  # keep only what falls inside this box
            x0, y0, x1, y1 = g["within"]
            keep = np.zeros_like(m)
            keep[y0:y1, x0:x1] = True
            m &= keep
        masks[name] = m
    for name, g in spec["groups"].items():
        for other in g.get("minus", []) + [n for n, o in spec["groups"].items() if o["kind"] == "still" and n != name]:
            masks[name] &= ~masks[other]

    preview = np.asarray(image).astype(np.float32)
    hole = np.zeros(image.size[::-1], dtype=bool)
    pieces, water = [], []
    for name, g in spec["groups"].items():
        m = masks[name]
        print(f"{name}: {m.mean() * 100:.1f}% of the screen")
        preview[m] = preview[m] * 0.5 + np.array(TINTS[g["kind"]], dtype=np.float32) * 0.5
        if g["kind"] == "still":
            continue
        soft = Image.fromarray(m.astype(np.uint8) * 255).filter(ImageFilter.GaussianBlur(1))
        soft.save(os.path.join(out_dir, f"{name}_mask.png"))
        if g["kind"] == "water":
            entry = {"file": f"{name}_mask.png", "flow": g.get("flow", False)}
            if entry["flow"]:
                flow_map(m, g.get("source")).save(os.path.join(out_dir, f"{name}_flow.png"))
                entry["flow_map"] = f"{name}_flow.png"
            water.append(entry)
        else:
            cut = image.copy()
            cut.putalpha(soft)
            pieces += split(cut, m, name, out_dir, spec.get("pad", 12), hang=g["kind"] == "hang")
            hole |= m

    Image.fromarray(preview.astype(np.uint8)).save(os.path.join(out_dir, "preview.jpg"), quality=88)
    if hole.any():
        from simple_lama_inpainting import SimpleLama

        t = time.time()
        grow = spec.get("grow", 8)
        grown = Image.fromarray(hole.astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(grow * 2 + 1))
        filled = SimpleLama()(image, grown).resize(image.size)
        # Keep the painting wherever no blade was: the gaps between blades show through the pieces at rest,
        # so only the pixels a blade covered (and a blade's sway can uncover) take LaMa's guess.
        under = Image.fromarray(hole.astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(3))
        Image.composite(filled, image, under).save(os.path.join(out_dir, "plate.png"))
        print(f"plate: inpainted in {time.time() - t:.1f}s")
    with open(os.path.join(out_dir, "manifest.json"), "w") as f:
        json.dump({"pieces": pieces, "water_masks": water}, f, indent=1)
    print(f"done in {time.time() - t0:.1f}s on {device}")


if __name__ == "__main__":
    main()
