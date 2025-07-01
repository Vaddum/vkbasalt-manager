#!/bin/bash

# VkBasalt Manager for Steam Deck
# Complete installation and configuration tool

set -u  # Treat unset variables as errors

# Trap SIGINT (Ctrl+C)
trap 'echo -e "\n\033[0;31mAborted by user\033[0m"; exit 1' INT

# Check for required commands
for cmd in wget unzip grep sed cp rm mv ls cat clear tr cut rmdir; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Missing required command: $cmd"; exit 1; }
done

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
TEXTURE_PATH="/home/deck/.config/reshade/Textures"

# Display header
show_header() {
    command -v clear >/dev/null 2>&1 && clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                          ║${NC}"
    echo -e "${CYAN}║          ${YELLOW}VkBasalt Manager for Steam Deck${CYAN}                 ║${NC}"
    echo -e "${CYAN}║                    ${PURPLE}Version 1.1${CYAN}                           ║${NC}"
    echo -e "${CYAN}║                                                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_main_menu() {
    echo -e "${BLUE}Main Menu:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Install VkBasalt (with 4 shaders)"
    echo -e "  ${GREEN}2)${NC} Configure VkBasalt"
    echo -e "  ${GREEN}3)${NC} Usage Information"
    echo -e "  ${GREEN}4)${NC} Check Installation Status"
    echo -e "  ${RED}5)${NC} Uninstall Everything"
    echo -e "  ${CYAN}0)${NC} Exit"
    echo ""
    echo -e -n "${YELLOW}Your choice [0-5]: ${NC}"
}

check_status() {
    echo -e "${BLUE}Installation Status:${NC}"
    echo ""
    if [ -f "/home/deck/.local/lib/libvkbasalt.so" ] && [ -f "/home/deck/.local/lib32/libvkbasalt.so" ]; then
        echo -e "  ${GREEN}✓${NC} VkBasalt: ${GREEN}Installed${NC}"
    else
        echo -e "  ${RED}✗${NC} VkBasalt: ${RED}Not installed${NC}"
    fi
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "  ${GREEN}✓${NC} Configuration: ${GREEN}Found${NC}"
    else
        echo -e "  ${YELLOW}⚠${NC} Configuration: ${YELLOW}Missing${NC}"
    fi
    if [ -d "$SHADER_PATH" ] && [ "$(ls -A "$SHADER_PATH" 2>/dev/null)" ]; then
        shader_count=$(ls -1 "$SHADER_PATH"/*.fx 2>/dev/null | wc -l)
        echo -e "  ${GREEN}✓${NC} Shaders: ${GREEN}${shader_count} shaders installed${NC}"
    else
        echo -e "  ${RED}✗${NC} Shaders: ${RED}Not installed${NC}"
    fi
    echo ""
}

install_vkbasalt() {
    echo -e "${BLUE}🚀 Starting complete installation...${NC}"
    echo ""
    echo -e "${BLUE}📦 Installing VkBasalt...${NC}"
    if wget -q https://github.com/simons-public/steam-deck-vkbasalt-install/raw/main/vkbasalt_install.sh; then
        echo -e "${GREEN}✓ Download successful${NC}"
        if bash vkbasalt_install.sh; then
            echo -e "${GREEN}✓ VkBasalt installed successfully!${NC}"
            rm -f vkbasalt_install.sh
        else
            echo -e "${RED}✗ Error installing VkBasalt${NC}"
            rm -f vkbasalt_install.sh
            return 1
        fi
    else
        echo -e "${RED}✗ Error downloading VkBasalt installer${NC}"
        return 1
    fi
    echo ""
    echo -e "${BLUE}🎨 Installing shaders...${NC}"
    if wget -q https://github.com/Vaddum/vkbasalt-manager/archive/refs/heads/main.zip; then
        echo -e "${GREEN}✓ Download successful${NC}"
        if unzip -q main.zip; then
            echo -e "${GREEN}✓ Extraction successful${NC}"
            if cp -rf vkbasalt-manager-main/. /home/deck/.config/; then
                echo -e "${GREEN}✓ Shaders installed successfully!${NC}"
                rm -rf main.zip vkbasalt-manager-main
            else
                echo -e "${RED}✗ Error copying shaders${NC}"
                rm -rf main.zip vkbasalt-manager-main
                return 1
            fi
        else
            echo -e "${RED}✗ Error extracting files${NC}"
            rm -f main.zip
            return 1
        fi
    else
        echo -e "${RED}✗ Error downloading shaders${NC}"
        return 1
    fi
    create_default_config
    echo ""
    echo -e "${GREEN}🎉 Installation complete!${NC}"
}

create_default_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# VkBasalt Configuration

effects = cas

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
}

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

show_preset_menu() {
    command -v clear >/dev/null 2>&1 && clear
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

apply_preset() {
    local preset=$1
    create_backup
    case $preset in
        1)
            cat > "$CONFIG_FILE" << EOF
# Performance Configuration - Light effects

effects = cas:fxaa:smaa

casSharpness = 0.4
fxaaQualitySubpix = 0.75
fxaaQualityEdgeThreshold = 0.125
fxaaQualityEdgeThresholdMin = 0.0312
smaaEdgeDetection = luma
smaaThreshold = 0.05
smaaMaxSearchSteps = 32
smaaMaxSearchStepsDiag = 16
smaaCornerRounding = 25

reshadeTexturePath = "$TEXTURE_PATH"
reshadeIncludePath = "$SHADER_PATH"
depthCapture = off

toggleKey = Home

enableOnLaunch = True
EOF
            echo -e "${GREEN}✓ Performance configuration applied${NC}"
            ;;
        2)
            cat > "$CONFIG_FILE" << EOF
# Quality Configuration - Enhanced visuals

effects = cas:smaa:lumasharpen:vibrance

casSharpness = 0.6
smaaEdgeDetection = luma
smaaThreshold = 0.05
smaaMaxSearchSteps = 32
smaaMaxSearchStepsDiag = 16
smaaCornerRounding = 25
lumaSharpenStrength = 0.65
lumaSharpenClamp = 0.035
vibranceStrength = 0.15

reshadeTexturePath = "$TEXTURE_PATH"
reshadeIncludePath = "$SHADER_PATH"
depthCapture = off

toggleKey = Home

enableOnLaunch = True

lumasharpen = $SHADER_PATH/LumaSharpen.fx
vibrance = $SHADER_PATH/Vibrance.fx
EOF
            echo -e "${GREEN}✓ Quality configuration applied${NC}"
            ;;
        3)
            cat > "$CONFIG_FILE" << EOF
# Cinematic Configuration - Film look

effects = dpx:vibrance

dpxSaturation = 3.0
dpxColorGamma = 2.5
dpxContrast = 0.1
vibranceStrength = 0.20

reshadeTexturePath = "$TEXTURE_PATH"
reshadeIncludePath = "$SHADER_PATH"
depthCapture = off

toggleKey = Home

enableOnLaunch = True

dpx = $SHADER_PATH/DPX.fx
vibrance = $SHADER_PATH/Vibrance.fx
EOF
            echo -e "${GREEN}✓ Cinematic configuration applied${NC}"
            ;;
        4)
            cat > "$CONFIG_FILE" << EOF
# Minimal Configuration - Sharpness only

effects = cas

casSharpness = 0.5

reshadeTexturePath = "$TEXTURE_PATH"
reshadeIncludePath = "$SHADER_PATH"
depthCapture = off

toggleKey = Home

enableOnLaunch = True
EOF
            echo -e "${GREEN}✓ Minimal configuration applied${NC}"
            ;;
        5)
            cat > "$CONFIG_FILE" << EOF
# Complete Configuration - All effects

effects = cas:fxaa:smaa:lumasharpen:dpx:vibrance:clarity

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

reshadeTexturePath = "$TEXTURE_PATH"
reshadeIncludePath = "$SHADER_PATH"
depthCapture = off

toggleKey = Home

enableOnLaunch = True

clarity = $SHADER_PATH/Clarity.fx
dpx = $SHADER_PATH/DPX.fx
lumasharpen = $SHADER_PATH/LumaSharpen.fx
vibrance = $SHADER_PATH/Vibrance.fx
EOF
            echo -e "${GREEN}✓ Complete configuration applied${NC}"
            ;;
    esac
}

manage_shaders() {
    command -v clear >/dev/null 2>&1 && clear
    show_header
    echo -e "${BLUE}Shader Management:${NC}"
    echo ""
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
    read -r new_effects
    if [ -n "$new_effects" ]; then
        create_backup
        sed -i "s/^effects.*/effects = $new_effects/" "$CONFIG_FILE"
        echo -e "${GREEN}✓ Shaders updated: $new_effects${NC}"
    fi
}

show_advanced_menu() {
    echo -e "${BLUE}Advanced Settings:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Change toggle key (default: Home)"
    echo -e "  ${GREEN}2)${NC} CAS Sharpness adjustment"
    echo -e "  ${GREEN}3)${NC} DPX settings"
    echo -e "  ${GREEN}4)${NC} SMAA settings"
    echo -e "  ${GREEN}5)${NC} FXAA settings"
    echo -e "  ${GREEN}6)${NC} Vibrance settings"
    echo -e "  ${GREEN}7)${NC} LumaSharpen settings"
    echo -e "  ${GREEN}8)${NC} Clarity settings"
    echo -e "  ${RED}0)${NC} Back"
    echo ""
    echo -e -n "${YELLOW}Your choice [0-8]: ${NC}"
}

change_toggle_key() {
    echo ""
    echo -e "${BLUE}Available keys:${NC}"
    echo -e "  Home, End, Insert, Delete, F1-F12, etc."
    echo -e -n "${YELLOW}New toggle key: ${NC}"
    read -r new_key
    if [ -n "$new_key" ]; then
        create_backup
        sed -i "s/^toggleKey.*/toggleKey = $new_key/" "$CONFIG_FILE"
        echo -e "${GREEN}✓ Toggle key changed to: $new_key${NC}"
    fi
}

adjust_cas() {
    echo ""
    echo -e "${BLUE}CAS Configuration:${NC}"
    echo ""
    current_sharpness=$(grep "^casSharpness" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    echo -e "${CYAN}Current values:${NC}"
    echo -e "  CAS Sharpness: ${YELLOW}${current_sharpness:-0.4}${NC}"
    echo ""
    echo -e "${BLUE}CAS Sharpness intensity (0.0 - 1.0):${NC}"
    echo -e "  0.3 = Light | 0.5 = Moderate | 0.7 = Strong"
    echo -e -n "${YELLOW}Value (default 0.5): ${NC}"
    read -r sharpness
    sharpness=${sharpness:-0.5}
    if [ -n "$sharpness" ]; then
        create_backup
        if grep -q "^casSharpness" "$CONFIG_FILE"; then
            sed -i "s/^casSharpness.*/casSharpness = $sharpness/" "$CONFIG_FILE"
        else
            echo "casSharpness = $sharpness" >> "$CONFIG_FILE"
        fi
        echo -e "${GREEN}✓ CAS sharpness adjusted to: $sharpness${NC}"
    fi
}

configure_dpx() {
    echo ""
    echo -e "${BLUE}DPX Configuration:${NC}"
    echo ""
    current_sat=$(grep "^dpxSaturation" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    current_gamma=$(grep "^dpxColorGamma" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    current_contrast=$(grep "^dpxContrast" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    echo -e "${CYAN}Current values:${NC}"
    echo -e "  Saturation: ${YELLOW}${current_sat:-3.0}${NC}"
    echo -e "  Color Gamma: ${YELLOW}${current_gamma:-2.5}${NC}"
    echo -e "  Contrast: ${YELLOW}${current_contrast:-0.1}${NC}"
    echo ""
    echo -e "${BLUE}DPX Saturation (1.0 - 5.0, default: 3.0):${NC}"
    echo -e "  Higher values = more saturated colors"
    echo -e -n "${YELLOW}Saturation: ${NC}"
    read -r dpx_sat
    dpx_sat=${dpx_sat:-3.0}
    echo -e "${BLUE}DPX Color Gamma (1.0 - 4.0, default: 2.5):${NC}"
    echo -e "  Controls color response curve"
    echo -e -n "${YELLOW}Color Gamma: ${NC}"
    read -r dpx_gamma
    dpx_gamma=${dpx_gamma:-2.5}
    echo -e "${BLUE}DPX Contrast (-1.0 - 1.0, default: 0.1):${NC}"
    echo -e "  Positive values increase contrast"
    echo -e -n "${YELLOW}Contrast: ${NC}"
    read -r dpx_contrast
    dpx_contrast=${dpx_contrast:-0.1}
    if [ -n "$dpx_sat" ] || [ -n "$dpx_gamma" ] || [ -n "$dpx_contrast" ]; then
        create_backup
        if grep -q "^dpxSaturation" "$CONFIG_FILE"; then
            sed -i "s/^dpxSaturation.*/dpxSaturation = $dpx_sat/" "$CONFIG_FILE"
        else
            echo "dpxSaturation = $dpx_sat" >> "$CONFIG_FILE"
        fi
        if grep -q "^dpxColorGamma" "$CONFIG_FILE"; then
            sed -i "s/^dpxColorGamma.*/dpxColorGamma = $dpx_gamma/" "$CONFIG_FILE"
        else
            echo "dpxColorGamma = $dpx_gamma" >> "$CONFIG_FILE"
        fi
        if grep -q "^dpxContrast" "$CONFIG_FILE"; then
            sed -i "s/^dpxContrast.*/dpxContrast = $dpx_contrast/" "$CONFIG_FILE"
        else
            echo "dpxContrast = $dpx_contrast" >> "$CONFIG_FILE"
        fi
        echo -e "${GREEN}✓ DPX settings updated${NC}"
    fi
}

configure_smaa() {
    echo ""
    echo -e "${BLUE}SMAA Configuration:${NC}"
    echo ""
    current_edge=$(grep "^smaaEdgeDetection" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    current_threshold=$(grep "^smaaThreshold" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    current_steps=$(grep "^smaaMaxSearchSteps" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    current_steps_diag=$(grep "^smaaMaxSearchStepsDiag" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    current_corner=$(grep "^smaaCornerRounding" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    echo -e "${CYAN}Current values:${NC}"
    echo -e "  Edge Detection: ${YELLOW}${current_edge:-luma}${NC}"
    echo -e "  Threshold: ${YELLOW}${current_threshold:-0.05}${NC}"
    echo -e "  Max Search Steps: ${YELLOW}${current_steps:-32}${NC}"
    echo -e "  Max Search Steps Diag: ${YELLOW}${current_steps_diag:-16}${NC}"
    echo -e "  Corner Rounding: ${YELLOW}${current_corner:-25}${NC}"
    echo ""
    echo -e "${BLUE}SMAA Edge Detection (luma/color/depth):${NC}"
    echo -e "  luma = luminance based (recommended)"
    echo -e "  color = color based"
    echo -e "  depth = depth based"
    echo -e -n "${YELLOW}Edge Detection [current: ${current_edge:-luma}]: ${NC}"
    read -r smaa_edge
    smaa_edge=${smaa_edge:-${current_edge:-luma}}
    echo -e "${BLUE}SMAA Threshold (0.01 - 0.20, default: 0.05):${NC}"
    echo -e "  Lower values = more anti-aliasing"
    echo -e -n "${YELLOW}Threshold: ${NC}"
    read -r smaa_threshold
    smaa_threshold=${smaa_threshold:-${current_threshold:-0.05}}
    echo -e "${BLUE}Max Search Steps (8 - 64, default: 32):${NC}"
    echo -e "  Higher values = better quality but slower"
    echo -e -n "${YELLOW}Max Steps: ${NC}"
    read -r smaa_steps
    smaa_steps=${smaa_steps:-${current_steps:-32}}
    echo -e "${BLUE}Max Search Steps Diagonal (4 - 32, default: 16):${NC}"
    echo -e "  Search steps for diagonal edges"
    echo -e -n "${YELLOW}Max Steps Diagonal: ${NC}"
    read -r smaa_steps_diag
    smaa_steps_diag=${smaa_steps_diag:-${current_steps_diag:-16}}
    echo -e "${BLUE}Corner Rounding (0 - 100, default: 25):${NC}"
    echo -e "  Controls edge smoothing"
    echo -e -n "${YELLOW}Corner Rounding: ${NC}"
    read -r smaa_corner
    smaa_corner=${smaa_corner:-${current_corner:-25}}
    if [ -n "$smaa_edge" ] || [ -n "$smaa_threshold" ] || [ -n "$smaa_steps" ] || [ -n "$smaa_steps_diag" ] || [ -n "$smaa_corner" ]; then
        create_backup
        if grep -q "^smaaEdgeDetection" "$CONFIG_FILE"; then
            sed -i "s/^smaaEdgeDetection.*/smaaEdgeDetection = $smaa_edge/" "$CONFIG_FILE"
        else
            echo "smaaEdgeDetection = $smaa_edge" >> "$CONFIG_FILE"
        fi
        if grep -q "^smaaThreshold" "$CONFIG_FILE"; then
            sed -i "s/^smaaThreshold.*/smaaThreshold = $smaa_threshold/" "$CONFIG_FILE"
        else
            echo "smaaThreshold = $smaa_threshold" >> "$CONFIG_FILE"
        fi
        if grep -q "^smaaMaxSearchSteps" "$CONFIG_FILE"; then
            sed -i "s/^smaaMaxSearchSteps.*/smaaMaxSearchSteps = $smaa_steps/" "$CONFIG_FILE"
        else
            echo "smaaMaxSearchSteps = $smaa_steps" >> "$CONFIG_FILE"
        fi
        if grep -q "^smaaMaxSearchStepsDiag" "$CONFIG_FILE"; then
            sed -i "s/^smaaMaxSearchStepsDiag.*/smaaMaxSearchStepsDiag = $smaa_steps_diag/" "$CONFIG_FILE"
        else
            echo "smaaMaxSearchStepsDiag = $smaa_steps_diag" >> "$CONFIG_FILE"
        fi
        if grep -q "^smaaCornerRounding" "$CONFIG_FILE"; then
            sed -i "s/^smaaCornerRounding.*/smaaCornerRounding = $smaa_corner/" "$CONFIG_FILE"
        else
            echo "smaaCornerRounding = $smaa_corner" >> "$CONFIG_FILE"
        fi
        echo -e "${GREEN}✓ SMAA settings updated${NC}"
    fi
}

configure_fxaa() {
    echo ""
    echo -e "${BLUE}FXAA Configuration:${NC}"
    echo ""
    current_subpix=$(grep "^fxaaQualitySubpix" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    current_edge=$(grep "^fxaaQualityEdgeThreshold" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    current_edge_min=$(grep "^fxaaQualityEdgeThresholdMin" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    echo -e "${CYAN}Current values:${NC}"
    echo -e "  Quality Subpix: ${YELLOW}${current_subpix:-0.75}${NC}"
    echo -e "  Edge Threshold: ${YELLOW}${current_edge:-0.125}${NC}"
    echo -e "  Edge Threshold Min: ${YELLOW}${current_edge_min:-0.0312}${NC}"
    echo ""
    echo -e "${BLUE}FXAA Quality Subpix (0.0 - 1.0, default: 0.75):${NC}"
    echo -e "  Controls subpixel aliasing removal"
    echo -e -n "${YELLOW}Quality Subpix: ${NC}"
    read -r fxaa_subpix
    fxaa_subpix=${fxaa_subpix:-${current_subpix:-0.75}}
    echo -e "${BLUE}FXAA Edge Threshold (0.063 - 0.333, default: 0.125):${NC}"
    echo -e "  Lower values = more anti-aliasing"
    echo -e -n "${YELLOW}Edge Threshold: ${NC}"
    read -r fxaa_edge
    fxaa_edge=${fxaa_edge:-${current_edge:-0.125}}
    echo -e "${BLUE}FXAA Edge Threshold Min (0.0 - 0.0833, default: 0.0312):${NC}"
    echo -e "  Minimum edge detection threshold"
    echo -e -n "${YELLOW}Edge Threshold Min: ${NC}"
    read -r fxaa_edge_min
    fxaa_edge_min=${fxaa_edge_min:-${current_edge_min:-0.0312}}
    if [ -n "$fxaa_subpix" ] || [ -n "$fxaa_edge" ] || [ -n "$fxaa_edge_min" ]; then
        create_backup
        if grep -q "^fxaaQualitySubpix" "$CONFIG_FILE"; then
            sed -i "s/^fxaaQualitySubpix.*/fxaaQualitySubpix = $fxaa_subpix/" "$CONFIG_FILE"
        else
            echo "fxaaQualitySubpix = $fxaa_subpix" >> "$CONFIG_FILE"
        fi
        if grep -q "^fxaaQualityEdgeThreshold" "$CONFIG_FILE"; then
            sed -i "s/^fxaaQualityEdgeThreshold.*/fxaaQualityEdgeThreshold = $fxaa_edge/" "$CONFIG_FILE"
        else
            echo "fxaaQualityEdgeThreshold = $fxaa_edge" >> "$CONFIG_FILE"
        fi
        if grep -q "^fxaaQualityEdgeThresholdMin" "$CONFIG_FILE"; then
            sed -i "s/^fxaaQualityEdgeThresholdMin.*/fxaaQualityEdgeThresholdMin = $fxaa_edge_min/" "$CONFIG_FILE"
        else
            echo "fxaaQualityEdgeThresholdMin = $fxaa_edge_min" >> "$CONFIG_FILE"
        fi
        echo -e "${GREEN}✓ FXAA settings updated${NC}"
    fi
}

configure_vibrance() {
    echo ""
    echo -e "${BLUE}Vibrance Configuration:${NC}"
    echo ""
    current_strength=$(grep "^vibranceStrength" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    echo -e "${CYAN}Current values:${NC}"
    echo -e "  Vibrance Strength: ${YELLOW}${current_strength:-0.15}${NC}"
    echo ""
    echo -e "${BLUE}Vibrance Strength (-1.0 - 1.0, default: 0.15):${NC}"
    echo -e "  Positive values increase color vibrance"
    echo -e "  Negative values decrease color vibrance"
    echo -e -n "${YELLOW}Vibrance Strength: ${NC}"
    read -r vibrance_strength
    vibrance_strength=${vibrance_strength:-${current_strength:-0.15}}
    if [ -n "$vibrance_strength" ]; then
        create_backup
        if grep -q "^vibranceStrength" "$CONFIG_FILE"; then
            sed -i "s/^vibranceStrength.*/vibranceStrength = $vibrance_strength/" "$CONFIG_FILE"
        else
            echo "vibranceStrength = $vibrance_strength" >> "$CONFIG_FILE"
        fi
        echo -e "${GREEN}✓ Vibrance settings updated${NC}"
    fi
}

configure_lumasharpen() {
    echo ""
    echo -e "${BLUE}LumaSharpen Configuration:${NC}"
    echo ""
    current_strength=$(grep "^lumaSharpenStrength" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    current_clamp=$(grep "^lumaSharpenClamp" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    echo -e "${CYAN}Current values:${NC}"
    echo -e "  Sharpen Strength: ${YELLOW}${current_strength:-0.65}${NC}"
    echo -e "  Sharpen Clamp: ${YELLOW}${current_clamp:-0.035}${NC}"
    echo ""
    echo -e "${BLUE}LumaSharpen Strength (0.0 - 3.0, default: 0.65):${NC}"
    echo -e "  Controls sharpening intensity"
    echo -e -n "${YELLOW}Sharpen Strength: ${NC}"
    read -r luma_strength
    luma_strength=${luma_strength:-${current_strength:-0.65}}
    echo -e "${BLUE}LumaSharpen Clamp (0.0 - 1.0, default: 0.035):${NC}"
    echo -e "  Limits maximum sharpening to prevent artifacts"
    echo -e -n "${YELLOW}Sharpen Clamp: ${NC}"
    read -r luma_clamp
    luma_clamp=${luma_clamp:-${current_clamp:-0.035}}
    if [ -n "$luma_strength" ] || [ -n "$luma_clamp" ]; then
        create_backup
        if [ -n "$luma_strength" ]; then
            if grep -q "^lumaSharpenStrength" "$CONFIG_FILE"; then
                sed -i "s/^lumaSharpenStrength.*/lumaSharpenStrength = $luma_strength/" "$CONFIG_FILE"
            else
                echo "lumaSharpenStrength = $luma_strength" >> "$CONFIG_FILE"
            fi
        fi
        if [ -n "$luma_clamp" ]; then
            if grep -q "^lumaSharpenClamp" "$CONFIG_FILE"; then
                sed -i "s/^lumaSharpenClamp.*/lumaSharpenClamp = $luma_clamp/" "$CONFIG_FILE"
            else
                echo "lumaSharpenClamp = $luma_clamp" >> "$CONFIG_FILE"
            fi
        fi
        echo -e "${GREEN}✓ LumaSharpen settings updated${NC}"
    fi
}

configure_clarity() {
    echo ""
    echo -e "${BLUE}Clarity Configuration:${NC}"
    echo ""
    current_radius=$(grep "^clarityRadius" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    current_offset=$(grep "^clarityOffset" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    current_strength=$(grep "^clarityStrength" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    echo -e "${CYAN}Current values:${NC}"
    echo -e "  Clarity Radius: ${YELLOW}${current_radius:-3}${NC}"
    echo -e "  Clarity Offset: ${YELLOW}${current_offset:-2.0}${NC}"
    echo -e "  Clarity Strength: ${YELLOW}${current_strength:-0.4}${NC}"
    echo ""
    echo -e "${BLUE}Clarity Radius (1 - 8, default: 3):${NC}"
    echo -e "  Controls the radius of the clarity effect"
    echo -e -n "${YELLOW}Clarity Radius: ${NC}"
    read -r clarity_radius
    clarity_radius=${clarity_radius:-${current_radius:-3}}
    echo -e "${BLUE}Clarity Offset (0.0 - 10.0, default: 2.0):${NC}"
    echo -e "  Controls the offset for clarity calculation"
    echo -e -n "${YELLOW}Clarity Offset: ${NC}"
    read -r clarity_offset
    clarity_offset=${clarity_offset:-${current_offset:-2.0}}
    echo -e "${BLUE}Clarity Strength (0.0 - 1.0, default: 0.4):${NC}"
    echo -e "  Controls the intensity of the clarity effect"
    echo -e -n "${YELLOW}Clarity Strength: ${NC}"
    read -r clarity_strength
    clarity_strength=${clarity_strength:-${current_strength:-0.4}}
    if [ -n "$clarity_radius" ] || [ -n "$clarity_offset" ] || [ -n "$clarity_strength" ]; then
        create_backup
        if [ -n "$clarity_radius" ]; then
            if grep -q "^clarityRadius" "$CONFIG_FILE"; then
                sed -i "s/^clarityRadius.*/clarityRadius = $clarity_radius/" "$CONFIG_FILE"
            else
                echo "clarityRadius = $clarity_radius" >> "$CONFIG_FILE"
            fi
        fi
        if [ -n "$clarity_offset" ]; then
            if grep -q "^clarityOffset" "$CONFIG_FILE"; then
                sed -i "s/^clarityOffset.*/clarityOffset = $clarity_offset/" "$CONFIG_FILE"
            else
                echo "clarityOffset = $clarity_offset" >> "$CONFIG_FILE"
            fi
        fi
        if [ -n "$clarity_strength" ]; then
            if grep -q "^clarityStrength" "$CONFIG_FILE"; then
                sed -i "s/^clarityStrength.*/clarityStrength = $clarity_strength/" "$CONFIG_FILE"
            else
                echo "clarityStrength = $clarity_strength" >> "$CONFIG_FILE"
            fi
        fi
        echo -e "${GREEN}✓ Clarity settings updated${NC}"
    fi
}

show_current_config() {
    command -v clear >/dev/null 2>&1 && clear
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

create_backup() {
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        echo -e "${GREEN}✓ Backup created${NC}"
    fi
}

restore_backup() {
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$CONFIG_FILE"
        echo -e "${GREEN}✓ Configuration restored from backup${NC}"
    else
        echo -e "${RED}❌ No backup found${NC}"
    fi
}

delete_backup() {
    if [ -f "$BACKUP_FILE" ]; then
        rm "$BACKUP_FILE"
        echo -e "${GREEN}✓ Backup deleted${NC}"
    else
        echo -e "${RED}❌ No backup found${NC}"
    fi
}

show_usage() {
    command -v clear >/dev/null 2>&1 && clear
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

uninstall_all() {
    echo -e "${RED}🗑️  Uninstall VkBasalt and shaders${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  This will remove all VkBasalt components and shaders${NC}"
    echo -e -n "${RED}Are you sure you want to continue? [y/N]: ${NC}"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Uninstall cancelled.${NC}"
        return 0
    fi
    echo ""
    echo -e "${BLUE}Removing files...${NC}"
    [ -d "/home/deck/.config/vkBasalt" ] && rm -rf /home/deck/.config/vkBasalt && echo -e "${GREEN}✓ Configuration removed${NC}"
    [ -d "/home/deck/.config/reshade" ] && rm -rf /home/deck/.config/reshade && echo -e "${GREEN}✓ Shaders removed${NC}"
    [ -f "/home/deck/.local/lib/libvkbasalt.so" ] && rm -f /home/deck/.local/lib/libvkbasalt.so && echo -e "${GREEN}✓ 64-bit library removed${NC}"
    [ -f "/home/deck/.local/lib32/libvkbasalt.so" ] && rm -f /home/deck/.local/lib32/libvkbasalt.so && echo -e "${GREEN}✓ 32-bit library removed${NC}"
    [ -f "/home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.json" ] && rm -f /home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.json && echo -e "${GREEN}✓ 64-bit Vulkan layer removed${NC}"
    [ -f "/home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json" ] && rm -f /home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json && echo -e "${GREEN}✓ 32-bit Vulkan layer removed${NC}"
    rmdir /home/deck/.local/share/vulkan/implicit_layer.d 2>/dev/null || true
    rmdir /home/deck/.local/share/vulkan 2>/dev/null || true
    rmdir /home/deck/.local/lib32 2>/dev/null || true
    echo ""
    echo -e "${GREEN}🎉 Uninstall complete!${NC}"
    echo -e "${BLUE}ℹ️  Remember to remove ${YELLOW}ENABLE_VKBASALT=1${BLUE} from your game launch options${NC}"
}

pause() {
    echo ""
    echo -e -n "${CYAN}Press Enter to continue...${NC}"
    read -r
}

handle_config_menu() {
    while true; do
        command -v clear >/dev/null 2>&1 && clear
        show_header
        show_config_menu
        read -r choice
        case $choice in
            1)
                while true; do
                    show_preset_menu
                    read -r preset_choice
                    case $preset_choice in
                        1|2|3|4|5)
                            apply_preset "$preset_choice"
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
                    command -v clear >/dev/null 2>&1 && clear
                    show_header
                    show_advanced_menu
                    read -r adv_choice
                    case $adv_choice in
                        1) change_toggle_key; pause ;;
                        2) adjust_cas; pause ;;
                        3) configure_dpx; pause ;;
                        4) configure_smaa; pause ;;
                        5) configure_fxaa; pause ;;
                        6) configure_vibrance; pause ;;
                        7) configure_lumasharpen; pause ;;
                        8) configure_clarity; pause ;;
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
                    command -v clear >/dev/null 2>&1 && clear
                    show_header
                    show_backup_menu
                    read -r backup_choice
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
                read -r confirm
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

main() {
    while true; do
        show_header
        check_status
        show_main_menu
        read -r choice
        case $choice in
            1)
                command -v clear >/dev/null 2>&1 && clear
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
                command -v clear >/dev/null 2>&1 && clear
                show_header
                check_status
                pause
                ;;
            5)
                command -v clear >/dev/null 2>&1 && clear
                show_header
                uninstall_all
                pause
                ;;
            0)
                command -v clear >/dev/null 2>&1 && clear
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

main
