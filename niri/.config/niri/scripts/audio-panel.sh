#!/usr/bin/env bash
# Toggle the audio mixer as a tiled Niri window (fullscreen with Mod+Shift+F).
#   audio-panel.sh           -> pavucontrol (apps / devices / volume)
#   audio-panel.sh effects   -> Easy Effects (EQ, bass, noise, etc.)
set -euo pipefail

MODE="${1:-mixer}"

if [ "$MODE" = "effects" ]; then
    PATTERN='^(com\.github\.wwmm\.easyeffects)$'
    SPAWN=(easyeffects)
else
    PATTERN='^(pavucontrol|org\.pulseaudio\.pavucontrol)$'
    SPAWN=(pavucontrol)
fi

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    # --- Hyprland : toggle pavucontrol / easyeffects via hyprctl ---
    read -r WIN_ADDR FOCUSED <<EOF
$(hyprctl clients -j 2>/dev/null | python3 -c '
import json, sys, re
pat = re.compile(sys.argv[1])
try:
    wins = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for w in wins or []:
    cls = w.get("class") or ""
    icls = w.get("initialClass") or ""
    if pat.match(cls) or pat.match(icls):
        print(w.get("address", ""), "true" if w.get("focusHistoryID") == 0 else "false")
        break
' "$PATTERN")
EOF

    if [ -n "${WIN_ADDR:-}" ]; then
        if [ "${FOCUSED:-false}" = "true" ]; then
            hyprctl dispatch "hl.dsp.window.close({ window = \"$WIN_ADDR\" })" >/dev/null 2>&1 || true
        else
            hyprctl dispatch "hl.dsp.focus({ window = \"$WIN_ADDR\" })" >/dev/null 2>&1 || true
        fi
        exit 0
    fi

    exec "${SPAWN[@]}"
fi

windows="$(niri msg --json windows 2>/dev/null || true)"
read -r WIN_ID FOCUSED <<EOF
$(printf '%s' "$windows" | python3 -c '
import json, sys, re
pat = re.compile(sys.argv[1])
try:
    wins = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for w in wins or []:
    app = w.get("app_id") or ""
    if pat.match(app):
        print(w.get("id", ""), "true" if w.get("is_focused") else "false")
        break
' "$PATTERN")
EOF

if [ -n "${WIN_ID:-}" ]; then
    if [ "${FOCUSED:-false}" = "true" ]; then
        niri msg action close-window --id "$WIN_ID" >/dev/null 2>&1 || true
    else
        niri msg action focus-window --id "$WIN_ID" >/dev/null 2>&1 || true
    fi
    exit 0
fi

exec "${SPAWN[@]}"
