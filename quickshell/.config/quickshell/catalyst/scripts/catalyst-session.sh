#!/bin/bash
set -euo pipefail

QS_PATH="${HOME}/.config/quickshell/catalyst"
CFG="${QS_PATH}/shell.json"
WAYBAR="${HOME}/.config/waybar/launch.sh"

replace_waybar=true
bar=true
if [[ -f "$CFG" ]]; then
    eval "$(python3 - "$CFG" <<'PY'
import json, sys
p = sys.argv[1]
try:
    d = json.load(open(p))
except Exception:
    d = {}
print(f"replace_waybar={'true' if d.get('replaceWaybar', True) else 'false'}")
print(f"bar={'true' if d.get('bar', True) else 'false'}")
PY
)"
fi

pkill -x mako >/dev/null 2>&1 || true
pkill -x swaync >/dev/null 2>&1 || true
systemctl --user stop mako.service >/dev/null 2>&1 || true
systemctl --user mask mako.service >/dev/null 2>&1 || true

alive=0
if timeout 1 qs ipc -p "$QS_PATH" call panels ping >/dev/null 2>&1; then
    alive=1
fi

if [[ "${1:-}" == "restart" || "$alive" -eq 0 ]]; then
    # après un crash, Quickshell se relance sous le nom « quickshell »
    pkill -x qs >/dev/null 2>&1 || true
    pkill -f "^/usr/bin/quickshell$" >/dev/null 2>&1 || true
    sleep 0.25
    pkill -9 -x qs >/dev/null 2>&1 || true
    pkill -9 -f "^/usr/bin/quickshell$" >/dev/null 2>&1 || true
    # processus enfants orphelins d'une instance plantée
    pkill -f "^/usr/bin/pactl subscribe$" >/dev/null 2>&1 || true
    pkill -x hyprsunset >/dev/null 2>&1 || true
    sleep 0.15
    qs -p "$QS_PATH" -n -d >/dev/null 2>&1 &
    sleep 0.35
fi

if [[ "$replace_waybar" == "true" && "$bar" == "true" ]]; then
    pkill -x waybar >/dev/null 2>&1 || true
    pkill -x swaync >/dev/null 2>&1 || true
    pkill -x mako >/dev/null 2>&1 || true
    pkill -f '/.config/dock/dock.py' >/dev/null 2>&1 || true
    rm -f /tmp/apple-dock.pid
else
    if [[ -x "$WAYBAR" ]]; then
        "$WAYBAR" &
    fi
fi
