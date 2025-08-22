#!/bin/bash

USER_HOME="/home/deck"
SYSTEM_USER="deck"

CONFIG_FILE="${USER_HOME}/.config/vkBasalt/vkBasalt.conf"
SHADER_PATH="${USER_HOME}/.config/reshade/Shaders"
TEXTURE_PATH="${USER_HOME}/.config/reshade/Textures"
SCRIPT_PATH="${USER_HOME}/.config/vkBasalt/vkbasalt-manager.sh"
ICON_PATH="${USER_HOME}/.config/vkBasalt/vkbasalt-manager.png"
DESKTOP_FILE="${USER_HOME}/Desktop/VkBasalt-Manager.desktop"
LOG_FILE="${USER_HOME}/.config/vkBasalt/manager.log"
PROFILES_DIR="${USER_HOME}/.config/vkBasalt/profiles"


declare -A SHADER_DESC_CACHE

mkdir -p "${USER_HOME}/Desktop" "${PROFILES_DIR}"

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE"
}

cleanup_shader_name() {
    local name="$1"
    echo "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

download_with_retry() {
    local url="$1"
    local output="$2"
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if wget -q --timeout=30 --tries=1 "$url" -O "$output" 2>/dev/null; then
            log_info "Successfully downloaded $url"
            return 0
        fi
        log_error "Download attempt $attempt failed for $url"
        attempt=$((attempt + 1))
        sleep 2
    done
    return 1
}

verify_package_integrity() {
    local pkg_file="$1"
    if ! tar -tf "$pkg_file" >/dev/null 2>&1; then
        log_error "Corrupted package: $pkg_file"
        return 1
    fi
    return 0
}

check_system_compatibility() {
    if ! vulkaninfo --summary >/dev/null 2>&1; then
        show_error "Vulkan is not available on this system"
        return 1
    fi

    local available_space=$(df "${USER_HOME}" | awk 'NR==2 {print $4}')
    if [ $available_space -lt 100000 ]; then
        show_error "Insufficient disk space (minimum 100MB required)"
        return 1
    fi

    return 0
}

check_dependencies() {
    local missing_deps=()

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

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_info "Installing missing dependencies: ${missing_deps[*]}"
        sudo steamos-readonly disable
        sudo pacman -S --noconfirm "${missing_deps[@]}"
        sudo steamos-readonly enable
    fi
}

show_error() { zenity --error --text="$1" --width=480 --height=140; }
show_info() { zenity --info --text="$1" --width=480 --height=140; }
show_question() { zenity --question --text="$1" --width=480 --height=140; }

check_installation() {
    local vkbasalt_installed=false
    local shaders_installed=false

    if [ -f "${USER_HOME}/.local/lib/libvkbasalt.so" ] && [ -f "${USER_HOME}/.local/lib32/libvkbasalt.so" ]; then
        vkbasalt_installed=true
    fi

    if [ -d "$SHADER_PATH" ] && [ "$(ls -A $SHADER_PATH 2>/dev/null)" ]; then
        shaders_installed=true
    fi

    if [ "$vkbasalt_installed" = true ] && [ "$shaders_installed" = true ]; then
        return 2
    elif [ "$vkbasalt_installed" = true ]; then
        return 1
    else
        return 0
    fi
}

move_script_to_final_location() {
    local current_script="$(realpath "$0")"
    if [ "$current_script" != "$SCRIPT_PATH" ]; then
        cp "$current_script" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        chown "${SYSTEM_USER}:${SYSTEM_USER}" "$SCRIPT_PATH" 2>/dev/null || true

        if [ -f "$DESKTOP_FILE" ]; then
            sed -i "s|Exec=.*|Exec=$SCRIPT_PATH|" "$DESKTOP_FILE"
        fi

        return 0
    fi
    return 1
}

install_vkbasalt() {
    if ! grep -q SteamOS /etc/os-release 2>/dev/null ; then
    return 1
    fi
    if [ "$EUID" -eq 0 ]; then
        return 1
    fi

    local AUR_BASE='https://builds.garudalinux.org/repos/chaotic-aur/x86_64/'

    local VKBASALT_PKG_VER
    VKBASALT_PKG_VER=$(curl -s ${AUR_BASE} 2>/dev/null | grep -o 'vkbasalt-[0-9\.\-]*-x86_64' | head -1)
    if [ -z "$VKBASALT_PKG_VER" ]; then
        return 1
    fi

    local VKBASALT_PKG="${VKBASALT_PKG_VER}.pkg.tar.zst"
    local VKBASALT_LIB32_PKG="lib32-${VKBASALT_PKG}"
    local VKBASALT_PKG_FILE=$(mktemp /tmp/vkbasalt.XXXXXX.tar.zst)
    local VKBASALT_LIB32_PKG_FILE=$(mktemp /tmp/vkbasalt.XXXXXX.lib32.tar.zst)

    if ! download_with_retry "${AUR_BASE}${VKBASALT_PKG}" "${VKBASALT_PKG_FILE}"; then
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    if ! download_with_retry "${AUR_BASE}${VKBASALT_LIB32_PKG}" "${VKBASALT_LIB32_PKG_FILE}"; then
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    if ! verify_package_integrity "$VKBASALT_PKG_FILE" || ! verify_package_integrity "$VKBASALT_LIB32_PKG_FILE"; then
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    mkdir -p "${USER_HOME}/.local/lib"
    mkdir -p "${USER_HOME}/.local/lib32"
    mkdir -p "${USER_HOME}/.local/share/vulkan/implicit_layer.d"
    mkdir -p "${USER_HOME}/.config/vkBasalt"
    mkdir -p "${USER_HOME}/.config/reshade"

    if ! tar xf "${VKBASALT_PKG_FILE}" --strip-components=2 --directory="${USER_HOME}/.local/lib/" usr/lib/libvkbasalt.so; then
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    if ! tar xf "${VKBASALT_LIB32_PKG_FILE}" --strip-components=2 --directory="${USER_HOME}/.local/lib32/" usr/lib32/libvkbasalt.so; then
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    if ! tar xf "${VKBASALT_PKG_FILE}" --to-stdout usr/share/vulkan/implicit_layer.d/vkBasalt.json \
            | sed -e "s|libvkbasalt.so|${USER_HOME}/.local/lib/libvkbasalt.so|" \
                  -e "s/ENABLE_VKBASALT/SteamDeck/" \
                  > "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.json"; then
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    if ! tar xf "${VKBASALT_LIB32_PKG_FILE}" --to-stdout usr/share/vulkan/implicit_layer.d/vkBasalt.x86.json \
            | sed -e "s|libvkbasalt.so|${USER_HOME}/.local/lib32/libvkbasalt.so|" \
                  -e "s/ENABLE_VKBASALT/SteamDeck/" \
                  > "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json"; then
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    tar xf "${VKBASALT_PKG_FILE}" --to-stdout usr/share/vkBasalt/vkBasalt.conf.example 2>/dev/null \
            | sed -e "s|/opt/reshade/textures|${USER_HOME}/.config/reshade/Textures|" \
                  -e "s|/opt/reshade/shaders|${USER_HOME}/.config/reshade/Shaders|" \
                  > "${USER_HOME}/.config/vkBasalt/vkBasalt.conf.example" || true

    rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
    chown -R "${SYSTEM_USER}:${SYSTEM_USER}" "${USER_HOME}/.local/lib" "${USER_HOME}/.local/lib32" "${USER_HOME}/.local/share" "${USER_HOME}/.config/vkBasalt" "${USER_HOME}/.config/reshade" 2>/dev/null || true

    log_info "VkBasalt installation completed successfully"
    return 0
}

install_vkbasalt_complete() {
    if ! check_system_compatibility; then
        return 1
    fi

    show_info "🚀 VkBasalt Manager Installation\n\nThis will download and install:\n• VkBasalt\n• ReShade shaders\n• Default configurations\n• Graphical interface\n\nThis may take a few minutes..."

    (
        echo "10" ; echo "# System check..."
        mkdir -p "${USER_HOME}/Desktop" "${USER_HOME}/.config/vkBasalt" "${USER_HOME}/.config/reshade" "${PROFILES_DIR}" 2>/dev/null || true

        echo "20" ; echo "# Checking dependencies..."
        check_dependencies 2>&1

        echo "30" ; echo "# Installing VkBasalt core..."
        if ! install_vkbasalt 2>&1; then
            echo "100" ; echo "# VkBasalt installation failed"
            exit 1
        fi

        echo "70" ; echo "# Downloading ReShade shaders..."
        local TMPDIR=$(mktemp -d)
        cd "$TMPDIR"
        if download_with_retry "https://github.com/Vaddum/vkbasalt-manager/archive/refs/heads/main.zip" "main.zip"; then
            if unzip -q main.zip 2>/dev/null && [ -d "vkbasalt-manager-main/reshade" ]; then
                cp -rf vkbasalt-manager-main/reshade/* "${USER_HOME}/.config/reshade/" 2>/dev/null || true
            fi
        fi
        cd "${USER_HOME}" && rm -rf "$TMPDIR"

        echo "80" ; echo "# Creating default configuration..."
        create_default_config

        echo "85" ; echo "# Setting up manager interface..."
        move_script_to_final_location

        echo "90" ; echo "# Creating desktop icon..."
        create_desktop_entry

        echo "95" ; echo "# Setting permissions..."
        chmod +x "$SCRIPT_PATH" "$DESKTOP_FILE" 2>/dev/null || true
        chown "${SYSTEM_USER}:${SYSTEM_USER}" "$SCRIPT_PATH" "$DESKTOP_FILE" 2>/dev/null || true

        echo "100" ; echo "# Installation complete!"

    ) | zenity --progress --title="VkBasalt Manager Installation" --text="Preparing..." --percentage=0 --auto-close --width=420 --height=110

    if [ $? -eq 0 ] && [ -f "${USER_HOME}/.local/lib/libvkbasalt.so" ] && [ -f "${USER_HOME}/.local/lib32/libvkbasalt.so" ]; then
        local script_moved_msg=""
        if [ "$(realpath "$0")" != "$SCRIPT_PATH" ]; then
            script_moved_msg="\n\n📁 The script has been moved to: $SCRIPT_PATH"
        fi

        show_info "✅ Installation successful!$script_moved_msg\n\nVkBasalt Manager is now installed!\n\n🔧 Use this manager to configure effects and settings."
        return 0
    else
        show_error "❌ Installation failed!\n\nPossible causes:\n• Network connection issues\n• Missing dependencies\n• Insufficient permissions\n\nPlease check your internet connection and try again."
        return 1
    fi
}

create_desktop_entry() {
    local ICON_URL="https://raw.githubusercontent.com/Vaddum/vkbasalt-manager/main/vkbasalt-manager.png"

    if command -v wget &> /dev/null; then
        download_with_retry "$ICON_URL" "$ICON_PATH" || ICON_PATH=""
    elif command -v curl &> /dev/null; then
        curl -s --max-time 10 -A "Mozilla/5.0" "$ICON_URL" -o "$ICON_PATH" 2>/dev/null || ICON_PATH=""
    fi

    if [ ! -f "$ICON_PATH" ] || ! file "$ICON_PATH" 2>/dev/null | grep -qi "image\|png"; then
        ICON_PATH=""
    fi

    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=VkBasalt Manager
Comment=VkBasalt manager with graphical interface for Steam Deck
Exec=$SCRIPT_PATH
Icon=$ICON_PATH
Terminal=false
StartupNotify=true
NoDisplay=true
StartupWMClass=zenity
MimeType=
EOF

    chmod +x "$DESKTOP_FILE" 2>/dev/null || true
}

uninstall_vkbasalt() {
    if show_question "🗑️ Uninstall VkBasalt?\n\n⚠️ WARNING: This will remove:\n• VkBasalt Manager\n• VkBasalt itself\n• All configurations\n• All shaders\n• All profiles\n\nThis action is irreversible!\n\nContinue?"; then
        (
            echo "10" ; echo "# Removing VkBasalt Manager..."
            rm -f "$SCRIPT_PATH" "$ICON_PATH" "$DESKTOP_FILE"

            echo "20" ; echo "# Removing profiles..."
            rm -rf "$PROFILES_DIR"

            echo "30" ; echo "# Removing VkBasalt..."
            rm -f "${USER_HOME}/.local/lib/libvkbasalt.so" "${USER_HOME}/.local/lib32/libvkbasalt.so"
            rm -f "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.json" "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json"

            echo "60" ; echo "# Removing configurations..."
            rm -rf "${USER_HOME}/.config/vkBasalt"

            echo "80" ; echo "# Removing shaders..."
            rm -rf "${USER_HOME}/.config/reshade"

            echo "90" ; echo "# Cleaning directories..."
            rmdir "${USER_HOME}/.local/share/vulkan/implicit_layer.d" "${USER_HOME}/.local/share/vulkan" "${USER_HOME}/.local/lib32" 2>/dev/null || true

            echo "100" ; echo "# Uninstallation complete"
        ) | zenity --progress --title="Uninstallation" --text="Removing all components..." --percentage=0 --auto-close --width=420 --height=110

        show_info "✅ Uninstallation finished!\n\nVkBasalt has been completely removed."
        exit 0
    fi
}

get_shader_description_cached() {
    local shader="$1"
    if [ -z "${SHADER_DESC_CACHE[$shader]}" ]; then
        SHADER_DESC_CACHE[$shader]=$(get_shader_description "$shader")
    fi
    echo "${SHADER_DESC_CACHE[$shader]}"
}

get_shader_description() {
    case "$1" in
        "cas"|"CAS") echo "🔵 AMD Adaptive Sharpening - Enhances details without artifacts (Built-in)" ;;
        "fxaa"|"FXAA") echo "🔵 Fast Anti-Aliasing - Smooths jagged edges quickly (Built-in)" ;;
        "smaa"|"SMAA") echo "🔵 High-quality Anti-Aliasing - Better than FXAA (Built-in)" ;;
        "dls"|"DLS") echo "🔵 Denoised Luma Sharpening - Intelligent sharpening without noise (Built-in)" ;;
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

manage_profiles() {
    local choice=$(zenity --list --title="Profile Management" \
        --text="Manage VkBasalt configuration profiles:" \
        --column="Action" --column="Description" \
        --width=500 --height=380 \
        "Create Profile" "Save current configuration as new profile" \
        "Save Profile" "Save changes to currently loaded profile" \
        "Load Profile" "Load an existing profile" \
        "Delete Profile" "Remove a profile" \
        "Export Profile" "Export profile to file" \
        "Import Profile" "Import profile from file" \
        2>/dev/null)

    case "$choice" in
        "Create Profile")
            local profile_name=$(zenity --entry --title="Create Profile" --text="Enter profile name:" --width=350)
            if [ ! -z "$profile_name" ]; then
                local profile_file="${PROFILES_DIR}/${profile_name}.conf"
                if [ -f "$profile_file" ]; then
                    if show_question "Profile '$profile_name' already exists. Overwrite?"; then
                        cp "$CONFIG_FILE" "$profile_file"
                        echo "$profile_name" > "${USER_HOME}/.config/vkBasalt/.current_profile"
                        log_info "Profile '$profile_name' overwritten and set as current"
                        show_info "Profile '$profile_name' updated and set as current profile"
                    fi
                else
                    cp "$CONFIG_FILE" "$profile_file"
                    echo "$profile_name" > "${USER_HOME}/.config/vkBasalt/.current_profile"
                    log_info "Profile '$profile_name' created and set as current"
                    show_info "Profile '$profile_name' created and set as current profile"
                fi
            fi
            ;;
        "Save Profile")
            local current_profile=""
            if [ -f "${USER_HOME}/.config/vkBasalt/.current_profile" ]; then
                current_profile=$(cat "${USER_HOME}/.config/vkBasalt/.current_profile" 2>/dev/null)
            fi

            if [ ! -z "$current_profile" ] && [ -f "${PROFILES_DIR}/${current_profile}.conf" ]; then
                if show_question "Save current configuration to profile '$current_profile'?"; then
                    cp "$CONFIG_FILE" "${PROFILES_DIR}/${current_profile}.conf"
                    log_info "Changes saved to profile '$current_profile'"
                    show_info "Changes saved to profile '$current_profile'"
                fi
            else
                if show_question "No current profile set. Create a new profile with current configuration?"; then
                    local profile_name=$(zenity --entry --title="Save as New Profile" --text="Enter profile name:" --width=350)
                    if [ ! -z "$profile_name" ]; then
                        cp "$CONFIG_FILE" "${PROFILES_DIR}/${profile_name}.conf"
                        echo "$profile_name" > "${USER_HOME}/.config/vkBasalt/.current_profile"
                        log_info "New profile '$profile_name' created and set as current"
                        show_info "New profile '$profile_name' created and set as current profile"
                    fi
                fi
            fi
            ;;
        "Load Profile")
            local profiles=($(ls "$PROFILES_DIR"/*.conf 2>/dev/null | xargs -n1 basename -s .conf))
            if [ ${#profiles[@]} -eq 0 ]; then
                show_error "No profiles found"
                return
            fi

            local selected_profile=$(zenity --list --title="Load Profile" \
                --text="Select a profile to load:" \
                --column="Profile Name" \
                --width=350 --height=300 \
                "${profiles[@]}" 2>/dev/null)

            if [ ! -z "$selected_profile" ]; then
                cp "${PROFILES_DIR}/${selected_profile}.conf" "$CONFIG_FILE"
                echo "$selected_profile" > "${USER_HOME}/.config/vkBasalt/.current_profile"
                log_info "Profile '$selected_profile' loaded and set as current"
                show_info "Profile '$selected_profile' loaded and set as current profile"
            fi
            ;;
        "Delete Profile")
            local profiles=($(ls "$PROFILES_DIR"/*.conf 2>/dev/null | xargs -n1 basename -s .conf))
            if [ ${#profiles[@]} -eq 0 ]; then
                show_error "No profiles found"
                return
            fi

            local selected_profile=$(zenity --list --title="Delete Profile" \
                --text="Select a profile to delete:" \
                --column="Profile Name" \
                --width=350 --height=300 \
                "${profiles[@]}" 2>/dev/null)

            if [ ! -z "$selected_profile" ]; then
                if show_question "Delete profile '$selected_profile'?\n\nThis action cannot be undone."; then
                    local current_profile=""
                    if [ -f "${USER_HOME}/.config/vkBasalt/.current_profile" ]; then
                        current_profile=$(cat "${USER_HOME}/.config/vkBasalt/.current_profile" 2>/dev/null)
                    fi

                    rm -f "${PROFILES_DIR}/${selected_profile}.conf"

                    if [ "$current_profile" = "$selected_profile" ]; then
                        rm -f "${USER_HOME}/.config/vkBasalt/.current_profile"
                        log_info "Deleted current profile '$selected_profile'"
                        show_info "Profile '$selected_profile' deleted (was current profile)"
                    else
                        log_info "Profile '$selected_profile' deleted"
                        show_info "Profile '$selected_profile' deleted successfully"
                    fi
                fi
            fi
            ;;
        "Export Profile")
            local profiles=($(ls "$PROFILES_DIR"/*.conf 2>/dev/null | xargs -n1 basename -s .conf))
            if [ ${#profiles[@]} -eq 0 ]; then
                show_error "No profiles found"
                return
            fi

            local selected_profile=$(zenity --list --title="Export Profile" \
                --text="Select a profile to export:" \
                --column="Profile Name" \
                --width=350 --height=300 \
                "${profiles[@]}" 2>/dev/null)

            if [ ! -z "$selected_profile" ]; then
                local export_file=$(zenity --file-selection --save --title="Export Profile" \
                    --filename="${selected_profile}.conf" 2>/dev/null)
                if [ ! -z "$export_file" ]; then
                    cp "${PROFILES_DIR}/${selected_profile}.conf" "$export_file"
                    show_info "Profile exported to: $export_file"
                fi
            fi
            ;;
        "Import Profile")
            local import_file=$(zenity --file-selection --title="Import Profile" \
                --file-filter="Configuration files (*.conf) | *.conf" 2>/dev/null)
            if [ ! -z "$import_file" ] && [ -f "$import_file" ]; then
                local profile_name=$(zenity --entry --title="Import Profile" \
                    --text="Enter name for imported profile:" \
                    --entry-text="$(basename "$import_file" .conf)" --width=350)
                if [ ! -z "$profile_name" ]; then
                    cp "$import_file" "${PROFILES_DIR}/${profile_name}.conf"
                    show_info "Profile '$profile_name' imported successfully"
                fi
            fi
            ;;
    esac
}

run_diagnostics() {
    local diag_output=$(mktemp)

    {
        echo "=== VkBasalt Manager Diagnostics ==="
        echo "Date: $(date)"
        echo "System: $(uname -a)"
        echo ""
        echo "=== Installation Status ==="
        check_installation
        local status=$?
        case $status in
            0) echo "Status: Not installed" ;;
            1) echo "Status: VkBasalt installed, shaders missing" ;;
            2) echo "Status: Fully installed" ;;
        esac
        echo ""
        echo "=== VkBasalt Files ==="
        ls -la "${USER_HOME}/.local/lib/libvkbasalt.so" 2>/dev/null || echo "64-bit: Not found"
        ls -la "${USER_HOME}/.local/lib32/libvkbasalt.so" 2>/dev/null || echo "32-bit: Not found"
        echo ""
        echo "=== Vulkan Layer Files ==="
        ls -la "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.json" 2>/dev/null || echo "64-bit layer: Not found"
        ls -la "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json" 2>/dev/null || echo "32-bit layer: Not found"
        echo ""
        echo "=== Current Configuration ==="
        if [ -f "$CONFIG_FILE" ]; then
            cat "$CONFIG_FILE"
        else
            echo "No configuration file found"
        fi
        echo ""
        echo "=== Available Shaders ==="
        if [ -d "$SHADER_PATH" ]; then
            ls -la "$SHADER_PATH"/*.fx 2>/dev/null || echo "No external shaders found"
        else
            echo "Shader directory not found"
        fi
        echo ""
        echo "=== Profiles ==="
        if [ -d "$PROFILES_DIR" ]; then
            ls -la "$PROFILES_DIR"/*.conf 2>/dev/null || echo "No profiles found"
        else
            echo "Profiles directory not found"
        fi
        echo ""
        echo "=== Recent Log Entries ==="
        if [ -f "$LOG_FILE" ]; then
            tail -20 "$LOG_FILE" 2>/dev/null || echo "No recent log entries"
        else
            echo "No log file found"
        fi
        echo ""
        echo "=== System Information ==="
        echo "Vulkan Support:"
        vulkaninfo --summary 2>/dev/null || echo "Vulkan not available"
        echo ""
        echo "Disk Space:"
        df -h "${USER_HOME}" | tail -1
        echo ""
        echo "Dependencies:"
        for dep in zenity wget unzip tar vulkaninfo; do
            if command -v $dep &> /dev/null; then
                echo "$dep: Available"
            else
                echo "$dep: Missing"
            fi
        done
    } > "$diag_output"

    zenity --text-info --title="System Diagnostics" --filename="$diag_output" --width=800 --height=600
    rm -f "$diag_output"
}

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
            active_effect=$(cleanup_shader_name "$active_effect")
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
        local description=$(get_shader_description_cached "$shader_name")
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
                local description=$(get_shader_description_cached "$file_basename")
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
            local config_shaders=""
            IFS=':' read -ra SELECTED_ARRAY <<< "$selected_shaders"
            for display_shader in "${SELECTED_ARRAY[@]}"; do
                local config_name="${display_shader,,}"
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
        shader=$(cleanup_shader_name "$shader")
        if [ -z "$lowercase_shaders" ]; then
            lowercase_shaders="${shader,,}"
        else
            lowercase_shaders="${lowercase_shaders}:${shader,,}"
        fi
    done

    local temp_params=$(mktemp)
    local temp_toggle_key=$(mktemp)

    if [ -f "$CONFIG_FILE" ]; then
        grep -E "^[a-zA-Z].*=" "$CONFIG_FILE" | grep -v -E "^(effects|reshadeTexturePath|reshadeIncludePath|depthCapture|enableOnLaunch)" > "$temp_params" 2>/dev/null || true
        grep "^toggleKey" "$CONFIG_FILE" > "$temp_toggle_key" 2>/dev/null || echo "toggleKey = Home" > "$temp_toggle_key"
    else
        echo "toggleKey = Home" > "$temp_toggle_key"
    fi

    mkdir -p "$(dirname "$CONFIG_FILE")"

    cat > "$CONFIG_FILE" << EOF
effects = $lowercase_shaders
reshadeTexturePath = $TEXTURE_PATH
reshadeIncludePath = $SHADER_PATH
depthCapture = off
enableOnLaunch = True

EOF

    cat "$temp_toggle_key" >> "$CONFIG_FILE"
    echo "" >> "$CONFIG_FILE"

    get_saved_or_default() {
        local param_name="$1"
        local default_value="$2"
        local saved_value=$(grep "^$param_name" "$temp_params" 2>/dev/null | cut -d'=' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        if [ ! -z "$saved_value" ]; then
            echo "$saved_value"
        else
            echo "$default_value"
        fi
    }

    for shader in "${SHADER_ARRAY[@]}"; do
        shader=$(cleanup_shader_name "$shader")
        local shader_lower="${shader,,}"

        case "$shader_lower" in
            "cas")
                local cas_sharpness=$(get_saved_or_default "casSharpness" "0.4")
                echo "casSharpness = $cas_sharpness" >> "$CONFIG_FILE"
                ;;
            "fxaa")
                local fxaa_subpix=$(get_saved_or_default "fxaaQualitySubpix" "0.75")
                local fxaa_edge=$(get_saved_or_default "fxaaQualityEdgeThreshold" "0.125")
                echo "fxaaQualitySubpix = $fxaa_subpix" >> "$CONFIG_FILE"
                echo "fxaaQualityEdgeThreshold = $fxaa_edge" >> "$CONFIG_FILE"
                ;;
            "smaa")
                local smaa_detection=$(get_saved_or_default "smaaEdgeDetection" "luma")
                local smaa_threshold=$(get_saved_or_default "smaaThreshold" "0.05")
                local smaa_steps=$(get_saved_or_default "smaaMaxSearchSteps" "32")
                echo "smaaEdgeDetection = $smaa_detection" >> "$CONFIG_FILE"
                echo "smaaThreshold = $smaa_threshold" >> "$CONFIG_FILE"
                echo "smaaMaxSearchSteps = $smaa_steps" >> "$CONFIG_FILE"
                ;;
            "dls")
                local dls_sharpness=$(get_saved_or_default "dlsSharpness" "0.5")
                local dls_denoise=$(get_saved_or_default "dlsDenoise" "0.17")
                echo "dlsSharpness = $dls_sharpness" >> "$CONFIG_FILE"
                echo "dlsDenoise = $dls_denoise" >> "$CONFIG_FILE"
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

    rm -f "$temp_params" "$temp_toggle_key"
    log_info "Configuration updated with effects: $lowercase_shaders"
}

create_default_config() {
    create_dynamic_config "cas"
}

command_line_interface() {
    case "${1,,}" in
        "install")
            install_vkbasalt_complete
            ;;
        "uninstall")
            if [ "$2" = "--force" ] || [ "$2" = "-f" ]; then
                rm -rf "${USER_HOME}/.local/lib/libvkbasalt.so" "${USER_HOME}/.local/lib32/libvkbasalt.so"
                rm -rf "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.json" "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json"
                rm -rf "${USER_HOME}/.config/vkBasalt" "${USER_HOME}/.config/reshade"
                echo "VkBasalt uninstalled (forced)"
            else
                echo "Use --force or -f to confirm uninstallation"
            fi
            ;;
        "status")
            check_installation
            case $? in
                0) echo "VkBasalt: Not installed" ;;
                1) echo "VkBasalt: Partially installed (missing shaders)" ;;
                2) echo "VkBasalt: Fully installed" ;;
            esac
            ;;
        "enable")
            if [ ! -z "$2" ]; then
                create_dynamic_config "$2"
                echo "Effects enabled: $2"
            else
                echo "Usage: $0 enable <effect1:effect2:...>"
            fi
            ;;
        "disable")
            create_minimal_config
            echo "All effects disabled"
            ;;
        "list")
            echo "Available built-in effects: cas, fxaa, smaa, dls"
            if [ -d "$SHADER_PATH" ]; then
                echo "External shaders:"
                ls "$SHADER_PATH"/*.fx 2>/dev/null | xargs -n1 basename -s .fx || echo "None found"
            fi
            ;;
        "toggle")
            if [ ! -z "$2" ]; then
                sed -i "s/^toggleKey.*/toggleKey = $2/" "$CONFIG_FILE"
                echo "Toggle key set to: $2"
            else
                echo "Usage: $0 toggle <key>"
            fi
            ;;
        "backup")
            echo "Feature removed"
            ;;
        "restore")
            echo "Feature removed"
            ;;
        "diagnostics")
            run_diagnostics
            ;;
        "update")
            echo "Feature removed"
            ;;
        "help"|"--help"|"-h")
            echo "VkBasalt Manager CLI"
            echo "Usage: $0 [command] [options]"
            echo ""
            echo "Commands:"
            echo "  install                    Install VkBasalt and dependencies"
            echo "  uninstall [--force]        Uninstall VkBasalt"
            echo "  status                     Show installation status"
            echo "  enable <effects>           Enable specified effects (e.g., cas:fxaa)"
            echo "  disable                    Disable all effects"
            echo "  list                       List available effects"
            echo "  toggle <key>               Set toggle key"
            echo "  backup                     Feature removed"
            echo "  restore <timestamp>        Feature removed"
            echo "  diagnostics                Run system diagnostics"
            echo "  update                     Feature removed"
            echo "  help                       Show this help message"
            echo ""
            echo "Without arguments, the GUI will be launched."
            ;;
        *)
            if [ ! -z "$1" ]; then
                echo "Unknown command: $1"
                echo "Use '$0 help' for available commands"
                exit 1
            fi
            ;;
    esac
}

show_main_menu() {
    check_installation
    local install_status=$?

    if [ $install_status -eq 0 ]; then
        if show_question "🚀 VkBasalt is not yet installed!\n\nWould you like to proceed with automatic installation?"; then
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

show_config_menu() {
    if [ ! -f "$CONFIG_FILE" ]; then
        show_info "🔧 Creating default configuration..."
        create_default_config
        show_info "✅ Default configuration created! VkBasalt is ready with CAS."
    fi

    while true; do
        local shader_count=0
        local builtin_count=4
        local external_count=0

        if [ -d "$SHADER_PATH" ] && [ "$(ls -A $SHADER_PATH 2>/dev/null)" ]; then
            external_count=$(ls -1 $SHADER_PATH/*.fx 2>/dev/null | wc -l)
        fi

        shader_count=$((builtin_count + external_count))

        local status_text=""
        local current_profile=""
        if [ -f "${USER_HOME}/.config/vkBasalt/.current_profile" ]; then
            current_profile=$(cat "${USER_HOME}/.config/vkBasalt/.current_profile" 2>/dev/null)
        fi

        if [ $external_count -gt 0 ]; then
            status_text="VkBasalt ready! ($shader_count shaders: $builtin_count built-in + $external_count external)"
        else
            status_text="VkBasalt ready! ($builtin_count built-in shaders available)"
        fi

        if [ ! -z "$current_profile" ]; then
            status_text="$status_text • Profile: $current_profile"
        fi

        local active_effects=""
        if [ -f "$CONFIG_FILE" ]; then
            active_effects=$(grep "^effects" "$CONFIG_FILE" | head -n1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            if [ ! -z "$active_effects" ] && [ "$active_effects" != "" ]; then
                local effect_count=$(echo "$active_effects" | tr ':' '\n' | wc -l)
                status_text="$status_text • $effect_count effects active"
            else
                status_text="$status_text • No effects active"
            fi
        fi

        local choice=$(zenity --list --title="VkBasalt Manager" --text="$status_text" --column="Option" --column="Description" --width=480 --height=420 \
            "Shaders" "Manage active shaders and effects" \
            "Toggle Key" "Change toggle key for effects" \
            "Advanced" "Advanced built-in effects settings" \
            "Profiles" "Manage configuration profiles" \
            "View Config" "View current configuration file" \
            "Diagnostics" "Run system diagnostics" \
            "Reset" "Reset to default values" \
            "Uninstall" "Uninstall VkBasalt completely" \
            "Exit" "Exit VkBasalt Manager" \
            2>/dev/null)

        case "$choice" in
            "Shaders") manage_shaders ;;
            "Toggle Key") change_toggle_key ;;
            "Advanced") show_advanced_menu ;;
            "Profiles") manage_profiles ;;
            "View Config")
                if [ -f "$CONFIG_FILE" ]; then
                    zenity --text-info --title="Current Configuration" --filename="$CONFIG_FILE" --width=600 --height=400 2>/dev/null
                else
                    show_error "Configuration file not found"
                fi
                ;;
            "Diagnostics") run_diagnostics ;;
            "Reset")
                if show_question "⚠️ Reset configuration to default values?"; then
                    create_default_config
                    show_info "Configuration reset to default values"
                fi
                ;;
            "Uninstall") uninstall_vkbasalt ;;
            "Exit"|"") exit 0 ;;
        esac
    done
}

show_advanced_menu() {
    local choice=$(zenity --list \
        --title="Advanced Settings - Built-in VkBasalt Effects" \
        --text="Configure built-in VkBasalt effects:" \
        --column="Effect" --column="Description" \
        --width=500 --height=300 \
        "CAS" "🔵 Contrast Adaptive Sharpening - AMD FidelityFX" \
        "FXAA" "🔵 Fast Approximate Anti-Aliasing" \
        "SMAA" "🔵 Subpixel Morphological Anti-Aliasing" \
        "DLS" "🔵 Denoised Luma Sharpening - Intelligent sharpening" \
        2>/dev/null)
    case "$choice" in
        "CAS") configure_cas ;;
        "FXAA") configure_fxaa ;;
        "SMAA") configure_smaa ;;
        "DLS") configure_dls ;;
    esac
}

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
        log_info "Toggle key changed to: $new_key"
        show_info "Toggle key changed: $new_key\n\nNow use the '$new_key' key to enable/disable VkBasalt effects in game."
    fi
}

configure_cas() {
    local cur=$(grep "^casSharpness" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local val=40; [ ! -z "$cur" ] && val=$(awk "BEGIN {printf \"%.0f\", $cur * 100}")
    local sharpness=$(zenity --scale --title="CAS - Contrast Adaptive Sharpening" \
        --text="Adjust sharpening strength\nCurrent value: ${cur:-0.4}\n\n0 = No sharpening\n100 = Maximum sharpening" \
        --min-value=0 --max-value=100 --value=$val --step=5)
    if [ ! -z "$sharpness" ]; then
        local v=$(awk "BEGIN {printf \"%.2f\", $sharpness / 100}")
        grep -q "^casSharpness" "$CONFIG_FILE" && sed -i "s/^casSharpness.*/casSharpness = $v/" "$CONFIG_FILE" || echo "casSharpness = $v" >> "$CONFIG_FILE"
        log_info "CAS sharpness set to: $v"
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

        local e=23
        if [ ! -z "$edge" ]; then
            local safe_edge=$(awk "BEGIN {
                val = $edge
                if (val < 0.063) val = 0.063
                if (val > 0.333) val = 0.333
                printf \"%.3f\", val
            }")
            e=$(awk "BEGIN {printf \"%.0f\", ($safe_edge - 0.063) * 100 / 0.27}")
        fi

        local ed=$(zenity --scale --title="FXAA - Edge Threshold" \
            --text="Adjust edge detection sensitivity\nCurrent value: ${edge:-0.125}\n\n0 = Detect all edges (softer)\n100 = Detect only sharp edges (sharper)" \
            --min-value=0 --max-value=100 --value=$e --step=5)
        if [ ! -z "$ed" ]; then
            local edf=$(awk "BEGIN {printf \"%.3f\", 0.063 + ($ed * 0.27 / 100)}")
            grep -q "^fxaaQualitySubpix" "$CONFIG_FILE" && sed -i "s/^fxaaQualitySubpix.*/fxaaQualitySubpix = $spf/" "$CONFIG_FILE" || echo "fxaaQualitySubpix = $spf" >> "$CONFIG_FILE"
            grep -q "^fxaaQualityEdgeThreshold" "$CONFIG_FILE" && sed -i "s/^fxaaQualityEdgeThreshold.*/fxaaQualityEdgeThreshold = $edf/" "$CONFIG_FILE" || echo "fxaaQualityEdgeThreshold = $edf" >> "$CONFIG_FILE"
            log_info "FXAA settings updated: Subpixel=$spf, Edge=$edf"
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
        local t=21
        if [ ! -z "$thresh" ]; then
            local safe_thresh=$(awk "BEGIN {
                val = $thresh
                if (val < 0.01) val = 0.01
                if (val > 0.20) val = 0.20
                printf \"%.3f\", val
            }")
            t=$(awk "BEGIN {printf \"%.0f\", ($safe_thresh - 0.01) * 100 / 0.19}")
        fi

        local th=$(zenity --scale --title="SMAA - Edge Detection Threshold" \
            --text="Adjust edge detection sensitivity\nCurrent value: ${thresh:-0.05}\n\n0 = Detect all edges (softer)\n100 = Detect only sharp edges (sharper)" \
            --min-value=0 --max-value=100 --value=$t --step=5)

        if [ ! -z "$th" ]; then
            local thf=$(awk "BEGIN {printf \"%.3f\", 0.01 + ($th * 0.19 / 100)}")

            local s=43
            if [ ! -z "$steps" ]; then
                local safe_steps=$(awk "BEGIN {
                    val = $steps
                    if (val < 8) val = 8
                    if (val > 64) val = 64
                    printf \"%.0f\", val
                }")
                s=$(awk "BEGIN {printf \"%.0f\", ($safe_steps - 8) * 100 / 56}")
            fi

            local st=$(zenity --scale --title="SMAA - Maximum Search Steps" \
                --text="Adjust search quality vs performance\nCurrent value: ${steps:-32}\n\n0 = Faster (lower quality)\n100 = Slower (higher quality)" \
                --min-value=0 --max-value=100 --value=$s --step=5)

            if [ ! -z "$st" ]; then
                local stf=$(awk "BEGIN {printf \"%.0f\", 8 + ($st * 56 / 100)}")
                grep -q "^smaaEdgeDetection" "$CONFIG_FILE" && sed -i "s/^smaaEdgeDetection.*/smaaEdgeDetection = $edge_detection/" "$CONFIG_FILE" || echo "smaaEdgeDetection = $edge_detection" >> "$CONFIG_FILE"
                grep -q "^smaaThreshold" "$CONFIG_FILE" && sed -i "s/^smaaThreshold.*/smaaThreshold = $thf/" "$CONFIG_FILE" || echo "smaaThreshold = $thf" >> "$CONFIG_FILE"
                grep -q "^smaaMaxSearchSteps" "$CONFIG_FILE" && sed -i "s/^smaaMaxSearchSteps.*/smaaMaxSearchSteps = $stf/" "$CONFIG_FILE" || echo "smaaMaxSearchSteps = $stf" >> "$CONFIG_FILE"
                log_info "SMAA settings updated: Detection=$edge_detection, Threshold=$thf, Steps=$stf"
                show_info "SMAA settings updated\nEdge Detection: $edge_detection\nThreshold: $thf\nMax Search Steps: $stf"
            fi
        fi
    fi
}

configure_dls() {
    local sharpness=$(grep "^dlsSharpness" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local denoise=$(grep "^dlsDenoise" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')

    local sv=50; [ ! -z "$sharpness" ] && sv=$(awk "BEGIN {printf \"%.0f\", $sharpness * 100}")
    local s=$(zenity --scale --title="DLS - Sharpening Strength" \
        --text="Adjust sharpening intensity\nCurrent value: ${sharpness:-0.5}\n\n0 = No sharpening\n100 = Maximum sharpening" \
        --min-value=0 --max-value=100 --value=$sv --step=5)

    if [ ! -z "$s" ]; then
        local sf=$(awk "BEGIN {printf \"%.2f\", $s / 100}")

        local dv=17; [ ! -z "$denoise" ] && dv=$(awk "BEGIN {printf \"%.0f\", $denoise * 100}")
        local d=$(zenity --scale --title="DLS - Denoise Strength" \
            --text="Adjust noise reduction\nCurrent value: ${denoise:-0.17}\n\n0 = No denoising\n100 = Maximum denoising" \
            --min-value=0 --max-value=100 --value=$dv --step=5)

        if [ ! -z "$d" ]; then
            local df=$(awk "BEGIN {printf \"%.2f\", $d / 100}")
            grep -q "^dlsSharpness" "$CONFIG_FILE" && sed -i "s/^dlsSharpness.*/dlsSharpness = $sf/" "$CONFIG_FILE" || echo "dlsSharpness = $sf" >> "$CONFIG_FILE"
            grep -q "^dlsDenoise" "$CONFIG_FILE" && sed -i "s/^dlsDenoise.*/dlsDenoise = $df/" "$CONFIG_FILE" || echo "dlsDenoise = $df" >> "$CONFIG_FILE"
            log_info "DLS settings updated: Sharpness=$sf, Denoise=$df"
            show_info "DLS settings updated\nSharpness: $sf\nDenoise: $df"
        fi
    fi
}

validate_config_values() {
    if [ ! -f "$CONFIG_FILE" ]; then
        return
    fi

    local needs_update=false

    local shader_path=$(grep "^reshadeIncludePath" "$CONFIG_FILE" | cut -d'=' -f2- | sed 's/^[[:space:]]*//')
    if [ ! -z "$shader_path" ] && [ ! -d "$shader_path" ]; then
        mkdir -p "$shader_path"
        log_info "Created missing shader directory: $shader_path"
    fi

    local texture_path=$(grep "^reshadeTexturePath" "$CONFIG_FILE" | cut -d'=' -f2- | sed 's/^[[:space:]]*//')
    if [ ! -z "$texture_path" ] && [ ! -d "$texture_path" ]; then
        mkdir -p "$texture_path"
        log_info "Created missing texture directory: $texture_path"
    fi

    local cas_val=$(grep "^casSharpness" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    if [ ! -z "$cas_val" ]; then
        local corrected=$(awk "BEGIN {
            val = $cas_val
            if (val < 0) val = 0
            if (val > 1) val = 1
            printf \"%.2f\", val
        }")
        if [ "$cas_val" != "$corrected" ]; then
            sed -i "s/^casSharpness.*/casSharpness = $corrected/" "$CONFIG_FILE"
            log_info "Corrected CAS sharpness value: $cas_val -> $corrected"
            needs_update=true
        fi
    fi

    local fxaa_edge=$(grep "^fxaaQualityEdgeThreshold" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    if [ ! -z "$fxaa_edge" ]; then
        local corrected=$(awk "BEGIN {
            val = $fxaa_edge
            if (val < 0.063) val = 0.063
            if (val > 0.333) val = 0.333
            printf \"%.3f\", val
        }")
        if [ "$fxaa_edge" != "$corrected" ]; then
            sed -i "s/^fxaaQualityEdgeThreshold.*/fxaaQualityEdgeThreshold = $corrected/" "$CONFIG_FILE"
            log_info "Corrected FXAA edge threshold: $fxaa_edge -> $corrected"
            needs_update=true
        fi
    fi

    local smaa_thresh=$(grep "^smaaThreshold" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    if [ ! -z "$smaa_thresh" ]; then
        local corrected=$(awk "BEGIN {
            val = $smaa_thresh
            if (val < 0.01) val = 0.01
            if (val > 0.20) val = 0.20
            printf \"%.3f\", val
        }")
        if [ "$smaa_thresh" != "$corrected" ]; then
            sed -i "s/^smaaThreshold.*/smaaThreshold = $corrected/" "$CONFIG_FILE"
            log_info "Corrected SMAA threshold: $smaa_thresh -> $corrected"
            needs_update=true
        fi
    fi

    local smaa_steps=$(grep "^smaaMaxSearchSteps" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    if [ ! -z "$smaa_steps" ]; then
        local corrected=$(awk "BEGIN {
            val = $smaa_steps
            if (val < 8) val = 8
            if (val > 64) val = 64
            printf \"%.0f\", val
        }")
        if [ "$smaa_steps" != "$corrected" ]; then
            sed -i "s/^smaaMaxSearchSteps.*/smaaMaxSearchSteps = $corrected/" "$CONFIG_FILE"
            log_info "Corrected SMAA max search steps: $smaa_steps -> $corrected"
            needs_update=true
        fi
    fi

    local dls_sharp=$(grep "^dlsSharpness" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    if [ ! -z "$dls_sharp" ]; then
        local corrected=$(awk "BEGIN {
            val = $dls_sharp
            if (val < 0) val = 0
            if (val > 1) val = 1
            printf \"%.2f\", val
        }")
        if [ "$dls_sharp" != "$corrected" ]; then
            sed -i "s/^dlsSharpness.*/dlsSharpness = $corrected/" "$CONFIG_FILE"
            log_info "Corrected DLS sharpness: $dls_sharp -> $corrected"
            needs_update=true
        fi
    fi

    local dls_denoise=$(grep "^dlsDenoise" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    if [ ! -z "$dls_denoise" ]; then
        local corrected=$(awk "BEGIN {
            val = $dls_denoise
            if (val < 0) val = 0
            if (val > 1) val = 1
            printf \"%.2f\", val
        }")
        if [ "$dls_denoise" != "$corrected" ]; then
            sed -i "s/^dlsDenoise.*/dlsDenoise = $corrected/" "$CONFIG_FILE"
            log_info "Corrected DLS denoise: $dls_denoise -> $corrected"
            needs_update=true
        fi
    fi

    if [ "$needs_update" = true ]; then
        show_info "⚠️ Configuration values were automatically corrected to valid ranges."
    fi
}

main() {
    log_info "VkBasalt Manager started with arguments: $*"

    if [ $# -gt 0 ]; then
        command_line_interface "$@"
        exit $?
    fi

    check_dependencies
    validate_config_values
    show_main_menu
}

main "$@"
