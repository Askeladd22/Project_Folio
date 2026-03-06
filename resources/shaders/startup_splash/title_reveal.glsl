#ifdef PIXEL

uniform float time;
uniform float alpha;
uniform vec2 screen;

const vec3 inkDry = vec3(0.10, 0.06, 0.035);
const vec3 inkMid = vec3(0.22, 0.13, 0.065);
const vec3 inkWet = vec3(0.38, 0.23, 0.11);

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
    for (int i = 0; i < 4; ++i) {
        v += a * noise(p);
        p = p * 2.05 + vec2(8.4, -6.7);
        a *= 0.5;
    }
    return v;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 safeScreen = max(screen, vec2(1.0, 1.0));
    vec2 uv = screen_coords / safeScreen;
    float paper = fbm(uv * vec2(9.0, 7.0) + vec2(time * 0.05, -time * 0.03));
    float detail = fbm(uv * vec2(22.0, 15.0) + vec2(time * 0.11, time * 0.07));
    float grain = hash(screen_coords * 1.6 + time * 36.0) - 0.5;

    // Simulated calligraphic stroke progression.
    float axis = uv.x * 1.05 + uv.y * 0.16;
    axis += (paper - 0.5) * 0.08;
    axis += 0.03 * sin(uv.y * 18.0 + time * 0.9);

    float progress = clamp(time * 0.52, 0.0, 1.08);
    float strokeDelta = progress - clamp(axis, 0.0, 1.0);

    float revealBody = smoothstep(-0.10, 0.00, strokeDelta);
    float revealSoft = smoothstep(-0.20, -0.04, strokeDelta) * 0.55;
    float reveal = clamp(revealBody + revealSoft, 0.0, 1.0);

    // Fresh nib highlight near advancing stroke tip.
    float tipBand = exp(-pow((strokeDelta - 0.01) * 26.0, 2.0));
    float freshTip = smoothstep(-0.02, 0.06, strokeDelta) * (1.0 - smoothstep(0.08, 0.20, strokeDelta));
    float dryMix = smoothstep(0.05, 0.35, strokeDelta);
    float wick = smoothstep(-0.18, 0.02, strokeDelta) * (0.85 + 0.15 * detail);

    vec3 ink = mix(inkWet, inkDry, dryMix);
    ink = mix(ink, inkMid, freshTip * 0.55);
    ink += vec3(tipBand * 0.10);
    ink *= mix(0.88, 1.0, wick);
    ink *= 0.92 + 0.08 * paper;
    ink += vec3(grain * 0.05);
    ink = clamp(ink, 0.0, 1.0);

    float outAlpha = clamp(alpha, 0.0, 1.0) * reveal * (0.90 + 0.10 * wick);
    return vec4(ink, outAlpha);
}

#endif
