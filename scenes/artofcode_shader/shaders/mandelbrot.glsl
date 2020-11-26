uniform vec2 iMouse;
uniform Image tex;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    //vec4 texturecolor = Texel(tex, texture_coords);
    //return texturecolor * color;
    vec2 uv = (screen_coords.xy - .5 * love_ScreenSize.xy) / love_ScreenSize.y;
    vec2 m = iMouse.xy / love_ScreenSize.xy;
    float zoom = pow(10., -m.x * 3.);
    vec2 c = uv * zoom * 3.;
    c += vec2(-.69955, .37999);

    vec2 z = vec2(0.);
    float iter = 0.;

    const float max_iter = 100.;
    for (float i = 0.; i < max_iter; ++i) {
        z = vec2(z.x * z.x - z.y * z.y, 2. * z.x * z.y) + c;

        if (length(z) > 2.) break;
        ++iter;
    }

    float f = iter / max_iter;
    //vec3 col = vec3(f);
    vec3 col = texture2D(tex, vec2(f, .5)).rgb;
    return vec4(col, 1.0);
}


