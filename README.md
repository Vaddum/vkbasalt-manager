# VkBasalt Manager pour Steam Deck

Un gestionnaire graphique complet pour VkBasalt sur Steam Deck avec interface utilisateur intuitive et installation automatisée.

## 🎮 Qu'est-ce que VkBasalt ?

VkBasalt est une couche Vulkan qui permet d'appliquer des effets visuels post-traitement (shaders) aux jeux compatibles Vulkan, similaire à ReShade mais spécifiquement conçu pour Linux.

## ✨ Fonctionnalités

### 🚀 Installation automatisée
- Installation complète de VkBasalt en un clic
- Téléchargement automatique des shaders ReShade
- Configuration des permissions et raccourcis bureau
- Détection automatique de l'environnement Steam Deck

### 🎨 Interface graphique intuitive
- Manager graphique complet avec Zenity
- Sélection visuelle des shaders avec cases à cocher
- Sliders pour ajuster les paramètres en temps réel
- Presets prédéfinis pour différents styles visuels

### 🔧 Gestion avancée
- **Presets** : Performance, Qualité, Cinématique, Minimal, Complet
- **Shaders supportés** : CAS, FXAA, SMAA, LumaSharpen, Vibrance, DPX, Clarity
- **Sauvegarde/Restauration** : Système de backup automatique
- **Configuration personnalisée** : Modification de tous les paramètres

## 📋 Prérequis

- **Steam Deck** avec SteamOS
- **Accès root/sudo** pour l'installation
- **Connexion internet** pour le téléchargement des composants

## 🛠️ Installation

### Installation rapide

```bash
# Télécharger et exécuter l'installateur
wget -O vkbasalt_installer.sh https://github.com/Vaddum/vkbasalt-manager/blob/2903877a51b9b32d3312b41d8cbf0a9c3499fef4/vkbasalt_installer.sh
chmod +x vkbasalt_installer.sh
./vkbasalt_installer.sh
```

### Installation manuelle

1. **Télécharger les scripts**
   ```bash
   wget https://votre-url/vkbasalt_installer.sh
   wget https://votre-url/vkbasalt_uninstaller.sh
   ```

2. **Rendre exécutables**
   ```bash
   chmod +x vkbasalt_installer.sh vkbasalt_uninstaller.sh
   ```

3. **Lancer l'installation**
   ```bash
   ./vkbasalt_installer.sh
   ```

## 🎯 Utilisation

### Lancement du manager

Après installation, vous trouverez l'icône **VkBasalt Manager** sur votre bureau. Double-cliquez pour ouvrir l'interface graphique.

Ou lancez depuis le terminal :
```bash
/home/deck/.config/vkBasalt/VkBasalt-Manager.sh
```

### Activation dans Steam

1. **Ouvrez Steam en mode Bureau**
2. **Clic droit sur votre jeu** → Propriétés
3. **Dans les options de lancement, ajoutez :**
   ```
   ENABLE_VKBASALT=1 %command%
   ```
4. **Lancez le jeu**
5. **Utilisez la touche `Home`** pour activer/désactiver les effets

### Interface du manager

#### Menu principal
- **Presets** : Configurations prédéfinies
- **Shaders** : Sélection et activation des effets
- **Touche** : Modification de la touche de basculement
- **Avancé** : Paramètres détaillés des shaders
- **Voir** : Affichage de la configuration actuelle
- **Sauvegarde** : Gestion des backups
- **Reset** : Réinitialisation aux valeurs par défaut

#### Presets disponibles

| Preset | Shaders | Description |
|--------|---------|-------------|
| **Performance** | CAS + FXAA + SMAA | Effets légers pour meilleures performances |
| **Qualité** | CAS + SMAA + LumaSharpen + Vibrance | Visuels améliorés équilibrés |
| **Cinématique** | DPX + Vibrance | Look cinéma dramatique |
| **Minimal** | CAS seulement | Netteté uniquement |
| **Complet** | Tous les shaders | Tous les effets activés |

#### Shaders supportés

- **CAS** : Contrast Adaptive Sharpening (AMD) - Netteté intelligente
- **FXAA** : Fast Approximate Anti-Aliasing - Anti-aliasing rapide
- **SMAA** : Subpixel Morphological AA - Anti-aliasing haute qualité
- **LumaSharpen** : Netteté basée sur la luminance
- **Vibrance** : Saturation intelligente des couleurs
- **DPX** : Look cinéma professionnel
- **Clarity** : Amélioration de la clarté et des détails

## ⚙️ Configuration manuelle

### Fichier de configuration principal
```
/home/deck/.config/vkBasalt/vkBasalt.conf
```

### Exemple de configuration
```ini
# VkBasalt Configuration
effects = cas:fxaa:smaa

reshadeTexturePath = "/home/deck/.config/reshade/Textures"
reshadeIncludePath = "/home/deck/.config/reshade/Shaders"

toggleKey = Home
enableOnLaunch = True

# Paramètres CAS
casSharpness = 0.4

# Paramètres FXAA
fxaaQualitySubpix = 0.75
fxaaQualityEdgeThreshold = 0.125
```

### Modification de la touche de basculement

Les touches supportées incluent :
- `Home`, `End`, `Insert`, `Delete`
- `F1` à `F12`
- `Page_Up`, `Page_Down`
- `Tab`, `Caps_Lock`, `Num_Lock`

## 🗑️ Désinstallation

### Utilisation du désinstallateur

```bash
./vkbasalt_uninstaller.sh
```

### Options de désinstallation

1. **Manager seulement** : Supprime l'interface mais garde VkBasalt
2. **Complète** : Supprime tout (VkBasalt + Manager + Shaders + Configs)
3. **Configurations** : Supprime seulement les fichiers de configuration

### Désinstallation manuelle

```bash
# Supprimer VkBasalt Manager
rm -f /home/deck/.config/vkBasalt/VkBasalt-Manager.sh
rm -f /home/deck/.config/vkBasalt/vkbasalt-manager.svg
rm -f /home/deck/Desktop/VkBasalt-Manager.desktop

# Supprimer VkBasalt complet
rm -f /home/deck/.local/lib/libvkbasalt.so
rm -f /home/deck/.local/lib32/libvkbasalt.so
rm -f /home/deck/.local/share/vulkan/implicit_layer.d/vkBasalt*.json
rm -rf /home/deck/.config/vkBasalt
rm -rf /home/deck/.config/reshade
```

## 🔧 Dépannage

### VkBasalt ne fonctionne pas

1. **Vérifiez que le jeu utilise Vulkan** (VkBasalt ne fonctionne pas avec OpenGL/DirectX)
2. **Confirmez l'option de lancement** : `ENABLE_VKBASALT=1 %command%`
3. **Testez avec un jeu Vulkan connu** (ex: DOOM Eternal, Cyberpunk 2077)
4. **Vérifiez l'installation** via le menu "Statut" du manager

### Performances dégradées

1. **Utilisez le preset "Performance"**
2. **Désactivez les shaders coûteux** (Clarity, DPX)
3. **Ajustez les paramètres** via le menu "Avancé"
4. **Réduisez les valeurs de netteté** (CAS, LumaSharpen)

### Interface ne s'ouvre pas

1. **Vérifiez l'installation de Zenity** :
   ```bash
   sudo pacman -S zenity
   ```
2. **Lancez depuis le terminal** pour voir les erreurs
3. **Vérifiez les permissions** :
   ```bash
   chmod +x /home/deck/.config/vkBasalt/VkBasalt-Manager.sh
   ```

### Problèmes de configuration

1. **Utilisez "Reset"** dans le manager pour revenir aux défauts
2. **Restaurez depuis une sauvegarde** via le menu "Sauvegarde"
3. **Supprimez la config** et relancez le manager :
   ```bash
   rm /home/deck/.config/vkBasalt/vkBasalt.conf
   ```

## 📁 Structure des fichiers

```
/home/deck/
├── .config/
│   ├── vkBasalt/
│   │   ├── VkBasalt-Manager.sh      # Script principal
│   │   ├── vkbasalt-manager.svg     # Icône
│   │   ├── vkBasalt.conf            # Configuration
│   │   └── vkBasalt.conf.backup     # Sauvegarde
│   └── reshade/
│       ├── Shaders/                 # Fichiers .fx
│       └── Textures/                # Textures pour shaders
├── .local/
│   ├── lib/libvkbasalt.so           # Bibliothèque 64-bit
│   ├── lib32/libvkbasalt.so         # Bibliothèque 32-bit
│   └── share/vulkan/implicit_layer.d/
│       ├── vkBasalt.json            # Couche Vulkan 64-bit
│       └── vkBasalt.x86.json        # Couche Vulkan 32-bit
└── Desktop/
    └── VkBasalt-Manager.desktop     # Raccourci bureau
```

## 🎮 Jeux testés et compatibles

### ✅ Fonctionne parfaitement
- **DOOM Eternal**
- **Cyberpunk 2077**
- **The Witcher 3**
- **Red Dead Redemption 2**
- **Baldur's Gate 3**
- **Hogwarts Legacy**

### ⚠️ Support partiel
- **Proton/Wine games** : Peut nécessiter des ajustements
- **Jeux plus anciens** : Compatibilité variable

### ❌ Non compatible
- **Jeux OpenGL uniquement**
- **Jeux DirectX sans traduction Vulkan**

## 🛡️ Sécurité et permissions

- **Installation sécurisée** : Scripts vérifiés et signés
- **Permissions minimales** : Seules les permissions nécessaires
- **Pas de télémétrie** : Aucune donnée collectée
- **Open source** : Code source visible et modifiable

## 📝 Changelog

### v2.0 (Actuel)
- Interface graphique complète avec Zenity
- Système de presets
- Configuration avancée avec sliders
- Gestion des sauvegardes
- Support de tous les shaders populaires

### v1.0
- Installation automatique de base
- Configuration minimale

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- **Signaler des bugs**
- **Proposer des améliorations**
- **Ajouter des presets**
- **Améliorer la documentation**

## 📄 Licence

Ce projet est sous licence libre. Vous êtes libre de l'utiliser, le modifier et le redistribuer.

## 🙏 Remerciements

- **Équipe VkBasalt** pour le développement principal
- **Communauté ReShade** pour les shaders
- **Valve** pour le Steam Deck
- **Communauté Steam Deck** pour les tests et retours

---

**⭐ Si ce projet vous aide, n'hésitez pas à le partager !**
