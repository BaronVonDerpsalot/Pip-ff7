class_name Pip
extends Node2D
## Pip on a painted screen. His position is where his feet touch the ground.
## Size comes from the screen's depth numbers; movement stays inside its walk area.

## Pip's height in a sprite frame, in pixels (frames are 320x320, feet at y=277).
const FRAME_HEIGHT := 245.0
## Directions with rendered sheets. The left-hand ones are these, mirrored.
const SECTORS := ["right", "downright", "down", "downright", "right", "upright", "up", "upright"]

## Walking speed, in Pip-heights per second, so he covers ground at the same pace near and far.
@export var speed := 1.5
## Up and down the screen is foreshortened, so vertical movement is slowed by this much.
@export var vertical_factor := 0.6

var facing := "down"
var screen: Screen

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	screen = _find_screen()
	_apply_depth_scale()
	sprite.play("idle_down")


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var moving := input.length() > 0.1

	if moving:
		_face(input)
		var height := screen.height_at(position.y) if screen else FRAME_HEIGHT
		var step := Vector2(input.x, input.y * vertical_factor) * height * speed * delta
		_move(step)

	var anim := ("walk_" if moving else "idle_") + facing
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.speed_scale = clampf(input.length(), 0.5, 1.0) if moving else 1.0
	_apply_depth_scale()


func _draw() -> void:
	# Soft contact shadow under the feet, in sprite-frame pixels (the node is scaled).
	var points := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		points.append(Vector2(cos(a) * 64.0, sin(a) * 18.0))
	draw_colored_polygon(points, Color(0.1, 0.12, 0.15, 0.33))


func _face(input: Vector2) -> void:
	var sector := wrapi(roundi(input.angle() / (PI / 4.0)), 0, 8)
	facing = SECTORS[sector]
	# Sectors 2..5 run through the left side: down-left, left, up-left.
	sprite.flip_h = sector >= 3 and sector <= 5


func _move(step: Vector2) -> void:
	if screen == null:
		position += step
		return
	# Try the full step, then slide along the edge on one axis.
	for candidate in [position + step, position + Vector2(step.x, 0), position + Vector2(0, step.y)]:
		if screen.is_walkable(candidate):
			position = candidate
			return


func _apply_depth_scale() -> void:
	if screen == null:
		return
	var s := screen.height_at(position.y) / FRAME_HEIGHT
	scale = Vector2(s, s)


func _find_screen() -> Screen:
	var node := get_parent()
	while node:
		if node is Screen:
			return node
		node = node.get_parent()
	return null
