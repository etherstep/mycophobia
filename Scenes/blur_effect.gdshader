shader_type canvas_item;

uniform float blur_radius : hint_range(0.0, 10.0, 0.1) = 2.0;

void fragment() {
	vec4 result = vec4(0.0);
	float total_weight = 0.0;

	vec2 pixel = TEXTURE_PIXEL_SIZE * blur_radius;

	for (int x = -4; x <= 4; x++) {
		for (int y = -4; y <= 4; y++) {
			float distance_sq = float(x * x + y * y);

			// Gaussian weighting
			float weight = exp(-distance_sq / 8.0);

			vec2 offset = vec2(float(x), float(y)) * pixel;

			result += texture(TEXTURE, UV + offset) * weight;
			total_weight += weight;
		}
	}

	COLOR = result / total_weight;
}