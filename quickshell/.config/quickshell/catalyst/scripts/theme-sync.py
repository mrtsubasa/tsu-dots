#!/usr/bin/env python3
"""Tsubasa Catalyst — propage un thème complet aux applications.

Rend les templates matugen existants (~/.config/matugen/config.toml) avec la
palette d'un preset Catalyst au lieu des couleurs tirées du fond d'écran :
GTK 3/4, rofi, hyprlock, couleurs Hyprland, applis Qt/KDE (Dolphin…). Le template `spell` (palette du
shell) est ignoré : Quickshell lit le preset directement.

  theme-sync.py --json '<preset json>'   applique la palette du preset
  theme-sync.py --auto                   revient à matugen (fond d'écran)
  theme-sync.py --qt                     réapplique Catalyst.colors aux applis Qt/KDE

Aucune donnée n'est envoyée nulle part ; seuls des fichiers locaux sont écrits.
"""
import colorsys
import json
import os
import re
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path

HOME = Path.home()
MATUGEN_CFG = HOME / ".config/matugen/config.toml"
WALL_FILE = HOME / ".cache/matugen/current-wallpaper"
PALETTE_APPLY = HOME / ".config/niri/scripts/palette-apply.sh"
SKIP = {"spell", "waybar", "swaync"}
QT_COLORS = HOME / ".local/share/color-schemes/Catalyst.colors"
KDEGLOBALS = HOME / ".config/kdeglobals"
QT_BACKUP = HOME / ".cache/catalyst/qt-backup"
QT_ICONS = "Catalyst"
ICON_DIR = HOME / ".local/share/icons" / QT_ICONS
PAPIRUS = Path("/usr/share/icons/Papirus")
# Couleurs de dossiers fournies par Papirus, avec leur teinte (degrés).
FOLDER_HUES = {"red": 4, "deeporange": 16, "orange": 30, "yellow": 48, "green": 122, "teal": 174,
               "cyan": 187, "blue": 212, "indigo": 231, "violet": 262, "magenta": 291, "pink": 340}
QT_FONT = "Inter"
QT_MONO = "JetBrainsMono Nerd Font"


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
    """Palette Catalyst (format tsu) -> rôles Material 3 attendus par les templates."""
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


PLACEHOLDER = re.compile(r"\{\{\s*colors\.([a-z_]+)\.(?:default|dark)\.(hex_stripped|hex|rgb|rgba|red|green|blue)\s*\}\}")


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
        if fmt in ("red", "green", "blue"):
            return str(int(v[{"red": 0, "green": 2, "blue": 4}[fmt]:][:2], 16))
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
    sync_qt()
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


def ini_sections(text):
    """Sections d'un fichier KDE, dans l'ordre : [(en-tête, [lignes])]. Préambule = en-tête vide."""
    out = [("", [])]
    for line in text.splitlines():
        if line.startswith("["):
            out.append((line, []))
        else:
            out[-1][1].append(line)
    return out


def set_keys(body, keys):
    body = [l for l in body if l.split("=", 1)[0] not in keys]
    while body and not body[-1].strip():
        body.pop()
    return body + [f"{k}={v}" for k, v in keys.items()] + [""]


def backup_once(path):
    dest = QT_BACKUP / path.name
    if path.exists() and not dest.exists():
        QT_BACKUP.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(path.read_bytes())


def write_through(path, text):
    """Écrit à travers un éventuel lien symbolique (dotfiles), sans fichier à moitié écrit."""
    real = path.resolve()
    tmp = real.with_name(real.name + ".tmp")
    tmp.write_text(text)
    tmp.replace(real)


def sync_kdeglobals(scheme):
    """Les applis KDE lisent aussi leurs couleurs ici : sans ça, elles gardent Breeze."""
    backup_once(KDEGLOBALS)
    colors = {h: b for h, b in ini_sections(scheme) if h.startswith("[Colors:")}
    # Sections absentes du template : dérivées, pour ne pas laisser de bleu Breeze.
    colors["[Colors:Complementary]"] = colors["[Colors:Window]"]
    colors["[Colors:Header][Inactive]"] = colors["[Colors:Header]"]
    current = ini_sections(KDEGLOBALS.read_text()) if KDEGLOBALS.exists() else [("", [])]
    kept = [(h, b) for h, b in current if not h.startswith("[Colors:")]
    keys = {
        "[General]": {"ColorScheme": "Catalyst", "font": f"{QT_FONT},10,-1,5,50,0,0,0,0,0", "fixed": f"{QT_MONO},10,-1,5,50,0,0,0,0,0"},
        "[Icons]": {"Theme": QT_ICONS},
        # C'est cette clé qui fait appliquer le schéma à Dolphin ; le reste ne suffit pas.
        "[UiSettings]": {"ColorScheme": "Catalyst"},
        "[KDE]": {"widgetStyle": "Breeze"},
    }
    for header, values in keys.items():
        for i, (h, b) in enumerate(kept):
            if h == header:
                kept[i] = (h, set_keys(b, values))
                break
        else:
            kept.append((header, set_keys([], values)))
    sections = kept + list(colors.items())
    lines = []
    for h, b in sections:
        if h:
            lines.append(h)
        lines.extend(b)
        if lines and lines[-1].strip():
            lines.append("")
    write_through(KDEGLOBALS, "\n".join(lines).rstrip("\n") + "\n")


def qtct_palette(scheme):
    """Palette au format natif de qt5ct/qt6ct : ils n'exploitent pas les .colors de KDE."""
    data = {h: dict(l.split("=", 1) for l in b if "=" in l) for h, b in ini_sections(scheme) if h}

    def col(section, key):
        return "".join(f"{int(x):02x}" for x in data[f"[Colors:{section}]"][key].split(","))

    def row(fade=0.0):
        window, base, button = col("Window", "BackgroundNormal"), col("View", "BackgroundNormal"), col("Button", "BackgroundNormal")
        text = col("Window", "ForegroundNormal")
        soft = mix(text, window, fade)
        accent = col("Selection", "BackgroundNormal")
        # Ordre imposé par qt5ct/qt6ct (rôles de QPalette).
        roles_ = [
            soft, button, mix(button, text, 0.22), mix(button, text, 0.12), mix(button, "000000", 0.35),
            mix(button, text, 0.08), soft, text, soft, base, window, "000000",
            accent if not fade else mix(accent, window, fade), col("Selection", "ForegroundNormal"),
            col("View", "ForegroundLink"), col("View", "ForegroundVisited"), col("View", "BackgroundAlternate"),
            "000000", col("Tooltip", "BackgroundNormal"), col("Tooltip", "ForegroundNormal"),
            col("View", "ForegroundInactive"),
        ]
        return ", ".join("#" + c for c in roles_)

    return f"[ColorScheme]\nactive_colors={row()}\ninactive_colors={row()}\ndisabled_colors={row(0.55)}\n"


def sync_qtct(name, palette):
    path = HOME / f".config/{name}/{name}.conf"
    if not path.exists():
        return
    backup_once(path)
    target = HOME / f".config/{name}/colors/Catalyst.conf"
    target.parent.mkdir(parents=True, exist_ok=True)
    write_through(target, palette)
    font = lambda f: f'"{f},10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"'
    wanted = {
        "color_scheme_path": str(target),
        "custom_palette": "true",
        "icon_theme": QT_ICONS,
        "style": "Breeze",
        "general": font(QT_FONT),
        "fixed": font(QT_MONO),
    }
    lines = [
        f"{l.split('=', 1)[0]}={wanted[l.split('=', 1)[0]]}" if l.split("=", 1)[0] in wanted else l
        for l in path.read_text().splitlines()
    ]
    write_through(path, "\n".join(lines) + "\n")


def folder_color(accent):
    r, g, b = (int(accent[i:i + 2], 16) / 255 for i in (0, 2, 4))
    hue, _, sat = colorsys.rgb_to_hls(r, g, b)
    if sat < 0.12:
        return "grey"
    distance = lambda h: min(abs(hue * 360 - h), 360 - abs(hue * 360 - h))
    return min(FOLDER_HUES, key=lambda name: distance(FOLDER_HUES[name]))


def sync_icons(accent):
    """Papirus-Dark avec des dossiers de la couleur du thème, sans droits root : liens par utilisateur."""
    color = folder_color(accent)
    if not PAPIRUS.is_dir():
        log("qt: Papirus absent")
        return
    if ICON_DIR.exists():
        shutil.rmtree(ICON_DIR)
    dirs = []
    for size in sorted(PAPIRUS.iterdir()):
        places = size / "places"
        if not places.is_dir() or not size.name[0].isdigit():
            continue
        out = ICON_DIR / size.name / "places"
        out.mkdir(parents=True)
        # Comme papirus-folders : tout ce que Papirus fait pointer vers le bleu change de couleur.
        for link in places.iterdir():
            final = link.resolve().name
            if not link.is_symlink() or "-blue" not in final:
                continue
            target = places / final.replace("-blue", f"-{color}")
            if target.exists():
                (out / link.name).symlink_to(target.resolve())
        dirs.append(size.name)
    entries = "".join(
        f"\n[{d}/places]\nContext=Places\nSize={int(d.split('x')[0])}\nType=Fixed\n" for d in dirs
    )
    (ICON_DIR / "index.theme").write_text(
        "[Icon Theme]\nName=Catalyst\nComment=Papirus-Dark aux couleurs du thème\nInherits=Papirus-Dark\n"
        + "Directories=" + ",".join(f"{d}/places" for d in dirs) + "\n" + entries
    )


def sync_qt():
    """Applique Catalyst.colors aux applis Qt/KDE. Les fenêtres ouvertes changent à leur réouverture."""
    try:
        scheme = QT_COLORS.read_text()
        sync_kdeglobals(scheme)
        selection = dict(l.split("=", 1) for h, b in ini_sections(scheme) if h == "[Colors:Selection]" for l in b if "=" in l)
        sync_icons("".join(f"{int(x):02x}" for x in selection["BackgroundNormal"].split(",")))
        palette = qtct_palette(scheme)
        sync_qtct("qt6ct", palette)
        sync_qtct("qt5ct", palette)
    except (OSError, KeyError, ValueError) as e:
        log(f"qt: {e}")
        return 1
    return 0


def post():
    if PALETTE_APPLY.is_file():
        subprocess.run(["bash", str(PALETTE_APPLY)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
    subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10)


def main(argv):
    if len(argv) >= 3 and argv[1] == "--json":
        return apply_preset(json.loads(argv[2]))
    if len(argv) >= 2 and argv[1] == "--qt":
        return sync_qt()
    if len(argv) >= 2 and argv[1] == "--auto":
        return apply_auto()
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
