# VkBasalt Manager

Graphical interface for managing VkBasalt on Steam Deck. Provides easy installation, configuration, and shader management for Vulkan post-processing effects.

## Quick Start

1. Download `vkbasalt_manager.sh`
2. `chmod +x vkbasalt_manager.sh`
3. `./vkbasalt_manager.sh`
4. Follow the installation wizard

## Features

| Feature | Description |
|---------|-------------|
| **Auto Install** | One-click VkBasalt + ReShade shaders installation |
| **Shader Manager** | Enable/disable effects with GUI |
| **Advanced Config** | Visual parameter adjustment |
| **Toggle Key** | Customizable in-game hotkey |
| **Desktop Icon** | Easy access shortcut |

## Supported Effects

### Built-in (VkBasalt Native)
| Effect | Type | Description |
|--------|------|-------------|
| **CAS** | 🔵 Sharpening | AMD Adaptive Sharpening |
| **FXAA** | 🔵 Anti-aliasing | Fast edge smoothing |
| **SMAA** | 🔵 Anti-aliasing | High-quality AA |
| **DLS** | 🔵 Sharpening | Denoised Luma Sharpening |

### External (ReShade)
| Effect | Complexity | Description |
|--------|------------|-------------|
| **AdaptiveSharpen** | 🟠 Medium | Smart edge-aware sharpening |
| **Border** | 🟢 Light | Customizable screen borders |
| **Clarity** | 🔴 Heavy | Advanced sharpening with blur masking |
| **CRT** | 🔴 Heavy | Retro CRT monitor simulation |
| **Curves** | 🟢 Light | S-curve contrast adjustment |
| **DPX** | 🟠 Medium | Film-style color grading |
| **FakeHDR** | 🔴 Heavy | HDR simulation with bloom |
| **FilmGrain** | 🟠 Medium | Realistic film grain |
| **LumaSharpen** | 🟠 Medium | Luminance-based sharpening |
| **Vibrance** | 🟢 Light | Smart saturation enhancement |

## Usage

### Main Menu
| Option | Function |
|--------|----------|
| **Shaders** | Manage active effects |
| **Toggle Key** | Change in-game hotkey |
| **Advanced** | Configure effect parameters |
| **View Config** | Display current settings |
| **Reset** | Restore defaults |
| **Uninstall** | Remove VkBasalt completely |

### In-Game Controls
- **Toggle Effects**: Press configured key (default: Home)
- **Real-time**: No restart required

## File Locations

| Component | Path |
|-----------|------|
| **Config** | `~/.config/vkBasalt/vkBasalt.conf` |
| **Shaders** | `~/.config/reshade/Shaders/` |
| **Libraries** | `~/.local/lib/libvkbasalt.so` |
| **Desktop** | `~/Desktop/VkBasalt-Manager.desktop` |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **No effects visible** | Check game uses Vulkan renderer |
| **Installation fails** | Verify internet connection |
| **Performance drops** | Disable heavy effects (🔴) |
| **Toggle key not working** | Change key in settings menu |

## Advanced Configuration

### CAS Settings
| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| Sharpness | 0.0-1.0 | 0.5 | Sharpening intensity |

### FXAA Settings
| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| Subpix Quality | 0.0-1.0 | 0.75 | Subpixel antialiasing |
| Edge Threshold | 0.063-0.333 | 0.125 | Edge detection sensitivity |

### SMAA Settings
| Parameter | Options | Default | Description |
|-----------|---------|---------|-------------|
| Edge Detection | luma/color/depth | luma | Detection method |
| Threshold | 0.01-0.20 | 0.05 | Sensitivity |
| Max Steps | 8-64 | 32 | Quality vs performance |

### DLS Settings
| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| Sharpening | 0.0-1.0 | 0.5 | Sharpening strength |
| Denoise | 0.0-1.0 | 0.2 | Noise reduction |

## Dependencies

| Package | Purpose | Auto-installed |
|---------|---------|----------------|
| `zenity` | GUI dialogs | ✅ |
| `wget` | Downloads | ✅ |
| `unzip` | Archives | ✅ |
| `tar` | Packages | ✅ |
