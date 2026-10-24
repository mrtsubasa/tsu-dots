# ◆ Tsubasa Catalyst — shell v3

Environnement de bureau Quickshell pour Hyprland : cyber-anime, sombre, précis,
pensé pour le développement. Tout est piloté par un design system unique et
un moteur de thèmes ; chaque réglage est persistant et modifiable depuis le
**Studio**.

- Quickshell 0.3.2 · Hyprland 0.56 · Qt 6.12 · CachyOS
- Lancement : `scripts/catalyst-session.sh` (autostart Hyprland), relance `Super+Alt+R`
- Branche git : `tsubasa-catalyst` dans `~/.lyne-dots`

---

## Surfaces

| Surface | Ouverture | Contenu |
|---|---|---|
| **Barre** | toujours | marque ◆, workspaces, fenêtre active · horloge · média, métriques (en alerte), tray, état, notifications, session |
| **Launcher** | clic ◆, `Super+D` / `Super+G` | applications (recherche floue + fréquence), `=` calcul, `>` terminal, `:` commandes Catalyst |
| **Centre de contrôle** | clic sur l'état, `Super+Y` | réseau, Bluetooth, NPD, lumière nocturne, énergie, éveil, volume (≤150 %), micro, luminosité DDC, média, notifications ; sous-pages réseau / BT / audio + mixeur / égaliseur / énergie |
| **Studio** | clic droit ◆, `Super+Shift+,` | thèmes, fond d'écran, barre, dock, bureau, profil & interface, profils |
| **Calendrier** | clic horloge | mois, semaines ISO, météo |
| **Moniteur système** | clic métriques | jauges, top processus |
| **Session** | ⏻ | verrouiller (L), veille (S), déconnexion* (D), redémarrer* (R), éteindre* (E) — *confirmation avec le nombre de fenêtres ouvertes ; écrans éteints (O), redémarrer vers l'UEFI (U), relancer le shell, extinction programmée (logind, compte à rebours dans la barre), mises à jour (dépôts + AUR) |
| **Vue d'ensemble** | `Super+Shift+O`, clic fenêtre active | workspaces par écran, captures réelles des fenêtres, glisser pour déplacer |
| **Dock** | Studio → Dock | épinglées + ouvertes, menu contextuel, masquage auto |
| **Widgets** | Studio → Bureau | 9 types, mode édition avec magnétisme |
| **OSD / Toasts** | automatique | capsule volume/micro/luminosité ; 3 notifications max à l'écran |
| **Verrouillage** | `Super+Alt+L`, hypridle | hyprlock (PAM) aux couleurs du thème |
| **Micro & visio** | tuile Mode visio, `Super+Alt+V` | micro traité (EasyEffects) / brut, vumètre, « m'écouter », mode visio, qui utilise micro / caméra / écran |
| **Presse-papiers** | `Super+X` | recherche, copie, suppression, tout effacer, pause de l'enregistrement |
| **Raccourcis** | launcher `:raccourcis` | générés depuis `keybinds.conf`, conflits signalés |
| **Conteneurs** | launcher `:conteneurs` | Podman / Docker : démarrer, arrêter, journaux, shell |
| **Terminal déroulant** | `Super+`` ` | Alacritty persistant (workspace spécial `term`) |

Les panneaux développeur existants (IA, VM, Scripts, Chat, Bots, Ops, Paquets,
BlackArch, Omarchy, Presse-papiers, Raccourcis) sont conservés tels quels et
partagent l'habillage v3. Tous sont accessibles depuis le launcher (`:`).

---

## Architecture

```
catalyst/
├─ shell.qml              point d'entrée + IPC
├─ kit/                   design system : composants réutilisables (qs.kit)
│   Pane Txt Icon IconButton Button Toggle Slider Tile ListItem SearchField
│   Segmented SectionHeader SettingRow Group Badge Ring Spinner Art Tip Menu
│   Popout BarItem Mark EmptyState Field Swatch FocusRing StateLayer Divider
├─ rice/                  services (singletons, qs.rice)
│   Theme Tokens Motion            tokens couleurs / géométrie / animation
│   Themes Palettes Chrome         moteur de thèmes, palettes, identités
│   ShellCfg BarCfg DockCfg        réglages persistants (JSON surveillés)
│   WidgetStore Profiles Walls     widgets, profils, fonds d'écran
│   Niri(=WM) SysInfo Net Audio Players Notifs Bright Night Power Caffeine
│   Recorder Search Equalizer Weather Identity PanelService …
├─ modules/
│   topbar/  stage/ (couche des surfaces transitoires)  control/  studio/
│   notifs/  osd/  dock/  overview/  widgets/  dev/ (galerie du kit)
│   ai/ vm/ scripts/ chat/ bots/ ops/ clip/ wall/ binds/ pkgs/ omarchy/
│   blackarch/ bar/ (popovers tray + mini-terminal)
├─ components/            composants hérités, restylés (panneaux dev)
├─ tokens/presets/        thèmes complets (+ user/ pour les tiens)
├─ tokens/themes/         packs d'identité (géométrie)
├─ profiles/              profils de configuration (Studio → Profils)
└─ scripts/               bridge.py, theme-sync.py, profiles.py, thumbs.sh,
                          catalyst-tools.sh, catalyst-walls.sh, catalyst-rollback.sh
```

**Règle d'or :** un composant ne contient ni couleur ni dimension en dur — il
lit `Theme` (couleurs, polices), `Tokens` (tailles, rayons) et `Motion`
(durées, courbes).

### Intégrations système (toutes réelles, pilotées par événements)

| Domaine | Source |
|---|---|
| Workspaces / fenêtres | socket d'événements Hyprland (rafraîchi sur événement, filet 5 s) |
| Réseau | NetworkManager D-Bus (`Quickshell.Networking`) — filaire + Wi-Fi |
| Bluetooth | BlueZ D-Bus (`Quickshell.Bluetooth`) |
| Audio | PipeWire (`Quickshell.Services.Pipewire`), mixeur par application |
| Égaliseur | plugin Equalizer d'EasyEffects (fichiers de config réels) |
| Média | MPRIS |
| Notifications | serveur `org.freedesktop.Notifications` du shell (unique) |
| Énergie | power-profiles-daemon via UPower |
| Éveil | protocole Wayland idle-inhibit (respecté par hypridle) |
| Luminosité | DDC/CI (`brightness.sh`, `ddcutil`) — touches via IPC |
| True Tone / mode nuit | `hyprsunset` possédé par le shell (`rice/Night.qml`) |
| Extinction programmée | systemd-logind (`shutdown +N`, propriété `ScheduledShutdown`) |
| Métriques | `/proc` + hwmon (k10temp), aucun processus |
| Enregistrement | `wf-recorder`, processus possédé par le shell |
| Vie privée | types de nœuds PipeWire (capture audio / vidéo, portail xdph) |
| Micro traité | `pactl set-default-source easyeffects_source`, EasyEffects lancé en `--service-mode` à la demande |
| GPU | `nvidia-smi -lms` (un seul processus, seulement quand affiché) |
| IP / VPN / débit | `ip -j addr` (10 s, 2 s panneau ouvert), `/proc/net/dev` |
| Conteneurs | `podman ps` / `docker ps` (3 s, panneau ouvert) |
| Mode jeu | événements Hyprland + `gamemoded -r<pid>` |
| OCR / pipette | `tesseract`, `hyprpicker` — local uniquement |

---

## True Tone

Un PC fixe n'a pas de capteur de lumière ambiante : Catalyst l'**estime**
avec la hauteur réelle du soleil (heure + position de la météo) et la
couverture nuageuse (Open-Meteo), puis règle le blanc de l'écran
(`hyprsunset`) en conséquence :

| Moment | Ambiance estimée | Écran (intensité 70 %) |
|---|---|---|
| Plein jour / ciel couvert | 6500 K | neutre |
| Heure dorée (0–15°) | 5600 → 6500 K | ≈ 5900 → 6500 K |
| Crépuscule (−6–0°) | 5000 → 5600 K | ≈ 5450 → 5900 K |
| Soirée (éclairage intérieur) | 4900 K | ≈ 5380 K |

La dérive suit le soleil par pas de 40 K toutes les 2 s (imperceptible) ; un
changement de mode se fait en ~2 s. Le mode nuit (température fixe, 2500–5500 K)
est prioritaire. Réglages : centre de contrôle → tuile True Tone → page Écran,
ou Studio → Profil & interface. `hyprsunset` ne tourne que si l'un des deux
est actif.

## Thèmes

Trois thèmes complets, plus les palettes classiques (Tokyo Night, Catppuccin…)
et Material You (matugen, depuis le fond d'écran) :

| Thème | Identité | Caractère |
|---|---|---|
| **Catalyst Dark** | `catalyst` — capsule flottante, rayons doux | graphite, violet électrique, bleu glace, rose retenu |
| **Silver Protocol** | `protocol` — bord à bord, angles précis | graphite froid, argent, bleu glace, violet discret |
| **Neon Pulse** | `pulse` — îlots, halo | charbon, violet + magenta, rose assumé, néon contrôlé |

Un thème s'applique en direct, sans redémarrage, à : barre, centre de contrôle,
launcher, Studio, dock, widgets, notifications, OSD, vue d'ensemble, panneaux
dev, bordures de fenêtres Hyprland, **et** GTK 3/4, rofi, hyprlock
(`scripts/theme-sync.py` rend tes templates matugen avec la palette du thème).
Le terminal garde son propre système (pack Omarchy).

### Créer un thème

Le plus simple : **Studio → Thèmes**, choisir un thème de départ, régler
accents / halo / verre, puis « Enregistrer comme nouveau thème ».

À la main : copier `tokens/presets/catalyst-dark.json` dans
`tokens/presets/user/mon-theme.json` et modifier :

```jsonc
{
  "id": "mon-theme",
  "label": "Mon thème",
  "identity": "catalyst",            // catalyst | protocol | pulse | ilots | wolf | …
  "effects": { "glow": 0.3, "glass": 0.84 },
  "hyprland": { "active": "#…", "active2": "#…", "inactive": "#…" },
  "palette": {
    "background": "#…", "blueDark": "#…",             // fond, fond le plus bas
    "surface0": "#…", "surface1": "#…", "surface2": "#…", "surface3": "#…",
    "text": "#…", "subtext": "#…", "textReverse": "#…",
    "accent": "#…", "electric": "#…", "signature": "#…",
    "success": "#…", "warning": "#…", "error": "#…", "muted": "#…"
  }
}
```

Le thème apparaît immédiatement dans le Studio et le launcher (`:thème`).
Un nouveau pack d'identité (géométrie) = un fichier dans `tokens/themes/`.

---

## Profils et sauvegardes

- **Studio → Profils** : enregistrer / appliquer / dupliquer / renommer /
  supprimer un profil (thème, barre, dock, widgets, densité, identité).
  Chaque chargement sauvegarde l'état courant → « Annuler ».
  « Réglages par défaut » est aussi annulable.
- CLI : `scripts/profiles.py list|save|load|undo|defaults`.

### Rollback complet vers l'avant-v3

```bash
~/.config/quickshell/catalyst/scripts/catalyst-rollback.sh status
~/.config/quickshell/catalyst/scripts/catalyst-rollback.sh all   # shell + Hyprland + hyprlock
```

Sauvegardes : commit `95e295e` (shell avant v3), `backups/pre-v3-*.tar.gz`
(shell, `conf.d`, cache matugen), `backups/hyprlock.conf.pre-v3`.

---

## IPC

`qs ipc -p ~/.config/quickshell/catalyst call <cible> <fonction> [args]`

| Cible | Fonctions |
|---|---|
| `panels` | `toggle|show|open <nom> [écran]`, `hide`, `control <page>`, `studio <page>` |
| `theme` | `list`, `current`, `apply <id>`, `auto`, `save <nom>` |
| `widgets` | `list`, `add <type>`, `remove <id>`, `edit`, `setedit on|off` |
| `brightness` | `up`, `down`, `set <pct>` |
| `record` | `toggle region|screen`, `stop` |
| `display` | `truetone on|off`, `night on|off`, `status` |
| `audio` | `mic`, `processed on|off`, `call [on|off]`, `status` |
| `game` | `toggle`, `status` |
| `eq` | `status`, `on`, `off`, `gain <i> <dB>`, `curve <id>`, `load <preset>` |
| `diag` | `net`, `sys`, `wm` — état réel des services (JSON) |

Noms de panneaux : `launcher control studio calendar media sysmon power
overview kit ai vm scripts chat bots ops clip wall binds pkgs blackarch
omarchy` (alias : `dashboard`→`control`, `atelier`→`studio`).
Pages : `control` → `net bt out in eq power` · `studio` → `themes wall bar
dock desk panels profiles`.

---

## Performances (mesurées le 23/10/2026)

| | avant v3 | v3 |
|---|---|---|
| Processus lancés par le shell | ≈ 13 / s (python3 + playerctl chaque seconde, 4 × hyprctl / 400 ms, nmcli / 3 s, 4 scripts / 4 s) | ≈ 0,2 / s (sondes `pgrep` lentes) |
| CPU du processus `qs` au repos | — | ≈ 3 % d'un cœur (moyenne 10 s) |
| Mémoire `qs` | — | ≈ 660 Mo RSS |

Aucune animation continue au repos ; la position média, les métriques rapides,
le scan Wi-Fi et la découverte Bluetooth ne tournent que lorsqu'une surface
les affiche. Les captures de la vue d'ensemble sont prises une seule fois à
l'ouverture.

---

## Arsenal — navigateur d'outils

Bouton **arsenal** dans la barre (ou launcher : « arsenal », ou panneau
`arsenal`). Liste **tous** tes outils de sécurité installés (groupes
BlackArch), façon menu Kali/Parrot :

- colonne de **catégories** (Scanners, Recon, Web, Exploitation, Réseau,
  Windows, Cassage, Forensic, Reverse…) avec compteurs, plus **Favoris** et
  **Récents** ;
- **recherche** instantanée par nom et description ;
- clic sur un outil → **détail** : description longue, version, site, et la
  liste de ses **exécutables** (un paquet peut en fournir plusieurs) ;
- actions : **Terminal** (lance l'outil prêt à l'emploi), **Aide** (`--help`),
  **man**, **favori** (★), **copier le nom**. Les outils graphiques se lancent
  directement.

Le catalogue couvre les groupes **blackarch-\*** ET **archstrike-\***, plus une
liste d'outils « classiques » d'Arch (nmap, sqlmap, wireshark, metasploit,
hashcat, ghidra, bettercap, impacket…) que BlackArch ne repackage pas.
Chaque outil affiche son **dépôt d'origine** (blackarch, chaotic, cachyos, extra…).

**Dépôts alternatifs** : tu as déjà `blackarch` et `chaotic-aur`. Pour ajouter
**ArchStrike** (outils complémentaires) : launcher → « ArchStrike », ou
`scripts/add-archstrike.sh` dans un terminal (clé téléchargée en HTTPS depuis
le domaine officiel, empreinte affichée avant approbation ; `remove` pour
revenir en arrière). Ses outils apparaissent dans l'Arsenal une fois installés.

Données : `scripts/arsenal.py` lit la base pacman locale (aucun réseau, aucun
sudo) et met en cache `~/.cache/catalyst/arsenal.json`, reconstruit quand tu
installes ou retires des paquets. Masquable depuis le Studio → Barre.

## VPN (style Kali / Parrot)

Centre de contrôle → Réseau → **VPN** (ou launcher : « vpn »). Tout passe par
NetworkManager (`scripts/vpn.py`) : aucun `sudo`, état temps réel.

- **Ajouter** : fichier (`.ovpn`, `.conf` WireGuard, `.pcf`…), configuration
  **collée**, ou **WireGuard en saisie manuelle** (génération de clés incluse,
  clé publique à donner au serveur).
- **Connecter / déconnecter** ; si le VPN demande des identifiants, un
  terminal `nmcli --ask` s'ouvre.
- **Exporter** en fichier réutilisable sur n'importe quelle machine :
  `.ovpn` avec certificats intégrés (lignes `user/group nm-openvpn` retirées),
  `.conf` WireGuard complet. Dossier : `~/Documents/VPN` (droits 600) ou au choix.
- **VPN seul** (`never-default`) : seuls les réseaux du VPN passent par le
  tunnel, Internet reste sur la box (HTB / THM). **Auto** : connexion automatique.
- **Réparer** : un VPN dont les certificats ont disparu est signalé ; on le
  remplace par son fichier d'origine en gardant le nom.
- Une copie de chaque configuration importée est conservée dans
  `~/.local/share/catalyst/vpn` (600) pour l'export.
- Autres types (AnyConnect, GlobalProtect, Fortinet, IPsec, L2TP, SSTP…) :
  installer le plugin `networkmanager-<type>`, il est détecté automatiquement.
- NetBird / Tailscale (gérés par leur propre démon) sont affichés en lecture seule.

## Barre : indicateurs contextuels

N'apparaissent que lorsqu'ils ont quelque chose à dire : enregistrement
d'écran, extinction programmée, **vie privée** (micro ambre, caméra verte,
écran partagé rose, pastilles « visio » / « jeu »), **pentest** (IP du VPN =
LHOST, cible — clic pour copier).

## Raccourcis ajoutés

| Touche | Action |
|---|---|
| `Super+Ctrl+M` | couper / rétablir le micro (OSD) |
| `Super+Alt+V` | mode visio |
| `Super+`` ` | terminal déroulant |
| `Super+Ctrl+O` | panneau Ops (était en conflit avec la vue d'ensemble sur `Super+Maj+O`) |
| `Super+X` | presse-papiers |

## Limites connues

- **hyprlock** n'a pas été testé visuellement pendant la refonte (le tester
  demande un mot de passe) : `Super+Alt+L` pour valider ; ancienne version dans
  `backups/hyprlock.conf.pre-v3`.
- Le **terminal** (Alacritty) suit le pack Omarchy, pas le thème Catalyst.
- Les fonds d'écran **par écran** n'utilisent pas matugen (Material You suit le
  fond global).
- L'historique des notifications est en mémoire : conservé lors d'un
  rechargement du shell, perdu à son redémarrage.
- Après la **suppression** d'un fichier QML, le rechargement à chaud peut
  garder l'ancienne version : `Super+Alt+R` (relance complète).
- Docker n'est géré que si l'utilisateur a accès au socket (groupe `docker`).
- Une application qui ouvre `/dev/videoN` sans passer par PipeWire n'est pas
  vue par l'indicateur caméra.
- La luminosité DDC/CI applique la même valeur aux deux écrans (script existant).
- Les panneaux dev hérités ont l'habillage v3 mais leur mise en page interne
  d'origine.
