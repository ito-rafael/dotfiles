// DNA Double Helix — OpenRGB Effects Plugin
// Tuned for a Visual Map with 10 rows x 4 columns (40 LEDs).
// Apply to the combined Visual Map, not to each RAM stick separately.
//
// User-adjustable parameters:
const float SPEED = 1.20;       // Animation speed: 0.0 = stopped, larger = faster
const float BRIGHTNESS = 1.00;  // Overall LED brightness: 0.0 = off, 1.0 = maximum
//
// Smooth-transition version:
// Strand positions remain fractional instead of snapping to whole columns.
// Each LED's intensity is blended by its distance from each strand so adjacent
// LEDs fade down/up continuously as the strands move across the 4-column matrix.

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 res = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord.xy / res;

    // LED-center coordinates: columns 0..3 and rows 0..9.
    // Keeping fractional coordinates is important for smooth cross-fading.
    float col = clamp(uv.x * 4.0 - 0.5, 0.0, 3.0);
    float row = clamp(uv.y * 10.0 - 0.5, 0.0, 9.0);

    // One full turn along the 10 LEDs of a stick.
    float phase = row * (6.28318530718 / 10.0)
                + 1.57079632679
                - iTime * SPEED;
    float wave = sin(phase);

    // Fractional strand positions. Do not round these to integer columns.
    float strandPosA = 1.5 + 1.45 * wave;
    float strandPosB = 1.5 - 1.45 * wave;

    vec3 cyan       = vec3(0.03, 0.80, 1.00);
    vec3 magenta    = vec3(1.00, 0.04, 0.44);
    vec3 rungGreen  = vec3(0.18, 1.00, 0.48);
    vec3 background = vec3(0.001, 0.003, 0.010);

    // Smoothly fade each strand across nearby LEDs instead of switching LEDs
    // abruptly. A strand at an LED center has full strength; as it moves toward
    // the next column, one LED dims while the next one brightens.
    const float STRAND_WIDTH = 1.05;
    float onA = 1.0 - smoothstep(0.0, STRAND_WIDTH, abs(col - strandPosA));
    float onB = 1.0 - smoothstep(0.0, STRAND_WIDTH, abs(col - strandPosB));

    // Soft connecting rungs between the two fractional strand positions.
    // Their ends also fade rather than appearing/disappearing as hard steps.
    float lo = min(strandPosA, strandPosB);
    float hi = max(strandPosA, strandPosB);
    float rungStart = smoothstep(lo + 0.10, lo + 0.75, col);
    float rungEnd   = 1.0 - smoothstep(hi - 0.75, hi - 0.10, col);
    float rung = clamp(rungStart * rungEnd, 0.0, 1.0);

    // Blend strand colors smoothly near crossings. This weighted blend also
    // avoids one strand abruptly hiding the other at a crossover.
    float strandTotal = onA + onB;
    vec3 strandColor = (cyan * onA + magenta * onB) / max(strandTotal, 0.0001);
    float strandStrength = clamp(strandTotal, 0.0, 1.0);

    vec3 color = mix(background, rungGreen, rung * 0.75);
    color = mix(color, strandColor, strandStrength);

    // Gentle pulse; its timing follows SPEED as well.
    float pulse = 0.90 + 0.10 * (0.5 + 0.5 * sin((iTime * SPEED) * 2.0 + row * 0.35));
    color *= pulse;

    // Apply overall brightness after all color/pulse calculations.
    color *= clamp(BRIGHTNESS, 0.0, 1.0);

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
