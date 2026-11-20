shader_type canvas_item;

// The screen's clean plate, alive only where a water mask is white. Water moves in place, so it needs no
// cut-out: the painting's own pixels are nudged. Two kinds, each with its own mask and settings:
//   river_mask  flowing water: the wobble pattern drifts downstream along `river_flow`
//   pond_mask   still water (puddles, ponds): a slow wobble that stays where it is, and the odd ripple ring
// Both get sun glints on the crests, tinted by the painting's own colour there.
#include "res://scripts/motion_water.gdshaderinc"

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec2 p = UV / px;
	float mr = texture(river_mask, UV).r;
	float mp = texture(pond_mask, UV).r;
	float river_spark;
	float ring_crest;
	vec2 off = water_offset(p, UV, mr, mp, river_spark, ring_crest);
	float tp = TIME * pond_speed;
	// Only sample other water, so shore and reed pixels never smear into it.
	vec2 suv = UV + off * px;
	float m2 = max(texture(river_mask, suv).r, texture(pond_mask, suv).r);
	vec4 c = texture(TEXTURE, UV + off * px * m2);

	float spark = 0.0;
	spark += river_spark * river_glints * mr;
	if (mp > 0.0) {
		spark += sparkle(p, tp, vec2(0.0)) * pond_glints * mp;
	}
	float m = max(mr, mp);
	float flick = shimmer * (fbm(vec2(p.x * 0.036, p.y * 0.1) + TIME * 0.5) - 0.5) * 2.0;
	c.rgb += m * flick * c.rgb + spark * mix(vec3(1.0, 0.9, 0.7), c.rgb * 2.0, 0.4);
	c.rgb += ring_crest * 0.35 * vec3(1.0, 0.95, 0.85);  // Pip's rings catch a little light
	COLOR = c;
}
