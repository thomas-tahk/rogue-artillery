shader_type canvas_item;
// Kenney particle PNGs are opaque white-on-black; this turns luminance into alpha for normal-blend use.
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	float l = max(t.r, max(t.g, t.b));
	COLOR = vec4(COLOR.rgb * (0.55 + 0.6 * l), COLOR.a * smoothstep(0.02, 0.85, l));
}
