class_name Villager
extends Node2D
## A villager standing on a painted screen (the mole, for now). His position is where his feet touch the ground.
## Sized by the screen's depth numbers like Pip, lit by the same light map, and given Pip's shadow and
## reflection (the Shadow and Reflection children reuse Pip's scripts). He idles, turning to face Pip.
## Hiding him behind reeds and posts is a DepthOcc under the screen's Overhead with `target` set to him.

## His height in a sprite frame, in pixels. The mole is 1.25x Pip (Pip's FRAME_HEIGHT 245 x 1.25).
@export var frame_height := 306.0
## His height compared with Pip's, so the screen's Pip heights size him.
@export var height_factor := 1.25
@export_range(0.0, 1.0) var light_strength := 0.5
@export_range(0.0, 1.0) var light_spread := 0.35
## Degrees past a direction's edge Pip has to move before the villager turns, so he doesn't flicker between two.
@export var turn_margin := 10.0

## Directions with rendered sheets; the left-hand ones are mirrored (as Pip's).
const SECTORS := ["right", "downright", "down", "downright", "right", "upright", "up", "upright"]

var facing := "down"
## Read by the shared reflection script; a standing villager makes no rings.
var gait := "idle"
var screen: Screen
var _sector := 2
var _pip: Node2D

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	screen = _find_screen()
	if screen != null:
		_pip = screen.get_node_or_null("World/Pip") as Node2D
		var s := screen.height_at(position.y) * height_factor / frame_height
		scale = Vector2(s, s)
		var light := Pip.light_material(screen, light_strength, light_spread)
		if light != null:
			light.set_shader_parameter("feet", global_position)
			sprite.material = light
	_face_pip(true)


func _process(_delta: float) -> void:
	_face_pip(false)


## Turns toward Pip. Up and down the screen is foreshortened, so the screen offset is stretched back
## by Pip's vertical_factor before its angle is read.
func _face_pip(force: bool) -> void:
	if _pip == null:
		sprite.play("idle_" + facing)
		return
	var to := _pip.global_position - global_position
	var vf: Variant = _pip.get("vertical_factor")
	to.y /= vf if vf != null else 1.0
	if to.length() < 1.0:
		return
	var angle := to.angle() / (PI / 4.0)
	var sector := wrapi(roundi(angle), 0, 8)
	if not force and sector != _sector:
		# Keep the current direction until Pip is clearly into the next one.
		var off := absf(wrapf(angle - _sector, -4.0, 4.0))
		if off < 0.5 + turn_margin / 45.0:
			sector = _sector
	if force or sector != _sector:
		_sector = sector
		facing = SECTORS[sector]
		sprite.flip_h = sector >= 3 and sector <= 5
	var anim := "idle_" + facing
	if sprite.animation != anim:
		sprite.play(anim)


func _find_screen() -> Screen:
	var node := get_parent()
	while node:
		if node is Screen:
			return node
		node = node.get_parent()
	return null
