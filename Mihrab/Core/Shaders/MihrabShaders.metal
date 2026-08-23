#include <metal_stdlib>
using namespace metal;

// Mihrab greens: forest 0.051/0.141/0.094 · abyss 0.027/0.071/0.051
// emerald 0.122/0.663/0.420 · mint 0.498/0.878/0.698 · sprout 0.722/0.961/0.839
// brass 0.788/0.635/0.294 · violet 0.165/0.129/0.251 · gold 0.910/0.769/0.463
//
// House rules for every motif in this file:
//   · Signature is always (position, color, time, halfSize) so the Swift side
//     can treat motifs interchangeably.
//   · Luminance stays low. These paint *behind* type: highlight energy is
//     capped so a card scrim can always win the contrast fight.
//   · Motion is slow. Nothing here should read as "activity" in peripheral
//     vision — it should read as breathing.

static inline float mihrabGrad(float2 position, float2 halfSize) {
    return clamp(position.y / max(2.0 * halfSize.y, 2.0), 0.0, 1.0);
}

/// Soft radial falloff from the centre of the drawn rect, 1 at the middle.
static inline float mihrabVignette(float2 position, float2 halfSize, float strength) {
    float2 d = (position - halfSize) / max(halfSize.y, 1.0);
    return clamp(1.0 - strength * length(d), 1.0 - strength, 1.0);
}

/// Cheap value hash for grain / bokeh seeds.
static inline float mihrabHash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

static inline float mihrabValueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = mihrabHash(i);
    float b = mihrabHash(i + float2(1.0, 0.0));
    float c = mihrabHash(i + float2(0.0, 1.0));
    float d = mihrabHash(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// MARK: - Emerald Silk

[[ stitchable ]] half4 emeraldSilk(float2 position, half4 color, float time, float2 halfSize) {
    float g = mihrabGrad(position, halfSize);
    float3 base = mix(float3(0.051, 0.141, 0.094), float3(0.027, 0.071, 0.051), g);

    float2 p = position * 0.0062;
    float d = p.x * 0.82 - p.y * 0.57;
    float w1 = sin(d * 3.4 + time * 0.22 + sin(p.y * 1.2 + time * 0.11) * 0.8);
    float w2 = sin(d * 6.6 - time * 0.15 + p.x * 0.9);
    // Wider smoothstep window + higher exponent = fewer, softer bands.
    float sheen = pow(smoothstep(-0.75, 1.15, w1 * 0.70 + w2 * 0.30), 1.85);
    float fold = 0.52 + 0.16 * sin(p.x * 1.4 - time * 0.09);

    float3 silk = mix(float3(0.122, 0.663, 0.420), float3(0.498, 0.878, 0.698), 0.45 + 0.35 * w2);
    float3 bloom = float3(0.722, 0.961, 0.839) * sheen * sheen * 0.09;
    float3 lit = base + silk * sheen * fold * 0.46 + bloom;
    return half4(half3(lit * mihrabVignette(position, halfSize, 0.22)), color.a);
}

// MARK: - Mosque Caustics

[[ stitchable ]] half4 mosqueCaustics(float2 position, half4 color, float time, float2 halfSize) {
    float g = mihrabGrad(position, halfSize);
    float3 base = mix(float3(0.058, 0.152, 0.102), float3(0.027, 0.071, 0.051), g);

    float2 p = position * 0.014;
    float t = time * 0.17;
    float c1 = sin(p.x * 1.5 + sin(p.y * 1.1 + t) * 1.7 + t * 0.7);
    float c2 = sin(p.y * 1.3 - sin(p.x * 0.9 - t * 0.6) * 1.9 - t * 0.5);
    float c3 = sin((p.x + p.y) * 0.8 + t * 0.4);
    float cell = pow(clamp(c1 * c2 + c3 * 0.30, 0.0, 1.0), 2.1);

    float3 glass = float3(0.122, 0.663, 0.420);
    float3 mint = float3(0.498, 0.878, 0.698);
    float3 brass = float3(0.788, 0.635, 0.294);
    float3 lit = base + glass * cell * 0.42 + mint * cell * 0.14 + brass * cell * cell * 0.06;
    return half4(half3(lit * mihrabVignette(position, halfSize, 0.34)), color.a);
}

// MARK: - Aurora Veil

static inline float veilNoise(float2 p, float t) {
    float n = sin(p.x * 1.35 + t) * 0.55
            + sin(p.x * 3.10 - t * 0.62 + sin(p.y * 0.90 + t * 0.35) * 1.2) * 0.30
            + sin(p.x * 6.40 + t * 0.41) * 0.15;
    return n * 0.5 + 0.5;
}

[[ stitchable ]] half4 auroraVeil(float2 position, half4 color, float time, float2 halfSize) {
    float g = mihrabGrad(position, halfSize);
    float3 base = mix(float3(0.051, 0.141, 0.094), float3(0.027, 0.071, 0.051), g);

    float2 p = position / max(2.0 * halfSize.y, 2.0) * 3.4;
    float t = time * 0.15;
    float curtain = veilNoise(float2(p.x * 0.85, p.y), t);
    float curtain2 = veilNoise(float2(p.x * 1.70 + 3.1, p.y * 0.6), t * 0.80 + 1.7);
    float falloff = exp(-g * 1.75);
    float veil = pow(curtain * 0.62 + curtain2 * 0.38, 1.85) * falloff;

    float3 glow = mix(float3(0.498, 0.878, 0.698), float3(0.722, 0.961, 0.839), clamp(veil * 1.10, 0.0, 1.0));
    float3 mist = float3(0.122, 0.663, 0.420) * veil * 0.14;
    return half4(half3(base + glow * veil * 0.42 + mist), color.a);
}

// MARK: - Lantern Glow
//
// Fanous lamps breathing in a dark courtyard: a handful of large, heavily
// blurred bokeh discs that drift and pulse out of phase. No edges, no bands —
// this is the calmest motif and the safest one to place under long text.

static inline float lanternDisc(float2 uv, float2 centre, float radius, float softness) {
    float d = length(uv - centre) / max(radius, 0.001);
    return pow(1.0 - smoothstep(1.0 - softness, 1.0, d), 2.0);
}

[[ stitchable ]] half4 lanternGlow(float2 position, half4 color, float time, float2 halfSize) {
    float g = mihrabGrad(position, halfSize);
    float3 base = mix(float3(0.045, 0.126, 0.086), float3(0.024, 0.063, 0.046), g);

    // Normalise so the layout holds on any aspect ratio.
    float2 uv = (position - halfSize) / max(halfSize.y, 1.0);
    float t = time * 0.11;

    float3 lit = base;
    float warm = 0.0;
    float cool = 0.0;

    // Six lanterns on lazy Lissajous paths, each with its own breath period.
    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        float seed = fi * 1.6180339;
        float2 centre = float2(
            sin(t * (0.42 + 0.11 * fi) + seed * 2.1) * (0.55 + 0.18 * mihrabHash(float2(seed, 1.0))),
            cos(t * (0.31 + 0.09 * fi) + seed * 1.3) * 0.62
        );
        float radius = 0.34 + 0.20 * mihrabHash(float2(seed, 7.0));
        float breath = 0.62 + 0.38 * sin(t * 1.7 + seed * 3.3);
        float disc = lanternDisc(uv, centre, radius, 0.95) * breath;
        if (i % 2 == 0) { warm += disc; } else { cool += disc; }
    }

    float3 gold = float3(0.910, 0.769, 0.463);
    float3 mint = float3(0.498, 0.878, 0.698);
    lit += gold * clamp(warm, 0.0, 2.0) * 0.085;
    lit += mint * clamp(cool, 0.0, 2.0) * 0.070;

    // Whisper of grain so the bokeh never posterises into rings.
    float grain = (mihrabHash(floor(position * 0.9)) - 0.5) * 0.012;
    return half4(half3(clamp(lit + grain, 0.0, 1.0) * mihrabVignette(position, halfSize, 0.28)), color.a);
}

// MARK: - Still Ripple
//
// The surface of a şadırvan pool: concentric rings expanding from two drip
// points, damped hard with distance so the centre stays quiet.

static inline float rippleRings(float2 uv, float2 origin, float t, float speed, float freq) {
    float d = length(uv - origin);
    float wave = sin(d * freq - t * speed);
    float damp = exp(-d * 2.3) * smoothstep(0.0, 0.08, d);
    return wave * damp;
}

[[ stitchable ]] half4 stillRipple(float2 position, half4 color, float time, float2 halfSize) {
    float g = mihrabGrad(position, halfSize);
    float3 base = mix(float3(0.040, 0.116, 0.080), float3(0.024, 0.063, 0.046), g);

    float2 uv = (position - halfSize) / max(halfSize.y, 1.0);
    float t = time * 0.55;

    float2 dropA = float2(-0.28 + 0.06 * sin(t * 0.13), -0.18);
    float2 dropB = float2(0.34, 0.26 + 0.06 * cos(t * 0.11));

    float r = rippleRings(uv, dropA, t, 1.0, 15.0) * 0.62
            + rippleRings(uv, dropB, t * 0.83 + 2.4, 1.0, 11.0) * 0.38;

    // Crest highlight only — troughs stay in the base colour.
    float crest = pow(clamp(r, 0.0, 1.0), 1.6);
    float trough = pow(clamp(-r, 0.0, 1.0), 1.6);

    float3 sheen = float3(0.498, 0.878, 0.698);
    float3 deep = float3(0.020, 0.055, 0.042);
    float3 lit = base + sheen * crest * 0.16 - (base - deep) * trough * 0.45;

    // A slow, wide light shaft across the water.
    float shaft = exp(-pow((uv.x - sin(t * 0.06) * 0.4) * 1.4, 2.0)) * 0.05;
    lit += float3(0.788, 0.635, 0.294) * shaft;

    return half4(half3(clamp(lit, 0.0, 1.0) * mihrabVignette(position, halfSize, 0.30)), color.a);
}

// MARK: - Kufic Lattice
//
// An eight-point star (khatem/rub el hizb) tiling, drawn as hairlines only.
// The lattice is deliberately near-threshold: it should read as woven texture
// at arm's length, never as a graphic competing with the content above it.

/// Signed distance to an 8-pointed star = intersection of two rotated squares.
static inline float starLattice(float2 p) {
    float2 a = abs(p);
    float sq1 = max(a.x, a.y);                       // axis-aligned square
    float2 r = float2(a.x + a.y, a.x - a.y) * 0.7071; // 45° rotated square
    float sq2 = max(abs(r.x), abs(r.y));
    return max(sq1, sq2);
}

[[ stitchable ]] half4 kuficLattice(float2 position, half4 color, float time, float2 halfSize) {
    float g = mihrabGrad(position, halfSize);
    float3 base = mix(float3(0.047, 0.132, 0.090), float3(0.024, 0.063, 0.046), g);

    // Tile in normalised space so cell size is stable across screen and card.
    float scale = 9.0;
    float2 uv = position / max(2.0 * halfSize.y, 2.0) * scale;
    // Very slow parallax drift instead of rotation — keeps it meditative.
    uv += float2(sin(time * 0.028) * 0.35, time * 0.012);

    float2 cell = fract(uv) - 0.5;
    float star = starLattice(cell);

    // Two nested outlines: the star ring and a smaller inner ring.
    float ringA = 1.0 - smoothstep(0.005, 0.028, abs(star - 0.34));
    float ringB = 1.0 - smoothstep(0.004, 0.022, abs(star - 0.19));
    float node = 1.0 - smoothstep(0.0, 0.055, length(cell));

    // Fade the lattice by a soft noise field so it dissolves in places.
    float breathe = 0.55 + 0.45 * mihrabValueNoise(uv * 0.22 + float2(0.0, time * 0.02));

    float3 brass = float3(0.788, 0.635, 0.294);
    float3 mint = float3(0.498, 0.878, 0.698);
    float3 lit = base
        + brass * ringA * 0.085 * breathe
        + mint * ringB * 0.055 * breathe
        + brass * node * 0.070 * breathe;

    return half4(half3(clamp(lit, 0.0, 1.0) * mihrabVignette(position, halfSize, 0.32)), color.a);
}
