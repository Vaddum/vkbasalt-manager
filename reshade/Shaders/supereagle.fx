/*
    SuperEagle.fx — Adaptation ReShade FX
    ---------------------------------------------------------------------
    Reinterpretation du filtre de lissage "Super Eagle" (famille 2xSaI,
    principe original de Derek Liauw Kie Fa, 1999-2001) pour ReShade FX.

    Ce n'est PAS un portage ligne a ligne des implementations historiques
    (Cg pour libretro, HLSL Effects pour DOSBox — toutes deux GPL). C'est
    une reecriture du principe algorithmique : detecter les diagonales
    dans l'art pixel et les lisser, tout en preservant les transitions
    nettes ailleurs, en comparant les pixels voisins sur une grille
    logique (le "pixel source" du jeu, pas le pixel d'affichage).

    Contrairement au 2xSaI/SuperEagle original (qui double la resolution),
    ce shader tourne dans le pipeline ReShade/vkBasalt en post-traitement
    a resolution constante : il lisse donc l'aliasing des diagonales sans
    changer la taille de l'image, ce qui est l'usage courant de ce type
    de filtre en dehors des emulateurs.

    Reglages :
    - SourcePixelSize : rapport entre la resolution native du jeu et la
      resolution d'affichage. Augmente cette valeur si l'effet ne
      detecte pas correctement la grille de pixels.
    - Threshold : tolerance de similarite entre deux pixels.
    - Strength : intensite du lissage applique.
*/

#include "ReShade.fxh"

uniform float SourcePixelSize <
    ui_type = "slider";
    ui_min = 1.0;
    ui_max = 10.0;
    ui_step = 0.5;
    ui_label = "Taille du pixel source";
    ui_tooltip = "Rapport entre la resolution native du jeu et la resolution d'affichage.";
> = 2.0;

uniform float Threshold <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 0.2;
    ui_step = 0.005;
    ui_label = "Seuil de similarite";
    ui_tooltip = "Tolerance pour considerer deux pixels comme identiques.";
> = 0.02;

uniform float Strength <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.05;
    ui_label = "Intensite du lissage";
> = 1.0;

uniform float ContrastLimit <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Protection du texte (contraste max)";
    ui_tooltip = "Au-dela de cet ecart de luminosite entre pixels voisins, le lissage est desactive.\nPermet de garder le texte/UI net tout en lissant les diagonales du jeu.\nBaisse la valeur si le texte est encore flou.";
> = 0.30;

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

// Un ecart de luminosite trop fort entre le centre et un coin ressemble
// a du texte/UI net (lettre blanche sur fond sombre, etc.), pas a une
// diagonale d'art pixel : on evite alors de lisser pour garder le texte lisible.
bool ContrastOK(float3 a, float3 b)
{
    return abs(Luma(a) - Luma(b)) < ContrastLimit;
}

float3 SuperEaglePS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float2 pixelSize = BUFFER_PIXEL_SIZE * SourcePixelSize;
    float2 gridCoord = floor(texcoord / pixelSize);
    float2 subpixel  = frac(texcoord / pixelSize);

    // Voisinage 3x3 sur la grille de pixels logique
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

    // Coin haut-gauche : diagonale N-W presente, pas de bord parasite cote N-E / W-S
    if (!Similar(c, nw) && Similar(n, w) && !Similar(n, e) && !Similar(w, s) && ContrastOK(c, n))
    {
        float bx = subpixel.x < 0.5 ? 1.0 - subpixel.x * 2.0 : 0.0;
        float by = subpixel.y < 0.5 ? 1.0 - subpixel.y * 2.0 : 0.0;
        result = lerp(result, n, min(bx, by) * Strength);
    }
    // Coin haut-droit
    if (!Similar(c, ne) && Similar(n, e) && !Similar(n, w) && !Similar(e, s) && ContrastOK(c, e))
    {
        float bx = subpixel.x > 0.5 ? (subpixel.x - 0.5) * 2.0 : 0.0;
        float by = subpixel.y < 0.5 ? 1.0 - subpixel.y * 2.0 : 0.0;
        result = lerp(result, e, min(bx, by) * Strength);
    }
    // Coin bas-gauche
    if (!Similar(c, sw) && Similar(s, w) && !Similar(s, e) && !Similar(w, n) && ContrastOK(c, s))
    {
        float bx = subpixel.x < 0.5 ? 1.0 - subpixel.x * 2.0 : 0.0;
        float by = subpixel.y > 0.5 ? (subpixel.y - 0.5) * 2.0 : 0.0;
        result = lerp(result, s, min(bx, by) * Strength);
    }
    // Coin bas-droit
    if (!Similar(c, se) && Similar(s, e) && !Similar(s, w) && !Similar(e, n) && ContrastOK(c, se))
    {
        float bx = subpixel.x > 0.5 ? (subpixel.x - 0.5) * 2.0 : 0.0;
        float by = subpixel.y > 0.5 ? (subpixel.y - 0.5) * 2.0 : 0.0;
        result = lerp(result, se, min(bx, by) * Strength);
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
