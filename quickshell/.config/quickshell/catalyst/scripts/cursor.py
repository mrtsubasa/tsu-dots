#!/usr/bin/env python3
"""Tsubasa Catalyst — thème et taille du curseur.

  cursor.py list                 JSON des thèmes de curseur installés
  cursor.py current              { theme, size } actuels (gsettings)
  cursor.py apply <theme> <taille>
        applique en direct (hyprctl setcursor + gsettings) et persiste dans
        ~/.config/hypr/local/extra_environment.lua (bloc délimité, fichier
        user-local non suivi par git) pour survivre au redémarrage.

Aucune connexion réseau. N'écrit qu'un bloc marqué du fichier local de Hyprland
(jamais la config suivie par git) et les clés gsettings du curseur.
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
ENV_FILE = HOME / ".config/hypr/local/extra_environment.lua"
ICON_DIRS = [HOME / ".local/share/icons", HOME / ".icons", Path("/usr/share/icons")]
BEGIN = "-- >>> catalyst cursor (généré) >>>"
END = "-- <<< catalyst cursor <<<"
NAME_RE = re.compile(r"^[A-Za-z0-9 ._-]+$")


def themes():
    """Thèmes de curseur : un dossier d'icônes contenant cursors/ (xcursor) ou
    un manifeste hyprcursor. Dédup par nom, le premier dossier gagne."""
    found = {}
    for base in ICON_DIRS:
        if not base.is_dir():
            continue
        for d in sorted(base.iterdir()):
            if not d.is_dir() or d.name in found:
                continue
            xc = (d / "cursors").is_dir()
            hc = (d / "manifest.hl").is_file() or (d / "hyprcursors").is_dir()
            if xc or hc:
                found[d.name] = {"name": d.name, "xcursor": xc, "hypr": hc}
    return sorted(found.values(), key=lambda t: t["name"].lower())


def gset(key, default=""):
    try:
        out = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", key],
                             capture_output=True, text=True, timeout=5).stdout.strip()
        return out.strip("'\"")
    except Exception:
        return default


def current():
    size = gset("cursor-size", "24")
    try:
        size = int(size)
    except ValueError:
        size = 24
    return {"theme": gset("cursor-theme", "") or "", "size": size}


def write_env(theme, size):
    block = "\n".join([
        BEGIN,
        '-- Réglé depuis le Studio (Interface → Curseur). Ne pas éditer à la main.',
        f'hl.env("XCURSOR_THEME", "{theme}")',
        f'hl.env("XCURSOR_SIZE", "{size}")',
        f'hl.env("HYPRCURSOR_THEME", "{theme}")',
        f'hl.env("HYPRCURSOR_SIZE", "{size}")',
        END,
    ])
    ENV_FILE.parent.mkdir(parents=True, exist_ok=True)
    text = ENV_FILE.read_text() if ENV_FILE.is_file() else ""
    pat = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END), re.DOTALL)
    if pat.search(text):
        text = pat.sub(block, text)
    else:
        text = text.rstrip() + "\n\n" + block + "\n"
    tmp = ENV_FILE.with_suffix(".lua.tmp")
    tmp.write_text(text)
    tmp.replace(ENV_FILE)


def apply(theme, size):
    if not NAME_RE.match(theme or ""):
        return {"ok": False, "error": "nom de thème invalide"}
    try:
        size = max(8, min(96, int(size)))
    except (TypeError, ValueError):
        size = 24
    # live : Hyprland + applications déjà ouvertes (GTK via gsettings)
    subprocess.run(["hyprctl", "setcursor", theme, str(size)],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for key, val in (("cursor-theme", theme), ("cursor-size", str(size))):
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", key, val],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    write_env(theme, size)
    return {"ok": True, "theme": theme, "size": size}


def main(a):
    if len(a) < 2:
        print(__doc__)
        return 2
    cmd = a[1]
    if cmd == "list":
        print(json.dumps({"ok": True, "themes": themes(), "current": current()}, ensure_ascii=False))
    elif cmd == "current":
        print(json.dumps(current(), ensure_ascii=False))
    elif cmd == "apply" and len(a) >= 4:
        print(json.dumps(apply(a[2], a[3]), ensure_ascii=False))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
