shader_type spatial;
render_mode cull_back;

void fragment() {
	float latitude = UV.y;
	float warp = sin(UV.x * 45.0 + latitude * 35.0) * 0.006 + sin(UV.x * 90.0 - latitude * 70.0) * 0.002;
	float bands = sin((latitude + warp) * 100.0) * 0.5 + 0.5;
	float broad = sin(latitude * 31.0) * 0.5 + 0.5;
	vec3 cloud = mix(vec3(0.45, 0.32, 0.24), vec3(0.86, 0.77, 0.62), smoothstep(0.15, 0.85, bands));
	cloud = mix(cloud, vec3(0.76, 0.65, 0.49), broad * 0.25);
	vec2 storm = vec2((UV.x - 0.62) * 3.7, (latitude - 0.61) * 12.0);
	cloud = mix(cloud, vec3(0.65, 0.32, 0.19), (1.0 - smoothstep(0.6, 1.0, length(storm))) * 0.7);
	ALBEDO = cloud;
	ROUGHNESS = 1.0;
}
