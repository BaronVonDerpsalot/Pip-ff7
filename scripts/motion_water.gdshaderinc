// Shared by motion_water.gdshader (the water itself) and pip_reflection.gdshader (Pip's reflection in it), so
// the reflection ripples exactly as the water under it does. Uniform values are set on the water's material
// and copied to the reflection's by scripts/pip_reflection.gd.
uniform sampler2D river_mask : filter_linear, hint_default_black;
uniform sampler2D pond_mask : filter_linear, hint_default_black;

uniform float river_amp = 3.5;       // pixels the reflections waver
uniform float river_speed = 1.0;
uniform vec2 river_flow = vec2(-0.35, 1.6); // without a flow map: one drift for the whole river (+x right, +y down)
// With a flow map (tools/segment/segment.py, <river>_flow.png: R, G = direction), the pattern instead drifts
// along the river at every point, following its bends, at river_px_per_s.
uniform sampler2D river_flow_map : filter_linear, hint_default_black;
uniform bool has_flow_map = false;
uniform float river_px_per_s = 55.0;
uniform float river_glints = 0.35;

uniform float pond_amp = 2.0;
uniform float pond_speed = 0.35;
uniform float pond_glints = 0.25;
uniform float rings = 1.0;           // strength of the ripple rings on still water (0 = none)
uniform float ring_cell = 120.0;     // pixels between possible ring spots
uniform float ring_rate = 0.15;      // rings per spot per second

uniform float shimmer = 0.05;        // soft overall flicker on both

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

// Offset (in pixels) from the rings near p: a thin crest that grows and fades.
vec2 ring_offset(vec2 p, float t) {
	vec2 cell = floor(p / ring_cell);
	vec2 off = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 c = cell + vec2(float(i), float(j));
			vec2 centre = (c + vec2(hash(c), hash(c + 17.3))) * ring_cell;
			float cycle = t * ring_rate + hash(c + 41.7);
			float life = fract(cycle);
			float alive = step(0.55, hash(c + floor(cycle)));  // not every spot every time
			vec2 d = p - centre;
			float dist = length(d);
			float radius = life * ring_cell * 0.45;
			float crest = exp(-pow((dist - radius) / 2.5, 2.0)) * (1.0 - life) * alive;
			off += normalize(d + 0.001) * crest;
		}
	}
	return off;
}

// Wobble offset in pixels; `drift` moves the pattern (zero for still water).
vec2 wobble(vec2 p, float t, vec2 drift) {
	vec2 q = vec2(p.x * 0.012, p.y * 0.035) - drift * t;  // squashed vertically, like reflections at a low angle
	vec2 n = vec2(fbm(q + vec2(0.0, t * 0.6)), fbm(q + vec2(5.2, -t * 0.4))) - 0.5;
	return vec2(n.x * 2.0, n.y * 0.7);
}

float sparkle(vec2 p, float t, vec2 drift) {
	float crest = fbm(vec2(p.x * 0.05, p.y * 0.12) - drift * t * 3.0 + vec2(t * 0.9, -t * 0.5));
	return smoothstep(0.68, 0.78, crest);
}

// The river's wobble and glint carried along the flow map. A pattern can't be dragged along a bend forever
// without smearing, so two copies take turns: each drifts for one cycle and fades out as the other, half a
// cycle behind, fades in (the usual flow-map trick).
void flowed(vec2 p, vec2 dir, float t, out vec2 wob, out float spark) {
	float cycle = 1.6;  // seconds each copy drifts before it resets
	float pa = fract(TIME / cycle);
	float pb = fract(TIME / cycle + 0.5);
	float wa = 1.0 - abs(pa * 2.0 - 1.0);  // weight: 0 at reset, 1 mid-cycle
	vec2 sa = p - dir * pa * cycle * river_px_per_s;
	vec2 sb = p - dir * pb * cycle * river_px_per_s + vec2(37.0, 91.0);  // offset so the copies don't match
	wob = mix(wobble(sb, t, vec2(0.0)), wobble(sa, t, vec2(0.0)), wa);
	spark = mix(sparkle(sb, t, vec2(0.0)), sparkle(sa, t, vec2(0.0)), wa);
}

// Rings Pip makes stepping into water (scripts/pip_reflection.gd): x, y, age in seconds, strength (0 = none).
uniform vec4 step_rings[4];
uniform float step_ring_speed = 38.0;  // pixels a ring grows per second
uniform float step_ring_life = 1.4;    // seconds

// Offset (in pixels) from Pip's rings near p, and how bright their crests are there.
vec2 step_ring_offset(vec2 p, out float crest_sum) {
	vec2 off = vec2(0.0);
	crest_sum = 0.0;
	for (int k = 0; k < 4; k++) {
		vec4 r = step_rings[k];
		if (r.w <= 0.0 || r.z < 0.0 || r.z > step_ring_life) {
			continue;
		}
		vec2 d = (p - r.xy) * vec2(1.0, 2.6);  // squashed: a ring on the ground seen at a low angle
		float dist = length(d);
		float life = r.z / step_ring_life;
		float radius = r.z * step_ring_speed;
		float crest = exp(-pow((dist - radius) / 3.5, 2.0)) * (1.0 - life) * r.w;
		off += normalize(d + 0.001) * crest;
		crest_sum += crest;
	}
	return off;
}

// The water's offset at screen pixel p (uv = p / screen size), before masking the sample to water.
vec2 water_offset(vec2 p, vec2 uv, float mr, float mp, out float river_spark, out float ring_crest) {
	vec2 off = vec2(0.0);
	float tr = TIME * river_speed;
	float tp = TIME * pond_speed;
	river_spark = 0.0;
	ring_crest = 0.0;
	if (mr > 0.0) {
		if (has_flow_map) {
			vec2 dir = texture(river_flow_map, uv).rg * 2.0 - 1.0;
			vec2 wob;
			flowed(p, dir, tr * 0.5, wob, river_spark);
			off += wob * river_amp * mr;
		} else {
			off += wobble(p, tr, river_flow) * river_amp * mr;
			river_spark = sparkle(p, tr, river_flow);
		}
	}
	float m = max(mr, mp);
	if (mp > 0.0) {
		off += (wobble(p, tp, vec2(0.0)) * pond_amp + ring_offset(p, TIME) * rings * 2.0) * mp;
	}
	if (m > 0.0) {
		off += step_ring_offset(p, ring_crest) * 4.0 * m;
		ring_crest *= m;
	}
	return off;
}
