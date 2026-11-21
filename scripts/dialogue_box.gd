class_name DialogueBox
extends CanvasLayer
## A conversation's text box along the bottom of the screen. Each press of `talk` shows the next line;
## after the last one it closes and emits `finished`. Lines come from res://lines/slice.txt (never from code).
## Placeholder look and font: the font is still an open decision (BRIEF).

signal finished

const LINES_FILE := "res://lines/slice.txt"

var _lines: Array[Dictionary] = []
var _at := 0
var _at_top := false
var _name: Label
var _text: Label


## Opens a box on the current scene for the conversation `id`. Returns null if the file has no such conversation.
## at_top puts it along the top of the screen, for when the speakers stand low enough for it to cover them.
static func open(tree: SceneTree, id: String, at_top := false) -> DialogueBox:
	var lines := load_conversation(id)
	if lines.is_empty():
		push_warning("No conversation '%s' in %s" % [id, LINES_FILE])
		return null
	var box := DialogueBox.new()
	box._lines = lines
	box._at_top = at_top
	tree.current_scene.add_child(box)
	return box


## The lines of conversation `id`, as {"speaker": String, "text": String}; narration has speaker "".
static func load_conversation(id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var file := FileAccess.open(LINES_FILE, FileAccess.READ)
	if file == null:
		push_error("Can't read %s" % LINES_FILE)
		return out
	var inside := false
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.begins_with("=="):
			inside = line.trim_prefix("==").strip_edges() == id
			continue
		if not inside:
			continue
		if line.begins_with("("):
			out.append({"speaker": "", "text": line})
		else:
			var colon := line.find(":")
			if colon > 0:
				out.append({"speaker": line.left(colon).strip_edges(), "text": line.substr(colon + 1).strip_edges()})
			else:
				out.append({"speaker": "", "text": line})
	return out


func _ready() -> void:
	layer = 50
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.08, 0.07, 0.82)
	style.border_color = Color(0.85, 0.78, 0.62, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left = 0.12
	panel.anchor_right = 0.88
	panel.anchor_top = 0.05 if _at_top else 0.74
	panel.anchor_bottom = 0.26 if _at_top else 0.95
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 34)
	_name.add_theme_color_override("font_color", Color(0.95, 0.8, 0.5))
	column.add_child(_name)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 40)
	_text.add_theme_color_override("font_color", Color(0.96, 0.94, 0.9))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_text)
	_show()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("talk") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_at += 1
		if _at >= _lines.size():
			finished.emit()
			queue_free()
		else:
			_show()


func _show() -> void:
	var line: Dictionary = _lines[_at]
	_name.text = line.speaker
	_name.visible = line.speaker != ""
	_text.text = line.text
