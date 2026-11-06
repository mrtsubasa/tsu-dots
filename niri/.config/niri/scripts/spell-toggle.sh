#!/bin/bash
PANEL="${1:-}"
QS_PATH="$HOME/.config/quickshell/catalyst"

if [ -z "$PANEL" ] || [ "$PANEL" = "none" ]; then
    qs -p "$QS_PATH" -n -d >/dev/null 2>&1 &
    exit 0
fi

MON="${2:-${WAYBAR_OUTPUT:-${SPELL_CLICK_OUTPUT:-}}}"
if [ -z "$MON" ]; then
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        MON="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .name' 2>/dev/null || true)"
    else
        MON="$(niri msg --json focused-output 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if isinstance(data, str):
    print(data)
elif isinstance(data, dict):
    print(data.get("name") or "")
')"
    fi
fi

qs ipc -p "$QS_PATH" call panels open "$PANEL" "$MON" >/dev/null 2>&1 || {
    qs -p "$QS_PATH" -n -d >/dev/null 2>&1
    sleep 0.2
    qs ipc -p "$QS_PATH" call panels open "$PANEL" "$MON" >/dev/null 2>&1 || true
}
