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
## Where Pip's shadow falls: his head's shadow lands this far from his feet, per unit of his height
## (screen x, y). Away from the painting's sun.
@export var shadow_dir := Vector2(0.3, 0.35)
@export_range(0.0, 1.0) var shadow_strength := 0.7
## The painting's depth map (tools/depth/depth.py), which Pip's shadow bends over. Optional.
@export var depth_map: Texture2D
## On a painting wider than the view, how far (view pixels) the camera trails Pip, and how far he can
## move from the middle of the view before it follows: FF7's scrolling screens keep him near the middle.
@export var camera_smoothing := 4.0
@export var camera_dead_zone := 0.12

## The view the game draws (project settings: 1920x1080).
const VIEW := Vector2(1920, 1080)

@onready var walk_area: Polygon2D = $WalkArea
@onready var pip: Pip = $World/Pip
## ScreenExit zones (under an Exits node) and ScreenEntry points (under Entries).
var exits: Array[ScreenExit] = []
var camera: Camera2D


func _ready() -> void:
	var exit_nodes := get_node_or_null("Exits")
	if exit_nodes:
		for node in exit_nodes.get_children():
			if node is ScreenExit:
				exits.append(node)
	# The walk area and exits show in the editor for drawing, but not in the game (F toggles them).
	_show_guides(false)
	_add_camera()
	_arrive()
	if camera != null:
		_follow(true)


func _process(_delta: float) -> void:
	if camera != null:
		_follow(false)


## The painting's size in screen pixels (the Background's texture); 1920x1080 on a screen without one.
## Shaders that turn screen pixels into texture coordinates take this, so a wide painting works as a normal one.
## Children ask for it in their own _ready, before this node's, so it's read from the Background each time.
func painting_size() -> Vector2:
	var bg := get_node_or_null("Background") as Sprite2D
	if bg == null or bg.texture == null:
		return VIEW
	return bg.texture.get_size() * bg.scale


## A painting bigger than the view gets a camera that follows Pip and stops at its edges.
func _add_camera() -> void:
	var size := painting_size()
	if size.x <= VIEW.x + 1.0 and size.y <= VIEW.y + 1.0:
		return
	camera = Camera2D.new()
	camera.name = "Camera"
	camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = camera_smoothing
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	camera.drag_left_margin = camera_dead_zone
	camera.drag_right_margin = camera_dead_zone
	camera.drag_top_margin = camera_dead_zone
	camera.drag_bottom_margin = camera_dead_zone
	add_child(camera)
	camera.make_current()


## Puts the camera on Pip (his middle, not his feet). `snap` jumps straight there, for arriving on the screen.
func _follow(snap: bool) -> void:
	var height := height_at(pip.global_position.y)
	camera.global_position = pip.global_position - Vector2(0, height * 0.5)
	if snap:
		camera.reset_smoothing()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_walk_area"):
		_show_guides(not walk_area.visible)


func _physics_process(_delta: float) -> void:
	if ScreenChanger.busy:
		return
	for exit in exits:
		if exit.contains(pip.position, pip.get_parent()):
			# Pip stops where he is and fades out with the screen.
			pip.process_mode = Node.PROCESS_MODE_DISABLED
			ScreenChanger.go(exit.to_screen, exit.to_entry)
			return


## Puts Pip at the entry point he came through, and holds him still until the fade-in ends.
func _arrive() -> void:
	var entry_name := ScreenChanger.take_entry()
	if entry_name == &"":
		return
	var entry := get_node_or_null("Entries/" + entry_name) as ScreenEntry
	if entry == null:
		push_warning("%s has no entry point %s; Pip stays at his start." % [name, entry_name])
	else:
		pip.arrive_at(pip.get_parent().to_local(entry.global_position), entry.facing)
	if ScreenChanger.busy:
		pip.process_mode = Node.PROCESS_MODE_DISABLED
		await ScreenChanger.arrived
		pip.process_mode = Node.PROCESS_MODE_INHERIT


func _show_guides(on: bool) -> void:
	walk_area.visible = on
	for exit in exits:
		exit.visible = on


## Pip's on-screen height in pixels when his feet are at screen y.
func height_at(y: float) -> float:
	var t := inverse_lerp(far_y, near_y, y)
	return lerpf(far_height, near_height, t)


## Inside the walk area and not where a villager stands.
func is_walkable(point: Vector2) -> bool:
	var global := to_global(point)
	if not Geometry2D.is_point_in_polygon(walk_area.to_local(global), walk_area.polygon):
		return false
	for villager in get_tree().get_nodes_in_group(&"villagers"):
		if villager.blocks(global):
			return false
	return true
