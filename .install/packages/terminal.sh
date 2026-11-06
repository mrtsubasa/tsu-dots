#!/bin/bash
# =============================================================================
# Terminal Packages - Terminal Emulators & Shells
# =============================================================================
# Packages for terminal, shells and multiplexers
# =============================================================================

TERMINAL_PACKAGES=(
    # Terminal Emulator
    "kitty"                 # GPU-accelerated terminal emulator
    "alacritty"             # Terminal opened by Catalyst panels
    "ghostty"               # Terminal

    # Shell
    "zsh"                   # Z Shell

    # Multiplexer
    "tmux"                  # Terminal multiplexer

    # System Info
    "fastfetch"             # Fast system info display
)

# AUR packages
TERMINAL_AUR_PACKAGES=(
    # Oh-My-Zsh and plugins are installed by setup_zsh() in install.sh
)
