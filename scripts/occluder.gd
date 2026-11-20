extends Sprite2D

## One piece of a layer sent from Affinity (tools/layers_to_game.gd puts these under Overhead as Occ_ sprites).
## sort = true: it covers Pip only while his feet are above its bottom edge at his x, so he goes behind it
## from above and in front of it from below. Its edge is read from its own pixels; nothing is set by hand.
## sort = false (layers named "Over..."): it always covers him, for things that hang, like willow fronds.
## On a screen with a Loop node it draws the video's pixels through its own shape, so it moves with the loop;
## on a still screen it draws its own pixels, cut from the painting.

@export var sort := true

var _x0 := 0
var _bottom := PackedInt32Array()  # bottom edge (screen y) per column, from _x0
var _pip: Node2D = null
var _loop: Node = null  # a VideoStreamPlayer (screen_loop.gd) or a shader-motion screen (screen_motion.gd)
var _mat: ShaderMaterial = null


func _ready() -> void:
	var screen: Node = owner if owner != null else get_parent().get_parent()
	_pip = screen.get_node_or_null("World/Pip") as Node2D
	_loop = screen.get_node_or_null("Loop")
	if sort:
		_read_bottom_edge()
	if _loop != null:
		_mat = ShaderMaterial.new()
		_mat.shader = preload("res://scripts/occluder_video.gdshader")
		var size := Vector2(texture.get_width(), texture.get_height())
		_mat.set_shader_parameter("rect", Vector4(global_position.x, global_position.y, size.x, size.y))
		material = _mat


func _read_bottom_edge() -> void:
	var img := texture.get_image()
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	_x0 = int(global_position.x)
	_bottom.resize(w)
	var last := -1
	for x in w:
		var y := h - 1
		while y >= 0 and img.get_pixel(x, y).a < 0.5:
			y -= 1
		if y < 0:
			y = last  # an empty column takes the edge of the one before it
		_bottom[x] = y
		last = y
	# Empty columns at the left take the first edge found.
	var first := -1
	for x in w:
		if _bottom[x] >= 0:
			first = _bottom[x]
			break
	for x in w:
		if _bottom[x] < 0:
			_bottom[x] = first
		_bottom[x] += int(global_position.y)


func _process(_delta: float) -> void:
	if _mat != null and not _mat.get_shader_parameter("has_video"):
		var t: Texture2D = _loop.call("get_video_texture")
		if t != null:
			_mat.set_shader_parameter("video", t)
			_mat.set_shader_parameter("has_video", true)
	if sort and _pip != null and not _bottom.is_empty():
		var i := clampi(int(_pip.global_position.x) - _x0, 0, _bottom.size() - 1)
		visible = _pip.global_position.y < _bottom[i]
