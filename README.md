<div align="center">

# ◆ Tsubasa Catalyst

**Rice Hyprland + Quickshell, design cyber-anime, entièrement en français.**

Hyprland 0.57 (config Lua) · Quickshell · thèmes appliqués en direct · CachyOS / Arch

![Bureau](./.data/assets/screenshots/desktop.webp)

</div>

> Basé sur [lyne-dots](https://github.com/caioax/lyne-dots) de caioax, puis largement réécrit : le shell **Catalyst** (`quickshell/.config/quickshell/catalyst/`) remplace la barre d'origine.

---

## 📸 Aperçu

<table>
  <tr>
    <td width="50%"><img src="./.data/assets/screenshots/glance.webp" alt="Glance"><br><b>Glance</b> — clic sur l'horloge : heure, calendrier, télémétrie, média, météo</td>
    <td width="50%"><img src="./.data/assets/screenshots/control.webp" alt="Centre de contrôle"><br><b>Centre de contrôle</b> — réseau, Bluetooth, True Tone, énergie, mode visio, VPN, volumes, notifications</td>
  </tr>
  <tr>
    <td><img src="./.data/assets/screenshots/launcher.webp" alt="Launcher"><br><b>Launcher</b> — applis, projets, <code>=</code> calcul, <code>&gt;</code> terminal, <code>:</code> commandes Catalyst</td>
    <td><img src="./.data/assets/screenshots/studio.webp" alt="Studio"><br><b>Studio</b> — thèmes, fonds d'écran, barre, dock, widgets du bureau, profils</td>
  </tr>
  <tr>
    <td><img src="./.data/assets/screenshots/sysmon.webp" alt="Moniteur système"><br><b>Moniteur système</b> — CPU, RAM, GPU, disque, réseau, top processus</td>
    <td><img src="./.data/assets/screenshots/power.webp" alt="Session"><br><b>Session</b> — verrouiller, veille, redémarrer, UEFI, extinction programmée, mises à jour</td>
  </tr>
</table>

---

## ✨ Ce qu'il y a dedans

- **Shell Catalyst** (Quickshell/QML) — barre, launcher, centre de contrôle, Studio, glance, calendrier, moniteur système, session, vue d'ensemble, dock, widgets de bureau, OSD et notifications. Tout passe par un design system commun (`kit/`, `rice/Theme`, `Tokens`, `Motion`) avec animations à ressort.
- **Thèmes en direct** — Catalyst Dark, Silver Protocol, Neon Pulse, les palettes classiques (Tokyo Night, Catppuccin, Dracula, Gruvbox, Nord, Rose Pine) et Material You depuis le fond d'écran (matugen). Appliqués sans redémarrage au shell, aux bordures Hyprland, à GTK 3/4, Qt/KDE (Dolphin), rofi et hyprlock.
- **Fonds d'écran** — bibliothèque avec recadrage, fonds animés, et navigateur en ligne (Wallhaven…) intégré au Studio.
- **Outils intégrés** — VPN (WireGuard/OpenVPN, ProtonVPN), machines virtuelles (libvirt), gestionnaire de paquets et dépôts, Arsenal (navigateur d'outils de sécurité BlackArch), scène caméra virtuelle, micro traité + mode visio, presse-papiers, conteneurs Podman/Docker.
- **Hyprland 0.57 en Lua** — config modulaire dans `hyprland/.config/hypr/conf.d/*.lua`, workspaces dynamiques.
- **Le reste** — Neovim (lazy.nvim, LSP), Zsh + Powerlevel10k, Tmux, Kitty, Fastfetch.

La doc détaillée du shell (surfaces, architecture, IPC, thèmes, rollback) est dans [`catalyst/README.md`](quickshell/.config/quickshell/catalyst/README.md).

---

## 📦 Installation

> ⚠️ **C'est ma config perso.** Elle tourne sur CachyOS avec deux écrans 1080p. Certains raccourcis appellent encore des scripts de `~/.config/niri/scripts/`, qui ne sont pas dans ce dépôt : ils ne feront rien chez toi tant que tu ne les remplaces pas. Lis la config avant de l'installer.

```bash
git clone https://github.com/mrtsubasa/tsu-dots.git ~/.tsu-dots
cd ~/.tsu-dots
./install.sh
```

L'installeur est interactif : il propose les catégories de paquets, crée les liens avec [GNU Stow](https://www.gnu.org/software/stow/) puis génère les fichiers propres à la machine.

```bash
./install.sh --stow-only       # seulement les liens symboliques
./install.sh --setup-only      # seulement la config Hyprland
./install.sh --packages core   # une seule catégorie
```

Détails dans [.install/README.md](.install/README.md).

Les fonds d'écran ne sont pas dans le dépôt (`catalyst/wallpapers/` est ignoré par git) : mets les tiens dans `catalyst/wallpapers/sfw/`.

---

## ⌨️ Raccourcis principaux

| Raccourci | Action |
| --- | --- |
| `Super + Return` / `Super + T` | Terminal |
| `` Super + ` `` | Terminal déroulant |
| `Super + E` | Neovim |
| `Super + Shift + E` | Gestionnaire de fichiers (Dolphin) |
| `Super + D` / `Super + G` | Launcher |
| `Super + Y` | Centre de contrôle |
| `Super + Shift + ,` | Studio |
| `Super + Shift + O` | Vue d'ensemble |
| `Super + X` | Presse-papiers |
| `Super + Shift + S` / `Print` | Capture zone / plein écran |
| `Super + Ctrl + M` | Couper le micro |
| `Super + Alt + V` | Mode visio |
| `Super + Alt + L` | Verrouiller |
| `Super + Alt + R` | Relancer le shell |
| `Super + Q` | Fermer la fenêtre |
| `Super + H J K L` | Focus |
| `Super + Ctrl + H / L` | Déplacer la fenêtre |
| `Super + ← / →` | Workspace précédent / suivant |
| `Super + Alt + ← / →` | Écran gauche / droite |

La liste complète est dans [`keybinds.lua`](hyprland/.config/hypr/conf.d/keybinds.lua), ou dans le launcher avec `:raccourcis`.

---

## 🔧 Tsu CLI

`tsu` gère les dotfiles depuis le terminal (chargé par `.zshrc`).

| Commande | Rôle |
| --- | --- |
| `tsu theme` | thème actuel, `list`, `set <nom>`, `auto` (Material You), `scheme light/dark` |
| `tsu state` | éditer / synchroniser `state.json` |
| `tsu migrate` | migrations (`list`, `run`, `done`) |
| `tsu update` | récupérer les mises à jour et lancer les migrations |
| `tsu git …` | git dans le dossier des dotfiles |
| `tsu reload` | recharger Quickshell |

> `tsu update` fait un `git reset --hard` avant de mettre à jour : commite tes modifications avant.

---

## 📁 Structure

Chaque dossier à la racine est un paquet Stow lié dans `$HOME`.

| Dossier | Contenu |
| --- | --- |
| `quickshell/` | shell Catalyst (`catalyst/`) + scripts Python/Bash |
| `hyprland/` | Hyprland (Lua), hypridle, hyprlock, UWSM |
| `nvim/` | Neovim |
| `zsh/`, `tmux/`, `kitty/`, `fastfetch/` | terminal |
| `theming/`, `kde/` | GTK 3/4, Qt5/6, kdeglobals |
| `local/` | scripts perso, binaire `tsu` |
| `.install/` | scripts d'installation |
| `.data/` | thèmes, templates matugen, tsu-cli, fonds par défaut |

Les réglages propres à la machine (écrans, autostart, variables, raccourcis locaux) vont dans `~/.config/hypr/local/` et ne sont pas suivis par git.

---

## 🙏 Crédits

- [lyne-dots](https://github.com/caioax/lyne-dots) par caioax — la base de départ
- [HyprQuickFrame](https://github.com/Ronin-CK/HyprQuickFrame) — inspiration de l'outil de capture
- [caelestia](https://github.com/caelestia-dots/shell) — inspiration des animations et widgets

Licence [GPL-3.0](LICENSE).
