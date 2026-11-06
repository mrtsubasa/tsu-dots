#!/usr/bin/env python3
"""Pick an app and send its audio through a headphone return (YouTube, Vesktop, …)."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

SINK_NAME = "retour"
SINK_DESC = "Retour"
STATE = Path.home() / ".cache/audio-retour.json"
SKIP = {
    "speech-dispatcher-dummy",
    "speech-dispatcher",
    "easyeffects",
    "pw-loopback",
    "loopback",
    "retour",
}


def run(args, check=False):
    return subprocess.run(args, capture_output=True, text=True, check=check)


def pactl_json(*args):
    p = run(["pactl", "--format=json", *args])
    if p.returncode != 0 or not (p.stdout or "").strip():
        return []
    try:
        return json.loads(p.stdout)
    except json.JSONDecodeError:
        return []


def notify(msg, urgency="low"):
    subprocess.run(
        ["notify-send", "-a", "Retour audio", "-u", urgency, "Retour audio", msg],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def load_state():
    try:
        return json.loads(STATE.read_text())
    except Exception:
        return {"inputs": {}, "loopback": None, "null": None}


def save_state(st):
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps(st, indent=2))


def default_sink():
    p = run(["pactl", "get-default-sink"])
    return (p.stdout or "").strip()


def sinks_by_id():
    out = {}
    for s in pactl_json("list", "sinks"):
        out[s.get("index")] = s.get("name")
        props = s.get("properties") or {}
        if s.get("name"):
            out[s.get("name")] = s.get("name")
        desc = props.get("device.description") or s.get("description")
        if desc:
            out[("desc", s.get("name"))] = desc
    return out


def sink_desc(name):
    for s in pactl_json("list", "sinks"):
        if s.get("name") == name:
            props = s.get("properties") or {}
            return props.get("device.description") or s.get("description") or name
    return name or "?"


def ensure_retour(st):
    names = [s.get("name") for s in pactl_json("list", "sinks")]
    if SINK_NAME not in names:
        p = run(
            [
                "pactl",
                "load-module",
                "module-null-sink",
                f"sink_name={SINK_NAME}",
                f"sink_properties=device.description={SINK_DESC}",
            ]
        )
        st["null"] = (p.stdout or "").strip() or st.get("null")
    dest = default_sink()
    if dest == SINK_NAME:
        notify("Le sink par défaut est déjà Retour — choisis tes AirPods / HP d'abord.", "normal")
        return st
    # Recreate loopback if missing or pointed at the wrong headphones.
    loop_id = None
    for line in (run(["pactl", "list", "short", "modules"]).stdout or "").splitlines():
        parts = line.split("\t")
        if len(parts) < 2:
            parts = line.split(None, 2)
        if len(parts) < 2:
            continue
        mid, name = parts[0], parts[1]
        args = parts[2] if len(parts) > 2 else ""
        if name == "module-loopback" and "source=retour.monitor" in args:
            if f"sink={dest}" in args:
                st["loopback"] = mid
                save_state(st)
                return st
            run(["pactl", "unload-module", mid])
            loop_id = None
    p = run(
        [
            "pactl",
            "load-module",
            "module-loopback",
            "source=retour.monitor",
            f"sink={dest}",
            "latency_msec=30",
        ]
    )
    st["loopback"] = (p.stdout or "").strip() or loop_id
    save_state(st)
    return st


def inputs():
    mapping = {s.get("index"): s.get("name") for s in pactl_json("list", "sinks")}
    rows = []
    for s in pactl_json("list", "sink-inputs"):
        props = s.get("properties") or {}
        app = props.get("application.name") or props.get("node.name") or "app"
        if app.lower() in SKIP or (props.get("application.process.binary") or "").lower() in SKIP:
            continue
        media = props.get("media.name") or ""
        binary = props.get("application.process.binary") or ""
        sink_id = s.get("sink")
        sink_name = mapping.get(sink_id, "")
        on_retour = sink_name == SINK_NAME
        label = app
        if media and media.lower() not in ("playback", "audio stream", app.lower()):
            label = f"{app}  ·  {media}"
        mark = "●" if on_retour else "○"
        rows.append(
            {
                "index": s.get("index"),
                "app": app,
                "label": f"{mark}  {label}",
                "on": on_retour,
                "sink": sink_name,
                "binary": binary,
            }
        )
    rows.sort(key=lambda r: (not r["on"], r["app"].lower()))
    return rows, mapping


def move_input(idx, sink):
    run(["pactl", "move-sink-input", str(idx), sink])


def restore_all(st, mapping):
    dest = default_sink()
    if dest == SINK_NAME:
        dest = "auto_null"
        # last non-retour sink
        for s in pactl_json("list", "sinks"):
            if s.get("name") not in (SINK_NAME, None):
                dest = s.get("name")
                break
    for s in pactl_json("list", "sink-inputs"):
        name = (s.get("properties") or {}).get("application.name", "")
        if name.lower() in SKIP:
            continue
        sn = mapping.get(s.get("sink"))
        if sn == SINK_NAME:
            orig = (st.get("inputs") or {}).get(str(s.get("index"))) or dest
            if orig == SINK_NAME:
                orig = dest
            move_input(s.get("index"), orig)
    st["inputs"] = {}
    save_state(st)


def pick(rows):
    lines = [
        "■  Arrêter le retour (tout remettre)",
        "↻  Recâbler vers le casque actuel",
    ]
    if not rows:
        lines.append("—  aucune app en train de jouer (lance YouTube puis réouvre)")
    else:
        lines.extend(r["label"] for r in rows)
    p = subprocess.run(
        [
            "rofi",
            "-dmenu",
            "-i",
            "-p",
            "Retour audio",
            "-mesg",
            "Choisis l'app à envoyer dans le retour (YouTube, Vesktop…)",
        ],
        input="\n".join(lines) + "\n",
        capture_output=True,
        text=True,
    )
    return (p.stdout or "").strip()


def main():
    st = load_state()
    rows, mapping = inputs()
    choice = pick(rows)
    if not choice:
        return 0

    if choice.startswith("■"):
        restore_all(st, mapping)
        notify("Retour coupé — les apps reviennent sur le casque.")
        return 0

    if choice.startswith("↻"):
        st = ensure_retour(st)
        notify(f"Retour recâblé vers {sink_desc(default_sink())}")
        return 0

    if choice.startswith("—"):
        return 0

    st = ensure_retour(st)
    dest = default_sink()
    target = None
    for r in rows:
        if r["label"] == choice:
            target = r
            break
    if not target:
        notify("App introuvable (elle a peut-être coupé le son).", "normal")
        return 1

    idx = str(target["index"])
    if target["on"]:
        orig = (st.get("inputs") or {}).get(idx) or dest
        if orig == SINK_NAME:
            orig = dest
        move_input(target["index"], orig)
        st.setdefault("inputs", {}).pop(idx, None)
        save_state(st)
        notify(f"{target['app']} retiré du retour")
        return 0

    st.setdefault("inputs", {})[idx] = target["sink"] or dest
    save_state(st)
    move_input(target["index"], SINK_NAME)
    notify(f"{target['app']} → retour vers {sink_desc(dest)}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
