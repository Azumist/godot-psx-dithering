//Original shader from https://github.com/jmickle66666666/PSX-Dither-Shader/blob/master/PSX%20Dither.shader
//Shadertoy version by László Matuska / @BitOfGold https://www.shadertoy.com/view/tlc3DM
//Ported to Godot by Azumist
shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D dither_pattern: hint_albedo;
uniform float screen_width = 512;
uniform float screen_height = 300;
uniform float color_depth = 32;

float channel_error(float col, float col_min, float col_max) {
	float range = abs(col_min - col_max);
	float a_range = abs(col - col_min);
	return a_range / range;
}

float dithered_channel(float error, vec2 dither_block_uv) {
	float pattern = texture(dither_pattern, dither_block_uv).r;
	if(error > pattern)
		return 1.0;
	else
		return 0.0;
}

vec3 rgb2yuv(vec3 rgb) {
	vec3 yuv;
	yuv.r = rgb.r * 0.2126 + 0.7152 * rgb.g + 0.0722 * rgb.b;
	yuv.g = (rgb.b - yuv.r) / 1.8556;
	yuv.b = (rgb.r - yuv.r) / 1.5748;
	
	yuv.gb += 0.5;
	
	return yuv;
}

vec3 yuv2rgb(vec3 yuv) {
	 yuv.gb -= 0.5;
	return vec3(
		yuv.r * 1.0 + yuv.g * 0.0 + yuv.b * 1.5748,
		yuv.r * 1.0 + yuv.g * -0.187324 + yuv.b * -0.468124,
		yuv.r * 1.0 + yuv.g * 1.8556 + yuv.b * 0.0);
}

vec3 dither_color(vec3 col, vec2 uv, float xres, float yres) {
	vec3 yuv = rgb2yuv(col);
    vec3 col1 = floor(yuv * color_depth) / color_depth;
    vec3 col2 = ceil(yuv * color_depth) / color_depth;
	
	// Calculate dither texture UV based on the input texture
    vec2 dither_block_uv = uv * vec2(xres / 8.0, yres / 8.0);
    yuv.x = mix(col1.x, col2.x, dithered_channel(channel_error(yuv.x, col1.x, col2.x), dither_block_uv));
    yuv.y = mix(col1.y, col2.y, dithered_channel(channel_error(yuv.y, col1.y, col2.y), dither_block_uv));
    yuv.z = mix(col1.z, col2.z, dithered_channel(channel_error(yuv.z, col1.z, col2.z), dither_block_uv));

	return yuv2rgb(yuv);
}

void fragment() {
	vec3 col = texture(TEXTURE, UV).rgb;
	col = dither_color(col, UV.xy, screen_width, screen_height);
	COLOR = vec4(col,1.0);
}