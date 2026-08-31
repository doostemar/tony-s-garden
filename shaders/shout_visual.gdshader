// shout_visual.gdshader
// draws tony's shout area-of-effect as an analytical circle.
// radius and quad_size are in local pixel units and are fed from Shout_Component,
// so the drawn circle always matches the CircleShape2D the physics uses.

shader_type canvas_item;

// --- driven by script, do not hand-edit at runtime ---
uniform float radius = 25.0;          // actual gameplay radius (px)
uniform float quad_size = 60.0;       // full width/height of the sprite quad (px)
uniform float progress : hint_range(0.0, 1.0) = 0.0; // 0 = shout start, 1 = hitbox ends
uniform bool  active = false;         // true while the hitbox is live
uniform bool  show_static_outline = false; // testing aid: always draw the AOE edge

// --- look & feel, safe to tweak in the inspector ---
uniform vec4  fill_color : source_color = vec4(1.0, 0.85, 0.3, 0.30);
uniform vec4  ring_color : source_color = vec4(1.0, 0.55, 0.1, 0.90);
uniform vec4  outline_color : source_color = vec4(1.0, 1.0, 1.0, 0.35);
uniform float ring_thickness = 2.0;   // px
uniform float edge_softness  = 1.0;   // px of anti-aliasing

void fragment() {
	// UV (0..1) -> local px, origin at circle center
	vec2  local = (UV - vec2(0.5)) * quad_size;
	float d     = length(local);
	float s     = max(edge_softness, 0.0001);

	// 1 inside the true radius, 0 outside (anti-aliased edge)
	float inside = 1.0 - smoothstep(radius - s, radius + s, d);

	vec4 col = vec4(0.0);

	if (active) {
		float fade = 1.0 - progress;

		// translucent fill of the exact AOE, fading out over the hitbox duration
		col = vec4(fill_color.rgb, fill_color.a * inside * fade);

		// ring that expands from the center to the true radius
		float ring_r = radius * progress;
		float ring   = 1.0 - smoothstep(
			ring_thickness * 0.5,
			ring_thickness * 0.5 + s,
			abs(d - ring_r)
		);
		ring *= inside; // never draw outside the gameplay area

		float ring_a = ring * ring_color.a * fade;
		col.rgb = mix(col.rgb, ring_color.rgb, ring_a);
		col.a   = max(col.a, ring_a);
	}

	if (show_static_outline) {
		// thin line exactly on the radius so you can see the AOE without debug shapes
		float o   = 1.0 - smoothstep(
			0.5,
			0.5 + s,
			abs(d - radius)
		);
		float o_a = o * outline_color.a;
		col.rgb = mix(col.rgb, outline_color.rgb, o_a);
		col.a   = max(col.a, o_a);
	}

	COLOR = col;
}