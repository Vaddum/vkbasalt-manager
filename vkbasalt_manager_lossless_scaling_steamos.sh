#!/bin/bash

# VkBasalt Manager - SteamOS/Steam Deck Version
# Complete installation, configuration and management tool for Steam Deck

# System paths for Steam Deck
USER_HOME="/home/deck"
SYSTEM_USER="deck"

CONFIG_FILE="${USER_HOME}/.config/vkBasalt/vkBasalt.conf"
SHADER_PATH="${USER_HOME}/.config/reshade/Shaders"
TEXTURE_PATH="${USER_HOME}/.config/reshade/Textures"
SCRIPT_PATH="${USER_HOME}/.config/vkBasalt/vkbasalt-manager.sh"
ICON_PATH="${USER_HOME}/.config/vkBasalt/vkbasalt-manager.svg"
DESKTOP_FILE="${USER_HOME}/Desktop/VkBasalt-Manager.desktop"

# Steam paths - Multiple possible locations on Steam Deck
STEAM_CONFIG_DIRS=(
    "${USER_HOME}/.steam/steam/config"
    "${USER_HOME}/.local/share/Steam/config"
    "${USER_HOME}/.var/app/com.valvesoftware.Steam/.steam/steam/config"
    "${USER_HOME}/.var/app/com.valvesoftware.Steam/.local/share/Steam/config"
)

STEAM_USERDATA_DIRS=(
    "${USER_HOME}/.steam/steam/userdata"
    "${USER_HOME}/.local/share/Steam/userdata"
    "${USER_HOME}/.var/app/com.valvesoftware.Steam/.steam/steam/userdata"
    "${USER_HOME}/.var/app/com.valvesoftware.Steam/.local/share/Steam/userdata"
)

# Simple and reliable Steam check
is_steam_running() {
    # Check for Steam windows using wmctrl if available
    if command -v wmctrl &> /dev/null; then
        if wmctrl -l | grep -i "steam" > /dev/null 2>&1; then
            return 0
        fi
    fi

    # Check for Steam lock file
    if [ -f "${USER_HOME}/.steam/steam.pid" ]; then
        local steam_pid=$(cat "${USER_HOME}/.steam/steam.pid" 2>/dev/null)
        if [ ! -z "$steam_pid" ] && kill -0 "$steam_pid" 2>/dev/null; then
            return 0
        fi
    fi

    # Final check: look for main Steam process that's actually running
    if pgrep -x "steam" > /dev/null 2>&1; then
        # Additional check to see if it's the main UI process
        local steam_cmdlines=$(pgrep -x "steam" -a 2>/dev/null)
        if echo "$steam_cmdlines" | grep -v "steamwebhelper\|steam://\|\.steam" > /dev/null; then
            return 0
        fi
    fi

    return 1
}

# Advanced Steam diagnostic with file permissions
diagnose_steam_accessibility() {
    echo "=== Advanced Steam Accessibility Diagnosis ==="

    # Check current user
    echo "Current user: $(whoami)"
    echo "Expected user: deck"

    if [ "$(whoami)" != "deck" ]; then
        echo "⚠️  WARNING: Script should be run as 'deck' user"
    fi

    # Find Steam directories
    local steam_config_dir=""
    local steam_userdata_dir=""

    echo ""
    echo "Searching for Steam installations..."

    # Check all possible Steam locations
    local steam_locations=(
        "${USER_HOME}/.steam/steam"
        "${USER_HOME}/.local/share/Steam"
        "${USER_HOME}/.var/app/com.valvesoftware.Steam/.steam/steam"
        "${USER_HOME}/.var/app/com.valvesoftware.Steam/.local/share/Steam"
    )

    for location in "${steam_locations[@]}"; do
        if [ -d "$location" ]; then
            echo "✓ Found Steam at: $location"

            # Check config directory
            if [ -d "$location/config" ]; then
                echo "  ✓ Config directory exists"
                steam_config_dir="$location/config"

                # Check libraryfolders.vdf
                if [ -f "$location/config/libraryfolders.vdf" ]; then
                    echo "    ✓ libraryfolders.vdf exists ($(ls -la "$location/config/libraryfolders.vdf"))"
                else
                    echo "    ✗ libraryfolders.vdf missing"
                fi
            else
                echo "  ✗ Config directory missing"
            fi

            # Check userdata directory
            if [ -d "$location/userdata" ]; then
                echo "  ✓ Userdata directory exists"
                steam_userdata_dir="$location/userdata"

                # List user directories
                local user_dirs=$(ls -1 "$location/userdata" 2>/dev/null | grep '^[0-9]*$')
                if [ ! -z "$user_dirs" ]; then
                    echo "    User directories found:"
                    for uid in $user_dirs; do
                        local config_path="$location/userdata/$uid/config"
                        local vdf_file="$config_path/localconfig.vdf"

                        echo "      User $uid:"
                        if [ -d "$config_path" ]; then
                            echo "        ✓ Config dir exists"
                            if [ -f "$vdf_file" ]; then
                                echo "        ✓ localconfig.vdf exists"
                                echo "          File info: $(ls -la "$vdf_file")"
                                echo "          Size: $(wc -c < "$vdf_file") bytes"
                                echo "          Readable: $([ -r "$vdf_file" ] && echo "YES" || echo "NO")"
                                echo "          Writable: $([ -w "$vdf_file" ] && echo "YES" || echo "NO")"
                            else
                                echo "        ✗ localconfig.vdf missing"
                            fi
                        else
                            echo "        ✗ Config dir missing"
                        fi
                    done
                else
                    echo "    ✗ No user directories found"
                fi
            else
                echo "  ✗ Userdata directory missing"
            fi
            echo ""
        else
            echo "✗ Not found: $location"
        fi
    done

    # Check Steam processes
    echo "Steam processes:"
    local steam_processes=$(pgrep -af "steam" 2>/dev/null)
    if [ ! -z "$steam_processes" ]; then
        echo "✓ Steam is running:"
        echo "$steam_processes"
    else
        echo "✗ Steam is not running"
    fi

    # Check file system permissions
    echo ""
    echo "File system checks:"
    echo "Home directory writable: $([ -w "$USER_HOME" ] && echo "YES" || echo "NO")"

    # Try to create a test file
    local test_file="$USER_HOME/.steam_test_$$"
    if touch "$test_file" 2>/dev/null; then
        echo "Test file creation: SUCCESS"
        rm -f "$test_file"
    else
        echo "Test file creation: FAILED"
    fi

    echo "================================="

    # Return found directories
    if [ ! -z "$steam_config_dir" ] && [ ! -z "$steam_userdata_dir" ]; then
        export FOUND_STEAM_CONFIG_DIR="$steam_config_dir"
        export FOUND_STEAM_USERDATA_DIR="$steam_userdata_dir"
        return 0
    else
        return 1
    fi
}

# Force create Steam config if missing
force_create_steam_config() {
    local steam_user_id="$1"
    local userdata_dir="$2"

    if [ -z "$steam_user_id" ] || [ -z "$userdata_dir" ]; then
        return 1
    fi

    local config_dir="$userdata_dir/$steam_user_id/config"
    local config_file="$config_dir/localconfig.vdf"

    # Create config directory if it doesn't exist
    if [ ! -d "$config_dir" ]; then
        echo "Creating config directory: $config_dir"
        mkdir -p "$config_dir" || return 1
    fi

    # Create minimal localconfig.vdf if it doesn't exist
    if [ ! -f "$config_file" ]; then
        echo "Creating minimal localconfig.vdf"
        cat > "$config_file" << 'EOF'
"UserLocalConfigStore"
{
	"Software"
	{
		"Valve"
		{
			"Steam"
			{
				"Apps"
				{
				}
			}
		}
	}
}
EOF

        # Set proper permissions
        chmod 644 "$config_file"
        chown "${SYSTEM_USER}:${SYSTEM_USER}" "$config_file" 2>/dev/null || true

        if [ -f "$config_file" ]; then
            echo "✓ Created localconfig.vdf successfully"
            return 0
        else
            echo "✗ Failed to create localconfig.vdf"
            return 1
        fi
    fi

    return 0
}

# Function to find Steam directories
find_steam_directories() {
    local config_dir=""
    local userdata_dir=""

    # Find config directory
    for dir in "${STEAM_CONFIG_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            config_dir="$dir"
            break
        fi
    done

    # Find userdata directory
    for dir in "${STEAM_USERDATA_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            userdata_dir="$dir"
            break
        fi
    done

    if [ -z "$config_dir" ] || [ -z "$userdata_dir" ]; then
        return 1
    fi

    # Set global variables
    STEAM_CONFIG_DIR="$config_dir"
    STEAM_USERDATA_DIR="$userdata_dir"
    return 0
}

# Function to get Steam user ID with better detection
get_steam_user_id() {
    # First ensure we have the right Steam directories
    if ! find_steam_directories; then
        return 1
    fi

    if [ -d "$STEAM_USERDATA_DIR" ]; then
        # Find the largest numbered directory (most recent user)
        local user_id=$(ls -1 "$STEAM_USERDATA_DIR" 2>/dev/null | grep '^[0-9]*$' | sort -n | tail -n1)
        if [ ! -z "$user_id" ] && [ -d "$STEAM_USERDATA_DIR/$user_id" ]; then
            echo "$user_id"
            return 0
        fi
    fi
    return 1
}

# Robust function to get Steam config file path
get_steam_config_file() {
    # First run diagnosis
    if ! diagnose_steam_accessibility > /dev/null 2>&1; then
        echo "ERROR: Steam accessibility diagnosis failed"
        return 1
    fi

    # Use found directories from diagnosis
    local steam_config_dir="$FOUND_STEAM_CONFIG_DIR"
    local steam_userdata_dir="$FOUND_STEAM_USERDATA_DIR"

    if [ -z "$steam_config_dir" ] || [ -z "$steam_userdata_dir" ]; then
        echo "ERROR: Steam directories not found"
        return 1
    fi

    # Get user ID
    local steam_user_id=$(ls -1 "$steam_userdata_dir" 2>/dev/null | grep '^[0-9]*$' | sort -n | tail -n1)
    if [ -z "$steam_user_id" ]; then
        echo "ERROR: No Steam user ID found"
        return 1
    fi

    local config_file="$steam_userdata_dir/$steam_user_id/config/localconfig.vdf"

    # Check if file exists and is accessible
    if [ -f "$config_file" ] && [ -r "$config_file" ] && [ -w "$config_file" ]; then
        echo "$config_file"
        return 0
    fi

    # Try to fix permissions if file exists but not accessible
    if [ -f "$config_file" ]; then
        echo "Attempting to fix file permissions..."
        chmod 644 "$config_file" 2>/dev/null
        chown "${SYSTEM_USER}:${SYSTEM_USER}" "$config_file" 2>/dev/null || true

        if [ -r "$config_file" ] && [ -w "$config_file" ]; then
            echo "✓ Fixed permissions for $config_file"
            echo "$config_file"
            return 0
        fi
    fi

    # Try to create the file if it doesn't exist
    echo "Attempting to create missing config file..."
    if force_create_steam_config "$steam_user_id" "$steam_userdata_dir"; then
        if [ -f "$config_file" ] && [ -r "$config_file" ] && [ -w "$config_file" ]; then
            echo "$config_file"
            return 0
        fi
    fi

    echo "ERROR: Cannot access or create $config_file"
    return 1
}

# Comprehensive Steam diagnostic function
diagnose_steam_installation() {
    echo "=== Steam Installation Diagnosis ==="

    echo "Checking Steam directories..."
    local found_config=false
    local found_userdata=false

    for dir in "${STEAM_CONFIG_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo "✓ Config found: $dir"
            found_config=true
            # Check for libraryfolders.vdf
            if [ -f "$dir/libraryfolders.vdf" ]; then
                echo "  ✓ libraryfolders.vdf exists"
            else
                echo "  ✗ libraryfolders.vdf missing"
            fi
        else
            echo "✗ Config not found: $dir"
        fi
    done

    for dir in "${STEAM_USERDATA_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo "✓ Userdata found: $dir"
            found_userdata=true
            # List user IDs
            local user_ids=$(ls -1 "$dir" 2>/dev/null | grep '^[0-9]*$')
            if [ ! -z "$user_ids" ]; then
                echo "  User IDs found: $user_ids"
                for uid in $user_ids; do
                    local config_file="$dir/$uid/config/localconfig.vdf"
                    if [ -f "$config_file" ]; then
                        echo "    ✓ $uid: localconfig.vdf exists ($(wc -c < "$config_file") bytes)"
                    else
                        echo "    ✗ $uid: localconfig.vdf missing"
                    fi
                done
            else
                echo "  ✗ No user IDs found"
            fi
        else
            echo "✗ Userdata not found: $dir"
        fi
    done

    # Check if Steam is installed via different methods
    echo ""
    echo "Steam installation methods:"
    if [ -d "${USER_HOME}/.steam" ]; then
        echo "✓ Native Steam installation detected"
    else
        echo "✗ Native Steam not found"
    fi

    if [ -d "${USER_HOME}/.var/app/com.valvesoftware.Steam" ]; then
        echo "✓ Flatpak Steam installation detected"
    else
        echo "✗ Flatpak Steam not found"
    fi

    # Check Steam processes
    echo ""
    echo "Steam processes:"
    if pgrep -f "steam" > /dev/null 2>&1; then
        echo "✓ Steam processes running:"
        pgrep -af "steam" | head -3
    else
        echo "✗ No Steam processes running"
    fi

    echo "================================="

    return $([ "$found_config" = true ] && [ "$found_userdata" = true ])
}

# Create necessary directories
mkdir -p "${USER_HOME}/Desktop"

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

    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    # Check for Python3 for automatic Steam configuration
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Installing missing dependencies: ${missing_deps[*]}"

        # SteamOS - disable readonly filesystem temporarily
        if command -v steamos-readonly &> /dev/null; then
            sudo steamos-readonly disable 2>/dev/null || true
        fi

        sudo pacman -S --noconfirm "${missing_deps[@]}"

        if command -v steamos-readonly &> /dev/null; then
            sudo steamos-readonly enable 2>/dev/null || true
        fi
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

    # Check VkBasalt core files
    if [ -f "${USER_HOME}/.local/lib/libvkbasalt.so" ] && [ -f "${USER_HOME}/.local/lib32/libvkbasalt.so" ]; then
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

        # Update the Exec path in the desktop file
        if [ -f "$DESKTOP_FILE" ]; then
            sed -i "s|Exec=.*|Exec=$SCRIPT_PATH|" "$DESKTOP_FILE"
        fi

        return 0
    fi
    return 1
}

# Install VkBasalt from Chaotic AUR
install_vkbasalt() {
    # System checks
    if [ "$EUID" -eq 0 ]; then
        echo "ERROR: This script should not be run as root"
        return 1
    fi

    # Installation from Chaotic AUR for Steam Deck
    local AUR_BASE='https://builds.garudalinux.org/repos/chaotic-aur/x86_64/'

    local VKBASALT_PKG_VER
    VKBASALT_PKG_VER=$(curl -s ${AUR_BASE} 2>/dev/null | grep -o 'vkbasalt-[0-9\.\-]*-x86_64' | head -1)
    if [ -z "$VKBASALT_PKG_VER" ]; then
        echo "ERROR: Cannot fetch VkBasalt package information"
        return 1
    fi

    local VKBASALT_PKG="${VKBASALT_PKG_VER}.pkg.tar.zst"
    local VKBASALT_LIB32_PKG="lib32-${VKBASALT_PKG}"
    local VKBASALT_PKG_FILE=$(mktemp /tmp/vkbasalt.XXXXXX.tar.zst)
    local VKBASALT_LIB32_PKG_FILE=$(mktemp /tmp/vkbasalt.XXXXXX.lib32.tar.zst)

    if ! wget -q "${AUR_BASE}${VKBASALT_PKG}" -O "${VKBASALT_PKG_FILE}"; then
        echo "ERROR: Failed to download VkBasalt package"
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    if ! wget -q "${AUR_BASE}${VKBASALT_LIB32_PKG}" -O "${VKBASALT_LIB32_PKG_FILE}"; then
        echo "ERROR: Failed to download VkBasalt lib32 package"
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    mkdir -p "${USER_HOME}/.local/lib"
    mkdir -p "${USER_HOME}/.local/lib32"
    mkdir -p "${USER_HOME}/.local/share/vulkan/implicit_layer.d"
    mkdir -p "${USER_HOME}/.config/vkBasalt"
    mkdir -p "${USER_HOME}/.config/reshade"

    if ! tar xf "${VKBASALT_PKG_FILE}" --strip-components=2 --directory="${USER_HOME}/.local/lib/" usr/lib/libvkbasalt.so; then
        echo "ERROR: Failed to extract main VkBasalt library"
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    if ! tar xf "${VKBASALT_LIB32_PKG_FILE}" --strip-components=2 --directory="${USER_HOME}/.local/lib32/" usr/lib32/libvkbasalt.so; then
        echo "ERROR: Failed to extract lib32 VkBasalt library"
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    # Configure Vulkan layers with Steam Deck specific environment variable
    if ! tar xf "${VKBASALT_PKG_FILE}" --to-stdout usr/share/vulkan/implicit_layer.d/vkBasalt.json \
            | sed -e "s|libvkbasalt.so|${USER_HOME}/.local/lib/libvkbasalt.so|" \
                  -e "s/ENABLE_VKBASALT/SteamDeck/" \
                  > "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.json"; then
        echo "ERROR: Failed to configure main Vulkan layer"
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    if ! tar xf "${VKBASALT_LIB32_PKG_FILE}" --to-stdout usr/share/vulkan/implicit_layer.d/vkBasalt.x86.json \
            | sed -e "s|libvkbasalt.so|${USER_HOME}/.local/lib32/libvkbasalt.so|" \
                  -e "s/ENABLE_VKBASALT/SteamDeck/" \
                  > "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json"; then
        echo "ERROR: Failed to configure lib32 Vulkan layer"
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    tar xf "${VKBASALT_PKG_FILE}" --to-stdout usr/share/vkBasalt/vkBasalt.conf.example 2>/dev/null \
            | sed -e "s|/opt/reshade/textures|${USER_HOME}/.config/reshade/Textures|" \
                  -e "s|/opt/reshade/shaders|${USER_HOME}/.config/reshade/Shaders|" \
                  > "${USER_HOME}/.config/vkBasalt/vkBasalt.conf.example" || true

    rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
    chown -R "${SYSTEM_USER}:${SYSTEM_USER}" "${USER_HOME}/.local/lib" "${USER_HOME}/.local/lib32" "${USER_HOME}/.local/share" "${USER_HOME}/.config/vkBasalt" "${USER_HOME}/.config/reshade" 2>/dev/null || true

    return 0
}

# Main installation function
install_vkbasalt_complete() {
    show_info "🚀 VkBasalt Manager Installation\n\nInstalling on: Steam Deck\n\nThe installation will download and install:\n• VkBasalt\n• ReShade shaders\n• Default configurations\n• Graphical interface\n\nThis may take a few minutes..."

    (
        echo "10" ; echo "# System check..."
        mkdir -p "${USER_HOME}/Desktop" "${USER_HOME}/.config/vkBasalt" "${USER_HOME}/.config/reshade" 2>/dev/null || true

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

        echo "90" ; echo "# Creating desktop icon..."
        create_icon_and_desktop

        echo "95" ; echo "# Setting permissions..."
        chmod +x "$SCRIPT_PATH" "$DESKTOP_FILE" 2>/dev/null || true
        chown "${SYSTEM_USER}:${SYSTEM_USER}" "$SCRIPT_PATH" "$ICON_PATH" "$DESKTOP_FILE" 2>/dev/null || true

        echo "100" ; echo "# Installation complete!"

    ) | zenity --progress --title="VkBasalt Manager Installation" --text="Preparing..." --percentage=0 --auto-close --width=420 --height=110

    if [ $? -eq 0 ] && [ -f "${USER_HOME}/.local/lib/libvkbasalt.so" ] && [ -f "${USER_HOME}/.local/lib32/libvkbasalt.so" ]; then
        local script_moved_msg=""
        if [ "$(realpath "$0")" != "$SCRIPT_PATH" ]; then
            script_moved_msg="\n\n📁 The script has been moved to: $SCRIPT_PATH\n💡 You can now delete the original script file."
        fi

        show_info "✅ Installation successful!$script_moved_msg\n\nVkBasalt Manager is now installed and ready to use.\n\n🔧 Use this manager to configure effects and settings."
        return 0
    else
        show_error "❌ Installation failed!\n\nPossible causes:\n• Network connection issues\n• Missing dependencies\n• Insufficient permissions\n\nPlease check your internet connection and try again."
        return 1
    fi
}

# Create desktop icon
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
    <path d="M-20,-15 Q-10,0 0,10 Q8,20 15,30" stroke="url(#crackGrad)" stroke-width="3" fill="none" opacity="0.9"/>
    <path d="M-30,-5 Q-15,5 -5,8" stroke="url(#crackGrad)" stroke-width="2" fill="none" opacity="0.8"/>
    <path d="M10,-20 Q18,-5 25,5" stroke="url(#crackGrad)" stroke-width="2" fill="none" opacity="0.8"/>
  </g>
  <g transform="translate(64,64)">
    <ellipse cx="0" cy="15" rx="12" ry="8" fill="url(#lavaGrad)" opacity="0.9"/>
    <circle cx="-18" cy="-8" r="4" fill="url(#lavaGrad)" opacity="0.8"/>
    <ellipse cx="22" cy="-5" rx="5" ry="3" fill="url(#lavaGrad)" opacity="0.8"/>
  </g>
</svg>
EOF

    # Create the desktop file
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
NoDisplay=false
StartupWMClass=zenity
Categories=Game;Settings;
MimeType=
EOF

    chmod +x "$DESKTOP_FILE" 2>/dev/null || true
}

# Uninstall VkBasalt
uninstall_vkbasalt() {
    if show_question "🗑️ Uninstall VkBasalt?\n\n⚠️ WARNING: This will remove EVERYTHING:\n• VkBasalt Manager\n• VkBasalt itself\n• All configurations\n• All shaders\n\nThis action is IRREVERSIBLE!\n\nContinue?"; then
        (
            echo "10" ; echo "# Removing VkBasalt Manager..."
            rm -f "$SCRIPT_PATH" "$ICON_PATH" "$DESKTOP_FILE"

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

        show_info "✅ Uninstallation finished!\n\nVkBasalt has been completely removed from your Steam Deck."
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
    local status_text="System: Steam Deck (SteamOS)\n"

    [ -f "${USER_HOME}/.local/lib/libvkbasalt.so" ] && [ -f "${USER_HOME}/.local/lib32/libvkbasalt.so" ] \
        && status_text+="✓ VkBasalt: Installed\n" || status_text+="✗ VkBasalt: Not installed\n"

    [ -f "$CONFIG_FILE" ] && status_text+="✓ Configuration: Found\n" || status_text+="⚠ Configuration: Missing\n"

    if [ -d "$SHADER_PATH" ] && [ "$(ls -A $SHADER_PATH 2>/dev/null)" ]; then
        local shader_count=$(ls -1 $SHADER_PATH/*.fx 2>/dev/null | wc -l)
        status_text+="✓ Shaders: $shader_count installed\n"
    else
        status_text+="✗ Shaders: Not installed\n"
    fi

    # Check for Python3 availability for automatic Steam configuration
    if command -v python3 &> /dev/null; then
        status_text+="✓ Python3: Available for automatic Steam config\n"
    else
        status_text+="⚠ Python3: Missing - manual config only\n"
    fi

    # Check Steam configuration
    local steam_user_id=$(get_steam_user_id)
    if [ ! -z "$steam_user_id" ] && [ -f "$STEAM_USERDATA_DIR/$steam_user_id/config/localconfig.vdf" ]; then
        status_text+="✓ Steam Config: Accessible\n"
    else
        status_text+="⚠ Steam Config: Not found or inaccessible\n"
    fi

    zenity --info --text="$status_text" --title="Installation Status" --width=450 --height=320
}

# Debug function to check Steam configuration
debug_steam_config() {
    local steam_user_id=$(get_steam_user_id)
    local config_file="$STEAM_USERDATA_DIR/$steam_user_id/config/localconfig.vdf"

    echo "=== Steam Configuration Debug ==="
    echo "Steam user ID: $steam_user_id"
    echo "Config file: $config_file"
    echo "Config file exists: $([ -f "$config_file" ] && echo "YES" || echo "NO")"
    echo "Config file readable: $([ -r "$config_file" ] && echo "YES" || echo "NO")"
    echo "Config file writable: $([ -w "$config_file" ] && echo "YES" || echo "NO")"
    echo "Python3 available: $(command -v python3 &> /dev/null && echo "YES" || echo "NO")"
    echo "Steam running: $(pgrep -x "steam" > /dev/null 2>&1 && echo "YES" || echo "NO")"

    if [ -f "$config_file" ]; then
        echo "Config file size: $(wc -c < "$config_file") bytes"
        echo "Apps section found: $(grep -q '"Apps"' "$config_file" && echo "YES" || echo "NO")"
    fi
    echo "================================="
}

# Function to get Steam user ID
get_steam_user_id() {
    if [ -d "$STEAM_USERDATA_DIR" ]; then
        ls -1 "$STEAM_USERDATA_DIR" 2>/dev/null | head -n1
    fi
}

# Check if Python3 is available
check_python3() {
    if ! command -v python3 &> /dev/null; then
        show_error "❌ Python3 is required for automatic Steam configuration\n\nPlease install Python3 or use manual configuration."
        return 1
    fi
    return 0
}

# Function to backup and modify Steam's localconfig.vdf - SIMPLIFIED (no Steam check)
modify_steam_launch_options() {
    local app_id="$1"
    local launch_options="$2"
    local action="$3"  # "add" or "remove"

    echo "=== DEBUG: modify_steam_launch_options ==="
    echo "App ID: $app_id"
    echo "Launch options: $launch_options"
    echo "Action: $action"

    local config_file
    config_file=$(get_steam_config_file)
    if [ -z "$config_file" ]; then
        echo "ERROR: Steam config file not found"
        return 1
    fi

    echo "Config file: $config_file"

    # Verify file exists and is writable
    if [ ! -f "$config_file" ]; then
        echo "ERROR: Config file does not exist: $config_file"
        return 1
    fi

    if [ ! -w "$config_file" ]; then
        echo "ERROR: Config file is not writable: $config_file"
        return 1
    fi

    # Create backup
    local backup_file="$config_file.backup.$(date +%Y%m%d_%H%M%S)"
    if ! cp "$config_file" "$backup_file" 2>/dev/null; then
        echo "ERROR: Failed to create backup"
        return 1
    fi
    echo "Backup created: $backup_file"

    # NOTE: Steam closure is now handled by handle_steam_closure() before calling this function
    echo "Proceeding with configuration modification (Steam closure handled externally)"

    # [Le reste du code Python reste identique - pas de changement dans la partie Python]
    # Use a simpler, more reliable Python script
    python3 << EOF
import sys
import re
import os

def debug_print(msg):
    print(f"[DEBUG] {msg}")

def modify_steam_config(config_file, app_id, launch_options, action):
    debug_print(f"Starting modification: {action} for app {app_id}")

    try:
        # Read file
        with open(config_file, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        debug_print(f"File read successfully, size: {len(content)} bytes")

        # First, find or create the Apps section
        apps_match = re.search(r'"Apps"\s*\{', content)
        if not apps_match:
            debug_print("Apps section not found, trying to create it")
            # Try to add Apps section
            steam_section = re.search(r'("Steam"\s*\{)', content)
            if steam_section:
                insert_pos = steam_section.end()
                apps_section = '\n\t\t\t"Apps"\n\t\t\t{\n\t\t\t}\n'
                content = content[:insert_pos] + apps_section + content[insert_pos:]
                debug_print("Added Apps section")
            else:
                debug_print("ERROR: Cannot find Steam section to add Apps")
                return False

        # Find the full Apps section with proper bracket matching
        apps_start = re.search(r'"Apps"\s*\{', content)
        if not apps_start:
            debug_print("ERROR: Still cannot find Apps section")
            return False

        # Find the matching closing bracket for Apps
        bracket_count = 0
        apps_content_start = apps_start.end()
        apps_end_pos = None

        for i, char in enumerate(content[apps_content_start:], apps_content_start):
            if char == '{':
                bracket_count += 1
            elif char == '}':
                if bracket_count == 0:
                    apps_end_pos = i
                    break
                bracket_count -= 1

        if apps_end_pos is None:
            debug_print("ERROR: Cannot find end of Apps section")
            return False

        apps_content = content[apps_content_start:apps_end_pos]
        debug_print(f"Apps content extracted, length: {len(apps_content)}")

        # Look for the specific app
        app_pattern = rf'"{re.escape(app_id)}"\s*\{{'
        app_match = re.search(app_pattern, apps_content)

        if action == 'add':
            if app_match:
                debug_print(f"App {app_id} found, updating")
                # Find the app's content
                app_start = app_match.start()

                # Find the matching closing bracket for this app
                bracket_count = 0
                app_content_start = app_match.end()
                app_end_pos = None

                for i, char in enumerate(apps_content[app_content_start:], app_content_start):
                    if char == '{':
                        bracket_count += 1
                    elif char == '}':
                        if bracket_count == 0:
                            app_end_pos = i
                            break
                        bracket_count -= 1

                if app_end_pos is None:
                    debug_print(f"ERROR: Cannot find end of app {app_id} section")
                    return False

                app_content = apps_content[app_content_start:app_end_pos]
                debug_print(f"App content: {app_content[:100]}...")

                # Look for existing LaunchOptions
                launch_match = re.search(r'"LaunchOptions"\s*"([^"]*)"', app_content)

                if launch_match:
                    debug_print("Found existing LaunchOptions, updating")
                    current_options = launch_match.group(1)

                    # Remove existing LSFG options with better precision matching
                    new_options = re.sub(r'ENABLE_LSFG=\d+\s*', '', current_options)
                    new_options = re.sub(r'LSFG_MULTIPLIER=\d+\s*', '', new_options)
                    new_options = re.sub(r'LSFG_FLOW_SCALE=[\d.]+\s*', '', new_options)
                    new_options = re.sub(r'LSFG_PERF_MODE=\d+\s*', '', new_options)
                    new_options = new_options.strip()

                    # Add new options
                    if new_options:
                        final_options = f"{launch_options} {new_options}"
                    else:
                        final_options = launch_options

                    # Replace in app content
                    new_app_content = re.sub(r'"LaunchOptions"\s*"[^"]*"',
                                           f'"LaunchOptions"\t\t"{final_options}"', app_content)
                else:
                    debug_print("No existing LaunchOptions, adding new")
                    # Add LaunchOptions at the beginning of app content
                    new_app_content = f'\n\t\t\t\t"LaunchOptions"\t\t"{launch_options}"{app_content}'

                # Replace the app section in apps_content
                new_apps_content = (apps_content[:app_content_start] +
                                  new_app_content +
                                  apps_content[app_end_pos:])

            else:
                debug_print(f"App {app_id} not found, creating new entry")
                # Add new app entry
                new_app_entry = f'\n\t\t\t"{app_id}"\n\t\t\t{{\n\t\t\t\t"LaunchOptions"\t\t"{launch_options}"\n\t\t\t}}'
                new_apps_content = apps_content + new_app_entry

        elif action == 'remove':
            if app_match:
                debug_print(f"Removing LSFG options from app {app_id}")
                # Find the app's content (same as above)
                app_start = app_match.start()
                bracket_count = 0
                app_content_start = app_match.end()
                app_end_pos = None

                for i, char in enumerate(apps_content[app_content_start:], app_content_start):
                    if char == '{':
                        bracket_count += 1
                    elif char == '}':
                        if bracket_count == 0:
                            app_end_pos = i
                            break
                        bracket_count -= 1

                if app_end_pos is None:
                    return False

                app_content = apps_content[app_content_start:app_end_pos]

                # Look for LaunchOptions and remove LSFG options
                launch_match = re.search(r'"LaunchOptions"\s*"([^"]*)"', app_content)

                if launch_match:
                    current_options = launch_match.group(1)

                    # Remove LSFG options
                    new_options = re.sub(r'ENABLE_LSFG=\d+\s*', '', current_options)
                    new_options = re.sub(r'LSFG_MULTIPLIER=\d+\s*', '', new_options)
                    new_options = re.sub(r'LSFG_FLOW_SCALE=[\d.]+\s*', '', new_options)
                    new_options = re.sub(r'LSFG_PERF_MODE=\d+\s*', '', new_options)
                    new_options = new_options.strip()

                    if new_options:
                        # Keep other options
                        new_app_content = re.sub(r'"LaunchOptions"\s*"[^"]*"',
                                               f'"LaunchOptions"\t\t"{new_options}"', app_content)
                    else:
                        # Remove LaunchOptions line entirely
                        new_app_content = re.sub(r'\s*"LaunchOptions"\s*"[^"]*"\s*\n?', '', app_content)

                    # Replace the app section
                    new_apps_content = (apps_content[:app_content_start] +
                                      new_app_content +
                                      apps_content[app_end_pos:])
                else:
                    debug_print("No LaunchOptions found to remove")
                    return True
            else:
                debug_print(f"App {app_id} not found for removal")
                return True

        # Reconstruct the full content
        new_content = (content[:apps_content_start] +
                      new_apps_content +
                      content[apps_end_pos:])

        # Write back to file
        with open(config_file, 'w', encoding='utf-8') as f:
            f.write(new_content)

        debug_print(f"Successfully {action}ed launch options for app {app_id}")
        return True

    except Exception as e:
        debug_print(f"ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

# Main execution
config_file = "$config_file"
app_id = "$app_id"
launch_options = "$launch_options"
action = "$action"

success = modify_steam_config(config_file, app_id, launch_options, action)
sys.exit(0 if success else 1)
EOF

    local python_exit_code=$?

    if [ $python_exit_code -eq 0 ]; then
        echo "✓ Steam configuration updated successfully"

        # Verify the change was applied
        if grep -q "ENABLE_LSFG" "$config_file"; then
            echo "✓ LSFG options found in config file"
        else
            echo "⚠ Warning: LSFG options not found in config file after modification"
        fi

        return 0
    else
        echo "✗ Python script failed with exit code $python_exit_code"

        # Restore backup on failure
        if [ -f "$backup_file" ]; then
            echo "Restoring backup..."
            cp "$backup_file" "$config_file"
        fi

        return 1
    fi
}

# Function to verify launch options were applied
verify_launch_options() {
    local app_id="$1"
    local config_file
    config_file=$(get_steam_config_file)

    if [ -z "$config_file" ] || [ ! -f "$config_file" ]; then
        return 1
    fi

    # Use Python to extract launch options for the specific app
    python3 << EOF
import re

try:
    with open("$config_file", 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Find the app section
    app_pattern = rf'"{re.escape("$app_id")}"\s*\{{([^}}]*(?:\{{[^}}]*\}}[^}}]*)*)\}}'
    app_match = re.search(app_pattern, content, re.DOTALL)

    if app_match:
        app_content = app_match.group(1)
        launch_match = re.search(r'"LaunchOptions"\s*"([^"]*)"', app_content)

        if launch_match:
            print(f"Launch options found: {launch_match.group(1)}")
        else:
            print("No launch options found for this app")
    else:
        print("App not found in config")

except Exception as e:
    print(f"Error: {e}")
EOF
}

# Lossless Scaling functions
get_steam_games() {
    local games_list=()

    # Ensure Steam directories are found
    if ! find_steam_directories; then
        echo "ERROR: Could not find Steam directories"
        return 1
    fi

    local steam_user_id=$(get_steam_user_id)
    if [ -z "$steam_user_id" ]; then
        echo "ERROR: Could not find Steam user data"
        return 1
    fi

    # Parse Steam library folders from libraryfolders.vdf
    local library_file="$STEAM_CONFIG_DIR/libraryfolders.vdf"
    if [ -f "$library_file" ]; then
        # Extract library paths and scan for games
        local lib_paths
        lib_paths=$(grep -o '"path"[[:space:]]*"[^"]*"' "$library_file" 2>/dev/null | sed 's/"path"[[:space:]]*"//g' | sed 's/"$//g')

        while IFS= read -r lib_path; do
            [ -z "$lib_path" ] && continue
            local steamapps_dir="$lib_path/steamapps"
            if [ -d "$steamapps_dir" ]; then
                # Find .acf files which contain game information
                for acf_file in "$steamapps_dir"/*.acf; do
                    [ -f "$acf_file" ] || continue

                    local app_id=$(grep -o '"appid"[[:space:]]*"[^"]*"' "$acf_file" 2>/dev/null | sed 's/"appid"[[:space:]]*"//g' | sed 's/"$//g')
                    local game_name=$(grep -o '"name"[[:space:]]*"[^"]*"' "$acf_file" 2>/dev/null | sed 's/"name"[[:space:]]*"//g' | sed 's/"$//g')

                    if [ ! -z "$app_id" ] && [ ! -z "$game_name" ]; then
                        games_list+=("$app_id" "$game_name")
                    fi
                done
            fi
        done <<< "$lib_paths"
    fi

    # If no games found, provide some example entries
    if [ ${#games_list[@]} -eq 0 ]; then
        games_list=("000000" "No Steam games found - Check manually")
    fi

    printf '%s\n' "${games_list[@]}"
    return 0
}

manage_lossless_scaling() {
    # Check for Python3 first
    if ! check_python3; then
        return 1
    fi

    # Run comprehensive diagnosis
    echo "Running Steam accessibility diagnosis..."
    local diag_output=$(diagnose_steam_accessibility 2>&1)
    local diag_result=$?

    if [ $diag_result -ne 0 ]; then
        local error_msg="❌ Steam installation not detected or accessible\n\n"
        error_msg+="Possible solutions:\n"
        error_msg+="• Install Steam if not installed\n"
        error_msg+="• Run Steam at least once to create config files\n"
        error_msg+="• Ensure you're running as 'deck' user\n"
        error_msg+="• Check file permissions\n\n"
        error_msg+="Would you like to see detailed diagnosis?"

        if show_question "$error_msg"; then
            # Show detailed diagnosis
            zenity --text-info --title="Steam Diagnosis" --width=900 --height=700 --text="$diag_output" 2>/dev/null
        fi
        return 1
    fi

    # Try to get Steam config file
    local config_file
    config_file=$(get_steam_config_file 2>&1)
    local config_result=$?

    if [ $config_result -ne 0 ]; then
        local error_msg="❌ Steam configuration file not accessible\n\n"
        error_msg+="Error details:\n$config_file\n\n"
        error_msg+="Possible solutions:\n"
        error_msg+="• Close Steam completely and try again\n"
        error_msg+="• Run Steam once to generate config files\n"
        error_msg+="• Check file permissions in ~/.steam/\n"
        error_msg+="• Restart Steam Deck if issues persist\n\n"
        error_msg+="Would you like to try automatic config file creation?"

        if show_question "$error_msg"; then
            # Try to create config automatically
            (
                echo "10" ; echo "# Analyzing Steam installation..."
                sleep 1

                echo "30" ; echo "# Creating missing directories..."
                diagnose_steam_accessibility > /dev/null 2>&1

                echo "50" ; echo "# Attempting to create config file..."
                local new_config
                new_config=$(get_steam_config_file 2>&1)

                echo "80" ; echo "# Verifying configuration..."
                sleep 1

                if [ -f "$new_config" ]; then
                    echo "100" ; echo "# Configuration created successfully!"
                    sleep 1
                    exit 0
                else
                    echo "100" ; echo "# Failed to create configuration"
                    sleep 1
                    exit 1
                fi

            ) | zenity --progress --title="Creating Steam Configuration" --text="Preparing..." --percentage=0 --auto-close --width=420 --height=110 2>/dev/null

            if [ $? -eq 0 ]; then
                show_info "✅ Steam configuration created successfully!\n\nTrying again..."
                # Retry with new config
                config_file=$(get_steam_config_file 2>&1)
                config_result=$?
            fi
        fi

        if [ $config_result -ne 0 ]; then
            show_error "❌ Unable to access Steam configuration\n\nPlease:\n1. Close Steam completely\n2. Run Steam once\n3. Close Steam again\n4. Try this script again"
            return 1
        fi
    fi

    echo "Using Steam config: $config_file"

    # Continue with game detection
    local game_list
    game_list=$(get_steam_games)

    if [ $? -ne 0 ] || [ -z "$game_list" ]; then
        show_error "❌ Unable to detect Steam games\n\nPossible causes:\n• Steam not installed\n• No games in library\n• Permission issues\n\nYou can manually add launch options in Steam."
        return 1
    fi

    # Convert the list into zenity format
    local zenity_args=()
    local app_ids=()
    local game_names=()

    while IFS=$'\n' read -r line; do
        if [ ${#app_ids[@]} -eq ${#game_names[@]} ]; then
            app_ids+=("$line")
        else
            game_names+=("$line")
            zenity_args+=("${app_ids[-1]}" "${game_names[-1]}")
        fi
    done <<< "$game_list"

    local selected_game
    selected_game=$(zenity --list \
        --title="Lossless Scaling - Game Selection" \
        --text="Select a game to configure Lossless Scaling:\n\n🔧 Launch options will be automatically applied to Steam\n\nConfig file: $(basename "$config_file")" \
        --column="App ID" \
        --column="Game Name" \
        --width=700 \
        --height=400 \
        "${zenity_args[@]}" \
        2>/dev/null)

    if [ ! -z "$selected_game" ]; then
        configure_lossless_scaling_for_game "$selected_game"
    fi
}

configure_lossless_scaling_for_game() {
    local app_id="$1"
    local game_name=""

    # Find the game name for the selected app ID
    local game_list
    game_list=$(get_steam_games)
    local found_name=false

    while IFS=$'\n' read -r line; do
        if [ "$found_name" = true ]; then
            game_name="$line"
            break
        elif [ "$line" = "$app_id" ]; then
            found_name=true
        fi
    done <<< "$game_list"

    if [ -z "$game_name" ]; then
        game_name="Selected Game (ID: $app_id)"
    fi

    # Simplified configuration dialog - automatic by default
    local choice=$(zenity --list \
        --title="Lossless Scaling Configuration" \
        --text="Game: $game_name\nApp ID: $app_id\n\n🔧 All options will be automatically applied to Steam!" \
        --column="Action" \
        --column="Description" \
        --width=600 \
        --height=320 \
        "Enable (Auto)" "✅ Enable with recommended settings (2x, 0.5 flow)" \
        "Custom (Auto)" "⚙️ Configure custom settings and auto-apply" \
        "Disable (Auto)" "🚫 Remove all Lossless Scaling options" \
        "Manual Guide" "📖 Show manual setup instructions" \
        2>/dev/null)

    case "$choice" in
        "Enable (Auto)")
            enable_lossless_scaling_auto "$app_id" "$game_name"
            ;;
        "Custom (Auto)")
            configure_lossless_scaling_advanced_auto "$app_id" "$game_name"
            ;;
        "Disable (Auto)")
            disable_lossless_scaling_auto "$app_id" "$game_name"
            ;;
        "Manual Guide")
            show_manual_lossless_scaling_instructions
            ;;
    esac
}

enable_lossless_scaling_auto() {
    local app_id="$1"
    local game_name="$2"
    local lsfg_command="ENABLE_LSFG=1 LSFG_MULTIPLIER=2 LSFG_FLOW_SCALE=0.50 LSFG_PERF_MODE=1 %COMMAND%"

    echo "Starting enable_lossless_scaling_auto for $game_name (ID: $app_id)"

    # Handle Steam closure first
    if ! handle_steam_closure "$app_id" "$game_name"; then
        echo "Steam closure handling failed or was cancelled"
        return 1
    fi

    # Show progress dialog
    (
        echo "10" ; echo "# Preparing Steam configuration..."
        sleep 1

        echo "30" ; echo "# Backing up current settings..."
        sleep 1

        echo "50" ; echo "# Applying Lossless Scaling options..."

        # Try to automatically apply the settings
        if modify_steam_launch_options "$app_id" "$lsfg_command" "add"; then
            echo "80" ; echo "# Verifying changes..."
            sleep 1
            echo "100" ; echo "# Successfully applied settings!"
        else
            echo "100" ; echo "# Failed to apply settings"
            exit 1
        fi

    ) | zenity --progress --title="Applying Lossless Scaling" --text="Preparing..." --percentage=0 --auto-close --width=420 --height=110 2>/dev/null

    if [ $? -eq 0 ]; then
        # Verify the changes
        local verification=$(verify_launch_options "$app_id")

        show_info "✅ Lossless Scaling Enabled Successfully!\n\nGame: $game_name\nApp ID: $app_id\n\n🎯 Settings Applied:\n• 2x scaling multiplier\n• Flow scale: 0.50\n• Performance mode enabled\n\n🚀 You can now restart Steam and launch your game!\n\n💡 Verification:\n$verification"
    else
        show_error "❌ Failed to automatically configure Steam\n\nTrying manual fallback..."
        enable_lossless_scaling_manual "$app_id" "$game_name"
    fi
}

configure_lossless_scaling_advanced_auto() {
    local app_id="$1"
    local game_name="$2"

    echo "Starting configure_lossless_scaling_advanced_auto for $game_name (ID: $app_id)"

    # Handle Steam closure first
    if ! handle_steam_closure "$app_id" "$game_name"; then
        echo "Steam closure handling failed or was cancelled"
        return 1
    fi

    # Get multiplier
    local multiplier=$(zenity --list \
        --title="LSFG Multiplier" \
        --text="Choose scaling multiplier for $game_name:" \
        --column="Multiplier" \
        --column="Description" \
        --width=400 \
        --height=300 \
        "1" "No scaling (disabled)" \
        "2" "2x scaling (recommended)" \
        "3" "3x scaling" \
        "4" "4x scaling (high performance impact)" \
        2>/dev/null)

    if [ -z "$multiplier" ]; then
        echo "User cancelled multiplier selection"
        return
    fi

    echo "Selected multiplier: $multiplier"

    # Get flow scale with higher precision (2 decimals)
    local flow_scale_percent=$(zenity --scale \
        --title="LSFG Flow Scale (Precision Mode)" \
        --text="Adjust flow scale for motion smoothness\n(0.10 = very smooth, 1.00 = very responsive)\n\nPrecision: 2 decimal places" \
        --min-value=10 \
        --max-value=100 \
        --value=50 \
        --step=1 \
        2>/dev/null)

    if [ -z "$flow_scale_percent" ]; then
        echo "User cancelled flow scale selection"
        return
    fi

    # Convert to decimal with 2 decimal places precision
    local flow_scale=$(awk "BEGIN {printf \"%.2f\", $flow_scale_percent / 100}" 2>/dev/null || echo "0.50")
    echo "Selected flow scale: $flow_scale (from $flow_scale_percent%)"

    # Get performance mode
    local perf_mode="1"
    if ! zenity --question --text="Enable Performance Mode?\n\nPerformance mode reduces quality slightly for better framerates." --width=400 2>/dev/null; then
        perf_mode="0"
    fi

    echo "Selected performance mode: $perf_mode"

    local lsfg_command="ENABLE_LSFG=1 LSFG_MULTIPLIER=$multiplier LSFG_FLOW_SCALE=$flow_scale LSFG_PERF_MODE=$perf_mode %COMMAND%"
    echo "Final LSFG command: $lsfg_command"

    # Show progress dialog
    (
        echo "10" ; echo "# Preparing custom configuration..."
        sleep 1

        echo "30" ; echo "# Backing up current settings..."
        sleep 1

        echo "50" ; echo "# Applying custom Lossless Scaling options..."

        # Try to automatically apply the settings
        if modify_steam_launch_options "$app_id" "$lsfg_command" "add"; then
            echo "80" ; echo "# Verifying changes..."
            sleep 1
            echo "100" ; echo "# Successfully applied custom settings!"
        else
            echo "100" ; echo "# Failed to apply settings"
            exit 1
        fi

    ) | zenity --progress --title="Applying Custom Lossless Scaling" --text="Preparing..." --percentage=0 --auto-close --width=420 --height=110 2>/dev/null

    if [ $? -eq 0 ]; then
        # Verify the changes
        local verification=$(verify_launch_options "$app_id")

        show_info "✅ Custom Lossless Scaling Applied Successfully!\n\nGame: $game_name\n\n🎯 Settings Applied:\n• Multiplier: ${multiplier}x\n• Flow Scale: $flow_scale (2 decimal precision)\n• Performance Mode: $([ "$perf_mode" = "1" ] && echo "Enabled" || echo "Disabled")\n\n🚀 You can now restart Steam and launch your game!\n\n💡 Launch Options:\n$lsfg_command\n\n🔍 Verification:\n$verification"
    else
        show_error "❌ Failed to automatically configure Steam\n\nTrying manual fallback..."
        show_info "🎮 Add this to Launch Options manually:\n\n$lsfg_command\n\nSettings:\n• Multiplier: ${multiplier}x\n• Flow Scale: $flow_scale (2 decimal precision)\n• Performance Mode: $([ "$perf_mode" = "1" ] && echo "Enabled" || echo "Disabled")"

        # Try to copy to clipboard
        if command -v wl-copy &> /dev/null; then
            echo "$lsfg_command" | wl-copy 2>/dev/null && show_info "📋 Launch options copied to clipboard!"
        elif command -v xclip &> /dev/null; then
            echo "$lsfg_command" | xclip -selection clipboard 2>/dev/null && show_info "📋 Launch options copied to clipboard!"
        fi
    fi
}

disable_lossless_scaling_auto() {
    local app_id="$1"
    local game_name="$2"

    # Handle Steam closure first
    if ! handle_steam_closure "$app_id" "$game_name"; then
        echo "Steam closure handling failed or was cancelled"
        return 1
    fi

    # Show progress dialog
    (
        echo "10" ; echo "# Preparing to remove Lossless Scaling..."
        sleep 1

        echo "30" ; echo "# Backing up current settings..."
        sleep 1

        echo "50" ; echo "# Removing Lossless Scaling options..."

        # Try to automatically remove the settings
        if modify_steam_launch_options "$app_id" "" "remove"; then
            echo "80" ; echo "# Verifying changes..."
            sleep 1
            echo "100" ; echo "# Successfully removed settings!"
        else
            echo "100" ; echo "# Failed to remove settings"
            exit 1
        fi

    ) | zenity --progress --title="Removing Lossless Scaling" --text="Preparing..." --percentage=0 --auto-close --width=420 --height=110 2>/dev/null

    if [ $? -eq 0 ]; then
        show_info "✅ Lossless Scaling Disabled Successfully!\n\nGame: $game_name\nApp ID: $app_id\n\n🚀 You can now restart Steam and launch your game!\n\n✅ All LSFG launch options have been automatically removed from this game."
    else
        show_error "❌ Failed to automatically remove from Steam\n\nPlease remove LSFG options manually:\n\n1. Open Steam\n2. Right-click '$game_name'\n3. Select 'Properties'\n4. Remove LSFG options from Launch Options"
    fi
}

configure_lossless_scaling_advanced_auto() {
    local app_id="$1"
    local game_name="$2"

    echo "Starting configure_lossless_scaling_advanced_auto for $game_name (ID: $app_id)"

    # Get multiplier
    local multiplier=$(zenity --list \
        --title="LSFG Multiplier" \
        --text="Choose scaling multiplier for $game_name:" \
        --column="Multiplier" \
        --column="Description" \
        --width=400 \
        --height=300 \
        "1" "No scaling (disabled)" \
        "2" "2x scaling (recommended)" \
        "3" "3x scaling" \
        "4" "4x scaling (high performance impact)" \
        2>/dev/null)

    if [ -z "$multiplier" ]; then
        echo "User cancelled multiplier selection"
        return
    fi

    echo "Selected multiplier: $multiplier"

    # Get flow scale with higher precision (2 decimals)
    local flow_scale_percent=$(zenity --scale \
        --title="LSFG Flow Scale (Precision Mode)" \
        --text="Adjust flow scale for motion smoothness\n(0.10 = very smooth, 1.00 = very responsive)\n\nPrecision: 2 decimal places" \
        --min-value=10 \
        --max-value=100 \
        --value=50 \
        --step=1 \
        2>/dev/null)

    if [ -z "$flow_scale_percent" ]; then
        echo "User cancelled flow scale selection"
        return
    fi

    # Convert to decimal with 2 decimal places precision
    local flow_scale=$(awk "BEGIN {printf \"%.2f\", $flow_scale_percent / 100}" 2>/dev/null || echo "0.50")
    echo "Selected flow scale: $flow_scale (from $flow_scale_percent%)"

    # Get performance mode
    local perf_mode="1"
    if ! zenity --question --text="Enable Performance Mode?\n\nPerformance mode reduces quality slightly for better framerates." --width=400 2>/dev/null; then
        perf_mode="0"
    fi

    echo "Selected performance mode: $perf_mode"

    local lsfg_command="ENABLE_LSFG=1 LSFG_MULTIPLIER=$multiplier LSFG_FLOW_SCALE=$flow_scale LSFG_PERF_MODE=$perf_mode %COMMAND%"
    echo "Final LSFG command: $lsfg_command"

    # Show progress dialog
    (
        echo "10" ; echo "# Preparing custom configuration..."
        sleep 1

        echo "30" ; echo "# Backing up current settings..."
        sleep 1

        echo "50" ; echo "# Applying custom Lossless Scaling options..."

        # Try to automatically apply the settings
        if modify_steam_launch_options "$app_id" "$lsfg_command" "add"; then
            echo "80" ; echo "# Verifying changes..."
            sleep 1
            echo "100" ; echo "# Successfully applied custom settings!"
        else
            echo "100" ; echo "# Failed to apply settings"
            exit 1
        fi

    ) | zenity --progress --title="Applying Custom Lossless Scaling" --text="Preparing..." --percentage=0 --auto-close --width=420 --height=110 2>/dev/null

    if [ $? -eq 0 ]; then
        # Verify the changes
        local verification=$(verify_launch_options "$app_id")

        show_info "✅ Custom Lossless Scaling Applied Successfully!\n\nGame: $game_name\n\n🎯 Settings Applied:\n• Multiplier: ${multiplier}x\n• Flow Scale: $flow_scale (2 decimal precision)\n• Performance Mode: $([ "$perf_mode" = "1" ] && echo "Enabled" || echo "Disabled")\n\n🔄 Please restart Steam for changes to take effect.\n\n💡 Launch Options:\n$lsfg_command\n\n🔍 Verification:\n$verification"
    else
        show_error "❌ Failed to automatically configure Steam\n\nTrying manual fallback..."
        show_info "🎮 Add this to Launch Options manually:\n\n$lsfg_command\n\nSettings:\n• Multiplier: ${multiplier}x\n• Flow Scale: $flow_scale (2 decimal precision)\n• Performance Mode: $([ "$perf_mode" = "1" ] && echo "Enabled" || echo "Disabled")"

        # Try to copy to clipboard
        if command -v wl-copy &> /dev/null; then
            echo "$lsfg_command" | wl-copy 2>/dev/null && show_info "📋 Launch options copied to clipboard!"
        elif command -v xclip &> /dev/null; then
            echo "$lsfg_command" | xclip -selection clipboard 2>/dev/null && show_info "📋 Launch options copied to clipboard!"
        fi
    fi
}

disable_lossless_scaling_auto() {
    local app_id="$1"
    local game_name="$2"

    # Show progress dialog
    (
        echo "10" ; echo "# Preparing to remove Lossless Scaling..."
        sleep 1

        echo "30" ; echo "# Backing up current settings..."
        sleep 1

        echo "50" ; echo "# Removing Lossless Scaling options..."

        # Try to automatically remove the settings
        local result_output
        result_output=$(modify_steam_launch_options "$app_id" "" "remove" 2>&1)
        local result_code=$?

        echo "80" ; echo "# Verifying changes..."
        sleep 1

        if [ $result_code -eq 0 ]; then
            echo "100" ; echo "# Successfully removed settings!"
        else
            echo "100" ; echo "# Failed to remove settings"
            exit 1
        fi

    ) | zenity --progress --title="Removing Lossless Scaling" --text="Preparing..." --percentage=0 --auto-close --width=420 --height=110 2>/dev/null

    if [ $? -eq 0 ]; then
        show_info "✅ Lossless Scaling Disabled Successfully!\n\nGame: $game_name\nApp ID: $app_id\n\n🔄 Please restart Steam for changes to take effect.\n\n✅ All LSFG launch options have been automatically removed from this game."
    else
        show_error "❌ Failed to automatically remove from Steam\n\nPlease remove LSFG options manually:\n\n1. Open Steam\n2. Right-click '$game_name'\n3. Select 'Properties'\n4. Remove LSFG options from Launch Options"
    fi
}

disable_lossless_scaling_auto() {
    local app_id="$1"
    local game_name="$2"

    # Try to automatically remove the settings
    if modify_steam_launch_options "$app_id" "" "remove"; then
        show_info "✅ Lossless Scaling Disabled Successfully!\n\nGame: $game_name\n\n🔄 Please restart Steam for changes to take effect."
    else
        show_error "❌ Failed to automatically configure Steam\n\nPlease remove LSFG options manually from Steam launch options."
    fi
}

enable_lossless_scaling_manual() {
    local app_id="$1"
    local game_name="$2"
    local lsfg_command="ENABLE_LSFG=1 LSFG_MULTIPLIER=2 LSFG_FLOW_SCALE=0.5 LSFG_PERF_MODE=1 %COMMAND%"

    show_info "🎮 Manual Lossless Scaling Setup\n\nGame: $game_name\n\n📋 Steps:\n1. Open Steam\n2. Right-click '$game_name'\n3. Select 'Properties'\n4. Add to Launch Options:\n\n$lsfg_command"

    # Try to copy to clipboard if available
    if command -v wl-copy &> /dev/null; then
        echo "$lsfg_command" | wl-copy 2>/dev/null && show_info "📋 Copied to clipboard!"
    elif command -v xclip &> /dev/null; then
        echo "$lsfg_command" | xclip -selection clipboard 2>/dev/null && show_info "📋 Copied to clipboard!"
    fi
}

show_manual_lossless_scaling_instructions() {
    zenity --text-info \
        --title="Lossless Scaling Instructions" \
        --width=700 \
        --height=500 \
        --text="🎮 Lossless Scaling Setup Guide

📋 BASIC SETUP:
1. Open Steam
2. Right-click on any game
3. Select 'Properties'
4. In 'Launch Options' field, add:
   ENABLE_LSFG=1 LSFG_MULTIPLIER=2 LSFG_FLOW_SCALE=0.50 LSFG_PERF_MODE=1 %COMMAND%

🔧 PARAMETERS:

ENABLE_LSFG=1
   • Enables Lossless Scaling Frame Generation

LSFG_MULTIPLIER=X
   • Scaling multiplier (1, 2, 3, or 4)
   • 2 = recommended for most games

LSFG_FLOW_SCALE=X.XX
   • Motion smoothness (0.10 to 1.00) - 2 decimal precision
   • 0.50 = balanced
   • Lower values = smoother motion
   • Higher values = more responsive

LSFG_PERF_MODE=X
   • Performance optimization
   • 1 = enabled (recommended)

📝 EXAMPLE CONFIGURATIONS:

Ultra Smooth (best for high motion games):
ENABLE_LSFG=1 LSFG_MULTIPLIER=2 LSFG_FLOW_SCALE=0.25 LSFG_PERF_MODE=1 %COMMAND%

Balanced (recommended):
ENABLE_LSFG=1 LSFG_MULTIPLIER=2 LSFG_FLOW_SCALE=0.50 LSFG_PERF_MODE=1 %COMMAND%

Responsive (best for competitive games):
ENABLE_LSFG=1 LSFG_MULTIPLIER=2 LSFG_FLOW_SCALE=0.80 LSFG_PERF_MODE=1 %COMMAND%

⚠️  NOTES:
- Lossless Scaling must be installed separately
- Not all games are compatible
- Test settings per game for best results
- Use 2 decimal precision for optimal tuning" \
        2>/dev/null
}

# Main menu
show_main_menu() {
    check_installation
    local install_status=$?

    if [ $install_status -eq 0 ]; then
        if show_question "🚀 VkBasalt Manager - First Use\n\nSystem detected: Steam Deck\n\nVkBasalt is not yet installed on your system.\n\nWould you like to proceed with automatic installation?"; then
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
        local choice=$(zenity --list --title="VkBasalt Manager - Configuration" --text="VkBasalt is installed and ready!" --column="Option" --column="Description" --width=420 --height=400 \
    "Shaders" "Manage active shaders" \
    "Toggle Key" "Change toggle key" \
    "Advanced" "Advanced shader settings" \
    "Lossless Scaling" "Configure Lossless Scaling" \
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
            "Lossless Scaling") manage_lossless_scaling ;;
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
    check_dependencies
    show_main_menu
}

main
