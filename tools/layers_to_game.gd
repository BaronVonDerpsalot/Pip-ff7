extends SceneTree
## Turns the layers sent from Affinity (tools/affinity/send_to_game.js) into game assets.
## Run through tools/send_layers.sh, which also imports the new images. By hand:
##   godot --headless --path . -s tools/layers_to_game.gd -- <screen> <work folder>
##
## For each layer in <screen>__manifest.json it writes assets/screens/<screen>/<screen>_occ_<name>.png
## and puts a Sprite2D named Occ_<name> in scenes/screens/<screen>.tscn, with scripts/occluder.gd:
##   SORTED   under Overhead, covering Pip only while his feet are above its bottom edge at his x.
##            Each separate shape in the layer becomes its own piece (Occ_<name>_<k>) with its own edge.
##            Affinity's script sends every layer as SORTED unless its name starts with "Over".
##   OVERHEAD under Overhead, covering Pip always (layers named "Over...", like hanging fronds).
##   WORLD    (only if a manifest asks for it) under World, positioned at its base (the layer's lowest opaque
##            pixel unless the manifest gives one), image pulled up by offset, so World's y-sort puts Pip
##            behind it while his feet are above the base.
## Running it again replaces every Occ_ sprite and its PNG, and touches nothing else in the scene.
## Every run also stamps the scene's Overhead node with `metadata/layered = true`. An empty send (no
## layers) is how a person says "I looked, this screen needs none", so it counts as layered too.
## If the Affinity document wasn't 1920x1080, the layer is scaled to game size with its colours
## taken from the painting itself, so it stays sharp.

const GAME_W := 1920
const GAME_H := 1080


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: godot --headless --path . -s tools/layers_to_game.gd -- <screen> <work folder>")
		quit(2)
		return
	quit(_run(args[0], args[1]))


func _run(screen: String, work: String) -> int:
	var manifest_path := work.path_join("%s__manifest.json" % screen)
	if not FileAccess.file_exists(manifest_path):
		printerr("No manifest at ", manifest_path)
		return 1
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	var scene_path := "res://scenes/screens/%s.tscn" % screen
	if not FileAccess.file_exists(scene_path):
		printerr("No scene at ", scene_path, " (the document must be named after the screen)")
		return 1
	var scene_text := FileAccess.get_file_as_string(scene_path)
	var doc_w := int(manifest.get("doc_w", GAME_W))
	var doc_h := int(manifest.get("doc_h", GAME_H))
	var scaled := doc_w != GAME_W or doc_h != GAME_H
	var painting: Image = null
	if scaled:
		painting = _load_painting(scene_text)
		if painting == null:
			printerr("The document is %dx%d, not %dx%d, and the screen's painting wasn't found to take colours from." % [doc_w, doc_h, GAME_W, GAME_H])
			return 1
		print("Document is %dx%d: scaling layers to game size." % [doc_w, doc_h])

	var dir_res := "res://assets/screens/%s/" % screen
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_res))
	var placed: Array[Dictionary] = []
	for layer: Dictionary in manifest.get("layers", []):
		placed.append_array(_place_layer(layer, work, screen, dir_res, doc_w, doc_h, scaled, painting))

	_remove_stale(dir_res, screen, placed)
	_write_scene(scene_path, scene_text, dir_res, placed)

	for s: String in manifest.get("skipped", []):
		print("Skipped: ", s)
	for p: Dictionary in placed:
		print("%-9s %-24s at %s, %dx%d%s" % [p.role, p.name, p.rect.position, p.rect.size.x, p.rect.size.y, ("  base " + str(p.base)) if p.role == "WORLD" else ""])
	# Tidy up the hand-over files; keep the manifest for debugging.
	for layer: Dictionary in manifest.get("layers", []):
		DirAccess.remove_absolute(work.path_join(layer.file))
	DirAccess.rename_absolute(manifest_path, work.path_join("%s__last_manifest.json" % screen))
	print("DONE %d layer(s) -> %s" % [placed.size(), scene_path])
	return 0


## Reads one layer's pixels, scales if needed, crops, saves the PNG(s) and returns where each piece goes.
## A SORTED layer is split into its separate shapes, since each sorts against Pip by its own bottom edge.
func _place_layer(layer: Dictionary, work: String, screen: String, dir_res: String, doc_w: int, doc_h: int, scaled: bool, painting: Image) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var w := int(layer.w)
	var h := int(layer.h)
	var f := FileAccess.open(work.path_join(layer.file), FileAccess.READ)
	if f == null:
		printerr("Missing pixel file ", layer.file)
		return out
	var bytes := f.get_buffer(w * h * 4)
	if bytes.size() != w * h * 4:
		printerr("Pixel file ", layer.file, " is the wrong size")
		return out
	var img := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes)
	var origin := Vector2i(int(layer.x), int(layer.y))
	if scaled:
		var canvas := Image.create_empty(doc_w, doc_h, false, Image.FORMAT_RGBA8)
		canvas.blit_rect(img, Rect2i(0, 0, w, h), origin)
		canvas.resize(GAME_W, GAME_H, Image.INTERPOLATE_BILINEAR)
		var used := canvas.get_used_rect()
		for y in range(used.position.y, used.end.y):
			for x in range(used.position.x, used.end.x):
				var a := clampf((canvas.get_pixel(x, y).a - 0.5) * 3.0 + 0.5, 0.0, 1.0)
				var c := painting.get_pixel(x, y)
				c.a = a
				canvas.set_pixel(x, y, c)
		img = canvas
		origin = Vector2i.ZERO
	var rect := img.get_used_rect()
	if rect.size == Vector2i.ZERO:
		return out
	var crop := img.get_region(rect)
	var role := String(layer.role)
	var pieces: Array[Dictionary] = [{"img": crop, "at": Vector2i.ZERO}]
	if role == "SORTED":
		pieces = _split_shapes(crop)
	for k in pieces.size():
		var piece: Dictionary = pieces[k]
		var pimg: Image = piece.img
		var game_rect := Rect2i(origin + rect.position + Vector2i(piece.at), pimg.get_size())
		var name := String(layer.name) + ("" if pieces.size() == 1 else "_%d" % (k + 1))
		pimg.save_png(ProjectSettings.globalize_path("%s%s_occ_%s.png" % [dir_res, screen, name]))
		var base := game_rect.end.y
		if layer.get("base") != null:
			base = int(layer.base)
		out.append({"name": name, "role": role, "rect": game_rect, "base": base, "file": "%s_occ_%s.png" % [screen, name]})
	return out


## Splits a layer into its separate shapes (8-connected, any alpha), each cropped to itself.
## Specks under MIN_PIECE pixels are dropped and reported.
const MIN_PIECE := 64
func _split_shapes(img: Image) -> Array[Dictionary]:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()  # RGBA8
	var lab := PackedInt32Array()
	lab.resize(w * h)
	var pieces: Array[Dictionary] = []
	var dropped := 0
	var stack := PackedInt32Array()
	var n := 0
	for start in w * h:
		if lab[start] != 0 or data[start * 4 + 3] == 0:
			continue
		n += 1
		lab[start] = n
		stack.append(start)
		var members := PackedInt32Array()
		var x0 := w
		var y0 := h
		var x1 := -1
		var y1 := -1
		while not stack.is_empty():
			var i := stack[stack.size() - 1]
			stack.remove_at(stack.size() - 1)
			members.append(i)
			var x := i % w
			var y := i / w
			x0 = mini(x0, x); x1 = maxi(x1, x); y0 = mini(y0, y); y1 = maxi(y1, y)
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nx := x + dx
					var ny := y + dy
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue
					var j := ny * w + nx
					if lab[j] == 0 and data[j * 4 + 3] != 0:
						lab[j] = n
						stack.append(j)
		if members.size() < MIN_PIECE:
			dropped += 1
			continue
		var piece := Image.create_empty(x1 - x0 + 1, y1 - y0 + 1, false, Image.FORMAT_RGBA8)
		for i in members:
			piece.set_pixel(i % w - x0, i / w - y0, img.get_pixel(i % w, i / w))
		pieces.append({"img": piece, "at": Vector2i(x0, y0)})
	if dropped > 0:
		print("Dropped %d speck(s) under %d pixels." % [dropped, MIN_PIECE])
	if pieces.is_empty():
		pieces.append({"img": img, "at": Vector2i.ZERO})
	return pieces


## Deletes occluder PNGs from earlier runs that aren't in this run.
func _remove_stale(dir_res: String, screen: String, placed: Array[Dictionary]) -> void:
	var keep := {}
	for p: Dictionary in placed:
		keep[p.file] = true
		keep[p.file + ".import"] = true
	var dir := DirAccess.open(dir_res)
	if dir == null:
		return
	for file in dir.get_files():
		if file.begins_with("%s_occ_" % screen) and not keep.has(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(dir_res + file))
			print("Removed old ", file)


## Replaces every Occ_ sprite (and its texture line) in the scene with the new set.
func _write_scene(scene_path: String, text: String, dir_res: String, placed: Array[Dictionary]) -> void:
	var lines := text.split("\n")
	var kept := PackedStringArray()
	var i := 0
	while i < lines.size():
		var ln := lines[i]
		if ln.begins_with("[node name=\"Occ_"):
			i += 1
			while i < lines.size() and not lines[i].begins_with("["):
				i += 1
			continue
		if ln.begins_with("[ext_resource") and " id=\"occ_" in ln:
			i += 1
			continue
		kept.append(ln)
		i += 1

	var ext_lines := PackedStringArray()
	if not placed.is_empty():
		ext_lines.append("[ext_resource type=\"Script\" path=\"res://scripts/occluder.gd\" id=\"occ_script\"]")
	var world_lines := PackedStringArray()
	var over_lines := PackedStringArray()
	for p: Dictionary in placed:
		ext_lines.append("[ext_resource type=\"Texture2D\" path=\"%s%s\" id=\"occ_%s\"]" % [dir_res, p.file, p.name])
		var rect: Rect2i = p.rect
		var node := PackedStringArray()
		if p.role == "OVERHEAD" or p.role == "SORTED":
			node.append("[node name=\"Occ_%s\" type=\"Sprite2D\" parent=\"Overhead\"]" % p.name)
			node.append("position = Vector2(%d, %d)" % [rect.position.x, rect.position.y])
			node.append("texture = ExtResource(\"occ_%s\")" % p.name)
			node.append("centered = false")
			node.append("script = ExtResource(\"occ_script\")")
			node.append("sort = %s" % ("true" if p.role == "SORTED" else "false"))
			node.append("")
			over_lines.append_array(node)
		else:
			var pos := Vector2i(rect.position.x + rect.size.x / 2, int(p.base))
			node.append("[node name=\"Occ_%s\" type=\"Sprite2D\" parent=\"World\"]" % p.name)
			node.append("position = Vector2(%d, %d)" % [pos.x, pos.y])
			node.append("texture = ExtResource(\"occ_%s\")" % p.name)
			node.append("centered = false")
			node.append("offset = Vector2(%d, %d)" % [rect.position.x - pos.x, rect.position.y - pos.y])
			node.append("")
			world_lines.append_array(node)

	var overhead_at := -1
	var last_ext := -1
	for j in kept.size():
		if kept[j].begins_with("[node name=\"Overhead\""):
			overhead_at = j
		if kept[j].begins_with("[ext_resource"):
			last_ext = j
	if overhead_at < 0 or last_ext < 0:
		printerr("The scene has no Overhead node or no resources; not editing it.")
		return
	# Bottom-up, so earlier line numbers stay valid.
	# Every send, even an empty one ("this screen needs none"), stamps the Overhead node as layered.
	# tools/layering_status.sh lists the screens that don't have the stamp yet.
	var after := overhead_at
	var stamped := false
	while after + 1 < kept.size() and kept[after + 1] != "" and not kept[after + 1].begins_with("["):
		after += 1
		if kept[after].begins_with("metadata/layered"):
			stamped = true
	if not stamped:
		kept.insert(after + 1, "metadata/layered = true")
		after += 1
	after += 1  # the blank line that ends the Overhead node
	if after >= kept.size() or kept[after] != "":
		kept.insert(after, "")
	var tail := kept.slice(after + 1)
	var head := kept.slice(0, after + 1)
	head.append_array(over_lines)
	head.append_array(tail)
	kept = head
	var with_world := kept.slice(0, overhead_at)
	with_world.append_array(world_lines)
	with_world.append_array(kept.slice(overhead_at))
	kept = with_world
	var with_ext := kept.slice(0, last_ext + 1)
	with_ext.append_array(ext_lines)
	with_ext.append_array(kept.slice(last_ext + 1))
	var out := "\n".join(with_ext)
	var f := FileAccess.open(scene_path, FileAccess.WRITE)
	f.store_string(out)
	f.close()


func _load_painting(scene_text: String) -> Image:
	var re := RegEx.create_from_string("path=\"(res://assets/screens/[^\"]+_bg\\.(?:jpg|png))\"")
	var m := re.search(scene_text)
	if m == null:
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(m.get_string(1)))
	if img != null:
		img.convert(Image.FORMAT_RGBA8)
	return img
