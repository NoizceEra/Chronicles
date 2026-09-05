shader_type canvas_item;

// sprite_depth.gdshader — 2.5D sprite depth for Godot 4.x
// Adds a soft drop-shadow offset and a rim/outline whose strength
// scales with z_height. Works on AnimatedSprite2D / Sprite2D.

// --- Z height (world elevation) ---
uniform float z_height : hint_range(0.0, 128.0) = 0.0;
uniform float max_z : hint_range(1.0, 256.0) = 64.0;

// --- Drop shadow ---
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.45);
uniform vec2 shadow_offset : hint_range(-32.0, 32.0) = vec2(3.0, 6.0);
uniform float shadow_softness : hint_range(0.0, 1.0) = 0.5;
uniform float shadow_scale_with_height : hint_range(0.0, 2.0) = 0.8;

// --- Outline ---
uniform vec4 outline_color : source_color = vec4(1.0, 0.95, 0.55, 1.0);
uniform float outline_width : hint_range(0.0, 4.0) = 1.2;
uniform float outline_threshold : hint_range(0.0, 1.0) = 0.3;
uniform float outline_height_fade : hint_range(0.0, 1.0) = 0.6;

// --- Height lift (fake perspective) ---
uniform float height_lift_factor : hint_range(0.0, 2.0) = 1.0;
uniform float squash_at_peak : hint_range(0.0, 0.5) = 0.08;

varying vec2 base_uv;

void vertex() {
	float t = clamp(z_height / max_z, 0.0, 1.0);
	// Lift sprite upward to simulate elevation (negative Y is up)
	VERTEX.y -= z_height * height_lift_factor;
	// Subtle squash to sell jump arc
	float squash = 1.0 - t * squash_at_peak;
	VERTEX.x *= mix(1.0, 1.0 + squash_at_peak * 0.5, t);
	VERTEX.y *= mix(1.0, squash, t);
	base_uv = UV;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float h = clamp(z_height / max_z, 0.0, 1.0);

	// ---- Drop shadow (sample offset UV) ----
	vec2 shadow_uv = UV - shadow_offset * TEXTURE_PIXEL_SIZE * (1.0 + h * shadow_scale_with_height);
	vec4 shadow_tex = texture(TEXTURE, shadow_uv);
	float shadow_alpha = shadow_tex.a * shadow_color.a * (0.35 + h * 0.65);
	// Soften shadow for higher elevations (penumbra)
	shadow_alpha *= mix(1.0, 0.6, shadow_softness * h);

	// ---- Outline (edge detection via alpha neighbors) ----
	float outline_alpha = 0.0;
	if (outline_width > 0.01) {
		vec2 px = TEXTURE_PIXEL_SIZE * outline_width;
		float a0 = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
		float a1 = texture(TEXTURE, UV + vec2(-px.x, 0.0)).a;
		float a2 = texture(TEXTURE, UV + vec2(0.0, px.y)).a;
		float a3 = texture(TEXTURE, UV + vec2(0.0, -px.y)).a;
		float a4 = texture(TEXTURE, UV + vec2(px.x, px.y)).a;
		float a5 = texture(TEXTURE, UV + vec2(-px.x, px.y)).a;
		float a6 = texture(TEXTURE, UV + vec2(px.x, -px.y)).a;
		float a7 = texture(TEXTURE, UV + vec2(-px.x, -px.y)).a;
		float neighbor = max(max(max(a0, a1), max(a2, a3)), max(max(a4, a5), max(a6, a7)));
		// Outline appears where neighbor has alpha but center is transparent/edge
		float edge = clamp((neighbor - tex.a) * 4.0, 0.0, 1.0);
		// Only show outline above threshold, stronger with height
		float height_mod = mix(1.0 - outline_height_fade, 1.0, h);
		outline_alpha = edge * step(outline_threshold, neighbor) * height_mod;
		// Taper outline by original alpha edge
		if (tex.a > 0.5) outline_alpha *= 0.0;
	}

	vec3 col = tex.rgb;
	float alpha = tex.a;

	// Composite: shadow behind, then outline, then sprite on top
	// Blend shadow where sprite is transparent
	vec3 shadow_composite = mix(col, shadow_color.rgb, shadow_alpha * (1.0 - tex.a));
	// Slight shadow tint under opaque pixels too (contact shadow)
	col = mix(col, col * 0.85, shadow_alpha * tex.a * 0.3);

	if (outline_alpha > 0.01) {
		col = mix(col, outline_color.rgb, outline_alpha);
		alpha = max(alpha, outline_alpha);
		// Shadow still shows outside outline
		col = mix(shadow_composite, col, alpha);
	} else if (shadow_alpha > 0.01 && tex.a < 0.01) {
		col = shadow_color.rgb;
		alpha = shadow_alpha;
	}

	// Subtle height-based brightness (higher = slightly brighter / rim)
	col += vec3(h * 0.06);

	COLOR = vec4(col, alpha);
}
