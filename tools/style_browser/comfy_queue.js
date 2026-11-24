// Queue the style browser's images on ComfyUI (MimicPC), from the ComfyUI page itself.
// Run in the page with the browser's JavaScript tool (claude-in-chrome javascript_tool), with window.P set to
// prompts.json (read from an <input type=file> filled by file_upload), then call
//   await pipStyles.queue(0, 25)     styles [from, to) x every scene, style by style so finished styles are complete
//   await pipStyles.status()         counts only
// The scenes' depth maps must be in input/pip/ as grey PNGs: <scene>_depthgrey.png (nearer whiter; the game's
// 16-bit maps: take the red channel). Outputs land in output/pip/styles/ as <style>__<scene>_00001_.png.
// Needs an SDXL depth ControlNet in models/controlnet (CONTROLNET below, from ComfyUI-Manager's model list).
window.pipStyles = (() => {
  const b = location.origin;
  const CKPT = "sdxl/sd_xl_base_1.0_0.9vae.safetensors";
  const CONTROLNET = "SDXL/controlnet-depth-sdxl-1.0/diffusion_pytorch_model.safetensors";

  function job(style, scene, opt) {
    const neg = P.negative + (style.negative_extra ? ", " + style.negative_extra : "");
    const depth = opt.depth || `pip/${scene.id}_depthgrey.png`;
    return {
      "1": { class_type: "CheckpointLoaderSimple", inputs: { ckpt_name: CKPT } },
      "2": { class_type: "CLIPTextEncode", inputs: { clip: ["1", 1], text: [style.prompt, scene.content, P.shared_suffix].join(", ") } },
      "3": { class_type: "CLIPTextEncode", inputs: { clip: ["1", 1], text: neg } },
      "4": { class_type: "ControlNetLoader", inputs: { control_net_name: opt.controlnet || CONTROLNET } },
      "5": { class_type: "LoadImage", inputs: { image: depth } },
      "6": { class_type: "ControlNetApplyAdvanced", inputs: { positive: ["2", 0], negative: ["3", 0], control_net: ["4", 0],
        image: ["5", 0], strength: opt.strength, start_percent: 0, end_percent: opt.end, vae: ["1", 2] } },
      "7": { class_type: "EmptyLatentImage", inputs: { width: 1344, height: 768, batch_size: 1 } },
      "8": { class_type: "KSampler", inputs: { model: ["1", 0], positive: ["6", 0], negative: ["6", 1], latent_image: ["7", 0],
        seed: scene.seed, steps: opt.steps, cfg: P.settings.cfg, sampler_name: "dpmpp_2m", scheduler: "karras", denoise: 1 } },
      "9": { class_type: "VAEDecode", inputs: { samples: ["8", 0], vae: ["1", 2] } },
      "10": { class_type: "SaveImage", inputs: { images: ["9", 0], filename_prefix: `pip/styles/${style.id}__${scene.id}` } },
    };
  }

  async function post(prompt) {
    const r = await fetch(b + "/prompt", { method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt, client_id: "pip-styles" }) });
    const j = await r.json();
    return j.prompt_id || ("ERROR " + JSON.stringify(j.node_errors || j.error).slice(0, 300));
  }

  return {
    // opt: strength, end, steps, controlnet, scenes (ids), depth (an input/ path overriding the scene's).
    async queue(from, to, opt = {}) {
      opt = { strength: 0.6, end: 0.8, steps: P.settings.steps, ...opt };
      const ids = JSON.parse(localStorage.getItem("pipStyles") || "{}");
      const errs = [];
      for (const style of P.styles.slice(from, to))
        for (const scene of P.scenes) {
          if (opt.scenes && !opt.scenes.includes(scene.id)) continue;
          const id = await post(job(style, scene, opt));
          if (id.startsWith("ERROR")) errs.push(`${style.id}/${scene.id} ${id}`);
          else ids[`${style.id}__${scene.id}`] = id;
        }
      localStorage.setItem("pipStyles", JSON.stringify(ids));
      return `${Object.keys(ids).length} known jobs` + (errs.length ? "\n" + errs.slice(0, 3).join("\n") : "");
    },
    async status() {
      const ids = JSON.parse(localStorage.getItem("pipStyles") || "{}");
      const h = await fetch(b + "/history?max_items=300").then((r) => r.json());
      const n = { success: 0, error: 0, pending: 0 };
      const secs = [];
      for (const id of Object.values(ids)) {
        const s = h[id] ? h[id].status.status_str : "pending";
        n[s] = (n[s] || 0) + 1;
        if (h[id]) {
          const t = Object.fromEntries(h[id].status.messages.map((m) => [m[0], m[1].timestamp]));
          if (t.execution_success) secs.push((t.execution_success - t.execution_start) / 1000);
        }
      }
      return JSON.stringify({ ...n, lastSecs: secs.slice(-4).map(Math.round) });
    },
  };
})();
"pipStyles ready";
