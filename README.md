# VkBasalt Manager for Steam Deck

<div align="center">

![VkBasalt Manager](https://img.shields.io/badge/VkBasalt-Manager-orange?style=for-the-badge)
![Steam Deck](https://img.shields.io/badge/Steam-Deck-blue?style=for-the-badge)
![Vulkan](https://img.shields.io/badge/Vulkan-API-red?style=for-the-badge)

**🎮 All-in-One VkBasalt Management Tool for Steam Deck**

*Complete graphical interface for installation, configuration, and management of VkBasalt with ReShade shaders*

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Shaders](#-available-shaders) • [FAQ](#-faq)

</div>

---

## 🚀 Features

### **Unified Management**
- 🔄 **Auto-detection** - Automatically detects existing VkBasalt installation
- 📦 **One-click installation** - Downloads and installs VkBasalt + shaders + configuration
- ⚙️ **Advanced configuration** - Graphical interface with sliders for all shader parameters
- 🗑️ **Complete uninstallation** - Clean removal options (partial or complete)

### **Smart Configuration**
- 🎯 **Preset configurations** - Performance, Quality, Cinematic, Minimal, Complete
- 🎨 **Shader management** - Enable/disable individual shaders with checkboxes
- 🔧 **Advanced tweaking** - Fine-tune each shader with visual sliders
- 💾 **Backup system** - Create, restore, and manage configuration backups
- 🎮 **Toggle key customization** - Change the in-game toggle key

### **User Experience**
- 🖥️ **Zenity GUI** - Modern graphical interface, no terminal required
- 🔄 **Progress indicators** - Visual feedback for all operations
- 📋 **Status monitoring** - Check installation status and shader count
- 📖 **Built-in help** - Complete usage instructions included

---

## 📋 Requirements

- **Steam Deck** running SteamOS
- **Internet connection** (for initial installation)
- **Vulkan games** (VkBasalt only works with Vulkan API)

---

## 📥 Installation

### Method 1: Quick Install (Recommended)

```bash
# Download and run the installer
curl -L https://github.com/[your-repo]/vkbasalt-manager/raw/main/vkbasalt-manager.sh -o vkbasalt-manager.sh
chmod +x vkbasalt-manager.sh
./vkbasalt-manager.sh
```

### Method 2: Manual Download

1. Download `vkbasalt-manager.sh` from the releases page
2. Make it executable: `chmod +x vkbasalt-manager.sh`
3. Run it: `./vkbasalt-manager.sh`

### First Launch

On first launch, the script will:
1. **Detect** if VkBasalt is installed
2. **Offer automatic installation** if not found
3. **Download** VkBasalt, ReShade shaders, and create desktop shortcuts
4. **Create** a default configuration ready to use

---

## 🎮 Usage

### Activating VkBasalt in Games

1. **Open Steam** in Desktop mode
2. **Right-click** on your game → **Properties**
3. **Add to Launch Options**: `ENABLE_VKBASALT=1 %command%`
4. **Launch the game**
5. **Press Home key** to toggle effects on/off

### Managing Configurations

#### **Quick Presets**
- **Performance**: CAS + FXAA + SMAA (light effects, better FPS)
- **Quality**: CAS + SMAA + LumaSharpen + Vibrance (enhanced visuals)
- **Cinematic**: DPX + Vibrance (movie-like appearance)
- **Minimal**: CAS only (subtle sharpening)
- **Complete**: All shaders enabled (maximum enhancement)

#### **Custom Configuration**
1. Open **VkBasalt Manager** from desktop
2. Select **"Shaders"** to enable/disable individual effects
3. Use **"Advanced"** for detailed parameter tweaking
4. **Backup** your configuration before major changes

### Toggle Key Options

Change the in-game toggle key through **Configuration → Toggle Key**:
- **Home** (default, recommended)
- **F1-F12** function keys
- **Insert**, **Delete**, **Page Up/Down**
- **Print Screen**, **Pause**, **Menu**

---

## 🎨 Available Shaders

| Shader | Description | Performance Impact | Best For |
|--------|-------------|-------------------|----------|
| **CAS** | AMD Contrast Adaptive Sharpening | Low | All games, subtle enhancement |
| **FXAA** | Fast Approximate Anti-Aliasing | Low | Smooth edges, reduce jaggies |
| **SMAA** | Subpixel Morphological Anti-Aliasing | Medium | High-quality edge smoothing |
| **LumaSharpen** | Luminance-based sharpening | Low | Text clarity, detail enhancement |
| **Vibrance** | Smart color saturation | Low | More vivid colors without oversaturation |
| **DPX** | Digital Picture Exchange (Cinema look) | Medium | Movie-like color grading |
| **Clarity** | Local contrast enhancement | Medium | Enhanced detail perception |

### Shader Parameters

Each shader can be fine-tuned with sliders:

- **CAS**: Sharpness intensity (0-100%)
- **FXAA**: Subpixel quality, edge threshold
- **SMAA**: Detection mode, threshold, search steps
- **LumaSharpen**: Strength, clamp value
- **Vibrance**: Saturation strength
- **DPX**: Saturation, gamma, contrast
- **Clarity**: Radius, offset, strength

---

## 🔧 Configuration Management

### Backup System
- **Create backup**: Save current configuration before changes
- **Restore backup**: Return to previous working configuration
- **Delete backup**: Remove stored backup files

### Reset Options
- **Reset to defaults**: Return to CAS-only configuration
- **Remove configurations**: Delete config files but keep VkBasalt
- **Factory reset**: Complete removal and reinstallation

### File Locations
```
Configuration: /home/deck/.config/vkBasalt/vkBasalt.conf
Backup:        /home/deck/.config/vkBasalt/vkBasalt.conf.backup
Shaders:       /home/deck/.config/reshade/Shaders/
Textures:      /home/deck/.config/reshade/Textures/
```

---

## 🗑️ Uninstallation

The manager provides three uninstall options:

### **Manager Only**
- Removes VkBasalt Manager interface
- Keeps VkBasalt and configurations
- Use if you only want to remove the GUI

### **Complete Removal**
- Removes everything: Manager + VkBasalt + shaders + configs
- Clean system state
- **⚠️ Irreversible action**

### **Configuration Only**
- Removes config files and backups
- Keeps VkBasalt Manager and VkBasalt installed
- Use for troubleshooting config issues

---

## ❓ FAQ

### **Q: Which games support VkBasalt?**
A: Only games using the **Vulkan graphics API**. Most modern games on Steam Deck support Vulkan, but older DirectX games won't work.

### **Q: Does VkBasalt affect performance?**
A: Impact varies by shader:
- **Low impact**: CAS, FXAA, LumaSharpen, Vibrance
- **Medium impact**: SMAA, DPX, Clarity
- Use **Performance preset** for minimal impact

### **Q: Can I use VkBasalt with Proton games?**
A: Yes! VkBasalt works with both native Linux games and Windows games running through Proton, as long as they use Vulkan.

### **Q: The toggle key doesn't work in-game**
A: Try these solutions:
1. Ensure the game uses Vulkan (check game properties)
2. Verify `ENABLE_VKBASALT=1 %command%` is in launch options
3. Try a different toggle key (F1-F12 often work better)
4. Check that shaders are actually enabled in configuration

### **Q: How do I know if VkBasalt is working?**
A: 1. Launch a Vulkan game with VkBasalt enabled
2. Press the toggle key (Home by default)
3. You should see a visible difference in image quality
4. Some shaders like CAS provide subtle improvements

### **Q: Can I create custom shader combinations?**
A: Yes! Use the **"Shaders"** menu to select any combination of available shaders. Each combination can be fine-tuned in the **"Advanced"** settings.

### **Q: Installation fails with download errors**
A: Check your internet connection and try again. The installer downloads from GitHub and may be temporarily unavailable.

---

## 🛠️ Troubleshooting

### **VkBasalt not working in games:**
1. Verify Vulkan support: `vulkaninfo | grep deviceName`
2. Check launch options: `ENABLE_VKBASALT=1 %command%`
3. Test with a known Vulkan game (e.g., DOOM Eternal)
4. Check shader configuration is not empty

### **Manager won't start:**
1. Ensure you're running on Steam Deck (`/home/deck` exists)
2. Install Zenity: `sudo pacman -S zenity`
3. Check script permissions: `chmod +x vkbasalt-manager.sh`

### **Performance issues:**
1. Use **Performance preset** for lighter effects
2. Disable heavy shaders (DPX, Clarity, SMAA)
3. Reduce shader parameters in **Advanced** settings
4. Monitor FPS before/after enabling effects

---

## 📄 License

This project is open source and available under the MIT License.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to:
- Report bugs via GitHub issues
- Suggest new features
- Submit pull requests
- Improve documentation

---

## 🙏 Credits

- **VkBasalt**: [DadSchoorse/vkBasalt](https://github.com/DadSchoorse/vkBasalt)
- **Steam Deck VkBasalt Installer**: [simons-public/steam-deck-vkbasalt-install](https://github.com/simons-public/steam-deck-vkbasalt-install)
- **ReShade Shaders**: [Vaddum/vkbasalt-manager](https://github.com/Vaddum/vkbasalt-manager)
- **Zenity**: GNOME Project

---

<div align="center">

**Made with ❤️ for the Steam Deck community**

*Enhance your gaming experience with beautiful post-processing effects!*

</div>
