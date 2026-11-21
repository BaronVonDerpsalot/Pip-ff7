class_name Villager
extends Node2D
## A villager standing on a painted screen (the mole, for now). His position is where his feet touch the ground.
## Sized by the screen's depth numbers like Pip, lit by the same light map, and given Pip's shadow and
## reflection (the Shadow and Reflection children reuse Pip's scripts). He idles, turning to face Pip, and
## when Pip is close and presses `talk`, plays his conversation from res://lines/slice.txt (DialogueBox).
## Hiding him behind reeds and posts is a DepthOcc under the screen's Overhead with `target` set to him.

## His height in a sprite frame, in pixels. The mole is 1.25x Pip (Pip's FRAME_HEIGHT 245 x 1.25).
@export var frame_height := 306.0
## His height compared with Pip's, so the screen's Pip heights size him.
@export var height_factor := 1.25
@export_range(0.0, 1.0) var light_strength := 0.5
@export_range(0.0, 1.0) var light_spread := 0.35
## Degrees past a direction's edge Pip has to move before the villager turns, so he doesn't flicker between two.
@export var turn_margin := 10.0
## The conversation (in res://lines/slice.txt) that plays when Pip talks to him.
@export var conversation := "mole_hypnotised"
## How close Pip's feet must be to talk, in Pip-heights along the ground.
@export var talk_range := 1.1
## How close Pip can walk to him, in Pip-heights along the ground: he stands in Pip's way.
@export var block_radius := 0.6

## Directions with rendered sheets; the left-hand ones are mirrored (as Pip's).
const SECTORS := ["right", "downright", "down", "downright", "right", "upright", "up", "upright"]

var facing := "down"
## Read by the shared reflection script; a standing villager makes no rings.
var gait := "idle"
var screen: Screen
var _sector := 2
var _pip: Node2D
var _box: DialogueBox

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group(&"villagers")
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("talk") and not event.is_echo() and _box == null and in_talk_range():
		get_viewport().set_input_as_handled()
		_talk()


## Whether a point (screen space) is too close to stand on: Screen.is_walkable asks every villager.
func blocks(point: Vector2) -> bool:
	if screen == null:
		return false
	var to := point - global_position
	var vf: Variant = _pip.get("vertical_factor") if _pip != null else null
	to.y /= vf if vf != null else 1.0
	return to.length() < block_radius * screen.height_at(global_position.y)


## Whether Pip is close enough to talk: ground distance between their feet, in Pip-heights.
func in_talk_range() -> bool:
	if _pip == null or screen == null or ScreenChanger.busy:
		return false
	var to := _pip.global_position - global_position
	var vf: Variant = _pip.get("vertical_factor")
	to.y /= vf if vf != null else 1.0
	return to.length() <= talk_range * screen.height_at(global_position.y)


func _talk() -> void:
	# In the lower half of the screen the box would cover him and Pip, so it goes along the top.
	_box = DialogueBox.open(get_tree(), conversation, global_position.y > 540.0)
	if _box == null:
		return
	_face_pip(true)
	_pip.set("talking", true)
	if _pip.has_method("face_point"):
		_pip.call("face_point", _pip.get_parent().to_local(global_position))
	await _box.finished
	_box = null
	_pip.set("talking", false)


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
