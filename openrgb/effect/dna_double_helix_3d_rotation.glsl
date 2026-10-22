// DNA Double Helix — 3D axial rotation for OpenRGB Effects > Shaders
// For a 4-column x 10-row Visual Map (40 LEDs).
// Apply to the combined Visual Map, not to each RAM stick separately.
// No connecting rungs: only the cyan and magenta strands are rendered.
//
// The rotation is projected from a simple 3D helix:
//   horizontal position = sin(angle)
//   depth / front-back = cos(angle)
// As time advances, the angle changes so the two strands orbit the long axis;
// each crossing swaps which strand is in front. The front strand becomes wider,
// brighter, and gets a small cool-white highlight; the rear strand recedes.

const float ROTATION_SPEED = 1.20;          // Radians/second; higher = faster rotation
const float BRIGHTNESS = 1.00;               // Overall brightness: 0.0 to 1.0
const float TURN_LENGTH = 10.0;              // Rows per full helical turn
const float STRAND_RADIUS = 1.45;             // Horizontal travel in LED columns
const float BACK_BRIGHTNESS = 0.22;           // Rear strand brightness at maximum depth
const float FRONT_HIGHLIGHT = 0.18;           // Front-facing specular highlight
const float MIN_STRAND_WIDTH = 0.90;          // Rear strand width in LED units
const float MAX_STRAND_WIDTH = 1.28;          // Front strand width in LED units

const float TAU = 6.28318530718;
const float PI  = 3.14159265359;

float strandCoverage(float col, float strandX, float width)
{
    float d = abs(col - strandX);
    return 1.0 - smoothstep(0.12, width, d);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 res = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord.xy / res;

    // Continuous coordinates centered on the 4 x 10 LED grid.
    float col = clamp(uv.x * 4.0 - 0.5, 0.0, 3.0);
    float row = clamp(uv.y * 10.0 - 0.5, 0.0, 9.0);

    // Rotate the helix around its long axis. The sin() component is its visible
    // left/right orbit; cos() is depth, determining which strand faces camera.
    float angleA = row * (TAU / TURN_LENGTH) - iTime * ROTATION_SPEED;
    float angleB = angleA + PI;

    float depthA = cos(angleA);  // +1 = cyan strand fully forward
    float depthB = cos(angleB);  // opposite depth to strand A

    float mid = 1.5;
    float xA = mid + STRAND_RADIUS * sin(angleA);
    float xB = mid + STRAND_RADIUS * sin(angleB);

    // A strand is visually fuller when it faces the viewer and thinner as it
    // rotates away. This helps the motion read as a rotating 3D object.
    float widthA = mix(MIN_STRAND_WIDTH, MAX_STRAND_WIDTH, 0.5 + 0.5 * depthA);
    float widthB = mix(MIN_STRAND_WIDTH, MAX_STRAND_WIDTH, 0.5 + 0.5 * depthB);
    float onA = strandCoverage(col, xA, widthA);
    float onB = strandCoverage(col, xB, widthB);

    vec3 cyan = vec3(0.03, 0.80, 1.00);
    vec3 pink = vec3(1.00, 0.035, 0.42);
    vec3 background = vec3(0.001, 0.003, 0.010);

    // Depth shading: the rear side is deliberately darker, while the forward
    // side gets a subtle highlight that moves around the helix with the rotation.
    float shadeA = mix(BACK_BRIGHTNESS, 1.0, smoothstep(-0.35, 0.55, depthA));
    float shadeB = mix(BACK_BRIGHTNESS, 1.0, smoothstep(-0.35, 0.55, depthB));
    float shineA = FRONT_HIGHLIGHT * pow(max(depthA, 0.0), 8.0);
    float shineB = FRONT_HIGHLIGHT * pow(max(depthB, 0.0), 8.0);
    vec3 colorA = mix(cyan * shadeA, vec3(1.0), shineA);
    vec3 colorB = mix(pink * shadeB, vec3(1.0), shineB);

    // The strands have opposite depth. Paint the rear one first, then place the
    // front one over it. The swap occurs when their projected positions are far
    // apart, avoiding a visible popping effect at the crossing.
    float aIsFront = step(0.0, depthA);
    float backOn = mix(onA, onB, aIsFront);
    float frontOn = mix(onB, onA, aIsFront);
    vec3 backColor = mix(colorA, colorB, aIsFront);
    vec3 frontColor = mix(colorB, colorA, aIsFront);

    vec3 color = mix(background, backColor, clamp(backOn, 0.0, 1.0));
    color = mix(color, frontColor, clamp(frontOn, 0.0, 1.0));

    // Very subtle breathing highlights; the actual axial rotation remains the
    // dominant motion and both strands keep their original cyan/pink identity.
    float pulse = 0.96 + 0.04 * (0.5 + 0.5 * sin(iTime * ROTATION_SPEED * 1.7 + row * 0.28));
    color *= pulse * clamp(BRIGHTNESS, 0.0, 1.0);

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
