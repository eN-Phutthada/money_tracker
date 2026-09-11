#include <flutter/runtime_effect.glsl>

// Uniforms from Flutter (Float uniforms)
uniform vec2 uResolution;
uniform vec2 uMouse;
uniform float uEffectSize;        // Scale / bevel width factor
uniform float uBlurIntensity;     // Blur intensity
uniform float uDispersionStrength;// Chromatic dispersion (RGB spectrum split)
uniform float uRefractionStrength;// Optical lens refraction power

out vec4 fragColor;

// Exact 2D Signed Distance Function for a Rounded Rectangle (Capsule Pill)
float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 res = uResolution;
    // Auto-detect and adapt if FlutterFragCoord() is in physical screen pixels
    if (fragCoord.x > res.x * 1.3 || fragCoord.y > res.y * 1.3) {
        float scale = max(fragCoord.x / res.x, fragCoord.y / res.y);
        res *= scale;
    }

    vec2 center = res * 0.5;
    vec2 p = fragCoord - center;

    // Capsule pill dimensions (Dock height: 66, cornerRadius: 28)
    float cornerRadius = min(res.y * 0.48, 28.0 * (res.y / max(uResolution.y, 1.0)));
    vec2 halfSize = res * 0.5;

    // Distance to dock edge: d < 0 is inside the glass dock, d > 0 is outside
    float d = sdRoundedBox(p, halfSize - vec2(1.0), cornerRadius);

    // If outside the capsule pill, output 100% transparent (NO square corners / NO black artifacts!)
    if (d > 1.0) {
        fragColor = vec4(0.0);
        return;
    }

    // --- 1. Liquid Meniscus Curvature & Surface Normal ---
    float bevelWidth = clamp(cornerRadius * 0.85, 14.0, 26.0);
    float distFromEdge = max(-d, 0.0);

    // Normalized depth profile of liquid glass: 1.0 at center, drops to 0.0 at edge
    float edgeFactor = clamp(distFromEdge / bevelWidth, 0.0, 1.0);
    // Smooth convex meniscus profile (quarter ellipse curvature)
    float heightProfile = sqrt(clamp(1.0 - pow(1.0 - edgeFactor, 2.0), 0.0, 1.0));

    // Direction vector pointing outward towards the nearest boundary
    vec2 edgeDir;
    vec2 pAbs = abs(p);
    vec2 q = pAbs - (halfSize - vec2(cornerRadius));
    if (q.x > 0.0 && q.y > 0.0) {
        edgeDir = normalize(q) * sign(p);
    } else if (q.x > q.y) {
        edgeDir = vec2(sign(p.x), 0.0);
    } else {
        edgeDir = vec2(0.0, sign(p.y));
    }

    // Normal gradient slope: steepest near the edge (meniscus rim)
    float slope = (1.0 - edgeFactor) / max(heightProfile, 0.10);
    slope = clamp(slope, 0.0, 3.2);

    // --- 2. Apple iOS 26 Prismatic Chromatic Dispersion ---
    // Spectral rainbow along the meniscus rim (Cauchy's dispersion model)
    float dispFactor = (uDispersionStrength > 0.01 ? uDispersionStrength : 0.55);
    float rainbowPhase = (1.0 - edgeFactor) * 0.85;
    vec3 rainbowSpectrum = 0.5 + 0.5 * cos(6.28318 * (vec3(0.0, 0.33, 0.67) + rainbowPhase));
    float rainbowIntensity = smoothstep(0.1, 1.0, slope / 2.5) * (1.0 - edgeFactor) * dispFactor;
    vec3 dispersionLight = rainbowSpectrum * (rainbowIntensity * 0.28);

    // --- 3. iOS 26 Caustic Specular Highlights & Directional Lighting ---
    // Ambient overhead light direction
    vec3 lightDir = normalize(vec3(-0.15, -0.90, 0.40));
    vec3 normal = normalize(vec3(edgeDir * slope * 0.45, 1.0));
    float specular = pow(max(dot(reflect(vec3(0.0, 0.0, -1.0), normal), lightDir), 0.0), 28.0);

    // Razor-sharp 1.5px outer glass rim caustic (Apple hairline reflection)
    float outerHairline = smoothstep(1.5, 0.0, abs(d));

    // Inner bevel highlight where meniscus curve transitions into flat body
    float innerBevel = smoothstep(3.5, 1.0, distFromEdge) * (1.0 - smoothstep(1.0, 0.0, distFromEdge));

    // Top edge light accentuation (Light falls from top)
    float topLight = clamp(-edgeDir.y * 0.60 + 0.40, 0.0, 1.0);

    // Subtle liquid surface sheen & Fresnel effect
    float fresnel = pow(1.0 - heightProfile, 2.5) * 0.22;
    float surfaceSheen = (1.0 - heightProfile) * 0.06 + specular * 0.45 * topLight + fresnel * 0.15;

    // --- 4. Optical Lighting Composition ---
    vec3 finalRgb = vec3(1.0) * (outerHairline * 0.45 * topLight)
                  + vec3(1.0) * (innerBevel * 0.20 * topLight)
                  + vec3(1.0) * (surfaceSheen * 0.18)
                  + dispersionLight;

    // Alpha mask: transparent body with luminous highlights on rim & caustics
    float alpha = clamp(
        outerHairline * 0.65 * topLight +
        innerBevel * 0.25 * topLight +
        surfaceSheen * 0.20 +
        rainbowIntensity * 0.35,
        0.0, 0.90
    );

    // Antialiased border blend at the very edge of the pill (d = 0)
    float edgeAntialias = smoothstep(0.5, -0.5, d);
    float totalAlpha = alpha * edgeAntialias;
    fragColor = vec4(finalRgb * totalAlpha, totalAlpha);
}