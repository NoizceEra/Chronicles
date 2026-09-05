shader_type canvas_item;

// height_fog.gdshader — 2.5D height fog for Godot 4.x
// Darkens / fogs lower tiles based on world Y to sell depth.
// Assign to TileMap / ground Sprite2D layers or a full-screen ColorRect
// over the World. Uses SCREEN_UV or world position via FRAGCOORD.

uniform vec4 fog_color : source_color = vec4(0.08, 0.12, 0.22, 1.0);
uniform float fog_start_y : hint_range(0.0, 2000.0) = 560.0;
uniform float fog_end_y : hint_range(0.0, 3000.0) = 1280.0;
uniform float fog_intensity : hint_range(0.0, 1.0) = 0.55;
uniform float darken_strength : hint_range(0.0, 1.0) = 0.35;
uniform float fog_curve : hint_range(0.5, 4.0) = 1.6;
// Optional: use UV.y instead of world position (for tiled sprites without global coords)
uniform bool use_uv_y = false;
// Adds subtle vertical gradient even above fog_start_y
uniform float ambient_falloff : hint_range(0.0, 1.0) = 0.2;

// If you want world-space, set this from GDScript each frame:
//   material.set_shader_parameter("world_origin_y", global_position.y)
uniform float world_origin_y : hint_range(-2000.0, 3000.0) = 0.0;
uniform float world_scale_y : hint_range(0.1, 10.0) = 1.0;

varying vec2 world_uv;

void vertex() {
	world_uv = VERTEX;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 col = tex.rgb;

	// Compute height factor t in [0,1] — 0 = high / clear, 1 = low / foggy
	float h;
	if (use_uv_y) {
		h = UV.y;
	} else {
		// Approximate world Y from vertex position + uniform offset.
		// For TileMap/Sprite2D batches, world_uv tracks local vertex; add world_origin_y.
		float world_y = world_uv.y + world_origin_y;
		// Also factor screen position for full-screen quad usage
		// Mix local and screen so both placements work.
		world_y = mix(world_y, (FRAGCOORD.y * world_scale_y), 0.0);
		// Normalize between fog_start_y and fog_end_y
		h = clamp((world_y - fog_start_y) / max(fog_end_y - fog_start_y, 1.0), 0.0, 1.0);
		h = pow(h, fog_curve);
	}

	// Darken lower areas (height-based AO)
	float darken = h * darken_strength;
	col = mix(col, col * 0.55, darken);

	// Fog blend — lerp toward fog_color
	float fog = h * fog_intensity;
	// Keep original alpha; fog affects color only
	col = mix(col, fog_color.rgb, fog);

	// Subtle ambient falloff: slightly desaturate / lift with height inverse
	if (ambient_falloff > 0.0) {
		float height_factor = 1.0 - h;
		float lift = height_factor * ambient_falloff * 0.08;
		col += vec3(lift);
	}

	COLOR = vec4(col, tex.a);
	// Preserve translucency for tiles with alpha
	COLOR.a = tex.a;
}
