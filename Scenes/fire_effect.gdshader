
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never,
	blend_mix;

uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform float pixel_size : hint_range(0.005, 0.1) = 0.015;
uniform float fire_alpha : hint_range(0.0, 1.0) = 0.95;
uniform float flicker_strength : hint_range(0.0, 0.5) = 0.15;

uniform vec4 base_color : source_color =
	vec4(0.9, 0.12, 0.015, 1.0);
uniform vec4 top_color : source_color =
	vec4(0.4, 0.35, 0.2, 1.0);
uniform vec4 spark_color : source_color =
	vec4(1.0, 0.7, 0.1, 1.0);
uniform vec4 smoke_color : source_color =
	vec4(0.07, 0.065, 0.06, 1.0);

uniform float hue_shift : hint_range(-1.0, 1.0) = 0.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float brightness : hint_range(0.2, 4.0) = 1.5;

uniform float fire_shift : hint_range(0.0, 0.5) = 0.15;
uniform float fire_frequency : hint_range(1.0, 10.0) = 5.0;
uniform float fire_height : hint_range(0.1, 2.0) = 0.8;
uniform float fire_width : hint_range(0.05, 1.0) = 0.45;

uniform float spark_count : hint_range(1.0, 24.0) = 8.0;
uniform float spark_size : hint_range(0.005, 0.1) = 0.025;
uniform float spark_speed : hint_range(0.1, 3.0) = 1.0;

uniform float smoke_amount : hint_range(0.0, 1.0) = 0.3;
uniform float smoke_size : hint_range(0.03, 0.5) = 0.18;
uniform float wind : hint_range(-1.0, 1.0) = 0.0;

uniform float edge_softness : hint_range(0.01, 0.5) = 0.12;
uniform float emission_strength : hint_range(0.0, 5.0) = 2.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)))
		* 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x),
		mix(c, d, f.x), f.y);
}

vec3 rgb_to_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0,
		2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz),
		vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r),
		vec4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;

	return vec3(
		abs(q.w - q.y) / (6.0 * d + e) + q.z,
		d / (q.x + e),
		q.x
	);
}

vec3 hsv_to_rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0,
		1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx,
		clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;

	// Center the coordinates and make the flame rise.
	vec2 p = (uv - vec2(0.5, 0.0));
	p.x += wind * p.y * 0.3;

	// Animated turbulence.
	float n = noise(vec2(
		p.x * 9.0 + t * 0.4,
		p.y * 5.0 - t * fire_frequency
	));

	float wobble = (n - 0.5) * fire_shift;
	float x = abs(p.x + wobble);

	// Narrower toward the tip.
	float width = fire_width * (1.0 - uv.y * 0.8);
	float body = 1.0 - smoothstep(
		width * (1.0 - edge_softness),
		width,
		x
	);

	float bottom = smoothstep(0.0, 0.12, uv.y);
	float tip = 1.0 - smoothstep(0.72, 1.0, uv.y);
	float flame = body * bottom * tip;

	float turbulence = noise(
		uv * 12.0 + vec2(t * 0.4, -t * 2.0)
	);
	flame *= mix(0.65, 1.2, turbulence);

	// Hot core and orange outer flame.
	float core = 1.0 - smoothstep(
		0.0, width * 0.8, x
	);
	vec3 fire = mix(base_color.rgb,
		vec3(1.0, 0.72, 0.12), core);

	fire = mix(fire, vec3(1.0, 0.95, 0.65),
		core * core * 0.6);

	// Sparks rise through the flame.
	float sparks = 0.0;
	for (int i = 0; i < 12; i++) {
		if (float(i) >= spark_count) {
			break;
		}

		float id = float(i);
		float seed = hash(vec2(id, 7.13));
		float phase = fract(t * spark_speed
			+ seed * 7.0);

		vec2 center = vec2(
			(seed - 0.5) * fire_width
				+ wind * phase * 0.2,
			phase * fire_height
		);

		float d = length(p - center);
		float s = 1.0 - smoothstep(
			spark_size * 0.2,
			spark_size,
			d
		);

		sparks += s * (1.0 - phase);
	}

	// Diffuse smoke near the upper flame.
	float smoke_noise = noise(
		uv * 7.0 + vec2(wind * t, -t * 0.25)
	);

	float smoke_shape = smoothstep(
		0.3, 0.8, uv.y
	) * (1.0 - smoothstep(0.85, 1.0, uv.y));

	float smoke = smoke_shape * smoke_amount
		* smoke_noise
		* exp(-abs(p.x) * 3.0);

	vec3 color = fire * flame;
	color += spark_color.rgb * sparks * 1.5;
	color = mix(color, smoke_color.rgb,
		clamp(smoke * 0.65, 0.0, 0.65));

	color = max(color, vec3(0.0));

	vec3 hsv = rgb_to_hsv(color);
	hsv.x = fract(hsv.x + hue_shift);
	hsv.y = clamp(hsv.y * saturation, 0.0, 1.0);
	color = hsv_to_rgb(hsv);

	float flicker = 1.0
		+ (noise(vec2(t * 8.0, 3.7)) - 0.5)
		* flicker_strength;

	float alpha = max(flame, sparks * 0.8);
	alpha = max(alpha, smoke * 0.5);
	alpha *= fire_alpha;

	ALBEDO = color * flicker;
	EMISSION = color * flicker * emission_strength;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
