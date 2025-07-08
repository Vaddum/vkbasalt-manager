# VkBasalt Manager for Steam Deck

A complete graphical interface for managing VkBasalt post-processing effects on Steam Deck, featuring automatic installation, configuration, and shader management.

## 🚀 Features

- **One-click Installation**: Automatically downloads and installs VkBasalt and ReShade shaders
- **Graphical Interface**: User-friendly Zenity-based GUI for all operations
- **Shader Management**: Easy selection and configuration of visual effects
- **Built-in Effects**: Supports VkBasalt's native CAS, FXAA, SMAA, and DLS effects
- **ReShade Compatibility**: Manages external ReShade shader library
- **Advanced Configuration**: Fine-tune individual shader parameters
- **Toggle Key Customization**: Choose your preferred in-game toggle key
- **Complete Uninstallation**: Clean removal of all components

## 📋 What is VkBasalt?

VkBasalt is a Vulkan post-processing layer that applies visual effects to games in real-time. It can enhance image quality through:

- **Sharpening**: CAS (Contrast Adaptive Sharpening), DLS (Denoised Luma Sharpening)
- **Anti-aliasing**: FXAA, SMAA for smoother edges
- **Visual Effects**: Film grain, color correction, HDR simulation, and many more

## 🛠️ Prerequisites

- **Steam Deck** running SteamOS
- **Internet connection** for initial download
- **Zenity** (automatically installed if missing)

## 📦 Installation

### Method 1: Download and Run
1. Download the script: `vkbasalt-manager.sh`
2. Make it executable: `chmod +x vkbasalt-manager.sh`
3. Run it: `./vkbasalt-manager.sh`
4. Follow the on-screen instructions for automatic installation

### Method 2: One-line Installation
```bash
wget -q -O vkbasalt-manager.sh https://raw.githubusercontent.com/Vaddum/vkbasalt-manager/main/vkbasalt-manager.sh && chmod +x vkbasalt-manager.sh && ./vkbasalt-manager.sh
```

## 🎮 Usage

### First Time Setup
1. Run the script - it will detect that VkBasalt is not installed
2. Choose "Yes" to proceed with automatic installation
3. Wait for the installation to complete (downloads ~50MB)
4. The script will create a desktop shortcut for future use

### Enabling VkBasalt in Steam Games
1. Right-click on a game in Steam → **Properties**
2. In **Launch Options**, add: `ENABLE_VKBASALT=1 %command%`
3. Launch the game
4. Press **Home** key (or your configured toggle key) to enable/disable effects

### Managing Shaders
1. Launch **VkBasalt Manager** from desktop or run the script
2. Select **"Shaders"** to manage active effects
3. Use Ctrl+Click to select multiple effects
4. Built-in effects (CAS, FXAA, SMAA, DLS) are always available
5. Additional ReShade shaders are automatically detected

### Advanced Configuration
- **Toggle Key**: Change the in-game key for enabling/disabling effects
- **Advanced Settings**: Fine-tune parameters for built-in effects
- **View Configuration**: Inspect the current VkBasalt configuration file
- **Reset**: Restore default settings

## 🎨 Available Effects

### Built-in VkBasalt Effects (High Performance)
- **CAS (Contrast Adaptive Sharpening)**: AMD's intelligent sharpening
- **FXAA**: Fast anti-aliasing for smooth edges
- **SMAA**: High-quality anti-aliasing (better than FXAA)
- **DLS (Denoised Luma Sharpening)**: Advanced noise-free sharpening

### ReShade Shader Library
- **Visual Enhancement**: Clarity, Vibrance, Technicolor
- **Retro Effects**: CRT, Film Grain, Sepia, Nostalgia
- **Color Correction**: Curves, Levels, Lift-Gamma-Gain
- **Special Effects**: Chromatic Aberration, Vignette, Border
- **Accessibility**: Daltonize (color blindness correction)
- **And many more...**

## 🔧 Configuration Files

- **Main Config**: `/home/deck/.config/vkBasalt/vkBasalt.conf`
- **Shaders**: `/home/deck/.config/reshade/Shaders/`
- **Textures**: `/home/deck/.config/reshade/Textures/`
- **Script Location**: `/home/deck/.config/vkBasalt/vkbasalt-manager.sh`

## ⌨️ Default Controls

- **Toggle Key**: Home (customizable)
- **In-Game**: Press toggle key to enable/disable all effects
- **No Performance Impact**: When disabled, zero overhead

## 🎯 Performance Tips

1. **Start Simple**: Begin with just CAS for sharpening
2. **Built-in First**: VkBasalt's native effects are more optimized
3. **Monitor FPS**: Some ReShade shaders can impact performance
4. **Order Matters**: Effects are applied in the order listed
5. **Test Different Games**: Some effects work better with certain art styles

## 🔍 Troubleshooting

### VkBasalt Not Working
- Ensure launch option is set: `ENABLE_VKBASALT=1 %command%`
- Check if the game uses Vulkan (VkBasalt only works with Vulkan games)
- Verify installation with **Status** option in the manager

### No Visible Effects
- Press the toggle key (Home by default) in-game
- Check that effects are enabled in the shader selection
- Some effects are subtle - try CAS with high sharpening for testing

### Performance Issues
- Disable heavy effects like SMAA or complex ReShade shaders
- Use only CAS or FXAA for minimal performance impact
- Monitor GPU temperature on Steam Deck

### GUI Issues
- The script automatically installs Zenity if missing
- Run in Desktop mode for best experience
- Check that you have internet connection for initial setup

## 🗑️ Uninstallation

The manager provides complete uninstallation:
1. Launch VkBasalt Manager
2. Select **"Uninstall"**
3. Confirm the removal (this action is irreversible)
4. Manually remove `ENABLE_VKBASALT=1` from Steam game launch options

## 📁 File Structure After Installation

```
/home/deck/
├── .config/
│   ├── vkBasalt/
│   │   ├── vkBasalt.conf              # Main configuration
│   │   ├── vkbasalt-manager.sh        # This script
│   │   └── vkbasalt-manager.svg       # Icon
│   └── reshade/
│       ├── Shaders/                   # ReShade shader files
│       └── Textures/                  # Shader textures
├── .local/
│   ├── lib/
│   │   └── libvkbasalt.so             # VkBasalt library (64-bit)
│   ├── lib32/
│   │   └── libvkbasalt.so             # VkBasalt library (32-bit)
│   └── share/vulkan/implicit_layer.d/
│       ├── vkBasalt.json              # Vulkan layer registration
│       └── vkBasalt.x86.json          # 32-bit layer registration
└── Desktop/
    └── VkBasalt-Manager.desktop       # Desktop shortcut
```

## 🎮 Compatible Games

VkBasalt works with any game that uses the Vulkan graphics API. Popular Vulkan games on Steam Deck include:

- **AAA Titles**: Cyberpunk 2077, Red Dead Redemption 2, Control
- **Indie Games**: Many modern indie titles use Vulkan
- **Emulation**: RetroArch, PCSX2, RPCS3 (when using Vulkan backend)

**Note**: OpenGL and DirectX games are not supported by VkBasalt.

## 🛡️ Safety and Compatibility

- **Non-invasive**: VkBasalt doesn't modify game files
- **VAC Safe**: Post-processing layers are generally considered safe
- **Reversible**: Can be completely disabled or uninstalled
- **Steam Deck Optimized**: Designed specifically for Steam Deck's hardware

## 🤝 Contributing

This script is based on the VkBasalt project and various community contributions. Feel free to report issues or suggest improvements.

## 📜 License

This script is provided as-is for the Steam Deck community. VkBasalt itself is licensed under the zlib License.

## 🔗 Related Projects

- **VkBasalt**: [https://github.com/DadSchoorse/vkBasalt](https://github.com/DadSchoorse/vkBasalt)
- **ReShade**: [https://reshade.me/](https://reshade.me/)
- **Steam Deck VkBasalt Install**: [https://github.com/simons-public/steam-deck-vkbasalt-install](https://github.com/simons-public/steam-deck-vkbasalt-install)

## 📞 Support

For issues specific to this manager script, please check the troubleshooting section first. For VkBasalt-related issues, refer to the official VkBasalt documentation and community.

---

**Enjoy enhanced gaming visuals on your Steam Deck! 🎮✨**
