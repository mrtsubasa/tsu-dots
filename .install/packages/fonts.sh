#!/bin/bash
# =============================================================================
# Font Packages - Fonts, Icons & Cursor
# =============================================================================
# Fonts and icons used by Catalyst
# =============================================================================

FONTS_PACKAGES=(
    # Catalyst fonts
    "ttf-jetbrains-mono-nerd"       # JetBrainsMono Nerd Font (mono / terminal)
    "inter-font"                    # Inter (UI font)
    "ttf-material-symbols-variable" # Material Symbols (icons)
    "ttf-nerd-fonts-symbols"        # Nerd Fonts symbols

    # Base Fonts
    "noto-fonts"       # Noto Sans/Serif (fallback)
    "noto-fonts-cjk"   # CJK support (Chinese, Japanese, Korean)
    "noto-fonts-emoji" # Emoji support

    # Icons (theme-sync.py builds the "Catalyst" icon theme on top of Papirus)
    "papirus-icon-theme"
    "gtk-update-icon-cache"
)

FONTS_AUR_PACKAGES=(
    "otf-space-grotesk"       # Space Grotesk (display font)
    "bibata-cursor-theme-bin" # Bibata cursor theme
)
