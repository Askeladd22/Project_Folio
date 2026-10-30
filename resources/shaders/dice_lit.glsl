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

varying vec3 vertexNormal;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screenCoords) {
    // LÖVE's 'color' already contains VertexColor and graphics color.
    // Do not multiply by g3d.vert's vertexColor again.
    vec4 albedo = Texel(texture, uv) * color;
    if (debugMode == 1) {
        return albedo; // reference: inspect original pip textures without lighting
    }

    vec3 n = normalize(vertexNormal);
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
        lit += vec3(1.0, 0.90, 0.70) * (specularStrength * spec * key);
    }
    return vec4(clamp(lit, 0.0, 1.0), albedo.a);
}
