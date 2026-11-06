#!/usr/bin/env bash
# =============================================================================
# Overview intelligent : hyprexpo (miniatures live) si dispo, sinon panel QS
# =============================================================================
set -euo pipefail

QS_PATH="${HOME}/.config/quickshell/catalyst"

if hyprctl plugin list 2>/dev/null | grep -qi "hyprexpo"; then
    exec hyprctl dispatch hyprexpo:expo toggle
fi

exec qs ipc -p "$QS_PATH" call panels toggle overview
