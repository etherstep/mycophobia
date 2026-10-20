shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D mask_tex : filter_linear, repeat_disable;
uniform vec4 smoke_color : source_color = vec4(0.82, 0.82, 0.82, 1.0);

void vertex() {
	mat4 world = mat4(
		normalize(INV_VIEW_MATRIX[0]),
		normalize(INV_VIEW_MATRIX[1]),
		normalize(INV_VIEW_MATRIX[2]),
		MODEL_MATRIX[3]
	);
	world = world * mat4(
		vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0),
		vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0),
		vec4(0.0, 0.0, 0.0, 1.0)
	);
	world = world * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0)
	);
	MODELVIEW_MATRIX = VIEW_MATRIX * world;
}

void fragment() {
	float lod = clamp(COLOR.r, 0.0, 1.0) * 8.0;
	float noise = textureLod(noise_tex, UV, lod).r;
	float mask = texture(mask_tex, UV).r;
	ALBEDO = smoke_color.rgb;
	ALPHA = noise * mask * COLOR.a;
}
