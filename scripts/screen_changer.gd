extends CanvasLayer
## Autoload (ScreenChanger): moves Pip from one screen to the next.
## Pip and the whole screen fade out together, then the next screen fades in
## with Pip already at his entry point (DECISIONS, 2026-11-13).

## Seconds for each half of the fade.
const FADE_TIME := 0.35

## True from the moment Pip steps into an exit until the next screen has faded in.
var busy := false
## The entry point the next screen should put Pip at, or &"" for its default.
var _pending_entry: StringName = &""
var _veil: ColorRect

signal arrived


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_veil = ColorRect.new()
	_veil.color = Color(0, 0, 0, 0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_veil)


## Fades out, loads the screen at path, puts Pip at its entry point, fades back in.
func go(path: String, entry: StringName) -> void:
	if busy:
		return
	busy = true
	_pending_entry = entry
	await _fade_to(1.0)
	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed
	await _fade_to(0.0)
	busy = false
	arrived.emit()


## Called by a screen as it loads: the entry point to use, once.
func take_entry() -> StringName:
	var entry := _pending_entry
	_pending_entry = &""
	return entry


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_veil, "color:a", alpha, FADE_TIME)
	await tween.finished
