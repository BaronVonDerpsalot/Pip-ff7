# Recipe: builds and the itch.io link

Making the web build and the Windows build, and putting the web one on itch.io. Why these two: `DECISIONS.md`, 2026-11-13.

## Once per PC
1. Install Godot 4.7.2's export templates, the official ones, version-matched to the editor. Use the editor's **Editor > Manage Export Templates**, or download `Godot_v4.7.2-stable_export_templates.tpz` from the 4.7.2-stable GitHub release. If you download it, check it against that release's `SHA512-SUMS.txt`. The game needs only `web_*`, `windows_*x86_64*`, `version.txt` and `icudt_godot.dat`. They go in `%APPDATA%/Godot/export_templates/4.7.2.stable/`.
2. The presets live in `export_presets.cfg`, which is committed: "Web" (single-threaded) and "Windows Desktop" (the game packed into the .exe, unsigned). Both skip `tools/` and `docs/`.

## Build
Builds go to `Pip FF7/builds/`, next to the repo and never committed. On Mike's PC the console exe is in `C:\Games\Godot\`. From the repo folder:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Web" ../builds/web/site/index.html
Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows Desktop" "../builds/windows/Pip FF7.exe"
```

Then zip each one. For the web build, zip the *contents* of `site/` so `index.html` sits at the top of the zip: `../builds/web/pip-ff7-web.zip`. For Windows, zip the .exe: `../builds/windows/pip-ff7-windows.zip`.

## Check before handing it over
- **Web:** start the `web-build` server in `.claude/launch.json` (it serves `../builds/web/site` on localhost:8060) and open it in the browser. The marsh and Pip should load, he should walk, and the console should show no errors.
- **Windows:** run the .exe. It opens a 1280×720 window on the marsh.
- **Both, Pip's looks:** walk him and check that he takes on the light at his feet, casts his own soft shadow (none on water), shows a reflection only inside water with a ring when he steps in, hides behind the boardwalk and stream bridge posts, and that reeds, willow fronds and water move on every screen.

## itch.io
- Upload the web zip as an HTML game and tick "This file will be played in the browser". Use a 1280×720 viewport with the fullscreen button on, and leave "SharedArrayBuffer support" off, since the build is single-threaded.
- Keep the page private: Draft (secret link) or Restricted (password). Christine only gets finished products (`DECISIONS.md`).
- The Windows zip can go on the same page as a download.

## Gotchas
- **Export to `index.html`, then zip it yourself** (2026-11-13, M3): exporting straight to a `.zip` path didn't make a zip. Godot wrote loose files and saved the HTML page under the `.zip` name.
- **A browser doesn't see the pad until a button is pressed** (2026-11-13, M3, from Godot's web export docs). Press a pad button before using the stick. Button mapping can also differ between browsers, so if the pad misbehaves, try another browser or the Windows build.
- **Windows warns about the unsigned .exe** (2026-11-13, M3): SmartScreen shows a blue warning the first time. Click "More info", then "Run anyway".
- **Tapped keys don't walk Pip in the browser pane** (2026-11-13, M3): repeated key taps sent from the browser tools left Pip standing still, because he reads keys held down from frame to frame. When testing the web build in the browser pane, send `keydown`, wait about a second, then `keyup` to the canvas from `javascript_tool`.
- **Computer use finds the .exe by its file name** (2026-11-13, M3): asking for "Pip FF7" failed, while "Pip FF7.exe" (the process name) worked. Its `hold_key` then walked Pip in the window. When checking the Windows build with computer use, request access to `Pip FF7.exe`.
- **A hidden browser pane runs the web build at about 3 fps** (2026-11-20, M5): with the pane hidden, a one-second key hold moved Pip only a fraction of his normal distance. When the pane is hidden, toggle run with Shift and hold keys longer, or show the pane first.
- **Grab the canvas to inspect the web build** (2026-11-20, M5): pane screenshots come back at 800×450, too small to judge the shadow or ripples. When you need detail, grab `canvas.toDataURL()` inside a double `requestAnimationFrame` from `javascript_tool`, then draw crops (or a two-frame difference) onto an overlay canvas and screenshot that. The difference of two frames shows the shadow and shader motion plainly.
- **No need to clear `site/` before exporting** (2026-11-20, M5): `rm` on `../builds/web/site/*` was blocked by Claude Code's safety check. The export overwrites the same file names anyway, so export over the old files.
