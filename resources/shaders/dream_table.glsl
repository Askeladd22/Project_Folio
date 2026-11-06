extern vec2 tableCenter;
extern vec2 tableHalf;
varying vec4 worldPosition;
varying vec3 vertexNormal;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screenCoords) {
    vec4 stone = Texel(texture, uv) * color;
    vec2 local = (worldPosition.xy - tableCenter) / tableHalf;
    float radius = max(abs(local.x), abs(local.y));
    float center = 1.0 - smoothstep(0.34, 0.78, radius);
    float upward = smoothstep(0.35, 0.82, normalize(vertexNormal).z);
    float top = 1.0 - smoothstep(0.02, 0.18, abs(worldPosition.z));
    float field = center * upward * top;

    // Keep the carved border, but let the dice read against a calmer stone center.
    vec3 warmStone = vec3(0.70, 0.62, 0.51);
    stone.rgb = mix(stone.rgb, warmStone, field * 0.58);
    float candle = 1.0 + field * 0.18;
    stone.rgb = min(vec3(1.0), stone.rgb * candle);
    float support = smoothstep(0.35, 1.35, -worldPosition.z);
    stone.rgb = mix(stone.rgb, vec3(0.32, 0.19, 0.11), support * 0.32);
    return stone;
}