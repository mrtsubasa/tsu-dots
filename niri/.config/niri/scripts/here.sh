#!/bin/bash
set -euo pipefail

HERE="$HOME/.config/niri/scripts/here.sh"
TOGGLE="$HOME/.config/niri/scripts/spell-toggle.sh"

focused_output() {
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        hyprctl monitors -j 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for mon in data:
    if mon.get("focused"):
        print(mon.get("name", ""))
        sys.exit(0)
' && return
    fi
    niri msg --json focused-output 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if isinstance(data, str):
    print(data)
elif isinstance(data, dict):
    print(data.get("name") or data.get("output") or "")
' || true
}

resolve_output() {
    if [ -n "${WAYBAR_OUTPUT:-}" ]; then
        printf '%s\n' "$WAYBAR_OUTPUT"
        return
    fi
    if [ -n "${SPELL_CLICK_OUTPUT:-}" ]; then
        printf '%s\n' "$SPELL_CLICK_OUTPUT"
        return
    fi
    focused_output
}

focus_output() {
    local mon="$1"
    [ -z "$mon" ] && return 0
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        hyprctl dispatch "hl.dsp.focus({ monitor = \"$mon\" })" >/dev/null 2>&1 || true
        return
    fi
    niri msg action focus-monitor "$mon" >/dev/null 2>&1 || true
}

run_here() {
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        exec "$@"
    fi
    exec niri msg action spawn -- "$@"
}

if [ "${1:-}" = "--" ]; then
    shift
fi

if [ "${1:-}" = "spell" ]; then
    MON="$(resolve_output)"
    export WAYBAR_OUTPUT="${WAYBAR_OUTPUT:-$MON}"
    export SPELL_CLICK_OUTPUT="${SPELL_CLICK_OUTPUT:-$MON}"
    exec "$TOGGLE" "${2:-}" "$MON"
fi

MON="$(resolve_output)"
export WAYBAR_OUTPUT="${WAYBAR_OUTPUT:-$MON}"
export SPELL_CLICK_OUTPUT="${SPELL_CLICK_OUTPUT:-$MON}"
focus_output "$MON"

if [ -z "${1:-}" ]; then
    exit 0
fi

base="${1##*/}"
case "$base" in
    spell-toggle.sh|here.sh|wallpaper.sh|wallpaper_menu.sh|wallpaper_select.sh|wallhaven_wallpaper.sh|unsplash_wallpaper.sh|konachan_wallpaper.sh|gelbooru_wallpaper.sh|yandere_wallpaper.sh|local_wallpaper.sh)
        exec "$@"
        ;;
esac
run_here "$@"
