#!/usr/bin/env python3
"""Hyprland dynamic workspaces (niri-like).

Hyprland destroys empty workspaces on its own when you leave them, so this
script only provides the smart navigation that makes the flow feel dynamic:

  next        go to the next workspace on the focused monitor; if you are on
              the last one, a new workspace is created at the end of the pile
  prev        go to the previous workspace on the focused monitor (no create)
  new         create a new workspace at the end of the focused monitor's pile
  move-next   move the active window to the next workspace (creates if needed)
  move-prev   move the active window to the previous workspace
  move-new    move the active window to a freshly created workspace
  switch N    go to the Nth workspace of the focused monitor (by position)
  move N      move the active window to the Nth workspace (by position)
  switch N MON  like switch, but first focus monitor MON
  status      print per-monitor workspace state
"""

import json
import subprocess
import sys


def hyprctl(*args):
    r = subprocess.run(["hyprctl", *args], capture_output=True, text=True)
    return r.stdout


def monitors():
    return json.loads(hyprctl("monitors", "-j") or "[]")


def workspaces():
    return json.loads(hyprctl("workspaces", "-j") or "[]")


def focused_mon():
    for m in monitors():
        if m.get("focused"):
            return m["name"]
    return None


def mon_index(name):
    mons = sorted(monitors(), key=lambda m: m["x"])
    for i, m in enumerate(mons):
        if m["name"] == name:
            return i
    return 0


def active_ws(mon):
    for m in monitors():
        if m["name"] == mon:
            return m["activeWorkspace"]["id"]
    return None


def ws_ids_on(mon):
    return sorted(
        w["id"] for w in workspaces() if w["monitor"] == mon and w.get("id", 0) >= 1
    )


def all_ids():
    return {w["id"] for w in workspaces() if w.get("id", 0) >= 1}


def append_id(mon):
    ids = ws_ids_on(mon)
    existing = all_ids()
    cand = (max(ids) + 1) if ids else 1
    while cand in existing:
        cand += 1
    return cand


def dispatch(*args):
    subprocess.run(["hyprctl", "dispatch", *args], capture_output=True)


def goto(ws_id):
    dispatch(f"hl.dsp.focus({{ workspace = {ws_id} }})")


def move_to(ws_id):
    dispatch(f"hl.dsp.window.move({{ workspace = {ws_id} }})")


def ensure_mon(mon):
    if mon and mon != focused_mon():
        dispatch(f'hl.dsp.focus({{ monitor = "{mon}" }})')


def cmd_next(move=False):
    mon = focused_mon()
    cur = active_ws(mon)
    ids = ws_ids_on(mon)
    target = next((i for i in ids if i > cur), None)
    if target is None:
        target = append_id(mon)
    (move_to if move else goto)(target)


def cmd_prev(move=False):
    mon = focused_mon()
    cur = active_ws(mon)
    ids = ws_ids_on(mon)
    target = next((i for i in reversed(ids) if i < cur), None)
    if target is None:
        return
    (move_to if move else goto)(target)


def cmd_new(move=False):
    mon = focused_mon()
    target = append_id(mon)
    (move_to if move else goto)(target)


def cmd_switch(n, move=False, mon=None):
    ensure_mon(mon)
    mon = focused_mon()
    ids = ws_ids_on(mon)
    if 1 <= n <= len(ids):
        (move_to if move else goto)(ids[n - 1])


def cmd_status():
    for m in sorted(monitors(), key=lambda x: x["x"]):
        idx = mon_index(m["name"])
        cur = active_ws(m["name"])
        ids = ws_ids_on(m["name"])
        print(f"[{idx}] {m['name']}: active={cur} wss={ids}")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cmd = sys.argv[1]
    rest = sys.argv[2:]
    arg = int(rest[0]) if rest and rest[0].lstrip("-").isdigit() else None
    mon = rest[1] if len(rest) > 1 else None

    if cmd == "next":
        cmd_next(False)
    elif cmd == "prev":
        cmd_prev(False)
    elif cmd == "new":
        cmd_new(False)
    elif cmd == "move-next":
        cmd_next(True)
    elif cmd == "move-prev":
        cmd_prev(True)
    elif cmd == "move-new":
        cmd_new(True)
    elif cmd == "switch" and arg is not None:
        cmd_switch(arg, False, mon)
    elif cmd == "move" and arg is not None:
        cmd_switch(arg, True, mon)
    elif cmd == "status":
        cmd_status()
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
