shader_type canvas_item;
// Textured dirt with depth gradient, soil strata and a scorched crater.
uniform sampler2D dirt_tex : repeat_enable, filter_linear_mipmap;
uniform vec4 top_col : source_color = vec4(1.3, 0.95, 0.8, 1.0);
uniform vec4 bot_col : source_color = vec4(0.32, 0.16, 0.36, 1.0);
uniform float y_top = 440.0;
uniform float y_bot = 720.0;
uniform vec2 crater = vec2(790.0, 566.0);
varying vec2 wp;

void vertex() { wp = VERTEX; }

void fragment() {
	vec3 tex = texture(dirt_tex, wp * 0.0030).rgb;
	float t = clamp((wp.y - y_top) / (y_bot - y_top), 0.0, 1.0);
	vec3 col = tex * mix(top_col.rgb, bot_col.rgb, pow(t, 0.8));
	float band = sin(wp.y * 0.085 + sin(wp.x * 0.011) * 2.6 + sin(wp.x * 0.034) * 0.7);
	col *= 1.0 - 0.16 * smoothstep(0.55, 1.0, band);
	float b2 = sin(wp.y * 0.21 + sin(wp.x * 0.02) * 3.0 + 1.7);
	col = mix(col, col * vec3(1.25, 1.1, 0.9), 0.10 * smoothstep(0.7, 1.0, b2));
	vec2 dc = (wp - crater) / vec2(78.0, 52.0);
	float scorch = exp(-dot(dc, dc));
	col = mix(col, vec3(0.10, 0.045, 0.11), 0.85 * scorch);
	COLOR = vec4(col, 1.0);
}
