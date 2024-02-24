shader_type canvas_item;

uniform vec4 line_color  = vec4(0.0, 0.3, 1.0, 0.6);
uniform float line_thickness : hint_range(0, 10) = 15.0;

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
	
	float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
	outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
	outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
	outline = min(outline, 1.0);
	
	vec4 color = texture(TEXTURE, UV);
	COLOR = mix(color, line_color, outline - color.a);
}

//shader_type canvas_item;
//
//uniform sampler2D color : source_color;
//uniform vec2 offset;
//uniform float shadow_alpha;
//
//void fragment() {
	//vec4 c = texture(color, UV);
	//if (c.a < 1.0) {
		//vec4 cr = texture(color, UV - offset);
		//if (cr.a > 0.0) {
			//c.rgb = clamp(c.rgb * c.a + vec3(0.0, 0.0, 0.0) * cr.a * shadow_alpha * (1.0 - c.a), vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
			//c.a = clamp(c.a + cr.a * shadow_alpha * (1.0 - c.a), 0.0, 1.0);
		//}
	//}
		//
	//COLOR = c;
//}
