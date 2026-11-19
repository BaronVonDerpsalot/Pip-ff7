extends VideoStreamPlayer

## The screen's looping video, standing in for the Background: the painting, with only the moving parts
## animated (made as in screens-flow.md, "An animated screen").
## Whatever covers Pip is drawn by the screen's Occ_ sprites (scripts/occluder.gd), which take this video's
## pixels through their own shapes, so they move with it.

@export var clip: VideoStream


func _ready() -> void:
	expand = true
	loop = true
	position = Vector2.ZERO
	size = Vector2(1920, 1080)

	var bg: CanvasItem = get_parent().get_node_or_null("Background")
	if bg != null:
		bg.visible = false

	stream = clip
	play()
