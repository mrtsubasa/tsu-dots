#!/usr/bin/env python3
"""Tsubasa Catalyst — profils de configuration (préréglages complets du bureau).

Un profil est un instantané des fichiers de réglages du shell :
  catalyst/shell.json        thème actif, modules globaux
  catalyst/bar.json          éléments, ordre et style de la barre
  catalyst/widgets.json      widgets du bureau (positions, tailles, réglages)
  catalyst/tokens/shell.json densité, animations
  ~/.config/dock/dock.json   dock et applications épinglées
  ~/.config/spell-shell/panel.json  identité, horloge

  profiles.py list                 JSON [{id, name, created, builtin}]
  profiles.py save <nom>           enregistre la configuration courante
  profiles.py load <id>            applique un profil (sauvegarde _previous avant)
  profiles.py undo                 restaure l'état d'avant le dernier chargement
  profiles.py duplicate <id>       copie
  profiles.py rename <id> <nom>    renomme
  profiles.py delete <id>          supprime (profils utilisateur uniquement)
  profiles.py defaults             revient aux réglages Catalyst par défaut

Les écritures sont atomiques (fichier temporaire + rename) ; le shell suit
les fichiers et se met à jour sans redémarrage.
"""
import json
import re
import sys
import time
import unicodedata
from pathlib import Path

HOME = Path.home()
ROOT = HOME / ".config/quickshell/catalyst"
DIR = ROOT / "profiles"
FILES = {
    "shell": ROOT / "shell.json",
    "bar": ROOT / "bar.json",
    "widgets": ROOT / "widgets.json",
    "tokens": ROOT / "tokens/shell.json",
    "dock": HOME / ".config/dock/dock.json",
    "panel": HOME / ".config/spell-shell/panel.json",
}

DEFAULTS = {
    "shell": {"bar": True, "osd": True, "atelier": True, "replaceWaybar": True, "widgets": True,
              "widgetsLayer": "desk", "paletteMode": "theme", "palette": "catalyst-dark", "theme": "catalyst-dark"},
    "bar": {"output": "all", "height": 0, "opacity": 0, "style": "", "metrics": "auto",
            "rightOrder": ["media", "metrics", "tray", "status", "notif", "power"],
            "modules": {"mark": True, "workspaces": True, "window": True, "clock": True, "media": True,
                        "metrics": True, "tray": True, "status": True, "notif": True, "power": True, "tools": False}},
    "tokens": {"$schema": "catalyst.shell/v3", "identity": "catalyst", "density": "regular",
               "reducedMotion": False, "bar": {"opacity": 0.84}, "chrome": {"veil": 0.78, "blurBackdrop": True}},
}


def out(obj):
    print(json.dumps(obj, ensure_ascii=False))


def slug(name):
    flat = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    s = re.sub(r"[^a-z0-9]+", "-", flat.lower()).strip("-")
    return s or "profil"


def read(path):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return None


def write_atomic(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    tmp.replace(path)


def snapshot(name):
    return {"name": name, "created": int(time.time()),
            "files": {k: read(p) for k, p in FILES.items() if p.is_file()}}


def apply(profile):
    files = profile.get("files") or {}
    for key, data in files.items():
        if key in FILES and isinstance(data, (dict, list)):
            write_atomic(FILES[key], data)


def path_of(pid):
    return DIR / f"{pid}.json"


def cmd_list():
    DIR.mkdir(parents=True, exist_ok=True)
    items = []
    for f in sorted(DIR.glob("*.json")):
        d = read(f)
        if not d:
            continue
        pid = f.stem
        items.append({"id": pid, "name": d.get("name", pid), "created": d.get("created", 0),
                      "internal": pid.startswith("_")})
    items.sort(key=lambda x: (x["internal"], -x["created"]))
    out(items)


def main(a):
    if len(a) < 2:
        print(__doc__)
        return 2
    cmd = a[1]
    if cmd == "list":
        cmd_list()
    elif cmd == "save" and len(a) >= 3:
        name = a[2].strip()
        pid = slug(name)
        write_atomic(path_of(pid), snapshot(name))
        out({"ok": True, "id": pid})
    elif cmd == "load" and len(a) >= 3:
        p = read(path_of(a[2]))
        if not p:
            out({"ok": False, "error": "profil introuvable"})
            return 1
        write_atomic(path_of("_previous"), snapshot("Avant « " + p.get("name", a[2]) + " »"))
        apply(p)
        out({"ok": True})
    elif cmd == "undo":
        p = read(path_of("_previous"))
        if not p:
            out({"ok": False, "error": "rien à annuler"})
            return 1
        cur = snapshot("Annulé")
        apply(p)
        write_atomic(path_of("_previous"), cur)
        out({"ok": True})
    elif cmd == "duplicate" and len(a) >= 3:
        p = read(path_of(a[2]))
        if not p:
            out({"ok": False})
            return 1
        name = p.get("name", a[2]) + " (copie)"
        pid = slug(name)
        n = 2
        while path_of(pid).exists():
            pid = slug(f"{name} {n}")
            n += 1
        p["name"] = name
        p["created"] = int(time.time())
        write_atomic(path_of(pid), p)
        out({"ok": True, "id": pid})
    elif cmd == "rename" and len(a) >= 4:
        p = read(path_of(a[2]))
        if not p:
            out({"ok": False})
            return 1
        p["name"] = a[3].strip()
        nid = slug(p["name"])
        write_atomic(path_of(nid), p)
        if nid != a[2]:
            path_of(a[2]).unlink(missing_ok=True)
        out({"ok": True, "id": nid})
    elif cmd == "delete" and len(a) >= 3:
        if a[2].startswith("_"):
            out({"ok": False})
            return 1
        path_of(a[2]).unlink(missing_ok=True)
        out({"ok": True})
    elif cmd == "defaults":
        write_atomic(path_of("_previous"), snapshot("Avant réinitialisation"))
        for key, data in DEFAULTS.items():
            cur = read(FILES[key]) or {}
            if isinstance(cur, dict):
                cur.update(data)
                data = cur
            write_atomic(FILES[key], data)
        out({"ok": True})
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
