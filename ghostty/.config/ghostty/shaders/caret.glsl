// Animated caret: the cursor drags a shrinking capsule from its previous cell to
// its current one. Runs as a second custom-shader pass, so iChannel0 here is the
// galaxy pass's output and the smear lands on top of the nebula.
//
// Ghostty gives us iPreviousCursor and iTimeCursorChange precisely for this —
// no frame-to-frame state needed, the whole animation is a function of how long
// ago the cursor moved.

#define TRAIL_DURATION  0.16   // seconds for the smear to fade out
#define TRAIL_STRENGTH  0.55   // brightness of the smear
#define TRAIL_SPREAD    0.06   // softness of the falloff (lower = wider halo)
#define TAIL_FALLOFF    1.8    // higher = tail fades away faster behind the caret
#define TAIL_MIN        0.04   // brightness left at the very tip of the tail
#define TAIL_PINCH      0.15   // tail thickness as a fraction of the head's

// Liquid warp. This one bends the image instead of lighting it: the sample
// coordinates are pushed along the comet's surface normal, so the nebula and
// glyphs behind the caret refract. Set WARP_AMOUNT to 0.0 for glow only.
#define WARP_AMOUNT     9.0    // peak displacement, in pixels
#define WARP_FALLOFF    0.045  // how fast the lens fades away from the comet edge
#define WARP_RIPPLE     0.55   // 0 = steady lens, 1 = fully oscillating
#define WARP_FREQ       0.10   // ripple wavelength (radians per pixel)
#define WARP_SPEED      9.0    // ripple travel speed
#define WARP_LOCAL      0.35   // warp scale for short moves (1.0 = same as a jump)

// Distance-aware morph. A one-cell move and a pane-to-pane jump should not look
// alike, so travel distance drives intensity, duration, and how hard it settles.
#define JUMP_NEAR       40.0   // px: at or below this, a move counts as local
#define JUMP_FAR        400.0  // px: at or above this, full pane-to-pane morph
#define JUMP_STRETCH    2.2    // duration multiplier at full jump
#define RETRACT_EASE    1.5    // >1 = tail lags, then snaps into the head
#define SETTLE_BULGE    0.30   // overshoot as the tail lands, then it settles
#define TRAIL_TINT vec3(0.62, 0.34, 0.92)  // purple, to match the nebula
#define TINT_MIX        0.60   // 0 = pure cursor colour, 1 = pure TRAIL_TINT

// Vertical anchor of the reported cursor rect, in units of its own height.
// +0.5 assumes iCurrentCursor.y is the rect's TOP edge, -0.5 its BOTTOM edge.
// Nudge by 0.25 if the smear still sits high or low: more negative = higher.
#define CURSOR_Y_ANCHOR -0.5

// Distance to the segment in .x, plus how far along it we are in .y (0 at `a`,
// 1 at `b`). The old version threw the parameter away, which is why the smear
// was a uniform bar — every pixel along the capsule got identical brightness.
vec2 sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return vec2(length(pa - ba * h), h);
}

vec2 cursorCenter(vec4 c) {
    return vec2(c.x + c.z * 0.5, c.y + c.w * CURSOR_Y_ANCHOR);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    if (iCursorVisible == 0) {
        fragColor = texture(iChannel0, uv);
        return;
    }

    vec2 cur = cursorCenter(iCurrentCursor);
    vec2 prv = cursorCenter(iPreviousCursor);

    // How far this move was, in pixels. Everything below scales off it so a jump
    // across panes morphs hard while stepping one cell stays almost unnoticed.
    float travel = length(cur - prv);
    float jump = smoothstep(JUMP_NEAR, JUMP_FAR, travel);

    // Long jumps get proportionally longer to resolve, which is what makes the
    // liquid read as heavy rather than just fast.
    float duration = TRAIL_DURATION * mix(1.0, JUMP_STRETCH, jump);

    float age = (iTime - iTimeCursorChange) / duration;
    if (age < 0.0 || age > 1.0) {
        fragColor = texture(iChannel0, uv);
        return;
    }
    float k = 1.0 - age;              // 1 the instant it moves, 0 when spent
    float ease = k * k;               // fade out fast, linger briefly

    // The tail is drawn from a point that travels toward the head, so the blob
    // physically retracts and lands instead of fading where it was. At age 1 the
    // capsule has collapsed onto the cursor and everything is back to normal.
    float retract = pow(age, RETRACT_EASE);
    vec2 tail = mix(prv, cur, retract);

    // Comet between the two cells: head at the caret, tail at the old position.
    // h runs 0 (tail) -> 1 (head), tapering thickness and brightness together so
    // the shape pinches and dims backwards instead of reading as a solid block.
    vec2 seg = sdSegment(fragCoord, tail, cur);
    float h = seg.y;

    // Bulge as the retracting tail slams into the head, easing out after.
    float settle = 1.0 + SETTLE_BULGE * jump * smoothstep(0.55, 1.0, age) * k;

    float taper = mix(TAIL_MIN, 1.0, pow(h, TAIL_FALLOFF));
    float thick = iCurrentCursor.w * 0.30 * k * settle
                * mix(TAIL_PINCH, 1.0, h) + 1.0;
    float d = seg.x - thick;
    float glow = exp(-max(d, 0.0) * TRAIL_SPREAD) * ease * taper;

    // Outward normal of the comet: from the nearest point on its axis to this
    // pixel. Displacing along it makes the distortion bulge around the shape
    // rather than shear the whole neighbourhood one direction.
    vec2 axis = tail + (cur - tail) * h;
    vec2 nrm = (fragCoord - axis) / max(seg.x, 1e-4);

    // Lens peaks at the comet's surface (d == 0) and decays outward and inward.
    // The sin term turns a static bulge into something that moves like liquid;
    // it swings negative, so the surface alternately pushes and pulls.
    float lens = exp(-abs(d) * WARP_FALLOFF);
    float ripple = sin(d * WARP_FREQ - age * WARP_SPEED);
    vec2 warp = nrm * lens * taper * ease
              * WARP_AMOUNT * mix(WARP_LOCAL, 1.0, jump)
              * mix(1.0, ripple, WARP_RIPPLE);

    // Warp in pixels, then convert; clamped so edge pixels can't sample outside.
    vec4 col = texture(iChannel0, clamp(uv + warp / iResolution.xy, 0.0, 1.0));

    vec3 tint = mix(iCurrentCursorColor.rgb, TRAIL_TINT, TINT_MIX);

    fragColor = vec4(col.rgb + tint * glow * TRAIL_STRENGTH, col.a);
}
