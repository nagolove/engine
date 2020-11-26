vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    //vec4 texturecolor = Texel(tex, texture_coords);
    //return texturecolor * color;
    vec2 uv = screen_coords / love_ScreenSize.xy;
    vec3 col = vec3(0.1);

    float d = 0.1;
    float m;

    //col += smoothstep(d, d + 0.1, uv.y) + smoothstep((0.8), (0.8) + 0.4, uv.y);

    //m = smoothstep(d, d + 0.1, uv.x);
    //col += m;

    d = 0.8;
    m = smoothstep(d, d + 0.1, uv.x);
    col += m;


    return vec4(col, 1.0);
}

