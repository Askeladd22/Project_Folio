extern float dreamTime;

vec4 effect(vec4 tint, Image texture, vec2 uv, vec2 screenCoords) {
    float time = dreamTime;
    vec2 warped = uv;
    float symmetry = 1.0 - smoothstep(0.0, 0.50, abs(uv.x - 0.5));
    warped.x += sin(uv.y * 34.0 + time * 1.3) * symmetry * 0.0045;
    warped.y += sin(uv.x * 17.0 - time * 0.7) * symmetry * 0.0025;
    warped.x += sin(uv.y * 4.2 + time * 0.28) * 0.006;
    warped.y += sin(uv.x * 3.4 - time * 0.22) * 0.0035;

    vec4 room = Texel(texture, warped) * tint;
    vec2 edge = (uv - vec2(0.5)) * vec2(1.0, 0.88);
    float vignette = smoothstep(0.24, 0.76, length(edge)) * 0.48;

    vec2 moonPos = (uv - vec2(0.11, 0.26)) * vec2(2.3, 1.5);
    float moonHaze = exp(-dot(moonPos, moonPos) * 1.5) * 0.27;
    vec2 pressPos = (uv - vec2(0.91, 0.42)) * vec2(2.0, 1.4);
    float pressHaze = exp(-dot(pressPos, pressPos) * 1.3) * 0.24;
    vec2 dreamPos = (uv - vec2(0.53, 0.48)) * vec2(1.25, 1.8);
    float dreamHaze = exp(-dot(dreamPos, dreamPos) * 1.5) * 0.19;
    float breath = 0.84 + 0.16 * sin(time * 0.37);

    room.rgb = mix(room.rgb, vec3(0.38, 0.49, 0.68), moonHaze * breath);
    room.rgb = mix(room.rgb, vec3(0.88, 0.52, 0.30), pressHaze * breath);
    room.rgb = mix(room.rgb, vec3(0.66, 0.58, 0.52), dreamHaze * breath);
    room.rgb *= 1.0 - vignette;
    return room;
}