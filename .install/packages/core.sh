#!/bin/bash
# =============================================================================
# Core Packages - Window Manager & Session
# =============================================================================
# Essential packages for the Hyprland environment to work
# =============================================================================

CORE_PACKAGES=(
    # Window Manager (config is Lua: Hyprland >= 0.57)
    "hyprland"

    # Session Management
    "uwsm"

    # Hyprland Utilities
    "hypridle"        # idle / screen off
    "hyprlock"        # lock screen
    "hyprpicker"      # color picker
    "hyprsunset"      # night light
    "hyprpolkitagent" # Polkit agent
    "polkit-kde-agent" # Polkit agent started by autostart.lua

    # Display
    "nwg-displays"    # Monitor configuration tool

    # XDG & Portal
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"
    "xdg-user-dirs-gtk"
    "xdg-utils"
    "qt5-wayland"
    "qt6-wayland"
)

CORE_AUR_PACKAGES=(
    # No mandatory AUR packages for core
)
