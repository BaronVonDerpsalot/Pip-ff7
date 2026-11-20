extends Node2D

## A still screen brought to life by shaders instead of a video (docs/recipes/screens-shader-motion.md).
## Its SubViewport holds the clean plate (water rippling through scripts/motion_water.gdshader) and the
## swaying cut-outs (scripts/motion_sway.gdshader); this node shows that viewport in place of the Background.
## Named "Loop" on the screen so the Occ_ sprites (scripts/occluder.gd) draw its pixels through their shapes,
## exactly as they do with a video loop.

@onready var _vp: SubViewport = $SubViewport


func _ready() -> void:
	position = Vector2.ZERO
	var bg: CanvasItem = get_parent().get_node_or_null("Background")
	if bg != null:
		bg.visible = false
	var view := Sprite2D.new()
	view.centered = false
	view.texture = _vp.get_texture()
	add_child(view)


## Same name as VideoStreamPlayer's, so occluders treat this like a video loop.
func get_video_texture() -> Texture2D:
	return _vp.get_texture()
