# Installation

## Distributions supportées

| Distribution | Support |
| --- | --- |
| **Arch Linux** | `./install.sh` |
| **CachyOS** | `./install.sh` — les dépôts CachyOS (paquets optimisés) sont utilisés automatiquement |
| **BlackArch** (sur Arch) | `./install.sh` — la catégorie `security` réutilise le dépôt déjà présent |
| **EndeavourOS, Garuda** | `./install.sh` |
| **Manjaro** | `./install.sh`, mais ses dépôts ont du retard : Hyprland ≥ 0.57 (config Lua) peut manquer |
| **NixOS** | flake + module home-manager, **expérimental** : voir [`nix/README.md`](../nix/README.md) |
| Debian, Ubuntu, Fedora… | pas de script : voir [Autres distributions](#autres-distributions) |

`install.sh` détecte la distribution. Chaque paquet passe par pacman si un dépôt actif le fournit (officiel, CachyOS, Chaotic-AUR, BlackArch), sinon par l'AUR (yay/paru, yay est installé si besoin). Si une installation groupée échoue, il réessaie paquet par paquet et liste les échecs à la fin.

## Utilisation

```bash
./install.sh                           # menu interactif
./install.sh --dry-run                 # ce qui serait installé (dépôts / AUR), sans rien toucher
./install.sh --packages catalyst,fonts # seulement ces catégories
./install.sh --check                   # vérifie que Catalyst a tout ce qu'il lui faut
./install.sh --stow-only               # seulement les liens symboliques
./install.sh --setup-only              # seulement les fichiers locaux Hyprland
```

## Catégories

| # | Catégorie | Contenu |
| --- | --- | --- |
| 1 | `core` | Hyprland, UWSM, portails, hypridle, hyprlock, hyprpicker, hyprsunset, polkit (**essentiel**) |
| 2 | `catalyst` | Quickshell + ce que les panneaux appellent : awww, mpvpaper, matugen, rofi, alacritty, cliphist, grim/slurp/satty, wf-recorder, cava, ddcutil, Python (gi, dbus, Pillow)… (**essentiel**) |
| 3 | `terminal` | Alacritty, Ghostty, Kitty, Zsh (+ Oh-My-Zsh, Powerlevel10k), Tmux, Fastfetch |
| 4 | `editor` | Neovim + outils de dev |
| 5 | `apps` | Dolphin, Zen Browser, Spotify, mpv |
| 6 | `utils` | NetworkManager, Bluetooth, PipeWire, EasyEffects, btop |
| 7 | `fonts` | JetBrainsMono Nerd, Inter, Space Grotesk, Material Symbols, Papirus, Bibata |
| 8 | `theming` | qt5ct, qt6ct, adw-gtk3, nwg-look |
| 9 | `vm` | libvirt, QEMU, virt-manager (panneau VM) — ajoute l'utilisateur au groupe `libvirt` |
| 10 | `vpn` | WireGuard, OpenVPN, ProtonVPN (panneau VPN) |
| 11 | `cam` | v4l2loopback, OpenCV, onnxruntime (caméra virtuelle) — installe les headers du noyau courant |
| 12 | `fun` | Pokémon (pokemon-colorscripts), fortune, cowsay, cbonsai, lolcat, cmatrix, pipes.sh — pour l'accueil du terminal (Studio → Terminal) |
| 13 | `security` | dépôt BlackArch via le `strap.sh` officiel (affiche son SHA1 et **demande confirmation**) + nmap, wireshark, tcpdump… |
| 14 | `nvidia` | variables d'environnement NVIDIA |

Menu : `a` = 1 à 8 (recommandé), `f` = 1 à 12. `security` et `nvidia` ne sont jamais installées sans les choisir.

## Fichiers locaux (non suivis par git)

Créés au premier lancement depuis `.data/hyprland/templates/` :

- `~/.config/hypr/local/autostart.lua`
- `~/.config/hypr/local/extra_keybinds.lua`
- `~/.config/hypr/local/extra_environment.lua` (version NVIDIA si tu as répondu oui)
- `~/.config/uwsm/env.d/*.sh`

`monitors.lua` et `workspaces.lua` sont dans le dépôt : adapte `monitors.lua` à tes écrans.
Les fonds d'écran par défaut sont copiés dans `~/.config/quickshell/catalyst/wallpapers/sfw/`.

## Autres distributions

Pas de script : Hyprland 0.57, Quickshell et plusieurs outils n'y existent pas en paquets à jour.
Pour tenter quand même, il faut au minimum :

- **Session** : Hyprland ≥ 0.57 (config Lua), UWSM, xdg-desktop-portal-hyprland, hypridle, hyprlock, hyprpicker, hyprsunset, un agent polkit
- **Shell** : Quickshell ≥ 0.3 avec Qt 6 (declarative, wayland, svg, 5compat, imageformats), upower
- **Outils** : awww, mpv, mpvpaper, matugen, ImageMagick, ffmpeg, ffmpegthumbnailer, rofi (Wayland), alacritty, zenity, wl-clipboard, cliphist, grim, slurp, satty, wf-recorder, playerctl, brightnessctl, ddcutil, cava, libnotify, lm-sensors, wtype, socat, jq, bc, fzf, libsecret, translate-shell, tesseract, yt-dlp
- **Python 3** : PyGObject, dbus-python, Pillow (+ numpy, OpenCV, onnxruntime pour la caméra)
- **Polices** : JetBrainsMono Nerd Font, Inter, Space Grotesk, Material Symbols Rounded, Papirus

Puis `stow` des dossiers listés dans `.install/setup/stow.sh` et `./install.sh --setup-only` (la partie Hyprland ne dépend pas de pacman).
