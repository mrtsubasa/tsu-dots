#!/usr/bin/env python3
"""Tsubasa Catalyst — propage un thème complet aux applications.

Rend les templates matugen existants (~/.config/matugen/config.toml) avec la
palette d'un preset Catalyst au lieu des couleurs tirées du fond d'écran :
GTK 3/4, rofi, hyprlock, couleurs Hyprland. Le template `spell` (palette du
shell) est ignoré : Quickshell lit le preset directement.

  theme-sync.py --json '<preset json>'   applique la palette du preset
  theme-sync.py --auto                   revient à matugen (fond d'écran)

Aucune donnée n'est envoyée nulle part ; seuls des fichiers locaux sont écrits.
"""
import json
import os
import re
import subprocess
import sys
import tomllib
from pathlib import Path

HOME = Path.home()
MATUGEN_CFG = HOME / ".config/matugen/config.toml"
WALL_FILE = HOME / ".cache/matugen/current-wallpaper"
PALETTE_APPLY = HOME / ".config/niri/scripts/palette-apply.sh"
SKIP = {"spell", "waybar", "swaync"}


def log(msg):
    print(msg, file=sys.stderr)


def hex6(c):
    c = str(c or "").strip().lstrip("#")
    return c[-6:].lower() if len(c) >= 6 else "000000"


def mix(a, b, t):
    a, b = hex6(a), hex6(b)
    ca = [int(a[i:i + 2], 16) for i in (0, 2, 4)]
    cb = [int(b[i:i + 2], 16) for i in (0, 2, 4)]
    return "".join(f"{round(x * (1 - t) + y * t):02x}" for x, y in zip(ca, cb))


def roles(p):
    """Palette Catalyst (format lyne) -> rôles Material 3 attendus par les templates."""
    bg = p.get("background")
    text = p.get("text")
    accent = p.get("accent")
    sig = p.get("signature") or accent
    on = p.get("textReverse") or bg
    r = {
        "source_color": accent,
        "primary": accent,
        "on_primary": on,
        "primary_container": mix(accent, bg, 0.62),
        "on_primary_container": text,
        "secondary": p.get("electric") or p.get("subtext"),
        "on_secondary": on,
        "secondary_container": mix(p.get("electric") or accent, bg, 0.7),
        "on_secondary_container": text,
        "tertiary": sig,
        "on_tertiary": on,
        "tertiary_container": mix(sig, bg, 0.7),
        "on_tertiary_container": text,
        "error": p.get("error"),
        "on_error": on,
        "error_container": mix(p.get("error"), bg, 0.7),
        "on_error_container": text,
        "background": bg,
        "on_background": text,
        "surface": bg,
        "on_surface": text,
        "surface_variant": p.get("surface2"),
        "on_surface_variant": p.get("subtext"),
        "surface_dim": p.get("blueDark") or bg,
        "surface_bright": p.get("surface3"),
        "surface_container_lowest": p.get("blueDark") or bg,
        "surface_container_low": p.get("surface0"),
        "surface_container": p.get("surface1"),
        "surface_container_high": p.get("surface2"),
        "surface_container_highest": p.get("surface3"),
        "outline": p.get("muted"),
        "outline_variant": p.get("surface3"),
        "inverse_surface": text,
        "inverse_on_surface": bg,
        "inverse_primary": mix(accent, bg, 0.4),
        "shadow": "000000",
        "scrim": "000000",
    }
    return {k: hex6(v) for k, v in r.items()}


PLACEHOLDER = re.compile(r"\{\{\s*colors\.([a-z_]+)\.(?:default|dark)\.(hex_stripped|hex|rgb|rgba)\s*\}\}")


def render(text, r):
    def sub(m):
        key, fmt = m.group(1), m.group(2)
        v = r.get(key)
        if v is None:
            return m.group(0)
        if fmt == "hex_stripped":
            return v
        if fmt == "hex":
            return "#" + v
        rgb = ", ".join(str(int(v[i:i + 2], 16)) for i in (0, 2, 4))
        return f"rgb({rgb})" if fmt == "rgb" else f"rgba({rgb}, 1.0)"
    return PLACEHOLDER.sub(sub, text)


def apply_preset(data):
    pal = data.get("palette") or {}
    if not pal.get("accent") or not pal.get("background"):
        log("preset sans palette exploitable")
        return 1
    r = roles(pal)
    cfg = tomllib.loads(MATUGEN_CFG.read_text())
    written = 0
    for name, t in (cfg.get("templates") or {}).items():
        if name in SKIP:
            continue
        src = Path(os.path.expanduser(t["input_path"]))
        dst = Path(os.path.expanduser(t["output_path"]))
        try:
            out = render(src.read_text(), r)
            dst.parent.mkdir(parents=True, exist_ok=True)
            tmp = dst.with_suffix(dst.suffix + ".tmp")
            tmp.write_text(out)
            tmp.replace(dst)
            written += 1
        except Exception as e:  # un template cassé ne bloque pas les autres
            log(f"{name}: {e}")
    post()
    log(f"{written} fichiers générés pour {data.get('id', '?')}")
    return 0


def apply_auto():
    try:
        wall = WALL_FILE.read_text().strip()
    except OSError:
        wall = ""
    if not wall or not Path(wall).is_file():
        log("aucun fond d'écran connu : matugen non relancé")
        return 1
    subprocess.run(["matugen", "image", wall, "-t", "scheme-content", "--prefer", "saturation"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60)
    post()
    return 0


def post():
    if PALETTE_APPLY.is_file():
        subprocess.run(["bash", str(PALETTE_APPLY)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
    subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10)


def main(argv):
    if len(argv) >= 3 and argv[1] == "--json":
        return apply_preset(json.loads(argv[2]))
    if len(argv) >= 2 and argv[1] == "--auto":
        return apply_auto()
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
