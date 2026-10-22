// DNA Double Helix — OpenRGB Effects Plugin
// Smooth 4-column x 10-row Visual Map, with alternating front/back depth.
// Apply to the combined Visual Map, not to each RAM stick separately.
// Green connecting rungs are removed.

const float SPEED = 1.20;                 // Animation speed: 0 = stopped, larger = faster
const float BRIGHTNESS = 1.00;            // Overall brightness: 0 = off, 1 = maximum
const float BACK_STRAND_BRIGHTNESS = 0.28; // Brightness of the strand behind the front one
const float FRONT_HIGHLIGHT = 0.18;       // Subtle highlight on the front-facing strand

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 res = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord.xy / res;

    // LED-center coordinates: columns 0..3 and rows 0..9.
    // Fractional coordinates produce smooth movement across neighboring LEDs.
    float col = clamp(uv.x * 4.0 - 0.5, 0.0, 3.0);
    float row = clamp(uv.y * 10.0 - 0.5, 0.0, 9.0);

    // The traveling phase controls both the crossing position and the depth.
    // As cos(phase) changes sign, the blue and pink strands swap front/back.
    const float TAU = 6.28318530718;
    float phase = row * (TAU / 10.0) + 1.57079632679 - iTime * SPEED;
    float wave = sin(phase);
    float depthA = cos(phase); // positive: cyan/blue strand A faces forward

    float strandPosA = 1.5 + 1.45 * wave;
    float strandPosB = 1.5 - 1.45 * wave;

    vec3 cyan       = vec3(0.03, 0.80, 1.00);
    vec3 magenta    = vec3(1.00, 0.04, 0.44);
    vec3 background = vec3(0.001, 0.003, 0.010);

    // Soft strand coverage: LEDs fade as each strand moves between columns.
    const float STRAND_WIDTH = 1.05;
    float onA = 1.0 - smoothstep(0.0, STRAND_WIDTH, abs(col - strandPosA));
    float onB = 1.0 - smoothstep(0.0, STRAND_WIDTH, abs(col - strandPosB));

    // Depth continuously changes each strand's brightness without changing its
    // identity: blue stays blue and pink stays pink. They trade depth as cos(phase)
    // changes sign, so the same-color strand is bright at the front crossings and
    // dimmer while it passes behind the other strand.
    float shadeA = BACK_STRAND_BRIGHTNESS
                 + (1.0 - BACK_STRAND_BRIGHTNESS) * (0.5 + 0.5 * depthA);
    float shadeB = BACK_STRAND_BRIGHTNESS
                 + (1.0 - BACK_STRAND_BRIGHTNESS) * (0.5 - 0.5 * depthA);

    // At the projected crossings, depthA determines the draw order. These
    // crossings happen where abs(depthA) is near 1, so the order changes while
    // the strands are spatially separated and does not visibly pop at a crossing.
    float aIsFront = step(0.0, depthA);
    float frontOn = mix(onB, onA, aIsFront);
    float backOn  = mix(onA, onB, aIsFront);
    vec3 frontColor = mix(magenta * shadeB, cyan * shadeA, aIsFront);
    vec3 backColor  = mix(cyan * shadeA, magenta * shadeB, aIsFront);

    // Render back first, then the front strand on top at the crossing.
    vec3 color = mix(background, backColor, clamp(backOn, 0.0, 1.0));
    float frontShine = 1.0 + FRONT_HIGHLIGHT * abs(depthA);
    color = mix(color, frontColor * frontShine, clamp(frontOn, 0.0, 1.0));

    // Gentle pulse retained from the original smooth animation.
    float pulse = 0.90 + 0.10 * (0.5 + 0.5 * sin((iTime * SPEED) * 2.0 + row * 0.35));
    color *= pulse * clamp(BRIGHTNESS, 0.0, 1.0);

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
