uniform float iTime;
uniform float qTime;
uniform vec2 iMouse, iResolution;
uniform vec3 lightPos, RayOrigin;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001

#define S smoothstep

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float Hash21(vec2 p) {
    p = fract(p*vec2(123.34,233.53));
    p += dot(p, p+23.234);
    return fract(p.x*p.y);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float sdBox2(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float sdSphere(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.));//+min(max(p.x, max(p.y, p.z)), 0.);
}

float GetDist3(vec3 p) {
    float r1 = 1., r2 = .2;
    float d = sdSphere(p, vec3(1.5));
    //d = sdBox2(p, vec3(1));

    d = length(vec2(length(p.xz) - r1, p.y)) - r2;
    vec2 cp = vec2(length(p.xz) - r1, p.y);
    float a = atan(p.x, p.z);
    cp *= Rot(a * qTime);
    cp.y = abs(cp.y) - .3;
    d = length(cp) - r2;
    
    return d;
}

float GetDist2(vec3 p) {
    float r1 = 1., r2 = .2;
    float d = sdBox(p, vec3(1));
    //d = sdBox2(p, vec3(1));

    d = length(vec2(length(p.xz) - r1, p.y)) - r2;
    vec2 cp = vec2(length(p.xz) - r1, p.y);
    float a = atan(p.x, p.z);
    cp *= Rot(a * qTime);
    cp.y = abs(cp.y) - .3;
    d = length(cp) - r2;
    
    return d;
}

float GetDist(vec3 p) {
    float r1 = 1., r2 = .2;
    float d = sdBox(p, vec3(1, 2, 0.1));

    //d = sdBox2(p, vec3(1));

    /*
     *d = length(vec2(length(p.xz) - r1, p.y)) - r2;
     *vec2 cp = vec2(length(p.xz) - r1, p.y);
     *float a = atan(p.x, p.z);
     *cp *= Rot(a * qTime);
     *cp.y = abs(cp.y) - .3;
     *d = length(cp) - r2;
     */
    
    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}

float RayMarch2(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist2(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}

float RayMarch3(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist3(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

vec3 m1(vec2 uv, vec3 ro, vec3 rd) {
    float d = RayMarch(ro, rd);
    vec3 col = vec3(0.);
    
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        
        //float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        float dif = dot(n, normalize(lightPos))*.5+.5;
        col.r += dif;  
    }
    return col;
}

vec3 m2(vec2 uv, vec3 ro, vec3 rd) {
    float d = RayMarch2(ro, rd);
    vec3 col = vec3(0.);
    
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        
        //float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        float dif = dot(n, normalize(lightPos))*.5+.5;
        col += dif;  
    }

    return col;
}

vec3 m3(vec2 uv, vec3 ro, vec3 rd) {
    float d = RayMarch3(ro, rd);
    vec3 col = vec3(0.);
    
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        
        //float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        float dif = dot(n, normalize(lightPos))*.5+.5;
        col.r += dif;  
    }

    return col;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = (screen_coords - .5 * love_ScreenSize.xy) / love_ScreenSize.y;
    vec2 m = iMouse.xy/iResolution.xy;
    
    vec3 col = vec3(0);
    
    //vec3 ro = vec3(0, 3, -3);
    vec3 ro = RayOrigin;
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0), 1.);

    col += m1(uv, ro, rd);
    //col += m2(uv, ro, rd);
    //col += m3(uv, ro, rd);

    col = pow(col, vec3(.4545));	// gamma correction
    
    return vec4(col,1.0);
}

