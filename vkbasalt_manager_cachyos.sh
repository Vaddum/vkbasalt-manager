#!/bin/bash

# VkBasalt Manager - CachyOS Version
# Complete installation, configuration and management tool for CachyOS using Paru

# System paths for CachyOS
USER_HOME="$HOME"
SYSTEM_USER="$(whoami)"

CONFIG_FILE="${USER_HOME}/.config/vkBasalt/vkBasalt.conf"
SHADER_PATH="${USER_HOME}/.config/reshade/Shaders"
TEXTURE_PATH="${USER_HOME}/.config/reshade/Textures"
SCRIPT_PATH="${USER_HOME}/.config/vkBasalt/vkbasalt-manager.sh"
ICON_PATH="${USER_HOME}/.config/vkBasalt/vkbasalt-manager.svg"

# Desktop file locations for CachyOS (both desktop and applications)
DESKTOP_FILE="${USER_HOME}/Desktop/VkBasalt-Manager.desktop"
DESKTOP_FILE_APPS="${USER_HOME}/.local/share/applications/VkBasalt-Manager.desktop"

# Create necessary directories
mkdir -p "${USER_HOME}/Desktop" "${USER_HOME}/.local/share/applications"

# Check and install dependencies
check_dependencies() {
    local missing_deps=()

    # Check required tools
    if ! command -v zenity &> /dev/null; then
        missing_deps+=("zenity")
    fi

    if ! command -v wget &> /dev/null; then
        missing_deps+=("wget")
    fi

    if ! command -v unzip &> /dev/null; then
        missing_deps+=("unzip")
    fi

    if ! command -v tar &> /dev/null; then
        missing_deps+=("tar")
    fi

    # Check if paru is available
    if ! command -v paru &> /dev/null; then
        echo "ERROR: Paru is not installed. Please install paru first."
        echo "Run: sudo pacman -S paru"
        exit 1
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Installing missing dependencies: ${missing_deps[*]}"
        # CachyOS with Paru - no sudo needed for paru
        paru -S --noconfirm "${missing_deps[@]}"
    fi
}

# Dialog functions
show_error() { zenity --error --text="$1" --width=480 --height=140; }
show_info() { zenity --info --text="$1" --width=480 --height=140; }
show_question() { zenity --question --text="$1" --width=480 --height=140; }

# Check installation status
check_installation() {
    local vkbasalt_installed=false
    local shaders_installed=false

    # Check VkBasalt core files (both user local and system installation)
    if [ -f "${USER_HOME}/.local/lib/libvkbasalt.so" ] && [ -f "${USER_HOME}/.local/lib32/libvkbasalt.so" ]; then
        vkbasalt_installed=true
    elif [ -f "/usr/lib/libvkbasalt.so" ] && [ -f "/usr/lib32/libvkbasalt.so" ]; then
        vkbasalt_installed=true
    fi

    # Check shaders
    if [ -d "$SHADER_PATH" ] && [ "$(ls -A $SHADER_PATH 2>/dev/null)" ]; then
        shaders_installed=true
    fi

    # Return status (0=not installed, 1=partially installed, 2=fully installed)
    if [ "$vkbasalt_installed" = true ] && [ "$shaders_installed" = true ]; then
        return 2
    elif [ "$vkbasalt_installed" = true ]; then
        return 1
    else
        return 0
    fi
}

# Move script to final location
move_script_to_final_location() {
    local current_script="$(realpath "$0")"
    if [ "$current_script" != "$SCRIPT_PATH" ]; then
        cp "$current_script" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        chown "${SYSTEM_USER}:${SYSTEM_USER}" "$SCRIPT_PATH" 2>/dev/null || true

        # Update the Exec path in both desktop files
        if [ -f "$DESKTOP_FILE" ]; then
            sed -i "s|Exec=.*|Exec=$SCRIPT_PATH|" "$DESKTOP_FILE"
        fi
        
        if [ -f "$DESKTOP_FILE_APPS" ]; then
            sed -i "s|Exec=.*|Exec=$SCRIPT_PATH|" "$DESKTOP_FILE_APPS"
        fi

        return 0
    fi
    return 1
}

# Get VkBasalt package source (prioritize official repos, fallback to AUR)
get_vkbasalt_source() {
    # Check if VkBasalt is available in official repositories
    if paru -Ss "^vkbasalt$" 2>/dev/null | grep -q "^extra/\|^community/\|^core/\|^multilib/"; then
        echo "REPO"
    else
        echo "AUR"
    fi
}

# Install VkBasalt from official repositories
install_vkbasalt_repo() {
    echo "# Installing VkBasalt from official repositories..."

    if ! paru -S --noconfirm vkbasalt lib32-vkbasalt; then
        echo "ERROR: Failed to install VkBasalt from repositories"
        return 1
    fi

    # Create user directories for consistency
    mkdir -p "${USER_HOME}/.local/lib" "${USER_HOME}/.local/lib32" "${USER_HOME}/.local/share/vulkan/implicit_layer.d"
    mkdir -p "${USER_HOME}/.config/vkBasalt" "${USER_HOME}/.config/reshade"

    # Create symlinks in user directory pointing to system libraries
    local vkbasalt_lib=$(find /usr/lib -name "libvkbasalt.so" 2>/dev/null | head -1)
    local vkbasalt_lib32=$(find /usr/lib32 -name "libvkbasalt.so" 2>/dev/null | head -1)

    if [ -n "$vkbasalt_lib" ]; then
        ln -sf "$vkbasalt_lib" "${USER_HOME}/.local/lib/libvkbasalt.so"
    fi

    if [ -n "$vkbasalt_lib32" ]; then
        ln -sf "$vkbasalt_lib32" "${USER_HOME}/.local/lib32/libvkbasalt.so"
    fi

    # Copy and configure Vulkan layer files
    if [ -f "/usr/share/vulkan/implicit_layer.d/vkBasalt.json" ]; then
        cp "/usr/share/vulkan/implicit_layer.d/vkBasalt.json" "${USER_HOME}/.local/share/vulkan/implicit_layer.d/"
        sed -i "s|/usr/lib/libvkbasalt.so|${USER_HOME}/.local/lib/libvkbasalt.so|" "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.json"
        sed -i "s/ENABLE_VKBASALT/ENABLE_VKBASALT/" "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.json"
    fi

    if [ -f "/usr/share/vulkan/implicit_layer.d/vkBasalt.x86.json" ]; then
        cp "/usr/share/vulkan/implicit_layer.d/vkBasalt.x86.json" "${USER_HOME}/.local/share/vulkan/implicit_layer.d/"
        sed -i "s|/usr/lib32/libvkbasalt.so|${USER_HOME}/.local/lib32/libvkbasalt.so|" "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json"
        sed -i "s/ENABLE_VKBASALT/ENABLE_VKBASALT/" "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json"
    fi

    # Copy example config if available
    if [ -f "/usr/share/vkBasalt/vkBasalt.conf.example" ]; then
        cp "/usr/share/vkBasalt/vkBasalt.conf.example" "${USER_HOME}/.config/vkBasalt/"
        sed -i -e "s|/opt/reshade/textures|${USER_HOME}/.config/reshade/Textures|" \
               -e "s|/opt/reshade/shaders|${USER_HOME}/.config/reshade/Shaders|" \
               "${USER_HOME}/.config/vkBasalt/vkBasalt.conf.example"
    fi

    # Set permissions
    chown -R "${SYSTEM_USER}:${SYSTEM_USER}" "${USER_HOME}/.local/lib" "${USER_HOME}/.local/lib32" "${USER_HOME}/.local/share" "${USER_HOME}/.config/vkBasalt" "${USER_HOME}/.config/reshade" 2>/dev/null || true

    return 0
}

# Install VkBasalt from AUR
install_vkbasalt_aur() {
    echo "# Installing VkBasalt from AUR..."

    if ! paru -S --noconfirm vkbasalt lib32-vkbasalt; then
        echo "ERROR: Failed to install VkBasalt from AUR"
        return 1
    fi

    # Create user directories
    mkdir -p "${USER_HOME}/.local/lib" "${USER_HOME}/.local/lib32" "${USER_HOME}/.local/share/vulkan/implicit_layer.d"
    mkdir -p "${USER_HOME}/.config/vkBasalt" "${USER_HOME}/.config/reshade"

    # Create symlinks to installed libraries
    local vkbasalt_lib=$(find /usr/lib -name "libvkbasalt.so" 2>/dev/null | head -1)
    local vkbasalt_lib32=$(find /usr/lib32 -name "libvkbasalt.so" 2>/dev/null | head -1)

    if [ -n "$vkbasalt_lib" ]; then
        ln -sf "$vkbasalt_lib" "${USER_HOME}/.local/lib/libvkbasalt.so"
    fi

    if [ -n "$vkbasalt_lib32" ]; then
        ln -sf "$vkbasalt_lib32" "${USER_HOME}/.local/lib32/libvkbasalt.so"
    fi

    # Copy and configure Vulkan layer files
    if [ -f "/usr/share/vulkan/implicit_layer.d/vkBasalt.json" ]; then
        cp "/usr/share/vulkan/implicit_layer.d/vkBasalt.json" "${USER_HOME}/.local/share/vulkan/implicit_layer.d/"
        sed -i -e "s|/usr/lib/libvkbasalt.so|${USER_HOME}/.local/lib/libvkbasalt.so|" \
               -e "s/ENABLE_VKBASALT/ENABLE_VKBASALT/" \
               "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.json"
    fi

    if [ -f "/usr/share/vulkan/implicit_layer.d/vkBasalt.x86.json" ]; then
        cp "/usr/share/vulkan/implicit_layer.d/vkBasalt.x86.json" "${USER_HOME}/.local/share/vulkan/implicit_layer.d/"
        sed -i -e "s|/usr/lib32/libvkbasalt.so|${USER_HOME}/.local/lib32/libvkbasalt.so|" \
               -e "s/ENABLE_VKBASALT/ENABLE_VKBASALT/" \
               "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json"
    fi

    # Copy example config
    if [ -f "/usr/share/vkBasalt/vkBasalt.conf.example" ]; then
        cp "/usr/share/vkBasalt/vkBasalt.conf.example" "${USER_HOME}/.config/vkBasalt/"
        sed -i -e "s|/opt/reshade/textures|${USER_HOME}/.config/reshade/Textures|" \
               -e "s|/opt/reshade/shaders|${USER_HOME}/.config/reshade/Shaders|" \
               "${USER_HOME}/.config/vkBasalt/vkBasalt.conf.example"
    fi

    # Set permissions
    chown -R "${SYSTEM_USER}:${SYSTEM_USER}" "${USER_HOME}/.local/lib" "${USER_HOME}/.local/lib32" "${USER_HOME}/.local/share" "${USER_HOME}/.config/vkBasalt" "${USER_HOME}/.config/reshade" 2>/dev/null || true

    return 0
}

# Main installation function
install_vkbasalt_complete() {
    show_info "🚀 VkBasalt Manager Installation\n\nInstalling on: CachyOS (using Paru)\n\nThe installation will download and install:\n• VkBasalt\n• ReShade shaders\n• Default configurations\n• Graphical interface\n\nThis may take a few minutes..."

    (
        echo "10" ; echo "# System check..."
        mkdir -p "${USER_HOME}/Desktop" "${USER_HOME}/.config/vkBasalt" "${USER_HOME}/.config/reshade" 2>/dev/null || true

        echo "20" ; echo "# Checking dependencies..."
        check_dependencies 2>&1

        echo "30" ; echo "# Installing VkBasalt core..."
        local package_source=$(get_vkbasalt_source)

        if [ "$package_source" = "REPO" ]; then
            echo "# Using official repository packages..."
            if ! install_vkbasalt_repo 2>&1; then
                echo "# Repository installation failed, trying AUR..."
                if ! install_vkbasalt_aur 2>&1; then
                    echo "100" ; echo "# VkBasalt installation failed"
                    exit 1
                fi
            fi
        else
            echo "# Using AUR packages..."
            if ! install_vkbasalt_aur 2>&1; then
                echo "100" ; echo "# VkBasalt installation failed"
                exit 1
            fi
        fi

        echo "70" ; echo "# Downloading ReShade shaders..."
        local TMPDIR=$(mktemp -d)
        cd "$TMPDIR"
        if wget -q --timeout=30 https://github.com/Vaddum/vkbasalt-manager/archive/refs/heads/main.zip 2>/dev/null; then
            if unzip -q main.zip 2>/dev/null && [ -d "vkbasalt-manager-main/reshade" ]; then
                cp -rf vkbasalt-manager-main/reshade/* "${USER_HOME}/.config/reshade/" 2>/dev/null || true
            fi
        fi
        cd "${USER_HOME}" && rm -rf "$TMPDIR"

        echo "80" ; echo "# Creating default configuration..."
        create_default_config

        echo "85" ; echo "# Setting up manager interface..."
        move_script_to_final_location

        echo "90" ; echo "# Creating desktop icons..."
        create_icon_and_desktop

        echo "95" ; echo "# Setting permissions..."
        chmod +x "$SCRIPT_PATH" "$DESKTOP_FILE" "$DESKTOP_FILE_APPS" 2>/dev/null || true
        chown "${SYSTEM_USER}:${SYSTEM_USER}" "$SCRIPT_PATH" "$ICON_PATH" "$DESKTOP_FILE" "$DESKTOP_FILE_APPS" 2>/dev/null || true

        echo "100" ; echo "# Installation complete!"

    ) | zenity --progress --title="VkBasalt Manager Installation" --text="Preparing..." --percentage=0 --auto-close --width=420 --height=110

    if [ $? -eq 0 ] && ([ -f "${USER_HOME}/.local/lib/libvkbasalt.so" ] || [ -f "/usr/lib/libvkbasalt.so" ]); then
        local script_moved_msg=""
        if [ "$(realpath "$0")" != "$SCRIPT_PATH" ]; then
            script_moved_msg="\n\n📁 The script has been moved to: $SCRIPT_PATH\n💡 You can now delete the original script file."
        fi

        show_info "✅ Installation successful!$script_moved_msg\n\nVkBasalt Manager is now installed and ready to use.\n\n🔧 Use this manager to configure effects and settings.\n\n📱 Launch from Desktop or Applications menu."
        return 0
    else
        show_error "❌ Installation failed!\n\nPossible causes:\n• Network connection issues\n• Missing dependencies\n• Paru configuration issues\n\nPlease check your setup and try again."
        return 1
    fi
}

# Create desktop icon and shortcuts
create_icon_and_desktop() {
    cat > "$ICON_PATH" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">
  <defs>
    <radialGradient id="bgGrad" cx="50%" cy="30%" r="80%">
      <stop offset="0%" style="stop-color:#2c1810;stop-opacity:1" />
      <stop offset="70%" style="stop-color:#1a0f0a;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#0d0704;stop-opacity:1" />
    </radialGradient>
    <linearGradient id="stoneGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#4a4a4a;stop-opacity:1" />
      <stop offset="30%" style="stop-color:#2d2d2d;stop-opacity:1" />
      <stop offset="70%" style="stop-color:#1a1a1a;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#0f0f0f;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="cachyGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#00d4ff;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#0099cc;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#006699;stop-opacity:1" />
    </linearGradient>
  </defs>
  <circle cx="64" cy="64" r="60" fill="url(#bgGrad)"/>
  <g transform="translate(64,64)">
    <path d="M-35,-25 Q-25,-35 -10,-32 Q5,-38 20,-30 Q35,-25 40,-10 Q38,5 35,20 Q30,35 15,38 Q0,40 -15,35 Q-30,30 -38,15 Q-40,0 -35,-15 Z"
          fill="url(#stoneGrad)" stroke="#0a0a0a" stroke-width="1"/>
    <ellipse cx="-15" cy="-10" rx="8" ry="5" fill="#1f1f1f" opacity="0.6"/>
    <ellipse cx="12" cy="-18" rx="6" ry="4" fill="#1f1f1f" opacity="0.6"/>
    <ellipse cx="20" cy="8" rx="7" ry="6" fill="#1f1f1f" opacity="0.6"/>
    <ellipse cx="-8" cy="15" rx="5" ry="7" fill="#1f1f1f" opacity="0.6"/>
  </g>
  <g transform="translate(64,64)">
    <ellipse cx="0" cy="15" rx="12" ry="8" fill="url(#cachyGrad)" opacity="0.9"/>
    <circle cx="-18" cy="-8" r="4" fill="url(#cachyGrad)" opacity="0.8"/>
    <ellipse cx="22" cy="-5" rx="5" ry="3" fill="url(#cachyGrad)" opacity="0.8"/>
  </g>
  <text x="64" y="120" text-anchor="middle" font-family="Arial" font-size="10" fill="#00d4ff">CachyOS</text>
</svg>
EOF

    # Create the desktop file
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=VkBasalt Manager
Comment=VkBasalt manager with graphical interface for CachyOS
Exec=$SCRIPT_PATH
Icon=$ICON_PATH
Terminal=false
StartupNotify=true
NoDisplay=false
StartupWMClass=zenity
Categories=Game;Settings;
MimeType=
EOF

    # Create the applications menu file
    cat > "$DESKTOP_FILE_APPS" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=VkBasalt Manager
Comment=VkBasalt manager with graphical interface for CachyOS
Exec=$SCRIPT_PATH
Icon=$ICON_PATH
Terminal=false
StartupNotify=true
NoDisplay=false
StartupWMClass=zenity
Categories=Game;Settings;
MimeType=
EOF

    chmod +x "$DESKTOP_FILE" "$DESKTOP_FILE_APPS" 2>/dev/null || true
}

# Uninstall VkBasalt
uninstall_vkbasalt() {
    if show_question "🗑️ Uninstall VkBasalt?\n\n⚠️ WARNING: This will remove EVERYTHING:\n• VkBasalt Manager\n• VkBasalt itself\n• All configurations\n• All shaders\n\nThis action is IRREVERSIBLE!\n\nContinue?"; then
        (
            echo "10" ; echo "# Removing VkBasalt Manager..."
            rm -f "$SCRIPT_PATH" "$ICON_PATH" "$DESKTOP_FILE" "$DESKTOP_FILE_APPS"

            echo "30" ; echo "# Removing VkBasalt packages..."
            # Check if packages are installed and remove them
            if paru -Qs vkbasalt &>/dev/null; then
                echo "# Removing VkBasalt packages with paru..."
                paru -Rns --noconfirm vkbasalt lib32-vkbasalt 2>/dev/null || true
            fi

            echo "50" ; echo "# Removing user files..."
            rm -f "${USER_HOME}/.local/lib/libvkbasalt.so" "${USER_HOME}/.local/lib32/libvkbasalt.so"
            rm -f "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.json" "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json"

            echo "70" ; echo "# Removing configurations..."
            rm -rf "${USER_HOME}/.config/vkBasalt"

            echo "80" ; echo "# Removing shaders..."
            rm -rf "${USER_HOME}/.config/reshade"

            echo "90" ; echo "# Cleaning directories..."
            rmdir "${USER_HOME}/.local/share/vulkan/implicit_layer.d" "${USER_HOME}/.local/share/vulkan" "${USER_HOME}/.local/lib32" 2>/dev/null || true

            echo "100" ; echo "# Uninstallation complete"
        ) | zenity --progress --title="Uninstallation" --text="Removing all components..." --percentage=0 --auto-close --width=420 --height=110

        show_info "✅ Uninstallation finished!\n\nVkBasalt has been completely removed from your CachyOS system."
        exit 0
    fi
}

# Get shader description with proper display name
get_shader_description() {
    case "$1" in
        "cas"|"CAS") echo "⭐ AMD Adaptive Sharpening - Enhances details without artifacts (Built-in)" ;;
        "fxaa"|"FXAA") echo "⭐ Fast Anti-Aliasing - Smooths jagged edges quickly (Built-in)" ;;
        "smaa"|"SMAA") echo "⭐ High-quality Anti-Aliasing - Better than FXAA (Built-in)" ;;
        "dls"|"DLS") echo "⭐ Denoised Luma Sharpening - Intelligent sharpening without noise (Built-in)" ;;
        "4xbrz"|"4xBRZ") echo "🔴 4xBRZ - Complex pixel art upscaling algorithm for retro games" ;;
        "adaptivesharpen"|"AdaptiveSharpen") echo "🟠 Adaptive Sharpen - Smart edge-aware sharpening with minimal artifacts" ;;
        "border"|"Border") echo "🟢 Border - Adds customizable borders to fix edges" ;;
        "cartoon"|"Cartoon") echo "🟠 Cartoon - Creates cartoon-like edge enhancement" ;;
        "clarity"|"Clarity") echo "🔴 Clarity - Advanced sharpening with blur masking" ;;
        "crt"|"CRT"|"Crt") echo "🔴 CRT - Simulates old CRT monitor appearance" ;;
        "curves"|"Curves") echo "🟢 Curves - S-curve contrast without clipping" ;;
        "daltonize"|"Daltonize") echo "🟢 Daltonize - Color blindness correction filter" ;;
        "defring"|"Defring") echo "🟢 Defring - Removes chromatic aberration/fringing" ;;
        "dpx"|"DPX"|"Dpx") echo "🟠 DPX - Film-style color grading effect" ;;
        "fakehdr"|"FakeHDR"|"Fakehdr") echo "🔴 FakeHDR - Simulates HDR with bloom effects" ;;
        "filmgrain"|"FilmGrain"|"Filmgrain") echo "🟠 FilmGrain - Adds realistic film grain noise" ;;
        "levels"|"Levels") echo "🟢 Levels - Adjusts black/white points range" ;;
        "liftgammagain"|"LiftGammaGain"|"Liftgammagain") echo "🟢 LiftGammaGain - Pro shadows/midtones/highlights tool" ;;
        "lumasharpen"|"LumaSharpen"|"Lumasharpen") echo "🟠 LumaSharpen - Luminance-based detail enhancement" ;;
        "monochrome"|"Monochrome") echo "🟢 Monochrome - Black&White conversion with film presets" ;;
        "nostalgia"|"Nostalgia") echo "🟠 Nostalgia - Retro gaming visual style emulation" ;;
        "sepia"|"Sepia") echo "🟢 Sepia - Vintage sepia tone effect" ;;
        "smartsharp"|"SmartSharp"|"Smartsharp") echo "🔴 SmartSharp - Depth-aware intelligent sharpening" ;;
        "technicolor"|"Technicolor") echo "🟢 Technicolor - Classic vibrant film process look" ;;
        "tonemap"|"Tonemap") echo "🟢 Tonemap - Comprehensive tone mapping controls" ;;
        "vibrance"|"Vibrance") echo "🟢 Vibrance - Smart saturation enhancement tool" ;;
        "vignette"|"Vignette") echo "🟠 Vignette - Darkened edges camera lens effect" ;;
        *) echo "$1 - Available graphics effect" ;;
    esac
}

# Get proper display name for effect
get_display_name() {
    case "${1,,}" in
        "cas") echo "CAS" ;;
        "fxaa") echo "FXAA" ;;
        "smaa") echo "SMAA" ;;
        "dls") echo "DLS" ;;
        "4xbrz") echo "4xBRZ" ;;
        "adaptivesharpen") echo "AdaptiveSharpen" ;;
        "border") echo "Border" ;;
        "cartoon") echo "Cartoon" ;;
        "clarity") echo "Clarity" ;;
        "crt") echo "CRT" ;;
        "curves") echo "Curves" ;;
        "daltonize") echo "Daltonize" ;;
        "defring") echo "Defring" ;;
        "dpx") echo "DPX" ;;
        "fakehdr") echo "FakeHDR" ;;
        "filmgrain") echo "FilmGrain" ;;
        "levels") echo "Levels" ;;
        "liftgammagain") echo "LiftGammaGain" ;;
        "lumasharpen") echo "LumaSharpen" ;;
        "monochrome") echo "Monochrome" ;;
        "nostalgia") echo "Nostalgia" ;;
        "sepia") echo "Sepia" ;;
        "smartsharp") echo "SmartSharp" ;;
        "technicolor") echo "Technicolor" ;;
        "tonemap") echo "Tonemap" ;;
        "vibrance") echo "Vibrance" ;;
        "vignette") echo "Vignette" ;;
        *) echo "$1" ;;
    esac
}

# Shader management
manage_shaders() {
    local current_effects=""
    if [ -f "$CONFIG_FILE" ]; then
        current_effects=$(grep "^effects" "$CONFIG_FILE" | head -n1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    fi

    local checklist_items=()
    local current_effects_array=()
    if [ ! -z "$current_effects" ]; then
        IFS=':' read -ra current_effects_array <<< "$current_effects"
    fi

    is_effect_enabled() {
        local effect_to_check="$1"
        for active_effect in "${current_effects_array[@]}"; do
            active_effect=$(echo "$active_effect" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            if [[ "${active_effect,,}" == "${effect_to_check,,}" ]]; then
                return 0
            fi
        done
        return 1
    }

    local builtin_effects=("CAS" "FXAA" "SMAA" "DLS")
    for shader_name in "${builtin_effects[@]}"; do
        local lowercase_name="${shader_name,,}"
        local enabled="FALSE"
        is_effect_enabled "$lowercase_name" && enabled="TRUE"
        local display_name=$(get_display_name "$shader_name")
        local description=$(get_shader_description "$shader_name")
        checklist_items+=("$enabled" "$display_name" "$description")
    done

    if [ -d "$SHADER_PATH" ]; then
        for file in "$SHADER_PATH"/*.fx; do
            [ -f "$file" ] || continue
            local file_basename=$(basename "$file" .fx)

            local is_builtin=false
            for builtin in "${builtin_effects[@]}"; do
                if [[ "${file_basename,,}" == "${builtin,,}" ]]; then
                    is_builtin=true
                    break
                fi
            done

            if [ "$is_builtin" = false ]; then
                local enabled="FALSE"
                is_effect_enabled "${file_basename}" && enabled="TRUE"
                local display_name=$(get_display_name "$file_basename")
                local description=$(get_shader_description "$file_basename")
                checklist_items+=("$enabled" "$display_name" "$description")
            fi
        done
    fi

    if [ ${#checklist_items[@]} -eq 0 ]; then
        show_error "No effects available"
        return
    fi

    local selected_shaders
    selected_shaders=$(zenity --list --title="VkBasalt Effects Selection" --text="Select effects to enable (Ctrl+Click for multiple):" --checklist --column="Enable" --column="Effect" --column="Description" --width=900 --height=500 --separator=":" "${checklist_items[@]}" 2>/dev/null)

    if [ $? -eq 0 ]; then
        if [ -z "$selected_shaders" ]; then
            if show_question "No effects selected. Disable all effects?"; then
                create_minimal_config
                show_info "All effects disabled"
            fi
        else
            # Convert display names back to config names (lowercase)
            local config_shaders=""
            IFS=':' read -ra SELECTED_ARRAY <<< "$selected_shaders"
            for display_shader in "${SELECTED_ARRAY[@]}"; do
                # Convert display name back to lowercase for config
                local config_name="${display_shader,,}"
                # Handle special cases
                case "$display_shader" in
                    "CAS") config_name="cas" ;;
                    "FXAA") config_name="fxaa" ;;
                    "SMAA") config_name="smaa" ;;
                    "DLS") config_name="dls" ;;
                    "4xBRZ") config_name="4xbrz" ;;
                    "AdaptiveSharpen") config_name="adaptivesharpen" ;;
                    "CRT") config_name="crt" ;;
                    "DPX") config_name="dpx" ;;
                    "FakeHDR") config_name="fakehdr" ;;
                    "FilmGrain") config_name="filmgrain" ;;
                    "LiftGammaGain") config_name="liftgammagain" ;;
                    "LumaSharpen") config_name="lumasharpen" ;;
                    "SmartSharp") config_name="smartsharp" ;;
                    *) config_name="${display_shader,,}" ;;
                esac

                if [ -z "$config_shaders" ]; then
                    config_shaders="$config_name"
                else
                    config_shaders="$config_shaders:$config_name"
                fi
            done

            create_dynamic_config "$config_shaders"
            show_info "Configuration updated with effects: $selected_shaders"
        fi
    fi
}

# Configuration functions
create_minimal_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
effects =
reshadeTexturePath = $TEXTURE_PATH
reshadeIncludePath = $SHADER_PATH
depthCapture = off
toggleKey = Home
enableOnLaunch = True
EOF
}

create_dynamic_config() {
    local selected_shaders="$1"
    local lowercase_shaders=""
    IFS=':' read -ra SHADER_ARRAY <<< "$selected_shaders"
    for shader in "${SHADER_ARRAY[@]}"; do
        if [ -z "$lowercase_shaders" ]; then
            lowercase_shaders="${shader,,}"
        else
            lowercase_shaders="${lowercase_shaders}:${shader,,}"
        fi
    done

    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
effects = $lowercase_shaders
reshadeTexturePath = $TEXTURE_PATH
reshadeIncludePath = $SHADER_PATH
depthCapture = off
toggleKey = Home
enableOnLaunch = True

EOF

    for shader in "${SHADER_ARRAY[@]}"; do
        shader=$(echo "$shader" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        local shader_lower="${shader,,}"

        case "$shader_lower" in
            "cas")
                echo "casSharpness = 0.5" >> "$CONFIG_FILE"
                ;;
            "fxaa")
                echo "fxaaQualitySubpix = 0.75" >> "$CONFIG_FILE"
                echo "fxaaQualityEdgeThreshold = 0.125" >> "$CONFIG_FILE"
                ;;
            "smaa")
                echo "smaaEdgeDetection = luma" >> "$CONFIG_FILE"
                echo "smaaThreshold = 0.05" >> "$CONFIG_FILE"
                echo "smaaMaxSearchSteps = 32" >> "$CONFIG_FILE"
                ;;
            "dls")
                echo "dlsSharpening = 0.5" >> "$CONFIG_FILE"
                echo "dlsDenoise = 0.20" >> "$CONFIG_FILE"
                ;;
            *)
                local shader_path=""
                local name_variations=("$shader" "${shader,,}" "${shader^^}" "${shader^}")

                for name_var in "${name_variations[@]}"; do
                    if [ -f "$SHADER_PATH/$name_var.fx" ]; then
                        shader_path="$SHADER_PATH/$name_var.fx"
                        break
                    fi
                done

                if [ ! -z "$shader_path" ]; then
                    echo "$shader_lower = $shader_path" >> "$CONFIG_FILE"
                fi
                ;;
        esac
    done
}

create_default_config() {
    create_dynamic_config "cas"
}

# Status check
check_status() {
    local status_text="System: CachyOS (using Paru)\n"

    # Check VkBasalt installation (both system and user locations)
    if [ -f "/usr/lib/libvkbasalt.so" ] && [ -f "/usr/lib32/libvkbasalt.so" ]; then
        status_text+="✓ VkBasalt: Installed (System)\n"
    elif [ -f "${USER_HOME}/.local/lib/libvkbasalt.so" ] && [ -f "${USER_HOME}/.local/lib32/libvkbasalt.so" ]; then
        status_text+="✓ VkBasalt: Installed (User)\n"
    else
        status_text+="✗ VkBasalt: Not installed\n"
    fi

    [ -f "$CONFIG_FILE" ] && status_text+="✓ Configuration: Found\n" || status_text+="⚠ Configuration: Missing\n"

    if [ -d "$SHADER_PATH" ] && [ "$(ls -A $SHADER_PATH 2>/dev/null)" ]; then
        local shader_count=$(ls -1 $SHADER_PATH/*.fx 2>/dev/null | wc -l)
        status_text+="✓ Shaders: $shader_count installed\n"
    else
        status_text+="✗ Shaders: Not installed\n"
    fi

    # Check package manager
    if command -v paru &> /dev/null; then
        status_text+="✓ Paru: Available\n"
    else
        status_text+="✗ Paru: Not found\n"
    fi

    zenity --info --text="$status_text" --title="Installation Status" --width=400 --height=280
}

# Main menu
show_main_menu() {
    check_installation
    local install_status=$?

    if [ $install_status -eq 0 ]; then
        if show_question "🚀 VkBasalt Manager - First Use\n\nSystem detected: CachyOS (using Paru)\n\nVkBasalt is not yet installed on your system.\n\nWould you like to proceed with automatic installation?"; then
            install_vkbasalt_complete
            check_installation
            if [ $? -eq 2 ]; then
                show_config_menu
            fi
        else
            exit 0
        fi
    else
        show_config_menu
    fi
}

# Configuration menu
show_config_menu() {
    if [ ! -f "$CONFIG_FILE" ]; then
        show_info "🔧 Creating default configuration..."
        create_default_config
        show_info "✅ Default configuration created! VkBasalt is ready with CAS."
    fi

    while true; do
        local choice=$(zenity --list --title="VkBasalt Manager - Configuration" --text="VkBasalt is installed and ready!" --column="Option" --column="Description" --width=420 --height=350 \
            "Shaders" "Manage active shaders" \
            "Toggle Key" "Change toggle key" \
            "Advanced" "Advanced shader settings" \
            "View" "View current configuration" \
            "Reset" "Reset to default values" \
            "Status" "Check installation" \
            "Uninstall" "Uninstall VkBasalt" \
            "Exit" "Exit VkBasalt Manager" \
            2>/dev/null)

        case "$choice" in
            "Shaders") manage_shaders ;;
            "Toggle Key") change_toggle_key ;;
            "Advanced") show_advanced_menu ;;
            "View") [ -f "$CONFIG_FILE" ] && zenity --text-info --title="Current Configuration" --filename="$CONFIG_FILE" --width=560 --height=340 || show_error "Configuration file not found" ;;
            "Reset")
                if show_question "⚠️ Reset configuration to default values?"; then
                    create_default_config
                    show_info "Configuration reset to default values"
                fi
                ;;
            "Status") check_status ;;
            "Uninstall") uninstall_vkbasalt ;;
            "Exit"|"") exit 0 ;;
        esac
    done
}

# Advanced configuration menu
show_advanced_menu() {
    local choice=$(zenity --list \
        --title="Advanced Settings - Built-in VkBasalt Effects" \
        --text="Configure built-in VkBasalt effects:" \
        --column="Effect" --column="Description" \
        --width=500 --height=300 \
        "CAS" "Contrast Adaptive Sharpening - AMD FidelityFX" \
        "FXAA" "Fast Approximate Anti-Aliasing" \
        "SMAA" "Subpixel Morphological Anti-Aliasing" \
        "DLS" "Denoised Luma Sharpening - Intelligent sharpening" \
        2>/dev/null)
    case "$choice" in
        "CAS") configure_cas ;;
        "FXAA") configure_fxaa ;;
        "SMAA") configure_smaa ;;
        "DLS") configure_dls ;;
    esac
}

# Change toggle key
change_toggle_key() {
    local current_key=$(grep "^toggleKey" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')

    local new_key=$(zenity --list \
        --title="Change Toggle Key" \
        --text="Current key: ${current_key:-Home}\n\nChoose a new key to enable/disable VkBasalt effects:" \
        --column="Key" \
        --column="Description" \
        --width=350 \
        --height=540 \
        "Home" "Home key (recommended)" \
        "End" "End key" \
        "Insert" "Insert key" \
        "Delete" "Delete key" \
        "F1" "Function F1" \
        "F2" "Function F2" \
        "F3" "Function F3" \
        "F4" "Function F4" \
        "F5" "Function F5" \
        "F6" "Function F6" \
        "F7" "Function F7" \
        "F8" "Function F8" \
        "F9" "Function F9" \
        "F10" "Function F10" \
        "F11" "Function F11" \
        "F12" "Function F12" \
        "Page_Up" "Page Up" \
        "Page_Down" "Page Down" \
        "Print" "Print Screen" \
        "Scroll_Lock" "Scroll Lock" \
        "Pause" "Pause" \
        "Menu" "Context Menu key" \
        "Tab" "Tab" \
        "Caps_Lock" "Caps Lock" \
        "Num_Lock" "Num Lock" \
        2>/dev/null)

    if [ ! -z "$new_key" ]; then
        sed -i "s/^toggleKey.*/toggleKey = $new_key/" "$CONFIG_FILE"
        show_info "Toggle key changed: $new_key\n\nNow use the '$new_key' key to enable/disable VkBasalt effects in your games."
    fi
}

# Advanced configuration functions for built-in VkBasalt effects
configure_cas() {
    local cur=$(grep "^casSharpness" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local val=40; [ ! -z "$cur" ] && val=$(awk "BEGIN {printf \"%.0f\", $cur * 100}")
    local sharpness=$(zenity --scale --title="CAS - Contrast Adaptive Sharpening" \
        --text="Adjust sharpening strength\nCurrent value: ${cur:-0.5}\n\n0 = No sharpening\n100 = Maximum sharpening" \
        --min-value=0 --max-value=100 --value=$val --step=5)
    if [ ! -z "$sharpness" ]; then
        local v=$(awk "BEGIN {printf \"%.2f\", $sharpness / 100}")
        grep -q "^casSharpness" "$CONFIG_FILE" && sed -i "s/^casSharpness.*/casSharpness = $v/" "$CONFIG_FILE" || echo "casSharpness = $v" >> "$CONFIG_FILE"
        show_info "CAS sharpness adjusted to: $v ($sharpness%)"
    fi
}

configure_fxaa() {
    local subpix=$(grep "^fxaaQualitySubpix" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local edge=$(grep "^fxaaQualityEdgeThreshold" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')

    local s=75; [ ! -z "$subpix" ] && s=$(awk "BEGIN {printf \"%.0f\", $subpix * 100}")
    local sp=$(zenity --scale --title="FXAA - Subpixel Quality" \
        --text="Adjust subpixel aliasing reduction\nCurrent value: ${subpix:-0.75}\n\n0 = No subpixel AA\n100 = Maximum subpixel AA" \
        --min-value=0 --max-value=100 --value=$s --step=5)
    if [ ! -z "$sp" ]; then
        local spf=$(awk "BEGIN {printf \"%.2f\", $sp / 100}")

        local e=37; [ ! -z "$edge" ] && e=$(awk "BEGIN {printf \"%.0f\", ($edge - 0.063) * 100 / 0.27}")
        local ed=$(zenity --scale --title="FXAA - Edge Threshold" \
            --text="Adjust edge detection sensitivity\nCurrent value: ${edge:-0.125}\n\n0 = Detect all edges (softer)\n100 = Detect only sharp edges (sharper)" \
            --min-value=0 --max-value=100 --value=$e --step=5)
        if [ ! -z "$ed" ]; then
            local edf=$(awk "BEGIN {printf \"%.3f\", 0.063 + ($ed * 0.27 / 100)}")
            grep -q "^fxaaQualitySubpix" "$CONFIG_FILE" && sed -i "s/^fxaaQualitySubpix.*/fxaaQualitySubpix = $spf/" "$CONFIG_FILE" || echo "fxaaQualitySubpix = $spf" >> "$CONFIG_FILE"
            grep -q "^fxaaQualityEdgeThreshold" "$CONFIG_FILE" && sed -i "s/^fxaaQualityEdgeThreshold.*/fxaaQualityEdgeThreshold = $edf/" "$CONFIG_FILE" || echo "fxaaQualityEdgeThreshold = $edf" >> "$CONFIG_FILE"
            show_info "FXAA settings updated\nSubpixel Quality: $spf\nEdge Threshold: $edf"
        fi
    fi
}

configure_smaa() {
    local thresh=$(grep "^smaaThreshold" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local steps=$(grep "^smaaMaxSearchSteps" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')

    local edge_detection=$(zenity --list --title="SMAA - Edge Detection Method" \
        --text="Choose edge detection method:" \
        --column="Mode" --column="Description" \
        --width=520 --height=280 \
        "luma" "Luminance-based (recommended)" \
        "color" "Color-based (more accurate)" \
        "depth" "Depth-based (for 3D games)" \
        2>/dev/null)

    if [ ! -z "$edge_detection" ]; then
        local t=25; [ ! -z "$thresh" ] && t=$(awk "BEGIN {printf \"%.0f\", ($thresh - 0.01) * 100 / 0.19}")
        local th=$(zenity --scale --title="SMAA - Edge Detection Threshold" \
            --text="Adjust edge detection sensitivity\nCurrent value: ${thresh:-0.05}\n\n0 = Detect all edges (softer)\n100 = Detect only sharp edges (sharper)" \
            --min-value=0 --max-value=100 --value=$t --step=5)

        if [ ! -z "$th" ]; then
            local thf=$(awk "BEGIN {printf \"%.3f\", 0.01 + ($th * 0.19 / 100)}")

            local s=43; [ ! -z "$steps" ] && s=$(awk "BEGIN {printf \"%.0f\", ($steps - 8) * 100 / 56}")
            local st=$(zenity --scale --title="SMAA - Maximum Search Steps" \
                --text="Adjust search quality vs performance\nCurrent value: ${steps:-32}\n\n0 = Faster (lower quality)\n100 = Slower (higher quality)" \
                --min-value=0 --max-value=100 --value=$s --step=5)

            if [ ! -z "$st" ]; then
                local stf=$(awk "BEGIN {printf \"%.0f\", 8 + ($st * 56 / 100)}")
                grep -q "^smaaEdgeDetection" "$CONFIG_FILE" && sed -i "s/^smaaEdgeDetection.*/smaaEdgeDetection = $edge_detection/" "$CONFIG_FILE" || echo "smaaEdgeDetection = $edge_detection" >> "$CONFIG_FILE"
                grep -q "^smaaThreshold" "$CONFIG_FILE" && sed -i "s/^smaaThreshold.*/smaaThreshold = $thf/" "$CONFIG_FILE" || echo "smaaThreshold = $thf" >> "$CONFIG_FILE"
                grep -q "^smaaMaxSearchSteps" "$CONFIG_FILE" && sed -i "s/^smaaMaxSearchSteps.*/smaaMaxSearchSteps = $stf/" "$CONFIG_FILE" || echo "smaaMaxSearchSteps = $stf" >> "$CONFIG_FILE"
                show_info "SMAA settings updated\nEdge Detection: $edge_detection\nThreshold: $thf\nMax Search Steps: $stf"
            fi
        fi
    fi
}

configure_dls() {
    local sharpening=$(grep "^dlsSharpening" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local denoise=$(grep "^dlsDenoise" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')

    local sv=50; [ ! -z "$sharpening" ] && sv=$(awk "BEGIN {printf \"%.0f\", $sharpening * 100}")
    local s=$(zenity --scale --title="DLS - Sharpening Strength" \
        --text="Adjust sharpening intensity\nCurrent value: ${sharpening:-0.5}\n\n0 = No sharpening\n100 = Maximum sharpening" \
        --min-value=0 --max-value=100 --value=$sv --step=5)

    if [ ! -z "$s" ]; then
        local sf=$(awk "BEGIN {printf \"%.2f\", $s / 100}")

        local dv=17; [ ! -z "$denoise" ] && dv=$(awk "BEGIN {printf \"%.0f\", $denoise * 100}")
        local d=$(zenity --scale --title="DLS - Denoise Strength" \
            --text="Adjust noise reduction\nCurrent value: ${denoise:-0.20}\n\n0 = No denoising\n100 = Maximum denoising" \
            --min-value=0 --max-value=100 --value=$dv --step=5)

        if [ ! -z "$d" ]; then
            local df=$(awk "BEGIN {printf \"%.2f\", $d / 100}")
            grep -q "^dlsSharpening" "$CONFIG_FILE" && sed -i "s/^dlsSharpening.*/dlsSharpening = $sf/" "$CONFIG_FILE" || echo "dlsSharpening = $sf" >> "$CONFIG_FILE"
            grep -q "^dlsDenoise" "$CONFIG_FILE" && sed -i "s/^dlsDenoise.*/dlsDenoise = $df/" "$CONFIG_FILE" || echo "dlsDenoise = $df" >> "$CONFIG_FILE"
            show_info "DLS settings updated\nSharpening: $sf\nDenoise: $df"
        fi
    fi
}

# Main execution
main() {
    # Verify we're on CachyOS
    if ! grep -q "CachyOS" /etc/os-release 2>/dev/null; then
        show_error "❌ This script is designed specifically for CachyOS!\n\nCurrent system: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Unknown")\n\nPlease use the appropriate version for your distribution."
        exit 1
    fi

    check_dependencies
    show_main_menu
}

main