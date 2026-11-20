extends Node
## Pip's reflection in water, and the rings he makes stepping into it. Lives under Pip; on a screen with
## shader motion it puts a flipped copy of his frame inside the Loop's viewport, just above the clean plate,
## so it ripples with the water (scripts/pip_reflection.gdshader) and the reeds and hide-Pip shapes stay in
## front of it. A screen without a shader-motion Loop gets neither.

## Seconds between rings while he keeps walking in water (a ring also starts the moment he steps in).
@export var ring_every := 0.55
@export_range(0.0, 1.0) var ring_strength := 1.0

const RINGS := 4

var _pip: Pip
var _sprite: AnimatedSprite2D
var _copy: AnimatedSprite2D
var _mat: ShaderMaterial
var _water_mat: ShaderMaterial
var _masks: Array[Image] = []
var _rings: Array[Vector4] = []
var _next := 0
var _was_wet := false
var _since_ring := 0.0
var _setup_done := false


func _process(delta: float) -> void:
	if not _setup_done:
		_setup()
	if _copy == null:
		return
	if _copy.animation != _sprite.animation:
		_copy.animation = _sprite.animation
	_copy.frame = _sprite.frame
	_copy.flip_h = _sprite.flip_h
	var feet := _pip.global_position
	var s := _pip.global_scale.x
	_copy.position = feet
	_copy.scale = Vector2(s, -s)
	var tex := _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	if tex is AtlasTexture:
		var at := tex as AtlasTexture
		var size := Vector2(at.atlas.get_size())
		_mat.set_shader_parameter("region", Vector4(at.region.position.x / size.x, at.region.position.y / size.y,
				at.region.end.x / size.x, at.region.end.y / size.y))
	_mat.set_shader_parameter("feet", feet)
	_mat.set_shader_parameter("pip_height", _pip.screen.height_at(feet.y))
	_mat.set_shader_parameter("tex_px_per_screen_px", 1.0 / maxf(s, 0.02))
	_update_rings(delta, feet)


func _setup() -> void:
	_setup_done = true
	_pip = get_parent() as Pip
	_sprite = _pip.get_node("Sprite")
	if _pip.screen == null:
		return
	var plate := _pip.screen.get_node_or_null("Loop/SubViewport/Plate") as Sprite2D
	if plate == null or not (plate.material is ShaderMaterial):
		return
	_water_mat = plate.material as ShaderMaterial
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://scripts/pip_reflection.gdshader")
	# Ripple exactly as the water does: copy every setting the two shaders share.
	for u: Dictionary in _water_mat.shader.get_shader_uniform_list():
		var value: Variant = _water_mat.get_shader_parameter(u.name)
		if value != null:
			_mat.set_shader_parameter(u.name, value)
	_mat.set_shader_parameter("plate", plate.texture)
	for mask: String in ["river_mask", "pond_mask"]:
		var t: Variant = _water_mat.get_shader_parameter(mask)
		if t is Texture2D:
			var img := (t as Texture2D).get_image()
			if img.is_compressed():
				img.decompress()
			_masks.append(img)
	_copy = AnimatedSprite2D.new()
	_copy.name = "PipReflection"
	_copy.sprite_frames = _sprite.sprite_frames
	_copy.offset = _sprite.offset
	_copy.material = _mat
	plate.add_sibling(_copy)  # just above the plate, under the swaying reeds
	for i in RINGS:
		_rings.append(Vector4(0, 0, 0, 0))


## How much water is at a screen point (0..1), from the water masks.
func _water_at(p: Vector2) -> float:
	var w := 0.0
	for img in _masks:
		var x := clampi(int(p.x * img.get_width() / 1920.0), 0, img.get_width() - 1)
		var y := clampi(int(p.y * img.get_height() / 1080.0), 0, img.get_height() - 1)
		w = maxf(w, img.get_pixel(x, y).r)
	return w


## A ring when he steps into water, then one every ring_every seconds while he walks in it.
func _update_rings(delta: float, feet: Vector2) -> void:
	for i in RINGS:
		_rings[i].z += delta
	var wet := _water_at(feet) > 0.5
	var moving := _pip.gait != "idle"
	_since_ring += delta
	if wet and (not _was_wet or (moving and _since_ring >= ring_every)):
		_rings[_next] = Vector4(feet.x, feet.y, 0.0, ring_strength)
		_next = (_next + 1) % RINGS
		_since_ring = 0.0
	_was_wet = wet
	var packed := PackedVector4Array(_rings)
	_water_mat.set_shader_parameter("step_rings", packed)
	_mat.set_shader_parameter("step_rings", packed)
