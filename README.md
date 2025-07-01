# 🎮 VkBasalt Manager for Steam Deck

<div align="center">

![Steam Deck](https://img.shields.io/badge/Platform-Steam%20Deck-1e2328?style=for-the-badge&logo=steamdeck&logoColor=white)
![Vulkan](https://img.shields.io/badge/API-Vulkan-AC162C?style=for-the-badge&logo=vulkan&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-1.1-blue?style=for-the-badge)

</div>

A comprehensive installation and configuration tool for VkBasalt on Steam Deck, providing an intuitive interface to enhance your gaming visuals with post-processing effects including 4 ReShade shaders.

## ✨ Features

- 🚀 **Complete Installation**: Automated VkBasalt and shader installation
- 🎨 **Preset Configurations**: Ready-to-use visual enhancement presets
- ⚙️ **Advanced Configuration**: Fine-tune individual shader parameters
- 💾 **Backup Management**: Create, restore, and manage configuration backups
- 🎯 **User-Friendly Interface**: Colorful terminal interface with clear navigation

## 🔍 What is VkBasalt?

VkBasalt is a Vulkan post-processing layer that allows you to apply various visual effects to Vulkan games, including:

| Effect | Description | Icon |
|--------|-------------|------|
| **CAS** | Contrast Adaptive Sharpening - Enhanced image sharpness | 🔪 |
| **SMAA** | Enhanced Anti-Aliasing - Smooth edge rendering | 🧽 |
| **FXAA** | Fast Approximate Anti-Aliasing - Quick anti-aliasing | ⚡ |
| **LumaSharpen** | Luminance-based sharpening | ✨ |
| **Vibrance** | Color saturation enhancement | 🌈 |
| **DPX** | Digital Picture Exchange color grading | 🎬 |
| **Clarity** | Image clarity enhancement | 🔍 |

## 📦 Installation

### 🚀 Quick Start

1. **Download** the script to your Steam Deck:
   ```bash
   wget https://github.com/Vaddum/vkbasalt-manager/raw/main/vkbasalt_manager.sh
   chmod +x vkbasalt_manager.sh
   ```

2. **Run** the manager:
   ```bash
   ./vkbasalt_manager.sh
   ```

3. **Select** option `1` to install VkBasalt and the 4 included shaders

### 📋 What Gets Installed

- ⚙️ **VkBasalt libraries** (64-bit and 32-bit)
- 🔧 **Vulkan layer configuration**
- 🎨 **Collection of 4 ReShade shaders**
- 📄 **Default configuration file**

## 🎮 Usage

### 🎯 Enabling VkBasalt for Games

1. 🖥️ Open Steam in **Desktop Mode**
2. 🖱️ Right-click your game → **Properties**
3. ⌨️ In **Launch Options**, add:
   ```
   ENABLE_VKBASALT=1 %command%
   ```

### 🎛️ Controls

- 🔄 **Toggle Effects**: `Home` key (default, configurable)
- 🎮 Effects can be toggled on/off during gameplay

## ⚙️ Configuration Options

### 📋 Main Menu

| Option | Description | Icon |
|--------|-------------|------|
| **Install VkBasalt and 4 ReShade shaders** | Complete automated installation | 📦 |
| **Configure VkBasalt** | Access configuration options | ⚙️ |
| **Usage Information** | Help and file locations | ℹ️ |
| **Check Installation Status** | Verify installation | ✅ |
| **Uninstall Everything** | Complete removal | 🗑️ |

### 🎨 Preset Configurations (using the 4 included ReShade shaders)

#### 1. 🏁 Performance (Light Effects)
- **Effects**: CAS + FXAA + SMAA
- **Focus**: Minimal performance impact
- **Best for**: Competitive gaming, lower-end hardware

#### 2. ⭐ Quality (Enhanced Visuals)
- **Effects**: CAS + SMAA + LumaSharpen + Vibrance
- **Focus**: Balanced quality and performance
- **Best for**: General gaming

#### 3. 🎬 Cinematic (Film Look)
- **Effects**: DPX + Vibrance
- **Focus**: Movie-like visual style
- **Best for**: Story-driven games, screenshots

#### 4. 🎯 Minimal (Sharpness Only)
- **Effects**: CAS only
- **Focus**: Basic sharpening
- **Best for**: Maximum performance

#### 5. 🌟 Complete (All Effects)
- **Effects**: All available shaders
- **Focus**: Maximum visual enhancement
- **Best for**: High-end hardware, single-player games

### 🔧 Advanced Settings

Fine-tune individual shader parameters:

#### 🔪 CAS (Contrast Adaptive Sharpening)
- **Sharpness**: `0.0 - 1.0` (default: `0.4`)

#### 🎬 DPX (Digital Picture Exchange)
- **Saturation**: `1.0 - 5.0` (default: `3.0`)
- **Color Gamma**: `1.0 - 4.0` (default: `2.5`)
- **Contrast**: `-1.0 - 1.0` (default: `0.1`)

#### 🧽 SMAA (Enhanced Anti-Aliasing)
- **Edge Detection**: `luma/color/depth` (default: `luma`)
- **Threshold**: `0.01 - 0.20` (default: `0.05`)
- **Max Search Steps**: `8 - 64` (default: `32`)
- **Max Search Steps Diagonal**: `4 - 32` (default: `16`)
- **Corner Rounding**: `0 - 100` (default: `25`)

#### ⚡ FXAA (Fast Approximate Anti-Aliasing)
- **Quality Subpix**: `0.0 - 1.0` (default: `0.75`)
- **Edge Threshold**: `0.063 - 0.333` (default: `0.125`)
- **Edge Threshold Min**: `0.0 - 0.0833` (default: `0.0312`)

#### 🌈 Vibrance
- **Strength**: `-1.0 - 1.0` (default: `0.15`)

#### ✨ LumaSharpen
- **Strength**: `0.0 - 3.0` (default: `0.65`)
- **Clamp**: `0.0 - 1.0` (default: `0.035`)

#### 🔍 Clarity
- **Radius**: `1 - 8` (default: `3`)
- **Offset**: `0.0 - 10.0` (default: `2.0`)
- **Strength**: `0.0 - 1.0` (default: `0.4`)

## 📁 File Locations

| Type | Path | Description |
|------|------|-------------|
| 📄 **Configuration** | `/home/deck/.config/vkBasalt/vkBasalt.conf` | Main config file |
| 🎨 **Shaders** | `/home/deck/.config/reshade/Shaders` | Shader files |
| 🖼️ **Textures** | `/home/deck/.config/reshade/Textures` | Texture files |
| 💾 **Backup** | `/home/deck/.config/vkBasalt/vkBasalt.conf.backup` | Backup config |

## 💾 Backup Management

- 📝 **Create Backup**: Save current configuration
- 🔄 **Restore from Backup**: Revert to saved configuration
- 🗑️ **Delete Backup**: Remove backup file

> ⚠️ All configuration changes automatically create backups for safety.

## 🛠️ Troubleshooting

### ❌ VkBasalt Not Working

1. 🎮 **Check Game Compatibility**: VkBasalt only works with Vulkan games
2. ⚙️ **Verify Launch Options**: Ensure `ENABLE_VKBASALT=1 %command%` is added
3. ✅ **Check Installation**: Use option `4` to verify installation status
4. 🔄 **Toggle Key**: Try pressing the toggle key (default: Home) during gameplay

### 🐌 Performance Issues

1. 🏁 **Use Performance Preset**: Switch to lighter effect combinations
2. ❌ **Disable Heavy Effects**: Avoid DPX and Clarity for better performance
3. ⬇️ **Lower Settings**: Reduce shader intensity values
4. 📊 **Check GPU Load**: Monitor GPU usage during gameplay

### ⚙️ Configuration Issues

1. 🔄 **Reset to Defaults**: Use option `6` in Configuration Menu
2. 💾 **Restore Backup**: Use Backup Management to revert changes
3. ✏️ **Manual Edit**: Configuration file is located at the path shown in Usage Information

## 🎯 Compatibility

| Category | Status | Details |
|----------|--------|---------|
| 🖥️ **Platform** | ✅ Supported | Steam Deck (SteamOS) |
| 🎮 **Games** | ⚠️ Limited | Vulkan-based games only |
| 🍷 **Proton** | ✅ Compatible | Works with Proton games |
| 🐧 **Native Linux** | ✅ Compatible | Works with native Linux games |

## 🗑️ Uninstallation

To completely remove VkBasalt:

1. 🚀 Run the manager script
2. 5️⃣ Select option `5` - Uninstall Everything
3. ❌ Remove `ENABLE_VKBASALT=1` from game launch options

This will remove:
- 📚 VkBasalt libraries
- 🔧 Vulkan layers
- 📄 Configuration files
- 🎨 Shader files

## 🤝 Contributing

This tool automates the installation and configuration of:
- 🛠️ [VkBasalt](https://github.com/DadSchoorse/vkBasalt) by DadSchoorse
- 🎨 4 shaders from various ReShade contributors

## 📜 License

This management script is provided as-is for educational and convenience purposes. Please respect the licenses of the underlying projects (VkBasalt and individual shaders).

## 🆘 Support

For issues related to:

| Issue Type | Action | Icon |
|------------|--------|------|
| **This script** | Check troubleshooting section or create an issue | 🐛 |
| **VkBasalt itself** | Visit the [official VkBasalt repository](https://github.com/DadSchoorse/vkBasalt) | 🛠️ |
| **Individual shaders** | Check respective shader documentation | 📖 |

---

<div align="center">

> ⚠️ **Note**: VkBasalt may impact game performance. Start with lighter presets and adjust based on your hardware capabilities.

**Made with ❤️ for the Steam Deck community**

</div>
