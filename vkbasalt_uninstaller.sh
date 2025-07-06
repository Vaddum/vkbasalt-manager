#!/bin/bash

# VkBasalt Manager - Désinstallateur complet
# Supprime VkBasalt Manager et optionnellement VkBasalt lui-même

echo "🗑️ Désinstallateur VkBasalt Manager pour Steam Deck"
echo "================================================="
echo

# Vérifier si on est sur Steam Deck
if [ ! -d "/home/deck" ]; then
    echo "❌ Ce script est conçu pour Steam Deck (/home/deck introuvable)"
    exit 1
fi

# Vérifier si zenity est disponible, sinon utiliser des prompts basiques
if command -v zenity &> /dev/null; then
    USE_ZENITY=true
else
    USE_ZENITY=false
    echo "ℹ️ Zenity non disponible, utilisation de l'interface texte"
fi

# Fonctions d'interface
show_question() {
    local message="$1"
    if [ "$USE_ZENITY" = true ]; then
        zenity --question --text="$message" --width=450
    else
        echo "$message"
        read -p "Continuer ? (y/N): " response
        [[ "$response" =~ ^[Yy]$ ]]
    fi
}

show_info() {
    local message="$1"
    if [ "$USE_ZENITY" = true ]; then
        zenity --info --text="$message" --width=400
    else
        echo "$message"
        read -p "Appuyez sur Entrée pour continuer..."
    fi
}

show_error() {
    local message="$1"
    if [ "$USE_ZENITY" = true ]; then
        zenity --error --text="$message" --width=400
    else
        echo "❌ $message"
    fi
}

show_progress() {
    local title="$1"
    local text="$2"
    if [ "$USE_ZENITY" = true ]; then
        (
            echo "10" ; sleep 0.5
            echo "# $text..." ; sleep 0.5
            echo "30" ; sleep 0.5
            echo "# Suppression en cours..." ; sleep 0.5
            echo "60" ; sleep 0.5
            echo "# Nettoyage..." ; sleep 0.5
            echo "90" ; sleep 0.5
            echo "# Finalisation..." ; sleep 0.5
            echo "100" ; sleep 0.5
        ) | zenity --progress \
            --title="$title" \
            --text="$text" \
            --percentage=0 \
            --auto-close \
            --width=400
    else
        echo "⏳ $text..."
    fi
}

# Détecter les composants installés
detect_components() {
    echo "🔍 Détection des composants installés..."

    # VkBasalt Manager
    MANAGER_SCRIPT="/home/deck/.config/vkBasalt/VkBasalt-Manager.sh"
    MANAGER_ICON="/home/deck/.config/vkBasalt/vkbasalt-manager.svg"
    MANAGER_DESKTOP="/home/deck/Desktop/VkBasalt-Manager.desktop"
    MANAGER_CONFIG_DIR="/home/deck/.config/vkBasalt"

    # VkBasalt lui-même
    VKBASALT_LIB64="/home/deck/.local/lib/libvkbasalt.so"
    VKBASALT_LIB32="/home/deck/.local/lib32/libvkbasalt.so"
    VKBASALT_LAYER64="/home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.json"
    VKBASALT_LAYER32="/home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt.x86.json"
    VKBASALT_CONFIG="/home/deck/.config/vkBasalt/vkBasalt.conf"
    VKBASALT_BACKUP="/home/deck/.config/vkBasalt/vkBasalt.conf.backup"
    RESHADE_DIR="/home/deck/.config/reshade"

    # Vérifications
    MANAGER_INSTALLED=false
    VKBASALT_INSTALLED=false

    if [ -f "$MANAGER_SCRIPT" ] || [ -f "$MANAGER_DESKTOP" ]; then
        MANAGER_INSTALLED=true
    fi

    if [ -f "$VKBASALT_LIB64" ] || [ -f "$VKBASALT_LIB32" ]; then
        VKBASALT_INSTALLED=true
    fi

    echo "   VkBasalt Manager: $( [ "$MANAGER_INSTALLED" = true ] && echo "✓ Installé" || echo "✗ Non trouvé" )"
    echo "   VkBasalt:         $( [ "$VKBASALT_INSTALLED" = true ] && echo "✓ Installé" || echo "✗ Non trouvé" )"
    echo
}

# Menu principal de désinstallation
show_uninstall_menu() {
    if [ "$USE_ZENITY" = true ]; then
        local choice=$(zenity --list \
            --title="Désinstallateur VkBasalt Manager" \
            --text="Que souhaitez-vous désinstaller ?\n\n⚠️ Choisissez l'option appropriée :" \
            --column="Option" \
            --column="Description" \
            --width=600 \
            --height=400 \
            "Manager" "Désinstaller seulement VkBasalt Manager (garder VkBasalt)" \
            "Complet" "Désinstaller VkBasalt Manager + VkBasalt + Shaders" \
            "Config" "Supprimer seulement les configurations/sauvegardes" \
            "Annuler" "Annuler la désinstallation" \
            2>/dev/null)

        case "$choice" in
            "Manager") return 1 ;;
            "Complet") return 2 ;;
            "Config") return 3 ;;
            *) return 0 ;;
        esac
    else
        echo "Que souhaitez-vous désinstaller ?"
        echo
        echo "1) VkBasalt Manager seulement (garder VkBasalt)"
        echo "2) Désinstallation complète (Manager + VkBasalt + Shaders)"
        echo "3) Configurations/sauvegardes seulement"
        echo "0) Annuler"
        echo
        read -p "Votre choix [0-3]: " choice

        case "$choice" in
            1) return 1 ;;
            2) return 2 ;;
            3) return 3 ;;
            *) return 0 ;;
        esac
    fi
}

# Désinstaller VkBasalt Manager seulement
uninstall_manager_only() {
    if show_question "🗑️ Désinstaller VkBasalt Manager uniquement ?\n\nCela supprimera :\n• Le script VkBasalt Manager\n• L'icône et raccourci bureau\n• MAIS gardera VkBasalt et ses configurations\n\nContinuer ?"; then

        show_progress "Désinstallation Manager" "Suppression de VkBasalt Manager"

        echo "📝 Suppression de VkBasalt Manager..."

        # Supprimer les fichiers du manager
        [ -f "$MANAGER_SCRIPT" ] && rm -f "$MANAGER_SCRIPT" && echo "   ✓ Script supprimé"
        [ -f "$MANAGER_ICON" ] && rm -f "$MANAGER_ICON" && echo "   ✓ Icône supprimée"
        [ -f "$MANAGER_DESKTOP" ] && rm -f "$MANAGER_DESKTOP" && echo "   ✓ Raccourci bureau supprimé"

        # Supprimer les anciens fichiers s'ils existent
        [ -f "/home/deck/Desktop/VkBasalt-Manager.sh" ] && rm -f "/home/deck/Desktop/VkBasalt-Manager.sh"
        [ -f "/home/deck/Desktop/vkbasalt-manager.svg" ] && rm -f "/home/deck/Desktop/vkbasalt-manager.svg"
        [ -f "/home/deck/.local/share/applications/VkBasalt-Manager.desktop" ] && rm -f "/home/deck/.local/share/applications/VkBasalt-Manager.desktop"

        echo "   ✓ Nettoyage terminé"

        show_info "✅ VkBasalt Manager désinstallé avec succès !\n\n📋 Résultat :\n• Manager supprimé\n• VkBasalt conservé\n• Configurations conservées\n• Shaders conservés"
    fi
}

# Désinstaller tout (complet)
uninstall_complete() {
    if show_question "🗑️ Désinstallation complète ?\n\n⚠️ ATTENTION: Cela supprimera TOUT :\n• VkBasalt Manager\n• VkBasalt lui-même\n• Toutes les configurations\n• Tous les shaders\n• Toutes les sauvegardes\n\nCette action est IRRÉVERSIBLE !\n\nContinuer ?"; then

        show_progress "Désinstallation complète" "Suppression de tous les composants"

        echo "🗑️ Désinstallation complète en cours..."

        # VkBasalt Manager
        echo "📝 Suppression de VkBasalt Manager..."
        [ -f "$MANAGER_SCRIPT" ] && rm -f "$MANAGER_SCRIPT" && echo "   ✓ Script supprimé"
        [ -f "$MANAGER_ICON" ] && rm -f "$MANAGER_ICON" && echo "   ✓ Icône supprimée"
        [ -f "$MANAGER_DESKTOP" ] && rm -f "$MANAGER_DESKTOP" && echo "   ✓ Raccourci supprimé"

        # VkBasalt lui-même
        echo "🔧 Suppression de VkBasalt..."
        [ -f "$VKBASALT_LIB64" ] && rm -f "$VKBASALT_LIB64" && echo "   ✓ Bibliothèque 64-bit supprimée"
        [ -f "$VKBASALT_LIB32" ] && rm -f "$VKBASALT_LIB32" && echo "   ✓ Bibliothèque 32-bit supprimée"
        [ -f "$VKBASALT_LAYER64" ] && rm -f "$VKBASALT_LAYER64" && echo "   ✓ Couche Vulkan 64-bit supprimée"
        [ -f "$VKBASALT_LAYER32" ] && rm -f "$VKBASALT_LAYER32" && echo "   ✓ Couche Vulkan 32-bit supprimée"

        # Configurations, shaders et dossiers
        echo "⚙️ Suppression des configurations et shaders..."

        # Supprimer le dossier de configuration de VkBasalt en entier (inclut .conf, .backup, .example, etc.)
        [ -d "$MANAGER_CONFIG_DIR" ] && rm -rf "$MANAGER_CONFIG_DIR" && echo "   ✓ Dossier de configuration VkBasalt supprimé"

        # Supprimer le dossier des shaders
        [ -d "$RESHADE_DIR" ] && rm -rf "$RESHADE_DIR" && echo "   ✓ Dossier Shaders supprimé"

        # Nettoyage des dossiers potentiellement vides
        echo "🧹 Nettoyage des dossiers..."
        rmdir /home/deck/.local/share/vulkan/implicit_layer.d 2>/dev/null || true
        rmdir /home/deck/.local/share/vulkan 2>/dev/null || true
        rmdir /home/deck/.local/lib32 2>/dev/null || true

        # Nettoyage des anciens fichiers
        [ -f "/home/deck/Desktop/VkBasalt-Manager.sh" ] && rm -f "/home/deck/Desktop/VkBasalt-Manager.sh"
        [ -f "/home/deck/Desktop/vkbasalt-manager.svg" ] && rm -f "/home/deck/Desktop/vkbasalt-manager.svg"
        [ -f "/home/deck/.local/share/applications/VkBasalt-Manager.desktop" ] && rm -f "/home/deck/.local/share/applications/VkBasalt-Manager.desktop"

        echo "   ✓ Nettoyage terminé"

        show_info "✅ Désinstallation complète terminée !\n\n📋 Résultat :\n• VkBasalt Manager supprimé\n• VkBasalt supprimé\n• Configurations supprimées\n• Shaders supprimés\n• Système nettoyé\n\n💡 N'oubliez pas de supprimer ENABLE_VKBASALT=1 des options de lancement de vos jeux Steam."
    fi
}

# Supprimer seulement les configurations
uninstall_config_only() {
    if show_question "🗑️ Supprimer les configurations ?\n\nCela supprimera :\n• vkBasalt.conf\n• vkBasalt.conf.backup\n• MAIS gardera VkBasalt Manager et VkBasalt\n\nContinuer ?"; then

        show_progress "Suppression configurations" "Nettoyage des configurations"

        echo "⚙️ Suppression des configurations..."

        [ -f "$VKBASALT_CONFIG" ] && rm -f "$VKBASALT_CONFIG" && echo "   ✓ Configuration supprimée"
        [ -f "$VKBASALT_BACKUP" ] && rm -f "$VKBASALT_BACKUP" && echo "   ✓ Sauvegarde supprimée"

        echo "   ✓ Nettoyage terminé"

        show_info "✅ Configurations supprimées !\n\n📋 Résultat :\n• Configurations supprimées\n• VkBasalt Manager conservé\n• VkBasalt conservé\n• Shaders conservés"
    fi
}

# Fonction principale
main() {
    # Détecter les composants
    detect_components

    # Vérifier s'il y a quelque chose à désinstaller
    if [ "$MANAGER_INSTALLED" = false ] && [ "$VKBASALT_INSTALLED" = false ]; then
        show_info "ℹ️ Aucun composant VkBasalt détecté sur le système.\n\nRien à désinstaller."
        exit 0
    fi

    # Afficher le menu et traiter le choix
    show_uninstall_menu
    local choice=$?

    case $choice in
        1)
            if [ "$MANAGER_INSTALLED" = true ]; then
                uninstall_manager_only
            else
                show_error "VkBasalt Manager n'est pas installé."
            fi
            ;;
        2)
            uninstall_complete
            ;;
        3)
            uninstall_config_only
            ;;
        0)
            echo "🚫 Désinstallation annulée."
            exit 0
            ;;
    esac

    echo
    echo "✨ Désinstallation terminée !"
    echo "Le script de désinstallation n'a pas été supprimé."
}

# Lancer le programme principal
main
