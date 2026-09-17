shader_type canvas_item;

uniform float white_tolerance : hint_range(0.0, 0.3) = 0.12;

bool is_background_white(vec3 c) {
	return (c.r > 0.88 && c.g > 0.88 && c.b > 0.88);
}

bool is_purple_watermark(vec3 c) {
	// 보라색 글자 특징: Blue와 Red가 Green보다 높고 푸르스름한 보라빛
	float diff_bg = c.b - c.g;
	float diff_rg = c.r - c.g;
	bool dark_purple = (diff_bg > 0.14 && diff_rg > 0.08 && c.b > 0.40);
	bool bright_purple = (c.b > 0.60 && c.r > 0.50 && diff_bg > 0.08 && diff_rg > 0.05);
	return dark_purple || bright_purple;
}

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE;
	vec4 col = texture(TEXTURE, UV);
	
	// 1. 흰색 네모 배경 완벽 투명화
	if (is_background_white(col.rgb)) {
		discard;
	}
	
	// 2. 보라색 워터마크 글씨 감지 및 지우기
	if (is_purple_watermark(col.rgb)) {
		// 주변 4방향 픽셀 샘플링
		vec4 left = texture(TEXTURE, UV + vec2(-ps.x * 2.5, 0.0));
		vec4 right = texture(TEXTURE, UV + vec2(ps.x * 2.5, 0.0));
		vec4 up = texture(TEXTURE, UV + vec2(0.0, -ps.y * 2.5));
		vec4 down = texture(TEXTURE, UV + vec2(0.0, ps.y * 2.5));
		
		int white_count = 0;
		if (is_background_white(left.rgb)) white_count++;
		if (is_background_white(right.rgb)) white_count++;
		if (is_background_white(up.rgb)) white_count++;
		if (is_background_white(down.rgb)) white_count++;
		
		// 캐릭터 외부/경계의 글자는 투명하게 날림
		if (white_count >= 2) {
			discard;
		} else {
			// 캐릭터 내부를 지나는 글자는 보라색이 아닌 이웃 캐릭터 픽셀로 감쪽같이 대체
			if (!is_purple_watermark(left.rgb) && !is_background_white(left.rgb)) {
				col.rgb = left.rgb;
			} else if (!is_purple_watermark(right.rgb) && !is_background_white(right.rgb)) {
				col.rgb = right.rgb;
			} else if (!is_purple_watermark(up.rgb) && !is_background_white(up.rgb)) {
				col.rgb = up.rgb;
			} else if (!is_purple_watermark(down.rgb) && !is_background_white(down.rgb)) {
				col.rgb = down.rgb;
			} else {
				discard;
			}
		}
	}
	
	COLOR = col;
}
