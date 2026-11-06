#!/usr/bin/env python3
"""Gestion des thèmes de curseur (niri + GTK + gsettings)."""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

HOME = Path.home()
USER_ROOTS = [HOME / ".icons", HOME / ".local/share/icons"]
SYS_ROOT = Path("/usr/share/icons")
CACHE = HOME / ".cache" / "cursor-thumbs"
RICE = HOME / ".config" / "waybar" / "rice.json"
NIRI = HOME / ".config" / "niri" / "config.kdl"
GTK3 = HOME / ".config" / "gtk-3.0" / "settings.ini"
GTK4 = HOME / ".config" / "gtk-4.0" / "settings.ini"
GTK2 = HOME / ".gtkrc-2.0"
GTK2_MINE = HOME / ".gtkrc-2.0.mine"
XSETTINGS = HOME / ".config" / "xsettingsd" / "xsettingsd.conf"
HYPR_ENV = HOME / ".config" / "hypr" / "conf.d" / "environment.conf"


def notify(msg: str) -> None:
    subprocess.run(["notify-send", "Curseur", msg], check=False)


def load_rice() -> dict:
    try:
        data = json.loads(RICE.read_text())
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def save_rice(data: dict) -> None:
    RICE.parent.mkdir(parents=True, exist_ok=True)
    RICE.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def rice_cursor() -> dict:
    cur = load_rice().get("cursor") or {}
    if not isinstance(cur, dict):
        cur = {}
    return cur


def theme_label(folder: Path) -> str:
    idx = folder / "index.theme"
    if idx.is_file():
        for line in idx.read_text(errors="ignore").splitlines():
            if line.lower().startswith("name="):
                name = line.split("=", 1)[1].strip().strip(".")
                if name:
                    return name
    return folder.name


def find_left_ptr(folder: Path) -> Path | None:
    cursors = folder / "cursors"
    for name in ("left_ptr", "default", "arrow", "cursor"):
        p = cursors / name
        if p.is_file() or p.is_symlink():
            return p
    return None


def make_preview(folder: Path, theme_id: str) -> str:
    src = find_left_ptr(folder)
    if src is None:
        return ""
    CACHE.mkdir(parents=True, exist_ok=True)
    dest = CACHE / f"{theme_id}.png"
    try:
        if dest.is_file() and dest.stat().st_mtime >= src.stat().st_mtime:
            return str(dest)
    except OSError:
        pass
    tmp = Path(tempfile.mkdtemp(prefix="xcur-"))
    try:
        subprocess.run(
            ["xcur2png", "-q", "-d", str(tmp), str(src)],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        pngs = sorted(tmp.glob("*.png"))
        if not pngs:
            return ""
        shutil.copy2(pngs[0], dest)
        return str(dest)
    except Exception:
        return ""
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def iter_theme_dirs():
    seen: set[str] = set()
    for root, user in [(USER_ROOTS[0], True), (USER_ROOTS[1], True), (SYS_ROOT, False)]:
        if not root.is_dir():
            continue
        try:
            children = sorted(root.iterdir(), key=lambda p: p.name.lower())
        except OSError:
            continue
        for child in children:
            if child.name in ("default", "hicolor") or child.name in seen:
                continue
            if not child.is_dir() or not (child / "cursors").is_dir():
                continue
            seen.add(child.name)
            yield child, user


def cmd_list(_: argparse.Namespace) -> None:
    out = []
    for folder, user in iter_theme_dirs():
        out.append(
            {
                "id": folder.name,
                "label": theme_label(folder),
                "user": user,
                "preview": make_preview(folder, folder.name),
            }
        )
    print(json.dumps(out, ensure_ascii=False))


def current_from_files() -> tuple[str, int]:
    theme = "blackarch-cursor"
    size = 24
    if GTK3.is_file():
        for line in GTK3.read_text().splitlines():
            if line.startswith("gtk-cursor-theme-name="):
                theme = line.split("=", 1)[1].strip() or theme
            elif line.startswith("gtk-cursor-theme-size="):
                try:
                    size = int(line.split("=", 1)[1].strip())
                except ValueError:
                    pass
    cur = rice_cursor()
    theme = str(cur.get("theme") or theme)
    try:
        size = int(cur.get("size") or size)
    except (TypeError, ValueError):
        pass
    return theme, size


def cmd_get(_: argparse.Namespace) -> None:
    theme, size = current_from_files()
    hide = bool(rice_cursor().get("hide_typing", False))
    print(json.dumps({"theme": theme, "size": size, "hide_typing": hide}, ensure_ascii=False))


def patch_key_value(path: Path, key: str, value: str, quoted: bool = False) -> None:
    if not path.is_file():
        return
    text = path.read_text()
    repl = f'{key}="{value}"' if quoted else f"{key}={value}"
    pat = rf"(?m)^{re.escape(key)}\s*=\s*.*$"
    if re.search(pat, text):
        text = re.sub(pat, repl, text, count=1)
    else:
        text = text.rstrip() + "\n" + repl + "\n"
    path.write_text(text)


def patch_xsettings(theme: str, size: int) -> None:
    if not XSETTINGS.is_file():
        return
    text = XSETTINGS.read_text()
    text = re.sub(r'(?m)^Gtk/CursorThemeName\s+".*"', f'Gtk/CursorThemeName "{theme}"', text)
    text = re.sub(r"(?m)^Gtk/CursorThemeSize\s+\d+", f"Gtk/CursorThemeSize {size}", text)
    XSETTINGS.write_text(text)
    subprocess.run(["killall", "-HUP", "xsettingsd"], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def patch_niri(theme: str, size: int, hide: bool) -> None:
    if not NIRI.is_file():
        return
    text = NIRI.read_text()
    lines = [
        "cursor {",
        f'    xcursor-theme "{theme}"',
        f"    xcursor-size {size}",
    ]
    if hide:
        lines.append("    hide-when-typing")
    lines.append("}")
    block = "\n".join(lines)
    if re.search(r"(?m)^cursor\s*\{", text):
        text = re.sub(r"(?ms)^cursor\s*\{.*?\n\}", block, text, count=1)
    elif "prefer-no-csd" in text:
        text = text.replace("prefer-no-csd", "prefer-no-csd\n\n" + block, 1)
    else:
        text = block + "\n\n" + text
    NIRI.write_text(text)


def patch_default_inherit(theme: str) -> None:
    for path in (
        HOME / ".icons" / "default" / "index.theme",
        HOME / ".local" / "share" / "icons" / "default" / "index.theme",
    ):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            "[Icon Theme]\n"
            "Name=Default\n"
            "Comment=Default Cursor Theme\n"
            f"Inherits={theme}\n"
        )


def patch_hypr(theme: str, size: int) -> None:
    if not HYPR_ENV.is_file():
        return
    text = HYPR_ENV.read_text()
    text = re.sub(r"(?m)^env = XCURSOR_THEME,.*$", f"env = XCURSOR_THEME,{theme}", text)
    text = re.sub(r"(?m)^env = XCURSOR_SIZE,.*$", f"env = XCURSOR_SIZE,{size}", text)
    HYPR_ENV.write_text(text)


def apply(theme: str, size: int, hide: bool) -> None:
    size = max(8, min(64, int(size)))
    rice = load_rice()
    rice["cursor"] = {"theme": theme, "size": size, "hide_typing": bool(hide)}
    save_rice(rice)

    patch_key_value(GTK3, "gtk-cursor-theme-name", theme)
    patch_key_value(GTK3, "gtk-cursor-theme-size", str(size))
    patch_key_value(GTK4, "gtk-cursor-theme-name", theme)
    patch_key_value(GTK4, "gtk-cursor-theme-size", str(size))
    patch_key_value(GTK2, "gtk-cursor-theme-name", theme, quoted=True)
    patch_key_value(GTK2, "gtk-cursor-theme-size", str(size))
    if GTK2_MINE.is_file():
        patch_key_value(GTK2_MINE, "gtk-cursor-theme-name", theme, quoted=True)
        patch_key_value(GTK2_MINE, "gtk-cursor-theme-size", str(size))
    patch_xsettings(theme, size)
    patch_default_inherit(theme)
    patch_niri(theme, size, hide)
    patch_hypr(theme, size)
    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", theme],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "cursor-size", str(size)],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def cmd_set(args: argparse.Namespace) -> None:
    theme, size = current_from_files()
    hide = bool(rice_cursor().get("hide_typing", False))
    if args.theme:
        theme = args.theme
    if args.size is not None:
        size = args.size
    if args.hide is not None:
        hide = args.hide == 1
    known = {folder.name for folder, _ in iter_theme_dirs()}
    if theme not in known:
        notify(f"Thème inconnu : {theme}")
        raise SystemExit(1)
    apply(theme, size, hide)
    notify(f"{theme} · {size}px")


def find_cursor_roots(base: Path) -> list[Path]:
    found: list[Path] = []
    candidates = [base] + [p for p in base.rglob("*") if p.is_dir()]
    for p in candidates:
        if (p / "cursors").is_dir() and p.name != "cursors":
            found.append(p)
        elif p.name == "cursors" and p.is_dir():
            found.append(p.parent)
    # unique by resolved path
    uniq = []
    seen = set()
    for p in found:
        key = str(p.resolve()) if p.exists() else str(p)
        if key in seen:
            continue
        seen.add(key)
        uniq.append(p)
    return uniq


def cmd_import(args: argparse.Namespace) -> None:
    src = Path(args.path).expanduser()
    if not src.exists():
        notify("Fichier introuvable")
        raise SystemExit(1)
    dest_root = HOME / ".icons"
    dest_root.mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp(prefix="cursor-import-"))
    try:
        work = src
        if src.is_file():
            name = src.name.lower()
            if name.endswith(".zip"):
                subprocess.run(["unzip", "-q", str(src), "-d", str(tmp)], check=True)
            else:
                subprocess.run(["tar", "-xf", str(src), "-C", str(tmp)], check=True)
            work = tmp
        roots = find_cursor_roots(work)
        if not roots:
            notify("Pas de dossier cursors/ dans l'archive")
            raise SystemExit(1)
        imported = []
        for root in roots:
            name = root.name.strip() or "imported-cursor"
            target = dest_root / name
            if target.exists():
                shutil.rmtree(target)
            shutil.copytree(root, target, symlinks=True)
            imported.append(name)
        apply(imported[0], current_from_files()[1], bool(rice_cursor().get("hide_typing", False)))
        notify("Importé : " + ", ".join(imported))
        print(json.dumps({"imported": imported}, ensure_ascii=False))
    except subprocess.CalledProcessError:
        notify("Échec de l'extraction")
        raise SystemExit(1)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def cmd_delete(args: argparse.Namespace) -> None:
    name = args.name
    removed = False
    for root in USER_ROOTS:
        target = root / name
        if target.is_dir() and (target / "cursors").is_dir():
            shutil.rmtree(target)
            removed = True
    if not removed:
        notify("Thème système, suppression refusée")
        raise SystemExit(1)
    theme, size = current_from_files()
    if theme == name:
        fallback = next((f.name for f, _ in iter_theme_dirs()), "Adwaita")
        apply(fallback, size, bool(rice_cursor().get("hide_typing", False)))
    notify(f"Supprimé : {name}")


def pick_archive() -> str:
    r = subprocess.run(
        [
            "zenity",
            "--file-selection",
            "--title=Importer un thème de curseur",
            "--file-filter=Archives | *.zip *.tar *.tar.gz *.tgz *.tar.xz *.tar.zst *.tar.bz2",
            "--file-filter=Tous | *",
        ],
        capture_output=True,
        text=True,
    )
    return r.stdout.strip()


def cmd_pick_import(_: argparse.Namespace) -> None:
    path = pick_archive()
    if not path:
        raise SystemExit(1)
    ns = argparse.Namespace(path=path)
    cmd_import(ns)


def main() -> None:
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    sub.add_parser("get")
    s = sub.add_parser("set")
    s.add_argument("--theme")
    s.add_argument("--size", type=int)
    s.add_argument("--hide", type=int, choices=(0, 1))
    i = sub.add_parser("import")
    i.add_argument("path")
    d = sub.add_parser("delete")
    d.add_argument("name")
    sub.add_parser("pick-import")
    args = p.parse_args()
    {
        "list": cmd_list,
        "get": cmd_get,
        "set": cmd_set,
        "import": cmd_import,
        "delete": cmd_delete,
        "pick-import": cmd_pick_import,
    }[args.cmd](args)


if __name__ == "__main__":
    main()
