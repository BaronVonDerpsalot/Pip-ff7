shader_type canvas_item;

// An occluder (scripts/occluder.gd). On a screen with a video loop it draws the loop's pixels through its own shape;
// until the video has a frame (or on a still screen) it draws its own pixels, cut from the painting.
// A shape on the bottom-edge rule is switched on by Pip alone, so it draws only inside his frame: anyone else
// near it (the mole) isn't covered just because Pip is behind it.
uniform sampler2D video : source_color, filter_linear;
uniform bool has_video = false;
uniform vec4 rect; // the occluder's x, y, width, height on the 1920x1080 screen
uniform bool clip_to_pip = false;
uniform vec4 pip_rect; // Pip's frame: left, top, right, bottom on the screen
const vec2 SCREEN = vec2(1920.0, 1080.0);

void fragment() {
	vec2 p = rect.xy + UV * rect.zw;
	if (clip_to_pip && (p.x < pip_rect.x || p.x > pip_rect.z || p.y < pip_rect.y || p.y > pip_rect.w)) {
		discard;
	}
	vec4 own = texture(TEXTURE, UV);
	if (has_video) {
		COLOR = vec4(texture(video, p / SCREEN).rgb, own.a);
	} else {
		COLOR = own;
	}
}
