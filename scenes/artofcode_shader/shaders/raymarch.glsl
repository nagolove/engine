uniform float iTime;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST 0.1

float GetDist(vec3 p) {
    vec4 s = vec4(0., 1., 6., 1.);
    float sphereDist = length(p - s.xyz) - s.w;
    float planeDist = p.y;
    float d = min(sphereDist, planeDist);
    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float d0 = 0.;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d0;
        float dS = GetDist(p);
        d0 += dS;
        if (d0 > MAX_DIST || dS < SURF_DIST) break;
    }

    return d0;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(0.01, 0.);
    vec3 n = d - vec3(
            GetDist(p - e.xyy),
            GetDist(p - e.yxy),
            GetDist(p - e.yyx));
    return normalize(n);
}

float GetLight(vec3 p) {
    vec3 lightPos = vec3(0., 5., 6.);
    lightPos.xz += vec2(sin(iTime), cos(iTime));
    vec3 l = normalize(lightPos - p);
    vec3 n = GetNormal(p);
    return 1.;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = (screen_coords - .5 * love_ScreenSize.xy) / love_ScreenSize.y;
    vec3 col = vec3(0.);
    vec3 ro = vec3(0., 1., 0.); //ray origin
    vec3 rd = normalize(vec3(uv.x, uv.y, 1.)); // ray direction
    float d = RayMarch(ro, rd);
    vec3 p = ro + rd * d;
    float diffuse = GetLight(p);
    //d /= 10;
    //col = vec3(d);
    col = vec3(diffuse);
    col = GetNormal(p);
    return vec4(col, 1.);
}

