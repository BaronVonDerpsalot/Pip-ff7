class_name Pip
extends Node2D
## Pip on a painted screen. His position is where his feet touch the ground.
## Size comes from the screen's depth numbers; movement stays inside its walk area.

## Pip's height in a sprite frame, in pixels (frames are 320x320; feet on pixel row 276,
## so the Sprite's offset of -117 puts this node's origin at y=277, just under them).
const FRAME_HEIGHT := 245.0
## Directions with rendered sheets. The left-hand ones are these, mirrored.
const SECTORS := ["right", "downright", "down", "downright", "right", "upright", "up", "upright"]

## Walking speed, in Pip-heights per second, so he covers ground at the same pace near and far.
@export var speed := 1.5
## Running speed (toggled with run_toggle: L3 or Shift). Running stops when Pip stands still.
@export var run_speed := 3.0
## Top creeping speed (a gentle push of the stick, or holding creep: C).
@export var creep_speed := 0.6
## A push on the stick below this creeps; above it walks.
@export var creep_below := 0.5
## Up and down the screen is foreshortened, so vertical movement is slowed by this much.
@export var vertical_factor := 0.6
## How far Pip takes on the screen's light where he stands (0 = never, 1 = fully).
@export_range(0.0, 1.0) var light_strength := 0.5
## How much that light changes from his feet to his head (0 = one tint for all of him).
@export_range(0.0, 1.0) var light_spread := 0.35

## The light map: the painting shrunk to this size, then blurred this many times.
const LIGHT_MAP_SIZE := Vector2i(32, 18)
const LIGHT_MAP_BLURS := 3
## Light-map pixels are kept within this range of the screen's average brightness, so
## a bright sky or black shadow never washes Pip out.
const LIGHT_MAP_MIN := 0.45
const LIGHT_MAP_MAX := 1.6

## How fast a stand-in walk loop plays for a gait that has no sheets of its own yet.
const PLACEHOLDER_ANIM_SPEED := {"run": 1.8, "creep": 0.55}
## Colour Pip flashes when he changes gait while it's played by a stand-in walk loop.
const PLACEHOLDER_FLASH := {"walk": Color(1.6, 1.6, 1.6), "run": Color(1.8, 1.25, 0.6), "creep": Color(0.6, 0.9, 1.7)}

var facing := "down"
## "idle", "creep", "walk" or "run".
var gait := "idle"
var running := false
var screen: Screen
var _flash: Tween
var _gait_is_placeholder := false
var _light: ShaderMaterial

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	screen = _find_screen()
	_apply_depth_scale()
	_setup_light()
	sprite.play("idle_down")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("run_toggle"):
		running = not running


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var push := minf(input.length(), 1.0)
	var moving := push > 0.1
	if not moving:
		running = false

	var new_gait := _gait_for(push, moving)
	if moving:
		_face(input)
		var height := screen.height_at(position.y) if screen else FRAME_HEIGHT
		var direction := input.normalized()
		var step := Vector2(direction.x, direction.y * vertical_factor) * height * _speed_for(new_gait, push) * delta
		_move(step)
	_set_gait(new_gait, push)
	_apply_depth_scale()
	if _light:
		_light.set_shader_parameter("feet", global_position)


func _gait_for(push: float, moving: bool) -> String:
	if not moving:
		return "idle"
	if running:
		return "run"
	if Input.is_action_pressed("creep") or push < creep_below:
		return "creep"
	return "walk"


## Pip-heights per second for a gait. Walking and creeping follow how far the stick is pushed.
func _speed_for(g: String, push: float) -> float:
	match g:
		"run":
			return run_speed
		"creep":
			if Input.is_action_pressed("creep"):
				return creep_speed
			return creep_speed * clampf(push / creep_below, 0.3, 1.0)
		"walk":
			return speed * push
	return 0.0


## Plays <gait>_<facing>. A gait without its own sheets yet (run, creep) plays the
## walk loop faster or slower instead, and Pip flashes a colour when he changes into it.
func _set_gait(new_gait: String, push: float) -> void:
	var kind := new_gait
	var placeholder := false
	if not sprite.sprite_frames.has_animation(kind + "_" + facing):
		kind = "walk"
		placeholder = true
	var anim := kind + "_" + facing
	if sprite.animation != anim:
		sprite.play(anim)

	if new_gait == "walk":
		sprite.speed_scale = clampf(push, 0.5, 1.0)
	elif placeholder:
		sprite.speed_scale = PLACEHOLDER_ANIM_SPEED.get(new_gait, 1.0)
	else:
		sprite.speed_scale = 1.0

	if new_gait != gait:
		# Flash into a stand-in gait, and back out of one into a walk.
		if new_gait != "idle" and (placeholder or _gait_is_placeholder):
			_flash_colour(PLACEHOLDER_FLASH.get(new_gait, Color.WHITE))
		gait = new_gait
		_gait_is_placeholder = placeholder


## Puts Pip at a point (in his parent's space), standing and facing a direction.
## Used when he arrives on a screen through an exit.
func arrive_at(point: Vector2, look: Vector2) -> void:
	position = point
	running = false
	_face(look)
	gait = "idle"
	sprite.play("idle_" + facing)
	_apply_depth_scale()
	if _light:
		_light.set_shader_parameter("feet", global_position)


func _flash_colour(colour: Color) -> void:
	if _flash:
		_flash.kill()
	sprite.modulate = colour
	_flash = create_tween()
	_flash.tween_property(sprite, "modulate", Color.WHITE, 0.3)


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


## Gives Pip's sprite the light shader, with a light map made from the screen's painting.
## Every screen gets one this way, with no per-screen step; Background stays loaded even
## where shader motion hides it.
func _setup_light() -> void:
	if screen == null:
		return
	var background := screen.get_node_or_null("Background") as Sprite2D
	if background == null or background.texture == null:
		return
	var image := background.texture.get_image()
	if image == null:
		return
	_light = ShaderMaterial.new()
	_light.shader = preload("res://scripts/pip_light.gdshader")
	_light.set_shader_parameter("light_map", ImageTexture.create_from_image(make_light_map(image)))
	_light.set_shader_parameter("map_origin", background.global_position)
	_light.set_shader_parameter("map_size", background.texture.get_size() * background.global_scale)
	_light.set_shader_parameter("strength", light_strength)
	_light.set_shader_parameter("spread", light_spread)
	_light.set_shader_parameter("feet", global_position)
	sprite.material = _light


## A tiny, heavily blurred copy of a painting, divided by its average brightness so 1.0
## is the screen's average light. Halving step by step averages every pixel in.
static func make_light_map(painting: Image) -> Image:
	var image := painting.duplicate() as Image
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBF)
	while image.get_width() > LIGHT_MAP_SIZE.x * 2:
		image.resize(maxi(image.get_width() >> 1, LIGHT_MAP_SIZE.x), maxi(image.get_height() >> 1, LIGHT_MAP_SIZE.y), Image.INTERPOLATE_BILINEAR)
	image.resize(LIGHT_MAP_SIZE.x, LIGHT_MAP_SIZE.y, Image.INTERPOLATE_BILINEAR)
	for i in LIGHT_MAP_BLURS:
		image = _box_blur(image)
	var total := 0.0
	for y in image.get_height():
		for x in image.get_width():
			total += image.get_pixel(x, y).get_luminance()
	var mean := maxf(total / (image.get_width() * image.get_height()), 0.01)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y) / mean
			var lum := maxf(c.get_luminance(), 0.001)
			c *= clampf(lum, LIGHT_MAP_MIN, LIGHT_MAP_MAX) / lum
			c.a = 1.0
			image.set_pixel(x, y, c)
	image.convert(Image.FORMAT_RGBH)
	return image


static func _box_blur(image: Image) -> Image:
	var w := image.get_width()
	var h := image.get_height()
	var out := Image.create_empty(w, h, false, image.get_format())
	for y in h:
		for x in w:
			var sum := Color(0, 0, 0, 0)
			var n := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var sx := clampi(x + dx, 0, w - 1)
					var sy := clampi(y + dy, 0, h - 1)
					sum += image.get_pixel(sx, sy)
					n += 1
			out.set_pixel(x, y, sum / n)
	return out


func _find_screen() -> Screen:
	var node := get_parent()
	while node:
		if node is Screen:
			return node
		node = node.get_parent()
	return null
