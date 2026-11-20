extends Node
## Records a running screen as numbered half-size JPGs, for a capture to approve (docs/recipes/screens-shader-motion.md).
## Put it in a scene with the screen instanced next to it and run that scene; frames go to
## user://capture/<frame>.jpg with times.txt (on Windows: %APPDATA%/Godot/app_userdata/<project>/capture/).

@export var start_after := 0.5   # seconds, so loading doesn't land in the capture
@export var every := 3           # frames between saves (60 fps / 3 = 20 fps)
@export var count := 160         # 8 s at 20 fps: the sway is slow, so shorter shows under one cycle

var _frame := 0
var _saved := 0
var _images: Array[Image] = []
var _times: PackedInt64Array = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://capture")
	for f in DirAccess.get_files_at("user://capture"):
		DirAccess.remove_absolute("user://capture/" + f)


func _process(_delta: float) -> void:
	if _saved >= count or Time.get_ticks_msec() < start_after * 1000.0:
		return
	_frame += 1
	if _frame % every != 0:
		return
	# Held in memory and written at the end: saving PNGs mid-run drops the frame rate and speeds up the GIF.
	# Reading a frame back slows the game, but shaders run on real time, so each frame's time is written
	# too (times.txt, ms) and the GIF should use those gaps rather than a fixed delay.
	var img := get_viewport().get_texture().get_image()
	img.resize(960, 540, Image.INTERPOLATE_BILINEAR)  # half size as taken: 160 full-size frames would be 1.3 GB
	_images.append(img)
	_times.append(Time.get_ticks_msec())
	_saved += 1
	if _saved == count:
		for i in _images.size():  # JPGs: full-size PNGs take long enough to stall the run
			_images[i].save_jpg("user://capture/%03d.jpg" % i, 0.9)
		FileAccess.open("user://capture/times.txt", FileAccess.WRITE).store_string("\n".join(Array(_times).map(func(t: int) -> String: return str(t))))
		print("capture: %d frames written" % _images.size())
