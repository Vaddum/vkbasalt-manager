#!/bin/bash

# VkBasalt Manager for Steam Deck
# Complete installation and configuration tool

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration paths
CONFIG_FILE="/home/deck/.config/vkBasalt/vkBasalt.conf"
BACKUP_FILE="/home/deck/.config/vkBasalt/vkBasalt.conf.backup"
SHADER_PATH="/home/deck/.config/reshade/Shaders"

# Display header
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                          ║${NC}"
    echo -e "${CYAN}║          ${YELLOW}VkBasalt Manager for Steam Deck${CYAN}                 ║${NC}"
    echo -e "${CYAN}║                    ${PURPLE}Version 1.0${CYAN}                           ║${NC}"
    echo -e "${CYAN}║                                                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Main menu
show_main_menu() {
    echo -e "${BLUE}Main Menu:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Install VkBasalt & Shaders"
    echo -e "  ${GREEN}2)${NC} Configure VkBasalt"
    echo -e "  ${GREEN}3)${NC} Usage Information"
    echo -e "  ${GREEN}4)${NC} Check Installation Status"
    echo -e "  ${RED}5)${NC} Uninstall Everything"
    echo -e "  ${CYAN}0)${NC} Exit"
    echo ""
    echo -e -n "${YELLOW}Your choice [0-5]: ${NC}"
}

# Check installation status
check_status() {
    echo -e "${BLUE}Installation Status:${NC}"
    echo ""
    
    # Check VkBasalt
    if [ -f "/home/deck/.local/lib/libvkbasalt.so" ] && [ -f "/home/deck/.local/lib32/libvkbasalt.so" ]; then
        echo -e "  ${GREEN}✓${NC} VkBasalt: ${GREEN}Installed${NC}"
    else
        echo -e "  ${RED}✗${NC} VkBasalt: ${RED}Not installed${NC}"
    fi
    
    # Check configuration
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "  ${GREEN}✓${NC} Configuration: ${GREEN}Found${NC}"
    else
        echo -e "  ${YELLOW}⚠${NC} Configuration: ${YELLOW}Missing${NC}"
    fi
    
    # Check shaders
    if [ -d "$SHADER_PATH" ] && [ "$(ls -A $SHADER_PATH 2>/dev/null)" ]; then
        shader_count=$(ls -1 $SHADER_PATH/*.fx 2>/dev/null | wc -l)
        echo -e "  ${GREEN}✓${NC} Shaders: ${GREEN}$shader_count shaders installed${NC}"
    else
        echo -e "  ${RED}✗${NC} Shaders: ${RED}Not installed${NC}"
    fi
    
    echo ""
}

# Installation function
install_vkbasalt() {
    echo -e "${BLUE}🚀 Starting complete installation...${NC}"
    echo ""
    
    # Install VkBasalt
    echo -e "${BLUE}📦 Installing VkBasalt...${NC}"
    if wget -q https://github.com/simons-public/steam-deck-vkbasalt-install/raw/main/vkbasalt_install.sh; then
        echo -e "${GREEN}✓ Download successful${NC}"
        if bash vkbasalt_install.sh; then
            echo -e "${GREEN}✓ VkBasalt installed successfully!${NC}"
            rm -f vkbasalt_install.sh
        else
            echo -e "${RED}✗ Error installing VkBasalt${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Error downloading VkBasalt installer${NC}"
        return 1
    fi
    
    echo ""
    
    # Install shaders
    echo -e "${BLUE}🎨 Installing shaders...${NC}"
    if wget -q https://github.com/Vaddum/vkbasalt-manager/archive/refs/heads/main.zip; then
        echo -e "${GREEN}✓ Download successful${NC}"
        if unzip -q main.zip; then
            echo -e "${GREEN}✓ Extraction successful${NC}"
            if cp -r vkbasalt-shaders-main/* /home/deck/.config/; then
                echo -e "${GREEN}✓ Shaders installed successfully!${NC}"
                rm -rf main.zip vkbasalt-shaders-main
            else
                echo -e "${RED}✗ Error copying shaders${NC}"
                return 1
            fi
        else
            echo -e "${RED}✗ Error extracting files${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Error downloading shaders${NC}"
        return 1
    fi
    
    # Create default configuration
    create_default_config
    
    echo ""
    echo -e "${GREEN}🎉 Installation complete!${NC}"
}

# Create default configuration
create_default_config() {
    mkdir -p $(dirname "$CONFIG_FILE")
    cat > "$CONFIG_FILE" << EOF
# VkBasalt Configuration
effects = cas:smaa
casSharpness = 0.4
reshadeTexturePath = "$TEXTURE_PATH"
reshadeIncludePath = "$SHADER_PATH"
toggleKey = Home
enableOnLaunch = True

# Shader paths
clarity = $SHADER_PATH/Clarity.fx
dpx = $SHADER_PATH/DPX.fx
lumasharpen = $SHADER_PATH/LumaSharpen.fx
vibrance = $SHADER_PATH/Vibrance.fx
EOF
}

# Configuration menu
show_config_menu() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ VkBasalt is not installed or configuration is missing.${NC}"
        echo -e "${YELLOW}Please install VkBasalt first.${NC}"
        pause
        return
    fi
    
    echo -e "${BLUE}Configuration Menu:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Apply preset configuration"
    echo -e "  ${GREEN}2)${NC} Manage shaders"
    echo -e "  ${GREEN}3)${NC} Advanced settings"
    echo -e "  ${GREEN}4)${NC} View current configuration"
    echo -e "  ${GREEN}5)${NC} Backup management"
    echo -e "  ${GREEN}6)${NC} Reset to defaults"
    echo -e "  ${RED}0)${NC} Back to main menu"
    echo ""
    echo -e -n "${YELLOW}Your choice [0-6]: ${NC}"
}

# Preset configurations menu
show_preset_menu() {
    clear
    show_header
    echo -e "${BLUE}Preset Configurations:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Performance (light effects)"
    echo -e "  ${GREEN}2)${NC} Quality (enhanced visuals)"
    echo -e "  ${GREEN}3)${NC} Cinematic (film look)"
    echo -e "  ${GREEN}4)${NC} Minimal (sharpness only)"
    echo -e "  ${GREEN}5)${NC} Complete (all effects)"
    echo -e "  ${RED}0)${NC} Back"
    echo ""
    echo -e -n "${YELLOW}Your choice [0-5]: ${NC}"
}

# Apply preset configuration
apply_preset() {
    local preset=$1
    create_backup
    
    case $preset in
        1) # Performance
            cat > "$CONFIG_FILE" << EOF
# Performance Configuration - Light effects
effects = cas:smaa:fxaa
casSharpness = 0.4
reshadeTexturePath = "$TEXTURE_PATH"
reshadeIncludePath = "$SHADER_PATH"
toggleKey = Home
enableOnLaunch = True
clarity = $SHADER_PATH/Clarity.fx
dpx = $SHADER_PATH/DPX.fx
lumasharpen = $SHADER_PATH/LumaSharpen.fx
vibrance = $SHADER_PATH/Vibrance.fx
EOF
            echo -e "${GREEN}✓ Performance configuration applied${NC}"
            ;;
        2) # Quality
            cat > "$CONFIG_FILE" << EOF
# Quality Configuration - Enhanced visuals
effects = cas:smaa:lumasharpen:vibrance
casSharpness = 0.6
lumaSharpenStrength = 0.65
lumaSharpenClamp = 0.035
vibranceStrength = 0.15
reshadeTexturePath = "$TEXTURE_PATH"
reshadeIncludePath = "$SHADER_PATH"
toggleKey = Home
enableOnLaunch = True
clarity = $SHADER_PATH/Clarity.fx
dpx = $SHADER_PATH/DPX.fx
lumasharpen = $SHADER_PATH/LumaSharpen.fx
vibrance = $SHADER_PATH/Vibrance.fx
vignette = $SHADER_PATH/Vignette.fx
EOF
            echo -e "${GREEN}✓ Quality configuration applied${NC}"
            ;;
        3) # Cinematic
            cat > "$CONFIG_FILE" << EOF
# Cinematic Configuration - Film look
effects = dpx:vibrance
dpxSaturation = 3.0
dpxColorGamma = 2.5
dpxContrast = 0.1
vibranceStrength = 0.20
reshadeTexturePath = "$TEXTURE_PATH"
reshadeIncludePath = "$SHADER_PATH"
toggleKey = Home
enableOnLaunch = True
clarity = $SHADER_PATH/Clarity.fx
dpx = $SHADER_PATH/DPX.fx
lumasharpen = $SHADER_PATH/LumaSharpen.fx
vibrance = $SHADER_PATH/Vibrance.fx
EOF
            echo -e "${GREEN}✓ Cinematic configuration applied${NC}"
            ;;
        4) # Minimal
            cat > "$CONFIG_FILE" << EOF
# Minimal Configuration - Sharpness only
effects = cas
casSharpness = 0.5
reshadeTexturePath = "$TEXTURE_PATH"
reshadeIncludePath = "$SHADER_PATH"
toggleKey = Home
enableOnLaunch = True
clarity = $SHADER_PATH/Clarity.fx
dpx = $SHADER_PATH/DPX.fx
lumasharpen = $SHADER_PATH/LumaSharpen.fx
vibrance = $SHADER_PATH/Vibrance.fx
vignette = $SHADER_PATH/Vignette.fx
EOF
            echo -e "${GREEN}✓ Minimal configuration applied${NC}"
            ;;
        5) # Complete
            cat > "$CONFIG_FILE" << EOF
# Complete Configuration - All effects
effects = cas:smaa:lumasharpen:dpx:vibrance:clarity
casSharpness = 0.5
lumaSharpenStrength = 0.60
lumaSharpenClamp = 0.030
dpxSaturation = 3.0
dpxContrast = 0.1
vibranceStrength = 0.15
clarityRadius = 3
clarityOffset = 2.0
clarityStrength = 0.4
reshadeTexturePath = "$TEXTURE_PATH"
reshadeIncludePath = "$SHADER_PATH"
toggleKey = Home
enableOnLaunch = True
clarity = $SHADER_PATH/Clarity.fx
dpx = $SHADER_PATH/DPX.fx
lumasharpen = $SHADER_PATH/LumaSharpen.fx
vibrance = $SHADER_PATH/Vibrance.fx
vignette = $SHADER_PATH/Vignette.fx
EOF
            echo -e "${GREEN}✓ Complete configuration applied${NC}"
            ;;
    esac
}

# Manage shaders
manage_shaders() {
    clear
    show_header
    echo -e "${BLUE}Shader Management:${NC}"
    echo ""
    
    # Show current effects
    if [ -f "$CONFIG_FILE" ]; then
        current_effects=$(grep "^effects" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')
        echo -e "${CYAN}Currently active shaders:${NC} ${GREEN}${current_effects}${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Available shaders:${NC}"
    echo -e "  ${YELLOW}cas${NC} - Contrast Adaptive Sharpening"
    echo -e "  ${YELLOW}smaa${NC} - Enhanced Anti-Aliasing"
    echo -e "  ${YELLOW}fxaa${NC} - Fast Approximate Anti-Aliasing"
    echo -e "  ${YELLOW}lumasharpen${NC} - Luminance-based Sharpening"
    echo -e "  ${YELLOW}vibrance${NC} - Color Vibrance Enhancement"
    echo -e "  ${YELLOW}dpx${NC} - Digital Picture Exchange"
    echo -e "  ${YELLOW}clarity${NC} - Image Clarity Enhancement"
    echo ""
    echo -e "${PURPLE}Enter shaders to activate separated by colons:${NC}"
    echo -e "${PURPLE}Example: cas:smaa:vibrance${NC}"
    echo -e -n "${YELLOW}Shaders: ${NC}"
    read new_effects
    
    if [ ! -z "$new_effects" ]; then
        create_backup
        sed -i "s/^effects.*/effects = $new_effects/" "$CONFIG_FILE"
        echo -e "${GREEN}✓ Shaders updated: $new_effects${NC}"
    fi
}

# Advanced settings menu
show_advanced_menu() {
    echo -e "${BLUE}Advanced Settings:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Change toggle key (default: Home)"
    echo -e "  ${GREEN}2)${NC} CAS Sharpness adjustment"
    echo -e "  ${GREEN}3)${NC} Vibrance settings"
    echo -e "  ${GREEN}4)${NC} LumaSharpen settings"
    echo -e "  ${GREEN}5)${NC} DPX settings"
    echo -e "  ${GREEN}6)${NC} Clarity settings"
    echo -e "  ${RED}0)${NC} Back"
    echo ""
    echo -e -n "${YELLOW}Your choice [0-6]: ${NC}"
}

# Change toggle key
change_toggle_key() {
    echo ""
    echo -e "${BLUE}Available keys:${NC}"
    echo -e "  Home, End, Insert, Delete, F1-F12, etc."
    echo -e -n "${YELLOW}New toggle key: ${NC}"
    read new_key
    
    if [ ! -z "$new_key" ]; then
        create_backup
        sed -i "s/^toggleKey.*/toggleKey = $new_key/" "$CONFIG_FILE"
        echo -e "${GREEN}✓ Toggle key changed to: $new_key${NC}"
    fi
}

# Adjust CAS sharpness
adjust_cas() {
    echo ""
    echo -e "${BLUE}CAS Sharpness intensity (0.0 - 1.0):${NC}"
    echo -e "  0.3 = Light | 0.5 = Moderate | 0.7 = Strong"
    echo -e -n "${YELLOW}Value (default 0.5): ${NC}"
    read sharpness
    
    if [ ! -z "$sharpness" ]; then
        create_backup
        if grep -q "^casSharpness" "$CONFIG_FILE"; then
            sed -i "s/^casSharpness.*/casSharpness = $sharpness/" "$CONFIG_FILE"
        else
            echo "casSharpness = $sharpness" >> "$CONFIG_FILE"
        fi
        echo -e "${GREEN}✓ CAS sharpness adjusted to: $sharpness${NC}"
    fi
}

# Show current configuration
show_current_config() {
    clear
    show_header
    echo -e "${BLUE}Current Configuration:${NC}"
    echo ""
    
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${CYAN}Contents of vkBasalt.conf:${NC}"
        echo -e "${YELLOW}────────────────────────────────────────${NC}"
        cat "$CONFIG_FILE"
        echo -e "${YELLOW}────────────────────────────────────────${NC}"
    else
        echo -e "${RED}❌ Configuration file not found${NC}"
    fi
}

# Backup management menu
show_backup_menu() {
    echo -e "${BLUE}Backup Management:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Create backup"
    echo -e "  ${GREEN}2)${NC} Restore from backup"
    echo -e "  ${GREEN}3)${NC} Delete backup"
    echo -e "  ${RED}0)${NC} Back"
    echo ""
    echo -e -n "${YELLOW}Your choice [0-3]: ${NC}"
}

# Create backup
create_backup() {
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        echo -e "${GREEN}✓ Backup created${NC}"
    fi
}

# Restore backup
restore_backup() {
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$CONFIG_FILE"
        echo -e "${GREEN}✓ Configuration restored from backup${NC}"
    else
        echo -e "${RED}❌ No backup found${NC}"
    fi
}

# Delete backup
delete_backup() {
    if [ -f "$BACKUP_FILE" ]; then
        rm "$BACKUP_FILE"
        echo -e "${GREEN}✓ Backup deleted${NC}"
    else
        echo -e "${RED}❌ No backup found${NC}"
    fi
}

# Usage information
show_usage() {
    clear
    show_header
    echo -e "${BLUE}How to Use VkBasalt:${NC}"
    echo ""
    echo -e "${CYAN}═══ Game Configuration ═══${NC}"
    echo -e "${YELLOW}1.${NC} Open Steam in Desktop Mode"
    echo -e "${YELLOW}2.${NC} Right-click your game → Properties"
    echo -e "${YELLOW}3.${NC} In launch options, add:"
    echo -e "   ${GREEN}ENABLE_VKBASALT=1 %command%${NC}"
    echo ""
    echo -e "${CYAN}═══ File Locations ═══${NC}"
    echo -e "Configuration: ${GREEN}$CONFIG_FILE${NC}"
    echo -e "Shaders:       ${GREEN}$SHADER_PATH${NC}"
    echo -e "Textures:      ${GREEN}$TEXTURE_PATH${NC}"
    echo ""
    echo -e "${CYAN}═══ Toggle Controls ═══${NC}"
    echo -e "Toggle effects: ${GREEN}Home key${NC} (default, configurable)"
    echo ""
    echo -e "${YELLOW}⚠️  Note: VkBasalt only works with Vulkan games${NC}"
}

# Uninstall function
uninstall_all() {
    echo -e "${RED}🗑️  Uninstall VkBasalt and Shaders${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  This will remove all VkBasalt components and shaders${NC}"
    echo -e -n "${RED}Are you sure you want to continue? [y/N]: ${NC}"
    read confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Uninstall cancelled.${NC}"
        return 0
    fi
    
    echo ""
    echo -e "${BLUE}Removing files...${NC}"
    
    # Remove all files and directories
    [ -d "/home/deck/.config/vkBasalt" ] && rm -rf /home/deck/.config/vkBasalt && echo -e "${GREEN}✓ Configuration removed${NC}"
    [ -d "/home/deck/.config/reshade" ] && rm -rf /home/deck/.config/reshade && echo -e "${GREEN}✓ Shaders removed${NC}"
    [ -f "/home/deck/.local/lib/libvkbasalt.so" ] && rm -f /home/deck/.local/lib/libvkbasalt.so && echo -e "${GREEN}✓ 64-bit library removed${NC}"
    [ -f "/home/deck/.local/lib32/libvkbasalt.so" ] && rm -f /home/deck/.local/lib32/libvkbasalt.so && echo -e "${GREEN}✓ 32-bit library removed${NC}"
    [ -f "/home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.json" ] && rm -f /home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.json && echo -e "${GREEN}✓ 64-bit Vulkan layer removed${NC}"
    [ -f "/home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json" ] && rm -f /home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json && echo -e "${GREEN}✓ 32-bit Vulkan layer removed${NC}"
    
    # Clean empty directories
    rmdir /home/deck/.local/share/vulkan/implicit_layer.d 2>/dev/null || true
    rmdir /home/deck/.local/share/vulkan 2>/dev/null || true
    rmdir /home/deck/.local/lib32 2>/dev/null || true
    
    echo ""
    echo -e "${GREEN}🎉 Uninstall complete!${NC}"
    echo -e "${BLUE}ℹ️  Remember to remove ${YELLOW}ENABLE_VKBASALT=1${BLUE} from your game launch options${NC}"
}

# Pause function
pause() {
    echo ""
    echo -e -n "${CYAN}Press Enter to continue...${NC}"
    read
}

# Configuration submenu handler
handle_config_menu() {
    while true; do
        clear
        show_header
        show_config_menu
        read choice
        
        case $choice in
            1)
                while true; do
                    show_preset_menu
                    read preset_choice
                    case $preset_choice in
                        1|2|3|4|5)
                            apply_preset $preset_choice
                            pause
                            break
                            ;;
                        0) break ;;
                        *) 
                            echo -e "${RED}❌ Invalid choice${NC}"
                            pause
                            ;;
                    esac
                done
                ;;
            2)
                manage_shaders
                pause
                ;;
            3)
                while true; do
                    clear
                    show_header
                    show_advanced_menu
                    read adv_choice
                    
                    case $adv_choice in
                        1) change_toggle_key; pause ;;
                        2) adjust_cas; pause ;;
                        3) echo -e "${YELLOW}Feature coming soon...${NC}"; pause ;;
                        4) echo -e "${YELLOW}Feature coming soon...${NC}"; pause ;;
                        5) echo -e "${YELLOW}Feature coming soon...${NC}"; pause ;;
                        6) echo -e "${YELLOW}Feature coming soon...${NC}"; pause ;;
                        0) break ;;
                        *) echo -e "${RED}❌ Invalid choice${NC}"; pause ;;
                    esac
                done
                ;;
            4)
                show_current_config
                pause
                ;;
            5)
                while true; do
                    clear
                    show_header
                    show_backup_menu
                    read backup_choice
                    
                    case $backup_choice in
                        1) create_backup; pause ;;
                        2) restore_backup; pause ;;
                        3) delete_backup; pause ;;
                        0) break ;;
                        *) echo -e "${RED}❌ Invalid choice${NC}"; pause ;;
                    esac
                done
                ;;
            6)
                echo -e "${YELLOW}⚠️  This will reset to default configuration${NC}"
                echo -e -n "${RED}Continue? [y/N]: ${NC}"
                read confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    create_backup
                    create_default_config
                    echo -e "${GREEN}✓ Configuration reset to defaults${NC}"
                fi
                pause
                ;;
            0) return ;;
            *)
                echo -e "${RED}❌ Invalid choice${NC}"
                pause
                ;;
        esac
    done
}

# Main program loop
main() {
    while true; do
        show_header
        check_status
        show_main_menu
        read choice
        
        case $choice in
            1)
                clear
                show_header
                install_vkbasalt
                pause
                ;;
            2)
                handle_config_menu
                ;;
            3)
                show_usage
                pause
                ;;
            4)
                clear
                show_header
                check_status
                pause
                ;;
            5)
                clear
                show_header
                uninstall_all
                pause
                ;;
            0)
                clear
                echo -e "${GREEN}Thank you for using VkBasalt Manager! 👋${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid choice. Please choose between 0 and 5.${NC}"
                pause
                ;;
        esac
    done
}

# Start the program
main
