extends AnimatedSprite2D
## Pip's shadow: his current frame, flattened and sheared along the ground from his feet, so it walks and
## turns with him. The screen sets where it falls (Screen.shadow_dir) and gives the depth map it bends over.
## Drawn under his sprite (it's the first child of Pip) and multiplied over the painting
## (scripts/pip_shadow.gdshader).

@onready var _sprite: AnimatedSprite2D = get_parent().get_node("Sprite")
var _mat: ShaderMaterial
var _screen: Screen
var _ready_done := false


func _ready() -> void:
	sprite_frames = _sprite.sprite_frames
	offset = _sprite.offset
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://scripts/pip_shadow.gdshader")
	material = _mat


## Pip (or a villager) finds his screen in his own _ready, after this one's; so the screen's settings are read on first use.
func _setup() -> void:
	_ready_done = true
	# Pip, or a villager: anything with a `screen`.
	_screen = get_parent().get("screen") as Screen
	if _screen == null:
		return
	_mat.set_shader_parameter("strength", _screen.shadow_strength)
	_mat.set_shader_parameter("SCREEN", _screen.painting_size())
	# No shadow on water: borrow the shader-motion water masks, if the screen has them.
	var plate := _screen.get_node_or_null("Loop/SubViewport/Plate") as CanvasItem
	if plate != null and plate.material is ShaderMaterial:
		for mask: String in ["river_mask", "pond_mask"]:
			var tex: Variant = (plate.material as ShaderMaterial).get_shader_parameter(mask)
			if tex is Texture2D:
				_mat.set_shader_parameter(mask, tex)
	if _screen.depth_map != null:
		_mat.set_shader_parameter("depth_tex", _screen.depth_map)
		_mat.set_shader_parameter("has_depth", true)


func _process(_delta: float) -> void:
	if not _ready_done:
		_setup()
	if animation != _sprite.animation:
		animation = _sprite.animation
	frame = _sprite.frame
	flip_h = _sprite.flip_h
	var dir := _screen.shadow_dir if _screen else Vector2(0.3, 0.3)
	# Pip's up (local -y) maps to dir: his head's shadow lands dir x his height from his feet.
	transform = Transform2D(Vector2(1, 0), -dir, Vector2.ZERO)
	var tex := sprite_frames.get_frame_texture(animation, frame)
	if tex is AtlasTexture:
		var at := tex as AtlasTexture
		var size := Vector2(at.atlas.get_size())
		_mat.set_shader_parameter("region", Vector4(at.region.position.x / size.x, at.region.position.y / size.y,
				at.region.end.x / size.x, at.region.end.y / size.y))
	var s := (get_parent() as Node2D).global_scale.y
	_mat.set_shader_parameter("tex_px_per_screen_px", 1.0 / maxf(s * absf(dir.y), 0.02))
	_mat.set_shader_parameter("tex_px_per_screen_px_x", 1.0 / maxf(s, 0.02))
