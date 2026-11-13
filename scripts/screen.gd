class_name Screen
extends Node2D
## One painted screen: a flat backdrop, foreground cut-outs, a walk area,
## and two numbers for how tall Pip is far away and close up.

## Screen y (Pip's feet) at the far end of the walk area, and Pip's height there in pixels.
@export var far_y := 215.0
@export var far_height := 72.0
## Screen y at the near end, and Pip's height there.
@export var near_y := 1075.0
@export var near_height := 253.0

@onready var walk_area: Polygon2D = $WalkArea


func _ready() -> void:
	# The walk area shows in the editor for drawing, but not in the game (F toggles it).
	walk_area.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_walk_area"):
		walk_area.visible = not walk_area.visible


## Pip's on-screen height in pixels when his feet are at screen y.
func height_at(y: float) -> float:
	var t := inverse_lerp(far_y, near_y, y)
	return lerpf(far_height, near_height, t)


func is_walkable(point: Vector2) -> bool:
	var local := walk_area.to_local(to_global(point))
	return Geometry2D.is_point_in_polygon(local, walk_area.polygon)
