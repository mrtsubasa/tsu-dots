#!/usr/bin/env bash
set -euo pipefail

NIRI="/usr/bin/niri"
cmd="${1:-park}"
wid="${2:-}"

if [[ ! -x "$NIRI" ]]; then
    NIRI="$(command -v niri)"
fi

# ── Hyprland : park = special:park (pas de workspaces nommés) ──
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    exec python3 - "$cmd" <<'HYP'
import json, subprocess, sys

cmd = sys.argv[1]

def hypr(*args):
    return subprocess.run(["hyprctl", *args], capture_output=True, text=True)

def load(kind):
    try:
        return json.loads(hypr(kind, "-j").stdout)
    except Exception:
        return {} if kind == "activewindow" else []

def active():
    a = load("activewindow")
    return a if isinstance(a, dict) else {}

def park_clients():
    spaces = load("workspaces")
    parks = [s for s in spaces if s.get("name") == "special:park"]
    if not parks:
        return [], None
    return [c for c in load("clients") if c.get("workspace", {}).get("name") == "special:park"], None

def run(*args):
    hypr("dispatch", *args)

act = active()

if cmd == "restore":
    cs, _ = park_clients()
    if not cs:
        sys.exit(0)
    addr = cs[0].get("address")
    act_ws = act.get("workspace", {}).get("id")
    run(f'hl.dsp.focus({{ window = "address:{addr}" }})')
    if act_ws is not None:
        run(f"hl.dsp.window.move({{ workspace = {act_ws} }})")
    # Si la vue speciale est encore ouverte, on la referme
    act2 = active()
    if act2.get("workspace", {}).get("name") == "special:park":
        run('hl.dsp.workspace.toggle_special("park")')
    sys.exit(0)

# park : mettre la fenêtre active de côté
addr = act.get("address")
if not addr:
    sys.exit(0)
run(f'hl.dsp.window.move({{ workspace = "special:park", follow = false, window = "address:{addr}" }})')
HYP
fi

exec python3 - "$NIRI" "$cmd" "$wid" <<'PY'
import json, subprocess, sys

niri, cmd, wid = sys.argv[1], sys.argv[2], sys.argv[3]
PARK = "park"


def run(*args):
    return subprocess.run([niri, "msg", "action", *args], check=False)


def load(kind):
    try:
        data = json.loads(subprocess.check_output([niri, "msg", "--json", kind], text=True))
    except Exception:
        return []
    if kind == "focused-window":
        return data or {}
    return data or []


def ws_by_id(spaces, sid):
    for s in spaces:
        if s.get("id") == sid:
            return s
    return None


def focused_ws(spaces):
    for s in spaces:
        if s.get("is_focused"):
            return s
    for s in spaces:
        if s.get("is_active"):
            return s
    return None


def find_park(spaces, output=None):
    for s in spaces:
        if s.get("name") != PARK:
            continue
        if output and s.get("output") != output:
            continue
        return s
    return None


def win_by_id(wins, wid):
    sw = str(wid)
    for w in wins:
        if str(w.get("id")) == sw:
            return w
    return None


def park_empty(park, wins):
    if not park:
        return True
    pid = park.get("id")
    for w in wins:
        if w.get("workspace_id") == pid:
            return False
    return True


def drop_empty_park():
    spaces = load("workspaces")
    wins = load("windows")
    park = find_park(spaces)
    if park and park_empty(park, wins):
        run("unset-workspace-name", PARK)


def other_on_output(wins, spaces, output, avoid):
    avoid = str(avoid)
    for w in wins:
        if str(w.get("id")) == avoid:
            continue
        if w.get("is_floating"):
            continue
        ws = ws_by_id(spaces, w.get("workspace_id"))
        if not ws or ws.get("name") == PARK:
            continue
        if output and ws.get("output") != output:
            continue
        return w
    return None


def resolve_win(wid):
    wins = load("windows")
    spaces = load("workspaces")
    if str(wid).strip():
        w = win_by_id(wins, wid)
        if w:
            return w, wins, spaces
        return None, wins, spaces
    fw = load("focused-window")
    if isinstance(fw, dict) and fw.get("id"):
        w = win_by_id(wins, fw.get("id"))
        if w:
            return w, wins, spaces
    cur = focused_ws(spaces)
    if cur and cur.get("name") != PARK and cur.get("active_window_id"):
        w = win_by_id(wins, cur.get("active_window_id"))
        if w:
            return w, wins, spaces
    return None, wins, spaces


def live_idx(spaces, output):
    on = [s for s in spaces if s.get("name") != PARK and (not output or s.get("output") == output)]
    for s in on:
        if s.get("is_focused") or s.get("is_active"):
            return int(s.get("idx") or 1)
    for s in on:
        if s.get("active_window_id"):
            return int(s.get("idx") or 1)
    if on:
        return int(on[0].get("idx") or 1)
    return 1


win, wins, spaces = resolve_win(wid)
if not win:
    sys.exit(0)

wid_i = str(int(win["id"]))
origin = ws_by_id(spaces, win.get("workspace_id"))
out = (origin or {}).get("output") or ""

if cmd == "restore":
    idx = live_idx(spaces, out)
    if out:
        run("focus-monitor", out)
    run("move-window-to-tiling", "--id", wid_i)
    run("move-window-to-workspace", "--window-id", wid_i, "--focus", "true", str(idx))
    run("focus-window", "--id", wid_i)
    drop_empty_park()
    sys.exit(0)

run("move-window-to-tiling", "--id", wid_i)

park = find_park(spaces, out)
if park and park.get("output") != out and park_empty(park, load("windows")):
    run("unset-workspace-name", PARK)
    park = None
    spaces = load("workspaces")
    park = find_park(spaces, out)

if park and park.get("output") == out:
    run("move-window-to-workspace", "--window-id", wid_i, "--focus", "false", PARK)
else:
    if out:
        run("focus-monitor", out)
        spaces = load("workspaces")
    on = [s for s in spaces if not out or s.get("output") == out]
    last_idx = max((int(s.get("idx") or 1) for s in on), default=1)
    run("set-workspace-name", "--workspace", str(last_idx), PARK)
    run("move-window-to-workspace", "--window-id", wid_i, "--focus", "false", PARK)

if out:
    run("focus-monitor", out)
spaces = load("workspaces")
wins = load("windows")
other = other_on_output(wins, spaces, out, wid_i)
if other:
    run("focus-window", "--id", str(other["id"]))
else:
    run("focus-workspace", str(live_idx(spaces, out)))
    run("focus-tiling")
PY
