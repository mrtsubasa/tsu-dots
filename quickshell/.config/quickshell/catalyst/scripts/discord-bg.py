#!/usr/bin/env python3
"""Fond de la conversation Discord (thème Vesktop « Tsubasa Catalyst »).

L'image choisie est redimensionnée, légèrement floutée puis intégrée en
data-URI dans un bloc délimité à la fin du thème ; Vesktop recharge le thème
à chaud. La copie traitée et l'état sont gardés dans ~/.local/share/catalyst
pour l'aperçu du Studio et pour régler l'assombrissement sans tout refaire.

  discord-bg.py pick                 (sélecteur, puis rouvre le Studio)
  discord-bg.py set <image> [--blur N]
  discord-bg.py dim <0..1>
  discord-bg.py blur <px>
  discord-bg.py clear
  discord-bg.py mark <mot 1> [mot 2]   (signature de la barre du haut ; sans argument = défaut)
  discord-bg.py rail left|right|top|dock  (position de la barre des serveurs)
  discord-bg.py shape round|soft|square   (forme des icônes de serveurs)
  discord-bg.py status

Chaque commande affiche l'état en JSON sur une ligne.
"""
import base64
import json
import os
import subprocess
import sys
import tempfile

HOME = os.path.expanduser("~")
THEME = os.path.join(HOME, ".config/vesktop/themes/tsu.theme.css")
DATA = os.path.join(HOME, ".local/share/catalyst")
STATE = os.path.join(DATA, "discord-bg.json")
IMAGE = os.path.join(DATA, "discord-bg.jpg")

START = "/* @tc-wallpaper:start"
END = "/* @tc-wallpaper:end */"
MAX_W, MAX_H = 1920, 1200
MARK = ("TSUBASA", "CATALYST")
DEFAULT = {"source": "", "dim": 0.78, "blur": 2, "applied": False,
           "mark1": MARK[0], "mark2": MARK[1], "rail": "left", "shape": "soft", "error": ""}
RAILS = ("left", "right", "top", "dock")
SHAPES = {"round": "50%", "soft": "13px", "square": "6px"}


def css_str(t):
    return '"' + t.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'



def atomic_write(path, data, mode="w"):
    d = os.path.dirname(path)
    os.makedirs(d, exist_ok=True)
    try:
        perm = os.stat(path).st_mode & 0o777
    except OSError:
        perm = 0o644
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".tmp-")
    with os.fdopen(fd, mode) as f:
        f.write(data)
    os.chmod(tmp, perm)
    os.replace(tmp, path)


def load_state():
    try:
        with open(STATE) as f:
            return {**DEFAULT, **json.load(f), "error": ""}
    except (OSError, ValueError):
        return dict(DEFAULT)


def save_state(st):
    atomic_write(STATE, json.dumps({k: v for k, v in st.items() if k != "error"}, indent=2))


def process(src, blur):
    from PIL import Image, ImageFilter, ImageOps

    with Image.open(src) as im:
        im.seek(0)  # GIF animé : première image
        im = ImageOps.exif_transpose(im).convert("RGB")
        im.thumbnail((MAX_W, MAX_H), Image.LANCZOS)
        if blur > 0:
            im = im.filter(ImageFilter.GaussianBlur(blur))
        os.makedirs(DATA, exist_ok=True)
        fd, tmp = tempfile.mkstemp(dir=DATA, prefix=".tmp-", suffix=".jpg")
        os.close(fd)
        im.save(tmp, "JPEG", quality=82, optimize=True, progressive=True)
        os.replace(tmp, IMAGE)


def write_theme(st):
    with open(THEME) as f:
        css = f.read()
    i = css.find(START)
    if i >= 0:
        j = css.find(END, i)
        if j < 0:
            raise RuntimeError("bloc @tc-wallpaper non fermé dans le thème")
        css = css[:i].rstrip("\n") + css[j + len(END):]
    css = css.rstrip("\n") + "\n"
    decl = []
    if st["applied"]:
        with open(IMAGE, "rb") as f:
            b64 = base64.b64encode(f.read()).decode()
        decl += [f"  --tc-wallpaper: url(data:image/jpeg;base64,{b64});",
                 f"  --tc-wallpaper-dim: {st['dim']:.2f};"]
    if (st["mark1"], st["mark2"]) != MARK:
        decl += [f"  --tc-mark-1: {css_str(st['mark1'])};",
                 f"  --tc-mark-2: {css_str('◆ ' + st['mark2'] if st['mark2'] else '')};"]
    if st["rail"] != "left":
        decl.append(f"  --tc-rail: {st['rail']};")
    if st["shape"] != "soft":
        decl.append(f"  --tc-rail-r: {SHAPES[st['shape']]};")
    if decl:
        css += ("\n" + START + " — géré par le rice : Studio › Fond d'écran › Discord */\n"
                ":root {\n" + "\n".join(decl) + "\n}\n" + END + "\n")
    atomic_write(THEME, css)


def main(argv):
    cmd = argv[1] if len(argv) > 1 else "status"
    st = load_state()
    try:
        if cmd == "set":
            src = os.path.abspath(os.path.expanduser(argv[2]))
            if "--blur" in argv:
                st["blur"] = max(0, min(20, int(argv[argv.index("--blur") + 1])))
            process(src, st["blur"])
            st.update(source=src, applied=True)
            write_theme(st)
        elif cmd == "dim":
            st["dim"] = max(0.0, min(0.95, float(argv[2])))
            if st["applied"]:
                write_theme(st)
        elif cmd == "blur":
            st["blur"] = max(0, min(20, int(float(argv[2]))))
            if st["applied"] and st["source"]:
                process(st["source"], st["blur"])
                write_theme(st)
        elif cmd == "pick":
            # Lancé détaché par le Studio (qui se ferme pour laisser passer la
            # fenêtre) ; on rouvre le Studio sur la page Fond d'écran à la fin.
            try:
                p = subprocess.run(
                    ["zenity", "--file-selection", "--title=Fond de la conversation Discord",
                     "--filename=" + os.path.join(HOME, ".config/quickshell/catalyst/wallpapers") + "/",
                     "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.gif *.bmp"],
                    stdout=subprocess.PIPE, text=True,
                )
                src = (p.stdout or "").strip()
                if src:
                    process(src, st["blur"])
                    st.update(source=src, applied=True)
                    write_theme(st)
                else:
                    cmd = "status"  # annulé : rien à enregistrer
            finally:
                subprocess.run(["qs", "ipc", "-p", os.path.join(HOME, ".config/quickshell/catalyst"),
                                "call", "panels", "studio", "discord"],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif cmd == "mark":
            words = [w.strip() for w in argv[2:4]]
            st["mark1"], st["mark2"] = (words + [""])[:2] if any(words) else MARK
            write_theme(st)
        elif cmd == "rail":
            if argv[2] not in RAILS:
                raise ValueError(f"position inconnue : {argv[2]}")
            st["rail"] = argv[2]
            write_theme(st)
        elif cmd == "shape":
            if argv[2] not in SHAPES:
                raise ValueError(f"forme inconnue : {argv[2]}")
            st["shape"] = argv[2]
            write_theme(st)
        elif cmd == "clear":
            st["applied"] = False
            write_theme(st)
        elif cmd != "status":
            raise ValueError(f"commande inconnue : {cmd}")
        if cmd != "status":
            save_state(st)
    except Exception as e:  # remonté tel quel au Studio
        st["error"] = str(e)
    st["image"] = IMAGE if st["applied"] else ""
    print(json.dumps(st, ensure_ascii=False), flush=True)
    return 1 if st["error"] else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
