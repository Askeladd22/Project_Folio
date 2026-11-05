// Manuscript-specific dice material, paired with unmodified lib/g3d/g3d.vert.
// Normals are already in world space: the physics bodies rotate the vertices.
// mode 1 = unlit, 2 = normals, 3 = diffuse, 4 = warm ivory + soft specular.
extern int debugMode;
extern vec3 lightDirection;
extern vec3 fillDirection;
extern vec3 viewDirection;
extern vec3 materialTint;
extern float ambientStrength;
extern float keyStrength;
extern float fillStrength;
extern float specularStrength;
extern float specularExponent;
extern vec2 pipTexel;
extern float pipReliefStrength;
extern float boneSurface;
extern float boneSeed;
extern int pipValue;
varying vec4 worldPosition;

varying vec3 vertexNormal;


float bone_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bone_noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(bone_hash(cell), bone_hash(cell + vec2(1.0, 0.0)), f.x),
               mix(bone_hash(cell + vec2(0.0, 1.0)),
                   bone_hash(cell + vec2(1.0, 1.0)), f.x), f.y);
}

vec2 nearer_pip(vec2 a, vec2 b) {
    return dot(a, a) < dot(b, b) ? a : b;
}

// Every value uses the standard layout. UV orientation follows the physical face.
vec2 pip_offset(vec2 uv) {
    vec2 offset = vec2(10.0);
    if (pipValue == 1 || pipValue == 3 || pipValue == 5)
        offset = uv - vec2(0.5);
    if (pipValue >= 2) {
        offset = nearer_pip(offset, uv - vec2(0.25, 0.25));
        offset = nearer_pip(offset, uv - vec2(0.75, 0.75));
    }
    if (pipValue >= 4) {
        offset = nearer_pip(offset, uv - vec2(0.25, 0.75));
        offset = nearer_pip(offset, uv - vec2(0.75, 0.25));
    }
    if (pipValue == 6) {
        offset = nearer_pip(offset, uv - vec2(0.25, 0.5));
        offset = nearer_pip(offset, uv - vec2(0.75, 0.5));
    }
    return offset;
}

vec3 aged_bone(vec2 uv, float distanceToPip) {
    vec2 seed = vec2(boneSeed * 3.17, boneSeed * 5.43);
    float mottling = bone_noise(uv * 5.0 + seed) - 0.5;
    float grain = bone_noise(uv * vec2(85.0, 15.0) + seed) - 0.5;
    float pores = smoothstep(0.92, 0.995, bone_hash(floor(uv * 145.0) + seed));
    float variation = sin(boneSeed * 1.7) * 0.018;
    vec3 bone = vec3(0.94, 0.87, 0.74) +
                vec3(mottling * 0.065 + grain * 0.012 + variation);
    bone -= vec3(0.07, 0.06, 0.04) * pores;
    float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    float wear = 1.0 - smoothstep(0.0, 0.12, edge);
    bone = mix(bone, vec3(0.73, 0.57, 0.37), wear * 0.10);
    float aa = max(fwidth(distanceToPip), 0.001);
    float ring = 1.0 - smoothstep(0.006, 0.009 + aa,
                                abs(distanceToPip - 0.072));
    float dish = 1.0 - smoothstep(0.045, 0.064, distanceToPip);
    float hole = 1.0 - smoothstep(0.019 - aa, 0.027 + aa, distanceToPip);
    bone = mix(bone, bone * vec3(0.92, 0.89, 0.84), dish * 0.35);
    bone = mix(bone, vec3(0.34, 0.22, 0.12), ring * 0.90);
    return mix(bone, vec3(0.15, 0.095, 0.045), hole);
}

vec3 engraved_normal(vec3 normal, vec2 uv, vec2 offset) {
    float distanceToPip = length(offset);
    float t = (distanceToPip - 0.072) / 0.012;
    float slope = 0.16 * t * exp(-t * t);
    slope += 0.20 * smoothstep(0.012, 0.022, distanceToPip) *
             (1.0 - smoothstep(0.022, 0.037, distanceToPip));
    vec2 gradient = offset / max(distanceToPip, 0.001) * slope;
    vec3 dx = dFdx(worldPosition.xyz);
    vec3 dy = dFdy(worldPosition.xyz);
    vec2 du = dFdx(uv);
    vec2 dv = dFdy(uv);
    float determinant = du.x * dv.y - du.y * dv.x;
    if (abs(determinant) < 0.0000001) return normal;
    vec3 tangent = normalize((dx * dv.y - dy * du.y) / determinant);
    vec3 bitangent = normalize((dy * du.x - dx * dv.x) / determinant);
    return normalize(normal - tangent * gradient.x - bitangent * gradient.y);
}

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screenCoords) {
    // LÖVE's 'color' already contains VertexColor and graphics color.
    // Do not multiply by g3d.vert's vertexColor again.
    vec4 albedo = Texel(texture, uv) * color;
    if (debugMode == 1) {
        return albedo; // reference: inspect original pip textures without lighting
    }

    vec3 n = normalize(vertexNormal);
    if (debugMode == 4 && boneSurface > 0.5) {
        vec2 offset = pip_offset(uv);
        albedo = vec4(aged_bone(uv, length(offset)), 1.0) * color;
        if (pipValue > 0) n = engraved_normal(n, uv, offset);
    }
    if (debugMode == 2) {
        return vec4(n * 0.5 + 0.5, albedo.a);
    }

    float key = max(dot(n, normalize(lightDirection)), 0.0);
    float fill = max(dot(n, normalize(fillDirection)), 0.0);
    float lighting = clamp(ambientStrength + keyStrength * key + fillStrength * fill, 0.0, 1.15);
    vec3 base = albedo.rgb * materialTint;
    vec3 lit = base * lighting;

    if (debugMode == 4 && key > 0.0) {
        vec3 reflected = reflect(-normalize(lightDirection), n);
        float spec = pow(max(dot(reflected, normalize(viewDirection)), 0.0), specularExponent);
        // Warm and deliberately subdued: bone/ivory rather than glossy plastic.
        // Black pips are matte recessed pigment, not glossy black beads.
        // Suppress the ivory reflection on dark texels instead of
        // adding a white highlight on top of an ink-black pip.
        float ivoryReflectance = smoothstep(0.12, 0.72,
            dot(albedo.rgb, vec3(0.299, 0.587, 0.114)));
        lit += vec3(1.0, 0.90, 0.70) *
               (specularStrength * spec * key * ivoryReflectance);
    }

    if (debugMode == 4 && pipTexel.x > 0.0 && pipTexel.y > 0.0 && boneSurface < 0.5) {
        // Approximate the tiny bevel of an engraved pip from the texture
        // contrast. Never change the pip shape, UV coordinates or score.
        // Four additional texture reads are intentionally ivory-mode only.
        vec2 du = vec2(pipTexel.x, 0.0);
        vec2 dv = vec2(0.0, pipTexel.y);
        vec3 weights = vec3(0.299, 0.587, 0.114);
        float leftLight  = dot(Texel(texture, uv-du).rgb, weights);
        float rightLight = dot(Texel(texture, uv+du).rgb, weights);
        float upLight    = dot(Texel(texture, uv-dv).rgb, weights);
        float downLight  = dot(Texel(texture, uv+dv).rgb, weights);
        float relief = clamp((leftLight-rightLight)*0.48 +
                             (upLight-downLight)*0.70, -1.0, 1.0);
        lit += vec3(1.0, 0.85, 0.66) * (pipReliefStrength * relief);
    }
    return vec4(clamp(lit, 0.0, 1.0), albedo.a);
}
