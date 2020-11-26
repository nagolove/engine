extern float iTime;
extern bool useFast;

vec2 N22(vec2 p) {
    vec3 a = fract(p.yxy * vec3(98.2, 24.2, 9014.3));
    a += dot(a, a - 141.34145);
    return fract(vec2(a.x * a.y, a.z * a.y));
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = (2. * screen_coords - love_ScreenSize.xy) / love_ScreenSize.y;
    //vec2 uv = (screen_coords - .5 * love_ScreenSize.xy) / love_ScreenSize.y;
    float m = 0;
    float t = iTime;
    float minDist = 100.;
    float cellIndex = 0.;
    vec3 col = vec3(0.);

    if (!useFast) {
        for (float i = 0.; i < 1050.; i++) {
            vec2 n = N22(vec2(i));
            vec2 p = sin(n * t);
            float d = length(uv - p);
            m += smoothstep(0.2, 0.1, d);

            if (d < minDist) {
                minDist = d;
                cellIndex = i;
            }
        }
        col = vec3(minDist);
    } else {
        uv *= 3.;
        vec2 gv = fract(uv) - .5;
        vec2 id = floor(uv);
        vec2 cellID = vec2(0.);
        //col.rg = gv;
        //col.rg = id * .1;
        for (float y = -1.; y <= 1.; y++) {
            for (float x = -1.; x <= 1.; x++) {
                vec2 offs = vec2(x, y);
                vec2 n = N22(id + offs);
                vec2 p = offs + sin(n * t) * .5;
                p -= gv;
                float ed = length(gv - p);
                float md = abs(p.x) + abs(p.y);
                float d = mix(ed, md, .5);

                if (d < minDist) {
                    minDist = d;
                    cellID = id + offs;
                }

            }
        }
        col = vec3(minDist);
        //col.rg = cellID * .1;
    }

    //col = vec3(minDist);
    //vec3 col = vec3(cellIndex / 50);
    return vec4(col, 1.);
}

