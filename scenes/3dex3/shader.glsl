uniform mat4 view;
uniform mat4 model;

#ifdef VERTEX
vec4 position(mat4 projection, vec4 vertex) {
	return view * model * vertex;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
	vec4 texturecolor = Texel(texture, texture_coords);
	return color * texturecolor;
}
#endif
