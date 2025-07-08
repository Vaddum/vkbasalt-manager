#!/bin/bash

# VkBasalt Manager for Steam Deck - Installation, Configuration and Uninstallation
# Complete graphical interface with Zenity
# Automatically manages installation, configuration and uninstallation

CONFIG_FILE="/home/deck/.config/vkBasalt/vkBasalt.conf"
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

# Dialogs - OPTIMIZED SIZES
show_error() { zenity --error --text="$1" --width=480 --height=140; }
show_info() { zenity --info --text="$1" --width=480 --height=140; }
show_warning() { zenity --warning --text="$1" --width=480 --height=140; }
show_question() { zenity --question --text="$1" --width=480 --height=140; }

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
        --width=420 \
        --height=110

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

uninstall_vkbasalt() {
    if show_question "🗑️ Uninstallation?\n\n⚠️ WARNING: This will remove EVERYTHING:\n• VkBasalt Manager\n• VkBasalt itself\n• All configurations\n• All shaders\n• All backups\n\nThis action is IRREVERSIBLE!\n\nContinue?"; then
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

            echo "100" ; echo "# Uninstallation"
        ) | zenity --progress --title="Uninstallation" --text="Removing all components..." --percentage=0 --auto-close --width=420 --height=110

        show_info "✅ Uninstallation finished!\n\n📋 Result:\n• VkBasalt Manager removed\n• VkBasalt removed\n• Configurations removed\n• Shaders removed\n• System cleaned\n\n💡 Don't forget to remove ENABLE_VKBASALT=1 from your Steam games launch options."
        exit 0
    fi
}

# ===============================
# CONFIGURATION
# ===============================

# Function to get shader description
get_shader_description() {
    local shader_name="$1"
    case "$shader_name" in
        "cas"|"CAS") echo "🟢 AMD Adaptive Sharpening - Enhances details without artifacts (Built-in VkBasalt)" ;;
        "fxaa"|"FXAA") echo "🟢 Fast Anti-Aliasing - Smooths jagged edges quickly (Built-in VkBasalt)" ;;
        "smaa"|"SMAA") echo "🟢 High-quality Anti-Aliasing - Better than FXAA (Built-in VkBasalt)" ;;
        "dls"|"DLS"|"denoised_luma_sharpening"|"Denoised_Luma_Sharpening") echo "🟢 Denoised Luma Sharpening - Intelligent sharpening without noise (Built-in VkBasalt)" ;;
        "border"|"Border") echo "Borders - Adds a frame around the image" ;;
        "CRT"|"crt") echo "Retro Effect - Cathode Ray Tube television look" ;;
        "cartoon"|"Cartoon") echo "Cartoon Style - Animated drawing effect" ;;
        "chromatic_aberration"|"ChromaticAberration") echo "Chromatic Aberration - Separates RGB channels" ;;
        "clarity"|"Clarity") echo "Clarity and Depth - Increases overall definition" ;;
        "curves"|"Curves") echo "Curve Correction - Adjusts contrast and brightness" ;;
        "dpx"|"DPX") echo "Cinematic Look - Professional film effect" ;;
        "daltonize"|"Daltonize") echo "Color Blindness Correction - Helps with visual impairments" ;;
        "defring"|"Defring") echo "Fringe Correction - Reduces OLED chromatic aberrations" ;;
        "fake_hdr"|"FakeHDR") echo "Fake HDR - Simulates HDR effect" ;;
        "filmgrain"|"FilmGrain") echo "Film Grain - Vintage film texture" ;;
        "levels"|"Levels") echo "RGB Levels - Black/white threshold adjustment" ;;
        "liftgammagain"|"LiftGammaGain") echo "LGG Correction - Precise tone control" ;;
        "lumasharpen"|"LumaSharpen") echo "Luminance Sharpening - Enhances edges and details" ;;
        "monochrome"|"Monochrome") echo "Monochrome - Black and white conversion" ;;
        "nostalgia"|"Nostalgia") echo "Nostalgia - Old photo effect" ;;
        "sepia"|"Sepia") echo "Sepia Effect - Vintage brown/beige tint" ;;
        "smart_sharp"|"Smart_Sharp") echo "Depth Based Unsharp Mask Bilateral Contrast Adaptive Sharpening" ;;
        "technicolor"|"Technicolor") echo "Vintage Technicolor Effect - Retro colorful style" ;;
        "tonemap"|"Tonemap") echo "HDR Tone Mapping - Optimizes dynamic range" ;;
        "vibrance"|"Vibrance") echo "Intelligent Saturation - Enhances colors naturally" ;;
        "vignette"|"Vignette") echo "Vignetting - Darkens image edges" ;;
        *) echo "$shader_name - Available graphics effect" ;;
    esac
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
            "dls")
                echo "# DLS (Denoised Luma Sharpening) Settings" >> "$CONFIG_FILE"
                echo "dlsSharpening = 0.5" >> "$CONFIG_FILE"
                echo "dlsDenoise = 0.17" >> "$CONFIG_FILE"
                echo "" >> "$CONFIG_FILE"
                ;;
            *)
                # For external shaders, add the path to the .fx file
                local found_file=""

                # 1. Try exact name
                if [ -f "$SHADER_PATH/$shader.fx" ]; then
                    found_file="$SHADER_PATH/$shader.fx"
                # 2. Try with first letter capitalized
                elif [ -f "$SHADER_PATH/${shader^}.fx" ]; then
                    found_file="$SHADER_PATH/${shader^}.fx"
                else
                    # 3. Search for file with case-insensitive match
                    if [ -d "$SHADER_PATH" ]; then
                        for file in "$SHADER_PATH"/*.fx; do
                            if [ -f "$file" ]; then
                                local basename_file=$(basename "$file" .fx)
                                if [[ "${basename_file,,}" == "${shader,,}" ]]; then
                                    found_file="$file"
                                    break
                                fi
                            fi
                        done
                    fi
                fi

                # Write shader path if found
                if [ ! -z "$found_file" ]; then
                    echo "# $shader shader path" >> "$CONFIG_FILE"
                    echo "$shader = $found_file" >> "$CONFIG_FILE"
                    echo "" >> "$CONFIG_FILE"
                fi
                ;;
        esac
    done
}

create_default_config() {
    create_dynamic_config "cas";
}

manage_shaders() {
    # Read currently active effects from configuration file
    local current_effects=""
    if [ -f "$CONFIG_FILE" ]; then
        current_effects=$(grep "^effects" "$CONFIG_FILE" | head -n1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    fi

    # Generate checklist dynamically
    local checklist_items=()
    local shader_name
    local description
    local enabled

    # Convert current effects string to array
    local current_effects_array=()
    if [ ! -z "$current_effects" ]; then
        IFS=':' read -ra current_effects_array <<< "$current_effects"
    fi

    # Function to check if an effect is enabled
    is_effect_enabled() {
        local effect_to_check="$1"
        for active_effect in "${current_effects_array[@]}"; do
            # Clean spaces
            active_effect=$(echo "$active_effect" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            if [[ "$active_effect" == "$effect_to_check" ]]; then
                return 0  # Found
            fi
        done
        return 1  # Not found
    }

    # First add built-in VkBasalt effects (always available)
    local builtin_effects=("CAS" "FXAA" "SMAA" "DLS")
    for shader_name in "${builtin_effects[@]}"; do
        # For built-in effects, check lowercase version in config
        local lowercase_name="${shader_name,,}"

        enabled="FALSE"
        if is_effect_enabled "$lowercase_name"; then
            enabled="TRUE"
        fi

        # Get description
        description=$(get_shader_description "$shader_name")
        checklist_items+=("$enabled" "$shader_name" "$description")
    done

    # Then add available ReShade shaders from folder
    if [ -d "$SHADER_PATH" ]; then
        shopt -s nullglob
        for file in "$SHADER_PATH"/*.fx; do
            local file_basename=$(basename "$file" .fx)

            # Avoid duplicates with built-in effects
            local is_builtin=false
            for builtin in "${builtin_effects[@]}"; do
                if [[ "${file_basename,,}" == "${builtin,,}" ]]; then
                    is_builtin=true
                    break
                fi
            done

            if [ "$is_builtin" = false ]; then
                shader_name="$file_basename"

                # Check if this external effect is enabled
                enabled="FALSE"
                if is_effect_enabled "$file_basename"; then
                    enabled="TRUE"
                else
                    # Try case-insensitive comparison too
                    for active_effect in "${current_effects_array[@]}"; do
                        active_effect=$(echo "$active_effect" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                        if [[ "${active_effect,,}" == "${file_basename,,}" ]]; then
                            enabled="TRUE"
                            break
                        fi
                    done
                fi

                description=$(get_shader_description "$shader_name")
                checklist_items+=("$enabled" "$shader_name" "$description")
            fi
        done
        shopt -u nullglob
    fi

    if [ ${#checklist_items[@]} -eq 0 ]; then
        show_error "No effects available"
        return
    fi

    # Create a list of current effects for display (with display names)
    local current_display_effects=""
    for active_effect in "${current_effects_array[@]}"; do
        active_effect=$(echo "$active_effect" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        case "$active_effect" in
            "cas") current_display_effects+="CAS:" ;;
            "fxaa") current_display_effects+="FXAA:" ;;
            "smaa") current_display_effects+="SMAA:" ;;
            "dls") current_display_effects+="DLS:" ;;
            *) current_display_effects+="$active_effect:" ;;
        esac
    done
    current_display_effects="${current_display_effects%:}"  # Remove last ":"

    # Display dynamic checklist (OPTIMIZED SIZE)
    local selected_shaders
    selected_shaders=$(zenity --list \
        --title="VkBasalt Effects Selection" \
        --text="Built-in VkBasalt effects (performant) & Available shaders\nCurrent: $current_display_effects\nCtrl+Click for multiple selection" \
        --checklist \
        --column="Enable" --column="Effect" --column="Description" \
        --width=900 --height=500 --separator=":" \
        "${checklist_items[@]}" \
        2>/dev/null)

    if [ $? -eq 0 ]; then
        if [ -z "$selected_shaders" ]; then
            if show_question "No effects selected.\nDo you want to disable all effects?"; then
                create_minimal_config
                show_info "All effects have been disabled"
            fi
        else
            # Convert built-in effect names to lowercase for configuration
            local config_effects=""
            IFS=':' read -ra EFFECT_ARRAY <<< "$selected_shaders"
            for effect in "${EFFECT_ARRAY[@]}"; do
                case "$effect" in
                    "CAS") config_effects+="cas:" ;;
                    "FXAA") config_effects+="fxaa:" ;;
                    "SMAA") config_effects+="smaa:" ;;
                    "DLS") config_effects+="dls:" ;;
                    *) config_effects+="$effect:" ;;
                esac
            done
            # Remove last ":"
            config_effects="${config_effects%:}"

            create_dynamic_config "$config_effects"
            show_info "Configuration updated with effects: $selected_shaders"
        fi
    fi
}

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
    zenity --info --text="$status_text" --title="Installation Status" --width=320 --height=180
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
        --width=420 --height=320 \
        "Shaders" "Manage active shaders" \
        "Toggle Key" "Change toggle key" \
        "Advanced" "Advanced shader settings" \
        "View" "View current configuration" \
        "Reset" "Reset to default values" \
        "Status" "Check installation" \
        "Uninstall" "Uninstallation" \
        2>/dev/null)
    case "$choice" in
        "Shaders") manage_shaders ;;
        "Toggle Key") change_toggle_key ;;
        "Advanced") show_advanced_menu ;;
        "View") show_current_config ;;
        "Reset")
            if show_question "⚠️ This will reset the configuration to default values.\nContinue?"; then
                create_default_config
                show_info "Configuration reset to default values"
            fi
            ;;
        "Status") check_status ;;
        "Uninstall")
            if show_question "🗑️ Uninstall VkBasalt?\n\n⚠️ WARNING: This will remove EVERYTHING:\n• VkBasalt Manager\n• VkBasalt itself\n• All configurations\n• All shaders\n\nThis action is IRREVERSIBLE!\n\nDo you want to continue?"; then
                uninstall_vkbasalt
            fi
            ;;
        *) exit 0 ;;
    esac
}

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

# Configuration functions for built-in VkBasalt effects
configure_cas() {
    local cur=$(grep "^casSharpness" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local val=40; [ ! -z "$cur" ] && val=$(awk "BEGIN {printf \"%.0f\", $cur * 100}")
    local sharpness=$(zenity --scale --title="CAS - Contrast Adaptive Sharpening" \
        --text="Adjust sharpening strength\nCurrent value: ${cur:-0.4}\n\n0 = No sharpening\n100 = Maximum sharpening" \
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

    # Subpixel quality
    local s=75; [ ! -z "$subpix" ] && s=$(awk "BEGIN {printf \"%.0f\", $subpix * 100}")
    local sp=$(zenity --scale --title="FXAA - Subpixel Quality" \
        --text="Adjust subpixel aliasing reduction\nCurrent value: ${subpix:-0.75}\n\n0 = No subpixel AA\n100 = Maximum subpixel AA" \
        --min-value=0 --max-value=100 --value=$s --step=5)
    if [ ! -z "$sp" ]; then
        local spf=$(awk "BEGIN {printf \"%.2f\", $sp / 100}")

        # Edge threshold
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

    # Edge detection method
    local edge_detection=$(zenity --list --title="SMAA - Edge Detection Method" \
        --text="Choose edge detection method:" \
        --column="Mode" --column="Description" \
        --width=520 --height=280 \
        "luma" "Luminance-based (recommended)" \
        "color" "Color-based (more accurate)" \
        "depth" "Depth-based (for 3D games)" \
        2>/dev/null)

    if [ ! -z "$edge_detection" ]; then
        # Threshold
        local t=25; [ ! -z "$thresh" ] && t=$(awk "BEGIN {printf \"%.0f\", ($thresh - 0.01) * 100 / 0.19}")
        local th=$(zenity --scale --title="SMAA - Edge Detection Threshold" \
            --text="Adjust edge detection sensitivity\nCurrent value: ${thresh:-0.05}\n\n0 = Detect all edges (softer)\n100 = Detect only sharp edges (sharper)" \
            --min-value=0 --max-value=100 --value=$t --step=5)

        if [ ! -z "$th" ]; then
            local thf=$(awk "BEGIN {printf \"%.3f\", 0.01 + ($th * 0.19 / 100)}")

            # Search steps
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

    # Sharpening strength
    local sv=50; [ ! -z "$sharpening" ] && sv=$(awk "BEGIN {printf \"%.0f\", $sharpening * 100}")
    local s=$(zenity --scale --title="DLS - Sharpening Strength" \
        --text="Adjust sharpening intensity\nCurrent value: ${sharpening:-0.5}\n\n0 = No sharpening\n100 = Maximum sharpening" \
        --min-value=0 --max-value=100 --value=$sv --step=5)

    if [ ! -z "$s" ]; then
        local sf=$(awk "BEGIN {printf \"%.2f\", $s / 100}")

        # Denoise strength
        local dv=17; [ ! -z "$denoise" ] && dv=$(awk "BEGIN {printf \"%.0f\", $denoise * 100}")
        local d=$(zenity --scale --title="DLS - Denoise Strength" \
            --text="Adjust noise reduction\nCurrent value: ${denoise:-0.17}\n\n0 = No denoising\n100 = Maximum denoising" \
            --min-value=0 --max-value=100 --value=$dv --step=5)

        if [ ! -z "$d" ]; then
            local df=$(awk "BEGIN {printf \"%.2f\", $d / 100}")
            grep -q "^dlsSharpening" "$CONFIG_FILE" && sed -i "s/^dlsSharpening.*/dlsSharpening = $sf/" "$CONFIG_FILE" || echo "dlsSharpening = $sf" >> "$CONFIG_FILE"
            grep -q "^dlsDenoise" "$CONFIG_FILE" && sed -i "s/^dlsDenoise.*/dlsDenoise = $df/" "$CONFIG_FILE" || echo "dlsDenoise = $df" >> "$CONFIG_FILE"
            show_info "DLS settings updated\nSharpening: $sf\nDenoise: $df"
        fi
    fi
}

show_current_config() {
    [ -f "$CONFIG_FILE" ] && zenity --text-info --title="Current Configuration" --filename="$CONFIG_FILE" --width=560 --height=340 \
        || show_error "Configuration file not found"
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
