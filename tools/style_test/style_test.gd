extends Screen
## Style test bench (not part of the game): Pip walks the paths of trial paintings so their look can be
## judged with him in front. Run tools/style_test/style_test.tscn.
##
## Drop images (PNG, JPG or WebP, ideally 16:9) into Pip FF7/kept-assets/style-tests/, outside git, or into
## a subfolder of it for a round of tests (the label shows which); names must be unique across folders.
## Tab flips to the next one, Shift+Tab back. F shows the walk area.
##
## Each image can have files of its own in style-tests/bench/, with the image's name:
##   <name>.jpg        the painting at 1920x1080 (otherwise the original is stretched to fit)
##   <name>.json       {"walk": [x, y, ...], "start": [x, y], "far_y", "far_height", "near_y", "near_height",
##                     "gaps"?: [[x, y, ...], ...]} in 1920x1080 pixels: where Pip can walk, where he starts,
##                     his size (Screen), and holes in what he walks on (the Gaps node, depth_occluder.gd)
##   <name>_depth.png  depth map of <name>.jpg (tools/depth/depth.py), so nearer things hide him
##   <name>_shapes/    hide-Pip shapes as PNGs cut from <name>.jpg, listed in manifest.json (see _add_shapes)
## Without a json he can walk anywhere; without a depth map nothing hides him.

const FOLDER := "../kept-assets/style-tests"
const SIZE := Vector2(1920, 1080)

## Which image is showing; kept across the reload that Tab does, so every part of the screen
## (Pip's light, shadow, the depth occluder) sets itself up from scratch for each image.
static var _index := 0

var _files := PackedStringArray()
var _note := ""


## Runs before Pip's and the occluder's _ready, which read the painting, depth map and depth numbers.
func _enter_tree() -> void:
	var dir := ProjectSettings.globalize_path("res://").path_join(FOLDER).simplify_path()
	# The folder and each subfolder but bench/ (one round of tests each); contact sheets are skipped.
	for sub in [""] + Array(DirAccess.get_directories_at(dir)):
		if sub == "bench":
			continue
		var files: Array = Array(DirAccess.get_files_at(dir.path_join(sub)))
		files.sort()
		for file: String in files:
			if file.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"] and not "contact_sheet" in file:
				_files.append(dir.path_join(sub).path_join(file))
	if _files.is_empty():
		_note = "No images yet. Put some in %s, then run this again." % dir
		_drop_occluder()
		return
	_index = posmod(_index, _files.size())
	var stem := _files[_index].get_file().get_basename()
	var bench := dir.path_join("bench")

	var path := bench.path_join(stem + ".jpg")
	var image := Image.load_from_file(path if FileAccess.file_exists(path) else _files[_index])
	if image.get_size() != Vector2i(SIZE):
		image.resize(int(SIZE.x), int(SIZE.y), Image.INTERPOLATE_LANCZOS)
	($Background as Sprite2D).texture = ImageTexture.create_from_image(image)

	var extras: PackedStringArray = []
	var json_path := bench.path_join(stem + ".json")
	if FileAccess.file_exists(json_path):
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(json_path))
		far_y = data.far_y
		far_height = data.far_height
		near_y = data.near_y
		near_height = data.near_height
		var points := PackedVector2Array()
		var walk: Array = data.walk
		for i in range(0, walk.size(), 2):
			points.append(Vector2(walk[i], walk[i + 1]))
		($WalkArea as Polygon2D).polygon = points
		($World/Pip as Node2D).position = Vector2(data.start[0], data.start[1])
		# Holes in what Pip walks on, for the depth occluder (a Gaps node, as on a screen).
		if data.has("gaps") and not (data.gaps as Array).is_empty():
			var gaps := Node2D.new()
			gaps.name = "Gaps"
			for g: Array in data.gaps:
				var shape := Polygon2D.new()
				var gp := PackedVector2Array()
				for i in range(0, g.size(), 2):
					gp.append(Vector2(g[i], g[i + 1]))
				shape.polygon = gp
				gaps.add_child(shape)
			add_child(gaps)
		extras.append("path")
	var shapes := _add_shapes(bench.path_join(stem + "_shapes"))
	if shapes > 0:
		extras.append("%d shapes" % shapes)
	var depth_path := bench.path_join(stem + "_depth.png")
	if FileAccess.file_exists(depth_path):
		depth_map = ImageTexture.create_from_image(Image.load_from_file(depth_path))
		extras.append("depth")
	else:
		_drop_occluder()
	var folder := _files[_index].get_base_dir().get_file()
	if folder != "style-tests":
		stem = folder + "/" + stem
	_note = "%d/%d  %s  [%s]   (Tab: next, Shift+Tab: back, F: walk area)" % [
			_index + 1, _files.size(), stem, ", ".join(extras) if extras else "no path or depth"]


func _ready() -> void:
	super._ready()
	($Info/Label as Label).text = _note


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if _files.is_empty():
		return
	if event.is_action_pressed("ui_focus_prev"):
		_index -= 1
		get_tree().reload_current_scene.call_deferred()
	elif event.is_action_pressed("ui_focus_next"):
		_index += 1
		get_tree().reload_current_scene.call_deferred()


## Hide-Pip shapes from <dir>/manifest.json ([{"file", "x", "y", "sort"?, "edge"?: [ax, ay, bx, by]}], files beside it), each a sprite
## with the game's own occluder (scripts/occluder.gd: the bottom-edge rule, or always over with sort false).
func _add_shapes(dir: String) -> int:
	var manifest := dir.path_join("manifest.json")
	if not FileAccess.file_exists(manifest):
		return 0
	var overhead := $Overhead
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string(manifest))
	for entry: Dictionary in entries:
		var sprite := Sprite2D.new()
		sprite.name = "Shape_" + String(entry.file).get_basename()
		sprite.texture = ImageTexture.create_from_image(Image.load_from_file(dir.path_join(entry.file)))
		sprite.centered = false
		sprite.position = Vector2(entry.x, entry.y)
		sprite.set_script(preload("res://scripts/occluder.gd"))
		sprite.set("sort", entry.get("sort", true))
		if entry.has("edge"):
			var e: Array = entry.edge
			sprite.set("edge", PackedVector2Array([Vector2(e[0], e[1]), Vector2(e[2], e[3])]))
		overhead.add_child(sprite)
		overhead.move_child(sprite, 0)  # under the depth occluder, like Auto_ sprites on a screen
	return entries.size()


func _drop_occluder() -> void:
	var occ := get_node_or_null("Overhead/DepthOcc")
	if occ != null:
		occ.get_parent().remove_child(occ)
		occ.free()
