#ifdef PIXEL

uniform float time;
uniform float alpha;
uniform vec2 screen;

const vec3 parchmentA = vec3(0.11, 0.07, 0.035);
const vec3 parchmentB = vec3(0.18, 0.11, 0.05);
const vec3 emberTint = vec3(0.34, 0.20, 0.07);

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; ++i) {
        v += a * noise(p);
        p = p * 2.0 + vec2(11.3, -4.7);
        a *= 0.5;
    }
    return v;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 safeScreen = max(screen, vec2(1.0, 1.0));
    vec2 uv = screen_coords / safeScreen;

    float coarse = fbm(uv * vec2(5.0, 8.0) + vec2(time * 0.05, -time * 0.03));
    float fine = fbm(uv * vec2(20.0, 14.0) + vec2(-time * 0.12, time * 0.06));
    float grain = hash(screen_coords * 1.5 + time * 35.0);

    float vignette = smoothstep(1.15, 0.22, distance(uv, vec2(0.5, 0.5)));

    float flickerLow = 0.94 + 0.05 * sin(time * 5.8 + coarse * 5.5);
    float flickerHigh = 0.02 * sin(time * 14.0 + uv.x * 12.0 + fine * 8.0);
    float flicker = clamp(flickerLow + flickerHigh, 0.84, 1.05);

    float emberWave = smoothstep(0.65, 1.0, 0.5 + 0.5 * sin(uv.x * 8.5 - uv.y * 3.5 + time * 0.9 + fine * 3.0));
    vec3 parchment = mix(parchmentA, parchmentB, coarse * 0.9 + fine * 0.1);
    parchment = mix(parchment, emberTint, emberWave * 0.16);
    parchment += (grain - 0.5) * 0.035;
    parchment *= vignette * flicker;
    parchment = clamp(parchment, 0.0, 1.0);

    return vec4(parchment, clamp(alpha, 0.0, 1.0));
}

#endif
