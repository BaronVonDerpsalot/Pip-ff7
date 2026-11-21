class_name BuildPipFrames
extends RefCounted
## Rebuilds assets/pip/pip_frames.tres (Pip's SpriteFrames) from his sheets.
## Every res://assets/pip/pip_<kind>_<direction>_sheet.png becomes an animation
## "<kind>_<direction>", one 320x320 frame per cell, left to right.
##
## Run after replacing or adding sheets (see docs/recipes/pip-blender.md):
##   BuildPipFrames.build()    # e.g. from Ziva's execute_script
##   BuildPipFrames.build_mole()   # the mole's: assets/mole/mole_<kind>_<direction>_sheet.png, 400x400 frames
## The sheets must be imported by the editor first.

const SHEET_DIR := "res://assets/pip/"
const OUTPUT := "res://assets/pip/pip_frames.tres"
const FRAME_SIZE := 320
## Frames per second by kind; anything not listed uses DEFAULT_FPS.
const FPS := {"walk": 9.0, "idle": 8.0, "run": 12.0, "creep": 7.0}
const DEFAULT_FPS := 8.0


static func build() -> String:
	return build_from(SHEET_DIR, "pip_", OUTPUT, FRAME_SIZE)


static func build_mole() -> String:
	return build_from("res://assets/mole/", "mole_", "res://assets/mole/mole_frames.tres", 400)


## Every <dir><prefix><kind>_<direction>_sheet.png becomes "<kind>_<direction>", frame_size square frames.
static func build_from(sheet_dir: String, prefix: String, output: String, frame_size: int) -> String:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var report := PackedStringArray()
	var files := DirAccess.get_files_at(sheet_dir)
	files.sort()
	for file in files:
		if not (file.begins_with(prefix) and file.ends_with("_sheet.png")):
			continue
		var parts := file.trim_prefix(prefix).trim_suffix("_sheet.png").split("_", false, 1)
		if parts.size() != 2:
			report.append("skipped " + file + " (name isn't " + prefix + "<kind>_<direction>_sheet.png)")
			continue
		var anim := StringName(parts[0] + "_" + parts[1])
		var sheet: Texture2D = load(sheet_dir + file)
		if sheet == null:
			report.append("skipped " + file + " (not imported yet)")
			continue
		var count := sheet.get_width() / frame_size
		frames.add_animation(anim)
		frames.set_animation_loop(anim, true)
		frames.set_animation_speed(anim, FPS.get(parts[0], DEFAULT_FPS))
		for i in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(i * frame_size, 0, frame_size, frame_size)
			frames.add_frame(anim, atlas)
		report.append("%s: %d frames" % [anim, count])
	var err := ResourceSaver.save(frames, output)
	report.append("saved " + output + (" OK" if err == OK else " FAILED (%d)" % err))
	return "\n".join(report)
