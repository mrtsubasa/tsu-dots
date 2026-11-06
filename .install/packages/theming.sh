#!/bin/bash
# =============================================================================
# Theming Packages - Qt/GTK Theming
# =============================================================================
# Packages for Qt and GTK theme configuration
# =============================================================================

THEMING_PACKAGES=(
    # GTK Theming
    "nwg-look" # GTK theme configuration for Wayland

    # Themes
    "breeze"        # KDE Breeze theme
    "breeze5"       # Breeze QT5 theme
    "breeze-gtk"    # Breeze GTK theme
    "adw-gtk-theme" # adw-gtk3 theme (GTK3 port of libadwaita, supports @define-color)

    # Material You color generation
    "matugen" # Generate Material You colors from wallpapers
    "qt5ct"   # Qt5 theme configuration (Catalyst writes its colors)
    "qt6ct"   # Qt6 theme configuration
)

# AUR packages
THEMING_AUR_PACKAGES=(
    # No mandatory AUR packages
)

# =============================================================================
# Setup - Apply theme settings
# =============================================================================
setup_theming() {
    echo "[>>] Applying GTK theme settings..."
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
    gsettings set org.gnome.desktop.interface font-name "Inter 10"
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic"
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    echo "[OK] GTK theme applied!"

    echo "[>>] Setting up matugen..."
    mkdir -p "$HOME/.cache/matugen"
    mkdir -p "$HOME/.local/share/color-schemes"
    mkdir -p "$HOME/.config/matugen"
    ln -sf "$HOME/.tsu-dots/.data/matugen/config.toml" "$HOME/.config/matugen/config.toml"
    echo "[OK] Matugen configured!"
}
