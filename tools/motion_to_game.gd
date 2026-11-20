class_name MotionToGame
## Puts a screen's shader motion (docs/recipes/screens-shader-motion.md) into its scene.
## Reads assets/screens/<screen>/motion/manifest.json, written by tools/segment/segment.py, and the images
## next to it (import them first: godot --headless --path . --import). Run with Ziva's execute_script:
##   MotionToGame.build("stream")            water and sway
##   MotionToGame.build("stream", false)     water only, on the painting itself (no plate, no sway pieces)
## It edits the .tscn as text (loading and re-saving a screen headless drops its script and uids) and adds,
## right after Background:
##   Loop/SubViewport/Plate     the clean plate, rippling where the water mask is white
##   Loop/SubViewport/Sway_<k>  each cut-out piece, swaying from its bottom edge
## Running it again replaces everything it added (ids and nodes starting "motion_" / under Loop) and touches
## nothing else. Tuning made by hand on those nodes is lost.


static func build(screen: String, include_sway: bool = true) -> String:
	var dir := "res://assets/screens/%s/motion/" % screen
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "manifest.json"))
	var scene_path := "res://scenes/screens/%s.tscn" % screen
	var blocks := _blocks(FileAccess.get_file_as_string(scene_path))

	# Drop whatever an earlier run added.
	var kept: Array[String] = []
	for b in blocks:
		if "id=\"motion_" in b.get_slice("\n", 0) or b.begins_with("[node name=\"Loop\" ") or "parent=\"Loop" in b.get_slice("\n", 0):
			continue
		kept.append(b)

	var ext: Array[String] = []
	var sub: Array[String] = []
	var nodes: Array[String] = []
	ext.append('[ext_resource type="Script" path="res://scripts/screen_motion.gd" id="motion_script"]')
	ext.append('[ext_resource type="Shader" path="res://scripts/motion_water.gdshader" id="motion_water"]')
	ext.append('[ext_resource type="Shader" path="res://scripts/motion_sway.gdshader" id="motion_sway"]')

	nodes.append('[node name="Loop" type="Node2D" parent="."]\nscript = ExtResource("motion_script")')
	nodes.append('[node name="SubViewport" type="SubViewport" parent="Loop"]\nsize = Vector2i(1920, 1080)\nrender_target_update_mode = 4')

	var plate := "plate.png" if include_sway else ""
	var plate_ref := 'ExtResource("2_bg")'
	if plate != "":
		ext.append('[ext_resource type="Texture2D" path="%s" id="motion_plate"]' % (dir + plate))
		plate_ref = 'ExtResource("motion_plate")'
	var plate_node := '[node name="Plate" type="Sprite2D" parent="Loop/SubViewport"]\ntexture = %s\ncentered = false' % plate_ref
	# One flowing mask (river) and one still mask (puddles, ponds) at most; the shader treats them differently.
	var masks: Array = manifest.get("water_masks", [])
	if not masks.is_empty():
		var mat := '[sub_resource type="ShaderMaterial" id="motion_water_mat"]\nshader = ExtResource("motion_water")'
		for w: Dictionary in masks:
			var key := "river" if w.flow else "pond"
			ext.append('[ext_resource type="Texture2D" path="%s" id="motion_%s_mask"]' % [dir + str(w.file), key])
			mat += '\nshader_parameter/%s_mask = ExtResource("motion_%s_mask")' % [key, key]
			if w.flow and w.has("flow_map"):
				ext.append('[ext_resource type="Texture2D" path="%s" id="motion_river_flow"]' % (dir + str(w.flow_map)))
				mat += '\nshader_parameter/river_flow_map = ExtResource("motion_river_flow")\nshader_parameter/has_flow_map = true'
		sub.append(mat)
		plate_node += '\nmaterial = SubResource("motion_water_mat")'
	nodes.append(plate_node)

	var n := 0
	if include_sway:
		for p: Dictionary in manifest.get("pieces", []):
			n += 1
			var r: Array = p.rect
			ext.append('[ext_resource type="Texture2D" path="%s" id="motion_sway_%d"]' % [dir + str(p.file), n])
			# Taller pieces move further at the tip (up to 14 px; the pieces are padded 28 px for it);
			# each gets its own phase so neighbours don't move in step.
			# Speeds spread 0.16-0.28 cycles a second, so no two clumps keep the same tempo.
			var tempo := 0.16 + fposmod(n * 0.37, 1.0) * 0.12
			sub.append('[sub_resource type="ShaderMaterial" id="motion_sway_mat_%d"]\nshader = ExtResource("motion_sway")\nshader_parameter/amp = %.1f\nshader_parameter/phase = %.1f\nshader_parameter/speed = %.2f' % [n, clampf(float(r[3]) / 60.0, 4.0, 14.0), n * 1.7, tempo])
			nodes.append('[node name="Sway_%d" type="Sprite2D" parent="Loop/SubViewport"]\nmaterial = SubResource("motion_sway_mat_%d")\nposition = Vector2(%d, %d)\ntexture = ExtResource("motion_sway_%d")\ncentered = false' % [n, n, r[0], r[1], n])

	# Reassemble: header, ext_resources, sub_resources, then nodes with Loop right after Background.
	var out: Array[String] = [kept[0]]
	var last_ext := 0
	var last_sub := 0
	for i in range(1, kept.size()):
		if kept[i].begins_with("[ext_resource"):
			last_ext = i
		elif kept[i].begins_with("[sub_resource"):
			last_sub = i
	for i in range(1, kept.size()):
		out.append(kept[i])
		if i == last_ext:
			out.append_array(ext)
			if last_sub == 0:
				out.append_array(sub)
		if i == last_sub:
			out.append_array(sub)
		if kept[i].begins_with('[node name="Background"'):
			out.append_array(nodes)
	var f := FileAccess.open(scene_path, FileAccess.WRITE)
	f.store_string(("\n\n".join(out) + "\n").replace("]\n\n[ext_resource", "]\n[ext_resource"))
	f.close()
	return "Loop built for %s: %s, %d sway pieces, %d water mask(s)" % [screen, plate if plate != "" else "painting", n, masks.size()]


## A .tscn split into its bracketed sections, each with its property lines.
static func _blocks(text: String) -> Array[String]:
	var blocks: Array[String] = []
	var cur := ""
	for line in text.split("\n"):
		if line.begins_with("[") and cur.strip_edges() != "":
			blocks.append(cur.strip_edges())
			cur = ""
		cur += line + "\n"
	if cur.strip_edges() != "":
		blocks.append(cur.strip_edges())
	return blocks
