"""Build the style browser page (an artifact) from prompts.json and a folder or zip of samples.

  ../segment-env/venv/Scripts/python.exe tools/style_browser/build.py <out folder> "<Label>=<samples folder or zip>" [...]

One "Label=samples" per model (or setting) to compare; the first is the one the page opens on, e.g.
"SDXL round 1=../kept-assets/style-browser/round1".

Samples are ComfyUI's output files (tools/style_browser/comfy_queue.js): <style>__<scene>_<counter>_.png, the newest
counter of each kept. Writes <out>/index.html, <out>/img/<style>__<scene>.webp (later sets in img/<set>/), <out>/img/game/<scene>.webp (our
paintings, to compare with) and <out>/pip_<n>.png (Pip's idle frames). Publish index.html with img/ and the pip files
beside it, declaring the db capability. The person's picks
are in the artifact's database, picks/<style id>: {fav, like: no|maybe|yes|love, small: no|ok|yes, comment}.
"""
import io
import json
import os
import re
import sys
import zipfile

from PIL import Image

# Where Pip stands (feet, 1920x1080) and his size, from each screen's scene file. The reedbed has no scene yet, so it
# has the Screen defaults and a spot on its path.
SCREEN = {
    "boardwalk": dict(label="Boardwalk (easy)", pip=[590, 790], far_y=250, far_height=70, near_y=1075, near_height=270),
    "marsh": dict(label="Marsh (medium)", pip=[1200, 985], far_y=265, far_height=50, near_y=1075, near_height=260),
    "stream": dict(label="Stream (hard)", pip=[1400, 800], far_y=330, far_height=60, near_y=1075, near_height=270),
    "reedbed": dict(label="Reedbed (hardest)", pip=[680, 800], far_y=215, far_height=72, near_y=1075, near_height=253),
}
# Our own painting of each scene. The reedbed is only a still so far, outside git.
PAINTING = {
    "boardwalk": ("assets/screens/boardwalk/boardwalk_bg.jpg", "Our painting"),
    "marsh": ("assets/screens/marsh/marsh_willow_bg.jpg", "Our painting"),
    "stream": ("assets/screens/stream/stream_bg.jpg", "Our painting"),
    "reedbed": ("../preprocessing/reedbed/reedbed_bg.jpg", "Our still (not in the game yet)"),
}
POSES = ["pip_idle_downright_sheet.png", "pip_idle_down_sheet.png", "pip_idle_right_sheet.png"]
NAME = re.compile(r"(?:^|/)([a-z0-9_]+?)__([a-z0-9]+)_(\d+)_\.png$")


def newest_samples(src: str) -> dict:
    """{style__scene: function returning its PNG bytes}, from a folder or a zip."""
    if zipfile.is_zipfile(src):
        z = zipfile.ZipFile(src)
        items = [(n, (lambda n=n: z.read(n))) for n in z.namelist()]
    else:
        items = [(os.path.join(r, f).replace("\\", "/"), (lambda p=os.path.join(r, f): open(p, "rb").read()))
                 for r, _, fs in os.walk(src) for f in fs]
    newest = {}
    for name, read in items:
        m = NAME.search(name)
        if m:
            key, n = f"{m[1]}__{m[2]}", int(m[3])
            if key not in newest or n > newest[key][0]:
                newest[key] = (n, read)
    return {key: read for key, (_, read) in newest.items()}


def main() -> None:
    out = sys.argv[1]
    data = json.load(open("tools/style_browser/prompts.json", encoding="utf8"))
    wanted = {f"{s['id']}__{c['id']}" for s in data["styles"] for c in data["scenes"]}
    sets = []
    for arg in sys.argv[2:]:
        label, src = arg.split("=", 1)
        set_id = re.sub(r"[^a-z0-9]+", "_", label.lower()).strip("_")
        samples = newest_samples(src)
        have = sorted(wanted & set(samples))
        folder = f"img/{set_id}" if sets else "img"
        os.makedirs(f"{out}/{folder}", exist_ok=True)
        for key in have:
            image = Image.open(io.BytesIO(samples[key]())).convert("RGB")
            image.save(f"{out}/{folder}/{key}.webp", quality=86, method=6)
        sets.append({"id": set_id, "label": label, "dir": folder, "have": have})
        print(f"{label}: {len(have)} of {len(wanted)} samples; missing: {sorted(wanted - set(have))[:12]}")
    poses = []
    for i, sheet in enumerate(POSES):
        Image.open(f"assets/pip/{sheet}").crop((0, 0, 320, 320)).save(f"{out}/pip_{i}.png")
        poses.append(f"pip_{i}.png")
    scenes = []
    os.makedirs(f"{out}/img/game", exist_ok=True)
    for c in data["scenes"]:
        path, label = PAINTING[c["id"]]
        painting = f"img/game/{c['id']}.webp" if os.path.exists(path) else None
        if painting:
            Image.open(path).convert("RGB").save(f"{out}/{painting}", quality=90, method=6)
        else:
            print(f"no painting to compare with for {c['id']}: {path}")
        scenes.append({"id": c["id"], **SCREEN[c["id"]], "painting": painting, "painting_label": label})
    page = {"styles": data["styles"], "sets": sets, "poses": poses, "scenes": scenes}
    html = open("tools/style_browser/page.html", encoding="utf8").read()
    html = html.replace("__DATA__", json.dumps(page).replace("<", "\\u003c"))
    open(f"{out}/index.html", "w", encoding="utf8", newline="\n").write(html)


main()
