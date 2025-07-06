#!/bin/bash

# VkBasalt Manager - Installateur automatique (complet, tout inclus, prêt-à-lancer)
# Installe vkBasalt, les shaders, la configuration, le manager graphique (zenity), icône et raccourci bureau

echo "🚀 Installation de VkBasalt Manager pour Steam Deck"
echo "=================================================="
echo

# Vérifier si on est sur Steam Deck
if [ ! -d "/home/deck" ]; then
    echo "❌ Ce script est conçu pour Steam Deck (/home/deck introuvable)"
    exit 1
fi

# Créer les répertoires nécessaires
echo "📁 Création des répertoires..."
mkdir -p /home/deck/Desktop
mkdir -p /home/deck/.config/vkBasalt
mkdir -p /home/deck/.config/reshade

SCRIPT_PATH="/home/deck/.config/vkBasalt/VkBasalt-Manager.sh"
ICON_PATH="/home/deck/.config/vkBasalt/vkbasalt-manager.svg"
DESKTOP_FILE="/home/deck/Desktop/VkBasalt-Manager.desktop"

# Installation de Zenity si besoin
if ! command -v zenity &> /dev/null; then
    echo "🛠 Installation de Zenity..."
    if command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm zenity
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y zenity
    else
        echo "Impossible d'installer Zenity automatiquement."
        exit 1
    fi
fi

# Installation de vkBasalt
echo "🔽 Téléchargement de vkBasalt et des shaders..."
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

if wget -q https://github.com/simons-public/steam-deck-vkbasalt-install/raw/main/vkbasalt_install.sh; then
    echo "▶ Installation de vkBasalt..."
    bash vkbasalt_install.sh > /dev/null 2>&1
    rm -f vkbasalt_install.sh
else
    echo "❌ Impossible de télécharger vkbasalt_install.sh"
    exit 1
fi

# Installation des shaders (Vaddum/vkbasalt-manager)
if wget -q https://github.com/Vaddum/vkbasalt-manager/archive/refs/heads/main.zip; then
    unzip -q main.zip
    cp -rf vkbasalt-manager-main/reshade /home/deck/.config/
    rm -rf main.zip vkbasalt-manager-main
else
    echo "❌ Impossible de télécharger les shaders"
    exit 1
fi

cd ~
rm -rf "$TMPDIR"

# Générer une config par défaut minimaliste si besoin
CONFIG_FILE="/home/deck/.config/vkBasalt/vkBasalt.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << EOF
# VkBasalt Configuration - Aucun effet actif

effects = cas

reshadeTexturePath = "/home/deck/.config/reshade/Textures"
reshadeIncludePath = "/home/deck/.config/reshade/Shaders"

toggleKey = Home

enableOnLaunch = True

# CAS (Contrast Adaptive Sharpening)
casSharpness = 0.4
EOF
fi

# Script principal (manager graphique complet inline)
echo "📝 Création du script principal..."
cat > "$SCRIPT_PATH" << 'SCRIPT_EOF'
#!/bin/bash

# VkBasalt Manager pour Steam Deck - Gestionnaire graphique complet (Zenity)
# Version Standalone Configuration (sliders, presets, backup, etc.)
# ⚠️ Ce script suppose que VkBasalt est déjà installé sur le système

CONFIG_FILE="/home/deck/.config/vkBasalt/vkBasalt.conf"
BACKUP_FILE="/home/deck/.config/vkBasalt/vkBasalt.conf.backup"
SHADER_PATH="/home/deck/.config/reshade/Shaders"
TEXTURE_PATH="/home/deck/.config/reshade/Textures"

# Vérifier Zenity
check_zenity() {
    if ! command -v zenity &> /dev/null; then
        echo "Zenity n'est pas installé. Installation en cours..."
        if command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm zenity
        elif command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y zenity
        else
            echo "Impossible d'installer Zenity automatiquement."
            exit 1
        fi
    fi
}

# Dialogs
show_error() { zenity --error --text="$1" --width=400; }
show_info() { zenity --info --text="$1" --width=400; }
show_warning() { zenity --warning --text="$1" --width=400; }

# Backup
create_backup() { [ -f "$CONFIG_FILE" ] && cp "$CONFIG_FILE" "$BACKUP_FILE"; }
restore_backup() {
    if [ -f "$BACKUP_FILE" ]; then
        if zenity --question --text="Restaurer la configuration depuis la sauvegarde ?\nCela écrasera la configuration actuelle."; then
            cp "$BACKUP_FILE" "$CONFIG_FILE"
            show_info "✓ Configuration restaurée depuis la sauvegarde"
        fi
    else
        show_error "❌ Aucune sauvegarde trouvée"
    fi
}
delete_backup() {
    if [ -f "$BACKUP_FILE" ]; then
        if zenity --question --text="Supprimer la sauvegarde ?\nCette action est irréversible."; then
            rm "$BACKUP_FILE"
            show_info "✓ Sauvegarde supprimée"
        fi
    else
        show_error "❌ Aucune sauvegarde trouvée"
    fi
}

# Configurations de base
create_minimal_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# VkBasalt Configuration - Aucun effet actif

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
# VkBasalt Configuration - Shaders sélectionnés: $selected_shaders

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

# Vérification d'installation
check_status() {
    local status_text=""
    [ -f "/home/deck/.local/lib/libvkbasalt.so" ] && [ -f "/home/deck/.local/lib32/libvkbasalt.so" ] \
        && status_text+="✓ VkBasalt: Installé\n" || status_text+="✗ VkBasalt: Non installé\n"
    [ -f "$CONFIG_FILE" ] && status_text+="✓ Configuration: Trouvée\n" || status_text+="⚠ Configuration: Manquante\n"
    if [ -d "$SHADER_PATH" ] && [ "$(ls -A $SHADER_PATH 2>/dev/null)" ]; then
        shader_count=$(ls -1 $SHADER_PATH/*.fx 2>/dev/null | wc -l)
        status_text+="✓ Shaders: $shader_count Shaders installés\n"
    else
        status_text+="✗ Shaders: Non installés\n"
    fi
    zenity --info --text="$status_text" --title="État de l'installation" --width=400
}

# Menus principaux
show_main_menu() {
    if [ ! -f "/home/deck/.local/lib/libvkbasalt.so" ]; then
        show_error "❌ VkBasalt n'est pas installé !\nUtilisez l'installateur VkBasalt Manager pour installer VkBasalt."
        exit 1
    fi
    if [ ! -f "$CONFIG_FILE" ]; then
        show_info "🔧 Première utilisation détectée. Création d'une configuration par défaut..."
        create_default_config
        show_info "✅ Configuration par défaut créée !\nVkBasalt est prêt à utiliser avec CAS."
    fi
    show_config_menu
}

show_config_menu() {
    local choice=$(zenity --list \
        --title="VkBasalt Manager - Configuration" \
        --text="VkBasalt est installé et prêt ! Choisissez une option :" \
        --column="Option" --column="Description" \
        --width=600 --height=500 \
        "Presets" "Appliquer une configuration prédéfinie" \
        "Shaders" "Gérer les shaders actifs" \
        "Touche" "Changer la touche de basculement" \
        "Avancé" "Paramètres avancés des shaders" \
        "Voir" "Voir la configuration actuelle" \
        "Sauvegarde" "Gestion des sauvegardes" \
        "Reset" "Réinitialiser aux valeurs par défaut" \
        "Utilisation" "Informations d'utilisation" \
        "Statut" "Vérifier l'installation" \
        2>/dev/null)
    case "$choice" in
        "Presets") show_preset_menu ;;
        "Shaders") manage_shaders ;;
        "Touche") change_toggle_key ;;
        "Avancé") show_advanced_menu ;;
        "Voir") show_current_config ;;
        "Sauvegarde") show_backup_menu ;;
        "Reset")
            if zenity --question --text="⚠️ Cela réinitialisera la configuration aux valeurs par défaut.\nContinuer ?"; then
                create_backup
                create_default_config
                show_info "✓ Configuration réinitialisée aux valeurs par défaut"
            fi
            ;;
        "Utilisation") show_usage ;;
        "Statut") check_status ;;
        *) exit 0 ;;
    esac
}

show_preset_menu() {
    local choice=$(zenity --list \
        --title="Configurations prédéfinies" \
        --text="Choisissez une configuration :" \
        --column="Preset" --column="Description" \
        --width=600 --height=400 \
        "Performance" "Effets légers pour de meilleures performances" \
        "Qualité" "Visuels améliorés avec effets multiples" \
        "Cinématique" "Look cinéma avec effets dramatiques" \
        "Minimal" "Netteté uniquement (CAS)" \
        "Complet" "Tous les effets activés" \
        2>/dev/null)
    case "$choice" in
        "Performance") apply_preset 1 ;;
        "Qualité") apply_preset 2 ;;
        "Cinématique") apply_preset 3 ;;
        "Minimal") apply_preset 4 ;;
        "Complet") apply_preset 5 ;;
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
            show_info "✓ Configuration Performance appliquée\nShaders actifs: CAS, FXAA, SMAA"
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
            show_info "✓ Configuration Qualité appliquée\nShaders actifs: CAS, SMAA, LumaSharpen, Vibrance"
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
            show_info "✓ Configuration Cinématique appliquée\nShaders actifs: DPX, Vibrance"
            ;;
        4)
            create_dynamic_config "cas"
            cat >> "$CONFIG_FILE" << EOF

# Minimal optimizations
casSharpness = 0.5
depthCapture = off
EOF
            show_info "✓ Configuration Minimale appliquée\nShader actif: CAS uniquement"
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
            show_info "✓ Configuration Complète appliquée\nTous les shaders actifs: CAS, FXAA, SMAA, LumaSharpen, DPX, Vibrance, Clarity"
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
        --title="Sélection des Shaders" \
        --text="Choisissez les shaders à activer :\nActuellement actifs: $current_effects\n⚠️ Ctrl+Clic pour sélectionner plusieurs shaders" \
        --checklist \
        --column="Activer" --column="Shader" --column="Description" \
        --width=700 --height=450 --separator=":" \
        $cas_check "cas" "Contrast Adaptive Sharpening - Netteté AMD" \
        $fxaa_check "fxaa" "Fast Approximate Anti-Aliasing - AA rapide" \
        $smaa_check "smaa" "Subpixel Morphological Anti-Aliasing - AA HQ" \
        $lumasharpen_check "lumasharpen" "Netteté luminance" \
        $vibrance_check "vibrance" "Saturation intelligente" \
        $dpx_check "dpx" "Look cinéma" \
        $clarity_check "clarity" "Clarté et détails" \
        2>/dev/null)
    if [ $? -eq 0 ]; then
        create_backup
        if [ -z "$selected_shaders" ]; then
            if zenity --question --text="Aucun shader sélectionné.\nVoulez-vous désactiver tous les shaders ?"; then
                create_minimal_config
                show_info "✓ Tous les shaders ont été désactivés"
            fi
        else
            create_dynamic_config "$selected_shaders"
            show_info "✓ Configuration mise à jour avec les shaders: $selected_shaders"
        fi
    fi
}

show_advanced_menu() {
    local choice=$(zenity --list \
        --title="Paramètres avancés" \
        --text="Choisissez un shader à configurer en détail :" \
        --column="Shader" --column="Description" \
        --width=700 --height=450 \
        "CAS" "Contrast Adaptive Sharpening - Netteté AMD" \
        "Clarity" "Clarté et détails" \
        "DPX" "Look cinéma professionnel" \
        "FXAA" "Fast Approximate Anti-Aliasing - AA rapide" \
        "LumaSharpen" "Netteté luminance" \
        "SMAA" "Subpixel Morphological Anti-Aliasing - AA HQ" \
        "Vibrance" "Saturation intelligente" \
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
        --title="Changer la touche de basculement" \
        --text="Touche actuelle: ${current_key:-Home}\n\nChoisissez une nouvelle touche pour activer/désactiver les effets VkBasalt :" \
        --column="Touche" \
        --column="Description" \
        --width=500 \
        --height=500 \
        "Home" "Touche Début (recommandée)" \
        "End" "Touche Fin" \
        "Insert" "Touche Insertion" \
        "Delete" "Touche Suppression" \
        "F1" "Fonction F1" \
        "F2" "Fonction F2" \
        "F3" "Fonction F3" \
        "F4" "Fonction F4" \
        "F5" "Fonction F5" \
        "F6" "Fonction F6" \
        "F7" "Fonction F7" \
        "F8" "Fonction F8" \
        "F9" "Fonction F9" \
        "F10" "Fonction F10" \
        "F11" "Fonction F11" \
        "F12" "Fonction F12" \
        "Page_Up" "Page Précédente" \
        "Page_Down" "Page Suivante" \
        "Print" "Impression Écran" \
        "Scroll_Lock" "Arrêt Défilement" \
        "Pause" "Pause" \
        "Menu" "Touche Menu contextuel" \
        "Tab" "Tabulation" \
        "Caps_Lock" "Verrouillage Majuscules" \
        "Num_Lock" "Verrouillage Numérique" \
        2>/dev/null)

    if [ ! -z "$new_key" ]; then
        create_backup
        sed -i "s/^toggleKey.*/toggleKey = $new_key/" "$CONFIG_FILE"
        show_info "✓ Touche de basculement changée: $new_key\n\nUtilisez maintenant la touche '$new_key' pour activer/désactiver les effets VkBasalt dans vos jeux."
    fi
}

# Sliders pour chaque shader
configure_cas() {
    local cur=$(grep "^casSharpness" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local val=40; [ ! -z "$cur" ] && val=$(awk "BEGIN {printf \"%.0f\", $cur * 100}")
    local sharpness=$(zenity --scale --title="CAS - Netteté" --text="Valeur actuelle: ${cur:-0.4}" --min-value=0 --max-value=100 --value=$val --step=5)
    if [ ! -z "$sharpness" ]; then
        local v=$(awk "BEGIN {printf \"%.2f\", $sharpness / 100}")
        create_backup
        grep -q "^casSharpness" "$CONFIG_FILE" && sed -i "s/^casSharpness.*/casSharpness = $v/" "$CONFIG_FILE" || echo "casSharpness = $v" >> "$CONFIG_FILE"
        show_info "✓ Netteté CAS ajustée à: $v ($sharpness%)"
    fi
}
configure_fxaa() {
    local subpix=$(grep "^fxaaQualitySubpix" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local edge=$(grep "^fxaaQualityEdgeThreshold" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local s=75; [ ! -z "$subpix" ] && s=$(awk "BEGIN {printf \"%.0f\", $subpix * 100}")
    local sp=$(zenity --scale --title="FXAA - Qualité Subpix" --text="Valeur actuelle: ${subpix:-0.75}" --min-value=0 --max-value=100 --value=$s --step=5)
    if [ ! -z "$sp" ]; then
        local spf=$(awk "BEGIN {printf \"%.2f\", $sp / 100}")
        local e=37; [ ! -z "$edge" ] && e=$(awk "BEGIN {printf \"%.0f\", ($edge - 0.063) * 100 / 0.27}")
        local ed=$(zenity --scale --title="FXAA - Seuil Edge" --text="Valeur actuelle: ${edge:-0.125}" --min-value=0 --max-value=100 --value=$e --step=5)
        if [ ! -z "$ed" ]; then
            local edf=$(awk "BEGIN {printf \"%.3f\", 0.063 + ($ed * 0.27 / 100)}")
            create_backup
            grep -q "^fxaaQualitySubpix" "$CONFIG_FILE" && sed -i "s/^fxaaQualitySubpix.*/fxaaQualitySubpix = $spf/" "$CONFIG_FILE" || echo "fxaaQualitySubpix = $spf" >> "$CONFIG_FILE"
            grep -q "^fxaaQualityEdgeThreshold" "$CONFIG_FILE" && sed -i "s/^fxaaQualityEdgeThreshold.*/fxaaQualityEdgeThreshold = $edf/" "$CONFIG_FILE" || echo "fxaaQualityEdgeThreshold = $edf" >> "$CONFIG_FILE"
            show_info "✓ Paramètres FXAA mis à jour\nSubpix: $spf | Edge: $edf"
        fi
    fi
}
configure_smaa() {
    local thresh=$(grep "^smaaThreshold" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local steps=$(grep "^smaaMaxSearchSteps" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local edge_detection=$(zenity --list --title="SMAA - Détection des bords" --text="Mode de détection :" --column="Mode" --column="Description" --width=500 --height=300 "luma" "Luminance (recommandé)" "color" "Couleur" "depth" "Profondeur" 2>/dev/null)
    if [ ! -z "$edge_detection" ]; then
        local t=25; [ ! -z "$thresh" ] && t=$(awk "BEGIN {printf \"%.0f\", ($thresh - 0.01) * 100 / 0.19}")
        local th=$(zenity --scale --title="SMAA - Seuil" --text="Valeur actuelle: ${thresh:-0.05}" --min-value=0 --max-value=100 --value=$t --step=5)
        if [ ! -z "$th" ]; then
            local thf=$(awk "BEGIN {printf \"%.3f\", 0.01 + ($th * 0.19 / 100)}")
            local s=43; [ ! -z "$steps" ] && s=$(awk "BEGIN {printf \"%.0f\", ($steps - 8) * 100 / 56}")
            local st=$(zenity --scale --title="SMAA - Steps" --text="Valeur actuelle: ${steps:-32}" --min-value=0 --max-value=100 --value=$s --step=5)
            if [ ! -z "$st" ]; then
                local stf=$(awk "BEGIN {printf \"%.0f\", 8 + ($st * 56 / 100)}")
                create_backup
                grep -q "^smaaEdgeDetection" "$CONFIG_FILE" && sed -i "s/^smaaEdgeDetection.*/smaaEdgeDetection = $edge_detection/" "$CONFIG_FILE" || echo "smaaEdgeDetection = $edge_detection" >> "$CONFIG_FILE"
                grep -q "^smaaThreshold" "$CONFIG_FILE" && sed -i "s/^smaaThreshold.*/smaaThreshold = $thf/" "$CONFIG_FILE" || echo "smaaThreshold = $thf" >> "$CONFIG_FILE"
                grep -q "^smaaMaxSearchSteps" "$CONFIG_FILE" && sed -i "s/^smaaMaxSearchSteps.*/smaaMaxSearchSteps = $stf/" "$CONFIG_FILE" || echo "smaaMaxSearchSteps = $stf" >> "$CONFIG_FILE"
                show_info "✓ SMAA mis à jour\nDétection: $edge_detection | Seuil: $thf | Steps: $stf"
            fi
        fi
    fi
}
configure_dpx() {
    local sat=$(grep "^dpxSaturation" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local gamma=$(grep "^dpxColorGamma" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local contrast=$(grep "^dpxContrast" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local sv=43; [ ! -z "$sat" ] && sv=$(awk "BEGIN {printf \"%.0f\", ($sat - 1.0) * 100 / 7.0}")
    local saturation=$(zenity --scale --title="DPX - Saturation" --text="Valeur actuelle: ${sat:-3.0}" --min-value=0 --max-value=100 --value=$sv --step=5)
    if [ ! -z "$saturation" ]; then
        local satf=$(awk "BEGIN {printf \"%.1f\", 1.0 + ($saturation * 7.0 / 100)}")
        local gv=50; [ ! -z "$gamma" ] && gv=$(awk "BEGIN {printf \"%.0f\", ($gamma - 1.0) * 100 / 3.0}")
        local gamma_val=$(zenity --scale --title="DPX - Gamma" --text="Valeur actuelle: ${gamma:-2.5}" --min-value=0 --max-value=100 --value=$gv --step=5)
        if [ ! -z "$gamma_val" ]; then
            local gammaf=$(awk "BEGIN {printf \"%.1f\", 1.0 + ($gamma_val * 3.0 / 100)}")
            local cv=55; [ ! -z "$contrast" ] && cv=$(awk "BEGIN {printf \"%.0f\", ($contrast + 1.0) * 100 / 2.0}")
            local contrast_val=$(zenity --scale --title="DPX - Contraste" --text="Valeur actuelle: ${contrast:-0.1}" --min-value=0 --max-value=100 --value=$cv --step=5)
            if [ ! -z "$contrast_val" ]; then
                local contrastf=$(awk "BEGIN {printf \"%.1f\", -1.0 + ($contrast_val * 2.0 / 100)}")
                create_backup
                grep -q "^dpxSaturation" "$CONFIG_FILE" && sed -i "s/^dpxSaturation.*/dpxSaturation = $satf/" "$CONFIG_FILE" || echo "dpxSaturation = $satf" >> "$CONFIG_FILE"
                grep -q "^dpxColorGamma" "$CONFIG_FILE" && sed -i "s/^dpxColorGamma.*/dpxColorGamma = $gammaf/" "$CONFIG_FILE" || echo "dpxColorGamma = $gammaf" >> "$CONFIG_FILE"
                grep -q "^dpxContrast" "$CONFIG_FILE" && sed -i "s/^dpxContrast.*/dpxContrast = $contrastf/" "$CONFIG_FILE" || echo "dpxContrast = $contrastf" >> "$CONFIG_FILE"
                show_info "✓ DPX mis à jour\nSaturation: $satf | Gamma: $gammaf | Contraste: $contrastf"
            fi
        fi
    fi
}
configure_lumasharpen() {
    local strength=$(grep "^lumaSharpenStrength" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local clamp=$(grep "^lumaSharpenClamp" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local sv=22; [ ! -z "$strength" ] && sv=$(awk "BEGIN {printf \"%.0f\", $strength * 100 / 3.0}")
    local s=$(zenity --scale --title="LumaSharpen - Force" --text="Valeur actuelle: ${strength:-0.65}" --min-value=0 --max-value=100 --value=$sv --step=5)
    if [ ! -z "$s" ]; then
        local sf=$(awk "BEGIN {printf \"%.2f\", $s * 3.0 / 100}")
        local cv=4; [ ! -z "$clamp" ] && cv=$(awk "BEGIN {printf \"%.0f\", $clamp * 100}")
        local c=$(zenity --scale --title="LumaSharpen - Clamp" --text="Valeur actuelle: ${clamp:-0.035}" --min-value=0 --max-value=100 --value=$cv --step=1)
        if [ ! -z "$c" ]; then
            local cf=$(awk "BEGIN {printf \"%.3f\", $c / 100}")
            create_backup
            grep -q "^lumaSharpenStrength" "$CONFIG_FILE" && sed -i "s/^lumaSharpenStrength.*/lumaSharpenStrength = $sf/" "$CONFIG_FILE" || echo "lumaSharpenStrength = $sf" >> "$CONFIG_FILE"
            grep -q "^lumaSharpenClamp" "$CONFIG_FILE" && sed -i "s/^lumaSharpenClamp.*/lumaSharpenClamp = $cf/" "$CONFIG_FILE" || echo "lumaSharpenClamp = $cf" >> "$CONFIG_FILE"
            show_info "✓ LumaSharpen mis à jour\nForce: $sf | Clamp: $cf"
        fi
    fi
}
configure_clarity() {
    local radius=$(grep "^clarityRadius" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local offset=$(grep "^clarityOffset" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local strength=$(grep "^clarityStrength" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local rv=29; [ ! -z "$radius" ] && rv=$(awk "BEGIN {printf \"%.0f\", ($radius - 1) * 100 / 7}")
    local r=$(zenity --scale --title="Clarity - Radius" --text="Valeur actuelle: ${radius:-3}" --min-value=0 --max-value=100 --value=$rv --step=14)
    if [ ! -z "$r" ]; then
        local rf=$(awk "BEGIN {printf \"%.0f\", 1 + ($r * 7 / 100)}")
        local ov=20; [ ! -z "$offset" ] && ov=$(awk "BEGIN {printf \"%.0f\", $offset * 10}")
        local o=$(zenity --scale --title="Clarity - Offset" --text="Valeur actuelle: ${offset:-2.0}" --min-value=0 --max-value=100 --value=$ov --step=5)
        if [ ! -z "$o" ]; then
            local of=$(awk "BEGIN {printf \"%.1f\", $o / 10}")
            local sv=40; [ ! -z "$strength" ] && sv=$(awk "BEGIN {printf \"%.0f\", $strength * 100}")
            local s=$(zenity --scale --title="Clarity - Force" --text="Valeur actuelle: ${strength:-0.4}" --min-value=0 --max-value=100 --value=$sv --step=5)
            if [ ! -z "$s" ]; then
                local sf=$(awk "BEGIN {printf \"%.2f\", $s / 100}")
                create_backup
                grep -q "^clarityRadius" "$CONFIG_FILE" && sed -i "s/^clarityRadius.*/clarityRadius = $rf/" "$CONFIG_FILE" || echo "clarityRadius = $rf" >> "$CONFIG_FILE"
                grep -q "^clarityOffset" "$CONFIG_FILE" && sed -i "s/^clarityOffset.*/clarityOffset = $of/" "$CONFIG_FILE" || echo "clarityOffset = $of" >> "$CONFIG_FILE"
                grep -q "^clarityStrength" "$CONFIG_FILE" && sed -i "s/^clarityStrength.*/clarityStrength = $sf/" "$CONFIG_FILE" || echo "clarityStrength = $sf" >> "$CONFIG_FILE"
                show_info "✓ Clarity mis à jour\nRadius: $rf | Offset: $of | Force: $sf"
            fi
        fi
    fi
}
configure_vibrance() {
    local strength=$(grep "^vibranceStrength" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local sv=58; [ ! -z "$strength" ] && sv=$(awk "BEGIN {printf \"%.0f\", ($strength + 1.0) * 100 / 2.0}")
    local s=$(zenity --scale --title="Vibrance - Force" --text="Valeur actuelle: ${strength:-0.15}" --min-value=0 --max-value=100 --value=$sv --step=5)
    if [ ! -z "$s" ]; then
        local sf=$(awk "BEGIN {printf \"%.2f\", -1.0 + ($s * 2.0 / 100)}")
        create_backup
        grep -q "^vibranceStrength" "$CONFIG_FILE" && sed -i "s/^vibranceStrength.*/vibranceStrength = $sf/" "$CONFIG_FILE" || echo "vibranceStrength = $sf" >> "$CONFIG_FILE"
        show_info "✓ Vibrance mise à jour\nForce: $sf"
    fi
}

show_current_config() {
    [ -f "$CONFIG_FILE" ] && zenity --text-info --title="Configuration actuelle" --filename="$CONFIG_FILE" --width=600 --height=400 \
        || show_error "❌ Fichier de configuration non trouvé"
}
show_backup_menu() {
    local choice=$(zenity --list --title="Gestion des sauvegardes" --text="Options de sauvegarde :" --column="Action" --column="Description" --width=500 --height=300 \
        "Créer" "Créer une sauvegarde" "Restaurer" "Restaurer depuis la sauvegarde" "Supprimer" "Supprimer la sauvegarde" 2>/dev/null)
    case "$choice" in
        "Créer") create_backup; show_info "✓ Sauvegarde créée" ;;
        "Restaurer") restore_backup ;;
        "Supprimer") delete_backup ;;
    esac
}
show_usage() {
    zenity --info --title="Comment utiliser VkBasalt" --text="🎮 VkBasalt est installé et prêt à utiliser !
═══ Activation dans les jeux Steam ═══

1. Ouvrez Steam en mode Bureau
2. Clic droit sur votre jeu → Propriétés
3. Dans les options de lancement, ajoutez :
   ENABLE_VKBASALT=1 %command%
4. Lancez le jeu
5. Utilisez la touche Home pour activer/désactiver

═══ Shaders disponibles ═══
• CAS - Netteté adaptative AMD
• FXAA - Anti-aliasing rapide
• SMAA - Anti-aliasing haute qualité
• LumaSharpen - Netteté luminance
• Vibrance - Saturation intelligente
• DPX - Look cinéma professionnel
• Clarity - Clarté et détails

═══ Configuration actuelle ═══
Fichier: $CONFIG_FILE
Shaders: $SHADER_PATH
Textures: $TEXTURE_PATH

⚠️  VkBasalt ne fonctionne qu'avec les jeux Vulkan
🎯 Touche de basculement configurable dans le menu Configuration → Touche" --width=650 --height=500
}

main() {
    check_zenity
    while true; do show_main_menu; [ $? -ne 0 ] && exit 0; done
}

main
SCRIPT_EOF

echo "🎨 Création de l'icône..."
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
    <filter id="heatWave">
      <feTurbulence baseFrequency="0.02" numOctaves="3" result="noise"/>
      <feDisplacementMap in="SourceGraphic" in2="noise" scale="2"/>
    </filter>
    <filter id="bubble" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="1" result="blur"/>
      <feOffset dx="1" dy="1" result="offset"/>
      <feMerge>
        <feMergeNode in="offset"/>
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
  <g transform="translate(64,64)" filter="url(#moltenGlow)">
    <path d="M-20,-15 Q-10,0 0,10 Q8,20 15,30"
          stroke="url(#crackGrad)" stroke-width="3" fill="none" opacity="0.9"/>
    <path d="M-30,-5 Q-15,5 -5,8"
          stroke="url(#crackGrad)" stroke-width="2" fill="none" opacity="0.8"/>
    <path d="M10,-20 Q18,-5 25,5"
          stroke="url(#crackGrad)" stroke-width="2" fill="none" opacity="0.8"/>
    <path d="M-25,10 Q-15,18 -8,25"
          stroke="url(#crackGrad)" stroke-width="1.5" fill="none" opacity="0.7"/>
    <path d="M5,15 Q15,25 22,30"
          stroke="url(#crackGrad)" stroke-width="1.5" fill="none" opacity="0.7"/>
    <path d="M-35,-8 L-25,-10" stroke="#ff4500" stroke-width="1" opacity="0.6"/>
    <path d="M30,-15 L35,-12" stroke="#ff4500" stroke-width="1" opacity="0.6"/>
    <path d="M-32,20 L-28,25" stroke="#ff4500" stroke-width="1" opacity="0.6"/>
  </g>
  <g transform="translate(64,64)">
    <ellipse cx="0" cy="15" rx="12" ry="8" fill="url(#lavaGrad)" filter="url(#bubble)" opacity="0.9"/>
    <circle cx="-18" cy="-8" r="4" fill="url(#lavaGrad)" filter="url(#bubble)" opacity="0.8"/>
    <ellipse cx="22" cy="-5" rx="5" ry="3" fill="url(#lavaGrad)" filter="url(#bubble)" opacity="0.8"/>
    <circle cx="-8" cy="25" r="3" fill="url(#lavaGrad)" filter="url(#bubble)" opacity="0.7"/>
    <ellipse cx="18" cy="20" rx="4" ry="2" fill="url(#lavaGrad)" filter="url(#bubble)" opacity="0.7"/>
  </g>
  <g opacity="0.4" filter="url(#heatWave)">
    <path d="M25,35 Q35,25 45,35 Q55,45 65,35 Q75,25 85,35"
          stroke="#ff6600" stroke-width="1" fill="none" opacity="0.3"/>
    <path d="M20,45 Q30,35 40,45 Q50,55 60,45 Q70,35 80,45"
          stroke="#ff8800" stroke-width="1" fill="none" opacity="0.3"/>
    <path d="M30,55 Q40,45 50,55 Q60,65 70,55 Q80,45 90,55"
          stroke="#ffaa00" stroke-width="1" fill="none" opacity="0.3"/>
  </g>
  <g opacity="0.8">
    <circle cx="95" cy="25" r="1" fill="#ffff00" filter="url(#moltenGlow)"/>
    <circle cx="105" cy="35" r="0.8" fill="#ff8c00" filter="url(#moltenGlow)"/>
    <circle cx="88" cy="45" r="1.2" fill="#ff4500" filter="url(#moltenGlow)"/>
    <circle cx="25" cy="15" r="0.6" fill="#ffff66" filter="url(#moltenGlow)"/>
    <circle cx="15" cy="25" r="0.8" fill="#ff6600" filter="url(#moltenGlow)"/>
    <circle cx="35" cy="40" r="0.7" fill="#ffaa00" filter="url(#moltenGlow)"/>
    <circle cx="75" cy="20" r="0.9" fill="#ff4500" filter="url(#moltenGlow)"/>
  </g>
</svg>
ICON_EOF

echo "🖥️ Création du fichier .desktop..."
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=VkBasalt Manager
Comment=Gestionnaire VkBasalt pour Steam Deck avec interface graphique
Comment[en]=VkBasalt Manager for Steam Deck with GUI
Exec=$SCRIPT_PATH
Icon=$ICON_PATH
Terminal=false
StartupNotify=true
NoDisplay=false
StartupWMClass=zenity
MimeType=
EOF

echo "🔧 Configuration des permissions..."
chmod +x "$SCRIPT_PATH"
chmod +x "$DESKTOP_FILE"
chown deck:deck "$SCRIPT_PATH" "$ICON_PATH" "$DESKTOP_FILE" 2>/dev/null || true

if command -v gio &> /dev/null; then
    gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null || true
fi
if command -v dconf &> /dev/null; then
    dconf write /org/gnome/nautilus/preferences/executable-text-activation "'launch'" 2>/dev/null || true
fi

echo
echo "✅ VkBasalt, shaders, configuration et manager graphique installés !"
echo "   Double-clique sur l'icône VkBasalt Manager sur le bureau pour configurer."
echo

exit 0
