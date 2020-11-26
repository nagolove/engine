vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    //vec4 texturecolor = Texel(tex, texture_coords);
    //return texturecolor * color;
    vec2 uv = screen_coords / love_ScreenSize.xy;
    vec3 col = vec3(0.1);
    float m = smoothstep(0.4, 0.6, uv.x);
    col += m;
    return vec4(col, 1.0);
}

