#!/usr/bin/env python3
"""Réglages de SekaiPop pour l'Atelier : lit et modifie config.toml sans le reformater.

  get                          état du service + réglages (JSON)
  apply section.clé=valeur...  écrit les valeurs (JSON) puis relance le service s'il tourne
  service on|off               active ou coupe le service, démarrage compris
"""
import json
import os
import re
import subprocess
import sys
import tempfile
import tomllib

CONFIG = os.path.expanduser("~/.config/sekaipop-rs/config.toml")
UNIT = "sekaipop-rs.service"


def systemctl(*args):
    return subprocess.run(["systemctl", "--user", *args], capture_output=True, text=True)


def active():
    return systemctl("is-active", UNIT).stdout.strip() == "active"


def get():
    try:
        with open(CONFIG, "rb") as f:
            cfg = tomllib.load(f)
    except (OSError, tomllib.TOMLDecodeError) as e:
        cfg = {"error": str(e)}
    print(json.dumps({
        "active": active(),
        "error": cfg.get("error", ""),
        "bar": cfg.get("bar", {}),
        "osd": cfg.get("osd", {}),
    }))


def set_key(lines, section, key, value):
    header = f"[{section}]"
    start = next((i for i, l in enumerate(lines) if l.strip() == header), None)
    if start is None:
        if lines and lines[-1].strip():
            lines.append("")
        lines += [header, f"{key} = {value}"]
        return
    end = start + 1
    while end < len(lines) and not lines[end].lstrip().startswith("["):
        end += 1
    pattern = re.compile(rf"^\s*{re.escape(key)}\s*=")
    for i in range(start + 1, end):
        if pattern.match(lines[i]):
            lines[i] = f"{key} = {value}"
            return
    lines.insert(start + 1, f"{key} = {value}")


def apply(pairs):
    with open(CONFIG, encoding="utf-8") as f:
        lines = f.read().splitlines()
    for pair in pairs:
        path, value = pair.split("=", 1)
        section, key = path.rsplit(".", 1)
        set_key(lines, section, key, json.dumps(json.loads(value), ensure_ascii=False))
    text = "\n".join(lines) + "\n"
    tomllib.loads(text)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(CONFIG))
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(text)
    os.chmod(tmp, os.stat(CONFIG).st_mode & 0o777)
    os.replace(tmp, CONFIG)
    if active():
        systemctl("restart", UNIT)


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "get"
    if cmd == "apply":
        apply(sys.argv[2:])
    elif cmd == "service":
        systemctl("enable" if sys.argv[2] == "on" else "disable", "--now", UNIT)
    elif cmd != "get":
        sys.exit(f"commande inconnue : {cmd}")
    get()


if __name__ == "__main__":
    main()
