#!/usr/bin/env python3
"""
wallcrop.py — recadre un fond d'écran selon une zone normalisée puis le
redimensionne à la résolution de l'écran cible (ImageMagick). Le fichier
produit vit dans ~/.cache/catalyst/framed/ et s'applique comme un fond normal.

  crop <src> <nx> <ny> <nw> <nh> <tw> <th>   -> {ok, path} | {error}

nx,ny,nw,nh : zone visible en fractions (0..1) de l'image source.
tw,th       : résolution cible (px).
"""
import hashlib
import json
import os
import subprocess
import sys

HOME = os.path.expanduser("~")
OUTDIR = os.path.join(HOME, ".cache", "catalyst", "framed")


def die(msg):
    print(json.dumps({"error": msg}))
    sys.exit(0)


def identify(src):
    out = subprocess.run(["magick", "identify", "-format", "%w %h", src],
                         capture_output=True, text=True, timeout=20)
    if out.returncode != 0:
        die("image illisible : " + out.stderr.strip()[:120])
    w, h = out.stdout.split()[:2]
    return int(w), int(h)


def main():
    a = sys.argv[1:]
    if len(a) < 8 or a[0] != "crop":
        die("usage: crop <src> <nx> <ny> <nw> <nh> <tw> <th>")
    src = a[1]
    if not os.path.isfile(src):
        die("fichier introuvable : " + src)
    nx, ny, nw, nh = (float(a[2]), float(a[3]), float(a[4]), float(a[5]))
    tw, th = int(a[6]), int(a[7])

    iw, ih = identify(src)
    # zone source en pixels, bornée à l'image
    cx = max(0, min(iw - 1, round(nx * iw)))
    cy = max(0, min(ih - 1, round(ny * ih)))
    cw = max(1, min(iw - cx, round(nw * iw)))
    ch = max(1, min(ih - cy, round(nh * ih)))

    os.makedirs(OUTDIR, exist_ok=True)
    tag = hashlib.md5(
        ("%s|%d,%d,%d,%d|%dx%d" % (src, cx, cy, cw, ch, tw, th)).encode()
    ).hexdigest()[:12]
    ext = os.path.splitext(src)[1].lower()
    if ext not in (".jpg", ".jpeg", ".png", ".webp"):
        ext = ".jpg"
    out = os.path.join(OUTDIR, "frame_%s%s" % (tag, ext))

    if not os.path.exists(out):
        cmd = [
            "magick", src,
            "-crop", "%dx%d+%d+%d" % (cw, ch, cx, cy), "+repage",
            "-filter", "Lanczos", "-resize", "%dx%d!" % (tw, th),
        ]
        if ext in (".jpg", ".jpeg"):
            cmd += ["-quality", "92"]
        cmd.append(out)
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        if r.returncode != 0 or not os.path.exists(out):
            die("recadrage : " + r.stderr.strip()[:140])

    print(json.dumps({"ok": True, "path": out}))


if __name__ == "__main__":
    main()
