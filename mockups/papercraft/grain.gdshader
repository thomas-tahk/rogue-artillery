shader_type canvas_item;
uniform sampler2D noise : repeat_enable;
uniform sampler2D fibre : repeat_enable;
void fragment() {
	float n = texture(noise, UV * 3.0).r;
	float f = texture(fibre, UV * vec2(2.0, 5.0)).r;
	float a = abs(n - 0.5) * 0.30 + abs(f - 0.5) * 0.14;
	vec2 d = UV - 0.5;
	float v = smoothstep(0.35, 0.85, length(d * vec2(1.2, 1.0)));
	COLOR = vec4(0.30, 0.16, 0.06, clamp(a + v * 0.22, 0.0, 1.0));
}
