shader_type canvas_item;

// Outline-Preserving HSV + 7 Skin-Tint Protagonist Customizer Shader for Godot 4
uniform float hue_shift_deg : hint_range(-180.0, 180.0) = 0.0;
uniform float sat_mult : hint_range(0.4, 1.7) = 1.0;
uniform float val_mult : hint_range(0.75, 1.3) = 1.0;
uniform int skin_mode : hint_range(0, 6) = 0; // 0=none, 1=warm, 2=tan, 3=pale, 4=drow, 5=goblin, 6=aqua

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)) * 360.0, d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec3 h_norm = vec3(mod(c.x, 360.0) / 360.0, c.y, c.z);
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(h_norm.xxx + K.xyz) * 6.0 - K.www);
	return h_norm.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), h_norm.y);
}

vec3 get_skin_target(int m) {
	if (m == 1) return vec3(22.0, 0.28, 0.96);
	if (m == 2) return vec3(26.0, 0.44, 0.80);
	if (m == 3) return vec3(320.0, 0.08, 0.96);
	if (m == 4) return vec3(255.0, 0.24, 0.72);
	if (m == 5) return vec3(46.0, 0.68, 0.92);
	if (m == 6) return vec3(172.0, 0.34, 0.88);
	return vec3(0.0);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Preserve soft ground shadow (< 0.63 alpha) and crisp 2.5D dark ink outlines!
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	if (tex.a > 0.62 && lum >= 0.266) {
		vec3 hsv = rgb2hsv(tex.rgb);
		// Preserve white eye sclera
		if (!(hsv.y < 0.09 && hsv.z > 0.85)) {
			bool is_warm_skin = (hsv.x >= 10.0 && hsv.x <= 42.0 && hsv.y >= 0.12 && hsv.y <= 0.48 && hsv.z >= 0.55);
			if (skin_mode > 0 && is_warm_skin) {
				vec3 st = get_skin_target(skin_mode);
				hsv.x = st.x;
				hsv.y = min(0.95, hsv.y * 0.35 + st.y * 0.65);
				hsv.z = min(0.98, hsv.z * 0.55 + st.z * 0.45);
			} else {
				hsv.x = mod(hsv.x + hue_shift_deg + 360.0, 360.0);
				hsv.y = min(0.96, hsv.y * sat_mult);
				hsv.z = clamp(hsv.z * val_mult, 0.12, 0.97);
			}
			tex.rgb = hsv2rgb(hsv);
		}
	}
	COLOR = tex * COLOR;
}
