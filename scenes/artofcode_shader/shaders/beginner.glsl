
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    uv.y = 1 - uv.y;
    uv -= .5;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;
    float d = length(uv);
    d = smoothstep(0.1, 0.109, d);
    return vec4(vec3(d),1.0);
}

