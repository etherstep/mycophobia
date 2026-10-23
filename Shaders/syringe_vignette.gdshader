shader_type canvas_item;

uniform float inner_radius : hint_range(0.0, 1.0) = 0.2;
uniform float outer_radius : hint_range(0.0, 2.0) = 0.8;

uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0;   // How fast it pulses
uniform float pulse_amount : hint_range(0.0, 0.5) = 0.1;   // How far in/out it stretches

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
    float dist = distance(UV, vec2(0.5));
    
    float animated_outer = outer_radius + sin(TIME * pulse_speed) * pulse_amount;
    float vignette = smoothstep(inner_radius, animated_outer, dist);
    
    // 1. Calculate the shader's vignette color
    vec4 final_color = vec4(tex_color.rgb, tex_color.a * vignette);
    
    // 2. Multiply by COLOR so modulate / modulate.a in GDScript works again!
    COLOR = final_color * COLOR;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
