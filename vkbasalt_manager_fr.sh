#!/bin/bash

USER_HOME="/home/deck"
SYSTEM_USER="deck"

CONFIG_FILE="${USER_HOME}/.config/vkBasalt/vkBasalt.conf"
SHADER_PATH="${USER_HOME}/.config/reshade/Shaders"
TEXTURE_PATH="${USER_HOME}/.config/reshade/Textures"
SCRIPT_PATH="${USER_HOME}/.config/vkBasalt/vkbasalt-manager.sh"
ICON_PATH="${USER_HOME}/.config/vkBasalt/vkbasalt-manager.svg"
DESKTOP_FILE="${USER_HOME}/Desktop/VkBasalt-Manager.desktop"

mkdir -p "${USER_HOME}/Desktop"

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
        if command -v steamos-readonly &> /dev/null; then
            sudo steamos-readonly disable 2>/dev/null || true
        fi

        sudo pacman -S --noconfirm "${missing_deps[@]}"

        if command -v steamos-readonly &> /dev/null; then
            sudo steamos-readonly enable 2>/dev/null || true
        fi
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

    if ! wget -q "${AUR_BASE}${VKBASALT_PKG}" -O "${VKBASALT_PKG_FILE}"; then
        rm -f "${VKBASALT_PKG_FILE}" "${VKBASALT_LIB32_PKG_FILE}"
        return 1
    fi

    if ! wget -q "${AUR_BASE}${VKBASALT_LIB32_PKG}" -O "${VKBASALT_LIB32_PKG_FILE}"; then
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

    return 0
}

install_vkbasalt_complete() {
    show_info "🚀 Installation du Gestionnaire VkBasalt\n\nInstallation sur : Steam Deck\n\nL'installation va télécharger et installer :\n• VkBasalt\n• Shaders essentiels\n• Configurations par défaut\n• Interface graphique\n\nCela peut prendre quelques minutes..."

    (
        echo "10" ; echo "# Vérification du système..."
        mkdir -p "${USER_HOME}/Desktop" "${USER_HOME}/.config/vkBasalt" "${USER_HOME}/.config/reshade" 2>/dev/null || true

        echo "20" ; echo "# Vérification des dépendances..."
        check_dependencies 2>&1

        echo "30" ; echo "# Installation du noyau VkBasalt..."
        if ! install_vkbasalt 2>&1; then
            echo "100" ; echo "# Échec de l'installation VkBasalt"
            exit 1
        fi

        echo "70" ; echo "# Téléchargement des shaders essentiels..."
        local TMPDIR=$(mktemp -d)
        cd "$TMPDIR"
        if wget -q --timeout=30 https://github.com/Vaddum/vkbasalt-manager/archive/refs/heads/main.zip 2>/dev/null; then
            if unzip -q main.zip 2>/dev/null && [ -d "vkbasalt-manager-main/reshade" ]; then
                mkdir -p "${USER_HOME}/.config/reshade/Shaders"
                mkdir -p "${USER_HOME}/.config/reshade/Textures"

                for shader in lumasharpen.fx vibrance.fx clarity.fx dpx.fx adaptivesharpen.fx; do
                    if [ -f "vkbasalt-manager-main/reshade/Shaders/$shader" ]; then
                        cp "vkbasalt-manager-main/reshade/Shaders/$shader" "${USER_HOME}/.config/reshade/Shaders/" 2>/dev/null || true
                    fi
                done

                if [ -d "vkbasalt-manager-main/reshade/Textures" ]; then
                    cp -rf vkbasalt-manager-main/reshade/Textures/* "${USER_HOME}/.config/reshade/Textures/" 2>/dev/null || true
                fi
            fi
        fi
        cd "${USER_HOME}" && rm -rf "$TMPDIR"

        echo "80" ; echo "# Création de la configuration par défaut..."
        create_default_config

        echo "85" ; echo "# Configuration de l'interface du gestionnaire..."
        move_script_to_final_location

        echo "90" ; echo "# Création de l'icône du bureau..."
        create_icon_and_desktop

        echo "95" ; echo "# Définition des permissions..."
        chmod +x "$SCRIPT_PATH" "$DESKTOP_FILE" 2>/dev/null || true
        chown "${SYSTEM_USER}:${SYSTEM_USER}" "$SCRIPT_PATH" "$ICON_PATH" "$DESKTOP_FILE" 2>/dev/null || true

        echo "100" ; echo "# Installation terminée !"

    ) | zenity --progress --title="Installation du Gestionnaire VkBasalt" --text="Préparation..." --percentage=0 --auto-close --width=420 --height=110

    if [ $? -eq 0 ] && [ -f "${USER_HOME}/.local/lib/libvkbasalt.so" ] && [ -f "${USER_HOME}/.local/lib32/libvkbasalt.so" ]; then
        local script_moved_msg=""
        if [ "$(realpath "$0")" != "$SCRIPT_PATH" ]; then
            script_moved_msg="\n\n📁 Le script a été déplacé vers : $SCRIPT_PATH\n💡 Vous pouvez maintenant supprimer le fichier de script original."
        fi

        show_info "✅ Installation réussie !$script_moved_msg\n\nLe Gestionnaire VkBasalt est maintenant installé et prêt à être utilisé.\n\n🔧 Utilisez ce gestionnaire pour configurer les effets et paramètres."
        return 0
    else
        show_error "❌ Échec de l'installation !\n\nCauses possibles :\n• Problèmes de connexion réseau\n• Dépendances manquantes\n• Permissions insuffisantes\n\nVeuillez vérifier votre connexion Internet et réessayer."
        return 1
    fi
}

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

    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Gestionnaire VkBasalt
Comment=Gestionnaire VkBasalt avec interface graphique pour Steam Deck
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
    if show_question "🗑️ Désinstaller VkBasalt ?\n\n⚠️ ATTENTION : Cela va supprimer TOUT :\n• Gestionnaire VkBasalt\n• VkBasalt lui-même\n• Toutes les configurations\n• Tous les shaders\n\nCette action est IRRÉVERSIBLE !\n\nContinuer ?"; then
        (
            echo "10" ; echo "# Suppression du Gestionnaire VkBasalt..."
            rm -f "$SCRIPT_PATH" "$ICON_PATH" "$DESKTOP_FILE"

            echo "30" ; echo "# Suppression de VkBasalt..."
            rm -f "${USER_HOME}/.local/lib/libvkbasalt.so" "${USER_HOME}/.local/lib32/libvkbasalt.so"
            rm -f "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.json" "${USER_HOME}/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json"

            echo "60" ; echo "# Suppression des configurations..."
            rm -rf "${USER_HOME}/.config/vkBasalt"

            echo "80" ; echo "# Suppression des shaders..."
            rm -rf "${USER_HOME}/.config/reshade"

            echo "90" ; echo "# Nettoyage des répertoires..."
            rmdir "${USER_HOME}/.local/share/vulkan/implicit_layer.d" "${USER_HOME}/.local/share/vulkan" "${USER_HOME}/.local/lib32" 2>/dev/null || true

            echo "100" ; echo "# Désinstallation terminée"
        ) | zenity --progress --title="Désinstallation" --text="Suppression de tous les composants..." --percentage=0 --auto-close --width=420 --height=110

        show_info "✅ Désinstallation terminée !\n\nVkBasalt a été complètement supprimé de votre Steam Deck."
        exit 0
    fi
}

get_shader_description() {
    case "$1" in
        "cas"|"CAS") echo "🔵 Netteté Adaptative AMD - Améliore les détails sans artefacts (Intégré)" ;;
        "fxaa"|"FXAA") echo "🔵 Anti-Aliasing Rapide - Lisse les bords dentelés rapidement (Intégré)" ;;
        "smaa"|"SMAA") echo "🔵 Anti-Aliasing Haute Qualité - Meilleur que FXAA (Intégré)" ;;
        "dls"|"DLS") echo "🔵 Netteté Débruitée Luma - Netteté intelligente sans bruit (Intégré)" ;;
        "adaptivesharpen"|"AdaptiveSharpen") echo "🟠 Netteté Adaptative - Netteté sensible aux contours" ;;
        "clarity"|"Clarity") echo "🟠 Clarity - Netteté avancée avec masquage de flou" ;;
        "dpx"|"DPX") echo "🟠 DPX - Effet de correction colorimétrique style cinéma" ;;
        "lumasharpen"|"LumaSharpen") echo "🟢 LumaSharpen - Shader d'amélioration des détails le plus populaire" ;;
        "vibrance"|"Vibrance") echo "🟢 Vibrance - Outil essentiel d'amélioration des couleurs" ;;


        *) echo "$1 - Effet graphique disponible" ;;
    esac
}

get_display_name() {
    case "${1,,}" in
        "cas") echo "CAS" ;;
        "fxaa") echo "FXAA" ;;
        "smaa") echo "SMAA" ;;
        "dls") echo "DLS" ;;
        "adaptivesharpen") echo "NettetéAdaptative" ;;
        "clarity") echo "Clarity" ;;
        "dpx") echo "DPX" ;;
        "lumasharpen") echo "LumaSharpen" ;;
        "vibrance") echo "Vibrance" ;;
        *) echo "$1" ;;
    esac
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

    local essential_shaders=("LumaSharpen" "Vibrance" "Clarity" "AdaptiveSharpen" "DPX")
    if [ -d "$SHADER_PATH" ]; then
        for shader_name in "${essential_shaders[@]}"; do
            local shader_file=""
            for variation in "${shader_name}" "${shader_name,,}" "${shader_name^^}"; do
                if [ -f "$SHADER_PATH/$variation.fx" ]; then
                    shader_file="$SHADER_PATH/$variation.fx"
                    break
                fi
            done

            if [ ! -z "$shader_file" ]; then
                local enabled="FALSE"
                is_effect_enabled "${shader_name}" && enabled="TRUE"
                local display_name=$(get_display_name "$shader_name")
                local description=$(get_shader_description "$shader_name")
                checklist_items+=("$enabled" "$display_name" "$description")
            fi
        done
    fi

    if [ ${#checklist_items[@]} -eq 0 ]; then
        show_error "Aucun effet disponible"
        return
    fi

    local selected_shaders
    selected_shaders=$(zenity --list --title="Sélection des Effets VkBasalt" --text="Sélectionnez les effets à activer (Ctrl+Clic pour sélection multiple) :" --checklist --column="Activer" --column="Effet" --column="Description" --width=900 --height=400 --separator=":" "${checklist_items[@]}" 2>/dev/null)

    if [ $? -eq 0 ]; then
        if [ -z "$selected_shaders" ]; then
            if show_question "Aucun effet sélectionné. Désactiver tous les effets ?"; then
                create_minimal_config
                show_info "Tous les effets désactivés"
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
                    "DPX") config_name="dpx" ;;
                    "Clarity") config_name="clarity" ;;
                    "LumaSharpen") config_name="lumasharpen" ;;
                    "NettetéAdaptative") config_name="adaptivesharpen" ;;
                    "Vibrance") config_name="vibrance" ;;
                    *) config_name="${display_shader,,}" ;;
                esac

                if [ -z "$config_shaders" ]; then
                    config_shaders="$config_name"
                else
                    config_shaders="$config_shaders:$config_name"
                fi
            done

            create_dynamic_config "$config_shaders"
            show_info "Configuration mise à jour avec les effets : $selected_shaders"
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

show_main_menu() {
    check_installation
    local install_status=$?

    if [ $install_status -eq 0 ]; then
        if show_question "🚀 Gestionnaire VkBasalt - Première utilisation\n\nVkBasalt n'est pas encore installé !\n\nSouhaitez-vous procéder à l'installation automatique ?"; then
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
        show_info "🔧 Création de la configuration par défaut..."
        create_default_config
        show_info "✅ Configuration par défaut créée ! VkBasalt est prêt avec CAS."
    fi

    while true; do
        local shader_count=0
        local builtin_count=4
        local external_count=0

        if [ -d "$SHADER_PATH" ] && [ "$(ls -A $SHADER_PATH 2>/dev/null)" ]; then
            local essential_shaders=("LumaSharpen" "Vibrance" "Clarity" "AdaptiveSharpen" "DPX")
            for shader_name in "${essential_shaders[@]}"; do
                for variation in "${shader_name}" "${shader_name,,}" "${shader_name^^}"; do
                    if [ -f "$SHADER_PATH/$variation.fx" ]; then
                        external_count=$((external_count + 1))
                        break
                    fi
                done
            done
        fi

        shader_count=$((builtin_count + external_count))

        local status_text=""
        if [ $external_count -gt 0 ]; then
            status_text="VkBasalt prêt ! ($shader_count shaders : $builtin_count intégrés + $external_count essentiels)"
        else
            status_text="VkBasalt prêt ! ($builtin_count shaders intégrés disponibles)"
        fi

        local active_effects=""
        if [ -f "$CONFIG_FILE" ]; then
            active_effects=$(grep "^effects" "$CONFIG_FILE" | head -n1 | cut -d'=' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            if [ ! -z "$active_effects" ] && [ "$active_effects" != "" ]; then
                local effect_count=$(echo "$active_effects" | tr ':' '\n' | wc -l)
                status_text="$status_text • $effect_count effets actifs"
            else
                status_text="$status_text • Aucun effet actif"
            fi
        fi

        local choice=$(zenity --list --title="Gestionnaire VkBasalt" --text="$status_text" --column="Option" --column="Description" --width=420 --height=320 \
            "Shaders" "Gérer les shaders actifs" \
            "Touche" "Changer la touche de basculement" \
            "Avancé" "Paramètres avancés des shaders" \
            "Config" "Voir la configuration actuelle" \
            "Réinitialiser" "Remettre aux valeurs par défaut" \
            "Désinstaller" "Désinstaller VkBasalt" \
            "Quitter" "Quitter le Gestionnaire VkBasalt" \
            2>/dev/null)

        case "$choice" in
            "Shaders") manage_shaders ;;
            "Touche") change_toggle_key ;;
            "Avancé") show_advanced_menu ;;
            "Config")
                if [ -f "$CONFIG_FILE" ]; then
                    zenity --text-info --title="Configuration Actuelle" --filename="$CONFIG_FILE" --width=560 --height=340 2>/dev/null
                else
                    show_error "Fichier de configuration introuvable"
                fi
                ;;
            "Réinitialiser")
                if show_question "⚠️ Réinitialiser la configuration aux valeurs par défaut ?"; then
                    create_default_config
                    show_info "Configuration réinitialisée aux valeurs par défaut"
                fi
                ;;
            "Désinstaller") uninstall_vkbasalt ;;
            "Quitter"|"") exit 0 ;;
        esac
    done
}

show_advanced_menu() {
    local choice=$(zenity --list \
        --title="Paramètres Avancés - Effets VkBasalt Intégrés" \
        --text="Configurer les effets VkBasalt intégrés :" \
        --column="Effet" --column="Description" \
        --width=500 --height=300 \
        "CAS" "Netteté Adaptative au Contraste - AMD FidelityFX" \
        "FXAA" "Anti-Aliasing Approximatif Rapide" \
        "SMAA" "Anti-Aliasing Morphologique Sous-Pixel" \
        "DLS" "Netteté Luma Débruitée - Netteté intelligente" \
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
        --title="Changer la Touche de Basculement" \
        --text="Touche actuelle : ${current_key:-Home}\n\nChoisissez une nouvelle touche pour activer/désactiver les effets VkBasalt :" \
        --column="Touche" \
        --column="Description" \
        --width=350 \
        --height=540 \
        "Home" "Touche Début (recommandée)" \
        "End" "Touche Fin" \
        "Insert" "Touche Insertion" \
        "Delete" "Touche Supprimer" \
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
        "Print" "Impr. Écran" \
        "Scroll_Lock" "Arrêt Défil" \
        "Pause" "Pause" \
        "Menu" "Touche Menu Contextuel" \
        "Tab" "Tabulation" \
        "Caps_Lock" "Verr. Maj" \
        "Num_Lock" "Verr. Num" \
        2>/dev/null)

    if [ ! -z "$new_key" ]; then
        sed -i "s/^toggleKey.*/toggleKey = $new_key/" "$CONFIG_FILE"
        show_info "Touche de basculement changée : $new_key\n\nUtilisez maintenant la touche '$new_key' pour activer/désactiver les effets VkBasalt dans vos jeux."
    fi
}

configure_cas() {
    local cur=$(grep "^casSharpness" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local val=50; [ ! -z "$cur" ] && val=$(awk "BEGIN {printf \"%.0f\", $cur * 100}")
    local sharpness=$(zenity --scale --title="CAS - Netteté Adaptative au Contraste" \
        --text="Ajuster l'intensité de la netteté\nValeur actuelle : ${cur:-0.5}\n\n0 = Aucune netteté\n100 = Netteté maximale" \
        --min-value=0 --max-value=100 --value=$val --step=5)
    if [ ! -z "$sharpness" ]; then
        local v=$(awk "BEGIN {printf \"%.2f\", $sharpness / 100}")
        grep -q "^casSharpness" "$CONFIG_FILE" && sed -i "s/^casSharpness.*/casSharpness = $v/" "$CONFIG_FILE" || echo "casSharpness = $v" >> "$CONFIG_FILE"
        show_info "Netteté CAS ajustée à : $v ($sharpness%)"
    fi
}

configure_fxaa() {
    local subpix=$(grep "^fxaaQualitySubpix" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local edge=$(grep "^fxaaQualityEdgeThreshold" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')

    local s=75; [ ! -z "$subpix" ] && s=$(awk "BEGIN {printf \"%.0f\", $subpix * 100}")
    local sp=$(zenity --scale --title="FXAA - Qualité Sous-Pixel" \
        --text="Ajuster la réduction de l'aliasing sous-pixel\nValeur actuelle : ${subpix:-0.75}\n\n0 = Aucun AA sous-pixel\n100 = AA sous-pixel maximal" \
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

        local ed=$(zenity --scale --title="FXAA - Seuil de Détection des Contours" \
            --text="Ajuster la sensibilité de détection des contours\nValeur actuelle : ${edge:-0.125}\n\n0 = Détecter tous les contours (plus doux)\n100 = Détecter seulement les contours nets (plus net)" \
            --min-value=0 --max-value=100 --value=$e --step=5)
        if [ ! -z "$ed" ]; then
            local edf=$(awk "BEGIN {printf \"%.3f\", 0.063 + ($ed * 0.27 / 100)}")
            grep -q "^fxaaQualitySubpix" "$CONFIG_FILE" && sed -i "s/^fxaaQualitySubpix.*/fxaaQualitySubpix = $spf/" "$CONFIG_FILE" || echo "fxaaQualitySubpix = $spf" >> "$CONFIG_FILE"
            grep -q "^fxaaQualityEdgeThreshold" "$CONFIG_FILE" && sed -i "s/^fxaaQualityEdgeThreshold.*/fxaaQualityEdgeThreshold = $edf/" "$CONFIG_FILE" || echo "fxaaQualityEdgeThreshold = $edf" >> "$CONFIG_FILE"
            show_info "Paramètres FXAA mis à jour\nQualité Sous-Pixel : $spf\nSeuil de Contour : $edf"
        fi
    fi
}

configure_smaa() {
    local thresh=$(grep "^smaaThreshold" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local steps=$(grep "^smaaMaxSearchSteps" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')

    local edge_detection=$(zenity --list --title="SMAA - Méthode de Détection des Contours" \
        --text="Choisir la méthode de détection des contours :" \
        --column="Mode" --column="Description" \
        --width=520 --height=280 \
        "luma" "Basé sur la luminance (recommandé)" \
        "color" "Basé sur la couleur (plus précis)" \
        "depth" "Basé sur la profondeur (pour jeux 3D)" \
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

        local th=$(zenity --scale --title="SMAA - Seuil de Détection des Contours" \
            --text="Ajuster la sensibilité de détection des contours\nValeur actuelle : ${thresh:-0.05}\n\n0 = Détecter tous les contours (plus doux)\n100 = Détecter seulement les contours nets (plus net)" \
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

            local st=$(zenity --scale --title="SMAA - Étapes de Recherche Maximales" \
                --text="Ajuster la qualité de recherche vs performance\nValeur actuelle : ${steps:-32}\n\n0 = Plus rapide (qualité inférieure)\n100 = Plus lent (qualité supérieure)" \
                --min-value=0 --max-value=100 --value=$s --step=5)

            if [ ! -z "$st" ]; then
                local stf=$(awk "BEGIN {printf \"%.0f\", 8 + ($st * 56 / 100)}")
                grep -q "^smaaEdgeDetection" "$CONFIG_FILE" && sed -i "s/^smaaEdgeDetection.*/smaaEdgeDetection = $edge_detection/" "$CONFIG_FILE" || echo "smaaEdgeDetection = $edge_detection" >> "$CONFIG_FILE"
                grep -q "^smaaThreshold" "$CONFIG_FILE" && sed -i "s/^smaaThreshold.*/smaaThreshold = $thf/" "$CONFIG_FILE" || echo "smaaThreshold = $thf" >> "$CONFIG_FILE"
                grep -q "^smaaMaxSearchSteps" "$CONFIG_FILE" && sed -i "s/^smaaMaxSearchSteps.*/smaaMaxSearchSteps = $stf/" "$CONFIG_FILE" || echo "smaaMaxSearchSteps = $stf" >> "$CONFIG_FILE"
                show_info "Paramètres SMAA mis à jour\nDétection de Contour : $edge_detection\nSeuil : $thf\nÉtapes de Recherche Max : $stf"
            fi
        fi
    fi
}

configure_dls() {
    local sharpening=$(grep "^dlsSharpening" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
    local denoise=$(grep "^dlsDenoise" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')

    local sv=50; [ ! -z "$sharpening" ] && sv=$(awk "BEGIN {printf \"%.0f\", $sharpening * 100}")
    local s=$(zenity --scale --title="DLS - Intensité de la Netteté" \
        --text="Ajuster l'intensité de la netteté\nValeur actuelle : ${sharpening:-0.5}\n\n0 = Aucune netteté\n100 = Netteté maximale" \
        --min-value=0 --max-value=100 --value=$sv --step=5)

    if [ ! -z "$s" ]; then
        local sf=$(awk "BEGIN {printf \"%.2f\", $s / 100}")

        local dv=20; [ ! -z "$denoise" ] && dv=$(awk "BEGIN {printf \"%.0f\", $denoise * 100}")
        local d=$(zenity --scale --title="DLS - Intensité du Débruitage" \
            --text="Ajuster la réduction du bruit\nValeur actuelle : ${denoise:-0.20}\n\n0 = Aucun débruitage\n100 = Débruitage maximal" \
            --min-value=0 --max-value=100 --value=$dv --step=5)

        if [ ! -z "$d" ]; then
            local df=$(awk "BEGIN {printf \"%.2f\", $d / 100}")
            grep -q "^dlsSharpening" "$CONFIG_FILE" && sed -i "s/^dlsSharpening.*/dlsSharpening = $sf/" "$CONFIG_FILE" || echo "dlsSharpening = $sf" >> "$CONFIG_FILE"
            grep -q "^dlsDenoise" "$CONFIG_FILE" && sed -i "s/^dlsDenoise.*/dlsDenoise = $df/" "$CONFIG_FILE" || echo "dlsDenoise = $df" >> "$CONFIG_FILE"
            show_info "Paramètres DLS mis à jour\nNetteté : $sf\nDébruitage : $df"
        fi
    fi
}

validate_config_values() {
    if [ ! -f "$CONFIG_FILE" ]; then
        return
    fi

    local needs_update=false

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
            needs_update=true
        fi
    fi

    if [ "$needs_update" = true ]; then
        show_info "⚠️ Les valeurs de configuration ont été automatiquement corrigées dans les plages valides."
    fi
}

main() {
    check_dependencies
    show_main_menu
}

main
