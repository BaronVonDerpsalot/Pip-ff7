shader_type canvas_item;
// Tints Pip toward the screen's light where he stands. light_map is a tiny, heavily
// blurred copy of the painting (made by pip.gd), divided by its own average brightness,
// so a pixel of 1.0 is the screen's average light: Pip is warmer and brighter in sun,
// darker and greener in shade, and takes on the screen's colour cast.

uniform sampler2D light_map : filter_linear, repeat_disable;
// Turns a canvas position into light-map UV: uv = (pos - origin) / size.
uniform vec2 map_origin = vec2(0.0);
uniform vec2 map_size = vec2(1920.0, 1080.0);
// Pip's feet, in canvas pixels: the light there sets his overall tint.
uniform vec2 feet = vec2(960.0, 540.0);
// How far toward the light he goes (0 = untouched, 1 = fully lit by it).
uniform float strength : hint_range(0.0, 1.0) = 0.5;
// How much the light changes across his own body, from feet to head (0 = one tint).
uniform float spread : hint_range(0.0, 1.0) = 0.35;

varying vec2 canvas_pos;

void vertex() {
	canvas_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// COLOR already holds the frame's pixel times modulate (the gait flash).
	vec4 col = COLOR;
	vec3 at_feet = texture(light_map, (feet - map_origin) / map_size).rgb;
	vec3 here = texture(light_map, (canvas_pos - map_origin) / map_size).rgb;
	vec3 light = mix(at_feet, here, spread);
	col.rgb *= mix(vec3(1.0), light, strength);
	COLOR = col;
}
