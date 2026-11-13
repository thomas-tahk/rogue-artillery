shader_type canvas_item;
void fragment() {
	vec2 uv = UV - 0.5;
	float v = smoothstep(0.30, 0.95, length(uv * vec2(1.0, 1.2)));
	COLOR = vec4(0.10, 0.03, 0.22, v * 0.6);
}
