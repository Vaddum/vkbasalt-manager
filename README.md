# VkBasalt Manager

<div align="center"><img src="https://github.com/Vaddum/vkbasalt-manager/blob/main/VkBasalt_Manager_Heroes_Logo_1920x620.png" alt="VkBasalt Manager" width="1080" height="512"></div>

**Graphical interface for managing VkBasalt on Steam Deck**

VkBasalt Manager provides easy installation, configuration, and shader management for Vulkan post-processing effects.

## Quick Installation

1. Download the `vkbasalt_manager.sh` file
2. Make it executable: `chmod +x vkbasalt_manager.sh`
3. Launch it: `./vkbasalt_manager.sh`
4. Follow the installation wizard

## Key Features

- **Auto Install**: One-click installation of VkBasalt + ReShade shaders
- **Shader Manager**: Enable/disable effects with graphical interface
- **Advanced Config**: Visual parameter adjustment
- **Toggle Key**: Customizable in-game hotkey
- **Desktop Icon**: Easy access shortcut

### VkBasalt Built-in Effects 🔵

### CAS Settings
- **Sharpness** (0.0-1.0, default: 0.5): Sharpening intensity

### FXAA Settings
- **Subpix Quality** (0.0-1.0, default: 0.75): Subpixel antialiasing
- **Edge Threshold** (0.063-0.333, default: 0.125): Edge detection sensitivity

### SMAA Settings
- **Edge Detection** (luma/color/depth, default: luma): Detection method
- **Threshold** (0.01-0.20, default: 0.05): Sensitivity
- **Max Steps** (8-64, default: 32): Quality vs performance

### DLS Settings
- **Sharpening** (0.0-1.0, default: 0.5): Sharpening strength
- **Denoise** (0.0-1.0, default: 0.2): Noise reduction

### Supported External Effects (ReShade)

#### Light Effects 🟢
- **Border**: Adds customizable borders to fix edges
- **Curves**: S-curve contrast without clipping
- **Daltonize**: Color blindness correction filter
- **Defring**: Removes chromatic aberration/fringing
- **Levels**: Adjusts black/white point range
- **LiftGammaGain**: Professional shadows/midtones/highlights tool
- **Monochrome**: Black & white conversion with film presets
- **Sepia**: Vintage sepia tone effect
- **Technicolor**: Classic vibrant film process look
- **Tonemap**: Comprehensive tone mapping controls
- **Vibrance**: Smart saturation enhancement tool

#### Medium Effects 🟠
- **AdaptiveSharpen**: Smart edge-aware sharpening with minimal artifacts
- **Cartoon**: Creates cartoon-like edge enhancement
- **DPX**: Film-style color grading effect
- **FilmGrain**: Adds realistic film grain noise
- **LumaSharpen**: Luminance-based detail enhancement
- **Nostalgia**: Retro gaming visual style emulation
- **Vignette**: Darkened edges camera lens effect

#### Heavy Effects 🔴
- **4xBRZ**: Complex pixel art upscaling for retro games
- **Clarity**: Advanced sharpening with blur masking
- **CRT**: Simulates old CRT monitor appearance
- **FakeHDR**: Simulates HDR with bloom effects
- **SmartSharp**: Depth-aware intelligent sharpening

## Usage

### Main Menu

- **Shaders**: Manage active effects
- **Toggle Key**: Change in-game hotkey
- **Advanced**: Configure effect parameters
- **View Config**: Display current settings
- **Reset**: Restore default settings
- **Uninstall**: Remove VkBasalt completely

### In-Game Controls

**Toggle Effects**: Press the configured key (default: Home)

Effects activate in real-time, no restart required.

## File Locations

- **Configuration**: `~/.config/vkBasalt/vkBasalt.conf`
- **Shaders**: `~/.config/reshade/Shaders/`
- **Libraries**: `~/.local/lib/libvkbasalt.so`
- **Desktop**: `~/Desktop/VkBasalt-Manager.desktop`

## Troubleshooting

**No effects visible**: Check that the game uses Vulkan renderer

**Installation fails**: Verify your internet connection

**Performance drops**: Disable heavy effects (🔴)

**Toggle key not working**: Change the key in settings menu
