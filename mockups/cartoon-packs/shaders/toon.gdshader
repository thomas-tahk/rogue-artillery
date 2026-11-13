shader_type canvas_item;
// Adds what the flat Kenney tank art lacks: top-down shading, cool shadow side, warm rim light.
uniform vec4 rim_col : source_color = vec4(1.0, 0.78, 0.45, 1.0);
uniform vec2 light_dir = vec2(0.75, -0.65);
uniform float rim_px = 4.0;
uniform float rim_strength = 1.0;
uniform vec4 shade_col : source_color = vec4(0.55, 0.38, 0.62, 1.0);
uniform float shade_amt = 0.5;
uniform vec4 tint : source_color = vec4(1.0);
uniform float flip_x = 1.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * tint;
	vec2 d = normalize(light_dir) * vec2(flip_x, 1.0) * TEXTURE_PIXEL_SIZE * rim_px;
	float a1 = texture(TEXTURE, UV + d).a;
	float a2 = texture(TEXTURE, UV + d * 0.5).a;
	float edge = c.a * (1.0 - 0.5 * (a1 + a2));
	float g = smoothstep(0.15, 1.0, UV.y);
	vec3 rgb = mix(c.rgb, c.rgb * shade_col.rgb * 1.25, g * shade_amt);
	rgb = mix(vec3(dot(rgb, vec3(0.33))), rgb, 1.25);
	rgb = mix(rgb, rim_col.rgb, clamp(edge, 0.0, 1.0) * rim_strength);
	COLOR = vec4(rgb, c.a);
}
