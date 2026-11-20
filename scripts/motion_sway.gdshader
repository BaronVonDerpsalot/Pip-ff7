shader_type canvas_item;

// A cut-out that sways in the breeze (reeds, grass, fronds), pinned at its bottom edge.
// The sprite's texture is padded by a few pixels on each side so the sway never runs off its edge.
// Motion is three slow waves at unrelated speeds (so it never visibly repeats) under a gust strength that
// rises and falls on its own. Set by tools/motion_to_game.gd; tune per piece in the inspector.
uniform float amp = 5.0;        // pixels the tips move at most
uniform float speed = 0.22;     // main sway cycles per second
uniform float stiffness = 1.8;  // higher keeps more of the stem still; motion grows as height^stiffness
uniform float phase = 0.0;      // offsets this piece so neighbours don't move in step
uniform float lean = 0.3;       // share of amp the piece leans downwind on average
uniform float gustiness = 0.6;  // 0 = steady breeze, 1 = gusts from near calm to full

float hash(float n) { return fract(sin(n) * 43758.5453); }

// Smooth 1D value noise, 0..1.
float noise(float x) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), f);
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	float h = clamp(1.0 - UV.y, 0.0, 1.0);  // 0 at the root (bottom), 1 at the top
	float w = pow(h, stiffness);
	float x = UV.x / px.x;                   // pixels across the piece
	float t = TIME * speed * 6.2832;
	// Columns further right lag a little, so a clump moves as a wave rather than a block.
	float lag = x * 0.003;
	float s = 0.55 * sin(t + phase - lag)
		+ 0.30 * sin(t * 0.61 + phase * 1.9 - lag * 1.4)
		+ 0.15 * sin(t * 1.73 + phase * 0.7 - lag * 3.0);
	float gust = mix(1.0, noise(TIME * 0.12 + phase * 3.1) * 1.4, gustiness);
	float dx = amp * w * (lean + (1.0 - lean) * s) * gust;
	COLOR = texture(TEXTURE, UV - vec2(dx * px.x, 0.0));
}
