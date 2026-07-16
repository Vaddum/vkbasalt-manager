#include "ReShade.fxh"

// Define configurable parameters
uniform float BoostAmount < ui_type = "slider"; ui_min = 0.0; ui_max = 2.0; > = 0.5;
uniform float SaturationThreshold < ui_type = "slider"; ui_min = 0.0; ui_max = 1.0; > = 0.7;
uniform float GrayscaleThreshold < ui_type = "slider"; ui_min = 0.0; ui_max = 1.0; > = 1.0;

float3 BoostSaturation(float3 color, float boostAmount, float grayscaleThreshold, float saturationThreshold)
{
    // Calculate current saturation level
    float chroma = max(max(color.r, color.g), color.b) - min(min(color.r, color.g), color.b);
    float saturation = (chroma == 0.0) ? 0.0 : chroma / (1.0 - abs(1.0 - (color.r + color.g + color.b) / 3.0));

    // Determine the saturation boost factor with roll-off for high saturation levels
    float boostFactor = boostAmount * smoothstep(0.0, grayscaleThreshold, saturation) * (1.0 - smoothstep(saturationThreshold, 1.0, saturation));

    // Apply saturation boost
    float3 boostedColor = color + boostFactor * (color - 0.5);

    // Ensure color values are within valid range
    boostedColor = saturate(boostedColor);

    return boostedColor;
}

float4 PS_SaturationBoost(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    // Sample input texture from ReShade's back buffer
    float4 inputColor = tex2D(ReShade::BackBuffer, texcoord);

    // Boost saturation with rolloff for non-grayscale colors
    float3 boostedColor = BoostSaturation(inputColor.rgb, BoostAmount, GrayscaleThreshold, SaturationThreshold);

    // Return adjusted color with original alpha
    return float4(boostedColor, inputColor.a);
}

technique SaturationBoost
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SaturationBoost;
    }
}
