#!/bin/bash

# VkBasalt Manager for Steam Deck - Installation, Configuration and Uninstallation
# Complete graphical interface with Zenity
# Automatically manages installation, configuration and uninstallation

CONFIG_FILE="/home/deck/.config/vkBasalt/vkBasalt.conf"
BACKUP_FILE="/home/deck/.config/vkBasalt/vkBasalt.conf.backup"
SHADER_PATH="/home/deck/.config/reshade/Shaders"
TEXTURE_PATH="/home/deck/.config/reshade/Textures"
SCRIPT_PATH="/home/deck/.config/vkBasalt/vkbasalt-manager.sh"
ICON_PATH="/home/deck/.config/vkBasalt/vkbasalt-manager.svg"
DESKTOP_FILE="/home/deck/Desktop/VkBasalt-Manager.desktop"

# Check Zenity
check_zenity() {
    if ! command -v zenity &> /dev/null; then
        echo "Zenity is not installed. Installing..."
        if command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm zenity
        elif command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y zenity
        else
            echo "Cannot install Zenity automatically."
            exit 1
        fi
    fi
}

# Dialogs
show_error() { zenity --error --text="$1" --width=400; }
show_info() { zenity --info --text="$1" --width=400; }
show_warning() { zenity --warning --text="$1" --width=400; }
show_question() { zenity --question --text="$1" --width=450; }

# Installation check
check_installation() {
    local vkbasalt_installed=false
    local manager_installed=false
    local shaders_installed=false

    # Check VkBasalt
    if [ -f "/home/deck/.local/lib/libvkbasalt.so" ] && [ -f "/home/deck/.local/lib32/libvkbasalt.so" ]; then
        vkbasalt_installed=true
    fi

    # Check shaders
    if [ -d "$SHADER_PATH" ] && [ "$(ls -A $SHADER_PATH 2>/dev/null)" ]; then
        shaders_installed=true
    fi

    # Check manager (current script)
    if [ -f "$SCRIPT_PATH" ] && [ -f "$ICON_PATH" ] && [ -f "$DESKTOP_FILE" ]; then
        manager_installed=true
    fi

    # Return status (0=not installed, 1=partially installed, 2=fully installed)
    if [ "$vkbasalt_installed" = true ] && [ "$shaders_installed" = true ]; then
        return 2  # Complete installation
    elif [ "$vkbasalt_installed" = true ] || [ "$shaders_installed" = true ]; then
        return 1  # Partial installation
    else
        return 0  # Not installed
    fi
}

# Function to move script to final location
move_script_to_final_location() {
    # Get the current script path
    local current_script="$(realpath "$0")"
    local current_dir="$(dirname "$current_script")"

    # If script is not already in the target location
    if [ "$current_script" != "$SCRIPT_PATH" ]; then
        # Copy the script to the final location
        cp "$current_script" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        chown deck:deck "$SCRIPT_PATH" 2>/dev/null || true

        # Update desktop file to point to new location
        if [ -f "$DESKTOP_FILE" ]; then
            sed -i "s|Exec=.*|Exec=$SCRIPT_PATH|" "$DESKTOP_FILE"
        fi

        return 0  # Script was moved
    fi

    return 1  # Script was already in place
}

# ===============================
# INSTALLATION
# ===============================

install_vkbasalt() {
    show_info "🚀 VkBasalt Manager Installation\n\nThe installation will download and install:\n• VkBasalt\n• ReShade shaders\n• Default configurations\n• Graphical interface\n\nThis may take a few minutes..."

    (
        echo "10" ; echo "# System check..."
        sleep 1

        # Check if running on Steam Deck
        if [ ! -d "/home/deck" ]; then
            echo "100" ; echo "# Error: Not compatible"
            sleep 1
        fi

        echo "20" ; echo "# Creating directories..."
        mkdir -p /home/deck/Desktop
        mkdir -p /home/deck/.config/vkBasalt
        mkdir -p /home/deck/.config/reshade
        sleep 1

        echo "30" ; echo "# Downloading VkBasalt..."
        TMPDIR=$(mktemp -d)
        cd "$TMPDIR"

        if wget -q https://github.com/simons-public/steam-deck-vkbasalt-install/raw/main/vkbasalt_install.sh; then
            echo "50" ; echo "# Installing VkBasalt..."
            bash vkbasalt_install.sh > /dev/null 2>&1
            rm -f vkbasalt_install.sh
        else
            echo "100" ; echo "# Download error"
            exit 1
        fi

        echo "70" ; echo "# Downloading shaders..."
        if wget -q https://github.com/Vaddum/vkbasalt-manager/archive/refs/heads/main.zip; then
            unzip -q main.zip
            cp -rf vkbasalt-manager-main/reshade /home/deck/.config/
            rm -rf main.zip vkbasalt-manager-main
        else
            echo "100" ; echo "# Error: Shaders not downloaded"
            exit 1
        fi

        echo "80" ; echo "# Creating configuration..."
        create_default_config

        echo "85" ; echo "# Moving script to final location..."
        move_script_to_final_location

        echo "90" ; echo "# Creating icon and shortcut..."
        create_icon_and_desktop

        echo "95" ; echo "# Setting permissions..."
        chmod +x "$SCRIPT_PATH"
        chmod +x "$DESKTOP_FILE"
        chown deck:deck "$SCRIPT_PATH" "$ICON_PATH" "$DESKTOP_FILE" 2>/dev/null || true

        cd ~
        rm -rf "$TMPDIR"

        echo "100" ; echo "# Installation complete!"
        sleep 1

    ) | zenity --progress \
        --title="VkBasalt Manager Installation" \
        --text="Preparing..." \
        --percentage=0 \
        --auto-close \
        --width=500

    if [ $? -eq 0 ]; then
        # Check if script was moved and inform user
        if move_script_to_final_location; then
            show_info "✅ Installation successful!\n\nVkBasalt Manager is now installed and ready to use.\n\n📁 The script has been moved to: $SCRIPT_PATH\n\n🎮 To enable VkBasalt in a Steam game:\n1. Right-click on the game → Properties\n2. Launch options: ENABLE_VKBASALT=1 %command%\n3. Launch the game and use the Home key to toggle\n\n💡 You can now delete the original script file if it was in a different location."
        else
            show_info "✅ Installation successful!\n\nVkBasalt Manager is now installed and ready to use.\n\n🎮 To enable VkBasalt in a Steam game:\n1. Right-click on the game → Properties\n2. Launch options: ENABLE_VKBASALT=1 %command%\n3. Launch the game and use the Home key to toggle"
        fi
    else
        show_error "❌ Installation error.\nPlease try again or check your internet connection."
    fi
}

create_icon_and_desktop() {
    # Create SVG icon
    cat > "$ICON_PATH" << 'ICON_EOF'
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
    <radialGradient id="lavaGrad" cx="50%" cy="80%" r="60%">
      <stop offset="0%" style="stop-color:#ffff00;stop-opacity:1" />
      <stop offset="20%" style="stop-color:#ff8c00;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#ff4500;stop-opacity:1" />
      <stop offset="80%" style="stop-color:#dc143c;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#8b0000;stop-opacity:1" />
    </radialGradient>
    <linearGradient id="crackGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#ffff66;stop-opacity:0.9" />
      <stop offset="50%" style="stop-color:#ff6600;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#cc0000;stop-opacity:0.8" />
    </linearGradient>
    <filter id="moltenGlow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="4" result="coloredBlur"/>
      <feMerge>
        <feMergeNode in="coloredBlur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
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
    <path d="M-20,-15 Q-10,0 0,10 Q8,20 15,30"
          stroke="url(#crackGrad)" stroke-width="3" fill="none" opacity="0.9"/>
    <path d="M-30,-5 Q-15,5 -5,8"
          stroke="url(#crackGrad)" stroke-width="2" fill="none" opacity="0.8"/>
    <path d="M10,-20 Q18,-5 25,5"
          stroke="url(#crackGrad)" stroke-width="2" fill="none" opacity="0.8"/>
  </g>
  <g transform="translate(64,64)">
    <ellipse cx="0" cy="15" rx="12" ry="8" fill="url(#lavaGrad)" opacity="0.9"/>
    <circle cx="-18" cy="-8" r="4" fill="url(#lavaGrad)" opacity="0.8"/>
    <ellipse cx="22" cy="-5" rx="5" ry="3" fill="url(#lavaGrad)" opacity="0.8"/>
  </g>
</svg>
ICON_EOF

    # Create .desktop file
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=VkBasalt Manager
Comment=VkBasalt manager for Steam Deck with graphical interface
Comment[fr]=Gestionnaire VkBasalt pour Steam Deck avec interface graphique
Exec=$SCRIPT_PATH
Icon=$ICON_PATH
Terminal=false
StartupNotify=true
NoDisplay=false
StartupWMClass=zenity
MimeType=
EOF
}

# ===============================
# UNINSTALLATION
# ===============================

show_uninstall_menu() {
    local choice=$(zenity --list \
        --title="VkBasalt Manager Uninstaller" \
        --text="What do you want to uninstall?\n\n⚠️ Choose the appropriate option:" \
        --column="Option" \
        --column="Description" \
        --width=600 \
        --height=400 \
        "Manager" "Uninstall only VkBasalt Manager (keep VkBasalt)" \
        "Complete" "Uninstall VkBasalt Manager + VkBasalt + Shaders" \
        "Config" "Remove only configurations/backups" \
        "Cancel" "Return to main menu" \
        2>/dev/null)

    case "$choice" in
        "Manager") uninstall_manager_only ;;
        "Complete") uninstall_complete ;;
        "Config") uninstall_config_only ;;
        *) return ;;
    esac
}

uninstall_manager_only() {
    if show_question "🗑️ Uninstall VkBasalt Manager only?\n\nThis will remove:\n• VkBasalt Manager script\n• Icon and desktop shortcut\n• BUT will keep VkBasalt and its configurations\n\nContinue?"; then
        (
            echo "20" ; echo "# Removing script..."
            [ -f "$SCRIPT_PATH" ] && rm -f "$SCRIPT_PATH"

            echo "50" ; echo "# Removing icon..."
            [ -f "$ICON_PATH" ] && rm -f "$ICON_PATH"

            echo "80" ; echo "# Removing shortcut..."
            [ -f "$DESKTOP_FILE" ] && rm -f "$DESKTOP_FILE"

            echo "100" ; echo "# Cleanup complete"
        ) | zenity --progress --title="Manager Uninstallation" --text="Removing in progress..." --percentage=0 --auto-close --width=400

        show_info "✅ VkBasalt Manager uninstalled successfully!\n\n📋 Result:\n• Manager removed\n• VkBasalt kept\n• Configurations kept\n• Shaders kept"
        exit 0
    fi
}

uninstall_complete() {
    if show_question "🗑️ Complete uninstallation?\n\n⚠️ WARNING: This will remove EVERYTHING:\n• VkBasalt Manager\n• VkBasalt itself\n• All configurations\n• All shaders\n• All backups\n\nThis action is IRREVERSIBLE!\n\nContinue?"; then
        (
            echo "10" ; echo "# Removing VkBasalt Manager..."
            [ -f "$SCRIPT_PATH" ] && rm -f "$SCRIPT_PATH"
            [ -f "$ICON_PATH" ] && rm -f "$ICON_PATH"
            [ -f "$DESKTOP_FILE" ] && rm -f "$DESKTOP_FILE"

            echo "30" ; echo "# Removing VkBasalt..."
            [ -f "/home/deck/.local/lib/libvkbasalt.so" ] && rm -f "/home/deck/.local/lib/libvkbasalt.so"
            [ -f "/home/deck/.local/lib32/libvkbasalt.so" ] && rm -f "/home/deck/.local/lib32/libvkbasalt.so"
            [ -f "/home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.json" ] && rm -f "/home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.json"
            [ -f "/home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json" ] && rm -f "/home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json"

            echo "60" ; echo "# Removing configurations..."
            [ -d "/home/deck/.config/vkBasalt" ] && rm -rf "/home/deck/.config/vkBasalt"

            echo "80" ; echo "# Removing shaders..."
            [ -d "$SHADER_PATH" ] && rm -rf "/home/deck/.config/reshade"

            echo "90" ; echo "# Cleaning directories..."
            rmdir /home/deck/.local/share/vulkan/implicit_layer.d 2>/dev/null || true
            rmdir /home/deck/.local/share/vulkan 2>/dev/null || true
            rmdir /home/deck/.local/lib32 2>/dev/null || true

            echo "100" ; echo "# Uninstallation complete"
        ) | zenity --progress --title="Complete Uninstallation" --text="Removing all components..." --percentage=0 --auto-close --width=450

        show_info "✅ Complete uninstallation finished!\n\n📋 Result:\n• VkBasalt Manager removed\n• VkBasalt removed\n• Configurations removed\n• Shaders removed\n• System cleaned\n\n💡 Don't forget to remove ENABLE_VKBASALT=1 from your Steam games launch options."
        exit 0
    fi
}

uninstall_config_only() {
    if show_question "🗑️ Remove configurations?\n\nThis will remove:\n• vkBasalt.conf\n• vkBasalt.conf.backup\n• BUT will keep VkBasalt Manager and VkBasalt\n\nContinue?"; then
        (
            echo "30" ; echo "# Removing configurations..."
            [ -f "$CONFIG_FILE" ] && rm -f "$CONFIG_FILE"

            echo "70" ; echo "# Removing backups..."
            [ -f "$BACKUP_FILE" ] && rm -f "$BACKUP_FILE"

            echo "100" ; echo "# Cleanup complete"
        ) | zenity --progress --title="Configuration Removal" --text="Cleaning configurations..." --percentage=0 --auto-close --width=400

        show_info "✅ Configurations removed!\n\n📋 Result:\n• Configurations removed\n• VkBasalt Manager kept\n• VkBasalt kept\n• Shaders kept"
    fi
}

# ===============================
# CONFIGURATION (EXISTING CODE)
# ===============================

# Backup
create_backup() { [ -f "$CONFIG_FILE" ] && cp "$CONFIG_FILE" "$BACKUP_FILE"; }
restore_backup() {
    if [ -f "$BACKUP_FILE" ]; then
        if show_question "Restore configuration from backup?\nThis will overwrite the current configuration."; then
            cp "$BACKUP_FILE" "$CONFIG_FILE"
            show_info "✓ Configuration restored from backup"
        fi
    else
        show_error "❌ No backup found"
    fi
}
delete_backup() {
    if [ -f "$BACKUP_FILE" ]; then
        if show_question "Delete backup?\nThis action is irreversible."; then
            rm "$BACKUP_FILE"
            show_info "✓ Backup deleted"
        fi
    else
        show_error "❌ No backup found"
    fi
}

# Basic configurations
create_minimal_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# VkBasalt Configuration - No active effects

effects =

reshadeTexturePath = "$TEXTURE_PATH"
reshadeIncludePath = "$SHADER_PATH"

toggleKey = Home

enableOnLaunch = True
EOF
}

create_dynamic_config() {
    local selected_shaders="$1"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# VkBasalt Configuration - Selected shaders: $selected_shaders

effects = $selected_shaders

reshadeTexturePath = "$TEXTURE_PATH"
reshadeIncludePath = "$SHADER_PATH"

toggleKey = Home

enableOnLaunch = True

EOF
    IFS=':' read -ra SHADER_ARRAY <<< "$selected_shaders"
    for shader in "${SHADER_ARRAY[@]}"; do
        case "$shader" in
            "cas")
                echo "# CAS (Contrast Adaptive Sharpening) Settings" >> "$CONFIG_FILE"
                echo "casSharpness = 0.4" >> "$CONFIG_FILE"
                echo "" >> "$CONFIG_FILE"
                ;;
            "fxaa")
                echo "# FXAA" >> "$CONFIG_FILE"
                echo "fxaaQualitySubpix = 0.75" >> "$CONFIG_FILE"
                echo "fxaaQualityEdgeThreshold = 0.125" >> "$CONFIG_FILE"
                echo "fxaaQualityEdgeThresholdMin = 0.0312" >> "$CONFIG_FILE"
                echo "" >> "$CONFIG_FILE"
                ;;
            "smaa")
                echo "# SMAA" >> "$CONFIG_FILE"
                echo "smaaEdgeDetection = luma" >> "$CONFIG_FILE"
                echo "smaaThreshold = 0.05" >> "$CONFIG_FILE"
                echo "smaaMaxSearchSteps = 32" >> "$CONFIG_FILE"
                echo "smaaMaxSearchStepsDiag = 16" >> "$CONFIG_FILE"
                echo "smaaCornerRounding = 25" >> "$CONFIG_FILE"
                echo "" >> "$CONFIG_FILE"
                ;;
            "lumasharpen")
                echo "# LumaSharpen" >> "$CONFIG_FILE"
                echo "lumaSharpenStrength = 0.65" >> "$CONFIG_FILE"
                echo "lumaSharpenClamp = 0.035" >> "$CONFIG_FILE"
                echo "lumasharpen = $SHADER_PATH/LumaSharpen.fx" >> "$CONFIG_FILE"
                echo "" >> "$CONFIG_FILE"
                ;;
            "vibrance")
                echo "# Vibrance" >> "$CONFIG_FILE"
                echo "vibranceStrength = 0.15" >> "$CONFIG_FILE"
                echo "vibrance = $SHADER_PATH/Vibrance.fx" >> "$CONFIG_FILE"
                echo "" >> "$CONFIG_FILE"
                ;;
            "dpx")
                echo "# DPX" >> "$CONFIG_FILE"
                echo "dpxSaturation = 3.0" >> "$CONFIG_FILE"
                echo "dpxColorGamma = 2.5" >> "$CONFIG_FILE"
                echo "dpxContrast = 0.1" >> "$CONFIG_FILE"
                echo "dpx = $SHADER_PATH/DPX.fx" >> "$CONFIG_FILE"
                echo "" >> "$CONFIG_FILE"
                ;;
            "clarity")
                echo "# Clarity" >> "$CONFIG_FILE"
                echo "clarityRadius = 3" >> "$CONFIG_FILE"
                echo "clarityOffset = 2.0" >> "$CONFIG_FILE"
                echo "clarityStrength = 0.4" >> "$CONFIG_FILE"
                echo "clarity = $SHADER_PATH/Clarity.fx" >> "$CONFIG_FILE"
                echo "" >> "$CONFIG_FILE"
                ;;
        esac
    done
}

create_default_config() { create_dynamic_config "cas"; }

# Installation check
check_status() {
    local status_text=""
    [ -f "/home/deck/.local/lib/libvkbasalt.so" ] && [ -f "/home/deck/.local/lib32/libvkbasalt.so" ] \
        && status_text+="✓ VkBasalt: Installed\n" || status_text+="✗ VkBasalt: Not installed\n"
    [ -f "$CONFIG_FILE" ] && status_text+="✓ Configuration: Found\n" || status_text+="⚠ Configuration: Missing\n"
    if [ -d "$SHADER_PATH" ] && [ "$(ls -A $SHADER_PATH 2>/dev/null)" ]; then
        shader_count=$(ls -1 $SHADER_PATH/*.fx 2>/dev/null | wc -l)
        status_text+="✓ Shaders: $shader_count Shaders installed\n"
    else
        status_text+="✗ Shaders: Not installed\n"
    fi
    zenity --info --text="$status_text" --title="Installation Status" --width=400
}

# Unified main menu
show_main_menu() {
    check_installation
    local install_status=$?

    if [ $install_status -eq 0 ]; then
        # Not installed - Offer installation
        if show_question "🚀 VkBasalt Manager - First Use\n\nVkBasalt is not yet installed on your system.\n\nWould you like to proceed with automatic installation?\n\nThis will install:\n• VkBasalt\n• ReShade shaders\n• Configuration interface\n• Desktop shortcuts"; then
            install_vkbasalt
            # Restart menu after installation
            [ $? -eq 0 ] && show_main_menu
        else
            exit 0
        fi
    else
        # Installed - Show configuration menu with uninstall option
        show_config_menu
    fi
}

show_config_menu() {
    # Ensure configuration exists
    if [ ! -f "$CONFIG_FILE" ]; then
        show_info "🔧 First use detected. Creating default configuration..."
        create_default_config
        show_info "✅ Default configuration created!\nVkBasalt is ready to use with CAS."
    fi

    local choice=$(zenity --list \
        --title="VkBasalt Manager - Configuration" \
        --text="VkBasalt is installed and ready! Choose an option:" \
        --column="Option" --column="Description" \
        --width=600 --height=550 \
        "Presets" "Apply a predefined configuration" \
        "Shaders" "Manage active shaders" \
        "Toggle Key" "Change toggle key" \
        "Advanced" "Advanced shader settings" \
        "View" "View current configuration" \
        "Backup" "Backup management" \
        "Reset" "Reset to default values" \
        "Usage" "Usage information" \
        "Status" "Check installation" \
        "Uninstall" "Uninstall VkBasalt/Manager" \
        2>/dev/null)
    case "$choice" in
        "Presets") show_preset_menu ;;
        "Shaders") manage_shaders ;;
        "Toggle Key") change_toggle_key ;;
        "Advanced") show_advanced_menu ;;
        "View") show_current_config ;;
        "Backup") show_backup_menu ;;
        "Reset")
            if show_question "⚠️ This will reset the configuration to default values.\nContinue?"; then
                create_backup
                create_default_config
                show_info "✓ Configuration reset to default values"
            fi
            ;;
        "Usage") show_usage ;;
        "Status") check_status ;;
        "Uninstall") show_uninstall_menu ;;
        *) exit 0 ;;
    esac
}

show_preset_menu() {
    local choice=$(zenity --list \
        --title="Predefined Configurations" \
        --text="Choose a configuration:" \
        --column="Preset" --column="Description" \
        --width=600 --height=400 \
        "Performance" "Light effects for better performance" \
        "Quality" "Enhanced visuals with multiple effects" \
        "Cinematic" "Cinema look with dramatic effects" \
        "Minimal" "Sharpening only (CAS)" \
        "Complete" "All effects enabled" \
        2>/dev/null)
    case "$choice" in
        "Performance") apply_preset 1 ;;
        "Quality") apply_preset 2 ;;
        "Cinematic") apply_preset 3 ;;
        "Minimal") apply_preset 4 ;;
        "Complete") apply_preset 5 ;;
    esac
}

apply_preset() {
    local preset=$1
    create_backup
    case $preset in
        1)
            create_dynamic_config "cas:fxaa:smaa"
            cat >> "$CONFIG_FILE" << EOF

# Performance optimizations
casSharpness = 0.4
fxaaQualitySubpix = 0.75
fxaaQualityEdgeThreshold = 0.125
fxaaQualityEdgeThresholdMin = 0.0312
smaaEdgeDetection = luma
smaaThreshold = 0.05
smaaMaxSearchSteps = 32
smaaMaxSearchStepsDiag = 16
smaaCornerRounding = 25
EOF
            show_info "✓ Performance configuration applied\nActive shaders: CAS, FXAA, SMAA"
            ;;
        2)
            create_dynamic_config "cas:smaa:lumasharpen:vibrance"
            cat >> "$CONFIG_FILE" << EOF

# Quality optimizations
casSharpness = 0.6
smaaEdgeDetection = luma
smaaThreshold = 0.05
smaaMaxSearchSteps = 32
smaaMaxSearchStepsDiag = 16
smaaCornerRounding = 25
lumaSharpenStrength = 0.65
lumaSharpenClamp = 0.035
vibranceStrength = 0.15
depthCapture = off
EOF
            show_info "✓ Quality configuration applied\nActive shaders: CAS, SMAA, LumaSharpen, Vibrance"
            ;;
        3)
            create_dynamic_config "dpx:vibrance"
            cat >> "$CONFIG_FILE" << EOF

# Cinematic optimizations
dpxSaturation = 3.0
dpxColorGamma = 2.5
dpxContrast = 0.1
vibranceStrength = 0.20
depthCapture = off
EOF
            show_info "✓ Cinematic configuration applied\nActive shaders: DPX, Vibrance"
            ;;
        4)
            create_dynamic_config "cas"
            cat >> "$CONFIG_FILE" << EOF

# Minimal optimizations
casSharpness = 0.5
depthCapture = off
EOF
            show_info "✓ Minimal configuration applied\nActive shader: CAS only"
            ;;
        5)
            create_dynamic_config "cas:fxaa:smaa:lumasharpen:dpx:vibrance:clarity"
            cat >> "$CONFIG_FILE" << EOF

# Complete configuration optimizations
casSharpness = 0.6
fxaaQualitySubpix = 0.75
fxaaQualityEdgeThreshold = 0.125
fxaaQualityEdgeThresholdMin = 0.0312
smaaEdgeDetection = luma
smaaThreshold = 0.05
smaaMaxSearchSteps = 32
smaaMaxSearchStepsDiag = 16
smaaCornerRounding = 25
lumaSharpenStrength = 0.65
lumaSharpenClamp = 0.035
dpxSaturation = 3.0
dpxContrast = 0.1
vibranceStrength = 0.15
clarityRadius = 3
clarityOffset = 2.0
clarityStrength = 0.4
EOF
            show_info "✓ Complete configuration applied\nAll active shaders: CAS, FXAA, SMAA, LumaSharpen, DPX, Vibrance, Clarity"
            ;;
    esac
}

manage_shaders() {
    local current_effects=""
    [ -f "$CONFIG_FILE" ] && current_effects=$(grep "^effects" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')
    local cas_check="FALSE" fxaa_check="FALSE" smaa_check="FALSE" lumasharpen_check="FALSE" vibrance_check="FALSE" dpx_check="FALSE" clarity_check="FALSE"
    [[ "$current_effects" == *"cas"* ]] && cas_check="TRUE"
    [[ "$current_effects" == *"fxaa"* ]] && fxaa_check="TRUE"
    [[ "$current_effects" == *"smaa"* ]] && smaa_check="TRUE"
    [[ "$current_effects" == *"lumasharpen"* ]] && lumasharpen_check="TRUE"
    [[ "$current_effects" == *"vibrance"* ]] && vibrance_check="TRUE"
    [[ "$current_effects" == *"dpx"* ]] && dpx_check="TRUE"
    [[ "$current_effects" == *"clarity"* ]] && clarity_check="TRUE"
    local selected_shaders=$(zenity --list \
        --title="Shader Selection" \
        --text="Choose shaders to activate:\nCurrently active: $current_effects\n⚠️ Ctrl+Click to select multiple shaders" \
        --checklist \
        --column="Enable" --column="Shader" --column="Description" \
        --width=700 --height=450 --separator=":" \
        $cas_check "cas" "Contrast Adaptive Sharpening - AMD sharpening" \
        $fxaa_check "fxaa" "Fast Approximate Anti-Aliasing - Fast AA" \
        $smaa_check "smaa" "Subpixel Morphological Anti-Aliasing - HQ AA" \
        $lumasharpen_check "lumasharpen" "Luminance sharpening" \
        $vibrance_check "vibrance" "Smart saturation" \
        $dpx_check "dpx" "Cinema look" \
        $clarity_check "clarity" "Clarity and details" \
        2>/dev/null)
    if [ $? -eq 0 ]; then
        create_backup
        if [ -z "$selected_shaders" ]; then
            if show_question "No shader selected.\nDo you want to disable all shaders?"; then
                create_minimal_config
                show_info "✓ All shaders have been disabled"
            fi
        else
            create_dynamic_config "$selected_shaders"
            show_info "✓ Configuration updated with shaders: $selected_shaders"
        fi
    fi
}

show_advanced_menu() {
    local choice=$(zenity --list \
        --title="Advanced Settings" \
        --text="Choose a shader to configure in detail:" \
        --column="Shader" --column="Description" \
        --width=700 --height=450 \
        "CAS" "Contrast Adaptive Sharpening - AMD sharpening" \
        "Clarity" "Clarity and details" \
        "DPX" "Professional cinema look" \
        "FXAA" "Fast Approximate Anti-Aliasing - Fast AA" \
        "LumaSharpen" "Luminance sharpening" \
        "SMAA" "Subpixel Morphological Anti-Aliasing - HQ AA" \
        "Vibrance" "Smart saturation" \
        2>/dev/null)
    case "$choice" in
        "CAS") configure_cas ;;
        "Clarity") configure_clarity ;;
        "DPX") configure_dpx ;;
        "FXAA") configure_fxaa ;;
        "LumaSharpen") configure_lumasharpen ;;
        "SMAA") configure_smaa ;;
        "Vibrance") configure_vibrance ;;
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
        --width=500 \
        --height=500 \
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
        create_backup
        sed -i "s/^toggleKey.*/toggleKey = $new_key/" "$CONFIG_FILE"
        show_info "✓ Toggle key changed: $new_key\n\nNow use the '$new_key' key to enable/disable VkBasalt effects in your games."
    fi
}

# Sliders for each shader
configure_cas() {
    local cur=$(grep "^casSharpness" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local val=40; [ ! -z "$cur" ] && val=$(awk "BEGIN {printf \"%.0f\", $cur * 100}")
    local sharpness=$(zenity --scale --title="CAS - Sharpness" --text="Current value: ${cur:-0.4}" --min-value=0 --max-value=100 --value=$val --step=5)
    if [ ! -z "$sharpness" ]; then
        local v=$(awk "BEGIN {printf \"%.2f\", $sharpness / 100}")
        create_backup
        grep -q "^casSharpness" "$CONFIG_FILE" && sed -i "s/^casSharpness.*/casSharpness = $v/" "$CONFIG_FILE" || echo "casSharpness = $v" >> "$CONFIG_FILE"
        show_info "✓ CAS sharpness adjusted to: $v ($sharpness%)"
    fi
}

configure_fxaa() {
    local subpix=$(grep "^fxaaQualitySubpix" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local edge=$(grep "^fxaaQualityEdgeThreshold" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local s=75; [ ! -z "$subpix" ] && s=$(awk "BEGIN {printf \"%.0f\", $subpix * 100}")
    local sp=$(zenity --scale --title="FXAA - Subpix Quality" --text="Current value: ${subpix:-0.75}" --min-value=0 --max-value=100 --value=$s --step=5)
    if [ ! -z "$sp" ]; then
        local spf=$(awk "BEGIN {printf \"%.2f\", $sp / 100}")
        local e=37; [ ! -z "$edge" ] && e=$(awk "BEGIN {printf \"%.0f\", ($edge - 0.063) * 100 / 0.27}")
        local ed=$(zenity --scale --title="FXAA - Edge Threshold" --text="Current value: ${edge:-0.125}" --min-value=0 --max-value=100 --value=$e --step=5)
        if [ ! -z "$ed" ]; then
            local edf=$(awk "BEGIN {printf \"%.3f\", 0.063 + ($ed * 0.27 / 100)}")
            create_backup
            grep -q "^fxaaQualitySubpix" "$CONFIG_FILE" && sed -i "s/^fxaaQualitySubpix.*/fxaaQualitySubpix = $spf/" "$CONFIG_FILE" || echo "fxaaQualitySubpix = $spf" >> "$CONFIG_FILE"
            grep -q "^fxaaQualityEdgeThreshold" "$CONFIG_FILE" && sed -i "s/^fxaaQualityEdgeThreshold.*/fxaaQualityEdgeThreshold = $edf/" "$CONFIG_FILE" || echo "fxaaQualityEdgeThreshold = $edf" >> "$CONFIG_FILE"
            show_info "✓ FXAA settings updated\nSubpix: $spf | Edge: $edf"
        fi
    fi
}

configure_smaa() {
    local thresh=$(grep "^smaaThreshold" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local steps=$(grep "^smaaMaxSearchSteps" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local edge_detection=$(zenity --list --title="SMAA - Edge Detection" --text="Detection mode:" --column="Mode" --column="Description" --width=500 --height=300 "luma" "Luminance (recommended)" "color" "Color" "depth" "Depth" 2>/dev/null)
    if [ ! -z "$edge_detection" ]; then
        local t=25; [ ! -z "$thresh" ] && t=$(awk "BEGIN {printf \"%.0f\", ($thresh - 0.01) * 100 / 0.19}")
        local th=$(zenity --scale --title="SMAA - Threshold" --text="Current value: ${thresh:-0.05}" --min-value=0 --max-value=100 --value=$t --step=5)
        if [ ! -z "$th" ]; then
            local thf=$(awk "BEGIN {printf \"%.3f\", 0.01 + ($th * 0.19 / 100)}")
            local s=43; [ ! -z "$steps" ] && s=$(awk "BEGIN {printf \"%.0f\", ($steps - 8) * 100 / 56}")
            local st=$(zenity --scale --title="SMAA - Search Steps" --text="Current value: ${steps:-32}" --min-value=0 --max-value=100 --value=$s --step=5)
            if [ ! -z "$st" ]; then
                local stf=$(awk "BEGIN {printf \"%.0f\", 8 + ($st * 56 / 100)}")
                create_backup
                grep -q "^smaaEdgeDetection" "$CONFIG_FILE" && sed -i "s/^smaaEdgeDetection.*/smaaEdgeDetection = $edge_detection/" "$CONFIG_FILE" || echo "smaaEdgeDetection = $edge_detection" >> "$CONFIG_FILE"
                grep -q "^smaaThreshold" "$CONFIG_FILE" && sed -i "s/^smaaThreshold.*/smaaThreshold = $thf/" "$CONFIG_FILE" || echo "smaaThreshold = $thf" >> "$CONFIG_FILE"
                grep -q "^smaaMaxSearchSteps" "$CONFIG_FILE" && sed -i "s/^smaaMaxSearchSteps.*/smaaMaxSearchSteps = $stf/" "$CONFIG_FILE" || echo "smaaMaxSearchSteps = $stf" >> "$CONFIG_FILE"
                show_info "✓ SMAA updated\nDetection: $edge_detection | Threshold: $thf | Steps: $stf"
            fi
        fi
    fi
}

configure_dpx() {
    local sat=$(grep "^dpxSaturation" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local gamma=$(grep "^dpxColorGamma" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local contrast=$(grep "^dpxContrast" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local sv=43; [ ! -z "$sat" ] && sv=$(awk "BEGIN {printf \"%.0f\", ($sat - 1.0) * 100 / 7.0}")
    local saturation=$(zenity --scale --title="DPX - Saturation" --text="Current value: ${sat:-3.0}" --min-value=0 --max-value=100 --value=$sv --step=5)
    if [ ! -z "$saturation" ]; then
        local satf=$(awk "BEGIN {printf \"%.1f\", 1.0 + ($saturation * 7.0 / 100)}")
        local gv=50; [ ! -z "$gamma" ] && gv=$(awk "BEGIN {printf \"%.0f\", ($gamma - 1.0) * 100 / 3.0}")
        local gamma_val=$(zenity --scale --title="DPX - Gamma" --text="Current value: ${gamma:-2.5}" --min-value=0 --max-value=100 --value=$gv --step=5)
        if [ ! -z "$gamma_val" ]; then
            local gammaf=$(awk "BEGIN {printf \"%.1f\", 1.0 + ($gamma_val * 3.0 / 100)}")
            local cv=55; [ ! -z "$contrast" ] && cv=$(awk "BEGIN {printf \"%.0f\", ($contrast + 1.0) * 100 / 2.0}")
            local contrast_val=$(zenity --scale --title="DPX - Contrast" --text="Current value: ${contrast:-0.1}" --min-value=0 --max-value=100 --value=$cv --step=5)
            if [ ! -z "$contrast_val" ]; then
                local contrastf=$(awk "BEGIN {printf \"%.1f\", -1.0 + ($contrast_val * 2.0 / 100)}")
                create_backup
                grep -q "^dpxSaturation" "$CONFIG_FILE" && sed -i "s/^dpxSaturation.*/dpxSaturation = $satf/" "$CONFIG_FILE" || echo "dpxSaturation = $satf" >> "$CONFIG_FILE"
                grep -q "^dpxColorGamma" "$CONFIG_FILE" && sed -i "s/^dpxColorGamma.*/dpxColorGamma = $gammaf/" "$CONFIG_FILE" || echo "dpxColorGamma = $gammaf" >> "$CONFIG_FILE"
                grep -q "^dpxContrast" "$CONFIG_FILE" && sed -i "s/^dpxContrast.*/dpxContrast = $contrastf/" "$CONFIG_FILE" || echo "dpxContrast = $contrastf" >> "$CONFIG_FILE"
                show_info "✓ DPX updated\nSaturation: $satf | Gamma: $gammaf | Contrast: $contrastf"
            fi
        fi
    fi
}

configure_lumasharpen() {
    local strength=$(grep "^lumaSharpenStrength" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local clamp=$(grep "^lumaSharpenClamp" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local sv=22; [ ! -z "$strength" ] && sv=$(awk "BEGIN {printf \"%.0f\", $strength * 100 / 3.0}")
    local s=$(zenity --scale --title="LumaSharpen - Strength" --text="Current value: ${strength:-0.65}" --min-value=0 --max-value=100 --value=$sv --step=5)
    if [ ! -z "$s" ]; then
        local sf=$(awk "BEGIN {printf \"%.2f\", $s * 3.0 / 100}")
        local cv=4; [ ! -z "$clamp" ] && cv=$(awk "BEGIN {printf \"%.0f\", $clamp * 100}")
        local c=$(zenity --scale --title="LumaSharpen - Clamp" --text="Current value: ${clamp:-0.035}" --min-value=0 --max-value=100 --value=$cv --step=1)
        if [ ! -z "$c" ]; then
            local cf=$(awk "BEGIN {printf \"%.3f\", $c / 100}")
            create_backup
            grep -q "^lumaSharpenStrength" "$CONFIG_FILE" && sed -i "s/^lumaSharpenStrength.*/lumaSharpenStrength = $sf/" "$CONFIG_FILE" || echo "lumaSharpenStrength = $sf" >> "$CONFIG_FILE"
            grep -q "^lumaSharpenClamp" "$CONFIG_FILE" && sed -i "s/^lumaSharpenClamp.*/lumaSharpenClamp = $cf/" "$CONFIG_FILE" || echo "lumaSharpenClamp = $cf" >> "$CONFIG_FILE"
            show_info "✓ LumaSharpen updated\nStrength: $sf | Clamp: $cf"
        fi
    fi
}

configure_clarity() {
    local radius=$(grep "^clarityRadius" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local offset=$(grep "^clarityOffset" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local strength=$(grep "^clarityStrength" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local rv=29; [ ! -z "$radius" ] && rv=$(awk "BEGIN {printf \"%.0f\", ($radius - 1) * 100 / 7}")
    local r=$(zenity --scale --title="Clarity - Radius" --text="Current value: ${radius:-3}" --min-value=0 --max-value=100 --value=$rv --step=14)
    if [ ! -z "$r" ]; then
        local rf=$(awk "BEGIN {printf \"%.0f\", 1 + ($r * 7 / 100)}")
        local ov=20; [ ! -z "$offset" ] && ov=$(awk "BEGIN {printf \"%.0f\", $offset * 10}")
        local o=$(zenity --scale --title="Clarity - Offset" --text="Current value: ${offset:-2.0}" --min-value=0 --max-value=100 --value=$ov --step=5)
        if [ ! -z "$o" ]; then
            local of=$(awk "BEGIN {printf \"%.1f\", $o / 10}")
            local sv=40; [ ! -z "$strength" ] && sv=$(awk "BEGIN {printf \"%.0f\", $strength * 100}")
            local s=$(zenity --scale --title="Clarity - Strength" --text="Current value: ${strength:-0.4}" --min-value=0 --max-value=100 --value=$sv --step=5)
            if [ ! -z "$s" ]; then
                local sf=$(awk "BEGIN {printf \"%.2f\", $s / 100}")
                create_backup
                grep -q "^clarityRadius" "$CONFIG_FILE" && sed -i "s/^clarityRadius.*/clarityRadius = $rf/" "$CONFIG_FILE" || echo "clarityRadius = $rf" >> "$CONFIG_FILE"
                grep -q "^clarityOffset" "$CONFIG_FILE" && sed -i "s/^clarityOffset.*/clarityOffset = $of/" "$CONFIG_FILE" || echo "clarityOffset = $of" >> "$CONFIG_FILE"
                grep -q "^clarityStrength" "$CONFIG_FILE" && sed -i "s/^clarityStrength.*/clarityStrength = $sf/" "$CONFIG_FILE" || echo "clarityStrength = $sf" >> "$CONFIG_FILE"
                show_info "✓ Clarity updated\nRadius: $rf | Offset: $of | Strength: $sf"
            fi
        fi
    fi
}

configure_vibrance() {
    local strength=$(grep "^vibranceStrength" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local sv=58; [ ! -z "$strength" ] && sv=$(awk "BEGIN {printf \"%.0f\", ($strength + 1.0) * 100 / 2.0}")
    local s=$(zenity --scale --title="Vibrance - Strength" --text="Current value: ${strength:-0.15}" --min-value=0 --max-value=100 --value=$sv --step=5)
    if [ ! -z "$s" ]; then
        local sf=$(awk "BEGIN {printf \"%.2f\", -1.0 + ($s * 2.0 / 100)}")
        create_backup
        grep -q "^vibranceStrength" "$CONFIG_FILE" && sed -i "s/^vibranceStrength.*/vibranceStrength = $sf/" "$CONFIG_FILE" || echo "vibranceStrength = $sf" >> "$CONFIG_FILE"
        show_info "✓ Vibrance updated\nStrength: $sf"
    fi
}

show_current_config() {
    [ -f "$CONFIG_FILE" ] && zenity --text-info --title="Current Configuration" --filename="$CONFIG_FILE" --width=600 --height=400 \
        || show_error "❌ Configuration file not found"
}

show_backup_menu() {
    local choice=$(zenity --list --title="Backup Management" --text="Backup options:" --column="Action" --column="Description" --width=500 --height=300 \
        "Create" "Create a backup" "Restore" "Restore from backup" "Delete" "Delete backup" 2>/dev/null)
    case "$choice" in
        "Create") create_backup; show_info "✓ Backup created" ;;
        "Restore") restore_backup ;;
        "Delete") delete_backup ;;
    esac
}

show_usage() {
    zenity --info --title="How to use VkBasalt" --text="🎮 VkBasalt is installed and ready to use!
═══ Activation in Steam games ═══

1. Open Steam in Desktop mode
2. Right-click on your game → Properties
3. In launch options, add:
   ENABLE_VKBASALT=1 %command%
4. Launch the game
5. Use the Home key to enable/disable

═══ Available shaders ═══
• CAS - AMD adaptive sharpening
• FXAA - Fast anti-aliasing
• SMAA - High quality anti-aliasing
• LumaSharpen - Luminance sharpening
• Vibrance - Smart saturation
• DPX - Professional cinema look
• Clarity - Clarity and details

═══ Current configuration ═══
File: $CONFIG_FILE
Shaders: $SHADER_PATH
Textures: $TEXTURE_PATH

⚠️  VkBasalt only works with Vulkan games
🎯 Toggle key configurable in Configuration → Toggle Key" --width=650 --height=500
}

# Main function
main() {
    check_zenity
    while true; do
        show_main_menu
        [ $? -ne 0 ] && exit 0
    done
}

main
