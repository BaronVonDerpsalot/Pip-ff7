shader_type canvas_item;

// Hides Pip behind whatever is nearer than the ground at his feet (scripts/depth_occluder.gd).
// Drawn over the whole screen above Pip, but only inside his box and above his feet: there it redraws the
// screen's own pixels wherever the depth map says they are nearer than his feet by more than `tolerance`.
// Ground in front of him is below his feet on screen, so it never hides him.

// Nearness (0 far .. 1 near), 16 bits packed in red (high byte) and green (low byte): tools/depth/depth.py.
uniform sampler2D depth_tex : filter_nearest;
// The screen's moving pixels (shader motion or video); without them, the sprite's own texture (the painting).
uniform sampler2D colour_tex : source_color, filter_linear;
uniform bool has_colour = false;
uniform vec2 feet = vec2(0.0);         // Pip's feet, screen pixels
uniform vec4 pip_rect = vec4(0.0);     // x0, y0, x1, y1: where Pip can be drawn
uniform float ground = 0.0;            // nearness of the ground at his feet (depth_occluder.gd reads it)
uniform float tolerance = 0.01;        // how much nearer than his feet a pixel must be to cover him
uniform float soft = 0.01;             // fade over this much more nearness
uniform float grow = 3.0;              // px: whatever covers him also covers this far past its edge
uniform bool show_mask = false;        // debug: tint what covers him red
const vec2 SCREEN = vec2(1920.0, 1080.0);

float nearness(vec2 px) {
	vec2 rg = texture(depth_tex, px / SCREEN).rg;
	return (floor(rg.r * 255.0 + 0.5) * 256.0 + floor(rg.g * 255.0 + 0.5)) / 65535.0;
}

void fragment() {
	vec2 px = UV * SCREEN;
	if (px.x < pip_rect.x || px.x > pip_rect.z || px.y < pip_rect.y || px.y > feet.y) {
		COLOR = vec4(0.0);
	} else {
		// The nearest thing within `grow` px, so the depth map's soft edges don't leave a rim of Pip showing.
		float n = nearness(px);
		if (grow > 0.0) {
			for (int i = 0; i < 8; i++) {
				vec2 dir = vec2(cos(float(i) * 0.785398), sin(float(i) * 0.785398));
				n = max(n, max(nearness(px + dir * grow), nearness(px + dir * grow * 0.5)));
			}
		}
		float a = smoothstep(ground + tolerance, ground + tolerance + soft, n);
		vec3 c = has_colour ? texture(colour_tex, UV).rgb : texture(TEXTURE, UV).rgb;
		if (show_mask) {
			c = mix(c, vec3(1.0, 0.0, 0.0), 0.6);
		}
		COLOR = vec4(c, a);
	}
}
