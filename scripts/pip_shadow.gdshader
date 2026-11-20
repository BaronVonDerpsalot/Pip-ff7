shader_type canvas_item;
render_mode blend_mul;

// Pip's shadow (scripts/pip_shadow.gd): his current frame, flattened and sheared along the ground, multiplied
// over the painting so its texture shows through. With a depth map, the shadow bends over the ground like
// the old displacement-map trick: where the ground bulges toward the camera (a tussock) it climbs, where it
// dips (a rut) it sinks. Depth, not brightness, since dark mud isn't low ground.

uniform vec3 colour : source_color = vec3(0.28, 0.30, 0.38);  // the shadow's darkest tint
uniform float strength : hint_range(0.0, 1.0) = 0.5;
uniform float blur = 5.0;                // screen px the shadow's edge is blurred over
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);  // the current frame inside its sheet, in UV (x0, y0, x1, y1)
// Nearness, 16 bits packed in red and green (tools/depth/depth.py).
uniform sampler2D depth_tex : filter_nearest;
uniform bool has_depth = false;
uniform float bend = 900.0;              // screen px the shadow moves per unit of nearness above its surroundings
uniform float max_bend = 20.0;           // screen px, at most
uniform float bump_radius = 24.0;        // screen px: bumps are measured against the ground this far around
// The screen's water (the shader-motion masks, white = water): no shadow falls on it.
uniform sampler2D river_mask : filter_linear, hint_default_black;
uniform sampler2D pond_mask : filter_linear, hint_default_black;
uniform float tex_px_per_screen_px = 4.0;    // up the ground: set every frame by pip_shadow.gd
uniform float tex_px_per_screen_px_x = 2.0;  // across: set every frame by pip_shadow.gd
const vec2 SCREEN = vec2(1920.0, 1080.0);

varying vec2 canvas_pos;

void vertex() {
	canvas_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float nearness(vec2 px) {
	vec2 rg = texture(depth_tex, clamp(px, vec2(0.0), SCREEN - 1.0) / SCREEN).rg;
	return (floor(rg.r * 255.0 + 0.5) * 256.0 + floor(rg.g * 255.0 + 0.5)) / 65535.0;
}

float shape(sampler2D tex, vec2 uv) {  // TEXTURE only exists inside fragment()
	if (uv.x < region.x || uv.y < region.y || uv.x > region.z || uv.y > region.w) {
		return 0.0;
	}
	return texture(tex, uv).a;
}

void fragment() {
	vec2 uv = UV;
	if (has_depth) {
		float here = nearness(canvas_pos);
		float around = 0.0;
		for (int i = 0; i < 8; i++) {
			float a = float(i) * 0.785398;
			around += nearness(canvas_pos + vec2(cos(a), sin(a)) * bump_radius);
		}
		float bump = here - around / 8.0;
		float shift = clamp(bump * bend, -max_bend, max_bend);  // screen px; up for a bulge
		uv.y += shift * tex_px_per_screen_px * TEXTURE_PIXEL_SIZE.y;
	}
	// A soft edge: the frame's shape averaged over two rings of eight points, sized in screen pixels so it
	// blurs as much along the ground as across it (the frame is squashed a lot more up the ground).
	vec2 r = vec2(tex_px_per_screen_px_x, tex_px_per_screen_px) * TEXTURE_PIXEL_SIZE * blur;
	float a = shape(TEXTURE, uv) * 0.2;
	for (int i = 0; i < 8; i++) {
		float ang = float(i) * 0.785398 + 0.3927;
		vec2 d = vec2(cos(ang), sin(ang)) * r;
		a += shape(TEXTURE, uv + d) * 0.05 + shape(TEXTURE, uv + d * 0.5) * 0.05;
	}
	vec2 suv = canvas_pos / SCREEN;
	float water = max(texture(river_mask, suv).r, texture(pond_mask, suv).r);
	a *= 1.0 - smoothstep(0.2, 0.8, water);
	COLOR = vec4(mix(vec3(1.0), colour, a * strength), 1.0);
}
