extern float shadowPass;
extern vec2 shadowTexel;
extern vec3 inkTone;
extern vec3 paperTone;

vec4 effect(vec4 tint, Image texture, vec2 uv, vec2 screenCoords) {
    vec4 print = Texel(texture, uv) * tint;
    if (shadowPass > 0.5) {
        vec2 blur = shadowTexel * 7.0;
        float coverage = Texel(texture, uv).a * 0.25;
        coverage += (Texel(texture, uv + vec2(blur.x, 0.0)).a +
                     Texel(texture, uv - vec2(blur.x, 0.0)).a +
                     Texel(texture, uv + vec2(0.0, blur.y)).a +
                     Texel(texture, uv - vec2(0.0, blur.y)).a) * 0.125;
        coverage += (Texel(texture, uv + blur).a +
                     Texel(texture, uv - blur).a +
                     Texel(texture, uv + vec2(blur.x, -blur.y)).a +
                     Texel(texture, uv + vec2(-blur.x, blur.y)).a) * 0.0625;
        return vec4(tint.rgb, tint.a * coverage);
    }

    float luminance = dot(print.rgb, vec3(0.299, 0.587, 0.114));
    float inkCoverage = smoothstep(0.12, 0.88, luminance);
    vec3 duotone = mix(inkTone, paperTone, inkCoverage);
    return vec4(duotone, print.a);
}
