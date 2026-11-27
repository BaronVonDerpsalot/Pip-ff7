extends Sprite2D
## Hides Pip behind whatever is nearer than the ground at his feet, read from the screen's depth map
## (tools/depth/depth.py), with no shapes drawn by hand. Put it under Overhead, above Pip.
## On a shader-motion screen the swaying pieces carry their depth with them: a hidden SubViewport redraws
## the depth map with the same sway as the Loop, and that is what the shader reads.

## Leave empty to use the screen's depth_map.
@export var depth_map: Texture2D
## How much nearer than his feet (0..1 of the screen's depth range) something must be to cover him.
@export_range(0.0, 0.2, 0.001) var tolerance := 0.01
@export_range(0.0, 0.1, 0.001) var soft := 0.01
## Pixels past its edge that whatever covers him also covers (the depth map's edges are soft and run small).
@export_range(0.0, 8.0, 0.5) var grow := 3.0
## Debug: tint what covers him red.
@export var show_mask := false
## Who it hides, from the screen: Pip by default. A villager gets an occluder of his own.
@export var target := NodePath("World/Pip")
## The target's frame: half its width, and how far its feet sit below its top, in frame pixels.
## Pip's frames are 320 wide with his feet 277 px down; the mole's are 400 wide with his feet 345 px down.
@export var frame_half_width := 160.0
@export var frame_above_feet := 277.0

var _pip: Node2D
var _screen: Screen
var _depth: Image  # the depth map on the CPU, to read the ground at Pip's feet
var _loop: Node
var _mat: ShaderMaterial
## Gaps in what Pip walks on (the screen's Gaps node: Polygon2D shapes in screen space), such as a missing
## plank he can step over. The ground is never read inside them: it's filled in from the walk surface
## behind and in front.
var _gaps: Array[PackedVector2Array] = []


func _ready() -> void:
	var screen: Node = owner if owner != null else get_parent().get_parent()
	_pip = screen.get_node_or_null(target) as Node2D
	_screen = screen as Screen
	if depth_map == null and _screen != null:
		depth_map = _screen.depth_map  # the screen's own depth map, unless this node is given another
	_depth = depth_map.get_image()
	if _depth.is_compressed():
		_depth.decompress()
	_loop = screen.get_node_or_null("Loop")
	var gaps := screen.get_node_or_null("Gaps")
	if gaps != null:
		gaps.visible = false
		for g in gaps.get_children():
			if g is Polygon2D:
				_gaps.append((g as Polygon2D).global_transform * (g as Polygon2D).polygon)
	var bg :=screen.get_node_or_null("Background") as Sprite2D
	if texture == null and bg != null:
		texture = bg.texture
	centered = false
	global_position = Vector2.ZERO
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://scripts/depth_occluder.gdshader")
	_mat.set_shader_parameter("depth_tex", _moving_depth())
	_mat.set_shader_parameter("tolerance", tolerance)
	_mat.set_shader_parameter("soft", soft)
	_mat.set_shader_parameter("grow", grow)
	_mat.set_shader_parameter("show_mask", show_mask)
	if _screen != null:
		_mat.set_shader_parameter("SCREEN", _screen.painting_size())
	material = _mat


## The depth map, or, on a screen with swaying pieces, a viewport that sways it the same way.
func _moving_depth() -> Texture2D:
	var pieces: Array[Sprite2D] = []
	var src := _loop.get_node_or_null("SubViewport") if _loop != null else null
	if src != null:
		for child in src.get_children():
			if child is Sprite2D and child.name.begins_with("Sway") and child.material is ShaderMaterial:
				pieces.append(child)
	if pieces.is_empty():
		return depth_map
	var vp := SubViewport.new()
	vp.size = Vector2i(depth_map.get_size())
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(vp)
	var base := Sprite2D.new()
	base.texture = depth_map
	base.centered = false
	vp.add_child(base)
	for piece in pieces:
		var copy := Sprite2D.new()
		copy.texture = piece.texture
		copy.centered = false
		copy.position = piece.position
		var m := (piece.material as ShaderMaterial).duplicate() as ShaderMaterial
		m.set_shader_parameter("depth_mode", true)
		m.set_shader_parameter("depth_map", depth_map)
		m.set_shader_parameter("piece_pos", piece.position)
		copy.material = m
		vp.add_child(copy)
	return vp.get_texture()


func _process(_delta: float) -> void:
	if _pip == null:
		return
	if _loop != null and not _mat.get_shader_parameter("has_colour"):
		var t: Texture2D = _loop.call("get_video_texture")
		if t != null:
			_mat.set_shader_parameter("colour_tex", t)
			_mat.set_shader_parameter("has_colour", true)
	var feet := _pip.global_position
	var s := _pip.global_scale.x
	_mat.set_shader_parameter("feet", feet)
	_mat.set_shader_parameter("ground", _ground_at(feet, s))
	_mat.set_shader_parameter("pip_rect", Vector4(feet.x - frame_half_width * s, feet.y - frame_above_feet * s,
			feet.x + frame_half_width * s, feet.y))


## Nearness of the ground at Pip's feet: the middle value of points along his feet, counting only points in
## the walk area, so a post or reed he stands behind (outside it) is never taken for the ground he's on.
## Ground gets nearer row by row toward the camera, so a row farther than the walk area just behind him,
## with nearer ground in front, is a gap seen through (water between planks): the ground is lifted to the
## nearest row behind him. On ordinary ground this changes nothing.
## If every point at his feet is in a marked gap (Gaps node), the ground is blended from the nearest rows of
## walk surface behind and in front, by how far he is between them.
func _ground_at(feet: Vector2, s: float) -> float:
	var g := _row_at(feet.x, feet.y + 2.0, s)
	var behind := -1.0
	var ahead := -1.0
	var first_behind := NAN
	var first_ahead := NAN
	var d_behind := 0.0
	var d_ahead := 0.0
	var dy := 4.0
	while dy < GAP_REACH * s:
		var b := _row_at(feet.x, feet.y + 2.0 - dy, s)
		var a := _row_at(feet.x, feet.y + 2.0 + dy, s)
		if not is_nan(b):
			behind = maxf(behind, b)
			if is_nan(first_behind):
				first_behind = b
				d_behind = dy
		if not is_nan(a):
			ahead = maxf(ahead, a)
			if is_nan(first_ahead):
				first_ahead = a
				d_ahead = dy
		dy += 4.0
	if is_nan(g):
		if not is_nan(first_behind) and not is_nan(first_ahead):
			return lerpf(first_behind, first_ahead, d_behind / (d_behind + d_ahead))
		return _nearness(feet)
	if behind >= 0.0 and ahead >= 0.0:
		g = maxf(g, minf(behind, ahead))
	return g


## How far (frame pixels) behind and in front of Pip's feet the gap check looks.
const GAP_REACH := 80.0


## The middle nearness of walk-area points (outside any gap) along a row through Pip's feet, or NAN if none.
func _row_at(x: float, y: float, s: float) -> float:
	var values: Array[float] = []
	for k in range(-7, 8):
		var p := Vector2(x + k * 10.0 * s, y)
		if (_screen == null or _screen.is_walkable(p)) and not _in_gap(p):
			values.append(_nearness(p))
	if values.is_empty():
		return NAN
	values.sort()
	return values[values.size() >> 1]


func _in_gap(p: Vector2) -> bool:
	for poly in _gaps:
		if Geometry2D.is_point_in_polygon(p, poly):
			return true
	return false


func _nearness(p: Vector2) -> float:
	var x := clampi(int(p.x), 0, _depth.get_width() - 1)
	var y := clampi(int(p.y), 0, _depth.get_height() - 1)
	var c := _depth.get_pixel(x, y)
	return (roundf(c.r * 255.0) * 256.0 + roundf(c.g * 255.0)) / 65535.0
