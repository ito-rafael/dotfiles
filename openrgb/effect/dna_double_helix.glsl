// DNA Double Helix — OpenRGB Effects Plugin
// Tuned for a Visual Map with exactly 10 rows x 4 columns (40 LEDs).
// Apply to the combined Visual Map, not to each RAM stick separately.
//
// User-adjustable parameters:
const float SPEED = 1.20;      // Animation speed: 0.0 = stopped, larger = faster
const float BRIGHTNESS = 1.00; // LED brightness: 0.0 = off, 1.0 = maximum
//
// The strand positions are quantized to the four real LED columns so the
// pattern remains visible on a narrow 4-column matrix. Green LEDs form the
// ladder rungs between the two strands.

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 res = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord.xy / res;

    // Logical matrix coordinates: 10 rows high, 4 columns wide.
    // Normalized coordinates keep this usable even if the shader buffer is
    // rendered larger than 4x10 before being sampled by the Visual Map.
    float row = clamp(floor(uv.y * 10.0), 0.0, 9.0);
    float col = clamp(floor(uv.x * 4.0), 0.0, 3.0);

    // One full turn along the 10 LEDs of a stick.
    float phase = row * (6.28318530718 / 10.0)
                + 1.57079632679
                - iTime * SPEED;
    float wave = sin(phase);

    // Opposing strands, mapped onto column coordinates 0..3.
    // The 1.45 amplitude drives the strands to the outer columns at each peak.
    float strandPosA = 1.5 + 1.45 * wave;
    float strandPosB = 1.5 - 1.45 * wave;

    // Snap each strand to its nearest physical column.
    float strandA = clamp(floor(strandPosA + 0.5), 0.0, 3.0);
    float strandB = clamp(floor(strandPosB + 0.5), 0.0, 3.0);

    vec3 cyan       = vec3(0.03, 0.80, 1.00);
    vec3 magenta    = vec3(1.00, 0.04, 0.44);
    vec3 rungGreen  = vec3(0.18, 1.00, 0.48);
    vec3 crossover  = mix(cyan, magenta, 0.5);
    vec3 background = vec3(0.001, 0.003, 0.010);

    float onA = 1.0 - step(0.1, abs(col - strandA));
    float onB = 1.0 - step(0.1, abs(col - strandB));

    // Illuminate the cells strictly between the strand endpoints as rungs.
    float lo = min(strandA, strandB);
    float hi = max(strandA, strandB);
    float rung = step(lo + 0.5, col) * step(col, hi - 0.5);

    vec3 color = background;
    color = mix(color, rungGreen, rung);
    color = mix(color, cyan, onA);
    color = mix(color, magenta, onB);

    // At the projected crossover, blend both strand colors instead of hiding one.
    float overlap = onA * onB;
    color = mix(color, crossover, overlap);

    // Gentle pulse; its timing follows SPEED as well.
    float pulse = 0.90 + 0.10 * (0.5 + 0.5 * sin((iTime * SPEED) * 2.0 + row * 0.35));
    color *= pulse;

    // Apply overall brightness after all color/pulse calculations.
    color *= clamp(BRIGHTNESS, 0.0, 1.0);

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
