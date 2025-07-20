# 🎮 Gestionnaire VkBasalt pour Steam Deck

Interface graphique pour installer et configurer VkBasalt - Améliorez vos jeux avec des effets visuels.

## 🚀 Installation Rapide

1. **Téléchargez le script :**
   ```bash
   wget https://github.com/Vaddum/vkbasalt-manager/raw/main/vkbasalt_manager_fr.sh
   chmod +x vkbasalt_manager_fr.sh
   ./vkbasalt_manager_fr.sh
   ```

2. **Première utilisation :** Le script installe automatiquement VkBasalt et les shaders essentiels.

## ✨ Fonctionnalités

- **Installation automatique** de VkBasalt en un clic
- **Interface française** avec Zenity
- **8 effets disponibles** : 4 intégrés + 4 shaders externes essentiels
- **Configuration avancée** pour chaque effet
- **Touche de basculement** personnalisable (défaut : `Home`)

### Effets Disponibles

| Type | Nom | Description |
|------|-----|-------------|
| ⭐ Intégré | **CAS** | Netteté adaptative AMD |
| ⭐ Intégré | **FXAA** | Anti-aliasing rapide |
| ⭐ Intégré | **SMAA** | Anti-aliasing haute qualité |
| ⭐ Intégré | **DLS** | Netteté luma débruitée |
| 🔧 Externe | **LumaSharpen** | Netteté populaire |
| 🔧 Externe | **Vibrance** | Amélioration couleurs |
| 🔧 Externe | **Clarity** | Netteté avancée |
| 🔧 Externe | **Netteté Adaptative** | Netteté intelligente |

## 🎯 Utilisation

1. **Activez les effets :** Sélectionnez les shaders dans l'interface
2. **Dans le jeu :** Appuyez sur `Home` pour activer/désactiver
3. **Configuration :** Utilisez le menu "Avancé" pour ajuster les paramètres

## ⚙️ Configurations Recommandées

- **Général :** CAS (50%) + Vibrance
- **Jeux pixellisés :** SMAA + LumaSharpen
- **Jeux sombres :** CAS + Vibrance + Clarity

## 🛠️ Dépannage

**VkBasalt ne fonctionne pas ?**
- Vérifiez que le jeu utilise Vulkan
- Redémarrez Steam après installation
- Essayez une autre touche de basculement

**Performance réduite ?**
- Utilisez uniquement CAS ou FXAA
- Réduisez l'intensité des effets

## 🔄 Désinstallation

Lancez le gestionnaire → **"Désinstaller"** → Confirmer

## 📁 Emplacements des Fichiers

- **Configuration :** `~/.config/vkBasalt/vkBasalt.conf`
- **Shaders :** `~/.config/reshade/Shaders/`
- **Gestionnaire :** `~/.config/vkBasalt/vkbasalt-manager.sh`
