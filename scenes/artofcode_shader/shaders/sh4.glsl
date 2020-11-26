#define S smoothstep

float Feather(vec2 p) {
    //float d = length(p - vec2(clamp(p.x, -0., .3), clamp(p.y, -0., 0.3)));
    float d = length(p - vec2(0., clamp(p.y, -0.35, 0.35)));
    float r = mix(.1, .01, S(-0.3, .3, p.y));
    float m = S(.001, .0, d - r);
    float x = .9 * abs(p.x)/r;
    float wave = (1. - x) * sqrt(x) + x * (1. - sqrt(1.-x));
    float y = (p.y - wave*.2) * 40.;
    float id = floor(y);
    float n = fract(sin(id*564.)*845.);
    float shade = mix(.3, .1, n);

    float strand = S(.1, 0., abs(fract(y) - .5) - .3);

    d = length(p - vec2(0., clamp(p.y, -0.45, 0.1)));
    float stem = S(.01, .0, d);

    return strand * m * shade + stem;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    //vec2 uv = (screen_coords - .5 * love_ScreenSize.xy) / love_ScreenSize.xy;
    vec2 uv = (screen_coords - .5 * love_ScreenSize.xy) / love_ScreenSize.xy;
    vec3 col = vec3(.0);
    col += Feather(uv);
    return vec4(col, 1.);
}

