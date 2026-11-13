shader_type canvas_item;
// Luminance -> two-colour gradient map; recolours any CC0 sprite into the shared palette.
uniform vec4 dark_col : source_color = vec4(0.2, 0.1, 0.4, 1.0);
uniform vec4 light_col : source_color = vec4(0.8, 0.4, 0.6, 1.0);
uniform float lo = 0.15;
uniform float hi = 0.95;
uniform vec4 haze_col : source_color = vec4(1.0, 0.6, 0.5, 1.0);
uniform float haze_amt = 0.0;
uniform float haze_from = 0.4;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float t = clamp((l - lo) / (hi - lo), 0.0, 1.0);
	vec3 g = mix(dark_col.rgb, light_col.rgb, t);
	g = mix(g, haze_col.rgb, haze_amt * smoothstep(haze_from, 1.0, UV.y));
	COLOR = vec4(g, c.a * COLOR.a);
}
