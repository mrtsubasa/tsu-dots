#!/bin/bash
# =============================================================================
# Catalyst Packages - Quickshell shell + everything its panels call
# =============================================================================
# ESSENTIAL: without these the bar, launcher, Studio and panels break.
# =============================================================================

CATALYST_PACKAGES=(
    # Shell
    "quickshell"       # QML shell framework (Catalyst runs on it)
    "qt6-base"
    "qt6-declarative"
    "qt6-wayland"
    "qt6-svg"
    "qt6-5compat"      # Qt5Compat.GraphicalEffects
    "qt6-imageformats" # webp / avif thumbnails
    "upower"           # battery (Quickshell.Services.UPower)

    # Wallpapers & colors
    "awww"             # wallpaper daemon (successor of swww)
    "mpv"              # animated wallpapers player
    "matugen"          # Material You palettes + templates (GTK, Qt, hyprlock)
    "imagemagick"      # wallpaper crop / framing, thumbnails
    "ffmpeg"
    "ffmpegthumbnailer"

    # Launcher, menus, terminal used by panels
    "rofi"             # rofi menus (scripts in ~/.config/niri/scripts)
    "alacritty"        # terminal spawned by panels and the drop-down terminal
    "zenity"           # file pickers

    # Desktop plumbing
    "wl-clipboard"
    "cliphist"         # clipboard history (Super+X)
    "grim"
    "slurp"
    "satty"            # screenshot annotation
    "wf-recorder"      # screen recording / camera scene
    "playerctl"
    "brightnessctl"
    "ddcutil"          # external monitor brightness (DDC/CI)
    "cava"             # audio visualizer widget
    "libnotify"
    "lm_sensors"       # temperatures
    "pacman-contrib"   # checkupdates (update counter)
    "wtype"
    "socat"
    "jq"
    "bc"
    "fzf"
    "libsecret"        # secret-tool (AI keys)
    "gnome-keyring"
    "xdg-user-dirs"

    # Helpers used by scripts
    "python"
    "python-gobject"
    "python-dbus"
    "python-pillow"
    "translate-shell"  # translate selection
    "tesseract"        # OCR of a screen region
    "tesseract-data-eng"
    "tesseract-data-fra"
    "yt-dlp"           # music downloader menu
)

CATALYST_AUR_PACKAGES=(
    "mpvpaper"         # video wallpapers
)
