// Widen a screen's painting sideways on ComfyUI (MimicPC) with Flux Fill, for the wide screen test.
// Run in the ComfyUI page with the browser's JavaScript tool (claude-in-chrome javascript_tool), then:
//   await pipWide.upload(input, "<screen>")   input: an <input type=file> filled with the painting (file_upload)
//   await pipWide.queue("<screen>", seed)     one job: two steps each side, each adding `STEP` px
//   await pipWide.status()                    until it says done
//   await pipWide.stitch("<screen>")          joins them and uploads input/pip/pip_<screen>_wide.jpg, ready for
//                                             tools/depth/comfy_queue.js (pipOcc.queue("<screen>_wide"))
// Each step paints STEP new pixels beside KEEP pixels of the painting (or the step before), so every step
// sees half a screen of what's already there. Outputs land in output/pip/wide/ as <screen>_R1, _R2, _L1, _L2.
// The stitch keeps only each step's new pixels, blended into the old over BLEND px so the seam doesn't show,
// and shows the result over the page (click to close). On the T4: about 28 s a sampling step at 1440x1088,
// so 11 minutes a piece and 45 for all four (2026-11-27).
window.pipWide = (() => {
  const b = location.origin;
  const UNET = "FLUX1/flux1-fill-dev.safetensors";
  const KEEP = 960, STEP = 480, H = 1080, PADB = 8;  // Flux wants sizes in 16s: 1080 is padded to 1088
  const PROMPT =
    "In the style of Hayao Miyazaki, but slightly more subdued colours, high angle overhead image with ray tracing " +
    "and reflections of a marsh land, seen from a raised viewpoint about as high as a two-storey house, looking down " +
    "at about 45 degrees. The marsh carries on: tussocks of grass, reeds and cattails, still pools and puddles " +
    "reflecting the sky, muddy ground, the occasional willow. Only a thin band of distant marsh and sky along the top. " +
    "Soft, muted greens and browns. A few very small red and white mushrooms. Sunset lighting. Hand-painted, " +
    "watercolour and ink linework. No people, no animals, no writing, no signature, no caption.";

  let last = null;

  function graph(screen, seed, steps) {
    const g = {
      unet: { class_type: "UNETLoader", inputs: { unet_name: UNET, weight_dtype: "fp8_e4m3fn" } },
      clip: { class_type: "DualCLIPLoader", inputs: { clip_name1: "clip_l.safetensors", clip_name2: "t5xxl_fp8_e4m3fn.safetensors", type: "flux" } },
      vae: { class_type: "VAELoader", inputs: { vae_name: "FLUX1/ae.safetensors" } },
      pos: { class_type: "CLIPTextEncode", inputs: { clip: ["clip", 0], text: PROMPT } },
      neg: { class_type: "CLIPTextEncode", inputs: { clip: ["clip", 0], text: "" } },
      guide: { class_type: "FluxGuidance", inputs: { conditioning: ["pos", 0], guidance: 30 } },
      model: { class_type: "DifferentialDiffusion", inputs: { model: ["unet", 0] } },
      src: { class_type: "LoadImage", inputs: { image: `pip/wide_${screen}.png` } },
    };
    // One step: crop KEEP px at x from `from`, pad STEP px on `side`, fill, decode, save.
    const step = (name, from, x, side, s, n) => {
      g[name + "_crop"] = { class_type: "ImageCrop", inputs: { image: from, width: KEEP, height: H, x, y: 0 } };
      g[name + "_pad"] = { class_type: "ImagePadForOutpaint", inputs: { image: [name + "_crop", 0], left: side === "L" ? STEP : 0,
        top: 0, right: side === "R" ? STEP : 0, bottom: PADB, feathering: 48 } };
      g[name + "_cond"] = { class_type: "InpaintModelConditioning", inputs: { positive: ["guide", 0], negative: ["neg", 0],
        vae: ["vae", 0], pixels: [name + "_pad", 0], mask: [name + "_pad", 1], noise_mask: true } };
      g[name + "_ks"] = { class_type: "KSampler", inputs: { model: ["model", 0], seed: s, steps: n, cfg: 1, sampler_name: "euler",
        scheduler: "normal", positive: [name + "_cond", 0], negative: [name + "_cond", 1], latent_image: [name + "_cond", 2], denoise: 1 } };
      g[name + "_dec"] = { class_type: "VAEDecode", inputs: { samples: [name + "_ks", 0], vae: ["vae", 0] } };
      g[name + "_save"] = { class_type: "SaveImage", inputs: { images: [name + "_dec", 0], filename_prefix: `pip/wide/${screen}_${name}` } };
      return [name + "_dec", 0];
    };
    const W = 1920;
    const r1 = step("R1", ["src", 0], W - KEEP, "R", seed, steps[0]);
    step("R2", r1, KEEP + STEP - KEEP, "R", seed + 1, steps[1]);  // the right-hand KEEP px of R1 (which is KEEP + STEP wide)
    const l1 = step("L1", ["src", 0], 0, "L", seed + 2, steps[2]);
    step("L2", l1, 0, "L", seed + 3, steps[3]);
    return g;
  }

  return {
    async upload(input, screen) {
      const fd = new FormData();
      fd.append("image", input.files[0], `wide_${screen}.png`);
      fd.append("type", "input"); fd.append("subfolder", "pip"); fd.append("overwrite", "true");
      const r = await fetch(b + "/upload/image", { method: "POST", body: fd });
      return `${input.files[0].name} -> pip/wide_${screen}.png ${r.status}`;
    },
    // steps: sampling steps for R1, R2, L1, L2. Requeueing with a piece unchanged reuses it from ComfyUI's cache.
    async queue(screen, seed = 7, steps = [24, 16, 16, 16]) {
      const r = await fetch(b + "/prompt", { method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ prompt: graph(screen, seed, steps) }) });
      const j = await r.json();
      last = j.prompt_id;
      return j.prompt_id ? `queued ${j.prompt_id}` : JSON.stringify(j.node_errors || j.error).slice(0, 600);
    },
    async stitch(screen, seedFile = "00001") {
      const BLEND = 96, MATCH = 60, W = 1920, left = 2 * STEP;
      const report = [];
      const img = (url) => new Promise((res, rej) => { const i = new Image(); i.onload = () => res(i); i.onerror = rej; i.src = url; });
      const c = document.createElement("canvas"); c.width = W + 4 * STEP; c.height = H;
      const x = c.getContext("2d");
      x.drawImage(await img(b + `/view?type=input&subfolder=pip&filename=wide_${screen}.png`), left, 0);
      // Each piece's x=0 in the painting's coordinates.
      for (const [n, px] of [["R1", W - KEEP], ["R2", W - KEEP + STEP], ["L1", -STEP], ["L2", -2 * STEP]]) {
        const i = await img(b + `/view?type=output&subfolder=pip%2Fwide&filename=${screen}_${n}_${seedFile}_.png`);
        const t = document.createElement("canvas"); t.width = KEEP + STEP; t.height = H;
        const tx = t.getContext("2d");
        tx.drawImage(i, 0, 0);
        const right = n[0] === "R";
        // Flux Fill paints the new part brighter and greyer than the painting (marsh R1: +20 levels at the seam),
        // so scale each channel of the new pixels to match what's already on the canvas beside the seam.
        const seam = right ? KEEP : STEP;  // the first new column (right) or one past the last (left)
        const mean = (ctx, x0) => { const d = ctx.getImageData(x0, 0, MATCH, H).data; const s = [0, 0, 0];
          for (let k = 0; k < d.length; k += 4) { s[0] += d[k]; s[1] += d[k + 1]; s[2] += d[k + 2]; }
          return s.map((v) => v / (d.length / 4)); };
        const old = mean(x, left + px + (right ? seam - MATCH : seam));
        const neu = mean(tx, right ? seam : seam - MATCH);
        const gain = old.map((v, k) => v / Math.max(neu[k], 1));
        const nd = tx.getImageData(0, 0, KEEP + STEP, H);
        for (let k = 0; k < nd.data.length; k += 4) for (let ch = 0; ch < 3; ch++) nd.data[k + ch] = Math.min(255, nd.data[k + ch] * gain[ch]);
        tx.putImageData(nd, 0, 0);
        report.push(`${n} gain ${gain.map((g) => g.toFixed(2)).join("/")}`);
        // Keep the new pixels, fading into the old over BLEND px.
        const g = tx.createLinearGradient(right ? KEEP - BLEND : STEP + BLEND, 0, right ? KEEP : STEP, 0);
        g.addColorStop(0, "rgba(0,0,0,0)"); g.addColorStop(1, "rgba(0,0,0,1)");
        tx.globalCompositeOperation = "destination-in";
        tx.fillStyle = g;
        tx.fillRect(right ? KEEP - BLEND : 0, 0, right ? STEP + BLEND : STEP + BLEND, H);
        if (right) tx.clearRect(0, 0, KEEP - BLEND, H); else tx.clearRect(STEP + BLEND, 0, KEEP - BLEND, H);
        x.drawImage(t, left + px, 0);
      }
      const blob = await new Promise((r) => c.toBlob(r, "image/jpeg", 0.95));
      const fd = new FormData();
      fd.append("image", blob, `pip_${screen}_wide.jpg`);
      fd.append("type", "input"); fd.append("subfolder", "pip"); fd.append("overwrite", "true");
      const r = await fetch(b + "/upload/image", { method: "POST", body: fd });
      let o = document.getElementById("pipWidePrev");
      if (!o) { o = document.createElement("img"); o.id = "pipWidePrev"; document.body.appendChild(o); o.onclick = () => o.remove(); }
      o.style.cssText = "position:fixed;inset:0;width:100vw;z-index:999999;background:#000";
      o.src = URL.createObjectURL(blob);
      // A copy in output/pip/comfy/, so one download of that folder brings the painting with its depth and masks.
      await fetch(b + "/prompt", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ prompt: {
        "1": { class_type: "LoadImage", inputs: { image: `pip/pip_${screen}_wide.jpg` } },
        "2": { class_type: "SaveImage", inputs: { images: ["1", 0], filename_prefix: `pip/comfy/${screen}_wide_painting` } } } }) });
      return `${c.width}x${c.height} -> input/pip/pip_${screen}_wide.jpg ${r.status}; ${report.join(", ")}`;
    },
    async status() {
      const q = await fetch(b + "/queue").then((r) => r.json());
      const h = last ? await fetch(b + "/history/" + last).then((r) => r.json()) : {};
      const e = h[last];
      if (!e) return `running ${q.queue_running.length}, pending ${q.queue_pending.length}`;
      const files = Object.values(e.outputs || {}).flatMap((o) => (o.images || []).map((i) => i.filename));
      return `${e.status?.status_str}: ${files.join(", ")}`;
    },
  };
})();
