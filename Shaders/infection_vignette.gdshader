shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 pixel = SCREEN_PIXEL_SIZE * 2.8 * strength;
	vec3 blurred = vec3(0.0);
	float total = 0.0;
	for (int x = -3; x <= 3; x++) {
		for (int y = -3; y <= 3; y++) {
			float weight = exp(-float(x * x + y * y) / 5.0);
			blurred += texture(screen_texture, SCREEN_UV + vec2(float(x), float(y)) * pixel).rgb * weight;
			total += weight;
		}
	}
	blurred /= max(total, 0.001);
	vec2 centered = UV * 2.0 - 1.0;
	float vignette = smoothstep(0.2, 1.15, dot(centered, centered));
	vec3 tinted = mix(blurred, blurred * vec3(1.2, 0.28, 0.22) + vec3(0.45, 0.02, 0.02), vignette);
	COLOR = vec4(tinted, strength);
}
