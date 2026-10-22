// ============================================================================
//  DNA DOUBLE HELIX  -  for the OpenRGB Effects Plugin  >  "Shaders" effect
//  Written in GLSL 1.10 (the plugin's default "#version 110"), so it runs as-is.
//
//  Inspired by WLED effect 152 "DNA" / 182 "DNA Spiral": two counter-phase sine
//  strands that cross each other - here with 3D depth shading and base-pair rungs.
//  ROTATING version: the strand in front is thicker, brighter and hides the one behind.
// ============================================================================

// ---- 1. YOUR MATRIX ---------------------------------------------------------
// Size of your Visual Map matrix:  columns x rows.
// 4 RAM sticks side by side with 10 LEDs each  ->  4 x 10.
// (If your map has the sticks stacked as rows instead, use 10 x 4.)
// The helix automatically runs along the longer side.
// Set both to 0.0 to take the size from the effect's Width / Height boxes.
#define GRID_COLS 4.0
#define GRID_ROWS 10.0

// ---- 2. LOOK ----------------------------------------------------------------
#define TURN_LENGTH    8.0    // LEDs per full 360-degree twist (smaller = tighter)
#define TURNS_PER_SEC  0.40   // rotation speed (negative = reverse direction)
#define STRAND_SIZE    0.8    // strand thickness in LEDs (0.6 crisp ... 1.2 soft)
#define RUNG_EVERY     3.0    // base-pair rung every N LEDs (0 = no rungs)
#define RUNG_LEVEL     0.35   // rung brightness, 0..1
#define DEPTH          0.65   // 3D shading: 0 = flat, 1 = strand behind almost dark
#define SHINE          0.50   // white highlight on the strand facing you, 0..1
#define PERSPECTIVE    0.35   // strand in front is drawn thicker, the one behind thinner (0 = off)
#define OCCLUSION      0.70   // how strongly the front strand hides the one behind it, 0..1
#define CROSS_SHARP    3.0    // how crisply the strands swap front/back at a crossing (higher = crisper)
#define RAINBOW        0.0    // 1.0 = colors drift through the rainbow (WLED style)

// ---- 3. COLORS (used when RAINBOW is 0.0) -----------------------------------
#define COLOR_A vec3(0.00, 0.55, 1.00)    // strand 1  (r, g, b  each 0..1)
#define COLOR_B vec3(1.00, 0.10, 0.50)    // strand 2

// ============================================================================
const float TAU = 6.28318530718;

vec3 dnaHue(float h)                 // fully saturated rainbow colour, h = 0..1
{
    return clamp(abs(fract(h + vec3(0.0, 2.0, 1.0) / 3.0) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
}

float tent(float d, float r)         // soft dot: 1 at the centre, 0 at distance r
{
    return max(0.0, 1.0 - abs(d) / r);
}

float cube(float x)                  // x*x*x of the positive part (for highlights)
{
    float f = max(x, 0.0);
    return f * f * f;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 grid = (GRID_COLS > 0.5) ? vec2(GRID_COLS, GRID_ROWS) : iResolution.xy;

    // Snap this pixel to the LED it belongs to (so any render size works).
    vec2 cell = min(floor(fragCoord / iResolution.xy * grid), grid - 1.0);
    vec2 p = cell + 0.5;                                  // LED centre, y points up

    // Helix frame: 'a' runs ALONG the helix, 'c' ACROSS it.
    float a;
    float c;
    float len;
    float wid;
    if (grid.y >= grid.x) { a = p.y; c = p.x;          len = grid.y; wid = grid.x; }
    else                  { a = p.x; c = grid.y - p.y; len = grid.x; wid = grid.y; }

    // The two strands: opposite sine waves, half a turn apart.
    float ph  = TAU * fract(a / TURN_LENGTH - TURNS_PER_SEC * iTime);
    float s   = sin(ph);
    float zA  = cos(ph);                                  // +1 = facing us, -1 = behind
    float amp = 0.5 * (wid - 1.0);
    float mid = 0.5 * wid;
    float xA  = mid + amp * s;
    float xB  = mid - amp * s;

    // Colours
    vec3 cA = COLOR_A;
    vec3 cB = COLOR_B;
    if (RAINBOW > 0.5)
    {
        float h = a / len * 0.35 - 0.08 * iTime;
        cA = dnaHue(h);
        cB = dnaHue(h + 0.5);
    }

    // Base-pair rung on every RUNG_EVERY-th LED: each half takes its strand's colour.
    float rung = 0.0;
    vec3  rungCol = vec3(0.0);
    if (RUNG_EVERY > 0.5 && mod(floor(a), RUNG_EVERY) < 0.5)
    {
        float lo = min(xA, xB);
        float hi = max(xA, xB);
        rung = clamp(min(c + 0.5, hi) - max(c - 0.5, lo), 0.0, 1.0);   // LED coverage
        float tB = clamp(0.5 - (c - mid) * s * 3.0, 0.0, 1.0);         // 0 = strand 1 half, 1 = strand 2 half
        rungCol = mix(cA, cB, tB) * RUNG_LEVEL;
    }

    // Perspective: the strand facing us is drawn thicker, the one behind it thinner.
    float covA = tent(c - xA, STRAND_SIZE * (1.0 + PERSPECTIVE * zA));
    float covB = tent(c - xB, STRAND_SIZE * (1.0 - PERSPECTIVE * zA));

    // Which strand is in front?  1 = strand 1, 0 = strand 2 (soft only right at the crossing).
    float wA = clamp(0.5 + CROSS_SHARP * zA, 0.0, 1.0);

    // 3D shading: the strand facing us is brighter and shinier, the one behind is dim.
    // The white highlight is strongest at the strand's core, so its edges keep their colour.
    vec3  colA = cA * (1.0 - DEPTH * 0.5 * (1.0 - zA));
    vec3  colB = cB * (1.0 - DEPTH * 0.5 * (1.0 + zA));
    colA = mix(colA, vec3(1.0), SHINE * cube(zA) * covA * covA);
    colB = mix(colB, vec3(1.0), SHINE * cube(-zA) * covB * covB);

    // The strand in front is more opaque, so it hides what is behind it.
    covA = min(1.0, covA * (1.0 + OCCLUSION * wA));
    covB = min(1.0, covB * (1.0 + OCCLUSION * (1.0 - wA)));

    // Paint back-to-front: back strand, rung, front strand. Both orders are
    // computed and cross-faded around the crossing so nothing "pops".
    vec3 aFront = mix(mix(mix(vec3(0.0), colB, covB), rungCol, rung), colA, covA);
    vec3 bFront = mix(mix(mix(vec3(0.0), colA, covA), rungCol, rung), colB, covB);
    vec3 col = mix(bFront, aFront, wA);

    fragColor = vec4(col, 1.0);
}
