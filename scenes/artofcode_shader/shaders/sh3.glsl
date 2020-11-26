uniform float iTime;
uniform float iCount;
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    vec3 col = vec3(0.5);
    vec2 gv = fract(uv * iCount) - .5;
    //float d = length(gv);
    float m = 0.;

    for (float y = -1.; y <= 1.; y++) {
        for (float x = -1.; x <= 1.; x++) {
            vec2 offs = vec2(x, y);
            float d = length(gv + offs);
            //float r = 0.1;
            //m += smoothstep(r, r * 0.9, d);
            float r = mix(0.3, 0.5, sin(iTime + length(uv) * 39.) * 0.5 + 0.5);
            m += smoothstep(r, r * 0.9, d);
        }
    }

    col.rg = gv;
    col += m;
    //col += smoothstep(0.1, 0.11, uv.x);
    return vec4(col, 1.0);
}

