extends Screen
## Style test bench (not part of the game): Pip walks over trial paintings so
## their look can be judged with him in front. Run tools/style_test/style_test.tscn.
##
## Drop images (PNG, JPG or WebP, ideally 1920x1080 or 16:9) into
## Pip FF7/kept-assets/style-tests/, outside git. Tab flips to the next one;
## Pip stays where he is so the same spot can be compared across styles.
## He can walk anywhere on screen, and his size follows the depth numbers below.

const FOLDER := "../kept-assets/style-tests"
const SIZE := Vector2(1920, 1080)

var _files := PackedStringArray()
var _index := 0

@onready var background: Sprite2D = $Background
@onready var label: Label = $Info/Label


func _ready() -> void:
	super._ready()
	var dir := ProjectSettings.globalize_path("res://").path_join(FOLDER).simplify_path()
	for file in DirAccess.get_files_at(dir):
		if file.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"]:
			_files.append(dir.path_join(file))
	_files.sort()
	if _files.is_empty():
		label.text = "No images yet. Put some in %s, then run this again." % dir
		return
	_show(0)


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if event.is_action_pressed("ui_focus_next") and not _files.is_empty():
		_show((_index + 1) % _files.size())


func _show(i: int) -> void:
	_index = i
	var image := Image.load_from_file(_files[i])
	if image == null:
		label.text = "Couldn't read %s" % _files[i].get_file()
		return
	background.texture = ImageTexture.create_from_image(image)
	# Fill the screen whatever the image's size; a non-16:9 image is stretched.
	background.scale = SIZE / Vector2(image.get_size())
	label.text = "%d/%d  %s   (Tab: next)" % [i + 1, _files.size(), _files[i].get_file()]
