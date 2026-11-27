shader_type canvas_item;

// Pip's reflection (scripts/pip_reflection.gd): his current frame flipped about his feet, drawn inside the
// screen's shader-motion viewport just above the clean plate, so reeds and the hide-Pip shapes stay in front.
// It shows only where the water masks are white, ripples with the water under it (the same code, shared
// through motion_water.gdshaderinc), is darkened and tinted to the water, and fades with distance from his feet.
#include "res://scripts/motion_water.gdshaderinc"

uniform sampler2D plate : source_color, filter_linear;  // the water's own colours, for the tint
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);  // the current frame inside its sheet, in UV
uniform vec2 feet = vec2(0.0);          // screen px
uniform float pip_height = 200.0;       // screen px, from Screen.height_at
uniform float strength : hint_range(0.0, 1.0) = 0.85;
uniform float darken : hint_range(0.0, 1.0) = 0.12;
uniform float tint : hint_range(0.0, 1.0) = 0.18;
// Its own gentle waver on top of the water's, so even a still puddle bends it a little.
uniform float waver = 2.5;              // screen px, side to side
uniform float waver_speed = 1.3;
uniform float fade_heights = 0.9;       // gone this many Pip-heights below his feet
uniform float tex_px_per_screen_px = 2.0;  // set every frame by pip_reflection.gd
uniform vec2 SCREEN = vec2(1920.0, 1080.0);  // the painting's size (Screen.painting_size), set by the script

varying vec2 canvas_pos;

void vertex() {
	canvas_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 p = canvas_pos;
	vec2 suv = p / SCREEN;
	float mr = texture(river_mask, suv).r;
	float mp = texture(pond_mask, suv).r;
	float m = max(mr, mp);
	if (m <= 0.0) {
		COLOR = vec4(0.0);
	} else {
		float river_spark;
		float ring_crest;
		vec2 off = water_offset(p, suv, mr, mp, river_spark, ring_crest);
		// Bands across the reflection slide side to side, more the further from his feet.
		float below = clamp((p.y - feet.y) / max(pip_height, 1.0), 0.0, 1.0);
		off.x += waver * (0.4 + below) * sin(p.y * 0.21 + TIME * waver_speed * 6.2832)
			* (0.6 + 0.4 * sin(p.y * 0.05 - TIME * waver_speed * 2.3));
		off.y += waver * 0.25 * sin(p.x * 0.08 + TIME * waver_speed * 4.1);
		// The frame is flipped vertically, so a screen offset down is a texture offset up.
		vec2 uv = UV + vec2(off.x, -off.y) * tex_px_per_screen_px * TEXTURE_PIXEL_SIZE;
		float inside = step(region.x, uv.x) * step(region.y, uv.y) * step(uv.x, region.z) * step(uv.y, region.w);
		vec4 c = texture(TEXTURE, uv);
		vec3 water = texture(plate, suv).rgb;
		vec3 col = mix(c.rgb * (1.0 - darken), water, tint);
		float fade = 1.0 - smoothstep(0.0, fade_heights * pip_height, p.y - feet.y);
		COLOR = vec4(col, c.a * inside * m * fade * strength);
	}
}
