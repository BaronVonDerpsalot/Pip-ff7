// Queue the occlusion set for one screen on ComfyUI (MimicPC), from the ComfyUI page itself.
// Run in the page with the browser's JavaScript tool (claude-in-chrome javascript_tool), then call
//   await pipOcc.queue("<screen>")   after the painting is uploaded as input/pip/pip_<screen>.jpg (pipOcc.upload)
//   await pipOcc.status()            until it says all done
// Outputs land in output/pip/comfy/ as <screen>_depth_dav2l_00001_.png and <screen>_sam3_<thing>_mask_00001_.png;
// download that folder as a zip from MimicPC's storage panel, then run tools/depth/comfy_import.py.
// Needs the nodes in docs/recipes/screens-layering.md (Depth occlusion, step 1) and sam3.pt in models/sam3/.
// Reading results: read prompt ids and statuses only. A full log or history dump can carry tokens, and the
// browser tool blocks output that looks like one.
window.pipOcc = (() => {
  const b = location.origin;
  // Things that hide Pip, and the walkable surface (for tools/depth/walk_guess.py).
  const HIDE = ["wooden post", "reeds", "grassy bank"];
  const WALK = ["dirt path", "wooden boardwalk", "footbridge"];
  const slug = (s) => s.replace(/\s+/g, "_");

  function depthJob(screen) {
    return {
      "1": { class_type: "LoadImage", inputs: { image: `pip/pip_${screen}.jpg` } },
      "2": { class_type: "DownloadAndLoadDepthAnythingV2Model", inputs: { model: "depth_anything_v2_vitl_fp16.safetensors" } },
      "3": { class_type: "DepthAnything_V2", inputs: { da_model: ["2", 0], images: ["1", 0] } },
      "4": { class_type: "SaveImage", inputs: { images: ["3", 0], filename_prefix: `pip/comfy/${screen}_depth_dav2l` } },
    };
  }

  function samJob(screen, prompt) {
    return {
      "1": { class_type: "LoadImage", inputs: { image: `pip/pip_${screen}.jpg` } },
      "2": { class_type: "TBGSAM3ModelLoaderAdvanced", inputs: { model_source: "local (auto-download)", device: "cuda" } },
      "3": { class_type: "TBGSam3Segmentation", inputs: {
        sam3_model: ["2", 0], image: ["1", 0], confidence_threshold: 0.3, pipeline_mode: "all", detect_all: true,
        max_detections: 50, instances: false, crop_factor: 1.5, min_size: 1, fill_holes: false, edge_feather: 0,
        text_prompt: prompt } },
      // Output 5 is combined_mask; output 0 stays empty with instances off.
      "4": { class_type: "MaskToImage", inputs: { mask: ["3", 5] } },
      "5": { class_type: "SaveImage", inputs: { images: ["4", 0], filename_prefix: `pip/comfy/${screen}_sam3_${slug(prompt)}_mask` } },
    };
  }

  async function post(prompt) {
    const r = await fetch(b + "/prompt", { method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt, client_id: "pip-occlusion" }) });
    const j = await r.json();
    return j.prompt_id || ("ERROR " + JSON.stringify(j.node_errors || j.error).slice(0, 300));
  }

  return {
    // Upload files from an <input type=file> (the agent adds one and fills it with file_upload) as pip/pip_<screen>.jpg.
    async upload(input, screens) {
      const out = [];
      for (let i = 0; i < input.files.length; i++) {
        const f = input.files[i];
        const fd = new FormData();
        fd.append("image", f, `pip_${screens[i]}.jpg`);
        fd.append("type", "input"); fd.append("subfolder", "pip"); fd.append("overwrite", "true");
        const r = await fetch(b + "/upload/image", { method: "POST", body: fd });
        out.push(`${f.name} -> pip_${screens[i]}.jpg ${r.status}`);
      }
      return out.join("\n");
    },
    async queue(screen) {
      const ids = [["depth", await post(depthJob(screen))]];
      for (const p of [...HIDE, ...WALK]) ids.push([p, await post(samJob(screen, p))]);
      const all = JSON.parse(localStorage.getItem("pipOcc") || "{}");
      all[screen] = ids;
      localStorage.setItem("pipOcc", JSON.stringify(all));
      return ids.map(([n, id]) => `${screen} ${n}: ${id}`).join("\n");
    },
    async status() {
      const all = JSON.parse(localStorage.getItem("pipOcc") || "{}");
      const h = await fetch(b + "/history?max_items=200").then((r) => r.json());
      const lines = [];
      let pending = 0;
      for (const [screen, ids] of Object.entries(all)) {
        for (const [n, id] of ids) {
          const s = h[id] ? h[id].status.status_str : "pending";
          if (s === "pending") pending++;
          let why = "";
          if (s === "error") {
            const e = h[id].status.messages.find((m) => m[0] === "execution_error");
            why = " " + String(e ? e[1].exception_type + ": " + e[1].exception_message : "").split(/\s+/)
              .filter((w) => !/[=?&]|https?:|hf_|[A-Za-z0-9]{30,}/.test(w)).join(" ").slice(0, 200);
          }
          lines.push(`${screen} ${n}: ${s}${why}`);
        }
      }
      return (pending ? `${pending} still running\n` : "all done\n") + lines.join("\n");
    },
  };
})();
"pipOcc ready";
