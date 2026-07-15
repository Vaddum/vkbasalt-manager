/*
    SuperEagle.fx - "Cartoon smoothing" adaptation for ReShade FX
    ---------------------------------------------------------------------
    Reinterpretation of the "Super Eagle" smoothing filter (2xSaI family,
    original principle by Derek Liauw Kie Fa, 1999-2001) for ReShade FX,
    extended to push the look further from "smoothed pixel art" toward a
    soft, cartoon/flat-shaded feel.

    What changed vs. the diagonal-only version:
    - Diagonal corners are still detected and smoothed, but the blend curve
      now uses a smoothstep (rounded) ramp instead of a straight linear one,
      giving softer, rounder curves instead of a hard diagonal cut.
    - A second pass softens straight horizontal/vertical staircases (the
      blockiness a purely-diagonal filter leaves untouched), blending only
      near logical-pixel boundaries so flat interior color stays flat
      (keeps a cartoon/flat-shaded feel rather than a blurry mess).
    - Both passes are gated by the same contrast-based text/UI protection:
      strong local contrast (typical of text) disables smoothing there.

    Settings:
    - SourcePixelSize : ratio between the game's native resolution and the
      display resolution.
    - Threshold       : color similarity tolerance used for pattern matching.
    - ContrastLimit   : text/UI protection - smoothing is skipped above this
      luminance gap between neighbors.
    - Strength        : diagonal corner smoothing intensity.
    - Softness        : straight-edge smoothing intensity (the "cartoon"
      knob). Set to 0 to get the original diagonal-only behavior back.
*/

#include "ReShade.fxh"

uniform float SourcePixelSize <
    ui_type = "slider";
    ui_min = 1.0;
    ui_max = 10.0;
    ui_step = 0.5;
    ui_label = "Source pixel size";
    ui_tooltip = "Ratio between the game's native resolution and the display resolution.";
> = 2.0;

uniform float Threshold <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 0.2;
    ui_step = 0.005;
    ui_label = "Similarity threshold";
    ui_tooltip = "Tolerance for considering two pixels identical.";
> = 0.02;

uniform float ContrastLimit <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Text protection (max contrast)";
    ui_tooltip = "Above this luminance gap between neighboring pixels, smoothing is disabled.\nKeeps text/UI sharp while diagonals and edges in the game world still get smoothed.\nLower this value if text still looks blurry.";
> = 0.45;

uniform float Strength <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.05;
    ui_label = "Diagonal smoothing strength";
> = 1.0;

uniform float Softness <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.05;
    ui_label = "Edge softness (cartoon look)";
    ui_tooltip = "Extra smoothing of straight horizontal/vertical edges, for a softer,\nmore cartoon-like feel instead of visible pixel blocks.\nSet to 0 to keep the original diagonal-only look.";
> = 0.6;

texture texColorBuffer : COLOR;
sampler SamplerColor
{
    Texture = texColorBuffer;
};

float3 SampleGrid(float2 gridCoord, float2 offset, float2 pixelSize)
{
    float2 uv = (gridCoord + offset + 0.5) * pixelSize;
    return tex2D(SamplerColor, uv).rgb;
}

bool Similar(float3 a, float3 b)
{
    return dot(abs(a - b), float3(1.0, 1.0, 1.0)) < Threshold;
}

float Luma(float3 c)
{
    return dot(c, float3(0.299, 0.587, 0.114));
}

// A large luminance gap between neighbors looks like text/UI (a sharp letter
// on a flat background), not a pixel-art diagonal: skip smoothing there so
// text stays readable.
bool ContrastOK(float3 a, float3 b)
{
    return abs(Luma(a) - Luma(b)) < ContrastLimit;
}

// Rounded ramp (smoothstep) instead of a straight linear one: softer, more
// "cartoon" curves at corners and edges instead of a hard diagonal cut.
float SmoothRamp(float x)
{
    x = saturate(x);
    return x * x * (3.0 - 2.0 * x);
}

float3 SuperEaglePS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float2 pixelSize = BUFFER_PIXEL_SIZE * SourcePixelSize;
    float2 gridCoord = floor(texcoord / pixelSize);
    float2 subpixel  = frac(texcoord / pixelSize);

    // 3x3 neighborhood on the logical pixel grid
    float3 nw = SampleGrid(gridCoord, float2(-1,-1), pixelSize);
    float3 n  = SampleGrid(gridCoord, float2( 0,-1), pixelSize);
    float3 ne = SampleGrid(gridCoord, float2( 1,-1), pixelSize);
    float3 w  = SampleGrid(gridCoord, float2(-1, 0), pixelSize);
    float3 c  = SampleGrid(gridCoord, float2( 0, 0), pixelSize);
    float3 e  = SampleGrid(gridCoord, float2( 1, 0), pixelSize);
    float3 sw = SampleGrid(gridCoord, float2(-1, 1), pixelSize);
    float3 s  = SampleGrid(gridCoord, float2( 0, 1), pixelSize);
    float3 se = SampleGrid(gridCoord, float2( 1, 1), pixelSize);

    float3 result = c;

    // --- Diagonal corner smoothing (rounded ramp) ---------------------------
    // Top-left corner: N-W diagonal present, no false edge on N-E / W-S
    if (!Similar(c, nw) && Similar(n, w) && !Similar(n, e) && !Similar(w, s) && ContrastOK(c, n))
    {
        float bx = subpixel.x < 0.5 ? SmoothRamp(1.0 - subpixel.x * 2.0) : 0.0;
        float by = subpixel.y < 0.5 ? SmoothRamp(1.0 - subpixel.y * 2.0) : 0.0;
        result = lerp(result, n, min(bx, by) * Strength);
    }
    // Top-right corner
    if (!Similar(c, ne) && Similar(n, e) && !Similar(n, w) && !Similar(e, s) && ContrastOK(c, e))
    {
        float bx = subpixel.x > 0.5 ? SmoothRamp((subpixel.x - 0.5) * 2.0) : 0.0;
        float by = subpixel.y < 0.5 ? SmoothRamp(1.0 - subpixel.y * 2.0) : 0.0;
        result = lerp(result, e, min(bx, by) * Strength);
    }
    // Bottom-left corner
    if (!Similar(c, sw) && Similar(s, w) && !Similar(s, e) && !Similar(w, n) && ContrastOK(c, s))
    {
        float bx = subpixel.x < 0.5 ? SmoothRamp(1.0 - subpixel.x * 2.0) : 0.0;
        float by = subpixel.y > 0.5 ? SmoothRamp((subpixel.y - 0.5) * 2.0) : 0.0;
        result = lerp(result, s, min(bx, by) * Strength);
    }
    // Bottom-right corner
    if (!Similar(c, se) && Similar(s, e) && !Similar(s, w) && !Similar(e, n) && ContrastOK(c, se))
    {
        float bx = subpixel.x > 0.5 ? SmoothRamp((subpixel.x - 0.5) * 2.0) : 0.0;
        float by = subpixel.y > 0.5 ? SmoothRamp((subpixel.y - 0.5) * 2.0) : 0.0;
        result = lerp(result, se, min(bx, by) * Strength);
    }

    // --- Straight-edge softening (the "cartoon" pass) -----------------------
    // Blends toward the horizontal/vertical neighbor, but only near the
    // logical-pixel boundary (weight fades to 0 at the cell center), so flat
    // interior colors stay flat and only the blocky staircases get rounded.
    if (Softness > 0.0)
    {
        float distX = min(subpixel.x, 1.0 - subpixel.x); // 0 at boundary, 0.5 at center
        float distY = min(subpixel.y, 1.0 - subpixel.y);
        float edgeWeightX = SmoothRamp(1.0 - distX * 2.0); // 1 at boundary, 0 at center
        float edgeWeightY = SmoothRamp(1.0 - distY * 2.0);

        float3 hNeighbor = subpixel.x < 0.5 ? w : e;
        float3 vNeighbor = subpixel.y < 0.5 ? n : s;

        if (!Similar(c, hNeighbor) && ContrastOK(c, hNeighbor))
            result = lerp(result, hNeighbor, edgeWeightX * 0.5 * Softness);
        if (!Similar(c, vNeighbor) && ContrastOK(c, vNeighbor))
            result = lerp(result, vNeighbor, edgeWeightY * 0.5 * Softness);
    }

    return result;
}

technique SuperEagle
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = SuperEaglePS;
    }
}
