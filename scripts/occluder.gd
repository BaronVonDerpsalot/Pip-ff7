extends Sprite2D

## One piece of a layer sent from Affinity (tools/layers_to_game.gd puts these under Overhead as Occ_ sprites).
## sort = true: it covers Pip only while his feet are above its bottom edge at his x, so he goes behind it
## from above and in front of it from below. Its edge is read from its own pixels; nothing is set by hand.
## It draws only inside Pip's frame, so a big shape switched on by Pip doesn't cover the mole beside it.
## sort = false (layers named "Over..."): it always covers him, for things that hang, like willow fronds.
## On a screen with a Loop node (video or shader motion) it draws the Loop's pixels through its own shape, so it moves with it;
## on a still screen it draws its own pixels, cut from the painting.

@export var sort := true
## Screen points of the line this shape stands behind, for bank shapes from tools/depth/auto_occ.py: with it,
## the shape covers Pip only while his feet are above this line at his x, not above its own lowest pixels.
@export var edge := PackedVector2Array()

## Pixels below its `edge` line that still count as behind it. The edge is the walk area's own edge, so Pip
## sliding along it has his feet within a pixel of the line; without this the shape flickered on and off.
const EDGE_MARGIN := 6

var _x0 := 0
var _bottom := PackedInt32Array()  # bottom edge (screen y) per column, from _x0
var _pip: Node2D = null
var _loop: Node = null  # a VideoStreamPlayer (screen_loop.gd) or a shader-motion screen (screen_motion.gd)
var _mat: ShaderMaterial = null


func _ready() -> void:
	var screen: Node = owner if owner != null else get_parent().get_parent()
	_pip = screen.get_node_or_null("World/Pip") as Node2D
	_loop = screen.get_node_or_null("Loop")
	if sort and edge.size() >= 2:
		_bottom_from_edge()
	elif sort:
		_read_bottom_edge()
	if _loop != null or sort:
		_mat = ShaderMaterial.new()
		_mat.shader = preload("res://scripts/occluder_video.gdshader")
		var size := Vector2(texture.get_width(), texture.get_height())
		_mat.set_shader_parameter("rect", Vector4(global_position.x, global_position.y, size.x, size.y))
		_mat.set_shader_parameter("clip_to_pip", sort)
		if screen is Screen:
			_mat.set_shader_parameter("SCREEN", (screen as Screen).painting_size())
		material = _mat


## The bottom edge per column from the `edge` line, held level past its ends.
func _bottom_from_edge() -> void:
	var a := edge[0]
	var b := edge[edge.size() - 1]
	if a.x > b.x:
		var t := a
		a = b
		b = t
	_x0 = int(global_position.x)
	_bottom.resize(texture.get_width())
	for i in _bottom.size():
		var x := float(_x0 + i)
		var f := clampf((x - a.x) / maxf(b.x - a.x, 1.0), 0.0, 1.0)
		_bottom[i] = ceili(lerpf(a.y, b.y, f)) + EDGE_MARGIN


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
	if _mat != null and _loop != null and not _mat.get_shader_parameter("has_video"):
		var t: Texture2D = _loop.call("get_video_texture")
		if t != null:
			_mat.set_shader_parameter("video", t)
			_mat.set_shader_parameter("has_video", true)
	if sort and _pip != null and not _bottom.is_empty():
		var i := clampi(int(_pip.global_position.x) - _x0, 0, _bottom.size() - 1)
		visible = _pip.global_position.y < _bottom[i]
		if visible and _mat != null:
			# Pip's frame (320 wide, feet 277 px down), so the shape covers only him, not the mole beside him.
			var feet := _pip.global_position
			var s := _pip.global_scale.x
			_mat.set_shader_parameter("pip_rect", Vector4(feet.x - 160.0 * s, feet.y - 277.0 * s,
					feet.x + 160.0 * s, feet.y + 4.0 * s))
