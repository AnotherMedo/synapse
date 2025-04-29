shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

vec4 draw_ripple(vec2 screen_pixel_size, vec4 coord, float time, vec4 color){
	// Conversion
	vec2 i_resolution = 1.0 / screen_pixel_size;
	vec2 frag_coord = vec2(coord.r, coord.g);
	// Centering uv
	vec2 uv = frag_coord / i_resolution * 2.0 - 1.0;
	// Normalization
	uv.r *= i_resolution.r / i_resolution.g;
	// Distance between pixel and center
	float d = length(uv);
	// float time_loop = cos(TIME);
	d = sin(d * 10.0 + time * 2.0) / 1.5;
	d = abs(d);
	d = smoothstep(0.8, 0.1, d);
	d = 0.2 / d;
	return vec4(d * color.r, d * color.g, color.b, color.a);
}

vec4 draw_circle(vec2 screen_pixel_size, vec4 coord, float time, vec4 base_color){
	// Conversion
	vec2 i_resolution = 1.0 / screen_pixel_size;
	vec2 frag_coord = vec2(coord.r, coord.g);
	// Centering uv
	vec2 uv = frag_coord / i_resolution * 2.0 - 1.0;
	// Normalization
	uv.r *= i_resolution.r / i_resolution.g;
	// Distance between pixel and center
	float d = length(uv);
	// float time_loop = cos(TIME);
	d = sin(d * 1.0 + time * 2.0) / 1.7;
	d = abs(d);
	d = smoothstep(0.7, 0.3, d);
	d = 0.2 / d;
	return vec4(d * base_color.r, d * base_color.g, base_color.b, base_color.a);
}

void fragment() {
	vec4 col_1 = vec4(0.5, 0.2, 0.0, 1.0);
	vec4 col_2 = vec4(1.0, 0.0, 0.0, 1.0);
	vec4 color = draw_ripple(SCREEN_PIXEL_SIZE, FRAGCOORD, TIME, col_1);
	//color += draw_circle(SCREEN_PIXEL_SIZE, FRAGCOORD, TIME, col_1);
	color += draw_circle(SCREEN_PIXEL_SIZE, FRAGCOORD, -TIME, col_1);
	COLOR = color;
}
