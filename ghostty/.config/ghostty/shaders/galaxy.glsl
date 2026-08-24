// Subtle purple galaxy backdrop.
//
// Ghostty custom shaders are post-process, not a layer behind the text:
// iChannel0 holds the already-rendered terminal, so the nebula is masked out
// wherever a pixel is bright enough to be a glyph or the cursor. Tune the knobs
// below; everything else is shape, not intensity.

#define NEBULA_STRENGTH 0.28   // peak glow added to the background
#define CLOUD_COVERAGE  0.18   // lower = cloud confined to fewer, smaller patches
#define FILAMENT_DEPTH  0.90   // how hard the fine layer breaks up flat areas
#define STAR_STRENGTH   0.42   // brightness of the sparse stars
#define STAR_RARITY     0.955  // higher = fewer stars (fraction of cells rejected)
#define CENTER_GLOW     0.20   // how much nebula survives mid-screen (0 = none)
#define EDGE_BAND       0.30   // width of the glowing border, in units of screen height
#define VOID_DEPTH      0.50   // how far the empty regions darken the background
#define CENTER_SHADE    0.50   // black tint over the middle, for legibility
#define DRIFT_SPEED     0.012  // how fast the clouds churn
#define BASE_TINT vec3(0.008, 0.003, 0.018)  // barely-there wash; keep low for deep blacks

float hash21(vec2 p) {
    p = fract(p * vec2(233.34, 851.73));
    p += dot(p, p + 23.45);
    return fract(p.x * p.y);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Normalised to ~0..1; the amplitudes sum to 0.96875, so divide it back out.
float fbm(vec2 p) {
    float sum = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        sum += amp * vnoise(p);
        p = p * 2.03 + 17.1;
        amp *= 0.5;
    }
    return sum * 1.0323;
}

// A seed that changes once a day. iDate is (year, month, day, seconds-in-day);
// hashing only the date part keeps it rock steady for the whole session — using
// the seconds component would make the sky race. If Ghostty ever leaves iDate
// zeroed, this degrades to a fixed offset rather than breaking.
vec2 daySeed() {
    float d = iDate.z + iDate.y * 31.0 + iDate.x * 372.0;
    return vec2(hash21(vec2(d, 7.3)), hash21(vec2(d, 19.1))) * 64.0;
}

// Sparse twinkling stars on a jittered grid: one candidate per cell, most
// cells rejected so they stay rare rather than reading as noise.
float stars(vec2 p) {
    vec2 cell = floor(p);
    float seed = hash21(cell);
    if (seed < STAR_RARITY) return 0.0;
    vec2 jitter = (vec2(hash21(cell + 3.1), hash21(cell + 7.7)) - 0.5) * 0.7;
    float d = length(fract(p) - 0.5 - jitter);

    // Phase and rate come from hashes independent of `seed`. Using seed here
    // synced every star: the rarity test only admits seed > STAR_RARITY, so it
    // spans ~0.045 and offsets the whole sky by barely 2 radians. Independent
    // hashes give a full 2*pi spread, and a per-star rate keeps them from ever
    // drifting back into step.
    float phase = hash21(cell + 11.3) * 6.2831853;
    float rate  = 0.8 + 1.6 * hash21(cell + 19.7);
    float mag   = 0.45 + 0.55 * hash21(cell + 29.1);
    float twinkle = 0.55 + 0.45 * sin(iTime * rate + phase);

    return smoothstep(0.12, 0.0, d) * twinkle * mag;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p  = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);

    float t = iTime * DRIFT_SPEED;

    // The seed offsets only where the noise is SAMPLED. The framing below reads
    // from screen position alone, so a new seed reshapes the clouds while the
    // edge-heavy, faint-centre composition stays put.
    vec2 seed = daySeed();

    // Two layers drifting apart so the clouds churn instead of sliding.
    float n1 = fbm(p * 2.6 + vec2(t, t * 0.6) + seed);
    float n2 = fbm(p * 4.7 - vec2(t * 1.4, t * 0.9) + 4.2 + seed * 1.37);
    float field = n1 * 0.62 + n2 * 0.38;

    // A third, much coarser layer decides WHERE cloud is allowed, so the gaps
    // between patches read as deliberate voids rather than merely dimmer.
    float region = smoothstep(0.30, 0.68,
                              fbm(p * 1.15 + vec2(t * 0.5, -t * 0.35) + seed * 0.63));

    // region shifts the threshold instead of scaling the result. Multiplying two
    // shaped smoothsteps together is what flattened this before: each averages
    // well under 0.5, so the product never climbed out of the floor. As a
    // threshold it places the cloud without dimming it — cores reach ~1.0 while
    // void regions demand noise the field almost never produces.
    // Coverage and brightness are independent: CLOUD_COVERAGE sets how easily a
    // patch qualifies as cloud at all, NEBULA_STRENGTH sets how bright it burns.
    float lo = mix(0.60, CLOUD_COVERAGE, region);

    // Ramp widened from 0.34: the narrower window pinned density at exactly 1.0
    // across large areas, and a plateau clips away every bit of internal detail,
    // which is what read as flat.
    float density = smoothstep(lo, lo + 0.44, field);

    // Fine filaments. Two cheap noise taps rather than a fourth fbm — this only
    // needs to break up plateaus, not define shape. Applied multiplicatively so
    // it carves texture INTO saturated regions instead of merely adding on top.
    float detail = 0.6 * vnoise(p * 9.0 - vec2(t * 0.8, t * 1.1) + seed * 2.1)
                 + 0.4 * vnoise(p * 17.0 + vec2(t * 1.3, -t * 0.7) + seed * 3.4);
    density = clamp(density * (1.0 - FILAMENT_DEPTH * 0.5 + FILAMENT_DEPTH * detail),
                    0.0, 1.0);

    // Frame the window: distance to the nearest edge, measured in units of screen
    // height so the band is the same pixel thickness on all four sides. A radial
    // vignette can't do this — length(p) hits ~1.0 at the left and right edges
    // but only ~0.45 at top and bottom, so it reads as an ellipse, not a frame.
    vec2 e = min(uv, 1.0 - uv);
    e.x *= iResolution.x / iResolution.y;
    float frame = 1.0 - smoothstep(0.03, EDGE_BAND, min(e.x, e.y));
    density *= CENTER_GLOW + (1.0 - CENTER_GLOW) * frame;

    // Kept bright enough that density and NEBULA_STRENGTH are the only things
    // scaling the result — a dark palette here is what made it invisible before.
    vec3 violet = vec3(0.40, 0.16, 0.72);
    vec3 orchid = vec3(0.66, 0.38, 0.92);
    vec3 nebula = mix(violet, orchid, smoothstep(0.55, 1.0, density));

    vec3 glow = BASE_TINT;
    glow += nebula * density * NEBULA_STRENGTH;
    // Stars read brightest through the voids, dimmed where cloud sits in front.
    glow += vec3(0.78, 0.72, 0.98) * stars(p * 34.0 + seed * 2.0) * STAR_STRENGTH
            * (0.45 + 0.55 * (1.0 - density));

    vec4 term = texture(iChannel0, uv);
    float lum = dot(term.rgb, vec3(0.299, 0.587, 0.114));
    float mask = 1.0 - smoothstep(0.02, 0.22, lum);  // 1 = background, 0 = glyph

    // Additive glow alone can never go below the theme background, so pull the
    // background itself down in the voids to get blacks deeper than the theme's.
    vec3 lit = term.rgb * (1.0 - VOID_DEPTH * (1.0 - density) * mask);
    lit += glow * mask;

    // Legibility vignette: tint the middle toward black and release it outward.
    // Keyed to the same `frame` the nebula uses, so the dark core and the bright
    // rim are one gradient rather than two vignettes fighting each other. Scaled
    // by `mask`, so it never dims the glyphs themselves.
    float shade = CENTER_SHADE * (1.0 - frame);
    lit *= 1.0 - shade * mask;

    fragColor = vec4(lit, term.a);
}
