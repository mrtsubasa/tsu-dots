#!/bin/bash
set -euo pipefail

cmd="${1:-add}"

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
'
        return
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

output() {
    if [ -n "${WAYBAR_OUTPUT:-}" ]; then
        printf '%s\n' "$WAYBAR_OUTPUT"
        return
    fi
    focused_output
}

case "$cmd" in
up)
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        hyprctl dispatch 'hl.dsp.focus({ workspace = "e-1" })'
    else
        niri msg action focus-workspace-up
    fi
    ;;
down)
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        hyprctl dispatch 'hl.dsp.focus({ workspace = "e+1" })'
    else
        niri msg action focus-workspace-down
    fi
    ;;
add)
    mon="$(output)"
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        WS_JSON="$(hyprctl workspaces -j 2>/dev/null || echo '[]')"
        WS_JSON="$WS_JSON" python3 - "$mon" <<'PY'
import json, os, sys, subprocess
mon = sys.argv[1]
data = json.loads(os.environ.get("WS_JSON") or "[]")
mine = [w for w in data if not mon or w.get("monitor") == mon]
if not mine:
    mine = data
idxs = [int(w.get("id") or 0) for w in mine]
nxt = (max(idxs) + 1) if idxs else 1
subprocess.run(["hyprctl", "dispatch", f"hl.dsp.focus({{ workspace = {nxt} }})"], check=False)
PY
    else
        WS_JSON="$(niri msg --json workspaces 2>/dev/null || echo '[]')"
        WS_JSON="$WS_JSON" python3 - "$mon" <<'PY'
import json, os, sys, subprocess
mon = sys.argv[1]
data = json.loads(os.environ.get("WS_JSON") or "[]")
mine = [w for w in data if not mon or w.get("output") == mon]
if not mine:
    mine = data
idxs = [int(w.get("idx") or 0) for w in mine]
nxt = (max(idxs) + 1) if idxs else 1
active = next((w for w in mine if w.get("is_focused") or w.get("is_active")), None)
if active and int(active.get("idx") or 0) == max(idxs or [0]):
    nxt = int(active.get("idx") or 1) + 1
subprocess.run(["niri", "msg", "action", "focus-workspace", str(nxt)], check=False)
PY
    fi
    ;;
focus)
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        hyprctl dispatch "hl.dsp.focus({ workspace = ${2:?} })"
    else
        niri msg action focus-workspace "${2:?}"
    fi
    ;;
*)
    exit 1
    ;;
esac
