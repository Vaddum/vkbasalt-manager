# VkBasalt Manager - Universal Version

A comprehensive installation, configuration, and management tool for VkBasalt with graphical interface support. Compatible with Steam Deck (SteamOS), CachyOS, Arch Linux, and other Linux distributions.

## 🎯 Features

- **Universal Compatibility**: Works on Steam Deck, CachyOS, Arch Linux, and other distributions
- **Automatic Installation**: Downloads and installs VkBasalt with all dependencies
- **Graphical Interface**: Easy-to-use GUI with Zenity dialogs
- **Shader Management**: Browse and enable/disable effects with visual feedback
- **Advanced Configuration**: Fine-tune built-in VkBasalt effects (CAS, FXAA, SMAA, DLS)
- **Desktop Integration**: Creates desktop shortcuts and application menu entries
- **Package Manager Detection**: Automatically uses the best package manager (paru, pacman, etc.)

## 🖼️ Screenshots

### Main Configuration Menu
![Configuration Menu](image2.png)

*Main interface showing all available configuration options*

### Shader Selection Interface
![Shader Selection](image3.png)

*Interactive shader selection with descriptions and difficulty indicators*

### Advanced Settings
![Advanced Settings](image1.png)

*Built-in effect configuration for professional fine-tuning*

## 🚀 Quick Start

### Installation

1. **Make the script executable:**
   ```bash
   chmod +x vkbasalt_manager_universal.sh
   ```

2. **Run the installer:**
   ```bash
   ./vkbasalt_manager_universal.sh
   ```

3. **Follow the installation wizard** - the script will automatically:
   - Detect your system (Steam Deck, CachyOS, Arch, etc.)
   - Install required dependencies
   - Download and configure VkBasalt
   - Install ReShade shaders
   - Create desktop shortcuts

### Managing Effects

1. **Launch VkBasalt Manager** from desktop or applications menu
2. **Select "Shaders"** to manage active effects
3. **Choose effects** using the checkbox interface:
   - ⭐ **Built-in effects** (CAS, FXAA, SMAA, DLS) - Always available
   - 🟢 **Low impact** - Minimal performance cost
   - 🟠 **Medium impact** - Moderate performance cost  
   - 🔴 **High impact** - Higher performance cost
4. **Apply settings** and test in your games

### Toggle Effects In-Game

- **Default key**: `Home` (configurable)
- Press the toggle key to enable/disable effects while playing
- Change toggle key via "Toggle Key" option in the manager

## 🎨 Available Effects

### Built-in VkBasalt Effects
| Effect | Description | Performance Impact |
|--------|-------------|-------------------|
| **CAS** | AMD FidelityFX Contrast Adaptive Sharpening | Low |
| **FXAA** | Fast Approximate Anti-Aliasing | Low |
| **SMAA** | Subpixel Morphological Anti-Aliasing | Medium |
| **DLS** | Denoised Luma Sharpening | Low |

### ReShade Effects
| Effect | Description | Performance Impact |
|--------|-------------|-------------------|
| Border | Customizable borders to fix screen edges | Low |
| Cartoon | Cartoon-like edge enhancement | Medium |
| Clarity | Advanced sharpening with blur masking | High |
| CRT | Simulates old CRT monitor appearance | High |
| Curves | S-curve contrast enhancement | Low |
| Daltonize | Color blindness correction filter | Low |
| DPX | Film-style color grading | Medium |
| FakeHDR | HDR simulation with bloom effects | High |
| FilmGrain | Realistic film grain noise | Medium |
| Levels | Black/white point adjustments | Low |
| LiftGammaGain | Professional color grading tool | Low |
| LumaSharpen | Luminance-based sharpening | Medium |
| Monochrome | Black & white conversion | Low |
| Nostalgia | Retro gaming visual style | Medium |
| Sepia | Vintage sepia tone effect | Low |
| SmartSharp | Depth-aware intelligent sharpening | High |
| Technicolor | Classic vibrant film look | Low |
| Tonemap | Advanced tone mapping controls | Low |
| Vibrance | Smart saturation enhancement | Low |
| Vignette | Camera lens edge darkening | Medium |

## ⚙️ Advanced Configuration

### Built-in Effect Settings

The manager provides detailed configuration for built-in effects:

#### CAS (Contrast Adaptive Sharpening)
- **Sharpness**: 0.0 to 1.0 (default: 0.5)
- Enhances details without introducing artifacts

#### FXAA (Fast Approximate Anti-Aliasing)
- **Subpixel Quality**: 0.0 to 1.0 (default: 0.75)
- **Edge Threshold**: 0.063 to 0.333 (default: 0.125)

#### SMAA (Subpixel Morphological Anti-Aliasing)
- **Edge Detection**: luma, color, or depth (default: luma)
- **Threshold**: 0.01 to 0.20 (default: 0.05)
- **Max Search Steps**: 8 to 64 (default: 32)

#### DLS (Denoised Luma Sharpening)
- **Sharpening**: 0.0 to 1.0 (default: 0.5)
- **Denoise**: 0.0 to 1.0 (default: 0.20)

### Manual Configuration

Configuration file location: `~/.config/vkBasalt/vkBasalt.conf`

Example configuration:
```ini
effects = cas:fxaa:smaa
reshadeTexturePath = ~/.config/reshade/Textures
reshadeIncludePath = ~/.config/reshade/Shaders
depthCapture = off
toggleKey = Home
enableOnLaunch = True

casSharpness = 0.5
fxaaQualitySubpix = 0.75
fxaaQualityEdgeThreshold = 0.125
smaaEdgeDetection = luma
smaaThreshold = 0.05
smaaMaxSearchSteps = 32
```

## 🖥️ System Compatibility

### Supported Systems
- **Steam Deck** (SteamOS) - Full support with system-specific optimizations
- **CachyOS** - Native repository and AUR package support
- **Arch Linux** - AUR package installation
- **Other Linux** - Generic installation with automatic detection

### Supported Package Managers
- **paru** (CachyOS preferred)
- **pacman** (Arch/SteamOS)
- **apt** (Debian/Ubuntu)
- **dnf** (Fedora)
- **zypper** (openSUSE)

### Dependencies
Automatically installed:
- `zenity` - GUI dialogs
- `wget` - Downloads
- `unzip` - Archive extraction
- `tar` - Package extraction

## 📁 File Locations

| Component | Location |
|-----------|----------|
| VkBasalt Libraries | `~/.local/lib/libvkbasalt.so`<br>`~/.local/lib32/libvkbasalt.so` |
| Configuration | `~/.config/vkBasalt/vkBasalt.conf` |
| Shaders | `~/.config/reshade/Shaders/` |
| Textures | `~/.config/reshade/Textures/` |
| Vulkan Layers | `~/.local/share/vulkan/implicit_layer.d/` |
| Manager Script | `~/.config/vkBasalt/vkbasalt-manager.sh` |
| Desktop Icon | `~/Desktop/VkBasalt-Manager.desktop` |

## 🔧 Troubleshooting

### Common Issues

**VkBasalt not working in games:**
1. Verify installation status via "Status" in the manager
2. Check that the correct environment variable is used
3. Ensure the game uses Vulkan API (not OpenGL/DirectX)

**Effects not visible:**
1. Press the toggle key (default: Home) in-game
2. Check that effects are enabled in the shader manager
3. Verify configuration file syntax

**Performance issues:**
1. Disable high-impact effects (marked with 🔴)
2. Reduce effect intensity in advanced settings
3. Use only built-in effects for maximum performance

**Installation fails:**
1. Check internet connection
2. Ensure sufficient disk space
3. Verify user permissions
4. Try running with elevated privileges if needed

### Getting Help

1. **Check Status**: Use the "Status" option in the manager
2. **View Configuration**: Use "View" to check current settings
3. **Reset to Defaults**: Use "Reset" to restore working configuration
4. **Complete Reinstall**: Use "Uninstall" then reinstall

## 🗑️ Uninstallation

The manager provides complete uninstallation:

1. Launch VkBasalt Manager
2. Select "Uninstall"
3. Confirm removal (⚠️ This removes EVERYTHING)

Manual removal:
```bash
rm -rf ~/.config/vkBasalt ~/.config/reshade
rm -f ~/.local/lib/libvkbasalt.so ~/.local/lib32/libvkbasalt.so
rm -f ~/.local/share/vulkan/implicit_layer.d/vkBasalt*.json
```

## 📝 License

This project is open source. Please check the license file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## ⭐ Acknowledgments

- **VkBasalt** project for the core post-processing layer
- **ReShade** community for shader effects
- **Chaotic AUR** for package distribution
- **AMD FidelityFX** for CAS implementation
