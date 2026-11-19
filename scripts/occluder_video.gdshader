shader_type canvas_item;

// An occluder (scripts/occluder.gd) on a screen with a video loop: the loop's pixels, through the occluder's shape.
// Until the video has a frame, it draws its own pixels (cut from the painting).
uniform sampler2D video : source_color, filter_linear;
uniform bool has_video = false;
uniform vec4 rect; // the occluder's x, y, width, height on the 1920x1080 screen
const vec2 SCREEN = vec2(1920.0, 1080.0);

void fragment() {
	vec4 own = texture(TEXTURE, UV);
	if (has_video) {
		COLOR = vec4(texture(video, (rect.xy + UV * rect.zw) / SCREEN).rgb, own.a);
	} else {
		COLOR = own;
	}
}
