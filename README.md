# VkBasalt Manager - Universal Version

A comprehensive graphical interface for installing, configuring, and managing VkBasalt on Steam Deck (SteamOS) and CachyOS/Arch Linux systems.

## Features

- **Universal Compatibility**: Works on Steam Deck, CachyOS, Arch Linux, and other distributions
- **Automatic Installation**: Installs VkBasalt, ReShade shaders, and all dependencies
- **Graphical Interface**: Easy-to-use Zenity-based GUI for all operations
- **Advanced Configuration**: Fine-tune CAS, FXAA, SMAA, and DLS settings
- **Shader Management**: Enable/disable multiple effects with visual selection
- **Complete Uninstall**: Clean removal of all components

## Supported Systems

- **Steam Deck (SteamOS)**: Full support with Steam integration
- **CachyOS**: Official repository packages with AUR fallback
- **Arch Linux**: AUR package installation
- **Other distributions**: Basic support via package managers

## Quick Start

### Installation

1. Download the script and run:
```bash
chmod +x vkbasalt_manager_universal.sh
```

2. Run the installer:
```bash
./vkbasalt_manager_universal.sh
```

3. Follow the graphical installation wizard

### Usage

#### Steam Deck
1. Right-click on any Steam game → Properties
2. Add to Launch Options: `ENABLE_VKBASALT=1 %command%`
3. Launch the game and press `Home` key to toggle effects

#### CachyOS/Linux
1. Launch games with: `ENABLE_VKBASALT=1 your_game`
2. Or set globally: `export ENABLE_VKBASALT=1`
3. Press `Home` key in-game to toggle effects

## Configuration

The manager provides several configuration options:

- **Shaders**: Enable/disable built-in effects (CAS, FXAA, SMAA, DLS) and ReShade shaders
- **Toggle Key**: Change the in-game toggle key (Home, F1-F12, etc.)
- **Advanced Settings**: Fine-tune sharpening, anti-aliasing, and other parameters
- **Reset**: Restore default configuration

## Built-in Effects

- **CAS (Contrast Adaptive Sharpening)**: AMD FidelityFX sharpening
- **FXAA (Fast Approximate Anti-Aliasing)**: Quick anti-aliasing
- **SMAA (Subpixel Morphological Anti-Aliasing)**: High-quality anti-aliasing
- **DLS (Denoised Luma Sharpening)**: Intelligent sharpening with noise reduction

## Requirements

- **Steam Deck**: SteamOS 3.0+
- **CachyOS/Arch**: Recent installation with pacman
- **Dependencies**: zenity, wget, unzip, tar (auto-installed)
- **GPU**: Vulkan-compatible graphics card

## File Locations

- **Configuration**: `~/.config/vkBasalt/vkBasalt.conf`
- **Shaders**: `~/.config/reshade/Shaders/`
- **Manager**: `~/.config/vkBasalt/vkbasalt-manager.sh`
- **Desktop Entry**: 
  - Steam Deck: `~/Desktop/VkBasalt-Manager.desktop`
  - Linux: `~/.local/share/applications/VkBasalt-Manager.desktop`

## Troubleshooting

### Installation Issues
- Ensure internet connection is stable
- Check if running as regular user (not root)
- Verify Vulkan drivers are installed

### Game Not Enhanced
- Verify `ENABLE_VKBASALT=1` is set correctly
- Check that VkBasalt is installed: run manager → Status
- Ensure the game uses Vulkan renderer

### Performance Issues
- Reduce number of active effects
- Lower effect intensity in Advanced settings
- Use built-in effects (CAS, FXAA) for better performance

## Uninstallation

Run the manager and select "Uninstall" to completely remove:
- VkBasalt libraries and layers
- All configurations and shaders
- Manager interface and desktop entries
- System packages (on CachyOS)

## License

This project is open source. VkBasalt is developed by DadSchoorse.

## Credits

- **VkBasalt**: [DadSchoorse](https://github.com/DadSchoorse/vkBasalt)
- **Original Steam Deck installer**: [simons-public](https://github.com/simons-public/steam-deck-vkbasalt-install)

---

**Note**: This is an unofficial tool. Use at your own risk. Always backup your game saves before using post-processing effects.
