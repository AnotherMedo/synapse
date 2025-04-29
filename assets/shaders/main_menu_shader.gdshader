shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Conversion
	vec2 i_resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 frag_coord = vec2(FRAGCOORD.r, FRAGCOORD.g);
	// Centering uv
	vec2 uv = frag_coord / i_resolution * 2.0 - 1.0;
	// Normalization
	uv.r *= i_resolution.r / i_resolution.g;
	// Distance between pixel and center
	float d = length(uv);
	COLOR = vec4(d, d, 0, 1);
}

void main_image(out vec4 frag_color, in vec2 frag_coord){
	
}
